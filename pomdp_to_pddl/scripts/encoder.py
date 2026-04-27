"""
Algorithm 1 : FSC-PDDL compilation.

Implements the encoding scheme validated in the four-domain experiments
(Tiger, Channel, Faulty Robot Sensor, Minesweeper).

Produces PDDL that, when processed by Fast Downward with
    lm_merged([lm_rhw(), lm_zg()])
is expected to yield disjunctive landmarks in bijection with the
hidden variable structure:
    - one { k(v1), ..., k(vc) } disjunction per hidden variable
    - one { k-not(v1), ..., k-not(vc) } disjunction per hidden variable
    - possibly structural disjunctions over FSC node positions

Design notes:
  1. `k` and `k-not` use a single parameterised predicate per hidden variable,
     where the parameter is a PDDL type whose objects are the domain values.
     This is what forces the FD translator to keep these values in ONE
     multi-valued SAS+ variable — the prerequisite for disjunctive-landmark
     extraction. Flat Booleans (e.g. k-left, k-right) break this.

  2. Commitment gates (`committed_X`, `neg-committed_X`) ensure the
     disjunctions lie on the necessary goal path, so lm_rhw emits them
     as landmarks rather than pruning them.

  3. FSC transitions are stored as :init facts, not hard-coded in actions,
     because the FD translator rejects ground constants inside action bodies.

  4. Identity-flag predicates are used in place of equality checks to avoid
     the same translator restriction.
"""

from __future__ import annotations
from typing import List

from fsc_spec import FSCPomdpSpec, HiddenVariable


# ======================================================================
#  Domain generation
# ======================================================================

def generate_domain(spec: FSCPomdpSpec) -> str:
    """Emit the PDDL :domain string."""
    spec.validate()

    lines: List[str] = []
    lines.append(f"(define (domain {spec.name})")
    lines.append("  (:requirements :strips :typing :negative-preconditions :equality)")

    # ---- types ----
    type_decls = ["node - object"]
    for v in spec.hidden_variables:
        type_decls.append(f"{v.name} - object")
    lines.append(f"  (:types {' '.join(type_decls)})")

    # ---- predicates ----
    lines.append("  (:predicates")
    lines.append("    (at ?n - node)")
    lines.append("    (commit-node ?n - node)")   # marks nodes from which commit may fire
    for v in spec.hidden_variables:
        lines.append(f"    (k ?x - {v.name})")
        lines.append(f"    (k-not ?x - {v.name})")
        lines.append(f"    (committed-{v.name})")
        lines.append(f"    (neg-committed-{v.name})")
        lines.append(f"    (confirmed-{v.name})")
    # Transition facts — one predicate per observation symbol
    for o in spec.observations:
        lines.append(f"    (trans-{_sanitize(o)} ?from - node ?to - node)")
    # Belief-update facts — "when you take transition X, set k(var=val)"
    # Stored as init facts so actions stay parameter-clean.
    for v in spec.hidden_variables:
        lines.append(f"    (writes-k-{v.name} ?from - node ?to - node ?x - {v.name})")
        lines.append(f"    (writes-knot-{v.name} ?from - node ?to - node ?x - {v.name})")
    lines.append("    (done)")
    lines.append("  )")

    # ---- actions ----
    # 1) Sense actions: one per observation symbol.
    for o in spec.observations:
        lines.append(_sense_action(spec, o))

    # 2) Commit actions: one per hidden variable (positive belief).
    for v in spec.hidden_variables:
        lines.append(_commit_action(v))

    # 3) Negative-commit actions: one per hidden variable.
    for v in spec.hidden_variables:
        lines.append(_neg_commit_action(v))

    # 4) Confirm actions: one per hidden variable.
    for v in spec.hidden_variables:
        lines.append(_confirm_action(v))

    # 5) Finish action: ties everything to the goal.
    lines.append(_finish_action(spec))

    lines.append(")")
    return "\n".join(lines)


def _sense_action(spec: FSCPomdpSpec, obs: str) -> str:
    """Emit a sensing action for observation `obs`.

    The action fires any FSC edge whose observation == obs and writes the
    matching belief predicates. Multiple edges for the same observation are
    handled by having multiple `trans-obs` facts in :init.
    """
    osan = _sanitize(obs)
    # Parameters: the from/to node and (optionally) one domain value per variable
    # for which this sense action might write a belief update.
    param_parts = ["?from - node", "?to - node"]
    for v in spec.hidden_variables:
        param_parts.append(f"?x-{v.name} - {v.name}")

    # Preconditions: (at ?from) and (trans-obs ?from ?to)
    precs = [
        "(at ?from)",
        f"(trans-{osan} ?from ?to)",
    ]

    # Conditional effects via disjunctive writes facts:
    # If (writes-k-var ?from ?to ?x-var) ∈ :init, we'd like to set (k ?x-var).
    # Classical PDDL without conditional effects handles this by making the
    # writes-* fact a precondition AND the effect. But then only one
    # belief-update per transition is possible per call. That's fine for the
    # four domains studied — none writes multiple belief updates of the same
    # polarity in a single edge. If you need multi-write edges later, split
    # into multiple FSC edges or enable :conditional-effects.
    effects = [
        "(not (at ?from))",
        "(at ?to)",
    ]

    # Use :when if the PDDL backend supports conditional effects;
    # otherwise emit one sense-<obs>-<var>-<pol> variant per variable/polarity.
    # We take the simple, portable route: emit variant actions.
    #
    # (This function returns only the "movement" variant; belief-writing
    #  variants are emitted separately below.)
    return _format_action(
        name=f"sense-{osan}-move",
        parameters=param_parts,
        preconditions=precs + _no_writes_precs(spec, osan),
        effects=effects,
    ) + _belief_write_variants(spec, osan)


def _no_writes_precs(spec: FSCPomdpSpec, osan: str) -> List[str]:
    """Guard the plain-movement variant so it fires only when NO belief
    update is declared for this transition (e.g., reset / retry edges)."""
    guards = []
    for v in spec.hidden_variables:
        guards.append(
            f"(forall (?x-{v.name} - {v.name}) "
            f"(and (not (writes-k-{v.name} ?from ?to ?x-{v.name})) "
            f"(not (writes-knot-{v.name} ?from ?to ?x-{v.name}))))"
        )
    return guards


def _belief_write_variants(spec: FSCPomdpSpec, osan: str) -> str:
    """Emit one variant action per (variable, polarity) that actually writes
    a belief predicate when the writes-* :init fact is present."""
    out = []
    for v in spec.hidden_variables:
        # positive-write variant
        out.append(_format_action(
            name=f"sense-{osan}-write-k-{v.name}",
            parameters=[
                "?from - node", "?to - node", f"?x - {v.name}",
            ],
            preconditions=[
                "(at ?from)",
                f"(trans-{osan} ?from ?to)",
                f"(writes-k-{v.name} ?from ?to ?x)",
            ],
            effects=[
                "(not (at ?from))",
                "(at ?to)",
                f"(k ?x)",
            ],
        ))
        # negative-write variant
        out.append(_format_action(
            name=f"sense-{osan}-write-knot-{v.name}",
            parameters=[
                "?from - node", "?to - node", f"?x - {v.name}",
            ],
            preconditions=[
                "(at ?from)",
                f"(trans-{osan} ?from ?to)",
                f"(writes-knot-{v.name} ?from ?to ?x)",
            ],
            effects=[
                "(not (at ?from))",
                "(at ?to)",
                f"(k-not ?x)",
            ],
        ))
    return "\n".join(out)


def _commit_action(v: HiddenVariable) -> str:
    """Positive-belief commit: requires k(?x) to hold for SOME ?x of type v.

    Fast Downward's lm_rhw, reading the parameterised k(?x) predicate as one
    SAS+ variable, sees the precondition (k ?x) as a disjunctive obligation
    over the values of that variable. Because (committed-V) is required by
    downstream actions, the disjunction {k(v1),...,k(vc)} becomes a landmark.
    """
    return _format_action(
        name=f"commit-{v.name}",
        parameters=[f"?x - {v.name}", "?n - node"],
        preconditions=[
            "(at ?n)",
            "(commit-node ?n)",
            "(k ?x)",
            f"(not (committed-{v.name}))",
        ],
        effects=[f"(committed-{v.name})"],
    )


def _neg_commit_action(v: HiddenVariable) -> str:
    """Negative-belief commit — symmetric to commit, drives the k-not disjunction."""
    return _format_action(
        name=f"neg-commit-{v.name}",
        parameters=[f"?x - {v.name}", "?n - node"],
        preconditions=[
            "(at ?n)",
            "(commit-node ?n)",
            "(k-not ?x)",
            f"(not (neg-committed-{v.name}))",
        ],
        effects=[f"(neg-committed-{v.name})"],
    )


def _confirm_action(v: HiddenVariable) -> str:
    """Confirm a hidden variable: requires both gates open."""
    return _format_action(
        name=f"confirm-{v.name}",
        parameters=[f"?x - {v.name}"],
        preconditions=[
            f"(committed-{v.name})",
            f"(neg-committed-{v.name})",
            "(k ?x)",
            f"(not (confirmed-{v.name}))",
        ],
        effects=[f"(confirmed-{v.name})"],
    )


def _finish_action(spec: FSCPomdpSpec) -> str:
    """The goal-bearing action. Requires all confirmations."""
    precs = [f"(confirmed-{v.name})"
             for v in spec.hidden_variables
             if spec.goal_confirm_per.get(v.name, True)]
    return _format_action(
        name="finish",
        parameters=[],
        preconditions=precs,
        effects=["(done)"],
    )


def _format_action(name, parameters, preconditions, effects) -> str:
    params_str = " ".join(parameters) if parameters else ""
    precs_str = "\n      ".join(preconditions) if preconditions else ""
    effs_str = "\n      ".join(effects) if effects else ""
    return (
        f"  (:action {name}\n"
        f"    :parameters ({params_str})\n"
        f"    :precondition (and\n      {precs_str})\n"
        f"    :effect (and\n      {effs_str})\n"
        f"  )"
    )


# ======================================================================
#  Problem generation
# ======================================================================

def generate_problem(spec: FSCPomdpSpec) -> str:
    """Emit the PDDL :problem string."""
    spec.validate()

    lines: List[str] = []
    lines.append(f"(define (problem p-{spec.name})")
    lines.append(f"  (:domain {spec.name})")

    # ---- objects ----
    lines.append("  (:objects")
    lines.append(f"    {' '.join(spec.fsc_nodes)} - node")
    for v in spec.hidden_variables:
        lines.append(f"    {' '.join(v.domain)} - {v.name}")
    lines.append("  )")

    # ---- init ----
    lines.append("  (:init")
    lines.append(f"    (at {spec.initial_node})")
    for cn in spec.commit_nodes:
        lines.append(f"    (commit-node {cn})")
    # FSC transitions
    for t in spec.transitions:
        lines.append(f"    (trans-{_sanitize(t.observation)} {t.from_node} {t.to_node})")
        for bu in t.belief_updates:
            if bu.polarity == "pos":
                lines.append(
                    f"    (writes-k-{bu.variable} {t.from_node} {t.to_node} {bu.value})"
                )
            else:
                lines.append(
                    f"    (writes-knot-{bu.variable} {t.from_node} {t.to_node} {bu.value})"
                )
    lines.append("  )")

    # ---- goal ----
    lines.append("  (:goal (and (done)))")
    lines.append(")")
    return "\n".join(lines)


# ======================================================================
#  Convenience
# ======================================================================

def compile_to_pddl(spec: FSCPomdpSpec) -> tuple[str, str]:
    """Main entry point. Returns (domain_pddl, problem_pddl) strings."""
    return generate_domain(spec), generate_problem(spec)


def _sanitize(s: str) -> str:
    """PDDL identifiers must be alphanumeric + dash/underscore."""
    return s.replace(" ", "-").replace("_", "-").lower()

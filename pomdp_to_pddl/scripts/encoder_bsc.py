"""
BSC-PDDL compilation.

Converts a BSCSpec (belief-state controller) to PDDL for landmark extraction.
Unlike the FSC encoder, there are NO controller nodes.
The belief state (k / k-not predicates) is the sole state representation.

Design notes
============
1. Identity predicates  (self-VAR-VAL ?x)  stored in :init allow sense actions
   to reference specific ground values without embedding constants in action
   bodies.  (FD rejects ground constants inside action bodies.)

2. commit / neg-commit / confirm remain parameterised over ?x so FD's SAS+
   translation sees  k-VAR(?x)  as one multi-valued variable — the prerequisite
   for disjunctive-landmark extraction by lm_rhw.

3. One sense action is emitted per BSCTransition (indexed 0, 1, ...).
   Each uses the identity predicates to ground its parameters to the specific
   (variable, value) pairs its belief preconditions and effects reference.

4. Retraction effects  (not (k-VAR ?x))  are used for contradictory-reset
   transitions, restoring the uncertain state.

5. **Uncertain-variable optimisation** (key for large domains):
   When a BSCTransition's belief_precs negate ALL domain values of a variable
   (the "uncertain" pattern), those N negative preconditions are replaced by a
   single  (uncertain-VAR)  predicate.  This is added to :init and deleted by
   the sense action that writes the first k-fact, and restored by reset
   transitions that retract k-facts.

   Effect: FD's SAS+ translator groups {uncertain-VAR, k-VAR(v1), ...,
   k-VAR(vN)} into ONE multi-valued variable.  lm_rhw then finds the N-way
   disjunctive landmark regardless of cardinality — not just for N ≤ 4.
"""

from __future__ import annotations
from typing import Dict, List, Set, Tuple

from bsc_spec import BSCSpec, BSCTransition, BeliefUpdate, HiddenVariable


# ======================================================================
#  Uncertain-variable detection
# ======================================================================

def _find_uncertain_vars(spec: BSCSpec) -> Set[str]:
    """Return the set of variable names that have at least one 'uncertain' transition.

    A transition is 'uncertain' for variable V when its belief_precs contain
      (not k-V(vi))  for every vi in V.domain
    AND no  (k-V(*) holds=True)  is present.
    """
    var_map = {v.name: v for v in spec.hidden_variables}
    uncertain: Set[str] = set()

    for t in spec.transitions:
        for vname, var in var_map.items():
            neg_vals = {
                ref.value
                for ref in t.belief_precs
                if ref.variable == vname and ref.polarity == "pos" and not ref.holds
            }
            pos_vals = {
                ref.value
                for ref in t.belief_precs
                if ref.variable == vname and ref.polarity == "pos" and ref.holds
            }
            if neg_vals == set(var.domain) and not pos_vals:
                uncertain.add(vname)

    return uncertain


# ======================================================================
#  Domain generation
# ======================================================================

def generate_domain(spec: BSCSpec) -> str:
    """Emit the PDDL :domain string."""
    spec.validate()
    uncertain_vars = _find_uncertain_vars(spec)

    lines: List[str] = []
    lines.append(f"(define (domain {spec.name})")
    lines.append("  (:requirements :strips :typing :negative-preconditions :equality)")

    # ---- types ----
    type_decls = [f"{v.name} - object" for v in spec.hidden_variables]
    lines.append(f"  (:types {' '.join(type_decls)})")

    # ---- predicates ----
    lines.append("  (:predicates")
    # Identity predicates
    for v in spec.hidden_variables:
        for val in v.domain:
            lines.append(f"    (self-{_san(v.name)}-{_san(val)} ?x - {v.name})")
    # Belief predicates
    for v in spec.hidden_variables:
        lines.append(f"    ({_k(v.name)} ?x - {v.name})")
        lines.append(f"    ({_knot(v.name)} ?x - {v.name})")
        lines.append(f"    (committed-{_san(v.name)})")
        lines.append(f"    (neg-committed-{_san(v.name)})")
        lines.append(f"    (confirmed-{_san(v.name)})")
        # Uncertain predicate (replaces N negative k-precs; enables large disjunctions)
        if v.name in uncertain_vars:
            lines.append(f"    (uncertain-{_san(v.name)})")
    lines.append("    (done)")
    lines.append("  )")

    # ---- actions ----
    for i, t in enumerate(spec.transitions):
        lines.append(_sense_action(spec, t, i, uncertain_vars))

    for v in spec.hidden_variables:
        lines.append(_commit_action(v))
        lines.append(_neg_commit_action(v))
        lines.append(_confirm_action(v))

    lines.append(_finish_action(spec))
    lines.append(")")
    return "\n".join(lines)


def _sense_action(spec: BSCSpec, t: BSCTransition, idx: int,
                  uncertain_vars: Set[str]) -> str:
    """Emit one sense-action variant for BSCTransition t.

    For each variable V that is in uncertain_vars AND this transition covers
    all domain values of V with negative precs, we:
      - replace the N negative precs with  (uncertain-V)
      - add  (not (uncertain-V))  to the effects
      - skip adding those (V, val) pairs to the parameter list

    For reset transitions (retractions of k-V where V ∈ uncertain_vars):
      - add  (uncertain-V)  to effects (restoring the uncertain belief state)
    """
    var_map = {v.name: v for v in spec.hidden_variables}

    # Determine which variables have the uncertain pattern in THIS transition
    this_uncertain: Set[str] = set()
    for vname in uncertain_vars:
        var = var_map[vname]
        neg_vals = {
            ref.value for ref in t.belief_precs
            if ref.variable == vname and ref.polarity == "pos" and not ref.holds
        }
        pos_vals = {
            ref.value for ref in t.belief_precs
            if ref.variable == vname and ref.polarity == "pos" and ref.holds
        }
        if neg_vals == set(var.domain) and not pos_vals:
            this_uncertain.add(vname)

    # Collect (var, val) pairs — skip negative k-precs for uncertain variables
    seen: Dict[Tuple[str, str], str] = {}

    def _reg(var: str, val: str) -> str:
        key = (var, val)
        if key not in seen:
            seen[key] = f"?x-{_san(var)}-{_san(val)}"
        return seen[key]

    for ref in t.belief_precs:
        if ref.variable in this_uncertain and ref.polarity == "pos" and not ref.holds:
            continue  # replaced by (uncertain-VAR)
        _reg(ref.variable, ref.value)
    for bu in t.belief_updates:
        _reg(bu.variable, bu.value)
    for bu in t.retractions:
        _reg(bu.variable, bu.value)

    parameters = [f"{pname} - {var_map[var].name}" for (var, _val), pname in seen.items()]

    preconditions: List[str] = []
    # Identity grounding predicates
    for (var, val), pname in seen.items():
        preconditions.append(f"(self-{_san(var)}-{_san(val)} {pname})")
    # Uncertain predicates (replacing N negative k-precs)
    for vname in sorted(this_uncertain):
        preconditions.append(f"(uncertain-{_san(vname)})")
    # Remaining belief preconditions
    for ref in t.belief_precs:
        if ref.variable in this_uncertain and ref.polarity == "pos" and not ref.holds:
            continue
        pname = seen[(ref.variable, ref.value)]
        pred = _k(ref.variable) if ref.polarity == "pos" else _knot(ref.variable)
        atom = f"({pred} {pname})"
        preconditions.append(atom if ref.holds else f"(not {atom})")

    effects: List[str] = []
    # Unset uncertain predicates for this transition's uncertain variables
    for vname in sorted(this_uncertain):
        effects.append(f"(not (uncertain-{_san(vname)}))")
    # Belief update effects
    for bu in t.belief_updates:
        pname = seen[(bu.variable, bu.value)]
        pred = _k(bu.variable) if bu.polarity == "pos" else _knot(bu.variable)
        effects.append(f"({pred} {pname})")
    # Retraction effects; reset uncertain if retracting k-VAR for uncertain var
    for bu in t.retractions:
        pname = seen[(bu.variable, bu.value)]
        pred = _k(bu.variable) if bu.polarity == "pos" else _knot(bu.variable)
        effects.append(f"(not ({pred} {pname}))")
        if bu.variable in uncertain_vars and bu.polarity == "pos":
            effects.append(f"(uncertain-{_san(bu.variable)})")

    obs_san = _san(t.observation)
    return _fmt(f"sense-{obs_san}-{idx}", parameters, preconditions, effects)


def _commit_action(v: HiddenVariable) -> str:
    """Commit: requires k(?x) for some value of v."""
    return _fmt(
        f"commit-{_san(v.name)}",
        [f"?x - {v.name}"],
        [f"({_k(v.name)} ?x)", f"(not (committed-{_san(v.name)}))"],
        [f"(committed-{_san(v.name)})"],
    )


def _neg_commit_action(v: HiddenVariable) -> str:
    """Neg-commit: requires k-not(?x) for some value of v."""
    return _fmt(
        f"neg-commit-{_san(v.name)}",
        [f"?x - {v.name}"],
        [f"({_knot(v.name)} ?x)", f"(not (neg-committed-{_san(v.name)}))"],
        [f"(neg-committed-{_san(v.name)})"],
    )


def _confirm_action(v: HiddenVariable) -> str:
    """Confirm: both gates (committed + neg-committed) must be open."""
    return _fmt(
        f"confirm-{_san(v.name)}",
        [f"?x - {v.name}"],
        [
            f"(committed-{_san(v.name)})",
            f"(neg-committed-{_san(v.name)})",
            f"({_k(v.name)} ?x)",
            f"(not (confirmed-{_san(v.name)}))",
        ],
        [f"(confirmed-{_san(v.name)})"],
    )


def _finish_action(spec: BSCSpec) -> str:
    """Goal-bearing action — requires all confirmations."""
    precs = [
        f"(confirmed-{_san(v.name)})"
        for v in spec.hidden_variables
        if spec.goal_confirm_per.get(v.name, True)
    ]
    return _fmt("finish", [], precs, ["(done)"])


# ======================================================================
#  Problem generation
# ======================================================================

def generate_problem(spec: BSCSpec) -> str:
    """Emit the PDDL :problem string."""
    spec.validate()
    uncertain_vars = _find_uncertain_vars(spec)

    lines: List[str] = []
    lines.append(f"(define (problem p-{spec.name})")
    lines.append(f"  (:domain {spec.name})")

    # Objects: hidden variable values only — no nodes
    lines.append("  (:objects")
    for v in spec.hidden_variables:
        lines.append(f"    {' '.join(v.domain)} - {v.name}")
    lines.append("  )")

    # Init: identity grounding facts + uncertain predicates
    lines.append("  (:init")
    for v in spec.hidden_variables:
        for val in v.domain:
            lines.append(f"    (self-{_san(v.name)}-{_san(val)} {val})")
        if v.name in uncertain_vars:
            lines.append(f"    (uncertain-{_san(v.name)})")
    lines.append("  )")

    lines.append("  (:goal (and (done)))")
    lines.append(")")
    return "\n".join(lines)


# ======================================================================
#  Convenience
# ======================================================================

def compile_to_pddl(spec: BSCSpec) -> tuple[str, str]:
    """Main entry point. Returns (domain_pddl, problem_pddl) strings."""
    return generate_domain(spec), generate_problem(spec)


# ======================================================================
#  Helpers
# ======================================================================

def _fmt(name: str, parameters: List[str],
         preconditions: List[str], effects: List[str]) -> str:
    params_str = " ".join(parameters)
    precs_str = "\n      ".join(preconditions) if preconditions else "()"
    effs_str  = "\n      ".join(effects)        if effects        else "()"
    return (
        f"  (:action {name}\n"
        f"    :parameters ({params_str})\n"
        f"    :precondition (and\n      {precs_str})\n"
        f"    :effect (and\n      {effs_str})\n"
        f"  )"
    )


def _san(s: str) -> str:
    return s.replace(" ", "-").replace("_", "-").lower()


def _k(varname: str) -> str:
    return f"k-{_san(varname)}"


def _knot(varname: str) -> str:
    return f"k-not-{_san(varname)}"

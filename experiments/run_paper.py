#!/usr/bin/env python3
"""Reproduce every experiment in the paper. Run from the repository root:

    python experiments/run_paper.py                    # all experiments (~1 min)
    python experiments/run_paper.py main exactness     # a subset

  main        landmarks, orderings and solvability of the six controllers   (Table 1)
  exactness   RHW output vs. exhaustive ground truth                         (Table 1)
  ablation    FSC and generic-gate encodings vs. the faithful encoding        (Table 2)
  induced     hand-written vs. SARSOP-induced controllers                     (Table 3)
  mutation    fault injection: do landmark diffs flag commitment bugs?        (Table 4)
  scaling     Sensor-n and Mine-kxk                                           (Table 5)

Writes experiments/results/<experiment>.json. Every Fast Downward run keeps its
files in experiments/results/work/<experiment>/<run>/ for debugging.
"""

from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))  # repo root, for the package

from policy_landmarks import domains, extraction  # noqa: E402
from policy_landmarks.exact import StateGraph, closure, reduction  # noqa: E402
from policy_landmarks.domains import HAND_WRITTEN  # noqa: E402
from policy_landmarks.ground_truth import Task  # noqa: E402
from policy_landmarks.induction import TRACE_SOURCES, induce  # noqa: E402
from policy_landmarks.planner import (  # noqa: E402
    counts, edge_types, graph, is_belief_fact, run_fd, run_spec, show,
)
from policy_landmarks.spec import (  # noqa: E402
    BSCSpec, BSCTransition, BeliefUpdate, CommitCondition,
)

HERE = Path(__file__).resolve().parent
RESULTS = HERE / "results"
WORK = RESULTS / "work"
BASELINES = HERE / "baselines"   # frozen PDDL of earlier encodings (see README)
DISPLAY = {"tiger": "Tiger", "channel": "Channel", "mine-2x2": "Mine-2x2",
           "sensor-2": "Sensor-2", "sensor-3": "Sensor-3", "rocksample-4": "RockSample-4"}


def run_baseline(experiment: str, encoding: str, name: str) -> dict:
    d = BASELINES / encoding
    return run_fd(WORK / experiment / f"{name}-{encoding}",
                  (d / f"{name}-domain.pddl").read_text(),
                  (d / f"{name}-problem.pddl").read_text())


def _belief_lms(parsed: dict) -> list:
    return [k for k in graph(parsed)[0] if all(is_belief_fact(f) for f in k)]


# ===========================================================================
#  Experiments
# ===========================================================================

def exp_main() -> dict:
    rows = {}
    for name, make in HAND_WRITTEN.items():
        spec = make()
        r = run_spec(WORK / "main" / name, spec)
        solve = run_spec(WORK / "main" / f"{name}-blind", spec, search="astar(blind())")
        assert solve["plan_length"], f"{name}: compiled task is unsolvable"
        keys, _ = graph(r["parsed"])
        rows[DISPLAY[name]] = {
            "vars": len(spec.hidden_variables),
            "max_card": max(v.cardinality for v in spec.hidden_variables),
            **counts(r["parsed"]),
            "plan_length": solve["plan_length"],
            "lm_time_s": r["lm_time"],
            "landmark_list": sorted(show(k) for k in keys),
        }
    return rows


def exp_exactness() -> dict:
    rows = {}
    for name, make in HAND_WRITTEN.items():
        r = run_spec(WORK / "exactness" / name, make())
        task = Task(r["sas"])
        keys, edges = graph(r["parsed"])
        types = edge_types(r["parsed"])
        rhw_simple = {next(iter(k)) for k in keys if len(k) == 1}
        nontrivial = [n for n, (v, x) in task.fact.items() if task.init[v] != x]
        true_simple = {n for n in nontrivial if task.is_landmark({n})}
        disj = [k for k in keys if len(k) > 1]
        # Same-predicate belief disjunctions that are landmarks: did RHW find each?
        classes = {}
        for n in nontrivial:
            m = re.match(r"Atom ((?:k-|uncertain-)[^(]*)\(", n)
            if m:
                classes.setdefault(m.group(1), set()).add(n)
        true_classes = [c for c in classes.values()
                        if len(c) > 1 and not c & true_simple and task.is_landmark(c)]
        rows[DISPLAY[name]] = {
            "rhw_landmarks_true": sum(task.is_landmark(k) for k in keys),
            "rhw_landmarks": len(keys),
            "rhw_edges_true": sum(_ordering_holds(task, a, b, types[(a, b)]) for a, b in edges),
            "rhw_sound_edges": len(edges),
            "true_nontrivial_simple": len(true_simple),
            "rhw_found_nontrivial_simple": len(true_simple & rhw_simple),
            "true_belief_disjunctions": len(true_classes),
            "rhw_found_belief_disjunctions": sum(any(k <= c for k in disj) for c in true_classes),
            "missed": sorted(true_simple - rhw_simple),
        }
    return rows


def exp_ablation() -> dict:
    rows = {}
    for name, make in HAND_WRITTEN.items():
        faithful = Task(run_spec(WORK / "ablation" / f"{name}-faithful", make())["sas"])
        row = {}
        for encoding in ("generic_gates", "fsc"):
            if not (BASELINES / encoding / f"{name}-domain.pddl").exists():
                continue                         # no FSC model for RockSample
            r = run_baseline("ablation", encoding, name)
            keys, _ = graph(r["parsed"])
            unrequired = [k for k in _belief_lms(r["parsed"]) if not faithful.is_landmark(k)]
            structural = [k for k in keys if not any(
                f.split(" ", 1)[1].startswith(("k-", "uncertain-", "committed", "neg-committed",
                                               "confirmed", "done"))
                for f in k)]
            row[encoding] = {**counts(r["parsed"]), "structural": len(structural),
                             "belief_not_required_by_policy": len(unrequired),
                             "examples": sorted(show(k) for k in unrequired)[:4]}
        rows[DISPLAY[name]] = row
    return rows


def exp_induced() -> dict:
    rows = {}
    for name in TRACE_SOURCES:
        spec, report = induce(name)
        ind = run_spec(WORK / "induced" / f"{name}-induced", spec)
        hnd = run_spec(WORK / "induced" / f"{name}-hand", HAND_WRITTEN[name]())
        ki, ei = graph(ind["parsed"])
        kh, eh = graph(hnd["parsed"])
        rows[DISPLAY[name]] = {
            "hand": counts(hnd["parsed"]), "induced": counts(ind["parsed"]),
            "theta_commit": report.theta_commit,
            "coverage": round(report.coverage_fraction(), 3),
            "transitions_induced": report.n_transitions,
            "graded_decrement": report.has_graded_decrement,
            "only_induced": sorted(show(k) for k in ki - kh),
            "only_hand": sorted(show(k) for k in kh - ki),
            "identical": ki == kh and ei == eh,
        }
    return rows


def _with(spec: BSCSpec, **changes) -> BSCSpec:
    fields = dict(name=spec.name, hidden_variables=spec.hidden_variables,
                  observations=spec.observations, transitions=spec.transitions,
                  commit_conditions=spec.commit_conditions)
    fields.update(changes)
    return BSCSpec(**fields)


def _mutants(spec: BSCSpec):
    """Commitment bugs: drop a commit literal, commit blind, over-confident first update."""
    for i, cc in enumerate(spec.commit_conditions):
        for j, lit in enumerate(cc.belief_precs):
            ccs = list(spec.commit_conditions)
            ccs[i] = CommitCondition(cc.variable, cc.commit_value,
                                     cc.belief_precs[:j] + cc.belief_precs[j + 1:])
            yield ("drop-literal",
                   f"commit {cc.variable}={cc.commit_value} without "
                   f"{'k' if lit.polarity == 'pos' else 'k-not'}({lit.value})",
                   _with(spec, commit_conditions=ccs))
    for v in spec.hidden_variables:
        yield ("blind-commit", f"commit {v.name}={v.domain[0]} with no evidence",
               _with(spec, commit_conditions=list(spec.commit_conditions)
                     + [CommitCondition(v.name, v.domain[0], ())]))
    var_dom = {v.name: v.domain for v in spec.hidden_variables}
    for i, t in enumerate(spec.transitions):
        ups = [u for u in t.belief_updates if u.polarity == "pos"]
        if not ups or any(r.holds for r in t.belief_precs):
            continue                             # only first-evidence transitions
        u = ups[0]
        extra = tuple(BeliefUpdate(u.variable, o, "neg") for o in var_dom[u.variable]
                      if o != u.value)
        ts = list(spec.transitions)
        ts[i] = BSCTransition(t.observation, t.belief_precs, t.belief_updates + extra,
                              t.retractions)
        yield ("overconfident-update",
               f"first '{t.observation}' already rules out the alternatives",
               _with(spec, transitions=ts))


def exp_mutation() -> dict:
    rows, cases = {}, []
    for name in ("tiger", "channel", "mine-2x2", "sensor-2"):
        base = HAND_WRITTEN[name]()
        k0, e0 = graph(run_spec(WORK / "mutation" / name / "original", base)["parsed"])
        tally = {"TP": 0, "FP": 0, "FN": 0, "TN": 0}
        for n, (op, what, mutant) in enumerate(_mutants(base)):
            r = run_spec(WORK / "mutation" / name / f"m{n}", mutant)
            task = Task(r["sas"])
            k1, e1 = graph(r["parsed"])
            changed = (any(not task.is_landmark(k) for k in k0)
                       or any(not task.order_holds(*e) for e in e0))
            detected = bool(k0 - k1 or e0 - e1)
            tally[("T" if changed == detected else "F") + ("P" if detected else "N")] += 1
            cases.append({"domain": DISPLAY[name], "operator": op, "mutant": what,
                          "changed": changed, "detected": detected,
                          "lost_landmarks": sorted(show(k) for k in k0 - k1),
                          "lost_orderings": sorted(f"{show(a)} < {show(b)}"
                                                   for a, b in e0 - e1)})
        rows[DISPLAY[name]] = tally
    return {"per_domain": rows, "cases": cases}


def exp_scaling() -> dict:
    rows = {"sensor": [], "mine": []}
    for n in (1, 2, 4, 8, 16, 32, 64, 128):
        spec = domains.sensor_bsc_scaled(n)
        r = run_spec(WORK / "scaling" / f"sensor-{n}", spec)
        rows["sensor"].append({"n": n, "actions": len(spec.transitions)
                               + len(spec.commit_conditions) + 1,
                               **counts(r["parsed"]), "lm_time_s": r["lm_time"],
                               "wall_s": round(r["wall"], 2)})
    for k in (2, 3, 4, 5, 6, 8):
        spec = domains.mine_bsc_scaled(k, k)
        r = run_spec(WORK / "scaling" / f"mine-{k}x{k}", spec)
        disj = [lm for lm in r["parsed"]["landmarks"] if lm["kind"] == "disjunctive"]
        rows["mine"].append({"cells": k * k, "actions": len(spec.transitions)
                             + len(spec.commit_conditions) + 1,
                             **counts(r["parsed"]),
                             "largest_disjunction": max((len(lm["facts"]) for lm in disj),
                                                        default=0),
                             "lm_time_s": r["lm_time"], "wall_s": round(r["wall"], 2)})
    return rows


def _syntactic_baseline(ctrl: dict) -> set:
    """Disjunctions readable from the goal achievers alone (one backchaining step, Prop. 2)."""
    achievers = [s for s, _, _, t, _ in ctrl["edges"] if "terminal" in t]
    achievers += [s for s, _ in ctrl["commits"]]
    found = set()
    for pred in {f.split("(")[0] for s in achievers for f in s if "(" in f}:
        per = [{f for f in s if f.startswith(pred + "(")} for s in achievers]
        if all(per) and not (set().union(*per) & ctrl["init"]):
            found.add(frozenset(f"Atom {f}" for f in set().union(*per)))
    return found


def _ordering_holds(task: Task, a, b, kinds: set) -> bool:
    """Check every reported type: greedy-necessary exactly, natural as natural."""
    return all(task.gn_holds(a, b) if k == "gn" else task.order_holds(a, b) for k in kinds)


def exp_extracted() -> dict:
    """Controllers extracted from SARSOP policy graphs (faithful by construction)."""
    rows = {}
    for path in sorted((HERE / "policy_graphs").glob("*.json")):
        g = extraction.load(path)
        ctrl = extraction.controller(g)
        r = run_fd(WORK / "extracted" / path.stem, *extraction.to_pddl(ctrl, path.stem))
        task = Task(r["sas"])
        keys, edges = graph(r["parsed"])
        init_atoms = {f"Atom {f}" for f in ctrl["init"]}
        nontrivial = [k for k in keys if not k & init_atoms and not any(
            a.startswith("NegatedAtom") for a in k) and "Atom done()" not in k]
        beliefs = [k for k in nontrivial if all(a.startswith("Atom ev-") for a in k)]
        base = _syntactic_baseline(ctrl)
        commits = sorted({show(k) for k in nontrivial if any(
            a.startswith(("Atom sampled(", "Atom chose(")) for a in k)})
        levels = [k for k in beliefs if len({a.split("(")[0] for a in k}) == 1]
        var = lambda k: {a.split("(")[0] for a in k}  # noqa: E731
        cross = [(a, b) for a, b in edges if a in beliefs and b in beliefs and not var(a) & var(b)]
        types = edge_types(r["parsed"])
        ends, steps = extraction.first_hit(g, {n["id"]: 1.0 for n in g["nodes"] if n["kind"] != "inner"})
        t0 = time.perf_counter()
        sound_lms = sum(task.is_landmark(k) for k in keys)
        sound_orders = sum(_ordering_holds(task, a, b, types[(a, b)]) for a, b in edges)
        # every single fact that is a landmark, found or not (a model checker's "A F f" per fact)
        exact = {n for n in task.fact if n.startswith("Atom ") and n not in init_atoms
                 and task.is_landmark([n])}
        exhaustive_s = time.perf_counter() - t0
        rows[path.stem] = {
            "problem": g["problem"], **{k: g[k] for k in ("p_correct", "n", "k", "seed") if k in g},
            "solve_s": round(g["solve_seconds"], 1), "value_b0": round(g["value_at_b0"], 2),
            "exact_value": round(extraction.policy_value(g), 3),
            "policy_nodes": ctrl["policy_nodes"], "policy_edges": ctrl["policy_edges"],
            "controller_states": ctrl["controller_states"],
            **counts(r["parsed"]),
            "belief_landmarks": len(beliefs),
            "belief_landmarks_beyond_syntactic": sum(k not in base for k in beliefs),
            "syntactic_baseline": len(base),
            "commitment_landmarks": commits,
            "evidence_chain": sorted(show(k) for k in levels),
            "injective": ctrl["controller_states"] == ctrl["policy_nodes"],
            "sound_landmarks": sound_lms, "landmarks_total": len(keys),
            "sound_orderings": sound_orders, "orderings_total": len(edges),
            "single_fact_landmarks_exact": len(exact),
            "single_fact_landmarks_missed": sorted(n[5:] for n in exact if frozenset([n]) not in keys),
            "exhaustive_check_s": round(exhaustive_s, 3),
            "cross_variable_orderings": len(cross),
            "cross_variable_examples": sorted(f"{show(a)} < {show(b)}" for a, b in cross)[:6],
            "p_terminate": round(ends, 6),
            "expected_steps": round(steps, 3) if steps is not None else None,
            "p_end_within_100": round(extraction.p_end_within(g, 100), 4),
            "timeline": {show(k): extraction.landmark_timeline(
                g, ctrl, frozenset(a[5:] for a in k)) for k in sorted(beliefs, key=show)},
            "lm_time_s": r["lm_time"],
        }
    return rows


def _names(key) -> frozenset:
    """RHW atom names -> fact names of the exact engine ('Atom done()' -> 'done')."""
    return frozenset(a[5:-2] if a.endswith("()") else a[5:] for a in key)


def _exact_row(g: dict, ctrl: dict, rhw: dict | None = None) -> dict:
    """Exact landmarks/orderings of one controller, their classes, and RHW's recall."""
    sg = StateGraph(ctrl)
    t0 = time.perf_counter()
    lms = sg.landmarks(max_size=3)
    order = sg.orderings(lms)
    exact_s = time.perf_counter() - t0
    nat = {pair for pair, kinds in order.items() if "nat" in kinds}
    pred = lambda k: {f.split("(")[0] for f in k}  # noqa: E731
    belief = [k for k in lms if all(f.startswith("ev-") for f in k)]
    base = {_names(k) for k in _syntactic_baseline(ctrl)}
    moves = [k for k in lms if all(f.startswith("at(") for f in k)]
    commits = [k for k in lms if any(f.startswith(("sampled(", "chose(")) for f in k)]
    chosen = set(belief) | set(moves)
    cross = [(a, b) for a, b in nat if a in chosen and b in chosen and not pred(a) & pred(b)]
    show_ = lambda k: " | ".join(sorted(k))  # noqa: E731
    row = {
        "exact_landmarks": len(lms), "exact_natural": len(nat),
        "exact_gn": sum("gn" in kinds for kinds in order.values()),
        "exact_hasse_edges": len(reduction(nat)),
        "belief_landmarks": len(belief), "baseline": len([k for k in belief if k in base]),
        "belief_beyond_baseline": len([k for k in belief if k not in base]),
        "move_landmarks": len(moves), "commit_landmarks": [show_(k) for k in commits],
        "cross_variable_orderings": len(cross),
        "cross_variable_hasse": sorted(f"{show_(a)} < {show_(b)}" for a, b in reduction(set(cross))),
        "landmarks": sorted(show_(k) for k in lms), "exact_s": round(exact_s, 3),
        "truncated_groups": sorted(sg.truncated),
        "states": len(sg.states),
    }
    if rhw is not None:
        keys, edges = graph(rhw["parsed"])
        initial = sg.facts[0]
        found = {_names(k) for k in keys
                 if all(a.startswith("Atom ") for a in k) and not _names(k) & initial}
        assert all(sg.is_landmark(k) for k in found), "RHW reported a non-landmark"
        rhw_order = closure({(_names(a), _names(b)) for a, b in edges})
        row.update({
            "rhw_landmarks_found": len(found & set(lms)),
            "rhw_nonminimal": sorted(show_(k) for k in found - set(lms)),
            "rhw_missed": sorted(show_(k) for k in set(lms) - found),
            "rhw_natural_found": len(nat & rhw_order),
            "rhw_lm_ms": round(rhw["lm_time"] * 1000, 3),
        })
    return row


def exp_exact() -> dict:
    """Complete landmark graphs by search on the explicit state graph, and RHW's recall."""
    rows = {}
    for path in sorted((HERE / "policy_graphs").glob("*.json")):
        g = extraction.load(path)
        ctrl = extraction.controller(g)
        rhw = run_fd(WORK / "extracted" / path.stem, *extraction.to_pddl(ctrl, path.stem))
        rows[path.stem] = _exact_row(g, ctrl, rhw)
    return rows


BIN_VARIANTS = {"default": (0.5, 2.5, 4.5), "coarse": (1.0, 4.0), "shifted": (1.0, 3.0, 5.0),
                "fine": (0.25, 1.5, 3.0, 4.5)}


def _p_sampled(g: dict, rocks: list) -> dict:
    """Probability that a run samples each rock: hitting probability of the nodes whose
    action is sample on the rock's cell (the node after sampling merges with 'checked bad',
    so it cannot be the target)."""
    ctrl = extraction.controller(g)
    out = {}
    for r in rocks:
        at = "at(c" + next(xy for xy, rr in g["rock_at"].items() if rr == r).replace(",", "-") + ")"
        src = {n["id"]: 1.0 for n in g["nodes"] if n["kind"] == "inner" and n["action"] == extraction.RS_SAMPLE
               and at in ctrl["node_state"][n["id"]]}
        out[r] = round(extraction.first_hit(g, src)[0], 4)
    return out


def exp_bins() -> dict:
    """RockSample: do landmark counts and the rock resolution order survive other bin edges?"""
    rows = {}
    for path in sorted((HERE / "policy_graphs").glob("rocksample-*.json")):
        g = extraction.load(path)
        per = {}
        for name, bins in BIN_VARIANTS.items():
            ctrl = extraction.controller(g, bins)
            row = _exact_row(g, ctrl)
            # each rock's last belief landmark, and when it is first reached
            last = {}
            for lm in row["landmarks"]:
                facts = frozenset(lm.split(" | "))
                rock = next(iter(facts)).split("(")[0]
                if rock.startswith("ev-") and len({f.split("(")[0] for f in facts}) == 1:
                    t = extraction.landmark_timeline(g, ctrl, facts)["expected_steps"]
                    if t is not None and t > last.get(rock, (-1, ""))[0]:
                        last[rock] = (t, lm)
            per[name] = {"controller_states": ctrl["controller_states"],
                         "injective": ctrl["controller_states"] == ctrl["policy_nodes"],
                         "landmarks": row["exact_landmarks"],
                         "cross_variable_orderings": row["cross_variable_orderings"],
                         "resolution_order": [r[3:] for r, _ in sorted(last.items(), key=lambda kv: kv[1][0])]}
        ref = per["default"]["resolution_order"]
        per["p_sampled"] = _p_sampled(g, ref)               # settled rocks: by sampling vs by checks
        for k, v in per.items():
            if k != "p_sampled":
                v["same_order_as_default"] = v["resolution_order"] == ref
        rows[path.stem] = per
    return rows


def interpretable(lm: str) -> bool:
    """Single facts, belief disjunctions of one strength or one direction, and
    commitment disjunctions. Leaves out mixed-level and route disjunctions, which
    are minimal but restate the evidence chain or list alternative routes."""
    facts = lm.split(" | ")
    if len(facts) == 1:
        return True
    if all(f.startswith("chose(") for f in facts):
        return True
    if all(f.startswith("ev-") for f in facts):
        levels = [f.split("(")[1][:-1] for f in facts]
        return "unk" not in levels and (len({x[3:] for x in levels}) == 1
                                        or len({x[:3] for x in levels}) == 1)
    return False


def _graph_summary(g: dict) -> dict:
    """Exact interpretable landmarks/orderings of one policy graph, plus behaviour numbers."""
    ctrl = extraction.controller(g)
    sg = StateGraph(ctrl)
    if 0 not in sg.alive:                        # no run ends: landmarks would hold vacuously
        return {"nodes": len(g["nodes"]), "landmarks": None, "orderings": None, "terminates": False,
                "value": round(extraction.policy_value(g), 3), "p_end_within_100": 0.0,
                "actions": sorted({n["action"] for n in g["nodes"] if n["action"] not in (None, "nothing")})}
    lms = [k for k in sg.landmarks(max_size=3) if interpretable(" | ".join(sorted(k)))]
    nat = {(a, b) for (a, b), kinds in sg.orderings(lms).items() if "nat" in kinds}
    show_ = lambda k: " | ".join(sorted(k))  # noqa: E731
    ends, steps = extraction.first_hit(g, {n["id"]: 1.0 for n in g["nodes"] if n["kind"] != "inner"})
    return {"nodes": len(g["nodes"]), "terminates": True, "landmarks": sorted(show_(k) for k in lms),
            "orderings": sorted(f"{show_(a)} < {show_(b)}" for a, b in reduction(nat)),
            "value": round(extraction.policy_value(g), 3),
            "p_end_within_100": round(extraction.p_end_within(g, 100), 4),
            "actions": sorted({n["action"] for n in g["nodes"] if n["action"] not in (None, "nothing")})}


def _resolution_order(g: dict) -> list:
    """Hidden variables sorted by when the policy first reaches its last belief landmark."""
    ctrl = extraction.controller(g)
    lms = [k for k in StateGraph(ctrl).landmarks(max_size=1)
           if all(f.startswith("ev-") for f in k) and len({f.split("(")[0] for f in k}) == 1]
    last: dict = {}
    for k in lms:
        t = extraction.landmark_timeline(g, ctrl, frozenset(k))["expected_steps"]
        var = next(iter(k)).split("(")[0][3:]
        if t is not None and t > last.get(var, -1.0):
            last[var] = t
    return [v for v, _ in sorted(last.items(), key=lambda kv: kv[1])]


def _pairs_agree(a: list, b: list) -> tuple:
    """(variable pairs ordered the same way, pairs ordered in both lists)."""
    common = [v for v in a if v in b]
    pairs = [(x, y) for i, x in enumerate(common) for y in common[i + 1:]]
    return sum(b.index(x) < b.index(y) for x, y in pairs), len(pairs)


def exp_pbvi() -> dict:
    """SARSOP vs PBVI (a second point-based solver) on the same models."""
    return _compare_solvers("pbvi", order=True)


def exp_qmdp() -> dict:
    """SARSOP vs QMDP policies of the same models: what changes in the landmark graph."""
    return _compare_solvers("qmdp")


def _compare_solvers(folder: str, order: bool = False) -> dict:
    rows = {}
    for path in sorted((HERE / "policy_graphs" / folder).glob("*.json")):
        q = extraction.load(path)
        if "error" in q:
            rows[path.stem] = {"error": q["error"]}
            continue
        s = extraction.load(HERE / "policy_graphs" / path.name)
        a, b = _graph_summary(s), _graph_summary(q)
        rows[path.stem] = {
            "sarsop": a, "other": b,
            "only_sarsop": sorted(set(a["landmarks"]) - set(b["landmarks"] or [])),
            "only_other": sorted(set(b["landmarks"] or []) - set(a["landmarks"])),
            "same_graph": a["landmarks"] == b["landmarks"] and a["orderings"] == b["orderings"],
            "merges": q.get("merges")}
        if order and q["problem"] == "rocksample" and b["terminates"]:
            ra, rb = _resolution_order(s), _resolution_order(q)
            agree, total = _pairs_agree(ra, rb)
            rows[path.stem].update({"order_sarsop": ra, "order_other": rb,
                                    "order_pairs_agree": agree, "order_pairs": total})
    return rows


def _abstract_reach(g: dict) -> tuple:
    """Two landmark-free references for the mutant study: the abstract states reached with
    positive probability, and those visited on every run that ends (None if no run ends)."""
    c = extraction.controller(g)
    succ: dict = {}
    for s, _, _, t, _ in c["edges"]:
        succ.setdefault(s, set()).add(t)
    ends = {c["node_state"][n["id"]] for n in g["nodes"] if n["kind"] != "inner"}

    def reach(removed=None):
        if c["init"] == removed:
            return set()
        seen, todo = {c["init"]}, [c["init"]]
        while todo:
            for t in succ.get(todo.pop(), ()):
                if t != removed and t not in seen:
                    seen.add(t)
                    todo.append(t)
        return seen

    support = reach()
    sure = frozenset(s for s in support if not reach(s) & ends) if support & ends else None
    return frozenset(support), sure


def exp_mutants() -> dict:
    """Single-action mutants: does the landmark graph change when behaviour changes?"""
    rows = {}
    folder = HERE / "policy_graphs" / "mutants"
    for base_path in sorted(folder.glob("*-base.json")):
        name = base_path.stem[:-5]
        base = _graph_summary(extraction.load(base_path))
        base_reach = _abstract_reach(extraction.load(base_path))
        per = []
        for path in sorted(folder.glob(f"{name}-m*.json")):
            m = extraction.load(path)
            if "error" in m:
                per.append({"mutant": path.stem, "error": m["error"], **m.get("mutation", {})})
                continue
            x = _graph_summary(m)
            p_term, _ = extraction.first_hit(m, {n["id"]: 1.0 for n in m["nodes"] if n["kind"] != "inner"})
            lm_changed = x["terminates"] and (x["landmarks"] != base["landmarks"]
                                              or x["orderings"] != base["orderings"])
            category = ("lm" if lm_changed else "end" if p_term < 1 - 1e-9
                        else "cost" if abs(x["value"] - base["value"]) > 1e-6 else "same")
            per.append({"mutant": path.stem, **m.get("mutation", {}), "category": category,
                        "p_terminate": round(p_term, 6),
                        "graph_changed": x["nodes"] != base["nodes"] or x["actions"] != base["actions"]
                                         or x["value"] != base["value"],
                        "value_change": round(x["value"] - base["value"], 3),
                        "terminates": x["terminates"],
                        "landmarks_lost": sorted(set(base["landmarks"]) - set(x["landmarks"] or [])),
                        "landmarks_gained": sorted(set(x["landmarks"] or []) - set(base["landmarks"])),
                        "orderings_changed": x["orderings"] != base["orderings"],
                        "p_end_within_100": x["p_end_within_100"],
                        "support_changed": _abstract_reach(m)[0] != base_reach[0],
                        "sure_states_changed": _abstract_reach(m)[1] != base_reach[1]})
        cats = [m.get("category", "error") for m in per]
        rows[name] = {"base": base, "mutants": per,
                      "summary": {c: cats.count(c) for c in ("lm", "end", "cost", "same", "error")},
                      "support_changed": sum(bool(m.get("support_changed")) for m in per),
                      "sure_states_changed": sum(bool(m.get("sure_states_changed")) for m in per),
                      "lm_and_some_runs_never_end": sum(m.get("category") == "lm" and m["p_terminate"] < 1 - 1e-9
                                                        for m in per)}
    return rows


def exp_kept() -> dict:
    """Table 1: exact landmarks in the kept classes, ordering-diagram edges, cross-variable
    orderings, RHW's share of the kept landmarks, termination, and timings."""
    exact = json.loads((RESULTS / "exact.json").read_text())
    rows = {}
    for path in sorted((HERE / "policy_graphs").glob("*.json")):
        g = extraction.load(path)
        ctrl = extraction.controller(g)
        sg = StateGraph(ctrl)
        t0 = time.perf_counter()
        lms = [k for k in sg.landmarks() if interpretable(" | ".join(sorted(k)))]
        nat = {pair for pair, kinds in sg.orderings(lms).items() if "nat" in kinds}
        seconds = time.perf_counter() - t0
        pred = lambda k: {f.split("(")[0] for f in k}  # noqa: E731
        choice = [k for k in lms if all(f.startswith(("ev-", "at(")) for f in k)]
        cross = {(a, b) for a, b in nat if a in choice and b in choice and not pred(a) & pred(b)}
        missed = set(exact[path.stem]["rhw_missed"])
        p_term, steps = extraction.first_hit(g, {n["id"]: 1.0 for n in g["nodes"] if n["kind"] != "inner"})
        rows[path.stem] = {"landmarks": len(lms), "rhw": sum(" | ".join(sorted(k)) not in missed for k in lms),
                           "diagram_edges": len(reduction(nat)), "natural": len(nat),
                           "cross_variable": len(cross), "p_terminate": round(p_term, 6),
                           "p_end_within_100": round(extraction.p_end_within(g, 100), 4),
                           "exact_kept_s": round(seconds, 3), "exact_all_s": exact[path.stem]["exact_s"],
                           "rhw_ms": exact[path.stem]["rhw_lm_ms"]}
    return rows


def exp_large() -> dict:
    """Larger RockSample models (policy_graphs/large): the cost follows the policy graph,
    not the state space."""
    rows = {}
    for path in sorted((HERE / "policy_graphs" / "large").glob("*.json")):
        g = extraction.load(path)
        if "error" in g:
            rows[path.stem] = {"error": g["error"]}
            continue
        ctrl = extraction.controller(g)
        sg = StateGraph(ctrl)
        t0 = time.perf_counter()
        lms = [k for k in sg.landmarks() if interpretable(" | ".join(sorted(k)))]
        nat = {pair for pair, kinds in sg.orderings(lms).items() if "nat" in kinds}
        seconds = time.perf_counter() - t0
        pred = lambda k: {f.split("(")[0] for f in k}  # noqa: E731
        choice = [k for k in lms if all(f.startswith(("ev-", "at(")) for f in k)]
        cross = {(a, b) for a, b in nat if a in choice and b in choice and not pred(a) & pred(b)}
        rhw = run_fd(WORK / "large" / path.stem, *extraction.to_pddl(ctrl, path.stem))
        keys, _ = graph(rhw["parsed"])
        found = {_names(k) for k in keys if all(a.startswith("Atom ") for a in k)}
        p_term, steps = extraction.first_hit(g, {n["id"]: 1.0 for n in g["nodes"] if n["kind"] != "inner"})
        rows[path.stem] = {
            "states": len(g["states"]), "solve_s": round(g["solve_seconds"], 1),
            "policy_nodes": ctrl["policy_nodes"], "controller_states": ctrl["controller_states"],
            "merges": g.get("merges"), "value_b0": round(g["value_at_b0"], 3),
            "exact_value": round(extraction.policy_value(g), 3),
            "p_terminate": round(p_term, 6), "expected_steps": None if steps is None else round(steps, 2),
            "landmarks": len(lms), "rhw": sum(k in found for k in lms),
            "diagram_edges": len(reduction(nat)), "cross_variable": len(cross),
            "resolution_order": _resolution_order(g), "truncated_groups": sorted(sg.truncated),
            "exact_kept_s": round(seconds, 3), "rhw_ms": round(rhw["lm_time"] * 1000, 3),
            "rhw_wall_s": round(rhw["wall"], 2)}
    return rows


def exp_variants() -> dict:
    """Same model, other SARSOP settings (discount 0.90/0.99 for solving, 10 s/30 s time
    limits): policies with nearly the same value (under the paper's discount 0.95) but
    different landmark graphs."""
    rows = {}
    for base in sorted((HERE / "policy_graphs").glob("rocksample-[45]-*.json")):
        pols = {"base": base} | {p.stem.split("-")[-1]: p for p in
                                 sorted((HERE / "policy_graphs" / "variants").glob(base.stem + "-*.json"))}
        info = {}
        for name, path in pols.items():
            g = extraction.load(path)
            if "error" in g:
                continue
            summ = _graph_summary(g)
            info[name] = {"value": summ["value"], "terminates": summ["terminates"],
                          "landmarks": summ["landmarks"], "orderings": summ["orderings"],
                          "order": _resolution_order(g) if summ["terminates"] else None,
                          "nodes": summ["nodes"], "lossy": (g.get("merges") or {}).get("lossy")}
        pairs = []
        names = sorted(info)
        for i, a in enumerate(names):
            for b in names[i + 1:]:
                va, vb = info[a]["value"], info[b]["value"]
                if not (info[a]["terminates"] and info[b]["terminates"]):
                    continue
                pairs.append({"a": a, "b": b, "value_gap_pct": round(100 * abs(va - vb) / max(abs(va), abs(vb)), 2),
                              "same_landmarks": info[a]["landmarks"] == info[b]["landmarks"],
                              "same_orderings": info[a]["orderings"] == info[b]["orderings"],
                              "same_order": info[a]["order"] == info[b]["order"],
                              "only_a": sorted(set(info[a]["landmarks"]) - set(info[b]["landmarks"])),
                              "only_b": sorted(set(info[b]["landmarks"]) - set(info[a]["landmarks"]))})
        rows[base.stem] = {"policies": info, "pairs": pairs}
    return rows


def exp_monitor() -> dict:
    """Runtime monitoring: flag a run when a landmark of the nominal policy is not yet
    reached later than in 99% of nominal runs. Thresholds come from half of the nominal
    runs; false alarms are measured on the other half."""
    rows = {}
    folder = HERE / "monitor"
    for seed in sorted({p.stem.split("-")[1] for p in folder.glob("rs44-*.jsonl")}):
        g = extraction.load(HERE / "policy_graphs" / f"rocksample-4-4-{seed}.json")
        ctrl = extraction.controller(g)
        lms = [k for k in StateGraph(ctrl).landmarks(max_size=1)
               if interpretable(" | ".join(sorted(k))) and all(f.startswith(("ev-", "at(")) for f in k)]

        def runs(eff):
            out = []
            for line in (folder / f"rs44-{seed}-eff{eff}.jsonl").read_text().splitlines():
                e = json.loads(line)
                facts = [extraction.abstract(g, {int(i): float(x) for i, x in
                                                 (t.split(":") for t in st["b"].split())})
                         for st in e["steps"]]
                first = {k: next((t for t, f in enumerate(facts) if f & k), None) for k in lms}
                out.append({"first": first, "len": len(facts), "ended": e["ended"], "ret": e["return"]})
            return out

        nominal = runs(20)
        calib, test = nominal[::2], nominal[1::2]
        q99 = lambda xs: sorted(xs)[min(len(xs) - 1, int(0.99 * len(xs)))]  # noqa: E731
        tau = {k: q99([r["first"][k] if r["first"][k] is not None else r["len"] for r in calib]) for k in lms}
        tau_len = q99([r["len"] for r in calib])

        def flags(r):
            lm = [max(tau[k] + 1, 0) for k in lms if (r["first"][k] if r["first"][k] is not None else 10**9) > tau[k]]
            lm_t = min(lm) if lm else None                    # step at which a landmark is overdue
            first_lm = min((k for k in lms if (r["first"][k] if r["first"][k] is not None else 10**9) > tau[k]),
                           key=lambda k: tau[k], default=None)
            len_t = tau_len + 1 if r["len"] > tau_len else None
            return lm_t, len_t, first_lm

        per = {}
        for eff, data in (("20 (held-out)", test), *((e, runs(e)) for e in (10, 5, 2))):
            fl = [flags(r) for r in data]
            hit = [f for f in fl if f[0] is not None]
            per[str(eff)] = {
                "runs": len(data), "mean_return": round(sum(r["ret"] for r in data) / len(data), 3),
                "ended": sum(r["ended"] for r in data),
                "flagged_by_landmarks": len(hit),
                "flagged_by_length": sum(f[1] is not None for f in fl),
                "median_flag_step": sorted(f[0] for f in hit)[len(hit) // 2] if hit else None,
                "median_length_flag_step": tau_len + 1,
                "landmark_flagged_first_by_count": dict(sorted(
                    __import__("collections").Counter(" | ".join(sorted(f[2])) for f in hit).items(),
                    key=lambda kv: -kv[1])[:5])}
        rows[seed] = {"landmarks": len(lms), "tau_len": tau_len, "worlds": per}
    return rows


def _confidence_before_acting(g: dict, var: str, tol: float = 1e-4) -> float | None:
    """Largest c such that every run that ends first believes `var` or its negation
    with probability >= c ("knows" it in the knowledge view with eps = 1 - c).
    Bisection on eps; a K-or-Knot landmark only gets easier as eps grows."""
    def known(eps):
        sg = StateGraph(extraction.controller(g, eps=eps))
        return 0 in sg.alive and sg.is_landmark([f"kn-{var}(K)", f"kn-{var}(Knot)"])
    lo, hi = 0.0, 0.5                             # eps; at 0.5 every belief is "known"
    if not known(hi - 1e-9):
        return None
    while hi - lo > tol:
        mid = (lo + hi) / 2
        lo, hi = (lo, mid) if known(mid) else (mid, hi)
    return round(1 - hi, 4)


def exp_knowledge() -> dict:
    """Knowledge view (eps = 0.05) landmarks, and the confidence each policy always
    reaches about each hidden variable before the episode ends."""
    rows = {}
    for path in sorted((HERE / "policy_graphs").glob("*.json")):
        g = extraction.load(path)
        sg = StateGraph(extraction.controller(g, eps=0.05))
        if 0 not in sg.alive:
            rows[path.stem] = {"terminates": False}
            continue
        lms = [k for k in sg.landmarks(max_size=1)
               if all(f.startswith(("kn-", "chose", "at(")) for f in k) and not any(f.endswith("(U)") for f in k)]
        nat = {pair for pair, kinds in sg.orderings(lms).items() if "nat" in kinds}
        show_ = lambda k: " | ".join(sorted(k))  # noqa: E731
        conf = {v: _confidence_before_acting(g, v) for v in extraction.hidden_vars(g)}
        rows[path.stem] = {"landmarks": sorted(show_(k) for k in lms),
                           "orderings": sorted(f"{show_(a)} < {show_(b)}" for a, b in reduction(nat)),
                           "confidence_before_acting": conf,
                           "min_confidence": min((c for c in conf.values() if c is not None), default=None)}
    return rows


def exp_sampling() -> dict:
    """R1: landmarks from N sampled runs vs the exact graph (single facts and
    same-predicate pairs). True landmarks always survive; we count the
    non-landmarks that survive by chance, and compare with the exact survival
    probability (1 - q)^N, q = P(a run that ends avoids F)."""
    import random as _random
    from policy_landmarks import sampling
    sizes, reps = (5, 10, 20, 50, 100, 300), 10
    rows = {}
    paths = sorted((HERE / "policy_graphs").glob("*.json")) + [HERE / "policy_graphs" / "large" / "tag.json"]
    for path in paths:
        g = extraction.load(path)
        ctrl = extraction.controller(g)
        sg = StateGraph(ctrl)
        if 0 not in sg.alive:
            continue
        exact = set(sg.landmarks(max_size=2, complete=()))
        initial = sg.facts[0]
        p_term = extraction.first_hit(g, {n["id"]: 1.0 for n in g["nodes"] if n["kind"] != "inner"})[0]
        rng = _random.Random(1)
        per = {}
        worst = {}
        for n_runs in sizes:
            fp, exact_hits = [], 0
            for _ in range(reps):
                runs = []
                while len(runs) < n_runs:
                    r = sampling.run_facts(g, ctrl, rng)
                    if r is not None:
                        runs.append(r)
                emp = sampling.empirical_landmarks(runs, initial)
                false = emp - exact
                fp.append(len(false))
                exact_hits += emp == exact
                for f in false:
                    worst[f] = worst.get(f, 0) + 1
            per[str(n_runs)] = {"mean_false": round(sum(fp) / reps, 2), "max_false": max(fp),
                                "share_exact": exact_hits / reps}
        # survival bound for the most persistent false landmarks
        top = sorted(worst.items(), key=lambda kv: -kv[1])[:3]
        bound = []
        for key, count in top:
            avoid = sampling.avoid_probability(g, ctrl, key)
            q = None if avoid is None else avoid / p_term
            bound.append({"landmark": " | ".join(sorted(key)), "times_survived": count,
                          "q_avoid": None if q is None else round(q, 6),
                          "runs_for_1pct": None if not q or q >= 1 else
                          __import__("math").ceil(__import__("math").log(0.01) / __import__("math").log(1 - q))})
        rows[path.stem] = {"exact_landmarks": len(exact), "p_terminate": round(p_term, 4),
                           "by_runs": per, "most_persistent_false": bound}
    return rows


def _kept_symbolic(ctrl: dict) -> set:
    """Kept-class landmarks of a controller, ignoring the cell-identity facts cx-V(i)."""
    return {" | ".join(sorted(k)) for k in StateGraph(ctrl).landmarks()
            if not any(f.startswith("cx-") for f in k) and interpretable(" | ".join(sorted(k)))}


def exp_symbolic() -> dict:
    """R3: landmarks from the alpha-vectors alone (no belief enumeration), refined by
    halving cells, compared with the exact landmarks of the enumerated policy graph.
    Sound means every symbolic landmark is a landmark of the exact graph."""
    from policy_landmarks import symbolic as sy
    rows = {}
    for f in sorted((HERE / "policy_graphs" / "alphas").glob("*.alphas.json")):
        name = f.name.replace(".alphas.json", "")
        g = extraction.load(HERE / "policy_graphs" / f"{name}.json")
        if g["problem"] == "probe":
            continue                                         # see exp_symbolic_categorical
        model = sy.Model(g, json.loads(f.read_text()))
        exact_ctrl = extraction.controller(g)
        exact_sg = StateGraph(exact_ctrl)
        exact = _kept_symbolic(exact_ctrl)
        levels = []
        for h in range(5 if model.u else 3):
            grid = sy.unit_grid(model, h) if model.u else sy.bin_grid(model, h)
            t0 = time.perf_counter()
            ctrl = sy.abstract_controller(model, grid)
            found = _kept_symbolic(ctrl)
            levels.append({"halvings": h, "abstract_states": ctrl["abstract_states"],
                           "mixed_states": ctrl["mixed_states"], "found": len(found),
                           "sound": all(exact_sg.is_landmark(lm.split(" | ")) for lm in found),
                           "equal": found == exact, "seconds": round(time.perf_counter() - t0, 2)})
            if found == exact:
                break
        rows[name] = {"policy_nodes": len(g["nodes"]), "exact_landmarks": len(exact),
                      "alphas": len(model.A), "refinement": levels}
    return rows


def exp_symbolic_categorical() -> dict:
    """R3 on one categorical variable (Channel, Mine): coordinates are log-weights, so a
    cell fixes the net hits on each value. Facts here mean net evidence, not the exact
    graph's marginal levels, so we compare what both can state exactly: which values
    the policy may commit to, and whether committing is a landmark."""
    from policy_landmarks import symbolic as sy
    rows = {}
    for name in ("channel-3-0.85", "mine-4-0.85", "mine-9-0.85"):
        f = HERE / "policy_graphs" / "alphas" / f"{name}.alphas.json"
        g = extraction.load(HERE / "policy_graphs" / f"{name}.json")
        model = sy.Model(g, json.loads(f.read_text()))
        exact = StateGraph(extraction.controller(g))
        exact_commit = sorted(" | ".join(sorted(k)) for k in exact.landmarks()
                              if any(x.startswith("chose") for x in k))
        t0 = time.perf_counter()
        try:
            # lattice model: exact at lattice points inside the window, tails summarize the rest
            ctrl = sy.abstract_controller(model, sy.unit_grid(model, 0, levels=6), max_states=200_000,
                                          points=True)
        except RuntimeError as e:
            rows[name] = {"error": str(e), "seconds": round(time.perf_counter() - t0, 1)}
            continue
        sg = StateGraph(ctrl)
        ends = 0 in sg.alive
        commit = (sorted(" | ".join(sorted(k)) for k in sg.landmarks(max_size=1, complete=("chose",))
                         if any(x.startswith("chose") for x in k)) if ends else None)
        rows[name] = {"abstract_states": ctrl["abstract_states"], "mixed_states": ctrl["mixed_states"],
                      "commit_actions": sorted({a for _, a in ctrl["commits"]}),
                      "commit_landmarks": commit, "exact_commit_landmarks": exact_commit,
                      "graph_lossy_merges": (g.get("merges") or {}).get("lossy"),
                      "seconds": round(time.perf_counter() - t0, 1)}
    return rows


def exp_cegar(names=("rocksample-4-4-s5", "rocksample-4-4-s3", "rocksample-4-4-s1"),
              context: str = "coarse", folder: str = "alphas") -> dict:
    """R3c: verify every candidate belief landmark (single levels and kept-class pairs
    per rock) with counterexample-guided refinement, and compare with the exact graph.
    context="any" starts the other variables unconstrained (rule count linear in rocks)."""
    from policy_landmarks import cegar, symbolic as sy
    levels = ["neg3", "neg2", "neg1", "unk", "pos1", "pos2", "pos3"]     # bin grid cells 0..6
    pairs = [("neg2", "neg3"), ("pos2", "pos3"), ("neg1", "pos1"), ("neg2", "pos2"), ("neg3", "pos3")]
    rows = {}
    for name in names:
        g = extraction.load(HERE / "policy_graphs" / folder / f"{name}.json")
        m = sy.Model(g, json.loads((HERE / "policy_graphs" / folder / f"{name}.alphas.json").read_text()))
        grid, edges = sy.bin_grid(m, 0), (-4.5, 4.5)
        span = dict(zip(levels, zip(grid.edges[0], grid.edges[0][1:])))   # before any split
        positions = [(i, j) for i in range(1, m.n + 1) for j in range(1, m.n + 1)]
        exact = StateGraph(extraction.controller(g))
        t0 = time.perf_counter()
        rules = cegar.initial_rules(m, grid, positions, edges, context)
        n0 = len(rules)
        results = []
        for v, var in enumerate(m.vars):
            cands = [(lv,) for lv in levels if lv != "unk"] + pairs
            for cand in cands:
                facts = [f"ev-{var}({lv})" for lv in cand]
                truth = exact.is_landmark(facts)
                t = time.perf_counter()
                res = cegar.verify(m, grid, rules, {v: [span[lv] for lv in cand]}, WORK / f"cegar-{context}" / name,
                                   edges, max_iter=400)
                results.append({"candidate": " | ".join(facts), "exact": truth, "proven": res["landmark"],
                                "certified_counterexample": res.get("certified"), "reason": res.get("reason"),
                                "iterations": res["iterations"], "seconds": round(time.perf_counter() - t, 1)})
        proven = [r for r in results if r["proven"]]
        rows[name] = {"candidates": len(results), "exact_landmarks": sum(r["exact"] for r in results),
                      "proven": len(proven), "unsound": sum(not r["exact"] for r in proven),
                      "recall": f"{sum(r['exact'] for r in proven)}/{sum(r['exact'] for r in results)}",
                      "undecided": sum(r["proven"] is None for r in results),
                      "refuted_certified": sum(bool(r["certified_counterexample"]) for r in results),
                      "refuted_uncertified": sum(r["proven"] is False and not r["certified_counterexample"]
                                                 for r in results),
                      "context": context, "rules_initial": n0, "rules_final": len(rules),
                      "cells_final": [len(e) - 1 for e in grid.edges],
                      "seconds": round(time.perf_counter() - t0, 1), "results": results}
    return rows


def exp_cegar_region(names=("rocksample-4-4-s5", "rocksample-4-4-s3", "rocksample-4-4-s1"),
                     regions=((0.0, 0.0), (-0.5, 0.5), (-2.5, 2.5)), samples: int = 50,
                     folder: str = "alphas", time_limit: float | None = None) -> dict:
    """Prior-robust landmarks: CEGAR proves a candidate for every product prior whose
    per-rock log-odds lie in the region (a point = one prior). Ground truth: exact belief
    graphs built from the alpha vectors at the centre, the corners of the region (where
    random samples rarely land) and `samples` random priors; a proof refuted by any of them
    would be unsound. Certified refutations carry a witness prior, checked on its own
    graph; "relative_holds_at_witness" says whether the candidate holds there when levels
    are taken relative to the prior, i.e. whether only the absolute binning (bin skipping)
    refutes it. "minimal" marks proofs not implied by a proven single level."""
    import itertools
    import random
    from policy_landmarks import cegar, symbolic as sy
    levels = ["neg3", "neg2", "neg1", "unk", "pos1", "pos2", "pos3"]     # bin grid cells 0..6
    pairs = [("neg2", "neg3"), ("pos2", "pos3"), ("neg1", "pos1"), ("neg2", "pos2"), ("neg3", "pos3")]
    rows = {}
    for name in names:
        g = extraction.load(HERE / "policy_graphs" / folder / f"{name}.json")
        m = sy.Model(g, json.loads((HERE / "policy_graphs" / folder / f"{name}.alphas.json").read_text()))
        k = len(m.vars)
        for lo, hi in regions:
            grid, edges = sy.bin_grid(m, 0), (-4.5, 4.5)
            span = dict(zip(levels, zip(grid.edges[0], grid.edges[0][1:])))   # before any split
            positions = ([(i, j) for i in range(1, m.n + 1) for j in range(1, m.n + 1)]
                         if m.start() is not None else [None])
            rng = random.Random(0)
            corners = [list(c) for c in itertools.product((lo, hi), repeat=k)] if lo < hi else []
            priors = [[(lo + hi) / 2] * k] + corners + (
                [[rng.uniform(lo, hi) for _ in range(k)] for _ in range(samples)] if lo < hi else [])
            graphs = [cegar.exact_graph(m, pr) for pr in priors]
            t0 = time.perf_counter()
            rules = cegar.initial_rules(m, grid, positions, edges, "any")
            region = {v: (lo, hi) for v in range(k)}
            results = []
            for v, var in enumerate(m.vars):
                for cand in [(lv,) for lv in levels if lv != "unk"] + pairs:
                    ranges = [span[lv] for lv in cand]
                    holds = [cegar.exact_landmark(st, su, v, ranges) for st, su in graphs]
                    res = cegar.verify(m, grid, rules, {v: ranges}, WORK / "cegar-region" / name, edges,
                                       max_iter=400, region=region, time_limit=time_limit)
                    w = res.get("witness")
                    wg = cegar.exact_graph(m, w) if w is not None else None
                    results.append({"candidate": " | ".join(f"ev-{var}({lv})" for lv in cand),
                                    "var": v, "levels": list(cand),
                                    "proven": res["landmark"], "certified": res.get("certified"),
                                    "witness": w, "reason": res.get("reason"), "iterations": res["iterations"],
                                    "holds_at_centre": holds[0], "holds_at_all_samples": all(holds),
                                    "holds_at_corners": all(holds[1:1 + len(corners)]),
                                    "witness_confirmed": None if w is None else not cegar.exact_landmark(*wg, v, ranges),
                                    "relative_holds_at_witness": None if w is None else cegar.exact_landmark(
                                        *wg, v, [(a + w[v], b + w[v]) for a, b in ranges])})
            proven_single = {(r["var"], r["levels"][0]) for r in results if r["proven"] is True and len(r["levels"]) == 1}
            for r in results:
                r["minimal"] = r["proven"] is True and (
                    len(r["levels"]) == 1 or not any((r["var"], lv) in proven_single for lv in r["levels"]))
            rows[f"{name} [{lo}, {hi}]"] = {
                "candidates": len(results), "priors_sampled": len(priors),
                "proven": sum(r["proven"] is True for r in results),
                "unsound": sum(r["proven"] is True and not r["holds_at_all_samples"] for r in results),
                "refuted_certified": sum(bool(r["certified"]) for r in results),
                "witness_confirmed": sum(bool(r["witness_confirmed"]) for r in results),
                "undecided": sum(r["proven"] is None for r in results),
                "hold_at_all_samples": sum(r["holds_at_all_samples"] for r in results),
                "hold_at_centre": sum(r["holds_at_centre"] for r in results),
                "proven_minimal": sum(r["minimal"] for r in results),
                "refuted_bin_skipping": sum(bool(r["certified"]) and bool(r["relative_holds_at_witness"]) for r in results),
                "corners": len(corners),
                "rules_initial": len(cegar.initial_rules(m, sy.bin_grid(m, 0), positions, edges, "any")),
                "rules_final": len(rules), "cells_final": [len(e) - 1 for e in grid.edges],
                "seconds": round(time.perf_counter() - t0, 1), "results": results}
    return rows


EXPERIMENTS = {"main": exp_main, "exactness": exp_exactness, "ablation": exp_ablation,
               "induced": exp_induced, "mutation": exp_mutation, "scaling": exp_scaling,
               "extracted": exp_extracted, "exact": exp_exact, "bins": exp_bins,
               "qmdp": exp_qmdp, "pbvi": exp_pbvi, "mutants": exp_mutants, "kept": exp_kept,
               "large": exp_large, "variants": exp_variants, "monitor": exp_monitor,
               "knowledge": exp_knowledge, "sampling": exp_sampling,
               "symbolic": exp_symbolic, "symbolic_categorical": exp_symbolic_categorical,
               "cegar": exp_cegar, "cegar_region": exp_cegar_region}


def main(argv: list) -> int:
    unknown = set(argv) - set(EXPERIMENTS)
    if unknown:
        print(f"unknown experiment(s): {sorted(unknown)}; choose from {list(EXPERIMENTS)}")
        return 2
    RESULTS.mkdir(parents=True, exist_ok=True)
    for name in argv or list(EXPERIMENTS):
        t0 = time.perf_counter()
        result = EXPERIMENTS[name]()
        (RESULTS / f"{name}.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
        print(f"[OK] {name} ({time.perf_counter() - t0:.0f}s) -> {RESULTS / (name + '.json')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

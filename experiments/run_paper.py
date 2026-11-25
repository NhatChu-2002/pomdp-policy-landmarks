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
        for v in per.values():
            v["same_order_as_default"] = v["resolution_order"] == ref
        rows[path.stem] = per
    return rows


EXPERIMENTS = {"main": exp_main, "exactness": exp_exactness, "ablation": exp_ablation,
               "induced": exp_induced, "mutation": exp_mutation, "scaling": exp_scaling,
               "extracted": exp_extracted, "exact": exp_exact, "bins": exp_bins}


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

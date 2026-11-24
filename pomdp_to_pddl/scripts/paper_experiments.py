#!/usr/bin/env python3
"""Reproduce every experiment reported in the paper.

    python paper_experiments.py                      # all experiments
    python paper_experiments.py main exactness       # a subset

Experiments
  main        landmarks, orderings, solvability for the six benchmark BSCs
  exactness   RHW landmarks/orderings vs. exhaustive ground truth (state-space search)
  ablation    FSC encoding and generic-gate BSC encoding vs. policy-faithful encoding
  induced     hand-written BSCs vs. BSCs induced from SARSOP belief traces
  mutation    fault injection: do landmark diffs flag commitment bugs?
  scaling     #hidden variables (Sensor-n) and cardinality (Mine-kxk)

Outputs: landmark_experiments/results/paper/{<experiment>.json, summary.md}.
Needs the project Fast Downward build (builds/release64): its landmark factory
dumps the landmark graph and exits before search, and its RHW disjunction cap
is raised from 4 to 64 facts (src/search/landmarks/landmark_factory_rpg_sasp.cc).
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import time
from collections import deque
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[1]
sys.path.insert(0, str(REPO / "scripts"))

from parse_landmarks import parse_landmark_text  # noqa: E402

import domains as fsc_domains  # noqa: E402
import domains_bsc  # noqa: E402
import encoder as fsc_encoder  # noqa: E402
from bsc_induction import (  # noqa: E402
    induce_binary_bsc, parse_rocksample, parse_sensor, parse_tiger,
)
from bsc_spec import BSCSpec, BSCTransition, BeliefUpdate, CommitCondition  # noqa: E402
from encoder_bsc import compile_to_pddl  # noqa: E402

OUT = REPO / "landmark_experiments" / "results" / "paper"
WORK = OUT / "work"
LM_SEARCH = "astar(lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true)))"
SOUND_ORDERS = {"nec", "gn", "nat"}   # reasonable orders are not necessary orders
BELIEF_PREFIXES = ("k-", "uncertain-")

HAND = {
    "Tiger": domains_bsc.tiger_bsc,
    "Channel": domains_bsc.channel_bsc,
    "Mine-2x2": domains_bsc.mine_bsc,
    "Sensor-2": domains_bsc.sensor_bsc,
    "Sensor-3": domains_bsc.sensor_bsc_3,
    "RockSample-4": domains_bsc.rock_sample_bsc_4,
}
GENERIC_GATE_FILES = {   # pre-fix encoding, frozen in landmark_experiments/ablation_generic_gates
    "Tiger": "tiger-bsc", "Channel": "channel-bsc", "Mine-2x2": "mine-bsc",
    "Sensor-2": "sensor-bsc", "Sensor-3": "sensor-3-bsc", "RockSample-4": "rocksample-4-bsc",
}
FSC = {
    "Tiger": fsc_domains.tiger_spec, "Channel": fsc_domains.channel_spec,
    "Mine-2x2": fsc_domains.mine_spec, "Sensor-2": fsc_domains.sensor_spec,
    "Sensor-3": fsc_domains.sensor_spec_3,
}
POMDP = REPO / "pomdp_to_pddl" / "Pomdp"
INDUCED = {
    "Tiger": (lambda: parse_tiger(POMDP / "tiger_policy.csv"), None, domains_bsc.tiger_bsc),
    "Sensor-2": (lambda: parse_sensor(POMDP / "sensor_trace.csv"), None, domains_bsc.sensor_bsc),
    "RockSample-4": (lambda: parse_rocksample(POMDP / "rock_trace.csv", num_rocks=4),
                     lambda var, val: "good" if val.endswith("good") else "bad",
                     domains_bsc.rock_sample_bsc_4),
}


# ===========================================================================
#  Fast Downward
# ===========================================================================

def run_fd(name: str, domain: str, problem: str, search: str = LM_SEARCH) -> dict:
    wd = WORK / name
    wd.mkdir(parents=True, exist_ok=True)
    (wd / "domain.pddl").write_text(domain, encoding="utf-8")
    (wd / "problem.pddl").write_text(problem, encoding="utf-8")
    t0 = time.perf_counter()
    proc = subprocess.run(
        [sys.executable, str(REPO / "fast-downward.py"), "--build", "release64",
         "domain.pddl", "problem.pddl", "--search", search],
        cwd=wd, capture_output=True, text=True)
    wall = time.perf_counter() - t0
    log = proc.stdout + proc.stderr
    (wd / "fd.log").write_text(log, encoding="utf-8")
    if "translate exit code: 0" not in log:
        raise RuntimeError(f"{name}: translation failed, see {wd / 'fd.log'}")
    m = re.search(r"Landmarks generation time: ([\d.e+-]+)s", log)
    p = re.search(r"Plan length: (\d+) step", log)
    return {"parsed": parse_landmark_text(log), "sas": wd / "output.sas", "wall": wall,
            "lm_time": float(m.group(1)) if m else None,
            "plan_length": int(p.group(1)) if p else None}


def run_spec(name: str, spec: BSCSpec, search: str = LM_SEARCH) -> dict:
    return run_fd(name, *compile_to_pddl(spec), search=search)


def lm_key(lm: dict) -> frozenset:
    return frozenset(f"{f['atom_type']} {f['fact']}" for f in lm["facts"])


def graph(parsed: dict) -> tuple[set, set]:
    """(landmark keys, sound ordering pairs) of a parsed FD landmark graph."""
    keys = {lm["id"]: lm_key(lm) for lm in parsed["landmarks"]}
    edges = {(keys[e["from"]], keys[e["to"]]) for e in parsed["order_edges"]
             if e["order"] in SOUND_ORDERS}
    return set(keys.values()), edges


def is_belief_fact(fact: str) -> bool:
    return fact.split(" ", 1)[1].startswith(BELIEF_PREFIXES)


def counts(parsed: dict) -> dict:
    lms = parsed["landmarks"]
    return {
        "landmarks": len(lms),
        "disjunctive": sum(lm["kind"] == "disjunctive" for lm in lms),
        "belief": sum(any(is_belief_fact(f) for f in lm_key(lm)) for lm in lms),
        "edges": parsed["order_edge_count"],
    }


def show(key: frozenset) -> str:
    return " | ".join(sorted(key))


# ===========================================================================
#  Ground truth by exhaustive search over the translated SAS+ task
# ===========================================================================

class Task:
    """Explicit-state view of FD's output.sas (no axioms, no conditional effects)."""

    def __init__(self, path: Path):
        L = [line.strip() for line in path.read_text().splitlines()]
        i = L.index("end_metric") + 1
        n = int(L[i]); i += 1
        self.names = []
        for _ in range(n):
            rng = int(L[i + 3])
            self.names.append(L[i + 4:i + 4 + rng])
            i += 5 + rng
        n_mutex = int(L[i]); i += 1
        for _ in range(n_mutex):
            i += 3 + int(L[i + 1])
        self.init = tuple(int(x) for x in L[i + 1:i + 1 + n]); i += n + 2
        g = int(L[i + 1])
        self.goal = [tuple(map(int, L[i + 2 + j].split())) for j in range(g)]; i += 3 + g
        self.ops = []
        n_ops = int(L[i]); i += 1
        for _ in range(n_ops):
            n_prevail = int(L[i + 2]); i += 3     # begin_operator, name, num_prevail
            pre = [tuple(map(int, L[i + j].split())) for j in range(n_prevail)]
            i += n_prevail
            nef = int(L[i]); i += 1
            eff = []
            for j in range(nef):
                ncond, var, old, new = map(int, L[i + j].split())
                assert ncond == 0, "conditional effects are not supported"
                eff.append((var, new))
                if old != -1:
                    pre.append((var, old))
            i += nef + 2                     # effects, cost, end_operator
            self.ops.append((tuple(pre), tuple(eff)))
        assert int(L[i]) == 0, "axioms are not supported"
        self.fact = {name: (v, x) for v, vals in enumerate(self.names)
                     for x, name in enumerate(vals) if not name.startswith("<none")}

    def facts(self, key) -> list:
        """SAS facts for atom names; names the translator pruned can never hold."""
        return [self.fact[n] for n in key if n in self.fact]

    def succ(self, s):
        for pre, eff in self.ops:
            if all(s[v] == x for v, x in pre):
                t = list(s)
                for v, x in eff:
                    t[v] = x
                yield tuple(t)

    def _search(self, starts, blocked) -> bool:
        """Can the goal be reached from `starts` through states not `blocked`?"""
        seen, queue = set(starts), deque(starts)
        while queue:
            s = queue.popleft()
            if all(s[v] == x for v, x in self.goal):
                return True
            for t in self.succ(s):
                if t not in seen and not blocked(t):
                    seen.add(t)
                    queue.append(t)
        return False

    def is_landmark(self, key) -> bool:
        F = self.facts(key)
        hold = lambda s: any(s[v] == x for v, x in F)  # noqa: E731
        return hold(self.init) or not self._search([self.init], hold)

    def order_holds(self, a_key, b_key) -> bool:
        """Natural ordering: on every plan some A-fact holds strictly before B first holds."""
        A, B = self.facts(a_key), self.facts(b_key)
        hold = lambda s, F: any(s[v] == x for v, x in F)  # noqa: E731
        b_first = []                         # states where B first holds with A never before
        if hold(self.init, B):
            b_first.append(self.init)
        elif not hold(self.init, A):
            seen, queue = {self.init}, deque([self.init])
            while queue:
                for t in self.succ(queue.popleft()):
                    if t in seen:
                        continue
                    seen.add(t)
                    if hold(t, B):
                        b_first.append(t)
                    elif not hold(t, A):
                        queue.append(t)
        return not (b_first and self._search(b_first, lambda s: False))


def _selfcheck() -> None:
    """Two-step toy task: a -> b -> goal. Both facts are landmarks, a before b."""
    sas = WORK / "selfcheck.sas"
    sas.parent.mkdir(parents=True, exist_ok=True)
    sas.write_text("\n".join([
        "begin_version", "3", "end_version", "begin_metric", "0", "end_metric", "1",
        "begin_variable", "var0", "-1", "3", "Atom s0()", "Atom a()", "Atom b()",
        "end_variable", "0", "begin_state", "0", "end_state", "begin_goal", "1", "0 2",
        "end_goal", "2",
        "begin_operator", "go-a", "0", "1", "0 0 0 1", "1", "end_operator",
        "begin_operator", "go-b", "0", "1", "0 0 1 2", "1", "end_operator", "0"]))
    t = Task(sas)
    assert t.is_landmark({"Atom a()"}) and t.is_landmark({"Atom b()"})
    assert t.order_holds({"Atom a()"}, {"Atom b()"})
    assert not t.order_holds({"Atom b()"}, {"Atom a()"})


# ===========================================================================
#  Experiments
# ===========================================================================

def exp_main() -> dict:
    rows = {}
    for dom, make in HAND.items():
        spec = make()
        r = run_spec(f"main/{dom}", spec)
        solve = run_spec(f"main/{dom}-blind", spec, search="astar(blind())")
        keys, _ = graph(r["parsed"])
        rows[dom] = {
            "vars": len(spec.hidden_variables),
            "max_card": max(v.cardinality for v in spec.hidden_variables),
            **counts(r["parsed"]),
            "plan_length": solve["plan_length"],
            "lm_time_s": r["lm_time"],
            "landmark_list": sorted(show(k) for k in keys),
        }
        assert solve["plan_length"], f"{dom}: compiled BSC task is unsolvable"
    return rows


def exp_exactness() -> dict:
    rows = {}
    for dom, make in HAND.items():
        r = run_spec(f"exact/{dom}", make())
        task = Task(r["sas"])
        keys, edges = graph(r["parsed"])
        rhw_simple = {next(iter(k)) for k in keys if len(k) == 1}
        nontrivial = [n for n, (v, x) in task.fact.items() if task.init[v] != x]
        true_simple = {n for n in nontrivial if task.is_landmark({n})}
        disj = [k for k in keys if len(k) > 1]
        # Same-predicate disjunctions over a belief predicate: is each true one found?
        classes = {}
        for n in nontrivial:
            m = re.match(r"Atom ((?:k-|uncertain-)[^(]*)\(", n)
            if m:
                classes.setdefault(m.group(1), set()).add(n)
        true_classes = [c for c in classes.values()
                        if len(c) > 1 and not c & true_simple and task.is_landmark(c)]
        rows[dom] = {
            "rhw_landmarks_true": sum(task.is_landmark(k) for k in keys),
            "rhw_landmarks": len(keys),
            "rhw_edges_true": sum(task.order_holds(a, b) for a, b in edges),
            "rhw_sound_edges": len(edges),
            "true_nontrivial_simple": len(true_simple),
            "rhw_found_nontrivial_simple": len(true_simple & rhw_simple),
            "true_belief_disjunctions": len(true_classes),
            "rhw_found_belief_disjunctions": sum(any(k <= c for k in disj) for c in true_classes),
            "missed": sorted(true_simple - rhw_simple),
        }
    return rows


def _belief_lms(parsed: dict) -> list:
    return [k for k in graph(parsed)[0] if all(is_belief_fact(f) for f in k)]


def exp_ablation() -> dict:
    rows = {}
    gate_dir = REPO / "landmark_experiments" / "ablation_generic_gates"
    for dom, make in HAND.items():
        faithful = Task(run_spec(f"ablation/{dom}-faithful", make())["sas"])
        row = {}
        stem = GENERIC_GATE_FILES[dom]
        gate = run_fd(f"ablation/{dom}-gates",
                      (gate_dir / f"{stem}-domain.pddl").read_text(),
                      (gate_dir / f"{stem}-problem.pddl").read_text())
        variants = [("generic_gates", gate)]
        if dom in FSC:
            variants.append(("fsc", run_fd(f"ablation/{dom}-fsc",
                                           *fsc_encoder.compile_to_pddl(FSC[dom]()))))
        for label, r in variants:
            keys, _ = graph(r["parsed"])
            belief = _belief_lms(r["parsed"])
            spurious = [k for k in belief if not faithful.is_landmark(k)]
            structural = [k for k in keys if not any(
                f.split(" ", 1)[1].startswith(("k-", "uncertain-", "committed", "neg-committed",
                                               "confirmed", "done"))
                for f in k)]
            row[label] = {**counts(r["parsed"]), "structural": len(structural),
                          "belief_not_required_by_policy": len(spurious),
                          "examples": sorted(show(k) for k in spurious)[:4]}
        rows[dom] = row
    return rows


def exp_induced() -> dict:
    rows = {}
    for dom, (parse, role_of, hand) in INDUCED.items():
        spec, report = induce_binary_bsc(parse(), name=f"{dom.lower()}-induced-bsc",
                                         role_of=role_of)
        ind = run_spec(f"induced/{dom}", spec)
        hnd = run_spec(f"induced/{dom}-hand", hand())
        ki, ei = graph(ind["parsed"])
        kh, eh = graph(hnd["parsed"])
        rows[dom] = {
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


def _mutants(spec: BSCSpec):
    """Commitment bugs: drop a commit literal, commit blind, over-confident first update."""
    for i, cc in enumerate(spec.commit_conditions):
        for j, lit in enumerate(cc.belief_precs):
            precs = cc.belief_precs[:j] + cc.belief_precs[j + 1:]
            ccs = list(spec.commit_conditions)
            ccs[i] = CommitCondition(cc.variable, cc.commit_value, precs)
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
            continue                         # only first-evidence transitions
        u = ups[0]
        extra = tuple(BeliefUpdate(u.variable, o, "neg") for o in var_dom[u.variable]
                      if o != u.value)
        ts = list(spec.transitions)
        ts[i] = BSCTransition(t.observation, t.belief_precs, t.belief_updates + extra,
                              t.retractions)
        yield ("overconfident-update",
               f"first '{t.observation}' already rules out the alternatives",
               _with(spec, transitions=ts))


def _with(spec: BSCSpec, **changes) -> BSCSpec:
    fields = dict(name=spec.name, hidden_variables=spec.hidden_variables,
                  observations=spec.observations, transitions=spec.transitions,
                  commit_conditions=spec.commit_conditions)
    fields.update(changes)
    return BSCSpec(**fields)


def exp_mutation() -> dict:
    rows, cases = {}, []
    for dom in ("Tiger", "Channel", "Mine-2x2", "Sensor-2"):
        base = HAND[dom]()
        k0, e0 = graph(run_spec(f"mutation/{dom}/original", base)["parsed"])
        tally = {"TP": 0, "FP": 0, "FN": 0, "TN": 0}
        for n, (op, what, mutant) in enumerate(_mutants(base)):
            r = run_spec(f"mutation/{dom}/m{n}", mutant)
            task = Task(r["sas"])
            k1, e1 = graph(r["parsed"])
            lost_true = [k for k in k0 if not task.is_landmark(k)]
            broken_true = [e for e in e0 if not task.order_holds(*e)]
            changed = bool(lost_true or broken_true)
            detected = bool(k0 - k1 or e0 - e1)
            tally[("T" if changed == detected else "F") + ("P" if detected else "N")] += 1
            cases.append({"domain": dom, "operator": op, "mutant": what,
                          "changed": changed, "detected": detected,
                          "lost_landmarks": sorted(show(k) for k in k0 - k1),
                          "lost_orderings": sorted(f"{show(a)} < {show(b)}" for a, b in e0 - e1)})
        rows[dom] = tally
    return {"per_domain": rows, "cases": cases}


def exp_scaling() -> dict:
    rows = {"sensor": [], "mine": []}
    for n in (1, 2, 4, 8, 16, 32, 64, 128):
        spec = domains_bsc.sensor_bsc_scaled(n)
        r = run_spec(f"scaling/sensor-{n}", spec)
        rows["sensor"].append({"n": n, "actions": len(spec.transitions)
                               + len(spec.commit_conditions) + 1,
                               **counts(r["parsed"]), "lm_time_s": r["lm_time"],
                               "wall_s": round(r["wall"], 2)})
    for k in (2, 3, 4, 5, 6, 8):
        spec = domains_bsc.mine_bsc_scaled(k, k)
        r = run_spec(f"scaling/mine-{k}x{k}", spec)
        disj = [lm for lm in r["parsed"]["landmarks"] if lm["kind"] == "disjunctive"]
        rows["mine"].append({"cells": k * k, "actions": len(spec.transitions)
                             + len(spec.commit_conditions) + 1,
                             **counts(r["parsed"]),
                             "largest_disjunction": max((len(lm["facts"]) for lm in disj),
                                                        default=0),
                             "lm_time_s": r["lm_time"], "wall_s": round(r["wall"], 2)})
    return rows


EXPERIMENTS = {"main": exp_main, "exactness": exp_exactness, "ablation": exp_ablation,
               "induced": exp_induced, "mutation": exp_mutation, "scaling": exp_scaling}


def main(argv: list) -> int:
    _selfcheck()
    OUT.mkdir(parents=True, exist_ok=True)
    for name in argv or list(EXPERIMENTS):
        t0 = time.perf_counter()
        result = EXPERIMENTS[name]()
        (OUT / f"{name}.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
        print(f"[OK] {name} ({time.perf_counter() - t0:.0f}s) -> {OUT / (name + '.json')}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

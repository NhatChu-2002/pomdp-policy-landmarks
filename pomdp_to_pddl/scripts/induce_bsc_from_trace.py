#!/usr/bin/env python3
"""Induce a BSC from a SARSOP trace and compile it to PDDL for landmarks.

Unlike compile_trace_to_pddl_bsc.py -- which returns the hand-written spec from
domains_bsc.py and merely validates the trace -- this script *learns* the BSC
transitions and commit conditions from the trace's belief trajectories
(see bsc_induction.py).  It then reuses encoder_bsc.compile_to_pddl unchanged.

Usage:
    python induce_bsc_from_trace.py tiger
    python induce_bsc_from_trace.py rocksample

Output goes to landmark_experiments/generated/<domain>_induced/.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from encoder_bsc import compile_to_pddl
from bsc_induction import (
    induce_binary_bsc, parse_tiger, parse_rocksample, parse_sensor,
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


DOMAINS = {
    "tiger": {
        "csv": ("pomdp_to_pddl", "Pomdp", "tiger_policy.csv"),
        "name": "tiger-induced-bsc",
        "outdir": ("landmark_experiments", "generated", "tiger_induced"),
        "parse": lambda p: parse_tiger(p),
        "role_of": None,
    },
    "rocksample": {
        "csv": ("pomdp_to_pddl", "Pomdp", "rock_trace.csv"),
        "name": "rocksample-induced-bsc",
        "outdir": ("landmark_experiments", "generated", "rocksample_induced"),
        "parse": lambda p: parse_rocksample(p, num_rocks=4),
        # Rocks are isomorphic instances of one sensor template: pool their
        # observed outcomes (3 good, 1 bad in a single trace) by mapping each
        # value to its role, then instantiate the shared template per rock.
        "role_of": lambda var, val: "good" if val.endswith("good") else "bad",
    },
    "sensor": {
        "csv": ("pomdp_to_pddl", "Pomdp", "sensor_trace.csv"),
        "name": "sensor-induced-bsc",
        "outdir": ("landmark_experiments", "generated", "sensor_induced"),
        "parse": lambda p: parse_sensor(p),
        # Two independent binary sensors; 20 sims cover both outcomes for each,
        # so per-variable induction already recovers both branches (no pooling).
        "role_of": None,
    },
}


def main() -> int:
    root = repo_root()
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("domain", choices=list(DOMAINS))
    ap.add_argument("--csv", type=Path, help="override input trace CSV")
    ap.add_argument("--outdir", type=Path, help="override output directory")
    args = ap.parse_args()

    cfg = DOMAINS[args.domain]
    csv_path = args.csv or root.joinpath(*cfg["csv"])
    outdir = args.outdir or root.joinpath(*cfg["outdir"])
    name = cfg["name"]

    episodes = cfg["parse"](csv_path)
    if not episodes:
        print(f"[ERROR] no usable trace data in {csv_path}")
        return 1

    spec, report = induce_binary_bsc(episodes, name=name, role_of=cfg["role_of"])
    report.source_csv = str(csv_path)
    spec.validate()

    domain_pddl, problem_pddl = compile_to_pddl(spec)

    outdir.mkdir(parents=True, exist_ok=True)
    safe = name.replace("-", "_")
    (outdir / f"{safe}_domain.pddl").write_text(domain_pddl + "\n", encoding="utf-8")
    (outdir / f"{safe}_problem.pddl").write_text(problem_pddl + "\n", encoding="utf-8")
    (outdir / f"{safe}_report.json").write_text(
        json.dumps(report.as_dict(), indent=2), encoding="utf-8")

    print(f"[OK] induced {report.n_transitions} transitions, "
          f"{report.n_commit_conditions} commit conditions")
    print(f"     unit log-odds = {report.unit_logodds}, "
          f"theta_commit = {report.theta_commit} (levels {report.levels_observed})")
    print(f"     graded decrement discovered: {report.has_graded_decrement}")
    print(f"     coverage: {report.coverage_steps_explained}/"
          f"{report.coverage_steps_total} steps "
          f"({report.coverage_fraction():.0%}), "
          f"{report.nondeterministic_pairs} nondeterministic pairs")
    print(f"     transition kinds: {report.transition_kinds}")
    print(f"[OK] wrote PDDL + report to {outdir}")
    print()
    print("Run Fast Downward (from repo root):")
    print(f'  python fast-downward.py --build release64 \\')
    print(f'    "{outdir / (safe + "_domain.pddl")}" \\')
    print(f'    "{outdir / (safe + "_problem.pddl")}" \\')
    print(f'    --search "astar(lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true)))"')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

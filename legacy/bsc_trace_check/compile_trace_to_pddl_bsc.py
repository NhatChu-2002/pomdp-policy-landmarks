#!/usr/bin/env python3
"""Compile Julia SARSOP policy traces to BSC PDDL for landmark extraction.

Unlike compile_trace_to_pddl.py (FSC), this script produces PDDL with
NO abstract controller nodes.  The belief state alone drives sense-actions.
Fast Downward landmarks from this PDDL reflect MDP hidden-state structure.

Usage:
    python compile_trace_to_pddl_bsc.py tiger
    python compile_trace_to_pddl_bsc.py channel --csv channel_trace.csv
    python compile_trace_to_pddl_bsc.py sensor
    python compile_trace_to_pddl_bsc.py mine

Default CSV paths (relative to repo root / pomdp_to_pddl / Pomdp /):
    tiger   : tiger_policy.csv
    channel : channel_trace.csv
    sensor  : sensor_trace.csv
    mine    : mine_trace.csv

Output goes to:
    landmark_experiments/generated/<domain>_bsc/
"""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict
from pathlib import Path

from encoder_bsc import compile_to_pddl
from trace_adapters_bsc import (
    tiger_trace_to_bsc_spec,
    channel_trace_to_bsc_spec,
    sensor_trace_to_bsc_spec,
    mine_trace_to_bsc_spec,
    rock_sample_trace_to_bsc_spec,
)


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


DOMAIN_DEFAULTS = {
    "tiger": {
        "csv":    ("pomdp_to_pddl", "Pomdp", "tiger_policy.csv"),
        "name":   "tiger-bsc",
        "outdir": ("landmark_experiments", "generated", "tiger_bsc"),
        "adapter": tiger_trace_to_bsc_spec,
    },
    "channel": {
        "csv":    ("pomdp_to_pddl", "Pomdp", "channel_trace.csv"),
        "name":   "channel-bsc",
        "outdir": ("landmark_experiments", "generated", "channel_bsc"),
        "adapter": channel_trace_to_bsc_spec,
    },
    "sensor": {
        "csv":    ("pomdp_to_pddl", "Pomdp", "sensor_trace.csv"),
        "name":   "sensor-bsc",
        "outdir": ("landmark_experiments", "generated", "sensor_bsc"),
        "adapter": sensor_trace_to_bsc_spec,
    },
    "mine": {
        "csv":    ("pomdp_to_pddl", "Pomdp", "mine_trace.csv"),
        "name":   "mine-bsc",
        "outdir": ("landmark_experiments", "generated", "mine_bsc"),
        "adapter": mine_trace_to_bsc_spec,
    },
    "rocksample": {
        "csv":    ("pomdp_to_pddl", "Pomdp", "rock_trace.csv"),
        "name":   "rocksample-4-bsc",
        "outdir": ("landmark_experiments", "generated", "rocksample_bsc"),
        "adapter": rock_sample_trace_to_bsc_spec,
    },
}


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("domain", choices=list(DOMAIN_DEFAULTS),
                        help="POMDP domain to compile")
    parser.add_argument("--csv",    type=Path, help="Input trace CSV (overrides default)")
    parser.add_argument("--name",              help="PDDL domain/problem base name")
    parser.add_argument("--outdir", type=Path, help="Output directory")
    args = parser.parse_args()

    cfg     = DOMAIN_DEFAULTS[args.domain]
    csv_path = args.csv    or root.joinpath(*cfg["csv"])
    name     = args.name   or cfg["name"]
    outdir   = args.outdir or root.joinpath(*cfg["outdir"])

    adapter = cfg["adapter"]
    spec, summary = adapter(csv_path, name=name)
    spec.validate()

    domain_pddl, problem_pddl = compile_to_pddl(spec)

    outdir.mkdir(parents=True, exist_ok=True)
    safe_name    = name.replace("-", "_")
    domain_path  = outdir / f"{safe_name}_domain.pddl"
    problem_path = outdir / f"{safe_name}_problem.pddl"
    spec_path    = outdir / f"{safe_name}_spec.json"

    domain_path.write_text(domain_pddl + "\n",  encoding="utf-8")
    problem_path.write_text(problem_pddl + "\n", encoding="utf-8")
    spec_path.write_text(
        json.dumps(
            {
                "trace_summary": asdict(summary),
                "spec": {
                    "name": spec.name,
                    "hidden_variables": [
                        {"name": v.name, "domain": list(v.domain)}
                        for v in spec.hidden_variables
                    ],
                    "observations": spec.observations,
                    "transition_count": len(spec.transitions),
                    "commit_conditions": len(spec.commit_conditions),
                },
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    print(f"[OK] domain  : {domain_path}")
    print(f"[OK] problem : {problem_path}")
    print(f"[OK] spec    : {spec_path}")
    print()
    print("Run Fast Downward (from repo root):")
    print(f'  python fast-downward.py --build release64 \\')
    print(f'    "{domain_path}" \\')
    print(f'    "{problem_path}" \\')
    print(f'    --search "astar(lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true)))"')
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

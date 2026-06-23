#!/usr/bin/env python3
"""Compile policy traces into PDDL through the shared FSCPomdpSpec model."""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict
from pathlib import Path

from encoder import compile_to_pddl
from trace_adapters import rock_trace_to_spec, tiger_trace_to_spec


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


DOMAIN_DEFAULTS = {
    "tiger": {
        "csv": ("pomdp_to_pddl", "Pomdp", "tiger_policy.csv"),
        "name": "tiger-trace-fsc",
        "outdir": ("landmark_experiments", "generated", "tiger_trace_fsc"),
    },
    "rock": {
        "csv": ("pomdp_to_pddl", "Pomdp", "rock_trace.csv"),
        "name": "rock-trace-fsc",
        "outdir": ("landmark_experiments", "generated", "rock_trace_fsc"),
    },
}


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("domain", choices=list(DOMAIN_DEFAULTS))
    parser.add_argument("--csv", type=Path, help="Input policy trace CSV (overrides default).")
    parser.add_argument("--trace-id", type=int, help="Tiger only: compile a single trace id.")
    parser.add_argument("--name", help="PDDL domain/problem base name (overrides default).")
    parser.add_argument("--outdir", type=Path, help="Output directory (overrides default).")
    args = parser.parse_args()

    defaults = DOMAIN_DEFAULTS[args.domain]
    csv_path  = args.csv    or root.joinpath(*defaults["csv"])
    name      = args.name   or defaults["name"]
    outdir    = args.outdir or root.joinpath(*defaults["outdir"])

    if args.domain == "tiger":
        spec, summary = tiger_trace_to_spec(csv_path, trace_id=args.trace_id, name=name)
        summary_dict = asdict(summary)
        summary_line = (
            f"{summary.trace_count} trace(s), "
            f"{summary.listen_count} listen row(s), "
            f"observations={', '.join(summary.observations)}"
        )
    elif args.domain == "rock":
        spec, summary = rock_trace_to_spec(csv_path, name=name)
        summary_dict = asdict(summary)
        summary_line = (
            f"{summary.rock_count} rock(s), "
            f"{summary.sense_events} sense event(s), "
            f"rocks_sensed={summary.rocks_sensed}"
        )
    else:
        raise AssertionError(args.domain)

    domain_pddl, problem_pddl = compile_to_pddl(spec)

    outdir.mkdir(parents=True, exist_ok=True)
    safe_name = name.replace("-", "_")
    domain_path = outdir / f"{safe_name}_domain.pddl"
    problem_path = outdir / f"{safe_name}_problem.pddl"
    spec_path    = outdir / f"{safe_name}_spec.json"

    domain_path.write_text(domain_pddl + "\n", encoding="utf-8")
    problem_path.write_text(problem_pddl + "\n", encoding="utf-8")
    spec_path.write_text(
        json.dumps(
            {
                "trace_summary": summary_dict,
                "spec": {
                    "name": spec.name,
                    "hidden_variables": [
                        {"name": v.name, "domain": list(v.domain)}
                        for v in spec.hidden_variables
                    ],
                    "fsc_nodes": spec.fsc_nodes,
                    "initial_node": spec.initial_node,
                    "commit_nodes": spec.commit_nodes,
                    "observations": spec.observations,
                    "transition_count": len(spec.transitions),
                },
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    print(f"[OK] wrote domain:       {domain_path}")
    print(f"[OK] wrote problem:      {problem_path}")
    print(f"[OK] wrote spec summary: {spec_path}")
    print(f"[OK] trace summary: {summary_line}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

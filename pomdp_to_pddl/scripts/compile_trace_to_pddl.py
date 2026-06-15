#!/usr/bin/env python3
"""Compile policy traces into PDDL through the shared FSCPomdpSpec model."""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict
from pathlib import Path

from encoder import compile_to_pddl
from trace_adapters import tiger_trace_to_spec


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def main() -> int:
    root = repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("domain", choices=["tiger"])
    parser.add_argument(
        "--csv",
        type=Path,
        default=root / "pomdp_to_pddl" / "Pomdp" / "tiger_policy.csv",
        help="Input policy trace CSV.",
    )
    parser.add_argument("--trace-id", type=int, help="Compile only one trace id.")
    parser.add_argument(
        "--name",
        default="tiger-trace-fsc",
        help="PDDL domain/problem base name.",
    )
    parser.add_argument(
        "--outdir",
        type=Path,
        default=root / "landmark_experiments" / "generated" / "tiger_trace_fsc",
    )
    args = parser.parse_args()

    if args.domain == "tiger":
        spec, summary = tiger_trace_to_spec(args.csv, trace_id=args.trace_id, name=args.name)
    else:
        raise AssertionError(args.domain)

    domain_pddl, problem_pddl = compile_to_pddl(spec)

    args.outdir.mkdir(parents=True, exist_ok=True)
    domain_path = args.outdir / "tiger_trace_fsc_domain.pddl"
    problem_path = args.outdir / "tiger_trace_fsc_problem.pddl"
    spec_path = args.outdir / "tiger_trace_fsc_spec.json"

    domain_path.write_text(domain_pddl + "\n", encoding="utf-8")
    problem_path.write_text(problem_pddl + "\n", encoding="utf-8")
    spec_path.write_text(
        json.dumps(
            {
                "trace_summary": asdict(summary),
                "spec": {
                    "name": spec.name,
                    "hidden_variables": [
                        {"name": variable.name, "domain": list(variable.domain)}
                        for variable in spec.hidden_variables
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

    print(f"[OK] wrote domain: {domain_path}")
    print(f"[OK] wrote problem: {problem_path}")
    print(f"[OK] wrote spec summary: {spec_path}")
    print(
        "[OK] trace summary: "
        f"{summary.trace_count} trace(s), "
        f"{summary.listen_count} listen row(s), "
        f"observations={', '.join(summary.observations)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

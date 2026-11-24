"""Command line for the pipeline. Run from the repository root:

    python -m policy_landmarks list
    python -m policy_landmarks compile tiger            # PDDL only
    python -m policy_landmarks explain tiger            # landmarks + orderings
    python -m policy_landmarks explain sensor-2 --induced --check

Files go to generated/<name>/ (domain.pddl, problem.pddl, fd.log, output.sas).
"""

from __future__ import annotations

import argparse
import sys

from .domains import HAND_WRITTEN
from .encoder import compile_to_pddl
from .ground_truth import Task
from .induction import TRACE_SOURCES, induce
from .planner import REPO, graph, run_spec, show


def _controller(name: str, induced: bool):
    if induced:
        spec, report = induce(name)
        print(f"induced from trace: theta_commit={report.theta_commit}, "
              f"{report.n_transitions} sensing rules, "
              f"coverage {report.coverage_fraction():.0%}")
        return f"{name}-induced", spec
    return name, HAND_WRITTEN[name]()


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="python -m policy_landmarks", description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list", help="show available controllers")
    for cmd in ("compile", "explain"):
        p = sub.add_parser(cmd)
        p.add_argument("name", choices=sorted(HAND_WRITTEN))
        p.add_argument("--induced", action="store_true",
                       help=f"induce the controller from its SARSOP trace "
                            f"({', '.join(TRACE_SOURCES)})")
        if cmd == "explain":
            p.add_argument("--check", action="store_true",
                           help="verify every landmark and ordering by exhaustive search")
    args = ap.parse_args(argv)

    if args.cmd == "list":
        print("hand-written:", ", ".join(HAND_WRITTEN))
        print("induced (--induced):", ", ".join(TRACE_SOURCES))
        return 0

    if args.induced and args.name not in TRACE_SOURCES:
        ap.error(f"no trace for {args.name}; choose from {', '.join(TRACE_SOURCES)}")
    label, spec = _controller(args.name, args.induced)
    out = REPO / "generated" / label

    if args.cmd == "compile":
        out.mkdir(parents=True, exist_ok=True)
        domain, problem = compile_to_pddl(spec)
        (out / "domain.pddl").write_text(domain + "\n", encoding="utf-8")
        (out / "problem.pddl").write_text(problem + "\n", encoding="utf-8")
        print(f"wrote {out / 'domain.pddl'} and problem.pddl")
        return 0

    run = run_spec(out, spec)
    keys, edges = graph(run["parsed"])
    print(f"{label}: {len(keys)} landmarks, {len(edges)} sound orderings "
          f"(files in {out})")
    print("\nLandmarks")
    for key in sorted(keys, key=show):
        print("  " + show(key))
    print("\nOrderings (a  ->  b: a holds before b is first reached)")
    for a, b in sorted(edges, key=lambda e: (show(e[0]), show(e[1]))):
        print(f"  {show(a)}  ->  {show(b)}")
    if args.check:
        task = Task(run["sas"])
        bad = [show(k) for k in keys if not task.is_landmark(k)]
        bad += [f"{show(a)} -> {show(b)}" for a, b in edges if not task.order_holds(a, b)]
        print("\nExhaustive check:", "all confirmed" if not bad else f"FAILED: {bad}")
        return 1 if bad else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())

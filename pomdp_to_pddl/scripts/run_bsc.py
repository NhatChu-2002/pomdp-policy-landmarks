"""
CLI: python run_bsc.py <domain-name> [--outdir ./pddl_bsc_out]

Generates <name>-domain.pddl and <name>-problem.pddl in the output directory.

All encodings use the BSC (Belief-State Controller) approach:
  - NO abstract FSC memory nodes
  - Belief state (k / k-not predicates) is the sole state representation
  - Landmarks from Fast Downward reflect MDP hidden-state structure,
    not FSC controller graph topology

Run Fast Downward (from repo root):
    python fast-downward.py --build release64 \\
        <domain.pddl> <problem.pddl> \\
        --search "astar(lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true)))"
"""

import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))

from encoder_bsc import compile_to_pddl
import domains_bsc


REGISTRY = {
    "tiger":          domains_bsc.tiger_bsc,
    "channel":        domains_bsc.channel_bsc,
    "sensor":         domains_bsc.sensor_bsc,
    "mine":           domains_bsc.mine_bsc,
    "mine_3x3":       domains_bsc.mine_bsc_3x3,
    "sensor_3":       domains_bsc.sensor_bsc_3,
    "rocksample":     domains_bsc.rock_sample_bsc_4,
}


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument(
        "domain",
        choices=sorted(REGISTRY.keys()),
        help="which domain spec to compile",
    )
    ap.add_argument(
        "--outdir",
        default="./pddl_bsc_out",
        help="directory to write PDDL files into (default: ./pddl_bsc_out)",
    )
    args = ap.parse_args()

    spec = REGISTRY[args.domain]()
    spec.validate()
    domain_pddl, problem_pddl = compile_to_pddl(spec)

    os.makedirs(args.outdir, exist_ok=True)
    dpath = os.path.join(args.outdir, f"{spec.name}-domain.pddl")
    ppath = os.path.join(args.outdir, f"{spec.name}-problem.pddl")

    with open(dpath, "w") as f:
        f.write(domain_pddl + "\n")
    with open(ppath, "w") as f:
        f.write(problem_pddl + "\n")

    print(f"Wrote {dpath}")
    print(f"Wrote {ppath}")
    print()
    print("Run Fast Downward:")
    print(f"  python fast-downward.py --build release64 \\")
    print(f"    '{dpath}' \\")
    print(f"    '{ppath}' \\")
    print(f"    --search \"astar(lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true)))\"")
    return 0


if __name__ == "__main__":
    sys.exit(main())

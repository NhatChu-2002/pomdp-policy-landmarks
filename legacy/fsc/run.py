"""
CLI: python run.py <domain-name> [--outdir ./pddl_out]

Generates <name>-domain.pddl and <name>-problem.pddl in the output directory.
Feed those to Fast Downward with:
    fast-downward.py --search "astar(lmcount(lm_merged([lm_rhw(),lm_zg()])))" \\
        <name>-domain.pddl <name>-problem.pddl
"""

import argparse
import os
import sys

from encoder import compile_to_pddl
import domains


# Registry of available specs
REGISTRY = {
    "tiger":    domains.tiger_spec,
    "channel":  domains.channel_spec,
    "mine":     domains.mine_spec,
    "sensor":   domains.sensor_spec,
    "mine_3x3": domains.mine_spec_3x3,
    "sensor_3": domains.sensor_spec_3,
}


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("domain", choices=sorted(REGISTRY.keys()),
                    help="which domain spec to compile")
    ap.add_argument("--outdir", default="./pddl_out",
                    help="where to write the PDDL files")
    args = ap.parse_args()

    spec = REGISTRY[args.domain]()
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
    print(f"  fast-downward.py --search \\")
    print(f"    'astar(lmcount(lm_merged([lm_rhw(),lm_zg()])))' \\")
    print(f"    {dpath} {ppath}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

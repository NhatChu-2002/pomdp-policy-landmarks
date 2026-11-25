"""Run Fast Downward on a compiled controller and read its landmark graph.

Every run writes domain.pddl, problem.pddl, fd.log and output.sas into one
work folder, so a failed or surprising run can be inspected by hand.
"""

from __future__ import annotations

import re
import subprocess
import sys
import time
from pathlib import Path

from .encoder import compile_to_pddl
from .fd_output import parse_landmark_text
from .spec import BSCSpec

REPO = Path(__file__).resolve().parents[1]
FAST_DOWNWARD = REPO / "fast-downward" / "fast-downward.py"
LM_SEARCH = "astar(lmcount(lm_factory=lm_rhw(disjunctive_landmarks=true)))"
SOUND_ORDERS = {"nec", "gn", "nat"}   # reasonable orders are advice, not necessity
BELIEF_PREFIXES = ("k-", "uncertain-")


def run_fd(workdir: Path, domain: str, problem: str, search: str = LM_SEARCH) -> dict:
    """Translate and run Fast Downward; return the parsed landmark graph and run info.

    Our Fast Downward build exits right after dumping the landmark graph, so a
    landmark run never searches. Pass search="astar(blind())" to get a plan.
    """
    workdir.mkdir(parents=True, exist_ok=True)
    (workdir / "domain.pddl").write_text(domain.rstrip("\n") + "\n", encoding="utf-8")
    (workdir / "problem.pddl").write_text(problem.rstrip("\n") + "\n", encoding="utf-8")
    t0 = time.perf_counter()
    proc = subprocess.run(
        [sys.executable, str(FAST_DOWNWARD), "--build", "release64",
         "domain.pddl", "problem.pddl", "--search", search],
        cwd=workdir, capture_output=True, text=True)
    wall = time.perf_counter() - t0
    log = proc.stdout + proc.stderr
    (workdir / "fd.log").write_text(log, encoding="utf-8")
    if "translate exit code: 0" not in log:
        raise RuntimeError(f"translation failed, see {workdir / 'fd.log'}")
    # A missing graph means a stock, missing or crashed planner, not "no landmarks".
    if "lm_rhw" in search and "Landmark graph end." not in log:
        raise RuntimeError(f"no landmark graph in planner output, see {workdir / 'fd.log'}")
    lm_time = re.search(r"Landmarks generation time: ([\d.e+-]+)s", log)
    plan = re.search(r"Plan length: (\d+) step", log)
    return {"parsed": parse_landmark_text(log), "sas": workdir / "output.sas",
            "wall": wall, "lm_time": float(lm_time.group(1)) if lm_time else None,
            "plan_length": int(plan.group(1)) if plan else None}


def run_spec(workdir: Path, spec: BSCSpec, search: str = LM_SEARCH) -> dict:
    return run_fd(workdir, *compile_to_pddl(spec), search=search)


def lm_key(lm: dict) -> frozenset:
    """A landmark as a set of atom names, e.g. {'Atom k-direction(left)', ...}."""
    return frozenset(f"{f['atom_type']} {f['fact']}" for f in lm["facts"])


def graph(parsed: dict) -> tuple[set, set]:
    """(landmark keys, sound ordering pairs) of a parsed landmark graph."""
    keys = {lm["id"]: lm_key(lm) for lm in parsed["landmarks"]}
    edges = {(keys[e["from"]], keys[e["to"]]) for e in parsed["order_edges"]
             if e["order"] in SOUND_ORDERS}
    return set(keys.values()), edges


def edge_types(parsed: dict) -> dict:
    """{(landmark key, landmark key): {"gn", "nat", ...}} for sound orderings."""
    keys = {lm["id"]: lm_key(lm) for lm in parsed["landmarks"]}
    types: dict = {}
    for e in parsed["order_edges"]:
        if e["order"] in SOUND_ORDERS:
            types.setdefault((keys[e["from"]], keys[e["to"]]), set()).add(e["order"])
    return types


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
    """Readable landmark: 'k-direction(left) | k-direction(right)', 'not done()'."""
    return " | ".join(sorted(f.replace("NegatedAtom ", "not ").replace("Atom ", "")
                             for f in key))

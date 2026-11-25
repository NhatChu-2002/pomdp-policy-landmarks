"""Landmarks from sampled runs (research direction R1).

A policy graph is a Markov chain. Sampling N runs and keeping the fact sets that hold
on every sampled run that ends gives "empirical landmarks". True landmarks always
survive (they hold on every run that ends); the question is how many non-landmarks
survive by chance. A non-landmark F survives N runs with probability
(1 - q_F)^N, where q_F is the probability that a run that ends avoids F; q_F is
computed exactly from the graph by `avoid_probability`.
"""

from __future__ import annotations

import random

from .extraction import _san, first_hit


def run_facts(g: dict, ctrl: dict, rng: random.Random, max_steps: int = 2000):
    """One run from the root: the set of facts that held at some point, or None if the
    run did not end within max_steps."""
    out: dict = {}
    for e in g["edges"]:
        out.setdefault(e["from"], []).append((e["p"], e["to"], e["obs"]))
    nodes = {n["id"]: n for n in g["nodes"]}
    seen = set()
    i = g["nodes"][0]["id"]
    for _ in range(max_steps):
        seen |= ctrl["node_state"][i] - {"terminal"}
        n = nodes[i]
        if n["kind"] == "commit_end":
            return seen | {f"chose({_san(n['action'])})", "done"}
        if n["kind"] == "terminal":
            return seen | {"done"}
        r, acc = rng.random(), 0.0
        for p, t, _ in out[i]:
            acc += p
            if r <= acc:
                break
        if g["problem"] == "rocksample" and n["action"] == "1":
            cell = next(f for f in ctrl["node_state"][i] if f.startswith("at("))[4:-1]
            if cell in g["rock_at"]:
                seen.add(f"sampled({g['rock_at'][cell]})")
        i = t
    return None


def candidates(fact_sets: list) -> list:
    """Single facts and same-predicate pairs over the facts seen in the runs."""
    facts = sorted(set().union(*fact_sets)) if fact_sets else []
    groups: dict = {}
    for f in facts:
        if "(" in f:
            groups.setdefault(f.split("(")[0], []).append(f)
    cands = [frozenset([f]) for f in facts]
    for group in groups.values():
        cands += [frozenset([a, b]) for i, a in enumerate(group) for b in group[i + 1:]]
    return cands


def empirical_landmarks(fact_sets: list, initial: frozenset) -> set:
    """Minimal candidates that hold on every run, excluding facts true initially."""
    keep = [c for c in candidates(fact_sets)
            if not c & initial and all(c & fs for fs in fact_sets)]
    return {c for c in keep if not any(o < c for o in keep)}


def avoid_probability(g: dict, ctrl: dict, key: frozenset) -> float:
    """P(a run ends without any fact of `key` holding at a node), from the graph.
    Commitment facts are not node facts, so keys containing them return None."""
    if any(f.startswith(("chose(", "sampled(")) or f == "done" for f in key):
        return None
    blocked = {i for i, s in ctrl["node_state"].items() if s & key}
    value = {n["id"]: 0.0 for n in g["nodes"] if n["id"] in blocked}
    value.update({n["id"]: 1.0 for n in g["nodes"]
                  if n["kind"] != "inner" and n["id"] not in blocked})
    return first_hit(g, value)[0]

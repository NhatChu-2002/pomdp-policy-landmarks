"""Correctness of a RockSample policy's beliefs (research direction R2).

The policy graph records what the policy believes, not what is true. Rock qualities
are fixed except that sampling makes a rock bad, and the robot's moves are
deterministic, so the policy graph can be run jointly with the true rocks: a product
chain over (policy node, true rock bits). Observations come from a TRUE sensor whose
efficiency may differ from the model's (RockSample.jl: a check at distance d is
correct with probability (1 + exp(-d ln 2 / efficiency)) / 2).

The product chain answers what landmarks alone cannot: how often the policy ends
believing something false, samples a bad rock, or leaves a good rock behind.
"""

from __future__ import annotations

import math

import numpy as np

from .extraction import _belief

CHECK_OFFSET = 5          # RockSample.jl: action 5 + i checks rock i; 1 samples


def _cell(g: dict, node: dict):
    b = _belief(node)
    cells = {g["states"][i].split("|")[0] for i in b if g["states"][i] != "terminal"}
    return next(iter(cells)) if len(cells) == 1 else None


def product_chain(g: dict, efficiency: float = 20.0) -> dict:
    """Nodes (node id, true bits) reachable from the root, with transition
    probabilities under a sensor of the given efficiency."""
    rocks = {name: tuple(map(int, xy.split("-"))) for xy, name in g["rock_at"].items()}
    nodes = {n["id"]: n for n in g["nodes"]}
    out: dict = {}
    for e in g["edges"]:
        out.setdefault(e["from"], {}).setdefault(e["obs"], e["to"])
    root = g["nodes"][0]
    start = {}
    for i, p in _belief(root).items():
        bits = g["states"][i].split("|")[1]
        start[bits] = start.get(bits, 0.0) + p
    trans: dict = {}
    frontier = [(root["id"], bits) for bits in start]
    seen = set(frontier)
    while frontier:
        key = frontier.pop()
        nid, bits = key
        n = nodes[nid]
        succ = []
        if n["kind"] == "inner":
            a = n["action"]
            cell = _cell(g, n)
            new_bits = bits
            if a == "1" and cell is not None and cell.replace(",", "-") in g["rock_at"]:
                r = int(g["rock_at"][cell.replace(",", "-")][4:]) - 1
                new_bits = bits[:r] + "0" + bits[r + 1:]
            if a.isdigit() and int(a) > CHECK_OFFSET:
                r = int(a) - CHECK_OFFSET - 1
                rx, ry = rocks[f"rock{r + 1}"]
                x, y = map(int, cell.split(","))
                eff = 0.5 * (1 + math.exp(-math.hypot(x - rx, y - ry) * math.log(2) / efficiency))
                good = bits[r] == "1"
                for obs, p in (("1", eff if good else 1 - eff), ("2", 1 - eff if good else eff)):
                    if p > 0 and obs in out[nid]:
                        succ.append((p, (out[nid][obs], new_bits)))
                    elif p > 0:                   # observation the nominal model rules out
                        succ.append((p, ("impossible", new_bits)))
            else:
                (obs, child), = out[nid].items()
                succ.append((1.0, (child, new_bits)))
        trans[key] = succ
        for _, nxt in succ:
            if nxt not in seen and nxt[0] != "impossible":
                seen.add(nxt)
                frontier.append(nxt)
    return {"start": start, "trans": trans, "nodes": nodes}


def outcomes(g: dict, efficiency: float = 20.0, gamma: float = 0.95) -> dict:
    """Exact probabilities of correctness outcomes, and the expected return."""
    pc = product_chain(g, efficiency)
    keys = list(pc["trans"])
    ix = {k: i for i, k in enumerate(keys)}
    n_rocks = len(next(iter(pc["start"])))
    P = np.zeros((len(keys), len(keys)))
    for k, succ in pc["trans"].items():
        for p, nxt in succ:
            if nxt in ix:
                P[ix[k], ix[nxt]] += p
    x0 = np.zeros(len(keys))
    for bits, p in pc["start"].items():
        x0[ix[(g["nodes"][0]["id"], bits)]] = p
    # visit distribution (expected visits), then outcome probabilities at end states
    visits = np.linalg.solve(np.eye(len(keys)) - P.T, x0)
    reward = np.zeros(len(keys))
    end_mass, bad_samples = 0.0, 0.0
    good_left = np.zeros(n_rocks)
    bad_by_rock = np.zeros(n_rocks)
    initially_good = np.zeros(n_rocks)
    for bits, p in pc["start"].items():
        initially_good += p * np.array([c == "1" for c in bits])
    for k, i in ix.items():
        nid, bits = k
        n = pc["nodes"][nid]
        if n["kind"] == "terminal":
            end_mass += visits[i]
            good_left += visits[i] * np.array([c == "1" for c in bits])
        elif n["kind"] == "inner" and n["action"] == "1":
            cell = _cell(g, n)
            rock = g["rock_at"].get(cell.replace(",", "-")) if cell else None
            good = rock is not None and bits[int(rock[4:]) - 1] == "1"
            reward[i] = 20.0 if good else -10.0
            bad_samples += visits[i] * (not good)
            if rock is not None and not good:
                bad_by_rock[int(rock[4:]) - 1] += visits[i]
        if n["kind"] == "inner" and any(nx in ix and pc["nodes"][nx[0]]["kind"] == "terminal"
                                        for _, nx in pc["trans"][k]):
            reward[i] += 10.0
    value = np.linalg.solve(np.eye(len(keys)) - gamma * P, reward) @ x0
    return {"efficiency": efficiency, "p_end": round(float(end_mass), 6),
            "expected_bad_samples": round(float(bad_samples), 4),
            "good_rocks_left_behind": [round(float(v), 4) for v in good_left],
            "bad_samples_by_rock": [round(float(v), 4) for v in bad_by_rock],
            "good_rocks_initially": [round(float(v), 4) for v in initially_good],
            "value": round(float(value), 3)}

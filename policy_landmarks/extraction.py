"""Controllers extracted from a solved policy (no hand-writing, no sampling).

pomdp/extract_policy_graph.jl enumerates every belief a SARSOP policy reaches
from the initial belief, following the policy's action and every observation
with nonzero probability. This module abstracts each belief into graded
evidence facts and compiles the resulting controller graph into PDDL:

  ev-V(lvl)    evidence about hidden variable V: unk, or posK / negK, the log-odds
               of V's first value in units of one observation (Tiger) or binned
               at |lo| = 0.5, 2.5, 4.5 (RockSample, whose sensor accuracy varies)
  at(cell)     the observable robot position (RockSample)
  sampled(R)   the policy sampled rock R           (commitment, add-only)
  chose(A)     the policy took terminal decision A (commitment, e.g. open a door)
  done         the episode ended

Each controller edge becomes one action whose precondition is the full
abstract source state. Every positive-probability execution of the policy is
therefore a plan, so every landmark of the task holds on every execution
(the controller over-approximates the policy; it is exact when the abstraction
keeps reachable beliefs apart).
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import numpy as np

BINS = (0.5, 2.5, 4.5)       # |log-odds| thresholds for evidence levels 1, 2, 3
EPS = 1e-9
RS_SAMPLE = "1"              # RockSample.jl: 1 sample, 2-5 move N/E/S/W, 5+i check rock i


def level(p: float, unit: float | None = None, prior: float = 0.5) -> str:
    """Evidence level of P(first value) = p: log-odds relative to the prior,
    in units of `unit` (one observation), else binned."""
    p = min(1 - EPS, max(EPS, p))
    lo = math.log(p / (1 - p)) - math.log(prior / (1 - prior))
    k = min(9, round(abs(lo) / unit)) if unit else sum(abs(lo) >= b for b in BINS)
    return "unk" if k == 0 else ("pos" if lo > 0 else "neg") + str(k)


def unit_of(g: dict) -> float | None:
    """Tiger, Sensor: one observation's log-odds, so level k = k net consistent readings."""
    if g["problem"] in ("tiger", "sensor", "probe"):
        return math.log(g["p_correct"] / (1 - g["p_correct"]))
    return None


def _belief(node) -> dict:
    return {int(i): float(p) for i, p in (t.split(":") for t in node["belief"].split())}


def load(path: Path) -> dict:
    return json.loads(Path(path).read_text())


def hidden_vars(g: dict) -> list:
    if g["problem"] == "tiger":
        return ["direction"]                       # pos = tiger left
    if g["problem"] == "sensor":
        return ["sensor-a", "sensor-b"]            # pos = sensor ok
    if g["problem"] == "probe":
        return [f"v{i + 1}" for i in range(g["k"])]  # pos = this value is the hidden one
    k = len(next(s for s in g["states"] if s != "terminal").split("|")[1])
    return [f"rock{i + 1}" for i in range(k)]      # pos = rock good


def abstract(g: dict, belief: dict) -> frozenset:
    states = g["states"]
    if all(states[i] == "terminal" for i in belief):
        return frozenset({"terminal"})
    vars_ = hidden_vars(g)
    marg = dict.fromkeys(vars_, 0.0)
    cells = set()
    for i, p in belief.items():
        s = states[i]
        if g["problem"] == "tiger":
            marg["direction"] += p if s == "left" else 0.0
            continue
        if g["problem"] == "probe":
            if s in marg:
                marg[s] += p
            continue
        if g["problem"] == "sensor":
            if s != "done":
                marg["sensor-a"] += p if s.startswith("a-ok") else 0.0
                marg["sensor-b"] += p if s.endswith("b-ok") else 0.0
            continue
        xy, bits = s.split("|")
        cells.add(xy)
        for j, c in enumerate(bits):
            marg[f"rock{j + 1}"] += p if c == "1" else 0.0
    assert len(cells) <= 1, "robot position is observable in RockSample"
    prior = 1 / len(vars_) if g["problem"] == "probe" else 0.5   # evidence is relative to the prior
    facts = {f"ev-{v}({level(marg[v], unit_of(g), prior)})" for v in vars_}
    return frozenset(facts | {f"at(c{xy.replace(',', '-')})" for xy in cells})


def controller(g: dict) -> dict:
    """Quotient of the policy graph under the abstraction."""
    nodes = {n["id"]: n for n in g["nodes"]}
    state = {i: abstract(g, _belief(n)) for i, n in nodes.items()}
    edges = set()
    for e in g["edges"]:
        src, a = state[e["from"]], nodes[e["from"]]["action"]
        effect = set()
        if g["problem"] == "rocksample" and a == RS_SAMPLE:
            cell = next(f for f in src if f.startswith("at("))[4:-1]
            effect.add(f"sampled({g['rock_at'][cell]})")
        edges.add((src, a, e["obs"], state[e["to"]], frozenset(effect)))
    commits = {(state[i], n["action"]) for i, n in nodes.items() if n["kind"] == "commit_end"}
    return {"init": state[0], "edges": edges, "commits": commits, "node_state": state,
            "policy_nodes": len(nodes), "policy_edges": len(g["edges"]),
            "controller_states": len(set(state.values()))}


def _chain(g: dict):
    """Node ids, their index, and the transition matrix of the policy graph."""
    ids = [n["id"] for n in g["nodes"]]
    ix = {i: k for k, i in enumerate(ids)}
    P = np.zeros((len(ids), len(ids)))
    for e in g["edges"]:
        P[ix[e["from"]], ix[e["to"]]] += e["p"]
    return ids, ix, P


def first_hit(g: dict, value: dict) -> tuple[float, float | None]:
    """Run the policy's Markov chain from the root until it first enters a node of
    `value` (node id -> number) or an end node. Returns E[value of that node] and
    E[steps to it], the latter weighted by value (so with 0/1 values it is the
    expected time to the target given that the target is reached)."""
    ids, ix, P = _chain(g)
    v = np.array([value.get(i, 0.0) for i in ids])
    free = np.array([n["kind"] == "inner" and n["id"] not in value for n in g["nodes"]])
    # Free nodes that can reach a nonzero target; elsewhere h = m = 0. Restricted to
    # them, I - P is invertible because every such node is transient.
    live = (v != 0) & ~free
    while True:
        grow = free & ~live & (P[:, live].sum(axis=1) > 0)
        if not grow.any():
            break
        live |= grow
    R = np.flatnonzero(free & live)
    h, m = np.where(free, 0.0, v), np.zeros(len(ids))
    if len(R):
        A = np.eye(len(R)) - P[np.ix_(R, R)]
        h[R] = np.linalg.solve(A, P[R] @ np.where(free, 0.0, v))
        m[R] = np.linalg.solve(A, P[R] @ h)
    r = ix[g["nodes"][0]["id"]]
    return float(h[r]), (float(m[r] / h[r]) if h[r] > 1e-12 else None)


def p_end_within(g: dict, steps: int) -> float:
    """Probability that the policy reaches an end node within `steps` steps."""
    _, _, P = _chain(g)
    end = np.array([n["kind"] != "inner" for n in g["nodes"]])
    x = np.zeros(len(end)); x[0] = 1.0
    for _ in range(steps):
        x = x @ P + np.where(end, x, 0.0)        # end nodes have no edges: keep their mass
    return float(x[end].sum())


def _reward(g: dict, node: dict) -> float:
    """Expected immediate reward of the node's action under its belief (models in extract_policy_graph.jl)."""
    b, states, a = _belief(node), g["states"], node["action"]
    if g["problem"] == "tiger":
        return -1.0 if a == "listen" else sum(p * (-100.0 if states[i] == a else 10.0) for i, p in b.items())
    if g["problem"] in ("sensor", "probe"):
        if not a.startswith("commit"):
            return -1.0
        right = sum(p for i, p in b.items() if a == f"commit-{states[i]}")
        return 20.0 * right - 20.0 * (1 - right)
    if a != RS_SAMPLE:                           # RockSample: moves and checks are free
        return 0.0
    total = 0.0
    for i, p in b.items():
        xy, bits = states[i].split("|")
        rock = g["rock_at"].get(xy.replace(",", "-"))
        total += p * (20.0 if rock and bits[int(rock[4:]) - 1] == "1" else -10.0)
    return total


def policy_value(g: dict, gamma: float = 0.95) -> float:
    """Exact discounted value of the extracted graph at the initial belief.
    Tiger restarts from the initial belief after a door is opened; RockSample earns
    10 for exiting (an edge into the terminal node)."""
    ids, ix, P = _chain(g)
    kind = np.array([n["kind"] for n in g["nodes"]])
    r = np.array([_reward(g, n) if n["kind"] != "terminal" else 0.0 for n in g["nodes"]])
    if g["problem"] == "rocksample":
        r += 10.0 * P[:, kind == "terminal"].sum(axis=1)
    if g["problem"] == "tiger":
        P[kind == "commit_end", 0] = 1.0         # the next episode starts from b0 (node 0)
    return float(np.linalg.solve(np.eye(len(ids)) - gamma * P, r)[0])


def landmark_timeline(g: dict, ctrl: dict, facts: frozenset) -> dict:
    """For a landmark (abstract facts, any of which suffices): P(the policy reaches it),
    expected steps until it first holds, and how often each fact is the one reached."""
    hits = {i: s & facts for i, s in ctrl["node_state"].items() if s & facts}
    p, steps = first_hit(g, dict.fromkeys(hits, 1.0))
    split = {f: first_hit(g, {i: float(f in h) for i, h in hits.items()})[0] for f in sorted(facts)}
    return {"p_reach": round(p, 6), "expected_steps": None if steps is None else round(steps, 3),
            "first_reached": {f: round(q, 4) for f, q in split.items() if q > 0}}


def _atom(f: str) -> str:
    return f"({f.replace('(', ' ').rstrip(')')})" if "(" in f else f"({f})"


def to_pddl(ctrl: dict, name: str) -> tuple[str, str]:
    """One action per controller edge; preconditions are the full source state."""
    actions = []
    for i, (s, a, o, t, extra) in enumerate(sorted(ctrl["edges"], key=str)):
        if "terminal" in t:
            eff = ["(done)"]
        else:
            eff = [_atom(f) for f in sorted(t - s)] + [f"(not {_atom(f)})" for f in sorted(s - t)]
        eff += [_atom(f) for f in sorted(extra)]
        actions.append(_action(f"e{i}-a{_san(a)}-o{_san(o)}", s, eff))
    for j, (s, a) in enumerate(sorted(ctrl["commits"], key=str)):
        actions.append(_action(f"c{j}-{_san(a)}", s, [_atom(f"chose({_san(a)})"), "(done)"]))

    facts = set(ctrl["init"])
    for s, _, _, t, extra in ctrl["edges"]:
        facts |= s | t | extra
    facts |= {f"chose({_san(a)})" for _, a in ctrl["commits"]}
    facts.discard("terminal")
    unary = sorted({f.split("(")[0] for f in facts if "(" in f})
    zero = sorted({f for f in facts if "(" not in f} | {"done"})
    objs = sorted({f.split("(")[1].rstrip(")") for f in facts if "(" in f})
    domain = "\n".join([
        f"(define (domain {name})",
        "  (:requirements :strips)",
        "  (:predicates " + " ".join(f"({p} ?x)" for p in unary)
        + " " + " ".join(f"({z})" for z in zero) + ")",
        *actions, ")"])
    problem = "\n".join([
        f"(define (problem p-{name}) (:domain {name})",
        f"  (:objects {' '.join(objs)})",
        "  (:init " + " ".join(_atom(f) for f in sorted(ctrl["init"])) + ")",
        "  (:goal (done)))"])
    return domain, problem


def _action(name: str, pre: frozenset, eff: list) -> str:
    precond = " ".join(_atom(f) for f in sorted(pre) if f != "terminal")
    return (f"  (:action {name} :parameters ()\n    :precondition (and {precond})\n"
            f"    :effect (and {' '.join(eff)}))")


def _san(x) -> str:
    return "".join(c if c.isalnum() else "-" for c in str(x)).lower()

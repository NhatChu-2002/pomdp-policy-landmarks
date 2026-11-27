"""Landmark verification by counterexample-guided refinement (direction R3c).

To decide whether a fact set F is a landmark of an alpha-vector policy, search a
compact rule task (rules.py) for a plan that avoids F (Fast Downward, lazy greedy
with FF). No plan: F is a landmark - sound, because the rule task over-approximates
the policy. A plan: replay it with exact log-odds. If it is a real run of the policy,
F is certified not to be a landmark. Otherwise refine at the first divergence and
search again:

* the rule used covers beliefs where the action is impossible -> split one of its
  coarse context classes into fine cells (each child re-checked by the box test);
* an evidence shift lands in two cells and the plan picked the one the true belief
  never reaches -> split the source cell at the crossing point (the smallest double
  whose shifted value reaches the edge, so the halves map apart exactly);
* the action is possible somewhere in the fine cells but is not the policy's choice
  at the exact belief -> halve a fine cell.

Fine cells are kept as intervals; a cell split replaces every rule that uses the cell
by its two halves (re-checked), so the rules keep covering every belief where the
policy can act. Verdicts are three-valued: landmark / certified non-landmark /
unknown (iteration budget exhausted).
"""

from __future__ import annotations

import bisect
import itertools
import time
from pathlib import Path

import numpy as np

from .planner import run_fd_sas
from .rules import COARSE
from .symbolic import EPS, INF, SAFETY, Grid, Model, threshold


def _class(lo: float, hi: float, edges) -> int:
    return 0 if hi <= edges[0] else 2 if lo >= edges[1] else 1


def _box(model, assign, edges):
    box = []
    for v in range(len(model.vars)):
        kind, x = assign[v]
        box.append(x if kind == "f" else (-INF, INF) if kind == "a"
                   else ((-INF, edges[0]), (edges[0], edges[1]), (edges[1], INF))[x])
    return box


def _matches(entry, cell, edges) -> bool:
    """Does a rule's entry for one variable (any / coarse class / fine cell) contain the cell?"""
    kind, x = entry
    return kind == "a" or (x == cell if kind == "f" else _class(*cell, edges) == x)


def _acted(model, pos, a):
    return next((v for _, v, s, _, _ in model.step(pos, a) if v is not None and s is not None), None)


def _cells(grid: Grid, v: int) -> list:
    e = grid.edges[v]
    return [(e[i], e[i + 1]) for i in range(len(e) - 1)]


def initial_rules(model: Model, grid: Grid, positions: list, edges, context: str = "coarse") -> list:
    """[(pos, a, assign)]: assign[v] = ("f", (lo, hi)) for the acted variable; the others
    get every coarse class ("k", class), or with context="any" a single unconstrained
    entry ("a", None), so the rule count is linear in the number of variables and
    refinement adds classes only where plans need them. Covers every belief where the
    policy can act."""
    k = len(model.vars)
    out = []
    for pos in positions:
        for a in sorted(model.possible_actions(pos, [(-INF, INF)] * k)):
            acted = _acted(model, pos, a)
            others = [v for v in range(k) if v != acted]
            contexts = ([{v: ("a", None) for v in others}] if context == "any" else
                        [{v: ("k", cl) for v, cl in zip(others, classes)}
                         for classes in itertools.product(range(3), repeat=len(others))])
            for ctx in contexts:
                for cell in (_cells(grid, acted) if acted is not None else [None]):
                    assign = dict(ctx)
                    if acted is not None:
                        assign[acted] = ("f", cell)
                    if a in model.possible_actions(pos, _box(model, assign, edges)):
                        out.append((pos, a, assign))
    return out


def _rest(grid, v, entry, pin, edges) -> list:
    """Entries covering `entry`'s range minus `pin` (pin is a class or a fine cell inside it)."""
    kind, x = entry
    pk, px = pin
    cls = px if pk == "k" else _class(*px, edges)
    out = [("k", k) for k in range(3) if k != cls] if kind == "a" else []
    if pk == "f":
        out += [("f", c) for c in _cells(grid, v) if _class(*c, edges) == cls and c != px]
    return out


def split_away(model, grid, rule, fine: list, edges) -> list:
    """Cut out of a rule the region around a spurious step's fine box, where its action is
    impossible. A minimal set S of variables is pinned (to coarse classes if that already
    excludes the action, else to the plan's fine cells); the rest of the rule is covered
    by a decision list over S (v1 elsewhere | v1 pinned, v2 elsewhere | ...), each child
    re-checked. One round removes the step, however many variables it needs."""
    pos, a, assign = rule
    free = [v for v, (kind, _) in assign.items() if kind != "f"]

    def pinned(level, v):
        kind = assign[v][0]
        if level == "k":
            return ("k", _class(*fine[v], edges)) if kind == "a" else assign[v]
        return ("f", fine[v])

    def possible(asg):
        return a in model.possible_actions(pos, _box(model, asg, edges))

    level = next(lv for lv in ("k", "f") if not possible({**assign, **{v: pinned(lv, v) for v in free}}))
    S = [v for v in free if pinned(level, v) != assign[v]]
    for v in list(S):                                  # drop variables not needed to exclude a
        T = [u for u in S if u != v]
        if not possible({**assign, **{u: pinned(level, u) for u in T}}):
            S = T
    kids, prefix = [], dict(assign)
    for v in S:
        for entry in _rest(grid, v, assign[v], pinned(level, v), edges):
            child = {**prefix, v: entry}
            if possible(child):
                kids.append((pos, a, child))
        prefix[v] = pinned(level, v)
    return kids


def split_cell(model, grid, rules, var, at, edges) -> bool:
    """Add an edge at `at` to var's grid and split every rule using that fine cell."""
    e = grid.edges[var]
    if at in e or not (e[0] < at < e[-1]):
        return False
    i = bisect.bisect_left(e, at)
    old = (e[i - 1], e[i])
    e.insert(i, at)
    halves = [(old[0], at), (at, old[1])]
    new = []
    for pos, a, assign in rules:
        if assign.get(var) == ("f", old):
            for h in halves:
                child = {**assign, var: ("f", h)}
                if a in model.possible_actions(pos, _box(model, child, edges)):
                    new.append((pos, a, child))
        else:
            new.append((pos, a, assign))
    rules[:] = new
    return True


def compile_task(model, grid, rules, banned_cells: dict, edges, region: dict, name="cegar"):
    """STRIPS with fine (cv-) and coarse (ck-) facts. `banned_cells` maps a variable to
    the set of fine-cell intervals inside the candidate; actions entering one are
    dropped. Action names r{rule}-o{outcome}-t{target cell index}.
    The initial belief is any product prior in `region` ({var: (lo, hi)} log-odds; lo ==
    hi is a point): actions p{var}-c{cell} pick a start cell per variable, then `start`.
    A start cell inside the candidate is not offered (those priors satisfy it at once)."""
    actions = []
    index = [{cell: c for c, cell in enumerate(_cells(grid, v))} for v in range(len(model.vars))]

    def at(pos):
        return f"(at c{pos[0]}-{pos[1]})" if pos is not None else None

    for i, (pos, a, assign) in enumerate(rules):
        pre = ["(live)"] + ([at(pos)] if pos is not None else [])
        for v, (kind, x) in assign.items():
            if kind != "a":
                pre.append(f"(cv-{model.vars[v]} c{index[v][x]})" if kind == "f"
                           else f"(ck-{model.vars[v]} {COARSE[x]})")
        for j, (obs, v, shift, npos, term) in enumerate(model.step(pos, a)):
            if term:
                actions.append((f"r{i}-o{j}-tend", pre, ["(done)", "(not (live))"]))
                continue
            src = assign[v][1] if v is not None and shift is not None else None
            targets = [None]
            if src is not None:
                lo, hi = src
                targets = list(grid.successors(v, lo, hi, shift))
            for t in targets:
                eff = []
                if t is not None and t != index[v][src]:
                    tcell = _cells(grid, v)[t]
                    if tcell in banned_cells.get(v, ()):
                        continue
                    eff += [f"(cv-{model.vars[v]} c{t})", f"(not (cv-{model.vars[v]} c{index[v][src]}))"]
                    k0, k1 = _class(*src, edges), _class(*tcell, edges)
                    if k0 != k1:
                        eff += [f"(ck-{model.vars[v]} {COARSE[k1]})", f"(not (ck-{model.vars[v]} {COARSE[k0]}))"]
                if pos is not None and npos != pos:
                    eff += [at(npos), f"(not {at(pos)})"]
                actions.append((f"r{i}-o{j}-t{t}", pre, eff or ["(live)"]))
    for v, var in enumerate(model.vars):
        for c, cell in enumerate(_cells(grid, v)):
            if _in_region(cell, *region[v]) and cell not in banned_cells.get(v, ()):
                actions.append((f"p{v}-c{c}", [f"(pick-{var})"],
                                [f"(cv-{var} c{c})", f"(ck-{var} {COARSE[_class(*cell, edges)]})",
                                 f"(picked-{var})", f"(not (pick-{var}))"]))
    actions.append(("start", [f"(picked-{var})" for var in model.vars], ["(live)"]))
    n_cells = max(len(e) - 1 for e in grid.edges)
    preds = (["(live)", "(done)", "(at ?p)"] + [f"(cv-{v} ?c)" for v in model.vars]
             + [f"(ck-{v} ?k)" for v in model.vars] + [f"(pick-{v})" for v in model.vars]
             + [f"(picked-{v})" for v in model.vars])
    objs = {f"c{c}" for c in range(n_cells)} | set(COARSE)
    if model.problem == "rocksample":
        objs |= {f"c{x}-{y}" for x in range(1, model.n + 1) for y in range(1, model.n + 1)}
    domain = "\n".join([f"(define (domain {name})", "  (:requirements :strips)",
                        "  (:predicates " + " ".join(preds) + ")"]
                       + [f"  (:action {n} :parameters ()\n    :precondition (and {' '.join(p)})\n"
                          f"    :effect (and {' '.join(e)}))" for n, p, e in actions] + [")"])
    init = [f"(pick-{var})" for var in model.vars] + ([at(model.start())] if model.start() is not None else [])
    problem = "\n".join([f"(define (problem p-{name}) (:domain {name})", f"  (:objects {' '.join(sorted(objs))})",
                         "  (:init " + " ".join(init) + ")", "  (:goal (done)))"])
    return domain, problem


class RelativeModel:
    """The region problem with prior-relative levels. Per hidden variable V there are two
    coordinates: the evidence d_V (sum of the observation shifts so far, 0 for every prior,
    and binned for the levels) and the prior p_V (fixed during a run, picked from the
    region); the policy sees lambda_V = p_V + d_V. Variables 0..k-1 are evidence, k..2k-1
    priors, so the CEGAR code runs unchanged: shifts act on evidence variables, the box
    test runs on the interval sum, and refinement may split prior cells too."""

    def __init__(self, base):
        self.base, self.k = base, len(base.vars)
        self.vars = list(base.vars) + [f"prior-{v}" for v in base.vars]
        self.A, self.actions, self.problem = base.A, base.actions, base.problem
        self.n = getattr(base, "n", None)

    def start(self):
        return self.base.start()

    def step(self, pos, a):
        return self.base.step(pos, a)

    def corner(self, pos, coords):
        return self.base.corner(pos, [coords[v] + coords[self.k + v] for v in range(self.k)])

    def possible_actions(self, pos, box):
        return self.base.possible_actions(
            pos, [(box[v][0] + box[self.k + v][0], box[v][1] + box[self.k + v][1]) for v in range(self.k)])


def compile_sas(model, grid, rules, banned_cells: dict, edges, region: dict) -> str:
    """The task of compile_task written directly in Fast Downward's SAS+ format, so no
    translator run is needed (it took ~6 s of each ~7 s planner call on RockSample).
    Variables: phase (setup, live, done); per hidden variable its fine cell, its coarse
    class, and a picked flag (cell and class 'none' until picked); the robot cell.
    Same actions, names and goal; actions that change nothing are left out."""
    k = len(model.vars)
    cells = [_cells(grid, v) for v in range(k)]
    index = [{cell: c for c, cell in enumerate(cs)} for cs in cells]
    names: list = [("phase", ["setup", "live", "done"])]
    CV = [len(names) + 3 * v for v in range(k)]                  # var ids: cell, class, picked
    for v, var in enumerate(model.vars):
        names += [(f"cv-{var}", [f"c{c}" for c in range(len(cells[v]))] + ["none"]),
                  (f"ck-{var}", list(COARSE) + ["none"]), (f"picked-{var}", ["no", "yes"])]
    positions = ([(x, y) for x in range(1, model.n + 1) for y in range(1, model.n + 1)]
                 if model.start() is not None else [])
    AT = len(names) if positions else None
    if positions:
        names.append(("at", [f"c{x}-{y}" for x, y in positions]))
    pos_ix = {p: i for i, p in enumerate(positions)}
    ops = []

    def op(name, prevail, effects):
        changed = {var for var, _, _ in effects}
        ops.append((name, [(var, val) for var, val in prevail if var not in changed], effects))

    for i, (pos, a, assign) in enumerate(rules):
        pre = [(0, 1)] + ([(AT, pos_ix[pos])] if pos is not None else [])
        for v, (kind, x) in assign.items():
            if kind != "a":
                pre.append((CV[v], index[v][x]) if kind == "f" else (CV[v] + 1, x))
        for j, (obs, v, shift, npos, term) in enumerate(model.step(pos, a)):
            if term:
                op(f"r{i}-o{j}-tend", pre, [(0, 1, 2)])
                continue
            src = assign[v][1] if v is not None and shift is not None else None
            targets = list(grid.successors(v, *src, shift)) if src is not None else [None]
            for t in targets:
                eff = []
                if t is not None and t != index[v][src]:
                    if cells[v][t] in banned_cells.get(v, ()):
                        continue
                    eff.append((CV[v], index[v][src], t))
                    k0, k1 = _class(*src, edges), _class(*cells[v][t], edges)
                    if k0 != k1:
                        eff.append((CV[v] + 1, -1, k1))
                if pos is not None and npos != pos:
                    eff.append((AT, pos_ix[pos], pos_ix[npos]))
                if eff:
                    op(f"r{i}-o{j}-t{t}", pre, eff)
    for v in range(k):
        for c, cell in enumerate(cells[v]):
            if _in_region(cell, *region[v]) and cell not in banned_cells.get(v, ()):
                op(f"p{v}-c{c}", [], [(CV[v] + 2, 0, 1), (CV[v], len(cells[v]), c),
                                      (CV[v] + 1, len(COARSE), _class(*cell, edges))])
    op("start", [(CV[v] + 2, 1) for v in range(k)], [(0, 0, 1)])
    init = [0] + [x for v in range(k) for x in (len(cells[v]), len(COARSE), 0)] + (
        [pos_ix[model.start()]] if positions else [])
    out = ["begin_version", "3", "end_version", "begin_metric", "0", "end_metric", str(len(names))]
    for n, (var, values) in enumerate(names):
        out += ["begin_variable", f"var{n}", "-1", str(len(values))] + [f"Atom {var}({x})" for x in values] + ["end_variable"]
    out += ["0", "begin_state"] + [str(x) for x in init] + ["end_state", "begin_goal", "1", "0 2", "end_goal", str(len(ops))]
    for name, prevail, effects in ops:
        out += ["begin_operator", name, str(len(prevail))] + [f"{a} {b}" for a, b in prevail]
        out += [str(len(effects))] + [f"0 {a} {b} {c}" for a, b, c in effects] + ["1", "end_operator"]
    out.append("0")
    return "\n".join(out) + "\n"


def _in_region(cell, lo, hi) -> bool:
    """Does a half-open cell meet the closed region [lo, hi] (a point if lo == hi)? A cell
    that starts exactly at hi holds the prior hi, so it counts (corner priors found this)."""
    return cell[0] <= lo < cell[1] if lo == hi else cell[0] <= hi and lo < cell[1]


def _witness(cell, lo, hi, frac: float = 0.5) -> float:
    """A concrete prior log-odds inside both the start cell and the region, at `frac`
    of the way through their intersection."""
    a, b = max(cell[0], lo), min(cell[1], hi)
    return lo if lo == hi else a + frac * (b - a)


def _banned(grid, candidate) -> dict:
    """candidate: {var index: (lo, hi) ranges of log-odds}; banned fine cells inside them."""
    out = {}
    for v, ranges in candidate.items():
        out[v] = {cell for cell in _cells(grid, v) if any(lo <= cell[0] and cell[1] <= hi for lo, hi in ranges)}
    return out


def _next(lam_v: float, shift: float, a: str):
    """Log-odds after an observation, or None if it is impossible. An infinite shift
    sets the value (sample: the rock becomes bad; a perfect check at distance 0)."""
    if shift in (INF, -INF):
        return None if a != "1" and lam_v == -shift else shift
    return lam_v + shift


def exact_graph(model, lam0, max_nodes: int = 200_000):
    """The policy's reachable belief graph from the product prior lam0 (log-odds per
    variable), following the alpha-vector argmax exactly as replay does. Returns
    (start, succ) with succ[node] = successor nodes or "end"; nodes are (pos, lam) with
    lam rounded to 1e-12 so equal beliefs merge (as the Julia policy graphs do)."""
    start = (model.start(), tuple(lam0))
    succ, todo = {}, [start]
    while todo:
        node = todo.pop()
        if node in succ:
            continue
        if len(succ) >= max_nodes:
            raise RuntimeError("belief graph too large")
        pos, lam = node
        a = model.actions[int((model.A @ model.corner(pos, list(lam))).argmax())]
        out = []
        for obs, v, shift, npos, term in model.step(pos, a):
            if term:
                out.append("end")
                continue
            new = list(lam)
            if v is not None and shift is not None:
                x = _next(lam[v], shift, a)
                if x is None:
                    continue
                new[v] = x if x in (INF, -INF) else round(x, 12)
            out.append((npos, tuple(new)))
            todo.append(out[-1])
        succ[node] = out
    return start, succ


def exact_landmark(start, succ, v: int, ranges) -> bool:
    """Does every terminating run of the graph reach variable v's log-odds in a range
    (half-open [lo, hi), as grid cells are)?"""
    def hit(node):
        x = node[1][v]
        return any(lo <= x < hi or x == hi == INF for lo, hi in ranges)
    if hit(start):
        return True
    seen, todo = {start}, [start]
    while todo:
        for nxt in succ[todo.pop()]:
            if nxt == "end":
                return False
            if nxt not in seen and not hit(nxt):
                seen.add(nxt)
                todo.append(nxt)
    return True


def replay(model, grid, rules, steps, lam0):
    """Exact replay. Returns None if the plan is a real run of the policy, else
    (kind, details) for the first divergence. The log-odds follow the double-precision
    update lam[v] + shift, the semantics the successor cells are exact for, so cells are
    decided exactly. A step is a "tie", which the float replay cannot decide, if an action
    margin is within the dot-product error (n + 5k + 2) eps |A| b (Higham's gamma_n, plus
    the sigmoids)."""
    lam = list(lam0)
    acts = np.array(model.actions)
    for name in steps:
        i, j, t = name.split("-")[:3]
        pos, a, assign = rules[int(i[1:])]
        b = model.corner(pos, lam)
        vals = model.A @ b
        best = vals.max()
        if model.actions[int(vals.argmax())] != a:
            return ("action", int(i[1:]), list(lam))
        others = vals[acts != a]
        bound = (b.size + 5 * len(lam) + 2) * EPS * float((np.abs(model.A) @ np.abs(b)).max())
        if others.size and best - others.max() <= SAFETY * 2 * bound:
            return ("tie", int(i[1:]), list(lam))
        obs, v, shift, npos, term = model.step(pos, a)[int(j[1:])]
        if term:
            return None
        if v is not None and shift is not None:
            new = _next(lam[v], shift, a)
            if new is None:                                  # perfect check contradicting certainty
                return ("observation", int(i[1:]), list(lam))
            if t != "tNone" and grid.cell(v, new) != int(t[1:]):
                return ("cell", int(i[1:]), (v, lam[v], shift, int(t[1:])))
            lam[v] = new
    return None


def verify(model: Model, grid: Grid, rules: list, candidate: dict, workdir: Path, edges,
           max_iter: int = 400, trace: list | None = None, region: dict | None = None,
           time_limit: float | None = None) -> dict:
    """candidate: {var: [(lo, hi), ...]} log-odds ranges (e.g. a level or two levels).
    region: {var: (lo, hi)} set of product priors (default: the point 0, a uniform prior).
    "landmark": True means every run from every prior in the region reaches the
    candidate; a certified False comes with a witness prior in the region.
    trace, if given, gets one (refinement kind, plan length, rules, planner seconds) per round.
    time_limit (seconds), if given, stops refining and returns undecided."""
    region = region or {v: (0.0, 0.0) for v in range(len(model.vars))}
    t0 = time.perf_counter()
    for it in range(max_iter):
        if time_limit is not None and time.perf_counter() - t0 > time_limit:
            return {"landmark": None, "iterations": it, "reason": "time limit", "rules": len(rules)}
        banned = _banned(grid, candidate)
        run = run_fd_sas(workdir, compile_sas(model, grid, rules, banned, edges, region), "lazy_greedy([ff()])")
        plan_file = workdir / "sas_plan"
        if not plan_file.exists():
            if not run["exhausted"]:                           # crash or out of memory: no proof
                return {"landmark": None, "iterations": it, "reason": "planner gave up", "rules": len(rules)}
            return {"landmark": True, "iterations": it, "rules": len(rules)}
        steps = [l.strip("() \n").split()[0] for l in plan_file.read_text().splitlines() if l.startswith("(")]
        plan_file.unlink()
        picks = {int(x.split("-")[0][1:]): int(x.split("-")[1][1:]) for x in steps if x.startswith("p")}
        steps = [x for x in steps if x.startswith("r")]
        lam0 = [_witness(_cells(grid, v)[picks[v]], *region[v]) for v in range(len(model.vars))]
        # 1. fine-cell check: each rule must be possible at the plan's fine cells. Every
        # spurious step is refined at once (one planner call per batch, not per split).
        # Every rule that applies at a visited abstract state is checked, not only the one
        # the plan used: one box test per state catches the alternatives the planner
        # would otherwise find one round at a time.
        at_pos: dict = {}
        for idx, rule in enumerate(rules):
            at_pos.setdefault(rule[0], []).append(idx)
        cells = [picks[v] for v in range(len(model.vars))]
        spurious = {}
        for name in steps:
            i, j, t = name.split("-")[:3]
            pos, a, assign = rules[int(i[1:])]
            box = [_cells(grid, v)[cells[v]] for v in range(len(model.vars))]
            here = model.possible_actions(pos, box)
            for r2 in at_pos[pos]:
                _, a2, asg2 = rules[r2]
                if a2 not in here and r2 not in spurious and all(
                        _matches(asg2[v], box[v], edges) for v in range(len(model.vars))):
                    spurious[r2] = list(box)
            obs, v, shift, npos, term = model.step(pos, a)[int(j[1:])]
            if not term and t != "tNone" and v is not None and shift is not None:
                cells[v] = int(t[1:])
        if trace is not None:
            trace.append(("spurious" if spurious else "replay", len(steps), len(rules), round(run["wall"], 2)))
        if spurious:
            for r in sorted(spurious, reverse=True):          # high indices first: low ones stay valid
                kids = split_away(model, grid, rules[r], spurious[r], edges)
                rules[r:r + 1] = kids
            continue
        # 2. exact replay
        div = replay(model, grid, rules, steps, lam0)
        # A tie is usually an artifact of the witness (symmetric variables get equal priors,
        # so two actions' values agree), so try other priors in the same start cells, offset
        # per variable to break symmetry, before giving up.
        for frac in (0.382, 0.618, 0.25, 0.75):
            if div is None or div[0] != "tie":
                break
            alt = [_witness(_cells(grid, v)[picks[v]], *region[v], (frac + 0.236 * v) % 1)
                   for v in range(len(model.vars))]
            if alt != lam0:
                lam0, div = alt, replay(model, grid, rules, steps, alt)
        if div is None:
            return {"landmark": False, "certified": True, "witness": lam0, "iterations": it, "rules": len(rules)}
        kind, r, info = div
        if trace is not None:
            trace[-1] = (kind,) + trace[-1][1:]
        if kind == "cell":                                     # split the source at the crossing
            v, lam, shift, t = info
            src = _cells(grid, v)[grid.cell(v, lam)]
            tcell = _cells(grid, v)[t]
            edge = tcell[0] if tcell[0] > lam + shift else tcell[1]
            if not split_cell(model, grid, rules, v, threshold(edge, shift), edges):
                split_cell(model, grid, rules, v, _mid(src), edges)
        elif kind == "action":                                 # policy's choice differs: halve
            pos, a, _ = rules[r]
            pick = _shrink(model, grid, pos, a, info)
            if pick is None:
                return {"landmark": None, "iterations": it, "reason": "exact belief", "rules": len(rules)}
            split_cell(model, grid, rules, *pick, edges)
        else:   # "observation" (impossible from a certain belief) or "tie": no split decides it
            return {"landmark": None, "iterations": it, "reason": kind, "rules": len(rules)}
    return {"landmark": None, "iterations": max_iter, "rules": len(rules)}


def _shrink(model, grid, pos, a, lam):
    """(variable, point) to split the fine box around the exact belief `lam`: prefer a
    variable whose half holding lam already excludes action a, else the widest cell.
    Certain variables (+-inf) are skipped: splitting their end cell cannot isolate them."""
    k = len(model.vars)
    cells = [_cells(grid, u)[grid.cell(u, lam[u])] for u in range(k)]
    options = []
    for u in range(k):
        if lam[u] in (INF, -INF):
            continue
        at = _mid(cells[u], lam[u])
        half = (cells[u][0], at) if lam[u] < at else (at, cells[u][1])
        still = a in model.possible_actions(pos, cells[:u] + [half] + cells[u + 1:])
        options.append((still, -_width(cells[u]), u, at))
    return min(options)[2:] if options else None


def _width(cell):
    lo, hi = cell
    return 1e9 if INF in (lo, -lo, hi, -hi) else hi - lo


def _mid(cell, near=None):
    """Split point of a cell; for an end cell, 1 unit beyond `near` so it lands in a finite part."""
    lo, hi = cell
    if lo == -INF:
        return hi - 2.0 if near is None else min(near, hi) - 1.0
    if hi == INF:
        return lo + 2.0 if near is None else max(near, lo) + 1.0
    return (lo + hi) / 2

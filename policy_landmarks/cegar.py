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
  never reaches -> split the source cell at the crossing point;
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
from pathlib import Path

from .planner import run_fd
from .rules import COARSE
from .symbolic import INF, Grid, Model


def _class(lo: float, hi: float, edges) -> int:
    return 0 if hi <= edges[0] else 2 if lo >= edges[1] else 1


def _box(model, assign, edges):
    box = []
    for v in range(len(model.vars)):
        kind, x = assign[v]
        box.append(x if kind == "f" else ((-INF, edges[0]), (edges[0], edges[1]), (edges[1], INF))[x])
    return box


def _acted(model, pos, a):
    return next((v for _, v, s, _, _ in model.step(pos, a) if v is not None and s is not None), None)


def _cells(grid: Grid, v: int) -> list:
    e = grid.edges[v]
    return [(e[i], e[i + 1]) for i in range(len(e) - 1)]


def initial_rules(model: Model, grid: Grid, positions: list, edges) -> list:
    """[(pos, a, assign)]: assign[v] = ("f", (lo, hi)) for the acted variable and
    ("k", class) for the others; covers every belief where the policy can act."""
    k = len(model.vars)
    out = []
    for pos in positions:
        for a in sorted(model.possible_actions(pos, [(-INF, INF)] * k)):
            acted = _acted(model, pos, a)
            others = [v for v in range(k) if v != acted]
            for classes in itertools.product(range(3), repeat=len(others)):
                for cell in (_cells(grid, acted) if acted is not None else [None]):
                    assign = {v: ("k", cl) for v, cl in zip(others, classes)}
                    if acted is not None:
                        assign[acted] = ("f", cell)
                    if a in model.possible_actions(pos, _box(model, assign, edges)):
                        out.append((pos, a, assign))
    return out


def split_class(model, grid, rule, var, edges) -> list:
    """Replace a coarse class of `var` by the fine cells inside it (children re-checked)."""
    pos, a, assign = rule
    cl = assign[var][1]
    out = []
    for cell in _cells(grid, var):
        if _class(*cell, edges) == cl:
            child = {**assign, var: ("f", cell)}
            if a in model.possible_actions(pos, _box(model, child, edges)):
                out.append((pos, a, child))
    return out


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


def compile_task(model, grid, rules, banned_cells: dict, edges, name="cegar"):
    """STRIPS with fine (cv-) and coarse (ck-) facts. `banned_cells` maps a variable to
    the set of fine-cell intervals inside the candidate; actions entering one are
    dropped. Action names r{rule}-o{outcome}-t{target cell index}."""
    actions = []
    index = [{cell: c for c, cell in enumerate(_cells(grid, v))} for v in range(len(model.vars))]

    def at(pos):
        return f"(at c{pos[0]}-{pos[1]})" if pos is not None else None

    for i, (pos, a, assign) in enumerate(rules):
        pre = ["(live)"] + ([at(pos)] if pos is not None else [])
        for v, (kind, x) in assign.items():
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
                targets = ([grid.cell(v, shift)] if shift in (INF, -INF)
                           else list(grid.cells_overlapping(v, lo + shift, hi + shift)))
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
    n_cells = max(len(e) - 1 for e in grid.edges)
    preds = ["(live)", "(done)", "(at ?p)"] + [f"(cv-{v} ?c)" for v in model.vars] + [f"(ck-{v} ?k)" for v in model.vars]
    objs = {f"c{c}" for c in range(n_cells)} | set(COARSE)
    if model.problem == "rocksample":
        objs |= {f"c{x}-{y}" for x in range(1, model.n + 1) for y in range(1, model.n + 1)}
    domain = "\n".join([f"(define (domain {name})", "  (:requirements :strips)",
                        "  (:predicates " + " ".join(preds) + ")"]
                       + [f"  (:action {n} :parameters ()\n    :precondition (and {' '.join(p)})\n"
                          f"    :effect (and {' '.join(e)}))" for n, p, e in actions] + [")"])
    init, init_cells = [], []
    for v in range(len(model.vars)):
        c0 = grid.cell(v, 0.0)
        cell0 = _cells(grid, v)[c0]
        init_cells.append((v, cell0))
        init += [f"(cv-{model.vars[v]} c{c0})", f"(ck-{model.vars[v]} {COARSE[_class(*cell0, edges)]})"]
    if model.start() is not None:
        init.append(at(model.start()))
    problem = "\n".join([f"(define (problem p-{name}) (:domain {name})", f"  (:objects {' '.join(sorted(objs))})",
                         "  (:init (live) " + " ".join(init) + ")", "  (:goal (done)))"])
    holds_initially = any(cell in banned_cells.get(v, ()) for v, cell in init_cells)
    return domain, problem, holds_initially


def _banned(grid, candidate) -> dict:
    """candidate: {var index: (lo, hi) ranges of log-odds}; banned fine cells inside them."""
    out = {}
    for v, ranges in candidate.items():
        out[v] = {cell for cell in _cells(grid, v) if any(lo <= cell[0] and cell[1] <= hi for lo, hi in ranges)}
    return out


def replay(model, grid, rules, steps):
    """Exact replay. Returns None if the plan is a real run of the policy, else
    (kind, details) for the first divergence."""
    lam = [0.0] * len(model.vars)
    for name in steps:
        i, j, t = name.split("-")[:3]
        pos, a, assign = rules[int(i[1:])]
        b = model.corner(pos, lam)
        if model.actions[int((model.A @ b).argmax())] != a:
            return ("action", int(i[1:]), list(lam))
        obs, v, shift, npos, term = model.step(pos, a)[int(j[1:])]
        if term:
            return None
        if v is not None and shift is not None:
            if shift in (INF, -INF):                         # sample, or a perfect check: set
                if a != "1" and lam[v] == -shift:            # perfect check contradicting certainty
                    return ("observation", int(i[1:]), list(lam))
                new = shift
            else:
                new = lam[v] + shift
            if t != "tNone" and grid.cell(v, new) != int(t[1:]):
                return ("cell", int(i[1:]), (v, lam[v], shift, int(t[1:])))
            lam[v] = new
    return None


def verify(model: Model, grid: Grid, rules: list, candidate: dict, workdir: Path, edges,
           max_iter: int = 400) -> dict:
    """candidate: {var: [(lo, hi), ...]} log-odds ranges (e.g. a level or two levels)."""
    for it in range(max_iter):
        banned = _banned(grid, candidate)
        domain, problem, initially = compile_task(model, grid, rules, banned, edges)
        if initially:
            return {"landmark": True, "iterations": it, "reason": "holds initially"}
        run_fd(workdir, domain, problem, search="lazy_greedy([ff()])")
        plan_file = workdir / "sas_plan"
        if not plan_file.exists():
            return {"landmark": True, "iterations": it, "rules": len(rules)}
        steps = [l.strip("() \n").split()[0] for l in plan_file.read_text().splitlines() if l.startswith("(")]
        plan_file.unlink()
        # 1. fine-cell check: the rule must be possible at the plan's fine cells
        cells = [grid.cell(v, 0.0) for v in range(len(model.vars))]
        spurious = None
        for name in steps:
            i, j, t = name.split("-")[:3]
            pos, a, assign = rules[int(i[1:])]
            box = [_cells(grid, v)[cells[v]] for v in range(len(model.vars))]
            if a not in model.possible_actions(pos, box):
                spurious = (int(i[1:]), list(cells))
                break
            obs, v, shift, npos, term = model.step(pos, a)[int(j[1:])]
            if not term and t != "tNone" and v is not None and shift is not None:
                cells[v] = int(t[1:])
        if spurious is not None:
            r, fine = spurious
            pos, a, assign = rules[r]
            coarse = [v for v, (kind, _) in assign.items() if kind == "k"]
            # a fully fine rule has the plan's box, where its action was checked possible
            assert coarse, "spurious step on a rule without coarse classes"
            for v in coarse:
                kids = split_class(model, grid, rules[r], v, edges)
                if not any(ch[2][v][1] == _cells(grid, v)[fine[v]] for ch in kids):
                    break
            else:
                v = coarse[0]
            rules[r:r + 1] = split_class(model, grid, rules[r], v, edges)
            continue
        # 2. exact replay
        div = replay(model, grid, rules, steps)
        if div is None:
            return {"landmark": False, "certified": True, "iterations": it, "rules": len(rules)}
        kind, r, info = div
        if kind == "cell":                                     # split the source at the crossing
            v, lam, shift, t = info
            src = _cells(grid, v)[grid.cell(v, lam)]
            tcell = _cells(grid, v)[t]
            edge = tcell[0] if tcell[0] > lam + shift else tcell[1]
            if not split_cell(model, grid, rules, v, edge - shift, edges):
                split_cell(model, grid, rules, v, _mid(src), edges)
        elif kind == "action":                                 # policy's choice differs: halve
            pos, a, _ = rules[r]
            pick = _shrink(model, grid, pos, a, info)
            if pick is None:
                return {"landmark": None, "iterations": it, "reason": "exact belief", "rules": len(rules)}
            split_cell(model, grid, rules, *pick, edges)
        else:            # impossible observation from a certain belief: no finite split removes it
            return {"landmark": None, "iterations": it, "reason": "observation", "rules": len(rules)}
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

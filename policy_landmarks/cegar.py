"""Landmark verification by counterexample-guided refinement (direction R3c).

To prove that a fact set F is a landmark of an alpha-vector policy, search the compact
rule task (rules.py) for a plan that avoids F. No plan: F is a landmark (the rule task
over-approximates the policy, so this is sound). A plan: replay it on fine cells;
if every step's action is possible at the fine cells, the plan is a genuine
counterexample (at this precision) and F is reported as not proven. Otherwise the
first spurious step names the rule that let it through; that rule is split along
one coarsely described variable into its fine cells (each child re-checked by the box
test, so coverage and soundness are kept) and the search repeats. The planner's
search does the verification; refinement touches only rules used by counterexamples.
"""

from __future__ import annotations

import itertools
from pathlib import Path

from .planner import run_fd
from .rules import COARSE, coarse_class
from .symbolic import INF, Grid, Model


def _box(model, grid, assign, edges):
    box = []
    for v in range(len(model.vars)):
        kind, x = assign[v]
        if kind == "f":
            box.append(grid.interval(v, x))
        else:
            box.append(((-INF, edges[0]), (edges[0], edges[1]), (edges[1], INF))[x])
    return box


def _acted(model, pos, a):
    return next((v for _, v, s, _, _ in model.step(pos, a) if v is not None and s is not None), None)


def initial_rules(model: Model, grid: Grid, positions: list, edges) -> list:
    """[(pos, a, assign)], assign[v] = ("f", cell) for the acted variable and
    ("k", class) for the others; covers every belief where the policy can act."""
    n_cells = [len(e) - 1 for e in grid.edges]
    k = len(model.vars)
    out = []
    for pos in positions:
        for a in sorted(model.possible_actions(pos, [(-INF, INF)] * k)):
            acted = _acted(model, pos, a)
            others = [v for v in range(k) if v != acted]
            for classes in itertools.product(range(3), repeat=len(others)):
                for c in (range(n_cells[acted]) if acted is not None else [None]):
                    assign = {v: ("k", cl) for v, cl in zip(others, classes)}
                    if acted is not None:
                        assign[acted] = ("f", c)
                    if a in model.possible_actions(pos, _box(model, grid, assign, edges)):
                        out.append((pos, a, assign))
    return out


def split(model, grid, rule, var, edges) -> list:
    """Replace a coarse class of `var` by its fine cells; keep children where possible."""
    pos, a, assign = rule
    kind, cl = assign[var]
    assert kind == "k"
    cells = [c for c in range(len(grid.edges[var]) - 1) if coarse_class(grid, var, c, edges) == cl]
    out = []
    for c in cells:
        child = {**assign, var: ("f", c)}
        if a in model.possible_actions(pos, _box(model, grid, child, edges)):
            out.append((pos, a, child))
    return out


def compile_task(model, grid, rules, banned: set, edges, name="cegar"):
    """STRIPS with fine (cv-) and coarse (ck-) facts; actions adding a banned fact are
    dropped. Action names r{rule}-o{outcome}-t{target}."""
    actions = []

    def at(pos):
        return f"(at c{pos[0]}-{pos[1]})" if pos is not None else None

    for i, (pos, a, assign) in enumerate(rules):
        pre = ["(live)"] + ([at(pos)] if pos is not None else [])
        for v, (kind, x) in assign.items():
            pre.append(f"(cv-{model.vars[v]} c{x})" if kind == "f" else f"(ck-{model.vars[v]} {COARSE[x]})")
        for j, (obs, v, shift, npos, term) in enumerate(model.step(pos, a)):
            if term:
                eff = ["(done)", "(not (live))"]
                actions.append((f"r{i}-o{j}-tend", pre, eff))
                continue
            c = assign[v][1] if v is not None and shift is not None else None
            targets = [c]
            if v is not None and shift is not None:
                lo, hi = grid.interval(v, c)
                targets = ([grid.cell(v, shift)] if shift in (INF, -INF)
                           else list(grid.cells_overlapping(v, lo + shift, hi + shift)))
            for t in targets:
                eff = []
                if v is not None and shift is not None and t != c:
                    eff += [f"(cv-{model.vars[v]} c{t})", f"(not (cv-{model.vars[v]} c{c}))"]
                    k0, k1 = coarse_class(grid, v, c, edges), coarse_class(grid, v, t, edges)
                    if k0 != k1:
                        eff += [f"(ck-{model.vars[v]} {COARSE[k1]})", f"(not (ck-{model.vars[v]} {COARSE[k0]}))"]
                if pos is not None and npos != pos:
                    eff += [at(npos), f"(not {at(pos)})"]
                if any(e in banned for e in eff):
                    continue
                actions.append((f"r{i}-o{j}-t{t}", pre, eff or ["(live)"]))
    n_cells = [len(e) - 1 for e in grid.edges]
    preds = ["(live)", "(done)", "(at ?p)"] + [f"(cv-{v} ?c)" for v in model.vars] + [f"(ck-{v} ?k)" for v in model.vars]
    objs = {f"c{c}" for n in n_cells for c in range(n)} | set(COARSE)
    if model.problem == "rocksample":
        objs |= {f"c{x}-{y}" for x in range(1, model.n + 1) for y in range(1, model.n + 1)}
    domain = "\n".join([f"(define (domain {name})", "  (:requirements :strips)",
                        "  (:predicates " + " ".join(preds) + ")"]
                       + [f"  (:action {n} :parameters ()\n    :precondition (and {' '.join(p)})\n"
                          f"    :effect (and {' '.join(e)}))" for n, p, e in actions] + [")"])
    init = []
    for v in range(len(model.vars)):
        c0 = grid.cell(v, 0.0)
        init += [f"(cv-{model.vars[v]} c{c0})", f"(ck-{model.vars[v]} {COARSE[coarse_class(grid, v, c0, edges)]})"]
    if model.start() is not None:
        init.append(at(model.start()))
    problem = "\n".join([f"(define (problem p-{name}) (:domain {name})", f"  (:objects {' '.join(sorted(objs))})",
                         "  (:init (live) " + " ".join(init) + ")", "  (:goal (done)))"])
    return domain, problem, init


def exact_replay(model: Model, grid: Grid, rules: list, steps: list) -> bool:
    """Is the plan a real run of the policy? Replays it with exact log-odds: each action
    must be the alpha-vector policy's choice at the exact belief, and each chosen cell
    must contain the exact value. True certifies that a run of positive probability
    avoids the candidate, so it is not a landmark."""
    lam = [0.0] * len(model.vars)
    for name in steps:
        i, j, t = name.split("-")[:3]
        pos, a, _ = rules[int(i[1:])]
        b = model.corner(pos, lam)
        if model.actions[int((model.A @ b).argmax())] != a:
            return False
        obs, v, shift, npos, term = model.step(pos, a)[int(j[1:])]
        if term:
            return True
        if v is not None and shift is not None:
            if {lam[v], shift} == {INF, -INF}:
                return False                                  # observation impossible here
            lam[v] = lam[v] + shift
            if grid.cell(v, lam[v]) != int(t[1:]):
                return False                                  # plan picked a cell never reached
    return True


def verify(model: Model, grid: Grid, rules: list, banned: set, workdir: Path, edges,
           max_iter: int = 200) -> dict:
    """Is `banned` (a set of fact strings such as '(cv-rock4 c1)') a landmark? Refines
    `rules` in place along spurious counterexamples."""
    for it in range(max_iter):
        domain, problem, init = compile_task(model, grid, rules, banned, edges)
        if any(f in banned for f in init):
            return {"landmark": True, "iterations": it, "reason": "holds initially"}
        r = run_fd(workdir, domain, problem, search="lazy_greedy([ff()])")
        plan_file = workdir / "sas_plan"
        if not plan_file.exists():
            return {"landmark": True, "iterations": it, "rules": len(rules)}
        steps = [l.strip("() \n").split()[0] for l in plan_file.read_text().splitlines() if l.startswith("(")]
        plan_file.unlink()
        pos = model.start()
        cells = [grid.cell(v, 0.0) for v in range(len(model.vars))]
        spurious = None
        for name in steps:
            i, j, t = name.split("-")[:3]
            rule = rules[int(i[1:])]
            rpos, a, assign = rule
            fine_box = [grid.interval(v, cells[v]) for v in range(len(model.vars))]
            if a not in model.possible_actions(rpos, fine_box):
                spurious = int(i[1:])
                break
            obs, v, shift, npos, term = model.step(rpos, a)[int(j[1:])]
            if not term and v is not None and shift is not None:
                cells[v] = int(t[1:])
            pos = npos
        if spurious is None:
            return {"landmark": False, "iterations": it, "rules": len(rules), "counterexample": steps,
                    "certified": exact_replay(model, grid, rules, steps)}
        rpos, a, assign = rules[spurious]
        coarse = [v for v, (kind, _) in assign.items() if kind == "k"]
        # split the coarse variable whose fine cell at the spurious state excludes the action
        best = None
        for v in coarse:
            kids = split(model, grid, rules[spurious], v, edges)
            if not any(child[2][v][1] == cells[v] for child in kids):
                best = (v, kids)
                break
        if best is None:
            v = coarse[0]
            best = (v, split(model, grid, rules[spurious], v, edges))
        rules[spurious:spurious + 1] = best[1]
    return {"landmark": None, "iterations": max_iter, "rules": len(rules)}

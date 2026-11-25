"""Sound policy rules from alpha-vectors, compiled to a factored STRIPS task (R3b).

symbolic.abstract_controller enumerates abstract states. Here we never do: for each
observable part and action we extract rules "a is possible only if variable V is in
cell c" (a small decision tree over cells), each checked over the whole box of the
variables it leaves free, so the rules cover every belief where the policy can take
the action. Compiled to STRIPS (one fact per variable cell, one action per rule and
observation outcome), every run of the policy is a plan, so the landmarks that
Fast Downward's RHW factory finds are sound landmarks of the policy - without
enumerating beliefs or abstract states. This is where the planner is needed.
"""

from __future__ import annotations

from .symbolic import INF, Grid, Model, level_name


def _box(model: Model, grid: Grid, assign: dict, points: bool):
    box = []
    for v in range(len(model.vars)):
        if v in assign:
            lo, hi = grid.interval(v, assign[v])
            if points and lo != -INF and hi != INF:
                lo = hi = (lo + hi) / 2                      # lattice point of the cell
            box.append((lo, hi))
        else:
            box.append((-INF, INF))
    return box


def _acted_var(model: Model, pos, a):
    outs = model.step(pos, a)
    return next((v for _, v, shift, _, _ in outs if v is not None and shift is not None), None)


def extract_rules(model: Model, grid: Grid, positions: list, depth: int = 1,
                  points: bool = False) -> list:
    """[(pos, action, {var: cell})]: for each pos and action, partial assignments that
    together cover every cell combination where the action is possible."""
    n_cells = [len(e) - 1 for e in grid.edges]
    rules = []

    def split(pos, a, assign, d):
        if a not in model.possible_actions(pos, _box(model, grid, assign, points)):
            return []
        free = [v for v in range(len(model.vars)) if v not in assign]
        if d == 0 or not free:
            return [assign]
        acted = _acted_var(model, pos, a)
        if acted in free:
            v = acted                                         # its cell drives the effect
        else:                                                 # most selective variable
            v = min(free, key=lambda w: sum(a in model.possible_actions(
                pos, _box(model, grid, {**assign, w: c}, points)) for c in range(n_cells[w])))
        out = []
        for c in range(n_cells[v]):
            out += split(pos, a, {**assign, v: c}, d - 1)
        return out

    for pos in positions:
        full = _box(model, grid, {}, points)
        for a in sorted(model.possible_actions(pos, full)):
            rules += [(pos, a, assign) for assign in split(pos, a, {}, depth)]
    return rules


def to_pddl(model: Model, grid: Grid, rules: list, name: str, points: bool = False):
    """Factored STRIPS task: facts cv-V(cK) (the cell of V), at(cX-Y), live, done,
    chose(a), sampled(R). One action per rule, current cell of the acted variable (when
    the rule leaves it free) and observation outcome."""
    n_cells = [len(e) - 1 for e in grid.edges]
    actions = []

    def cell_fact(v, c):
        return f"(cv-{model.vars[v]} c{c})"

    def at(pos):
        return f"(at c{pos[0]}-{pos[1]})" if pos is not None else None

    for i, (pos, a, assign) in enumerate(rules):
        acted = _acted_var(model, pos, a)
        current = [assign[acted]] if acted is not None and acted in assign else (
            range(n_cells[acted]) if acted is not None else [None])
        for c in current:
            pre = ["(live)"] + ([at(pos)] if pos is not None else [])
            pre += [cell_fact(v, cc) for v, cc in assign.items() if v != acted]
            if c is not None:
                pre.append(cell_fact(acted, c))
            for j, (obs, v, shift, npos, term) in enumerate(model.step(pos, a)):
                san = "".join(ch if ch.isalnum() else "-" for ch in f"{a}-{obs}").lower()
                if term:
                    eff = ["(done)", "(not (live))"] + ([f"(chose {san})"] if obs == "commit" else [])
                    actions.append((f"r{i}-c{c}-o{j}-{san}", pre, eff))
                    continue
                targets = [c]
                if v is not None and shift is not None:
                    lo, hi = grid.interval(v, c)
                    if points and lo != -INF and hi != INF:
                        lo = hi = (lo + hi) / 2
                    targets = ([grid.cell(v, shift)] if shift in (INF, -INF)
                               else list(grid.cells_overlapping(v, lo + shift, hi + shift)))
                for t in targets:
                    eff = []
                    if v is not None and shift is not None and t != c:
                        eff += [cell_fact(v, t), f"(not {cell_fact(v, c)})"]
                    if pos is not None and npos != pos:
                        eff += [at(npos), f"(not {at(pos)})"]
                    if model.problem == "rocksample" and a == "1" and v is not None:
                        eff.append(f"(sampled rock{v + 1})")
                    actions.append((f"r{i}-c{c}-o{j}-t{t}-{san}", pre, eff or ["(live)"]))

    preds = ["(live)", "(done)", "(chose ?a)", "(sampled ?r)", "(at ?p)"]
    preds += [f"(cv-{v} ?c)" for v in model.vars]
    objs = {f"c{c}" for n in n_cells for c in range(n)}
    for _, pre, eff in actions:
        for p in pre + eff:
            atom = p[len("(not "):-1] if p.startswith("(not ") else p
            if atom.startswith(("(at ", "(chose ", "(sampled ")):
                objs.add(atom.split()[1].rstrip(")"))
    domain = "\n".join([f"(define (domain {name})", "  (:requirements :strips)",
                        "  (:predicates " + " ".join(preds) + ")"]
                       + [f"  (:action {n} :parameters ()\n    :precondition (and {' '.join(pre)})\n"
                          f"    :effect (and {' '.join(eff)}))" for n, pre, eff in actions] + [")"])
    start = [f"(cv-{model.vars[v]} c{grid.cell(v, 0.0)})" for v in range(len(model.vars))]
    if model.start() is not None:
        start.append(at(model.start()))
    problem = "\n".join([f"(define (problem p-{name}) (:domain {name})",
                         f"  (:objects {' '.join(sorted(objs))})",
                         "  (:init (live) " + " ".join(start) + ")", "  (:goal (done)))"])
    return domain, problem, len(actions)


def level_of(model: Model, grid: Grid, fact: str) -> str:
    """'cv-rock2(c3)' -> 'ev-rock2(neg2)' for display."""
    var, c = fact[3:].split("(")
    v = model.vars.index(var)
    lo, hi = grid.interval(v, int(c.rstrip(")")[1:]))
    return f"ev-{var}({level_name(model, v, lo, hi)})"

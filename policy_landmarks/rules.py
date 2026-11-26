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
                    targets = list(grid.successors(v, lo, hi, shift))
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



# --- Context rules: fine cell for the acted variable, coarse class for all others ----

COARSE = ("neg", "unk", "pos")


def coarse_class(grid: Grid, v: int, c: int, edges=(-0.5, 0.5)) -> int:
    """0 / 1 / 2 for cells below edges[0], between, above edges[1] (fine edges must
    include both, as the bin grid does)."""
    lo, hi = grid.interval(v, c)
    return 0 if hi <= edges[0] else 2 if lo >= edges[1] else 1


def _context_box(model, grid, ctx: dict, fine: dict, points: bool, edges=(-0.5, 0.5)):
    """Box for coarse classes `ctx` {var: 0/1/2} and fine cells `fine` {var: cell}."""
    box = []
    for v in range(len(model.vars)):
        if v in fine:
            lo, hi = grid.interval(v, fine[v])
            if points and lo != -INF and hi != INF:
                lo = hi = (lo + hi) / 2
        else:
            k = ctx[v]
            lo, hi = ((-INF, edges[0]), (edges[0], edges[1]), (edges[1], INF))[k]
        box.append((lo, hi))
    return box


def extract_context_rules(model: Model, grid: Grid, positions: list, points: bool = False,
                          edges=(-0.5, 0.5)):
    """[(pos, action, {var: class}, {var: cell})]: every combination of coarse classes of
    the non-acted variables, with the acted variable's fine cell, where the action is
    possible (box test). Covers every belief where the policy can take the action."""
    import itertools
    n_cells = [len(e) - 1 for e in grid.edges]
    k = len(model.vars)
    rules = []
    for pos in positions:
        for a in sorted(model.possible_actions(pos, [(-INF, INF)] * k)):
            acted = _acted_var(model, pos, a)
            others = [v for v in range(k) if v != acted]
            for classes in itertools.product(range(3), repeat=len(others)):
                ctx = dict(zip(others, classes))
                cells = range(n_cells[acted]) if acted is not None else [None]
                for c in cells:
                    fine = {acted: c} if c is not None else {}
                    if a in model.possible_actions(pos, _context_box(model, grid, ctx, fine, points, edges)):
                        rules.append((pos, a, ctx, fine))
    return rules


def to_pddl_context(model: Model, grid: Grid, rules: list, name: str, points: bool = False,
                    edges=(-0.5, 0.5)):
    """STRIPS with a fine fact cv-V(cK) and a coarse fact ck-V(neg|unk|pos) per variable,
    both updated when the acted variable moves."""
    actions = []

    def at(pos):
        return f"(at c{pos[0]}-{pos[1]})" if pos is not None else None

    for i, (pos, a, ctx, fine) in enumerate(rules):
        pre = ["(live)"] + ([at(pos)] if pos is not None else [])
        pre += [f"(ck-{model.vars[v]} {COARSE[k]})" for v, k in ctx.items()]
        pre += [f"(cv-{model.vars[v]} c{c})" for v, c in fine.items()]
        for j, (obs, v, shift, npos, term) in enumerate(model.step(pos, a)):
            san = "".join(ch if ch.isalnum() else "-" for ch in f"{a}-{obs}").lower()
            if term:
                eff = ["(done)", "(not (live))"] + ([f"(chose {san})"] if obs == "commit" else [])
                actions.append((f"r{i}-o{j}-{san}", pre, eff))
                continue
            c = fine.get(v) if v is not None else None
            targets = [c]
            if v is not None and shift is not None:
                lo, hi = grid.interval(v, c)
                if points and lo != -INF and hi != INF:
                    lo = hi = (lo + hi) / 2
                targets = list(grid.successors(v, lo, hi, shift))
            for t in targets:
                eff = []
                if v is not None and shift is not None and t != c:
                    eff += [f"(cv-{model.vars[v]} c{t})", f"(not (cv-{model.vars[v]} c{c}))"]
                    k0, k1 = coarse_class(grid, v, c, edges), coarse_class(grid, v, t, edges)
                    if k0 != k1:
                        eff += [f"(ck-{model.vars[v]} {COARSE[k1]})", f"(not (ck-{model.vars[v]} {COARSE[k0]}))"]
                if pos is not None and npos != pos:
                    eff += [at(npos), f"(not {at(pos)})"]
                if model.problem == "rocksample" and a == "1" and v is not None:
                    eff.append(f"(sampled rock{v + 1})")
                actions.append((f"r{i}-o{j}-t{t}-{san}", pre, eff or ["(live)"]))

    n_cells = [len(e) - 1 for e in grid.edges]
    preds = ["(live)", "(done)", "(chose ?a)", "(sampled ?r)", "(at ?p)"]
    preds += [f"(cv-{v} ?c)" for v in model.vars] + [f"(ck-{v} ?k)" for v in model.vars]
    objs = {f"c{c}" for n in n_cells for c in range(n)} | set(COARSE)
    for _, pre, eff in actions:
        for p in pre + eff:
            atom = p[len("(not "):-1] if p.startswith("(not ") else p
            if atom.startswith(("(at ", "(chose ", "(sampled ")):
                objs.add(atom.split()[1].rstrip(")"))
    domain = "\n".join([f"(define (domain {name})", "  (:requirements :strips)",
                        "  (:predicates " + " ".join(preds) + ")"]
                       + [f"  (:action {n} :parameters ()\n    :precondition (and {' '.join(pre)})\n"
                          f"    :effect (and {' '.join(eff)}))" for n, pre, eff in actions] + [")"])
    start = []
    for v in range(len(model.vars)):
        c0 = grid.cell(v, 0.0)
        start += [f"(cv-{model.vars[v]} c{c0})", f"(ck-{model.vars[v]} {COARSE[coarse_class(grid, v, c0, edges)]})"]
    if model.start() is not None:
        start.append(at(model.start()))
    problem = "\n".join([f"(define (problem p-{name}) (:domain {name})",
                         f"  (:objects {' '.join(sorted(objs))})",
                         "  (:init (live) " + " ".join(start) + ")", "  (:goal (done)))"])
    return domain, problem, len(actions)

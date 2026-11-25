"""Landmarks of an alpha-vector policy without enumerating its beliefs (direction R3).

For models whose belief factors into independent binary hidden variables (plus an
observable part, e.g. the robot's cell), a belief is a vector of per-variable
log-odds. An abstract state fixes the observable part and, for each variable, a cell
(an interval of log-odds). From the alpha-vectors alone we over-approximate the
actions the policy can take anywhere in the box (alpha . b is multilinear in the
per-variable probabilities, so comparing two vectors over the box only needs its
corners), and from the model the successor cells of each observation (an
observation shifts one variable's log-odds by a known amount). The result is a sound
over-approximation of the policy's controller: every run of the policy is a run of
the abstract controller, so its landmarks hold on every run of the policy that ends
(Theorem 1, part 1). Splitting cells where several actions remain possible refines it.
"""

from __future__ import annotations

import bisect
import itertools
import math

import numpy as np

INF = math.inf


def sigmoid(x: float) -> float:
    return 1.0 if x == INF else 0.0 if x == -INF else 1 / (1 + math.exp(-x))


class Model:
    """Factored belief dynamics of one problem (Tiger, Sensor, RockSample)."""

    def __init__(self, g: dict, alphas: dict):
        self.g, self.problem = g, g["problem"]
        self.states = alphas["states"]
        self.actions = alphas["actions"]
        self.A = np.array(alphas["alphas"])
        assert self.states == g["states"], "alpha-vectors and graph use one state order"
        if self.problem == "tiger":
            self.vars, self.u = ["direction"], math.log(g["p_correct"] / (1 - g["p_correct"]))
            self.terminal = {"left", "right"}
        elif self.problem == "sensor":
            self.vars, self.u = ["sensor-a", "sensor-b"], math.log(g["p_correct"] / (1 - g["p_correct"]))
            self.terminal = {a for a in self.actions if a.startswith("commit")}
        else:
            k = len(next(s for s in self.states if s != "terminal").split("|")[1])
            self.vars, self.u = [f"rock{i + 1}" for i in range(k)], None
            self.terminal = set()
            self.n, self.eff = g["n"], g.get("efficiency", 20.0)
            self.rock_cell = {int(r[4:]) - 1: tuple(map(int, xy.split("-"))) for xy, r in g["rock_at"].items()}
        # rows of the state list for each observable part, with each state's variable bits
        self.rows: dict = {}
        for i, s in enumerate(self.states):
            if s in ("terminal", "done"):
                continue
            if self.problem == "tiger":
                pos, bits = None, (s == "left",)
            elif self.problem == "sensor":
                pos, bits = None, (s.startswith("a-ok"), s.endswith("b-ok"))
            else:
                xy, b = s.split("|")
                pos, bits = tuple(map(int, xy.split(","))), tuple(c == "1" for c in b)
            self.rows.setdefault(pos, []).append((i, bits))

    def start(self):
        return (1, 1) if self.problem == "rocksample" else None

    def belief(self, pos, probs) -> np.ndarray:
        b = np.zeros(len(self.states))
        for i, bits in self.rows[pos]:
            b[i] = math.prod(p if bit else 1 - p for p, bit in zip(probs, bits))
        return b

    def possible_actions(self, pos, box) -> set:
        """Actions the alpha-vector policy can choose at some belief in the box
        (sound over-approximation: an action is dropped only if each of its vectors is
        beaten everywhere in the box by one vector of another action)."""
        corners = [self.belief(pos, [sigmoid(c) for c in corner])
                   for corner in itertools.product(*[(lo, hi) for lo, hi in box])]
        M = self.A @ np.array(corners).T                     # vectors x corners
        acts = np.array(self.actions)
        out = set()
        for a in set(self.actions):
            mine, other = M[acts == a], M[acts != a]
            if other.size == 0:
                out.add(a)
                continue
            # vector i of a is dominated if some other vector is larger at every corner
            dominated = (other[None, :, :] > mine[:, None, :]).all(axis=2).any(axis=1)
            if not dominated.all():
                out.add(a)
        return out

    def step(self, pos, a):
        """[(observation, variable index or None, shift or None, new pos, terminal)]"""
        if a in self.terminal:
            return [("commit", None, None, pos, True)]
        if self.problem in ("tiger", "sensor"):
            v = 0 if self.problem == "tiger" else (0 if a == "read-a" else 1)
            plus = "left" if self.problem == "tiger" else f"{a[-1]}-agree"
            minus = "right" if self.problem == "tiger" else f"{a[-1]}-disagree"
            return [(plus, v, +self.u, pos, False), (minus, v, -self.u, pos, False)]
        x, y = pos
        code = int(a)
        if code == 1:                                        # sample: the rock becomes bad
            r = next((r for r, c in self.rock_cell.items() if c == pos), None)
            return [("3", r, -INF if r is not None else None, pos, False)]
        if code <= 5:                                        # move N, E, S, W
            dx, dy = {2: (0, 1), 3: (1, 0), 4: (0, -1), 5: (-1, 0)}[code]
            if x + dx > self.n:
                return [("3", None, None, pos, True)]        # exit east ends the episode
            nx, ny = min(max(x + dx, 1), self.n), min(max(y + dy, 1), self.n)
            return [("3", None, None, (nx, ny), False)]
        r = code - 6                                         # check rock r
        rx, ry = self.rock_cell[r]
        eff = 0.5 * (1 + math.exp(-math.hypot(x - rx, y - ry) * math.log(2) / self.eff))
        d = INF if eff >= 1 else math.log(eff / (1 - eff))
        return [("1", r, +d, pos, False), ("2", r, -d, pos, False)]


class Grid:
    """Per-variable cell boundaries in log-odds (-inf and +inf at the ends)."""

    def __init__(self, edges: list):
        self.edges = edges                                   # one sorted list per variable

    def cell(self, v: int, x: float) -> int:
        e = self.edges[v]
        if x == INF:
            return len(e) - 2
        if x == -INF:
            return 0
        return min(max(bisect.bisect_right(e, x) - 1, 0), len(e) - 2)

    def interval(self, v: int, c: int):
        return self.edges[v][c], self.edges[v][c + 1]

    def cells_overlapping(self, v: int, lo: float, hi: float) -> range:
        if lo == hi:                                         # a single point (e.g. +-inf)
            return range(self.cell(v, lo), self.cell(v, lo) + 1)
        tol = 1e-9 * (1 + max(abs(b) for b in (lo, hi) if b not in (INF, -INF)))
        lo, hi = lo + tol if lo != -INF else lo, hi - tol if hi != INF else hi  # float noise at edges
        first = self.cell(v, lo)
        last = self.cell(v, hi) if hi != INF else len(self.edges[v]) - 2
        if hi != INF and hi == self.edges[v][last]:          # half-open cells
            last -= 1
        return range(first, max(first, last) + 1)


def level_name(model: Model, v: int, lo: float, hi: float) -> str:
    """The evidence level of the cell, in the naming of extraction.level."""
    mid = lo + 1 if hi == INF else hi - 1 if lo == -INF else (lo + hi) / 2
    if model.u:
        k = min(9, round(abs(mid) / model.u))
    else:
        k = sum(abs(mid) >= b for b in (0.5, 2.5, 4.5))
    return "unk" if k == 0 else ("pos" if mid > 0 else "neg") + str(k)


def abstract_controller(model: Model, grid: Grid, max_states: int = 200_000) -> dict:
    """BFS over abstract states (observable part, cell per variable) reachable under
    the over-approximated action sets. Returns a controller in the format of
    extraction.controller (facts: ev-V(level), at(cell), plus cx-V(i) for the cell)."""
    def facts(pos, cells):
        out = set()
        for v, c in enumerate(cells):
            lo, hi = grid.interval(v, c)
            out.add(f"ev-{model.vars[v]}({level_name(model, v, lo, hi)})")
            out.add(f"cx-{model.vars[v]}({c})")
        if pos is not None:
            out.add(f"at(c{pos[0]}-{pos[1]})")
        return frozenset(out)

    start = (model.start(), tuple(grid.cell(v, 0.0) for v in range(len(model.vars))))
    seen, frontier = {start}, [start]
    edges, commits, mixed = set(), set(), 0
    while frontier:
        pos, cells = frontier.pop()
        box = [grid.interval(v, c) for v, c in enumerate(cells)]
        acts = model.possible_actions(pos, box)
        mixed += len(acts) > 1
        src = facts(pos, cells)
        for a in acts:
            for obs, v, shift, npos, term in model.step(pos, a):
                if term:
                    if obs == "commit":
                        commits.add((src, a))
                    else:
                        edges.add((src, a, obs, frozenset({"terminal"}), frozenset()))
                    continue
                if v is None or shift is None:
                    targets = [cells]
                elif shift in (INF, -INF):
                    targets = [cells[:v] + (grid.cell(v, shift),) + cells[v + 1:]]
                else:
                    lo, hi = box[v]
                    targets = [cells[:v] + (c,) + cells[v + 1:]
                               for c in grid.cells_overlapping(v, lo + shift, hi + shift)]
                effect = frozenset()
                if model.problem == "rocksample" and a == "1" and v is not None:
                    effect = frozenset({f"sampled(rock{v + 1})"})
                for t in targets:
                    nxt = (npos, t)
                    edges.add((src, a, obs, facts(*nxt), effect))
                    if nxt not in seen:
                        seen.add(nxt)
                        frontier.append(nxt)
                        if len(seen) > max_states:
                            raise RuntimeError("abstract state space too large")
    return {"init": facts(*start), "edges": edges, "commits": commits,
            "abstract_states": len(seen), "mixed_states": mixed}


def unit_grid(model: Model, halvings: int = 0, levels: int = 12) -> Grid:
    """Cells of width u / 2^halvings, aligned so that one observation moves a cell to a
    cell; the outermost cells extend to infinity."""
    w = model.u / 2 ** halvings
    edges = [0.5 * model.u + k * w for k in range(-levels * 2 ** halvings, levels * 2 ** halvings)]
    return Grid([[-INF] + edges + [INF] for _ in model.vars])


def bin_grid(model: Model, halvings: int = 0) -> Grid:
    """RockSample: the paper's bins (|log-odds| = 0.5, 2.5, 4.5), each finite cell split
    into 2^halvings parts."""
    base = [-4.5, -2.5, -0.5, 0.5, 2.5, 4.5]
    edges = list(base)
    for _ in range(halvings):
        edges = sorted(set(edges + [(a + b) / 2 for a, b in zip(edges, edges[1:])]))
    return Grid([[-INF] + edges + [INF] for _ in model.vars])

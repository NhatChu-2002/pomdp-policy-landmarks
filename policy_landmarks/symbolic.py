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
EPS = float(np.finfo(float).eps)
SAFETY = 8.0        # slack on the derived float error bounds (box test here, replay in cegar.py)


def sigmoid(x: float) -> float:
    return 1.0 if x == INF else 0.0 if x == -INF else 1 / (1 + math.exp(-x))


def value_error(A: np.ndarray, k: int) -> float:
    """Bound on |fl(alpha . b) - alpha . b| for every row alpha of A (columns: the n states
    of one observable part) and every belief b of k independent variables computed as a
    product of sigmoids p or 1 - p. With exp within 4 ulp, each factor lies in [0, 1] with
    absolute error <= 5.5 eps (relative error of p, then 1 - p, which is accurate only in
    absolute terms near p = 1), so each b_i has absolute error <= 6k eps up to O(eps^2), and
    the dot product adds gamma_n sum |alpha_i| b_i <= n eps ||alpha||_1. Hence
    (n + 7k) eps max ||alpha||_1, the 7k absorbing the O(eps^2) terms."""
    return (A.shape[1] + 7 * k) * EPS * float(np.abs(A).sum(axis=1).max()) if A.size else 0.0


class Model:
    """Factored belief dynamics of one problem (Tiger, Sensor, RockSample)."""

    def __init__(self, g: dict, alphas: dict):
        self.g, self.problem = g, g["problem"]
        self.states = alphas["states"]
        self.actions = alphas["actions"]
        self.A = np.array(alphas["alphas"])
        self._names = sorted(set(self.actions))                       # action index of each vector
        self._aid = np.array([self._names.index(a) for a in self.actions])
        assert self.states == g["states"], "alpha-vectors and graph use one state order"
        if self.problem == "tiger":
            self.vars, self.u = ["direction"], math.log(g["p_correct"] / (1 - g["p_correct"]))
            self.terminal = {"left", "right"}
        elif self.problem == "sensor":
            self.vars, self.u = ["sensor-a", "sensor-b"], math.log(g["p_correct"] / (1 - g["p_correct"]))
            self.terminal = {a for a in self.actions if a.startswith("commit")}
        elif self.problem == "probe":
            # one categorical variable: coordinate v is the log-weight of value v (belief
            # = softmax of the weights); probing v adds +-u to coordinate v only
            self.vars = [s for s in self.states if s != "done"]
            self.u = math.log(g["p_correct"] / (1 - g["p_correct"]))
            self.terminal = {a for a in self.actions if a.startswith("commit")}
        else:
            k = len(next(s for s in self.states if s != "terminal").split("|")[1])
            self.vars, self.u = [f"rock{i + 1}" for i in range(k)], None
            self.terminal = set()
            self.n, self.eff = g["n"], g.get("efficiency", 20.0)
            self.rock_cell = {int(r[4:]) - 1: tuple(map(int, xy.split("-"))) for xy, r in g["rock_at"].items()}
        # rows of the state list for each observable part, with each state's variable bits
        self.rows: dict = {}
        self._rows_np: dict = {}                             # pos -> (alpha columns, bit matrix)
        for i, s in enumerate(self.states):
            if s in ("terminal", "done"):
                continue
            if self.problem == "tiger":
                pos, bits = None, (s == "left",)
            elif self.problem == "sensor":
                pos, bits = None, (s.startswith("a-ok"), s.endswith("b-ok"))
            elif self.problem == "probe":
                pos, bits = None, tuple(v == s for v in self.vars)
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

    def corner(self, pos, coords) -> np.ndarray:
        """A belief (or, for a categorical variable, a positive multiple of one) at a
        corner of a box. Comparisons of alpha-vectors keep their sign under positive
        scaling, so unnormalized weights are enough."""
        if self.problem != "probe":
            return self.belief(pos, [sigmoid(c) for c in coords])
        b = np.zeros(len(self.states))
        top = max(c for c in coords if c not in (INF, -INF)) if any(c not in (INF, -INF) for c in coords) else 0.0
        for i, bits in self.rows[pos]:
            c = coords[bits.index(True)]
            c = top + 60.0 if c == INF else c       # shortcut: +inf as a weight e^60 above the rest
            b[i] = 0.0 if c == -INF else math.exp(c - top)
        return b

    def _pos_rows(self, pos):
        """(alpha columns, bit matrix) of the states of observable part pos."""
        if pos not in self._rows_np:
            idx = [i for i, _ in self.rows[pos]]
            self._rows_np[pos] = (self.A[:, idx], np.array([b for _, b in self.rows[pos]], dtype=bool))
        return self._rows_np[pos]

    def value_error(self, pos) -> float:
        """Float error bound of every alpha-vector value at a belief of observable part pos
        (module value_error; not for the categorical "probe" problem)."""
        return value_error(self._pos_rows(pos)[0], len(self.vars))

    def possible_actions(self, pos, box) -> set:
        """Actions the alpha-vector policy can choose at some belief in the box
        (sound over-approximation: an action is dropped only if each of its vectors is
        beaten everywhere in the box by one vector of another action, by more than the
        float error of the values, so float evaluation at any belief in the box agrees)."""
        pts = list(itertools.product(*[(lo,) if lo == hi else (lo, hi) for lo, hi in box]))
        if self.problem == "probe":
            B = np.array([self.corner(pos, c) for c in pts])
            M = self.A @ B.T
            # exp weights are relatively accurate, so the error is relative to |A| b, whose
            # maximum over the box (multilinear) is at a corner
            err = (B.shape[1] + 5 * len(box) + 2) * EPS * float((np.abs(self.A) @ np.abs(B).T).max())
        else:                                                # vectorized self.corner on pos's rows
            A_pos, bits = self._pos_rows(pos)
            with np.errstate(over="ignore"):
                P = 1.0 / (1.0 + np.exp(-np.array(pts, dtype=float)))     # sigmoid, +-inf -> 1, 0
            B = np.where(bits[None], P[:, None, :], 1.0 - P[:, None, :]).prod(axis=2)
            M = A_pos @ B.T                                  # vectors x corners
            err = self.value_error(pos)
        # Each value, at a corner and at any belief inside, is within err of its exact value
        # (value_error), so a loss by more than 2 err at every corner is a loss at every
        # belief in the box (the exact values are multilinear) and in float evaluation there.
        margin = SAFETY * 2 * err
        winners = np.unique(M.argmax(axis=0))                # best vector at each corner
        # An action is dropped only if each of its vectors is beaten at every corner by one
        # corner winner (testing only winners keeps the check sound and fast). A vector
        # within the margin of the corner's best somewhere is beaten by no winner there
        # (float subtraction is monotone), so only the others are tested, winner by winner.
        alive = ~((M.max(axis=0) - M) > margin).all(axis=1)
        rest = np.flatnonzero(~alive)
        for w in winners[np.argsort(-M[winners].min(axis=1))]:   # most dominant winner first
            if not rest.size:
                break
            rest = rest[~((M[w] - M[rest]) > margin).all(axis=1)]
        alive[rest] = True
        return {self._names[i] for i in np.unique(self._aid[alive])}

    def step(self, pos, a):
        """[(observation, variable index or None, shift or None, new pos, terminal)]"""
        if a in self.terminal:
            return [("commit", None, None, pos, True)]
        if self.problem == "probe":
            v = self.vars.index(a[len("probe-"):])
            return [(f"hit-{self.vars[v]}", v, +self.u, pos, False),
                    (f"miss-{self.vars[v]}", v, -self.u, pos, False)]
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

    def successors(self, v: int, lo: float, hi: float, shift: float) -> range:
        """Cells that the double-precision update fl(x + shift) reaches from a double x in
        the cell [lo, hi). Rounding is monotone, so they are exactly the cells between
        fl(lo + shift) and fl(top + shift), where top is the largest double below hi."""
        if shift in (INF, -INF) or lo == hi:                 # a set value, or a point (lattice mode)
            c = self.cell(v, shift if shift in (INF, -INF) else lo + shift)
            return range(c, c + 1)
        top = math.nextafter(hi, -INF) + shift if hi != INF else INF
        return range(self.cell(v, lo + shift), self.cell(v, top) + 1)


def threshold(edge: float, shift: float) -> float:
    """The smallest double x with fl(x + shift) >= edge: splitting a cell here separates
    the doubles that an observation moves below the edge from those it moves past it."""
    x = edge - shift
    d = 4 * (math.ulp(edge) + math.ulp(shift) + math.ulp(x))
    lo, hi = x - d, x + d
    while lo + shift >= edge:
        lo, d = lo - d, 2 * d
    while hi + shift < edge:
        hi, d = hi + d, 2 * d
    while True:              # bisection keeps fl(lo + shift) < edge <= fl(hi + shift); stepping
        mid = lo + (hi - lo) / 2     # one ulp at a time never ends when |x| << |shift|
        if mid in (lo, hi):
            return hi
        lo, hi = (lo, mid) if mid + shift >= edge else (mid, hi)


def level_name(model: Model, v: int, lo: float, hi: float) -> str:
    """The evidence level of the cell, in the naming of extraction.level."""
    mid = lo + 1 if hi == INF else hi - 1 if lo == -INF else (lo + hi) / 2
    if model.u:
        k = min(9, round(abs(mid) / model.u))
    else:
        k = sum(abs(mid) >= b for b in (0.5, 2.5, 4.5))
    return "unk" if k == 0 else ("pos" if mid > 0 else "neg") + str(k)


def abstract_controller(model: Model, grid: Grid, max_states: int = 200_000,
                        points: bool = False) -> dict:
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

    n_cells = [len(e) - 1 for e in grid.edges]
    zero = grid.cell(0, 0.0)

    def canonical(cells):
        """Categorical log-weights are defined up to a common shift: move the leading
        finite value back to the start cell. Shifting only downward keeps the lower
        tail sound (a shifted tail stays inside the tail)."""
        if model.problem != "probe" or any(c == n_cells[v] - 1 for v, c in enumerate(cells)):
            return cells
        finite = [c for c in cells if c > 0]
        d = max(finite) - zero if finite else 0
        return tuple(0 if c == 0 else max(c - d, 0) for c in cells) if d > 0 else cells

    start = (model.start(), tuple(grid.cell(v, 0.0) for v in range(len(model.vars))))
    seen, frontier = {start}, [start]
    edges, commits, mixed = set(), set(), 0
    while frontier:
        pos, cells = frontier.pop()
        box = [grid.interval(v, c) for v, c in enumerate(cells)]
        if points:
            # Lattice models (every observation shifts by +-u from 0) reach only the lattice
            # point at the center of a finite unit cell: use it exactly; tails stay boxes.
            box = [(m, m) if lo != -INF and hi != INF else (lo, hi)
                   for lo, hi in box for m in [(lo + hi) / 2]]
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
                               for c in grid.successors(v, lo, hi, shift)]
                effect = frozenset()
                if model.problem == "rocksample" and a == "1" and v is not None:
                    effect = frozenset({f"sampled(rock{v + 1})"})
                for t in targets:
                    nxt = (npos, canonical(t))
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

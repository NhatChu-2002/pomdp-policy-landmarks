"""Exact landmarks and orderings by exhaustive search, independent of RHW.

Reads the SAS+ task (output.sas) that Fast Downward's translator writes and
searches its explicit state space. Only for small tasks: the state space is
enumerated in full.
"""

from __future__ import annotations

from collections import deque
from pathlib import Path


class Task:
    """Explicit-state view of output.sas (no axioms, no conditional effects)."""

    def __init__(self, path: Path):
        L = [line.strip() for line in Path(path).read_text().splitlines()]
        i = L.index("end_metric") + 1
        n = int(L[i]); i += 1
        self.names = []
        for _ in range(n):                       # begin_variable, name, layer, range, values..., end
            rng = int(L[i + 3])
            self.names.append(L[i + 4:i + 4 + rng])
            i += 5 + rng
        n_mutex = int(L[i]); i += 1
        for _ in range(n_mutex):
            i += 3 + int(L[i + 1])
        self.init = tuple(int(x) for x in L[i + 1:i + 1 + n]); i += n + 2
        g = int(L[i + 1])
        self.goal = [tuple(map(int, L[i + 2 + j].split())) for j in range(g)]; i += 3 + g
        self.ops = []
        n_ops = int(L[i]); i += 1
        for _ in range(n_ops):
            n_prevail = int(L[i + 2]); i += 3     # begin_operator, name, num_prevail
            pre = [tuple(map(int, L[i + j].split())) for j in range(n_prevail)]
            i += n_prevail
            nef = int(L[i]); i += 1
            eff = []
            for j in range(nef):
                ncond, var, old, new = map(int, L[i + j].split())
                assert ncond == 0, "conditional effects are not supported"
                eff.append((var, new))
                if old != -1:
                    pre.append((var, old))
            i += nef + 2                         # effects, cost, end_operator
            self.ops.append((tuple(pre), tuple(eff)))
        assert int(L[i]) == 0, "axioms are not supported"
        self.fact = {name: (v, x) for v, vals in enumerate(self.names)
                     for x, name in enumerate(vals) if not name.startswith("<none")}

    def facts(self, key) -> list:
        """SAS facts for atom names; names the translator pruned can never hold."""
        return [self.fact[n] for n in key if n in self.fact]

    def succ(self, s):
        for pre, eff in self.ops:
            if all(s[v] == x for v, x in pre):
                t = list(s)
                for v, x in eff:
                    t[v] = x
                yield tuple(t)

    def _search(self, starts, blocked) -> bool:
        """Can the goal be reached from `starts` through states not `blocked`?"""
        seen, queue = set(starts), deque(starts)
        while queue:
            s = queue.popleft()
            if all(s[v] == x for v, x in self.goal):
                return True
            for t in self.succ(s):
                if t not in seen and not blocked(t):
                    seen.add(t)
                    queue.append(t)
        return False

    def is_landmark(self, key) -> bool:
        """Does every plan pass through a state where some fact of `key` holds?"""
        F = self.facts(key)
        hold = lambda s: any(s[v] == x for v, x in F)  # noqa: E731
        return hold(self.init) or not self._search([self.init], hold)

    def order_holds(self, a_key, b_key) -> bool:
        """Natural ordering: on every plan an A-fact holds strictly before B first holds."""
        A, B = self.facts(a_key), self.facts(b_key)
        hold = lambda s, F: any(s[v] == x for v, x in F)  # noqa: E731
        b_first = []                             # states where B first holds, A never before
        if hold(self.init, B):
            b_first.append(self.init)
        elif not hold(self.init, A):
            seen, queue = {self.init}, deque([self.init])
            while queue:
                for t in self.succ(queue.popleft()):
                    if t in seen:
                        continue
                    seen.add(t)
                    if hold(t, B):
                        b_first.append(t)
                    elif not hold(t, A):
                        queue.append(t)
        return not (b_first and self._search(b_first, lambda s: False))

    def gn_holds(self, a_key, b_key) -> bool:
        """Greedy-necessary ordering: on every plan, A holds in the state just before B first holds."""
        A, B = self.facts(a_key), self.facts(b_key)
        hold = lambda s, F: any(s[v] == x for v, x in F)  # noqa: E731
        if hold(self.init, B):
            return True                          # B is never "first achieved" by an action
        seen, queue, violations = {self.init}, deque([self.init]), []
        while queue:
            s = queue.popleft()
            for t in self.succ(s):
                if hold(t, B):
                    if not hold(s, A):
                        violations.append(t)
                elif t not in seen:
                    seen.add(t)
                    queue.append(t)
        return not (violations and self._search(violations, lambda s: False))

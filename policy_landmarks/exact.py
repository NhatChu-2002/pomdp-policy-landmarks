"""Exact landmarks and orderings of a compiled controller, by search on its state graph.

The task Pi_alpha has one action per controller edge, so its reachable states can be
listed directly: an abstract state, the commitment facts collected so far, and whether
the episode has ended. This module enumerates them and decides exactly which facts and
which disjunctions (up to `max_size` facts with the same predicate, the form RHW uses)
are landmarks, and which natural and greedy-necessary orderings hold between them.
It needs neither a planner nor the PDDL translator; experiments compare RHW against it.
"""

from __future__ import annotations

from collections import deque
from itertools import combinations
from math import comb

from .extraction import _san


class StateGraph:
    """Reachable states of Pi_alpha for a controller from extraction.controller()."""

    def __init__(self, ctrl: dict):
        out: dict = {}
        for s, _a, _o, t, extra in ctrl["edges"]:
            out.setdefault(s, []).append((t, extra))
        for s, a in ctrl["commits"]:
            out.setdefault(s, []).append(("commit", frozenset({f"chose({_san(a)})"})))
        init = (ctrl["init"], frozenset(), False)
        self.states, self.succ, index = [init], [[]], {init: 0}
        queue = deque([0])
        while queue:
            i = queue.popleft()
            s, done_facts, ended = self.states[i]
            if ended:
                continue                          # plans stop when done first holds
            for t, extra in out.get(s, []):
                end = t == "commit" or "terminal" in t
                nxt = (s if end else t, done_facts | extra, end)
                if nxt not in index:
                    index[nxt] = len(self.states)
                    self.states.append(nxt)
                    self.succ.append([])
                    queue.append(index[nxt])
                self.succ[i].append(index[nxt])
        self.facts = [frozenset(s | c | ({"done"} if e else set())) for s, c, e in self.states]
        self.holds: dict = {}
        for i, fs in enumerate(self.facts):
            for f in fs:
                self.holds.setdefault(f, set()).add(i)
        self.goal = {i for i, (_, _, e) in enumerate(self.states) if e}
        pred: dict = {}
        for i, js in enumerate(self.succ):
            for j in js:
                pred.setdefault(j, []).append(i)
        self.alive = set(self.goal)               # states from which the goal is reachable
        queue = deque(self.goal)
        while queue:
            for i in pred.get(queue.popleft(), []):
                if i not in self.alive:
                    self.alive.add(i)
                    queue.append(i)

    def _states(self, key) -> set:
        return set().union(*(self.holds.get(f, set()) for f in key))

    def is_landmark(self, key) -> bool:
        """Does every plan pass through a state where some fact of `key` holds?"""
        hold = self._states(key)
        if 0 in hold:
            return True
        seen, queue = {0}, deque([0])
        while queue:
            i = queue.popleft()
            if i in self.goal:
                return False
            for j in self.succ[i]:
                if j not in seen and j not in hold:
                    seen.add(j)
                    queue.append(j)
        return True

    def natural(self, a_key, b_key) -> bool:
        """On every plan, A holds at some state strictly before B first holds."""
        A, B = self._states(a_key), self._states(b_key)
        if 0 in B:
            return False
        if 0 in A:
            return True
        seen, queue = {0}, deque([0])
        while queue:
            for j in self.succ[queue.popleft()]:
                if j in seen:
                    continue
                seen.add(j)
                if j in B:
                    if j in self.alive:
                        return False             # B reached first on a path that still ends
                elif j not in A:
                    queue.append(j)
        return True

    def greedy_necessary(self, a_key, b_key) -> bool:
        """On every plan, A holds in the state just before B first holds."""
        A, B = self._states(a_key), self._states(b_key)
        if 0 in B:
            return True
        seen, queue = {0}, deque([0])
        while queue:
            i = queue.popleft()
            for j in self.succ[i]:
                if j in B:
                    if i not in A and j in self.alive:
                        return False
                elif j not in seen:
                    seen.add(j)
                    queue.append(j)
        return True

    def landmarks(self, max_size: int = 3, complete=("ev-", "chose"), max_combos: int = 20_000) -> list:
        """All minimal landmarks: single facts, and disjunctions of facts with the same
        predicate. Predicates starting with a prefix in `complete` (belief levels and
        commitments, at most 16 facts each here) are enumerated in full; others, such as
        robot cells, up to `max_size` facts. Facts true initially are left out."""
        initial = self.facts[0]
        facts = sorted(f for f in self.holds if f not in initial)
        found = [frozenset([f]) for f in facts if self.is_landmark([f])]
        singles = {next(iter(k)) for k in found}
        groups: dict = {}
        for f in facts:
            if f not in singles and "(" in f:
                groups.setdefault(f.split("(")[0], []).append(f)
        self.truncated = set()                    # groups whose disjunctions were cut short
        for size in range(2, max(len(g) for g in groups.values()) + 1 if groups else 2):
            for pred_name, group in groups.items():
                if size > (len(group) if pred_name.startswith(complete) else max_size):
                    continue
                if not pred_name.startswith(complete) and comb(len(group), size) > max_combos:
                    self.truncated.add(pred_name)  # e.g. sets of cells on a large map
                    continue
                for combo in combinations(group, size):
                    key = frozenset(combo)
                    if not any(k < key for k in found) and self.is_landmark(key):
                        found.append(key)
        return found

    def orderings(self, lms: list) -> dict:
        """{(A, B): {"nat", "gn"}} for every ordered pair of landmarks with an ordering."""
        result = {}
        for a in lms:
            for b in lms:
                if a == b:
                    continue
                kinds = {k for k, ok in (("nat", self.natural(a, b)),
                                         ("gn", self.greedy_necessary(a, b))) if ok}
                if kinds:
                    result[(a, b)] = kinds
        return result


def closure(pairs: set) -> set:
    """Transitive closure of an ordering relation."""
    succ: dict = {}
    for a, b in pairs:
        succ.setdefault(a, set()).add(b)
    out = set()
    for a in succ:
        stack, seen = list(succ[a]), set()
        while stack:
            b = stack.pop()
            if b not in seen:
                seen.add(b)
                out.add((a, b))
                stack.extend(succ.get(b, ()))
    return out


def reduction(pairs: set) -> set:
    """Transitive reduction of an acyclic ordering relation (the edges a figure would draw)."""
    full = closure(pairs)
    return {(a, b) for a, b in full
            if not any((a, c) in full and (c, b) in full for c in {x for _, x in full} - {a, b})}

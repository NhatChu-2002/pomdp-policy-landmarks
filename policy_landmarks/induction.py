"""
Data-driven induction of a BSCSpec from SARSOP belief-trajectory traces.

Motivation
----------
The hand-written specs in domains.py encode the answer we expect a policy
to have.  A natural reviewer objection is: does landmark extraction recover
interpretable commitment structure only because that structure was written
into the domain file?  This module answers that by *learning* the BSC from a
solver's actual belief trajectories, with no hand-authored transitions.

Method (binary hidden variables)
--------------------------------
1. Parse the trace into per-variable pre-action belief trajectories.
2. Convert each belief P(v) to a log-odds evidence magnitude and quantise it
   into integer evidence *levels* using a learned unit step.
3. Learn two thresholds purely from data:
     theta_know   = 1                     (any nonzero evidence => leaning)
     theta_commit = min evidence level at which the policy took a
                    commit / terminal action
4. Map each level to the BSC predicate vocabulary:
     level 0                        -> uncertain   {}
     theta_know <= L < theta_commit -> leaning     {k(dom)}
     L >= theta_commit              -> confident   {k(dom), k-not(oth)}
5. Mine one BSCTransition per distinct (state, observation) -> next-state pair
   observed in the trace (updates = facts gained, retractions = facts lost).
6. Mine CommitConditions from the states in which commit/terminal actions fire.
7. Emit a BSCSpec plus an InductionReport (levels, thresholds, coverage, and
   the transition kinds discovered -- notably whether the policy performs
   graded Bayesian *decrement* rather than a full reset).

Only binary hidden variables are supported; this covers Tiger (direction) and
RockSample (per-rock quality).  Larger-cardinality domains (channel, mine) have
no belief-trajectory traces available and remain hand-specified.
"""

from __future__ import annotations

import csv
import math
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Dict, List, Optional, Sequence, Tuple

from .spec import (
    BSCSpec, BSCTransition, BeliefRef, BeliefUpdate, CommitCondition, HiddenVariable,
)


# ===========================================================================
#  Log-odds evidence levels
# ===========================================================================

_EPS = 1e-9


def log_odds(p: float) -> float:
    """Signed log-odds ln(p / (1-p)); clamped away from 0 and 1."""
    p = min(1.0 - _EPS, max(_EPS, p))
    return math.log(p / (1.0 - p))


# ===========================================================================
#  Abstract belief state (per binary variable)
# ===========================================================================
#
#  A fact is a (polarity, value) pair:
#     ("pos", v)  ==  k(var, v)
#     ("neg", v)  ==  k-not(var, v)
#  A variable's abstract state is a frozenset of such facts.

Fact = Tuple[str, str]              # (polarity, value)
State = frozenset                   # frozenset[Fact]


def _abstract_state(dom: str, oth: str, level: int, theta_commit: int) -> State:
    """Map an evidence level (magnitude, dom = favoured value) to facts."""
    if level <= 0:
        return frozenset()                              # uncertain
    if level < theta_commit:
        return frozenset({("pos", dom)})                # leaning
    return frozenset({("pos", dom), ("neg", oth)})      # confident


# ===========================================================================
#  Parsed trace datum
# ===========================================================================

@dataclass(frozen=True)
class VarObservation:
    """A single (pre-belief, observation) datum for one binary variable."""
    var: str
    values: Tuple[str, str]          # (value0, value1)
    p0: float                        # pre-action P(value0)
    obs: str                         # observation symbol driving the update
    is_commit: bool                  # did a commit/terminal action fire here?


# ===========================================================================
#  Induction report
# ===========================================================================

@dataclass
class InductionReport:
    domain: str
    source_csv: str
    variables: List[str]
    unit_logodds: float
    levels_observed: List[int]
    theta_know: int
    theta_commit: int
    n_transitions: int
    n_commit_conditions: int
    transition_kinds: Dict[str, int]        # kind -> count
    has_graded_decrement: bool
    coverage_steps_total: int
    coverage_steps_explained: int
    nondeterministic_pairs: int

    def coverage_fraction(self) -> float:
        if self.coverage_steps_total == 0:
            return 0.0
        return self.coverage_steps_explained / self.coverage_steps_total

    def as_dict(self) -> dict:
        d = self.__dict__.copy()
        d["coverage_fraction"] = round(self.coverage_fraction(), 4)
        return d


# ===========================================================================
#  Precondition builders
# ===========================================================================

def _state_refs(var: str, st: State, *, holds: bool) -> Tuple[BeliefRef, ...]:
    return tuple(
        BeliefRef(var, val, pol, holds=holds) for (pol, val) in sorted(st)
    )


def _precs_for_state(var: str, st: State, oth: str,
                     domain: Tuple[str, str]) -> Tuple[BeliefRef, ...]:
    """Belief preconditions that pin the controller to abstract state `st`.

    - uncertain : both values' k-fact absent (triggers the encoder's
                  uncertain-VAR optimisation, matching the hand specs).
    - leaning   : k(dom) holds and k-not(oth) is absent (distinguishes
                  leaning from confident).
    - confident : k(dom) holds and k-not(oth) holds.
    """
    if not st:
        v0, v1 = domain
        return (
            BeliefRef(var, v0, "pos", holds=False),
            BeliefRef(var, v1, "pos", holds=False),
        )
    refs: List[BeliefRef] = [
        BeliefRef(var, val, pol, holds=True) for (pol, val) in sorted(st)
    ]
    has_neg = any(pol == "neg" for pol, _ in st)
    if not has_neg:
        refs.append(BeliefRef(var, oth, "neg", holds=False))
    return tuple(refs)


def _classify(cur: State, nxt: State) -> str:
    """Human-readable kind label for a canonical-frame state->state edge."""
    cl, nl = len(cur), len(nxt)
    if cl == 0 and nl >= 1:
        return "form-belief (uncertain->leaning)" if nl == 1 \
            else "form-belief-direct (uncertain->confident)"
    if cl == 1 and nl == 2:
        return "confirm (leaning->confident)"
    if cl == 2 and nl == 1:
        return "graded-decrement (confident->leaning)"
    if cl == 1 and nl == 0:
        return "reset (leaning->uncertain)"
    if cl == 2 and nl == 0:
        return "full-reset (confident->uncertain)"
    return f"other ({cl}->{nl})"


# ===========================================================================
#  Core induction (binary variables, optional pooling)
# ===========================================================================

def induce_binary_bsc(
    episodes: Sequence[List[VarObservation]],
    *,
    name: str,
    role_of: Optional[Callable[[str, str], str]] = None,
) -> Tuple[BSCSpec, InductionReport]:
    """Induce a BSCSpec from per-episode lists of VarObservation.

    role_of : optional callable (var, value) -> role.  When given, the
        variables are treated as ISOMORPHIC instances of one shared template:
        transitions/commits are mined in the role frame by pooling every
        variable's data, then instantiated for each variable.  This lets a
        single trace in which different instances exhibit different outcomes
        (e.g. RockSample: 3 rocks good, 1 bad) recover the full per-instance
        structure -- including disjunctive belief landmarks -- that no single
        instance witnesses on its own.
    """
    # ---- collect per-variable domains & per-episode trajectories ----------
    #  Keep episode boundaries: transitions are only mined *within* an
    #  episode, never across the reset between two independent runs.
    var_domain: Dict[str, Tuple[str, str]] = {}
    traj: Dict[str, List[List[Tuple[float, str, bool]]]] = defaultdict(list)
    for episode in episodes:
        per_var: Dict[str, List[Tuple[float, str, bool]]] = defaultdict(list)
        for vo in episode:
            var_domain[vo.var] = vo.values
            per_var[vo.var].append((vo.p0, vo.obs, vo.is_commit))
        for v, steps in per_var.items():
            traj[v].append(steps)
    variables = list(var_domain.keys())

    def _all_steps(v: str):
        for run in traj[v]:
            yield from run

    # ---- learn the unit log-odds step -------------------------------------
    mags = [
        abs(log_odds(p0))
        for v in variables for p0, _o, _c in _all_steps(v)
        if abs(log_odds(p0)) > _EPS
    ]
    unit = min(mags) if mags else 1.0

    # ---- learn theta_commit from commit rows ------------------------------
    commit_levels = [
        round(abs(log_odds(p0)) / unit)
        for v in variables for p0, _o, is_commit in _all_steps(v) if is_commit
    ]
    theta_commit = max(min(commit_levels), 1) if commit_levels else 2
    theta_know = 1

    levels_seen: set = set()

    def var_state_runs(v: str) -> List[List[Tuple[State, str, bool, str, str]]]:
        """Abstract state sequences, one list per episode (no cross-episode edges)."""
        v0, v1 = var_domain[v]
        runs: List[List[Tuple[State, str, bool, str, str]]] = []
        for run in traj[v]:
            out = []
            for p0, obs, is_commit in run:
                L = log_odds(p0)                   # >0 favours v0
                lvl = round(abs(L) / unit)
                levels_seen.add(lvl if L >= 0 else -lvl)
                dom, oth = (v0, v1) if L >= 0 else (v1, v0)
                out.append((_abstract_state(dom, oth, lvl, theta_commit),
                            obs, is_commit, dom, oth))
            runs.append(out)
        return runs

    def canon(st: State, dom: str) -> State:
        return frozenset((pol, "D" if val == dom else "O") for pol, val in st)

    transitions: List[BSCTransition] = []
    commit_conditions: List[CommitCondition] = []
    seen_trans: set = set()
    seen_commit: set = set()
    kinds: Dict[str, int] = defaultdict(int)
    pair_outcomes: Dict[Tuple, set] = defaultdict(set)
    steps_total = 0
    has_decrement = False

    #  Pooled (role-frame) templates: when role_of is given, every observed
    #  move is recorded once in the shared role frame, then instantiated for
    #  ALL variables.  A single trace in which different instances show
    #  different outcomes therefore yields the full per-instance structure.
    def to_role(st: State, v: str) -> State:
        return frozenset((pol, role_of(v, val)) for (pol, val) in st)

    template_moves: set = set()          # (obs, cur_role, nxt_role, dom_role, oth_role)
    template_commits: set = set()        # (st_role, dom_role)

    def emit_transition(v: str, cur: State, nxt: State, obs: str, oth: str) -> None:
        precs = _precs_for_state(v, cur, oth, var_domain[v])
        updates = tuple(
            BeliefUpdate(v, val, pol)
            for (pol, val) in nxt if (pol, val) not in cur
        )
        retracts = tuple(
            BeliefUpdate(v, val, pol)
            for (pol, val) in cur if (pol, val) not in nxt
        )
        tkey = (v, obs, precs, updates, retracts)
        if tkey not in seen_trans:
            seen_trans.add(tkey)
            transitions.append(BSCTransition(
                observation=obs, belief_precs=precs,
                belief_updates=updates, retractions=retracts,
            ))

    def emit_commit(v: str, st: State, dom: str) -> None:
        ck = (v, dom)
        if ck not in seen_commit:
            seen_commit.add(ck)
            commit_conditions.append(CommitCondition(
                variable=v, commit_value=dom,
                belief_precs=_state_refs(v, st, holds=True),
            ))

    for v in variables:
        for seq in var_state_runs(v):
            for i in range(len(seq) - 1):
                cur, obs, _is_c, dom, oth = seq[i]
                nxt, _o2, _c2, _d2, _o2b = seq[i + 1]
                steps_total += 1
                pair_outcomes[(canon(cur, dom), obs)].add(canon(nxt, dom))
                if cur == nxt:
                    kinds["self-loop (no belief change)"] += 1
                    continue
                kind = _classify(canon(cur, dom), canon(nxt, dom))
                kinds[kind] += 1
                if kind.startswith("graded-decrement"):
                    has_decrement = True
                if role_of is None:
                    emit_transition(v, cur, nxt, obs, oth)
                else:
                    template_moves.add((
                        obs, to_role(cur, v), to_role(nxt, v),
                        role_of(v, dom), role_of(v, oth),
                    ))
            for st, _obs, is_commit, dom, _oth in seq:
                if is_commit and st:
                    if role_of is None:
                        emit_commit(v, st, dom)
                    else:
                        template_commits.add((to_role(st, v), role_of(v, dom)))

    #  Instantiate the pooled role-frame templates for every variable.
    if role_of is not None:
        for v in variables:
            v0, v1 = var_domain[v]
            inv = {role_of(v, v0): v0, role_of(v, v1): v1}
            for obs, cur_r, nxt_r, dom_r, oth_r in sorted(
                template_moves, key=lambda m: (m[0], sorted(m[1]), sorted(m[2]))
            ):
                cur = frozenset((pol, inv[r]) for (pol, r) in cur_r)
                nxt = frozenset((pol, inv[r]) for (pol, r) in nxt_r)
                emit_transition(v, cur, nxt, obs, inv[oth_r])
            for st_r, dom_r in sorted(
                template_commits, key=lambda c: (sorted(c[0]), c[1])
            ):
                st = frozenset((pol, inv[r]) for (pol, r) in st_r)
                emit_commit(v, st, inv[dom_r])

    nondet = sum(1 for outs in pair_outcomes.values() if len(outs) > 1)
    steps_explained = steps_total - nondet

    spec = BSCSpec(
        name=name,
        hidden_variables=[
            HiddenVariable(name=v, domain=var_domain[v]) for v in variables
        ],
        observations=sorted({vo.obs for ep in episodes for vo in ep}),
        transitions=transitions,
        commit_conditions=commit_conditions,
    )
    report = InductionReport(
        domain=name, source_csv="", variables=variables,
        unit_logodds=round(unit, 4), levels_observed=sorted(levels_seen),
        theta_know=theta_know, theta_commit=theta_commit,
        n_transitions=len(transitions),
        n_commit_conditions=len(commit_conditions),
        transition_kinds=dict(kinds), has_graded_decrement=has_decrement,
        coverage_steps_total=steps_total,
        coverage_steps_explained=steps_explained,
        nondeterministic_pairs=nondet,
    )
    return spec, report


# ===========================================================================
#  Trace parsers  (produce lists of VarObservation episodes)
# ===========================================================================

def _rows(csv_path: Path) -> List[List[str]]:
    with csv_path.open("r", newline="", encoding="utf-8") as fh:
        return [r for r in csv.reader(fh) if r and r[0].strip() == "TRACE"]


TIGER_TERMINALS = {"left", "right"}   # open-door actions (not 'listen')


def parse_tiger(csv_path: Path) -> List[List[VarObservation]]:
    """TRACE,<ep>,<action>,<obs>,<p_left>,<p_right>  (pre-action belief)."""
    episodes: Dict[int, List[VarObservation]] = defaultdict(list)
    for r in _rows(csv_path):
        if len(r) < 6:
            continue
        try:
            ep = int(r[1]); p_left = float(r[4])
        except ValueError:
            continue
        action = r[2].strip().lower()
        obs = r[3].strip().lower()
        episodes[ep].append(VarObservation(
            var="direction", values=("left", "right"),
            p0=p_left, obs=obs, is_commit=action in TIGER_TERMINALS,
        ))
    return [episodes[k] for k in sorted(episodes)]


# RockSample action / observation encoding (see trace_adapters_bsc.py)
_RS_SAMPLE_ACTION = 5
_RS_SENSE_OFFSET = 5           # sense rock i == action 5+i
_RS_OBS_GOOD = 1


def parse_rocksample(csv_path: Path, num_rocks: int = 4
                     ) -> List[List[VarObservation]]:
    """TRACE,t,x,y,action,obs,reward,belief_r1..rN,true_r1..rN (pre-action).

    The belief is the PRE-action belief, so a sense action's effect appears on
    the NEXT row.  We drive parsing off the action/observation columns
    (sense rock k == action 5+k, obs 1=GOOD/2=BAD) and read the resulting
    confident belief from the following row.  Each sensed rock yields a
    two-step run:  uncertain(pre) --sense-obs--> confident(post, is_commit).
    """
    data = []
    for r in _rows(csv_path):
        try:
            int(r[1]); data.append(r)
        except (ValueError, IndexError):
            continue
    bcol = 7
    episode: List[VarObservation] = []
    for idx, r in enumerate(data):
        try:
            action = int(r[4]); obs = int(r[5])
        except (ValueError, IndexError):
            continue
        target = action - _RS_SENSE_OFFSET          # 6->1 .. 9->4
        if not (1 <= target <= num_rocks):
            continue
        col = bcol + (target - 1)
        try:
            pre = float(r[col])
        except (ValueError, IndexError):
            continue
        # confident belief = same rock's belief on the following row
        if idx + 1 >= len(data):
            continue
        try:
            post = float(data[idx + 1][col])
        except (ValueError, IndexError):
            continue
        obs_sym = "sense-good" if obs == _RS_OBS_GOOD else "sense-bad"
        var = f"rock-{target}"
        vals = (f"r{target}-good", f"r{target}-bad")
        episode.append(VarObservation(var=var, values=vals,
                                      p0=pre, obs=obs_sym, is_commit=False))
        episode.append(VarObservation(var=var, values=vals,
                                      p0=post, obs=obs_sym, is_commit=True))
    return [episode] if episode else []


def parse_sensor(csv_path: Path) -> List[List[VarObservation]]:
    """TRACE,sim,t,action,obs,p_a-ok,p_a-faulty,p_b-ok,p_b-faulty (pre-action).

    Two INDEPENDENT binary variables (sensor-a: ok/faulty, sensor-b: ok/faulty).
    Each row's pre-action marginals give both variables' belief; the read-X
    observation drives only variable X, so the other variable self-loops (its
    belief is unchanged) and those steps are skipped by the miner.  Over many
    sims each sensor is read to both outcomes, so per-variable induction alone
    recovers both k-ok and k-faulty branches (no pooling needed).
    """
    episodes: Dict[int, List[VarObservation]] = defaultdict(list)
    for r in _rows(csv_path):
        if len(r) < 9:
            continue
        try:
            sim = int(r[1]); p_a_ok = float(r[5]); p_b_ok = float(r[7])
        except ValueError:
            continue
        action = r[3].strip().lower()
        obs = r[4].strip().lower()
        is_commit = action.startswith("commit")
        episodes[sim].append(VarObservation(
            var="sensor-a", values=("a-ok", "a-faulty"),
            p0=p_a_ok, obs=obs if action == "read-a" else "none",
            is_commit=is_commit,
        ))
        episodes[sim].append(VarObservation(
            var="sensor-b", values=("b-ok", "b-faulty"),
            p0=p_b_ok, obs=obs if action == "read-b" else "none",
            is_commit=is_commit,
        ))
    return [episodes[k] for k in sorted(episodes)]


# ===========================================================================
#  Trace sources (SARSOP rollouts written by the Julia models in pomdp/)
# ===========================================================================

POMDP_DIR = Path(__file__).resolve().parents[1] / "pomdp"

# name -> (parse episodes, role_of). RockSample pools its isomorphic rocks:
# one trajectory checks each rock once, so per-rock data is too sparse alone.
TRACE_SOURCES: Dict[str, Tuple[Callable[[], list], Optional[Callable]]] = {
    "tiger": (lambda: parse_tiger(POMDP_DIR / "tiger_policy.csv"), None),
    "sensor-2": (lambda: parse_sensor(POMDP_DIR / "sensor_trace.csv"), None),
    "rocksample-4": (
        lambda: parse_rocksample(POMDP_DIR / "rock_trace.csv", num_rocks=4),
        lambda var, val: "good" if val.endswith("good") else "bad",
    ),
}


def induce(name: str) -> Tuple[BSCSpec, InductionReport]:
    """Induce the controller for a trace source in TRACE_SOURCES."""
    parse, role_of = TRACE_SOURCES[name]
    episodes = parse()
    if not episodes:
        raise ValueError(f"no usable trace data for {name}")
    spec, report = induce_binary_bsc(episodes, name=f"{name}-induced", role_of=role_of)
    spec.validate()
    return spec, report

"""
Belief-State Controller (BSC) specification types.

The encoder takes a BSCSpec as input and produces PDDL.
Unlike the FSC approach, there are NO abstract memory nodes.
The sole state representation is the belief — tracked via k/k-not predicates.

Key difference from fsc_spec.py:
  FSC: state = at(node) + k-facts   (node is abstract memory)
  BSC: state = k-facts only          (belief IS the state)

Each BSCTransition fires when its belief preconditions hold and a particular
observation is received. It then writes new belief facts or retracts old ones.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, List, Tuple


# ----------------------------- Hidden variables -----------------------------

@dataclass(frozen=True)
class HiddenVariable:
    """One factor of the POMDP's hidden state.

    name   : identifier used as PDDL type name (e.g., "direction", "quality-r1")
    domain : value names (e.g., ("left", "right")) — become PDDL objects
    """
    name: str
    domain: Tuple[str, ...]

    @property
    def cardinality(self) -> int:
        return len(self.domain)


# ----------------------------- Belief predicates ----------------------------

@dataclass(frozen=True)
class BeliefUpdate:
    """A belief predicate to assert or retract when a transition fires.

    variable : HiddenVariable name
    value    : domain value of that variable
    polarity : 'pos' → assert k(variable, value)
               'neg' → assert k-not(variable, value)
    """
    variable: str
    value: str
    polarity: str  # 'pos' or 'neg'

    def __post_init__(self):
        if self.polarity not in ("pos", "neg"):
            raise ValueError(f"polarity must be 'pos' or 'neg', got {self.polarity!r}")


@dataclass(frozen=True)
class BeliefRef:
    """Reference to an existing belief predicate, used in preconditions.

    variable : HiddenVariable name
    value    : domain value
    polarity : 'pos' → refers to k(variable, value)
               'neg' → refers to k-not(variable, value)
    holds    : True  → predicate must hold (positive precondition)
               False → predicate must NOT hold (negative precondition)
    """
    variable: str
    value: str
    polarity: str   # 'pos' or 'neg'
    holds: bool     # True = must hold, False = must not hold

    def __post_init__(self):
        if self.polarity not in ("pos", "neg"):
            raise ValueError(f"polarity must be 'pos' or 'neg', got {self.polarity!r}")


# ----------------------------- BSC transitions ------------------------------

@dataclass(frozen=True)
class BSCTransition:
    """One sense-action variant of the belief-state controller.

    A BSCTransition fires when:
      (a) all preconditions hold (belief_precs), AND
      (b) the given observation is received.

    It then:
      - asserts new belief facts (belief_updates)
      - retracts stale belief facts (retractions) — used for contradictory resets

    Fields:
      observation   : observation symbol that triggers this transition
      belief_precs  : BeliefRef list — belief predicates that must / must not hold
                      for this transition to be applicable
      belief_updates: BeliefUpdate list — k/k-not facts to assert after firing
      retractions   : BeliefUpdate list — k/k-not facts to retract after firing
                      (polarity indicates WHICH predicate to remove:
                       'pos' → retract k(var, val); 'neg' → retract k-not(var, val))
    """
    observation: str
    belief_precs: Tuple[BeliefRef, ...] = ()
    belief_updates: Tuple[BeliefUpdate, ...] = ()
    retractions: Tuple[BeliefUpdate, ...] = ()


# ----------------------------- Commit conditions ----------------------------

@dataclass(frozen=True)
class CommitCondition:
    """The belief state required to fire a commit action for one hidden variable.

    When all belief_precs hold, the agent may commit to the value `commit_value`
    of variable `variable`.

    variable     : which HiddenVariable this commit is about
    commit_value : the value being committed to (e.g., "left")
    belief_precs : the belief facts that must hold to enable this commit
    """
    variable: str
    commit_value: str
    belief_precs: Tuple[BeliefRef, ...] = ()


# ---------------------------- Full specification ----------------------------

@dataclass
class BSCSpec:
    """Complete specification of a belief-state controller for PDDL compilation.

    There are NO controller nodes. The belief state — represented by the set of
    k/k-not predicates that currently hold — is the entire controller state.

    Fields:
      name             : problem name (used in PDDL :domain and :problem headers)
      hidden_variables : list of independent hidden factors
      observations     : list of observation symbols
      transitions      : BSCTransition list — one entry per distinct sense-action
                         variant (differentiated by belief preconditions + observation)
      commit_conditions: CommitCondition list — one per (variable, value) pair that
                         the controller can commit to
      goal_confirm_per : for each hidden variable name, whether the goal requires
                         a commitment on that variable (default True for all)
    """
    name: str
    hidden_variables: List[HiddenVariable]
    observations: List[str]
    transitions: List[BSCTransition]
    commit_conditions: List[CommitCondition]
    goal_confirm_per: Dict[str, bool] = field(default_factory=dict)

    def validate(self) -> None:
        """Catch common spec errors before PDDL generation."""
        var_map: Dict[str, HiddenVariable] = {v.name: v for v in self.hidden_variables}

        def _check_belief_ref(ref: BeliefRef, ctx: str) -> None:
            assert ref.variable in var_map, \
                f"{ctx}: unknown variable {ref.variable!r}"
            assert ref.value in var_map[ref.variable].domain, \
                f"{ctx}: value {ref.value!r} not in domain of {ref.variable!r}"

        def _check_belief_update(bu: BeliefUpdate, ctx: str) -> None:
            assert bu.variable in var_map, \
                f"{ctx}: unknown variable {bu.variable!r}"
            assert bu.value in var_map[bu.variable].domain, \
                f"{ctx}: value {bu.value!r} not in domain of {bu.variable!r}"

        for i, t in enumerate(self.transitions):
            ctx = f"transition[{i}] obs={t.observation!r}"
            assert t.observation in self.observations, \
                f"{ctx}: observation {t.observation!r} not in observations list"
            for ref in t.belief_precs:
                _check_belief_ref(ref, ctx)
            for bu in t.belief_updates:
                _check_belief_update(bu, ctx)
            for bu in t.retractions:
                _check_belief_update(bu, ctx)

        for i, cc in enumerate(self.commit_conditions):
            ctx = f"commit_condition[{i}] var={cc.variable!r} val={cc.commit_value!r}"
            assert cc.variable in var_map, \
                f"{ctx}: unknown variable {cc.variable!r}"
            assert cc.commit_value in var_map[cc.variable].domain, \
                f"{ctx}: commit_value {cc.commit_value!r} not in domain of {cc.variable!r}"
            for ref in cc.belief_precs:
                _check_belief_ref(ref, ctx)

        # default: confirm all hidden variables
        for v in self.hidden_variables:
            self.goal_confirm_per.setdefault(v.name, True)

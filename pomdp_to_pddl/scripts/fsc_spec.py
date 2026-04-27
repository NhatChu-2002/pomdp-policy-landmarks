"""
FSC-POMDP specification types.

The encoder takes one of these as input and produces PDDL.
Keep this file free of PDDL concerns — it's purely the domain model.
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple


# ----------------------------- Hidden variables -----------------------------

@dataclass(frozen=True)
class HiddenVariable:
    """One factor of the POMDP's hidden state.

    Two independent HiddenVariables produce two independent disjunction pairs
    in the compiled PDDL — this is what the bijection result relies on.

    name       : identifier used as PDDL type name (e.g., "direction", "channel")
    domain     : list of value names (e.g., ["left", "right"]) — become PDDL objects
    """
    name: str
    domain: Tuple[str, ...]

    @property
    def cardinality(self) -> int:
        return len(self.domain)


# ----------------------------- FSC transitions ------------------------------

@dataclass(frozen=True)
class BeliefUpdate:
    """What to write to belief when a sensing action fires.

    After a sense action returns observation `obs`, the agent updates belief.
    We encode this as: "set k(variable, value) true" or "set k-not(variable, value) true".

    variable   : HiddenVariable name
    value      : which domain value of that variable
    polarity   : 'pos'  → set k(variable, value)
                 'neg'  → set k-not(variable, value)
    """
    variable: str
    value: str
    polarity: str  # 'pos' or 'neg'

    def __post_init__(self):
        if self.polarity not in ("pos", "neg"):
            raise ValueError(f"polarity must be 'pos' or 'neg', got {self.polarity!r}")


@dataclass(frozen=True)
class FSCTransition:
    """A single (from, observation) → (to, belief-updates) edge of the FSC.

    from_node      : source FSC node
    observation    : observation symbol triggering this transition
    to_node        : destination FSC node
    belief_updates : belief predicates to set when this transition fires
                     (empty list allowed — e.g., for a pure "retry" transition)
    """
    from_node: str
    observation: str
    to_node: str
    belief_updates: Tuple[BeliefUpdate, ...] = ()


# ---------------------------- Full specification ----------------------------

@dataclass
class FSCPomdpSpec:
    """Complete specification of an FSC-POMDP pair for PDDL compilation.

    Fields:
      name               : problem name (used in PDDL :domain and :problem headers)
      hidden_variables   : list of independent hidden factors
      fsc_nodes          : list of FSC node names
      initial_node       : which FSC node is the start
      commit_nodes       : FSC nodes from which goal-bearing actions can fire.
                            Usually just one ("ncommit"), but Minesweeper has three.
      observations       : list of observation symbols
      transitions        : FSC transitions (may include retry/reset edges)
      goal_confirm_per   : for each hidden variable name, whether the goal requires
                            confirming that variable. Usually all of them.
    """
    name: str
    hidden_variables: List[HiddenVariable]
    fsc_nodes: List[str]
    initial_node: str
    commit_nodes: List[str]
    observations: List[str]
    transitions: List[FSCTransition]
    goal_confirm_per: Dict[str, bool] = field(default_factory=dict)

    def validate(self) -> None:
        """Catch common spec errors before PDDL generation."""
        assert self.initial_node in self.fsc_nodes, \
            f"initial_node {self.initial_node!r} not in fsc_nodes"
        for cn in self.commit_nodes:
            assert cn in self.fsc_nodes, f"commit_node {cn!r} not in fsc_nodes"
        var_names = {v.name for v in self.hidden_variables}
        for t in self.transitions:
            assert t.from_node in self.fsc_nodes, f"unknown from_node {t.from_node!r}"
            assert t.to_node in self.fsc_nodes, f"unknown to_node {t.to_node!r}"
            assert t.observation in self.observations, f"unknown observation {t.observation!r}"
            for bu in t.belief_updates:
                assert bu.variable in var_names, f"unknown variable {bu.variable!r}"
                vvals = {v.domain for v in self.hidden_variables if v.name == bu.variable}
                assert any(bu.value in d for d in vvals), \
                    f"value {bu.value!r} not in domain of {bu.variable!r}"
        # default: confirm all hidden variables
        for v in self.hidden_variables:
            self.goal_confirm_per.setdefault(v.name, True)

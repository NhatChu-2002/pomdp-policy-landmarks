"""
Domain specifications for the four validated POMDPs.

Each one builds an FSCPomdpSpec that the encoder turns into PDDL.
Start small: Tiger and Channel are here; add Sensor and Minesweeper
by following the same pattern.
"""

from fsc_spec import (
    FSCPomdpSpec,
    HiddenVariable,
    FSCTransition,
    BeliefUpdate,
)


# ======================================================================
#  Tiger (1 hidden variable, cardinality 2)
# ======================================================================
#
# Hidden state: which door hides the tiger.
# FSC: listen from nroot, branch on observation (growl-left / growl-right)
#       to intermediate nodes, then second listen drives commit.

def tiger_spec() -> FSCPomdpSpec:
    direction = HiddenVariable(name="direction", domain=("left", "right"))

    return FSCPomdpSpec(
        name="tiger",
        hidden_variables=[direction],
        fsc_nodes=["nroot", "nl1", "nr1", "ncommit"],
        initial_node="nroot",
        commit_nodes=["ncommit"],
        observations=["growl-left", "growl-right"],
        transitions=[
            # First listen from nroot: branch to intermediate per observation,
            # with positive belief about the direction.
            FSCTransition("nroot", "growl-left",  "nl1",
                          (BeliefUpdate("direction", "left",  "pos"),)),
            FSCTransition("nroot", "growl-right", "nr1",
                          (BeliefUpdate("direction", "right", "pos"),)),
            # Confirming second listen → ncommit, add k-not for the other side.
            FSCTransition("nl1", "growl-left",  "ncommit",
                          (BeliefUpdate("direction", "right", "neg"),)),
            FSCTransition("nr1", "growl-right", "ncommit",
                          (BeliefUpdate("direction", "left",  "neg"),)),
            # Contradicting listen → return to nroot (no belief update).
            FSCTransition("nl1", "growl-right", "nroot"),
            FSCTransition("nr1", "growl-left",  "nroot"),
        ],
    )


# ======================================================================
#  Noisy Channel (1 hidden variable, cardinality 3)
# ======================================================================
#
# Three channels, exactly one live. Probe returns "signal" or "noise".
# FSC: first probe from nroot branches to nc1s/nc2s/nc3s (positive belief),
#      confirming second probe → ncommit (negative belief for ruled-out).
# For simplicity we use a uniform "probe" action here — the distinction
# between probing c1 vs c2 vs c3 is carried by the trans-* facts.

def channel_spec() -> FSCPomdpSpec:
    channel = HiddenVariable(name="channel", domain=("c1", "c2", "c3"))

    transitions = []
    # First probe: root → intermediate with k(channel=c*)
    transitions += [
        FSCTransition("nroot", "signal-c1", "nc1s",
                      (BeliefUpdate("channel", "c1", "pos"),)),
        FSCTransition("nroot", "signal-c2", "nc2s",
                      (BeliefUpdate("channel", "c2", "pos"),)),
        FSCTransition("nroot", "signal-c3", "nc3s",
                      (BeliefUpdate("channel", "c3", "pos"),)),
    ]
    # Second probe from intermediate → commit, write k-not for the other two.
    # Only one k-not is written per edge (engine limitation noted in encoder).
    # To produce BOTH k-nots, we chain two edges that write one each.
    transitions += [
        FSCTransition("nc1s", "noise-c2",  "ncommit",
                      (BeliefUpdate("channel", "c2", "neg"),)),
        FSCTransition("nc1s", "noise-c3",  "ncommit",
                      (BeliefUpdate("channel", "c3", "neg"),)),
        FSCTransition("nc2s", "noise-c1",  "ncommit",
                      (BeliefUpdate("channel", "c1", "neg"),)),
        FSCTransition("nc2s", "noise-c3",  "ncommit",
                      (BeliefUpdate("channel", "c3", "neg"),)),
        FSCTransition("nc3s", "noise-c1",  "ncommit",
                      (BeliefUpdate("channel", "c1", "neg"),)),
        FSCTransition("nc3s", "noise-c2",  "ncommit",
                      (BeliefUpdate("channel", "c2", "neg"),)),
    ]
    # Contradicting probe (got another signal) → retry from nroot
    transitions += [
        FSCTransition("nc1s", "signal-c2", "nroot"),
        FSCTransition("nc1s", "signal-c3", "nroot"),
        FSCTransition("nc2s", "signal-c1", "nroot"),
        FSCTransition("nc2s", "signal-c3", "nroot"),
        FSCTransition("nc3s", "signal-c1", "nroot"),
        FSCTransition("nc3s", "signal-c2", "nroot"),
    ]

    return FSCPomdpSpec(
        name="channel",
        hidden_variables=[channel],
        fsc_nodes=["nroot", "nc1s", "nc2s", "nc3s", "ncommit"],
        initial_node="nroot",
        commit_nodes=["ncommit"],
        observations=[
            "signal-c1", "signal-c2", "signal-c3",
            "noise-c1",  "noise-c2",  "noise-c3",
        ],
        transitions=transitions,
    )

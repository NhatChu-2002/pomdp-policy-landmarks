"""
Domain specifications for the four validated POMDPs.

Each one builds an FSCPomdpSpec that the encoder turns into PDDL.
Use this file for domains that do not have CSV traces yet. Trace-backed
domains live in trace_adapters.py.
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


# ======================================================================
#  Faulty Sensor (2 hidden variables, cardinality 2 each)
# ======================================================================
#
# This is the non-trace version of the sensor pipeline. The two hidden
# variables are independent sensor health states:
#   sensor-a in {ok, faulty}
#   sensor-b in {ok, faulty}
#
# Each sensor is read in two steps:
#   1. write positive belief k-sensor-*(ok/faulty)
#   2. write complementary negative belief k-not-sensor-*(faulty/ok)
#
# The split is deliberate: the generic encoder models one belief write per
# transition, and this structure should expose four belief disjunctions:
#   k(sensor-a ok/faulty), k-not(sensor-a ok/faulty),
#   k(sensor-b ok/faulty), k-not(sensor-b ok/faulty).

def sensor_spec() -> FSCPomdpSpec:
    sensor_a = HiddenVariable(name="sensor-a", domain=("a-ok", "a-faulty"))
    sensor_b = HiddenVariable(name="sensor-b", domain=("b-ok", "b-faulty"))

    transitions = [
        FSCTransition(
            "nroot",
            "a-agree",
            "na-ok",
            (BeliefUpdate("sensor-a", "a-ok", "pos"),),
        ),
        FSCTransition(
            "nroot",
            "a-disagree",
            "na-faulty",
            (BeliefUpdate("sensor-a", "a-faulty", "pos"),),
        ),
        FSCTransition(
            "na-ok",
            "a-agree",
            "nb-start",
            (BeliefUpdate("sensor-a", "a-faulty", "neg"),),
        ),
        FSCTransition(
            "na-faulty",
            "a-disagree",
            "nb-start",
            (BeliefUpdate("sensor-a", "a-ok", "neg"),),
        ),
        # Contradictory second reading: restart sensor A.
        FSCTransition("na-ok", "a-disagree", "nroot"),
        FSCTransition("na-faulty", "a-agree", "nroot"),

        FSCTransition(
            "nb-start",
            "b-agree",
            "nb-ok",
            (BeliefUpdate("sensor-b", "b-ok", "pos"),),
        ),
        FSCTransition(
            "nb-start",
            "b-disagree",
            "nb-faulty",
            (BeliefUpdate("sensor-b", "b-faulty", "pos"),),
        ),
        FSCTransition(
            "nb-ok",
            "b-agree",
            "ncommit",
            (BeliefUpdate("sensor-b", "b-faulty", "neg"),),
        ),
        FSCTransition(
            "nb-faulty",
            "b-disagree",
            "ncommit",
            (BeliefUpdate("sensor-b", "b-ok", "neg"),),
        ),
        # Contradictory second reading: retry sensor B.
        FSCTransition("nb-ok", "b-disagree", "nb-start"),
        FSCTransition("nb-faulty", "b-agree", "nb-start"),
    ]

    return FSCPomdpSpec(
        name="sensor-spec-fsc",
        hidden_variables=[sensor_a, sensor_b],
        fsc_nodes=[
            "nroot",
            "na-ok",
            "na-faulty",
            "nb-start",
            "nb-ok",
            "nb-faulty",
            "ncommit",
        ],
        initial_node="nroot",
        commit_nodes=["ncommit"],
        observations=[
            "a-agree",
            "a-disagree",
            "b-agree",
            "b-disagree",
        ],
        transitions=transitions,
    )


# ======================================================================
#  Mine (1 hidden variable, cardinality 4)
# ======================================================================
#
# Compact spec version of the 2x2 mine domain. The hidden variable is the
# mine cell. First evidence chooses one possible mine cell; a second safe-cell
# observation supplies complementary negative belief.

def mine_spec() -> FSCPomdpSpec:
    cells = ("c00", "c01", "c10", "c11")
    mine_cell = HiddenVariable(name="mine-cell", domain=cells)

    transitions = []
    for cell in cells:
        transitions.append(
            FSCTransition(
                "nroot",
                f"mine-{cell}",
                f"nmaybe-{cell}",
                (BeliefUpdate("mine-cell", cell, "pos"),),
            )
        )

    for candidate in cells:
        for safe_cell in cells:
            if safe_cell == candidate:
                continue
            transitions.append(
                FSCTransition(
                    f"nmaybe-{candidate}",
                    f"safe-{safe_cell}",
                    "ncommit",
                    (BeliefUpdate("mine-cell", safe_cell, "neg"),),
                )
            )

    return FSCPomdpSpec(
        name="mine-spec-fsc",
        hidden_variables=[mine_cell],
        fsc_nodes=[
            "nroot",
            "nmaybe-c00",
            "nmaybe-c01",
            "nmaybe-c10",
            "nmaybe-c11",
            "ncommit",
        ],
        initial_node="nroot",
        commit_nodes=["ncommit"],
        observations=[
            *(f"mine-{cell}" for cell in cells),
            *(f"safe-{cell}" for cell in cells),
        ],
        transitions=transitions,
    )


# ======================================================================
#  Scaled Environment Specs
# ======================================================================

def mine_spec_scaled(width: int, height: int) -> FSCPomdpSpec:
    cells = tuple(f"c{x}{y}" for x in range(width) for y in range(height))
    mine_cell = HiddenVariable(name="mine-cell", domain=cells)

    transitions = []
    for cell in cells:
        transitions.append(
            FSCTransition(
                "nroot",
                f"mine-{cell}",
                f"nmaybe-{cell}",
                (BeliefUpdate("mine-cell", cell, "pos"),),
            )
        )

    for candidate in cells:
        for safe_cell in cells:
            if safe_cell == candidate:
                continue
            transitions.append(
                FSCTransition(
                    f"nmaybe-{candidate}",
                    f"safe-{safe_cell}",
                    "ncommit",
                    (BeliefUpdate("mine-cell", safe_cell, "neg"),),
                )
            )

    fsc_nodes = ["nroot"] + [f"nmaybe-{cell}" for cell in cells] + ["ncommit"]
    observations = [f"mine-{cell}" for cell in cells] + [f"safe-{cell}" for cell in cells]

    return FSCPomdpSpec(
        name=f"mine-{width}x{height}-spec-fsc",
        hidden_variables=[mine_cell],
        fsc_nodes=fsc_nodes,
        initial_node="nroot",
        commit_nodes=["ncommit"],
        observations=observations,
        transitions=transitions,
    )


def mine_spec_3x3() -> FSCPomdpSpec:
    return mine_spec_scaled(3, 3)


def sensor_spec_scaled(num_sensors: int) -> FSCPomdpSpec:
    assert num_sensors >= 1, "Must have at least 1 sensor"
    
    hidden_variables = []
    fsc_nodes = ["nroot"]
    observations = []
    transitions = []
    
    for i in range(1, num_sensors + 1):
        var_name = f"sensor-{i}"
        ok_val = f"{i}-ok"
        faulty_val = f"{i}-faulty"
        hidden_variables.append(HiddenVariable(name=var_name, domain=(ok_val, faulty_val)))
        
        observations.extend([f"{i}-agree", f"{i}-disagree"])
        
        fsc_nodes.extend([f"n{i}-ok", f"n{i}-faulty"])
        if i < num_sensors:
            fsc_nodes.append(f"n{i+1}-start")
            
    fsc_nodes.append("ncommit")
    
    for i in range(1, num_sensors + 1):
        var_name = f"sensor-{i}"
        ok_val = f"{i}-ok"
        faulty_val = f"{i}-faulty"
        
        start_node = "nroot" if i == 1 else f"n{i}-start"
        next_start_node = "ncommit" if i == num_sensors else f"n{i+1}-start"
        
        transitions.append(
            FSCTransition(
                start_node,
                f"{i}-agree",
                f"n{i}-ok",
                (BeliefUpdate(var_name, ok_val, "pos"),),
            )
        )
        transitions.append(
            FSCTransition(
                start_node,
                f"{i}-disagree",
                f"n{i}-faulty",
                (BeliefUpdate(var_name, faulty_val, "pos"),),
            )
        )
        
        transitions.append(
            FSCTransition(
                f"n{i}-ok",
                f"{i}-agree",
                next_start_node,
                (BeliefUpdate(var_name, faulty_val, "neg"),),
            )
        )
        transitions.append(
            FSCTransition(
                f"n{i}-faulty",
                f"{i}-disagree",
                next_start_node,
                (BeliefUpdate(var_name, ok_val, "neg"),),
            )
        )
        
        transitions.append(FSCTransition(f"n{i}-ok", f"{i}-disagree", start_node))
        transitions.append(FSCTransition(f"n{i}-faulty", f"{i}-agree", start_node))
        
    return FSCPomdpSpec(
        name=f"sensor-{num_sensors}-spec-fsc",
        hidden_variables=hidden_variables,
        fsc_nodes=fsc_nodes,
        initial_node="nroot",
        commit_nodes=["ncommit"],
        observations=observations,
        transitions=transitions,
    )


def sensor_spec_3() -> FSCPomdpSpec:
    return sensor_spec_scaled(3)

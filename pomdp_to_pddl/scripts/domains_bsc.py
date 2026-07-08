"""
BSC domain specifications for all validated POMDPs.

BSC = Belief-State Controller. Unlike FSC, there are NO abstract memory nodes.
The belief state (k / k-not predicates) is the sole state representation.
Landmarks produced by Fast Downward reflect MDP belief structure — what the
agent must come to know about the hidden state — not FSC controller topology.

Each function returns a BSCSpec ready to pass to encoder_bsc.compile_to_pddl().
"""

from bsc_spec import (
    BSCSpec,
    BSCTransition,
    BeliefRef,
    BeliefUpdate,
    CommitCondition,
    HiddenVariable,
)


# ======================================================================
#  Tiger BSC  (1 hidden variable, cardinality 2)
# ======================================================================
#
#  Tiger is hidden behind one of two doors (left / right).
#  Policy: listen until two CONSISTENT observations, then open the safe door.
#
#  Belief states
#    uncertain    : neither k(left) nor k(right) holds
#    leaning-left : k(left) holds; k-not(right) not yet confirmed
#    leaning-right: k(right) holds; k-not(left) not yet confirmed
#    certain-left : k(left) AND k-not(right)  → commit → open right door
#    certain-right: k(right) AND k-not(left)  → commit → open left door

def tiger_bsc() -> BSCSpec:
    direction = HiddenVariable(name="direction", domain=("left", "right"))
    return BSCSpec(
        name="tiger-bsc",
        hidden_variables=[direction],
        observations=["left", "right"],
        transitions=[
            # T0: uncertain + hear-left  → write k(left)
            BSCTransition(
                observation="left",
                belief_precs=(
                    BeliefRef("direction", "left",  "pos", holds=False),
                    BeliefRef("direction", "right", "pos", holds=False),
                ),
                belief_updates=(BeliefUpdate("direction", "left", "pos"),),
            ),
            # T1: uncertain + hear-right → write k(right)
            BSCTransition(
                observation="right",
                belief_precs=(
                    BeliefRef("direction", "left",  "pos", holds=False),
                    BeliefRef("direction", "right", "pos", holds=False),
                ),
                belief_updates=(BeliefUpdate("direction", "right", "pos"),),
            ),
            # T2: leaning-left + hear-left  → confirm: write k-not(right)
            BSCTransition(
                observation="left",
                belief_precs=(
                    BeliefRef("direction", "left",  "pos", holds=True),
                    BeliefRef("direction", "right", "neg", holds=False),
                ),
                belief_updates=(BeliefUpdate("direction", "right", "neg"),),
            ),
            # T3: leaning-left + hear-right → reset: retract k(left)
            BSCTransition(
                observation="right",
                belief_precs=(
                    BeliefRef("direction", "left",  "pos", holds=True),
                    BeliefRef("direction", "right", "neg", holds=False),
                ),
                retractions=(BeliefUpdate("direction", "left", "pos"),),
            ),
            # T4: leaning-right + hear-right → confirm: write k-not(left)
            BSCTransition(
                observation="right",
                belief_precs=(
                    BeliefRef("direction", "right", "pos", holds=True),
                    BeliefRef("direction", "left",  "neg", holds=False),
                ),
                belief_updates=(BeliefUpdate("direction", "left", "neg"),),
            ),
            # T5: leaning-right + hear-left → reset: retract k(right)
            BSCTransition(
                observation="left",
                belief_precs=(
                    BeliefRef("direction", "right", "pos", holds=True),
                    BeliefRef("direction", "left",  "neg", holds=False),
                ),
                retractions=(BeliefUpdate("direction", "right", "pos"),),
            ),
        ],
        commit_conditions=[
            # certain-left: open right door
            CommitCondition(
                variable="direction", commit_value="right",
                belief_precs=(
                    BeliefRef("direction", "left",  "pos", holds=True),
                    BeliefRef("direction", "right", "neg", holds=True),
                ),
            ),
            # certain-right: open left door
            CommitCondition(
                variable="direction", commit_value="left",
                belief_precs=(
                    BeliefRef("direction", "right", "pos", holds=True),
                    BeliefRef("direction", "left",  "neg", holds=True),
                ),
            ),
        ],
    )


# ======================================================================
#  Noisy Channel BSC  (1 hidden variable, cardinality 3)
# ======================================================================
#
#  One of three channels is live. Probing returns:
#    signal-c*  →  evidence that c* is the live channel (write k(c*))
#    noise-c*   →  evidence that c* is dead            (write k-not(c*))
#
#  Policy
#    uncertain  : first signal-c* writes k(c*)
#    leaning-c* : noise-other writes k-not(other); signal-other resets
#
#  Expected MDP landmarks (per hidden variable):
#    {k(c1), k(c2), k(c3)}         – must know which channel is live
#    {k-not(c1), k-not(c2), k-not(c3)} – must rule out at least one

def channel_bsc() -> BSCSpec:
    vals = ("c1", "c2", "c3")
    channel = HiddenVariable(name="channel", domain=vals)
    transitions = []

    # Uncertain → signal-v → k(v)
    for v in vals:
        transitions.append(BSCTransition(
            observation=f"signal-{v}",
            belief_precs=tuple(
                BeliefRef("channel", c, "pos", holds=False) for c in vals
            ),
            belief_updates=(BeliefUpdate("channel", v, "pos"),),
        ))

    # Leaning-v + noise-other → k-not(other)
    for v in vals:
        for other in vals:
            if other != v:
                transitions.append(BSCTransition(
                    observation=f"noise-{other}",
                    belief_precs=(BeliefRef("channel", v, "pos", holds=True),),
                    belief_updates=(BeliefUpdate("channel", other, "neg"),),
                ))

    # Leaning-v + signal-other → reset: retract k(v)
    for v in vals:
        for other in vals:
            if other != v:
                transitions.append(BSCTransition(
                    observation=f"signal-{other}",
                    belief_precs=(BeliefRef("channel", v, "pos", holds=True),),
                    retractions=(BeliefUpdate("channel", v, "pos"),),
                ))

    return BSCSpec(
        name="channel-bsc",
        hidden_variables=[channel],
        observations=[
            "signal-c1", "signal-c2", "signal-c3",
            "noise-c1",  "noise-c2",  "noise-c3",
        ],
        transitions=transitions,
        commit_conditions=[
            CommitCondition(
                variable="channel", commit_value=v,
                belief_precs=(BeliefRef("channel", v, "pos", holds=True),),
            )
            for v in vals
        ],
    )


# ======================================================================
#  Sensor BSC helpers
# ======================================================================

def _sensor_var_transitions(
    var_name: str,
    ok_val: str,
    faulty_val: str,
    obs_agree: str,
    obs_disagree: str,
) -> list:
    """Six BSC sense transitions for one 2-value sensor variable.

    Transitions are independent of other variables — no sequential ordering —
    so the resulting landmarks reflect the raw MDP belief about this sensor.

    Belief states for this variable:
      uncertain      : neither k(ok) nor k(faulty) holds
      leaning-ok     : k(ok) holds; k-not(faulty) not yet confirmed
      leaning-faulty : k(faulty) holds; k-not(ok) not yet confirmed
    """
    return [
        # uncertain + agree    → k(ok)
        BSCTransition(
            observation=obs_agree,
            belief_precs=(
                BeliefRef(var_name, ok_val,     "pos", holds=False),
                BeliefRef(var_name, faulty_val, "pos", holds=False),
            ),
            belief_updates=(BeliefUpdate(var_name, ok_val, "pos"),),
        ),
        # uncertain + disagree → k(faulty)
        BSCTransition(
            observation=obs_disagree,
            belief_precs=(
                BeliefRef(var_name, ok_val,     "pos", holds=False),
                BeliefRef(var_name, faulty_val, "pos", holds=False),
            ),
            belief_updates=(BeliefUpdate(var_name, faulty_val, "pos"),),
        ),
        # leaning-ok     + agree    → confirm: k-not(faulty)
        BSCTransition(
            observation=obs_agree,
            belief_precs=(
                BeliefRef(var_name, ok_val,     "pos", holds=True),
                BeliefRef(var_name, faulty_val, "neg", holds=False),
            ),
            belief_updates=(BeliefUpdate(var_name, faulty_val, "neg"),),
        ),
        # leaning-faulty + disagree → confirm: k-not(ok)
        BSCTransition(
            observation=obs_disagree,
            belief_precs=(
                BeliefRef(var_name, faulty_val, "pos", holds=True),
                BeliefRef(var_name, ok_val,     "neg", holds=False),
            ),
            belief_updates=(BeliefUpdate(var_name, ok_val, "neg"),),
        ),
        # leaning-ok     + disagree → reset: retract k(ok)
        BSCTransition(
            observation=obs_disagree,
            belief_precs=(
                BeliefRef(var_name, ok_val,     "pos", holds=True),
                BeliefRef(var_name, faulty_val, "neg", holds=False),
            ),
            retractions=(BeliefUpdate(var_name, ok_val, "pos"),),
        ),
        # leaning-faulty + agree    → reset: retract k(faulty)
        BSCTransition(
            observation=obs_agree,
            belief_precs=(
                BeliefRef(var_name, faulty_val, "pos", holds=True),
                BeliefRef(var_name, ok_val,     "neg", holds=False),
            ),
            retractions=(BeliefUpdate(var_name, faulty_val, "pos"),),
        ),
    ]


# ======================================================================
#  Sensor BSC  (2 sensors, letter-labelled: a, b)
# ======================================================================
#
#  Two independent sensors, each either ok or faulty.
#  Observations: a-agree/a-disagree for sensor-a; b-agree/b-disagree for sensor-b.
#
#  Unlike the FSC version (which sequences sensor-a before sensor-b via nodes),
#  the BSC treats both sensors independently. Each sensor's belief updates are
#  gated only on its own belief state — no cross-sensor ordering. This yields
#  pure MDP landmarks:
#    {k(sensor-a, a-ok), k(sensor-a, a-faulty)}   – must identify sensor-a
#    {k-not(sensor-a, ...)}                         – must rule out one value
#    {k(sensor-b, b-ok), k(sensor-b, b-faulty)}   – must identify sensor-b
#    {k-not(sensor-b, ...)}

def sensor_bsc() -> BSCSpec:
    sensor_a = HiddenVariable(name="sensor-a", domain=("a-ok", "a-faulty"))
    sensor_b = HiddenVariable(name="sensor-b", domain=("b-ok", "b-faulty"))
    return BSCSpec(
        name="sensor-bsc",
        hidden_variables=[sensor_a, sensor_b],
        observations=["a-agree", "a-disagree", "b-agree", "b-disagree"],
        transitions=(
            _sensor_var_transitions(
                "sensor-a", "a-ok", "a-faulty", "a-agree", "a-disagree"
            )
            + _sensor_var_transitions(
                "sensor-b", "b-ok", "b-faulty", "b-agree", "b-disagree"
            )
        ),
        commit_conditions=[
            CommitCondition("sensor-a", "a-ok",
                            (BeliefRef("sensor-a", "a-ok",     "pos", holds=True),)),
            CommitCondition("sensor-a", "a-faulty",
                            (BeliefRef("sensor-a", "a-faulty", "pos", holds=True),)),
            CommitCondition("sensor-b", "b-ok",
                            (BeliefRef("sensor-b", "b-ok",     "pos", holds=True),)),
            CommitCondition("sensor-b", "b-faulty",
                            (BeliefRef("sensor-b", "b-faulty", "pos", holds=True),)),
        ],
    )


# ======================================================================
#  Mine BSC  (NxM grid, 1 hidden variable, cardinality N*M)
# ======================================================================
#
#  One mine is hidden in exactly one cell of the grid.
#  Observations:
#    mine-c*  →  evidence the mine is AT c*   (write k(mine-cell, c*))
#    safe-c*  →  evidence the mine is NOT at c* (write k-not(mine-cell, c*))
#
#  Policy
#    uncertain    : mine-c* → k(mine-cell, c*)
#    leaning-c*   : safe-c# (# != *) → k-not(mine-cell, c#)
#    (no resets in this domain — matching the FSC spec)
#
#  Expected MDP landmarks:
#    {k(c00), k(c01), k(c10), k(c11)} – must identify the mine's location
#    {k-not(c00), ...}                 – must rule out at least one cell

def mine_bsc_scaled(width: int, height: int) -> BSCSpec:
    cells = tuple(f"c{x}{y}" for x in range(width) for y in range(height))
    mine_cell = HiddenVariable(name="mine-cell", domain=cells)
    transitions = []

    # uncertain + mine-c* → k(mine-cell, c*)
    for cell in cells:
        transitions.append(BSCTransition(
            observation=f"mine-{cell}",
            belief_precs=tuple(
                BeliefRef("mine-cell", c, "pos", holds=False) for c in cells
            ),
            belief_updates=(BeliefUpdate("mine-cell", cell, "pos"),),
        ))

    # leaning-candidate + safe-other → k-not(mine-cell, other)
    for candidate in cells:
        for safe_cell in cells:
            if safe_cell != candidate:
                transitions.append(BSCTransition(
                    observation=f"safe-{safe_cell}",
                    belief_precs=(
                        BeliefRef("mine-cell", candidate, "pos", holds=True),
                    ),
                    belief_updates=(BeliefUpdate("mine-cell", safe_cell, "neg"),),
                ))

    name = "mine-bsc" if (width == 2 and height == 2) else f"mine-{width}x{height}-bsc"
    return BSCSpec(
        name=name,
        hidden_variables=[mine_cell],
        observations=[
            *(f"mine-{c}" for c in cells),
            *(f"safe-{c}"  for c in cells),
        ],
        transitions=transitions,
        commit_conditions=[
            CommitCondition(
                "mine-cell", c,
                belief_precs=(BeliefRef("mine-cell", c, "pos", holds=True),),
            )
            for c in cells
        ],
    )


def mine_bsc() -> BSCSpec:
    return mine_bsc_scaled(2, 2)


def mine_bsc_3x3() -> BSCSpec:
    return mine_bsc_scaled(3, 3)


# ======================================================================
#  Sensor BSC scaled  (N sensors, number-labelled: 1..N)
# ======================================================================
#
#  N independent sensors, each ok or faulty.
#  Observations: "{i}-agree" / "{i}-disagree" for sensor i.
#  All sensors are processed independently (no sequential ordering in belief precs).

def sensor_bsc_scaled(num_sensors: int) -> BSCSpec:
    assert num_sensors >= 1, "Need at least one sensor."

    hidden_variables: list = []
    observations:     list = []
    transitions:      list = []
    commit_conditions: list = []

    for i in range(1, num_sensors + 1):
        var_name     = f"sensor-{i}"
        ok_val       = f"{i}-ok"
        faulty_val   = f"{i}-faulty"
        obs_agree    = f"{i}-agree"
        obs_disagree = f"{i}-disagree"

        hidden_variables.append(
            HiddenVariable(name=var_name, domain=(ok_val, faulty_val))
        )
        observations.extend([obs_agree, obs_disagree])
        transitions.extend(
            _sensor_var_transitions(
                var_name, ok_val, faulty_val, obs_agree, obs_disagree
            )
        )
        commit_conditions.extend([
            CommitCondition(var_name, ok_val,
                            (BeliefRef(var_name, ok_val,     "pos", holds=True),)),
            CommitCondition(var_name, faulty_val,
                            (BeliefRef(var_name, faulty_val, "pos", holds=True),)),
        ])

    return BSCSpec(
        name=f"sensor-{num_sensors}-bsc",
        hidden_variables=hidden_variables,
        observations=observations,
        transitions=transitions,
        commit_conditions=commit_conditions,
    )


def sensor_bsc_3() -> BSCSpec:
    return sensor_bsc_scaled(3)


# ======================================================================
#  RockSample BSC  (N rocks, each {good, bad})
# ======================================================================
#
#  RockSample(n,k): n×n grid, k rocks each with hidden quality {good, bad}.
#  The policy senses rocks (noisy observations) and commits to sampling or
#  skipping each rock before the episode ends.
#
#  BSC abstraction: each rock is an independent hidden variable with domain
#  {good, bad}. The spatial navigation is abstracted away; the BSC captures
#  only the belief-commitment structure — what the agent must know about each
#  rock's quality before committing.
#
#  This is isomorphic to sensor_bsc_scaled(k) with rock-specific naming:
#    uncertain-rock-i   : no evidence yet about rock i
#    k-rock-i(good)     : accumulated evidence that rock i is good
#    k-rock-i(bad)      : accumulated evidence that rock i is bad
#    k-not-rock-i(good) : ruled out rock i being good (→ commit bad)
#    k-not-rock-i(bad)  : ruled out rock i being bad  (→ commit good)
#
#  Expected BSC landmarks (per rock): 2 disjunctive + commitment chain.
#  RockSample(4,4): 4 rocks → same structure as sensor_bsc_scaled(4).

def rock_sample_bsc(num_rocks: int = 4) -> BSCSpec:
    assert num_rocks >= 1

    hidden_variables: list = []
    observations:     list = []
    transitions:      list = []
    commit_conditions: list = []

    for i in range(1, num_rocks + 1):
        var_name    = f"rock-{i}"
        good_val    = f"r{i}-good"
        bad_val     = f"r{i}-bad"
        obs_good    = f"sense-good-r{i}"
        obs_bad     = f"sense-bad-r{i}"

        hidden_variables.append(
            HiddenVariable(name=var_name, domain=(good_val, bad_val))
        )
        observations.extend([obs_good, obs_bad])
        transitions.extend(
            _sensor_var_transitions(
                var_name, good_val, bad_val, obs_good, obs_bad
            )
        )
        commit_conditions.extend([
            CommitCondition(var_name, good_val,
                            (BeliefRef(var_name, good_val, "pos", holds=True),)),
            CommitCondition(var_name, bad_val,
                            (BeliefRef(var_name, bad_val,  "pos", holds=True),)),
        ])

    return BSCSpec(
        name=f"rocksample-{num_rocks}-bsc",
        hidden_variables=hidden_variables,
        observations=observations,
        transitions=transitions,
        commit_conditions=commit_conditions,
    )


def rock_sample_bsc_4() -> BSCSpec:
    return rock_sample_bsc(4)

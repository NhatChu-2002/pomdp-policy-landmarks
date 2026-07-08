# Faulty Sensor POMDP — solved with SARSOP
#
# Two independent sensors (a, b), each either ok or faulty.
# The hidden state is the pair (sensor_a_status, sensor_b_status).
#
# Reading sensor-a returns:
#   a-agree    (0.9)  if sensor-a is ok,     else  a-agree    (0.1)
#   a-disagree (0.1)  if sensor-a is ok,     else  a-disagree (0.9)
# Reading sensor-b is symmetric, and independent of sensor-a's quality.
#
# The SARSOP policy learns: read each sensor twice consistently, then commit.
#
# States:       {a-ok-b-ok, a-ok-b-faulty, a-faulty-b-ok, a-faulty-b-faulty, done}
# Actions:      {read-a, read-b,
#                commit-a-ok-b-ok, commit-a-ok-b-faulty,
#                commit-a-faulty-b-ok, commit-a-faulty-b-faulty}
# Observations: {a-agree, a-disagree, b-agree, b-disagree, none}
#
# Reward:  read = -1,  correct-commit = +20,  wrong-commit = -20
#
# Trace format (BSC-compatible):
#   TRACE,<sim_id>,<t>,<action>,<obs>,<p_a-ok>,<p_a-faulty>,<p_b-ok>,<p_b-faulty>
#
# Usage:
#   julia sensor.jl [output_csv] [n_sims]
#
# import Pkg
# Pkg.add(["POMDPs", "QuickPOMDPs", "POMDPTools", "NativeSARSOP"])

using POMDPs
using QuickPOMDPs
using POMDPTools: Uniform, SparseCat, Deterministic, DiscreteUpdater, stepthrough
using NativeSARSOP
using Printf

# -----------------------------------------------------------------------
# Domain constants
# -----------------------------------------------------------------------

# Non-terminal states: (sensor_a_status, sensor_b_status)
const SA_VALS = ["a-ok", "a-faulty"]
const SB_VALS = ["b-ok", "b-faulty"]

# State encoded as "a-ok-b-ok" etc. (fields separated by known prefix)
const SENSOR_NT_STATES = ["$a-$b" for a in SA_VALS for b in SB_VALS]
const SENSOR_STATES    = vcat(SENSOR_NT_STATES, ["done"])

# Commit actions: one per (a_status, b_status) combination
const COMMIT_ACTIONS = ["commit-$a-$b" for a in SA_VALS for b in SB_VALS]
const SENSOR_ACTIONS = vcat(["read-a", "read-b"], COMMIT_ACTIONS)

const SENSOR_OBS = ["a-agree", "a-disagree", "b-agree", "b-disagree", "none"]

# Commitment map: action name → expected state string
const COMMIT_STATE = Dict(
    "commit-a-ok-b-ok"     => "a-ok-b-ok",
    "commit-a-ok-b-faulty"  => "a-ok-b-faulty",
    "commit-a-faulty-b-ok"  => "a-faulty-b-ok",
    "commit-a-faulty-b-faulty" => "a-faulty-b-faulty",
)

p_read_correct = 0.9   # P(correct observation when reading a functioning sensor)

# -----------------------------------------------------------------------
# Helper: extract sensor-a quality from state string
# -----------------------------------------------------------------------

function sensor_a_quality(s)
    # state = "a-ok-b-ok" or "a-faulty-b-ok" etc.
    return startswith(s, "a-ok") ? "a-ok" : "a-faulty"
end

function sensor_b_quality(s)
    # state = "a-??-b-ok" or "a-??-b-faulty"
    return endswith(s, "b-ok") ? "b-ok" : "b-faulty"
end

# -----------------------------------------------------------------------
# POMDP definition
# -----------------------------------------------------------------------

sensor_pomdp = QuickPOMDP(
    states       = SENSOR_STATES,
    actions      = SENSOR_ACTIONS,
    observations = SENSOR_OBS,
    initialstate = Uniform(SENSOR_NT_STATES),
    discount     = 0.95,
    isterminal   = s -> s == "done",

    transition = function (s, a)
        if s == "done" || startswith(a, "commit")
            return Deterministic("done")
        else
            return Deterministic(s)   # sensor qualities are fixed
        end
    end,

    observation = function (s, a, sp)
        if sp == "done" || startswith(a, "commit")
            return Deterministic("none")
        end
        if a == "read-a"
            qa = sensor_a_quality(sp)
            if qa == "a-ok"
                return SparseCat(["a-agree", "a-disagree"],
                                 [p_read_correct, 1.0 - p_read_correct])
            else
                return SparseCat(["a-agree", "a-disagree"],
                                 [1.0 - p_read_correct, p_read_correct])
            end
        else  # read-b
            qb = sensor_b_quality(sp)
            if qb == "b-ok"
                return SparseCat(["b-agree", "b-disagree"],
                                 [p_read_correct, 1.0 - p_read_correct])
            else
                return SparseCat(["b-agree", "b-disagree"],
                                 [1.0 - p_read_correct, p_read_correct])
            end
        end
    end,

    reward = function (s, a)
        if s == "done"
            return 0.0
        elseif startswith(a, "read")
            return -1.0
        else
            # commit action
            expected = COMMIT_STATE[a]
            return s == expected ? 20.0 : -20.0
        end
    end,
)

# -----------------------------------------------------------------------
# Solve with SARSOP
# -----------------------------------------------------------------------

solver = SARSOPSolver(precision=1e-3, max_time=60.0)
policy = solve(solver, sensor_pomdp)
up     = DiscreteUpdater(sensor_pomdp)

# -----------------------------------------------------------------------
# Helper: marginal beliefs over sensor-a and sensor-b
# -----------------------------------------------------------------------

function sensor_marginals(b)
    p_a_ok      = pdf(b, "a-ok-b-ok")     + pdf(b, "a-ok-b-faulty")
    p_a_faulty  = pdf(b, "a-faulty-b-ok") + pdf(b, "a-faulty-b-faulty")
    p_b_ok      = pdf(b, "a-ok-b-ok")     + pdf(b, "a-faulty-b-ok")
    p_b_faulty  = pdf(b, "a-ok-b-faulty") + pdf(b, "a-faulty-b-faulty")
    return p_a_ok, p_a_faulty, p_b_ok, p_b_faulty
end

# -----------------------------------------------------------------------
# Simulate n_sims episodes
# -----------------------------------------------------------------------

default_trace_path = joinpath(@__DIR__, "sensor_trace.csv")
trace_path = length(ARGS) >= 1 ? ARGS[1] : default_trace_path
n_sims     = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 5

open(trace_path, "w") do io
    println(io, "TRACE,sim,t,action,obs,p_a-ok,p_a-faulty,p_b-ok,p_b-faulty")

    for sim in 0 : n_sims - 1
        t = 0
        for (b, s, a, o, r) in stepthrough(sensor_pomdp, policy, up,
                                            "b,s,a,o,r"; max_steps=80)
            if s == "done"
                break
            end
            pa_ok, pa_f, pb_ok, pb_f = sensor_marginals(b)
            @printf(io, "TRACE,%d,%d,%s,%s,%.6f,%.6f,%.6f,%.6f\n",
                    sim, t, a, o, pa_ok, pa_f, pb_ok, pb_f)
            t += 1
            if startswith(a, "commit")
                break
            end
        end
    end
end

println("Wrote $n_sims simulation(s) to: $trace_path")

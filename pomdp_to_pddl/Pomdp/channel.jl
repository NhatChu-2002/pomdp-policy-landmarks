# Noisy Channel POMDP — solved with SARSOP
#
# One of three channels is live.  Probing channel cX returns:
#   signal-cX  with prob 0.85 if cX is live,  else 0.15
#   noise-cX   with prob 0.85 if cX is dead,  else 0.15
#
# The SARSOP policy learns: probe until confident, then commit to the live channel.
#
# States:       {c1, c2, c3, done}
# Actions:      {probe-c1, probe-c2, probe-c3, commit-c1, commit-c2, commit-c3}
# Observations: {signal-c1, signal-c2, signal-c3, noise-c1, noise-c2, noise-c3, none}
#
# Reward:  probe = -1,  correct-commit = +20,  wrong-commit = -20
#
# Trace format (BSC-compatible):
#   TRACE,<sim_id>,<t>,<action>,<obs>,<p_c1>,<p_c2>,<p_c3>
#
# Usage:
#   julia channel.jl [output_csv] [n_sims]
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

const CHANNELS = ["c1", "c2", "c3"]
const CH_STATES  = vcat(CHANNELS, ["done"])
const CH_ACTIONS = vcat(
    ["probe-$c" for c in CHANNELS],
    ["commit-$c" for c in CHANNELS],
)
const CH_OBS = vcat(
    ["signal-$c" for c in CHANNELS],
    ["noise-$c"  for c in CHANNELS],
    ["none"],
)

p_correct = 0.85   # P(correct signal when probing the live channel)

# -----------------------------------------------------------------------
# POMDP definition
# -----------------------------------------------------------------------

channel_pomdp = QuickPOMDP(
    states       = CH_STATES,
    actions      = CH_ACTIONS,
    observations = CH_OBS,
    initialstate = Uniform(CHANNELS),
    discount     = 0.95,
    isterminal   = s -> s == "done",

    transition = function (s, a)
        if s == "done" || startswith(a, "commit")
            return Deterministic("done")
        else
            return Deterministic(s)   # state (live channel) doesn't change
        end
    end,

    observation = function (s, a, sp)
        if sp == "done" || startswith(a, "commit")
            return Deterministic("none")
        end
        # a = "probe-cX"
        probed = a[7:end]   # "c1", "c2", or "c3"
        if s == probed
            return SparseCat(["signal-$probed", "noise-$probed"],
                             [p_correct, 1.0 - p_correct])
        else
            return SparseCat(["signal-$probed", "noise-$probed"],
                             [1.0 - p_correct, p_correct])
        end
    end,

    reward = function (s, a)
        if s == "done"
            return 0.0
        elseif startswith(a, "probe")
            return -1.0
        else
            # a = "commit-cX"
            committed = a[8:end]   # "c1", "c2", or "c3"
            return s == committed ? 20.0 : -20.0
        end
    end,
)

# -----------------------------------------------------------------------
# Solve with SARSOP
# -----------------------------------------------------------------------

solver = SARSOPSolver(precision=1e-3, max_time=60.0)
policy = solve(solver, channel_pomdp)
up     = DiscreteUpdater(channel_pomdp)

# -----------------------------------------------------------------------
# Simulate n_sims episodes; each ends when agent commits
# -----------------------------------------------------------------------

default_trace_path = joinpath(@__DIR__, "channel_trace.csv")
trace_path = length(ARGS) >= 1 ? ARGS[1] : default_trace_path
n_sims     = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 5

open(trace_path, "w") do io
    println(io, "TRACE,sim,t,action,obs,p_c1,p_c2,p_c3")

    for sim in 0 : n_sims - 1
        t = 0
        for (b, s, a, o, r) in stepthrough(channel_pomdp, policy, up,
                                            "b,s,a,o,r"; max_steps=60)
            if s == "done"
                break
            end
            p = [pdf(b, c) for c in CHANNELS]
            @printf(io, "TRACE,%d,%d,%s,%s,%.6f,%.6f,%.6f\n",
                    sim, t, a, o, p[1], p[2], p[3])
            t += 1
            if startswith(a, "commit")
                break
            end
        end
    end
end

println("Wrote $n_sims simulation(s) to: $trace_path")

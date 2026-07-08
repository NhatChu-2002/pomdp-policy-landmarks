# Tiger POMDP — solved with SARSOP (replaces QMDP)
#
# Standard formulation (infinite-horizon, discount 0.95):
#   States:       {left, right}        — where the tiger is
#   Actions:      {listen, left, right} — listen or open a door
#   Observations: {left, right}        — which side the tiger is heard from
#
# Policy (SARSOP): listen until confident, then open the safe door.
#
# Trace format (BACKWARD-COMPATIBLE with trace_adapters.py):
#   TRACE,<episode_id>,<action>,<obs>,<p_left>,<p_right>
#
# Usage:
#   julia tiger.jl [output_csv] [n_episodes]
#
# import Pkg
# Pkg.add(["POMDPs", "QuickPOMDPs", "POMDPTools", "NativeSARSOP"])

using POMDPs
using QuickPOMDPs
using POMDPTools: Uniform, SparseCat, Deterministic, DiscreteUpdater, stepthrough
using NativeSARSOP
using Printf

# -----------------------------------------------------------------------
# POMDP definition
# -----------------------------------------------------------------------

p_correct = 0.85   # P(hear tiger correctly when listening)

m = QuickPOMDP(
    states       = ["left", "right"],
    actions      = ["listen", "left", "right"],
    observations = ["left", "right"],
    initialstate = Uniform(["left", "right"]),
    discount     = 0.95,
    isterminal   = s -> false,     # infinite-horizon; episodes end on open

    transition = function (s, a)
        if a == "listen"
            return Deterministic(s)          # tiger stays put
        else
            return Uniform(["left", "right"]) # reset after opening
        end
    end,

    observation = function (s, a, sp)
        if a == "listen"
            if sp == "left"
                return SparseCat(["left", "right"], [p_correct, 1.0 - p_correct])
            else
                return SparseCat(["right", "left"], [p_correct, 1.0 - p_correct])
            end
        else
            return Uniform(["left", "right"])  # uninformative after opening
        end
    end,

    reward = function (s, a)
        if a == "listen"
            return -1.0
        elseif a == s           # opened the tiger's door
            return -100.0
        else                    # opened the safe door
            return 10.0
        end
    end,
)

# -----------------------------------------------------------------------
# Solve with SARSOP
# -----------------------------------------------------------------------

solver = SARSOPSolver(precision=1e-3, max_time=60.0)
policy = solve(solver, m)
up     = DiscreteUpdater(m)

# -----------------------------------------------------------------------
# Simulate n_episodes; each episode ends when agent opens a door
# -----------------------------------------------------------------------

default_trace_path = joinpath(@__DIR__, "tiger_policy.csv")
trace_path = length(ARGS) >= 1 ? ARGS[1] : default_trace_path
n_episodes = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 10

open(trace_path, "w") do io
    for ep in 0 : n_episodes - 1
        for (b, s, a, o, r) in stepthrough(m, policy, up, "b,s,a,o,r"; max_steps=50)
            p_left  = pdf(b, "left")
            p_right = pdf(b, "right")
            println(io, "TRACE,$ep,$a,$o,$p_left,$p_right")
            if a != "listen"
                break   # episode ends
            end
        end
    end
end

println("Wrote $(n_episodes) episode(s) to: $trace_path")

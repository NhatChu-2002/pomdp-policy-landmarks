# Mine POMDP (2×2 grid) — solved with SARSOP
#
# One mine is hidden in exactly one cell of a 2×2 grid.
# Probing cell cXY returns:
#   mine-cXY  with prob 0.85 if the mine IS at cXY, else 0.15 (false positive)
#   safe-cXY  with prob 0.85 if the mine is NOT at cXY, else 0.15 (false negative)
#
# The SARSOP policy learns: probe cells until confident, then commit to the mine's location.
#
# States:       {c00, c01, c10, c11, done}
# Actions:      {probe-c00, probe-c01, probe-c10, probe-c11,
#                commit-c00, commit-c01, commit-c10, commit-c11}
# Observations: {mine-c00, mine-c01, mine-c10, mine-c11,
#                safe-c00, safe-c01, safe-c10, safe-c11, none}
#
# Reward:  probe = -1,  correct-commit = +20,  wrong-commit = -20
#
# Trace format (BSC-compatible):
#   TRACE,<sim_id>,<t>,<action>,<obs>,<p_c00>,<p_c01>,<p_c10>,<p_c11>
#
# Usage:
#   julia mine.jl [output_csv] [n_sims]
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

const CELLS = ["c00", "c01", "c10", "c11"]   # 2×2 grid cells
const MINE_STATES  = vcat(CELLS, ["done"])
const MINE_ACTIONS = vcat(
    ["probe-$c"  for c in CELLS],
    ["commit-$c" for c in CELLS],
)
const MINE_OBS = vcat(
    ["mine-$c" for c in CELLS],
    ["safe-$c" for c in CELLS],
    ["none"],
)

p_detect = 0.85   # P(correct mine/safe detection when probing)

# -----------------------------------------------------------------------
# POMDP definition
# -----------------------------------------------------------------------

mine_pomdp = QuickPOMDP(
    states       = MINE_STATES,
    actions      = MINE_ACTIONS,
    observations = MINE_OBS,
    initialstate = Uniform(CELLS),
    discount     = 0.95,
    isterminal   = s -> s == "done",

    transition = function (s, a)
        if s == "done" || startswith(a, "commit")
            return Deterministic("done")
        else
            return Deterministic(s)   # mine location is fixed
        end
    end,

    observation = function (s, a, sp)
        if sp == "done" || startswith(a, "commit")
            return Deterministic("none")
        end
        # a = "probe-cXY"
        probed = a[7:end]   # "c00", "c01", "c10", or "c11"
        if s == probed
            # Mine IS at the probed cell
            return SparseCat(["mine-$probed", "safe-$probed"],
                             [p_detect, 1.0 - p_detect])
        else
            # Mine NOT at the probed cell
            return SparseCat(["mine-$probed", "safe-$probed"],
                             [1.0 - p_detect, p_detect])
        end
    end,

    reward = function (s, a)
        if s == "done"
            return 0.0
        elseif startswith(a, "probe")
            return -1.0
        else
            # a = "commit-cXY"
            committed = a[8:end]   # "c00", "c01", "c10", or "c11"
            return s == committed ? 20.0 : -20.0
        end
    end,
)

# -----------------------------------------------------------------------
# Solve with SARSOP
# -----------------------------------------------------------------------

solver = SARSOPSolver(precision=1e-3, max_time=60.0)
policy = solve(solver, mine_pomdp)
up     = DiscreteUpdater(mine_pomdp)

# -----------------------------------------------------------------------
# Simulate n_sims episodes
# -----------------------------------------------------------------------

default_trace_path = joinpath(@__DIR__, "mine_trace.csv")
trace_path = length(ARGS) >= 1 ? ARGS[1] : default_trace_path
n_sims     = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 5

open(trace_path, "w") do io
    println(io, "TRACE,sim,t,action,obs,p_c00,p_c01,p_c10,p_c11")

    for sim in 0 : n_sims - 1
        t = 0
        for (b, s, a, o, r) in stepthrough(mine_pomdp, policy, up,
                                            "b,s,a,o,r"; max_steps=60)
            if s == "done"
                break
            end
            p = [pdf(b, c) for c in CELLS]
            @printf(io, "TRACE,%d,%d,%s,%s,%.6f,%.6f,%.6f,%.6f\n",
                    sim, t, a, o, p[1], p[2], p[3], p[4])
            t += 1
            if startswith(a, "commit")
                break
            end
        end
    end
end

println("Wrote $n_sims simulation(s) to: $trace_path")

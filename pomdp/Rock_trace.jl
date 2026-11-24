# Rock Sample — run policy and print full trace
# Logs both belief AND true rock state (s.rocks) to avoid the belief-reset bug.
#
# Action encoding (RockSample.jl):
#   1 = North, 2 = East, 3 = South, 4 = West
#   5 = Sample
#   5+k = Sense rock k  (k = 1..N, 1-indexed)
#
# Observation encoding:
#   1 = GOOD  (rock sensed as good)
#   2 = BAD   (rock sensed as bad)
#   3 = none  (move or sample — no observation)

# import Pkg
# Pkg.add(["POMDPs", "POMDPTools", "RockSample", "NativeSARSOP", "POMDPGifs", "Cairo", "Printf"])

using POMDPs
using POMDPTools
using RockSample
using NativeSARSOP
using POMDPGifs
using Cairo
using Printf

# -----------------------------------------------------------------------
# Problem definition  (same as your original Rock_demo.jl)
# -----------------------------------------------------------------------
pomdp = RockSamplePOMDP(
    rocks_positions=[(2, 3), (4, 3), (4, 2), (3, 1)],
    sensor_efficiency=20.0,
    discount_factor=0.95,
    good_rock_reward=20.0
)

solver = SARSOPSolver(precision=1e-3)
policy = solve(solver, pomdp)
up     = DiscreteUpdater(pomdp)

# -----------------------------------------------------------------------
# Helper: compute marginal P(rock_i is good) from belief
# -----------------------------------------------------------------------
function rock_marginals(pomdp, b)
    n = length(pomdp.rocks_positions)
    p_good = zeros(Float64, n)
    for (s, p) in weighted_iterator(b)
        for i in 1:n
            if s.rocks[i]
                p_good[i] += p
            end
        end
    end
    return p_good
end

# -----------------------------------------------------------------------
# Helper: human-readable action name
# -----------------------------------------------------------------------
function action_name(a, n_rocks)
    names = ["North", "East", "South", "West", "Sample"]
    if a <= 5
        return names[a]
    else
        return "Sense_r$(a - 5)"
    end
end

# -----------------------------------------------------------------------
# Helper: human-readable observation name
# -----------------------------------------------------------------------
function obs_name(o)
    if o == 1 return "GOOD"
    elseif o == 2 return "BAD"
    else return "none"
    end
end

# -----------------------------------------------------------------------
# Save GIF (same as original)
# -----------------------------------------------------------------------
gif_path = "./rock_trace.gif"
sim = GifSimulator(filename=gif_path, max_steps=30)
simulate(sim, pomdp, policy)
println("Saved GIF to: $gif_path")

# -----------------------------------------------------------------------
# Run simulation and collect full trace
# -----------------------------------------------------------------------
n_rocks = length(pomdp.rocks_positions)

println()
println("=" ^ 90)
println("ROCK SAMPLE TRACE")
println("=" ^ 90)
@printf("%-5s  %-8s  %-14s  %-6s  %-8s  %-30s  %-s\n",
        "Step", "Pos(x,y)", "Action", "Obs", "Reward",
        "Belief(good)", "True_rocks(good=1)")
println("-" ^ 90)

csv_path = "./rock_trace.csv"
open(csv_path, "w") do io

    # CSV header
    print(io, "TRACE,t,x,y,action,obs,reward")
    for i in 1:n_rocks
        print(io, ",belief_r$i")
    end
    for i in 1:n_rocks
        print(io, ",true_r$i")
    end
    println(io)

    t = 0
    for (b, s, a, o, r) in stepthrough(pomdp, policy, up, "b,s,a,o,r"; max_steps=30)

        x   = s.pos[1]
        y   = s.pos[2]

        # Belief: P(rock_i is good) — from the belief BEFORE this action
        pgood = rock_marginals(pomdp, b)

        # True rock quality from the ACTUAL state — immune to belief reset
        true_rocks = [s.rocks[i] ? 1 : 0 for i in 1:n_rocks]

        # --- Console print ---
        pos_str    = "($x,$y)"
        aname      = action_name(a, n_rocks)
        oname      = obs_name(o)
        belief_str = join([@sprintf("r%d:%.3f", i, pgood[i]) for i in 1:n_rocks], " ")
        true_str   = join(["r$i:$(true_rocks[i])" for i in 1:n_rocks], " ")

        @printf("%-5d  %-8s  %-14s  %-6s  %-8.2f  %-30s  %s\n",
                t, pos_str, aname, oname, r, belief_str, true_str)

        # --- CSV row ---
        print(io, "TRACE,$t,$x,$y,$a,$o,$r")
        for i in 1:n_rocks
            @printf(io, ",%.10f", pgood[i])
        end
        for i in 1:n_rocks
            print(io, ",$(true_rocks[i])")
        end
        println(io)

        t += 1
        if isterminal(pomdp, s)
            break
        end
    end
end

println("=" ^ 90)
println()
println("Saved trace CSV to: $csv_path")
println()

# -----------------------------------------------------------------------
# Summary: which rocks were actually good?
# -----------------------------------------------------------------------
println("ROCK POSITIONS:")
for (i, pos) in enumerate(pomdp.rocks_positions)
    println("  r$i at $pos")
end
println()
println("NOTE: Read 'true_r*' columns from the CSV for reliable good/bad classification.")
println("      The 'belief_r*' columns may reset to 0 after sampling or standing on a rock")
println("      without sampling (implicit Bayesian evidence in the DiscreteUpdater).")
println("      'true_r*=1' means the rock IS good in the actual sampled world state.")

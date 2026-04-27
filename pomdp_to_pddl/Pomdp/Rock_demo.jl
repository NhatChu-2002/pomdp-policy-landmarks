# import Pkg;
# Pkg.add(["POMDPGifs", "Cairo"]);
using POMDPs
using POMDPTools
using RockSample
using NativeSARSOP
using POMDPGifs
using Cairo
using Printf

pomdp = RockSamplePOMDP(
    rocks_positions=[(2, 3), (4, 3), (4, 2), (3, 1)],
    sensor_efficiency=20.0,
    discount_factor=0.95,
    good_rock_reward=20.0
)

solver = SARSOPSolver(precision=1e-3)
policy = solve(solver, pomdp)
up = DiscreteUpdater(pomdp)

function rock_marginals(pomdp, b)
    n = length(pomdp.rocks_positions)
    p_good = zeros(Float64, n)

    for (s, p) in weighted_iterator(b)
        rocks = getproperty(s, :rocks)
        for i in 1:n
            if rocks[i]
                p_good[i] += p
            end
        end
    end
    return p_good
end

function agent_xy(s)
    pos = getproperty(s, :pos)
    return pos[1], pos[2]
end

gif_path = "./Pomdp/test.gif"
sim = GifSimulator(filename=gif_path, max_steps=30)
simulate(sim, pomdp, policy)

println("Saved GIF to: $gif_path")

csv_path = "./Pomdp/rock_policy.csv"
open(csv_path, "w") do io
    n = length(pomdp.rocks_positions)

    # # optional header
    # print(io, "TRACE,t,x,y,a,o")
    # for i in 1:n
    #     print(io, ",p_good_$i")
    # end
    println(io)

    t = 0
    for (b, s, a, o, r) in stepthrough(pomdp, policy, up, "b,s,a,o,r"; max_steps=30)
        x, y = agent_xy(s)
        pgood = rock_marginals(pomdp, b)

        print(io, "TRACE,$t,$x,$y,$a,$o")
        for i in 1:length(pgood)
            @printf(io, ",%.10f", pgood[i])
        end
        println(io)

        t += 1
        if isterminal(pomdp, s)
            break
        end
    end
end

println("Saved CSV to: $csv_path")
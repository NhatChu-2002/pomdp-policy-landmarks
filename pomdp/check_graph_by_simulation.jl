# Solve a model once, write its policy graph, and simulate the SAME policy with exact
# belief updates, so graph-based and simulated numbers refer to one policy.
#
#   SARSOP_TIME=600 julia --project=. check_graph_by_simulation.jl <out.json> <problem args...>
#   e.g.  ... check_graph_by_simulation.jl tag.json tag
#
# Prints the simulated mean discounted return, the fraction of runs that end within
# 100 and 1,000 steps, and the graph's lossy-merge count.
include("extract_policy_graph.jl")
using Statistics

function check(out, args; episodes = 2000, max_steps = 1000)
    (m, ends, desc, meta), _, _ = build(args)
    policy, solve_s = solve_policy(m)
    g = policy_graph(m, policy, ends)
    write_graph(out, m, desc, meta, "", solve_s, policy, g)
    up = DiscreteUpdater(m)
    rng = MersenneTwister(7)
    rets, lens = Float64[], Int[]
    for _ in 1:episodes
        hist = simulate(HistoryRecorder(max_steps = max_steps, rng = rng), m, policy, up)
        push!(rets, discounted_reward(hist)); push!(lens, length(hist))
    end
    println("SIM episodes=", episodes, " mean_return=", round(mean(rets), digits = 3),
            " se=", round(std(rets) / sqrt(episodes), digits = 3),
            " end_within_100=", round(mean(lens .<= 100), digits = 4),
            " end_within_", max_steps, "=", round(mean(lens .< max_steps), digits = 4),
            " lossy_merges=", g.lossy, " value_bound=", value(policy, g.beliefs[1]))
end

check(ARGS[1], ARGS[2:end])

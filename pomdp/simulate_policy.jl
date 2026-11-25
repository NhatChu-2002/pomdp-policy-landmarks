# Simulate a SARSOP policy directly (exact belief updates, no policy graph, no merging).
#
#   julia simulate_policy.jl probe mine 9 0.85 [episodes] [max_steps]
#
# Prints the mean discounted return with its standard error, the fraction of
# episodes that end within 100 and within max_steps steps, and how often the
# policy is still probing a value it believes with probability > 0.9999.
include("extract_policy_graph.jl")
using Statistics

function simulate_probe(name, k, p; episodes = 2000, max_steps = 1000, seed = 1)
    m, ends, _, _ = probe(name, k, p)
    t0 = time()
    policy = solve(SARSOPSolver(precision = 1e-3, max_time = parse(Float64, get(ENV, "SARSOP_TIME", "120"))), m)
    println("solve=", round(time() - t0, digits = 1), "s  bound(b0)=", value(policy, initialstate(m) |> b -> initialize_belief(DiscreteUpdater(m), b)))
    up = DiscreteUpdater(m)
    rng = MersenneTwister(seed)
    rets, lens, stuck = Float64[], Int[], 0
    for _ in 1:episodes
        hist = simulate(HistoryRecorder(max_steps = max_steps, rng = rng), m, policy, up)
        push!(rets, discounted_reward(hist)); push!(lens, length(hist))
        b = hist[end].bp
        stuck += maximum(b.b) > 0.9999 && !ends(hist[end].a)
    end
    println("episodes=", episodes, " mean_return=", round(mean(rets), digits = 3),
            " se=", round(std(rets) / sqrt(episodes), digits = 3),
            " end_within_100=", round(mean(lens .<= 100), digits = 4),
            " end_within_", max_steps, "=", round(mean(lens .< max_steps), digits = 4),
            " stuck_probing_certain=", stuck)
end

simulate_probe(ARGS[2], parse(Int, ARGS[3]), parse(Float64, ARGS[4]);
               episodes = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 2000,
               max_steps = length(ARGS) >= 6 ? parse(Int, ARGS[6]) : 1000)

# Simulate a policy directly (exact belief updates, no policy graph, no merging).
#
#   julia simulate_policy.jl probe mine 9 0.85 [episodes] [max_steps]
#   SOLVER=qmdp julia simulate_policy.jl probe channel 3 0.85
#
# Prints the mean discounted return with its standard error, the fraction of
# episodes that end within 100 and within max_steps steps, how often the policy
# is still probing a value it believes with probability > 0.9999, and how often
# it commits to each value (the committed action when an episode ends).
include("extract_policy_graph.jl")
using Statistics

function simulate_probe(name, k, p; episodes = 2000, max_steps = 1000, seed = 1)
    m, ends, _, _ = probe(name, k, p)
    policy, solve_s = solve_policy(m)
    b0 = initialize_belief(DiscreteUpdater(m), initialstate(m))
    println("solver=", solver_name(), " solve=", round(solve_s, digits = 1), "s  value(b0)=", value(policy, b0))
    up = DiscreteUpdater(m)
    rng = MersenneTwister(seed)
    rets, lens, stuck = Float64[], Int[], 0
    commits = Dict{String,Int}()
    for _ in 1:episodes
        hist = simulate(HistoryRecorder(max_steps = max_steps, rng = rng), m, policy, up)
        push!(rets, discounted_reward(hist)); push!(lens, length(hist))
        last = hist[end]
        if ends(last.a)
            commits[last.a] = get(commits, last.a, 0) + 1
        else
            stuck += maximum(last.bp.b) > 0.9999
        end
    end
    println("episodes=", episodes, " mean_return=", round(mean(rets), digits = 3),
            " se=", round(std(rets) / sqrt(episodes), digits = 3),
            " end_within_100=", round(mean(lens .<= 100), digits = 4),
            " end_within_", max_steps, "=", round(mean(lens .< max_steps), digits = 4),
            " stuck_probing_certain=", stuck,
            " commits=", join(["$a:$n" for (a, n) in sort(collect(commits))], ","))
end

simulate_probe(ARGS[2], parse(Int, ARGS[3]), parse(Float64, ARGS[4]);
               episodes = length(ARGS) >= 5 ? parse(Int, ARGS[5]) : 2000,
               max_steps = length(ARGS) >= 6 ? parse(Int, ARGS[6]) : 1000)

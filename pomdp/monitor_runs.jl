# Run a RockSample SARSOP policy in a world whose sensor differs from the model the
# policy was solved for, and record what the agent believes at every step.
#
#   TRUE_EFFICIENCY=5 julia --project=. monitor_runs.jl <n> <k> <seed> <episodes> <out.jsonl>
#
# The policy and its belief updates use the nominal model (sensor efficiency 20, as in
# extract_policy_graph.jl); observations come from the true model (TRUE_EFFICIENCY,
# default 20 = no mismatch). Each output line is one episode: the agent's belief before
# every step ("i:p" pairs over the nominal state order, as in the policy-graph JSON),
# the action, the discounted return under the nominal discount, and whether it ended.
include("extract_policy_graph.jl")

function monitor(n, k, seed, episodes, out; max_steps = 200)
    m, _, _, _ = rocksample(n, k, seed)                      # nominal model (policy)
    policy, solve_s = solve_policy(m)
    ENV["RS_EFFICIENCY"] = get(ENV, "TRUE_EFFICIENCY", "20.0")
    mt, _, _, _ = rocksample(n, k, seed)                     # true model (environment)
    delete!(ENV, "RS_EFFICIENCY")
    up = DiscreteUpdater(m)
    rng = MersenneTwister(seed + 1000)
    γ = discount(m)
    open(out, "w") do io
        for _ in 1:episodes
            s = rand(rng, initialstate(mt))
            b = initialize_belief(up, initialstate(m))
            steps, ret, ended = String[], 0.0, false
            for t in 0:max_steps - 1
                a = action(policy, b)
                nz = join([string(i - 1, ":", round(b.b[i], digits = 9)) for i in eachindex(b.b) if b.b[i] > 0], " ")
                push!(steps, "{\"a\":" * q(a) * ",\"b\":" * q(nz) * "}")
                sp, o, r = @gen(:sp, :o, :r)(mt, s, a, rng)
                ret += γ^t * r
                if isterminal(mt, sp)
                    ended = true
                    break
                end
                b = update(up, b, a, o)
                s = sp
            end
            println(io, "{\"return\":", ret, ",\"ended\":", ended, ",\"steps\":[", join(steps, ","), "]}")
        end
    end
    println("solve=", round(solve_s, digits = 1), "s value(b0)=", value(policy, initialize_belief(up, initialstate(m))))
end

monitor(parse(Int, ARGS[1]), parse(Int, ARGS[2]), parse(Int, ARGS[3]), parse(Int, ARGS[4]), ARGS[5])

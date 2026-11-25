# Extract the reachable policy graph of a SARSOP policy.
#
#   julia extract_policy_graph.jl tiger <p_correct> <out.json>
#   julia extract_policy_graph.jl rocksample <n> <k> <seed> <out.json>
#
# Starting from the initial belief, follow the policy: at each belief take the
# policy's action and branch on every observation with nonzero probability.
# Beliefs are merged when equal up to 1e-9. The output lists every reachable
# belief node (belief vector, action) and every edge (observation, probability),
# so the graph contains exactly the policy's executions with positive probability.

using POMDPs
using POMDPTools
using NativeSARSOP
using Random
using RockSample
using QuickPOMDPs

const MAX_NODES = 200_000

function tiger(p_correct)
    m = QuickPOMDP(
        states = ["left", "right"], actions = ["listen", "left", "right"],
        observations = ["left", "right"], initialstate = Uniform(["left", "right"]),
        discount = 0.95, isterminal = s -> false,
        transition = (s, a) -> a == "listen" ? Deterministic(s) : Uniform(["left", "right"]),
        observation = function (a, sp)
            a != "listen" && return Uniform(["left", "right"])
            other = sp == "left" ? "right" : "left"
            SparseCat([sp, other], [p_correct, 1.0 - p_correct])
        end,
        reward = (s, a) -> a == "listen" ? -1.0 : (a == s ? -100.0 : 10.0),
    )
    # Opening a door ends the episode (the commitment).
    m, a -> a != "listen", s -> string(s), "\"problem\": \"tiger\", \"p_correct\": $p_correct"
end

function sensor(p_correct)
    nt = ["a-$qa-b-$qb" for qa in ("ok", "faulty") for qb in ("ok", "faulty")]
    commits = ["commit-$x" for x in nt]
    m = QuickPOMDP(
        states = vcat(nt, ["done"]), actions = vcat(["read-a", "read-b"], commits),
        observations = ["a-agree", "a-disagree", "b-agree", "b-disagree", "none"],
        initialstate = Uniform(nt), discount = 0.95, isterminal = s -> s == "done",
        transition = (s, a) -> (s == "done" || startswith(a, "commit")) ? Deterministic("done") : Deterministic(s),
        observation = function (a, sp)
            (sp == "done" || startswith(a, "commit")) && return Deterministic("none")
            ok = a == "read-a" ? startswith(sp, "a-ok") : endswith(sp, "b-ok")
            x = a == "read-a" ? "a" : "b"
            SparseCat(["$x-agree", "$x-disagree"], ok ? [p_correct, 1 - p_correct] : [1 - p_correct, p_correct])
        end,
        reward = (s, a) -> s == "done" ? 0.0 : startswith(a, "read") ? -1.0 : (a == "commit-$s" ? 20.0 : -20.0),
    )
    m, a -> startswith(a, "commit"), s -> string(s), "\"problem\": \"sensor\", \"p_correct\": $p_correct"
end

# Channel (k = 3) and Mine (k = 4 or 9): which of k values is the hidden one;
# probing a value returns a noisy hit/miss; committing to a value ends the episode.
function probe(name, k, p_correct)
    vals = ["v$i" for i in 1:k]
    m = QuickPOMDP(
        states = vcat(vals, ["done"]),
        actions = vcat(["probe-$v" for v in vals], ["commit-$v" for v in vals]),
        observations = vcat(["hit-$v" for v in vals], ["miss-$v" for v in vals], ["none"]),
        initialstate = Uniform(vals), discount = 0.95, isterminal = s -> s == "done",
        transition = (s, a) -> (s == "done" || startswith(a, "commit")) ? Deterministic("done") : Deterministic(s),
        observation = function (a, sp)
            (sp == "done" || startswith(a, "commit")) && return Deterministic("none")
            v = a[7:end]
            SparseCat(["hit-$v", "miss-$v"], sp == v ? [p_correct, 1 - p_correct] : [1 - p_correct, p_correct])
        end,
        reward = (s, a) -> s == "done" ? 0.0 : startswith(a, "probe") ? -1.0 : (a == "commit-$s" ? 20.0 : -20.0),
    )
    m, a -> startswith(a, "commit"), s -> string(s),
        "\"problem\": \"probe\", \"name\": \"$name\", \"k\": $k, \"p_correct\": $p_correct"
end

function rocksample(n, k, seed)
    rng = MersenneTwister(seed)
    cells = [(x, y) for x in 1:n for y in 1:n if (x, y) != (1, 1)]
    rocks = cells[randperm(rng, length(cells))[1:k]]
    m = RockSamplePOMDP(map_size = (n, n), rocks_positions = rocks, init_pos = (1, 1),
                        sensor_efficiency = 20.0, discount_factor = 0.95,
                        good_rock_reward = 20.0)
    desc(s) = isterminal(m, s) ? "terminal" :
        string(s.pos[1], ",", s.pos[2], "|", join(Int.(collect(s.rocks))))
    # Exiting the grid ends the episode; the graph stops at the exit action.
    rock_at = join(["\"$(x)-$(y)\": \"rock$i\"" for (i, (x, y)) in enumerate(rocks)], ", ")
    m, a -> false, desc, "\"problem\": \"rocksample\", \"n\": $n, \"k\": $k, \"seed\": $seed, \"rock_at\": {$rock_at}"
end

function obs_prob(m, b, a, o, S)
    p = 0.0
    for (i, s) in enumerate(S)
        bs = b.b[i]
        (bs == 0 || isterminal(m, s)) && continue
        for (sp, tp) in weighted_iterator(transition(m, s, a))
            p += bs * tp * pdf(observation(m, a, sp), o)
        end
    end
    p
end

key(b) = Tuple(round.(b.b, digits = 9))
all_terminal(m, b, S) = all(b.b[i] == 0 || isterminal(m, s) for (i, s) in enumerate(S))

function extract(m, ends, desc, meta, out; max_time = parse(Float64, get(ENV, "SARSOP_TIME", "120")))
    t0 = time()
    policy = solve(SARSOPSolver(precision = 1e-3, max_time = max_time), m)
    solve_s = time() - t0
    up = DiscreteUpdater(m)
    S = ordered_states(m)
    O = ordered_observations(m)
    b0 = initialize_belief(up, initialstate(m))
    ids = Dict(key(b0) => 0); beliefs = [b0]; acts = Any[]; kinds = String[]
    edges = Tuple{Int,Any,Int,Float64}[]
    i = 0
    while i < length(beliefs)
        i += 1
        b = beliefs[i]
        if all_terminal(m, b, S)
            push!(acts, nothing); push!(kinds, "terminal"); continue
        end
        a = action(policy, b)
        push!(acts, a)
        if ends(a)
            push!(kinds, "commit_end"); continue
        end
        push!(kinds, "inner")
        for o in O
            p = obs_prob(m, b, a, o, S)
            p < 1e-12 && continue
            bp = update(up, b, a, o)
            kb = key(bp)
            if !haskey(ids, kb)
                length(beliefs) >= MAX_NODES && error("policy graph exceeds $MAX_NODES nodes")
                ids[kb] = length(beliefs); push!(beliefs, bp)
            end
            push!(edges, (i - 1, o, ids[kb], p))
        end
    end
    q(x) = "\"" * replace(string(x), "\"" => "'") * "\""
    open(out, "w") do io
        println(io, "{")
        println(io, meta, ",")
        println(io, "\"solve_seconds\": ", solve_s, ",")
        println(io, "\"value_at_b0\": ", value(policy, b0), ",")
        println(io, "\"states\": [", join(q.(desc.(S)), ","), "],")
        println(io, "\"nodes\": [")
        for (j, b) in enumerate(beliefs)
            nz = [string(t - 1, ":", round(b.b[t], digits = 9)) for t in eachindex(b.b) if b.b[t] > 0]
            print(io, "{\"id\":", j - 1, ",\"kind\":", q(kinds[j]), ",\"action\":", q(acts[j]),
                  ",\"belief\":", q(join(nz, " ")), "}")
            println(io, j < length(beliefs) ? "," : "")
        end
        println(io, "],")
        println(io, "\"edges\": [")
        for (j, (f, o, t, p)) in enumerate(edges)
            print(io, "{\"from\":", f, ",\"obs\":", q(o), ",\"to\":", t, ",\"p\":", p, "}")
            println(io, j < length(edges) ? "," : "")
        end
        println(io, "]}")
    end
    println("nodes=", length(beliefs), " edges=", length(edges), " solve=", round(solve_s, digits = 1), "s")
end

function run_job(args)
    if args[1] == "tiger"
        extract(tiger(parse(Float64, args[2]))..., args[3])
    elseif args[1] == "probe"
        extract(probe(args[2], parse(Int, args[3]), parse(Float64, args[4]))..., args[5])
    elseif args[1] == "sensor"
        extract(sensor(parse(Float64, args[2]))..., args[3])
    elseif args[1] == "rocksample"
        extract(rocksample(parse(Int, args[2]), parse(Int, args[3]), parse(Int, args[4]))..., args[5])
    else
        error("unknown problem $(args[1])")
    end
end

# `batch <jobs.txt>` runs one job per line in a single process (package loading is slow).
if ARGS[1] == "batch"
    for line in eachline(ARGS[2])
        isempty(strip(line)) && continue
        println("job: ", line); flush(stdout)
        run_job(split(line))
    end
else
    run_job(ARGS)
end

# Extract the reachable policy graph of a SARSOP (or QMDP) policy.
#
#   julia extract_policy_graph.jl tiger <p_correct> <out.json>
#   julia extract_policy_graph.jl sensor <p_correct> <out.json>
#   julia extract_policy_graph.jl probe <name> <k> <p_correct> <out.json>
#   julia extract_policy_graph.jl rocksample <n> <k> <seed> <out.json>
#   julia extract_policy_graph.jl mutate <problem args...> <count> <seed> <outdir>
#   julia extract_policy_graph.jl batch <jobs.txt>      (one job per line, one process)
#
# Starting from the initial belief, follow the policy: at each belief take the
# policy's action and branch on every observation with nonzero probability.
# Beliefs are merged when equal up to 1e-9. The output lists every reachable
# belief node (belief vector, action) and every edge (observation, probability),
# so the graph contains exactly the policy's executions with positive probability.
#
# Environment:
#   SOLVER=sarsop (default) | qmdp | pbvi (PBVI_ITERS, default 10)   recorded as "solver" in the JSON.
#   Run with `julia --project=.` (Project.toml pins the package versions).
#     qmdp: value iteration on the fully observable MDP, one alpha vector per
#     action (ignores the value of information).
#   SARSOP_TIME=<seconds>            SARSOP time limit (default 120).
#
# mutate (fault injection): solve once, write the base graph to
# <outdir>/<base>-base.json, then up to <count> single-action mutants
# <outdir>/<base>-m<i>.json. A mutant equals the base policy except at the
# belief of one inner node of the base graph (9-digit rounded key), where it
# takes a different action. (node, action) pairs are drawn without replacement
# with MersenneTwister(<seed>), nodes at BFS depth <= 6 first; fewer than <count>
# mutants are written when fewer distinct pairs exist. Each mutant JSON adds
#   "base": "<base>", "mutation": {"node", "depth", "original_action", "new_action"}.
# <base> is tiger-<p>, sensor-<p>, <name>-<k>-<p> or rocksample-<n>-<k>-s<seed>.
#
# A failing job (e.g. the graph exceeds MAX_NODES) writes {meta..., "error": "<message>"}
# instead of a graph, so a batch keeps going.

using POMDPs
using POMDPTools
using NativeSARSOP
using Random
using RockSample
using QuickPOMDPs
using PointBasedValueIteration

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
                        sensor_efficiency = parse(Float64, get(ENV, "RS_EFFICIENCY", "20.0")),
                        discount_factor = parse(Float64, get(ENV, "DISCOUNT", "0.95")),
                        good_rock_reward = 20.0)
    desc(s) = isterminal(m, s) ? "terminal" :
        string(s.pos[1], ",", s.pos[2], "|", join(Int.(collect(s.rocks))))
    # Exiting the grid ends the episode; the graph stops at the exit action.
    rock_at = join(["\"$(x)-$(y)\": \"rock$i\"" for (i, (x, y)) in enumerate(rocks)], ", ")
    m, a -> false, desc, "\"problem\": \"rocksample\", \"n\": $n, \"k\": $k, \"seed\": $seed, \"rock_at\": {$rock_at}, " *
        "\"discount\": $(discount(m)), \"efficiency\": $(m.sensor_efficiency)"
end

# Tag (Pineau, Gordon and Thrun 2003): a robot searches for an opponent on a 29-cell
# map, a 10x2 corridor with a 3x3 room above columns 6-8. The robot starts in the
# bottom-left cell and sees its own cell and whether the opponent shares it; the
# opponent starts uniformly in another cell and moves away from the robot with
# probability 0.8 (split over the moves that increase the distance), else stays.
# Tagging in the opponent's cell ends the episode (+10); a failed tag costs 10, a move 1.
function tag()
    cells = vcat([(x, y) for y in 1:2 for x in 1:10], [(x, y) for y in 3:5 for x in 6:8])
    onmap = Set(cells)
    dirs = Dict("north" => (0, 1), "south" => (0, -1), "east" => (1, 0), "west" => (-1, 0))
    move(c, d) = (n = (c[1] + d[1], c[2] + d[2]); n in onmap ? n : c)
    dist(a, b) = abs(a[1] - b[1]) + abs(a[2] - b[2])
    T0 = (0, 0, 0, 0)                                   # tagged (terminal)
    start = (1, 1)
    states = vcat([(r..., o...) for r in cells for o in cells], [T0])
    function opponent(o, r)
        away = unique([move(o, d) for d in values(dirs) if dist(move(o, d), r) > dist(o, r)])
        isempty(away) && return [o], [1.0]
        vcat(away, [o]), vcat(fill(0.8 / length(away), length(away)), [0.2])
    end
    m = QuickPOMDP(
        states = states, actions = ["north", "south", "east", "west", "tag"],
        observations = vcat([(c..., v) for c in cells for v in 0:1], [(0, 0, 0)]),
        initialstate = Uniform([(start..., o...) for o in cells if o != start]),
        discount = 0.95, isterminal = s -> s == T0,
        transition = function (s, a)
            s == T0 && return Deterministic(T0)
            r, o = (s[1], s[2]), (s[3], s[4])
            a == "tag" && r == o && return Deterministic(T0)
            r2 = a == "tag" ? r : move(r, dirs[a])
            os, ps = opponent(o, r)
            SparseCat([(r2..., x...) for x in os], ps)
        end,
        observation = function (a, sp)
            sp == T0 && return Deterministic((0, 0, 0))
            Deterministic((sp[1], sp[2], Int((sp[1], sp[2]) == (sp[3], sp[4]))))
        end,
        reward = function (s, a)
            s == T0 && return 0.0
            a == "tag" ? ((s[1], s[2]) == (s[3], s[4]) ? 10.0 : -10.0) : -1.0
        end,
    )
    desc(s) = s == T0 ? "terminal" : string(s[1], ",", s[2], "|", s[3], ",", s[4])
    m, a -> false, desc, "\"problem\": \"tag\""
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

q(x) = "\"" * replace(string(x), "\"" => "'") * "\""
solver_name() = get(ENV, "SOLVER", "sarsop")

# QMDP: value iteration on the fully observable MDP (terminal states valued 0),
# then alpha_a(s) = R(s,a) + gamma * sum_s' T(s'|s,a) V(s'), one vector per action.
function qmdp(m; tol = 1e-8, maxiter = 100_000)
    S = ordered_states(m); A = ordered_actions(m); g = discount(m)
    term = [isterminal(m, s) for s in S]
    R = [term[i] ? 0.0 : reward(m, s, a) for (i, s) in enumerate(S), a in A]
    T = [term[i] ? Tuple{Int,Float64}[] :
         [(stateindex(m, sp), p) for (sp, p) in weighted_iterator(transition(m, s, a)) if p > 0]
         for (i, s) in enumerate(S), a in A]
    V = zeros(length(S))
    Q(i, j) = term[i] ? 0.0 : R[i, j] + g * sum((p * V[k] for (k, p) in T[i, j]); init = 0.0)
    for it in 1:maxiter
        Vn = [maximum(Q(i, j) for j in eachindex(A)) for i in eachindex(S)]
        d = maximum(abs.(Vn .- V)); V .= Vn
        d < tol && break
        it == maxiter && println("qmdp: value iteration hit $maxiter iterations (residual $d)")
    end
    AlphaVectorPolicy(m, [[Q(i, j) for i in eachindex(S)] for j in eachindex(A)], A)
end

function solve_policy(m; max_time = parse(Float64, get(ENV, "SARSOP_TIME", "120")))
    t0 = time()
    s = solver_name()
    # NativeSARSOP gives its initial bounds 1 s by default, too little for large models
    # (the upper bound then stays at 0); SARSOP_INIT_TIME raises it.
    init = parse(Float64, get(ENV, "SARSOP_INIT_TIME", "1.0"))
    policy = s == "sarsop" ? solve(SARSOPSolver(precision = 1e-3, max_time = max_time,
                                    init_lower = NativeSARSOP.BlindLowerBound(bel_res = 1e-2, max_time = init),
                                    init_upper = NativeSARSOP.FastInformedBound(bel_res = 1e-2, max_time = init)), m) :
             s == "qmdp" ? qmdp(m) :
             s == "pbvi" ? solve(PBVISolver(max_iterations = parse(Int, get(ENV, "PBVI_ITERS", "10"))), m) :
             error("unknown SOLVER $s")
    policy, time() - t0
end

# BFS over reachable beliefs; depth[j] is the BFS depth of node j (root 0).
function policy_graph(m, policy, ends)
    up = DiscreteUpdater(m)
    S = ordered_states(m)
    O = ordered_observations(m)
    b0 = initialize_belief(up, initialstate(m))
    ids = Dict(key(b0) => 0); beliefs = [b0]; depth = [0]; acts = Any[]; kinds = String[]
    edges = Tuple{Int,Any,Int,Float64}[]
    # Lossy merges: a new belief that rounds to an existing node but differs from it
    # by more than 1e-12 (floating-point noise). They can create loops that the exact
    # belief process does not have, so every graph reports them.
    lossy, lossy_self, max_diff = 0, 0, 0.0
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
                ids[kb] = length(beliefs); push!(beliefs, bp); push!(depth, depth[i] + 1)
            else
                d = maximum(abs.(bp.b .- beliefs[ids[kb] + 1].b))
                if d > 1e-12
                    lossy += 1; lossy_self += ids[kb] == i - 1; max_diff = max(max_diff, d)
                end
            end
            push!(edges, (i - 1, o, ids[kb], p))
        end
    end
    (; beliefs, depth, acts, kinds, edges, lossy, lossy_self, max_diff)
end

# `extra` is "" or extra top-level JSON members (without trailing comma).
function write_graph(out, m, desc, meta, extra, solve_s, policy, g)
    S = ordered_states(m)
    open(out, "w") do io
        println(io, "{")
        println(io, meta, ",")
        println(io, "\"solver\": ", q(solver_name()), ",")
        isempty(extra) || println(io, extra, ",")
        println(io, "\"merges\": {\"lossy\": ", g.lossy, ", \"lossy_self_loops\": ", g.lossy_self,
                ", \"max_diff\": ", g.max_diff, "},")
        println(io, "\"solve_seconds\": ", solve_s, ",")
        println(io, "\"value_at_b0\": ", value(policy, g.beliefs[1]), ",")
        println(io, "\"states\": [", join(q.(desc.(S)), ","), "],")
        println(io, "\"nodes\": [")
        for (j, b) in enumerate(g.beliefs)
            nz = [string(t - 1, ":", round(b.b[t], digits = 9)) for t in eachindex(b.b) if b.b[t] > 0]
            print(io, "{\"id\":", j - 1, ",\"kind\":", q(g.kinds[j]), ",\"action\":", q(g.acts[j]),
                  ",\"belief\":", q(join(nz, " ")), "}")
            println(io, j < length(g.beliefs) ? "," : "")
        end
        println(io, "],")
        println(io, "\"edges\": [")
        for (j, (f, o, t, p)) in enumerate(g.edges)
            print(io, "{\"from\":", f, ",\"obs\":", q(o), ",\"to\":", t, ",\"p\":", p, "}")
            println(io, j < length(g.edges) ? "," : "")
        end
        println(io, "]}")
    end
    println("nodes=", length(g.beliefs), " edges=", length(g.edges), " solve=", round(solve_s, digits = 1), "s")
end

function write_error(out, meta, extra, e)
    e isa InterruptException && rethrow()
    msg = replace(sprint(showerror, e), '\\' => '/', '\n' => ' ', '\r' => ' ', '\t' => ' ')
    println("ERROR ", out, ": ", msg)
    open(out, "w") do io
        println(io, "{", meta, ", \"solver\": ", q(solver_name()), ",", isempty(extra) ? "" : " $extra,",
                " \"error\": ", q(msg), "}")
    end
end

# EXPORT_ALPHAS=1 also writes <out>.alphas.json: the policy's alpha-vectors over the
# state order of the graph JSON, with the action of each (research direction R3).
function write_alphas(out, m, desc, policy)
    S = ordered_states(m)
    open(replace(out, r"\.json$" => "") * ".alphas.json", "w") do io
        println(io, "{\"states\": [", join(q.(desc.(S)), ","), "],")
        println(io, "\"actions\": [", join(q.(policy.action_map), ","), "],")
        println(io, "\"alphas\": [", join(["[" * join(a, ",") * "]" for a in policy.alphas], ",\n"), "]}")
    end
end

function extract(m, ends, desc, meta, out; kw...)
    try
        policy, solve_s = solve_policy(m; kw...)
        # alphas first: they are needed exactly when the graph is too large to enumerate
        get(ENV, "EXPORT_ALPHAS", "0") == "1" && write_alphas(out, m, desc, policy)
        write_graph(out, m, desc, meta, "", solve_s, policy, policy_graph(m, policy, ends))
    catch e
        write_error(out, meta, "", e)
    end
end

# The base policy except at one belief (9-digit rounded key), where it takes `a`.
struct Mutant{P<:Policy} <: Policy
    base::P
    k::Tuple
    a::Any
end
POMDPs.action(p::Mutant, b) = key(b) == p.k ? p.a : action(p.base, b)
POMDPs.value(p::Mutant, b) = value(p.base, b)

function mutate(m, ends, desc, meta, name, count, seed, outdir)
    mkpath(outdir)
    policy, solve_s = solve_policy(m)
    g = policy_graph(m, policy, ends)
    write_graph(joinpath(outdir, "$name-base.json"), m, desc, meta, "", solve_s, policy, g)
    rng = MersenneTwister(seed)
    A = collect(actions(m))
    inner = [j for j in eachindex(g.kinds) if g.kinds[j] == "inner"]
    cands(ns) = [(j, a) for j in ns for a in A if a != g.acts[j]]
    pool = shuffle(rng, cands(filter(j -> g.depth[j] <= 6, inner)))
    append!(pool, shuffle(rng, setdiff(cands(inner), pool)))
    length(pool) < count && println("only $(length(pool)) distinct mutations for $name")
    for (i, (j, a)) in enumerate(pool[1:min(count, end)])
        mut = string("\"base\": ", q(name), ", \"mutation\": {\"node\": ", j - 1, ", \"depth\": ", g.depth[j],
                     ", \"original_action\": ", q(g.acts[j]), ", \"new_action\": ", q(a), "}")
        out = joinpath(outdir, "$name-m$i.json")
        println("mutant $i: node ", j - 1, " ", g.acts[j], " -> ", a); flush(stdout)
        try
            mp = Mutant(policy, key(g.beliefs[j]), a)
            write_graph(out, m, desc, meta, mut, solve_s, mp, policy_graph(m, mp, ends))
        catch e
            write_error(out, meta, mut, e)
        end
    end
end

# Returns (model tuple, base name, number of args used).
function build(args)
    p = args[1]
    p == "tiger" && return (tiger(parse(Float64, args[2])), "tiger-$(args[2])", 2)
    p == "sensor" && return (sensor(parse(Float64, args[2])), "sensor-$(args[2])", 2)
    p == "probe" && return (probe(args[2], parse(Int, args[3]), parse(Float64, args[4])),
                            "$(args[2])-$(args[3])-$(args[4])", 4)
    p == "rocksample" && return (rocksample(parse.(Int, args[2:4])...),
                                 "rocksample-$(args[2])-$(args[3])-s$(args[4])", 4)
    p == "tag" && return (tag(), "tag", 1)
    error("unknown problem $p")
end

function run_job(args)
    if args[1] == "mutate"
        model, name, n = build(args[2:end])
        mutate(model..., name, parse(Int, args[n + 2]), parse(Int, args[n + 3]), args[n + 4])
    else
        model, _, n = build(args)
        extract(model..., args[n + 1])
    end
end

# `batch <jobs.txt>` runs one job per line in a single process (package loading is slow).
# Guarded so that other scripts can `include` the model builders.
if abspath(PROGRAM_FILE) != @__FILE__
elseif ARGS[1] == "batch"
    for line in eachline(ARGS[2])
        isempty(strip(line)) && continue
        println("job: ", line); flush(stdout)
        try
            run_job(split(line))
        catch e
            e isa InterruptException && rethrow()
            println("ERROR job failed: ", sprint(showerror, e))
        end
        flush(stdout)
    end
else
    run_job(ARGS)
end

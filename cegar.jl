# CEGAR search for a same-house 4-state quota+PM contradiction.
# usage: julia cegar.jl h seed iters
include("explore.jl")
using Random

# all quota allocations of profile p at house h
function allocs(p, h)
    P = mkprof(p, h)
    fi = [i for i in 1:N if P.fr[i]]
    out = NTuple{N,Int}[]
    for m in 0:(2^length(fi) - 1)
        count_ones(m) == P.k || continue
        a = collect(P.fl)
        for (t, i) in enumerate(fi); (m >> (t - 1)) & 1 == 1 && (a[i] += 1); end
        push!(out, Tuple(a))
    end
    out
end

# paradox from old (p,a) to new (q,b)?
function paradox(p, a, q, b)
    for i in 1:N, j in 1:N
        i != j && q[i] >= p[i] && q[j] <= p[j] && b[i] < a[i] && b[j] > a[j] && return true
    end
    false
end
consistent(p, a, q, b) = !paradox(p, a, q, b) && !paradox(q, b, p, a)

function solveX(X, h)
    P, var, nv, cls = build(h, X)
    sat, model, f = solve(nv, cls)
    rm(f)
    sat || return nothing
    [ntuple(i -> P[t].fl[i] + (P[t].fr[i] && get(model, var[t][i], false) ? 1 : 0), N) for t in eachindex(P)]
end

function randprof(rng, X)
    if !isempty(X) && rand(rng) < 0.8
        p = collect(rand(rng, X))
        for _ in 1:rand(rng, 1:2)
            i = rand(rng, 1:N)
            p[i] = rand(rng) < 0.5 ? max(1, round(Int, p[i] * exp(randn(rng) * 1.5))) : round(Int, exp(rand(rng) * log(2000)))
        end
        return Tuple(p)
    end
    ntuple(_ -> round(Int, exp(rand(rng) * log(2000))), N)
end

function cegar(h, seed, iters)
    rng = MersenneTwister(seed)
    X = NTuple{N,Int}[ntuple(_ -> rand(rng, 1:50), N) for _ in 1:20]
    A = solveX(X, h)
    for it in 1:iters
        bad = NTuple{N,Int}[]
        for _ in 1:20000
            q = randprof(rng, X)
            q in X && continue
            ok = any(b -> all(t -> consistent(X[t], A[t], q, b), eachindex(X)), allocs(q, h))
            ok || push!(bad, q)
            length(bad) >= 10 && break
        end
        isempty(bad) && (println("it $it: no blocking profile found, |X|=$(length(X))"); continue)
        append!(X, unique(bad))
        A = solveX(X, h)
        println("it $it: |X|=$(length(X)) -> ", A === nothing ? "UNSAT" : "SAT"); flush(stdout)
        A === nothing && return X
    end
    nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    h = parse(Int, ARGS[1]); seed = parse(Int, ARGS[2]); iters = parse(Int, ARGS[3])
    X = cegar(h, seed, iters)
    if X !== nothing
        open("unsat_h$(h)_s$(seed).txt", "w") do io; for p in X; println(io, join(p, ' ')); end; end
    end
end

# SAT exploration: n=4 states, fixed house size h, profiles = finite set of positive population vectors.
# Variable x[(P,i)] = state i rounded up at profile P (only when its quota is fractional).
# usage: julia explore.jl h M     (profiles = all of [1..M]^4)
const N = 4

struct Prof
    p::NTuple{N,Int}
    fl::NTuple{N,Int}
    fr::NTuple{N,Bool}
    k::Int          # number of fractional states to round up
end
function mkprof(p, h)
    S = sum(p)
    fl = ntuple(i -> (p[i] * h) ÷ S, N)
    fr = ntuple(i -> (p[i] * h) % S != 0, N)
    Prof(p, fl, fr, h - sum(fl))
end

# literal for "f_i(P) == v": returns :true, :false, or Int literal
function eqlit(P::Prof, i, v, var)
    if !P.fr[i]
        return v == P.fl[i] ? :true : :false
    end
    v == P.fl[i] && return -var[i]
    v == P.fl[i] + 1 && return var[i]
    :false
end
vals(P, i) = P.fr[i] ? (P.fl[i], P.fl[i] + 1) : (P.fl[i],)

# flat clause buffer (low memory)
mutable struct CB
    buf::Vector{Int32}
    n::Int
end
CB() = CB(Int32[], 0)
Base.push!(c::CB, v) = (append!(c.buf, v); push!(c.buf, 0); c.n += 1; c)
Base.length(c::CB) = c.n

function build(h, ps)
    P = [mkprof(p, h) for p in ps]
    var = Vector{NTuple{N,Int}}(undef, length(P))
    nv = 0
    for a in eachindex(P)
        var[a] = ntuple(i -> P[a].fr[i] ? (nv += 1) : 0, N)
    end
    cls = CB()
    for a in eachindex(P)   # exactly k ups
        fi = [var[a][i] for i in 1:N if P[a].fr[i]]
        for m in 0:(2^length(fi) - 1)
            count_ones(m) == P[a].k && continue
            push!(cls, [((m >> (t - 1)) & 1 == 1) ? -fi[t] : fi[t] for t in eachindex(fi)])
        end
    end
    for a in eachindex(P), b in eachindex(P)
        a == b && continue
        p, q = P[a].p, P[b].p   # old p, new q
        for i in 1:N, j in 1:N
            (i != j && q[i] >= p[i] && q[j] <= p[j]) || continue
            # forbid f_i(q) < f_i(p) and f_j(q) > f_j(p)
            for ai in vals(P[a], i), bi in vals(P[b], i), aj in vals(P[a], j), bj in vals(P[b], j)
                (bi < ai && bj > aj) || continue
                lits = [eqlit(P[a], i, ai, var[a]), eqlit(P[b], i, bi, var[b]),
                        eqlit(P[a], j, aj, var[a]), eqlit(P[b], j, bj, var[b])]
                any(==(:false), lits) && continue
                c = Int[-l for l in lits if l isa Int]
                push!(cls, unique(c))
            end
        end
    end
    P, var, nv, cls
end

function solve(nv, cls; solver = "cadical", file = tempname(mkpath(joinpath(@__DIR__, "tmp"))) * ".cnf")
    open(file, "w") do io
        println(io, "p cnf $nv $(length(cls))")
        if cls isa CB
            for v in cls.buf
                print(io, v); print(io, v == 0 ? '\n' : ' ')
            end
        else
            for c in cls
                println(io, join(c, ' '), " 0")
            end
        end
    end
    out = read(ignorestatus(`$solver -q $file`), String)
    sat = occursin("s SATISFIABLE", out)
    sat || occursin("s UNSATISFIABLE", out) || error("solver gave no verdict:\n" * first(out, 500))
    model = Dict{Int,Bool}()
    for l in eachline(IOBuffer(out))
        startswith(l, "v ") || continue
        for t in split(l)[2:end]
            v = parse(Int, t); v == 0 && continue
            model[abs(v)] = v > 0
        end
    end
    sat, model, file
end

if abspath(PROGRAM_FILE) == @__FILE__
    h = parse(Int, ARGS[1]); M = parse(Int, ARGS[2])
    ps = vec([(a, b, c, d) for a in 1:M, b in 1:M, c in 1:M, d in 1:M])
    P, var, nv, cls = build(h, ps)
    sat, model, f = solve(nv, cls)
    println("h=$h M=$M profiles=$(length(P)) vars=$nv clauses=$(length(cls)) -> ", sat ? "SAT" : "UNSAT", "  ($f)")
end

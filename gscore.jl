# General price-based rules: item (i, x, t) has score s_i(x,t), strictly decreasing in t, nondecreasing in x.
# Allocation = top-h items.  Find scores such that every profile in the set has a strictly separated quota allocation.
# usage: julia gscore.jl h smallmax Bmax
include("cegar.jl")
h = parse(Int, ARGS[1]); SM = parse(Int, ARGS[2]); BM = parse(Int, ARGS[3])
profs = Set{NTuple{4,Int}}()
for pos in 1:N, B in 1:BM, x in 1:SM, y in 1:SM, z in 1:SM
    o = (x, y, z); v = zeros(Int, N); t = 1
    for i in 1:N; i == pos ? (v[i] = B) : (v[i] = o[t]; t += 1); end
    push!(profs, Tuple(v))
end
profs = collect(profs)
pops = sort(unique(vcat([collect(p) for p in profs]...)))
sv(i, x, t) = "s_$(i)_$(x)_$(t)"
io = IOBuffer()
println(io, "(set-logic QF_LRA)")
for i in 1:N, x in pops, t in 0:h
    println(io, "(declare-const $(sv(i,x,t)) Real)")
end
for i in 1:N, (k, x) in enumerate(pops), t in 0:h
    t < h && println(io, "(assert (> $(sv(i,x,t)) $(sv(i,x,t+1))))")
    k < length(pops) && println(io, "(assert (<= $(sv(i,x,t)) $(sv(i,pops[k+1],t))))")
end
for p in profs
    disj = String[]
    for a in allocs(p, h)
        cons = String[]
        for i in 1:N, j in 1:N
            (i != j && a[i] >= 1) || continue
            push!(cons, "(> $(sv(i, p[i], a[i]-1)) $(sv(j, p[j], a[j])))")
        end
        push!(disj, isempty(cons) ? "true" : "(and " * join(cons, " ") * ")")
    end
    println(io, "(assert (or ", join(disj, " "), "))")
end
println(io, "(check-sat)")
f = joinpath(@__DIR__, "tmp", "gscore_h$(h)_$(SM)_$(BM).smt2"); write(f, take!(io))
out = read(ignorestatus(`z3 -T:6000 $f`), String)
println("gscore h=$h SM=$SM BM=$BM profiles=$(length(profs)) -> ", first(out, 100))

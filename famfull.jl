# Full PM SAT (all pairs) on the dominant family: one coordinate in 1..BM, others in 1..SM.
# usage: julia famfull.jl h SM BM
include("explore.jl")
h = parse(Int, ARGS[1]); SM = parse(Int, ARGS[2]); BM = parse(Int, ARGS[3])
ps = Set{NTuple{4,Int}}()
for pos in 1:N, B in 1:BM, x in 1:SM, y in 1:SM, z in 1:SM
    o = (x, y, z); v = zeros(Int, N); t = 1
    for i in 1:N; i == pos ? (v[i] = B) : (v[i] = o[t]; t += 1); end
    push!(ps, Tuple(v))
end
ps = sort(collect(ps))
P, var, nv, cls = build(h, ps)
sat, model, f = solve(nv, cls)
println("famfull h=$h SM=$SM BM=$BM profiles=$(length(P)) clauses=$(length(cls)) -> ", sat ? "SAT" : "UNSAT ($f)")

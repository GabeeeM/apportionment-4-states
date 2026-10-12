# Reproduce every number reported for "quota + population monotonicity, 4 states, fixed house size".
#
#   julia reproduce.jl          # ~3 min: gadget, UNSAT check, minimality, LRAT certificate, Apportion4.lean
#   julia reproduce.jl full     # also the discovery runs (h=16,20,24 dominant families; ~1.5 h, ~25 GB RAM)
#
# Needs `cadical` on PATH and python3 (trim_lrat.py).
include("explore.jl")

const H = 24
const PERMS = [[a,b,c,d] for a in 1:4 for b in 1:4 for c in 1:4 for d in 1:4 if length(Set([a,b,c,d])) == 4]
shapes = [(1,1,3,26), (1,2,2,26), (2,2,3,26), (1,3,3,26), (1,1,3,34)]
gadget = sort(unique([Tuple(collect(s)[σ]) for s in shapes for σ in PERMS]))
open(joinpath(@__DIR__, "core60.txt"), "w") do io; for p in gadget; println(io, join(p, ' ')); end; end

println("Gadget: all relabelings of $(length(shapes)) shapes = $(length(gadget)) profiles, house size $H")
for s in shapes
    q = [s[i] * H // sum(s) for i in 1:4]
    println("  shape $s: quotas $q  (", round.(Float64.(q), digits = 3), ")")
end

function unsat(ps)
    P, v, n, c = build(H, ps); s, _, f = solve(n, c); rm(f); !s
end
println("gadget UNSAT: ", unsat(gadget))
println("dropping any one profile -> SAT in ",
        count(k -> !unsat([gadget[t] for t in eachindex(gadget) if t != k]), eachindex(gadget)), " / $(length(gadget)) cases")
println("dropping any one shape   -> SAT in ",
        count(k -> !unsat([p for p in gadget if Tuple(sort(collect(p))) != Tuple(sort(collect(shapes[k])))]), eachindex(shapes)),
        " / $(length(shapes)) cases")
println("big state never at label 1 (45 profiles) -> ", unsat([p for p in gadget if argmax(collect(p)) != 1]) ? "UNSAT" : "SAT")

# certificate and Lean file
P, var, nv, cls = build(H, gadget)
open(joinpath(@__DIR__, "core60.cnf"), "w") do io
    println(io, "p cnf $nv $(length(cls))")
    for v in cls.buf; print(io, v); print(io, v == 0 ? '\n' : ' '); end
end
println("CNF: $nv variables, $(length(cls)) clauses")
cd(@__DIR__) do
    run(ignorestatus(`cadical -q --lrat=true --binary=false core60.cnf core60.lrat`))
    run(`python3 trim_lrat.py core60.cnf core60.lrat core60t.cnf core60t.lrat core60t.map`)
    run(`julia genlean.jl core60.txt $H core60t.cnf core60t.lrat core60t.map Apportion4.lean`)
end

# side result: house size 23 is also impossible (8 shapes, 104 profiles; SAT-checked, not formalized)
shapes23 = [(1,1,3,30), (1,2,3,28), (2,3,3,22), (1,2,3,22), (2,2,2,28), (1,2,2,28), (2,2,2,22), (1,1,2,28)]
g23 = sort(unique([Tuple(collect(s)[σ]) for s in shapes23 for σ in PERMS]))
let (P, v, n, c) = build(23, g23)
    s, _, f = solve(n, c); rm(f)
    println("h=23 gadget: $(length(g23)) profiles -> ", s ? "SAT" : "UNSAT")
end

if length(ARGS) > 0 && ARGS[1] == "full"
    S = Set{NTuple{4,Int}}()
    for pos in 1:4, B in 1:120, x in 1:3, y in 1:3, z in 1:3
        o = (x, y, z); v = zeros(Int, 4); t = 1
        for i in 1:4; i == pos ? (v[i] = B) : (v[i] = o[t]; t += 1); end
        push!(S, Tuple(v))
    end
    ps = sort(collect(S))
    cd(@__DIR__) do
        for h in 2:7; run(`julia explore.jl $h 6`); end            # all of [1..6]^4: SAT
        run(`julia famfull.jl 12 3 60`)                            # h=12 family: SAT
        run(`julia gscore.jl 12 3 60`)                             # price-based rules on it: unsat
        run(`julia dpll.jl core60.txt 24`)                         # DPLL nodes on the gadget
        run(`julia branch.jl core60.txt 24`)                       # no single branch point (prints none)
        run(`python3 lp60.py`)                                     # LP relaxation feasible
    end
    for (h, bmax) in ((16, 80), (20, 100), (24, 120))
        fam = [p for p in ps if maximum(p) <= bmax]
        Pf, vf, nf, cf = build(h, fam)
        sf, _, ff = solve(nf, cf); rm(ff)
        println("dominant family h=$h, big<=$bmax, smalls in {1,2,3}: $(length(fam)) profiles -> ", sf ? "SAT" : "UNSAT")
    end
end

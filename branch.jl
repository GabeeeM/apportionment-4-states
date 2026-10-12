# Find a profile X of a gadget such that every quota option at X leads to a contradiction by
# propagation alone (repeated forward checking / arc consistency on the pairwise CSP).
include("dpll.jl")

# arc consistency: remove b from dom[y] if no compatible a in dom[x] for some x
function ac!(core, dom; log = nothing)
    n = length(core)
    changed = true
    while changed
        changed = false
        for y in 1:n, x in 1:n
            x == y && continue
            nd = filter(b -> any(a -> compatible(core[x], a, core[y], b), dom[x]), dom[y])
            if length(nd) < length(dom[y])
                log === nothing || push!(log, (y, x, setdiff(dom[y], nd)))
                dom[y] = nd; changed = true
                isempty(nd) && return false
            end
        end
    end
    true
end

if abspath(PROGRAM_FILE) == @__FILE__
    core = loadcore(ARGS[1]); h = parse(Int, ARGS[2])
    D = [allocs(p, h) for p in core]
    dom = deepcopy(D)
    println("AC at root: ", ac!(core, dom), "  domain sizes after root AC: ", [length(d) for d in dom])
    for x in eachindex(core)
        ok = true
        for a in dom[x]
            d2 = deepcopy(dom); d2[x] = [a]
            ac!(core, d2) && (ok = false; break)
        end
        ok && println("branch point: ", core[x], " options ", dom[x])
    end
end

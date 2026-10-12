# CSP view of a gadget: each profile has a domain of quota allocations; two allocations at profiles p,q are
# compatible iff no population paradox in either direction.  DPLL with forward checking; count nodes.
include("cegar.jl")

function loadcore(file)
    [Tuple(parse.(Int, split(l))) for l in eachline(file) if !isempty(strip(l))]
end

compatible(p, a, q, b) = !paradox(p, a, q, b) && !paradox(q, b, p, a)

mutable struct Stats; nodes::Int; end

# returns true if satisfiable
function dpll(core, h; order = :mindom)
    n = length(core)
    D0 = [allocs(p, h) for p in core]
    st = Stats(0)
    function propagate(dom, assigned)
        changed = true
        while changed
            changed = false
            for x in 1:n
                isempty(dom[x]) && return false
                if length(dom[x]) == 1 && !assigned[x]
                    assigned[x] = true; changed = true
                    a = dom[x][1]
                    for y in 1:n
                        y == x && continue
                        nd = filter(b -> compatible(core[x], a, core[y], b), dom[y])
                        length(nd) < length(dom[y]) && (dom[y] = nd)
                        isempty(nd) && return false
                    end
                end
            end
        end
        true
    end
    function rec(dom, assigned)
        st.nodes += 1
        propagate(dom, assigned) || return false
        free = [x for x in 1:n if !assigned[x]]
        isempty(free) && return true
        x = free[argmin([length(dom[y]) for y in free])]
        for a in dom[x]
            d2 = copy(dom); d2[x] = [a]; as2 = copy(assigned)
            rec(d2, as2) && return true
        end
        false
    end
    sat = rec(copy(D0), falses(n))
    sat, st.nodes
end

if abspath(PROGRAM_FILE) == @__FILE__
    core = loadcore(ARGS[1]); h = parse(Int, ARGS[2])
    sat, nodes = dpll(core, h)
    println("sat=$sat nodes=$nodes  |core|=$(length(core))  domains=", [length(allocs(p, h)) for p in core])
end

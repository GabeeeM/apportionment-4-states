# Keep only original clauses referenced by the LRAT proof; renumber clauses and variables.
import sys
cnf, lrat, ocnf, olrat, omap = sys.argv[1:6]
L = open(cnf).read().split('\n')
hdr = [l for l in L if l.startswith('p')][0].split()
nc = int(hdr[3])
clauses = []
for l in L:
    if not l or l.startswith('p') or l.startswith('c'): continue
    clauses.append([int(x) for x in l.split()[:-1]])
assert len(clauses) == nc
steps = []
for l in open(lrat):
    t = l.split()
    if not t: continue
    if t[1] == 'd': continue  # drop deletions
    i = int(t[0]); z = t.index('0', 1)
    lits = [int(x) for x in t[1:z]]; hints = [int(x) for x in t[z+1:-1]]
    steps.append((i, lits, hints))
used = set()
for i, lits, hints in steps:
    for hh in hints:
        if abs(hh) <= nc: used.add(abs(hh))
keep = sorted(used)
cid = {old: new for new, old in enumerate(keep, 1)}
vars_ = sorted({abs(x) for k in keep for x in clauses[k-1]} | {abs(x) for _, lits, _ in steps for x in lits})
vid = {old: new for new, old in enumerate(vars_, 1)}
nxt = len(keep)
with open(ocnf, 'w') as f:
    f.write(f"p cnf {len(vars_)} {len(keep)}\n")
    for k in keep:
        f.write(' '.join(str((1 if x > 0 else -1) * vid[abs(x)]) for x in clauses[k-1]) + ' 0\n')
with open(olrat, 'w') as f:
    for i, lits, hints in steps:
        nxt += 1; cid[i] = nxt
        nl = [(1 if x > 0 else -1) * vid[abs(x)] for x in lits]
        nh = [(1 if hh > 0 else -1) * cid[abs(hh)] for hh in hints]
        f.write(' '.join(map(str, [nxt] + nl + [0] + nh + [0])) + '\n')
with open(omap, 'w') as f:
    for old in vars_: f.write(f"{vid[old]} {old}\n")
    f.write("clauses " + ' '.join(map(str, keep)) + "\n")
print("kept clauses", len(keep), "vars", len(vars_), "steps", len(steps))

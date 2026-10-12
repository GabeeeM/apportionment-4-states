# LP relaxation of the 60-vector CNF (clause sums >= 1, 0 <= x <= 1), checked with z3 (exact rationals).
import subprocess, sys, os
d = os.path.dirname(os.path.abspath(__file__))
L = [l.split() for l in open(os.path.join(d, 'core60.cnf')) if l.strip() and not l.startswith('p')]
nv = int(open(os.path.join(d, 'core60.cnf')).readline().split()[2])
out = ['(set-logic QF_LRA)']
for v in range(1, nv + 1): out.append(f'(declare-const x{v} Real)(assert (<= 0 x{v}))(assert (<= x{v} 1))')
for c in L:
    terms = ' '.join(f'x{l}' if l > 0 else f'(- 1 x{-l})' for l in map(int, c[:-1]))
    out.append(f'(assert (>= (+ {terms} 0) 1))')
out.append('(check-sat)')
f = os.path.join(d, 'tmp', 'lp60.smt2'); open(f, 'w').write('\n'.join(out))
print('LP relaxation of the 60-vector CNF:', subprocess.run(['z3', f], capture_output=True, text=True).stdout.strip())

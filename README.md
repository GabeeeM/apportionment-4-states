# Quota and population monotonicity are incompatible for four states at a fixed house size

**Papers:**
- Gölz, Peters, Procaccia, *In This Apportionment Lottery, the House Always Wins*,
  [arXiv:2202.11061](https://arxiv.org/abs/2202.11061), §3.1:
  > "Whether impossibility holds for n = 4 remains an open question."
- Varshney, *Quota and population monotonicity across house sizes are incompatible for apportionment to four
  states*, [arXiv:2608.02759](https://arxiv.org/abs/2608.02759), settles n = 4 when the compared house sizes may
  differ. It leaves open the case where every comparison uses the same house size:
  > "the four-state problem without auxiliary regularity assumptions remains open when every monotonicity
  > comparison is restricted to a common house size."

## Solution

**No solution exists, already at the single house size h = 24.** For 4 states, no deterministic solution
f(p, h) satisfies both of the following:
- **quota:** each state gets the floor or ceiling of h·p_i / Σp, and the seats sum to h;
- **population monotonicity at a fixed house size:** if state i's population weakly grows and state j's weakly
  shrinks, i never loses a seat while j gains one.

No anonymity, neutrality, homogeneity or order-preservation is assumed.

**The gadget.** It uses the 60 population vectors that are relabelings of five shapes, all at h = 24:

| shape | quotas |
|---|---|
| (1,1,3,26) | 0.774, 0.774, 2.323, 20.129 |
| (1,2,2,26) | 0.774, 1.548, 1.548, 20.129 |
| (2,2,3,26) | 1.455, 1.455, 2.182, 18.909 |
| (1,3,3,26) | 0.727, 2.182, 2.182, 18.909 |
| (1,1,3,34) | 0.615, 0.615, 1.846, 20.923 |

No choice of quota allocations for these 60 vectors avoids every population paradox between them. Dropping any
one vector makes a choice possible. [`PROOF.md`](PROOF.md) has a worked example of the reasoning and explains why
no short hand proof was found. House size 23 is also impossible (104 vectors), but that case is only SAT-checked.

**Lean 4 (Mathlib).** [`Apportion4.lean`](Apportion4.lean) proves `Apportion4.no_quota_popmono_fixed_house`.
Each constraint is a lemma proved from the two axioms, and the SAT refutation (LRAT) is replayed in the Lean
kernel by Mathlib's `lrat_proof`, with no native code. The only axioms used are `propext`, `Classical.choice`
and `Quot.sound`. To check it, run `lake exe cache get && lake build` (about 4 minutes).

## How it was found

A Claude loop exploring open problems from recent math papers. [`reproduce.jl`](reproduce.jl) rebuilds the
gadget, the certificate and `Apportion4.lean` ([`repro_output.txt`](repro_output.txt)); it needs `cadical` and
`python3`.

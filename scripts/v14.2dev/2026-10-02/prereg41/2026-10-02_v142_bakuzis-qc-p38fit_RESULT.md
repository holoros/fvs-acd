# Bakuzis QC grid for the field tag QC anchor p38_fit, and a matched tree TOPHT bound: PREREG41 result

2 October 2026. Pre-registration `plan/2026-10-02_v142_bakuzis-qc-p38fit_PREREG41.md` (revision 1, md5 a1aa4b35), recorded at
13:52:31 server time before any PREREG41 output (`logs/prereg_md5.txt`). Wrapper `run_p41.sh` (d7fd3101), chain `chain_p41.sh`
(d733721b), assemblies `assemble_p41.R` (0b7344b2, Part A) and `assemble_p41b.R` (0055e48e, Part B), md5s logged at 13:54
before the chain and the verifier started (`logs/launch_md5s.txt`); diffs against PREREG31 in `diffs/`. Driver
`v142p31/scripts/driver_p31.R` read in place (467fb518). Chain start 13:54:26, CHAIN_DONE 14:14:23. Nothing fitted; L and T
not re-estimated; GT1 stays a named failure. The PREREG40 limit (FIA length MQO, 10 percent) is still unconfirmed, so every
reading here is conditional and nothing is adopted. No coordinates. No em dashes.

## Verdict

**Part A, Rule 2: not cleared.** p38_fit (QC_AFAC 1.242 on every seeded tree) is not non inferior to 14.1 (frozen PREREG31
qc141) on the law like relations. Part (A) fails on site ordering of basal area, with three new flags (BF at N0 1,500 and
3,000, SM at 1,500); part (B) fails on Reineke (worst margin 1.490 against 1.266) and on site ordering of BA (14 ages with an
inversion against 13). This was the stated expectation and repeats the PREREG31 p28b_small pattern almost exactly. 14.1 keeps
0.111; 1.242 is not cleared for release consideration.

**Part B: the PREREG40 measured height reading is robust to selection.** On the same trees on both sides, B_MM for p38_fit is
+1.50 percent (-0.10 to 3.00), against B_M +1.60 in PREREG40; qc141 is -8.82 (-10.51 to -7.22). No selected tree lacked a
prediction (0 of 562 dropped in every arm).

| Gate or relation | p38_fit | qc141 (frozen) | p28b_small (PREREG31) | NI for p38_fit |
|:--|:--|:--|:--|:--:|
| G0, G0c (cited from PREREG31, driver md5 identical) | worst scaled 0; G0C_PASS | | | Yes |
| G1 trajectories, 101 rows | 36 of 36 | 36 of 36 frozen | | Yes |
| G2 identity cell qc141 MX ESI 19.8 N0 6,000 through `run_p41.sh` | identical to frozen | | | Yes |
| Reineke, worst margin (flags) | 1.490 (36) | 1.266 (36) | 1.496 (36) | **No** |
| Site ordering BA, ages with inversion (flags) | 14 (9) | 13 (6) | 14 (9) | **No** |
| Site ordering VOL | 0 | 0 | 1 (1) | Yes |
| Site ordering HT | 1 (1, also flagged in qc141) | 7 (7) | 0 | Yes |
| HT monotone | 0 | 2.80 m (31) | 0 | Yes |
| Frontier | 0 | 0.053 (10) | 0 | Yes |
| Yield density | 0 | 0.028 (8) | 0 | Yes |
| Eichhorn | 0 | 0.021 (1) | 0 | Yes |
| Magnitude | 0 | 7.0e-5 (1) | 0 | Yes |
| Sukachev | 0 | 0 | 0 | Yes |

## What the grid shows

**p38_fit behaves like p28b_small, as expected.** Every seeded tree carries 1.242 for 100 years (dht.mult table; recruits 1),
against 1.265 under p28b_small, and the relation table differs from PREREG31 only in small margins: p38_fit avoids the
p28b_small volume ordering flag and carries one top height ordering flag that qc141 also has. Top height at 50 is 13.7 to 18.3
m (0.72 to 1.03 of ESI) and 22.3 to 27.3 m at 100; ratio to qc141 1.12 to 4.50. Volume at 100 is 1.29 to 2.23 times qc141 and
stems 0.49 to 1.06 times.

**The failing margins are small and come from the synthetic start, not from the anchor alone.** The new BA flags are
inversions of 0.04 to 0.72 percent of the highest BA at that age; the worst p38_fit unit (MX, 6,000) reaches 1.57 percent
against 1.09 percent for the worst qc141 unit. In both arms the four ESI levels, which span only 2.5 m, separate weakly
(Figure 1b), so ordering turns on small differences. Reineke fails in all 72 trajectories because stems rise from 1,000 to
about 2,800 ha⁻¹ through ingrowth before any self thinning (Figure 1c); p38_fit slopes run -0.91 to +0.29, outside (-2.2,
-1.2) in both arms. Under the PREREG31 rule these still count, and the rule is not relaxed after seeing them.

**Realism, reported.** By the PREREG26 low test 23 p38_fit rows fall below 0.85 ESI at 50 or below 0.90 of qc141 (qc141: all
36 cells below 0.85 ESI at 50); by the mirror high test all 72 rows exceed 1/0.90 of qc141, because qc141 is the low
reference, while no p38_fit cell exceeds 1.15 ESI at 50.

![Bakuzis QC grid](figs/gyr142-p41-grid_2026-10-02.png)

**Figure 1. PREREG41 Bakuzis QC grid, N0 3,000, ESI 17.3 and 19.8 m, five year points, qc141 (frozen PREREG31) and p38_fit
by mix. (a) Top height; (b) basal area; (c) trees ha⁻¹ against QMD on log scales (the Reineke plane).** Data
`figs/gyr142-p41-grid_DATA_2026-10-02.csv`.

## Part B detail

| Arm | B_MM (95 percent site cluster interval) | PREREG40 B_M |
|:--|:--:|:--:|
| p19_a0111, qc141 (0.111) | -8.82 (-10.51 to -7.22) | -8.45 |
| p19_a1000 (1.000) | -0.72 (-2.33 to 0.75) | -0.55 |
| p23_a1061 (1.061) | -0.16 (-1.77 to 1.32) | -0.00 |
| p28b_small | -0.00 (-1.53 to 1.44) | 0.17 |
| p38_fit (1.242) | 1.50 (-0.10 to 3.00) | 1.60 |

154 stands with a record on both sides, 3.6 selected trees per stand, in every arm (`assembled/gyr142-p41-mm_DATA_2026-10-02.csv`).
The PREREG40 observed M values were reproduced for all ten arms before B_MM was read (worst 3.6e-14). Removing the selection
asymmetry moves B_M by 0.1 to 0.4 points, so the PREREG40 asymmetry was not material.

## Re-derivation [F9]

An independent agent wrote `verify_20261002/vA.R` and `vB.R` from the plan, the PREREG26 and PREREG31 plans and the inputs,
without reading the PREREG41 scripts or assembled files or the PREREG31 assembly. It ran Part B while the chain ran and Part A
after the trajectories existed; it finished at 14:16:35, after the assembly (14:14:23). Against the assembly 91 of 91 compared
items agree (`verify_20261002/compare/p41_verify_compare_r2_DATA_2026-10-02.csv`): flags, new flags and NI for every relation,
Reineke and every other flagged worst margin, B_MM, selected, dropped and stand counts for all ten arms (worst difference 0),
and the decision Rule 2. Two notes. The verifier's first Reineke point reading gave a qc141 worst margin of 0.892; it adopted
the reading that reproduces the PREREG31 value (both end points of each qualifying step), which matches the assembly. It counts
site ordering inversions over ESI pairs rather than over ages (54 against 36 for BA), so those margins were compared for
direction only, which agrees. Comparison revision 1 read the verifier's 1 and 0 coding of ni_ok as text and listed 10 false
disagreements; revision 2 fixes the comparison only.

## Deviations

1. Part B writes into `assembled/` beside Part A (the plan's location) after a one line edit to `assemble_p41b.R` made before
   its md5 was logged; the laptop copy committed before that edit is superseded.
2. The launch call returned a device timeout while the chain started normally (logs/chain.txt); nothing was relaunched.
3. No other deviation.

## Consequence for 14.2

The field tag anchor near 1.2 fixes QC height increment and measured top height on the benchmark (PREREG38, 40, 41 Part B), and
fails the Bakuzis non inferiority rule on the same two relations that stopped p28b_small. Both failures are small and appear
tied to the synthetic seedling start and the narrow QC ESI span rather than to the anchor value, but they are not waived. 14.1
keeps 0.111. Options for a next track, each needing its own pre-registration: a Bakuzis QC grid started from measured qc_c
stand lists rather than a seedling cohort; a reassigned size dependent anchor (needs a runner hook); or closing the QC anchor
question with 0.111 kept and the benchmark evidence documented.

## Files

Firebreather `~/jobs/v142p41/`: `plan/`, `scripts/`, `diffs/`, `in/` (links), `out/` (p38_fit trajectories), `dry/`, `assembled/`
(gates, relations, NI, realism, dht.mult, checker, verdict for Part A; mm, mm-repro, mm-verdict, vs-p28b Part B;
mm-stands_SERVERONLY server only), `figs/`, `logs/`, `verify_20261002/`.

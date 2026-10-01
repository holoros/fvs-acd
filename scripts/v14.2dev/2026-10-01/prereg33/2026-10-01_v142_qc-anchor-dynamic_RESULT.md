# QC height anchor reassigned from current DBH every annual step: PREREG33 result

1 October 2026. Pre-registration `plan/2026-10-01_v142_qc-anchor-dynamic_PREREG33.md` (revision 1, md5 c225df88), recorded
at 07:07:44 server time before any fold B or grid output in `logs/prereg_md5.txt`. Runner `home/runner_p33_fb.R` (md5
e3301b78; `runner_p28_fb.R` md5 0a2b2742 plus one switch, `QC_AFAC_DYNAMIC`, default 0; diff
`diffs/runner_p28_fb.R_to_runner_p33_fb.R.diff`, md5 7ce37f82; no model file edited), grid driver `scripts/driver_p33.R`
(6b63cfee), bundle md5 list identical to PREREG28b (47 files), scorer `2026-09-27_v142_volconv_score.R` (019df238,
unedited), benchmark assembly `scripts/2026-10-01_v142_p33_assemble_bench.R` (ae24ea5e), grid assembly
`scripts/assemble_p33_grid.R` (c63b2932), chain `scripts/chain_p33.sh` (3588fb0f). Chain start 07:07:49, benchmark
assembled 07:41, CHAIN_DONE 08:11:55. Nothing fitted. L and T not re-estimated; GT1 stays a named failure. No em dashes.

## Verdict

**Rule 3. The benchmark passes and non inferiority fails: not cleared.** Reassigning the anchor by current DBH keeps every
PREREG28b gate on screened qc_c fold B (TOPHT +11.14 percent against the +14.63 limit, better than +11.97 for the static
anchor), but on the Bakuzis QC grid it is not non inferior to qc141. Part (A) fails on site ordering of basal area, three
new flags (BF at N0 1,500 and 3,000, SM at 1,500); part (B) fails on Reineke (worst margin 1.412 against 1.266) and on
site ordering of BA (14 inversions against 13). It clears the PREREG31 volume flag (VOL ordering 0 against 0). 14.1 is
unchanged; the dynamic anchor is not cleared for release consideration.

| Harness gate | Result | Threshold | Pass |
|:--|:--|:--|:--:|
| G0a switch 0 against frozen p28b_small (58 qc_c stands, 19 qc_fl; results and 11,594 trees) | 0 | at or below 1e-9 | Yes |
| G0b switch 2, flat 0.111, against frozen p19_a0111 (same subset) | 0 | at or below 1e-9 | Yes |
| K1 p33_dyn after retry | 0 of 378 qc_c, 0 of 19 qc_fl; no time limit hits | 0 | Yes |
| G0 qc141 through driver_p33, 3 stands, 12 columns | 0 | at or below 1e-9 | Yes |
| G0d switch 2 through driver_p33, same stands | 0 | at or below 1e-9 | Yes |
| G0c checker reproduces stored v1402 report | G0C_PASS | identical | Yes |
| G1 trajectories complete, 101 rows | 72 of 72 | all | Yes |
| G2 qc141 grid through driver_p33 against PREREG31 qc141 | identical, 3,636 rows | identical | Yes |

| Benchmark gate, screened qc_c fold B | p33_dyn | p28b_small (reported) | Reference | Pass |
|:--|:--|:--|:--|:--:|
| H_inc pooled | 0.846 (0.716 to 1.054) | 0.883 | 0.086 at 0.111 | Yes |
| Bias below 12.7 cm | -0.084 m yr⁻¹ | -0.084 | -0.254 at 0.111 | Yes |
| Bias 12.7 to 25 cm | -0.001 m yr⁻¹ (-0.036 to +0.038) | +0.011 | -0.161 at 0.111 | Yes |
| Bias 25 cm and over | -0.021 m yr⁻¹, worse by 0.000 | -0.021 | -0.021 at 0.111, margin 0.03 | Yes |
| TOPHT | +11.14 percent | +11.97 | +14.63 at 1.061 (limit); +6.29 at 0.111 | Yes |
| Dominant cohort t2 level | 0.975 | 0.986 | 0.922 at 0.111, margin 0.02 | Yes |
| V2 C1 %RMSE | 46.91, d -0.15 | 46.91 | 46.76 at 0.111, floor -0.5 | Yes |
| B1 basal area | 0.42 points | 0.40 | 0.17 at 0.111, margin 1.0 | Yes |
| B2 stems | 24.48 points | 24.52 | 24.23 at 0.111, margin 2.0 | Yes |

| Grid relation | p33_dyn | qc141 (14.1) | Pass |
|:--|:--|:--|:--:|
| Reineke, 36 trajectories each | 36 flags, worst 1.412 | 36 flags, worst 1.266 | **No** |
| Site ordering, BA | 8 flags (3 new), worst 14 | 6 flags, worst 13 | **No** |
| Site ordering, VOL | 0 flags | 0 flags | Yes |
| Site ordering, HT | 1 flag, worst 2 | 7 flags, worst 7 | Yes |
| HT monotone | 4 flags, worst 0.053 m | 31 flags, worst 2.798 m | Yes |
| Frontier, Yield density, Eichhorn, Magnitude, Sukachev | 0 flags each | 10, 8, 1, 1, 0 | Yes |

## What the data show

**Over one remeasurement interval the switch touches only trees that cross 25 cm.** The below 12.7 cm and 25 cm and over
classes are identical to p28b_small on both folds (fold B -0.0840 and -0.0213 m yr⁻¹), so recruits at 1.265 instead of 1
do not move seeded tree height growth within an interval. The 12.7 to 25 cm class falls from +0.011 to -0.001 m yr⁻¹ and
the dominant cohort level from 0.986 to 0.975, because trees that pass 25 cm drop to 0.111 for the rest of the interval.
TOPHT bias falls 0.83 points. Volume, basal area and stems do not move. Fold A agrees (pooled 0.983; 12.7 to 25 cm +0.012).
qc_fl, reported: pooled 0.949 on 5 tag trees, TOPHT +9.34 percent on 5 stands.

**On the grid the anchor now stops height growth of the trees that define top height.** Seeded trees run at 1.265 until
the largest pass 25 cm, from about year 40 in BF (47 stems ha⁻¹ at 25 cm and over at 40, 301 at 100, ESI 19.8, N0 3,000);
cohort mean dht.mult falls to 0.27 to 0.91 by year 100; recruits sit at 0.96 to 1.17. Top height follows p28b_small for
about 40 years and then flattens: 12.1 to 18.2 m at 50 and 15.7 to 21.2 m at 100, against 22.6 to 27.6 m at 100 for
p28b_small (PREREG31). In 13 of 36 cells top height at 100 is below qc141 (lowest ratio 0.741, MX ESI 17.3 N0 6,000, 17.5
against 23.6 m), where the qc141 recruits at 1 overtake a stalled cohort. Volume at 100 is 1.18 to 2.20 times qc141; in BF
it peaks near year 90 and falls (ESI 19.8, N0 3,000: 277.3 at 90, 261.9 at 100 against 188.7 for qc141).

**The flags that fail are small; the cleared ones are large.** The new BA ordering flags are 3 to 6 five year points with
a largest gap of 0.17 percent of the top BA; the worst units (BF and MX at 6,000, 14 points) peak at 0.97 and 1.52 percent. The
Reineke worst is MX ESI 18.5 N0 1,500, slope +0.212 on its evaluated points against +0.050 for qc141; all 72 slopes lie
outside (-2.2, -1.2) in both arms. Against p28b_small, the dynamic anchor removes the VOL flag and lowers the Reineke worst from 1.496 to
1.412, but the same three BA units flag, and HT ordering (1 flag) and HT monotone (4 MX units at 1,500, falls of 0.044 to
0.053 m) reappear in small form. Realism, reported: top height at 50 is below 0.85 ESI in 22 of 36 cells (qc141
36 of 36) and above 1.15 ESI in none.

![Height increment by QC anchor](figs/gyr142-p33-hinc-by-class_2026-10-01.png)

**Figure 1. Predicted against observed annual height increment for tag matched QC survivors on screened qc_c: pooled ratio
and mean bias by t1 diameter class, for 0.111 (14.1), the PREREG28b static anchor and p33_dyn, fold A (fit) and fold B
(held out), 95 percent site cluster bootstrap intervals (B = 1000).** The two anchors differ only in the 12.7 to 25 cm class
and the pooled ratio.

![Grid top height, stems and volume](figs/gyr142-p33-grid-height-stems-volume_2026-10-01.png)

**Figure 2. Top height (m), stems (trees 4 cm and over, ha⁻¹) and NSVB total volume (m³ ha⁻¹) by projection year at N0
3,000 stems ha⁻¹, by mix and ESI: qc141 solid, p28b_small (PREREG31) dotted, p33_dyn dashed.** p33_dyn follows p28b_small
until about year 40 and then flattens near 16 m (BF) and 20 m (SM, MX); the QC mix steps from 12.0 to 18.2 m between
years 45 and 50 when the records that define top height change. Stems of the two candidate arms nearly coincide.

## Re-derivation [F9]

`verify_20261001/p33_rederive_bench.R` (bda0ad4e) is the PREREG28b re-derivation with p33_dyn added (no code shared with
the helper or the assembly): 20 height rows match the assembly (trees identical; worst ratio 4.4e-15, bias 4.4e-16, level
4.4e-15) and 4 stand rows match (worst TOPHT 4.8e-14, RMSE 2.8e-14); it recomputes TOPHT +11.142 percent, pooled ratio
0.8458 and C1 %RMSE 46.910. Log ends `P33_BENCH_REDERIVE_DONE`. `verify_20261001/rederive_p33_grid.R` (186ca7c7) is the
PREREG31 re-derivation with the arms and paths changed: 408 of 408 relation rows and flags agree, worst margin difference
5.0e-15, 10 of 10 NI gates agree, NI overall FALSE, 3 new flags. Log ends `P33_GRID_REDERIVE_DONE`. The benchmark assembly
also reproduced the PREREG19, PREREG23 and PREREG28b frozen tables before using any p33 value (worst 4.6e-13). Bootstrap
limits are not re-derived.

## Deviations

1. **G0 on a stated subset** (qc_c chunks 1, 10 and 19 and qc_fl), as pre-registered.
2. **G0b used switch value 2, not 1.** Value 1 at a flat 0.111 gives recruits 0.111 where the frozen runner gives 1, so it
   is not an identity; G0b1 (value 1, reported) differs from frozen p19_a0111 by up to 0.024 on results and 0.44 on recruit
   trees, 0.0019 on seeded trees.
3. **G2 redefined** as the whole qc141 grid against PREREG31; the separate dry cell was not run.
4. **Launcher load test made strict** (no start at 12 or above; PREREG28b allowed 12.0). Load stayed below 2.5.
5. Before the plan, a build assertion and a figure label in the dry render failed and were fixed; no model output existed.
   The figures were viewed from the full PNGs downscaled locally, since the small JPEGs printed inline.

## Files

`~/jobs/v142p33/`: `plan/` (PREREG33, cell files), `home/` (bundle, runner, retry scripts, taskmap), `scripts/` (builders,
drivers, chain, assemblies, G0 scripts, scorer and helper copies), `diffs/` (16 diffs), `logs/` (prereg md5, launch md5s,
bundle check, chain, G0 records, score, assembly logs), `results/`, `tables/`, `out/` (six trajectory files),
`assembled/bench/`, `assembled/grid/`, `assembled/gyr142-p33-final-verdict_DATA_2026-10-01.txt`, `figs/`,
`verify_20261001/`, `dry/`.

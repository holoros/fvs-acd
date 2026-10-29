# Decomposing the TOPHT gate against the tag dominant cohort: PREREG39 result

2 October 2026. Pre-registration `plan/2026-10-02_v142_topht-gate-decomposition_PREREG39.md` (revision 1, md5 ba0a48ec),
recorded at 06:55:06 server time before any PREREG39 output (`logs/prereg_md5.txt`). Frozen outputs only: no engine run, no
score, no refit, no gate or default changed. Assembly `scripts/assemble_p39_r2.R` (35b8c2ad; revision 1 `assemble_p39.R`
3f6ef970 kept, see Deviations), outputs `assembled_r2/`, input md5s `logs/input_md5_r2.txt` (49 files). L and T not
re-estimated; GT1 stays a named failure. No coordinates. No em dashes.

## Verdict

**G2, observed height handling, is the dominant source of the TOPHT and dominant cohort gap, in both arms.** On screened qc_c
fold B (160 stands, 152 sites) the gap is 16.78 points for p38_fit (1.242) and 16.50 for qc141 (0.111). The single step that
replaces measured t2 heights by the runner's `himp` curve where a dominant survivor has no t2 height carries 9.29 points for
p38_fit (share 0.553, interval 7.28 to 11.33) and 9.04 for qc141 (share 0.548, 7.16 to 11.21). The reading is consistent
across arms. In the observed TOPHT set 60.6 percent of heights are imputed, and on the trees in that set that do have a
height, `himp` returns 0.892 of the measured value. TOPHT_o is therefore held low by the imputation curve, and the TOPHT
bias is inflated by about 9 points relative to a measured height comparison. Under the pre-registered consequence, a TOPHT
gate on measured heights is the next track, through a separate pre-registration. 14.1 keeps 0.111; the PREREG38 verdict
stands.

| Rung | Step isolated | qc141 | p38_fit | Arm difference |
|:--|:--|:--:|:--:|:--:|
| D0 | dominant cohort metric (pooled tree ratio), 83 sites | -10.21 (-12.60 to -8.05) | -0.57 (-2.51 to 1.35) | 9.64 |
| D1 | stand means, bias percent (84 stands) | -9.66 | 0.01 | 9.67 |
| D2 | tag record rules dropped (100 stands) | -7.98 | 1.61 | 9.58 |
| D3 | observed height via `himp` where missing (147 stands) | 1.06 (-0.97 to 3.16) | 10.89 (9.03 to 12.90) | 9.83 |
| D4 | every t1 dominant row predicted (147 stands) | 2.74 | 12.69 | 9.94 |
| D5 | t2 rank selection, mindbh, record unit (159 stands) | 5.83 | 15.72 | 9.89 |
| D6 | recruits and unlinked rows, the published TOPHT (160 stands) | 6.29 (4.04 to 8.76) | 16.21 (14.01 to 18.55) | 9.92 |

Values are bias percent with 95 percent site cluster intervals (B = 1000, seed 20261002).

| Group | qc141 (share) | p38_fit (share) | p38_fit interval |
|:--|:--:|:--:|:--:|
| G1 aggregation and record rules | 2.23 (0.135) | 2.17 (0.129) | 0.98 to 3.48 |
| G2 observed height handling | **9.04 (0.548)** | **9.29 (0.553)** | 7.28 to 11.33 |
| G3 fate | 1.68 (0.102) | 1.79 (0.107) | 0.94 to 2.65 |
| G4 t2 rank selection | 3.09 (0.187) | 3.03 (0.181) | 1.34 to 4.98 |
| G5 recruits and unlinked rows | 0.46 (0.028) | 0.50 (0.030) | -0.01 to 1.29 |
| Gap, D6 minus D0 | 16.50 | 16.78 | 14.26 to 19.33 |

Reproduction stops, all passed before any rung was read (`assembled_r2/gyr142-p39-repro_DATA_2026-10-02.csv`): S1, D6 stand
values equal the results TOPHT_o and TOPHT_p for all 160 stands (worst 7.5e-14) and D6 equals the PREREG38 TOPHT bias (worst
7.5e-14); S2, D0 equals the PREREG38 dominant level (worst 4.4e-14) on the same 133 records; S3, 160 stands in both arms; S4,
the field tag and run t2 frames agree on every column other than TREE over 68,584 rows.

## What the data show

**The offset is an observed side artifact, not a model response.** The arm difference is 9.6 to 9.9 points at every rung, so
the anchor moves the dominant cohort and the published TOPHT by the same amount; none of the steps from D0 to D6 depends on
the anchor. The gap sits between how the two metrics read the observed stand. The largest step is the imputation: once the
t2 survivors without a measured height enter with `himp` heights, observed mean height drops and the bias jumps by about 9
points in both arms. The `himp` curve (1.3 + 27 (1 - exp(-0.030 d)) for softwoods, 1.3 + 25 (1 - exp(-0.028 d)) for
hardwoods) is a generic placeholder; on the measured trees of the TOPHT set it averages 0.892 of the measured height. No
finite observed height in either set is at or below 1.3 m, so zero coded heights are not the cause.

**The smaller steps.** Selecting the 100 largest stems ha⁻¹ at t2 rather than following the t1 cohort adds about 3 points
(G4), record rules about 2 (G1), predicted trees whose observed counterpart died about 1.7 (G3), and recruits about 0.5 (G5,
interval touching 0). In the observed TOPHT set 60.9 percent of records are t1 dominant survivors; in the predicted set about
94 percent are t1 dominant rows.

**What this means for the PREREG38 conflict.** The dominant cohort gate and the TOPHT gate disagree because TOPHT_o is built
largely from imputed heights that run about 11 percent low. The +14.63 percent TOPHT limit is the 1.061 arm's value under the
same imputation, so the gate compares one imputed metric with another and penalizes any anchor that brings measured height
growth to unbiased. This reading is diagnostic; the gate is not changed here [F4].

![TOPHT ladder](figs/gyr142-p39-topht-ladder-r2_2026-10-02.png)

**Figure 1. Decomposition of the published TOPHT bias against the field tag dominant cohort level, screened qc_c fold B,
qc141 (0.111) and p38_fit (1.242), 95 percent site cluster intervals (B = 1000). (a) Bias at rungs D0 (dominant cohort metric)
to D6 (published TOPHT); (b) contribution of each step.** Data `figs/gyr142-p39-topht-ladder-r2_DATA_2026-10-02.csv`.

## Re-derivation [F9]

An independent agent wrote `verify_20261002/p39_verify.R` (1201874f) from the plan alone, without reading the assembly or its
outputs (log ends `P39_VERIFY_DONE`; data eb819ed8). Against revision 1 of the assembly, 107 of 124 point items agreed and 17
disagreed, all from one cause: stand QC__30004466L2__2003_2016_C has no observed survivor passing the mindbh and 100 stems cut,
and revision 1 kept it at D5 with an observed value of 0 (the runner's empty list return), while the plan computes each rung
over stands with at least one record on each side. The verifier's reading matches the plan text. Revision 2 applies it;
against revision 2, 124 of 124 point items agree, worst 1.1e-14, and the 24 interval limits also match
(`verify_20261002/p39_verify_compare_r2_DATA_2026-10-02.csv`, 222ce323). The verifier confirmed that the r1 to r2 diff
(`logs/assemble_r1_to_r2.diff`) makes only that change. Outcome identical.

## Deviations

1. The assembly was revised once (r1 to r2) after the verifier found that r1 departed from the plan's stand rule at D5. The
   change moved G4 from 3.79 to 3.03 and G5 from -0.26 to +0.50 for p38_fit; the outcome did not change. r1 outputs are kept
   in `assembled/` and `figs/` (no `-r2` suffix) and are superseded.
2. Order of work: the verifier finished its plan-only re-derivation before the assembly script was written, and its summary
   numbers were seen before the assembly was written. Its code was not read until after the comparison. The r1 disagreement
   shows the two implementations were built separately; the independence is weaker than intended and is stated here.
3. No other deviation.

## Consequence for 14.2

The QC anchor near 1.2 is not rejected by stand top height in any sense that bears on the anchor; it is rejected by a metric
whose observed side is about 60 percent `himp`. Next, under a new pre-registration: a TOPHT gate on measured heights only
(the 100 stems ha⁻¹ set restricted to trees with measured t2 height on both sides, or the observed set with heights from a
locally fitted height and diameter model), applied to the frozen PREREG38 arms, to see whether p38_fit then passes. 14.1 keeps
0.111 until then.

## Files

Firebreather `~/jobs/v142p39/`: `plan/`, `scripts/` (r1, r2), `assembled_r2/` (ladder fbb3f9ac, deltas 75628c29, groups
78f5ce5f, repro d4bf0239, diag 4c141eae, armdiff 870cdcdb, verdict cae6c413, stands_SERVERONLY a713d24c, server only),
`assembled/` (r1, superseded), `figs/` (r2 PNG 0df3e771, data 48284759), `logs/`, `verify_20261002/`.

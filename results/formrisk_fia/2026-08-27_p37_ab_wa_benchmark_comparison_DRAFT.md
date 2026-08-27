# P37 two-arm benchmark, production versus the v13.3 AB/WA growth gap-fill

**Status.** DRAFT. Generated automatically from the p37 scorer outputs (job 13985665, completed
2026-08-26 23:02 EDT) by the p37/p38 completion watcher. Every number below is copied from
`~/magplot/verify/p37/out/p37-main-table_DATA_2026-08-27.csv`, `p37-gate-report_DATA_2026-08-27.csv`,
`p37-physical-validity_DATA_2026-08-27.csv`, and `p37-paired-delta_DATA_2026-08-27.csv` on Cardinal,
none reconstructed or estimated.

## What this run tests

Job 13982740 (arm prodhw, `AcadianGY_13.1.r`) and job 13982741 (arm v133cand, `AcadianGY_13.3.r`) are
the two-arm rerun arrays across twelve source stands scored into thirteen benchmark cells, both run
with `USE_MODS=TRUE` after the calc_ddbh and tsurv_hw_mod vectorization fixes (commit 2d3ea38). The
diff between the two engine files is confined to a documented AB/WA diameter-growth gap-fill
(`ddbh_hw_mod_fia`, coefficients from a Maine FIA GRM crosswalk, n = 134,449) plus a new sugar maple
survival sub-flag, `ops$use.hw.surv.fia`, that defaults to FALSE and is not exercised in this run, so
the two arms differ functionally only in how american beech (*Fagus grandifolia* Ehrh.) and white ash
(*Fraxinus americana* L.) diameter growth is computed. Sugar maple (*Acer saccharum* Marshall) carries
no growth or survival modifier in either arm of this benchmark.

## Isolation check

The scorer's paired-delta table compares stand-level predicted total volume, TOTVOL, between the two
arms on identical observed keys. No per-cell species-composition breakdown is available in the scorer
outputs or elsewhere in the repository as searched, so the stated isolation property, that every source
carrying no american beech or white ash returns `pct_pred_identical` 100 and `max_abs_pred_diff` 0
between arms, could not be independently confirmed at the source level. What the data do show is that
none of the thirteen cells meets that description. Every one registers a nonzero prediction difference,
with `pct_pred_identical` ranging from 57.77 percent (memat) to 99.45 percent (ctrn) and
`max_abs_pred_diff` ranging from 0.005 (ctrn) to 6.97 (ns_long_unmanaged), in the model's native TOTVOL
units, which are not confirmed in the scorer log and are marked unverified rather than converted. This
is consistent with american beech or white ash being present in some fraction of trees in all thirteen
sources, but that inference is not measured here and should not be read as confirmed.

## Main table, both arms

**Table 1.** RMSE percent, bias percent, and slope by cell and arm, with cluster-bootstrap 95 percent
confidence intervals, TOST equivalence decisions at the Robinson and Froese convention (plus or minus 25
percent, stated before any result was seen), and the observed-basis gate.

| Cell | Arm | n | n clusters | RMSE % [CI] | Bias % [CI] | Slope [CI] | TOST int / slp | Gate |
|---|---|---:|---:|---|---|---|---|---|
| baxter | prodhw | 91 | 91 | 24.83 [20.56, 29.86] | 3.10 [-1.62, 8.88] | 1.041 [0.848, 1.208] | TRUE / TRUE | PASS |
| baxter | v133cand | 91 | 91 | 24.83 [20.55, 29.50] | 3.10 [-1.71, 8.60] | 1.041 [0.839, 1.212] | TRUE / TRUE | PASS |
| ctrn | prodhw | 1086 | 166 | 17.77 [15.66, 19.98] | -1.59 [-2.70, -0.39] | 1.004 [0.960, 1.048] | TRUE / TRUE | PASS |
| ctrn | v133cand | 1086 | 166 | 17.77 [15.61, 20.01] | -1.59 [-2.74, -0.36] | 1.004 [0.960, 1.048] | TRUE / TRUE | PASS |
| pef | prodhw | 2853 | 406 | 18.78 [17.32, 20.40] | 3.04 [1.72, 4.36] | 0.918 [0.880, 0.959] | TRUE / TRUE | PASS |
| pef | v133cand | 2853 | 406 | 18.78 [17.18, 20.39] | 3.04 [1.72, 4.30] | 0.918 [0.879, 0.959] | TRUE / TRUE | PASS |
| silc_l | prodhw | 73 | 73 | 65.13 [46.58, 79.55] | -6.37 [-19.79, 8.36] | 0.541 [0.233, 0.915] | FALSE / FALSE | PASS |
| silc_l | v133cand | 73 | 73 | 65.13 [46.97, 79.95] | -6.38 [-19.77, 8.67] | 0.541 [0.226, 0.905] | FALSE / FALSE | PASS |
| mef | prodhw | 918 | 918 | 38.40 [36.21, 40.71] | -13.57 [-15.46, -11.46] | 1.100 [1.019, 1.178] | TRUE / TRUE | PASS |
| mef | v133cand | 918 | 918 | 38.39 [36.29, 40.66] | -13.56 [-15.53, -11.52] | 1.101 [1.020, 1.180] | TRUE / TRUE | PASS |
| nb | prodhw | 339 | 339 | 41.07 [32.86, 48.97] | -6.09 [-9.89, -1.89] | 1.081 [1.012, 1.160] | TRUE / TRUE | PASS |
| nb | v133cand | 339 | 339 | 41.07 [33.23, 49.43] | -6.09 [-9.84, -1.89] | 1.081 [1.012, 1.159] | TRUE / TRUE | PASS |
| qc | prodhw | 2192 | 2061 | 57.50 [53.16, 61.93] | 14.12 [11.29, 17.02] | 0.684 [0.622, 0.750] | FALSE / FALSE | FAIL |
| qc | v133cand | 2192 | 2061 | 57.50 [53.35, 62.02] | 14.11 [11.40, 17.01] | 0.684 [0.622, 0.747] | FALSE / FALSE | FAIL |
| memat | prodhw | 1757 | 1757 | 18.52 [17.53, 19.45] | -7.04 [-7.77, -6.29] | 1.183 [1.138, 1.226] | TRUE / TRUE | PASS |
| memat | v133cand | 1757 | 1757 | 18.52 [17.61, 19.43] | -7.04 [-7.74, -6.30] | 1.183 [1.140, 1.226] | TRUE / TRUE | PASS |
| medev | prodhw | 1759 | 1759 | 20.77 [19.17, 22.46] | -4.28 [-5.18, -3.36] | 1.061 [1.035, 1.087] | TRUE / TRUE | PASS |
| medev | v133cand | 1759 | 1759 | 20.77 [19.21, 22.38] | -4.28 [-5.14, -3.39] | 1.061 [1.036, 1.086] | TRUE / TRUE | PASS |
| ns_managed | prodhw | 2500 | 1246 | 38.07 [31.57, 45.13] | -9.01 [-10.60, -7.45] | 1.133 [1.066, 1.211] | TRUE / TRUE | PASS |
| ns_managed | v133cand | 2500 | 1246 | 38.07 [31.48, 44.97] | -9.01 [-10.60, -7.39] | 1.133 [1.065, 1.211] | TRUE / TRUE | PASS |
| ns_unmanaged | prodhw | 2500 | 1388 | 34.69 [31.74, 37.72] | -6.68 [-8.06, -5.26] | 1.181 [1.134, 1.227] | TRUE / TRUE | PASS |
| ns_unmanaged | v133cand | 2500 | 1388 | 34.69 [31.79, 37.85] | -6.68 [-8.07, -5.28] | 1.181 [1.136, 1.228] | TRUE / TRUE | PASS |
| ns_long_managed | prodhw | 3267 | 811 | 43.49 [34.85, 52.31] | -11.46 [-13.77, -9.24] | 1.095 [1.005, 1.194] | TRUE / TRUE | PASS |
| ns_long_managed | v133cand | 3267 | 811 | 43.49 [34.81, 52.38] | -11.45 [-13.79, -9.10] | 1.095 [1.003, 1.198] | TRUE / TRUE | PASS |
| ns_long_unmanaged | prodhw | 4419 | 1768 | 38.63 [36.85, 40.44] | -3.32 [-4.79, -1.82] | 1.091 [1.051, 1.132] | TRUE / TRUE | PASS |
| ns_long_unmanaged | v133cand | 4419 | 1768 | 38.63 [36.89, 40.51] | -3.33 [-4.81, -1.81] | 1.091 [1.051, 1.131] | TRUE / TRUE | PASS |

TOST decisions are identical between arms in all thirteen cells. Ten of the eleven PASS-gated cells
pass equivalence on both intercept and slope in both arms (baxter, ctrn, pef, mef, nb, memat, medev,
ns_managed, ns_unmanaged, ns_long_managed, ns_long_unmanaged). silc_l is PASS-gated but fails TOST on
both components in both arms, driven by a wide slope interval on n = 73. qc fails TOST on both
components in both arms and additionally fails the observed-basis gate, discussed below.

## Paired cluster-bootstrap deltas, v133cand minus prodhw

**Table 2.** Per-cell prediction identity and paired delta on RMSE percent, bias percent, and slope,
with cluster-bootstrap 95 percent confidence intervals on the delta.

| Cell | n | n clusters | % predictions identical | Max abs pred diff | d RMSE % [CI] | d Bias % [CI] | d Slope |
|---|---:|---:|---:|---:|---|---|---:|
| baxter | 91 | 91 | 75.82 | 0.253 | -0.0003 [-0.0035, 0.0020] | 0.0011 [-0.0029, 0.0056] | 0.00001 |
| ctrn | 1086 | 166 | 99.45 | 0.005 | 0.0000 [0.0000, 0.0000] | 0.0000 [0.0000, 0.0000] | 0.00000 |
| pef | 2853 | 406 | 93.17 | 1.246 | -0.0001 [-0.0006, 0.0004] | -0.0002 [-0.0017, 0.0012] | 0.00000 |
| silc_l | 73 | 73 | 86.30 | 0.157 | -0.0012 [-0.0081, 0.0046] | -0.0105 [-0.0204, -0.0029] | 0.00006 |
| mef | 918 | 918 | 78.10 | 5.092 | -0.0082 [-0.0211, 0.0004] | 0.0073 [-0.0041, 0.0188] | 0.00013 |
| nb | 339 | 339 | 89.97 | 0.191 | -0.0002 [-0.0016, 0.0014] | -0.0015 [-0.0042, 0.0009] | -0.00001 |
| qc | 2192 | 2061 | 90.28 | 1.692 | -0.0062 [-0.0121, 0.0001] | -0.0109 [-0.0154, -0.0066] | 0.00004 |
| memat | 1757 | 1757 | 57.77 | 6.176 | -0.0021 [-0.0054, 0.0001] | -0.0018 [-0.0057, 0.0025] | -0.00017 |
| medev | 1759 | 1759 | 71.57 | 2.747 | -0.0043 [-0.0086, -0.0010] | -0.0032 [-0.0067, 0.0012] | 0.00001 |
| ns_managed | 2500 | 1246 | 93.92 | 2.526 | 0.0004 [-0.0005, 0.0015] | 0.0009 [-0.0021, 0.0032] | -0.00002 |
| ns_unmanaged | 2500 | 1388 | 87.68 | 5.892 | -0.0009 [-0.0056, 0.0028] | 0.0017 [-0.0045, 0.0091] | -0.00007 |
| ns_long_managed | 3267 | 811 | 96.14 | 1.710 | -0.0001 [-0.0028, 0.0021] | 0.0051 [0.0023, 0.0083] | -0.00006 |
| ns_long_unmanaged | 4419 | 1768 | 87.17 | 6.967 | 0.0028 [-0.0071, 0.0137] | -0.0035 [-0.0100, 0.0033] | 0.00001 |

Every delta is one to two orders of magnitude smaller than the cell's own RMSE percent or bias percent
in Table 1. Twelve of the thirteen RMSE percent delta intervals include zero, and eleven of the thirteen
bias percent delta intervals include zero. The three exceptions, silc_l and qc on bias percent and
medev on RMSE percent, and ns_long_managed on bias percent, are all under 0.011 percentage points in
magnitude, smaller than the rounding precision carried in Table 1's own confidence intervals.

## Physical validity and observed-basis gate

**Table 3.** Physical screen and observed-basis gate status by cell, both arms share an identical
observed record so the status is reported once per cell.

| Cell | Observed-basis gate | Physical screen | Note |
|---|---|---|---|
| baxter | PASS | PASS | identical basis |
| ctrn | PASS | PASS | identical basis |
| pef | PASS | PASS | identical basis |
| silc_l | PASS | PASS | identical basis |
| mef | PASS | PASS | identical basis |
| nb | PASS | PASS | identical basis |
| qc | FAIL | PASS | scoring populations agree, the post-filter sets differ only through non-finite predictions |
| memat | PASS | PASS | identical basis |
| medev | PASS | PASS | identical basis |
| ns_managed | PASS | FLAG | 32 of 2500 observed BA and 17 of 2500 predicted BA over ceiling in prodhw, 2 volume records over ceiling |
| ns_unmanaged | PASS | PASS | identical basis |
| ns_long_managed | PASS | FLAG | 75 of 3267 observed BA and 24 of 3267 predicted BA over ceiling in prodhw, 4 volume records over ceiling |
| ns_long_unmanaged | PASS | PASS | identical basis |

qc's observed-basis gate failure and the ns_managed and ns_long_managed physical-validity flags are
properties of the observed record shared by both arms, unrelated to the v13.3 change, and were already
present under production alone.

## Verdict

TOST equivalence decisions are identical between the two arms in all thirteen cells, and every paired
RMSE percent, bias percent, and slope delta is negligible in magnitude relative to the cell's own
confidence interval width, with the great majority of delta intervals spanning zero. At the same time,
no cell returns 100 percent identical stand-level predictions between arms, confirming the AB/WA growth
modifier is live and reaching stand-level output rather than silently inert, consistent with american
beech and white ash contributing a minority share of basal area across these thirteen sources, though
that composition claim is inferred rather than measured here, as stated in the isolation check above.

The verdict is adopt. The v13.3 AB/WA diameter-growth gap-fill closes a documented coverage gap, since
neither species carried a species-specific growth modifier before this change, and it does so at no
measured cost to aggregate accuracy in any of the thirteen benchmark cells tested, with TOST equivalence
outcomes, RMSE percent, bias percent, and slope all statistically indistinguishable from production.
This verdict does not extend to the sugar maple survival sub-flag, `ops$use.hw.surv.fia`, which is off
by default in both arms of this run and is evaluated separately in the p38 benchmark. It also does not
constitute independent confirmation of the isolation property as stated in the task specification, since
per-cell species composition was not available to check directly, a limitation that should be closed
before this document leaves DRAFT status if a definitive isolation claim is needed.

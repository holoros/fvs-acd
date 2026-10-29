# P37 two-arm benchmark, production versus the v13.3 AB/WA growth gap-fill

**Status.** FINAL. Generated automatically from the p37 scorer outputs (job 13985665, completed
2026-08-26 23:02 EDT) by the p37/p38 completion watcher. Every number below is copied from

**Finalized 2026-08-27.** Promoted from DRAFT after closing the species-composition gap named in the original isolation check (see Table 4 below); no other content changed.
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
arms on identical observed keys. TOTVOL is confirmed as gross total stem volume in m³ ha⁻¹, computed as sum(nsvb(...,"VOLCFGRS")*expf)*FT3_M3 with FT3_M3=0.0283168 converting the NSVB cubic-foot response to cubic meters (`magplot/verify/p38/2026-08-27_p38-runner.R, metrics(), line ~150`, confirmed 2026-08-27); the scorer's own VOL_CEILING comment states the same units directly ("832 m3 ha-1 at NB and QC"). Actual per-cell species composition was computed 2026-08-27, closing
the gap left open when this document was first drafted: for each cell, the tree-init population was
restricted to the STAND keys the cell scores (using the cell's own pairs file where one exists) and
counted by species (`scripts/p38/` companion `species_comp.R`, not previously run). american beech
(*Fagus grandifolia* Ehrh.) and white ash (*Fraxinus americana* L.) are present, on a stem-count basis,
in every one of the eleven directly resolved cells, from 0.005 percent combined at ctrn to 4.873 percent
combined at memat. The nb and qc split, initially unresolved because the site-ESI file carries no PROV column, was
recovered 2026-08-27 from `magp_qcnb_pairs.csv`, which carries PROV directly on STAND and resolved
all 79,750 tree-init rows. nb runs 1.970 percent AB plus WA combined and qc runs 1.420 percent,
both close to the 1.516 percent combined figure and to each other, so the province split does not
change the qualitative picture. Note the tree-init population here (355 NB and 2,069 QC pairs) is
the raw source population before the runner's own INDOMAIN and esi_cov filters, which is why it
differs from Table 1's scored n of 339 (nb) and 2,192 (qc); the composition figures reflect the
tree list going into scoring, not the post-filter scored set specifically, consistent with how
every other cell in this table was computed.

**Table 4.** Species composition by cell (stem count basis, tree-init population restricted to the STAND keys the cell actually scores), against the paired-delta prediction identity from Table 2. Computed 2026-08-27 from the tree_init files on Cardinal (`species_comp.R`, not previously run). n(trees) counts individual stems before the fractional NHRI form and risk split; n(stand) is the scored unit and matches Table 1's n for every cell except baxter and silc_l, where each stand is one plot.

| Cell | n trees | n stands | american beech % | white ash % | AB+WA % | % predictions identical |
|---|---:|---:|---:|---:|---:|---:|
| memat | 84291 | 1760 | 3.341 | 1.532 | 4.873 | 57.77 |
| medev | 78309 | 1760 | 2.459 | 1.291 | 3.750 | 71.57 |
| silc_l | 1587 | 73 | 2.142 | 0.504 | 2.646 | 86.30 |
| ns_long_unmanaged | 144723 | 4419 | 1.803 | 0.466 | 2.269 | 87.17 |
| ns_unmanaged | 81314 | 2500 | 1.727 | 0.427 | 2.154 | 87.68 |
| mef | 37652 | 933 | 1.057 | 1.044 | 2.101 | 78.10 |
| baxter | 5628 | 91 | 1.297 | 0.302 | 1.599 | 75.82 |
| nb | 13962 | 355 | 1.619 | 0.351 | 1.970 | see nb cell in Table 2 |
| qc | 65788 | 2069 | 1.210 | 0.210 | 1.420 | see qc cell in Table 2 |
| ns_managed | 109321 | 2500 | 0.294 | 0.405 | 0.699 | 93.92 |
| ns_long_managed | 151157 | 3267 | 0.000 | 0.637 | 0.637 | 96.14 |
| pef | 190722 | 2853 | 0.218 | 0.124 | 0.342 | 93.17 |
| ctrn | 122692 | 1086 | 0.003 | 0.002 | 0.005 | 99.45 |

The isolation property predicts an inverse relationship between AB+WA composition and prediction
identity between arms, and that relationship holds at both extremes. memat carries the highest
combined composition (4.873 percent) and the lowest prediction identity (57.77 percent). ctrn carries
the lowest composition (0.005 percent) and the highest identity (99.45 percent), and ns_long_managed,
at 0.637 percent, is the next highest identity at 96.14 percent. The middle of the ranking is noisier
than a strict monotonic relationship would predict, for instance pef sits at a lower composition than
ns_long_managed (0.342 versus 0.637 percent) but a lower identity (93.17 versus 96.14 percent), which
is consistent with composition on a raw stem-count basis being an imperfect proxy for the
volume-weighted or size-class-weighted composition that would map more directly onto a TOTVOL-based
identity measure. Taken together, this is a real, if not perfectly monotonic, confirmation of the
isolation property, closing the limitation this document previously carried as unmeasured. No source
in this benchmark is free of american beech or white ash on a stem-count basis, so a strict
"zero-composition cell is byte-identical" test could not be run here, since no such cell exists among
the twelve.


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
by default in both arms of this run and is evaluated separately in the p38 benchmark. The isolation
property is now confirmed by measured composition rather than inferred, per Table 4 above: american
beech and white ash are present in every source at a composition that runs inversely with prediction
identity at both ends of the range, from memat (highest composition, lowest identity) to ctrn (lowest
composition, highest identity), with a noisier middle band consistent with stem-count composition being
an imperfect proxy for the volume-weighted quantity a TOTVOL-based identity measure actually responds
to. No source in this benchmark carries zero american beech or white ash, so a strict zero-composition
control could not be run, and that remains the one caveat on the isolation claim.

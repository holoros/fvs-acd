# Pass 21 results: v13.2 full six/eight-source empirical battery rescore

Queued at pass 20, run 19-20 August 2026. Two Cardinal SLURM array jobs (13728925 array 1-2:
Baxter, Maine FIA whole-plot; 13728926 array 1-10: memat, medev, PEF, CTRN, SILC_L, NB MagPlot,
NS managed/unmanaged, NS-long managed/unmanaged) scored the pass-20 v13.2 site-fsm calc_ddbh
overlay under the exact same ship18 base config (ONSET 0.55, LEVER 3b lo 0.35 hi 0.45 qmin 18,
IMULT 2.5, p4e r2 ddbh refit) so the composite isolates the effect of the pass-20 patch alone.
All 12 array tasks completed clean (0 fail) except Maine FIA whole-plot (15 fail of 918, in line
with the ship18 run's own fail rate). The observed-basis gate (p21_observed_check.csv) confirms
byte-identical TOTVOL_o and stand keys against the base column on all 8 composite sources
(max_abs_dTOTVOL_o = 0 everywhere), so v13.2 and ship18 are scored on an apples-to-apples basis.

Raw per-stand results CSVs (p9_bax_v132_results.csv and the other 9 sources) live on Cardinal at
~/magplot/verify/p21/, not in this repo, consistent with how the p9lev3 ship18 raw results were
never checked in either; only the harness/composite scripts and the summary tables here are
tracked.

## Headline result

At the pooled composite level (p21_composite_v132.csv), v13.2 is statistically indistinguishable
from ship18: composite RMSE 85.86 vs 85.44 (NS scenario), 106.62 vs 106.47 (NS-long scenario);
bootstrap CIs overlap almost completely in both scenarios. The pooled composite does not move
because it is dominated by NS/NS-long (roughly half the pooled stand count) where v13.2 and
ship18 are within noise of each other.

Per source (p21_v132_persource.csv) tells the real story. Baxter, the mature held-out stand that
motivated the pass-19/20 site-term fix, goes from ship18's %RMSE 28.80 / bias +13.53% (over-
predicting, slope 0.845, the site-ordering violation) to v13.2's %RMSE 25.72 / bias -0.22% (slope
1.087, close to unbiased and near-unity slope). Every other source moves by at most about 1
RMSE point and well under 1 bias point in either direction relative to ship18 (CTRN, Maine FIA
whole-plot, PEF, SILC, NB, NS, NS-long), consistent with noise, not degradation. The pass-20 fix
resolves the specific pathology it targeted without collateral damage across the wider benchmark.

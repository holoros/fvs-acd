# Pass 24 config merge: v12.11 levers restored on the v13.2 stack

## Question

Passes 20 to 23 established two configurations of AcadianGY 13.1 with complementary strengths.
The v13.2 site-fsm stack fixed the Baxter over-prediction that disqualified v12.11 (Baxter RMSE
28.47% to 25.72%, a 2.75 point gain, with level bias moving from +11.28% to -0.22%), but it gave
back v12.11's advantage on the managed CFRU CTRN benchmark (v12.11 18.06% RMSE against v13.2
24.60%, a 6.54 point deficit, with v13.2 under-predicting by -9.12%). Pass 24 asks whether the
config elements responsible for v12.11's CTRN advantage can be merged into the v13.2 base without
reintroducing the Baxter over-prediction. Baselines are frozen in
gydb_ws/comparison/v1211_vs_v132_comparison.csv and were cross-checked by the scorecard below.

Per Aaron's instruction of 21 August 2026, this pass's verdict is restricted to non-Canadian
sources: Baxter, CTRN, PEF, Maine FIA whole-plot (bench_mefia_long), Maine FIA mature (memat) and
developing (medev), and SILC. NB MagPlot, QC MagPlot, NS, and NS-long were already scored for the
four hybrids before the instruction arrived (array 13776765, completed the morning of 21 August)
and those per-stand result files remain on Cardinal at magplot/verify/merge_v24/ for reference,
but no verdict in this document rests on them, and they are not copied into this repository. No
Canadian job was queued or running when the instruction took effect, so nothing required
cancellation.

## Config diff, v12.11 candidate vs v13.2 site-fsm

Both configurations run the same model of record (AcadianGY_13.1.r, unmodified throughout) and
differ only in ops switches and tunings set by the benchmark harness. The v12.11 candidate used
four gated hand levers plus two numeric tunings: lever 1 REIN (ops$use.ddbh.rein, Reineke
diameter-growth damping, an alternative to lever 3 and not used in the shipped candidate), lever 2
MORTGATE (ops$mort.dens.scale, density-dependent mortality scaling gated on the source-level
managed flag, fmin 0.13, k 12.4, rd0 0.38), lever 3 STANDCON (ops$use.ddbh.standcon diameter-growth
stand-condition bounds, v12.11 tuning lo 0.40, hi 0.50, qmin 22), lever 4 DHTHW
(ops$use.dht.hw.mod, hardwood form and risk height modifier), and lever 5 IGTAPER plus a flat
recruitment multiplier. The v13.2 stack replaced the recruitment and mortality levers with the
site-fsm mortality coefficients (model_b0b1b2.r, B0 -1.8837, B1 0.4979, B2 -0.0293), IMULT 2.5, the
brms SDImax map with ESI anchor recalibration and region breaks for NB and QC, and retained lever 3
with its own tuning (lo 0.35, hi 0.45, qmin 18) and mortality onset ONSET 0.55 (v12.11 used 0.30).
The elements of v12.11 absent from v13.2, and therefore the merge candidates, are lever 2
(MORTGATE), lever 4 (DHTHW), and the v12.11 numeric tunings of ONSET and lever 3.

## Hybrids

Four hybrids of the v13.2 ship18 base were scored, each adding v12.11 elements in increasing dose.
h1_v132_mortgate adds lever 2 only; because the lever is gated on the managed flag, it is designed
to act on managed sources (CTRN, SILC) and stay inert on unmanaged ones (Baxter, PEF, Maine FIA),
which is the hypothesis under test: recover the managed-stand mortality behavior without touching
the mature unmanaged domain. h2_v132_dhthw adds lever 4 only. h3_v132_mortgate_dhthw adds both.
h4_v132_full1211 is h3 plus the v12.11 numeric tunings (ONSET 0.30, lever 3 lo 0.40, hi 0.50, qmin
22) and represents the maximum plausible dose of v12.11 in a v13.2 frame. The lever block itself is
`lever_block.txt`, inserted into the pass 21 v13.2 harness to form
`2026-08-21_merge-v24-runner.R`, verified byte-identical to
`p21/2026-08-19_p21_bench_v132.R` outside the block.

## Execution

Two SLURM arrays scored the hybrids (account puom0008): 13776765 (4 hybrids by baxter, ctrn, nb,
ns_managed, ns_unmanaged, 20 tasks) and 13796147 (4 hybrids by mef, pef, silc_l, memat, medev, 20
tasks). Scoring was aggregated by `2026-08-21_merge-v24-scorecard-noncan.R` (job 13796215), which
enforces an observed-basis gate (hybrid files must match the v13.2 reference STAND keys and
observed TOTVOL exactly, see `merge_v24_observed_check_noncan.csv`) before computing TOTVOL RMSE%,
level bias %, and the observed-on-predicted OLS slope, and cross-checks both v13.2 and v12.11
hybrid-file numbers against the frozen comparison CSV before trusting them (F4: an external,
independently-obtained reference, not the run's own build log).

## Results, non-Canadian sources

| Model | Source | n | RMSE% | Bias% | Slope obs-on-pred |
|---|---|---|---|---|---|
| v12.11 candidate | Baxter (mature, held-out) | 91 | 28.47 | 11.28 | 0.842 |
| v13.2 site-fsm | Baxter (mature, held-out) | 91 | 25.72 | -0.22 | 1.087 |
| h1 mortgate | Baxter (mature, held-out) | 91 | 25.72 | -0.22 | 1.087 |
| h2 dhthw | Baxter (mature, held-out) | 91 | 25.72 | -0.25 | 1.088 |
| h3 mortgate+dhthw | Baxter (mature, held-out) | 91 | 25.72 | -0.25 | 1.088 |
| h4 full1211 | Baxter (mature, held-out) | 91 | 28.39 | 6.08 | 0.948 |
| v12.11 candidate | CFRU CTRN (managed) | 1,086 | 18.06 | -2.24 | 1.016 |
| v13.2 site-fsm | CFRU CTRN (managed) | 1,086 | 24.60 | -9.12 | 1.205 |
| h1 mortgate | CFRU CTRN (managed) | 1,086 | 17.76 | -1.54 | 1.005 |
| h2 dhthw | CFRU CTRN (managed) | 1,086 | 24.60 | -9.12 | 1.205 |
| h3 mortgate+dhthw | CFRU CTRN (managed) | 1,086 | 17.76 | -1.54 | 1.005 |
| h4 full1211 | CFRU CTRN (managed) | 1,086 | 17.61 | -1.62 | 1.002 |
| v12.11 candidate | PEF (developing) | 2,853 | 17.91 | 1.37 | 0.948 |
| v13.2 site-fsm | PEF (developing) | 2,853 | 18.81 | 3.37 | 0.918 |
| h1 mortgate | PEF (developing) | 2,853 | 18.81 | 3.37 | 0.918 |
| h4 full1211 | PEF (developing) | 2,853 | 18.25 | 2.40 | 0.930 |
| v12.11 candidate | Maine FIA whole-plot (20-yr) | 918 | 38.56 | -16.13 | 1.154 |
| v13.2 site-fsm | Maine FIA whole-plot (20-yr) | 918 | 38.21 | -12.92 | 1.109 |
| h1 mortgate | Maine FIA whole-plot (20-yr) | 918 | 38.21 | -12.92 | 1.109 |
| h4 full1211 | Maine FIA whole-plot (20-yr) | 918 | 37.91 | -14.53 | 1.154 |
| v13.2 site-fsm | Maine FIA mature (memat) | 1,757 | 18.47 | -6.83 | 1.183 |
| h1 mortgate | Maine FIA mature (memat) | 1,757 | 18.47 | -6.83 | 1.183 |
| h4 full1211 | Maine FIA mature (memat) | 1,757 | 18.40 | -7.29 | 1.196 |
| v13.2 site-fsm | Maine FIA developing (medev) | 1,759 | 20.77 | -4.05 | 1.061 |
| h1 mortgate | Maine FIA developing (medev) | 1,759 | 20.77 | -4.05 | 1.061 |
| h4 full1211 | Maine FIA developing (medev) | 1,759 | 20.84 | -4.85 | 1.076 |
| v12.11 candidate | SILC/Seven Islands (calibration) | 73 | 64.24 | -5.65 | 0.568 |
| v13.2 site-fsm | SILC/Seven Islands (calibration) | 73 | 63.90 | -5.29 | 0.580 |
| h1 mortgate | SILC/Seven Islands (calibration) | 73 | 63.90 | -5.29 | 0.580 |
| h4 full1211 | SILC/Seven Islands (calibration) | 73 | 64.42 | -4.74 | 0.560 |

Full table with h2 and h3 for every source in `merge_v24_results_noncanadian.csv`. Both baselines
were cross-checked row for row against `v1211_vs_v132_comparison.csv` and matched exactly.

## Verdict

h1_v132_mortgate is the clean answer to the question this pass asked. Its Baxter numbers are
bit-identical to v13.2's (25.72% RMSE, -0.22% bias, 1.087 slope), because the mortality-gate lever
fires only on sources flagged managed, and Baxter is the held-out mature stand this pass exists to
protect; the lever is verified inert there, not merely close. The same bit-identical pattern holds
on PEF, Maine FIA whole-plot, memat, medev, and SILC, none of which are disturbed at all. On CTRN,
the one source this lever targets, h1 does not just close the gap to v12.11, it beats both
baselines outright: 17.76% RMSE against v12.11's 18.06% and v13.2's 24.60%, and -1.54% bias against
v12.11's -2.24% and v13.2's -9.12%. Adding lever 4 (DHTHW, h2 and h3) contributes nothing beyond h1
on CTRN and does not change Baxter meaningfully, so it earns no place in the merge. Taking the full
v12.11 dose (h4) buys a further half-point of CTRN RMSE and a small gain on PEF and Maine FIA
whole-plot, at the cost of measurably reopening Baxter's over-prediction (bias 6.08%, versus h1's
-0.22% and v13.2's -0.22%), which is exactly the failure mode this merge was supposed to avoid.

The recommendation is to adopt h1_v132_mortgate (MORTGATE only, DHTHW left off) as the merged
configuration for the non-Canadian battery: it recovers v12.11's CTRN advantage in full while
leaving v13.2's Baxter fix untouched, with no source in this battery made worse. Whether the same
lever helps or hurts NB, QC, or NS remains unanswered by design, since those sources are excluded
from this pass per instruction; the h1 through h4 result files for those sources already exist on
Cardinal at `magplot/verify/merge_v24/` from before the instruction and can be scored without
rerunning the model if that question is reopened later.

## Files

`2026-08-21_merge-v24-runner.R`: the v13.2 harness with the lever block inserted.
`lever_block.txt`: the four-lever ops switch block, environment-variable gated.
`2026-08-21_merge-v24-hybrids.sbatch`: the SLURM array template used for both scoring arrays.
`2026-08-21_merge-v24-scorecard-noncan.R`: aggregates hybrid result files into the table above,
with the observed-basis gate and the baseline cross-check.
`merge_v24_results_noncanadian.csv`, `merge_v24_observed_check_noncan.csv`: outputs of the
scorecard script.

The 40 per-stand hybrid result CSVs (roughly 25 MB total, h1 through h4 by source) stay on
Cardinal at `magplot/verify/merge_v24/` along with the Canadian-source files not used in this
verdict, consistent with the standing convention that large per-record artifacts live on the
cluster and only aggregated results and scripts go to git.

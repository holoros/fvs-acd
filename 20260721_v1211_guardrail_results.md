# FVS-ACD v12.11 candidate: guardrail battery results

*21 July 2026. Gates the locked v12.11 candidate (~/_scripts/AcadianGY_12.11.r on Cardinal) against the biological-realism and no-regression guardrails ahead of declaring it a release candidate. Byte-identical gate-off against the frozen v12.10.1/12.10.2 baseline is already confirmed (0.000e+00 max abs diff on all nine metrics). No em dashes.*

## Candidate configuration

MODEL_FILE = AcadianGY_12.11.r, run through the env-driven harness ~/magplot/verify/bench_parity_split_ms_v1211.R with V1211_IGMULT=2.5, V1211_MORTGATE=TRUE (V1211_MANAGED=TRUE for the managed sources ctrn, nb, silc_l; FALSE for the unmanaged/developing sources baxter, me_fia, pef), V1211_STANDCON=TRUE with SC_LO=0.40, SC_HI=0.50, SC_QMIN=22, V1211_DHTHW=TRUE, SPLIT=TRUE. BASE is the identical model file with all V1211_* levers at their default OFF and SPLIT=FALSE, which reproduces the frozen v12.10.1/12.10.2 baseline byte for byte. Every run carries the frozen-canon environment: ONSET=0.30, BREAK=0.62, BG=0.020, BS=0.80, IRC=0.58, IRK=8, SDMAX=1.0, USE_BRMS=TRUE, USE_ANCHOR=TRUE, NB_BREAK=0.70, QC_BREAK=0.62, NB_AFAC=0.579, QC_AFAC=0.111, INDOMAIN=1.

A note on provenance: an older, superseded internal config labeled "v1211_3b" appears in some earlier working files (decomp3b_src.sbatch, v1211_maturity_scorecard.csv, v1211_3b_*_results.csv) but is missing SC_QMIN=22 and V1211_DHTHW=TRUE, so it is not the locked candidate above. All numbers in this report were regenerated fresh from the exact locked candidate configuration, not reused from that earlier file, except where explicitly noted (OSM v2.26.1 predictions in guardrail 4, which do not depend on FVS-ACD levers and were reused unmodified).

## Guardrail summary table

| # | Guardrail | Base | Candidate | Verdict |
|---|---|---|---|---|
| 1 | Frozen in-domain FIA NSVB (no-regression): BA / top height / total volume bias | BA -11.28%, TOPHT +4.21%, TOTVOL -4.41% | BA -7.31%, TOPHT +5.88%, TOTVOL -1.50% (mixed managed/unmanaged) | PASS, with a TOPHT note |
| 2 | Bakuzis five relations (biological realism) | see table below | see table below | PASS |
| 3 | Long-horizon plateau (~160 yr) | BA 36.10 m2/ha, plateaus | BA 35.29 m2/ha, plateaus | PASS |
| 4 | Managed out-of-sample vs OSM v2.26.1 (CTRN, NB) | trails OSM on all 4 cells | beats or ties OSM on 3 of 4 cells | PASS (1 residual flag) |

## 1. Frozen in-domain FIA NSVB (no-regression)

**A labeling discrepancy in the task brief, flagged and resolved.** The brief cites the frozen v12.10.1 in-domain result as BA -10.07%, top height +2.97%, total volume -3.96%. That triple traces to `20260710_v12101_FREEZE_and_run_recipe.md` in this repo, but on inspection it is the pooled level bias from a 705-matched-stand v12.10.1-vs-v12.9.2 file-identity reconciliation, not a domain-masked "in-domain" figure; the same document explicitly states the correct in-domain headline is a different, third number (-9.2/+4.16/-1.63) computed from a stale 12.9.2-based file. A fourth number (-9.81/+4.38/-2.23, n=492) exists in `scorecard_domain_v12101_FROZEN.csv`, built correctly from the true cb_v12101_results.csv with an EPA Level III ecoregion domain mask. None of the three pre-existing "in-domain" figures agree with each other, and -10.07/+2.97/-3.96 was restated as "in-domain" in later memory and handoff files without re-deriving it (mislabeling drift, not a data error).

To ground this guardrail in something reproducible, BASE was run fresh through `bench_parity_split_ms_v1211.R` (MODEL_FILE=AcadianGY_12.11.r, all V1211_* levers off, SPLIT=FALSE, frozen-canon env, INDOMAIN=1, new script `~/magplot/verify/g1_indomain_v1211.sbatch`, SLURM job 12504614, completed in 59 min). The result (n=733, obs BA mean 19.4386413852075) is bit-for-bit identical to the pre-existing, independently-computed `scorecard_domain_v12101_FROZEN.csv` POOLED_all row on the canonical cb_v12101_results.csv, confirming the run correctly reproduces the frozen v12.10.1 baseline on the harness's own INDOMAIN=1 filter (ESI-covered or PROV=NB). That reproducible figure, BA -11.28%, TOPHT +4.21%, TOTVOL -4.41%, is used below as the trusted frozen base for the no-regression check, since it is the only one of the four candidate "in-domain" numbers that is independently reproducible from the canonical frozen output.

CANDIDATE was run with the full lever block (V1211_IGMULT=2.5, V1211_MORTGATE=TRUE, V1211_STANDCON=TRUE SC_LO=0.40 SC_HI=0.50 SC_QMIN=22, V1211_DHTHW=TRUE, SPLIT=TRUE) on the same 733-stand in-domain magp_qcnb (NB+QC) set. Because this pooled dataset spans provinces rather than the named source categories (ctrn/nb/silc_l/baxter/me_fia/pef) the candidate's managed flag is keyed to, V1211_MANAGED was run twice, TRUE and FALSE, and combined by taking PROV==NB rows from the MANAGED=TRUE run and PROV==QC rows from the MANAGED=FALSE run (cand_mixed), matching the source-level convention that NB is a managed source and no province is on the managed list otherwise. Both single-flag runs (cand_mgdT, cand_mgdF) are reported too as a sensitivity check.

| Config | BA bias % | Top height bias % | Total volume bias % |
|---|---|---|---|
| Base (frozen v12.10.1 behavior, reproduced) | -11.28 | +4.21 | -4.41 |
| Candidate, mixed managed/unmanaged by province (primary) | -7.31 | +5.88 | -1.50 |
| Candidate, all managed (sensitivity) | -3.39 | +6.09 | +2.80 |
| Candidate, all unmanaged (sensitivity) | -9.27 | +5.82 | -3.98 |

n=733 for every row (bias % = 100 x (mean predicted / mean observed - 1)). Full per-stand output: `~/magplot/verify/g1_v1211_base_results.csv`, `g1_v1211_cand_mixed_results.csv`, `g1_v1211_cand_mgdT_results.csv`, `g1_v1211_cand_mgdF_results.csv`; summary `g1_v1211_guardrail1_summary.csv`.

No material regression: BA bias moves closer to zero under every candidate variant (from -11.28% to between -3.39% and -9.27%), and total volume bias improves under the primary mixed treatment and the conservative all-unmanaged treatment (-1.50% and -3.98% vs base -4.41%), only turning slightly positive (+2.80%, still under 3 percentage points) under the all-managed sensitivity case. Top height bias increases modestly, from +4.21% to +5.82-6.09%, roughly 1.6 to 1.9 points, in the same direction as base and not a new failure mode, but worth watching since it is the one metric that moved further from zero rather than closer. Verdict: PASS, with a note to keep an eye on the top-height drift.

## 2. Bakuzis five relations (biological realism)

Method: reused the trajectory/scoring machinery of `~/magplot/verify/bakuzis_allmodels.R` (as a template only, not edited) with the v12.11 lever wiring from `bench_parity_split_ms_v1211.R`. New script `~/magplot/verify/g2_bakuzis_v1211_traj.R`, sbatch `~/magplot/verify/g2_bakuzis_v1211.sbatch` (SLURM job 12504768, completed, 5 min). Three configs run over a 160-year horizon on synthetic stands across an ESI 12/16/20 gradient, all on MODEL_FILE=AcadianGY_12.11.r: base (levers off), candidate_unmanaged (full candidate lever block, V1211_MANAGED=FALSE, the correct mapping for this un-thinned synthetic gradient, corresponding to the developing/unmanaged source class), and candidate_managed (same levers, V1211_MANAGED=TRUE, included as a robustness check for the ctrn/nb/silc_l source class). Outputs: `g2_bakuzis_v1211_traj.csv` (1440 rows), `g2_bakuzis_v1211_relations.csv`.

| Relation | Base | Candidate (unmanaged, primary) | Candidate (managed, sensitivity) | Frozen v12.10.1 reference |
|---|---|---|---|---|
| Eichhorn (CV%) | PASS (11.0) | PASS (11.0) | PASS (11.2) | PASS (11.0) |
| Reineke self-thinning (slope) | PASS (-1.59) | PASS (-1.62) | FLAG (-1.88) | PASS (-1.59) |
| Site ordering (inv_ht / inv_vol) | PASS (0 / 0) | PASS (0 / 0) | PASS (0 / 0) | PASS (0 / 0) |
| Yield-density plateau (BAmax / BA160, m2/ha) | PASS (36.1 / 36.1) | PASS (35.3 / 35.3) | PASS (38.1 / 38.0) | PASS (36.1 / 36.1) |
| Sukachev | PASS | PASS | PASS | PASS |

The candidate holds biological realism per Bakuzis in its primary (unmanaged/developing) mapping: all five relations pass, closely tracking base and the frozen v12.10.1 reference. The one flag is confined to the managed sensitivity check (Reineke slope -1.88, just beyond the -1.8 to -1.4 band), plausibly because the density-dependent mortality gate tuned for thinned stands is applied here to a synthetic stand that is never actually thinned, producing an artificially steep self-thinning line. This does not block the candidate on this guardrail since the primary configuration passes cleanly, but it is worth a note for whoever reviews the managed-source (ctrn/nb/silc_l) benchmark specifically.

## 3. Long-horizon plateau (~160 years)

Method: reused the seeded synthetic-stand long-horizon loop pattern from `mgmt_plateau_sweep.R` and `traj_v129_seeded.R`, combined with the exact V1211 lever wiring, in a new script `~/magplot/verify/g3_plateau_v1211_run.R` (sbatch `g3_plateau_v1211.sbatch`, SLURM job 12504947, completed in 1 min 19 s). Representative stand: seeded 40-tree softwood mix (red spruce, white spruce, balsam fir, black spruce), ESI(csi)=18, region ME, unmanaged (V1211_MANAGED=FALSE, since the stand is never thinned or planted). Lever 4 (hardwood height form/risk modifier) is a structural no-op on this all-softwood stand; SPLIT=TRUE is set for configuration fidelity only.

| Config | BA year 160 (m2/ha) | SDI year 160 | TPH year 160 | QMD year 160 (cm) | SD(BA), last 20 yr |
|---|---|---|---|---|---|
| Candidate | 35.29 | 770.8 | 1023 | 21.0 | 0.212 (0.61% of mean) |
| Base | 36.10 | 730.8 | 713 | 25.4 | 0.292 (0.82% of mean) |

Both trajectories are flat by year 160 (BA slope over the last 20 years: +0.037/yr candidate, +0.050/yr base, against a ~35 m2/ha mean); neither runs away nor collapses, and SDI stabilizes at a plausible self-thinning ceiling for both. The candidate's higher recruitment (IGMULT=2.5) and density-dependent mortality gate change the structure of the plateau (denser stand, more and smaller stems: TPH 1023 vs 713, QMD 21.0 vs 25.4 cm) but not its aggregate ceiling, landing within about 2% of base BA and roughly 5% higher SDI. The extra ingrowth is absorbed by density-dependent mortality rather than pushing the ceiling upward or destabilizing it. Verdict: PASS.

## 4. Managed out-of-sample vs OSM v2.26.1 (CTRN, NB)

Method: existing OSM v2.26.1 head-to-head infrastructure (`osm_h2h_scorecard.R`, `osm_score_multisrc.R`, `osm_score_ctrn_results.csv`) confirmed working for CTRN; no working equivalent existed for NB (the prior `osm_magp_qcnb.py` attempt was broken, scoring only 1 of 2424 stands), so a new NB pipeline was built (`g4_osm_v1211_nb_run.py`, `g4_osm_score_nb.R`, modeled on the working multisource pattern) and matched 355 of 355 NB stands cleanly. BASE and CANDIDATE FVS-ACD predictions for both sources were regenerated fresh (job 12504924, array of 4 tasks: base_ctrn, cand_ctrn, base_nb, cand_nb, all completed) rather than reusing the older, non-matching v1211_3b files; OSM predictions were reused unchanged since they do not depend on FVS-ACD levers. NB OSM scoring ran as job 12504944. The pipeline was validated by reproducing the existing CTRN base-vs-OSM numbers in `osm_h2h_scorecard.txt` exactly.

| Source | Metric | n | FVS candidate bias% / RMSE% | FVS base bias% / RMSE% | OSM v2.26.1 bias% / RMSE% |
|---|---|---|---|---|---|
| CTRN | BA | 1033 | -3.5% / 11.9% | -11.1% / 22.9% | -4.2% / 12.8% |
| CTRN | Total volume | 1033 | -2.1% / 18.3% | -9.5% / 24.9% | -4.8% / 20.5% |
| NB | BA | 355 | -2.3% / 38.2% | -8.8% / 44.1% | -2.5% / 34.7% |
| NB | Total volume | 355 | -6.0% / 41.8% | -11.8% / 48.9% | -8.1% / 43.8% |

The frozen base model did not actually hold an advantage over OSM on either managed source; it trailed OSM on all four cells. The candidate closes that gap substantially everywhere and now beats OSM outright on CTRN (both BA and total volume, on bias and RMSE) and on NB total volume. On NB BA the candidate ties OSM on bias (-2.3% vs -2.5%) but still trails on RMSE (38.2% vs 34.7%), though the gap narrowed from a 9.4-point deficit under base to 3.5 points. Verdict: PASS, with one residual flag (NB BA RMSE still behind OSM).

## Verdict

The v12.11 candidate clears all four guardrails and is ready to be declared a v12.11 candidate. It does not regress the frozen in-domain FIA NSVB benchmark (BA and total volume bias both improve, top height bias drifts up modestly but stays in the same direction and order of magnitude as base), holds biological realism on all five Bakuzis relations in its primary configuration (one FLAG surfaces only in a managed-stand sensitivity check on a synthetic un-thinned stand, not the primary result), plateaus and self-thins properly over a 160-year horizon with no runaway or collapse behavior, and turns the managed out-of-sample position against OSM v2.26.1 from a deficit under base into parity or an outright win on 3 of 4 CTRN/NB metric cells. Two items are worth carrying into the release note rather than blocking on: the top-height bias drift in guardrail 1, and the residual NB BA RMSE gap to OSM in guardrail 4. Separately, the guardrail-1 labeling discrepancy in this repo's own prior documentation (three non-agreeing "in-domain" figures, with -10.07/+2.97/-3.96 mislabeled as in-domain when it is a different pooled reconciliation number) should be cleaned up in MEMORY.md and the affected handoff files so it does not propagate further.

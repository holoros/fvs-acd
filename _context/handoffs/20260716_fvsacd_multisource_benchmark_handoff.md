# FVS-ACD session handoff, 16 July 2026: record-split resume + multi-source benchmark

Continues 20260715_fvsacd_hwmod_phase1_handoff.md. v12.10.1 stays shipped, nothing gated, August materials frozen (main at 04d4064). No em dashes.

## Running jobs and armed harvests

- Record-split A/B job 12390203: COMPLETED (subagents observed it finish mid-session). The full off/on table was not read live. Harvest task harvest-hwsplit-ab-12390203 re-timed to 16 July 3 PM to read ~/logs/hwsplit_ab_12390203.out and ~/magplot/verify/split_ab_detail.csv. If picking this up before 3 PM, read those directly.
- v13.1 refit job 12349032: chains near-complete as of 06:36 (chain 3 at 1900/2000). Convergence harvest harvest-v131-v3-convergence re-armed for 9:30 AM to read Rhat/divergences from ~/v13_kickoff/ and ~/logs/v131refit_v3_12349032.out.

## Candidate (a) ingrowth split: BUILT, DRY-TESTED, staged not submitted

New files on Cardinal (do not collide with the running job): ~/magplot/verify/bench_parity_split_ig.R (split_ingrowth splits new NA-form hardwood recruits each cycle via split_formrisk, F7 column-align guard applied), run_bench_split_ig.sh, ~/hwsplit_ig.sbatch (tags split_ig_off/on, SPLIT_INGROWTH=TRUE), ~/analyze_split_ig_ab.R (adds a marginal block vs the initial-only split). Unit test + NMAX=2 smoke both 0 fail. Gate order: read the 3 PM initial-split result first; submit ~/hwsplit_ig.sbatch only if the marginal from recruits is worth the cost. Documented in data/hardwood_form_risk_investigation.md.

## Red-team of the record-split machinery (recorded in investigation md)

Backbone verified sound (stem conservation, fixed-budget mortality reallocation, assign-once-carry-fixed, candidate-a id accounting). F1 reconciled to a non-issue: the scorer's own tail print is base NSVB, but analyze_split_ab.R reads VALUE_s_p/SAWVOL_s_p as the on-Smith column, so the discrete modifier IS in the reported A/B. Carry F2 (self-competition artifact does not cancel exactly), F3 (species coverage asymmetry, SM has growth but no survival modifier; AB/WA/OH volume-only), F4 (form-risk independence most exposes value metrics in RM/mixedwood) as caveats on the VALUE/SAWVOL deltas. Read value deltas against the split-artifact floor the analyze script reports.

## Multi-source benchmark expansion: THREE strata BUILT, SMOKED, staged (task done bar full run)

Goal: broaden the scorecard beyond the MagPlot QC/NB pairs to Maine FIA and long-term CFI. Generalized scorer ~/magplot/verify/bench_parity_split_ms.R env-parametrizes the four input files (PAIRS_FILE, INIT_FILE, T2_FILE, SITE_FILE; defaults to magp_qcnb_*). All three sources smoke-passed n=3 0 fail through the real scorer + proto engine. Files under ~/magplot/verify/multisrc/, each with a build_*.R.

- ME_FIA (bench_mefia_*): 12,846 pairs, 12,829 in-domain. Units verified (DIA in to cm, TPA to trees/ha, ht ft to m). Species 0.93% folded to OS/OH. FIA true coords stayed server-side, no coords in outputs (hard constraint honored). Caveat: 5 yr annual panel, short intervals only (no long-horizon bins). Reused ~/acadgy_fia_verify/ pairing + ESI (enriched frame + Final_SI_Output.tif via gdallocationinfo).
- SILC (bench_silc_*): 14 pairs (13 scorer-usable), imperial to metric verified against silc_cfi_pair_summary.csv, esi8=14.744 for all 9 sites, survives INDOMAIN. PROPRIETARY (Seven Islands), aggregated only, per-plot stays internal. CAVEAT: 5 early pairs are tally-threshold artifacts; restrict to the 8 clean 1990->1995 intervals (SILC1100/1101/1102/1104/1105/1106/1107/1109_1990_1995). ELEV NA (defaults 200).
- PEF (bench_pef_*): 2,853 pairs after excluding 1,550 harvest-bracketing intervals (INCLUDE-ALL-with-harvest-exclusion; treatment labels in bench_pef_treatments.csv). Intervals to 20 yr (decade-scale value-add preserved). 25 AGY codes. esi8 is a dominant-height proxy (90th pct height, clamped 8-26 m), NOT true site index. ELEV constant 50 m. USFS RDS-2012-0008 public.

Baxter: found in LSOG but spatial only (Baxter_SFMA boundary shapefile, map sample, baxter_coords_clean.csv), NOT remeasured plot tree lists, so not benchmarkable as-is. CTRN: absent on Cardinal. Both need sourcing before inclusion.

## Follow-on (not done, next session)

1. Full-size multi-source scorecard run as a Cardinal job: run bench_parity_split_ms.R per source at full n (FIA 12.8k pairs is many hours), v12.10.1 baseline, per-PROV rows (ME_FIA, SILC, PEF). Decide SILC restriction to the 8 clean pairs. New PROVs get afac=1 (ME region path); source-specific dominant-height anchor coefficients wanted before strong height conclusions.
2. Add ME_FIA/SILC/PEF to the reporting rollup display (regen_five_way_scorecard*.R iterates only NB/QC; domain inclusion already works, this is display-only).
3. Record-split 3 PM gate, then candidate (a) if warranted.

## Repo / git

Committed the hardwood record-split workstream as 1de8b4e on branch hardwood-formrisk-wip (main stays frozen 04d4064). The sandbox mount left orphaned .git/index.lock and .git/HEAD.lock it cannot remove, so further git writes this session are blocked; clear on the local machine with `rm .git/index.lock .git/HEAD.lock`. Uncommitted since: investigation md red-team append, data/climatena_formrisk_covariate_scope.md (candidate d scope), this handoff. Commit them after clearing the lock.

## Minor items (unchanged)

GTR docx/pdf regeneration waits on team finalize; Hennigar/Rice Gmail drafts need PDFs attached by hand.

## Late additions (16 July, end of session)

FIA long-interval undisturbed stratum BUILT (PROV=ME_FIA_L). build_mefia_long_bench.R + bench_mefia_long_{pairs,site_esi,tree_init,tree_t2}.csv under multisrc/. Pairs each Maine plot's FIRST and LAST measurement, restricted to chains undisturbed and unharvested across every measurement (all conditions DSTRBCD1/2/3=0 and TRTCD1/2/3=0, COND_STATUS_CD=1 both ends; chains linked by PREV_PLT_CN). 933 pairs, interval median 20 yr (888 >= 20 yr, max 25), 100% survive INDOMAIN, coords server-side only. Net increment ~0.48 m2/ha/yr (init BA 20.8 -> last 30.6). This is the long-interval FIA answer to the 5-yr-panel caveat. Attrition from 6,665 chains: 3,030 <2 measurements, 538 non-forest, 1,721 harvest, 430 disturbance, 13 no live trees -> 933. Not yet in the scorecard run.

CTRN database located in Google Drive (not yet on Cardinal). Folder 1pM5EHvxkoHcn8pMFF-F-Pmiizb370pp5 holds CTRN.mdb (203 MB, 2012-03-30, id 1rLh1iTKH7MYPwuVkvCsQK-G00gnRau1r), CTRN_new_2010_3_0_2 - Copy.mdb, CTRN_new_2011_Brian.mdb; folder 1TtdxDbIgEWfwYR_vM5_fzcgMqk5y9o3w holds CTRN_new_2010.mdb and CTRN_Maintenance.mdb. CFRU Commercial Thinning Research Network long-term remeasurement. To include: Aaron moves one .mdb to Cardinal (Claude cannot push Drive to Cardinal), then extract tables via mdb-tools and build a CTRN stratum like FIA/SILC/PEF. Baxter remains spatial-only in LSOG; CTRN was absent on Cardinal but IS in Drive.

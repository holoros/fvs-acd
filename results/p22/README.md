# Pass 22 results, 20 August 2026

Continuation of pass 21 (`results/p21/README.md`). Pass 22 worked the open-items list left at the
end of pass 21: the Baxter/SILC_L real-tag restage, the SILC EXPF discrepancy writeup, QC MagPlot
reconciliation, and folding memat/medev into a reduced comparison. Model of record
`AcadianGY_13.1.r` untouched throughout; everything here is either a new overlay/build script or
a reconciliation of scoring results that already existed on Cardinal.

## Baxter real-tag restage (done, verified)

`2026-08-20_build_baxter_bench_realtag.R` reproduces `multisrc/build_baxter_bench.R` exactly
(same row selection, species crosswalk, PPS-1 screen) but keeps the source's own raw tree id
(RAWTREE) as TREE instead of nulling it before write. Verified against the existing
`bench_baxter_tree_init.csv`/`tree_t2.csv`: the per-stand multiset of (SP, DBH, HT, EXPF, YEAR)
is byte-identical (`MULTISET_MATCH init=TRUE t2=TRUE`), so stand-level scoring is provably
unaffected, only the tree-level identity label changes. One real, disclosed limitation: 29
(STAND, TREE) pairs collide in the t2 file, all confined to 2 stands (BAX_31_1996_2009,
BAX_52_1997_2009) and all small-diameter stems (1.78 to 13.72 cm), consistent with the raw data
steward reusing tree numbers for newly recruited (ingrowth) stems rather than a script defect.
The real-tag files are safe for stand-level work; they are not a unique per-tree key in those 2
stands without further disambiguation. Output: `bench_baxter_tree_init_realtag.csv`,
`bench_baxter_tree_t2_realtag.csv`.

## SILC_L real-tag restage (partial, one side unverified)

`2026-08-20_build_silc_l_bench_realtag.R` restages SILC_L using the only real-identity source
that exists in the repo: `silc_cfi_longhorizon_pairs_v16.csv`, which links a STAND to a raw
per-occasion tree list file with native TREE ids. That source covers only 73 of the 137 STAND
pairs in the current `bench_silc_l_pairs_full137.csv`; no builder for the other 64 (the "full137"
expansion, dated 12 Aug 2026) exists anywhere in `~/magplot/verify` (checked by grepping every
.R/.py/.sh/.sbatch file for the literal string "full137"; nothing writes those files). Restaging
the other 64 would mean guessing a join with no verifiable source, so this script does not
attempt it.

For the 73 recoverable pairs: the init side matches the existing benchmark exactly (multiset
match TRUE, zero TREE collisions). The t2 side does NOT match: 19 (STAND, SP, DBH, EXPF, YEAR)
groups differ from the existing `bench_silc_l_tree_t2_full137.csv`, and 184 (STAND, TREE) pairs
collide, concentrated in a small number of stands. Diagnosis so far: some of the mismatches are
species-crosswalk gaps (a handful of trees fall to "OH" in the reconstruction where the existing
file carries a real code such as BS or RP, meaning the SPCD map used to build the original
full137 file is not exactly `p5p/lk1_silc_spcd_map.csv`), and at least one stand
(SILC1197_1987_2002) has raw TREE values that come through as NA, which is a data issue in
`SILC_TREE_raw.csv` rather than a script bug. This t2 file is shipped for reference
(`bench_silc_l_tree_t2_realtag.csv`) but is explicitly UNVERIFIED and should not be used for any
downstream work until reconciled. Init file (`bench_silc_l_tree_init_realtag.csv`) is verified
and safe to use for the 73 covered stands.

## SILC EXPF 12.3553 vs 24.7105 (write-up; could not reproduce as described)

Grepped every .R file in `~/magplot/verify` for the literal strings "24.7105" and "24.710": no
match anywhere. The only fixed EXPF constant in the codebase is Baxter's `EXPF_HA <- 12.3553`
(1/5-acre fixed-radius plots, `EXPF_HA = 5 * 2.47105`). SILC itself does not use a fixed EXPF
constant at all in its current build (`multisrc/build_silc_bench.R`): EXPF is computed per tree
as `tr$EXPF * AC_HA` where `AC_HA = 2.4710538` and `tr$EXPF` is read from each raw tree record.
The SILC_L pipeline (`p5p/lk1_build_silc.R`) does use a fixed per-plot EXPF that happens to equal
12.3553 for the 73 checked stands (raw `EXPF` field is a constant 5 there), matching Baxter's
convention, not a second constant. One unverified speculation, flagged as such and not asserted
as fact: 24.7105 is exactly `AC_HA * 10`, so if some source used 1/10-acre plots rather than
Baxter's 1/5-acre, that source's fixed EXPF would be 24.7105 by the same logic that gives Baxter
12.3553 -- but no script anywhere in the repo actually assigns that value, so this is offered only
as a plausible origin for the number, not a resolved explanation. The original "12.3553 vs
24.7105" discrepancy as described in the pass-19 handoff could not be located or reproduced this
pass or last.

## QC MagPlot (done; was already scored, never reconciled)

QC MagPlot was never a missing baseline. `base_nb_results.csv`, `cand_nb_results.csv`,
`p9lev3/p9_ship18_nb_results.csv`, and `p21/p9_v132_nb_results.csv` all already carry 378 QC rows
(PROV=="QC") alongside their 355 NB rows, because the "NB MagPlot" scoring task has always scored
the combined `magp_qcnb` source, not NB alone; every composite script has filtered to
`PROV=="NB"` and silently dropped the QC rows in the process. No new Cardinal computation was
needed, only reconciliation of what already existed
(`2026-08-20_p22_qc_reconcile.R`, `p22_qc_reconciled.csv`). Result: QC is a noisy source in
absolute terms (RMSE in the high 50s to 60 percent range under every config, OLS slope around
0.52 to 0.54, well below unity), but v13.2 moves it in the same direction as everywhere else:
RMSE 58.58 vs ship18's 59.84 (-1.26), bias +3.43 vs ship18's +3.98 (-0.54), both small
improvements, no degradation. OSM never scored QC (`g4_osm_score_nb_results.csv` is NB-only, 355
rows, confirmed by inspection); that column is left blank rather than guessed.

## memat/medev reduced 3-way (done)

`2026-08-20_p22_memat_medev_reconcile.R` computes base/ship18(v13.1)/v132 RMSE, bias, and OLS
slope for both sources using the results files already on Cardinal from prior passes
(`p9g_base_memat_results.csv`, `p9lev3/p9_ship18_memat_results.csv`,
`p21/p9_v132_memat_results.csv`, and the medev equivalents). No candidate v12.11 or OSM run
exists for either source anywhere on Cardinal, so this is a reduced 3-way table, not folded into
the 8-source composite bootstrap (adding two more sources to that composite after the fact would
silently change what pass 21's composite numbers mean). Result (`p22_memat_medev_reduced.csv`):
memat moves +0.70 RMSE / -1.05 bias, medev moves -0.26 RMSE / +0.45 bias, both well under 1 point
in either metric, consistent with the "no collateral damage outside Baxter" pattern from pass 21.

## p19_refit.R doc correction

Additive correction in `p19refit/p19_refit.R` (backed up as `p19_refit_PREV_20260820.R`): the
existing paragraph describing Baxter/SILC_L as "EXCLUDED" from the fit is stale and does not
match the source registry actually executed in the same file, which includes both via `sv_file`.
The stale paragraph is left in place per the no-silent-removal convention; the correction explains
the actual current behavior and clarifies that the scoring-side restage (this pass's task) is
independent of the fitting pipeline, which already had real tree identity through
`p17survfix/p17_baxter_corrected_survivor_sums.csv` and the SILC equivalent.

## Open items after pass 22

1. SILC_L t2 real-tag reconciliation (19 mismatched groups, 184 TREE collisions) is unresolved.
2. The 64-of-137 SILC_L pairs with no recoverable real-tree-identity source remain unrestaged;
   would need whatever built the "full137" expansion (12 Aug 2026), not currently in the repo.
3. Propagate the dedup fix to other multisrc consumers (carried from pass 20/21, untouched).
4. fig15/22/23 regeneration (carried, untouched).
5. rt_net gnls step-halving failure, recurring, low priority (carried, untouched).

Raw per-stand results CSVs referenced above stay on Cardinal at `~/magplot/verify/p9g_base_*`,
`~/magplot/verify/p9lev3/*`, `~/magplot/verify/p21/*`, matching the standing precedent that raw
per-stand scoring output is not checked into the repo. The real-tag staged tree-list files are
checked in here because they are themselves a deliverable (restaged benchmark input), not run
output.

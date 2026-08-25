# GYDB build and v12.11 vs v13.2 comparison, 21 to 22 August 2026 (pass 23 to 24)

## What this is

`gydb` (Hennigar and Fortin, Canadian Forest Service, OSM-Contributors/gydb) is a private R
package implementing a standardized SQLite schema (v5.1) for harmonizing multi-provider forest
inventory data: 14 core tables under a strict Dataset to Block to Location to Plot to Visit to
Tree hierarchy, plus analysis views that compute plot and dataset summaries live from the child
tables. This pass built a production GYDB instance from every non-FIA benchmark source already
staged for FVS-ACD scoring, plus the MNAP/TNC Ecological Reserve network, and used it to answer
the standing question of how v12.11 (the CANDIDATE lineage) compares against v13.2 (the site-fsm
patch shipped in pass 20) across every source with both models scored.

The database itself, `data/ALL/ALL_Standardized.sqlite` (86 MB, built on Cardinal at
`~/gydb_ws/`), is not checked into this repo. It stays on Cardinal, consistent with the session
precedent that large binary data artifacts live on the cluster and only the build scripts,
documentation, and small result CSVs go to git.

## What got built

Eight datasets, 5,253 locations, 8,620 plots, 17,236 visits, 1,084,941 tree records (585,685
distinct trees across both occasions), spanning 1953 to 2024, all in Maine except for the
cross-border NB and QC sources folded into other passes' composites (not yet in GYDB, see gaps
below).

| Dataset | Full name | Locations | Plots | Visits | Trees | Years |
|---|---|---|---|---|---|---|
| BAXTER | Baxter State Park CFI (mature, held-out) | 91 | 91 | 182 | 11,596 | 1996 to 2009 |
| SILC_L | Seven Islands / SILC long-horizon CFI | 137 | 137 | 270 | 4,950 | 1986 to 2002 |
| CTRN | CFRU Cooperative Thinning Research Network | 166 | 1,086 | 2,172 | 241,798 | 2001 to 2022 |
| PEF | Penobscot Experimental Forest (developing) | 406 | 2,853 | 5,706 | 406,002 | 1953 to 2023 |
| MEFIA_L | Maine FIA whole-plot (long interval) | 933 | 933 | 1,866 | 86,276 | 1999 to 2024 |
| MEMAT | Maine FIA mature stratum | 1,760 | 1,760 | 3,520 | 168,902 | 1999 to 2024 |
| MEDEV | Maine FIA developing stratum | 1,760 | 1,760 | 3,520 | 165,417 | 1999 to 2024 |
| MNAP | Maine Ecological Reserves (MNAP/TNC) | 1,109 | 1,109 | 367 | 4,098 | 2004 to 2016, partial (pass 24) |

Species are stored under gydb's own Lookup_Species table, keyed by USDA PLANTS symbol. The AGY
two-letter codes used throughout the FVS-ACD scoring pipeline were cross-walked to PLANTS symbols
by reading `AcadianGY_13.1.r`'s own `sp.attr` tribble (which carries inline common-name comments
for every code) against the real, package-seeded Lookup_Species table, not invented; the 36-entry
crosswalk lives at the top of `build_gydb.R`. Any AGY code without a resolvable PLANTS symbol maps
to `T_X` (unclassified) rather than being silently dropped, and none were needed this pass.

Frame geometry (plot area and radius) was not available directly in the multisrc benchmark files,
only each source's known EXPF (expansion factor, trees ha⁻¹ per tallied stem). Since gydb's
analysis views compute per-tree expansion dynamically from `S_Frames.Area` or `.Radius` rather
than storing EXPF on `S_Trees`, plot area was back-calculated as Area_m2 = 10000/EXPF for every
distinct EXPF value found in each source, which recovers the correct nested-plot structure without
assuming one. PEF and MNAP both use genuinely nested fixed-radius designs (PEF: three tiers, EXPF
12.3552/49.421/123.5525; MNAP: two tiers, EXPF 59.5683/9.8792); the rest use one radius per source.

## Data quality findings, disclosed rather than patched silently

Three real defects surfaced during the build and are logged in `build_log_full.csv` with exact
counts, not estimated:

Baxter's real-tag tree-init file carried one row with a missing TREE id and 29 (VisitID, Tree)
collisions confined to two stands, consistent with the raw data steward reusing tree numbers for
new ingrowth (already disclosed in the pass 22 handoff). The missing-id row was dropped; the 29
collisions were resolved by keeping the first occurrence and dropping the duplicate, preserving
real cross-visit identity for every non-colliding stem rather than discarding the real-tag benefit
across the whole source.

CTRN's t2 tree list had one HT value of 200.1 m against a schema-enforced ceiling of 110 m, a
clear decimal-point data-entry error (stand CTRN_PE_7_I2019_2021, species RS). Rather than fix
only that one record, HT was range-checked across all eight sources uniformly and any value
outside [0.01, 110] m was nulled with a logged count; only CTRN had a violation.

PEF's TREE column turned out not to be a stable per-stem identity key at all: 149,406
(VisitID, Tree) collisions were found across the init and t2 files combined, with duplicate TREE
values sharing the same STAND but carrying different DBH, species, and EXPF, consistent with a
tally-class counter rather than an individually numbered tag. This was not a small edge case (as
Baxter's was) but the dominant pattern in PEF's data, so PEF's `S_Frames.TallyMethod` was corrected
from the generic per-source default (Individual Records) to Tally, and TREE was renumbered
sequentially within each visit rather than forcing a false individual-stem identity onto data that
never had one.

## Known gaps, not yet resolved

MNAP's `S_Visits` and `S_Trees` were partially built in pass 24. The blocker described in pass 23
(no calendar year in `ERM_ME_Plots.csv` or `ERM_ME_LiveTrees.csv`, only an ordinal Round label,
against a schema-enforced NOT NULL `S_Visits.YR`) was resolved by retrieving and converting
`EcoreserveMonitoring.accdb` from Google Drive on Cardinal (mdbtools built from source; see
`results/gydb/mnap_pass24_writeup.md` for the full method). Its `PlotMetrics` table ties `PM_ID`
to a real date and Round, joining exactly against the PM_ID already present in the tree CSVs (zero
Round mismatches across 3,564 checked rows). The recovered 2018 snapshot only covers 374 of the
roughly 1,600 PM_IDs the current CSVs reference, so coverage is real but partial: 367 `S_Visits`
rows (266 Round 1, 101 Round 2, years 2004 to 2016) and 4,098 `S_Trees` rows were added, with the
remaining approximately 78 percent of visits left unbuilt rather than guessed. MNAP is therefore
usable as a partial ninth scoring benchmark for the plots and years it now covers; closing the
rest needs either a newer `EcoreserveMonitoring.accdb` than this 2018 copy (the untested
TNC-only copy on Drive is the first thing to check) or MNAP/TNC confirming dates directly. Aaron's
local `Documents/MAINE/DATA/TNC/` holdings were also checked same day: `StJohnEIM.mdb` is a real,
dated (2005/2008/2009) survey of TNC's St. John River corridor preserve, but its plot layout and
township keys do not match the smaller St. John Ponds reserve already in GYDB, and every row
carries a single date rather than a Round 1/Round 2 pair, so it was confirmed not usable and no
database change was made from it (full check in `results/gydb/mnap_pass24_writeup.md`).

`S_PlotTreatments` loaded zero rows in pass 23 despite both CTRN and PEF having treatment source
files; pass 24 fixed both. CTRN's file carried the year under `TRT_YR`, not the literal `YR` the
build script checked for, so the loading branch's guard was always false; adding `TRT_YR` as a
fallback recovered 901 of 1,086 rows (the other 185 are genuinely untreated control intervals with
no TRT_YR to recover). PEF's treatment file has no year column of any kind; rather than guess one
from the STAND interval suffix, the compartment-level activity log
`PEF_CompartmentStudy_ActivityDates_TRMT.csv` (135 dated harvest and cultural-treatment events,
1952 to 2024, already read elsewhere in the PEF build pipeline but never carried through to the
treatments output) was joined against each interval-STAND's own measured t1-to-t2 window, resolving
666 of 2,853 PEF interval-STANDs (23 percent); the match rate scales cleanly with cutting-cycle
frequency (68 percent at 5-yr cycles down to 18 percent at 20-yr cycles) and is zero, correctly,
for every Reference (unmanaged) compartment, which is the expected signature of a real signal
rather than noise. `S_PlotTreatments` now holds 1,567 rows (901 CTRN, 666 PEF), with `Treatment`
recorded under the placeholder code 99 (Unknown treatment) pending a real crosswalk of CTRN's
regime and PEF's named silvicultural treatments onto `Lookup_Treatment`'s actual codes. Full method
in `results/gydb/plottreatments_pass24_writeup.md`.

SILC_L's real-tag t2 reconciliation remains unverified, carried unchanged from the pass 22 handoff
(19 mismatched groups, 184 TREE collisions, traced to a species-crosswalk gap and at least one
stand with NA raw TREE ids). SILC_L was loaded into GYDB using the existing non-real-tag
(sequentially renumbered) tree lists, not the unverified real-tag ones.

NB MagPlot, QC MagPlot, NS, and NS-long are not in GYDB. Only their scored RESULTS files were
located this session, not tree-level init/t2 sources with the shape the generic builder expects;
adding them needs locating or rebuilding their staged tree lists first.

## A build-time bug worth flagging for anyone reusing this script

The first verification pass after the build found `SV_Datasets` (gydb's own summary view)
reporting zero locations, plots, visits, and trees for every dataset, despite direct COUNT(*)
queries against the underlying `S_Locations`, `S_Plots`, `S_Visits`, and `S_Trees` tables showing
the real numbers. The cause: `S_Datasets` carries its own cached summary columns
(Locations, Plots, Visits, MinYr, MaxYr, DistinctTrees, Trees), and gydb's normal `standardize()`
pipeline populates them by running a shipped `3_S_Finalize.sql` script as its last step. This
build used `dbAppendTable()` directly rather than gydb's file-based pipeline, so that finalize
step was never run and the summary columns sat at their insert-time defaults. Fixed by locating
the shipped script (`system.file("sql", "2_Standardized", "3_S_Finalize.sql", package = "gydb")`)
and running it against the built database; `SV_Datasets` now reports correctly (verified below).
Anyone building a GYDB instance by hand rather than through `standardize_all()` needs this same
step.

```
sqlite3 ALL_Standardized.sqlite "SELECT * FROM SV_Datasets;"

Country  Jurisdiction  Datasets  MinYR  MaxYR  Locations  Plots  Visits  DistinctTrees  TotalTrees
USA      ME            8         1953   2024   5,253      8,620  17,236  585,685        1,084,941
```

After pass 24 (MNAP Visits/Trees and S_PlotTreatments added; `SV_Datasets` itself only aggregates
`S_Trees`/`S_Visits` and does not carry a treatments column, so it is unchanged by the treatments
load and updated only by the MNAP tree/visit rows):

```
S_Datasets         8
S_Locations    6,362
S_Plots        9,729
S_Visits      17,603   (+367, all MNAP)
S_Trees    1,089,039   (+4,098, all MNAP)
S_PlotTreatments  1,567   (+1,567: 901 CTRN, 666 PEF)
```

## v12.11 vs v13.2, full head-to-head

v12.11 (the CANDIDATE lineage from before the site-fsm work) and v13.2 (the patch validated and
shipped at pass 20 to 21) are not the same lineage stacked at two points in time. v13.2 stacks the
site-fsm fix on top of ship18/v13.1's base configuration, not on top of v12.11's configuration, so
this comparison is not a simple "which is the newer, better model" question. It is a real
tradeoff between two different configurations, and the results below say so plainly rather than
picking a winner.

| Source | n | RMSE v12.11 | Bias v12.11 | RMSE v13.2 | Bias v13.2 | Slope v13.2 | Delta RMSE | Delta bias |
|---|---|---|---|---|---|---|---|---|
| Baxter (mature, held-out) | 91 | 28.47 | 11.28 | 25.72 | -0.22 | 1.087 | -2.75 | -11.50 |
| CTRN (managed) | 1,086 | 18.06 | -2.24 | 24.60 | -9.12 | 1.205 | +6.54 | -6.88 |
| Maine FIA whole-plot (20-yr) | 918 | 38.56 | -16.13 | 38.21 | -12.92 | 1.109 | -0.35 | +3.21 |
| NB MagPlot (managed) | 355 | 41.85 | -5.96 | 48.80 | -11.13 | 1.181 | +6.95 | -5.17 |
| NS, NS scenario | 4,504 | 156.69 | -30.61 | 182.38 | -41.54 | 0.120 | +25.69 | -10.93 |
| NS, NS-long scenario | 5,348 | 127.35 | -30.41 | 153.67 | -38.34 | 0.220 | +26.32 | -7.93 |
| PEF (developing) | 2,853 | 17.91 | 1.37 | 18.81 | 3.37 | 0.918 | +0.90 | +2.00 |
| QC MagPlot | 378 | 58.50 | 9.46 | 58.58 | 3.43 | 0.538 | +0.08 | -6.03 |
| SILC/Seven Islands (calibration) | 73 | 64.24 | -5.65 | 63.90 | -5.29 | 0.580 | -0.34 | +0.36 |
| memat | 1,757 | no v12.11 run | -- | 18.47 | -6.83 | 1.183 | -- | -- |
| medev | 1,759 | no v12.11 run | -- | 20.77 | -4.05 | 1.061 | -- | -- |

Delta columns are v13.2 minus v12.11 (RMSE and bias in percent of observed mean, as scored by the
pass 21/22 harness); positive means v13.2 is worse.

v13.2 wins decisively, and by design, on exactly one source: Baxter. This is the source v13.2 was
built to fix. RMSE drops 2.75 points and bias collapses from +11.28 percent (ship18's known
over-prediction problem) to -0.22 percent, with a slope of 1.087, close to the 1:1 line. On every
other source, v13.2 either loses outright or is a wash.

v12.11 wins substantially on three sources. CTRN is the clearest: v13.2 is 6.54 RMSE points worse
and its bias more than triples in magnitude, from -2.24 to -9.12 percent. NB MagPlot moves the
same direction, v13.2 6.95 RMSE points worse with bias nearly doubling. NS is the most severe:
under both the NS and NS-long scoring scenarios, v13.2's RMSE is 20 to 26 points worse than
v12.11's, bias is 8 to 11 points worse, and the observed-on-predicted slope collapses to 0.12 to
0.22, a level of attenuation that means v13.2's predictions are barely tracking the observed
spread at all on this source, not merely biased.

The remaining five sources (Maine FIA whole-plot, PEF, QC MagPlot, SILC, and the two FIA strata
with no v12.11 comparison run available) are close to a wash, within 1 RMSE point either direction
except PEF's 2-point bias shift, none large enough to call a clear winner on their own.

Read together, this does not support treating v13.2 as a strict upgrade over v12.11. It supports
treating them as two different configurations with different strengths: v13.2 for anything close
to Baxter's mature, held-out stand structure, v12.11 for CTRN-like managed stands, NB, and
especially NS, where v13.2's attenuation is severe enough to be disqualifying on its own. The
pass 21/22 conclusion that v13.2 is the shipping candidate was validated against ship18 and the
rest of the eight-source battery, not against v12.11, and that conclusion stands on its own
grounds; this comparison answers a different question (v12.11 vs v13.2) and should not be read as
contradicting it. Whether v12.11's config elements that help CTRN/NB/NS can be merged into v13.2's
base without reintroducing Baxter's over-prediction is the natural next question and is not
answered by this pass.

## Pass 25 review: an omission in the v12.11 vs v13.2 table, and independent verification of pass 24

A review of this comparison (F9 firewall, re-deriving every number against primary sources rather
than trusting the composite) found the pairwise v12.11-vs-v13.2 figures above to be accurate: every
cell was re-checked against `p21/p21_v132_persource.csv`, `p22/p22_qc_reconciled.csv`, and
`p22/p22_memat_medev_reduced.csv` directly and matched exactly, with zero discrepancies.

It also found a real omission. `p21_v132_persource.csv`, the same file `build_v1211_vs_v132.R`
draws from, already carries a third model, OSM-ACD v2.26.1, scored alongside v12.11 and v13.2 on
every source, plus a `best_rmse_model` column naming the outright RMSE winner per source. That
column was never selected into the comparison table above, so the table silently omits it. OSM-ACD
v2.26.1 is the outright best RMSE model on four of eight comparable sources: Maine FIA whole-plot
(31.93% versus v12.11's 38.56% and v13.2's 38.21%, roughly 6.3 to 6.6 points better than either),
PEF (14.65% versus 17.91% and 18.81%, about 3 to 4 points better), SILC (62.99% versus 64.24% and
63.90%, a smaller margin), and NS under the NS scenario (153.05% versus 156.69% and 182.38%). It is
also close behind the winner on two more, CTRN (20.51%, second to v12.11's 18.06% but well ahead of
v13.2's 24.60%) and NS-long (128.34%, essentially tied with v12.11's 127.35%). It trails clearly
only on Baxter (32.22% against v13.2's 25.72%) and NB MagPlot (43.77%, between the two AGY
candidates).

This does not change the v12.11-vs-v13.2 conclusion itself, which remains numerically correct as a
pairwise comparison. It changes what that conclusion is worth in practice: on the majority of
non-Baxter sources, the real question is not only which AGY configuration to ship, but whether
either currently beats an existing external reference model that was already sitting in the same
results file. `build_v1211_vs_v132.R` is a two-line fix (select `rmse_osm`, `bias_osm`, and
`best_rmse_model` alongside the existing columns); flagged here rather than fixed silently, since
the choice of whether OSM-ACD is an appropriate reference for this table, or is scored under
different assumptions that make the comparison unfair, is a modeling judgment call, not a data bug.

Separately, this review independently re-derived two of pass 24's headline numbers directly from
the primary per-stand hybrid result files on Cardinal, rather than trusting
`merge_v24_results_noncanadian.csv`. `h1_v132_mortgate_ctrn_results.csv` (n = 1,086) recomputes to
RMSE 17.76%, bias -1.54%, slope 1.005, matching the README's verdict table exactly.
`h1_v132_mortgate_baxter_results.csv` (n = 91) recomputes to RMSE 25.72%, bias -0.22%, confirming
the lever is genuinely bit-identical to v13.2 on Baxter, not merely close. Pass 24's MNAP figures
were also cross-checked directly against the live database (367 visits, 4,098 trees, years 2004 to
2016) and matched. No defect was found in pass 24's work; the recommendation to adopt
h1_v132_mortgate for the non-Canadian battery stands on independently verified numbers, not only
on the run's own report of itself.

## Pass 24 additions (22 August 2026)

Three tracks closed or partially closed the gaps pass 23 left open. MNAP's `S_Visits`/`S_Trees`
were partially built (367 visits, 4,098 trees, 2004 to 2016) by recovering real survey dates from
`EcoreserveMonitoring.accdb`; full method and the disclosed coverage shortfall are in
`results/gydb/mnap_pass24_writeup.md`. `S_PlotTreatments` went from 0 to 1,567 rows (901 CTRN, 666
PEF) by fixing a column-name mismatch (CTRN) and joining a compartment activity log (PEF); full
method in `results/gydb/plottreatments_pass24_writeup.md`. A modeling question left open at the
end of pass 23, whether v12.11's CTRN-favorable config elements can be merged into v13.2's base
without reintroducing Baxter's over-prediction, was answered for the non-Canadian battery: yes, a
single lever (density-dependent mortality scaling, gated on the managed flag) recovers CTRN in
full while leaving Baxter, PEF, Maine FIA, and SILC numerically untouched. Full diff, hybrids, and
verdict in `results/gydb/merge_v24/README.md`. NB MagPlot, QC MagPlot, NS, and NS-long were
explicitly out of scope for pass 24 per instruction and remain exactly as pass 23 left them, not
in GYDB and not part of the merge verdict; item 4 in the gaps list above is unchanged.

`ALL_Standardized.sqlite` was backed up twice before these writes,
`ALL_Standardized_PREV_20260822.sqlite` (pre-treatments) and `ALL_Standardized_PREV_20260822b.sqlite`
(pre-MNAP), both retained on Cardinal alongside the live database.

## Files in this delivery

`scripts/gydb/build_gydb.R`: the full build script (v3, the version that ran clean end to end),
with the three fixes documented inline in its header comment.
`scripts/gydb/build_v1211_vs_v132.R`: builds the comparison table above from already-scored
results files, no new Cardinal compute.
`results/gydb/v1211_vs_v132_comparison.csv`: the comparison table as CSV.
`results/gydb/build_log_full.csv`: the structured audit log (Dataset, Provider, Level, Message)
from the full build, including MNAP.

`scripts/gydb/load_plot_treatments_pass24.R`: follow-on loader that patches `S_PlotTreatments`
without a full rebuild; the underlying fixes are also patched into `build_gydb.R` directly.
`results/gydb/plottreatments_pass24_writeup.md`, `results/gydb/mnap_pass24_writeup.md`: full pass
24 method writeups for the two data-gap tracks.
`results/gydb/merge_v24/`: the config-merge experiment (README, lever block, runner, sbatch,
scorecard script, and the two small aggregated result CSVs). The 40 per-stand hybrid result files
(about 25 MB) stay on Cardinal at `magplot/verify/merge_v24/`.

The 89 MB `ALL_Standardized.sqlite` itself stays on Cardinal at
`~/gydb_ws/data/ALL/ALL_Standardized.sqlite`.

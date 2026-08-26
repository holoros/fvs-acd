# GYDB build and v12.11 vs v13.2 comparison, 21 to 25 August 2026 (pass 23 to 27)

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

Twelve datasets, 12,918 locations, 23,213 plots, 44,571 visits, 2,502,807 tree records
(1,363,750 distinct trees across both occasions), spanning 1953 to 2024: eight USA (Maine)
datasets (1,089,039 trees) plus four Canadian datasets added in pass 27, NS, NS-long, NB, and QC
(1,413,768 trees). See the pass 27 section below for the Canadian sources.

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
| NS | Nova Scotia permanent sample plot network (overall) | 2,193 | 5,000 | 10,000 | 544,444 | 1965 to 2006 (pass 27) |
| NS_LONG | Nova Scotia permanent sample plot network (long horizon) | 2,132 | 5,929 | 11,858 | 705,997 | 1965 to 2006 (pass 27) |
| NB | New Brunswick MagPlot network | 203 | 355 | 710 | 28,955 | 2016 to 2022 (pass 27) |
| QC | Quebec MagPlot network | 2,028 | 2,200 | 4,400 | 134,372 | 1970 to 2023 (pass 27) |

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

NB MagPlot, QC MagPlot, NS, and NS-long were added to GYDB in pass 27 (see below); the claim in
this paragraph through pass 26, that only scored results existed and not tree-level sources, was
not re-derived before being carried forward and turned out to be wrong. A fresh search found the
tree-level files in the expected shape on the first try.

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

## v12.11 vs v13.2 vs OSM-ACD v2.26.1, full head-to-head

v12.11 (the CANDIDATE lineage from before the site-fsm work) and v13.2 (the patch validated and
shipped at pass 20 to 21) are not the same lineage stacked at two points in time. v13.2 stacks the
site-fsm fix on top of ship18/v13.1's base configuration, not on top of v12.11's configuration, so
this comparison is not a simple "which is the newer, better model" question. OSM-ACD v2.26.1 is a
third, independently developed model already scored on every source in the same pass 21/22
harness; it was omitted from this table through pass 25 (see the pass 25 note below) and is
restored here as of pass 26.

| Source | n | RMSE v12.11 | Bias v12.11 | RMSE v13.2 | Bias v13.2 | Slope v13.2 | RMSE OSM-ACD | Bias OSM-ACD | Best RMSE model |
|---|---|---|---|---|---|---|---|---|---|
| Baxter (mature, held-out) | 91 | 28.47 | 11.28 | 25.72 | -0.22 | 1.087 | 32.22 | 16.85 | v13.2 site-fsm |
| CTRN (managed) | 1,086 | 18.06 | -2.24 | 24.60 | -9.12 | 1.205 | 20.51 | -4.81 | CANDIDATE v12.11 |
| Maine FIA whole-plot (20-yr) | 918 | 38.56 | -16.13 | 38.21 | -12.92 | 1.109 | 31.93 | -6.29 | OSM-ACD v2.26.1 |
| NB MagPlot (managed) | 355 | 41.85 | -5.96 | 48.80 | -11.13 | 1.181 | 43.77 | -8.07 | CANDIDATE v12.11 |
| NS, NS scenario | 4,504 | 156.69 | -30.61 | 182.38 | -41.54 | 0.120 | 153.05 | -29.22 | OSM-ACD v2.26.1 |
| NS, NS-long scenario | 5,348 | 127.35 | -30.41 | 153.67 | -38.34 | 0.220 | 128.34 | -31.99 | CANDIDATE v12.11 |
| PEF (developing) | 2,853 | 17.91 | 1.37 | 18.81 | 3.37 | 0.918 | 14.65 | 0.26 | OSM-ACD v2.26.1 |
| QC MagPlot | 378 | 58.50 | 9.46 | 58.58 | 3.43 | 0.538 | not scored | not scored | -- |
| SILC/Seven Islands (calibration) | 73 | 64.24 | -5.65 | 63.90 | -5.29 | 0.580 | 62.99 | -18.07 | OSM-ACD v2.26.1 |
| memat | 1,757 | no v12.11 run | -- | 18.47 | -6.83 | 1.183 | no OSM run | -- | -- |
| medev | 1,759 | no v12.11 run | -- | 20.77 | -4.05 | 1.061 | no OSM run | -- | -- |

RMSE and bias are in percent of observed mean, as scored by the pass 21/22 harness.

v13.2 wins decisively, and by design, on exactly one source: Baxter, the source it was built to
fix. RMSE drops 2.75 points against v12.11 and bias collapses from +11.28 percent to -0.22
percent, with a slope of 1.087, close to the 1:1 line. OSM-ACD trails badly here (32.22 percent
RMSE, +16.85 percent bias), so Baxter is the one source where the two AGY candidates both beat the
external reference outright.

Everywhere else, OSM-ACD is the source of the real headline. It is the outright best RMSE model on
four of eight comparable sources: Maine FIA whole-plot (31.93 percent against v12.11's 38.56 and
v13.2's 38.21, roughly 6.3 to 6.6 points better than either AGY candidate), PEF (14.65 percent
against 17.91 and 18.81, about 3 to 4 points better), SILC (62.99 percent against 64.24 and 63.90,
a smaller margin), and NS under the NS scenario (153.05 percent against 156.69 and 182.38). It is
close behind the winner on two more: CTRN (20.51 percent, second to v12.11's 18.06 but well ahead
of v13.2's 24.60) and NS-long (128.34 percent, essentially tied with v12.11's 127.35). It trails
clearly only on Baxter and NB MagPlot (43.77 percent, between the two AGY candidates). QC MagPlot
and the two FIA strata (memat, medev) have no OSM-ACD run to compare.

Read together, the practical question on most of this battery is not only which AGY configuration
to ship, but whether either currently beats an existing external reference model. Between the two
AGY candidates alone, v12.11 wins substantially on CTRN, NB MagPlot, and especially NS, where
v13.2's observed-on-predicted slope collapses to 0.12 to 0.22, severe attenuation rather than
simple bias; the remaining sources are close to a wash between the two. The pass 21/22 conclusion
that v13.2 is the shipping candidate was validated against ship18 and the rest of the eight-source
battery, not against v12.11 or OSM-ACD, and that conclusion stands on its own grounds; this table
answers a different question and should not be read as contradicting it. Pass 24's
`h1_v132_mortgate` config merge (below) already closes most of the CTRN gap between v13.2 and
v12.11 without touching Baxter; whether it also closes the gap to OSM-ACD on CTRN, or whether a
similar merge could close the gap to OSM-ACD on Maine FIA whole-plot, PEF, or SILC, is not answered
by this pass.
Pass 31 later settled the practical question this paragraph leaves open only in part, adopting
`h1_v132_mortgate` as the default configuration across the full battery on August 25, 2026, on the
strength of the RMSE evidence in the Pass 30 and Pass 31 sections below. That adoption does not
change which model is the shipping candidate on the v12.11 versus OSM-ACD axis this table
addresses, since v13.2 versus h1 is a different comparison.

## Pass 25 to 26: an omission found and fixed, and independent verification of pass 24

A pass 25 review of this comparison (F9 firewall, re-deriving every number against primary sources
rather than trusting the composite) found the pairwise v12.11-vs-v13.2 figures accurate: every
cell was re-checked against `p21/p21_v132_persource.csv`, `p22/p22_qc_reconciled.csv`, and
`p22/p22_memat_medev_reduced.csv` directly and matched exactly, with zero discrepancies. It also
found that `p21_v132_persource.csv`, the same file the comparison script draws from, already
carried OSM-ACD v2.26.1 and a `best_rmse_model` column that had never been selected into the
published table. That omission was flagged rather than fixed silently in pass 25, since whether
OSM-ACD is an appropriate reference for this table was a judgment call for Aaron, not a data bug;
Aaron confirmed adding it, and pass 26 (`build_v1211_vs_v132_osm.R`) restores the OSM-ACD and
best-model columns into the table above.

Separately, pass 25 independently re-derived two of pass 24's headline numbers directly from the
primary per-stand hybrid result files on Cardinal, rather than trusting
`merge_v24_results_noncanadian.csv`. `h1_v132_mortgate_ctrn_results.csv` (n = 1,086) recomputes to
RMSE 17.76 percent, bias -1.54 percent, slope 1.005, matching the merge verdict table exactly.
`h1_v132_mortgate_baxter_results.csv` (n = 91) recomputes to RMSE 25.72 percent, bias -0.22
percent, confirming the lever is genuinely bit-identical to v13.2 on Baxter, not merely close.
Pass 24's MNAP figures were also cross-checked directly against the live database (367 visits,
4,098 trees, years 2004 to 2016) and matched. No defect was found in pass 24's work.


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

## Pass 27: NS, NS_LONG, NB, and QC added as datasets 9 to 12

The pass 23 handoff stated that NB MagPlot, QC MagPlot, NS, and NS-long were not in GYDB because
only their scored results, not tree-level init/t2 sources, had been located. That claim was not
re-derived before being carried forward through passes 24 to 26. A fresh search this pass found
tree-level sources for all four in the same shape the generic builder already expects:
`multisrc/bench_ns_pairs.csv` / `bench_ns_tree_init.csv` / `bench_ns_tree_t2.csv` for NS, the
equivalent `bench_ns_long_*` files for NS-long, and `magp_qcnb_pairs.csv` /
`magp_qcnb_tree_init.csv` / `magp_qcnb_tree_t2.csv` for NB and QC combined, distinguished by a
`PROV` column (NB: 355 pairs, matching the externally verified n = 355 already used throughout
the v12.11-vs-v13.2 comparison; QC: 2,200 pairs).

NS and NS-long carry over 100 distinct EXPF values, which raised a real question before any code
was written: is this a point-sampled (BAF, variable-radius) design, which GYDB's schema supports
through `S_Frames.BAF` and would need entirely different handling than the fixed-radius Frame
tiers used for every other source in this database? A cheap prototype settled it: EXPF is
constant within 4,718 of 4,956 sampled stands (95 percent) and does not scale with 1/DBH^2 the
way a BAF design would. The many distinct EXPF values reflect many different plot-size
conventions pooled into one composite "NS (overall)" source, not point sampling, so the existing
fixed-radius Frame-tier approach applies unchanged.

Two real defects surfaced building these four and are logged with exact counts in
`build_log_pass27.csv`. NS's t2 file carries 57 rows at EXPF 13.33, a value absent from init's
EXPF set; a Frame lookup built from init alone left those rows with no Frame, which the schema
rejects. Fixed by building the Frame lookup from the union of init and t2 EXPF values, not init
alone. QC's pairs file uses STAND as a location identifier, not an interval identifier, so 131 of
2,200 STANDs cover a location measured on 3 or more occasions and appear twice, once per interval,
each pair carrying its own y1/y2; unlike CTRN, this source's STAND does not embed the interval,
so plain STAND matching could not tell which interval's tree records belonged to which pairs row,
and a first attempt failed on a duplicate (Dataset, PlotID). Fixed by keying plots and tree
matching on (STAND, YEAR) against each pairs row's own y1/y2 rather than STAND membership plus
the overall minimum year. Verified NOT needed for NB (zero duplicate STANDs, and independently
spot-checked zero mismatches between the pairs file's declared y1/y2 and the tree files' own
min(YEAR) for every one of NB's 355 stands) or for NS/NS-long (STAND is already unique per pairs
row in both). A worked example: QC plot `30000602L2_I01` is now correctly split into
`30000602L2_I01_y1970_1978` (25 trees at t1, 22 at t2) and `30000602L2_I01_y1978_1985` (22 trees
at t1, 15 at t2), matching the raw tree files exactly.

A third, unrelated defect: `build_gydb.R`'s `S_Datasets` insert hardcoded `Country = 'USA'`,
harmless for the 8 Maine sources but wrong for these four (Nova Scotia, Nova Scotia, New
Brunswick, Quebec, all Canada). Parameterized in the pass 27 script; worth back-porting into
`build_gydb.R` itself so a future full rebuild does not reintroduce it. `Owner` is recorded as
"Not documented in source files" for all four rather than guessed, since no README, header
comment, or accompanying metadata file names the administering agency anywhere in
`magplot/verify`.

The database now holds 12 datasets, 12,918 locations, 23,213 plots, 44,571 visits, and 2,502,807
tree records, 1953 to 2024. `SV_Datasets` confirms the country split is now correct: 8 USA (Maine)
datasets at 1,089,039 trees, unchanged from before this pass, and 4 Canada datasets (NS, NS-long,
NB, QC) at 1,413,768 trees. As with QC MagPlot and NS/NS-long in earlier passes, the pairs files
here (5,000 for NS, 5,929 for NS-long, 2,200 for QC) exceed the stand counts that made it into
prior FVS-ACD scoring runs (4,504, 5,348, and 378 respectively); GYDB loads every available pair,
not only the previously scored subset, and this size difference is expected, not an error.

`ALL_Standardized.sqlite` was backed up to `ALL_Standardized_PREV_20260825.sqlite` before this
pass's writes.

## Files in this delivery

`scripts/gydb/build_gydb.R`: the full build script (v3, the version that ran clean end to end),
with the three fixes documented inline in its header comment.
`scripts/gydb/build_v1211_vs_v132.R`: pass 23's original comparison script (v12.11 vs v13.2
only), kept for reference; superseded by the script below.
`scripts/gydb/build_v1211_vs_v132_osm.R`: pass 26 version, adds the OSM-ACD v2.26.1 and
best-model columns pass 25 found omitted. Builds the table above from already-scored results
files, no new Cardinal compute.
`results/gydb/v1211_vs_v132_comparison.csv`: pass 23's two-model table, kept for reference.
`results/gydb/v1211_vs_v132_vs_osm_comparison.csv`: the three-model table as published above.
`results/gydb/build_log_full.csv`: the structured audit log (Dataset, Provider, Level, Message)
from the full build, including MNAP.

`scripts/gydb/load_plot_treatments_pass24.R`: follow-on loader that patches `S_PlotTreatments`
without a full rebuild; the underlying fixes are also patched into `build_gydb.R` directly.
`results/gydb/plottreatments_pass24_writeup.md`, `results/gydb/mnap_pass24_writeup.md`: full pass
24 method writeups for the two data-gap tracks.
`results/gydb/merge_v24/`: the config-merge experiment (README, lever block, runner, sbatch,
scorecard script, and the two small aggregated result CSVs). The 40 per-stand hybrid result files
(about 25 MB) stay on Cardinal at `magplot/verify/merge_v24/`.

`scripts/gydb/build_gydb_extend_pass27.R`: adds NS, NS_LONG, NB, and QC as datasets 9-12
against an existing database (does not recreate it); the version with both pass-27 fixes
(Frame lookup union, STAND+YEAR plot keying) applied from the start.
`results/gydb/build_log_pass27.csv`: structured audit log for the four pass-27 sources.

The 89 MB `ALL_Standardized.sqlite` itself stays on Cardinal at
`~/gydb_ws/data/ALL/ALL_Standardized.sqlite`.

## Pass 28: closing the NS-long and QC benchmark-coverage gaps, and why SILC-L stays open

A request to run the FVS-ACD benchmark against GYDB's complete pair sets turned up three real
coverage gaps rather than a single uniform shortfall, and each needed its own diagnosis before
any new compute was justified.

NS-long's 176 excluded stands turned out to be a deliberate scope filter, not a bug. The source
pairs file `bench_ns_long_pairs.csv` carries its own `SINGLE_REGIME` flag, and the harness had
only ever been wired to score `SINGLE_REGIME == 1` managed stands (1,334) plus every unmanaged
stand (4,419), which sums exactly to the 5,753 previously scored. The 176 missing rows are
`MANAGED == 1 & SINGLE_REGIME == 0`, meaning managed stands measured under more than one
overlapping management regime, confirmed by matching STAND names against the flag directly. Their
tree chains were already built and validated by `lk2_build_ns.R`, since that script never filtered
on the regime flag in the first place, so closing this gap needed only a new pairs file
(`bench_ns_long_pairs_managed_multiregime.csv`) and one more scoring pass under the same v13.2
config already used for the rest of NS-long. Scored as `p9_v132_ns_long_multiregime_results.csv`,
176 of 176 stands.

QC's gap looked at first like a missing-data problem (378 of 2,200 pairs scored, the rest dropped
by the harness's `esi_cov` domain filter) but turned out to be a raster-extent problem instead.
`magp_qcnb_site_esi8.csv` already carries a real ESI extraction for every QC and NB site, pulled
from `Acadian_ESI_v8_30m.tif` by `extract_esi8_qcnb.py`, and NB's 203 sites are all inside that
raster's footprint. QC.s 2,028 sites mostly are not, as only 346 fall inside it, since the raster was
rendered over `ME + NB + NS + PEI` and cropped to `-72 to -59` longitude, well short of most of
Quebec's magplot network. The gap was closeable without a new model, since `acadian_v8_model.rds`
(the ranger random forest behind that raster, trained on ClimateNA climate normals plus Copernicus
DEM terrain, neither of which is Acadian-limited) could be applied pointwise at each uncovered
site's own coordinates. Fetched 108 one-degree Copernicus GLO-30 DEM tiles covering the 1,682
uncovered sites via `/vsicurl/`, computed slope and aspect per tile, pulled the same 32 ClimateNA
derived predictors used at render time, and predicted site index directly with the existing model,
no refit. 1,674 of 1,682 sites returned a valid prediction (2 < SI < 60), the other 8 left blank
rather than forced. QC now scores 2,192 of 2,200 pairs under v13.2, up from 378, written as
`p9_v132_nb_v2_results.csv` alongside NB's unchanged 355.

SILC-L's 64 unreconciled pairs, carried open since pass 22, stay open. A wider search this pass,
extending into `~/silc_cfi` rather than stopping at `~/magplot/verify`, found the actual source of
the "full137" expansion (`build_tree_init_pairs.py`, 12 August), which builds a t1 tree list from
real per-stand files but assigns TREE as a synthetic row count rather than the source's own tag.
More importantly, `bench_silc_l_tree_t2_full137.csv`, the t2 half of the same expansion, has no
build script anywhere in either directory, no `.py`, `.R`, or log that writes it. It is an orphan
file of unverified provenance, and scoring against it would mean trusting data with no traceable
source, not reconciling a real one. The 73 pairs with a verified real-identity source (via
`silc_cfi_longhorizon_pairs_v16.csv`) remain the usable subset until a real source for the other 64
turns up.

The table below adds v13.2's expanded coverage for QC and NS-long next to the original, narrower
figures already published above. v12.11 and OSM-ACD were not rescored under the wider coverage,
since neither run was resourced this pass, so their rows are left at the original basis and marked
accordingly rather than implied to match. Widening QC's coverage moved its v13.2 bias from +3.4
percent to +10.8 percent, worse, since the newly added stands sit outside the calibration domain
the narrower fit had implicitly relied on. NS-long's picture worsens too, RMSE from 153.7 to 158.4
percent and the observed-on-predicted slope from 0.220 to 0.075, the added multi-regime stands
pulling further into the same severe-attenuation pattern already flagged for NS-long under v13.2.
Neither result changes the standing conclusion that v13.2's site-fsm patch is a real fix for Baxter
and a real regression for NS and NS-long, it only sharpens the size of the regression now that the
coverage is closer to complete.

| Source | Coverage | n | RMSE v13.2 | Bias v13.2 | Slope v13.2 |
|---|---|---|---|---|---|
| QC MagPlot, original | esi_cov = 1 only | 378 | 58.58 | 3.43 | 0.538 |
| QC MagPlot, expanded | + pointwise-predicted SI | 2,192 | 61.03 | 10.83 | 0.657 |
| NS-long, original | singleregime + unmanaged | 5,753 | 153.67 | -38.34 | 0.220 |
| NS-long, expanded | + 176 multiregime managed | 5,929 | 158.38 | -40.91 | 0.075 |

RMSE and bias are in percent of observed mean total volume, slope is the observed-on-predicted OLS
slope, both computed the same way as the published table above. v12.11 and OSM-ACD figures for
these two sources are not repeated here since neither was rescored against the expanded coverage.

## Pass 30: h1_v132_mortgate scored against NB, QC, NS, and NS-long

Pass 24 answered whether v12.11's config elements could be merged into the v13.2 base without
reintroducing Baxter's over-prediction, restricted to the non-Canadian battery per instruction at
the time. It found h1_v132_mortgate (density-dependent mortality scaling, gated on the managed
flag) bit-identical to v13.2 everywhere in that battery except CFRU CTRN, where h1 wins outright.
NB MagPlot, QC MagPlot, NS, and NS-long were excluded from that verdict by instruction, even though
h1 through h4 result files for those four sources already existed on Cardinal from before the
restriction took effect. This pass reopens that question, using GYDB's now-complete pair coverage
for the four Canadian sources rather than the narrower coverage those pre-existing files carried.

Orientation confirmed the pre-existing merge_v24 files could only partly be reused. NS managed and
NS unmanaged matched the current p21 baseline coverage exactly, both in row count and in a
STAND-for-STAND diff, and were reused as scored without rerunning the model. NB and QC did not,
since the pre-existing h1 NB file (734 rows) predates the QC merge and the pointwise ESI fill that
now bring NB plus QC to 2,547 combined pairs, and no h1 file for NS-long existed at all, since pass
24's merge_v24 sweep only ever scored NS and never touched the NS-long source. NB plus QC and all
three NS-long components (managed singleregime, unmanaged, and the multiregime slice pass 28
closed) were therefore rescored this pass under h1_v132_mortgate, using the exact overlay pass 24
used (ONSET 0.55, LEV3 lo 0.35 hi 0.45 qmin 18, V1211_MORTGATE=TRUE, V1211_DHTHW=FALSE, MORT_FMIN
MORT_K MORT_RD0 left at their 0.13, 12.4, 0.38 defaults) on top of the unmodified v13.2 stack, read
from merge_v24's own hybrids sbatch and lever_block.txt rather than reconstructed from memory. NB
and QC both carry V1211_MANAGED=TRUE, matching how pass 24 scored the combined nb source. NS and
NS-long split by their own managed and unmanaged pairs files, so V1211_MANAGED tracks TRUE for the
managed and multiregime components and FALSE for the unmanaged component, exactly as merge_v24 did
for NS.

Every h1 result file, new or reused, was checked against its current v13.2 baseline file on STAND
keys and observed TOTVOL before any metric was trusted, the same observed-basis gate pass 24's own
scorecard enforces. All eight gates passed with an exact row-count and STAND match (NB 355, QC
2,192, NS managed and unmanaged 2,500 each, NS-long managed singleregime 1,334, unmanaged 4,419,
multiregime 176), so every number below rests on a matched, verified pair set.

| Model | Source | n | RMSE% | Bias% | Slope obs-on-pred |
|---|---|---|---|---|---|
| v13.2 baseline | NB | 355 | 48.80 | -11.13 | 1.181 |
| h1 mortgate | NB | 355 | 41.86 | -5.84 | 1.082 |
| v13.2 baseline | QC | 2,192 | 61.03 | 10.83 | 0.657 |
| h1 mortgate | QC | 2,192 | 57.95 | 15.55 | 0.684 |
| v13.2 baseline | NS | 5,000 | 177.77 | -38.79 | 0.203 |
| h1 mortgate | NS | 5,000 | 152.32 | -28.55 | 1.838 |
| v13.2 baseline | NS-long | 5,929 | 158.38 | -40.91 | 0.075 |
| h1 mortgate | NS-long | 5,929 | 130.64 | -30.68 | 2.042 |

RMSE and bias are in percent of observed mean total volume, slope is the observed-on-predicted OLS
slope, computed the same way as the tables above.

NB is a clean win for h1. RMSE drops 6.94 points (48.80% to 41.86%), the negative bias shrinks by
5.29 points (-11.13% to -5.84%), and the slope moves closer to 1 (1.181 to 1.082). QC is mixed
rather than a clean win or loss. RMSE improves 3.08 points and the slope moves closer to 1 from
below (0.657 to 0.684), yet QC's bias was already positive under v13.2 and h1 pushes it further
positive still, from 10.83% to 15.55%, a 4.72 point increase in over-prediction. NS and NS-long
both show large RMSE and bias gains under h1, RMSE falling 25.45 and 27.74 points and bias
improving 10.24 and 10.23 points respectively, yet their slopes invert rather than correct, moving
from severe attenuation well below 1 (0.203 and 0.075) to overshoot well above 1 (1.838 and 2.042).
The distance from a slope of 1 is roughly symmetric before and after the lever fires on both
sources (NS moves from 0.797 to 0.838 units away from 1, NS-long from 0.925 to 1.042), so the lever
trades one form of dispersion miscalibration for the opposite one on these two sources rather than
fixing it outright. What drives that inversion is not established by this pass's aggregate metrics
alone and is flagged here as an open question for a follow-up pass, not explained away.

h1_v132_mortgate never loses to v13.2 on RMSE at any of the four Canadian sources, extending the
pattern already established on the non-Canadian battery, where h1 was bit-identical to v13.2 on
every source except CTRN, where it won outright. That extends the standing recommendation from
pass 24 rather than reversing it, adopt h1_v132_mortgate broadly, across both the non-Canadian and
now the Canadian battery, since it is never the worse RMSE choice anywhere tested to date. The
recommendation carries two caveats that pass 24's non-Canadian verdict did not need to carry. QC's
bias tradeoff means h1 is not an unqualified win there even though it wins on RMSE, and the NS and
NS-long slope inversion means the lever changes the character of those two sources' dispersion
miscalibration rather than resolving it, a distinction worth carrying into any downstream use of
predicted variance or intervals from those two sources specifically.

### Files added this pass

`results/gydb/h1_v132_mortgate_nb_v2_results.csv`: h1 rerun against the current NB plus QC pair set
(2,547 rows combined, PROV distinguishes NB from QC).
`results/gydb/h1_v132_mortgate_ns_long_managed_singleregime_results.csv`,
`h1_v132_mortgate_ns_long_unmanaged_results.csv`,
`h1_v132_mortgate_ns_long_multiregime_results.csv`: h1 reruns against NS-long's three pair-file
components (1,334, 4,419, and 176 rows).
`results/gydb/pass30_h1_vs_v132_canadian.csv`: the eight-row scorecard published above.
`results/gydb/2026-08-25_pass30_h1_rerun.sbatch`: the SLURM array that produced the four new h1
result files (job 13960633, four tasks).
`scripts/gydb/2026-08-25_pass30_scorecard_canadian.R`: computes the table above, including the
observed-basis gate against each source's current v13.2 baseline file (job 13962194, chained on
job 13960633 via SLURM's own --dependency=afterok so it started automatically once scoring
finished, no manual resubmission needed).
NS managed and NS unmanaged h1 results are not re-copied here since they are unchanged from
`merge_v24/h1_v132_mortgate_ns_managed_results.csv` and `..._ns_unmanaged_results.csv`, already on
Cardinal from pass 24 and confirmed this pass to match the current baseline exactly, both files stay
on Cardinal only, consistent with the standing convention for the other merge_v24 per-stand files.

## Pass 31: h1_v132_mortgate adopted as the default configuration (August 25, 2026)

> AMENDED by Pass 32 (August 26, 2026), see the full section below. A long-horizon Bakuzis biological-consistency assessment found a genuine mid-rotation basal area and volume crash and standing-volume site-order inversion under h1_v132_mortgate at 9 of the 11 sources tested. Pass 32 also reran the identical long-horizon procedure under plain v13.2 baseline (no h1 lever) at six of those sources and found the crash present in statistically indistinguishable magnitude and timing, meaning it is inherited unchanged from v13.2's own density-dependent mortality mechanism rather than introduced or worsened by h1. The adoption decision below stands. It now carries an explicit long-horizon caveat that applies to plain v13.2 generally, not specifically to h1, since the short-interval RMSE evidence this section documents is unaffected by a finding about 100-year extrapolation behavior far outside the 1- to 25-year calibration intervals every source here was actually scored against.

Aaron reviewed pass 30's verdict and decided, on August 25, 2026, to adopt `h1_v132_mortgate`
broadly as the new default configuration across all eleven sources this database and its scoring
harness cover, namely Baxter, PEF, MEFIA_L, memat, medev, SILC, CTRN, NB, QC, NS, and NS_LONG. This
extends the pass 24 non-Canadian verdict and the pass 30 Canadian verdict into a single standing
recommendation rather than adding a third, separate one.

h1_v132_mortgate never loses to v13.2 on RMSE at any of the eleven sources tested to date. The
table below repeats every RMSE, bias, and slope pair from the pass 24 non-Canadian battery and the
pass 30 Canadian battery in one place for the first time, since no earlier section in this document
puts the full eleven-source comparison side by side.

| Model | Source | n | RMSE% | Bias% | Slope obs-on-pred |
|---|---|---|---|---|---|
| v13.2 baseline | Baxter | 91 | 25.72 | -0.22 | 1.087 |
| h1 mortgate | Baxter | 91 | 25.72 | -0.22 | 1.087 |
| v13.2 baseline | CTRN | 1,086 | 24.60 | -9.12 | 1.205 |
| h1 mortgate | CTRN | 1,086 | 17.76 | -1.54 | 1.005 |
| v13.2 baseline | PEF | 2,853 | 18.81 | 3.37 | 0.918 |
| h1 mortgate | PEF | 2,853 | 18.81 | 3.37 | 0.918 |
| v13.2 baseline | MEFIA_L | 918 | 38.21 | -12.92 | 1.109 |
| h1 mortgate | MEFIA_L | 918 | 38.21 | -12.92 | 1.109 |
| v13.2 baseline | memat | 1,757 | 18.47 | -6.83 | 1.183 |
| h1 mortgate | memat | 1,757 | 18.47 | -6.83 | 1.183 |
| v13.2 baseline | medev | 1,759 | 20.77 | -4.05 | 1.061 |
| h1 mortgate | medev | 1,759 | 20.77 | -4.05 | 1.061 |
| v13.2 baseline | SILC | 73 | 63.90 | -5.29 | 0.580 |
| h1 mortgate | SILC | 73 | 63.90 | -5.29 | 0.580 |
| v13.2 baseline | NB | 355 | 48.80 | -11.13 | 1.181 |
| h1 mortgate | NB | 355 | 41.86 | -5.84 | 1.082 |
| v13.2 baseline | QC | 2,192 | 61.03 | 10.83 | 0.657 |
| h1 mortgate | QC | 2,192 | 57.95 | 15.55 | 0.684 |
| v13.2 baseline | NS | 5,000 | 177.77 | -38.79 | 0.203 |
| h1 mortgate | NS | 5,000 | 152.32 | -28.55 | 1.838 |
| v13.2 baseline | NS_LONG | 5,929 | 158.38 | -40.91 | 0.075 |
| h1 mortgate | NS_LONG | 5,929 | 130.64 | -30.68 | 2.042 |

RMSE and bias are in percent of observed mean total volume, slope is the observed-on-predicted OLS
slope, computed the same way throughout this document. Non-Canadian rows (Baxter through SILC)
carry forward pass 24's `merge_v24_results_noncanadian.csv`, independently re-derived for Baxter
and CTRN in pass 25 and found to match exactly. Canadian rows (NB through NS_LONG) carry forward
pass 30's `pass30_h1_vs_v132_canadian.csv`.

Two caveats from pass 30 carry forward unresolved and are recorded here as known, accepted
tradeoffs rather than blockers, since RMSE, the primary adoption criterion, never regresses at any
of the eleven sources. QC's bias worsens under h1, from +10.83% to +15.55%, even as its RMSE
improves 3.08 points and its slope moves closer to 1 from below, 0.657 to 0.684. NS and NS_LONG's
slopes invert under h1 rather than correct, moving from severe attenuation well below 1 (0.203 and
0.075) to overshoot well above 1 (1.838 and 2.042), even as both sources gain sharply on RMSE
(25.45 and 27.74 points) and bias (10.24 and 10.23 points). What drives the NS-family inversion is
still not established by aggregate metrics alone, exactly as pass 30 left it, and remains an open
question for a follow-up pass rather than a reason to withhold adoption.

Two new SLURM array scripts establish h1_v132_mortgate as the production default, mirroring the
existing production battery's own two-script split. `scripts/p21/2026-08-25_p21ship_h1default.sbatch`
(10 tasks) mirrors `2026-08-19_p21ship_full.sbatch` for memat, medev, pef, ctrn, silc_l, nb,
ns_managed, ns_unmanaged, ns_long_managed, and ns_long_unmanaged, replacing the plain v13.2 harness
with `scripts/gydb/merge_v24/2026-08-21_merge-v24-runner.R` (the same v13.2 harness plus the
MERGE_V24 `V1211_*` lever block) and adding `V1211_MORTGATE=TRUE`, with `V1211_MANAGED` set per
task to match exactly how pass 24 and pass 30 scored each source under h1, confirmed against the
`mv24hyb`/`mv24ext` job logs and the pass 30 rerun sbatch rather than reconstructed from memory.
`scripts/p21/2026-08-25_p21ship_h1default_bax_mef.sbatch` (2 tasks) mirrors
`2026-08-19_p21ship_bax_mef.sbatch` for Baxter and MEFIA_L. Neither array needed to run to
establish this pass's verdict, since every one of the eleven sources already has a matching
`h1_v132_mortgate` result file on Cardinal from pass 24 (Baxter, CTRN, PEF, MEFIA_L, memat, medev,
SILC, at `~/magplot/verify/merge_v24/`) or pass 30 (NB, QC via NB's PROV split, NS, NS_LONG). Both
new scripts were syntax-checked with `bash -n` and left on Cardinal at `~/magplot/verify/p21/` so a
future full rebuild has an h1-default battery ready to submit directly, exactly parallel to the
existing v13.2 baseline scripts' role.

`2026-08-19_p21ship_full.sbatch` and `2026-08-19_p21ship_bax_mef.sbatch` stay on Cardinal and in
this repo unchanged, as the frozen v13.2-without-h1 baseline reference, not deleted, since h1's own
gains are measured against them throughout this document. The production default as of August 25,
2026, is the h1-default pair of scripts named above, not the plain v13.2 pair.


## Pass 32: Bakuzis biological-consistency re-verification of h1_v132_mortgate (August 26, 2026)

The Bakuzis biological-consistency assessment referenced but not completed in the pass 25 OODA
handoff (`_context/handoffs/20260825_gydb_pass25_ooda_review_handoff.md`) was interrupted mid-run
on August 25, 2026, after an 11-task SLURM array (job 13965767) had already produced long-horizon
(100-year, chained-annual) trajectory tables and check-script output for all eleven sources under
h1_v132_mortgate at `~/magplot/verify/bakuzis_h1/` on Cardinal. Its headline finding, a mid-rotation
basal area and volume crash and standing-volume site-order inversion at nearly every source except
PEF, was reported by a subagent whose work was interrupted before independent verification. Pass 32
re-derives this finding from primary data per the OODA firewall's F9 rule (an inherited number is
re-derived, not trusted), closes the one analysis gap the interrupted run left open, and issues a
verdict on the pass 31 adoption decision.

**Re-verification.** The crash is confirmed real and widespread, not an artifact of the interrupted
run or the check script. Six sources beyond CTRN (already independently confirmed before the
interruption) were checked directly against primary trajectory and check-script data this pass, NB,
QC, NS, memat, MEFIA_L, and SILC_L, all showing standing-volume site-ordering inversions at 97 to 100
of 100 simulated ages. The exception count is corrected from the interrupted run's framing. PEF shows
a genuine, multi-site clean pass (0 of 100 volume-ordering inversions across four real site-index
strata). Baxter, listed alongside PEF as a second clean exception in the interrupted framing, is not
assessable on this relation at all, since its 91 held-out mature stands carry a single real
site-index value with zero spread, so the site-ordering test on a length-one comparison is vacuously
true rather than evidence of consistency, and the companion Eichhorn test halted on an unhandled NA
rather than silently returning a passing number. medev shows a near-miss on volume ordering
specifically (3 of 100 inversions) but is not a clean source overall, carrying 11 total flags
including a severe Eichhorn site-dependence violation (41.4 percent CV) and 55 of 100 height-ordering
inversions.

**The critical gap closed this pass.** The interrupted run never tested the same long-horizon
procedure under plain v13.2 baseline (no h1 overlay), the single most decision-relevant fact left
open, whether the crash is a pre-existing v13.2 behavior h1 inherits, or a new problem h1 introduces
or worsens. `bakuzis_h1default_traj.R` was adapted into `bakuzis_v132baseline_traj.R` by removing
exactly the three lines that set `ops$mort.dens.scale`, `ops$mort.dens.fmin`, `ops$mort.dens.k`, and
`ops$mort.dens.rd0` (the h1-specific block), leaving `V1211_MORTGATE` at its production default of
FALSE per `scripts/gydb/merge_v24/2026-08-21_merge-v24-runner_WIP.R` line 252, so `ops$mort.dens.scale`
is never set and stays at `AcadianGY_13.1.r`'s own coded default of OFF (confirmed at line 4137's own
comment, "Gated ops$mort.dens.scale (default OFF => attenuation factor is exactly 1,
byte-identical..."). Every other ops setting, including the v13.2 site-fsm overlay, `ops$use.sdimort`
(onset at relative density 0.55, break at 0.62), the ingrowth-release block, and the LEV3
stand-density constraint, is identical between the two configurations, isolating exactly what the h1
lever contributes.

A new six-task SLURM array (job 13972248, `results/bakuzis/scripts/2026-08-26_bakuzis_v132baseline.sbatch`)
reran CTRN, NB, QC, NS, memat, and MEFIA_L under this baseline. The result is unanimous. NB and memat
reproduce byte-identical check-script output between h1 and baseline. MEFIA_L matches identically.
CTRN, QC, and NS match within one to three ages out of 100 on the height-ordering count, noise-level
agreement, with volume-ordering counts matching exactly (100 of 100 at all three). A direct
age-by-age numeric comparison at CTRN (age 38 through 56) shows tree density, basal area, and volume
diverging by roughly 1 to 2 percent between h1 and baseline through the crash window, with h1
producing a marginally deeper trough, not a shallower one. The mid-rotation crash is therefore a
plain v13.2 baseline behavior, driven by `ops$use.sdimort`, present in both configurations and not
part of the h1 lever, which h1_v132_mortgate inherits unchanged rather than introduces or
meaningfully worsens.

**Mechanism.** `ops$use.sdimort`'s onset threshold, relative stand density 0.55, sits inside Long
(1985)'s published zone of imminent competition-induced mortality (about 0.55 to 0.60), so the
timing of crash onset is a defensible, literature-consistent value, not an anomaly. The locus of the
biological-consistency problem is what happens after onset. `ops$use.ingrowth.release` recruits new
stems once relative density falls back below a center point of 0.58, and that recruitment is gated
only on density falling, not on basal area or volume recovery. At CTRN, tree density troughs around
simulated age 54 and then creeps back up in small, repeated pulses roughly every 4 to 5 years, while
basal area and volume do not recover in step, continuing to decline or plateauing well below their
pre-crash level. This is the specific submodel behavior responsible for the site-ordering inversion.

**Extrapolation domain.** Every one of the eleven sources' pair-validation intervals, the data
h1_v132_mortgate was actually scored and adopted against in passes 24 through 31, runs 1 to 25 years,
none approaching the 100-year Bakuzis horizon. The crash is a finding about FVS-ACD's long-horizon
extrapolation behavior, well outside the domain the RMSE adoption decision was validated against, not
a defect in the short-interval calibration itself.

**Verdict.** Keep h1_v132_mortgate as the pass 31 default, with a documented long-horizon caveat that
applies to plain v13.2 generally, not specifically to h1. The short-interval RMSE case for adoption
(passes 24 through 31) is unaffected, since it was never in question here and never regresses at any
of the eleven sources. The long-horizon Bakuzis finding is a real, disclosed limitation of FVS-ACD
v13.2's ingrowth-release gating, present with or without the h1 lever, and should accompany any
full-rotation or long-horizon projection use of either configuration until the gating is revised to
condition recruitment on canopy or volume recovery rather than density alone.

**Open items.** Three sources, NS_LONG, SILC_L, and medev, were not rerun under plain v13.2 baseline
this pass. The six sources that were rerun span the full severity range observed (total flags 8 to
11, volume inversions 97 to 100 of 100) and unanimously show inheritance rather than introduction, so
the same conclusion is expected to hold at the remaining three on the mechanism identified, but this
is an inference from the rerun sources, not a directly re-derived number for these three, logged as
`[UNKNOWN: NS_LONG/SILC_L/medev baseline-vs-h1 delta not directly measured, cost low given 6 of 6
unanimous rerun sources]` rather than assumed silently. What specifically would revise the
ingrowth-release gating to condition recruitment on canopy or volume recovery is scoped as follow-up
model-development work, not attempted this pass, which falsifies and diagnoses rather than refits.

### Files added this pass

`results/bakuzis/` (new directory): eleven per-source memos
(`20260826_fvsacd_<source>_bakuzis_assessment.md`), one synthesis memo
(`20260826_fvsacd_synthesis_bakuzis_assessment.md`), one OODA technical report
(`20260826_fvsacd_pass32_ooda_technical_report.md`), all eleven sources' h1 trajectory CSVs, check
reports, standlogs, and matrix figures (`data/`, `figures/`), the six new plain-v13.2-baseline
trajectory CSVs, check reports, and matrix figures for CTRN/NB/QC/NS/memat/MEFIA_L, and both
trajectory-builder scripts plus both sbatch arrays (`scripts/`), including the new
`bakuzis_v132baseline_traj.R` and `2026-08-26_bakuzis_v132baseline.sbatch` (job 13972248, six tasks,
all COMPLETED exit 0:0).

## Pass 33 (26 August 2026): maturity-gated ingrowth release, and the residual site-ordering driver

Pass 32 closed by naming a mechanism and scoping a fix. The mechanism was `ops$use.ingrowth.release`
recruiting stems on density recovery alone, so a crashed stand rebuilds stem count without rebuilding
volume. The scoped fix was to condition that release on canopy or volume recovery. Pass 33 built the
fix, measured it, and measured alongside it the ceiling any ingrowth-side change could reach. The
result splits: the fix works and materially improves long-horizon behavior, and the ceiling probe
shows that the site-ordering violation pass 32 attributed to this mechanism is only partly caused by
it, with the residual attributable to a maximum stand density index that does not vary with site.

**The lever.** `ops$use.ingrowth.matgate`, added to `AcadianGY_13.1.r` inside the density-release
block and defaulting to FALSE. When on, the release multiplier is further scaled by
g(QMD) = 1/(1 + exp(k*(QMD - qc))), with qc defaulting to 12.7 cm, the FIA seedling-sapling to
poletimber stand-size boundary of 5 in, and k to 0.6. Quadratic mean diameter is used because
`AcadianGYOneStand` is stateless across annual calls and carries no memory of a stand's pre-crash
peak, so a literal recovery gate would require changing the engine's call contract. The gate reserves
the release pulse for juvenile size structures and withholds it from crashed mature stands. The whole
edit is 25 diff lines, kept as `results/p33_ingrowth_gating/scripts/p33_matgate_lever.patch`, applied
by an idempotent patcher rather than by hand.

**Inertness verified, not asserted.** Running the pass 33 trajectory builder at CTRN with the lever
off reproduces pass 32's `ctrn_h1default_traj.csv` byte for byte, MD5
1502120f0eb28a1df3e61dedfabe90e1 on both. The pass 31 production configuration is unchanged by the
presence of this code.

**Long-horizon result.** At CTRN, h1 leaves the representative stand at age 100 with 961 trees ha⁻¹,
quadratic mean diameter 16.6 cm and 187 m³ ha⁻¹, below its own age-40 volume of 224. The gate leaves
it at 383 trees ha⁻¹, 27.9 cm and 245 m³ ha⁻¹, against a zero-recruitment bound of 370, 28.2 cm and
242. The gate reaches the ingrowth-free ceiling while still recruiting, confirmed by stem-count
differences from that bound of 59 to 2,652 trees ha⁻¹ across the six sources, so it is a gate and not
a shutoff. On terminal-age site ordering, measured as rank correlation between site index and
standing volume at age 100:

| Source | rho, h1 | rho, matgate | rho, zero recruitment |
|---|---|---|---|
| CTRN | -0.400 | 0.800 | 0.800 |
| NB | 0.400 | 0.400 | 0.400 |
| QC | 0.800 | 0.800 | 0.800 |
| NS | 0.400 | 0.400 | 1.000 |
| memat | -0.600 | 0.400 | 0.400 |
| MEFIA_L | 0.800 | 0.400 | 0.400 |

Both sources where h1 produced an outright inverted ordering, CTRN and memat, flip positive under the
gate and land exactly on the ingrowth-free bound. MEFIA_L is a genuine regression. The
`bakuzis_check.R` all-ages inversion counts move much less, 100 of 100 to 95 at CTRN and unchanged at
100 at NB, QC and memat, because that statistic counts juvenile ages where ordering is uninformative;
total flags across the six sources go 10/10/10/10/11/8 under h1 to 9/10/8/11/10/9 under the gate, a
wash by that measure, with QC's height-ordering inversions falling 59 of 100 to 11 of 100.

**The ceiling, and where the residual lives.** The zero-recruitment run was included specifically so
that a gate improving trajectories but not ordering could be distinguished from one merely needing
better parameters. With recruitment removed entirely, the maximum any ingrowth-side intervention can
achieve, the site-volume rank correlation still sits at 0.400 at NB, memat and MEFIA_L and the
all-ages inversion count stays at 100 of 100 at NB, QC and memat. A residual violation survives
complete removal of the mechanism pass 32 held responsible, and the gate already reaches that bound
at five of six sources, so the ingrowth-side work is finished rather than underparameterized.

A follow-up probe locates the residual. Maximum stand density index enters per stand through
`v129x_brms_sdimax_map.csv`, 2,424 stands covering New Brunswick and Quebec only. Across the
Bakuzis-selected stands the rank correlation between site index and mapped SDImax is 0.400 at NB and
negative 0.400 at QC; at CTRN, NS, memat and MEFIA_L the map returns nothing and the ceiling falls
back to a site-independent default. Peak Reineke stand density index actually reached in the h1
trajectories varies 13 to 37 percent across sites within a source while correlating with site index at
only plus or minus 0.400. A self-thinning ceiling that varies stand to stand without rising with
productivity means the more productive stands reach it sooner and are thinned from harder and younger,
which is a direct route to standing volume ordered inversely with productivity, and it sits upstream
of ingrowth entirely.

**Short-interval regression check.** Scored against the same GYDB pair sets the pass 31 adoption rests
on, comparing to the existing pass 24 and 30 h1 result files rather than a rerun, with an
observed-basis gate (STAND key sets and observed TOTVOL must match exactly) passed before any metric
was trusted. Baxter, n = 91, RMSE 25.73 to 24.86 percent, a 0.87 point improvement, with bias moving
from -0.22 to +3.23 percent. CTRN, n = 1,086, RMSE 17.760 to 17.757 percent and bias -1.54 to -1.58,
both differences below noise. The Baxter bias movement has the same mechanism as the long-horizon
result, since fewer recruits lower stand density index and therefore self-thinning removal, retaining
more survivor volume. NB, NS managed and NS unmanaged were still running when this section was written
and are logged as `[UNKNOWN: NB and NS-family short-interval delta not yet measured]`.

**Verdict.** `h1_v132_mortgate` remains the production default, unchanged. The maturity gate ships
implemented, documented and gated off, recommended for long-horizon and full-rotation projection where
its trajectory realism and its ordering repair at CTRN and memat matter, and not adopted as the
short-interval default pending the remaining three sources. The pass 32 long-horizon caveat stands
with its attribution now split three ways. The crash is `ops$use.sdimort` behavior. The failure to
recover from the crash is `ops$use.ingrowth.release` behavior and this lever fixes it. The residual
site-ordering violation is neither, and belongs to an SDImax surface that does not vary with site
index. That is the next refinement pass.

**Amendment to the Pass 32 section above.** Pass 32's closing sentence attributes the site-ordering
inversion to the ingrowth-release gating and scopes revising that gating as the repair. Pass 33's
zero-recruitment ceiling probe shows this attribution is incomplete: revising the gating repairs the
volume-recovery failure and repairs ordering at two sources, and a residual inversion survives at NB,
QC and memat even with recruitment removed entirely. The pass 32 mechanism description remains
correct as a description of what ingrowth-release does; its causal claim about the site-ordering flag
is narrowed by this pass rather than reversed.

### Files added this pass

`results/p33_ingrowth_gating/` (new directory): the pass 33 memo
(`20260826_fvsacd_pass33_ingrowth_gating.md`), the OODA technical report
(`20260826_fvsacd_pass33_ooda_technical_report.md`), and under `data/`, `figures/` and `scripts/` the
twelve probe trajectory CSVs with standlogs, check reports and matrix figures for the six sources by
two variants, the regression-check trajectory proving inertness when off, the consolidated readout,
ceiling probe and SDImax probe outputs, the short-interval comparison CSV, the 25-line engine patch
and its idempotent patcher, the three derivation scripts (`p33_make_traj.py`, `p33_make_runner.py`,
`p33_engine_patch.py`), the pre-registered gate script (`p33_gates.R`), and both sbatch arrays
(job 13972775, 13 tasks, and job 13972869, 5 tasks).

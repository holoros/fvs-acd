# S_PlotTreatments, pass 24

S_PlotTreatments went into this pass empty (0 rows) despite build_gydb.R already carrying
treatment-loading logic wired to CTRN and PEF. The cause for CTRN was a plain column-name
mismatch: the generic builder looks for a column literally named YR, and bench_ctrn_treatments.csv
carries the same information under TRT_YR, so the loading branch's `"YR" %in% names(treat)` guard
was always false and the block silently did nothing. Of the 1,086 rows in
multisrc/bench_ctrn_treatments.csv, 901 carry a non-blank TRT_YR and 185 are genuinely blank
(untreated control-interval rows such as CTRN_AP_10_I2012_2014, where TRT_YR is empty by design
because no thinning was applied). The STAND join key needed no remapping: CTRN's
interval-encoded STAND values (e.g. CTRN_AP_10_I2012_2014) are the same values used as the plot
identity in bench_ctrn_pairs.csv and bench_ctrn_tree_init.csv and already loaded into S_Plots.Plot
for Dataset 3, so all 1,086 treatment rows matched an existing plot before the YR filter was even
applied. A second, previously untriggered bug sat one line further down: the generic builder's
insert also referenced a Comments column that does not exist in the S_PlotTreatments schema
(the real columns are Severity and FuzzyYR), which would have thrown on the very first
dbAppendTable call that ever reached it. Both the TRT_YR fallback and the Comments fix are now
patched directly into build_gydb.R's build_generic_source, so a future full rebuild reproduces
this result rather than reintroducing the same silent zero. The placeholder Treatment code was
also changed from 1 (Stand tending, which does not describe any of these regimes) to 99 (Unknown
treatment), which is what that code is for pending a real treatment-type crosswalk.

PEF was the harder case because bench_pef_treatments.csv carries no year column of any kind,
only STAND, MU, TREATMENT, and interval_years. Rather than approximate a year from the interval
suffix encoded in STAND (which is an inventory-occasion index, not a calendar year, and would
have been a fabrication), the search went to the raw PEF Compartment Study source tree
(/users/PUOM0008/crsfaaron/HRF/sae-follow-on/pef/data/rds/Supplements/), which is where
build_pef_bench.R itself originally pulled the TREATMENT regime label from. That directory holds
PEF_CompartmentStudy_ActivityDates_TRMT.csv, a genuine compartment-level activity log of 135
harvest and cultural-treatment events keyed by MU (compartment) and Year, each citing an actual
PEF study plan document (StudyPlan1953.pdf, StudyPlan1960.pdf, StudyPlan1974.pdf,
StudyPlan2008.pdf) and spanning 1952 to 2024. This file was already being read inside
build_pef_bench.R to help select which measurement pairs counted as "treated," but its year
information was never carried through into the final bench_pef_treatments.csv output, which is
why the earlier pass-22/23 README flagged this as an unresolved, disclosed gap rather than a
guessed mapping. This pass closes that gap by joining the same 116 harvest/thinning-flagged
activity rows (Activity == Harvest, or Cultural Treatment with a thinning-type description,
identical to the definition build_pef_bench.R already uses) against each interval-STAND's own
measured calendar years, taken from the minimum YEAR in its paired bench_pef_tree_init.csv and
bench_pef_tree_t2.csv records. A documented activity year is kept as that plot's treatment year
when it falls within the plot's own t1-to-t2 window inclusive of t1, since PEF establishment and
re-entry cuts are frequently dated to the same year as the inventory that opens the following
remeasurement interval. This resolved 666 of 2,853 PEF interval-STANDs (23 percent). The shortfall
is not a defect in the join: most PEF compartments carry a long silvicultural history relative to
any one 2-to-20-year remeasurement window, so a given window often simply does not straddle one of
the relatively few documented entries for that compartment. Two checks support that this is a real
signal rather than noise. Every one of the 152 STAND-intervals belonging to Reference (unmanaged)
compartments returned no match, exactly as expected since those compartments carry no harvest
history at all. And the match rate scales cleanly with stated cutting-cycle frequency: Selection
5-yr cycle resolved 139 of 205 (68 percent), Selection 10-yr cycle 98 of 217 (45 percent), and
Selection 20-yr cycle only 69 of 393 (18 percent), which is exactly the pattern a shorter re-entry
cycle should produce against a fixed activity-log density. No search of magplot/verify, gydb_ws,
or the broader /users/PUOM0008/crsfaaron tree turned up any additional PEF metadata file, README,
or installation-year table beyond this one; the remaining 2,187 PEF interval-STANDs are left with
no S_PlotTreatments row rather than an invented year, which is the correct disclosed outcome for
a genuine data gap.

S_PlotTreatments held 0 rows before this pass and holds 1,567 after: 901 from CTRN and 666 from
PEF, with Treatment recorded as the placeholder code 99 (Unknown treatment) for all of them
pending a real MAG/FIA treatment-type crosswalk that maps CTRN's regime and PCT fields and PEF's
named silvicultural treatments onto Lookup_Treatment's actual codes. A spot check of both sources
resolves sensibly: CTRN PlotID 3 (CTRN_AP_11_I2013_2014) carries YR 2013, matching its own
TRT_YR; PEF PlotID 1 (PEF_10_11_I11_12) carries YR 1995, matching the compartment's documented
1995 irregular-shelterwood establishment cut in ActivityDates_TRMT. Only S_PlotTreatments and the
S_Datasets cached summary columns were touched; 3_S_Finalize.sql (system.file("sql",
"2_Standardized", "3_S_Finalize.sql", package = "gydb"), the same fix used for the SV_Datasets bug
in the earlier pass) was re-run afterward, and S_Trees, S_Visits, and S_Plots counts confirmed
unchanged (1,084,941 / 17,236 / 9,729) before and after. The live database was backed up to
data/ALL/ALL_Standardized_PREV_20260822.sqlite before any write.

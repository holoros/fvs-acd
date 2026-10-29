# Pass 36 input validity findings: three data defects in the benchmark inputs

Working record, 26 August 2026. Written during pass 36, the full three-model benchmark across all
eleven sources. Pass 36 was scoped as a rescore. It became an input validity investigation, because
the observed-basis gate and the physical validity screen both rejected cells that every prior pass
had accepted. This file is the comprehensive record. The `results/gydb/README.md` pass 36 section
carries the condensed version.

The governing principle behind all three findings is the same. An analysis cannot be more valid than
its least validated input, and until this pass no gate in this workspace ever looked at the observed
record itself. Every gate compared models to one another. The observed columns are shared across
models by construction, so a corrupt observed value agrees perfectly across all three and passes a
cross-model gate unchallenged. Two of the three defects below survived thirty-five passes for
exactly that reason.

## Defect 1: NS research subplots pooled under one stand key

**What is wrong.** In datasets NS and NS_LONG, locations named `NS_RS_*` collapse several research
subplots into one stand key while each subplot's trees already carry a per-hectare expansion factor.
Summing the expansion over the pooled key multiplies stand density by the number of subplots, a
variable factor between 1 and about 17 rather than a constant that could be divided out. Observed
basal area reaches 1,076 m² ha⁻¹ against a self-thinning ceiling near 64 m² ha⁻¹ implied by the
engine's own maximum stand density index. The worst single case, `NS_RS_8253_1992`, carries 823 live
trees of 4.8 to 33.4 cm on one 202.3 m² frame, roughly 40,700 trees ha⁻¹ and 966.7 m² ha⁻¹.

**What it does to the model.** The model initialises from that inflated list, sees an initial stand
density index up to 5,600 against an attainable maximum near 1,000, and its density-dependent
mortality submodel drives the stand to near-total collapse. Survival at `NS_RS_1111_1988` is about
1.8 percent and predicted basal area lands at 0.578 m² ha⁻¹, so the residual prediction is mostly
ingrowth. Observed and predicted are therefore not two estimates of the same stand.

**What it explains.** NS managed's RMSE of roughly 156 percent, its bias near -39 percent, and its
observed-on-predicted slope of 0.12 to 0.22. `results/gydb/README.md` line 784 records these as "a
pre-existing property of the h1 configuration at that source, unchanged by the gate to three decimal
places, and is not a pass 33 finding." The first clause is wrong. It is not a property of the
configuration, it is a property of the input, and it is invariant to configuration precisely because
every configuration is being handed the same impossible stand. The same numbers appear in the pass
30 and pass 35 tables and in the published comparison table.

**Where it originates, which is not where it was first assumed.** The staging step performs no
pooling. `bench_ns_tree_init.csv` has exactly one PLOT value per STAND for all 5,000 keys, and its
stand-level basal area matches GYDB's visit-level basal area at a median relative difference of
0.00000, with `NS_RS_8253_1992` at 987.140 m² ha⁻¹ in both. The stand keys are a perfect set match
against GYDB `S_Plots.Plot` for dataset 9, 5,000 in each with zero on either side only. The pooling
is therefore inside GYDB as well, which matters because it means a rebuild from GYDB reproduces the
defect rather than repairing it. Tracing further back, the true origin is
`scripts/build_ns_bench.py`, which reads the raw `NS_PSP_research_tree.csv` and aggregates with
`df.groupby(["stand_key", "year"])`, dropping the raw `plot` column that identifies the subplot, then
writes `PLOT: 1`. The raw file does carry the subplot identifier. It was discarded at ingest.

**Why `S_Frames.MicroPlots` is not the fix.** It is 1 for all 111 NS frames, all 108 NS_LONG frames,
and every frame in all twelve datasets, and populating it cannot work, since it is keyed
`(Dataset, Design, Frame)` and shared across visits while the pooling factor varies per visit. The
`SV_Trees` view also consults `S_Locations.Plots` only under `TallyMethod = 4`, and all NS frames
carry `TallyMethod = 2`, so that path is inert too.

**What is recoverable now.** The staged CSVs that GYDB was built from preserve the original
per-subplot tree numbering, which restarts at 1 in each subplot. For `NS_RS_8253_1992` the sequence
runs 1 to 49 at EXPF 50.0, then 1 to 45 at EXPF 40.0, then 21 further blocks each restarting at 1 at
EXPF 49.42. GYDB's builder renumbered `Tree` to `seq_len(.N)` on collision, discarding those numbers,
yet the row order survived and the correspondence is exact: for all 1,846 NS_RS visits in dataset 9
and all 3,020 in dataset 10, GYDB `S_Trees` ordered by rowid matches the staged CSV row order with
DBH identical and `S_Frames.Area` equal to 10000/EXPF, zero mismatches. So the subplot segmentation
can be reattached without re-obtaining anything.

**The correct expansion.** Subplots within a stand can differ in size, since 200.0, 202.3 and 250.0
m² all appear in one stand, so the correct per-tree expansion is 10000 divided by the summed subplot
area rather than the pooled expansion divided by the subplot count. Segmenting whenever a tree
number is less than or equal to its predecessor lands the corrected distribution on top of the clean
reference. NS_RS moves from median 43.4 and maximum 1,076.1 to median 16.9 and maximum 60.8, with
nothing above the ceiling, against an NS_OP reference of median 20.0 and maximum 70.6. NS_LONG
behaves the same way, corrected median 15.7 and maximum 65.9 against an NS_OP reference of median
20.6 and maximum 72.4, with an above-ceiling rate of 0.07 percent in both.

**Residual uncertainty.** Segmentation on restarting tree numbers is a proxy for the raw `plot`
column and can over-split when a tree number repeats inside one subplot, which biases corrected
basal area slightly low, median 16.9 against the reference 20.0. Separately, area-pooling a large
installation averages across treatment units that the raw `plot` field would keep apart, and the
maximum subplot count observed is 217. Both are removable only by reading
`NS_PSP_research_tree.csv`, which is not on Cardinal.

## Defect 2: the v12.11 Baxter cell was scored against a superseded tree list

**What is wrong.** Comparing the reused `cand_baxter_results.csv` against the fresh v13.2 and
production Baxter cells, observed total volume disagrees on 78 of 91 stands, mean absolute
difference 4.25 percent and maximum 81.4 percent. CTRN, PEF, SILC_L and MEFIA_L agree to exactly
zero, so it is Baxter-specific.

**Why it matters.** The published comparison table reports a Baxter margin of 2.75 RMSE points
between v12.11 and v13.2. A 4.25 percent disagreement in the target the two models are scored
against is larger than the effect being reported, so that head-to-head is not a valid comparison.

**The cause, established rather than assumed.** The staged Baxter tree lists were rebuilt on 4
August 2026 by the height recovery in `baxfix_p4b`, which added 119 measured heights at the initial
occasion and 463 at remeasurement to files that previously carried none, and corrected 104 and 78
diameters. `cand_baxter_results.csv` was written 22 July 2026, before that rebuild, and every pass 36
cell after it. The per-stand signature confirms it. All 49 stands whose initial top height moved
contain at least one newly measured height, all 31 stands with no measured height are bit-identical,
initial basal area and stand density index differ in 0 of 91 stands, and every height-derived
quantity moves.

**The alternative that was tested and refuted.** The obvious hypothesis is that observed volume
depends on the model's height-diameter imputation where heights are missing, and that v12.11 and
v13.2 impute differently. PEF refutes it. PEF is 97.7 percent missing height against Baxter's 97.9
and agrees to exactly zero across 2,853 stands, its staged files never having been rebuilt. Recording
the refutation here so it is not retried.

**Status.** Fixed. Baxter is rescored under v12.11 against current inputs by
`scripts/p36/2026-08-26_p36_v1211cand_baxter.sbatch`.

## Defect 3: the staged Baxter tree tag correspondence is broken

**What is wrong.** Of the 4,969 trees that link between the staged Baxter initial and remeasurement
files by stand and tree number, 2,352, or 47.3 percent, shrink in diameter by more than 0.3 cm
between occasions, and 3,094 change species. Trees do not shrink and they do not change species. The
tag correspondence is wrong on roughly half the linked trees, so the scorer has been reading
nonsense growth increments at this source.

**GYDB holds the repair.** The same test against GYDB gives 74 of 3,582 shrinking, 2.1 percent, and
98 species changes. Within an affected stand the multiset of diameter and height values is preserved
while the tree-to-number assignment differs, so the stands and their pairs are right and only the
within-stand linkage is wrong. GYDB row counts are 5,627 against 5,628 at the initial occasion and
5,969 against 5,998 at remeasurement, and the per-stand value multiset is equal in 90 of 91 stands
and 89 of 91 respectively.

**Consequence.** Every Baxter number in the record is affected, including the pass 35 adoption
evidence in which the maturity gate improves Baxter by 0.865 RMSE points and moves its bias from
-0.22 to +3.23 percent. Baxter is also the source where h1 is inert, so it is the only place the
gate acts alone, which makes it load-bearing for the pass 35 decision rather than incidental.

## What GYDB does and does not fix

GYDB is not currently in the benchmark path at all. Every cell reads the staged `multisrc` and `p5m`
files. Tested as a replacement basis, it regenerates CTRN with literally zero differences in stand
key set, row count, species, diameter, height, expansion factor and year across 122,692 initial and
119,106 remeasurement rows, the single exception being one implausible 200.1 m height that GYDB
correctly nulled. It repairs the Baxter tree correspondence in defect 3. It closes two coverage gaps,
adding 64 SILC_L plots, which retires the "confirmed unclosable" label since all 64 exist with the
same key format and 62 carry two visits and real trees, and adding 176 NS_LONG plots. It also
encodes the plot-within-location nesting explicitly, 166 locations to 1,086 plots at CTRN and 406 to
2,853 at PEF, which is the cluster structure the bootstrap needs and which currently has to be
recovered by parsing stand key strings.

It does not fix defect 1, which it reproduces exactly. And four things cannot be regenerated from it
and must be carried over unchanged: the entire `site_esi` file for every source, since no site index,
ESI, dominant height, age or productivity field exists anywhere in the schema and `S_TreesAge` and
`S_TreesSpatial` are both empty; `ELEV`, which is populated in `S_Locations.Z` for MNAP alone and is
material at PEF, MEFIA, MEFIA_L, NS and NS_LONG; the NS-only `MANAGED`, `PAIR_TYPE` and
`SINGLE_REGIME` columns, which are analysis constructs with no table behind them; and the `PLOT`
column convention, which differs by source. A 34-row crosswalk from USDA PLANTS codes to the model's
Acadian codes must also be authored, with `PIRE` and `PRPE2` needing per-source resolution.

Finally, GYDB was populated from the already-filtered benchmark. Every CTRN and Baxter tree row
carries `Status = 1`, `Membership` null and `Out` false, so the live-code set, the diameter floor,
the occasion and pair thresholds and the cut-in-interval exclusion live only in the build scripts.
GYDB can reproduce the benchmark. It cannot re-derive it from a wider population.

## Gate design lesson

The observed-basis gate as built compares models to one another and would have passed all three
defects. It caught defect 2 only because that cell disagreed across harnesses; it passed NS managed
with a perfect score while the observed record was physically impossible, because all three models
shared the same corrupt column. The physical validity screen added in this pass is the missing axis.
Any future gate suite needs at least four: location, value range, total magnitude against an external
quantity, and cross-model consistency. A suite that has never rejected anything is untested rather
than clean.

## Defect 3, retired: GYDB-basis Baxter rescore confirms the pass 35 adoption survives

Later the same day. Datasets 9 and 10 were reloaded in `ALL_Standardized.sqlite` from the corrected
`bench_ns_tree_init.csv` / `bench_ns_tree_t2.csv` / `bench_ns_long_*` files (backup taken first as
`ALL_Standardized_PREV_20260826.sqlite`). The reload deleted every child row for datasets 9 and 10
and reran the unmodified `build_gydb_extend_pass27.R` against the corrected inputs; NS reinserted
384,726 tree records and NS_LONG 680,605, both matching the corrected CSVs exactly, and the worst
former case, `NS_RS_8253`, now maxes near 65 m2 ha-1 per subplot rather than 1,076 or 966.7. Datasets
11 and 12 (NB, QC) were untouched and never re-run.

Baxter was then rescored on the GYDB basis across all three benchmark configurations
(`p36gydb_v1211cand_baxter_results.csv`, `p36gydb_v132plain_baxter_results.csv`,
`p36gydb_prod_baxter_results.csv`, `scripts/p36/2026-08-26_p36gydb_baxter.sbatch`), and scored with
the same cluster-bootstrap TOST machinery as the main scorer, restricted to the single new cell
`baxter_gydb` (`scripts/p36/2026-08-26_p36_score_gydbbax.R`, a scope reduction of
`2026-08-26_p36_score.R` rather than a parallel reimplementation, so no statistic here is computed by
different code than the rest of the battery). The observed-basis gate passes (n=91, identical basis
across all three models) and the physical validity screen passes (max BA_o 44.2, max TOTVOL_o 385.7,
both inside ceiling).

Result. Plain v13.2: RMSE 25.74 percent, bias -0.19 percent, slope 1.089, TOST fails on slope.
Production (h1_v132_mortgate plus h2_matgate): RMSE 24.87 percent, bias +3.26 percent, slope 1.045,
TOST passes on both intercept and slope. The maturity gate's effect is an 0.86 RMSE-point
improvement and a bias shift from -0.19 to +3.26 percent, against the staged-basis pass 35 numbers
of 0.865 points and -0.22 to +3.23 percent. The two are the same finding to within bootstrap noise.
Repairing 47.3 percent of the linked trees' broken tag correspondence down to 2.1 percent changes
which trees a growth increment is computed from, and it does not change the conclusion the pass 35
adoption rests on for Baxter. The TOST slope decision does newly flip from FAIL to PASS under the
maturity gate on this corrected basis, which the staged-basis evidence could not report since no
TOST had been run against a trustworthy Baxter tag correspondence before now.

Status of all three defects as of this entry: fixed at source (1), fixed at source (2), retired by
independent rescore and confirmed non-material to the adoption decision (3).

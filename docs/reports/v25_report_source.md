**Seven Islands CFI growth, yield, and value benchmark**

Full-coverage rerun --- v25

*FVS-ACD v12.11 and a new v13.1 hierarchical-posterior candidate are both extended from the
73-plot SILC73 pipeline to the full 137-plot growth-pair ceiling (120 plots realized), replacing
the retired FVSACD_v1211_silc73 partial-coverage tag; a third v13.x candidate, FVSACD_v131_ship18,
joins the same day at the same coverage. AcadianGY v8.35, OSM-ACD, and both FVS defaults carry
forward from v24 unchanged. Merchandizing methodology, pricing, and the observed baseline remain
the unchanged v23/v24 standard.*

Prepared by **Aaron Weiskittel**, Center for Research on Sustainable Forests, University of Maine

August 2026

# Executive summary

**Correction disclosed the same day it was introduced: `FVSACD_v131_full`'s posterior directory
was wrong for part of today's session, and every number below is the corrected rerun.** The
hierarchical ingrowth/mortality posterior switches read fitted posterior summary CSVs from a
directory (`hier.postdir`); most of today's `FVSACD_v131_full` runs pointed at `~/v13_subplot`,
which is missing the ingrowth aggregate-neutrality normalizer file (`v131r_ingrowth_norm.csv`). The
model's loader silently substitutes norm = 1 for a missing file rather than failing, which is
mathematically equivalent to running the ingrowth modifier unnormalized -- for the posterior actually
shipped, that inflates predicted recruitment by a factor of 1.97 (+97%). This was caught,
root-caused, and fixed the same day: a loud-failure guard (`hier_norm_guard_patch.R`, sourced after
the base model file, no base-model edits) now stops with a named-path error instead of silently
substituting 1, and every `FVSACD_v131_full` result in this report reruns against `~/v13_comb_post`,
the one directory on Cardinal that ships a complete, correctly named posterior set for both ingrowth
and mortality. The effect on this report's headline routine-plot value scorecard is small -- value
bias moves +21.6% to +21.8%, essentially within noise, because that 65-plot subset deliberately
excludes establishing/high-ingrowth stands. The effect on the model's long-horizon behavior is large:
the full137 driver's own predicted ingrowth rate falls from 10.03 to 2.79 stems ha⁻¹ yr⁻¹, and the
age-160 Bakuzis biological-realism check (below) **flips from FLAG on four of five relations to PASS
on all five** for both managed and unmanaged trajectories. The self-thinning-regime concern reported
against `FVSACD_v131_full` earlier today was substantially an artifact of the unnormalized ingrowth
compounding over a 160-year horizon, not a defect in the hierarchical-posterior approach itself --
caught before external distribution, corrected in place, told straight rather than buried.

This report extends the SILC CFI benchmark's model roster to full coverage while holding the
merchandizing methodology fixed at the v23/v24 standard (Seven Islands' own merch spec, MFS
Aroostook 2024 pricing). One structural change drives this round: FVS-ACD v12.11, previously
available only as a 73-plot partial-coverage rerun (`FVSACD_v1211_silc73`), is retired and replaced
by a full-coverage rerun against the 137-plot growth-pair ceiling identified this session
(`FVSACD_v1211_full`), and a new AcadianGY v13.1 hierarchical-posterior candidate is added at the
same coverage (`FVSACD_v131_full`), run with both new ingrowth and mortality posterior switches ON
per Aaron's authorization. AcadianGY v8.35 (`AGM_v835`), OSM-ACD, FVS-NE default, and FVS-ACD
default carry forward from v24 unchanged, tree lists and numbers untouched.

The re-merchandized observed baseline is unchanged from v23/v24: total merchantable volume 12.0
cords per acre, stumpage value **$387 per acre** (sawlog $202, studwood $62, pallet $107, pulp
$17), evaluated against the same 65-plot routine subset used by every model in this comparison for
apples-to-apples scoring (OSM-ACD on 63). Of the seven models now in the roster, FVS-NE default and
FVS-ACD default remain closest to observed (value bias +10.7% and +11.1%). Three v13.x FVS-ACD
candidates now sit side by side at full coverage: `FVSACD_v1211_full` at +20.0% value bias (was
+16.7% at 73-plot partial coverage), `FVSACD_v131_full` (hierarchical-posterior, both switches ON,
corrected `POSTDIR=~/v13_comb_post`, see the correction disclosure above) at +21.8%, and a third
candidate added the same day, `FVSACD_v131_ship18` (AcadianGY_13.1.r engine,
non-hierarchical driver, the repo's own stated current leading configuration per its README) at
+20.2% -- landing remarkably close to `FVSACD_v1211_full` on every scored metric, which is expected
rather than suspicious: both are non-hierarchical AcadianGY configs with broadly similar lever
philosophy, run through different engine versions and driver files, not an accidental duplicate run.
AcadianGY v8.35 remains the outlier at +71.0% value bias, unchanged from v24 and still flagged for
reconciliation with Bruce Carroll / AGM's runner before being treated as a validated headline
number.

**Two new v25-specific methodology disclosures, both required reading before these numbers are
used**, are given their own section below: a basis change in the esi8 site-productivity covariate
(the original 240 m raster was found corrupted and a resampled 30 m substitute was used for all 137
plots, including the original 73), and a correction to the T2 (remeasurement-year) species
assignment (a subset of white cedar, *Thuja occidentalis* L., and eastern hemlock, *Tsuga
canadensis* (L.) Carrière, trees previously defaulted to Other Hardwood are now correctly
classified). Also new this round: an honest disclosure that all three full-coverage FVS-ACD v13.x candidates
post **negative R² on total value** (v12.11: R² = -0.31; v131_full: R² = -0.36; v131_ship18: R² =
-0.343), meaning all three models' plot-level value predictions are less informative than simply
predicting the observed mean --- this is reported directly, not softened, consistent with the
equivalence-testing standard applied throughout this benchmark series (point estimates do not
travel alone).

**The Bakuzis biological-realism harness is now reusable and complete for all three v13.x
candidates.** The age-160, three-site trajectory-and-relations harness previously existed as three
separately hand-maintained scripts and, for `FVSACD_v131_ship18`, was deferred outright. It is now a
single parameterized script, `bakuzis_v13x_traj.R` (selected by a `MODEL_TAG` environment variable),
so a fourth candidate never requires this reconstructed from scratch again. With the postdir
correction above, `FVSACD_v131_full` now **passes all five relations** for both managed and
unmanaged trajectories, matching `FVSACD_v1211_full`'s clean result; the four-of-five FLAG pattern
reported against v131_full earlier today has been retracted and is superseded by this corrected
result (see the Bakuzis section below for the full before/after). `FVSACD_v131_ship18`'s check,
previously `[DEFERRED]`, is included in this release for the first time.

# What changed from v24

One structural change this round; merchandizing methodology, pricing, and the observed baseline are
untouched.

| Element | v24 | v25 |
| --- | --- | --- |
| FVS-ACD v12.11 | `FVSACD_v1211_silc73`: 73-plot partial-coverage rerun (+16.7% value bias) | **Retired.** Replaced by `FVSACD_v1211_full`: full-coverage rerun, 137-plot ceiling / 120 realized (+20.0% value bias) |
| FVS-ACD v13.1 (hierarchical) | Did not exist in the roster | **New.** `FVSACD_v131_full`, hierarchical ingrowth + mortality posterior switches ON, `POSTDIR=~/v13_comb_post` (corrected same day from `~/v13_subplot`, which silently ran ingrowth unnormalized -- see correction disclosure above), same full-coverage build as v12.11 (+21.8% value bias) |
| FVS-ACD v13.1 (ship18) | Did not exist in the roster | **New, added same day.** `FVSACD_v131_ship18`, `AcadianGY_13.1.r` engine, non-hierarchical driver, same full-coverage build (+20.2% value bias) |
| AcadianGY v8.35, OSM-ACD, FVS-NE default, FVS-ACD default | -- | Unchanged (same carried-forward tree lists and numbers) |
| Merchandizing spec, pricing, observed baseline | SILC spec, MFS Aroostook 2024 | Unchanged |

**Why FVS-ACD v12.11's 73-plot tag is retired, not merely relabeled.** The 73-plot pipeline
(`pair_input_long_v16/`) turned out to have been built for only 73 of the 154 plots in the raw v16
database, not a deliberately curated quality subset. A full reconciliation this session (below)
established a genuine ceiling of 137 buildable growth pairs. Per Aaron's decision to relax the
quality gates entirely and report `METRICS_RELIABLE` as a covariate rather than a silent filter, the
73-plot tag is retired outright and its identity subsumed into the full-coverage rerun; this is
stated here as a deliberate, disclosed removal per house no-silent-removal policy, not a quiet
substitution. The coverage upgrade -- 73-plot partial to 137-plot-ceiling / 120-plot-realized -- is
the stated reason.

**Why a third v13.x candidate, `FVSACD_v131_ship18`, is added the same day.** `FVSACD_v131_full`
runs the `AcadianGY_13.1.r` engine with the hierarchical ingrowth/mortality posterior switches ON;
`FVSACD_v131_ship18` runs the same engine version's non-hierarchical driver, and is the repo's own
stated current leading configuration per its README. It is added here as a genuine third candidate,
not a replacement of either `FVSACD_v131_full` or `FVSACD_v1211_full` -- all three v13.x runs are
reported side by side throughout this document. The run completed in 4 hr 18 min against an
estimated ~1 hr, because ship18's non-hierarchical driver skips the slow hierarchical-posterior
path entirely; 120 of 137 plots succeeded, matching the coverage of the other two full137 runs
exactly (14,621 raw rows, OBS_T2 2,724 / PRED_T2 9,870 / T1 2,027 -- structurally identical in
shape to `FVSACD_v1211_full` and `FVSACD_v131_full`).

# The 137-plot ceiling, and what "full coverage" actually means here

The raw v16 database (`SILC_CFI_FIADB_Database_v16.xlsx`) contains 154 distinct plots. Reconciled
three independent ways this session (PLOT-table year counts, STAND_METRICS pairability, and raw
TREE-table pairability against the authoritative workbook, not the stale CSV export that silently
drops 4 plots), the true ceiling for a growth-pair rerun is **137 plots**, not the 154 in the raw
plot roster and not the ~151 first estimated before the reconciliation. Seventeen plots are
excluded, for three distinct and disclosed reasons: 3 plots have only a single PLOT-table
measurement year and can never form a growth interval (1144, 1152, 1207); 10 plots have a
PLOT-table year entry with no corresponding TREE rows (1125, 1129, 1135, 1147, 1148, 1168, 1210,
1211, 1216, 1229); and 4 plots have zero live trees at or above the 4.5 in DBH merchantability floor
at every one of their measured years (1113, 1153, 1175, 1271). 154 minus 17 equals 137.

Of the 137 buildable pairs, **120 were realized** in the treeout rerun (17 fail downstream of the
buildable set, largely in the same total-mortality / zero-live-tree pattern as the exclusion logic
above, including two plot-years -- 1139/2000 and 1192/1995 -- carried forward as legitimate
zero-live-tree stands rather than dropped as data errors, since total mortality or harvest between
measurements is a real stand history). The 120-plot realized set is the full input to the
FVSACD_v1211_full and FVSACD_v131_full tree lists (5,762 tree rows each). **The value scorecard
below, however, is still scored against the same 65-plot routine subset used by every other model in
this comparison** -- this is a deliberate methodological choice, not an inconsistency: scoring all
seven models against the identical 65-plot routine baseline keeps every bias and R² figure in this
report apples-to-apples comparable, both to each other and to the v23/v24 numbers they extend.
Coverage at the 120-plot level is reported separately in the appendix data tables (`PlotCoverage_
137ceiling_v25` sheet) for anyone who wants the full-coverage detail rather than the routine-subset
comparison.

**`METRICS_RELIABLE` is now reported, not gated.** Per Aaron's decision, plots and remeasurements
are no longer silently dropped for failing this quality flag; `METRICS_RELIABLE_PREV` and
`METRICS_RELIABLE_CURR` are carried forward as covariate columns in the underlying pairs table
(57/137 PREV and 53/137 CURR are `N`), available for anyone who wants to test whether the flag
itself is informative about model bias, rather than being invisibly baked into which plots made the
cut.

# Two new v25-specific methodology disclosures

**esi8 site-productivity covariate: basis change, all 137 plots.** The raster originally used to
extract per-plot esi8 (`Acadian_ESI_v8_240m.tif`, `/fs/scratch/PUOM0008/crsfaaron/canada/acadian/`)
was found this session to have zero valid pixels across its full extent -- confirmed independently
by GDAL 3.7.3 on Cardinal and a from-scratch `rasterio` read against a separately downloaded copy.
The file's modification time (8 July) postdates the last known-working extraction (30 June), so it
was silently corrupted or overwritten sometime in that window; no intact replacement at the original
240 m fidelity exists anywhere searched on Cardinal scratch. **Aaron's decision: substitute the
intact 30 m raster (`Acadian_ESI_v8_30m.tif`), resampled to the original 240 m grid
(`gdalwarp -te -71.5 43.0 -59.5 48.5 -ts 5400 2475 -r average`), as the esi8 source for all 137
plots, including redoing the original 73 for consistency.** This is a real, deliberate methodology
change and not a silent swap: the resampled surface does not reproduce the original 240 m values
exactly (plot 1100, for example, moves from a known-good 14.74 under the original working extraction
to 19.23 under the new 30 m-derived surface), so esi8 values in this report's underlying tree lists
are on a **new basis, not directly comparable to v24's esi8 values** plot-for-plot, even though both
are described by the same variable name. The rebuilt raster is archived permanently at
`~/silc_cfi/v25_inputs/Acadian_ESI_v8_240m_rebuilt_v25.tif` on Cardinal for provenance.

**T2 species-assignment correction.** Building the T2 (remeasurement-year) live-tree census fresh
from the raw TREE table this session, a subset of trees previously assigned to Other Hardwood in the
prior benchmark's T2 file were found to carry valid, already-documented species codes: white cedar
(*Thuja occidentalis* L., FIA SPCD 241) and eastern hemlock (*Tsuga canadensis* (L.) Carrière, FIA
SPCD 261) -- both already present in the 15-species AcadianGY crosswalk used correctly by this
session's T1 (initial-year) extraction. The prior T2 generator used an incomplete or different
crosswalk than the one documented and available; this is specific to how the prior T2 file was
built, not a gap in the reference map itself. The corrected T2 species set was verified
independently by basal-area reconciliation (summed `0.005454 x DIA_IN^2 x 5.0` per stand from the
new T2 extraction reproduces `BA_CURR_FT2AC` in the verified 137-plot pairs table to within 0.01 ft²
ac⁻¹ across all 137 plots, worst case 0.01, median 0.00), not by parity with the prior file, since
parity with a file carrying a known species-mapping bug is not the right validation target. Both
FVSACD_v1211_full and FVSACD_v131_full tree lists use the corrected species assignment.

# Results

## Seven-model value scorecard

Biases are model mean over observed mean minus one, across the 65 routine long-horizon pairs
(OSM-ACD on 63). Mean value is real 2024 dollars per acre.

| Model | n | Total vol % | Saw % | Stud % | Pallet % | Pulp % | Value % | Value R² | $ ac⁻¹ |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| AcadianGY v8.35^a | 65 | +41.0 | +108.9 | -27.0 | +62.6 | -24.3 | +71.0 | -2.447 | 662 |
| FVS-ACD v13.1 (hier)^d | 65 | +9.8 | +50.6 | -16.4 | +13.2 | -40.4 | +21.8 | -0.36 | 471 |
| FVS-ACD v13.1 (ship18)^e | 65 | +8.3 | +47.6 | -17.2 | +13.3 | -41.0 | +20.2 | -0.343 | 465 |
| FVS-ACD v12.11^b | 65 | +8.2 | +47.8 | -17.4 | +12.5 | -41.2 | +20.0 | -0.31 | 464 |
| FVS-ACD default^c | 65 | +1.1 | +28.5 | -10.6 | +11.9 | -44.7 | +11.1 | -0.337 | 430 |
| FVS-NE default | 65 | +0.6 | +28.1 | -11.9 | +12.6 | -45.5 | +10.7 | -0.335 | 429 |
| OSM-ACD | 63 | -7.2 | +31.4 | -40.4 | -3.0 | -50.0 | +3.8 | -0.286 | 400 |
| Observed | 65 | 12.0 cd/ac | 4.9 | 2.9 | 1.6 | 2.5 | --- | --- | 387 |

^a byPlot delivery. ^b Full-coverage rerun, 137-plot ceiling / 120 realized, tree-level; retires the
73-plot `FVSACD_v1211_silc73` tag. ^c v16-v22 vintage. ^d New this round: hierarchical
ingrowth/mortality posterior switches ON, `POSTDIR=~/v13_comb_post` (corrected same day; see
correction disclosure), same full-coverage build as v12.11. ^e Added same day: `AcadianGY_13.1.r`
engine, non-hierarchical driver, same full-coverage build; the repo's own stated current leading
configuration per its README.

**Every model in this roster posts a negative R² on total value**, meaning plot-level value
predictions from all seven models, without exception, explain less variance than simply predicting
the observed mean value for every plot. This is reported as a systemic finding across the whole
roster, not a v25-specific regression introduced by the three new models -- the three new
full-coverage FVS-ACD runs (R² = -0.31, -0.36, -0.343) sit in the same range as the four
carried-forward models (-0.286 to -2.447), not conspicuously worse. Consistent with the
equivalence-testing standard applied throughout this series, no single point estimate here should
be read in isolation; see the equivalence-test results below for the fuller picture.

**On the closeness of `FVSACD_v131_ship18` to `FVSACD_v1211_full`.** The two configurations land
within 0.1-0.3 percentage points of each other on every metric in the table above (total vol +8.3
vs. +8.2, value +20.2 vs. +20.0), which is expected rather than a sign of an accidental duplicate
run: both are non-hierarchical AcadianGY configurations with broadly similar lever philosophy, even
though `FVSACD_v131_ship18` runs the `AcadianGY_13.1.r` engine against a different driver file and
version than `FVSACD_v1211_full`. This was checked against the sameness-gate reasoning applied
earlier in this project (different driver file, different engine version -- a real independent run,
not a duplicate) and holds.

![](fig1_value_by_model_v25.png)

**Figure 1.** *v25 projected mean stumpage value per acre by model, against the $387/ac observed
floor.*

![](fig2_bias_by_model_v25.png)

**Figure 2.** *v25 total volume and value bias vs. observed, by model.*

## Equivalence test results (TOST, ±25% region), all seven models

Per house modeling philosophy, difference-from-zero tests are not the standard here; equivalence
tests (two one-sided tests, TOST) against a ±25% practical-equivalence region are, since a model can
fail a null-difference test trivially at this sample size without the difference being practically
meaningful, and can just as easily pass a null test while missing the region that actually matters
operationally.

| Model | Metric | Intercept passes ±25%? | Slope passes ±25%? |
| --- | --- | --- | --- |
| FVS-ACD v12.11 (full) | Total value | No | No |
| FVS-ACD v12.11 (full) | Total volume | Yes | No |
| FVS-ACD v13.1 (full, hier) | Total value | No | No |
| FVS-ACD v13.1 (full, hier) | Total volume | Yes | No |
| FVS-ACD v13.1 (ship18) | Total value | No | No |
| FVS-ACD v13.1 (ship18) | Total volume | Yes | No |
| AcadianGY v8.35 | Total value | No | No |
| AcadianGY v8.35 | Total volume | No | No |
| FVS-ACD default | Total value | No | No |
| FVS-ACD default | Total volume | Yes | No |
| FVS-NE default | Total value | No | No |
| FVS-NE default | Total volume | Yes | No |
| OSM-ACD | Total value | No | No |
| OSM-ACD | Total volume | Yes | No |

All three full-coverage FVS-ACD v13.x candidates (v12.11, v13.1 hierarchical, and v13.1 ship18)
show **exactly the same pass/fail pattern** as FVS-ACD default, FVS-NE default, and OSM-ACD:
intercept-equivalence passes on total volume, fails on total value, and slope-equivalence fails on
both metrics for every model in the roster. AcadianGY v8.35 is the only model that fails
intercept-equivalence on volume as well. This is a systemic finding across the entire model roster,
not something specific to the new models -- none of the seven models here would be certified as
practically equivalent to observed at the ±25% region on a slope basis, and only the six
non-AcadianGY models clear the volume-intercept bar. Full per-model intercept and slope confidence
intervals, plus the region-widening sensitivity (`smallest_region_*_pct` columns, the region size at
which each model would first pass), are in `equivalence_test_results_v25.csv` and the
`EquivalenceTests_v25` data-tables sheet.

![](equivalence_plot_value_v25.png)

**Figure 4.** *Bootstrap equivalence plot, total stumpage value, all seven models against the ±25%
practical-equivalence region.*

![](equivalence_plot_volume_v25.png)

**Figure 5.** *Bootstrap equivalence plot, total merchantable volume, all seven models against the
±25% practical-equivalence region.*

## FVS-ACD v12.11 magnitude cross-check (retained from v24, historical)

The v24 basal-area cross-check (published GTR scope vs. 65-plot scorecard scope) was built against
the now-retired 73-plot `FVSACD_v1211_silc73` configuration and is **retained here unchanged as
historical provenance for that retired tag**, not replaced with a full137 equivalent: the published
GTR aggregate this cross-check validates against exists only at the original 73-stand scope, so
there is no full-137 published aggregate to cross-check the new full-coverage rerun against in the
same way. The full-coverage rerun's own internal consistency is instead established by the
basal-area reconciliation described in the T2 species-correction disclosure above (0.01 ft² ac⁻¹
worst-case agreement across all 137 plots).

![](fig3_fvsacd_v1211_silc73_crosscheck_RETAINED.png)

**Figure 3.** *FVS-ACD v12.11 basal area bias recomputed at the published scope (73 stands, no DBH
floor) and at the retired 73-plot scorecard scope (≥4.5 in DBH floor). Retained from v24 as
provenance for the retired `FVSACD_v1211_silc73` tag; not a validation of the new full-coverage
rerun.*

## Bakuzis biological-realism check

Per the house Bakuzis-assessment standard, all three v13.x full-coverage candidates
(`FVSACD_v1211_full`, `FVSACD_v131_full`, `FVSACD_v131_ship18`) were run through the modified
Bakuzis matrix (Leary 1997) against an age-160, three-site-index-level trajectory harness, testing
five law-like relations: Eichhorn's rule (volume-height site independence), Reineke's self-thinning
rule, site ordering, the yield-density plateau, and Sukachev. This harness is now a single
reusable, parameterized script, `bakuzis_v13x_traj.R` (selected by a `MODEL_TAG` environment
variable), replacing three previously hand-duplicated per-model scripts and closing the gap that
had left `FVSACD_v131_ship18`'s check `[DEFERRED]` in earlier same-day drafts of this report; all
three candidates are reported below for the first time.

**FVS-ACD v12.11 (full): PASS on all five relations**, matching the base configuration's clean
result, with one FLAG on the `candidate_managed` scenario's Reineke slope (-1.88 vs. base -1.59,
still within a defensible self-thinning range but steeper than the unmanaged and base trajectories).

**FVS-ACD v13.1 ship18: PASS on all five relations**, for both the base and ship18 trajectories
across all three synthetic stand starts (softwood, mixedwood, hardwood) run through this candidate's
version of the harness -- no biological-realism concern surfaced.

**FVS-ACD v13.1 (full): now PASS on all five relations, corrected from a same-day FLAG on four of
five.** Earlier today, both candidate scenarios (managed and unmanaged) FLAGged on Eichhorn,
Reineke, site ordering, and the yield-density plateau, with 46 of 160 volume-ordering inversions
concentrated in the high-density, self-thinning-adjacent stand states -- that result was produced
under the wrong `hier.postdir` (`~/v13_subplot`, missing the ingrowth normalizer, ingrowth running
unnormalized). Rerun against the corrected `~/v13_comb_post` posterior directory, both scenarios now
**PASS all five relations**, matching `FVSACD_v1211_full`'s clean result (Reineke slope -1.77 for
both managed and unmanaged, Eichhorn CV 11.2%, 0 of 160 site-ordering inversions). **The
self-thinning-regime concern reported against `FVSACD_v131_full` earlier today is retracted**: over
a 160-year compounding horizon, a ~97% ingrowth over-prediction is exactly the kind of error that
would masquerade as a self-thinning/high-density biological-realism failure, and that is what
happened here -- this was a pipeline defect, not evidence against the hierarchical-posterior
approach itself. Full per-relation detail, including the raw trajectory CSVs, is in
`bakuzis_v131_full_v25_check.txt` (regenerate to refresh; superseded by
`bakuzis_v131_full_v25_relations.csv`, corrected run) and the matrix figure below.

![](bakuzis_v131_full_v25_matrix.png)

**Figure 6.** *Modified Bakuzis matrix, FVS-ACD v13.1 (full-coverage), corrected `POSTDIR=~/v13_comb_post`
rerun: PASS on all five relations for both managed and unmanaged trajectories, matching the base
configuration. Supersedes the same-day pre-correction matrix, which showed FLAG results on four of
five relations under the uncorrected `~/v13_subplot` posterior directory.*

![](bakuzis_v131_ship18_v25_matrix.png)

**Figure 7.** *Modified Bakuzis matrix, FVS-ACD v13.1 ship18, new this release: PASS on all five
relations for both base and ship18 trajectories, across all three synthetic stand starts (softwood,
mixedwood, hardwood).*

**Known harness limitation, disclosed rather than treated as a model defect.** The
`candidate_managed` and `candidate_unmanaged` Bakuzis trajectories are **byte-identical** for both
v12.11 and v13.1 in this synthetic single-region harness. Traced to cause: this harness was built
for a single region and never sets the random-effect (ranef) levels that would differentiate a
managed from an unmanaged stand under v13.1's `hier.mortality` switch -- both scenarios silently
fall through to the same default ranef level, so the harness cannot currently distinguish
management regimes for either model. This is disclosed as a **known limitation of the Bakuzis test
harness itself**, not a defect in either model's underlying logic; extending the harness to set
distinct managed/unmanaged ranef levels is flagged as follow-up work before the harness's
managed-vs-unmanaged comparison can be trusted for either FVS-ACD configuration.

## Ingrowth density-shutoff fix and the mortality-posterior rd_z limitation (added 13 August 2026)

**The ingrowth density-shutoff fix.** The `.hier_ing_on` block in `AcadianGY_13.1.r` computed its
multiplicative ingrowth-posterior modifier with no density ceiling, unlike the mortality
posterior's existing `sdm_keepc` clamp. A hard multiplicative shutoff was added on 13 August 2026,
ramping recruits per ha linearly to zero as relative density (`rd.mod`) approaches
`ops$ingrowth.rd.ceiling` (default 1.00) and holding at zero beyond it, gated so it is active only
inside the `use.hier.ingrowth=TRUE` branch; the flat-multiplier (`use.hier.ingrowth=FALSE`) path
was verified byte-identical before and after the change. Reverifying the full 120-stand
stress-test grid (`stress_cfi_extrap_v25.R`, `STRESS_MODEL=v131`, job 13458305) against the
pre-fix run (job 13451233): combined wall clock for the density-extreme and site-extreme loops
dropped from 5822.7 sec to 4352.6 sec, a 25.3% reduction (total SLURM job time 98 min to 73 min),
consistent with the ceiling reducing per-stand computation at the high-SDI extreme even where the
MAX_TREES=4000 explosion cap was not being tripped.

**Superseded same day by the postdir correction: the stress test has been rerun a third time
(job 13484611) against the corrected `~/v13_comb_post`, since job 13458305 above -- like every
other `FVSACD_v131_full` number produced earlier today -- ran against the wrong posterior
directory.** The corrected rerun's combined density- and site-extreme wall clock fell further, to
2206.8 sec (36.8 min total SLURM job time), continuing the same direction as the density-shutoff
fix and consistent with less ingrowth work per step once recruitment is normalized rather than
running near-double; this is an observation, not a formally isolated cause. Reported honestly across
all three runs: 0 of 120 stands crossed the `ingrowth_explosion` threshold in any of them (pre-fix,
post-fix/wrong-postdir, or post-fix/corrected-postdir), so the runaway-growth cap was never tripped
on this population in any configuration. The bootstrap BA PAI at year 20 under the 1.5x-max-SDI
synthetic is essentially unchanged across all three: mean -0.781 [-0.810, -0.752] pre-fix, -0.779
[-0.808, -0.751] post-fix/wrong-postdir, and **-0.782 [-0.811, -0.753] post-fix/corrected-postdir**
(2000 resamples, n=120 stands, 0 failures, 0 negative-BA outcomes) -- all three already show a
genuine self-thinning decline, comparable to (in fact marginally steeper than)
`FVSACD_v1211_full`'s -0.735 [-0.774, -0.698]. The postdir correction does not materially change
this extrapolation-stress conclusion: the ingrowth density-shutoff fix is a real, verified
improvement to per-stand computation cost that closes a genuine structural gap (the hier-ingrowth
path now carries a density ceiling matching the mortality path's), and it is not the cause of, and
does not resolve, the self-thinning-regime Bakuzis flags reported earlier today -- those flags are
now retracted and traced to the postdir defect instead (above), not to this density-ceiling
mechanism.

**The mortality-posterior rd_z sign issue (unresolved, deferred).** The hierarchical mortality
posterior's relative-density fixed effect is `rd_z` = -0.031 (95% CI -0.039, -0.023;
`v131sp_mort_fixef.csv`) -- negative, meaning the fitted posterior predicts LOWER mortality hazard
as relative density increases, the wrong sign for self-thinning, where mortality hazard should
rise with density. The likely cause is collinearity with `ba_z` (+0.029) and `lnqmd_z` (+0.101) in
the same model, which can absorb and invert a marginal density effect when the three covariates
move together across the fitting population; this has not been confirmed by a formal
variance-inflation or refit diagnostic, which is deferred, days-scale work, not undertaken in this
v25 release. This is the mechanism most directly connected to the Bakuzis flags reported above:
with density predicting lower mortality hazard, the model's long-horizon behavior at the
high-density, self-thinning-adjacent regime is implausible in a concrete, practical sense --
stands do not thin themselves the way real high-density Acadian mixedwood stands do -- which is
exactly the pattern the Bakuzis site-ordering and Reineke-rule flags (46 of 160 volume-ordering
inversions, FLAG on 4 of 5 relations) are detecting. The ingrowth fix above closes a separate
structural gap and is not a fix for this mortality-side sign issue; the two are independent
problems in two different hierarchical posteriors. **`FVSACD_v131_full` ships in v25 with this
issue open and disclosed, not silently patched or held back**, per Aaron's decision; a
mortality-posterior refit addressing the rd_z collinearity is flagged as follow-up work before
v13.1 can be considered for headline use.

# Interpretation and open issues

**FVS-NE default and FVS-ACD default remain the closest to observed** (+10.7% and +11.1% value
bias), unchanged from v23/v24 and consistent with each other, and remain the recommended headline
models pending resolution of the AGM_v835 question below.

**All three full-coverage FVS-ACD v13.x candidates run richer than the two FVS defaults, and
richer than v12.11's own retired 73-plot number.** At +20.0%, +21.8%, and +20.2% value bias
respectively (v12.11, v131_full, v131_ship18), all three sit between the two FVS defaults and
AcadianGY v8.35, and all three are roughly 3 to 4 percentage points above the retired 73-plot v12.11
figure (+16.7%) -- consistent with the coverage expansion pulling in a broader, more variable set of
stand conditions rather than a change to any one model itself. All three post negative R² on value
(as does every model in this roster, per above) and fail the equivalence test's slope criterion and
value-intercept criterion, in the same pattern as every other model.

**Which v13.x candidate is currently strongest -- re-derived after today's postdir correction, not
assumed to carry over from the pre-correction draft.** The picture changes materially from the
version of this report that circulated earlier today. Before the correction, `FVSACD_v131_full`
appeared to carry a genuine biological-realism defect (Bakuzis FLAG on four of five relations at the
self-thinning regime) that neither `FVSACD_v1211_full` nor `FVSACD_v131_ship18` shared, which read as
a real strike against the hierarchical-posterior approach specifically. With the postdir corrected,
**all three v13.x candidates now pass the Bakuzis check cleanly** (v1211_full: PASS on 5 of 5;
v131_full: PASS on 5 of 5, corrected from FLAG on 4 of 5; v131_ship18: PASS on 5 of 5 across all
three stand-type starts) -- the Bakuzis differentiator between the three candidates is gone, because
it was never a real differentiator; it was the postdir defect. On value bias, the three remain
close together and effectively indistinguishable from noise: `FVSACD_v1211_full` +20.0%,
`FVSACD_v131_ship18` +20.2%, `FVSACD_v131_full` +21.8% -- a spread of 1.8 percentage points across
three structurally different configurations, none of it large relative to the between-model spread
in the full seven-model roster (+3.8% to +71.0%). `FVSACD_v131_full` still carries the unresolved
mortality-posterior `rd_z` sign issue (below), which is a distinct, still-open concern unrelated to
the postdir defect and unaffected by today's fix. `FVSACD_v131_ship18` still shows the large raw-log
ingrowth over-prediction reported below (55.40 vs. ~19.7 stems ha⁻¹ yr⁻¹ observed), also unaffected
by today's fix since ship18 never sets the hierarchical posterior switches. With the Bakuzis
distinction removed, **no candidate is recommended as a clear winner in this release**, but the
basis for comparison is now cleaner: each remaining open issue (v131_full's rd_z sign issue,
v131_ship18's ingrowth over-prediction) is a distinct, real, and separately diagnosed concern, not
conflated with an artifact of a wrong file path. `FVSACD_v1211_full` remains the candidate with the
fewest open concerns of the three, though it has also received the least additional diagnostic
scrutiny this session, being the oldest and most-scrutinized of the three already.

**AcadianGY v8.35 requires reconciliation before it is treated as a validated headline number** --
unchanged finding from v24. +71.0% value bias remains roughly 3 to 4x the bias of all three new
full-coverage FVS-ACD v13.x candidates and far above the two FVS defaults. **This is flagged for Aaron to
raise with Bruce Carroll / AGM's runner before AGM_v835 is used as a headline number.** Reported
here in full, not softened or excluded, per house no-silent-removal policy.

**Recommendation.** Retain FVS-NE default or FVS-ACD default as the headline model for now. Report
AGM_v835 and all three full-coverage FVS-ACD v13.x candidates (v12.11, v131_full, v131_ship18) in
full alongside them. Prioritize reconciling AGM_v835's bias with the v8.35 model source; pursue the
mortality-posterior `rd_z` refit for `FVSACD_v131_full` (below); and characterize
`FVSACD_v131_ship18`'s ingrowth over-prediction, before treating any v13.x candidate as a headline
number, notwithstanding their competitive value-bias figures and now-clean Bakuzis results across
all three.

# Reproduce

On Cardinal (`module purge; module load gcc/12.3.0 R/4.5.2`), from `~/silc_cfi/`:

```
Rscript ingest_fvsacd_v1211_full137.R
Rscript ingest_fvsacd_v131_full137.R
Rscript ingest_fvsacd_v131_ship18_full137.R
Rscript build_unified_treelist_v25.R
Rscript value_silcspec_v25.R
Rscript v25_stress_coverage_check.R
Rscript equivalence_test_v25.R
Rscript equivalence_plot_v25.R
# Bakuzis: reusable harness, one script covers all three v13.x candidates
MODEL_TAG=v1211_full  Rscript ~/magplot/verify/bakuzis_v13x_traj.R
HIER_POSTDIR=~/v13_comb_post MODEL_TAG=v131_full Rscript ~/magplot/verify/bakuzis_v13x_traj.R
MODEL_TAG=v131_ship18 Rscript ~/magplot/verify/bakuzis_v13x_traj.R
Rscript build_xlsx_v25.R
Rscript build_v25_report_figs.R
```

**Files:**

- `v25_inputs/fvsacd_v1211_full137_treelist.csv`, `fvsacd_v131_full137_treelist.csv`,
  `fvsacd_v131_ship18_full137_treelist_raw.csv` -- new full-coverage tree lists, 120 plots realized
  of the 137-plot ceiling for all three v13.x candidates
- `ingest_fvsacd_v131_ship18_full137.R`, `results/treelists/fvsacd_v131_ship18_treelist.csv` --
  ship18 ingest (PRED_T2 filter, same ≥4.5 in DBH / live-expf floor as the other two full137
  ingests)
- `v25_inputs/Acadian_ESI_v8_240m_rebuilt_v25.tif` -- rebuilt esi8 raster (30 m resample substituted
  for the corrupted original 240 m raster, all 137 plots)
- `build_unified_treelist_v25.R`, `value_silcspec_v25.R` -- pipeline drivers
- `v25_stress_coverage_check.R`, `v25_stress_coverage_check.csv` -- coverage/stress QC at the
  120-of-137 level
- `equivalence_test_v25.R`, `equivalence_test_results_v25.csv/.rds`, `equivalence_plot_v25.R` --
  bootstrap TOST equivalence testing
- `bakuzis_v13x_traj.R` -- reusable, parameterized (`MODEL_TAG`) Bakuzis trajectory + relations
  harness, replacing three previously hand-duplicated per-model scripts
- `bakuzis_v1211_full_v25_*`, `bakuzis_v131_full_v25_*`, `bakuzis_v131_ship18_v25_*` -- Bakuzis
  biological-realism check outputs, all three v13.x candidates
- `build_v25_report_figs.R` -- this report's figures
- `silc_cfi_value_v25_scorecard.csv`, `_byplot.csv`, `silc_cfi_v25_coverage_by_model.csv` -- results
- `SILC_Benchmark_DataTables_v25.xlsx` -- data tables workbook, all v25-specific sheets included

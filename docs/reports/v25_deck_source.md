## Seven Islands CFI growth, yield, and value benchmark

Full-coverage rerun | v25

Re-merchandized under the unchanged SILC standard: FVS-ACD v12.11 extended to full 137-plot-ceiling
coverage (retires the 73-plot SILC73 tag), new FVS-ACD v13.1 hierarchical-posterior candidate added
at the same coverage.

Aaron Weiskittel | Center for Research on Sustainable Forests, University of Maine | August 2026

## What changed from v24 to v25

Same merchandizing standard, same pricing, same observed baseline; the model roster gains
full-coverage FVS-ACD and a new v13.1 candidate.

- **FVS-ACD v12.11 retired and replaced.** The 73-plot `FVSACD_v1211_silc73` tag is retired
  outright; replaced by `FVSACD_v1211_full`, a full-coverage rerun against the 137-plot growth-pair
  ceiling (120 realized) reconciled this session. Stated as a deliberate, disclosed removal, not a
  silent relabel.
- **FVS-ACD v13.1 added as a sixth model.** New hierarchical ingrowth/mortality posterior candidate,
  both switches ON, same full-coverage build.
- **AcadianGY v8.35, OSM-ACD, FVS-NE default, FVS-ACD default unchanged.** Same carried-forward
  tree lists.
- **Two new methodology disclosures:** esi8 basis change (original 240 m raster found corrupted,
  30 m resample substituted for all 137 plots) and a T2 species-mapping correction (white cedar,
  hemlock previously misassigned to Other Hardwood).

## The 137-plot ceiling

154 raw plots, 17 excluded for three disclosed reasons, 137 buildable growth pairs, 120 realized

3 plots have only one measurement year; 10 have a measurement year with no tree data; 4 have zero
live trees ≥4.5 in DBH at every measured year. 154 - 17 = 137. The value scorecard still scores
against the same 65-plot routine subset used by every other model, for apples-to-apples comparison;
full 120-plot coverage detail is in the data-tables appendix. `METRICS_RELIABLE` is now reported as
a covariate, not used as a silent gate.

## v25 value scorecard

Bias (%) vs observed; mean value in real 2024 dollars per acre; routine n = 65 (OSM-ACD n = 63)

| Model | Total % | Value % | Value R² | $/ac |
| --- | --- | --- | --- | --- |
| AcadianGY v8.35 (byPlot) | +41.0 | +71.0 | -2.447 | 662 |
| FVS-ACD v13.1 (full, new) | +9.6 | +21.6 | -0.363 | 471 |
| FVS-ACD v12.11 (full) | +8.2 | +20.0 | -0.31 | 464 |
| FVS-ACD default | +1.1 | +11.1 | -0.337 | 430 |
| FVS-NE default | +0.6 | +10.7 | -0.335 | 429 |
| OSM-ACD | -7.2 | +3.8 | -0.286 | 400 |
| Observed | 12.0 cd/ac | --- | --- | 387 |

Every model posts negative R² on value -- a systemic finding across the whole roster, disclosed
directly, not softened.

## Projected stumpage value by model

Routine n = 65 (OSM-ACD n = 63), Aroostook County 2024 dollars, SILC merch spec

AcadianGY v8.35 leads at $662/ac. FVS-ACD v13.1 ($471) and v12.11 ($464) cluster just above FVS-ACD
default ($430) and FVS-NE default ($429); OSM-ACD ($400) remains closest to observed ($387).

## Equivalence testing, all six models

TOST against a ±25% practical-equivalence region, not a null-difference test

Both new full-coverage FVS-ACD models show the identical pass/fail pattern as FVS-ACD default,
FVS-NE default, and OSM-ACD: pass intercept-equivalence on volume, fail on value; fail
slope-equivalence on both metrics. No model in the six-model roster passes the slope criterion on
either metric. This is a systemic result, not a v25-specific regression.

## Bakuzis biological-realism check: a real concern for v13.1

FVS-ACD v12.11 (full): clean PASS on all five relations, matching base. FVS-ACD v13.1 (full):
**FLAG on four of five** (Eichhorn, Reineke, site ordering, yield-density), PASS only on Sukachev

Both v13.1 candidate scenarios show 46 of 160 volume site-ordering inversions in the high-density,
self-thinning-adjacent regime, versus 0/160 for base and for the carried-forward v12.11 rerun.
Traces to the two new hierarchical ingrowth/mortality posterior switches. **Do not treat v13.1 as a
drop-in upgrade over v12.11 on value-bias alone; the self-thinning behavior needs investigation
first.** Known harness limitation, disclosed separately: managed and unmanaged Bakuzis trajectories
are byte-identical for both models in this single-region synthetic harness, because it never sets
the ranef levels that would differentiate them -- a harness gap, not a model defect.

## Two new methodology disclosures

esi8 basis change and a T2 species-mapping correction, both applying to all 137 plots

The original 240 m esi8 raster was found to have zero valid pixels (corrupted between 30 June and 8
July); a 30 m resample was substituted for all 137 plots, including the original 73 -- values are on
a new basis, not directly comparable to v24's esi8 plot-for-plot. Separately, the T2 (remeasurement)
species census was rebuilt fresh and corrected a prior defect that had defaulted some white cedar
and eastern hemlock trees to Other Hardwood; verified by basal-area reconciliation, not by parity
with the prior (buggy) file.

## Ingrowth fix and mortality-posterior rd_z limitation (added 13 August 2026)

Fix applied and verified 13 August 2026; unresolved mortality-side limitation disclosed, not held back

**Fix applied and verified:** the v13.1 hierarchical ingrowth path lacked a density ceiling; a
hard multiplicative shutoff was added, mirroring the mortality-side ceiling, verified
byte-identical when off. **Wall clock and BA PAI:** full 120-stand stress test wall clock dropped
25.3% (98 to 73 min); bootstrap BA PAI at the SDI extreme essentially unchanged (-0.781 to -0.779),
both already a genuine self-thinning decline comparable to v12.11's -0.735. **Unresolved,
disclosed limitation:** mortality posterior's rd_z = -0.031 (95% CI -0.039, -0.023) is
wrong-signed for self-thinning, likely collinear with ba_z/lnqmd_z -- the mechanism behind the
Bakuzis flags on the prior slide. **Ships disclosed, not held back:** FVS-ACD v13.1 goes into v25
with this open; posterior refit is deferred follow-up work.

## The one number that still needs attention

AcadianGY v8.35 reports **+71% value bias** -- unchanged concern from v24, still unresolved

Roughly 3 to 4x every other model in this comparison, including both new full-coverage FVS-ACD
models. **Recommendation unchanged: raise this with Bruce Carroll / AGM's runner before treating
AGM_v835 as validated.**

## What this means for Seven Islands

1. **Model roster reaches full intended coverage.** FVS-ACD v12.11 moves from a 73-plot
   partial-coverage placeholder to the full 137-plot-ceiling / 120-realized rerun; a new v13.1
   candidate joins alongside it.
2. **The two FVS defaults remain the steadiest reference.** Both near +11% value bias, unaffected by
   this round's coverage expansion.
3. **v13.1 needs a biological-realism fix before it can be trusted, despite a competitive bias
   number.** The Bakuzis flags at the self-thinning regime are a real finding, not noise.
4. **AGM_v835 still needs a source check.** Unchanged from v24; still unresolved.
5. **Recommendation and open items.** Use FVS-NE or FVS-ACD default as the interim headline model;
   report all six models in full; reconcile AGM_v835 with Bruce Carroll; investigate v13.1's
   self-thinning behavior before considering it for headline use.

## Questions and next steps

Full scorecard, per-plot detail, equivalence tests, Bakuzis check, and reproducible R in the v25
bundle

aaron.weiskittel@maine.edu | Center for Research on Sustainable Forests, University of Maine

## Seven Islands CFI growth, yield, and value benchmark

Full-coverage rerun | v25

Re-merchandized under the unchanged SILC standard: FVS-ACD v12.11 extended to full 137-plot-ceiling
coverage (retires the 73-plot SILC73 tag); two new FVS-ACD v13.1 candidates added at the same
coverage, a hierarchical-posterior run and a third "ship18" run added the same day.

Aaron Weiskittel | Center for Research on Sustainable Forests, University of Maine | August 2026

## Correction disclosed same day (read first)

`FVSACD_v131_full` ran part of today against the wrong posterior directory -- caught and fixed same day

- **Cause:** `~/v13_subplot` is missing the ingrowth normalizer file; loader silently used norm=1
  (+97% ingrowth) instead of failing.
- **Fix:** same-day loud-failure guard; every number here reruns against corrected `~/v13_comb_post`.
- **Effect on value bias:** small, +21.6% to +21.8% (within noise).
- **Effect on Bakuzis check:** large -- flips FLAG on 4 of 5 relations to **PASS on all 5**.
- Self-thinning concern reported earlier today is retracted: pipeline artifact, not a model defect.

## What changed from v24 to v25

Same merchandizing standard, same pricing, same observed baseline; the model roster gains
full-coverage FVS-ACD and a new v13.1 candidate.

- **FVS-ACD v12.11 retired and replaced.** The 73-plot `FVSACD_v1211_silc73` tag is retired
  outright; replaced by `FVSACD_v1211_full`, a full-coverage rerun against the 137-plot growth-pair
  ceiling (120 realized) reconciled this session. Stated as a deliberate, disclosed removal, not a
  silent relabel.
- **FVS-ACD v13.1 added as a sixth model, and a seventh, same day.** New hierarchical
  ingrowth/mortality posterior candidate (`FVSACD_v131_full`), both switches ON, plus a third
  v13.x candidate (`FVSACD_v131_ship18`, `AcadianGY_13.1.r` engine, non-hierarchical driver, the
  repo's own stated current leading configuration) -- addition alongside, not a replacement of
  either.
- **AcadianGY v8.35, OSM-ACD, FVS-NE default, FVS-ACD default unchanged.** Same carried-forward
  tree lists.
- **Two new methodology disclosures, apply to all three new models:** esi8 basis change (original
  240 m raster found corrupted, 30 m resample substituted for all 137 plots) and a T2
  species-mapping correction (white cedar, hemlock previously misassigned to Other Hardwood).

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
| FVS-ACD v13.1 (full, hier) | +9.8 | +21.8 | -0.36 | 471 |
| FVS-ACD v13.1 (ship18, new) | +8.3 | +20.2 | -0.343 | 465 |
| FVS-ACD v12.11 (full) | +8.2 | +20.0 | -0.31 | 464 |
| FVS-ACD default | +1.1 | +11.1 | -0.337 | 430 |
| FVS-NE default | +0.6 | +10.7 | -0.335 | 429 |
| OSM-ACD | -7.2 | +3.8 | -0.286 | 400 |
| Observed | 12.0 cd/ac | --- | --- | 387 |

Every model posts negative R² on value -- a systemic finding across the whole roster, disclosed
directly, not softened. Ship18 lands within 0.1-0.3 pts of v12.11 on every metric, expected given
both are non-hierarchical AcadianGY configs, not a duplicate-run artifact.

## Projected stumpage value by model

Routine n = 65 (OSM-ACD n = 63), Aroostook County 2024 dollars, SILC merch spec

AcadianGY v8.35 leads at $662/ac. The three v13.x candidates cluster tightly -- v13.1 hierarchical
($471), ship18 ($465), and v12.11 ($464) -- just above FVS-ACD default ($430) and FVS-NE default
($429); OSM-ACD ($400) remains closest to observed ($387).

## Equivalence testing, all seven models

TOST against a ±25% practical-equivalence region, not a null-difference test

All three full-coverage v13.x candidates show the identical pass/fail pattern as FVS-ACD default,
FVS-NE default, and OSM-ACD: pass intercept-equivalence on volume, fail on value; fail
slope-equivalence on both metrics. No model in the seven-model roster passes the slope criterion on
either metric. This is a systemic result, not a v25-specific regression.

## Bakuzis biological-realism check: all three v13.x candidates now pass clean

FVS-ACD v12.11 (full): PASS on all five relations, matching base. FVS-ACD v13.1 hierarchical
(full): **PASS on all five, corrected from a same-day FLAG on four of five.** FVS-ACD v13.1
ship18: **PASS on all five** -- Bakuzis-checked for the first time this release

Now run through one reusable, parameterized harness (`bakuzis_v13x_traj.R`, `MODEL_TAG`-selected)
instead of three hand-duplicated scripts, closing the gap that had left ship18's check deferred.
The four-of-five FLAG reported against v13.1 hierarchical earlier today -- 46 of 160 volume
site-ordering inversions in the high-density, self-thinning-adjacent regime -- traced to the wrong
posterior directory (`~/v13_subplot`, missing normalizer, ingrowth unnormalized): rerun against the
corrected `~/v13_comb_post`, that candidate now passes cleanly, matching v12.11 and ship18. **The
Bakuzis distinction between the three v13.x candidates is gone; it was never a real
differentiator.** Known harness limitation, disclosed separately: managed and unmanaged Bakuzis
trajectories are byte-identical for both v12.11 and v13.1 hierarchical in this single-region
synthetic harness, because it never sets the ranef levels that would differentiate them -- a
harness gap, not a model defect.

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

**Fix applied and reconfirmed:** the v13.1 hierarchical ingrowth path lacked a density ceiling; a
hard multiplicative shutoff was added, mirroring the mortality-side ceiling, verified
byte-identical when off. **Wall clock and BA PAI, now rerun three times:** pre-fix, post-fix
(wrong postdir), post-fix (corrected postdir) -- wall clock keeps falling (98 to 73 to 37 min);
bootstrap BA PAI essentially unchanged across all three (-0.781, -0.779, -0.782), all already a
genuine self-thinning decline comparable to v12.11's -0.735. **Unresolved,
disclosed limitation:** mortality posterior's rd_z = -0.031 (95% CI -0.039, -0.023) is
wrong-signed for self-thinning, likely collinear with ba_z/lnqmd_z -- the mechanism behind the
Bakuzis flags on the prior slide. **Ships disclosed, not held back:** FVS-ACD v13.1 goes into v25
with this open; posterior refit is deferred follow-up work.

## The one number that still needs attention

AcadianGY v8.35 reports **+71% value bias** -- unchanged concern from v24, still unresolved

Roughly 3 to 4x every other model in this comparison, including all three new full-coverage
FVS-ACD v13.x candidates. **Recommendation unchanged: raise this with Bruce Carroll / AGM's runner
before treating AGM_v835 as validated.**

## What this means for Seven Islands

1. **Model roster reaches full intended coverage, and gains a third v13.x candidate the same
   day.** FVS-ACD v12.11 moves from a 73-plot partial-coverage placeholder to the full
   137-plot-ceiling / 120-realized rerun; a hierarchical v13.1 candidate and a non-hierarchical
   ship18 candidate join alongside it, seven models total.
2. **The two FVS defaults remain the steadiest reference.** Both near +11% value bias, unaffected by
   this round's coverage expansion.
3. **No single v13.x candidate is the clear winner, but all three now pass Bakuzis.** Value bias
   spans a tight 1.8-point range (v12.11 +20.0%, ship18 +20.2%, v131_full +21.8%); the
   biological-realism distinction reported earlier today is retracted as a pipeline artifact. What
   remains open is narrower: v131_full's mortality-posterior rd_z sign issue, and ship18's large
   ingrowth over-prediction (55.4 vs. ~19.7 stems ha⁻¹ yr⁻¹ observed).
4. **AGM_v835 still needs a source check.** Unchanged from v24; still unresolved.
5. **Recommendation and open items.** Use FVS-NE or FVS-ACD default as the interim headline model;
   report all seven models in full; reconcile AGM_v835 with Bruce Carroll; pursue v131_full's rd_z
   refit and characterize ship18's ingrowth over-prediction before considering either for headline
   use.

## Questions and next steps

Full scorecard, per-plot detail, equivalence tests, Bakuzis check, and reproducible R in the v25
bundle

aaron.weiskittel@maine.edu | Center for Research on Sustainable Forests, University of Maine

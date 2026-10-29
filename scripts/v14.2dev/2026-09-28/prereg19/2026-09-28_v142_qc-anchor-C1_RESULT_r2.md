# QC height anchor (QC_AFAC) recalibration scored under C1: PREREG19 result

**Revision 2, 29 September 2026. Correction.** The C2 (tag height both sides) numbers in revision 1 are withdrawn. They
were produced by the PREREG16 scorer's C2 path, which attaches QC tag heights to the benchmark frame records by row
position (`gyr142-p23-fb-c2-c2align`: method "row aligned", 13,437 init and 14,303 t2 records on qc_c, 690 and 542 on
qc_fl), not by tag key; PREREG23's key based match finds 11,632 matched tags of which 1,569 carry the same species and a
measured height at both ends, so a row aligned C2 mixes records across trees. The withdrawn sentence is marked in the
text below and nothing else is changed. **The verdict stands:** rule 3 rests on the screened qc_c fold A C1 span (0.0067,
below 0.010), which does not use C2; H0, N0, K1 and the held out gates are unaffected; the TOPHT reading is unaffected.
Revision 1 is kept as `2026-09-28_v142_qc-anchor-C1_RESULT_PREV_20260929.md` (md5 e658d8c9). The row position matching
was identified in the 29 September session that built PREREG23 and is stated here on that record; this revision did not
re-derive it beyond the c2align table [UNVERIFIED: PREREG23 session finding].

28 September 2026 content, assembled 28 September on firebreather, read out 29 September. Pre-registration:
`2026-09-28_v142_qc-anchor-C1_PREREG19.md` (revision 1, md5 4b2c2488). Six arms (QC_AFAC 0.030, 0.060, 0.111, 0.250, 0.500,
1.000) and the nb_c control ran in `~/jobs/v142p19/` (taskmap md5 328284a5, driver `run_task_p19.sh` ac029e4e, launcher
`launch_p19.sh` 25786453), scored by `2026-09-27_v142_volconv_score.R` (019df238, copied, not edited) and assembled by
`2026-09-28_v142_p19_assemble.R` (7d13671b) into `assembled/`. Base v141LT. L and T unchanged; GT1 stays a named failure.
No em dashes.

## Verdict

**Not adopted. Rule 3 (flat) applies.** H0, N0 and K1 pass, so rules 1 and 2 do not stop the run. The screened qc_c fold A
C1 ratio spans 0.0067 across the whole grid, below the 0.010 threshold, so C1 volume is insensitive to the anchor. The
anchor is a height calibration only and should be refit on tag height increment, not on volume. 14.1 is unchanged.

The selection rule chose a* = 0.030, the lower edge, so rule 4 would also have applied had rule 3 not come first. Rule 3
precedes rule 4 in the stated order and is the verdict. The held out gates are reported below for completeness; they do
not change the verdict, and passing V1, V2, B1 and B2 by margins of 0.08 points or less at a flat criterion is not
evidence for any value.

| Gate | Result | Pass |
|:--|:--|:--:|
| H0 harness | 0.111 arm against Cardinal bench141 v141LT: qc_c worst scaled 9.22e-15 on 378 stands, qc_fl 6.42e-15 on 19 (TOTVOL_p) | Yes |
| H0 V3 | Screened qc_c C1 at 0.111 = 1.0882, within 0.001 of 1.088 | Yes |
| N0 regional | nb_c rows 1 to 40 at 1.000 against v141LT: worst scaled 0 on 40 stands | Yes |
| K1 failures | 0 RUN_OK other than 1 in 397 QC stands at a* | Yes |
| V1 held out bias | Fold B C1 bias +11.38 at a* against +11.46 at 0.111 | Yes |
| V2 %RMSE | Fold B C1 %RMSE 46.75 against 46.76, d +0.00 | Yes |
| B1 basal area | Fold B abs(BA ratio minus 1) 0.21 against 0.17 points | Yes |
| B2 stems | Fold B abs(stems ratio minus 1) 24.19 against 24.23 points | Yes |
| Edge | a* = 0.030 on {0.030, 0.060, 0.111, 0.250, 0.500, 1.000} | No |

## Selection (screened qc_c fold A, 153 stands on 147 sites)

| QC_AFAC | C1 ratio, fold A | Loss | C1 ratio, fold B | BA ratio, fold B | Stems ratio, fold B | TOPHT bias, screened (%) |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **0.030** | **1.0629** | **0.0610** | 1.1138 | 0.998 | 0.758 | +5.42 |
| 0.060 | 1.0631 | 0.0612 | 1.1141 | 0.998 | 0.758 | +5.68 |
| 0.111 | 1.0636 | 0.0616 | 1.1146 | 0.998 | 0.758 | +6.13 |
| 0.250 | 1.0646 | 0.0626 | 1.1158 | 0.999 | 0.757 | +7.36 |
| 0.500 | 1.0663 | 0.0642 | 1.1178 | 1.000 | 0.756 | +9.59 |
| 1.000 | 1.0696 | 0.0673 | 1.1212 | 1.002 | 0.754 | +14.03 |

Loss is abs(log(C1 ratio)). The fold A loss is monotone in the anchor, so the criterion always points to the smallest
value on any grid; there is no interior optimum to find by extending the grid downward.

![C1 volume, basal area and stems ratios against QC_AFAC, screened qc_c fold A and fold B](p19_assembled/gyr142-p19-grid_2026-09-28.png)

**Figure 1.** Pooled predicted over observed ratios of C1 total volume, basal area and stems against QC_AFAC (log scale),
screened qc_c fold A (selection) and fold B (held out). The dotted line marks the shipped 0.111; the dashed line marks a*.

## What the grid shows

A 33 fold change in the anchor moves screened C1 volume by 0.7 points (1.0875 to 1.0946 on all 313 screened stands) and
basal area by 0.4 points. Stems do not respond (0.770 to 0.766). The QC C1 excess, about 9 percent on screened stands and
11 percent on fold B, is not a height growth effect: it sits in diameters and stem numbers, as PREREG14 and the PREREG17
QC control (more ingrowth makes QC volume worse) already suggested. Stems run about 24 percent low on fold B at every
anchor, with basal area on target, so QMD runs 15 percent high; the C1 volume excess is consistent with too few, too large
trees.

C0 responds strongly (screened 1.112 at 0.030 to 1.231 at 1.000) because C0 carries model heights into volume. That is the
PREREG16 height carry, not a growth response. **C2 is withdrawn from this result** (see the correction note at the top):
the C2 values the first revision quoted (screened qc_c 1.072 at 0.030 and 1.078 at 1.000) were computed by matching QC
tag heights to frame records by row position rather than by tag, and are not a tag height both sides score.

**TOPHT points the same way as C1, not toward 1.2.** Screened qc_c TOPHT bias rises from +5.4 percent at 0.030 to +14.0
percent at 1.000. PREREG14 read the tag height increments as asking for an anchor near 1.2 [UNVERIFIED: PREREG14 text, not
re-derived this session]. On top height the model is already tall at 0.111, and removing the anchor makes it taller. The
two height diagnostics disagree, which is the first thing the rule 3 follow-up (refit on tag height increment) has to
resolve: tag increment on surviving tagged trees and top height on the dominant cohort are different quantities, and a
single multiplier on all QC trees may not serve both.

## Controls and qc_fl (reported, not gated)

N0 confirms the anchor is regional as coded: nb_c at 1.000 reproduces v141LT exactly. qc_fl (19 stands, 8 screened) is
reported only: screened C1 1.171 at 0.030 to 1.188 at 1.000, and 11 of 19 stands carry a harvest.

## Re-derivation [F9]

Every number above was re-derived outside the assembly script by `verify_20260929/p19_rederive.R` on firebreather, from
the per arm results files and the scorer's stand table, with folds recomputed from md5(SITE). Fold A and fold B C1 ratios,
fold B bias, %RMSE, basal area and stems ratios, stand and site counts, and the 0.0067 span all match the assembled grid
table to the printed precision. The screened C1 ratio at 0.111 (1.0882) matches the PREREG16 V3 value.

## Deviations

1. **No stand needed a retry.** The by name retry ran for every arm and found no time limited stand (all seven logs:
   `RETRY_DONE remaining: 0`). The section 8 rule was armed and did not fire.
2. **Smoke comparison against Cardinal deferred to H0**, as the pre-registration stated. H0 passed at full scale before any
   grid value was read.
3. **Table date stamps.** The scorer writes its tables with its own 2026-09-27 stamp (`gyr142-p19-fb-*_DATA_2026-09-27.csv`)
   although the content belongs to 28 September. Names were not changed, to keep them traceable to the scorer.
4. **Assembly on real outputs, first run.** The assembly had never run on real outputs before this chain. It ran once,
   exit 0, and its internal identity check (its screened and all stand C1 against the scorer's own) passed. No repair was
   needed and none was attempted.
5. **Host.** Firebreather was shared with the PREREG18 grid (load near 6 on 8 cores, 4 tasks running). Wall time is not a
   result.

## Files

`p19_assembled/` beside this file (gates, H0 and N0, selection, grid, verdict, Figure 1; firebreather
`~/jobs/v142p19/assembled/`, all six files md5 verified on the laptop). The re-derivation script and its table are in
`~/jobs/v142p19/verify_20260929/`. Scripts are on GitHub under `scripts/v14.2dev/2026-09-28/prereg19/` on
`v142-refinement-20260926`.

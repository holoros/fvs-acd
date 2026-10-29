# ns_long_fl 10 to 19 year height deficit, v141LTf against 14.1: PREREG34 result

1 October 2026 (assembly and verify ran 07:01 to 07:10 server time). Pre-registration:
`plan/2026-10-01_v142_ns-long-fl-mid-interval_PREREG34.md` (revision 1, md5 16bab8a5, recorded 06:51:09 in
`logs/prereg_md5.txt` before any new fold B quantity; no later revision). Frozen inputs, md5 checked in
`assembled/gyr142-p34-provenance_DATA_2026-10-01.csv`: PREREG20 keys (fd8ab6d5, dce39692), v141LTf results (e475736f,
f9b72f15), siteidx draws (f1cb3043, 7def79ab), PREREG30 height table, ns_long frames. v141LT is Hp141 in the key; all
per tree outputs were present, so no engine run. Assembly
`scripts/2026-10-01_v142_p34_assemble.R` revision 2 (md5 bb9c0799). Fold B confirmatory, fold A exploratory. No em dashes.

## Verdict

**Rule 2. The deficit is a program effect: the ns_long_fl 10 to 19 year bin is 62 percent NS_RS trees, and on its NS_OP
stands the height form does what it does on ns_long_c.** The form is safe on the population it was fit for; the bin is
named a program effect. The rule also records (c) as supported, but only through subsets that are NS_OP by another name
(below), so I read it as program, not frame.

| Fold B, tag matched survivors | Trees | Stands | v141LT | v141LTf (95% site interval) |
|:--|--:|--:|--:|:--|
| ns_long_c 10 to 19, all | 9,054 | 416 | 1.0441 | 1.0247 (1.0150 to 1.0355) |
| ns_long_c 10 to 19, NS_OP | 9,022 | 412 | 1.0443 | 1.0248 (1.0151 to 1.0358) |
| ns_long_fl 10 to 19, all | 4,188 | 296 | 0.9353 | 0.9186 (0.9020 to 0.9331) |
| ns_long_fl 10 to 19, NS_OP | 1,597 | 90 | 1.0197 | 0.9964 (0.9822 to 1.0088) |
| ns_long_fl 10 to 19, NS_RS | 2,591 | 206 | 0.8769 | 0.8647 (0.8450 to 0.8816) |

Level is predicted over observed end of interval height, from `assembled/gyr142-p34-subsets_DATA_2026-10-01.csv`. The
bin rows reproduce PREREG30 to 5.1e-15 in all 12 set, fold and arm cells (`gyr142-p34-repro_DATA`).

## What the data show

**Program composition carries more than half of the gap.** The v141LTf level gap between the ns_long_fl and ns_long_c
bins is -0.1059; the two factor Shapley split by program gives -0.0589 to composition (share 0.556) and -0.0470 to
within program differences (`gyr142-p34-shapley_DATA`). The same split by t1 class gives a composition share of 0.040,
by Y1 group -0.043 and by NLINKS 0.321. ns_long_c has 32 NS_RS trees in the bin, ns_long_fl 2,591: only the first to last frame
stretches the short NS_RS remeasurement cycle past 10 years.

**On NS_OP the form behaves.** NS_OP moves from 1.0197 to 0.9964, and by t1 class from 1.0097 to 1.0064 (below 12.7
cm, 660 trees), 1.0263 to 0.9945 (12.7 to 25, 751) and 1.0210 to 0.9813 (25 and over, 186). The residual check passes
on the pooled NS_OP bin and on both classes with 200 trees or more (`gyr142-p34-residual_DATA`); the 25 cm and over
class is under the gating size and ends 1.9 percent low, the same small large tree under prediction PREREG30 saw.

**NS_RS is low before the form touches it.** NS_RS observed increment is 0.264 m yr⁻¹ against 0.145 for NS_OP, and
14.1 already sits at 0.877. The deficit is concentrated below 12.7 cm (0.808, 1,819 trees, unchanged by the form) and in
the lower ESI tertile (0.758); the form then trims the larger NS_RS trees, 0.954 to 0.929 and 0.983 to 0.952. This is
the PREREG29 NS_RS pattern, already named outside the 14.2 NS height calibration.

**The frame route is program in disguise.** ESI cov30m (0.9948) and NLINKS 1 (0.9866) meet the materiality rule, but
the first is 1,541 of 1,541 NS_OP trees and the second 503 of 515. Within program the frame splits are flat: NS_OP gives
0.9933 for one link against 0.9977 for two or more, and NS_RS 0.8641 without a sibling link against 0.8725 with one. At
fixed program, NS_OP in ns_long_fl sits -0.0285 (-0.0451 to -0.0134) below NS_OP in ns_long_c
(`gyr142-p34-frame-contrast_DATA`): the interval excludes 0 but the size is under the 0.03 bar, so a small frame
offset exists and is not material. The 7.0 m old harness ESI offset pushes predictions up, so it cannot make this bin low.

**(b) and (d) fail.** Dropping any one class leaves the pooled bin at 0.888 to 0.962. Y1 before 1975 (1.0009) meets
the rule, but it is entirely NS_OP and its composition share is negative. Interval length inside the bin barely moves the
level (0.9164 at 10 to 14 years, 0.9214 at 15 to 19).

**Crossers are reported, not used**: 37.8 percent verified match coverage, under the 50 percent bar. Crossers run low
(NS_OP 0.946, NS_RS 0.772), as expected of a subset chosen by fast growth.

**Fold A transfers (exploratory).** NS_OP 1.0175 to 0.9968 and NS_RS 0.8613 to 0.8509, inside the fold B intervals.

![Fold B 10 to 19 year bin by program and t1 diameter class](assembled/gyr142-p34-bin-foldB_2026-10-01.png)

**Figure 1. Tag matched survivors in the 10 to 19 year interval bin, fold B: predicted over observed t2 height (top) and
mean bias in t2 height (m, bottom) for v141LT (14.1) and v141LTf, by t1 diameter class, for ns_long_c (all programs and
NS_OP) and ns_long_fl (all programs, NS_OP, NS_RS), with 95 percent site cluster bootstrap intervals (B = 1000, PREREG20
siteidx draws). NS_RS carries the deficit, largest below 12.7 cm.**

## Re-derivation [F9]

`verify_20261001/2026-10-01_v142_p34_verify.R` (md5 5fc17d3b) uses no source(), folds by openssl md5, and has its own
readers and its own id and match joins. It recomputes the bin levels by arm (both sets and folds), trees and level of every
fold B subset by stratum and arm, the ns_long_c references, the Shapley terms and the frame contrast: 549 checks, 0
failed, worst absolute difference 5.11e-15 at tolerance 1e-9 (`p34-verify-values_DATA_2026-10-01.csv`); fold
disagreement 0. The log ends `P34_VERIFY_DONE`. Bootstrap limits are not re-derived.

## Deviations

1. **Assembly revision 2.** Revision 1 and two partial edits stopped in the fold A loop before any fold B number was
   printed (two logical column subsets that data.table read as a column lookup; an empty ns_long_c NS_RS class cell). Fixes in
   `diffs/assemble_rev2_vs_rev1.diff`; revision 1 and failed logs kept. One launch was killed during its read, printing nothing.
2. **Verify revision 2**: an empty table guard (`diffs/verify_rev2_vs_rev1.diff`), before any comparison.
3. **The two fold A frame look scripts** behind the stated fold A counts were deleted after use; their output is quoted
   in the pre-registration.
4. **Shapley fallback.** NS_RS and NLINKS groups that are sparse or absent in the ns_long_c bin take the ns_long_c all
   interval or bin level, so the gap differs slightly by factor (-0.1059 to -0.1061).
5. **The frame contrast interval** pairs independent per set siteidx draws (conservative for shared sites). TOPHT by
   program was not computed (not pre-registered).

## Files

`~/jobs/v142p34/`: `plan/`, `logs/`, `scripts/`, `diffs/`, `assembled/` (tables, verdict, provenance, figure), `figs/`
(preview JPEG), `verify_20261001/`.

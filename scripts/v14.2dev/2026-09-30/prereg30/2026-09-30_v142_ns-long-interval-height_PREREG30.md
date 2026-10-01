# PREREG30: NS long interval end of interval height, v141LTf and v141LTfi against v141LT (14.1)

Revision 1, 30 September 2026. Track PREREG30 of the FVS-ACD (AcadianGY) 14.2 refinement series. Written before any fold B
value of this track is read. New directory only: `~/jobs/v142p30/`. No em dashes. No coordinates.

## Question

PREREG20 fitted a two segment Nova Scotia height increment multiplier m(D) = exp(-b1 (min(D,25) - 12.7)+ - b2 (D - 25)+),
b1 = 0.034416, b2 = 0.005072 (`~/jobs/v142p20/fit/gyr142-p20-fit-params_DATA_2026-09-28.csv`, md5 b06277a2), on one
remeasurement interval of fold A ns_c tag trees. On the long NS remeasurement intervals (ns_long_c gated, ns_long_fl
reported), is the observed end of interval height of tag matched survivors, and top height, closer to v141LTf (height form
alone) and v141LTfi (height form plus threshold matching, ING_MIN_FROM_SCORE=1, IMULT 1.5) or to v141LT (14.1 as shipped)?

## What was already seen (stated openly)

1. PREREG20 fitted b1 and b2 on fold A of ns_c (one interval). Its H2 table (`~/jobs/v142p20/tables/gyr142-p20-h2-*`) and
   PREREG22's (`~/jobs/v142p22/tables/gyr142-p22-h2-sizeclass_DATA_2026-09-29.csv`) already hold annual height increment
   ratios by set, fold and t1 diameter class, including ns_long_c and ns_long_fl fold B, for v141LT, v141LTf and v141LTfi.
   PREREG22 gated fold B large tree increment (ns_c, ns_long_c) and published TOPHT bias pooled over all stands (both folds)
   of ns_long_c and ns_long_fl against Cardinal aggregate v141LT values, and passed. The orchestrating session has seen
   those numbers. This track has not printed or read any of those values before this revision was recorded; it has read
   only table headers, gate names and fold A tag counts by interval length and class (used to pick interval bins).
2. PREREG26 (synthetic 100 year Bakuzis grid) showed the height form alone lowering 100 year top height by 14 to 25 percent
   against v141LT; the gated arm's better top height realism came from recruits entering at 9.1 cm.
3. PREREG29 applied the height forms offline to frozen v141LT increments on the PREREG20 keys and found that v141LT NS per
   tree and per stand result files are not on firebreather (its find_results.sh and find2.sh logs); it notes ns_long_c
   shares plots with ns_c.
4. New in this track: end of interval height level (not increment) as the metric, by interval length, the t1 dominant
   cohort, and published TOPHT bias per stand on fold B for v141LT, which requires a new run.

## Data and arms

Sets: ns_long_c (gated) and ns_long_fl (reported), frames `~/jobs/v142p20/home/magplot/verify/gydbreg20260916/frames`.
Tag matched survivors: the PREREG20 key `~/jobs/v142p20/in/key/p20_htkey_ns_long_c.csv` (md5 fd8ab6d5) and
`p20_htkey_ns_long_fl.csv` (md5 dce39692): survivors with measured height at both ends, matched through the pass 28 tag
frames, with the frozen Cardinal v141LT predicted t2 height `Hp141`. Fold: md5 of SITE, first hex digit even is A, odd B.

Arms. v141LT: `Hp141` in the key (frozen Cardinal per tree) for the tree level gates; per stand TOPHT from a new firebreather
run of the frozen PREREG20 runner (`runner_p20_fb.R`, md5 65392afb) with the PREREG20 environment `p20_env.sh` (md5 8edd89f4)
at column g0_off (height correction unset, IMULT 2.5, no ingrowth matching: the column PREREG20 G0 showed reproduces frozen
v141LT on ns_c at 2.6e-15), fold B stands only of both sets (4,282 ns_long_c and 1,167 ns_long_fl stands), in 7 chunks per
set selected by name through STAND_KEEP_FILE. v141LTf: frozen `~/jobs/v142p20/results/v141LTf/` (ns_long_c md5 e475736f,
ns_long_fl f9b72f15) and per tree `~/jobs/v142p20/home/out/v141LTf/`. v141LTfi: frozen `~/jobs/v142p22/results/v141LTfi/`
(ns_long_c 9ac03bc2, ns_long_fl cf8bf849) and per tree `~/jobs/v142p22/home/out/v141LTfi/`. Frozen runs are not rerun.

Metrics (fold B unless stated). Level ratio = sum of predicted t2 height over sum of observed t2 height across tag matched
survivors (PREREG28 `level_t2`). Classes by t1 DBH: below 12.7, 12.7 to 25, 25 cm and over. Interval bins: below 10, 10 to
19, 20 years and over. Dominant cohort: at t1, trees ranked by DBH descending within stand in the init frame, cumulative
EXPF up to 100 stems per ha (plus the largest tree), the runner TOPHT rule as coded in the PREREG23 helper; the gate uses
tag matched survivors in that cohort. Published TOPHT bias: 100 (mean TOPHT_p - mean TOPHT_o) / mean TOPHT_o over RUN_OK
stands (PREREG17 summary and PREREG28 assembly formula), on the fold B stands RUN_OK in all three arms; per stand bias
TOPHT_p - TOPHT_o is also reported. Intervals: site cluster bootstrap, B = 1000, the first 1000 columns of the PREREG20
`in/siteidx_<set>.rds` draws (site order unique SITE of the results file), fold B sites weighted by their draw counts.

## Gates, thresholds and provenance

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H0 | new v141LT run reproduces frozen Cardinal `Hp141` on every fold B key tree of both sets; K1: every fold B stand RUN_OK after by name retries | scaled difference at or below 1e-9; 0 not OK | PREREG20 G0 tolerance |
| L1 | ns_long_c fold B, pooled level ratio | abs(v141LTf - 1) < abs(v141LT - 1) | suggested by the track brief |
| L2 | ns_long_c fold B, level ratio by class | abs(v141LTf - 1) no more than abs(v141LT - 1) + 0.03 in every class | brief; PREREG23 class margin 0.03 |
| L3 | ns_long_c fold B, dominant cohort level | abs(v141LTf - 1) no more than abs(v141LT - 1) + 0.02 | brief; PREREG23 M_DOM 0.02 |
| L4 | ns_long_c fold B, published TOPHT bias | abs(v141LTf) no more than abs(v141LT) | brief; PREREG22 H1 direction |
| L5 | ns_long_c fold B, pooled level ratio on trees with interval 10 years and over | abs(v141LTf - 1) no more than abs(v141LT - 1) + 0.02 | added here: fold A shows 81 percent of ns_long_c tag trees on 5 year intervals, so L1 is dominated by the one interval case PREREG20 already fitted; L5 is the long interval reading |

v141LTfi is evaluated on the same gates and reported; it does not decide the verdict. ns_long_fl rows are reported, not
gated. Fold A rows are reported.

## Decision rule, in order

1. H0 fails: no verdict; report the harness failure only.
2. L1 or L3 fails: the height form is named as failing long interval realism and is not carried into 14.2 as fitted.
3. L1 to L5 all pass: the long interval data support the height form, and the PREREG26 top height loss is read as a
   synthetic start artifact.
4. L1 and L3 pass, and L2, L4 or L5 fails: mixed; the height form is not cleared for long interval use, the failing gate is
   named, and 14.1 is unchanged pending a further pre-registered test.

## Expectation (stated now)

L1 and the 25 cm and over class of L2 pass, because ns_long_c is mostly 5 year intervals like the fit data. L4 is the most
likely failure: PREREG26 suggests the form lowers top height, and if 14.1 does not over predict top height on long intervals
the form will overshoot below. For L5 and ns_long_fl I expect v141LTf to sit below 1 by more than v141LT sits above it on
the 20 year and over bin. Overall I give about even odds of rule 3 against rule 4.

## Caveats

ns_long_c shares plots with ns_c, so fold B is held out from the PREREG20 fit but was used by PREREG22 benchmark gates.
Tag matched survivors exclude mortality and ingrowth; the level metric carries the observed H1 in both sums, so level
ratios sit close to 1 and differences are small in absolute terms. TOPHT includes ingrowth and so reflects threshold
matching in v141LTfi. The v141LT per stand run covers fold B only (compute); fold A TOPHT for v141LT is not reported.

## Constraints

At most 2 R model processes at once, none started at a 1 minute load average of 12 or above, launched by a load gated
script under setsid nohup. Host time limit failures retried by STAND name through STAND_KEEP_FILE, up to three attempts.
No frozen run is rerun in its own directory. L and T are not re-estimated; GT1 stays a named failure. Nothing leaves the
server. Revisions only before fold B is read, all kept.

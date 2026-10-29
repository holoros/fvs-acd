# The 14.1 thinning response limited to partial removals, for 14.3: pre-registration 1

Registered 18 October 2026 as revision 1 (draft 6 with the probe counts verified). Drafts 1 to 6 (`_PREV_20261017` to `_PREV_20261018`)
were red teamed in rounds 1 to 5 (`review/`); round 5, on rule 4 alone, found it registrable after
the should fixes made here; `2026-10-17_v143-prereg1_CHANGES.md` maps each
finding to its repair. Opened from the 16 October 2026 cross-version benchmark
(`docs/benchmarks/2026-10-16_cross-version/README.md`, md5 9f865e03; `acdx_postharvest_by_type_DATA.csv`,
md5 72656c16), which found that 14.1 overstates annual biomass recovery after removals of more than
65% of merchantable volume by 1.39 (1.13 to 1.64) Mg ha⁻¹ yr⁻¹, double the observed 1.39. Written
before any 14.3 code, threshold computation, engine run or projection. The outcome **informs 14.3
only; 14.1 and the 14.2 track are unchanged**. L and T are not re-estimated: lambda 1.14863, alpha
0.37109, beta 0.08220 and gamma 2 come from `v141_option3_offline_coefs_r5_2026-09-23.rds` (md5
c8f02f58), and the relative size cap 2.9848 from the V141_RELCAP setting of the frozen launcher,
asserted equal to the rds rel_cap before any run. GT1 stays a named failure. Identifiers stay in
`*_SERVERONLY` files. No coordinates. No em dashes.

## What is known before any run

T multiplies the annual diameter increment of every tree in a stand with a known years since
thinning (tst) by m_T = 1 + alpha exp(-beta tst) min(d / Dq, cap)^gamma. It was fitted on CTRN only,
119 locations in 17 installations, with tst support 1 to 17 yr; BAXTER enters L alone. At tst 1 and
the cap, m_T is 4.05. Design probes on Cardinal (jobs 15612299, 15612657 and 15645813, the last
run on 18 October 2026 to verify the others; counts only, no outcome read) give:

| Frame | Stands | Known tst | tst range (yr) | Note |
|:--|:--:|:--:|:--:|:--|
| mefia_ph_c | 827 | 762 (heavy 205/221, intermediate 178/191, light 141/146, low volume 238/269) | 1 to 5, median 2 | inside the T support |
| ctrn_c, ctrn_fl | 1,086; 175 | 646; 63 | 1 to 17; 1 to 12 | the T estimation source |
| pef_c | 2,853 | 1,193 | 2 to 46 | 227 stands beyond 17 yr; T acts here |
| all other benchmark sets (pef_fl included) | | 0 | | T inert by contract |

CTRN and PEF carry no treatment type or severity in the standardized database (every record is
Treatment 99, "Unknown treatment", with no Severity; 901 CTRN and 666 PEF records). Of the 134
thinned CTRN locations, 30 in 9 of the 17 installations have a measured visit strictly before and
strictly after their first treatment year (last pre visit a mean 1.13 yr before it; pre to post gap
a mean 2.43 yr, at most 5). Whether all 30 are among the 119 locations of the T fit is checked in
the TH step.

## Two readings, registered before any run

The 14.1 minus 14.0.4 L2 uplift (L and T together) is +1.895 (light), +1.806 (intermediate),
+1.162 (heavy) and +1.367 (low volume) Mg ha⁻¹ yr⁻¹. Heavy has the smallest absolute uplift; it
is largest only per unit of t1 stock. Light lands within tolerance (+0.459) and intermediate and
heavy overshoot (+1.408, +1.391).

- **HG, geometry.** T is right for removals that keep or raise Dq and wrong where removal lowers
  Dq, because residual stems are then large relative to the new Dq. Predicts that 14.1's survivor
  increment excess concentrates at d / Dq above 1.15 in stands with DQR below 1, and that withholding
  T there closes the intermediate and heavy gaps while leaving light unchanged.
- **HR, rate.** alpha is too large for operational FIA removals regardless of geometry. Predicts a
  realized release below 14.1's m_T alike in stands whose removal kept and lowered Dq (rule 4 and
  the survivor increment ratio).

Passing P1 to P3 does not by itself favor HG: a rule that withholds T from most heavy and many
intermediate stands for any reason would also pass under HR, and so would a contrast between arms
scored on the same stands, because the observations cancel in it. The separating test therefore
uses the observations stand by stand: the realized T slope (rule 4). If HR holds, the
remedy needs T re-estimated or attenuated, which is outside this study and is Aaron's decision.

One bound follows from the design and is registered as a gate. Eligibility is fixed per stand, the
engine has no random draws, and T is the only difference, so each stand's predicted change under any
arm equals its 14.1 or its A0 prediction exactly (gates E0 and TR check the overlay). Over every
possible eligibility rule, a class mean prediction therefore lies between the class mean of the
per stand minimum and maximum of the two, and the smallest attainable absolute gap follows exactly.
If T lowered no stand's predicted change, the heavy minimum is A0's gap; P1 needs 0.346 from 1.391,
a fall of 1.045 of the 1.162 uplift, so P1 is then passable only if L alone adds no more than 0.117
Mg ha⁻¹ yr⁻¹ over 14.0.4 L2. Intermediate has the same structure under P2. Gate F (rule 2) computes
the attainable minimum for both classes on A0 before any eligibility arm is read, and reports the
number of stands where T lowers the predicted change (possible through density dependent mortality).

## Eligibility quantities, one definition in every frame

Every quantity uses live trees at or above 12.7 cm DBH (the r1 tree link floor and the L
smoothstep lower bound), their diameters at the last visit before the removal, and a tree link that
splits that list into removed and retained trees. Using pre visit diameters for both parts removes
growth over the lag and ingrowth from every quantity. A tree recorded dead from causes other than
cutting (r1: STATUSCD 2 with an agent other than 80) is excluded from both parts in the primary
rule and counted as removed in a stress run. A stand needs at least 4 retained trees at or above 12.7
cm, one per FIA subplot on average [choice, swept at 2 and 8]; below that it is ineligible, missing.
DQR is a proxy: the engine's Dq covers every stem at 2.54 cm and above at v1, tst years after the
cut, so the engine counters `thinning_calls_at_cap` and `max_rel_dq_seen` are reported by class and arm.

- RF: removed basal area over pre visit basal area.
- DQR: Dq of retained trees over Dq of all trees, both at pre visit diameters.
- RD_res: SDI of retained trees over the 14.0.4 SDImax of the stand.

| Frame | Pre visit | Removed | Lag to removal |
|:--|:--|:--|:--|
| mefia_ph_c | v0 FIA tree records | r1 rule: v1 record STATUSCD 3, or STATUSCD 2 with AGENTCD 80, or absent at v1 | v0 to harvest year, reported |
| CTRN (30 locations, 9 installations) | last tagged visit before thinYR | tag absent at the first post visit and not recorded dead | reported |
| ctrn_c, ctrn_fl, pef_c benchmark stands | as CTRN, where a pre visit exists | as CTRN | reported |
| 14.1 finalization grid (20 thinned cells) | the driver's list immediately before the thinning | the driver's removal | 0 |

A stand that lacks a pre visit, a link, enough retained trees or a Dq is "ineligible, missing",
reported apart from "ineligible, threshold" in every frame, extending the 14.1 contract that T is
never applied by guessing. The count of trees excluded as dead from other causes is reported.

## Arms

Every arm is 14.1 (v141LT settings copied verbatim from `2026-10-16_mefia_ph_array.sbatch`) with
one change. Eligibility is fixed once per stand from its removal and is not recomputed.

| Arm | Change from 14.1 | Threshold and provenance |
|:--|:--|:--|
| A0 v141L | THIN_V141=0 | none; decomposition and feasibility only, barred from candidacy; must pass rule 1 for any verdict |
| Apv | T only where the stand has a pre visit and enough retained trees | none; the null for the data rule, barred from candidacy |
| A1 t_rf | T only if RF at or below RF_MAX | maximum RF over the CTRN locations with a pre visit that are among the 119 of the T fit, by analogy with GT6, which caps d / Dq |
| A2 t_rd | T only if RD_res at or above RD_MIN | minimum RD_res over the same locations |
| A3 t_dq | T only if DQR at or above 1 | definitional: a removal from below or across keeps or raises Dq |

`thresholds_v143.R` computes RF_MAX and RD_MIN, writes `thresholds_v143_DATA.csv` with the n of
locations and installations behind each, and records its md5 before any arm output exists. The locations are a partial view of the T support (at most 30 locations in 9 of 17 installations),
so A1 and A2 carry that label in every verdict. The maximum of a subset is at or below that of the
full set, so RF_MAX is biased low and RD_MIN high: both arms are more restrictive than the T support
warrants, which favors P1 and P2 and penalizes N1 and N2. A3 needs no estimated constant.

Placebo arms, a reported null. For each of A1 to A3, 200 placebo draws (seeds 20261017 to 20261216)
withhold T from every "ineligible, missing" stand, as Apv does, and assign eligibility at random
within the non-missing pool of each class, matching the arm's eligible count there. Because T is
switched per stand, placebo predictions are assembled from the A0 and 14.1 runs without new
projections. The placebo distribution of the realized T slope contrast is reported beside each arm. Reference arms are the frozen 16
October outputs of 14.1, 14.0.4 L2 and 13.1h, read and never rerun.

## Harness gates (rule 1)

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| E0 | each switch off reproduces 14.1 on all 19 sets and mefia_ph_c | identical, results and per tree | 14.1 gate E1 |
| E0b | every set with 0 known tst in its bench141 TST file (all but ctrn_c, ctrn_fl, pef_c) | identical to 14.1 | T inert by contract |
| E0c | 200 yr mefia_l_c frame | identical to 14.1 | no harvest |
| CAP | V141_RELCAP equals the rds rel_cap | equal | finding F12 |
| TR | traced m_T on 4 eligible and 4 ineligible stands, 3 years | eligible matches the 14.1 formula to 1e-12; ineligible equals 1 | PREREG46 TR |
| K1 | RUN_OK other than 1 after the PREREG38 retry rule | 0 | PREREG23 |
| TH | thresholds and support file md5 recorded before any arm output | present | this plan |

## Support check (in the TH step, before any arm output)

RF, DQR and RD_res are tabulated for the CTRN threshold locations, the ctrn_c, ctrn_fl and pef_c
stands, the 20 grid cells and the mefia_ph_c classes, with the count outside the CTRN range on each,
the count ineligible for a missing pre visit (pef_c included), and the share of stands with DQR
between 0.95 and 1.05 by class. Every threshold location is eligible under A1 and A2 by
construction, and about 104 thinned ctrn_c locations lack a pre visit, so N1 is scored against both
14.1 and Apv; the comparison with Apv isolates the threshold from the data rule. Each gated class
needs 30 eligible and 30 ineligible stands under an arm [PREREG45 floor of 30, set for trees,
borrowed for stands]; below that the class verdict for that arm is uninformative.

## Benchmark gates (rules 3 and 5; P gates on mefia_ph_c, N gates on other frames)

The gap is predicted minus observed annual AGB change (NSVB, trees at least 5 cm), Mg ha⁻¹ yr⁻¹,
per FCCL class. Intervals come from 1,000 bootstrap resamples of plots (827 stands on 781 plots),
paired across arms, seed 20261017, and the reference arms are restated under this rule before any
arm is read.
tol is 25% of the observed class rate: 0.346 heavy, 0.515 intermediate, 0.632 light, 0.713 low
volume.

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| P1 heavy | absolute gap, point, with its interval reported | at or below tol | 16 October equivalence region (±25% of the observed mean, set for AGB levels), applied to rates; a choice made after the benchmark was read, so swept |
| P2 intermediate | as P1 | at or below tol | same |
| P3 no harm | light and low volume: absolute gap, and paired 95% upper limit of abs(gap arm) minus abs(gap 14.1) | gap at or below tol; worsening limit at or below 0.5 tol | same scale; the half tol margin is a choice, swept with tol |
| P5 total | AGB bias over all 827 stands, point estimate | within ±5% | borrowed from the 14.1 finalization E1 window, set for NS and NS_LONG total volume |
| N1 CTRN and PEF | ctrn_c consecutive and pef_c total volume %RMSE; ctrn_fl first-last total volume absolute bias; each against 14.1 and against Apv | %RMSE within 0.5 points of both; absolute bias no larger than both | 14.1 PREREG4 tolerance |
| N2 grid | the 20 thinned cells | all eligible; trajectories identical to 14.1 | a rule that strips T from a thinning from below cuts into T's own domain |

The paired heavy fall from 14.1 (formerly gate P4) is reported, not gated, since a P1 pass implies a
fall of at least 1.045. Every verdict is also reported at tol of 15% and 35%. A verdict that changes across the sweep is
labeled sensitive. 14.0.4 L2 and 13.1h fail P3 on light (paired against 14.1 they worsen it by
0.977 and 0.650), so no frozen version clears P1 to P3.

## Diagnostics registered with a predicted direction

- **T share.** S = (g141 minus gA0) / (g141 minus gL2) in heavy and intermediate, paired plot
  bootstrap, reported. Because L and T multiply, S measures T given L.
- **Realized T slope (gated in rule 4).** Per stand, D = pred141 minus predA0 (T's predicted
  addition to annual AGB change) and Y = obs minus predA0. Within heavy and within intermediate, and only
  over stands with a known tst (the count dropped is reported), the stands an arm keeps T on and the
  stands it withholds T from (threshold ineligible only) are fitted together as Y ~ group +
  group:ns(RF, df 2) + group:predA0 + group:D, each group with its own spline in RF and its own
  term in A0's predicted change, so that k_g, the group's D coefficient, is identified from tst and
  d / Dq variation at a fixed A0 increment.
  The slope k is the share of T's predicted release the data realize: near 1 where T is right, near
  0 where it is wrong. The intercepts, the RF splines and the predA0 terms absorb A0's level,
  its nonlinear RF trend and its proportional error, which vary with removal intensity (the 14.0.4
  L2 gap runs from +0.229 heavy to -1.436 light), so the slope contrast is not driven by those parts
  of A0's error. Error that covaries with D at fixed RF and predA0 is not removed and is named as a
  limit in the RESULT. Paired plot bootstrap. A group with fewer than 30 stands, or whose bootstrap 95% interval
  of k is wider than 1.0 (it cannot separate 0 from 1), is uninformative. The standard deviation of D
  after the covariates are partialled out is reported. The ratio of sums
  sum(Y) / sum(D) is reported beside it.
- **Survivor increment ratio (reported).** For v1 to v2 survivors in heavy and intermediate stands,
  sum of observed over sum of 14.1 predicted diameter increment, and the same for A0, by d / Dq class
  (below 0.6, 0.6 to 0.85, 0.85 to 1.15, 1.15 to 1.5, above 1.5; the first two bounds from GT3; Dq
  is the engine's, all stems at 2.54 cm and above at v1) and DQR group, cells of 30 trees or more,
  paired plot bootstrap. Read on the cells above 1.15 d / Dq pooled over tst: HG if the observed over
  14.1 ratio is within 0.10 of 1 for DQR at or above 1 and more than 0.10 lower for DQR below 1; HR if
  it is more than 0.10 below 1 in both and the two differ by 0.10 or less; neither otherwise. The
  0.10 is a choice, swept at 0.05 and 0.20. This test does not use the FCCL classifier.
- **Reported.** Gaps by FORTYPGRP_V0 (T was fitted on CTRN spruce-fir), with types of 30 or more
  stands (PREREG45 bin floor). Each arm's eligible share by class. RF, DQR and RD_res by class. The
  128 stands with natural disturbance at the second visit, apart. pef_c results split at tst 17.

## Stress test

A1 at RF_MAX 0.35 and 0.65 and RF on merchantable volume are run and reported as non-evidential,
since they restate the FCCL class bounds. The other variants are evidential:
- the net removal rule (PCT_REMOVED_NET);
- the 95th and 5th percentiles of the threshold locations in place of the maximum and minimum;
- a less restrictive variant: RF_MAX and RD_MIN over the threshold locations plus the pef_c stands
  with a pre visit and a known tst of 17 yr or less;
- DQR at or above 0.95 and at or above 1.05;
- trees dead from other causes counted as removed;
- minimum retained trees of 2 and 8;
- the 128 disturbed stands excluded.

A headline quoted at the favorable end of its range is flagged.

## Decision rule, per arm, in order

1. Any harness gate fails: no verdict for that arm.
2. **Gate F, feasibility.** A0 is assembled and read before any eligibility arm. If the smallest
   attainable absolute gap exceeds tol in heavy (0.346) or intermediate (0.515), no eligibility rule
   can pass P1 or P2. The study closes as "L limited", A1 to A3 are still run and reported without
   verdicts, and the remedy is outside this study. Gate F closes the study on tol at 25% only; at
   15% and 35% it is reported, and a verdict that differs is labeled sensitive. The bound the arms
   can actually reach, with missing stands held at their A0 prediction, is reported beside it. A0
   failing rule 1 gives no verdict for any arm.
3. P1, P2, P3 or P5 fails, or a gated class is uninformative: not adopted, failing gate named.
4. **Realized T slope.** In heavy and in intermediate, all of the following:
   - the paired 95% upper limit of k withheld minus k kept is below 0;
   - the point difference is at most minus 0.25 [choice, swept at 0.10 and 0.50];
   - the 95% interval of k kept intersects [1 minus m, 1 plus m], where m is the contrast margin
     (0.25, swept at 0.10 and 0.50).

   Outcomes, applied in this order:
   - Any group uninformative in either class: not adopted, uninformative.
   - In both classes, both k upper limits below 1 and the point contrast within ±m: not adopted,
     HR favored.
   - Any other failure: not adopted, unresolved.

   A rule 4 failure alone does not establish HR; the survivor increment reading is weighed with it.
   Reported beside it: the placebo distribution of the same contrast, and for A2 and A3 a placebo
   stratified by RF decile, which carries the intensity gradient that a random placebo does not.
5. N1 or N2 fails: not adopted, trade off reported.
6. All pass: a 14.3 candidate, subject to rule 7. A1 and A2 candidates carry the partial support
   label.
7. **Confirmation.** Before adoption, the candidate and 14.1 run on a New Hampshire and Vermont
   post-harvest FIA set and must pass P1, P2, P3, P5 and rule 4 there.
   - The set comes from a copy of the mefia_ph_c builder, changed only in the state tables and
     JURIS. Its mefia_l_c validation step (height source, ESI extraction) is replaced by the same
     check against an unmanaged New Hampshire and Vermont set built by the same copy. The diff is
     registered before the build.
   - 14.1 must show the heavy gap there (paired 95% lower limit above tol); otherwise the
     confirmation is uninformative and rule 7 stays open. An uninformative rule 4 there also leaves
     rule 7 open rather than rejecting the candidate.
   - ESI coverage of New Hampshire and Vermont in the Acadian ESI v8 raster is checked first. If
     fewer than 80% of candidate stands are covered, the set is not built and rule 7 is open.
   - Each gated class needs 30 stands or more (the PREREG45 floor).
   - The set is not built until a candidate exists.

If more than one arm reaches rule 6, the order alone decides: A3, A1, A2. A3 has no estimated
constant, and DQR can be computed for any thinning keyword that names the cut trees. **No
outcome changes 14.1.**

## Execution

Cardinal, named by Aaron for this study on 17 October 2026. Firebreather refuses port 22 from the
laptop and from Cardinal ("No route to host", job 15612299), and it holds none of the inputs. The
work goes in a new directory, `~/v143p1/`. Nothing is overwritten and frozen runs are read only.
The chain runs in this order:
1. thresholds, support check and their md5;
2. the overlay `AcadianGY_14.3dev_thinelig.r`, sourced after 14.1 and asserted to be the identity
   when off;
3. gates E0 to TR;
4. A0 on every frame, then gate F; then Apv and A1 to A3 on mefia_ph_c, ctrn_c, ctrn_fl, pef_c and
   the grid; the placebo draws are assembled from the A0 and 14.1 runs;
5. paired plot bootstrap scoring;
6. assembly, as a separate step with its md5 recorded before it runs.

Script md5s go to `logs/launch_md5s.txt` before the chain starts. Deviations are logged in the
RESULT.

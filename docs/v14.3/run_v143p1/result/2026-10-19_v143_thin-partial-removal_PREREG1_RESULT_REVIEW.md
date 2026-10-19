# The 14.1 thinning response limited to partial removals, for 14.3: result of pre-registration 1

Run 18 and 19 October 2026 on Cardinal in `~/v143p1/`, against the registered plan `2026-10-18_v143_thin-partial-removal_PREREG1.md` (md5 7f3e67c2, checked before any work). Every number below is a row of `2026-10-19_v143-prereg1_RESULT-tables_r2_DATA.md` (assembled by `v143_assemble.R`), of the TH support file `support_v143_DATA.csv`, or of the score files the tables compile (`score_ALL_counters_DATA.csv`, `score_ALL_survivor_cells_DATA.csv`, `score_ALL_favorable_flag_DATA.csv`). Gaps and rates are in Mg ha⁻¹ yr⁻¹, with paired plot bootstrap 95% intervals (1,000 resamples of 781 plots, seed 20261017). Deviations are listed at the end. 14.1 is unchanged by any outcome here. L and T were not re-estimated, and GT1 stays a named failure.

## Verdict

No eligibility rule is adopted. A1 and A2 (both carrying the partial support label: thresholds from 30 locations in 9 of the 17 T fit installations) and A3 each stop at rule 3 with an uninformative gated class. Each also fails gated benchmarks at the registered tolerance: P1 for all three (heavy gap 0.572 for A1, 0.395 for A2 and 0.428 for A3, against 0.346 and against 1.391 under 14.1), P2 for A1 and A2, and P3 in light stands for A3.

Gate F did not close the study at the registered 25%, because L adds only 0.088 over 14.0.4 L2 in heavy stands and A0's heavy gap of 0.317 sits inside the tolerance. That verdict is sensitive: at 15% gate F would have closed the study as L limited.

The realized T slope (rule 4) is uninformative in every arm, so the separating test registered for HG against HR gives no answer. The registered survivor increment reading, a reported diagnostic weighed beside rule 4, is HR at all three thresholds: the observed increment of large residual trees is about two thirds of 14.1's prediction whether the removal kept or lowered Dq. The remedy that reading points to (re-estimating or attenuating T) is outside this study and is Aaron's decision. Rule 7 was not reached, so the New Hampshire and Vermont confirmation set was not built.

## Harness gates (rule 1)

All harness gates pass.

- **E0.** With the overlay switched off, every result and tree list file reproduces frozen 14.1 byte for byte (md5) on all 19 Phase D sets and on mefia_ph_c. The 20 thinned grid trajectories are identical in every value; the grid check compares data, not md5.
- **E0b and E0c.** With the overlay on and every stand ineligible, results reproduce 14.1 byte for byte on the 16 sets with no known years since thinning and on all 31 chunks (217 files) of the 200 yr mefia_l_c frame. A0 on the grid reproduces the frozen 14.1 level-only grid.
- **TR.** On four eligible mefia_ph_c stands the traced m_T matched the 14.1 formula exactly over 2,977 calls (maximum absolute difference 0), with years since thinning advancing by one per step from the TST file and the m_T arguments matching the call's tst and Dq. The four ineligible stands drew no m_T call.
- **K1, CAP and TH.** No arm has a stand with RUN_OK other than 1 (73 units). V141_RELCAP equalled the coefficient rel_cap at four decimals in all 460 task logs. Every TH file still matches the md5 recorded before the first arm output.

The scorer also checked, before scoring, that each run arm equals its stand by stand assembly from A0 and 14.1: biomass on all 827 mefia_ph_c stands and total volume on ctrn_c, ctrn_fl and pef_c, maximum absolute difference 0 (scorer log `logs/v143score2_15670888.out` on Cardinal). That identity is what licenses assembling the placebo draws and the stress variants.

## Thresholds and support

The 30 CTRN locations with a visit before and after their first thinning lie in 9 of the 17 installations, and all 30 are among the 119 locations of the T fit. Over them RF_MAX is 0.721 and RD_MIN is 0.182; DQR at or above 1 is definitional. As registered, these thresholds lean restrictive because they come from a partial view of the T support. One effect pulls the other way: GYDB holds no dead records for CTRN, so mortality over the pre to post gap counts as removal there, which raises CTRN RF (and so RF_MAX) and lowers retained RD_res (and so RD_MIN). The mean lag from the last pre visit to the thinning is 1.13 yr at the threshold locations and 2.36 to 2.49 yr across the mefia_ph_c classes. DQR is a proxy: the engine's Dq covers every stem at or above 2.54 cm at v1, tst years after the cut.

| mefia_ph_c class (known tst) | Stands | Median RF | Median DQR | Median RD_res | DQR 0.95 to 1.05 | Eligible: Apv, A1, A2, A3 |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Heavy | 205 | 0.818 | 0.838 | 0.082 | 0.082 | 166, 39, 13, 21 |
| Intermediate | 178 | 0.492 | 0.936 | 0.236 | 0.275 | 178, 177, 143, 44 |
| Light | 141 | 0.193 | 0.996 | 0.356 | 0.809 | 141, 141, 139, 67 |
| Low volume | 238 | 0.563 | 0.921 | 0.087 | 0.388 | 184, 146, 47, 52 |

Heavy stands sit far outside the CTRN support: 166 of 205 exceed the CTRN RF range, 174 fall outside its DQR range and 192 outside its RD_res range. In heavy stands 39 are missing for having fewer than 4 retained trees at or above 12.7 cm; in low volume stands 51 are missing for that reason and 3 for having no tree at or above 12.7 cm (no Dq); none is missing in the other classes. Across mefia_ph_c, 1,118 trees recorded dead from causes other than cutting (283 in heavy stands) and 9 trees with other status codes were excluded from both the removed and the retained parts. In GYDB every CTRN and PEF tree record is live, so no tree was excluded there, and a tag absent at the first post visit counts as removed.

## Gate F (rule 2)

| Class | 14.1 gap | A0 gap | Smallest gap any rule can reach | Range reachable with missing stands at A0 | tol 25% | Closes at 15%, 25%, 35% |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| Heavy | 1.391 (1.138 to 1.640) | 0.317 (0.066 to 0.559) | 0.317 | 0.317 to 1.276 | 0.346 | yes, no, no |
| Intermediate | 1.408 (1.084 to 1.745) | -0.211 (-0.519 to 0.128) | 0 | -0.211 to 1.408 | 0.515 | no, no, no |

L adds 0.088 over 14.0.4 L2 in heavy stands, under the 0.117 the plan named, so P1 stayed attainable. T lowers no stand's predicted change, so the heavy bound is A0's gap. Given L, T accounts for 0.924 (0.919 to 0.930) of the 14.1 minus 14.0.4 L2 heavy gap and 0.896 (0.889 to 0.902) of the intermediate gap.

## Benchmark gates (rules 3 and 5), tol 25%

| Arm | Heavy gap (P1) | Intermediate gap (P2) | Light: gap, worsening limit (P3) | Low volume gap (P3) | AGB bias, % (P5) | Uninformative classes (eligible, not eligible) |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| A1, partial support | 0.572 (0.295 to 0.824), fail | 1.406, fail | 0.459, 0.000, pass | 0.377, pass | 4.74, pass | intermediate (177, 14), light (141, 5) |
| A2, partial support | 0.395 (0.132 to 0.644), fail | 1.113, fail | 0.439, 0.013, pass | -0.214, pass | 2.57, pass | heavy (13, 208), light (139, 7) |
| A3 | 0.428 (0.170 to 0.670), fail | 0.178 (-0.169 to 0.528), pass | -0.423, 0.854, fail | -0.189, pass | 0.17, pass | heavy (21, 200) |

The worsening limit is the paired 95% upper limit of the change in absolute gap from 14.1, against a margin of 0.316 in light stands. A3 passes P2 because it withholds T from 147 of 191 intermediate stands, but it moves light stands from overprediction to underprediction (-0.423), and the paired limit of that worsening is 0.854. A1 is informative in heavy stands (39 eligible, 182 not) and still fails P1. P5 fails for Apv (6.39%) and for 14.1 (7.04%).

At tol 35% (heavy tolerance 0.485) A2 and A3 pass P1, but A2 still fails P2 and A3 still fails P3 in light stands. No arm passes P1, P2 and P3 together at 15%, 25% or 35%, so the benchmark verdicts do not depend on tol; the study as a whole does, through gate F. The paired heavy fall from 14.1 is 0.819 (A1), 0.995 (A2) and 0.963 (A3), short of the 1.045 a P1 pass needs.

N2 passes for every arm: all 20 thinned grid cells are eligible under A1, A2 and A3, and their trajectories equal 14.1's. N1 fails for every arm on ctrn_fl. There the first-last total volume absolute bias is 18.74 (A1, A2) and 18.92 (A3), against 15.89 under 14.1 and 18.74 under Apv. Most of that loss comes from the data rule (Apv carries it, since 44 of the 63 ctrn_fl stands with a known tst lack a pre visit); for A3, 0.18 comes from the threshold. ctrn_c and pef_c %RMSE stay within 0.5 points of both references. pef_c %RMSE for stands with tst of 17 yr or less, above 17 yr and unknown is 14.26, 16.35 and 17.75 (A1), 14.14, 16.17 and 17.75 (A2) and 13.98, 16.27 and 17.75 (A3).

## Realized T slope (rule 4)

Every group in every arm is uninformative. The kept groups of A2 and A3 in heavy stands (13 and 21 stands) fall below the 30 stand floor, A1 withholds T from a single intermediate stand, and every bootstrap interval of k is wider than 1.0, two of them only just: A2 intermediate k kept (0.101 to 1.107) and A3 intermediate k withheld (0.078 to 1.084). Stands with an unknown tst were dropped (16 heavy, 13 intermediate).

| Arm, class | k kept | k withheld | Contrast (95%) | Placebo 95% range | sum Y / sum D, kept and withheld | SD of D, partialled |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| A1 heavy | 0.707 | 1.034 | 0.327 (-1.739 to 1.962) | -1.634 to 1.795 | -0.199, -0.233 | 0.443 |
| A2 heavy | 0.293 | 1.090 | 0.796 (-7.146 to 9.497) | -3.550 to 4.180 | -1.122, -0.144 | 0.443 |
| A2 intermediate | 0.615 | -0.130 | -0.745 (-2.025 to 0.517) | -1.189 to 1.172 | 0.174, -0.018 | 0.652 |
| A3 heavy | 0.527 | 1.016 | 0.489 (-2.483 to 3.683) | -2.743 to 2.580 | -0.475, -0.191 | 0.447 |
| A3 intermediate | 0.505 | 0.608 | 0.104 (-0.932 to 1.085) | -1.028 to 1.095 | 0.074, 0.160 | 0.641 |

The registered rule asks for an upper limit of the contrast below 0, a point contrast at or below -0.25, and an interval of k kept that reaches [0.75, 1.25]. Only A2 intermediate has the registered sign and clears the point threshold; it fails on its upper limit of 0.517. Every observed contrast lies inside its random placebo range. The RF decile stratified placebo shifts the A2 medians to 0.784 (heavy) and -0.445 (intermediate), so the observed A2 heavy contrast (0.796) is what removal intensity alone produces, and the intermediate contrast (-0.745) lies 0.30 below that median, well inside the stratified range (-1.523 to 0.561). The threshold and margin sweeps change no rule 4 outcome.

## Survivor increment ratio (reported, registered reading)

For survivors in heavy and intermediate stands at d / Dq above 1.15 (engine Dq, all stems at or above 2.54 cm at v1), the observed diameter increment is 0.679 (0.648 to 0.710; 4,963 trees) of 14.1's prediction where the removal lowered Dq and 0.649 (0.563 to 0.738; 815 trees) where it kept or raised Dq. Both are more than 0.10 below 1 and they differ by 0.030, the registered HR pattern; the reading is HR at 0.05, 0.10 and 0.20. Against A0 the same ratios are 1.249 and 1.198. Read together, 14.1 predicts about 1.84 times A0's increment for these trees, while observation is about 1.2 times, so roughly a quarter to a third of T's predicted release is realized. 9,599 survivor trees were linked, 4,752 of them hardwoods rebuilt from their form and risk sub-records.

| d / Dq class | Observed over 14.1, DQR below 1 | Observed over 14.1, DQR at or above 1 |
|:--:|:--:|:--:|
| Below 0.6 | 1.177 | 1.165 |
| 0.6 to 0.85 | 1.144 | 1.206 |
| 0.85 to 1.15 | 1.086 | 1.113 |
| 1.15 to 1.5 | 0.919 | 0.948 |
| Above 1.5 | 0.576 | 0.497 |

As an interpretation, not a registered test: on point values 14.1 underpredicts every class below d / Dq 1.15 and overpredicts above it, most strongly above 1.5, in both DQR groups; every interval excludes 1 in the DQR below 1 group, while in the smaller DQR at or above 1 group the intervals of the 0.6 to 1.5 cells include 1 (0.992 to 1.420, 0.943 to 1.332 and 0.783 to 1.116) and the cell above 1.5 lies below it (0.441 to 0.568). That pattern points to the relative size response of T (gamma 2, capped at d / Dq 2.98) at least as much as to alpha, which HR as registered names. The engine counters agree that T reaches far past its fit. Tree steps above the relative size cap, and the largest d / Dq, by class under Apv, A1, A2 and A3:

| Class | Tree steps above the cap | Largest d / Dq |
|:--:|:--:|:--:|
| Heavy | 4,673, 809, 117, 586 | 11.2, 6.5, 4.5, 11.2 |
| Intermediate | 5,222, 5,222, 3,627, 1,606 | 7.6, 7.6, 7.6, 7.6 |
| Light | 5,039, 5,039, 4,960, 2,523 | 6.9, 6.9, 6.9, 6.9 |
| Low volume | 8,083, 7,288, 2,085, 3,341 | 9.6, 9.6, 7.0, 9.4 |

Requiring DQR at or above 1 (A3) does not lower the largest d / Dq in heavy stands.

## Stress test

No evidential variant passes P1, P2 and P3 together, and rule 4 is uninformative in all of them. No headline above sits at the favorable end of its stress range.

- The 95th percentile RF threshold (A1_P95) brings the heavy gap to 0.334, inside tolerance, but leaves intermediate at 1.231. The 5th percentile RD_res (A2_P05) gives 0.350, just above tolerance, and intermediate 0.859.
- DQR at or above 0.95 (A3_095) passes P2 and P3 and fails P1 (0.464). DQR at or above 1.05 gives intermediate 0.020 and heavy 0.394, with light at -1.134.
- The less restrictive thresholds (A1_LR at RF 0.971, A2_LR at RD_res 0.020) reproduce Apv's gaps (heavy 1.276, intermediate 1.408) and fail P5.
- The net removal variant (A1_NET; PCT_REMOVED_NET is a volume fraction set against a basal area threshold) gives heavy 0.705.
- Counting trees dead from other causes as removed, and minimum retained trees of 2 or 8, move the heavy gap by at most 0.06.
- Excluding the 128 stands with natural disturbance at v2 raises the heavy gap under each arm (to 0.636, 0.454 and 0.471).
- Non-evidential, since they restate the FCCL class bounds: A1 at RF_MAX 0.35 passes P1 to P3 and P5 only by withholding T from every heavy stand (heavy gap 0.317, equal to A0). A1 at 0.65 gives heavy 0.371 and intermediate 1.380, and RF on merchantable volume gives heavy 0.541.

## Other reported results

By forest type group (30 stands or more), spruce-fir heavy stands keep a larger gap than maple-beech-birch heavy stands under every arm (0.692 to 0.833 against 0.302 to 0.504), and spruce-fir intermediate stands are larger still (A1 1.906, A3 0.947). A3's intermediate pass comes from maple-beech-birch (0.078). T was fitted on CTRN spruce-fir.

The 128 stands with natural disturbance at v2, by class (14.1, A0, A1, A2, A3): heavy (32 stands) 1.194, 0.026, 0.195, 0.052, 0.173; intermediate (35) 1.987, 0.117, 1.987, 1.590, 0.720; light (23) 0.722, -1.017, 0.722, 0.722, -0.411; low volume (38) 0.131, -1.052, -0.310, -0.893, -0.667.

## What this means for 14.3

Limiting T to removals inside the CTRN support does not fix the post-harvest overshoot without removing T from most of the stands where it acts. Where a rule is informative (A1 in heavy stands, A2 and A3 in intermediate stands) it either fails the gate (A1, P1; A2, P2) or passes it at the cost of light stands (A3, P3). The registered survivor reading is HR, and the size class pattern suggests the relative size term carries a large part of the excess. Two follow-ups fit that evidence, both outside this study, both needing their own pre-registration, and both Aaron's decision: re-estimate T with a gentler relative size response or a lower cap on a set that includes operational removals, or attenuate T for removals beyond the CTRN support. Nothing here changes 14.1.

## Limits

Rule 4 cannot separate error in A0 that covaries with D at fixed RF and A0 increment, and here it could not separate anything because the groups are small or the intervals wide. The thresholds come from 30 locations in 9 installations. DQR is a proxy measured at pre visit diameters, while the engine works on its own Dq tst years after the cut. The survivor reading uses the engine's Dq at v1 and t1 expansion weights. Gate F passes at 25% by a margin of 0.029 and closes at 15%.

## Deviations and implementation readings

The full list, with the stage log, is `2026-10-19_v143-prereg1_DEVIATIONS.md`. Those that bear on reading this result:

1. CAP was asserted at four decimals (setting 2.9848, rds 2.98478, difference 2.0e-5); strict equality would have voided every arm, frozen 14.1 included.
2. The stress variants and placebo draws were assembled from the A0 and 14.1 runs rather than run, after an exact assembly check on the four run arms.
3. A1_NET sets a volume based removal fraction against the basal area threshold, as A1_VOL does.
4. The class floor counts every stand that is not eligible; the rule 4 withheld group counts threshold ineligible stands only.
5. In GYDB each CTRN and PEF PlotID is one remeasurement interval of a single physical plot. The first TH attempt linked trees within PlotID, found 0 of the registered 30 locations and stopped before writing anything; the revised TH step links tags across interval records and reproduces 30 locations in 9 installations. The revision preceded every arm output, and the launch md5 list was re-recorded.
6. The first scoring pass read the TH md5 log with the wrong separator and marked TH failed, which voided every verdict as rule 1. The parser was fixed, the gate rerun, and the superseded files kept in `out/superseded_PREV_20261019/`; every number was unchanged and only the TH row and the verdict column moved.
7. N1 "within 0.5 points" was applied literally (two sided); the one sided reading gives the same outcome here.
8. Engine counters are per stand from the overlay, because the runner's counters are per process.
9. K1 was applied strictly (no RUN_OK other than 1); the PREREG38 retry rule was not re-implemented, and the frozen 14.1 runs had no such stand on any set.
10. In rule 4 the natural spline basis in RF is fixed on the full sample and resamples enter as plot weights; placebo draws are point contrasts.
11. The grid and E0c launchers are copies of the frozen bak141 and long200 launchers (their drivers), with the 14.1 settings verbatim.
12. The dry run on synthetic stands exercised every script except the E0c launcher, but no decision branch after rule 1.

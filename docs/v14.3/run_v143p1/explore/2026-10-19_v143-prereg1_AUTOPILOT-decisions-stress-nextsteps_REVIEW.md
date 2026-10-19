# 14.3 pre-registration 1: autopilot decisions, stress test and next steps

19 October 2026. This follows the RESULT (`2026-10-19_v143_thin-partial-removal_PREREG1_RESULT_REVIEW.md`). Everything in the stress test section is exploratory and was not registered. It does not change the registered verdict, and it is labeled exploratory wherever it is cited. The script is `v143_explore_stress.R` (Cardinal `~/v143p1/autopilot/`, md5 f18b284a) and the outputs are in `~/v143p1/out/explore/`. Gaps and rates are in Mg ha⁻¹ yr⁻¹.

## Decisions taken

**PRs #9 to #12: kept open, none merged or closed.** They form one stack of draft documentation PRs, and none is superseded by later work. This run's instruction was not to merge PRs. The new branches sit on top of #12 and do not change it. The merge order after review is #9, #10, #11, #12, then the 14.3 run branch.

**LICENSE: not added this cycle.** CC BY 4.0 is confirmed only for the v12.10.1 data deposit. A code license is a rights decision for the university's IP office as much as for the lab. Choosing one on autopilot would publish a grant of rights that cannot easily be withdrawn. The lowest-cost path when Aaron wants it is MIT (or GPL-3, to match FVS) for code and CC BY 4.0 for documents, in a single LICENSE plus a NOTICE section in README. That takes one commit.

**Cardinal engine copies: committed on a new branch.** The branch is `engine-frozen-cardinal-20261019`, off PR #12's branch and unmerged. It holds the copies the benchmarks ran, each with its md5:

- the 13.1 base (5894df60);
- `model_b0b1b2.r` (bb51eead);
- 14.0.4 (61f95d99);
- 14.1 (0bf27dde);
- the two form and risk helpers, the Phase D hooks, the counters runner (300a0d61) and the 13.2 site overlay;
- two coefficient tables, `nsvb_emulator_coefs.csv` and `spcd_spgrpcd.csv`.

The repo held none of the 14.x engines before this branch. The branch leaves out the two lookup files keyed by stand (`v129_gate3_dedup.csv`, `v129x_brms_sdimax_map.csv`), because they carry identifiers. It adds the coefficient rds files only if a scan finds no identifier-like data frame in them. A clone therefore runs 14.1 end to end except for those two lookups, and the README says so.

**R9 md5 discrepancy: resolved for Cardinal.** The only Cardinal copy of `model_b0b1b2.r` is bb51eead (a second copy under `p5p/` has the same bytes). Every 14.x benchmark launcher on Cardinal checks bb51eead. The other md5, 04a0b71d, appears in exactly one file, `v142_20260925/recs/htfix/fb_bundle/home/run_task.sh`, which is a launch bundle prepared for firebreather. So 04a0b71d is firebreather's copy, and it is unverified while firebreather is down. bb51eead is the base of the benchmarked 14.1.

**T follow-up: recommend re-estimating T's form (option 1), with two diagnostics first.** The reasons are in the stress test below. This is Aaron's call, and it needs its own pre-registration. A draft outline is given under next steps.

**Track B: still skipped.** Firebreather refused port 22 at 05:14, 06:35 and again at the start of this pass. Nothing was published, and the Zenodo 1.9.0 go remains unused.

## Stress test of the conclusions (exploratory)

**S1. The HR survivor reading is robust.** The registered reading uses trees at d / Dq above 1.15 in heavy and intermediate stands and compares observed with 14.1 predicted increment, split by DQR. That reading was recomputed under 12 variants. All 12 read HR at the 0.10 threshold.

| Variant | DQR at or above 1 | DQR below 1 |
|:--:|:--:|:--:|
| Registered (expf weighted) | 0.649 (0.563 to 0.738) | 0.679 (0.648 to 0.710) |
| Unweighted trees | 0.555 | 0.602 |
| Softwoods only | 0.590 | 0.613 |
| Hardwoods only | 0.751 | 0.756 |
| tst 1 to 2 yr | 0.557 | 0.633 |
| tst 3 to 5 yr | 0.653 | 0.693 |
| Spruce-fir | 0.661 | 0.648 |
| Maple-beech-birch | 0.695 | 0.711 |
| No natural disturbance at v2 | 0.666 | 0.669 |
| Heavy only | 0.722 | 0.716 |
| Intermediate only | 0.616 | 0.636 |
| Dq on trees at or above 12.7 cm | 0.426 | 0.437 |

The DQR groups never differ by more than 0.08, so the geometry reading (HG) gets no support from any variant. Two patterns bear on model form:

- **Species.** The overshoot is larger for softwoods (about 0.60) than for hardwoods (about 0.75), even though T was fitted on CTRN spruce-fir.
- **Timing.** The overshoot is larger in the first two years after the cut (0.56 to 0.63) than at 3 to 5 yr (0.65 to 0.69). T is at its maximum at tst 1 and decays at 8% per year (beta 0.082). The observed release looks more like one that builds over the first years.

**S2. Gate F at 25% is fragile.** A0's heavy gap (0.317) sits below the 0.346 tolerance in only 56% to 60% of plot bootstrap resamples, across four seeds, and in 58% of stand resamples. Intermediate is below tolerance in every resample. The registered rule reads the point estimate, so the study stays open. Whether L alone (with T off) can meet P1 is effectively a coin flip.

**S3. The stand level realized share of T is mixed.** This fits the rule 4 model without groups (slope of observed minus A0 on T's predicted addition, at fixed RF spline and A0 change):

| Classes | Stands | k (95%) | sum Y / sum D |
|:--:|:--:|:--:|:--:|
| Heavy | 205 | 0.96 (0.24 to 1.66) | -0.20 |
| Intermediate | 178 | 0.52 (0.05 to 0.98) | 0.14 |
| Heavy and intermediate | 383 | 0.68 (0.30 to 1.06) | -0.01 |
| Light and low volume | 376 | 0.23 (-0.12 to 0.59) | 0.56 |

Within heavy stands, those where T predicts more release do realize more, with a slope near 1 but a wide interval. On average, though, heavy stands realize none of T's predicted addition: observed change sits slightly below A0's (sum Y / sum D = -0.20). The heavy overshoot is therefore mostly a level error, which T adds on top of a small A0 overshoot. A pure rate cut (attenuating alpha) would fix the level only by also flattening a slope that looks roughly right in heavy stands. A form change (release lag, gentler size response) can fix the level while keeping the slope.

**What survived the stress test.** The registered verdict (no rule adopted) is not sensitive to any of these checks. HR holds in every variant, although the size of the large-tree excess depends on how Dq is defined: the ratio is 0.43 to 0.44 with Dq on trees at or above 12.7 cm, against 0.65 to 0.68 with the engine's Dq. Gate F is the weakest link: the study remained open on a margin that a resample erases 40% of the time.

## Next steps

**1. Two cheap diagnostics before any new study (Cardinal, about a day).**

- (a) Rebuild the S1 table on the CTRN post-thinning records that T was fitted on. If 14.1 fits CTRN at d / Dq above 1.5 but overshoots there on FIA, the defect is the extrapolation to operational removals. If it overshoots on CTRN too, the defect is the fixed gamma of 2 (the GT1 failure).
- (b) Cross-tabulate the S1 ratio by tst year and d / Dq class on mefia_ph_c and pef_c, to see whether a lag-then-decay release fits better than the exponential decay.

Both are read-only and use existing outputs.

**2. Pre-registration 2 for 14.3: re-estimate the form of T.** Draft outline, not registered:

- **Candidate forms.** m_T = 1 + alpha f(tst) g(d / Dq), with f either exponential decay (the 14.1 form, as baseline) or a rise-then-decay (gamma shaped) term. g is either a power with gamma free, a power with a lower cap (about 1.5), or a saturating form.
- **Fitting.** Fit on CTRN and PEF post-thinning records with installation-clustered bootstrap intervals, as in GT1. L stays fixed at 14.1's lambda.
- **Validation.** mefia_ph_c is held out entirely as external validation. The registered gates are the survivor increment ratio within 0.10 of 1 in every d / Dq class with 30 or more trees, plus P1 to P3 and P5 at the 25% tolerance, plus N1 and N2 against 14.1.
- **Confirmation.** The New Hampshire and Vermont post-harvest set (rule 7 of PREREG1), built only once a candidate exists.
- **Constraint.** This is a new study because it re-estimates T, which PREREG1 forbade.

**3. Settle gate F's fragility in the same plan.** Pre-register a P1 check of A0 (14.1 with T off) on the New Hampshire and Vermont set. That gives the "L limited" question a second, independent sample.

**4. Repo.** Open draft PRs for `v143-prereg1-run-20261019` and `engine-frozen-cardinal-20261019`, both against `docs-overhaul-20261017`. Cardinal has no GitHub token, so these are one-click links for Aaron. Then merge the stack bottom-up after review.

**5. Track B when firebreather answers.** In order:

- publish Zenodo 1.9.0;
- run p38_fit and qc_rh on mefia_l_c, mefia_ph_c and the 200 yr frame;
- run PREREG46, then the PREREG47 reading (revision 5);
- restage 1.10.0, which is not to be published without Aaron's go;
- verify the 04a0b71d copy of `model_b0b1b2.r` on firebreather against bb51eead.

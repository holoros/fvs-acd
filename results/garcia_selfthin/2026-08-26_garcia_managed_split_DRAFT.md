# Does the Garcia self-thinning curve move when managed pairs are removed?

Draft, August 26, 2026. Uncommitted. Nothing in the committed Garcia chain was edited to produce this.

## What was asked and what was done

The committed pooled Garcia (2009) relative-spacing self-thinning fit in this directory reports alpha 3.222059, beta 0.0680769838 and gamma 5.688335, fit by `nlme` over the three sources ns, ns_long and mefia_subp, and the committed write-up describes it as restricted to natural or lightly managed stands. That description is wrong, since no management filter was ever applied. The filter was dropped at `2026-08-26_garcia_stand_extraction.R` line 49, which selects only STAND and interval_years off the source pairs file and therefore discards the MANAGED column that ns and ns_long both carry. The question here is narrow, namely whether the curve actually moves once the managed pairs are taken out, so that the correction Aaron publishes is a measured result rather than a caveat.

The MANAGED flag was recovered by re-joining `bench_ns_pairs.csv` and `bench_ns_long_pairs.csv` on STAND, and the counts confirm the earlier audit exactly. Of the 2,987 pairs entering the pooled fit, 627 are managed, which is 20.991 percent, split 468 from ns and 159 from ns_long. The 321 mefia_subp pairs are unlabelled rather than unmanaged, since `bench_mefia_subp_pairs.csv` carries no MANAGED column at all, so 21 percent is a floor on the managed share and not a point estimate. Every stand contributes exactly one pair in all three sources, so a row-level resample is a stand-level resample.

## Reproduction check, which passed

The committed pooled specification was re-executed verbatim, meaning the same `nlsList` starting values of alpha 3, beta 0.07 and gamma 5, the same `random = beta ~ 1 | source` with the alpha fallback, and the same `nlmeControl` settings of maxIter 300, msMaxIter 300, pnlsMaxIter 100, tolerance 1e-4 and pnlsTol 1e-3. It reproduces to machine precision on all 2,987 pairs, with absolute differences of 2.7e-15 in alpha, 3.3e-10 in beta and 4.4e-15 in gamma, and the approximate 95 percent intervals come back identical to the committed report at [2.3806, 4.0635], [0.061346, 0.074808] and [4.2161, 7.1605]. The downstream work is therefore trustworthy.

## The primary estimator does not survive the split

The `nlme` estimator converged only on the full pooled set. It failed on all three subsets, and the failure modes are informative rather than incidental. On the 2,360 unmanaged-or-unlabelled pairs and on the 2,039 labelled-unmanaged pairs it failed with "step halving factor reduced below minimum in PNLS step" under both random-effect structures, and on the 627 managed pairs it failed with "Singularity in backsolve at level 0, block 1" under both.

The reason is visible in the per-source `nls` coefficients that feed `nlsList`. On the pooled data the ns group alone already converges to alpha 14.109 and gamma 14.920, an extreme and physically implausible optimum of exactly the kind the committed script's own comment identifies as poisoning the PNLS step for ctrn. Removing the managed pairs pushes ns further out, to alpha 22.284 and gamma 14.933, at which point the hierarchical step no longer completes. So the committed pooled fit is not merely contaminated by managed stands, it is also carrying a group whose own likelihood is already at a degenerate corner, and its convergence is fragile to any change in the data at all. That is a second defect, independent of the management question.

Because a subset whose primary fit fails still has to be reported with an interval, every subset was also fit with the bounded multi-start least-squares estimator taken unchanged from `2026-08-26_garcia_fit_bounded.R`, meaning L-BFGS-B from 27 starts with lower bounds c(0.3, 0.001, 0.3) and upper bounds c(30, 2, 40). This is a like-for-like comparator across subsets rather than a tuned rescue. Its credentials are good, since the pooled random-effect standard deviation in the committed fit is 1.33e-06, so the mixed model is effectively pooled least squares and the two estimators target the same optimum. On the pooled set the bounded estimator returns alpha 3.217072, beta 0.06804312 and gamma 5.680159, within 0.005, 3.4e-05 and 0.008 of the committed values, and density ceilings of 38,948, 3,369 and 805 trees ha⁻¹ against the committed 38,874, 3,363 and 804 trees ha⁻¹. Intervals for the bounded estimator are 2.5 and 97.5 percentiles of 500 nonparametric bootstrap resamples of the stand pairs, all 500 of which converged in every subset. Intervals for the `nlme` row are the Wald intervals from `intervals()` for the parameters and Monte Carlo percentiles from 40,000 draws on the fixed-effect covariance for the derived quantities.

## The three coefficient sets

The asymptote slope is 2γ/α, the exponent of the limiting relation N ∝ H^(−2γ/α) implied by setting the integration constant to zero in S^α = C + (βH)^γ, which with S = 100 N^(−1/2) gives the density ceiling N = 10⁴ (βH)^(−2γ/α). That expression returns 38,874, 3,363 and 804 trees ha⁻¹ from the committed coefficients, matching the roughly 38,800, 3,350 and 800 trees ha⁻¹ quoted in the audit, so the derivation is the intended one.

**Table 1.** Garcia self-thinning coefficients by management subset, with 95 percent intervals. The pooled row is given under both estimators to show they agree. Intervals are bootstrap percentiles for the bounded rows and Wald intervals for the nlme row.

| Subset | n | Estimator | α (95% CI) | β (95% CI) | γ (95% CI) | 2γ/α (95% CI) |
|---|---|---|---|---|---|---|
| Pooled, committed | 2,987 | nlme | 3.2221 (2.3806, 4.0635) | 0.068077 (0.061346, 0.074808) | 5.6883 (4.2161, 7.1605) | 3.5309 (2.8862, 4.3195) |
| Pooled | 2,987 | bounded LS | 3.2171 (2.5688, 4.1865) | 0.068043 (0.058606, 0.080194) | 5.6802 (4.4857, 7.3399) | 3.5313 (2.5822, 4.7991) |
| Unmanaged or unlabelled | 2,360 | bounded LS | 2.7214 (2.0987, 3.4987) | 0.066279 (0.056422, 0.075999) | 5.0927 (4.0136, 6.4861) | 3.7427 (2.9198, 5.1655) |
| Managed only | 627 | bounded LS | 4.6892 (3.8852, 11.9310) | 2.0000 (0.083665, 2.0000) | 0.4541 (0.3000, 9.1564) | 0.1937 (0.1227, 1.9294) |
| Unmanaged, labelled only, mefia_subp dropped | 2,039 | bounded LS | 5.5246 (3.4114, 8.6289) | 0.10129 (0.071502, 0.15024) | 6.8512 (5.5463, 8.4138) | 2.4802 (1.6728, 3.8218) |

The managed-only row is a non-result and should be read as one. Its beta sits exactly on the upper bound of 2.0 and its gamma sits within 0.16 of the lower bound of 0.3, and the bootstrap interval for beta runs from 0.0837 to the bound itself, so the optimizer is reporting a boundary solution rather than an interior optimum. The implied slope of 0.194 corresponds to a curve that is nearly flat in height, which is not a self-thinning line in any usable sense. The `nlme` fit on the same 627 pairs failed with a backsolve singularity, and the per-source `nls` fits disagree wildly, with ns at alpha 12.60 and gamma 13.70 while ns_long runs off to beta 2.85e+04. The honest statement is that 627 managed pairs from two sources do not identify the Garcia parameters, and the reason is mechanical rather than statistical, since a thinned stand's trajectory in relative-spacing space is dominated by the harvest rather than by mortality and carries little information about the limiting curve. No tuning was attempted to force convergence.

## Density ceilings

**Table 2.** Implied self-thinning density ceilings in trees ha⁻¹ at three top heights, with 95 percent intervals from the same resampling.

| Subset | Estimator | 10 m | 20 m | 30 m |
|---|---|---|---|---|
| Pooled, committed | nlme | 38,874 (23,478, 80,894) | 3,363 (2,852, 4,247) | 804 (635, 1,060) |
| Pooled | bounded LS | 38,948 (18,076, 125,368) | 3,369 (2,640, 4,758) | 805 (571, 1,177) |
| Unmanaged or unlabelled | bounded LS | 46,617 (22,764, 180,249) | 3,482 (2,678, 5,450) | 764 (549, 1,083) |
| Managed only, boundary solution | bounded LS | 5,598 (4,398, 12,926) | 4,895 (3,053, 7,533) | 4,525 (1,399, 7,023) |
| Unmanaged, mefia_subp dropped | bounded LS | 9,686 (5,042, 37,742) | 1,736 (1,440, 2,640) | 635 (467, 826) |

Removing the managed pairs moves the unmanaged ceiling up by 19.7 percent at 10 m, up by 3.4 percent at 20 m and down by 5.1 percent at 30 m, which is a modest steepening of the curve rather than a shift in level. Every one of those three unmanaged ceilings sits inside the pooled bootstrap interval, and so does every one of the three unmanaged parameters and the slope. The uncertainty at 10 m is enormous under both fits, spanning roughly an order of magnitude, which is expected since 10 m top height sits well below the height range where these pairs actually observe mortality and the ceiling there is an extrapolation of the fitted exponent rather than something the data constrain.

## The mefia_subp gap

The 321 mefia_subp pairs carry no MANAGED column, so the unmanaged-only fit is really an unmanaged-or-unlabelled fit, and it inherits whatever managed stands Maine FIA happens to contain. That matters more than the headline comparison suggests. Dropping mefia_subp entirely and fitting only the 2,039 labelled-unmanaged ns and ns_long pairs gives alpha 5.525, beta 0.1013 and gamma 6.851, a slope of 2.480 against 3.743 with mefia_subp included, and ceilings of 9,686, 1,736 and 635 trees ha⁻¹. Three of those quantities sit outside the pooled bootstrap interval, namely alpha, beta and the slope, and so do the ceilings at 10 m and 20 m, with 20 m falling to 52 percent of the pooled value. The 321 unlabelled Maine pairs are 13.6 percent of the unmanaged subset yet they dominate the fitted exponent, and they are the only source in the set carrying stands short enough and dense enough to anchor the low-height end of the curve. So the unmanaged curve does depend on an unlabelled source, and it depends on it heavily. A reader should be told that the 2,360-pair unmanaged fit is not a clean natural-stand curve, it is a two-thirds-labelled curve whose shape is set by the unlabelled third.

## Files written

All uncommitted, in `/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/results/garcia_selfthin/`. The fit script is `2026-08-26_garcia_managed_split_fit.R`, the coefficient table is `garcia_managed_split_coef_2026-08-26.csv`, the recorded primary-estimator failures are `garcia_managed_split_nlme_failures_2026-08-26.csv`, and the full console log including every model summary is `garcia_managed_split_log_2026-08-26.txt`.

## Answer

The committed curve needs re-describing rather than replacing, but it needs more re-describing than the management error alone implies. Taking the 627 managed pairs out moves alpha from 3.217 to 2.721, beta from 0.06804 to 0.06628 and gamma from 5.680 to 5.093, and moves the density ceilings from 38,948, 3,369 and 805 trees ha⁻¹ to 46,617, 3,482 and 764 trees ha⁻¹, all of which lie comfortably inside the pooled fit's own 95 percent bootstrap intervals, so on the evidence the contamination did not bias the published coefficients detectably and there is no numerical case for swapping them out. Two other things did surface, though, and both belong in whatever correction gets published. First, the committed `nlme` fit does not converge on any subset of its own data and is already carrying the ns source at a degenerate individual optimum of alpha 14.1 and gamma 14.9, so its apparent stability is a coincidence of the pooled sample rather than a property of the model. Second, the unmanaged curve depends heavily on the 321 unlabelled Maine FIA pairs, and dropping them moves alpha to 5.525 and the 20 m ceiling to 1,736 trees ha⁻¹, well outside the pooled interval, so the management filter cannot be described as recovering a natural-stand curve until mefia_subp is labelled. The defensible published statement is that the pooled curve is fit to all available pairs including at least 21 percent managed stands, that removing the labelled managed pairs does not move it beyond its own uncertainty, and that the estimator and the unlabelled Maine source are the two things that actually control the answer.

# A relative height multiplier for the NB height increment, stand level: PREREG45b result

5 October 2026. Pre-registration `plan/2026-10-05_v142_nb-relht-increment-standlevel_PREREG45b.md` (revision 1, md5
a0b8b166, recorded 17:13 server time before any run, fit or selection). Fit `fit_p45b.R`, fit file fbeaa86a; runner
`runner_p45b_fb.R` and driver `driver_p45b.R` (one insertion each, `diffs/`); assembly `assemble_p45b.R` (3ce976c0) and r2
(bc41b0bd), both md5s recorded before they ran. Informs 14.3 only; 14.2 keeps NB_AFAC 0.579. Aggregates only; stand
identifiers stay in `*_SERVERONLY` files. No coordinates. No em dashes.

## Verdict

**Rule 2: not adopted. The stand level fit does not transfer to fold B: the pooled predicted over observed measured top
height increment ratio is 0.556 (0.403 to 0.835) against the 0.90 to 1.10 window, and the 0.75 to 1 relative height bin is
biased by -0.253 m yr⁻¹.** Every harness gate passes. TOPHT, C0 volume, BA, stems and the 100 year bound pass; non
inferiority fails on HT monotone (2 new flags) and on the Reineke margin. The fold A and fold B observed increments differ
by a factor of 1.7, so the reading is that the observed side of this estimator is too noisy to fit on, not that the form is
right or wrong for NB.

## Fit (fold A, 70 stands)

a = 1.8672 (bootstrap -0.65 to 6.32), b = -2.1924 (-11.0 to 1.06); 45 of 1,000 bootstrap draws did not converge. The b
interval spans zero. m is 2.69 at r 0.4, 0.95 at 0.875 and 0.55 at 1.125. Pooled fold A obs over p0 1.173.

## Harness

| Gate | Result |
|:--|:--|
| G0n | nb141 equals frozen v141LT nb_c, 355 stands, worst 1.8e-15 |
| H0b | nb_rh0 (a = b = 0) equals nb_one, 55 stands, results and per tree 0 |
| G0, G0b | pass (driver_p45b with RH unset) |
| K1 | 0 of 355 not run |
| G1, G2 | 72 of 72 trajectories, age 0 worst 2.6e-15 |
| F9 | fold A population (70) and a, b re-solved in the assembly to 1e-9 |

## Benchmark, nb_c fold B (84 stands with obs and pred defined; 172 non empty stands for TOPHT and volume)

| Gate | nb_rh | nb141 (0.579) | nb_one (1.000) | Threshold | Pass |
|:--|:--|:--|:--|:--|:--|
| H1 pooled ratio | 0.556 (0.403 to 0.835) | 0.281 | 0.484 | 0.90 to 1.10 | no |
| r bins, bias m yr⁻¹ | -0.102 (27), -0.253 (28), -0.025 (29) | -0.282, -0.309, -0.027 | | absolute 0.04 | no |
| TOPHT bias | +9.49% | +1.04% | +3.45% | at most 10% | yes |
| C0 %RMSE | 34.61 | 34.48 | 34.05 | not worse by 0.5 | yes |
| BA, stems (points) | 2.11, 14.19 | 2.64, 13.12 | | within 1.0 and 2.0 | yes |

Observed mean increment is 0.283 m yr⁻¹ on fold B against 0.169 on fold A. Every arm, including 14.1, under predicts the
fold B measured top height increment by a factor of two to four while its published TOPHT bias is small (+1.04% for
nb141). The measured top height (the mean of measured heights in the dominant cohort) changes between visits partly because
a different subset of trees is measured, and NB has no stable tags to pair them; that is the most likely source.

## Long run, 36 measured nb_c fold B stand lists, 100 years

| Arm | HT/ESI at 0 | at 50 | at 100 (median) | Over 1.384 | Mean top height at 100 (m) |
|:--|--:|--:|--:|--:|--:|
| nb141 | 0.409 | 0.718 | 1.038 | 1 of 36 | 18.94 |
| nb_rh | 0.409 | 1.013 | 1.230 | 1 of 36 | 22.43 |

Gate C passes. Non inferiority fails on HT monotone (11 flags against 23, 2 new, falls of 0.06 and 0.26 m, worst margin
2.16 against 2.05) and on the Reineke margin (1 flag against 3, none new, worst 0.31 against 0.17). Eichhorn (1 against 2),
magnitude (0 against 1) and yield density (1 against 3) flag less often under nb_rh; frontier is equal (1 and 1).

## Deviations

Assembly r1 stopped at the decision line because the H0b per tree difference was NA for records with no height in both arms;
r2 changes only that line (both NA equal, one NA infinite), md5 recorded before it ran; log kept as
`assemble_r1_NA_stop.log`. The F9 row of the gates table prints threshold values in place of a and b because a later
section reuses the name `th`; the F9 test itself ran on the fit values before that (TRUE). `waiter_s2.sh`, which started stage
2 after stage 1, was not in the launch md5 list.

## Reading and recommendation

The NB arm cannot be decided with stand level measured top height on these frames. Before a 14.3 NB height arm, obtain a
tree paired NB height increment sample (NB tag linkage from the provincial PSP records, or a remeasured height subsample),
then rerun the PREREG45 field tag design. Until then NB stays at 0.579.

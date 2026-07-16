# Phase 2 scope: hardwood form and risk keyed value and sawlog modifier for FVS-ACD

15 July 2026. This document scopes Phase 2 of the hardwood form and risk direction: building the missing form and risk keyed sawlog and value modifier that Phase 1 does not touch. Phase 1 wired predicted form and risk into the growth (`ddbh_hw_mod`) and survival (`tsurv_hw_mod`) modifiers; it does nothing to volume or value. The hardwood value error is the largest single number in the frozen benchmark (VALUE about 81 percent %RMSE on hardwood, against about 76 percent for TOTVOL), and value has no form or risk term in v13.0 at all. Phase 2 targets that error using Ryan Smith's published coefficients. Grounded in `data/hardwood_form_risk_plan.md` and `data/hardwood_form_risk_investigation.md`. No em dashes.

## Why value is the right Phase 2 target

On the frozen basis v12.10.1 hardwood stand value reads about +20 percent mean bias but about 81 percent %RMSE, the worst scatter of any metric in any stratum. Smith's Chapter 2 gives the mechanism and independent confirmation: on ten managed northern Maine stands, FVS default outputs predicted 59 percent (Ashland) and 63 percent (Rangeley) of merchantable volume as sawlog, against 28 to 34 percent for the form and risk and ASG field methods and 19 to 22 percent for stick cruising. FVS sawlog volume ran 44 to 66 percent above the field methods, and FVS standing value was significantly higher than every field method (p < .05). That is the same failure mode, direction, and rough magnitude as the frozen benchmark's hardwood value inflation. A growth model with no stem quality term cannot see that a large-diameter hardwood is a cull or a fork, so it merchandises it as sawlog and overvalues the stand.

## What already exists in the engine

The old sawlog proportion function is still present in v13.0 as `hw.saw.prop(sp, dbh, form, risk)` at line 4202 of `AcadianGY_13.0.r` (and in the 12.6.2 prototypes), but it is inert: it is not called from the value pipeline, and `value_fns.R` computes sawlog and pulp splits with no form or risk input. The frozen benchmark's own value calculation (in `bench_parity.R`, function `metrics`) splits merchantable into sawlog and pulp purely by the NSVB `VOLCSNET` sound sawlog volume, again with no form or risk term, and prices hardwood sawlog at 75 and pulp at 10. So both the operational engine and the benchmark scorer currently have a form and risk shaped hole exactly where Smith's product ratio belongs.

## Smith 2022 Eq 13 and Eq 16, the usable coefficients

Smith fit two hardwood models with the structure Castle used, presence then proportion. Both are mixed effects with stand and plot random effects, VSURF plus AIC selection. Eq 13 is the sawlog presence model, a binomial with a logit link. Eq 16 is the product ratio model (proportion of merchantable volume that is sawlog quality, Svol/Mvol on 0 to 1), a beta regression with a logit link. The full Table 1.5 estimates are below. Reference levels are NHRI form classes 2 to 8 (so `Form1` is the ideal straight form indicator) and NHRI risk class 1 (so `Risk2` and `Risk3` are contrasts, with `Risk3` folding classes 3 and 4). Species enter through a species by DBH interaction term; American beech (*Fagus grandifolia* Ehrh.) is the reference for the DBH interaction in Eq 16 and so has no `AB x DBH` row there.

| Ind. variable | Par. | Eq. 13 estimate (SE) | Eq. 16 estimate (SE) |
|---|---|---|---|
| Intercept | b1 | -37.4916 (2.1573) | -35.1440 (2.1969) |
| log(DBH) | b2 | 12.6034 (0.8745) | 12.7029 (0.8555) |
| log(HT/DBH) | b3 | 2.3705 (0.6924) | -0.7946 (0.1448) |
| BAL | b4 | -0.0319 (0.0145) | not in model |
| Form1 (ideal form) | b5 | 1.2739 (0.1877) | 0.1393 (0.0395) |
| Risk2 | b6 | -0.7455 (0.2097) | -0.1801 (0.0436) |
| Risk3 (classes 3 and 4) | b6 | -4.0545 (0.2592) | -0.2903 (0.0796) |
| AB x DBH | b7 | -0.1166 (0.0406) | reference |
| OH x DBH | b7 | -0.1436 (0.0347) | -0.2864 (0.0243) |
| PB x DBH | b7 | -0.1331 (0.0345) | -0.2928 (0.0242) |
| QA x DBH | b7 | -0.1451 (0.0350) | -0.2823 (0.0241) |
| RM x DBH | b7 | -0.1522 (0.0302) | -0.2916 (0.0240) |
| RO x DBH | b7 | -0.0400 (0.0311) | -0.2911 (0.0240) |
| SM x DBH | b7 | -0.1405 (0.0276) | -0.2901 (0.0238) |
| WA x DBH | b7 | -0.0960 (0.0403) | -0.2791 (0.0243) |
| YB x DBH | b7 | -0.1414 (0.0281) | -0.2886 (0.0238) |

Fit: Eq 13 AUC 0.93 fixed effects, 0.97 with random effects. Eq 16 R-squared 0.29, RMSE 0.1534, MAE 0.1202, bias -0.0068 on the 0 to 1 scale (low precision, low bias). Species codes: AB American beech, OH other hardwoods, PB paper birch (*Betula papyrifera* Marshall), QA quaking aspen (*Populus tremuloides* Michx.), RM red maple (*Acer rubrum* L.), RO northern red oak (*Quercus rubra* L.), SM sugar maple (*Acer saccharum* Marshall), WA white ash (*Fraxinus americana* L.), YB yellow birch (*Betula alleghaniensis* Britton).

Functional forms, implementable as written:

- Sawlog presence, P(sawlog) = plogis( b131 + b132 log(DBH) + b133 log(HT/DBH) + b134 BAL + b135 Form1 + risk_contrast + b137_species DBH ), where risk_contrast is 0 for R1, b136(R2), or b136(R3).
- Product ratio, Svol/Mvol = plogis( b161 + b162 log(DBH) + b163 log(HT/DBH) + b164 Form1 + risk_contrast + b166_species DBH ). No BAL term. American beech carries no species DBH term (reference).

Both share the rise then fall shape in DBH: the large positive log(DBH) coefficient is offset by the negative species by DBH term on raw DBH, so the sawlog proportion peaks near 46 to 48 cm and declines past about 60 cm. Table A.10 maximum sawlog proportions confirm this: paper birch 71.1 percent at 46.1 cm, red maple 72.2 percent at 46.3 cm, red oak 72.7 percent at 46.3 cm, sugar maple 73.6 percent at 46.5 cm, yellow birch 75.0 percent at 46.8 cm, white ash 82.5 percent at 48.3 cm. DBH is in cm, HT in m, BAL in m² ha⁻¹.

## The class system mismatch and how to bridge it

Smith keys his models to a binary ideal form (F1 versus F2 to F8) and three risk groups (R1 reference, R2, R3 folding R4). The FVS-ACD engine's prediction functions output a different consolidation: `calc_form_prob` returns four NHRI form class probabilities (STM, LSW, MST, LF) and `calc_risk_prob` returns a single high risk probability (two levels). The bridge is mostly clean on form and requires a judgment on risk.

Form: Smith's `Form1` ideal indicator maps directly to the engine's STM class, so the expected `Form1` value per tree is `stm.prob` from `calc_form_prob`. That is exact, because STM (single straight stem) is NHRI F1, which is precisely Smith's ideal form.

Risk: this is the imperfect seam. Smith needs a three level contrast (R1, R2, R3+R4) but `calc_risk_prob` only predicts P(high risk). The defensible first pass is to treat the engine's high risk probability as the probability of the combined R2 plus R3 mass and split it, or more simply to map high risk to the R3 (classes 3 and 4) contrast and low risk to R1, ignoring R2. Because the R3 contrast in Eq 16 (-0.2903) and the R2 contrast (-0.1801) are close on the product ratio scale, the value model is not very sensitive to that choice; a conservative implementation uses the R2 contrast (the milder, more common defect level) for the high risk mass to avoid overcorrecting. Either way this is a mapping decision, not a refit, and it should be stated explicitly and tested both ways. A light refit of Eq 16 against the engine's two level risk output is the cleaner alternative if the mapping proves sensitive.

## The expected value implementation

The engine predicts class probabilities, not classes, so the modifier is a probability weighted expectation, the same formulation used in Phase 1. Per hardwood tree, the expected sawlog fraction of merchantable volume is the presence probability times the product ratio, each evaluated at the probability weighted form and risk:

    sawfrac_hat(tree) = P_sawlog(tree) * ratio(tree)

    P_sawlog = sum over form in {ideal, non-ideal}, risk in {R1, high} of
               w_form * w_risk * plogis( Eq13 linear predictor at that form and risk )

    ratio    = sum over the same classes of
               w_form * w_risk * plogis( Eq16 linear predictor at that form and risk )

with w_ideal = stm.prob, w_nonideal = 1 - stm.prob, w_R1 = 1 - risk.prob, w_high = risk.prob (mapped to the chosen R2 or R3 contrast). This expected sawlog fraction then replaces the current NSVB sound sawlog split in the value calculation: hardwood sawlog volume becomes sawfrac_hat times merchantable volume, the remainder is pulp, and stumpage value follows the existing hardwood sawlog and pulp prices. Softwood and the value of non hardwood species are untouched.

## Concrete build sequence

The work is an integration on the value side, parallel to Phase 1 on the growth side. First, add a top level function, an expected value analogue of `hw.saw.prop`, that returns sawfrac_hat per tree from `calc_form_prob`, `calc_risk_prob`, and the Smith Eq 13 and Eq 16 coefficient tables (new tribbles carrying the Table 1.5 estimates for RO, SM, YB, RM, plus PB, QA, AB, WA, and the OH pool). Second, connect it into `value_fns.R` so hardwood merchantable volume splits into sawlog and pulp by sawfrac_hat rather than by the raw NSVB sound sawlog volume, behind a new toggle (for example `ops$use.hw.value.mod`) so it can be A and B tested cleanly. Third, run the frozen benchmark A and B, value modifier off versus on, and read hardwood VALUE and SAWVOL %RMSE, the two metrics with the worst frozen scatter, exactly as Phase 1 read BA, TOTVOL, and increment. Reuse the Phase 1 harness pattern (`bench_parity_hwmod.R` with an env toggle, `analyze_hwmod_ab.R` restricted to the frozen `frozen_subsidiary_W.rds` stand set and fortype). Gate any keeper against `cb_v12101` the same way every v13 candidate is gated, and check that softwood and mixedwood value do not regress.

One benchmark subtlety to handle honestly: the frozen scorer computes VALUE inside `bench_parity.R` from NSVB volumes with fixed prices, not from the engine's `value_fns.R`. To A and B test the value modifier through the benchmark, the sawfrac_hat split has to be applied in the scorer's `metrics` function (or the scorer switched to call the engine value path), so the modifier actually reaches the reported VALUE and SAWVOL. This is a scorer change, not an engine change, and must be done in a prototype copy so the frozen scorer stays untouched.

## Honest caveats

Smith's own central negative result governs the whole direction: predicting form and risk from stand and site variables was largely unsuccessful for hardwoods, AUC 0.63 to 0.66, and good only for low variability spruce-fir. So feeding predicted rather than observed form and risk into Eq 13 and Eq 16 carries real uncertainty; the value models discriminate well given form and risk (Eq 13 AUC 0.93), but the form and risk they are fed are weakly predicted. The expected value formulation softens this by never hard assigning a class, but it cannot manufacture signal that the prediction step does not carry. Species coverage is the four Castle hardwoods plus Smith's four additions (American beech, paper birch, quaking aspen, white ash), which is exactly the set that dominates the hardwood scatter, but white ash (n = 129) and American beech (n = 269) are thin and beech is confounded by beech bark disease and its roughly 70 percent high risk rate. The class system mapping on risk is a modeling choice that should be tested both ways or resolved by a light refit. And the frozen scorer change described above must be made carefully so the baseline stays exactly reproducible.

The right validation asset is observed form and risk on real stands, which the benchmark cannot supply because no inventory source on Cardinal carries NHRI form or risk. Smith's underlying field data, the 18,003 tree form and risk set and the ten stand merchandized set with observed form and measured sawlog heights, sits with Seven Islands Land Company, collected under NSF CAFS INTERN award 1915078 and sourceable through Weiskittel. Securing that data is what turns Phase 2 from a plausible correction into a validated one, because it lets the predicted form and risk, and the resulting sawlog fraction, be checked against ground truth rather than only against downstream volume and value.

## Coefficient module built and validated (15 July 2026)

The Eq 13 and Eq 16 coefficients above are implemented in `scripts/hw_sawfrac_smith.R` as `p_sawlog`, `prod_ratio`, and the expected value wrapper `hw_sawfrac_ev`. A self test reproduces Smith's Table A.10 maximum product ratios and peak diameters closely for all six named hardwoods, which confirms the transcription and the functional form:

| species | module peak DBH (cm) | module max ratio | Table A.10 DBH | Table A.10 max |
|---|---|---|---|---|
| paper birch | 44.8 | 70.1% | 46.1 | 71.1% |
| red maple | 45.0 | 71.2% | 46.3 | 72.2% |
| red oak | 45.1 | 71.7% | 46.3 | 72.7% |
| sugar maple | 45.3 | 72.6% | 46.5 | 73.6% |
| white ash | 47.1 | 81.5% | 48.3 | 82.5% |
| yellow birch | 45.5 | 73.9% | 46.8 | 75.0% |

Peak diameters land within about 1.3 cm and maximum ratios within about 1 percent, with white ash correctly the highest, and the small consistent offset is the expected effect of using the benchmark height imputation rather than Smith's observed heights. The per tree sawlog fraction rises then falls with diameter (for red oak, ideal form, low risk: 0.02 at 20 cm, 0.63 at 35 cm, 0.70 at 50 cm, 0.49 at 65 cm), which is exactly the shape that would deflate FVS-ACD's over prediction of large hardwood sawlog volume. The remaining Phase 2 work is the integration described above (wire `hw_sawfrac_ev` into the value path and the benchmark scorer, add the `ops$use.hw.value.mod` toggle, run the frozen A and B on hardwood VALUE and SAWVOL %RMSE, gate against `cb_v12101`).

## Gating decision (15 July 2026)

Aaron's call: build Phase 2 regardless of the Phase 1 growth and survival A and B outcome, because Phase 2 targets the largest hardwood error (VALUE about 81 percent %RMSE, SAWVOL) that Phase 1 does not touch, and because the growth and survival modifiers saturate for large hardwoods, so value is the higher leverage lever.

## Frozen A/B verdict, SLURM 12372773 (15 July 2026)

Job 12372773 (`hwvalue.sbatch`) ran to COMPLETED on Cardinal (00:20:17, exit 0:0) and the frozen v12.10.1 projection wrote `~/magplot/verify/hwvalue_results.csv` (705 stands on the frozen basis: 321 softwood, 186 mixedwood, 178 hardwood, 20 unknown). The PARITY check passed cleanly: NSVB predicted VALUE, SAWVOL, BA, and TOTVOL each reproduce `cb_v12101` with max|hwvalue - cb| = 0.000e+00, so the NSVB path and the underlying projection are unchanged and the A/B isolates the merchandizing swap.

Operational note: the summarizer `analyze_hwvalue_ab.R` halted on a top level `else` syntax error (line 21, the parity `if`/`for` block has no braces, so the trailing `else` parses as an unexpected top level token), so `hwvalue_ab_summary.csv` and `hwvalue_pred_reduction.csv` were not written by the job. All inputs survived, so the A/B was recovered read only from `hwvalue_results.csv` using the script's own `pctrmse` and stratum logic (outputs staged to /tmp, nothing in Aaron's tree or the frozen scorer was touched, no job resubmitted). The one line fix is to brace the block (`if (...) { for (...) cat(...) } else cat(...)`) and rerun `Rscript ~/analyze_hwvalue_ab.R` on the login node to regenerate the canonical CSVs.

Result, hardwood stratum (n = 178), Smith form/risk merchandizing on versus NSVB off:

| metric | %RMSE off (NSVB) | %RMSE on (Smith) | dRMSE | bias off | bias on |
|---|---|---|---|---|---|
| VALUE | 81.05 | 91.91 | +10.87 | +20.38 | +21.09 |
| SAWVOL | 80.24 | 95.82 | +15.57 | +18.35 | +17.74 |

dRMSE is positive for both, so Smith merchandizing did not reduce the predicted versus observed discrepancy on this benchmark; it raised hardwood VALUE %RMSE by about 10.9 points and hardwood SAWVOL %RMSE by about 15.6 points. Mean bias barely moved (VALUE +20.4 to +21.1, SAWVOL +18.4 to +17.7), so the over prediction was not removed, only re scattered. Softwood did not regress (VALUE dRMSE +0.66, SAWVOL +0.60; bias flat near -14). Mixedwood degraded modestly (VALUE dRMSE +3.08, SAWVOL +4.76). POOLED was near flat (VALUE +0.03, SAWVOL +2.07).

Predicted side merchandizing change, Smith versus NSVB, the Chapter 2 over prediction magnitude (this compares only the predicted tree list under the two schemes, independent of observed): hardwood SAWVOL falls 43.4 percent (mean 64.08 to 36.26) and hardwood VALUE falls 36.8 percent (mean 4913.59 to 3105.22). Mixedwood falls about 16 percent on both; softwood falls about 2 percent, as expected since Smith form/risk acts on hardwoods. So Smith does exactly what Chapter 2 predicts to the predicted side: it cuts the over merchandized large hardwood sawlog hard.

Honest reading of the two results together: this benchmark applies Smith merchandizing to both the observed and the predicted tree lists, so the %RMSE A/B tests only whether swapping schemes tightens predicted versus observed agreement, not whether Smith is closer to truth. Applying Smith to the observed side also cuts the observed sawlog and value, moving the target, and the %RMSE rises because the two schemes disagree, not because Smith is wrong. The large predicted side reduction (about 43 percent on hardwood SAWVOL) is the real signal that NSVB over merchandises hardwood sawlog, but its correctness cannot be adjudicated here. True field value validation still needs the Seven Islands merchandized set with observed form and measured sawlog heights (NSF CAFS INTERN 1915078, sourceable through Weiskittel).

Keeper gate: on this benchmark alone Smith form/risk merchandizing is not a keeper over `cb_v12101`, since it worsens hardwood and mixedwood predicted versus observed %RMSE and does not improve softwood. v12.10.1 stays shipped. Nothing ships without Aaron's sign off.

## Sensitivity result: risk-class and scope axes, SLURM 12376903 (15 July 2026)

Job 12376903 (`hwvalue_sens.sbatch`) ran to COMPLETED on Cardinal (00:17:39, exit 0:0). The frozen v12.10.1 projection (`bench_parity_hwvalue.R`) emitted NSVB, Smith-R3 (`_s`), and Smith-R2 (`_s2`) VALUE and SAWVOL, and `analyze_hwvalue_sens.R` wrote `~/magplot/verify/hwvalue_sens_summary.csv` cleanly (705 stands: 321 softwood, 186 mixedwood, 178 hardwood). Five variants: off (NSVB baseline), R3_both, R2_both, R3_predonly, R2_predonly. R3 maps Smith risk class 3 to the engine high-risk class (R3+R4); R2 is the milder mapping. "both" applies Smith merchandizing to observed and predicted tree lists; "predonly" applies Smith to the predicted list only and scores it against the NSVB observed.

Hardwood stratum (n = 178), each variant versus off:

| metric | variant | %RMSE | dRMSE vs off | bias |
|---|---|---|---|---|
| VALUE | off (NSVB) | 81.04 | baseline | +20.38 |
| VALUE | R3_both | 91.91 | +10.87 | +21.09 |
| VALUE | R2_both | 91.81 | +10.77 | +21.65 |
| VALUE | R3_predonly | 85.58 | +4.54 | -23.93 |
| VALUE | R2_predonly | 82.89 | +1.85 | -20.20 |
| SAWVOL | off (NSVB) | 80.24 | baseline | +18.35 |
| SAWVOL | R3_both | 95.82 | +15.58 | +17.74 |
| SAWVOL | R2_both | 95.19 | +14.95 | +18.62 |
| SAWVOL | R3_predonly | 91.77 | +11.53 | -33.03 |
| SAWVOL | R2_predonly | 87.97 | +7.73 | -28.70 |

No variant reaches or beats off on hardwood %RMSE; off is lowest on both metrics. The closest is R2_predonly (VALUE 82.89 vs 81.04, +1.85; SAWVOL 87.97 vs 80.24, +7.73). The two axes behave distinctly. On the scope axis, "both" keeps hardwood bias positive and near baseline (about +21 VALUE, +18 SAWVOL) but inflates %RMSE by roughly 11 (VALUE) to 15 (SAWVOL) points, so it re-scatters without correcting the mean. "predonly" flips hardwood bias sharply negative (VALUE -20 to -24, SAWVOL -29 to -33): it overshoots, trading a +20 over-prediction for a 20 to 33 point under-prediction, and still does not lower %RMSE. On the risk-class axis, R3 cuts harder than R2 in every case, which is why R3_predonly overshoots most (most negative bias) and R2 is uniformly the milder of the pair.

Predicted-side hardwood reduction versus NSVB, R3 versus R2 (predicted list only, independent of observed): VALUE falls 36.8% under R3 (4913.6 to 3105.2) and 33.7% under R2 (to 3257.4); SAWVOL falls 43.4% under R3 (64.1 to 36.3) and 39.8% under R2 (to 38.6). R3 removes about 3 more points of hardwood value and 4 more of sawlog than R2, consistent with the broader R3+R4 high-risk mapping.

Regression check on the other strata: softwood is essentially inert across all five variants (VALUE %RMSE 50.04 to at most 51.32; bias flat near -14 to -16), as expected since Smith form/risk acts on hardwoods. Mixedwood is contained under "both" (VALUE 48.12 to about 51) but degrades under "predonly" (VALUE to 58 to 59, bias to about -18), the same predonly overshoot seen in hardwood attenuated by the lower hardwood fraction. POOLED tracks the mix (VALUE off 59.41; both about 59.5; predonly 63 to 65). Nothing blows up.

Honest reading: the frozen benchmark has no ground-truth value. bias here is measured against NSVB observed, so off wins the NSVB-anchored metric by construction, and predonly's negative bias is a departure from NSVB, not evidence of error against the field. This run bounds behavior and lets us pick a sensible default mapping, but it cannot adjudicate correctness. True value validation still needs the Seven Islands merchandized field set with observed form and measured sawlog heights (NSF CAFS INTERN 1915078, sourceable through Weiskittel).

Default from this run: keep the Smith modifier OFF (NSVB baseline) as the shipped default, since no variant improves hardwood on the frozen benchmark. If a modifier must be carried for the predicted-side hardwood sawlog correction that Chapter 2 motivates, R2_both is the most defensible: mildest risk mapping, applied symmetrically so it does not flip the bias sign, closest to baseline bias, with only modest %RMSE cost. Avoid predonly (both mappings), which overshoots hardwood into under-prediction. Keeper gate: on this benchmark alone, no variant is a keeper over `cb_v12101`. v12.10.1 stays shipped. Nothing ships without Aaron's sign-off. FIA true coordinates stay on Cardinal.

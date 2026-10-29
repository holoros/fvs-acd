# Sugar maple survival modifier for FVS-ACD, refit on a form the FIA GRM record supports

Working record, August 26, 2026. Companion to `2026-08-26_fia_crosswalk_formrisk_modifiers_DRAFT.md`,
which this builds on and corrects in four places. It fits a survival modifier for sugar maple
(*Acer saccharum* Marshall) directly from the Maine FIA growth, removal and mortality remeasurement
record, on a functional form that record can actually carry, and it does so having deliberately
abandoned `tsurv_hw_mod`'s functional form for this species. Aaron made that call knowing the result
would not be comparable to the modifiers the engine already carries for quaking aspen, red maple,
red oak, yellow birch and paper birch. The non-comparability is stated in full below and is the
point of the document rather than a caveat appended to it.

**What this replaces, and what it does not.** Sugar maple has carried no survival modifier in
FVS-ACD since v12.3.2, where it was struck from both `dDBH.HW.mod()` and `tsurv_hw_mod()`. A prior
session investigated putting it back in v13.3 as a drop-in sixth row of `tsurv.hw.spp` and declined,
correctly, since a drop-in needs a species intercept and DBH slope pair on the same
paper-birch-referenced logistic scale as the existing five rows, and nothing in the FIA fit lives on
that scale. This work takes the other road. It leaves `tsurv_hw_mod` and its five species rows
untouched, byte for byte, and specifies a separate sugar maple function on its own basis. Nothing in
the engine was edited. The existing five rows were verified unchanged across `AcadianGY_12.11.r`,
`AcadianGY_13.1_DRAFT.r` and `AcadianGY_13.3_DRAFT.r`, where the function body hashes identically in
all three (md5 `9cf01d113dc42cbcdb35e8f241ba1c6e`), so the comparison below holds for whichever
version the branch settles on.

**What the analysis population actually carries, checked rather than assumed.** The tree-level
population at `castle_2017/grm_formrisk/grm_formrisk_analysis_population_2026-08-26.csv` holds 86
columns, of which 78 are populated for at least one sugar maple record. Almost all of them are FIA
growth, removal and mortality accounting fields, meaning per-component expansion factors and
per-component volume and biomass quantities that describe the estimation design rather than the
tree's condition. Stripping those, the fields that are both fully populated and biologically usable
as predictors reduce to five, namely beginning diameter (`DIA_BEGIN`), the two-level crosswalk form
call (`form_begin`), the three-level crosswalk risk call (`risk_begin`), the remeasurement period
(`REMPER`) and the plot identifier (`PLT_CN`). Eight columns are entirely empty for sugar maple,
including all three `SUBPTYP` fields. Absent outright from the saved extract are basal area in larger
trees, plot basal area, crown ratio, height, site index, and any three-level or finer form call.

Two of those absences turn out to be an artifact of the extract rather than a property of the data,
and this is the most consequential finding of the session. The v13.3 disclosure states that
reconstructing basal area in larger trees or plot basal area "would need FIA population adjustment
factors this extract does not carry, and would undercount competitors on any plot with a harvested
tree, since the population is restricted to SURVIVOR/MORTALITY1/MORTALITY2 records." Neither
objection survives contact with the source tables. A competition index is a per-plot quantity that
needs the design expansion factor `TPA_UNADJ`, which `ME_TREE` carries on every tree row, not the
population-level stratum adjustment factors, which serve area expansion in estimation and have no
role in a per-tree competition term. And the undercount concern applies only to reconstructing
density from inside the restricted growth, removal and mortality population, whereas going back to
`ME_TREE` at the previous plot visit and summing over every live tree recorded there includes the
trees later harvested, since they were alive and present at the beginning occasion that defines the
covariate. Doing exactly that resolved a begin-of-interval tree record for 15,881 of 15,881 sugar
maple rows, and yielded plot basal area and basal area in larger trees at 100.00 percent coverage on
both. Median derived plot basal area is 25.0 m² ha⁻¹ and median basal area in larger trees is
12.7 m² ha⁻¹, both squarely plausible for Maine northern hardwood. Condition-level fields joined at
the same occasion (site productivity class, stand age, forest type, physiographic class, treatment
and disturbance codes) also came back at 100.00 percent coverage.

The two remaining blockers do stand, unchanged. The crosswalk yields a two-level form call only, so
the three-level NHRI split `tsurv_hw_mod` needs (stem, sweep and crook, multiple stem) cannot be
recovered, and no NHRI form data is staged anywhere in this workspace. And the annualized
complementary log-log hazard scale does not convert onto the untransformed logistic scale
`tsurv_hw_mod` uses, for reasons set out in the non-comparability section. So the prior refusal
remains right on its own terms, meaning a drop-in sixth row is still not available, while the reason
given for it was overstated by half.

**Corrections to the fourth-session write-up.** Four numbers in
`2026-08-26_fia_crosswalk_formrisk_modifiers_DRAFT.md` do not match the fit log at
`grmformrisk_13978142.out`, and all four are carried forward into both session handoffs. The
analysis population is 142,603 rows on 11,246 plots, not "134,646 trees on 8,973 plots." The figure
134,646 is the survivor count, which is the growth model's starting sample before its own 197-row
drop, and the mortality model's n is the full 142,603. Crosswalk coverage measured on this build is
83.38 percent for form and 90.46 percent for risk, not the "98 percent form, 100 percent risk"
quoted, which belongs to an earlier application of the same function to a different population and
should not have been asserted for this one. The 5.0 diameter threshold is 5.0 inches, not 5.0 cm, so
the population begins at 12.7 cm, not 5.0 cm, and the reported diameters throughout that document
are in inches. And the population carries only `MORTALITY1` records, 7,957 of them, with zero
`MORTALITY2`, so the filter's third term never binds. None of these change the fourth session's
conclusions, yet the diameter units error in particular would propagate straight into any downstream
engine coefficient, so it is flagged rather than quietly fixed.

**Sugar maple sample.** 15,881 remeasured trees on 3,216 plots, with 390 deaths, a 2.456 percent
period mortality rate over a mean remeasurement period of 4.99 yr. The six form by risk cells hold
12,920, 1,381, 105, 920, 425 and 130 trees respectively, so two of the six carry fewer than 150
trees, and every cell has at least 97 distinct plots behind it.

**Model form and selection.** The response is a binomial indicator of death over the remeasurement
interval, fit with a complementary log-log link and `log(REMPER)` as an offset, which makes the
fitted linear predictor an annualized hazard and makes the form and risk terms multiplicative on
that hazard. A plot-level random intercept absorbs the substantial between-plot heterogeneity, whose
fitted standard deviation on the cloglog scale is 1.6517. Five candidates were fit in `glmmTMB`, all
converging with a positive definite Hessian, and compared by AIC. The winner is
`MORT ~ form_begin + risk_begin + dbh_cm + sqrt(ba_plot) + bal + offset(log(REMPER)) + (1 | PLT_CN)`
at AIC 3418.84, ahead of the same model with an added form by risk interaction (ΔAIC 8.63), the
same covariates with log diameter in place of linear diameter (ΔAIC 10.24), form and risk alone
(ΔAIC 13.62) and form, risk and log diameter (ΔAIC 14.17). A likelihood ratio test on the form by
risk interaction returns χ² = 5.609 on 2 df, p = 0.061, so the interaction is not retained and form
and risk enter additively on the log hazard. The selected covariate set is, by AIC and without being
steered there, exactly `tsurv_hw_mod`'s own covariate set of diameter entering linearly, basal area
in larger trees entering linearly, and the square root of plot basal area.

The fit was run fresh rather than extracted from the existing joint nine-pool object, for three
reasons. The joint fit constrains the diameter slope, the plot random intercept variance and the
dispersion to be shared across all nine species pools, which is a strong assumption to carry into a
single-species coefficient. The joint fit carries no density covariates at all, since the saved
extract had none. And the joint fit imposes additivity of form and risk without ever having tested
it for sugar maple specifically. The joint fit is still used, as an independent cross-check reported
below, and it agrees.

**Coefficients and uncertainty.** Every term is significant at p < 0.001. Intervals are given two
ways, namely Wald intervals from the `glmmTMB` fixed-effect covariance and percentile intervals from
a plot-level cluster bootstrap of 600 resamples in which whole plots are drawn with replacement,
each resampled plot is given a fresh random-effect identifier so duplicate draws are not silently
collapsed into one group, and the model is refit. All 600 replicates converged with a positive
definite Hessian, so no replicate was discarded. A 50,000-draw Monte Carlo simulation from the
multivariate normal of the fixed effects was also run and reproduces the Wald intervals to three
decimal places, which is a consistency check on the delta-method step rather than an independent
interval.

**Table 1.** Fitted fixed effects for the sugar maple annualized mortality hazard, complementary
log-log link, with Wald 95 percent intervals on the hazard-ratio scale.

| Term | Estimate (cloglog) | SE | Hazard ratio | 95 % lower | 95 % upper | p |
|---|---|---|---|---|---|---|
| Intercept | −6.1577 | 0.3935 | 0.00212 | 0.00098 | 0.00458 | 3.3 × 10⁻⁵⁵ |
| Form F2 vs F1 | 0.6826 | 0.1555 | 1.979 | 1.459 | 2.684 | 1.1 × 10⁻⁵ |
| Risk R2 vs R1 | 1.0161 | 0.1395 | 2.762 | 2.102 | 3.631 | 3.2 × 10⁻¹³ |
| Risk R3 vs R1 | 2.0823 | 0.2342 | 8.023 | 5.070 | 12.697 | 6.1 × 10⁻¹⁹ |
| Diameter, per cm | 0.02732 | 0.00766 | 1.0277 | 1.0124 | 1.0432 | 3.6 × 10⁻⁴ |
| √(plot basal area), per (m² ha⁻¹)^½ | −0.3905 | 0.1062 | 0.6767 | 0.5496 | 0.8333 | 2.4 × 10⁻⁴ |
| Basal area in larger trees, per m² ha⁻¹ | 0.05357 | 0.01245 | 1.0550 | 1.0296 | 1.0811 | 1.7 × 10⁻⁵ |

Plot random intercept standard deviation 1.6517 on the cloglog scale. Sample 15,881 trees, 3,216
plots, 390 deaths.

**Table 2.** Sugar maple form by risk hazard ratios referenced to good form and low risk, with
plot-level cluster bootstrap percentile intervals from 600 resamples.

| Cell | Hazard ratio | Bootstrap 2.5 % | Bootstrap 97.5 % | Wald 2.5 % | Wald 97.5 % | n | Deaths |
|---|---|---|---|---|---|---|---|
| F1 / R1 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 12,920 | 230 |
| F1 / R2 | 2.762 | 2.093 | 3.713 | 2.102 | 3.631 | 1,381 | 68 |
| F1 / R3 | 8.023 | 5.011 | 13.411 | 5.070 | 12.697 | 105 | 11 |
| F2 / R1 | 1.979 | 1.426 | 2.738 | 1.459 | 2.684 | 920 | 33 |
| F2 / R2 | 5.466 | 3.743 | 7.926 | 3.787 | 7.891 | 425 | 23 |
| F2 / R3 | 15.877 | 9.852 | 26.948 | 9.891 | 25.486 | 130 | 25 |

The bootstrap and Wald intervals agree closely throughout, which says the plot random intercept is
already carrying the clustering the bootstrap would otherwise expose, and it is worth saying so
rather than reporting only the wider of the two. The cells with the widest intervals are the two
smallest, F1/R3 at 105 trees and F2/R3 at 130 trees, exactly where they should be.

Two coefficient signs deserve comment rather than silent acceptance. Diameter raises the hazard,
which runs opposite to the negative diameter term inside `tsurv_hw_mod`'s survival logistic. The
population begins at 12.7 cm, so it contains none of the small-stem limb where hardwood mortality
normally falls with size, and what is being estimated is the rising limb only, over a range where
sugar maple decline and cull accumulation genuinely do increase with size. The sign is defensible
inside the fitted range and should not be extrapolated below it. Plot basal area lowers the hazard,
which is counterintuitive as a competition term until it is read as a site quality proxy in an
unstratified statewide sample, and which agrees in sign with `tsurv_hw_mod`'s own negative
√(plot basal area) term. Basal area in larger trees raises the hazard, which is the expected
asymmetric-competition direction and also agrees in sign with the engine function.

**Physical validity screen.** Mortality must rise with worse form and with worse risk. Five
monotonicity tests were run, three risk gradients within each form class and one form gradient
within each of the three risk classes, on the observed annualized rates and independently on the
fitted hazard ratios. All five pass on both, with no exception anywhere and therefore no small-cell
exception to name. Observed annual mortality runs 0.00359, 0.01007 and 0.02191 across R1, R2 and R3
at good form, and 0.00729, 0.01109 and 0.04205 across the same gradient at poor form, and rises from
good to poor form within every risk class. The smallest cell entering any test holds 105 trees. This
is a stronger screen result than the nine-pool fit produced, where two minor reversals appeared in
cells under 70 trees for quaking aspen and red oak. Sugar maple has none.

The crude observed hazard ratios and the fitted ones diverge in the two poor-form, elevated-risk
cells, where the crude values are 3.10 and 11.93 against fitted values of 5.47 and 15.88. This is
the ordinary conditional versus marginal gap, since a random intercept with a standard deviation of
1.65 attenuates any marginal ratio toward one, and it is compounded here by the poor-form cells
holding systematically larger trees (30.0 cm and 38.5 cm mean diameter against 22.9 cm at reference)
with lower basal area in larger trees. The fitted ratios are the conditional, plot-specific ones,
which is the quantity the engine needs, since the engine applies a modifier to a named tree on a
named plot rather than to a population average.

**The engine-ready modifier.** On the cloglog scale with a `log(REMPER)` offset, the negative log of
annual survival is the annual hazard, and a form and risk contrast multiplies that hazard by a
constant. Writing *S*ref for the annual survival probability the engine would otherwise assign the
tree, and HR for the cell hazard ratio in Table 2, the modified annual survival is *S*ref^HR exactly,
so the multiplicative modifier is

    M(S_ref, form, risk) = clamp( S_ref^(HR - 1), 0.60, 1.00 )

which equals 1 at the reference condition of good form and low risk by construction, in the same
spirit as `ddbh_hw_mod` and `ddbh_hw_mod_fia`. It drops into the engine's existing slot without any
structural change, since survival is already assembled as
`tsurv = pmax(0, pmin(surv.tree * tsurv.thin.mod * tsurv.sbw.mod * tsurv.hw.mod, 1.0))`, and
`surv.tree` is precisely the *S*ref the expression above needs. The engine's cycle length is fixed at
one year, so an annual modifier applied once per cycle compounds correctly, and five annual
applications reproduce *S*ref^(5(HR−1)) exactly rather than approximately.

One property of this construction is worth stating because it is unusual for a modifier in this
engine. Because the plot random effect enters the linear predictor additively, it cancels out of the
hazard ratio entirely, so the modifier is invariant to it. And because the modifier is written as a
function of `surv.tree` rather than of a fixed baseline, it tracks any future recalibration of the
sugar maple survival equation automatically instead of drifting away from it. The cost of that
property is that the modifier's numerical value is not a constant per cell, it depends on the
reference survival the engine supplies, which is exactly why it cannot be tabulated as a b0 and b1
pair alongside the other five species.

**Table 3.** Modifier value by cell at several reference annual survival probabilities, with the
range implied by the bootstrap interval on the hazard ratio. The full lookup, including which entries
the clamp touches, is in `sm_modifier_lookup_2026-08-26.csv`.

| Reference annual survival | F1/R1 | F1/R2 | F1/R3 | F2/R1 | F2/R2 | F2/R3 |
|---|---|---|---|---|---|---|
| 0.999 | 1.000 | 0.998 | 0.993 | 0.999 | 0.996 | 0.985 |
| 0.995 | 1.000 | 0.991 | 0.965 | 0.995 | 0.978 | 0.928 |
| 0.990 | 1.000 | 0.982 | 0.932 | 0.990 | 0.956 | 0.861 |
| 0.980 | 1.000 | 0.965 | 0.868 | 0.980 | 0.914 | 0.740 |
| 0.960 | 1.000 | 0.931 | 0.751 | 0.961 | 0.833 | 0.600 |
| 0.900 | 1.000 | 0.831 | 0.600 | 0.902 | 0.625 | 0.600 |

**The clamp, and the evidence that it is inactive.** The clamp is a floor of 0.60 and a ceiling of
1.00 on the returned modifier, and no clamp at all on the hazard ratio itself. Three things justify
that specification. The ceiling of 1.00 is safe because every cell's bootstrap lower bound exceeds
one (the smallest is 1.426 at F2/R1), so no cell can produce a modifier above one and the ceiling
can never bind on a correctly coded tree. The absence of a hazard-ratio clamp is right because the
modifier is a six-cell lookup with nothing to interpolate and nothing to extrapolate over, so a
hazard-ratio clamp would do no guarding and would only truncate a fitted effect. A preset clamp of
[0.75, 6.00], written into the first pass before the coefficients were seen, would have silently cut
the F2/R3 hazard ratio from 15.88 to 6.00 and gutted the single largest effect in the fit, which is
recorded here because it is the sort of thing that survives into production unnoticed. The floor of
0.60 guards only the case where the engine hands the function a reference survival far below anything
the fit saw, and it was checked rather than asserted. Evaluated on every one of the 15,881 fitted
trees at that tree's own conditional reference survival, the raw modifier never falls below 0.7480,
and zero trees reach the floor. The floor first binds at a reference annual survival of 0.966 for the
worst cell (F2/R3) and 0.593 for the mildest non-reference cell (F2/R1), against an in-sample
reference annual survival whose per-cell fifth percentile never falls below 0.9906 and whose overall
minimum is 0.9305. The clamp is therefore
inactive across the entire fitted domain and acts purely as an extrapolation guard.

**Extrapolation domain, and where not to apply it.** The fit covers Maine only, `STATECD` 23, on FIA
annual-inventory plots whose remeasurement periods run 3.7 to 6.1 yr with a first-to-ninety-ninth
percentile span of 4.2 to 5.7 yr. That last number is the tightest constraint in the whole fit. The
annualization rests on a `log(REMPER)` offset estimated over a period range barely wider than one
year, so projecting the modifier onto cycle lengths far from five years leans on the offset's
functional assumption rather than on evidence. Beginning diameter runs 12.7 to 110.0 cm with a first
to ninety-ninth percentile span of 12.7 to 58.9 cm, and the 12.7 cm lower bound is a hard floor set
by the FIA five-inch subplot threshold, so the modifier carries no information whatever about
saplings and poles below that size and should not be applied to them. Plot basal area runs 0.2 to
66.0 m² ha⁻¹ with a fifth to ninety-fifth percentile span of 10.4 to 38.4 m² ha⁻¹, and basal area in
larger trees runs 0 to 58.1 m² ha⁻¹ with a fifth to ninety-fifth percentile span of 0 to
28.7 m² ha⁻¹. Stand age runs 0 to 205 yr with a median of 76 yr, and density runs 15 to
15,509 trees ha⁻¹ with a median of 1,668 trees ha⁻¹. Site productivity class covers only classes 3
through 6, so the fit says nothing about the two most productive FIA classes or the least productive
one. Forest type is 88.4 percent sugar maple, beech and yellow birch (`FORTYPCD` 801), so the
modifier is a northern hardwood result and applying it to sugar maple in a spruce or fir matrix is an
extrapolation across forest type. Fifteen point two percent of records sit on conditions with a
recorded cutting treatment and 11.3 percent carry a non-zero disturbance code, so the sample is
neither purely natural nor purely managed and the modifier should not be read as either.

Two further limits are worth naming. The population is restricted to survivor and mortality
components on the all-live forest land basis, so harvested trees are dropped from the sample rather
than being coded as anything, and the modifier estimates natural mortality conditional on the tree
not having been cut. Since poor-form and high-risk stems are exactly the ones a harvest preferentially
removes, that conditioning is not innocuous, and it most plausibly biases the fitted form and risk
effects downward rather than upward. And the two elevated-risk cells at
poor form hold 105 and 130 trees, so while they pass every screen, their intervals are wide (the
F2/R3 bootstrap interval spans 9.85 to 26.95) and a projection whose behaviour hinges on that one
cell should be reported with that interval attached rather than with the point estimate alone.

**Non-comparability with `tsurv_hw_mod`, stated in full.** The new modifier and `tsurv_hw_mod` occupy
the same multiplicative slot in the engine and are otherwise different objects on different scales,
and the following six differences are the ones that matter.

The scales differ. `tsurv_hw_mod` returns a ratio of two logistic survival probabilities taken from
Smith's NHRI-based hardwood survival equation, evaluated at the tree's form class in the numerator
and at the stem form class in the denominator, with a paper-birch baseline linear predictor of
15.1991 − 0.1509·dbh − 0.1232·bal − 1.4053·√(ba.plot) and a species offset pair b0 and b1 layered on
top. The new modifier returns *S*ref^(HR−1), a power transform of the engine's own annual survival
under a proportional hazard on the complementary log-log scale. A ratio of logistic probabilities and
a proportional hazard coincide only in the limit of small probabilities and equal baselines, and
neither condition holds here, so there is no algebraic conversion between the two and no arithmetic
that turns one coefficient set into the other.

The references differ. `tsurv_hw_mod`'s denominator is its own equation's prediction for a stem-form
tree of the same size and competitive position, meaning a borrowed model's internal reference, and it
is applied multiplicatively to `surv.tree`, a different equation's output, which is already an
approximation the engine accepts. The new modifier's reference is `surv.tree` itself, so the applied
product is exact rather than approximate. That is a genuine improvement in internal consistency and
it is also precisely why the two cannot be swapped.

The predictor definitions differ. `tsurv_hw_mod` keys on a four-level NHRI collapse of form codes F1
through F8 into stem, sweep and crook, multiple stem and other, and carries no risk term at all. The
new modifier keys on the FIA crosswalk's two-level form call built from `TREECLCD`, `TREEGRCD`,
`CULL_FLD` and `DAMAGE_AGENT_CD1` through `CD3`, crossed with that crosswalk's three-level risk call.
Risk is the larger of the two effects in the new fit and the engine's survival modifier has no
channel for it whatsoever, so the two functions are not even measuring the same construct.

The species referencing differs. `tsurv_hw_mod`'s five rows are offsets against a paper birch
baseline. The new modifier is estimated on sugar maple alone, with no borrowing and no reference
species, so its coefficients have no counterpart in `tsurv.hw.spp` and cannot be entered there.

The magnitudes are not on a common footing, and the difference is large enough to matter in
practice. Evaluating `tsurv_hw_mod` verbatim, extracted programmatically out of
`AcadianGY_12.11.r` lines 2037 to 2067 rather than retyped, over this population's own covariate
quantiles (diameter 13.2 to 42.9 cm, basal area in larger trees 6.5 to 19.3 m² ha⁻¹, plot basal area
19.3 to 30.7 m² ha⁻¹), the function returns exactly 1.0000 to four decimal places for red maple, red
oak and yellow birch in both form classes, and returns values between 0.7996 and 1.0000 for paper
birch and between 0.8726 and 1.0000 for quaking aspen. Eighty percent of the 450-cell grid sits
within 10⁻⁴ of one. The mechanism is saturation, since the species offsets push the shared logistic
far enough into its upper tail that numerator and denominator both round to one. Over this covariate
range the engine's existing survival modifier is therefore numerically inert for three of its five
gated species. The new sugar maple modifier at a reference annual survival of 0.99 ranges from 0.9902
at F2/R1 down to 0.8611 at F2/R3, which is a live effect across every cell. Reporting a percent
comparison between an inert function and a live one would be meaningless, and the inertness claim is
scoped to the covariate range stated and is not a claim about the function's behaviour elsewhere.

What breaks if someone treats them as interchangeable. Entering the new sugar maple result as a sixth
row of `tsurv.hw.spp` is not merely inadvisable, it is impossible, since no b0 and b1 pair reproduces
a function whose argument list includes `surv.tree`. Comparing coefficient magnitudes across the two
is a category error, since 0.6826 is a log hazard ratio increment while `tsurv_hw_mod`'s form
contrast of 3.3082 − 2.2518 = 1.0564 is a logit survival increment inside a different equation, and
neither converts without knowing a baseline probability that the two do not share. A benchmark that
toggles the hardwood modifier flag and attributes the resulting delta uniformly across species will
misattribute sugar maple's contribution, because sugar maple's modifier responds to the engine's own
baseline survival while the other five species' modifiers do not, so any recalibration of the
survival equation changes sugar maple's contribution and leaves theirs fixed. And the form codes are
not interchangeable at the input side either. The engine's `form` field carries NHRI codes F1 through
F8, whereas the new modifier's F1 and F2 are the FIA crosswalk's own two-level call, which was never
estimated on NHRI codes. Using v13.3's existing collapse, where NHRI F1, F3, F4 and F7 map to
crosswalk F1 and the rest to crosswalk F2, and where NHRI R4 folds into crosswalk R3, is the
consistent choice since `ddbh_hw_mod_fia` already made it, yet that mapping is an assumption carried
over rather than a measurement, and it is the weakest link in the whole chain.

**Cross-check against the joint nine-pool fit.** The sugar maple hazard ratios implied by the
existing joint fit, formed as the appropriate linear combinations of its species main effects and
species by form and species by risk interactions with Wald intervals from its own covariance matrix,
are 2.838, 8.240, 1.721, 4.883 and 14.177 for the five non-reference cells, against 2.762, 8.023,
1.979, 5.466 and 15.877 from the single-species refit. Every pair overlaps comfortably, and the
largest discrepancy, at F2/R1, is 1.72 against 1.98 with intervals of 1.31 to 2.27 and 1.43 to 2.74.
Two models with different constraints, one with no density covariates and shared nuisance parameters
across nine species pools and one with density covariates and none shared, land in the same place.
That is the closest thing to independent corroboration available here, and it is worth exactly that
much and no more, since both models draw on the same 15,881 trees.

**Recommendation on gating.** Gate it, default off, behind a new sub-flag rather than behind the
existing one. Concretely, add `tsurv_hw_mod_fia(sp, form, risk, surv.tree)` returning the clamped
modifier for sugar maple only, activate it when `ops$use.hw.mod` is TRUE and a new
`ops$use.hw.surv.fia` is also TRUE, and default the new flag to FALSE so the engine stays byte
identical to v13.3 out of the box. The alternative, folding it under `ops$use.hw.mod` alone in the
same way v13.3 folded in `ddbh_hw_mod_fia` for American beech and white ash, is defensible on
consistency grounds and is the second choice, yet it would break the isolation property the v13.3
benchmark currently running as Cardinal jobs 13981173 and 13981174 was designed to test, namely that
every source containing no American beech, white ash or sugar maple scores identically between
baseline and candidate. A separate sub-flag preserves that test and lets sugar maple survival be
scored on its own. Either way, this should not become a default until it has been through a
benchmark run of its own, since a hazard ratio of 15.9 in the worst cell is a large behavioural
change to introduce untested, and the one cell driving it holds 130 trees.

**What could not be verified, and what failed.** The mapping from the engine's NHRI form and risk
codes onto the FIA crosswalk's F1/F2 and R1/R2/R3 calls is assumed, not measured, and no NHRI field
data is staged in this workspace against which to check it. The claim that `tsurv_hw_mod` is
numerically inert for red maple, red oak and yellow birch is verified only over the covariate range
stated above and is not a general claim about the function. The derived plot basal area and basal
area in larger trees were computed from `TPA_UNADJ` on all live trees at the previous plot visit and
were sanity checked against expected Maine ranges, yet they were not cross-validated against an
independent FIA estimate of plot basal area, so a systematic bias in the derivation would not have
been caught. The diameter coefficient's positive sign is defensible inside the fitted range and is
untested below 12.7 cm, where the engine will routinely be asked to run. Three runs failed before
producing anything and are recorded rather than hidden. The first inventory pass died on a POSIXct
comparison in the column-coverage loop and was fixed. The stage two extrapolation domain block died
on a bad `rbindlist` call after the fit and bootstrap had already completed, and was rerun
separately, so the domain numbers come from a later job than the coefficients. And the first pass
carried a preset hazard-ratio clamp of [0.75, 6.00] that would have truncated the largest fitted
effect, which was caught on inspection of the fitted coefficients and corrected in a third pass. The
`osc-cardinal` connector dropped on roughly half of all calls throughout, as expected, and every
result reported here was confirmed by rereading the job log after a successful reconnect rather than
inferred from a call that returned.

**Files.** All written to `results/formrisk_fia/`, uncommitted. The build script is
`sm_build_analysis_frame_2026-08-26.R`, the fit and bootstrap script is
`sm_survival_refit_2026-08-26.R`, the clamp correction and modifier construction is
`sm_modifier_finalize_2026-08-26.R`, and the domain and reference-grid script is
`sm_domain_2026-08-26.R`. Coefficients are in `sm_survival_modifier_coefficients_2026-08-26.csv`,
`sm_fixed_effects_2026-08-26.csv` and `sm_main_effect_hr_2026-08-26.csv`, model selection in
`sm_model_selection_2026-08-26.csv`, the validity screen in `sm_validity_screen_2026-08-26.csv` and
`sm_validity_monotonicity_2026-08-26.csv`, the modifier lookup in
`sm_modifier_lookup_2026-08-26.csv` and `sm_modifier_insample_distribution_2026-08-26.csv`, the
extrapolation domain in `sm_extrapolation_domain_2026-08-26.csv` and
`sm_percell_coverage_2026-08-26.csv`, the joint-fit cross-check in
`sm_joint_vs_smonly_hr_2026-08-26.csv`, the reference hazard in
`sm_reference_hazard_2026-08-26.csv`, the column inventory in
`sm_grm_column_inventory_2026-08-26.csv`, and the engine function's own evaluation grid in
`tsurv_hw_mod_reference_grid_2026-08-26.csv`. The sugar maple analysis frame, the fitted model
object and the 600 bootstrap draws stay on Cardinal at
`/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/sm_refit/` and do not enter the repository, as
does the 52.6 MB tree-level population they derive from. Cardinal jobs 13981929, 13981984, 13982031
and 13982035 carry the run logs.

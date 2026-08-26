# FIA crosswalk growth and mortality modifiers for hardwood form and risk

Working record, August 26, 2026. Answers the question of whether Maine FIA data can support
hardwood form and risk modifiers for FVS-ACD beyond the ones Castle (2018) and Smith (2022) already
built into the engine. It fits new species-level growth and mortality effects directly from the FIA
remeasurement record for the eight species Smith's thesis treats individually, red maple (RM), sugar
maple (SM), yellow birch (YB), paper birch (PB), American beech (AB), white ash (WA), quaking aspen
(QA) and red oak (RO), plus an other-hardwood pool (OH), using form and risk jointly as growth and
mortality predictors rather than as two separate single-response fits.

**What was tried first, and why it was set aside.** Aaron supplied `2017 Master Stem Form and Risk
Data.csv`, a Mark Castle field file keyed by County, Plot, SubPlot and Tree, the same scheme FIA
itself uses, and asked whether it could be joined to ME_TREE and the GRM tables for a tree-level
growth and mortality fit. The county codes are genuine Maine FIPS values and the subplot numbering
matches FIA's four-subplot design, so the join was tested directly rather than dismissed. Only 44 of
83 (County, Plot) pairs matched any FIA plot record in any year, 40 of those 44 had their nearest FIA
measurement in 1995 rather than near 2017, and tree-level number matching at the best available cycle
reached 3.3 percent (37 of 1,112 rows), which is noise rather than a usable linkage. Maine Forest
Service's own plot numbering, superseded when FIA moved to the annualized protocol, is the most
likely reason, and Aaron separately raised whether 1995 coordinates could relink the two systems.
That path stays parked pending the actual 1995 coordinate file, which has not been supplied, and
pending explicit sign-off, since Aaron recalled FIA pushing back once before when he held plot
identifiers outside their own release. Given the weak join, Aaron chose to fit new modifiers directly
from the FIA-wide record instead of from the Castle file.

**Data build.** The existing form and risk crosswalk in `apply_formrisk_crosswalk.R`, built and
validated in an earlier pass, was reused verbatim rather than rebuilt, since re-deriving it would only invite a
second, needlessly different set of field-call thresholds. It maps TREECLCD, TREEGRCD (falling back to
TREE_GRADE_NCRS where TREEGRCD is missing), CULL_FLD and DAMAGE_AGENT_CD1 through CD3 into an F1/F2
form call and an R1/R2/R3 risk call. Each ME_TREE_GRM_COMPONENT record was matched to its beginning-
of-interval tree row by PREV_TRE_CN and to its plot's remeasurement period by PLT_CN, and the form and
risk crosswalk was applied at that beginning occasion only, so the covariate never uses information
from after the growth or mortality it predicts. The analysis population is every SURVIVOR,
MORTALITY1 or MORTALITY2 record with a beginning DBH at or above the FIA 5.0 inch threshold, which is
12.7 cm, a positive remeasurement period, and a resolved form and risk call, 142,603 rows on 11,246
plots, of which 134,646 are SURVIVOR and 7,957 are MORTALITY1. There are no MORTALITY2 records at all,
so that term of the filter never binds. Crosswalk coverage over the full candidate set on this build
is 83.38 percent for form and 90.46 percent for risk. Non-positive or missing annual diameter growth
on survivors dropped a further 197 rows (0.15 percent) before the growth fit.

Four numbers in the first version of this paragraph were wrong and are corrected above, with the
originals recorded here rather than silently replaced, since both of the 26 August session handoffs
propagated them. The population was given as 134,646 trees on 8,973 plots, which reported the
SURVIVOR subtotal as the whole population and attached a plot count that no candidate definition
reproduces, the correct figure being 11,246. Coverage was given as roughly 98 percent form and 100
percent risk, which are real figures from `apply_cw.out` but computed over a denominator counting only
rows that already carry a call, making the risk figure a tautology rather than a coverage rate. The
diameter threshold was given as 5.0 cm when `DIA` is in inches throughout, so the population actually
begins at 12.7 cm, and this is the one to watch, since the fitted coefficients are unaffected only
because no conversion was ever applied, while anyone reading this write-up to set an engine
coefficient would have carried the error into a metric model. And MORTALITY2 was named as an included
class when the count is zero. All four were re-derived against the committed run's own log (job
13978142) by an independent verification pass on 26 August 2026, recorded in
`2026-08-26_reversal_verification_REVIEW.md` in this directory.

**Physical validity screen.** Mortality rate rises with worse form and risk inside every one of the
nine species pools, from a low near 1 percent (RO, good form, low risk) to highs above 25 percent (AB,
QA and OH, poor form, high risk), with only two minor exceptions confined to cells under 70 trees (QA
form 2 risk 2 versus risk 3, and RO form 1 risk 3 at n=11 with zero deaths), which is sampling noise
rather than a reversed biological relationship. No species shows worse form or risk associated with
materially lower mortality in a well-sampled cell. This is the screen the workspace's own gate design
lesson calls for, since a cross-model consistency check alone cannot see a defect every model shares,
and here there is no second model to compare against, only the observed record checked against a
known biological direction.

**Growth model.** `ANN_DIA_GROWTH ~ SP * form_begin + SP * risk_begin + log(DIA_BEGIN) + (1 | PLT_CN)`,
Gamma family with a log link, glmmTMB, n=134,449, converged, species factor reference level RM. Risk
carries a clear, monotonic, and significant pooled effect, R2 growth is 0.98 percent lower than R1 and
R3 is 1.9 percent lower (both p<0.001, on the log scale so the percentages are exp(estimate)-1). Form's
pooled effect is small and not significant (F2 versus F1, -0.4 percent, p=0.11), but that pools over
real, opposite-signed species effects, five of eight non-reference species carry a significant form
interaction. OH is by far the largest, a 29 percent form-2 growth penalty (p<0.001), PB shows a smaller
penalty (-1.5 percent, p=0.02), and WA, QA and RO instead show a form-2 premium (+2.1 to +6.1 percent,
all p<0.05). SM, YB and AB show no significant form effect. Risk interactions are more widespread still,
six of eight species carry a significant R2 interaction and seven carry a significant R3 interaction,
and they run in both directions relative to the pooled penalty, YB and PB grow measurably slower yet
under high risk (R3 interaction -15.6 and -7.4 percent on top of the pooled -1.9 percent), while WA, QA
and OH show a positive interaction that offsets or reverses the pooled penalty (R3 interaction +8.3,
+6.1 and +9.8 percent). Baseline growth rate differs sharply by species relative to the RM reference,
RO and AB in particular grow 71 and 32 percent faster in raw terms holding form, risk and size fixed,
which is a species effect rather than a form or risk effect and should not be read as one.

**Mortality model.** `MORT ~ SP * form_begin + SP * risk_begin + DIA_BEGIN + offset(log(REMPER)) +
(1 | PLT_CN)`, binomial family with a cloglog link and the remeasurement period entered as an offset
so the fitted rate is an annualized hazard, converged on the full population, same RM reference level.
Both form and risk carry large, and highly significant pooled effects, poor form raises the cloglog-
scale hazard by 0.761 (p<0.001) and high risk (R3) raises it further still by 1.29 (p<0.001) beyond the
already substantial R2 effect of 0.758 (p<0.001), the three largest and most consistent effects in
either model. Species baseline mortality varies enormously against the RM reference, RO and SM carry
significantly lower hazard, PB, AB, QA and OH carry significantly and often far higher hazard, and WA
shows no significant difference from RM. Species interactions dampen or amplify the pooled form and
risk effects unevenly, YB and AB significantly reduce the form penalty for their species (nearly to
zero for YB), AB significantly reduces the R2 penalty while RO significantly amplifies it, and PB and
QA significantly reduce the R3 penalty while SM and YB significantly add to it. None of this reverses
the direction the physical validity screen already established directly from the raw rates, every one
of the nine species pools shows higher mortality at worse form and risk with only two small-sample
exceptions noted above, so the interactions redistribute the size of a real effect rather than its
sign.

**Comparison to the current engine's coverage.** Reading `ddbh_hw_mod` and `tsurv_hw_mod` directly in
`AcadianGY_12.11.r` rather than trusting the tabulated species coefficients alone turned up a
structural fact worth recording. The diameter growth modifier is built as a ratio of a form and risk
cell's predicted increment to that same species' own good-form, low-risk baseline, and every term
shared between numerator and denominator, including the species coefficient and its DBH interaction,
cancels algebraically. The coded growth modifier is therefore identical across the six species it
applies to, RO, SM, YB, RM, PB and QA, and depends only on the collapsed form (A/B) and risk (LR/HR)
classes, exp(-0.0250 x poor form - 0.2176 x high risk), a roughly 2.5 percent form penalty and a 20
percent risk penalty applied uniformly regardless of species. AB and WA get no growth modifier at all,
carrying a value of 1 always, since neither appears in the species gate. The survival modifier does
not have this property, since it is a ratio of two logistic probabilities rather than two exponentials,
so the species intercept and DBH slope do not cancel and survival really is species-specific in the
current engine, for QA, RM, RO, YB and PB. SM has carried no survival modifier since v12.3.2.

The new fit's clearest addition is exactly where the current engine has a documented gap, AB and WA
now have a real, statistically significant, species-specific form and risk effect on both growth and
mortality where the engine currently assumes no effect, and SM now has a mortality effect where none
existed since v12.3.2. The new fit's species-by-form and species-by-risk growth interactions also
directly contradict the current engine's uniform-across-species growth modifier, since OH's 29 percent
form penalty and QA's reversed-sign form premium cannot coexist with one shared modifier curve.

**What this is not.** This is a different basis and a different model form from Castle's, not a
literal head-to-head refit. Castle's modifiers are field-measured Master Stem form and risk classes
fed into a narrow multiplicative adjustment bolted onto an existing Kuehne increment equation and a
separate logistic survival equation. This fit uses the FIA-wide TREECLCD, TREEGRCD, CULL_FLD and
DAMAGE_AGENT_CD crosswalk as the form and risk source and estimates growth and mortality directly and
jointly in one mixed model per response, with a plot random intercept rather than a stand-level ratio
construction. Reporting a percent-effect comparison as though the two frameworks measured the same
quantity would overstate what has been shown. What can be said honestly is that the new fit's
direction (worse form and risk cost growth and raise mortality) agrees with Castle's engine wherever
the engine has a modifier at all, and that it supplies real, checked effects for AB, WA and SM, where
the engine has none.

**Status.** Both models are fit and converged, coefficients and the validity screen are saved to
`results/formrisk_fia/` alongside the build and fit script, and the 52.6 MB tree-level analysis
population stays on Cardinal at `/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/` rather than
entering the repository. Not yet done, translating either model into an engine-ready modifier function
comparable in form to `ddbh_hw_mod` and `tsurv_hw_mod`, and deciding with Aaron whether the joint
species-by-form-by-risk interaction structure should replace the current uniform growth modifier or
supplement it only for AB, WA and SM where no modifier exists today.

**Update, 26 August 2026, the growth half of that decision is settled and the sugar maple survival
half has been reopened.** Aaron scoped the growth question to gap fill only, and engine v13.3 adds
`ddbh_hw_mod_fia()` for American beech and white ash diameter growth alone, leaving every validated
species byte identical to production. On the survival side, a v13.3 sugar maple modifier was
investigated and declined on the stated ground that this analysis population lacks the BAL and plot
basal area fields `tsurv_hw_mod` needs. That premise was correct about the saved 52.6 MB extract and
wrong about the source. Both fields recover at 100.00 percent coverage on all 15,881 sugar maple rows
by returning to `ME_TREE` at the previous plot visit and summing 0.005454 DIA² TPA_UNADJ over the live
trees, independently confirmed on 26 August 2026. A sugar maple survival modifier fit on a form the
data actually supports now lives in `2026-08-26_sm_survival_refit_DRAFT.md` in this directory. It is
deliberately not comparable to `tsurv_hw_mod` and says so at length, so the two must not be read on
one scale. The remaining blockers named in the original refusal, the absent three level NHRI form
field and the absence of a scale conversion, are untouched by this and still stand.

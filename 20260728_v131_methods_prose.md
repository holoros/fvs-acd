# FVS-ACD v13.1 methods prose, drop-in draft

28 July 2026. Continuous prose for the v13.1 methods, written to drop into the benchmark report (Section 3 and
Section 13) and the variant overview GTR (Sections 5, 6 and 10). Supersedes the draft methods prose carried in
Section 4 of `20260723_v131_deliverables_plan.md`, which asserted a whole-plot convergence and a recruitment
convergence that did not survive. House style applied: species names italic with authority at first use, SI units
with true superscripts, prose and paragraphs rather than lists, no em dashes. Bracketed `[[TK:]]` tokens mark the
values that require a landed export.

## 1. Hierarchical mortality

Version 13.1 replaces the v12.11 management-gated attenuation of the self-thinning removal fraction
(`ops$mort.dens.scale`) with a fitted hierarchical mortality model. Where v12.11 damped a fixed self-thinning
curve by a hand-fitted logistic in relative density that was switched on only for managed sources, v13.1
estimates mortality directly as a Bayesian hierarchical hazard and lets that posterior scale the existing
density-frontier self-thinning rather than replace it. The mortality contribution enters as a multiplicative
hazard modifier. The frozen Reineke self-thinning ramp and the SDImax-anchored density plateau are retained
intact, and the fitted hazard multiplies the per-period removal, so the biological self-thinning behavior that
the Bakuzis battery certified in v12.11 is preserved by construction while the level and the source-to-source
structure of mortality become data-driven. Absolute replacement of the self-thinning curve was considered and
rejected in favor of the multiplicative form for exactly this reason. The modifier is scaled to equal unity at
the training-mean covariates, so a projection run with the switch on but without a posterior directory returns
the frozen baseline rather than a silent substitution.

The model is fitted at two grains that complement rather than duplicate each other. The whole-plot fit uses
consecutive remeasurement pairs at stand grain and, for the first time, folds in the Nova Scotia CFI record
(Section 3), yielding the coarse-grain posterior used for stand-level projection. The subplot fit uses 723,830
CONUS FIA subplots with a plot-level random effect that absorbs within-plot correlation, yielding a fine-grain
posterior. The grouping structure at both grains is a nested random-effects hierarchy on region, ecoregion within
region, forest type, and, at subplot grain, plot. The nesting of ecoregion within region rather than free is a
deliberate repair. An earlier free-ecoregion parameterization produced a boundary funnel and a maximum Rhat of
3.81, and re-nesting cured it. The subplot fit converged with a maximum Rhat of 1.015 for the mortality submodel,
a minimum bulk effective sample size of 723, a minimum tail effective sample size of 1,517, zero divergent
transitions, zero maximum-treedepth saturations, and an energy Bayesian fraction of missing information between
0.76 and 0.80. Its variance ladder is informative in itself, with a plot standard deviation of 0.947, forest type
0.411, region 0.241, and region-by-ecoregion 0.232 with a lower 95% bound of 0.205, so the nested term is
identified at subplot grain and the funnel is genuinely cured rather than merely regularized away.

The whole-plot fit required two attempts, and the first one is reported here because its failure mode informs how
the second should be read. The initial NS-inclusive whole-plot refit ran to a 72 h wall without usable production
output. A post-mortem established that it was wall-limited rather than stalled. It saturated a maximum tree depth
of 15 on 86 to 100% of draws while recording zero divergent transitions, so the adapt_delta setting of 0.99 was
buying step-size conservatism the geometry did not require and was paying for it in wall-clock. More consequential
was that the posterior was multimodal. One of four chains settled roughly 27,900 log-units below the other three,
and cross-chain Rhat ran between 1.32 and 3.03, with only 485 usable draws recoverable. Consequently the refit was
resubmitted with six chains at twelve threads each, adapt_delta reduced to 0.92, maximum tree depth reduced to 12,
and a 48 h wall. Six chains rather than four is a diagnostic choice as much as a throughput one, because
multimodality of this magnitude is easier to detect and harder to average away with more chains. Convergence for
the whole-plot posterior of record is reported as
`[[TK: whole-plot maximum Rhat, minimum bulk and tail ESS, divergent transitions, treedepth saturation, and the
per-chain mean log-posterior spread | src: job 12863545 export]]`, and the per-chain log-posterior spread is
reported alongside Rhat rather than in place of it, because a pooled Rhat computed across a stranded chain is not
interpretable.

The fitted density response is worth stating precisely, because it differs in kind from the hand lever it
replaces. The v12.11 gate was a steep logistic that cut the self-thinning removal fraction by roughly 86% across
a narrow band centred on a relative density of 0.38. The fitted hazard is directionally consistent, in that higher
relative density lowers the hazard, but it is far gentler and carries no threshold, falling only about 11% across
relative densities of 0.10 to 0.80. The data therefore support a continuous, modest density effect rather than the
steep hand-tuned attenuation that v12.11 imposed. This result should be read with one caveat: the relative-density
coefficient is marginal net of ln quadratic mean diameter and basal area, which covary with relative density, so
the marginal slope understates any total density effect that the correlated terms also carry.

The practical consequence of that gentleness is that the mortality component alone is close to neutral for
stand-level volume, and the report and the GTR state this rather than leaving a reader to infer a bias correction
that does not occur. Scored against a regenerated baseline on nine benchmark sources, the population-level
subplot-grain hazard moved Maine FIA whole-plot total-volume bias from -16.53% to -16.49%, a change of +0.04
percentage points, against an OSM-ACD v2.26.1 reference of -6.29%. Every scored source moved by less than 0.4
percentage points. The hazard genuinely bites, in that the candidate projection is not identical to the baseline,
but it does not move stand volume at the scale the developing-plot deficit would require. Overall, the
contribution of the hierarchical mortality model to v13.1 is that it retires a hand-tuned management gate on
evidence and replaces it with a defensible fitted effect of the correct sign, and not that it corrects the volume
bias.

The posterior enters the model file behind a gate, so that with the v13.1 switches off the projection reproduces
the shipped 12.10.1 baseline exactly. That contract is verified independently, with a maximum absolute difference
in diameter, height, and expansion factor of 0.000e+00 over a 20-year projection of seeded young and mature
stands, and it was re-verified after the ingrowth hook was changed to its multiplicative form so that the
contract of record postdates every structural change to the hooks.

## 2. Hierarchical recruitment

Version 13.1 replaces the v12.11 flat basal-area-anchored ingrowth multiplier (`ops$ingrowth.mult`, about 2.5)
with a hierarchical recruitment model. The v12.11 multiplier corrected a pooled recruitment deficit with a single
constant and relied on a separate always-on density-release logistic to keep it from over-seeding closed stands.
Version 13.1 estimates recruitment hierarchically, so that the deficit correction, the density dependence, and
the between-region and between-forest-type structure are carried by the fitted posterior instead of by a constant
plus a guard. Recruitment retains its hurdle structure, an occurrence probability and a conditional count, and
both stages draw on the hierarchical estimates. The grouping structure matches the mortality submodel, with
region, ecoregion within region, forest type, and plot at subplot grain, which keeps the two components on a
common hierarchy so that a region deviating in mortality and a region deviating in recruitment are expressed on
the same set of groups. The zero-recruitment fraction on the subplot fitset is 0.9048, which is why the count
stage is fitted as a negative binomial rather than a Poisson.

Like mortality, recruitment enters as a multiplicative modifier rather than as an absolute replacement of the
predicted ingrowth. This was not the original wiring. The hook initially applied the recruitment posterior as an
absolute replacement while mortality applied multiplicatively, and an ingrowth-only preview exposed the
asymmetry: predicted mean ingrowth at the Penobscot Experimental Forest rose from 13 to 186 stems ha⁻¹ yr⁻¹,
roughly fourteenfold, while the sign and magnitude of the effect were inconsistent across sources. Rewiring the
hook to a multiplicative modifier equal to unity at training-mean covariates reduced that preview from 186 to 66
stems ha⁻¹ yr⁻¹ and preserved gate-off byte-identity at 0.000e+00. The remaining discrepancy was not a hook
problem, and Section 2.1 records what it was.

### 2.1 Three generations of the recruitment submodel

The recruitment submodel went through three generations before the version reported here, and the sequence is
documented rather than summarized as a single converged fit, because the fitted coefficients moved materially
between generations and a reader comparing v13.1 against any earlier project memo would otherwise be unable to
reconcile them.

The first generation carried a data assembly defect in the expansion factor. Recruit density was bound to stand
density, with a median of 1,466 trees ha⁻¹, rather than to the per-tree microplot expansion constant of
185.243 ha⁻¹, which over-expanded the response by 18.4 times per tree and 19.2 times globally and put the mean
recruitment rate at 313.7 rather than 16.339 stems ha⁻¹ yr⁻¹. Because stand density scales approximately as the
inverse square of quadratic mean diameter, binding the response to stand density wrote a mechanical term of
roughly minus two times ln quadratic mean diameter into the response itself. The consequence was a spuriously
strong diameter effect. The fitted standardized ln quadratic mean diameter coefficient was -2.368 in that
generation, of which roughly 40% was mechanical, and it fell to -1.245 in a corrected pre-fit preview while the
standardized basal-area coefficient fell from +0.769 to +0.292. Any coefficient from the first generation should
be treated as uninterpretable rather than merely imprecise.

The second generation corrected the expansion constant, passed its assembly sanity gate with a corrected mean of
16.339 stems ha⁻¹ yr⁻¹ and a by-region range of 3.2 to 45.5, and converged. However, it failed the independent
verification against the Penobscot Experimental Forest, predicting a mean ingrowth of 33.60 stems ha⁻¹ yr⁻¹
against an observed base of 13.39 and an acceptance band of 10 to 20. Convergence was therefore not sufficient
evidence that the component was usable, and this is the reason the build order for v13.1 places an explicit
verification gate between a converged recruitment fit and any scorecard that uses it.

The cause of the second generation's failure was a response scale defect rather than an assembly defect. The
response submitted to the negative binomial was the microplot count already multiplied by the expansion constant
of 185.243. Multiplying a count by a large constant before fitting inflates the variance quadratically while
inflating the mean linearly, and the dispersion parameter absorbed the difference, settling at a shape of 0.0559
and a variance-to-mean ratio of about 1,627 at the mean count. Under that dispersion the likelihood is dominated
by relative rather than absolute error, so the fit performed ratio matching rather than mean matching and
overpredicted the population marginal mean by +32.2%. The third generation models the raw microplot count
directly, with log(185.243) folded into the offset so that the expansion is applied on the link scale where it
belongs and the dispersion parameter describes the count process rather than the scaling. Convergence and fixed
effects for the generation of record are reported as
`[[TK: v7 recruitment maximum Rhat, minimum bulk and tail ESS, divergent transitions, and fixed effects with
group standard deviations | src: job 12865188 export]]`, and the verification against the Penobscot Experimental
Forest is reported as `[[TK: v7 predicted mean ingrowth at PEF against the observed 13.39 stems ha⁻¹ yr⁻¹ and the
10 to 20 acceptance band | src: v7 PEF verification run]]`.

Recruitment is gated on the same terms as mortality, so that gate-off reproduces the frozen baseline exactly, and
the recruitment grain draws only on CONUS FIA.

## 3. Nova Scotia inclusion in the fit, and what it does and does not license

The Nova Scotia CFI record, used through v12.11 only as an independent province-scale benchmark, is folded into
the v13.1 whole-plot mortality fit. Nova Scotia is recorded at stand or whole-plot grain with no FIA subplots, so
it enters the whole-plot fit only and the subplot mortality posterior remains CONUS FIA. The whole-plot fitset
grows to 212,768 rows, of which 3,922 are Nova Scotia stands drawn from consecutive remeasurement pairs, roughly
924 of them managed or treated and 2,998 unmanaged. A Nova-Scotia-only recent-decile holdout reserves the most
recent decile, leaving 3,426 Nova Scotia stands in-fit of which 812 are managed. The holdout is Nova-Scotia-only
because the CONUS recent decile is empty by construction in this fitset. Nova Scotia enters under a managed
emphasis and at its native per-stand binomial weight, roughly one-eighth the per-stand weight of an FIA record,
because it carries no FIA population expansion and uses its native expansion factor only. It was not upweighted
unilaterally, and that choice is recorded because it bounds how much of the whole-plot posterior Nova Scotia can
move. Because Nova Scotia carries no ecoregion field it is represented as a single nested bucket, and its forest
type and SDImax are borrowed through a dominant-species-to-FIA-code crosswalk and a forest-type mean SDImax. No
plot coordinates are contained in the fitset, asserted at read, at build, and on re-verification.

The consequence for validation is stated plainly rather than smoothed. In v12.11 Nova Scotia served as a fully
independent province-scale validation, contributing no data to the fit. In v13.1 Nova Scotia is partly in-sample
for the mortality component and can no longer be read as a fully independent test of that component. It remains
independent for every component not refit on it, including the volume and taper system, the height-diameter and
increment relationships, and the recruitment grain, which draws only on CONUS FIA. Where a Nova Scotia benchmark
result is reported for v13.1, its in-sample or out-of-sample status for the component in question is labeled
rather than left implicit.

This inclusion licenses two things and does not license a third. It licenses a whole-plot mortality posterior
that has seen Maritime managed stands, which the CONUS-only fitset could not represent, and it licenses the
regional random effects to carry a Nova Scotia deviation rather than borrowing one from the nearest CONUS region.
It does not license reading a good Nova Scotia benchmark score for v13.1 as evidence of generalization in the way
the same score could be read for v12.11 or for OSM-ACD v2.26.1, neither of which saw any Nova Scotia data. The
reserved recent-decile holdout exists to separate those two readings, and Nova Scotia results for v13.1 are
therefore reported twice, once on the in-fit stands and once on the held-out stands, with the difference between
them treated as the estimate of in-sample optimism.
`[[TK: Nova Scotia in-fit and held-out TOTVOL percent RMSE and bias for base, v12.11, v13.1 and OSM-ACD v2.26.1 |
src: NS-holdout scorecard run]]`. Nova Scotia carries a large share of the total benchmark weight in this
project, and an earlier reconciliation already had to correct a cross-tabulation artifact that counted the same
Nova Scotia stands in up to three determinant cells, so the province's influence on any composite ranking is a
known sensitivity and is now compounded by its partial in-sample status. Overall, the honest statement is that
Nova Scotia improves the fit and weakens the benchmark, and both halves of that statement belong in the record.

One further caveat carries forward from v12.11 and is unaffected by the inclusion. The Nova Scotia site index
basis differs from the Acadian ESI basis used for the Maine, New Brunswick and Quebec sources, so the
transferability argument that Section 11 of the benchmark report makes for Nova Scotia rests on a site variable
that is mapped rather than measured on a common scale. That was a limitation when Nova Scotia was purely a
benchmark, and it is now also a property of part of the fitting data.

## 4. Lever 4 hardwood height on form and risk: the Castle refit

Lever 4 modifies predicted height increment for hardwoods as a function of stem form and stem risk class, through
a multiplier of the form exp(base risk coefficient times high-risk indicator, plus species risk coefficient times
high-risk indicator, plus form coefficient times form-B indicator), clamped to the interval 0.5 to 1.2 and equal
to unity exactly at form A and low risk. Form classes F1, F3, F4 and F7 collapse to form A and the remainder to
form B, and risk classes R1 and R2 collapse to low risk with R3 and R4 collapsing to high risk. The species
coefficients used through v12.11 were not field-fitted. The red oak coefficient in the shipped model was -0.1520,
derived from FIA Growth, Removal and Mortality damage codes on a red oak sample of one, and a value of 0.0220
that circulated in project notes as the red oak placeholder was in fact the yellow birch value, a bookkeeping
error that is corrected here and recorded rather than quietly fixed. An interim refit against FIA Maine field
heights produced 0.0759 on a sample of 10,827 and was staged but never landed.

Version 13.1 refits the hardwood risk coefficients from field data. The source is the Mark Castle cleaned
sawlog-volume dataset (`VOLUME_TREES_CLEAN.csv`), a metric, multi-forest compilation spanning the Holt Research
Forest, the King property, the Penobscot Experimental Forest, the Seven Islands SFMA holdings, and five New
Brunswick installations, in which height, form, risk and diameter are complete for every retained record. Four
hardwoods carry usable samples: northern red oak *Quercus rubra* L. (n = 618), red maple *Acer rubrum* L.
(n = 355), sugar maple *Acer saccharum* Marshall (n = 314), and yellow birch *Betula alleghaniensis* Britton
(n = 199). Per species, log height was regressed on log diameter, a form-B indicator, and a high-risk indicator,
which is the same specification the model convention assumes.

The red oak result reverses the modeled effect. High-risk red oak are not shorter at a given diameter; they are
marginally taller, by 3.9% on the form-adjusted fit (log coefficient +0.0384, standard error 0.0161, p = 0.017,
with the fit reproduced independently in R at +0.0384, p = 0.018). R3 and R4 risk in *Q. rubra* is therefore
associated with stem defect on large dominant stems rather than with height suppression, which is biologically
sensible for a species in which risk assignment is driven by cankers, seams and epicormic development on
well-established dominants. The implied species coefficient relative to the existing paper birch reference is
+0.1764, giving a modifier of about 1.039, so the term applies no height penalty and does not bind the clamp. The
three companion species retain a height deficit at high risk, though a weaker one than the earlier Smith fit
reported: red maple -0.0170 (p = 0.209), sugar maple -0.0490 (p = 0.005), and yellow birch -0.0496 (p = 0.008).
Only sugar maple and yellow birch are statistically distinguishable from zero.

Two limitations bound the term and are carried in the report and the GTR rather than in a footnote. First, the
Castle compilation is merchantable-only, with observed diameters at breast height between 25.4 and 82.0 cm, so
the refitted coefficients are not anchored below about 25 cm and should not be extrapolated to sapling and
pole-sized hardwoods, which is precisely the size class in which a height-risk relationship would be most likely
to differ. Second, paper birch *Betula papyrifera* Marshall is absent from the compilation, so the reference
coefficient of -0.1380 cannot be re-estimated from these data. Consequently the snippet carries two tables. The
primary table differences the Castle species deficits against the FIA-derived paper birch reference, which is
internally inconsistent in that it mixes a field-fitted deficit with a proxy-fitted base. The re-anchor table sets
the base to zero and uses each species' own Castle coefficient directly, which is internally consistent but
applies no risk penalty to any hardwood absent from the Castle compilation. The re-anchor table is wired active
behind the gate in the current model file. The term is staged with its switch default off, so it does not affect
the gate-off contract and does not enter any candidate scorecard until it is landed deliberately.

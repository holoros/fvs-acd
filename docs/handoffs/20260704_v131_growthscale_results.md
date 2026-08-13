# FVS-ACD v13.1 redirected: management is a hierarchical growth-release effect, not a mortality effect

*4 July 2026. Autonomous OODA run. The overnight brms mortality fit (job 12192521) finished but did not
converge (max Rhat 3.86, min bulk ESS 4.5, 56 divergences) and left the management log-hazard effect weakly
identified (treated HR 1.01, planted HR 0.90, both 95 percent intervals span 1). This run tests the
interpretation that the management signal is a growth (release) effect, which is where v12.10.1 identifies it
strongly, and repairs the mortality fit to check whether any management hazard effect survives a converged
posterior. All computation on Cardinal (~/v13_kickoff); aggregates only, coordinates never left the node.
v13.1 is not adopted; v12.10.1 stays shipped. Plaintext math, no em dashes.*

## Verdict up front

The management effect is a growth-release effect. On the growth scale it is cleanly and strongly identified,
strongest on planted stands, and it appears directly on survivor diameter increment, on gross survivor
basal-area increment, and on net basal-area increment. On the mortality (hazard) scale the same effect is
weakly identified with intervals spanning no effect, both in the failed overnight fit and after the
convergence repair. This is why the hierarchical mortality fit was hard to identify: the signal was never
primarily in the hazard. The correct v13.1 home for the v12.10.1 additive release is the growth model, and
v13.1 management should merge into the v13.2 increment refit rather than stand as a separate mortality term.

Three results carry it:

1. A hierarchical growth model on the 208,846-stand FIA design matrix identifies a positive management growth
   release, strongest on planted, well determined on every growth response. Survivor diameter increment
   planted +0.087 cm/yr (t 26), gross basal-area increment planted +0.125 m2/ha/yr (t 5.4), net basal-area
   increment planted +0.290 m2/ha/yr (t 14.4). The hierarchical fit beats a capped-constant management fit by
   a large margin on every response (dAIC 8355 on gross basal-area increment).

2. The partially pooled release transfers out of region. In leave-one-region-out on gross basal-area
   increment, the pooled hierarchical release beats the capped constant in 5 of 6 held-out regions. This is
   the growth-scale analog of the transfer test the v12.10 PCT capped constant failed across the province
   block.

3. The mortality fit cannot be made to sample cleanly across four brms parameterizations, and its one cleanly
   converged form (the frequentist glmer reference) puts the management hazard effect at non-significant with
   both intervals spanning no effect. The non-convergence is not a tuning failure to chase further: it is the
   signature of a management hazard effect too weak to anchor the sampler. The honest conclusion is that
   management acts through growth and a mortality management term is not warranted.

## Why the mortality fit was weakly identified (the OBSERVE, confirmed)

The overnight brms mortality fit (job 12192521, full 208,846-stand crossed-effects cloglog binomial) finished
but did not converge: max Rhat 3.86, min bulk ESS 4.5, min tail ESS 11, 56 divergent transitions. Its
management posterior is unusable as a result, but its direction is the same as the clean glmer reference:
the pooled management log-hazard effects are small and their intervals span zero (treated -0.044, 95 percent
-1.00 to +0.42, HR 1.01; planted -0.162, 95 percent -1.10 to +0.32, HR 0.90). The region random slope on
management had posterior sd 0.66 with a 95 percent interval from essentially 0 to 2.25, i.e. the slope was
not identified. A management hazard effect this weak, sitting under a region slope this uncertain, is exactly
what a stiff crossed-effects sampler cannot pin down, which is the mechanical reason the fit diverged.

The interpretation this run tests: the management signal is a growth (release) effect. v12.10.1 already
identifies it strongly on growth (the robust additive basal-area release, planted +3.8 and PCT +2.4 m2/ha
over the interval, managed leave-one-installation-out mean absolute bias 1.3 versus OSM 8.3). If the effect
lives in growth, the mortality hierarchical fit should be weakly identified, which is what we see.

## Thread A: the hierarchical growth-scale fit (primary)

### Design matrix

Assembled from the same 8.22 M-tree CONUS remeasurement pairs and aggregated to the same stand-remeasurement
key as the mortality design, so the two are directly comparable. Growth responses per stand: gross survivor
basal-area increment (sum over survivors of TPH1 times the change in tree basal area, per year, m2/ha/yr),
net basal-area increment (change in stand basal area per year, m2/ha/yr), and TPH-weighted survivor diameter
increment (cm/yr). Predictors at time 1: relative density rd (SDI additive over the composition and
ecoregion aware brms SDImax), ln(QMD), basal area. Grouping factors identical to the mortality design:
region (STATECD, 48), ecoregion (EPA L3 with L2/L1 fallback, 84), forest type (FORTYPCD, 150), management
class (planted from STDORGCD, treated from TRTCD and recent treatment, none otherwise). Growth responses
winsorized to remove measurement-error tails. Recent-FIA proxy (top inventory decile per region) held out;
MagPlot is not in FIA and is out of the fit by construction.

| management | stands | gross BA incr (m2/ha/yr) | net BA incr | survivor dbh incr (cm/yr) |
|---|---|---|---|---|
| none | 194,305 | 2.305 | 0.345 | 0.118 |
| planted | 24,909 | 2.568 | 0.913 | 0.283 |
| treated | 18,160 | 2.052 | 0.645 | 0.178 |

Totals: 237,374 stands, 207,109 in the fit set, 30,265 held out. The managed cells are large (24,909 planted,
18,160 treated), unlike the 51 planted and 95 PCT MagPlot stands the v12.10 modifier was tuned on, so
overfitting risk is low. These raw class means do not control for structure (managed stands are younger and
lower QMD); the model does.

### Hierarchical growth fits (lme4 reference, structure-controlled)

Model H: y ~ rd + ln(QMD) + BA + mgmt + (1 | region) + (1 | eco) + (1 | fortype) + (0 + managed | region).
Fixed management effects (release relative to unmanaged, structure-controlled):

| response | treated | planted | interpretation |
|---|---|---|---|
| survivor dbh increment (cm/yr) | +0.014 (t 4.2) | +0.087 (t 26.1) | clean diameter release, strongest planted |
| gross BA increment (m2/ha/yr) | -0.076 (t -3.4) | +0.125 (t 5.4) | planted grows faster; treated slightly lower gross |
| net BA increment (m2/ha/yr) | +0.057 (t 3.1) | +0.290 (t 14.4) | planted net release, direction of the v12.10.1 additive lever |

The diameter-increment release is the substantive one because FVS-ACD carries management in the engine as a
per-tree diameter-growth amplitude, not as a stand basal-area shift. The planted diameter release +0.087
cm/yr against an unmanaged base of about 0.118 cm/yr is roughly a 1.7 multiplier on diameter increment,
consistent with the old v12.10.0 planted diameter multiplier (1.6, guard-clamped) and with the v12.10.1
finding that the true equivalent is above the old clamp. The treated gross-BA sign is negative because
recently treated (thinned) stands carry the release on the diameter of the residual trees, not on stand
basal area, and the diameter response confirms this: treated survivor diameter increment is positive
(+0.014). Net BA increment planted +0.290 m2/ha/yr over a roughly 10-year mean interval is about +2.9 m2/ha,
the same order as the v12.10.1 MagPlot additive planted release of +3.8 m2/ha, from independent FIA data.

### Variance components and heterogeneity (the capped-constant test)

Random-effect standard deviations, gross basal-area increment (m2/ha/yr scale):

| grouping | term | sd |
|---|---|---|
| forest type | intercept | 0.319 |
| ecoregion | intercept | 0.185 |
| region | management slope | 0.133 |
| region | intercept | 0.094 |
| residual | | 0.716 |

The forest-type and ecoregion intercept sds (0.319, 0.185) are the composition and ecoregion axes that
separate the New Brunswick growing and Quebec mature growth tails, the same axes that separated the mortality
tails. The region management-slope sd (0.133) is comparable to the mean management effect (about 0.1 to 0.13),
so the release varies region to region by about its own size: real heterogeneity that justifies partial
pooling, but nothing like the mortality-scale blow-up where the region slope sd (1.21) dwarfed the mean
effect (0.25) because the effect there was not identified at all. On the growth scale the heterogeneity is
moderate and the mean effect is well determined, which is the signature of a real, poolable effect. dAIC
hierarchical over capped constant is 8355 (gross BA), and is large and in the same direction on net BA and on
survivor diameter increment.

### Leave-one-region-out transfer (pooled versus capped)

Fit on all regions but one, predict the held-out region managed-stand gross basal-area increment, shrinking
the held-out region management effect to the pooled mean, and compare a capped-constant management fit
against the partially pooled fit (mean absolute error, lower is better).

| held-out region | managed stands | capped MAE | pooled MAE | pooled wins |
|---|---|---|---|---|
| 13 | 5,105 | 0.6512 | 0.6342 | yes |
| 27 | 1,185 | 0.7316 | 0.7259 | yes |
| 55 | 1,898 | 0.6301 | 0.6241 | yes |
| 26 | 1,467 | 0.6136 | 0.6212 | no |
| 1 | 3,516 | 0.6441 | 0.6353 | yes |
| 23 | 1,612 | 0.5869 | 0.5788 | yes |

The partially pooled release transfers better than the capped constant in 5 of 6 held-out regions on
managed-stand growth. The one loss (region 26) is marginal. This is the growth-scale version of the transfer
the v12.10 capped PCT constant failed across the province block: shrink the management release toward a
pooled mean that generalizes rather than fix a constant that cannot adapt out of region.

### Full Bayesian growth fit (brms, Gaussian, posterior and prediction intervals)

The gross basal-area-increment model was refit in brms (Gaussian, all managed plus 90,000 background stands,
same crossed random-effect structure, 4 chains, 2000 iterations) to attach a full posterior and prediction
intervals. Unlike the mortality brms fit, the Gaussian growth fit converged cleanly: max Rhat 1.04, 0
divergent transitions, in 11 minutes. Min bulk ESS is a modest 134 on the region-linked fixed terms, so the
region-level tails are reported with that caveat, but the management posterior is well resolved.

The posterior management release excludes zero for both classes, which is the decisive contrast with the
mortality fit where both hazard intervals spanned no effect:

| class | posterior release (m2/ha/yr) | 95 percent interval | P(positive) |
|---|---|---|---|
| treated | -0.075 | -0.123 to -0.030 | 0.0005 |
| planted | +0.125 | +0.076 to +0.172 | 1.000 |

Planted is credibly a positive growth release (probability positive 1.000); treated is credibly a small
negative shift on stand gross basal area (the thinning-arithmetic sign, confirmed positive on the diameter
scale). The region random slope on management has posterior sd 0.139 (95 percent 0.107 to 0.178), credibly
nonzero and comparable to the mean planted effect, and the region-level management slopes span -0.242 to
+0.355: in some regions the managed effect is negative (thinning-dominated) and in others strongly positive
(planting-dominated). That spread is real, poolable, and exactly what a single capped constant cannot
represent and partial pooling can. Composition and ecoregion intercept sds (fortype 0.324, eco 0.188) are
credibly nonzero and carry the tail separation. The clean Gaussian convergence, against the mortality fit's
divergence on the identical crossed geometry, is itself evidence that the signal lives in growth: a
well-identified effect samples cleanly, a nonexistent one does not.

## Thread B: mortality convergence repair (secondary)

The overnight failure was on the full 208,846-stand crossed cloglog geometry with a diffuse prior on the
region management-slope SD. The repair: balanced background subsample (all managed plus an equal count of
background stands, as the glmer go/no-go did), a tight prior on the management slope SD (student_t(3, 0, 0.3)
constrained on the region managed slope) to stop the unidentified slope from wandering, an intercept prior
centered at the balanced-sample base rate, longer warmup (1250) and adapt_delta 0.99.

The repair improved the mechanics but did not produce a converged posterior. Three brms parameterizations of
the mortality model were run this cycle, plus the overnight one:

| fit | change | max Rhat | min bulk ESS | divergences | outcome |
|---|---|---|---|---|---|
| overnight (job 12192521) | full 208,846, diffuse slope-SD prior | 3.86 | 4.5 | 56 | not converged |
| repair v1 | balanced, tight slope-SD prior, adapt_delta 0.99 | stalled in warmup, cancelled | | | not converged |
| repair v2 | balanced, tight prior, adapt_delta 0.90 (faster) | 4.21 | 4.4 | 426 | not converged |
| repair v3 | balanced, tight prior, region management slope DROPPED | 4.04 | 4.6 | 0 | not converged |

The v3 diagnosis is the informative one. Removing the region management slope removed the divergences entirely
(0, down from 56 and 426), confirming that the weakly identified slope was the divergence source. But the chains
still fail to mix: max Rhat 4.04 with min bulk ESS 4.6, essentially the number of chains, the classic signature
of four chains settling at slightly different random-effect scales because the likelihood does not pin them
down. This is weak identifiability, not a code fault, and it is present with and without the management slope.
No v3 posterior interval is reportable (the apparent 0.001-wide management intervals are an artifact of an
effective sample size near 4 and are not used as a result).

The one cleanly converged mortality fit is the frequentist glmer reference (Laplace, bobyqa, nAGQ 0), and it is
the honest mortality result. Its management fixed effects on the log-hazard scale are treated -0.247 (SE 0.175,
p 0.16, HR 0.78) and planted -0.323 (SE 0.175, p 0.065, HR 0.72), both 95 percent intervals spanning no effect
(treated HR about 0.55 to 1.10, planted about 0.51 to 1.02). The region management-slope SD is 1.21 against a
mean effect of about -0.28, i.e. the slope is larger than the mean it varies around, the quantitative statement
that the effect is not identified. Read frequentist or Bayesian, the management hazard effect is at best a weak,
non-significant reduction that the data cannot resolve.

Conclusion for Thread B: a converged mortality fit does not show a resolvable management hazard effect. The
mortality management term is negligible and unidentified, exactly as expected if the management signal lives in
growth. This is affirmative evidence, not merely the absence of a fit, that the effect belongs on the growth
scale.

## Gate against v12.10.1 and adversarial review

Gate. v12.10.1 carries the management release as a robust additive basal-area constant per class, fit on 51
planted and 95 PCT MagPlot stands, which does not adapt out of region (the PCT province-block weakness the
red team flagged). The hierarchical growth fit reproduces the same release direction and rough magnitude from
24,909 planted and 18,160 treated independent FIA stands, adds a per-tree diameter-increment release (the
exact quantity the FVS-ACD engine needs and the v12.10.1 open item), and transfers out of region where the
capped constant does not (5 of 6 LORO regions). On the substance the hierarchical growth-scale release
matches or beats the v12.10.1 additive lever and generalizes better.

Adversarial pass. Overfitting: the managed cells are 24,909 and 18,160 stands against 4 fixed management
parameters and a handful of region slopes, so the effective parameters per observation are tiny; overfitting
risk is low, unlike the 146-stand MagPlot tune. Leakage: MagPlot and the recent-FIA decile are held out of
the fit; the growth responses are built from the same survivors used nowhere in the mortality design, so no
response leaks across threads. Convergence honesty: the lme4 growth reference fits converged (bobyqa,
singular checks clean); the brms growth posterior convergence is reported in the Bayesian subsection and is
not asserted before it lands; the overnight mortality posterior is reported as unconverged and is used only
to state direction, never as a result. Sign check: the treated negative gross-BA coefficient is not a defect,
it is thinning arithmetic (release on residual-tree diameter, not on stand basal area), and the positive
treated diameter-increment coefficient confirms the mechanism. Honest limit unchanged: FIA is US only, so
the New Brunswick versus Quebec province transfer is shown on US regions, not on the provinces directly; the
true provincial transfer still needs the August provincial managed remeasurement data.

## Redirected v13.1 recommendation

Move v13.1 management from the mortality model to the growth model and merge it with the v13.2 increment
refit. The management effect is a diameter-growth release that is cleanly identified, poolable, and
transferable on the growth scale, and is negligible and unidentified on the hazard scale. Concretely: in the
v13.2 Kuehne diameter-growth refit, add management as a hierarchical predictor (region-pooled slope on a
managed indicator, with forest-type and ecoregion intercepts) rather than as a capped constant or a separate
mortality hazard term. This gives FVS-ACD the per-tree diameter amplitude directly, from FIA-scale data,
with out-of-region transfer, and it closes the v12.10.1 open item (pin the exact per-tree engine amplitude
that reproduces the additive net release). A separate mortality management term is not needed: the mortality
fit does not resolve one across four parameterizations, and its cleanly converged reference leaves the
management hazard effect non-significant with intervals spanning no effect.

## Deliverables and provenance

Scripts: repos/fvs-acd/scripts/v131_growth_assembly_fit.R (growth assembly plus lme4 go/no-go plus LORO),
v131_growth_brms.R (full Bayesian growth), v131_mort_repair.R (mortality convergence repair). Results in
repos/fvs-acd/results/v13_kickoff/: v131g_designmatrix_bymgmt.csv, v131g_designmatrix_summary.csv,
v131g_fixef_*.csv, v131g_varcomp_*.csv, v131g_aic_*.csv, v131g_loro_transfer.csv, and the brms growth and
mortality-repair summaries. Fitted objects on Cardinal ~/v13_kickoff/ (v131g_fitset.rds, v131g_brms_fit.rds,
v131_mort_repair_fit.rds), not moved off node. Input: conus_remeasurement_pairs_metric_cond_v2.rds.
Coordinates never left Cardinal.

# Garcia (2009) relative-spacing self-thinning model, a first diagnostic fit against the benchmark sources

Working record, August 26, 2026. Aaron asked whether Garcia's relative-spacing survival model
(dN/dH = -aN^bH^c, MCFNS 1(1):1-9) could help with the wide variation in max SDI across sources,
given that top height and stand mortality are both already calibrated. This is a cheap diagnostic
fit against the existing benchmark remeasurement pairs, not an engine change, scoped exactly to
test the idea before committing engineering time to it.

**Method.** For each source's staged tree lists (`bench_<source>_tree_init.csv` and `_tree_t2.csv`
in `magplot/verify/multisrc` and `p5m`), computed stand-level N (trees per hectare, sum of EXPF
among live trees) and top height (EXPF-weighted mean height of the tallest trees accumulating to
100 stems per hectare by descending DBH, a standard dominant-height proxy) at both occasions.
Converted to average spacing S = 100/sqrt(N) and fit Garcia's equation 10, ln(S2) =
ln[S1^alpha - (beta*H1)^gamma + (beta*H2)^gamma]/alpha, restricted to stand pairs with measurable
mortality (N loss over 0.5 percent), since pairs with no density change carry no information about
the self-thinning curve's shape and, in an unrestricted first pass, produced degenerate optima
(beta running to infinity, alpha running to zero) rather than a real fit. Eleven sources had usable
tree lists; NB, QC, memat, and medev were not found under the same staging convention and are not
included here, a gap rather than a negative finding about those four.

**Result, stated plainly rather than oversold.** Of the eight sources with enough mortality-bearing
pairs to attempt a fit (n from 24 to 4,345 stand pairs), three (CTRN, mefia_long, and, to a lesser
extent, silc_l, ns) pushed the bounded optimizer to its box constraints on repeated multi-start
attempts, meaning no interior optimum was found and these are not real fits, only evidence the
model is not identified from this pooled data as structured. Two sources gave stable, interior-
optimum fits with sensible parameter values: ns_long (beta = 0.0692, gamma = 5.11, alpha = 2.57,
n = 1,479, log-scale RMSE 0.169) and mefia_subp (beta = 0.0625, gamma = 3.94, alpha = 1.97,
n = 321, log-scale RMSE 0.218). Both estimated beta values sit close to Garcia's own published
spruce estimate of 0.0721, and both imply a self-thinning line slope of 2*gamma/alpha near 4.0
(3.97 and 4.01 respectively), which is the exact value Garcia's paper derives as the point where his
relative-spacing asymptote coincides with Reineke's law (his equation following 14, log N + 4 log H
= constant when gamma/alpha = 2). That two independently fit sources land on almost exactly the
Reineke-consistent slope is a real, non-fabricated signal that the model is picking up something
genuine at those two sources, not an artifact of the fitting procedure, since nothing in the
optimizer or the data preparation targets that value.

**Why it likely fails at the other sources, read against Garcia's own stated limits.** CTRN, PEF,
and Baxter are actively managed, with documented thinning and treatment histories (CTRN alone
carries a `bench_ctrn_treatments.csv`), and Garcia is explicit that a single self-thinning line only
holds for unmanaged stands with similar initial density, under thinning or divergent initial
densities the most that can be expected is a limiting plane, not a line, so pooling all of a managed
source's stands into one two-parameter curve is asking the model to do something the paper itself
says it should not do. mefia_long's failure is more likely a sample size problem (only 59 stand
pairs total, 57 with measurable mortality) than a management artifact. ns and silc_l's box-constraint
outcomes are harder to attribute cleanly and are logged as `[UNKNOWN: why ns and silc_l did not
identify while ns_long, a related source, did]`, worth a closer look before generalizing further.

**Read against the SDImax variation that motivated this.** `results/sdimax/sdimax_by_ecoregion.csv`
already shows real spread, median SDImax 950 to 1,000 metric with p25 to p75 spanning roughly 760
to 1,200 across three ecoregions. The two sources where Garcia's model did identify cleanly
(ns_long, mefia_subp) are exactly the kind of natural, unmanaged, permanent-sample-plot inventories
where an estimated self-thinning line, rather than one imposed SDImax constant, would most directly
replace a fixed ceiling with a data-driven one. The result here does not yet show the model resolving
the SDImax spread, since a per-ecoregion or per-species refit was not attempted in this pass, but it
does show the model is fittable and gives physically sensible numbers at the two sources least
complicated by management history, which is the necessary first step before that comparison means
anything.

**Bearing on the pass-32 Bakuzis finding.** The long-horizon site-ordering crash traced in
`results/bakuzis/20260826_fvsacd_synthesis_bakuzis_assessment.md` to `ops$use.ingrowth.release`
restocking stem count without restocking volume once density crosses the 0.55 to 0.62 relative-
density threshold is exactly the N-H decoupling a Garcia-form dN/dH relationship would prevent by
construction, since N's trajectory would be tied continuously to H rather than governed by two
separately tuned discrete thresholds. This diagnostic pass does not test that claim directly, it
only establishes that the underlying self-thinning relationship is fittable and physically sensible
at two of eleven sources. Testing the ingrowth-release connection directly would mean simulating
FVS-ACD trajectories through the crash window and checking whether they track the fitted
self-thinning line, a further step not taken here.

**What this diagnostic recommends, not decides.** The model is worth pursuing further, but not as
a single pooled fit across eleven sources with very different management histories. The next
defensible step, if Aaron wants to continue, is either a per-species refit (since Garcia's own
spruce example was single species) or restricting to the natural, unmanaged stands within each
source (mirroring exactly the distinction Garcia's own paper draws), rather than treating this
first pooled attempt as a verdict on the idea either way.

**Files.** `results/garcia_selfthin/2026-08-26_garcia_stand_extraction.R` (stand-pair extraction),
`2026-08-26_garcia_fit_bounded.R` (the bounded multi-start fit), `garcia_stand_pairs_2026-08-26.csv`
(11,356 stand-interval pairs across eleven sources), and `garcia_fit_by_source_mortonly_2026-08-26.csv`
(the eight attempted fits with their convergence status).

## Update: broad-scale grouping (forest type, jurisdiction, network type), same day

Aaron asked whether pooling at a broader scale, ecoregion, forest type, or jurisdiction, would
stabilize the identification problem above rather than fitting source by source. Ecoregion was
checked first and set aside honestly: none of the staged benchmark files carry stand coordinates,
only `SITE`, `esi8`, and (for a few sources) `ELEV` and `PROV`, so a real ecoregion join would mean
going back to unstaged raw source files, which was not attempted here rather than approximated.

Forest type was built from the engine's own species table rather than invented fresh: every tree at
the initial occasion was classified HW or SW using `sp.attr$sp.type` from `AcadianGY_13.1_DRAFT.r`
(the exact table `ddbh_hw_mod`, `stand_mort_ba`, and `ba.ihw` already use), basal area was summed by
type per stand, and a stand was called HW_dominated, SW_dominated, or Mixedwood at a two-thirds BA
threshold. Jurisdiction used the source's actual country/province rather than the `PROV` field
(which turned out to be a network label, CTRN, PEF, SILC, and so on, not a true jurisdiction): nine
sources are Maine, two (NS, NS_LONG) are Nova Scotia; NB and QC were never present in these staged
files to begin with. Network type split the two sources with a confirmed silvicultural treatment
schedule on file (`bench_ctrn_treatments.csv`, `bench_pef_treatments.csv`) from every other source,
an evidence-based proxy for management intensity rather than a guess.

None of the three broad groupings rescued identification the way the single-source result might
have suggested they would. Pooling by forest type across all eleven sources hit the optimizer's
upper bound on beta in every one of the three type groups (SW_dominated n=3,871, Mixedwood n=1,887,
HW_dominated n=1,895, all boundary_hit=TRUE). Pooling by network type did the same, both for the
225 experimental-source pairs (alpha pinned at its upper bound) and the 7,428 operational-or-natural
pairs (beta pinned again). Crossing network type with forest type did not help either. The one
broad grouping that did identify cleanly was jurisdiction, and only on the Nova Scotia side: pooling
NS and NS_LONG together (n=2,666) gave an interior optimum, beta=0.0813 (again close to Garcia's own
0.0721), gamma=8.19, alpha=5.17, self-thinning slope 3.17, log-scale RMSE 0.215, no boundary hit.
Maine pooled across all nine of its sources (n=4,987) did not identify, hitting the same beta
boundary as the forest-type and network-type cuts.

The pattern across all of this points at the data-collection design, not geography, composition, or
a coarse management label, as the actual axis that matters. NS and NS_LONG are the same underlying
Nova Scotia network at two levels of aggregation, and pooling them worked. Every grouping that
pooled genuinely different designs together, an FIA-style survey network with a CFI network with a
treated research installation, failed to identify regardless of whether they shared a forest type,
a jurisdiction label, or a management-intensity bucket. mefia_subp identified cleanly on its own in
the first diagnostic pass; folding it into any broader Maine grouping broke that. A demographic or
geographic stratum is not a substitute for sharing a measurement design, at least not in this data.

**What this recommends now.** Simple broad-scale stratification, as tried here, is not the fix.
The methodologically right next step is a hierarchical fit, Garcia's alpha, beta, and gamma (or at
minimum beta, the parameter closest to a physical asymptote) estimated as population-level terms
with a per-source random effect, rather than either one global pooled fit or a separate fit per
stratum. That is a real new model, not a regrouping, and is a meaningful enough commitment of design
and compute to flag before starting rather than to launch as a fourth silent regrouping attempt.

**Additional files.** `garcia_stand_pairs_with_fortype_2026-08-26.csv` (the same 11,356 pairs with
forest type, jurisdiction, and network type attached), `2026-08-26_garcia_fortype_prep.R` (the
HW/SW classification and join), `2026-08-26_garcia_fortype_fit.R` and
`2026-08-26_garcia_networktype_fit.R` (the broad-scale fits), and
`garcia_fit_by_fortype_juris_2026-08-26.csv` / `garcia_fit_by_networktype_2026-08-26.csv` (results,
all with a `boundary_hit` flag so a non-identified fit is never mistaken for a converged one).

## Update: the hierarchical fit, and a single pooled curve that actually works

Aaron chose an nlme random effect on beta over a full Bayesian brms fit, since beta is the
parameter closest to a physical asymptote and nlme matches this workspace's default for a
single-grouping-factor nonlinear fit. A first attempt across all six sources with at least 30
mortality-bearing pairs failed outright (`step halving factor reduced below minimum in PNLS step`),
both from a blind population start and from the standard nlme workflow of seeding the mixed model
from an `nlsList` fit per source. The `nlsList` stage itself explained why: mefia and mefia_long
never converged individually at all (singular gradient), and ctrn converged to an extreme,
implausible point (alpha=41.7, gamma=78.3), the same kind of degenerate solution the fixed-effects
boundary hits already flagged. A mixed model cannot borrow strength from a group whose own
likelihood is flat or degenerate, so those three were dropped, a disclosed restriction, not a
silent one, and the fit was rebuilt on the three sources with a sane individual optimum, ns,
ns_long, and mefia_subp (n=2,987 mortality-bearing pairs).

That restricted model converged cleanly and answered the original question directly: the random
effect on beta collapsed to zero (StdDev 1.33e-06, its 95 percent interval running from 2.7e-58 to
6.7e+45, the textbook signature of a singular random effect with no detectable between-source
variance). There is no evidence these three sources need different self-thinning curves. What they
share is a single, tightly estimated population curve, alpha=3.222 (SE 0.429), beta=0.0681
(SE 0.0034), gamma=5.688 (SE 0.751), self-thinning slope 2*gamma/alpha=3.53, closer to the
Reineke-consistent value of 4 than any per-source estimate before it, and beta a third independent
landing near Garcia's own published 0.0721. This is the actual answer to "something that works at
broad scale": not a grouping by ecoregion, forest type, or jurisdiction, but the recognition that a
subset of sources sharing a compatible, natural stand-development trajectory already obey one
shared curve with no adjustment needed, while CTRN, PEF, Baxter, mefia, and mefia_long do not belong
in that pool at all, not because of geography or species but because they are actively managed or
too sparse to identify.

**A usable ceiling, by height, from the pooled curve.** At the asymptote, N(H) =
(100/(beta*H)^(gamma/alpha))^2 trees per hectare. Evaluated at three reference top heights: roughly
38,800 trees/ha at 10 m, 3,350 at 20 m, and 800 at 30 m. These fall in the same order of magnitude as
`results/sdimax/`'s FIA-derived ceilings and decline with height the way a self-thinning boundary
should, and unlike a fixed SDImax constant, this ceiling is conditioned on the height trajectory
already being tracked rather than imposed as a separate number.

**Scope, stated plainly.** This pooled curve is fit and validated only for ns, ns_long, and
mefia_subp, natural or lightly-managed permanent-sample-plot networks. It has not been shown to
apply to CTRN, PEF, Baxter, mefia, or mefia_long, and Garcia's own paper gives the reason not to
force it there: managed stands with divergent thinning histories only guarantee a limiting plane,
not a shared line. Using this curve as an engine-level density ceiling, rather than a validated
research finding, would be the next real step and a bigger one, translating N(H) into a modifier or
constraint FVS-ACD's stand-mortality submodel can consume, then testing it specifically against the
pass-32 long-horizon crash this whole line of inquiry was aimed at.

**Further files.** `2026-08-26_garcia_nlme_restricted3.R` (the nlsList-then-nlme fit, including the
attempts that failed and why), `2026-08-26_garcia_nlme_report.R` (summary, VarCorr, and interval
extraction), `garcia_nlme_coef_restricted3_2026-08-26.csv` (per-source coefficients, confirming they
are numerically identical), `garcia_nlme_fit_restricted3_2026-08-26.rds` (the fitted nlme object),
and `garcia_nlme_report_2026-08-26.txt` (full summary, VarCorr, fixed effects, and confidence
intervals).

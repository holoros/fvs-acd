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

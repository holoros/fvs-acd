# v13.1 crown-ratio recession recalibration: scoping plan

Planning only, no fitting, no jobs submitted. Prepared 2026-07-22. Builds on the
2026-07-21 crown-ratio investigation (`20260721_crown_ratio_investigation.md`), which
established that crown-ratio dynamics are already on, unconditional, and literature
based, so the queued task is a coefficient recalibration and not a mechanism change.
Model file inspected read-only: `repos/fvs-acd/scripts/AcadianGY_12.11.r` (byte
identical to the Cardinal copy `~/_scripts/AcadianGY_12.11.r`; the `dhcb` grep matches
line for line).

## 1. Current crown-recession model and coefficients

Crown recession is the annual change in height to crown base, `dhcb`, from Russell,
Weiskittel and Kershaw (2014, Eur J For Res 133:1121-1135). The function
(`AcadianGY_12.11.r` lines 1691-1710) is:

```r
dhcb = function(dht, dbh, ht, hcb, ccf, shade) {
  b1 = 4.000
  b2 = -0.8395
  b3 = -0.2196
  b4 = -0.3059
  b5 = -0.00553
  b6 = 0.09821
  cl = ht - hcb
  cr = cl / ht
  dhcb = (cl + dht) / (1 + exp(b1 + b2 * log(cr + 0.01) + b3 * log(ccf + 1) +
                                 b4 * log(1.01 - cr) + b5 * (shade^2) + b6 * log(shade * cr)))
  dhcb
}
```

The six coefficients are fixed constants baked into source. There are no
species-specific terms (shade tolerance, from the species trait table at line 238, is
the only taxon covariate), no region term, and no `ops$` gate. The only post-hoc
adjustment is `dhcb_thin_mod` (BF/RS post-commercial-thinning scalar, lines 1721-1752),
applied inside the wrapper `calc_dhcb` (lines 1765-1810), which otherwise just joins
plot CCF and evaluates `dhcb` once per tree per year.

## 2. How crown ratio flows into ddbh and dht

Crown ratio is a state variable carried on the tree list and refreshed at the end of
every one-year cycle. The order inside `AcadianGYOneStand` (lines 3740-3776) is
`calc_ddbh` then `calc_dht` then `calc_dhcb` then the output mutate.

Diameter increment, `ddbh` (lines 850-870, Kuehne log-log form), takes `cr` as
`(b3 + ddbh.b3.spp) * log(cr)`, base `b3 = 0.713456`. This is a strong positive
elasticity on the log scale: higher crown ratio means faster diameter growth. Call
site line 1133, `ddbh(dbh, cr, bal.sw, bal.hw, csi, ...)`.

Height increment, `dht` (lines 1405-1418, Kuehne form), takes `cr` linearly as
`b3 * cr`, base `b3 = 0.394837`. Positive: a longer live crown drives more height
growth. Call site line 1586, `dht(ht, cr, ccfl, csi, ...)`.

Both increments use the crown ratio that entered the cycle. After the increments are
computed, `calc_dhcb` returns `dhcb`, and the output block (lines 3768-3776) writes the
new state and recomputes crown ratio:

```r
tree = tree %>% mutate(year = year+1, dbh = dbh + coalesce(ddbh,0),
                        ht = ht + coalesce(dht,0), hcb = hcb + coalesce(dhcb,0),
                        expf = ..., cr = 1 - (hcb/ht))
```

So recession sets next year's crown ratio, which in turn sets next year's `ddbh` and
`dht`. Recalibrating `dhcb` therefore does not touch the increment equations directly;
it shifts the crown-ratio trajectory, and the increment response propagates through the
0.713 (diameter) and 0.395 (height) crown-ratio coefficients on the following cycle.
This is exactly the common-cause pathway the investigation flagged: if recession is too
slow in young high-CCF stands, crown ratio stays too high, and both increments run hot
in a way that a stand-level density correction cannot fully absorb.

Note (from the investigation, unchanged here): crown ratio has no direct term in the
baseline survival function (`tree_surv_prob`, dbh only); it reaches mortality only via
the gated spruce-budworm modifier. A recession refit will move growth, not survivor
count, in the non-outbreak case.

## 3. What a refit needs: response and predictors

The 2014 model is a nonlinear crown-base-rise equation. Response is `dhcb`, the annual
rise in height to crown base, bounded by available crown length so crown base cannot
overtake the tree top. Predictors as coded: current crown length `cl = ht - hcb`,
predicted height increment `dht`, current crown ratio `cr` (entering three ways: as
`log(cr + 0.01)`, `log(1.01 - cr)`, and `log(shade * cr)`), crown competition factor
`ccf`, and species shade tolerance `shade`. To recalibrate weighted to young high-CCF
developing stands we would refit the same six-coefficient structure (optionally adding a
young-stand or high-CCF interaction) rather than change the functional form, so the
result drops in as a coefficient swap.

The observable needed per remeasurement interval is crown base at two times, i.e. crown
ratio at two times, plus contemporaneous CCF and the realized (or predicted) height
increment. Crown ratio is not measured directly in the field; it is derived from
compacted live crown ratio, and height to crown base is then `hcb = ht * (1 - cr)`.

## 4. Where the data plausibly lives (Cardinal, read-only inspection done)

The v13 kickoff fit sets do NOT carry the tree-level crown data this refit needs. Both
`~/v13_kickoff/v131_fitset.rds` (208,846 rows, 28 cols) and
`~/v13_kickoff/v131g_fitset.rds` (207,109 rows, 32 cols) are stand-level panels: ba,
qmd, rd, sdimax, deaths, trials, survival counts, YEARS. Grepping their columns for
cr, hcb, crown, ccf, shade returns nothing. These were built for the density, mortality
and SDImax work and have no individual-tree crown ratio, no height to crown base, and no
CCF. So the crown-recession refit data has to be built fresh, not pulled from the
current kickoff sets.

The usable sources already on Cardinal:

- FIA tree tables `~/fia_data/ME_TREE.csv` (1,030,867 rows), plus NH and VT equivalents.
  These carry `CR` (compacted live crown ratio, col 22), `CCLCD` (crown class), `HT`,
  `ACTUALHT`, `PREV_TRE_CN` and `TRE_CN`. Remeasured crown-ratio pairs are buildable by
  self-joining `TRE_CN` to `PREV_TRE_CN` across panels, giving CR at both visits and
  hence observed HCB change. This is the CONUS/FIA remeasurement pathway and is the
  natural fit set for a recession model weighted toward Maine and Acadian conditions.
- `~/lever4_hw_height_grm.rds` (148,339 rows), the tree-level ME GRM remeasurement pair
  set already assembled for the Lever 4 height modifier. It already carries `CR`,
  `CCLCD`, `dbh_begin_cm`, `DIA_BEGIN`/`DIA_END`, `HT`/`HT.begin`, `PLT_CN`,
  `PREV_TRE_CN`, `ANN_HT_GROWTH`. It currently stores CR only at the end visit, but it
  is the fastest starting point: extend the same join to bring CR at the begin visit
  and it becomes a crown-recession fit set with the remeasurement plumbing already
  solved.
- `~/fvs-modern/config/greg_crown_change_coefficients.csv`, a by-SPCD national-FVS-style
  crown-change coefficient table (SPCD, n, b0, b1, b2). Different functional form from
  the Acadian `dhcb`, but a useful external reference and a source of per-species sample
  sizes to sanity-check which species can support their own recession terms.

CCF is not present in any of these and is not stored anywhere as a column, but it is
derivable: the model already contains the Russell and Weiskittel (2011) maximum crown
width equations (lines 329, 351) used to compute CCF inside projection, so CCF at each
remeasurement can be reconstructed from the plot tree list at that visit.

## 5. Weighting scheme

The target is young, high-CCF developing-end stands, the regime where FVS-ACD
under-predicts. Two workable options, recommended first:

1. Case weights on a young-and-dense index. Weight each remeasurement interval by a
   function that rises with CCF and falls with stand age or QMD, for example a weight
   proportional to CCF within young or low-QMD strata and tapering to a small floor for
   old open stands, so the six coefficients are pulled toward the developing end without
   discarding the mature data that anchors the asymptote. Keep every record, downweight
   rather than drop, to preserve the shade-tolerance and open-stand behavior.
2. Stratified subsample or hard filter to young high-CCF stands (for example stand age
   below a threshold and CCF above a threshold), fit there, and validate that the
   mature-stand recession is not degraded. Simpler and more transparent, but throws away
   information and risks a discontinuity at the stratum edge.

Either way, define young and high-CCF from stand-level joins (age or years since
disturbance, QMD, CCF) attached to each tree interval, and report the effective sample
size in the developing stratum so the refit is not driven by a handful of plots.

## 6. Fitting approach

R first. The equation is nonlinear in the six coefficients with a crown-length
multiplier and a logistic denominator, so weighted nonlinear least squares (`nls` with
the `weights` argument, port algorithm for bounds) is the direct analog of the original
2014 fit and the least surprising choice for a drop-in coefficient swap. If species or
region random effects on the recession rate are wanted, escalate to `nlme::nlme` (or
`brms` for a Bayesian version consistent with the rest of the v13 hierarchical stack),
with the species intercept the obvious grouping factor given the shade-tolerance
structure already in the form. Recommend starting with weighted `nls` reproducing the
2014 structure, confirming it recovers something close to the published coefficients on
the full sample, then re-fitting with the developing-end weights and comparing predicted
recession trajectories against the observed CR decline in young high-CCF plots. Deliver
as a gated coefficient set (`ops$use.hcb.refit` defaulting to the current 2014 values)
so gate-off parity is preserved, matching the Lever 1-4 pattern. Fitting itself runs on
Cardinal (R 4.5.2), not in the sandbox.

## 7. Open risks

- Crown ratio is not observed directly. The response is derived from FIA compacted crown
  ratio, an ocular, coarsely binned, gap-filled field estimate. HCB change over a
  5 to 10 year interval is a small signal riding on a noisy, compacted estimate, and
  compaction biases crown ratio upward relative to true live-crown ratio. This is the
  single biggest risk: the recession signal may be near the measurement noise floor,
  especially for the small young trees at the developing end. Mitigations: pool across
  the three-state northern FIA, screen on crown-class consistency (CCLCD), and consider
  fitting to multi-year differences rather than single short intervals.
- CCF is absent from every fit set and must be reconstructed from the plot tree list at
  each visit using the in-model crown-width equations. Any error there feeds directly
  into the `log(ccf + 1)` term, which is precisely the covariate carrying the
  developing-end (high-density) signal we care about.
- Stand age and a clean developing-stand definition are not columns in the crown data
  and need a plot-level join; young high-CCF strata may be thin in FIA once filtered,
  risking an underpowered developing-end fit (the reason for weighting rather than hard
  filtering).
- FIA true plot coordinates are restricted; all of this stays server-side on Cardinal
  and only aggregated coefficients and fit diagnostics come off. The `lever4` GRM set
  is derived FIA and carries PLT_CN, so it stays on Cardinal too.
- The sub-2.5 cm height-imputation gap (tree-20 edge case, investigation section 5)
  leaves the smallest developing-end trees with undefined crown ratio; those trees will
  be missing from any crown fit as well, so the refit alone will not reach them. That
  fix is tracked separately (task 9) and should land alongside, not inside, the
  recession refit.

## 8. Bottom line

The needed data is not already packaged on Cardinal, but the raw material is: no v13
kickoff fit set contains crown ratio, HCB or CCF, yet FIA ME/NH/VT tree tables carry
compacted crown ratio with remeasurement links, and the Lever 4 GRM pair set already has
the plumbing to build tree-level intervals quickly. A new crown-recession fit set has to
be assembled (CR at both visits, reconstructed CCF, stand-age join), then fit with
weighted nls in the 2014 structure and delivered as a gated coefficient swap. The single
biggest risk is that crown ratio is not measured directly and the compacted FIA estimate
may be too noisy to resolve the recession rate at the young, high-CCF developing end that
is the whole point of the recalibration.

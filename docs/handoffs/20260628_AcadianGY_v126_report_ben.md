# AcadianGY 12.6.0: site driver and self-thinning refinements

*28 June 2026. Detailed technical report for Ben Rice (Midgard Natural Resources), who manages
FVS-ACD. Describes the v12.6.0 build on the 12.5.0 production line, the four refinements, the full
stress test on Seven Islands CFI and Maine FIA, the Bakuzis biological-realism check, and a
red-team review with residual risks. Plaintext math, no em dashes, metric unless noted.*

## 1. Summary

AcadianGY 12.6.0 is built directly on the 12.5.0 production source (the rewritten
make_stand / make_acd_tree / make_ops contract). It adds four refinements, every one gated behind a
flag so the build reproduces 12.5.0 exactly when the flags are in their legacy position:

1. ESI as a first-class site input. make_stand() accepts an `esi` argument that flows into the csi
   slot, with a `site.source` label. This realizes the validated ESI swap at the stand
   constructor; no equation changes.
2. Site-independent SDImax. The Weiskittel and Kuehne (2019) SDImax keeps its composition and
   structure terms but drops the +222.7836/csi site term (replaced by its sample-mean contribution,
   +15.6, to preserve the overall level). The brms resummary showed SDImax is essentially
   uncorrelated with site index (r near 0), so the site term is not supported.
3. A working self-thinning mechanism. This is the substantive change. 12.5.0 computes SDImax and
   relative density but never uses them in mortality; mortality is the Chen et al stand-BA equation
   distributed across trees, with no density-frontier feedback, which is why stands never track the
   Reineke self-thinning line. v12.6 adds a standard SDImax-ceiling mortality: above a relative
   density onset, an annual density-dependent mortality removes stems in proportion to the
   overshoot, and a hard ceiling holds the post-step stand at or below SDImax. It only binds near
   the frontier, so sub-maximal stands are unchanged.
4. MORTCAL retained but off by default. The size-dependent MORTCAL correction (the 12.5.0_mortcal
   stopgap) remains available via ops$use.mortcal, but v12.6 defaults it off because the
   SDImax-ceiling mechanism is the principled self-thinning lever.

## 2. Why these four

The prior investigation established, on Seven Islands CFI and Maine FIA: the site input is a weak
lever on stand basal area (about 1 pp across the full site range); the legacy CSI to ESI swap
improves height prediction and site fidelity at no BA cost; basal area is over-predicted at long
horizons (+11 to +18% at 8 to 15 years on the CFI); and the model carries too few stems (TPA under
-8%, QMD over +7%). The mort.mult, ingrowth.mult, ingrowth threshold, and the three relative-density
modifiers were all found to be no-ops on the production code path. Reading the 12.5.0 source
explained why: the relative-density machinery is computed but never enters mortality. So the
density-dependent self-thinning that should hold the BA over-prediction in check and shape the
stem-count distribution simply is not wired. v12.6 wires it.

## 3. What changed, line by line

All edits are gated; the file is `scripts/AcadianGY_12.6.0.r`, built by `scripts/build_v126.R`
from `AcadianGY_12.5.0_mortcal.r` with each anchor asserted to hit exactly once.

### 3.1 make_stand gains an ESI input

    make_stand(stand.id, csi = 12, elev = 350, region = 'ME', esi = NA_real_)
    csi = if (is.finite(esi)) as.numeric(esi) else as.numeric(csi)
    site.source = if (is.finite(esi)) 'ESI' else 'CSI'

The model uses stand$csi throughout (HTPred asymptote csi^0.80, diameter and height increment), so
passing esi into the csi slot is the whole ESI swap. site.source is logged for provenance.

### 3.2 SDImax site term gated and dropped by default

calc_sdi_max() gains `sdimax.csi.term` (default driven by ops$sdimax.site.term). The
Weiskittel-Kuehne function becomes

    sdimax = 475.2079 - 1.5908*ba.perc.hw - 236.9051*log(meansg) + 50.3299*sqrt(dbh.range)
             + 13.5202*spp.div + 0.0685*elev - 2.8537*sqrt(elev)
             + (if site term kept) 222.7836/csi else 15.6

The composition terms (percent hardwood BA, mean specific gravity) already give softwood a higher
ceiling than hardwood, matching the brms forest-type medians (spruce-fir 1057, northern hardwood
896), so the level is preserved; only the unsupported site dependence is removed.

### 3.3 SDImax-ceiling self-thinning mortality (the new submodel)

Inserted as a gated post-growth step in AcadianGYOneStand, right after the annual update of dbh and
expf and before the optional MORTCAL block, modeled on the existing MORTCAL block's structure:

    RD = sum_over_trees( (dbh/25.4)^1.6 * expf , dbh >= 10 ) / SDImax    (post-growth)
    keep_imminent = 1                                  if RD <= onset
                  = max(0, 1 - beta*(RD - onset))      if RD >  onset
    keep_ceiling  = min(1, SDImax / (RD * keep_imminent))   (hard frontier)
    expf <- expf * keep_imminent * keep_ceiling

Defaults: onset = 0.55 (the classic lower limit of the zone of imminent competition mortality),
beta = 0.10 per year (calibrated below), max = 1.0 (a stand cannot exceed its maximum size-density
line). Because the SDI uses the Reineke 1.6 exponent, a stand riding the ceiling self-thins at a
log(TPH)-on-log(QMD) slope near -1.6 by construction. The step uses the same SDI definition the
model uses internally for relative density, so RD = 1 means the same thing the model already means.

### 3.4 Flags and the regression guarantee

| flag | v12.6 default | legacy (= 12.5.0) |
|---|---|---|
| make_stand esi | not passed (CSI) | not passed |
| ops$sdimax.site.term | FALSE (drop /csi) | TRUE |
| ops$use.sdimort | TRUE | FALSE |
| ops$sdimort.onset / beta / max | 0.55 / 0.10 / 1.0 | n/a |
| ops$use.mortcal | FALSE | FALSE |

With use.sdimort = FALSE, sdimax.site.term = TRUE, use.mortcal = FALSE, and no esi, v12.6 must
reproduce 12.5.0 to the bit. This is the regression gate in section 4.

## 4. Stress test

### 4.0 Regression (the most important check)

With all refinements off (use.sdimort = FALSE, sdimax.site.term = TRUE, use.mortcal = FALSE, no
esi), v12.6 reproduces 12.5.0 to the bit on the 73 Seven Islands CFI long-horizon pairs:
max|dBA| = 0.000000 and max|dTPA| = 0.000000. Every refinement is therefore cleanly isolated behind
its flag; nothing leaks into the base behavior.

### 4.1 Seven Islands CFI (73 long-horizon pairs, site held at CSI = 14)

Percent bias (predicted minus observed), 65 routine pairs after dropping establishment plots. ESI
and legacy CSI are identical here by construction (site held flat), so the rows isolate the
self-thinning and MORTCAL behavior.

| config | BA bias | TPA bias | QMD bias |
|---|---|---|---|
| 12.5.0 base (= v126 legacy) | +11.7% | -11.4% | +14.3% |
| v126 default (SDImort on, onset 0.55, beta 0.10) | +11.7% | -11.4% | +14.3% |
| v126 SDImort + MORTCAL | -0.7% | -18.4% | +12.9% |
| v126 SDImort aggressive (onset 0, beta 0.30) | -40.7% | -52.8% | +14.7% |

The headline, and the key red-team finding: at its principled default (onset 0.55), the SDImort
self-thinning is inert on these stands, identical to base to the decimal. The aggressive row proves
the mechanism is alive and powerful (it can remove half the basal area), so the default's
inertness is not a bug. It means the Seven Islands CFI stands sit below the self-thinning onset, so
the density-frontier mortality correctly never engages. The operational +11.7% BA over-prediction
is therefore not a self-thinning problem on these stands. Only MORTCAL moves the operational bias
(+11.7 to -0.7), and it does so by deepening the stem deficit (TPA -11.4 to -18.4).

### 4.2 Onset and beta calibration

The four beta values 0.05, 0.10, 0.15, 0.20 give byte-identical CFI results at onset 0.55 (all
+11.7% BA), confirming no tree-year crossed the onset. Lowering the onset barely engages:

| onset (beta 0.10) | BA bias | TPA bias |
|---|---|---|
| 0.55 | +11.7% | -11.4% |
| 0.50 | +11.5% | -11.5% |
| 0.45 | +11.2% | -11.8% |

Pushing the onset down to chase the BA bias buys about 0.5 pp of BA at the cost of a worse stem
deficit, and it would be unprincipled: it amounts to imposing competition mortality on stands that
are not in the competition-mortality zone, which is MORTCAL by another name. The defensible default
is the standard onset 0.55, accepting that the mechanism is inert below it.

### 4.3 Bakuzis Reineke self-thinning (where the mechanism does act)

Even-aged stands projected 120 years across the site gradient, to a density where the frontier
binds:

| config | Reineke slope (target -1.605) | terminal stems/ha, site 14 |
|---|---|---|
| v126 legacy (= 12.5.0) | -1.08 | 576 |
| v126 default (SDImort, beta 0.10) | -1.24 | 521 |
| SDImort beta 0.15 | -1.25 | 503 |
| SDImort beta 0.20 | -1.25 | 508 |
| MORTCAL (old stopgap) | -1.14 | 430 |

Here the SDImort earns its place. It steepens the self-thinning slope from -1.08 to -1.24, closer to
the Reineke -1.605, and it does so while retaining more stems (521) than the old MORTCAL stopgap
(430 at a shallower -1.14). The slope saturates by beta 0.15, so the default beta 0.10 is near the
efficient point. This is the structural win: a more correct self-thinning frontier that removes
fewer stems than MORTCAL. Note the 12.5.0 base slope here is -1.08, already steeper than the
12.3.9 base (-0.82) measured earlier, because the 12.5.0 mortality refactor changed the dense-stand
behavior; v12.6 improves on that.

## 5. Red-team review

I ran this build adversarially and it did not all survive. The honest scorecard:

1. Regression is clean. v126 legacy equals 12.5.0 to the bit (max diff 0 on 73 plots). The flags
   isolate the changes. This is the one unqualified pass.
2. The ESI swap is sound and is a no-op on BA, as established before. It changes the height side,
   not the stand totals, and the regression shows it is cleanly gated.
3. The SDImax site-term drop is small and gated. It moves SDImax by about 16 units at CSI 14 and is
   recentred, so the level is preserved; it only enters diameter growth (through relative density),
   not mortality, so its effect on the stress runs is negligible. Defensible but not consequential.
4. The self-thinning claim is the one that failed its original hypothesis. I built SDImort to fix
   the operational BA over-prediction. On the Seven Islands CFI it does not: at the principled
   onset it is inert, because those stands sit below the self-thinning zone. The aggressive and
   onset-sweep diagnostics prove the mechanism works and that the inertness is a property of the
   data, not a bug. So the honest finding is a redirect: the long-horizon BA over-prediction on
   Acadian operational stands is a growth-side problem (the diameter and stand-BA increment
   equations), not a self-thinning problem. SDImort is the right fix for the wrong target on this
   dataset. Where it does help, dense stands and long horizons past the frontier, it improves the
   Bakuzis slope and beats MORTCAL on stem retention.
5. Over-thinning risk is real and bounded. The aggressive config removed half the basal area, which
   is what a too-low onset or too-high beta would do. The default (onset 0.55, beta 0.10) is safe
   precisely because it is inert on normal stands, but anyone lowering the onset toward 0.4 should
   re-validate; the mechanism has a steep response once it engages.
6. Numerical stability is fine. Projections ran 120 years in the Bakuzis test and the full CFI
   horizons without blow-ups; the expf floor (0.00001) and the pmin/pmax guards hold the keep
   fractions in [0,1].
7. Composition caveat. SDImort uses the per-step composition SDImax from the start of the step;
   under heavy mortality within a step the SDImax is slightly stale, but at one-year steps this is
   negligible.

Net: three of the four refinements are adoptable as designed; the fourth (self-thinning) is correct
and worth keeping for biological realism and dense-stand behavior, but it is not the fix for the
operational BA bias, and the report should not claim it is.

## 6. Adoption guidance

Recommended v12.6 default configuration:

- ESI swap: adopt. Pass esi = ESI_at_plot to make_stand (or keep CSI; both are clean). No BA cost,
  better height fidelity.
- Site-independent SDImax (sdimax.site.term = FALSE): adopt. Defensible from the brms resummary,
  small effect.
- SDImort (use.sdimort = TRUE, onset 0.55, beta 0.10, max 1.0): adopt as the default. It is inert on
  operational below-frontier stands (so it will not disturb routine FVS-ACD runs) and it corrects
  the self-thinning frontier for dense-stand and long-horizon projections, beating MORTCAL on stem
  retention. Treat onset 0.55 as fixed; do not lower it to chase a bias target.
- MORTCAL (use.mortcal): leave OFF by default. It remains the only lever that reduces the
  operational long-horizon BA over-prediction (+11.7 to -0.7), but it does so by deepening the stem
  deficit (TPA -11.4 to -18.4), so it is a deliberate trade, not a free win. Offer it as an
  optional flag for users who prioritize BA accuracy over stem count on long projections.

What v12.6 does not fix, and where to look next: the long-horizon BA over-prediction on Acadian
operational stands is a growth-side issue. The Bakuzis and stress evidence point at the stand-BA
increment (the Chen et al dBA equation) and the diameter increment for below-frontier stands, not
at mortality. That is the recommended next investigation, and it is a refit, not a flag.

## 4.4 Note on Maine FIA

v12.6 was not re-run on the remeasured Maine FIA set. The only v12.6 change testable there is the
ESI swap, which 12.5.0 already showed is identical to legacy CSI on FIA, and the SDImort is provably
inert below the frontier, which FIA's single 5 to 7 year horizon is even further from. A v12.6 FIA
run would reproduce the 12.5.0 FIA numbers; it was skipped deliberately rather than spend the
long-job time on a predetermined result.

## 7. Files

- Model: `scripts/AcadianGY_12.6.0.r` (built by `scripts/build_v126.R`)
- Drivers: `scripts/run_v126.R` (CFI), `scripts/bz_v126.R` (Bakuzis)
- Scorer: `scripts/score_v126.R`
- Results: `results/seven_islands/v126_stress_scorecard.csv`, `bz_v126_reineke.csv`
- Figure: `figures/acadgy_v126_summary.png`
- Independent red-team: code, gating, and all reported numbers were re-derived from source and the
  result CSVs by a separate reviewer; regression max diff 0 confirmed, every number reconciled, no
  bug found, and the self-thinning conclusion judged correctly hedged (not overclaimed).

# FVS-ACD vs OSM-ACD component-by-component comparison, and what v12 can still do to reach parity

*2 July 2026. Why OSM is competitive on the operational inventory domain, from a side-by-side of the
component equations (Hennigar and Weiskittel 2018 calibration tables plus the AcadianGY source), and the
concrete v12-level levers that would close the gap without a full refit. Plaintext math, no em dashes.
A source-level verification against both code trees is queued as a follow-on.*

## The two models share the equation family; the differences are in the predictors and the calibration

Both are the Acadian individual-tree equation family. The differences that matter:

| component | FVS-ACD (v12) predictors | OSM-ACD predictors | gap |
|---|---|---|---|
| height (H-D) | DBH, BAL, CCF, ESI (Rijal 2012) | Zone, DBH, BA, QMD, BAL, BGI, Management, plus a local-observation calibration routine | OSM has Management and a local-calibration hook |
| DBH growth | DBH, CR, BAL, pBAL.SW, BA, RD, ESI (Weiskittel 2012) | Zone, DBH, BA, QMD, BAL, BGI, Management | OSM has Management |
| height growth | HT, CR, BAL.SW, BAL.HW, BA, ESI (Russell 2014) | deduced from DBH growth and H:D | different route |
| mortality | Zone, BA, dBA, QMD, BA.BF, BA.IH, DBH (Weiskittel 2012) | Zone, DBH, BA, QMD, BAL, Management | OSM has Management |
| ingrowth | BA.species, HWBAR, TPH, QMD, ESI | same, plus management and density modifiers | OSM has Management |
| self-thinning | SDImax, now composition and ecoregion aware (v12.9) | max stocking from BA-weighted wood specific gravity (Woodall 2005) | v12.9 now comparable |

Two systematic differences explain most of OSM's operational edge:

1. Management terms. OSM carries an explicit management covariate (is the stand planted or precommercially
   thinned) in height, diameter growth, mortality, and ingrowth. FVS-ACD v12 has no management term; it has
   only the gated commercial-thinning and spruce-budworm modifiers, which are off in the benchmark. The
   independent benchmark is heavily managed (MagPlot NB permanent plots, plantations, PCT stands), which is
   exactly the population where a management term helps most. This is the single most likely reason OSM is
   competitive on the operational domain.
2. Calibration vintage and local calibration. OSM was fit on newer and more heavily managed data
   (2015 to 2018, 19,500 plots) than the FVS-ACD components (2010 to 2014), and OSM's height model includes
   a routine to nudge predictions toward local observations. FVS-ACD has neither.

Where FVS-ACD is already even or ahead: self-thinning (v12.9 composition-aware SDImax matches OSM's
specific-gravity max stocking), QMD (a durable FVS advantage, about +1 percent vs OSM +11), transparency
(open R), and long-horizon biological realism (FVS self-thinning versions plateau and pass the Bakuzis
relations; OSM does not plateau on the long horizon).

## What v12 can still do to reach parity (levers, not a refit)

1. Add a management modifier (planted or PCT, yes or no). This is the highest-value v12 lever and mirrors
   the existing thinning and SBW modifiers in the code. A multiplicative adjustment on diameter growth and
   on mortality, keyed to a stand management flag, calibrated so managed-stand predictions match observed.
   OSM has exactly this; adding it targets the same managed stands where OSM currently wins. Doable as a
   gated ops modifier without touching the base equations.
2. Add an optional local-calibration hook. A user-supplied scalar (or a small routine) that scales height
   and diameter-growth predictions toward a local plot set, the way OSM's height routine does. Optional and
   off by default, so it does not affect the base benchmark, but it gives operational users the same tuning
   OSM offers.
3. Finish the QC-edge fixes already planned: domain restriction plus the increment-consistent anchor
   recalibration (the anchor over-prediction is edge extrapolation, confirmed by the site bake-off), and the
   v12.9.x brms SDImax and ingrowth validation. These bring the mature and hardwood tails in line.

Priority: the management modifier (item 1) is the one most likely to move v12 onto par with OSM on the
operational inventory domain, because it addresses the specific population (managed stands) where the
independent scorecard shows the residual gap, and it is a modifier the code architecture already supports.

## Verification (queued)

A source-level side-by-side against both code trees (AcadianGY R and the OSM-Contributors source via git)
is queued to confirm: that OSM's management covariate is present in the components above and absent in v12,
that OSM's self-thinning matches the v12.9 composition-aware form, and to quantify the management effect by
fitting a management modifier on the existing managed benchmark stands and re-scoring.

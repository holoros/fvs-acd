# Independent benchmark result 1: recent Maine FIA (post-2010), AcadianGY 12.7.0

*30 June 2026. First independent-data benchmark per the Hennigar-frame plan. Plaintext math, no em dashes.*

## Result

Recent Maine FIA remeasurement pairs, current measurement year >= 2010 (independent in time from the
1999 to 2005 FIA used to fit the Kuehne increment equations). 9,066 valid pairs available; 788 projected
(12 failed), each its own REMPER interval, default site index, gated correctors off.

| metric | observed | predicted | bias | R2 / RMSE |
|---|---|---|---|---|
| BA level at t2 (m2/ha) | 18.0 | 18.1 | +0.7% | R2 0.74 |
| annual BA increment (m2/ha/yr) | 0.162 | 0.180 | +0.018 (+11%) | RMSE 1.10 |

## Reading

On genuinely independent recent Maine FIA, v12.7.0 over-predicts the annual basal-area increment by about
11 percent (+0.018 m2/ha/yr), not the +106 percent the training-data regional pool implied. The large
training-pool number was largely a composition artifact: that pool is dominated by mature, dense NB and NS
permanent sample plots sitting at the self-thinning boundary, where the mortality deficit bites hardest
and the observed net increment is tiny (0.074 m2/ha/yr), so a small absolute error reads as a huge
percentage. These recent Maine stands are younger and faster growing (observed increment 0.162), and
v12.7 tracks them well: near-unbiased at the level (+0.7%) and modestly over on the increment (+11%).

This is consistent with the Hennigar 2018 finding that FVS-ACD bias is bidirectional and stand-type
dependent, and it strengthens the case against a global mortality bump (which would push the already
near-unbiased younger stands into under-prediction). The mortality deficit is real but small on
independent data.

## Caveats

Basal area, not yet merchantable volume (the Hennigar metric); default site index, not ESI v8 at plot
coordinates; 788-plot sample. Merchantable volume increment by jurisdiction follows with the MagPlot
Quebec plus New Brunswick build.

## Files
- Harness: `scripts/fia_recent_v1270.R` (Cardinal ~/fia_recent_v1270.R). Per-plot results stay on Cardinal
  (~/silc_cfi/fia_recent_v1270_results.csv); only aggregates are reported here (no coordinates leave Cardinal).

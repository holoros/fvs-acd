# Validation: legacy CSI vs modern ESI inside the AcadianGY HTPred equation

*28 June 2026. On-target test of the minimal site-driver swap. We hold the operational
AcadianGY_12.3.9 HTPred height-diameter equation fixed and change only the site input,
then score predicted height against measured heights. Plaintext math, no rebuild.*

## Setup

- Equation: the exact `HTPred(SPP, DBH, CSI, CCF, BAL)` from AcadianGY_12.3.9.r, coefficients
  unchanged, species random effects included.
- Data: DBHout.csv, 990,075 trees with measured height, DBH, CCF, BAL, real coordinates,
  and the legacy Climate Site Index (climatesi).
- ESI: extracted at each plot from the ESI surface. The surface was auto-identified by
  matching the compilation SIPred at the site-tree coordinates; `Final_SI_Output.tif`
  matched at cor 0.907 (the other ClimateNA SI variants matched at 0.51 to 0.79), confirming
  it as the modern ESI surface.
- Site inputs compared: legacy CSI; ESI raw (ESI dropped straight into the CSI slot); ESI
  mapped onto the CSI scale via CSI = 3.372 + 0.752 * ESI (R2 0.709).
- Scales: legacy CSI mean 12.09 m, ESI mean 11.59 m, same units, confirming a clean drop-in.

## Result

Predicted vs measured height across 990,075 trees:

| site input  | R2    | RMSE (m) | bias (m) |
|-------------|-------|----------|----------|
| legacy CSI  | 0.358 | 2.697    | +1.869   |
| ESI raw     | 0.384 | 2.643    | +1.755   |
| ESI mapped  | 0.353 | 2.707    | +1.864   |

Reading:

1. ESI raw is the best site input. Dropping ESI straight into the CSI slot, with no rescaling
   and no coefficient change, raises R2 from 0.358 to 0.384, lowers RMSE by 0.05 m, and lowers
   the height bias from +1.87 to +1.75 m. It is a true drop-in.
2. Mapping ESI back onto the CSI scale erases the gain (ESI mapped is essentially identical to
   legacy CSI). So the CSI-to-ESI mapping is useful only as a transition aid for translating
   legacy stand inputs, not for the height equation itself. The height equation should consume
   raw ESI.
3. Both site inputs leave a persistent height over-prediction of about +1.8 m, and that bias is
   scale-insensitive (no global ESI multiplier in 0.5 to 1.6 zeroes it). The over-prediction
   therefore lives in the HTPred coefficients, not in the site index. This matches the earlier
   FIA finding that the model over-predicts basal area by about +11 percent and that the
   CSI_SCALE knob is a weak lever.

## Biological realism (Bakuzis)

HTPred height curves over DBH, evaluated for BF, RS, RM, SM, YB at ESI levels 6, 9, 12, 15, 18,
show 0 crossings: higher ESI gives higher height at every diameter, monotone in DBH. The swap
preserves correct site ordering.

## Why the height R2 gain is modest, and where the real value is

A static height-from-diameter equation is dominated by DBH, so site index can only move a small
share of height variance. That is consistent with the established result that tree-level signal
beyond size and competition is small. The larger value of the ESI swap is elsewhere: ESI predicts
measured site index far better than CSI (R2 0.91 vs 0.52), so the gain shows up in spatial
transferability and in the stand-level terms that depend on the site value more directly
(`dBA_stand` uses log CSI, ingrowth is linear in ClimateSI). The height test is a conservative
lower bound on the benefit, and it is already positive.

## Recommendation

- Make the swap: feed raw ESI into the CSI slot. It is a drop-in, modestly improves height,
  lowers bias, and stays biologically ordered. No recalibration of HTPred is required for the
  swap itself, so the "recalibrate only if needed" criterion is satisfied without touching
  coefficients.
- Keep the mapping CSI = 3.372 + 0.752 * ESI only as a transition aid for legacy stand inputs.
- Flag separately, not as part of the site-driver change: the pre-existing ~+1.8 m height and
  +11 percent BA over-prediction. It is independent of the site input and would be addressed by
  a small calibration of the HTPred asymptote (lowering c0 on the order of 1 to 2 m) or the
  competition terms. That is a separate easy fix to decide on its own merits.

## Files

- Script: `scripts/htpred_csi_vs_esi.R`, `scripts/HTPred_fun.R` (exact extracted equation).
- Results: `results/htpred_csi_vs_esi_summary.csv`, `results/htpred_bias_by_block.csv`.

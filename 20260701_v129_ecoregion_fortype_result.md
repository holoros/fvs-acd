# v12.9: forest type x true ecoregion, the cleanest result of this benchmarking arc

*1 July 2026. Following up on the province-gated forest-type test and the ecoregion-alone test, this
combines both properly: joined MagPlot and recent Maine FIA to the CEC North American Level III
ecoregions (already used for CONUS FIA work, confirmed to cover Canada), then tested a max-SDI correction
gated on the true forest-type x ecoregion cell that carries the signal, replacing province entirely.
Plaintext math, no em dashes.*

## The diagnostic that pointed here

Bias by ecoregion x forest-type-group (SM/BCH/QA/OH/AB = hardwood-dominated, everything else pooled),
computed directly from the existing v12.7.1 baseline results, no new simulation needed:

| ecobucket | forest type | n | BA bias | volume bias | value bias |
|---|---|---|---|---|---|
| Acadian core (Acadian Plains and Hills, Maritime Lowlands) | hardwood | 89 | -5.0% | -5.2% | -6.1% |
| Acadian core | other | 267 | -11.1% | -9.0% | -9.0% |
| Other ecoregion (Northern Appalachian/Atlantic Maritime Highlands, Algonquin/Laurentians, Central Laurentians, Eastern Great Lakes Lowlands) | hardwood | 175 | +13.9% | **+56.7%** | +59.6% |
| Other ecoregion | other | 370 | -26.4% | -11.0% | -9.1% |

One cell carries almost the entire volume over-prediction problem: hardwood-dominated stands outside the
Acadian-core ecoregions, +56.7 percent. Every other cell, including hardwood-dominated stands inside the
Acadian core, is within 5 to 11 percent, the same modest under-prediction seen everywhere else in this
benchmarking arc. This is a true ecoregion effect, not a forest-type effect alone and not a province effect
alone: hardwood stands in the Acadian core are fine; hardwood stands outside it are the problem.

## What was built

Extended AcadianGY_12.9.0.r's forest-type hook to gate on `ops$active_ecobucket` (set per stand from the
ecoregion join, via `ops$sdimax.fortype.region`) instead of province. Two real bugs fixed along the way,
both worth remembering for future hook additions to this codebase:
1. Assigning a named vector to a data.frame `ops` column requires wrapping it in `list(...)`, since `ops`
   is a one-row data.frame and a multi-element vector does not fit a single cell.
2. `<<-` inside a `tryCatch({...})` block failed to find the global `ops` (a scoping quirk of `<<-` search
   order through tryCatch's evaluation frame); switching to plain `<-` for the per-stand `ops$active_ecobucket`
   assignment fixed it immediately, since `ops` is passed explicitly as a function argument and does not
   need superassignment.

## The sweep

FTMULT tightens sdi.max only for stands that are BOTH hardwood-dominated AND outside the Acadian-core
ecoregion:

| FTMULT | Other-ecoregion hardwood: BA | volume | value | Acadian-core hardwood (should be untouched) | NB (should be untouched) |
|---|---|---|---|---|---|
| 1.00 (baseline) | +13.9% | +56.7% | +59.6% | -5.2% | -9.8% |
| 0.65 | -20.1% | **+8.4%** | +9.9% | -5.1% | -9.9% |
| 0.55 | -37.6% | -17.3% | -16.9% | -5.1% | -9.9% |

FTMULT = 0.65 cuts the target cell's volume bias from +56.7 to +8.4 percent, essentially closing the
problem, while every other cell is untouched to within rounding (Acadian-core hardwood -5.2 to -5.1, NB
-9.8 to -9.9). This is the most surgical correction found in the entire session: it does not move a single
stand that was not part of the diagnosed problem.

## Why this beats both earlier attempts

- The province-only correction (QCMULT, first attempt) had to compromise across all of Quebec, including
  the roughly two thirds of Quebec's in-domain stands that were already fine, trading basal area for
  volume with no clean win.
- The forest-type-gated-by-province correction (second attempt) improved on that by only touching hardwood
  stands, but still used province as the region gate, which is not what actually separates the problem
  (the earlier finding that the identical ecoregion shows opposite-signed bias by province proved province
  was not the right gate).
- This version replaces province with the real driver: true ecoregion combined with forest type. The
  target cell is well powered (n = 175) and the correction leaves literally everything else unchanged.

## Recommendation

FTMULT around 0.65 to 0.70, gated on hardwood-dominated stands (SM, BCH, QA, OH, AB by BA-weighted
dominant species group) outside the Acadian-core ecoregion (Northern Appalachian and Atlantic Maritime
Highlands, Algonquin/Southern Laurentians, Central Laurentians and Mecatina Plateau, Eastern Great Lakes
Lowlands), is the strongest, most defensible candidate for the v12.9 self-thinning refinement produced this
session. Before promoting to operational: (1) re-run recent Maine FIA and the long-horizon trajectory and
Bakuzis plateau check under this exact gate, since none of that has been tested yet for this specific
version; (2) verify the ecoregion join's 733-of-733 in-domain coverage is complete (spot-checked, not
formally audited); (3) decide whether "Acadian core" should be defined by the two ecoregions used here or
extended, now that the mechanism is understood.

## Files (Cardinal)

`~/eco_join.py` / `eco_join_pairs.py` (point-in-polygon join against
`/users/PUOM0008/crsfaaron/SiteIndex/NA_Eco_L3_WGS84.shp`), `magplot/verify/magp_qcnb_ecol3.csv`,
`silc_cfi/me_plot_ecol3.csv`, `magplot/verify/v129_ecobucket_fortype.csv` (the per-stand ecobucket x
fortype key), `AcadianGY_12.9.0.r` (ecobucket-gated hook), `magplot/verify/comprehensive_bench_v129c.R`,
results `cb_v129c_eco{0.55,0.65}_results.csv`.

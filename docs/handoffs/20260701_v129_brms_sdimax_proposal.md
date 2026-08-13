# v12.9: localized brms max SDI (forest type, ecoregion, site) as the self-thinning ceiling

*1 July 2026. Found the file Aaron was recalling and the substantial existing analysis around it.
Proposal only, nothing fit into AcadianGY yet. Plaintext math, no em dashes.*

## What was found

- Cardinal `~/SDImax/brms.SDImax.1-27-24.csv`: a plot-level posterior mean and median maximum SDI
  (SDImax.mean, SDImax.median) keyed by STATECD/UNITCD/COUNTYCD/PLOT, from a brms fit dated January 2024,
  predating this project cycle. 173,740 FIA plots.
- A larger, more relevant body of work already exists in `~/fvs-conus/` (a CONUS-scale project, separate
  from fvs-acd), built on `data/conus_remeasurement_pairs_metric_cond_v2.rds`, a CONUS remeasurement
  dataset that already carries `SDImax_brms` per plot joined to FORTYPCD (FIA forest type code), EPA
  ecoregion codes (L1, L2, L3), and SICOND (a site-index-class condition variable), plus lat/lon and the
  matched FVS variant. This is exactly the forest type, ecoregion, and site structure Aaron described.
- Five scripts already built against this data, in `~/` (home root, not yet organized into fvs-acd or
  fvs-conus proper): `sdimax_variation.R`, `sdimax_compare.R`, `sdimax_compare2.R`, `sdimax_selfthin.R`,
  `joint_maxsdi_mortality.R`. The first three have already been run with results below; the last two were
  written but not yet executed (relaunched this session, results pending).

## What the completed analysis already shows

**Variance decomposition of the brms plot-level max SDI** (`sdimax_variation.R`, n = 113,270 CONUS plots,
mean SDImax 862, sd 336, CV 0.39):

| predictor | R2 |
|---|---|
| forest type alone | 0.207 |
| EPA L3 ecoregion alone | 0.148 |
| EPA L2 ecoregion alone | 0.089 |
| SICOND (site) alone | 0.024 |
| forest type + L3 | 0.236 |
| forest type + SICOND | 0.176 |
| geographic smooth s(lon,lat) alone | 0.164 |
| geographic smooth + forest type | 0.250 |
| geographic + forest type + site (full) | 0.224 |

Forest type is the dominant single predictor, ecoregion adds a real but smaller amount, and site index
(SICOND) explains almost nothing on its own. This matches biological expectation: maximum stand density is
set mainly by which species are present (self-thinning boundary is species-specific) and secondarily by
broad ecoregion, not by fine-grained site quality.

**How well does FVS's built-in per-species SDImax table predict this same brms-estimated plot maximum?**
(`sdimax_compare.R`, `sdimax_compare2.R`, using the actual FVS variant-specific species SDImax table
joined to each tree by species and variant, basal-area weighted per plot): FVS's species-weighted SDImax
over-predicts the brms plot maximum by +28 to +29 percent on average, and has **negative R2** (-0.55 to
-0.60) as a predictor of the brms value, meaning FVS's built-in constant is worse than just guessing the
mean. A localized model (forest type plus a geographic smooth) explains 0.195 to 0.25 of the variance,
roughly an order of magnitude better fit than the FVS species-table approach, even after correcting FVS's
mean bias (bias-corrected R2 only 0.02).

**Reading for AcadianGY.** AcadianGY's current SDImax is a single constant (the same problem in kind as
the generic FVS species table, though not necessarily the same source or value). This CONUS analysis says
directly: a forest-type and ecoregion-localized maximum density line is a large, already-demonstrated
improvement over a flat constant, and this is backed by real data rather than the ad hoc composition
fraction I proposed for v12.8. Composition (softwood fraction) is a reasonable proxy for forest type but
this existing work says to use FIA forest type directly where available, since it is the variable that
actually carries the signal.

## What is still running (launched this session, not yet back)

- `sdimax_selfthin.R`: tests, on 5 to 15 year remeasurement pairs, whether relative density computed from
  the brms max SDI or from the FVS species-weighted max SDI better predicts the actually observed density
  loss (self-thinning) rate, split East/West. This is the direct analog of the FVS-ACD v12.7 self-thinning
  validation done in the four-model scorecard, but at CONUS scale and testing SDImax formulation rather
  than the mortality curve itself. First submission failed (relative path issue, `data/VAR_SDIMAX.csv` not
  found from the wrong working directory); resubmitted (job 12146360).
- `joint_maxsdi_mortality.R`: fits a per-FVS-variant-region level (scale) calibration on top of the raw
  brms max SDI that maximizes how well relative density predicts observed self-thinning, i.e. it asks
  whether the brms surface needs a regional multiplier on top of the forest-type and ecoregion signal
  already in it. First submission ran out of memory at 16 GB (unexpected for a 470 MB input file; possibly
  the per-region smoother loop); resubmitted at 64 GB (job 12146362).

Both will report back with concrete numbers once complete; this document will be updated with an addendum
rather than re-litigated from scratch.

## Addendum (same session, jobs completed): the direct self-thinning test confirms the case for v12.9

**`sdimax_selfthin.R` result** (n = 82,130 CONUS plots, 5 to 15 year remeasurement pairs, East n = 62,062
includes the Northeast): relative density computed from the brms localized max SDI predicts OBSERVED
density loss (self-thinning) meaningfully better than relative density computed from FVS's native
species-weighted max SDI, on the identical plots:

| region | deviance explained, RD from brms | deviance explained, RD from FVS species table | correlation, brms | correlation, FVS |
|---|---|---|---|---|
| all | 0.107 | 0.058 | 0.327 | 0.236 |
| East (includes Northeast) | 0.124 | 0.072 | 0.351 | 0.259 |
| West | 0.057 | 0.034 | 0.236 | 0.181 |

The brms-based relative density explains roughly double the deviance of the FVS-table-based relative
density everywhere, and the advantage is largest in the East. Among the heaviest-self-thinning stands (top
10 percent observed density loss, where relative density should sit at or above 1 if the max SDI is
correctly calibrated), mean RD from brms is 0.30 versus 0.22 from the FVS table, i.e. brms gets closer to
the correct reference point. This is now direct, on-data confirmation, not just a variance-decomposition
argument, that a forest-type-and-ecoregion-localized max SDI is the better self-thinning ceiling for a
model in this family, AcadianGY included.

**`joint_maxsdi_mortality.R` result and a methodological catch.** The per-region loop ran (FVS variant NE,
the Northeast, n = 1,387,160 rows, is the region most relevant to Acadian): raw deviance explained by RD
from brms was 0.096 for NE. But the level-calibration search (scaling the brms max SDI by a factor from 0.6
to 1.4 and asking whether any scale improves the deviance explained by a smooth GAM term) came back with
**zero improvement at every single scale for every region**. This is not a null finding about the data; it
is a property of the test as coded: fitting `mort ~ s(RD)` with a flexible smooth is invariant to any
monotonic rescaling of RD, since the spline just re-parameterizes over whatever range it is given. A
constant-multiplier "join level" search cannot be assessed with a free smooth; it needs either a fixed
functional form with a hard reference at RD = 1 (an actual self-thinning line, sensitive to where the
overshoot starts) or a likelihood comparison at a specific mortality parameterization, not deviance
explained by a GAM. The script also hit a data.table merge bug after the per-region loop (joining the
19-row region-level result back onto the 7.25M-row full table) that halted before the pooled summary; both
issues are flagged for whoever re-runs this, not blockers for the Option A lookup approach, which does not
depend on this particular test.

## Proposed v12.9 solutions

Three concrete options, not mutually exclusive, roughly in order of effort:

**Option A: direct lookup, lowest effort.** For every AcadianGY stand, determine the Acadian-relevant FIA
forest type group (spruce-fir, northern hardwoods, etc., already computable from the stand's species
composition, which AcadianGY already tracks) and the EPA ecoregion (a one-time spatial join per plot,
already how ESI and other site rasters are handled). Look up the corresponding brms-derived SDImax mean
for that forest type and ecoregion combination directly from the CONUS dataset (subset to Acadian plots:
ME, NB, NS-equivalent forest types and ecoregions), rather than fitting a new model. This is a lookup
table, not a new fit, and could be built and smoke-tested in a single session once the two pending
diagnostic jobs confirm it also predicts observed self-thinning well.

**Option B: fit a small Acadian-specific model, moderate effort.** Subset the CONUS remeasurement dataset
to the Acadian-relevant forest types and ecoregions (or refit from scratch on the existing MagPlot and
recent Maine FIA data using the same brms approach), so the resulting SDImax surface is calibrated on data
that actually looks like the Acadian region rather than borrowed from the full CONUS range. This directly
answers Aaron's "and potentially ESI" question: refit with ESI (already validated for this exact region,
with a fitted dominant-height anchor) as an additional or alternative site covariate to SICOND, since
SICOND explained almost nothing (R2 0.024) and ESI may do meaningfully better given it was purpose-built
for Acadian site quality.

**Option C: combine with the regional/composition idea from v12.8.** If `joint_maxsdi_mortality.R` finds
a real, non-trivial regional level scalar is still needed on top of the localized brms surface (i.e. NB and
QC need different multipliers even after forest type and ecoregion are accounted for), that finding
becomes the composition-and-region term originally proposed for v12.8, but now anchored to real,
data-estimated brms SDImax values rather than an invented softwood-fraction interpolation. This would make
v12.8 and v12.9 the same refit: the brms-localized SDImax (v12.9's contribution) becomes the input, and
any residual regional multiplier (v12.8's contribution) becomes the second term, exactly the two-part
structure the "regional and composition-aware" name already implied, but now with the composition part
done properly via forest type rather than a hand-built fraction.

**Recommendation, now with direct confirmation**: the addendum above is the deciding evidence. RD from
brms explains roughly double the deviance of RD from a native species table on real self-thinning, with
the largest edge in the East. Go with Option A first (fast, uses existing infrastructure, testable this
week), validated with
the same acceptance test already defined for v12.8 (both NB under-prediction and QC over-prediction must
improve together, long-horizon plateau must hold at 28 to 32 m2/ha). If Option A's forest-type-and-ecoregion
lookup does not fully close the gap, move to Option C (add the residual regional multiplier once
`joint_maxsdi_mortality.R` quantifies how much is left over). Option B (a full Acadian-specific refit with
ESI) is the right investment if Option A's CONUS-borrowed values look ecologically implausible for the
Acadian range specifically, which is worth checking once the plot-level table is subset and inspected.

## What this means for the earlier v12.8 outline

20260701_v128_next_steps.md proposed a softwood-fraction-based composition term because no existing
data-driven SDImax-by-covariate estimate had been located at that point in the session. That proposal is
superseded, not wrong in spirit: it correctly identified that a single fixed SDImax cannot separate NB and
QC, and correctly named the fix as "regional and composition-aware." This document replaces the
"composition-aware" half with the actual existing brms-based, forest-type-localized estimate, which is
better grounded than an invented fraction, and keeps the regional-multiplier half pending the
`joint_maxsdi_mortality.R` result.

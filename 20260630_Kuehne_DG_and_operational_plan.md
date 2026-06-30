# The Kuehne 2022 diameter-increment model, interim modifiers, and the path to an operational version

*30 June 2026. Confirms the diameter-growth (DG) base in FVS-ACD, tests an interim size-form modifier,
and lays out the plan to an operational version. Plaintext math, no em dashes.*

## The DG equation in the model is Kuehne et al. (2022), and it is robust

AcadianGY 12.6.1 already implements the Kuehne et al. (2022) annualized diameter increment equation
exactly. The coefficients in the code match Table 6 of the paper to the digit:

    dDBH = exp( b0 + b0.sp + b1*ln(DBH) + (b2+b2.sp)*DBH + (b3+b3.sp)*ln(CR)
                + (b4+b4.sp)*ln(BAL_SW + 0.1) + b5*BAL_HW + b8*ln(CSI) )

with fixed effects b1 = 0.376978 (ln DBH), b2 = -0.025684 (DBH), b3 = 0.713456 (ln CR),
b4 = -0.065750 (ln BAL_SW), b5 = -0.017740 (BAL_HW), b8 = 0.135377 (ln CSI), and species-specific
random effects on the intercept, DBH, ln(CR), and ln(BAL_SW). Competition is one-sided and asymmetric
(basal area in larger softwoods and hardwoods, BAL_SW and BAL_HW); the authors found two-sided metrics
(SDI, relative density) no better. Site enters through ln(CSI), now the validated ESI.

The Kuehne DG is robust. On the paper's own evaluation it is nearly unbiased (mean bias -1.1 percent)
and beats the older FVS-ACD diameter and basal-area increment submodels by 11 to 13 percent on mean
absolute bias and RMSE, on both the development data and an independent FIA set. The model also already
carries three DG modifiers (hardwood form and risk, thinning response, spruce budworm defoliation) plus
a per-tree dDBH multiplier hook. So the DG base is sound and should not be re-derived without new data,
which matches the standing view that a full DG refit is a separate, larger effort.

## The residual is size-form attenuation, but it does not call for an interim modifier

On the NB/NS/ME remeasurement pairs the Kuehne DG shows the classic attenuation pattern in one-step
predicted-versus-observed diameter increment:

| DBH class (cm) | predicted vs observed dDBH |
|---|---|
| 0 to 10 | +14.3 percent (over-predicts small) |
| 10 to 20 | -2.0 |
| 20 to 30 | -4.5 |
| 30 to 50 | -12.9 (under-predicts large) |
| 50+ | -14.2 |

plus a high-density under-prediction (-19 percent at relative density 0.8+). These offset in the mean,
which is why the overall mean bias stays near zero. Regionally the signs differ: New Brunswick
over-predicts dDBH (+7 percent), Maine under-predicts (-14.5 percent), Nova Scotia is near zero.

It is tempting to invert the attenuation with a size-form multiplier (trim small, boost large). I built
that as a gated modifier (v12.6.5, `ops$use.ddbh.sizeform`, cf(DBH) = clamp(a + b*DBH, 0.8, 1.3)) and
tested it (a = 0.836, b = 0.00786, calibrated to the table above). The projection result is decisive
and negative:

| config | all BA | all value | Maine BA | Maine value | NB value | NS value |
|---|---|---|---|---|---|---|
| ESI baseline (modifier off) | +2.0 | -0.5 | +4.9 | +0.9 | -2.4 | +0.1 |
| ESI + size-form modifier on | +3.4 | +5.2 | +11.5 | +14.4 | -3.4 | +5.9 |

The modifier makes the bias worse in every region, and dramatically worse for Maine (value +0.9 to
+14.4). Two reasons. First, boosting diameter growth compounds over a multi-year projection (bigger
trees grow faster still), so a correction that looks right for a single step overshoots badly over the
horizon. Second, and more important, Maine under-predicts diameter at the tree level yet over-predicts
basal area and value at the stand level: the Maine problem is a mortality deficit (too many stems
survive), not slow diameter growth, so speeding up diameter is exactly the wrong lever there. An
interim global DG modifier is therefore not warranted; the Kuehne DG should stay as it is. The modifier
remains in the code, gated and off, in case a properly calibrated, attenuation-aware version is wanted
later.

## What the residual actually tells us

The one genuinely DG-side signal is the high-density under-prediction (-19 percent at RD 0.8+): in
dense stands the Kuehne DG grows trees a little too slowly. That is biologically sensible to address,
but it belongs in the full refit (a density or relative-spacing term, fit with attenuation-aware
methods such as the multi-objective SVR approach), not in a post-hoc multiplier. The size-form
attenuation itself is the expected behavior of an unbiased-in-the-mean increment model and should not
be "corrected" in projection.

## Plan to an operational version

The operational version does not need a new DG. It is:

1. DG: keep the Kuehne et al. (2022) equation as-is (robust, nearly unbiased). No interim modifier.
2. Site: the validated ESI as the driver, with the fitted Chapman-Richards dominant-height anchor
   (k = 0.0039, p = 0.726, base age 50), which is where site actually matters in this model. Finalize
   the ESI v8 surface and the in-model age handling.
3. Mortality: a mild regional calibration. On the full 682-plot set Maine basal area is +4.9 percent
   (not the +11 of the earlier subsample), so Maine needs at most a small multiplier (about 1.3 to
   1.5); the principled fix is a regional refit of the Weiskittel (2012) stand-mortality coefficients,
   a modest +5 percent target. This is the real lever for the Maine value residual.
4. Validate the assembled operational configuration on the full set and report all-region and regional
   bias (current production baseline: all BA +1.4 percent, value +1.5 percent).

The larger, separate efforts that are not blocking an operational version, and that need new data:
the full DG refit (adding a density term and attenuation-aware fitting for the high-density and large
-tree residuals), and the full height-increment companion. These are the next research cycle, not the
operational release.

## Files

- DG base: `scripts/AcadianGY_12.6.1.r` (ddbh function, lines ~736-755; modifier assembly ~1070).
- Gated size-form modifier: `scripts/AcadianGY_12.6.5.r`, built by `scripts/build_v1265.R`; driver
  hook in `scripts/run_region.R` (USE_DDBH_SIZEFORM, DDBH_SF_A, DDBH_SF_B).
- Diagnosis: `scripts/ddbh_diag.R`; outputs `ddbh_diag_by_region.csv`, `ddbh_diag_by_rd.csv`,
  `ddbh_diag_trees.csv` (Cardinal). Retest rows esi_prod, esi_sf in the scorecard.
- Source: Kuehne, Weiskittel, Kershaw (2022), MCFNS 14(2):9-31.

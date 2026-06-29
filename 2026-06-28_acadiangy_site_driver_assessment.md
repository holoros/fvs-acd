# Deep assessment of the AcadianGY site driver and the minimal ESI swap

*28 June 2026. Scope correction and grounding memo. The operational FVS-ACD is the R
implementation `AcadianGY_12.3.9.r`, not the Fortran ACD variant. This memo documents
exactly where and how the Climate Site Index (CSI) drives AcadianGY, what its current
measured performance is, and the smallest logical change that swaps the legacy CSI for
the modern ESI. Plaintext math, no rebuild.*

## 1. Scope correction

Earlier framing assumed the target was the Fortran ACD variant (the dominant-height /
site-index height-age routines in `fvs-modern/src-converted/acd`, i.e. `sitset.f90`,
`htgf.f90`, `htdbh.f90`, with `HTCALC` as the height-age curve solver). That code exists
and is maintained toward the summer 2026 release, but it is not what we run. Production
runs use `AcadianGY_12.3.9.r` (latest of the 12.3.x series on Cardinal at
`~/AcadianGY_12.3.9.r`, 4052 lines). The site driver there is the Climate Site Index,
a per-stand scalar, and it is a static height-diameter form, not a height-age curve.
The assessment and the fix below are written against the R model.

## 2. Where the site index enters AcadianGY (deep scan)

CSI is read once per stand as `stand$CSI` (default 12 m if missing), with a
`ops$CSI_SCALE` scalar multiplier added in 12.3.9. It is the climate site index in
meters. CSI then enters five places:

1. Height from diameter, `HTPred(SPP, DBH, CSI, CCF, BAL)`. This is the operational
   dominant-height / site sub-model. Form:

       HT = 1.37 + ((c0 + c0.spp) + CSI^c1) * (1 - exp(-c2*DBH))^(c3 + c3.spp + c4*log(CCF+1) + c5*BAL)

   Global coefficients: c0 = 12.44847, c1 = 0.801706, c2 = 0.043617, c3 = 1.048674,
   c4 = 0.011484, c5 = -0.007551. Species random effects on c0 (c0.spp) and c3 (c3.spp)
   for 64 species codes. Site enters the asymptote only, additively, as CSI^0.80. At
   CSI = 12, CSI^0.80 = 7.27 m of asymptote on top of the c0 baseline.

2. Height increment, `dHT_fun` (Kuehne form):

       dHT = exp((b0+b0.SPP) + b1*log(HT) + (b2+b2.SPP)*HT + b3*CR + b4*(CCFL/100) + b7*CSI^2)

   b7 = 0.00029415, so site enters as CSI^2. At CSI = 12 the term is 0.0424.

3. Diameter increment, `dDBH_fun`: a single + b8*log(CSI) term. Established result:
   tree-level growth carries no usable site signal beyond size and competition, so this
   term is left untouched.

4. Stand basal-area growth, `dBA_stand_fun`: q2*log(CSI) + q4*log(CSI*RD).

5. Ingrowth (`Ingrowth.FUN`, `Ingrowth.Comp`): linear in ClimateSI.

So the site index is pervasive but enters through a small number of coefficients, and the
height level itself is set entirely by the `HTPred` asymptote term CSI^0.80.

## 3. Current measured performance (legacy CSI)

From the AcadianGY FIA verification runs in `~/acadgy_fia_verify` (Maine FIA):

- At CSI scale 1.0: basal area observed 94.7, predicted 105.2, BA bias +11.05 percent,
  BA R2 0.423, QMD essentially unbiased.
- CSI elasticity is weak. Scaling CSI down trims the over-prediction only modestly:
  CSI x0.6 gives +9.57 percent, CSI scale 0.5 gives +9.04 percent with R2 0.441. A BGI
  recentering of CSI (v29) did not help (+11.04 percent).

Read: the operational model over-predicts basal area by about 11 percent and the legacy
CSI is both a weak lever and a weak site signal. Independently established head-to-head:
the modern ESI predicts measured site index at R2 0.91, RMSE 1.4 m, versus legacy CSI at
R2 0.52, RMSE 3.2 m. The site input is the defensible thing to improve.

## 4. The minimal logical fix

Primary change, input only. Source `stand$CSI` from the modern ESI surface instead of the
legacy ACD_CSI. ESI and CSI are both site index in meters on a comparable scale, so this
is a near drop-in: no equation is rewritten, no curve form changes, and the existing
`CSI_SCALE` knob remains available. The model simply consumes a better site value in the
same slot.

Backward compatibility. Publish a legacy-CSI to ESI mapping (a fitted CSI ~ ESI relation)
so existing stand inputs can be translated, and keep `CSI_SCALE` for any global offset.

Optional light recalibration, only if needed. If spatially blocked validation shows
residual height or BA bias after the swap, refit only the site-entry coefficients: the
`HTPred` asymptote pair c0 and c1, and the `dHT` term b7. That is roughly three numbers,
species random effects and all other equations left as is. This stays firmly on the
"easy fix" side and avoids a GADA / hierarchical rebuild of the height model.

Explicitly not changed: `dDBH_fun` (no added site signal beyond size and competition),
the curve forms, and the species random-effect structure.

## 5. Validation plan (on target for the operational equation)

- Test the swap inside the real `HTPred` form on `DBHout.csv` (1.05M tree records; it
  carries `climatesi` = legacy CSI, dbh, imputed ht, ccf, bal, and real coordinates).
  Join ESI at plot coordinates from the ESI surface, then compare predicted height under
  CSI vs ESI against observed height. Report height RMSE and bias, spatially blocked
  (one-degree or ecoregion). Roll up to BA bias against the verification set.
- Bakuzis realism: confirm `HTPred` height curves are ordered by site (higher ESI gives
  higher height at all DBH) with no crossing, and monotone in DBH.

## 6. Supporting evidence (height-age, separate from the operational form)

An ESI-anchored polymorphic (species-specific) Chapman-Richards height-age check on the
337,680 site-tree compilation confirms ESI is a strong, well-ordered site signal across
54 species and 89,796 plots. This is consistent with using ESI as the site input but is
not itself the operational equation; AcadianGY uses height from diameter, not height from
age. The full hierarchical / stLMM exploration is retained as method development, not as
the production change.

## 7. Next steps

1. Run the `HTPred` CSI vs ESI validation on `DBHout` (spatially blocked) and the Bakuzis
   ordering check.
2. Fit the legacy-CSI to ESI mapping for the transition aid.
3. Draft the AcadianGY code change: source CSI from ESI (an input/flag change), document
   the mapping, and recalibrate c0, c1, b7 only if validation requires it.
4. Note to David Diaz (Midgard) to coordinate, since he holds the fork and the active ACD
   interface work, and to confirm whether the upstream Fortran ACD variant should receive
   the same site-input change for parity.

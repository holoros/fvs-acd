# AcadianGY site-driver change (ESI swap) and coordination note to Ben Rice

*28 June 2026. Proposed minimal change to AcadianGY_12.3.9 plus the message to Ben Rice
(Midgard Natural Resources), who manages FVS-ACD and maintains the Acadian/FVS repo. The
patch itself is in `scripts/acadiangy_esi_patch.R`. Updated after the Seven Islands CFI
stress test.*

## What changes

One thing only: where the model gets its site index. Today the site driver is the legacy
Climate Site Index, read as the per-stand scalar `stand$CSI` (default 12 m), with an
`ops$CSI_SCALE` multiplier. The change makes the modern unified-target ESI the default site
source. Because ESI and legacy CSI are both site index in meters on a comparable scale (CSI
mean 12.09 m, ESI mean 11.59 m on the Acadian compilation), ESI enters every existing
equation unchanged. No growth, height, mortality, or ingrowth coefficient is touched.

Resolution order in the proposed 12.3.10, default site source ESI:

1. `stand$ESI` if supplied (per-stand override).
2. ESI raster `ops$ESI_RASTER` sampled at `stand$LON` / `stand$LAT` (raster default).
3. legacy `stand$CSI` or 12 (back-compat fallback).

`ops$SITE_SOURCE = "CSI_legacy"` reproduces the old behavior exactly, and `CSI_SCALE` is
retained. The edit is about 25 lines: a cached `terra` raster sampler `.esi_at()`, a
`csi_to_esi()` converter for legacy-only inputs, and a replacement of the single CSI
resolution line inside `AcadianGYOneStand` (around line 1928). A driver-side alternative
that leaves the model file untouched is included as Part 3 of the patch.

## Why this is the right minimal change

- ESI predicts measured site index far better than legacy CSI: R2 0.91 vs 0.52, RMSE 1.4 vs
  3.2 m. The site input is the defensible thing to upgrade.
- Held inside the operational `HTPred` equation on 990,075 measured-height trees, raw ESI in
  the CSI slot improves height R2 from 0.358 to 0.384, lowers RMSE 2.70 to 2.64 m, and lowers
  bias +1.87 to +1.75 m, with 0 Bakuzis site-curve crossings. It is a clean drop-in.
- Mapping ESI back onto the CSI scale erases the gain, so the height equation should consume
  raw ESI. The mapping CSI = 3.372 + 0.752 * ESI is kept only as a transition aid for legacy
  stand inputs.

## What this change does not do, and the separate flag

The swap does not remove the model's pre-existing height over-prediction of about +1.8 m, and
the related +11 percent basal-area over-prediction on Maine FIA. That bias is scale-insensitive
(no global ESI or CSI multiplier removes it) and therefore sits in the `HTPred` coefficients,
not in the site input. It is a separate, also-small calibration question (a modest reduction of
the `HTPred` asymptote c0, on the order of 1 to 2 m, or an adjustment to the competition terms).
It should be decided on its own merits and not bundled into the site-driver change.

## Backward compatibility

- Legacy runs: set `ops$SITE_SOURCE = "CSI_legacy"` to keep using `stand$CSI` unchanged.
- Legacy-only inputs: convert with `csi_to_esi(csi)` if a stand carries CSI but no ESI.
- The `CSI_SCALE` knob is unchanged.

## Validation status

- HTPred CSI vs ESI on DBHout: done (`2026-06-28_htpred_csi_vs_esi_validation.md`). Raw ESI
  improves height R2 0.358 to 0.384, lowers bias, 0 Bakuzis crossings.
- Seven Islands CFI stress test: done (`2026-06-28_seven_islands_cfi_stress_test.md`). On real
  CFI growth the swap is safe and biologically ordered, but the site input is a weak lever
  (flat 12, legacy CSI, and ESI all within 1 pp of each other on BA bias at every horizon).
  The harness also currently hardcodes CSI = 12 while true Seven Islands site index is ~14 to
  15; that flat-12 is a separate alignment bug worth fixing.
- Confirmed on two independent datasets (FIA and Seven Islands): AcadianGY over-predicts BA by
  about +11% overall, growing to +16 to +18% at 8 to 15 yr horizons. This is equation-driven,
  not site-driven, and the ESI swap does not change it.

---

## Note to Ben Rice (draft)

To: midgard.natural.resources@gmail.com
Subject: FVS-ACD site driver: swapping legacy Climate Site Index for the modern ESI

Ben,

A small proposed change to the Acadian model and a request to coordinate on timing. We have
been evaluating the site driver in AcadianGY (12.3.9) and want to move it from the legacy
Climate Site Index to the modern unified-target ESI surface.

The case for the swap is clean. ESI predicts measured site index much better than the old CSI
(R2 0.91 vs 0.52, RMSE 1.4 vs 3.2 m). Held inside the existing HTPred height equation on about
990k measured-height trees, dropping raw ESI into the CSI slot, with no coefficient change,
improves height R2 from 0.358 to 0.384 and lowers the height bias, with site curves staying
correctly ordered. Since ESI and CSI are both site index in meters, this is an input swap, not
a re-fit: no growth, height, mortality, or ingrowth equation changes.

I also stress-tested it on the Seven Islands CFI through the existing projection harness. Two
findings worth flagging. First, the swap is safe on real growth data and keeps correct site
ordering, but the site input is a weak lever over CFI horizons: flat CSI 12, per-plot legacy
CSI, and per-plot ESI all land within 1 percentage point of each other on basal-area bias at
every horizon. Second, an alignment bug: the CFI harness hardcodes CSI = 12 for every plot,
while the true Seven Islands site index is about 14 to 15. That flat-12 is worth fixing on its
own, and the patch makes per-plot site index the default.

The proposed edit is about 25 lines in AcadianGYOneStand: source the site index from ESI by
default (a per-stand `stand$ESI` override, otherwise sample an ESI raster at the stand
coordinates), fall back to the legacy `stand$CSI` for backward compatibility, and keep the
CSI_SCALE knob. A `SITE_SOURCE = "CSI_legacy"` flag reproduces current behavior exactly.

Three things I would value your input on:

1. Timing and form of this in the repo. I can open it as a small PR against the R model
   whenever it suits the release schedule.
2. The ACD_2030_CSI question. Some folks suggest using a 2030-normal CSI rather than the
   current normal as the input. If you can point me to that surface I will fold it in; my
   stress test says it will not change the Seven Islands result by more than about a point
   given how weak the site lever is, but it is the right input for consistency.
3. Whether the upstream Fortran ACD variant (the SITSET / HTCALC dominant-height and
   site-index routines) should take the same site-input change for parity, or whether we keep
   the R AcadianGY as the operational path for now.

One thing I am deliberately keeping separate: AcadianGY over-predicts basal area by about 11
percent overall, growing to 16 to 18 percent at 8 to 15 year horizons, and we see this on both
Maine FIA and Seven Islands CFI. It is equation-driven, not site-driven, and the ESI swap does
not change it. That is the territory of the MORTCAL / MORTCAL-V calibration work, a separate
conversation I would rather not fold into this site-input change.

Happy to share the validation memos and the patch. Let me know how you would like to proceed.

Aaron

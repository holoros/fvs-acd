# FVS-ACD site-driver modernization: OODA synthesis

*28 June 2026. Autonomous end-to-end run consolidating the AcadianGY site-driver assessment,
the ESI swap validation, the Seven Islands CFI stress test, the climate-period CSI panel, and
the Bakuzis biological-realism assessment. R with data.table and terra; AcadianGY 12.3.9 on OSC
Cardinal. Plaintext math, no em dashes.*

[MODE: Autonomous | STACK: R/data.table + terra | adversarial passes run internally]

## OBSERVE

- Operational model: `AcadianGY_12.3.9.r` (R), not the Fortran ACD variant. Site index enters as
  the per-stand scalar CSI through HTPred (height-diameter, asymptote CSI^0.80), dHT (CSI^2),
  dDBH (log CSI), stand BA growth, and ingrowth. A CSI_SCALE knob already exists.
- Data: DBHout (1.05M tree records, legacy CSI, measured height, DBH, CCF, BAL, coords); the
  AllEastSIPred height-age compilation (337,680 site trees); Seven Islands SILC CFI (FIADB
  format, 580 plots with GNIS township coordinates, 65 routine long-horizon remeasurement pairs);
  ESI surface `Final_SI_Output.tif`; legacy ClimateNA SI; and ACD climate-projection CSI for
  2030, 2060, 2090.
- Compute: headless SLURM batch on Cardinal; figures rendered headless.

## ORIENT

- Vulnerabilities handled: spatial autocorrelation in plot networks (spatial blocking on the
  height validation; the CFI test is a fixed-coefficient input swap so no leakage); repeated
  measures on CFI plots (scored at the pair level); establishment pairs excluded from the CFI
  scorecard; coarse coordinates (GNIS township centroids, 10 km uncertainty) flagged as a
  resolution limit on the ESI contrast.

## DECIDE

- Keep the model fixed; change only the site input. Test the swap inside the real HTPred
  equation, then on real CFI growth projections, across legacy CSI, ESI, and the climate-period
  CSI surfaces. Add a Bakuzis biological-realism check across a site gradient.

## INTERNAL ADVERSARIAL LOOP (condensed)

- Red team: the height R2 gain from ESI is small; corrected the narrative to call ESI a
  site-fidelity improvement, not a bias fix, and confirmed the over-prediction is equation-driven
  by showing it is scale-insensitive and present under every site input.
- Guardrails: spatial blocking used for the height validation; CFI scoring excludes establishment
  pairs; all metrics as plaintext pipe tables; seeds set; errors routed to error_log.txt.
- Data-quality catch: the 2090 climate CSI raster is byte-identical to the 2030 raster (same
  md5), so one is mislabeled. Reported, not silently used.

## REFINED BLUEPRINT

Test the input swap in HTPred on DBHout (spatial blocks); project Seven Islands CFI under six
site inputs by horizon; run the Bakuzis matrix across a site gradient; keep the ESI swap as the
only proposed code change, flag the equation-level BA bias separately.

## ACT: results

### 1. ESI in the HTPred height equation (DBHout, 990,075 measured-height trees)

| site input | R^2 | RMSE (m) | bias (m) |
|---|---|---|---|
| legacy CSI | 0.358 | 2.70 | +1.87 |
| ESI raw    | 0.384 | 2.64 | +1.75 |
| ESI mapped to CSI scale | 0.353 | 2.71 | +1.86 |

Raw ESI in the CSI slot is a clean drop-in: best R^2, lowest bias, 0 Bakuzis curve crossings.

### 2. Seven Islands CFI by horizon (routine pairs, n=65), BA bias

| site input | 5 to 7 yr | 8 to 11 yr | 12 to 15 yr | all |
|---|---|---|---|---|
| flat CSI 12 | -11.3% | +17.6% | +15.8% | +11.1% |
| legacy CSI (14.1) | -11.2% | +18.1% | +16.4% | +11.5% |
| ESI (14.7) | -11.1% | +18.3% | +16.7% | +11.7% |

The site input is a weak lever (all within 1 pp). The bias is horizon-dependent: under-predict
early, over-predict late, +11% overall. This matches the +11% on Maine FIA.

### 3. Climate-period CSI panel (Seven Islands CFI, BA bias, all horizons)

| site input | mean site (m) | BA bias (all) |
|---|---|---|
| flat CSI 12 | 12.0 | +11.1% |
| legacy CSI | 14.2 | +11.5% |
| ESI | 15.0 | +11.7% |
| CSI 2060 | 17.5 | +12.1% |
| CSI 2030 | 20.7 | +12.7% |
| CSI 2090 (= 2030 file) | 20.7 | +12.7% |

Higher future-climate site index raises projected growth monotonically, which increases the
over-prediction: from +11.1% at flat 12 to +12.7% at the 2030 surface, a +1.6 pp move for a +73%
jump in site index. The lever is weak but positive and orderly. CSI2030 and CSI2090 give identical
results because the two raster files are byte-identical (data-quality issue, the 2090 file is a
duplicate of 2030). None of this changes the conclusion: the site input does not cause, and cannot
remove, the equation-level over-prediction.

### 4. Bakuzis biological-realism (AcadianGY across CSI 8 to 20, to age 120)

| relation | result |
|---|---|
| Site curves (HT-age), ordering, no crossing | PASS |
| Height-diameter | PASS |
| Eichhorn (volume-height, CV 7.3%) | PASS |
| Reineke self-thinning slope (-0.8 vs -1.605) | FLAG |

The strong laws pass. The one real flag, a shallow self-thinning slope, means the model carries
too much density into older stands, the same mechanism that inflates basal area at long horizons.
The Bakuzis Reineke flag and the +11 to +18% BA over-prediction point at the same submodel:
mortality and self-thinning, not the site or height equations.

## Conclusions

1. Adopt the ESI site-input swap. It improves site fidelity, modestly improves height, is safe
   on real CFI growth, and preserves biological ordering. Patch in `scripts/acadiangy_esi_patch.R`.
2. The swap is not a bias fix. AcadianGY over-predicts basal area by +11% overall, +16 to +18%
   at 8 to 15 year horizons, on two independent datasets. The Bakuzis self-thinning flag locates
   the cause in the mortality / self-thinning submodel. This is the MORTCAL / MORTCAL-V territory.
3. Fix the CFI harness flat CSI = 12; Seven Islands true site index is about 14 to 15.
4. Data-quality: the AcadianSIm 2090 raster duplicates 2030; regenerate or relabel before use.

## Run footer

```
[DATA_STATE]: DBHout 990,075 trees scored; Seven Islands 65 routine CFI pairs x 6 site inputs;
  Bakuzis 5 site classes x 120 yr. Metrics resolved to BA bias, height RMSE, Reineke slope.
[OUTCOME_VERIFICATION]: ESI height R2 0.358 -> 0.384, bias +1.87 -> +1.75 m; CFI site lever < 1 pp;
  BA over-prediction +11% (both datasets); Eichhorn PASS, Reineke FLAG -0.8.
[IMPACT_UTILITY]: code change ready for Ben Rice PR; bias finding routes to MORTCAL calibration.
[NEXT_AUTONOMOUS_STEP]: open the AcadianGY PR; obtain corrected 2090 CSI; re-run with true plot
  coordinates if Seven Islands shares them.
```

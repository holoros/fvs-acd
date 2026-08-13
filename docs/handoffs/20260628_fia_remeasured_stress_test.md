# Remeasured Maine FIA stress test: ESI vs CSI vs 2030, with MORTCAL

*28 June 2026. Extends the AcadianGY stress test from the Seven Islands CFI to the remeasured
Maine FIA plots, an independent and much broader sample. Site input (legacy ClimateNA CSI, modern
ESI, 2030-normal CSI) crossed with the MORTCAL mortality correction. AcadianGY 12.3.9. Plaintext
math, no em dashes.*

## Why this matters

Seven Islands CFI is a single ownership in northern Maine. The remeasured FIA plots span the whole
state across all owners and forest types, so they test whether the two key findings generalize:
the site input is a weak lever, and MORTCAL removes the long-horizon basal-area over-prediction.
This run also adds the climate-CSI comparison (current vs 2030) the team asked for, now on FIA.

## Method

- The prior projection-ready validation set was gone, so the remeasurement pairs were rebuilt from
  ME_PLOT and ME_TREE: a current plot with a non-null PREV_PLT_CN gives a t1 to t2 pair, the
  remeasurement period REMPER is the projection interval (kept to 4 to 15 years), and observed t2
  basal area, stems per acre, and QMD come from the live trees at the current measurement. From
  ME_PLOT there are 14,600 remeasurement pairs in Maine; a sample of up to 700 with complete tree
  lists and all three site surfaces was projected.
- Site surfaces at each plot: ESI from the enriched plot frame (and the ESI raster where missing),
  legacy ClimateNA SI, and the 2030-normal Acadian SI, all in meters.
- Each pair was projected its REMPER years under six configurations: site in {legacy CSI, ESI, 2030
  CSI} crossed with MORTCAL {off, on}, and scored on BA, TPA, and QMD bias by horizon.

## Result

SLURM 12091429 (fia_remeas) completed cleanly. 14,600 ME_PLOT remeasurement pairs, 12,949
with observed t2 and a t1 tree list, 694 with all three site surfaces present and projected.
Site means at the 694 plots: ESI 14.69 m, legacy CSI 14.30 m, 2030 CSI 20.18 m. One important
sampling fact governs the read below: every one of the 694 pairs has a remeasurement period of
7 years or less, so all of them fall in the 5 to 7 year horizon bin and the 8 to 11 and 12 to 15
year bins are empty (n = 0). This is the standard Maine FIA panel: the state is on a roughly
5 year remeasurement cycle, so the long horizons that carried the Seven Islands over-prediction
signal do not exist in this sample.

ALL-horizon bias (= the 5 to 7 year result, n = 694), six configurations:

| config | n | BA bias | TPA bias | QMD bias |
|---|---|---|---|---|
| legacy_off | 694 | +3.1% | -8.4% | +6.9% |
| legacy_on | 694 | -3.2% | -15.4% | +7.3% |
| ESI_off | 694 | +3.1% | -8.4% | +6.9% |
| ESI_on | 694 | -3.2% | -15.4% | +7.3% |
| CSI2030_off | 694 | +4.0% | -8.1% | +7.2% |
| CSI2030_on | 694 | -2.3% | -15.1% | +7.6% |

ESI config by horizon, MORTCAL off vs on (only the 5 to 7 year bin is populated):

| config | horizon | n | BA bias | TPA bias | QMD bias |
|---|---|---|---|---|---|
| ESI_off | 5-7yr | 694 | +3.1% | -8.4% | +6.9% |
| ESI_off | 8-11yr | 0 | n/a | n/a | n/a |
| ESI_off | 12-15yr | 0 | n/a | n/a | n/a |
| ESI_on | 5-7yr | 694 | -3.2% | -15.4% | +7.3% |
| ESI_on | 8-11yr | 0 | n/a | n/a | n/a |
| ESI_on | 12-15yr | 0 | n/a | n/a | n/a |

### (a) Site input is still a weak lever

Within each MORTCAL state the three site surfaces are nearly indistinguishable. With MORTCAL
off: legacy +3.1%, ESI +3.1%, 2030 +4.0%, a spread of 0.9 pp across a 6 m swing in mean site
index (14.3 to 20.2 m). With MORTCAL on: legacy -3.2%, ESI -3.2%, 2030 -2.3%, a spread of 0.9 pp.
ESI and legacy CSI are in fact identical to one decimal place on BA, TPA, and QMD, because their
plot means are almost the same (14.69 vs 14.30 m) and the lever is too weak for that small a
difference to register. This reproduces the Seven Islands result exactly: moving site index
across its full plausible range shifts projected stand BA by about 1 pp, no more. The broader
FIA sample confirms the site input is a weak lever.

### (b) MORTCAL on FIA: the long-horizon test is not available here, but the short-horizon
over-correction shows

The headline Seven Islands finding, that MORTCAL removes a long-horizon BA over-prediction
(off near +11 to +15%, on near 0 at 8 to 15 years), cannot be evaluated on this FIA sample,
because the sample contains no long-horizon pairs. Maine FIA remeasures on a roughly 5 year
cycle, so all 694 pairs are 5 to 7 year projections and the over-prediction never has the
projection length it needs to build. What FIA does show is the short-horizon behavior, and it
matches the Seven Islands short-horizon behavior: MORTCAL slightly over-corrects at 5 to 7 years.
With MORTCAL off the model is close to unbiased on BA at this horizon (+3.1% legacy and ESI,
+4.0% 2030); turning MORTCAL on pulls BA down about 6 pp into mild under-prediction (-3.2%,
-3.2%, -2.3%). On Seven Islands MORTCAL was likewise noted to over-correct the 5 to 7 year bin
while fixing the long horizons. So FIA neither confirms nor contradicts the long-horizon claim
(it has no long horizons), but it confirms that MORTCAL is a real and sizeable BA-reducing lever
(about 6 pp) and that at short horizons it over-shoots slightly, consistent with the tuning note
already in the handoff.

### (c) TPA under-prediction and QMD over-prediction: the stem-count gap holds

The stem-count gap seen on Seven Islands is clearly present on FIA. TPA is under-predicted in
every configuration (off -8.1 to -8.4%, on -15.1 to -15.4%) and QMD is over-predicted in every
configuration (+6.9 to +7.6%). The model carries too few stems and makes the survivors too large,
so mean tree size is biased high while stem count is biased low. MORTCAL deepens the TPA
under-prediction by about 7 pp (it is a mortality correction, so it removes additional stems) and
nudges QMD over-prediction up slightly. The BA bias stays small because the two errors partly
offset: too few stems times too-large stems lands near the right basal area. This is the same
signature as Seven Islands and points at the recruitment and ingrowth side of the model, the
second known FVS-ACD problem, rather than at the site input.

### (d) Does the broader FIA sample confirm or contradict Seven Islands

It confirms the parts it is able to test and is silent on the one part it cannot. Confirmed:
the site input is a weak lever (about 1 pp across the full site range, ESI essentially equal to
legacy CSI), MORTCAL is a real BA-reducing lever (about 6 pp) that over-corrects slightly at
short horizons, and the stem-count gap is real (TPA under-predicted, QMD over-predicted). Not
testable: the long-horizon BA over-prediction that is the central Seven Islands result, because
Maine FIA has no 8 to 15 year remeasurement pairs. Nothing in the FIA sample contradicts the
Seven Islands story; the independent, all-owner, statewide sample reproduces every finding that
its 5 year horizon permits and simply lacks the projection length to exercise the long-horizon
claim. The practical conclusion is unchanged: adopt ESI for site fidelity (it costs nothing on
BA), treat the BA bias as equation-driven and address it through MORTCAL plus ingrowth, and read
the long-horizon MORTCAL benefit from the Seven Islands CFI, which is the only one of the two
datasets that reaches those horizons.

## Files

- Script: `scripts/fia_remeas_stress.R`
- Result: `results/seven_islands/acadgy_fia_remeas_stress.csv`

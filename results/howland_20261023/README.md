# Howland Research Forest application, October 23, 2026

Plots: 93 Howland (HL) plots from DigiSylva version 2.0 (Harvard Dataverse, doi:10.7910/DVN/A3EUOQ), live trees of 10 cm DBH or more at the latest measurement, 250 m2 plots, each plot grown in its own call, elevation 60 m, climate site index 10, 12, and 14 m. AGB is Jenkins et al. (2003) dry biomass in Mg/ha. Run on OSC Cardinal (R 4.5.2).

| Model | CSI (m) | 8 yr gross growth | 8 yr mortality | AGB 2033 | AGB 2075 | Plots losing AGB by 2075 |
|---|---|---|---|---|---|---|
| AcadianGY 12.3.6 | 10 / 12 / 14 | 19.4 / 19.2 / 19.1 | 4.8 / 5.3 / 5.7 | 225.1 / 224.4 / 223.8 | 275.7 / 272.8 / 270.5 | not computed |
| v13.1 ship18 (main b314b1c wiring) | 10 / 12 / 14 | 20.1 / 18.6 / 17.3 | 56.2 / 55.5 / 55.0 | 174.8 / 174.0 / 173.0 | 204.5 / 201.6 / 197.5 | 49 / 50 / 54 of 93 |

Initial mean AGB is 210.4 Mg/ha. Two findings. First, growth does not rise with climate site index in either version. In 12.3.6 the stand basal area increment equation has a net negative log(CSI) coefficient (q2 + q4 = -0.016) and SDImax falls with CSI. Second, v13.1 ship18 removes about 35 Mg/ha (17%) in the first annual cycle at these densities, then mortality falls to about 2 Mg/ha/yr, so the 8 year totals are dominated by a first-cycle shock that needs diagnosis (SDI mortality onset 0.55, the form and risk split, or height imputation) before v13.1 is applied to dense Acadian stands. Mortality and gross growth in the v13.1 file come from matching tree ids across cycles after the form and risk split and are approximate; AGB levels are not affected.

## Addendum: FVS-ACD 14.1 (the current release)

Arm v141L: the 14.0.4 L2 engine with the 14.1 overlay, the level term on and the thinning term off (all 93 stands unmanaged), environment copied from the October 16, 2026 cross-version long200 launcher and run through its runner (`acdx_20261016/long200/scripts/2026-10-16_acdx_long200_runner.R`) with `howland_v141_array.slurm`. Site entered as ESI 12, 15, and 18 m. BIOMASS is the runner's biomass output, so its level is not comparable with the Jenkins numbers above; BA and TPH are.

| ESI (m) | Biomass yr 0 / 10 / 50 | BA yr 0 / 10 / 50 (m2/ha) | Cumulative mortality BA by yr 50 | Plots losing biomass by yr 50 |
|---|---|---|---|---|
| 12 | 178.2 / 170.3 / 159.6 | 41.5 / 39.2 / 31.4 | 32.8 | 62 of 93 |
| 15 | 178.2 / 177.9 / 163.4 | 41.5 / 39.0 / 31.2 | 33.5 | 59 of 93 |
| 18 | 178.2 / 185.1 / 167.0 | 41.5 / 38.8 / 30.9 | 34.2 | 55 of 93 |

Version 14.1 has no first-cycle shock and its biomass rises with site index, but it projects basal area falling from 41.5 to about 31 m2/ha over 50 years at Howland, with 55 to 62 of 93 plots losing biomass, which matches the plateau-and-decline behavior the cross-version benchmark flagged for 14.3. Repeat ALS shows Howland gaining about 1 Mg C/ha/yr from 2012 to 2025. None of the 93 stands hit the brms SDImax map or the ecobucket lookup (both keyed to benchmark stands), so those used their fallbacks.

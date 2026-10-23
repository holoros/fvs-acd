# Howland Research Forest application, October 23, 2026

Plots: 93 Howland (HL) plots from DigiSylva version 2.0 (Harvard Dataverse, doi:10.7910/DVN/A3EUOQ), live trees of 10 cm DBH or more at the latest measurement, 250 m2 plots, each plot grown in its own call, elevation 60 m, climate site index 10, 12, and 14 m. AGB is Jenkins et al. (2003) dry biomass in Mg/ha. Run on OSC Cardinal (R 4.5.2).

| Model | CSI (m) | 8 yr gross growth | 8 yr mortality | AGB 2033 | AGB 2075 | Plots losing AGB by 2075 |
|---|---|---|---|---|---|---|
| AcadianGY 12.3.6 | 10 / 12 / 14 | 19.4 / 19.2 / 19.1 | 4.8 / 5.3 / 5.7 | 225.1 / 224.4 / 223.8 | 275.7 / 272.8 / 270.5 | not computed |
| v13.1 ship18 (main b314b1c wiring) | 10 / 12 / 14 | 20.1 / 18.6 / 17.3 | 56.2 / 55.5 / 55.0 | 174.8 / 174.0 / 173.0 | 204.5 / 201.6 / 197.5 | 49 / 50 / 54 of 93 |

Initial mean AGB is 210.4 Mg/ha. Two findings. First, growth does not rise with climate site index in either version. In 12.3.6 the stand basal area increment equation has a net negative log(CSI) coefficient (q2 + q4 = -0.016) and SDImax falls with CSI. Second, v13.1 ship18 removes about 35 Mg/ha (17%) in the first annual cycle at these densities, then mortality falls to about 2 Mg/ha/yr, so the 8 year totals are dominated by a first-cycle shock that needs diagnosis (SDI mortality onset 0.55, the form and risk split, or height imputation) before v13.1 is applied to dense Acadian stands. Mortality and gross growth in the v13.1 file come from matching tree ids across cycles after the form and risk split and are approximate; AGB levels are not affected.

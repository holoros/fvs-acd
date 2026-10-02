# Erratum: row index height gates in PREREG23, PREREG28, PREREG28b and PREREG33

2 October 2026. Issued under PREREG42 (`plan/2026-10-02_v142_rowindex-erratum_PREREG42.md`, md5 55b7b461). It corrects the tag
matched height increment gates of four FVS-ACD 14.2 refinement studies. The original RESULT and verdict files are not edited.
No em dashes.

## What was wrong

The four studies built their tag matched survivor pairs with the PREREG23 height key helper (`2026-09-29_v142_p23_hkey.R`,
59196106), which read the run frames, where the TREE column is a row index rather than the MAGPlot field tag (PREREG37). A
row index pair can join two different trees, so every height increment gate below was computed on partly wrong pairs: 301 tree
pairs on 108 sites of screened qc_c fold B against 737 field tag pairs on 136 sites. Gates that do not use the key (H0, K1,
published TOPHT, C1 %RMSE, basal area, stems and the PREREG33 Bakuzis grid) are not affected.

## Corrected values

Screened qc_c fold B, recomputed with each study's own gate code and the PREREG38 height functions on frozen outputs; the
reference is qc141 (QC_AFAC 0.111) under the same key. Row index values in brackets.

| Study, candidate | Pooled ratio (qc141 0.093 [0.086]) | Bias below 12.7 cm (qc141 -0.190 [-0.254]) | 12.7 to 25 cm (qc141 -0.141 [-0.161]) | 25 cm and over (qc141 -0.120 [-0.021]) | Dominant t2 level (qc141 0.898 [0.922]) |
|:--|:--:|:--:|:--:|:--:|:--:|
| PREREG23, p23_a1061 | 0.898 [0.828] | -0.054 [-0.115] | -0.004 [-0.020] | +0.013 [+0.099] | 0.979 [1.008] |
| PREREG28, p28_cand | 0.973 [0.875] | -0.024 [-0.084] | +0.025 [+0.011] | -0.132 [-0.032] | 0.958 [0.983] |
| PREREG28b, p28b_small | 0.979 [0.883] | -0.024 [-0.084] | +0.025 [+0.011] | -0.120 [-0.021] | 0.961 [0.986] |
| PREREG33, p33_dyn | 0.943 [0.846] | -0.024 [-0.084] | +0.015 [-0.001] | -0.120 [-0.021] | 0.949 [0.975] |

Biases in m yr⁻¹. Bootstrap intervals in `assembled_r2/gyr142-p42-hinc-field_DATA_2026-10-02.csv`.

## Verdicts

| Study | Verdict as published (row index) | Verdict under field tags |
|:--|:--|:--|
| PREREG23 | Rule 3: the 25 cm and over class worse than 0.111 by 0.077 m yr⁻¹ | **Rule 6: every gate passes** (25 cm and over now better than 0.111 by 0.108) |
| PREREG28 | Rule 6 | Rule 6, unchanged (25 cm and over worse by 0.011, inside 0.03) |
| PREREG28b | Rule 6 | Rule 6, unchanged |
| PREREG33 | Rule 3: benchmark passes, Bakuzis non inferiority fails | Rule 3, unchanged |

Three readings follow. First, the PREREG23 rejection of the single anchor 1.061 was a pairing artifact: under field tags it
passes every gate as PREREG23 coded them, and the route PREREG23 opened toward a size dependent anchor rested on that artifact.
Under the stricter PREREG38 restatement (pooled ratio inside 0.90 to 1.10) 1.061 sits just outside at 0.898, so it was not
reopened. Second, PREREG28, 28b and 33 keep their verdicts, but their small tree value 1.265 and large tree value 0.030 were
fitted on row index pairs, so a surviving verdict does not validate the fitted values. Third, the shipped 0.111 under predicts
QC height increment on measured tagged trees by about 90 percent under either key; the error is in the anchor, not in the
pairing.

## Provenance

All values were produced by `scripts/assemble_p42_r2.R` (f74eb057) after reproduction stops: the row index pass reproduces
each study's own published fold B values (worst 4.9e-15) and the field tag pass reproduces the PREREG38 table (worst 4.7e-15).
An independent verifier re-derived the p28_cand, p33_dyn and qc141 values, gates and verdicts from the plan (72 of 72 values,
worst 1.0e-16); the p23_a1061 and p28b_small field tag values were re-derived by the PREREG38 verifier (76 of 76).

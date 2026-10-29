# Provenance of QC_AFAC 0.111: PREREG43 addendum 3 result

5 October 2026. Pre-registration `plan/2026-10-05_v142_qc-anchor-0111-provenance_PREREG43_addendum3.md` (md5 586d6d58),
recorded before the file was read. Two Cardinal commands of the 10 allowed. Records only. No stand identifier left Cardinal.
No coordinates. No em dashes.

## Verdict

**NOT SETTLED under the registered rule, because the New Brunswick check fails; a post hoc reading, not registered, explains
both shipped values exactly.** The file is Cardinal `~/magplot/verify/topht_recal_diag.csv` (343,192 bytes, written 4 July
2026 08:44 EDT, md5 7b68e555, 2,810 stands).

| Province | Stands | Mean observed increment (m/yr) | Mean predicted (m/yr) | Ratio of means | Inverse | Shipped | Mean f |
|:--|--:|--:|--:|--:|--:|--:|--:|
| QC | 2,472 | 0.018220 | 0.161954 | 8.888861 | 0.112500 | 0.111 | 1.100830 |
| NB | 338 | 0.134580 | 0.233168 | 1.732564 | 0.577179 | 0.579 | 1.074969 |

The unrounded inverses round to 0.112 (QC) and 0.577 (NB), so neither shipped value is the inverse of the ratio, and the
registered NB check (inverse rounds to 0.579) fails. Mean f matches the 4 July note (1.101 QC, 1.075 NB), so the file is the
one that note used.

## Post hoc reading (not registered)

The diagnostic prints the two means to three decimals (line 19, `obs HGI %.3f pred HGI %.3f`). The ratio of the printed
values gives both shipped values: QC 0.018 / 0.162 = 0.1111 and NB 0.135 / 0.233 = 0.5794. So 0.111 and 0.579 were most
likely computed by hand from the rounded console means, not from the ratio. The QC mean observed increment, 0.018 m/yr on
2,472 stands, comes from `cb_v1270_results.csv` stand top heights, not from tagged trees; whether those stands match the
qc_c benchmark stands was not checked.

## Consequence

The origin of 0.111 is now as settled as records allow: a hand calculation from rounded diagnostic output on v12.7.0 stand
level top height increments, in which observed Quebec increment was very small. 14.2 is unchanged. No further provenance
search is warranted.

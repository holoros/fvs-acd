# Smith (2022) hardwood form and risk prediction models: extraction and Table A.9 verification

Source: Ryan Smith, MS thesis, University of Maine, 2022. `refs/Ryan_Smith_Thesis_2022.pdf`. Chapter 1 model equations on thesis p. 19 to 21 (pdftotext lines 1230 to 1290), definitions in Table 1.3 (p. 17), coefficient tables in Appendix A (Table A.1 to A.8, p. 101 to 105), observed class counts in Table A.9 (p. 106), and the ClimateNA bioclimatic variable list in Table A.13 (p. 110). Prepared for the FVS-ACD hardwood form/risk work to judge whether the fixed observed-distribution split (Table A.9) can later be upgraded to covariate-based prediction, and whether the required covariates live in a standard FIA or CFI tree list. No em dashes used.

## 1. What the hardwood form and risk models predict

Smith fit four hardwood models, each a binary (binomial) generalized linear mixed model with a logit link. The mixed-effect framework carried random effects for variability among stands and plots; the Appendix reports goodness of fit as AUC in two forms, fixed effects only (FE) and with random effects (RE). Variable selection used VSURF plus AIC. Form class was collapsed to a binary before modeling: ideal form is NHRI F1, and acceptable form is F2 through F8 (thesis p. 16), so equation 1 predicts P(F1). The three risk models predict membership in R1, R2, and R3 as separate binomial responses; R4 was not modeled for hardwoods. Species enters every model as a categorical term (SPP), with American Beech as the omitted reference category, so the intercept applies to American Beech and each listed species coefficient is an offset from it.

The four hardwood equations (thesis eq. 1 to 4), with SPP the species dummy set:

- Eq. 1, P(ideal form F1) = logit^-1( beta0 + beta1 HT + beta2 DD5 + beta3 SPP )
- Eq. 2, P(R1) = logit^-1( beta20 + beta21 (HT/DBH) + beta22 FFP + beta23 SPP )
- Eq. 3, P(R2) = logit^-1( beta30 + beta31 BAL + beta32 FFP + beta33 SPP )
- Eq. 4, P(R3) = logit^-1( beta40 + beta41 log(HT/DBH) + beta42 (Tallest/HT) + beta43 BAL + beta44 SPP )

Equations 5 through 12 are the spruce-fir and other-softwood form and risk models, and 14, 15, 17, 18 are softwood has-sawlog and sawlog-fraction models; none of those are hardwood form or risk, so they are outside the scope here and are not transcribed. The hardwood form/risk set is exactly equations 1 to 4.

## 2. Predictor inventory against the requested checklist

The task asked which of a specific covariate list appears. Reading across the four hardwood models:

- log(DBH) or DBH: does not appear directly in any hardwood form/risk model. DBH enters only through the ratio terms HT/DBH (eq. 2) and log(HT/DBH) (eq. 4).
- HT/DBH: yes. Linear HT/DBH in eq. 2 (R1); log(HT/DBH) in eq. 4 (R3). Note eq. 1 uses HT alone (not the ratio).
- BAL (basal area of larger trees): yes, in eq. 3 (R2) and eq. 4 (R3). One-sided competition metric.
- One-sided competition: yes. BAL is one such metric; additionally eq. 4 uses Tallest/HT, where Tallest is plot-level canopy height defined as the 100 tallest trees per plot (Table 1.3). Both are one-sided competition variables.
- Site index: does NOT appear in any hardwood form/risk model. (A climate site index, CSI, appears only in the softwood sawlog and sawlog-fraction models, eq. 15 and 17, not here.)
- Bioclimatic / climate variables: yes, in three of the four models. DD5 (growing degree-days above 5 C) in eq. 1; FFP (frost-free period) in eq. 2 and eq. 3. Both are ClimateNA products (Table 1.3 and Table A.13, source Wang 2015). Eq. 4 (R3) uses no climate variable.

Chapter text corroborates the split: tree-level variables drove ideal form; tree-level and one-sided competition variables drove R2 and R3; site-level climate variables were significant for ideal form, R1, and R2. Growing degree-days (DD5) had a negative relationship with ideal form; frost-free period had a negative relationship with R1 and a positive relationship with R2.

## 3. Parameter estimates (Appendix A, Tables A.1 and A.2)

All coefficients below transcribed directly from Table A.1 (eq. 1 and 2) and Table A.2 (eq. 3 and 4). Estimates and standard errors are cleanly machine-readable and are reported in full. Species rows are the SPP offsets from the American Beech reference. AUC is reported as (FE, RE).

### Eq. 1, P(ideal form F1), hardwood

| Term | Parameter | Estimate | SE | p-value |
|---|---|---|---|---|
| Intercept (ref = American Beech) | beta0 | 10.2075 | 1.3312 | <.001 |
| HT | beta1 | 0.2268 | 0.0242 | <.001 |
| DD5 | beta2 | -0.0077 | 0.0007 | <.001 |
| Other Hardwoods (OH) | beta3 | -0.5678 | 0.5368 | .290 |
| Paper Birch (PB) | beta3 | -0.2259 | 0.5066 | .656 |
| Quaking Aspen (QA) | beta3 | 2.9417 | 0.5744 | <.001 |
| Red Maple (RM) | beta3 | -1.1916 | 0.4580 | .009 |
| Red Oak (RO) | beta3 | -1.2560 | 0.4987 | .012 |
| Sugar Maple (SM) | beta3 | 0.2249 | 0.5000 | .653 |
| White Ash (WA) | beta3 | -2.0400 | 0.7629 | .008 |
| Yellow Birch (YB) | beta3 | -1.6315 | 0.4751 | <.001 |
| AUC (FE, RE) | | (.67, .78) | (.01, .01) | |

### Eq. 2, P(R1), hardwood

| Term | Parameter | Estimate | SE | p-value |
|---|---|---|---|---|
| Intercept (ref = American Beech) | beta20 | 5.1004 | 2.3168 | .027 |
| HT/DBH | beta21 | 3.2365 | 0.3339 | <.001 |
| FFP | beta22 | -0.0984 | 0.0190 | <.001 |
| Other Hardwoods (OH) | beta23 | 4.7368 | 0.5322 | <.001 |
| Paper Birch (PB) | beta23 | 5.3648 | 0.5048 | <.001 |
| Quaking Aspen (QA) | beta23 | 6.1257 | 0.5599 | <.001 |
| Red Maple (RM) | beta23 | 4.0752 | 0.4506 | <.001 |
| Red Oak (RO) | beta23 | 4.9593 | 0.4853 | <.001 |
| Sugar Maple (SM) | beta23 | 5.2356 | 0.4756 | <.001 |
| White Ash (WA) | beta23 | 5.9764 | 0.7474 | <.001 |
| Yellow Birch (YB) | beta23 | 4.6847 | 0.4651 | <.001 |
| AUC (FE, RE) | | (.66, .76) | (.01, .01) | |

### Eq. 3, P(R2), hardwood

| Term | Parameter | Estimate | SE | p-value |
|---|---|---|---|---|
| Intercept (ref = American Beech) | beta30 | -16.4301 | 1.7821 | <.001 |
| BAL | beta31 | -0.0286 | 0.0641 | <.001 |
| FFP | beta32 | 0.1042 | 1.4976 | <.001 |
| Other Hardwoods (OH) | beta33 | 0.9913 | 0.5085 | .051 |
| Paper Birch (PB) | beta33 | 0.7470 | 0.4777 | .118 |
| Quaking Aspen (QA) | beta33 | -0.4485 | 0.5221 | .390 |
| Red Maple (RM) | beta33 | 1.2499 | 0.4273 | .004 |
| Red Oak (RO) | beta33 | 2.4248 | 0.4637 | <.001 |
| Sugar Maple (SM) | beta33 | 1.1371 | 0.4525 | .012 |
| White Ash (WA) | beta33 | -0.5918 | 0.7150 | .408 |
| Yellow Birch (YB) | beta33 | 1.3419 | 0.4426 | .002 |
| AUC (FE, RE) | | (.67, .73) | (.01, .01) | |

Two caveats on eq. 3 as printed in Table A.2: the BAL standard error (0.0641) is larger than the estimate (-0.0286), and the FFP standard error (1.4976) is far larger than the estimate (0.1042), yet both carry p < .001. These SE values are transcribed exactly as printed but are internally inconsistent with the stated p-values and should be treated with caution; the BAL and FFP point estimates are legible, the SEs may contain a typesetting error in the thesis.

### Eq. 4, P(R3), hardwood

| Term | Parameter | Estimate | SE | p-value |
|---|---|---|---|---|
| Intercept (ref = American Beech) | beta40 | -1.5934 | 0.5806 | .006 |
| log(HT/DBH) | beta41 | -2.2437 | 0.2719 | <.001 |
| Tallest/HT | beta42 | 1.6271 | 0.3206 | <.001 |
| BAL | beta43 | 0.0146 | 0.0087 | <.001 |
| Other Hardwoods (OH) | beta44 | -5.3222 | 0.4091 | <.001 |
| Paper Birch (PB) | beta44 | -5.5906 | 0.3937 | <.001 |
| Quaking Aspen (QA) | beta44 | -5.2242 | 0.4495 | <.001 |
| Red Maple (RM) | beta44 | -4.8419 | 0.3489 | <.001 |
| Red Oak (RO) | beta44 | -6.6592 | 0.3781 | <.001 |
| Sugar Maple (SM) | beta44 | -5.7748 | 0.3781 | <.001 |
| White Ash (WA) | beta44 | -4.6448 | 0.5864 | <.001 |
| Yellow Birch (YB) | beta44 | -5.7313 | 0.3615 | <.001 |
| AUC (FE, RE) | | (.69, .82) | (.02, .01) | |

Note on AUC: the Appendix FE AUC values above (.67, .66, .67, .69 for eq. 1 to 4) differ slightly from the Chapter 1 body text, which reports fixed-effects AUC of 0.65, 0.66, 0.65, and 0.63 for form, R1, R2, and R3. The discrepancy is minor and does not affect the coefficients. Nothing in Tables A.1 or A.2 was unreadable; the full coefficient set extracted cleanly.

## 4. Covariate availability judgment for a standard FIA or CFI tree list

The decisive question is whether the predictors can be assembled from an ordinary tree list without pulling external climate rasters. The tree-level and competition predictors are all derivable in place. HT and DBH are standard tree records (HT often imputed where unmeasured); HT/DBH and log(HT/DBH) are simple derivations; BAL (basal area of larger trees) is computed by ranking the plot's trees by diameter; and Tallest, the mean height of the 100 tallest trees per plot, is a plot-level summary of the same tree list. FIA and CFI both carry the needed inputs for these, subject to height availability.

The climate predictors are not in a tree list. DD5 (growing degree-days above 5 C) and FFP (frost-free period) are ClimateNA outputs (Wang 2015; Table A.13), keyed to plot location and normal period. A standard FIA or CFI tree list does not contain them, so they require an external climate join. For FIA specifically, true plot coordinates are restricted and only fuzzed or aggregated locations are releasable, which further constrains a precise climate join; for CFI the plot coordinates are usually known and the join is straightforward.

Concretely, per model:

- Eq. 4 (R3) can be predicted from a tree list alone. Its predictors are log(HT/DBH), Tallest/HT, BAL, and species, all derivable in place. No external climate data needed.
- Eq. 1 (ideal form) requires DD5, an external ClimateNA variable.
- Eq. 2 (R1) requires FFP, an external ClimateNA variable.
- Eq. 3 (R2) requires FFP, an external ClimateNA variable.

Bottom line: upgrading the split from fixed observed distributions to covariate prediction is feasible only for R3 without external data. Predicting ideal form, R1, and R2, that is three of the four responses, requires attaching two ClimateNA bioclimatic variables (DD5 and FFP) to each plot. Those two variables are the entire external dependency; no other off-tree-list covariate is used (no site index appears in the hardwood models). If a one-time ClimateNA extract keyed to plot coordinates is acceptable and can be produced through the sanctioned outbound-fetch launcher rather than a Claude-initiated fetch, all four models become usable; otherwise only R3 is.

## 5. Table A.9 verification against the R script encoding

The observed NHRI counts encoded in `scripts/hw_formrisk_split.R` (object `.a9`, columns R1 to R4 and F1 to F8, nine species rows AB, PB, QA, RM, RO, SM, WA, YB, OH) were checked cell by cell against Table A.9 of the thesis (p. 106, hardwood block). All 108 counts match exactly, and each species total reconciles (the four risk counts sum to the same Total Trees as the eight form counts).

| Species | R1 | R2 | R3 | R4 | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | Total | Match |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| American Beech | 42 | 52 | 124 | 51 | 133 | 59 | 10 | 34 | 13 | 6 | 7 | 7 | 269 | yes |
| Paper Birch | 423 | 168 | 32 | 32 | 293 | 221 | 14 | 6 | 19 | 23 | 10 | 69 | 655 | yes |
| Quaking Aspen | 352 | 91 | 26 | 31 | 316 | 134 | 0 | 1 | 4 | 4 | 0 | 41 | 500 | yes |
| Red Maple | 1311 | 1132 | 370 | 212 | 1075 | 534 | 26 | 13 | 178 | 51 | 87 | 1061 | 3025 | yes |
| Red Oak | 629 | 975 | 87 | 37 | 667 | 589 | 6 | 0 | 94 | 119 | 60 | 193 | 1728 | yes |
| Sugar Maple | 577 | 269 | 144 | 65 | 750 | 166 | 36 | 5 | 15 | 26 | 31 | 26 | 1055 | yes |
| White Ash | 77 | 35 | 14 | 3 | 53 | 58 | 1 | 0 | 3 | 2 | 5 | 7 | 129 | yes |
| Yellow Birch | 625 | 352 | 149 | 66 | 584 | 248 | 76 | 49 | 60 | 25 | 44 | 106 | 1192 | yes |
| Other Hardwoods | 206 | 159 | 49 | 24 | 188 | 162 | 1 | 2 | 25 | 34 | 7 | 19 | 438 | yes |

The thesis column-total row (TOTAL OBSERVATIONS: R1 4242, R2 3233, R3 995, R4 521, F1 4059, F2 2171, F3 170, F4 110, F5 411, F6 290, F7 251, F8 1529, 8991 trees) also reconciles with the summed rows above. No discrepancy found. The R script encoding of Table A.9 is correct.

One representation caveat worth carrying forward, unrelated to the transcription accuracy: the R script builds the per-tree joint form-by-risk distribution as the outer product of the form and risk marginals, assuming independence, because Table A.9 reports marginals only and not the joint. That independence assumption is a modeling choice in the split, not a data error, and is documented in the script header.

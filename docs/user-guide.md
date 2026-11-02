# AcadianGY 14.1 user guide

## 1. The stack

AcadianGY 14.1 is four R files, each sourced after the one below it. A later layer changes an earlier one only by rebinding named functions, so no file is edited in place.

| Layer | File | What it defines or rebinds |
|:--|:--|:--|
| Base | `AcadianGY_13.1.r` | every component: crown, height, diameter increment, crown recession, mortality, ingrowth, `make_ops`, `make_stand`, and `AcadianGYOneStand` |
| Diameter increment | `model_b0b1b2.r` | the fixed effects b0, b1, and b2 of `ddbh()`, refitted (−1.8837, 0.4979, −0.0293 against −1.6423, 0.3770, −0.0257 in 13.1) |
| Engine | `AcadianGY_14.0.4.r` | three stage linked mortality, the refitted stand basal area increment target, and a small tree increment blend |
| Overlay | `AcadianGY_14.1.r` | the large stem level term L and the thinning release term T on diameter increment |

`load_acd141()` in `engine/load_acd141.R` checks each file and both coefficient bundles by md5, points `model_b0b1b2.r` at the repository copy of 13.1 (the file itself names a Cardinal path), sets the three refitted values the benchmark used, and sources the stack into the global environment. Call it with `benchmark_ddbh = FALSE` to keep the 13.1 values of b0, b1, and b2.

After loading, `AcadianVersionTag` reads AcadianV14.0.2. The tag is inherited and does not identify the release, so cite the md5 sums in `CHANGELOG.md` instead.

## 2. Calling the engine

`AcadianGYOneStand(tree, stand, ops)` advances one stand by one year and returns the new tree list, so a projection is a loop over years. The component functions read `ops` and `stand` from the global environment rather than from their arguments. A run is correct only when the global `ops` and `stand` are the objects passed in, so assign both globally, and when looping over stands reassign `stand` for each one. The 13.1 wrapper `Acadian.GY()` never reassigns `stand` and should not be used for several stands. `examples/ten_year_projection.R` follows these rules.

## 3. Inputs

### 3.1 Tree list

One row per tree record. The engine computes basal area in larger trees and plot summaries itself.

| Column | Units | Notes |
|:--|:--|:--|
| `year` | yr | step counter, advanced by 1 each call |
| `plot` | none | plot within the stand; plot level quantities are computed per plot |
| `tree` | none | unique within the stand; recruits take ids above the plot maximum |
| `sp` | none | two letter FVS-ACD code: AB, AS, BA, BC, BF, BP, BS, BT, EC, EH, GA, GB, HH, JP, NS, OH, OS, PB, PC, PR, QA, RB, RM, RN, RO, RS, SB, SM, ST, TA, WA, WC, WP, WS, YB, or 99; map anything else to OH or OS |
| `dbh` | cm | diameter at 1.37 m |
| `ht` | m | NA, 0, or above 50 is replaced by predicted height when `dbh` exceeds 2.5 cm |
| `hcb` | m | NA or above `ht` is replaced by predicted height to crown base |
| `cr` | proportion | NA, 0, or above 99 is recomputed as 1 − `hcb`/`ht` |
| `expf` | trees ha⁻¹ | per hectare on that plot, not divided by the number of plots |
| `form`, `risk` | none | hardwood form and risk classes, NA when absent |
| `ddbh.mult`, `dht.mult`, `mort.mult` | none | calibration multipliers, 1 for none |
| `max.dbh`, `max.height` | cm, m | size caps, 200 and 50 in the benchmark |

A stem of 2.5 cm or less with no height keeps an NA height and grows no diameter, so supply its height or drop it. Recruits are appended with NA in the five calibration columns, and an NA multiplier gives an NA increment, so refill those columns after every step.

### 3.2 Stand

`make_stand(stand.id, csi = 12, elev = 350, region = "ME", esi = NA)` returns a one row data frame. `csi` (m) is the site index used by every growth function, and a finite `esi` replaces it. `elev` (m) enters maximum SDI. `region` is ME, NB, NS, or QC and selects the jurisdiction effect of the linked mortality. The benchmark used ESI version 8 where available and 14 m otherwise. The 14.0.4 basal area increment target ignores site index, while diameter increment, height increment, height prediction, and ingrowth still use it.

### 3.3 Stand history on `ops`

Two stand facts live on `ops` and are set before every call. `ops$stand.managed` sets the management term of the linked mortality. `ops$stand.tst` is the number of years since the last commercial thinning at the start of the step, advanced by 1 each year. T is applied only where `stand.tst` is finite and at least 0, and is never applied by guessing a thinning date. Give `stand.tst` only for commercial thinnings, since T treats any removal as a thinning (Section 6).

## 4. Release configuration

Every switch is a field of `ops`, the one row data frame from `make_ops()`. The defaults of `make_ops()` leave the linked mortality and both 14.1 terms off, so the release configuration must be set explicitly, as below and in the example.

| `ops` field | Default | Release | Effect |
|:--|:--|:--|:--|
| `use.linked.mortality` | FALSE | TRUE | three stage linked mortality replaces the 13.1 mortality |
| `linked.mortality.mode` | L2 | L2 | linkage form |
| `linked.coef.file` | NA | `coef/v14_coef_bundle_2026-09-08.rds` | mortality coefficients |
| `use.dba.v1404` | TRUE | TRUE | refitted basal area increment target, *k* fixed at 90 m² ha⁻¹, no site term |
| `use.smalltree.dg` | FALSE | FALSE | small tree increment blend |
| `use.lsdg.v141` | FALSE | TRUE | level term L |
| `use.thin.v141` | FALSE | TRUE | thinning release term T, applied after L |
| `v141.coef.file` | NA | `coef/v141_option3_offline_coefs_r5_2026-09-23.rds` | L and T coefficients |
| `v141.rel.cap` | NA | 2.9848 | cap on *d*/*D*_q inside T; must be set, or a run with T on stops |
| `ingrowth.min.dbh` | 3.0 cm | 5.0 cm | diameter at which recruits enter |
| `ingrowth.mult` | 1 | 2.5 | multiplier on recruits ha⁻¹ yr⁻¹ |
| `use.ddbh.standcon` | FALSE | TRUE | lowers the activation of the Chapter 10 stand constraint |
| `ddbh.standcon.lo`, `.hi`, `.qmin` | 0.6, 0.8, 0 | 0.35, 0.45, 18 cm | activation fractions of 64.46 m² ha⁻¹ and the QMD floor |

L multiplies predicted annual diameter increment by 1 + (λ − 1)*s*(*d*), where *s* rises from 0 at 12.7 cm to 1 at 15.0 cm, so L leaves small stems untouched by construction. T multiplies it by 1 + α exp(−β *t*)(min(*d*/*D*_q, cap))^γ, where *t* is `stand.tst` and *D*_q is the quadratic mean diameter of the whole tree list. The shipped coefficients are λ 1.149 (0.926 to 1.376), α 0.371 (0.124 to 0.649), β 0.0822 (0.0075 to 0.2048), and γ 2, fixed. L was fitted on CTRN and BAXTER and T on 119 CTRN thinning locations in 17 installations, all in Maine.

The benchmark runner also set `dht.mult` to 0.579 for New Brunswick and 0.111 for Quebec stands and split hardwood form and risk classes with `split_formrisk()` before projecting. Neither step is in the example. Both helpers are at the archive tag in `engine/cardinal_frozen_20261019/`.

## 5. Outputs

Each call returns the tree list with `year` advanced by 1 and `dbh`, `ht`, and `hcb` including the year's increments, plus `pht` and `phcb`, the predicted height and height to crown base at the start of the step. Records are never dropped. Mortality lowers `expf` to a floor of 0.00001 trees ha⁻¹, so stand totals are weighted sums. The engine returns no stand table and no volume.

`.acd_v141_report()` counts the stems on which L and T acted since the last `.acd_v141_reset()`. A run with T on in which nearly every thinning call was skipped has not tested T.

The example run of November 2, 2026 returned 350 calls for each term, none skipped and none at the cap, and the stand moved from 1,260 trees ha⁻¹, 18.7 m² ha⁻¹, and 13.8 cm QMD at year 0 to 1,297 trees ha⁻¹, 25.5 m² ha⁻¹, and 15.8 cm at year 10.

## 6. Domain of use and limitations

14.1 is built for Maine, New Brunswick, Nova Scotia, and Quebec. The 14.0.4 basal area increment target was fitted on CSI of 15.6 to 21.2 m, and the release support of T is 1 to 17 yr since thinning. Lambda's interval covers 1, so L cannot be separated from the identity. Gate GT1 fails and the failure stands, since the implied release half life of 3.4 to 92.2 yr exceeds the 3 to 50 yr the gate requires. The data fix the sign of the release decay but not its rate.

The October 16, 2026 cross-version benchmark found 14.1 the best ten year model across 19 frozen benchmark sets, with a median absolute biomass bias of 3.8% against 9.6% for 13.1h. It also found three limitations in Maine.

- T overstates recovery after harvest. On 827 post-harvest Maine FIA stands, 14.1 overpredicts annual biomass change after heavy removals by 1.39 Mg ha⁻¹ yr⁻¹, double the observed rate, since T appears to treat an overstory removal as a thinning.
- 14.x declines over long horizons. Over 200 yr without harvest, 14.1 declines in 64 to 84% of 918 unmanaged Maine FIA stands in each of six forest types, while the FIA record shows a peak only in spruce-fir.
- Growth falls short on unmanaged stands. 14.1 underpredicts basal area by 8.4% and total volume by 12.2% on unmanaged Maine FIA stands, with QMD low by about 10%. Every version shares this shortfall.

Read the cross-version benchmark, at the archive tag in `docs/benchmarks/2026-10-16_cross-version/`, before using 14.1 for projections of 100 yr or longer.

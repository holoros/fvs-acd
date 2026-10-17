# AcadianGY 14.1 user guide

AcadianGY 14.1, the R implementation of the Acadian variant of the Forest Vegetation Simulator (FVS-ACD). Written October 17, 2026 from the engine files on branch `engines-14.1-20260924`: `scripts/AcadianGY_13.1.r`, `scripts/AcadianGY_14.0.4.r`, `scripts/AcadianGY_14.1.r` and `scripts/phaseD/2026-09-25_v141_phaseD_runner_p23_tst.R`. Every default below was read from those files. Statements that the code cannot settle are marked [UNVERIFIED].

## 1. What 14.1 is

14.1 is not one file. It is a stack of R scripts. Each layer is sourced after the one below it and changes the layer below only by rebinding named functions. Nothing is edited in place.

| Layer | File | What it rebinds |
|:--|:--|:--|
| Base | `AcadianGY_13.1.r` (model of record) | defines every component: crown, height, diameter increment, crown recession, mortality, ingrowth, `make_ops`, `make_stand`, `AcadianGYOneStand` |
| 14.x base (benchmark only) | `p4e/model_b0b1b2.r`, not in the repository | per its launcher variables, replaces the fixed effects b0, b1 and b2 of `ddbh()` [UNVERIFIED] |
| Engine | `AcadianGY_14.0.4.r` | `calc_mortality` (linked three stage mortality), `plot_ba_incr` (refitted stand basal area increment target), `ddbh` and `calc_ddbh` (small tree blend), `make_ops` |
| Overlay | `AcadianGY_14.1.r` | `ddbh`, `calc_ddbh` and `make_ops` again, adding the level term L and the thinning release term T |

Sourcing order is fixed. You source 14.0.4, and 14.0.4 sources its own base: the path in the environment variable `ACD_V14_BASE` if it is set, otherwise `~/AcadianGY_13.1.r` if that file exists, otherwise `AcadianGY_13.1_DRAFT.r` in the working directory. The third fallback is a different, older file, and `scripts/` contains it, so always set `ACD_V14_BASE`. You then source 14.1, which stops with an error unless 14.0.4 is already loaded.

With both 14.1 gates FALSE the stack is 14.0.4 exactly; with `use.dba.v1404 = FALSE` 14.0.4 is 14.0.3; with `use.linked.mortality = FALSE` the mortality is that of 13.1. Note that the defaults of `make_ops()` are not the release configuration: they leave the linked mortality and both 14.1 terms off. `AcadianVersionTag` reads `AcadianV14.0.2` after 14.1 loads, so identify the stack by md5 (Section 7).

## 2. How the engine is called

`AcadianGYOneStand(tree, stand, ops)` advances one stand by one year and returns the new tree list. A projection is a loop over years. The function's `ops` and `stand` arguments are used by only part of the code. The component functions (`calc_ddbh`, `calc_dht`, `calc_ingrowth`, the 14.0.4 mortality wrapper and both 14.1 terms) take their defaults from objects named `ops` and `stand` in the global environment, by lexical scoping. A run is therefore correct only when global `ops` and `stand` are the objects you pass. The benchmark runner assigns both with `<<-`. If you drive the engine from inside a function, do the same.

Two consequences follow. `Acadian.GY()`, the 13.1 multi-stand wrapper, never reassigns global `stand`, so loop over stands yourself and assign it for each one. The self-tests `.acd_v14_selftest()` and `.acd_v141_selftest()` toggle gates on local copies of `ops` that the gated functions never see, so they do not test the toggles.

## 3. Inputs

### 3.1 Tree list

One row per tree record. The engine joins species attributes, computes basal area in larger trees and plot summaries itself.

| Column | Type | Units | Notes |
|:--|:--|:--|:--|
| `year` | numeric | yr | step counter; advanced by 1 each call |
| `plot` | integer | none | plot within the stand; every plot-level quantity is computed per plot |
| `tree` | integer | none | unique within the stand; ingrowth takes new ids above the plot maximum, and the linked mortality uses ids to identify recruits |
| `sp` | character | none | two letter FVS-ACD code (below) |
| `dbh` | numeric | cm | diameter at 1.37 m |
| `ht` | numeric | m | NA, 0 or above 50 is replaced by predicted height when `dbh` > 2.5 cm |
| `hcb` | numeric | m | NA or above `ht` is replaced by predicted height to crown base |
| `cr` | numeric | proportion | NA, 0 or above 99 is recomputed as 1 - hcb / ht |
| `expf` | numeric | trees ha⁻¹ | per hectare on that plot, not divided by the number of plots |
| `form`, `risk` | character | none | hardwood form and risk classes; NA_character_ when absent |
| `ddbh.mult`, `dht.mult`, `mort.mult` | numeric | none | calibration multipliers; 1 for none |
| `max.dbh`, `max.height` | numeric | cm, m | size caps; the benchmark uses 200 and 50 |

Two practical rules follow from the code. A stem of 2.5 cm or less with no height keeps NA height and grows no diameter, so supply its height or drop it (`ops$use.htgap.fix`, default FALSE, is the 13.1 alternative). Ingrowth records are appended with NA in the five calibration columns, and an NA multiplier gives NA increment, so refill them after every step as the worked example does.

Species codes are those of the `sp.attr` table in 13.1: AB, AS, BA, BC, BF, BP, BS, BT, EC, EH, GA, GB, HH, JP, NS, OH, OS, PB, PC, PR, QA, RB, RM, RN, RO, RS, SB (sweet birch), SM, ST, TA, WA, WC, WP, WS, YB and 99. Map anything else to OH or OS, as the runner does. The linked mortality maps 32 codes to its stage 3 species effects (RN and PR as aliases of RP and PC) and evaluates the rest at the population level.

### 3.2 Stand

Build the stand with `make_stand(stand.id, csi = 12, elev = 350, region = "ME", esi = NA_real_)`. It returns a one-row data frame with `stand.id`, `csi`, `elev`, `region` and `site.source`.

| Field | Units | Notes |
|:--|:--|:--|
| `stand.id` | none | character; the linked mortality resets its recruit record when it changes |
| `csi` | m | site index used by every growth function; when `esi` is finite, `make_stand` stores ESI here and sets `site.source` to "ESI" |
| `elev` | m | used in maximum SDI |
| `region` | none | ME, NB, NS or QC; selects the jurisdiction effect of the linked mortality and the spruce budworm parameters |

The benchmark used ESI version 8 where available (values above 2 m) and 14 m otherwise. Since 14.0.4 the stand basal area increment target ignores site index. Site still enters diameter increment, height increment, height prediction and ingrowth.

### 3.3 Stand state fields on `ops`

Two stand facts live on `ops`, not on `stand`, and the caller sets both before every call.

`ops$stand.managed` (logical) sets the management term of the linked mortality. When it is NA or absent the engine infers 1 from `ops$mgmt.class` of PLANTED or PCT, or from a non-NA `ops$thin.year`, and 0 otherwise. The benchmark runner refuses to guess. It takes a per stand MANAGED column, then a stand file, then a source level value, and stops when none is given.

`ops$stand.tst` is the number of years since the last thinning at the start of the current step, advanced by 1 each projection year. T is applied only where it is finite and at least 0. When it is NULL, NA or negative, T is not applied and the skipped stems are counted. The runner contract is that T is never applied by guessing a thinning date. The runner takes the value from a per stand TST column, then a TST_FILE, then a source level SRC_TST, passes NEVER and UNKNOWN to the engine as NA, and stops when `THIN_V141=1` and no source is set. An interval whose thinning year falls on or after its start is supplied as UNKNOWN, because it contains the removal rather than a release.

## 4. Switches

Each switch is a field of `ops`, the one-row data frame from `make_ops()`. The 14.0.4 and 14.1 fields can also be set by environment variables, read when `make_ops()` is called. The benchmark column is the `v141LT` arm of the 14.1 benchmark launcher (copied verbatim into `docs/benchmarks/2026-10-16_cross-version/scripts/cardinal/postharv/2026-10-16_mefia_ph_array.sbatch`) as the runner turns it into `ops`.

### 4.1 14.1 overlay

| `ops` field | Environment | Default | Benchmark | Effect |
|:--|:--|:--|:--|:--|
| `use.lsdg.v141` | `LSDG_V141` | FALSE | TRUE | level term L on the annual diameter increment |
| `use.thin.v141` | `THIN_V141` | FALSE | TRUE | thinning release term T, applied after L |
| `v141.coef.file` | `V141_COEF` | NA | r5 bundle | lambda, alpha, beta, gamma, d_lo, d_hi |
| `v141.rel.cap` (ratio) | `V141_RELCAP` | NA | 2.9848 | cap on d / Dq inside T |
| `v141.d.lo`, `v141.d.hi` (cm) | `V141_DLO`, `V141_DHI` | 12.7, 15.0 | 12.7, 15.0 | smoothstep limits of L, used only without a coefficient file |
| `v141.lambda`, `v141.alpha`, `v141.beta`, `v141.gamma` | none | absent | not used | scalar coefficients when no file is named |

L is m_L(d) = 1 + (lambda - 1) s(d), where s is 0 below d_lo, 1 above d_hi, and the smoothstep 3u² - 2u³ between, with u = (d - d_lo) / (d_hi - d_lo). L is the identity below d_lo by construction. The code applies L to every stand, whatever its management flag. T is m_T = 1 + alpha exp(-beta tst) (min(d / Dq, cap))^gamma, where Dq is the quadratic mean diameter of the whole current tree list, all plots pooled. Both multiply the output of `ddbh()`, before the base modifiers, the Chapter 10 stand constraint and the size cap. Stems below 1.3716 m keep zero increment.

Three code behaviors matter here. When a coefficient file is named, d_lo and d_hi come from the file and `V141_DLO` and `V141_DHI` have no effect. The cap must be set explicitly: the r5 file carries rel_cap 2.98478, but `make_ops()` stores `v141.rel.cap` as NA rather than NULL, so the file value is never reached, and T with no finite cap stops the run (gate GT6). A gate set to TRUE with a missing coefficient also stops the run rather than falling back to the identity.

The shipped r5 coefficients are lambda 1.14863 [0.92637, 1.37565], alpha 0.37109 [0.12383, 0.64890], beta 0.08220 [0.00752, 0.20480] and gamma 2, fixed. L was fitted on CTRN and BAXTER and T on the CTRN thinnings alone (119 locations in 17 installations), all in Maine.

### 4.2 14.0.4 engine

| `ops` field | Environment | Default | Benchmark | Effect |
|:--|:--|:--|:--|:--|
| none | `ACD_V14_BASE` | see Section 1 | `p4e/model_b0b1b2.r` | base file sourced by 14.0.4 |
| `use.linked.mortality` | `LINKED` | FALSE | TRUE | three stage linked mortality replaces the 13.1 `calc_mortality`; `make_ops()` also sets `use.sdimort` to FALSE |
| `linked.mortality.mode` | `LINKED_MODE` | "L2" | "L2" | L1, L2 or L3 linkage |
| `linked.coef.file` | `LINKED_COEF` | NA | `v14_coef_bundle_2026-09-08.rds` | mortality bundle; the run stops if the lever is on and the file is missing |
| `linked.stage3.species.re` | `LINKED_SPRE` | TRUE | TRUE | stage 3 species conditional modes |
| `linked.jurisdiction.re` | `LINKED_JURRE` | TRUE | TRUE | jurisdiction conditional modes from `stand$region` |
| `linked.use.mortmult` | `LINKED_MORTMULT` | FALSE | FALSE | apply `mort.mult` to the linked kill |
| `linked.fix.threshold`, `.floordomain`, `.pool`, `.s3offset`, `.stepinv`, `.pscale` | `LINKED_FIX1` to `FIX5`, `FIX1B` | TRUE, FALSE, TRUE, TRUE, TRUE, FALSE | same | lever repairs of 14.0.2 and 14.0.3; pscale is ablation only and stops if set with stepinv |
| `linked.threshold.dref` (yr) | `LINKED_DREF` | 5 | 5 | reference interval for fixes 1, 3 and 5 |
| `use.dba.v1404` | `DBA_V1404` | TRUE | TRUE | refitted Verhulst target, k fixed at 90 m² ha⁻¹, no site term |
| `use.smalltree.dg` | `SMALLTREE` | FALSE | FALSE | small tree increment blend; needs `smalltree.coef.file`; bounds 8.25 and 12.7 cm, read at 5 yr |

### 4.3 13.1 base fields the benchmark sets

The runner builds `ops` with `make_ops(verbose = FALSE, use.ingrowth = TRUE, ingrowth.min.dbh = 5.0, ingrowth.thrshld = 0, use.cap.dbh = TRUE, use.cap.ht = TRUE, use.hw.mod = FALSE, use.sbw.mod = FALSE, use.thin.mod = FALSE, use.vol = FALSE)` and then sets the fields below. Fields the code does not read are listed at the end.

| `ops` field | Default | Benchmark | Effect |
|:--|:--|:--|:--|
| `ingrowth.min.dbh` (cm) | 3.0 | 5.0 | diameter at which recruits enter |
| `ingrowth.thrshld` | 0 | 0 | ingrowth probability cut point |
| `ingrowth.mult` | 1 | 2.5 | multiplier on recruits ha⁻¹ yr⁻¹ |
| `use.ingrowth.release` | TRUE | TRUE | logistic release of ingrowth in relative density |
| `ingrowth.rd.center`, `ingrowth.rd.k` | 0.58, 8 | 0.58, 8 | centre and slope of that release |
| `use.ddbh.standcon` | FALSE | TRUE | lever 3b, lowers the activation of the Chapter 10 constraint |
| `ddbh.standcon.lo`, `.hi`, `.qmin` (none, none, cm) | 0.6, 0.8, 0 | 0.35, 0.45, 18 | activation fractions of 64.46 m² ha⁻¹ and the QMD floor |
| `use.mortcal`, `sdimax.site.term`, `use.esi.domht` | FALSE | FALSE | MORTCAL haircut, site term in SDImax, ESI height anchor |
| `use.hier.ingrowth`, `use.hier.mortality` | FALSE | FALSE | 13.1 hierarchical posteriors |
| `use.thin.mod`, `use.hw.mod`, `use.sbw.mod`, `use.mgmt.mod` | FALSE | FALSE | 13.1 thinning, hardwood form and risk, budworm and management modifiers |

The Chapter 10 constraint activates against the published k = 64.45952 m² ha⁻¹, although the 14.0.4 target uses k = 90. Under the benchmark lever 3b settings it binds above 22.6 m² ha⁻¹ on plots with QMD of at least 18 cm and above 38.7 m² ha⁻¹ elsewhere, only where the free tree increment exceeds the target. No claim is made for lever 3b either way.

The benchmark runner also sets per tree `dht.mult` on the initial list to 0.579 for NB stands and 0.111 for QC stands, a multiplier on annual height increment. Recruits receive 1 when the runner refills NA multipliers. Under `LINKED=1` the SDImax self-thinning block is off, so the runner's `sdimort.*` settings (ONSET 0.55 and the rest) have no effect. The runner also sets `use.brms.sdimax`, `brms.sdimax.map`, `use.esi.anchor.recal`, `esi.anchor.coef`, `sdimort.break.region` and `ingrowth.mult.region`. None of 13.1, 14.0.4 or 14.1 reads any of them. Whether `model_b0b1b2.r` reads the brms fields is [UNVERIFIED]. `use.vol` is not read by `AcadianGYOneStand`.

Finally, the benchmark applied `split_formrisk()` from `hw_formrisk_split.R` once to each initial list (`SPLIT=TRUE`). That helper is not in the repository, and its effect on the tree list is [UNVERIFIED].

## 5. A ten year projection

**Not yet run.** The script below was checked against the signatures of `make_ops`, `make_stand` and `AcadianGYOneStand` and against the 14.1 runner contract. It runs the benchmark configuration on an invented single plot stand, using only repository files. It differs from the benchmarked 14.1 in one known respect: the base is the repository's 13.1, so the diameter increment fixed effects b0, b1 and b2 are the 13.1 values (-1.6423, 0.3770, -0.0257), not the benchmark's (-1.8837, 0.4979, -0.0293).

```r
library(dplyr); library(purrr)
setwd("~/fvs-acd")   # a checkout of branch engines-14.1-20260924

f <- c(base  = "scripts/AcadianGY_13.1.r",
       e1404 = "scripts/AcadianGY_14.0.4.r",
       e141  = "scripts/AcadianGY_14.1.r",
       mort  = "data/v14/v14_coef_bundle_2026-09-08.rds",
       opt3  = "data/v14/option3/v141_option3_offline_coefs_r5_2026-09-23.rds")
want <- c("6ec1823690ab6756b11e4f6fc684a325", "61f95d99f896e8e513930d6e33a7391a",
          "0bf27dde81240e6bdf59c9a90f0051bd", "4740de88af8231677d828dec8e5b753c",
          "c8f02f5841e98b93cb532b6fa9b1fc51")
stopifnot(identical(unname(tools::md5sum(f)), want))

Sys.setenv(ACD_V14_BASE = normalizePath(f[["base"]]))   # read when 14.0.4 is sourced
source(f[["e1404"]])
source(f[["e141"]])

# global ops, the benchmark configuration
ops <- make_ops(use.ingrowth = TRUE, ingrowth.min.dbh = 5.0, ingrowth.thrshld = 0,
                use.cap.dbh = TRUE, use.cap.ht = TRUE,
                use.linked.mortality = TRUE, linked.mortality.mode = "L2",
                linked.coef.file = f[["mort"]], linked.stage3.species.re = TRUE,
                use.dba.v1404 = TRUE, use.smalltree.dg = FALSE,
                use.lsdg.v141 = TRUE, use.thin.v141 = TRUE,
                v141.coef.file = f[["opt3"]], v141.rel.cap = 2.9848)
ops$ingrowth.mult      <- 2.5
ops$use.ddbh.standcon  <- TRUE
ops$ddbh.standcon.lo   <- 0.35
ops$ddbh.standcon.hi   <- 0.45
ops$ddbh.standcon.qmin <- 18
ops$use.mortcal        <- FALSE
ops$stand.managed      <- TRUE

# global stand; ESI 15.5 m replaces csi
stand <- make_stand(stand.id = "demo", csi = 14, elev = 200, region = "ME", esi = 15.5)

tree <- data.frame(year = 0, plot = 1L, tree = 1:8,
  sp   = c("BF", "BF", "RS", "RS", "RM", "PB", "WP", "EH"),
  dbh  = c(6.5, 11.2, 14.8, 21.3, 17.9, 13.4, 31.0, 24.6),
  ht = NA_real_, hcb = NA_real_, cr = NA_real_,
  expf = c(420, 310, 180, 95, 120, 70, 25, 40),
  form = NA_character_, risk = NA_character_,
  ddbh.mult = 1, dht.mult = 1, mort.mult = 1, max.dbh = 200, max.height = 50,
  stringsAsFactors = FALSE)

refill <- function(x) {             # recruits arrive with NA multipliers and caps
  for (v in c("ddbh.mult", "dht.mult", "mort.mult")) x[[v]][is.na(x[[v]])] <- 1
  x$max.dbh[is.na(x$max.dbh)] <- 200
  x$max.height[is.na(x$max.height)] <- 50
  x
}

tst0 <- 6          # years since the last thinning, from a treatment record; NA if unknown
.acd_v141_reset()
cur <- tree; traj <- vector("list", 10)
for (yr in 1:10) {
  ops$stand.tst <- if (is.na(tst0)) NA_real_ else tst0 + (yr - 1)
  cur <- refill(AcadianGYOneStand(tree = cur, stand = stand, ops = ops))
  traj[[yr]] <- cur
}
print(.acd_v141_report())

smry <- dplyr::bind_rows(tree, traj) %>%
  dplyr::group_by(year) %>%
  dplyr::summarise(tph = sum(expf), ba = sum(pi * (dbh / 200)^2 * expf),
                   qmd = sqrt(ba / tph / (pi / 40000)), .groups = "drop")
smry
```

For an unmanaged stand with no thinning record, set `ops$stand.managed <- FALSE` and `tst0 <- NA`. L still acts and T is the identity. For several stands, run the loop once per stand and reassign global `stand` each time. With the 14.1 gates FALSE, the same script is the `v141off` arm, which the October 16 benchmark labels 14.0.4 L2.

## 6. Outputs

Each call returns a data frame with the `ops$rtn.vars` columns that exist: `year`, `plot`, `tree`, `sp`, `dbh`, `ht`, `hcb`, `cr`, `expf`, `pht`, `phcb`, `form`, `risk`, the three multipliers, `max.dbh` and `max.height`. `year` has advanced by 1, and `dbh`, `ht` and `hcb` include the year's increments. `pht` and `phcb` are the predicted height and height to crown base at the start of the step. Records are never dropped: mortality lowers `expf`, which is floored at 0.00001 trees ha⁻¹, so stand totals are weighted sums and dead records persist. Recruits are appended with new `tree` ids at `ingrowth.min.dbh` with predicted height and crown.

The engine returns no stand table and no volume. `Summary.GY()` needs a `stand` column the output lacks, and `calc_tree_volume()` gives taper volume in m³. The benchmark scored volume and biomass with an NSVB emulator whose coefficients are not in the repository.

The 14.1 counters accumulate across calls until `.acd_v141_reset()`. `.acd_v141_report()` returns `level_term_calls`, `thinning_term_calls`, `thinning_skipped_no_tst`, `thinning_calls_at_cap` and `max_rel_dq_seen`, counted in stems. A run with THIN on and nearly all thinning calls skipped has not tested T.

## 7. Verifying the files

The md5 sums stated in VERSION_HISTORY Eras 7 and 8 are these.

| File | md5 |
|:--|:--|
| `data/v14/v14_coef_bundle_2026-09-08.rds` | 4740de88af8231677d828dec8e5b753c |
| `data/v14/v14_coef_bundle_2026-09-08_L2default.rds` | 655ef0117b3531651978f230d82d61fa |
| `data/v14/smalltree/smalltree_coef_bundle_2026-09-17.rds` | 69c423dc3adb142b16aae1bfede0359d |
| `data/v14/dba/v1404_dba_coef_FINAL_2026-09-17.rds` (provenance only; the engine carries the coefficients inline) | 87c3ba213271d79683415013a58353f3 |
| `data/v14/option3/v141_option3_offline_coefs_r5_2026-09-23.rds` | c8f02f5841e98b93cb532b6fa9b1fc51 |
| `scripts/phaseD/2026-09-25_v141_phaseD_runner_p23_tst.R` | 8471121e3a880e838b42923250a94cdd |
| `AcadianGY_14.0.3_mortonly.r` (identity reference) | af33056cd79f93055f5438e001795f10 |
| `docs/v14.1/2026-09-25_v141_option3_engine_gates_PREREG2_r5.md` | 1f149a0faadfebc0e640f5ffb129e91e |

VERSION_HISTORY gives no md5 for the engine scripts themselves. The benchmark README (`docs/benchmarks/2026-10-16_cross-version/README.md`) gives 61f95d99f896e8e513930d6e33a7391a for 14.0.4, 0bf27dde81240e6bdf59c9a90f0051bd for 14.1, and 5894df6013c701d09e7ba67ba6c2f090 for the Cardinal copy of 13.1. The files on branch `engines-14.1-20260924` match the first two, and every md5 in the table above matches the branch. The branch copy of 13.1 hashes to 6ec1823690ab6756b11e4f6fc684a325. It differs from the Cardinal copy only in line 17, which reads `AcadianV13.2` instead of `AcadianV13.1` (commit e9527d7), and reverting that line gives 5894df60. The `scripts/AcadianGY_13.1.r` on `main` is an older 4,842 line file and should not be used.

To check, run `md5sum <file>` on Linux, `md5 -q <file>` on macOS, `tools::md5sum(<files>)` in R, or `git show origin/engines-14.1-20260924:<path> | md5sum` without a checkout. The benchmark launchers check every md5 before running and stop on a mismatch, and the worked example does the same.

## 8. Domain of applicability and known limitations

The engine is built for the four jurisdictions ME, NB, NS and QC, and the linked mortality carries an effect for each. The Maine jurisdiction effect of the linked mortality (+0.647, the largest of the four) rests on CTRN alone, dataset and ecoregion effects are evaluated at the population level, and a recruit is immortal in its entry year.

The 14.0.4 basal area increment target does not respond to site index. Its fit frame spans CSI 15.58 to 21.18 m only.

L was fitted on CTRN and BAXTER and T on CTRN alone, all in Maine. Lambda's interval covers 1, so L is not separable from the identity at that level. Gate GT1 fails and the failure stands. GT1 requires the implied release half-life ln(2) / beta to lie between 3 and 50 yr. The fit gives 3.38 to 92.21 yr. The data fix the sign of the release decay but not its rate. The release support is 1 to 17 yr since thinning, and over 50 yr the two terms take the largest projected diameter from 53.0 to 70.2 cm. On thinned CTRN stands 14.1 under predicts survivor increment above 12.7 cm over 5 to 20 yr intervals and over predicts the largest stems at 5 yr intervals (VERSION_HISTORY Era 8). Outside Maine no stand carries a thinning year, so only L was tested there. L raised basal area on nearly every stand. That improved the basal area level in Nova Scotia, but it moved QMD and total volume away from 1 in Nova Scotia and Quebec.

The October 16, 2026 cross-version benchmark adds three limitations for Maine.

- T overstates recovery after harvest. On 827 post-harvest Maine FIA stands, 14.1 over predicts annual biomass change after heavy removals by 1.39 Mg ha⁻¹ yr⁻¹, which doubles the observed 1.39 Mg ha⁻¹ yr⁻¹, and after intermediate removals by 1.41 Mg ha⁻¹ yr⁻¹. T was fitted to commercial thinning and appears to treat an overstory removal as a thinning. Until 14.3 limits T to partial removals, supply `stand.tst` only for commercial thinnings.
- 14.x declines over long horizons. In 200 yr no-harvest projections of 918 unmanaged Maine FIA stands, 14.1 declines in 64 to 84 percent of stands in each of six forest types, while the FIA record shows a peak only in spruce-fir. By year 200, 14.1 sits at 0.56 of the maple-beech-birch yield curve and 0.70 of the white-red pine-hemlock curve.
- Diameter growth falls short. On unmanaged Maine FIA stands, 14.1 under predicts basal area by 8.4 percent and total volume by 12.2 percent, with top height nearly unbiased and QMD low by about 10 percent. The shortfall is common to every version. Read the cross-version benchmark before using 14.1 for projections of 100 yr or longer.

The benchmarked 14.1 cannot be reproduced exactly from the repository. The 14.x base `model_b0b1b2.r`, the runner's lookup files and helpers, the Phase D hooks and the frozen stand sets are on the compute hosts only. The base md5 is given as bb51eeada62796532ce3a7212a5c6451 in the benchmark README and as 04a0b71da081ae98d1473391c9976896 in the 14.2 launch scripts [UNVERIFIED which is current].

## 9. Citation

Cite the Zenodo concept DOI, which resolves to the latest deposited version:

Weiskittel, A., and B. Rice. FVS-ACD (AcadianGY): Acadian variant of the Forest Vegetation Simulator, modernization and benchmark record. Zenodo. https://doi.org/10.5281/zenodo.22996790

Also state the release as AcadianGY 14.1 and give the engine md5 sums of Section 7, since the version tag does not identify it. Which deposited version first includes the 14.1 engine files is [UNVERIFIED]. Cite Kuehne, Weiskittel and Kershaw (2022, Mathematical and Computational Forestry & Natural-Resource Sciences 14(2): 9-31) for the diameter and height increment equations the stack inherits.

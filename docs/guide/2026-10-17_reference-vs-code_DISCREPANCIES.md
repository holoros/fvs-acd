# Discrepancies between the reference drafts and the 14.1 engine code

Compiled October 17, 2026 after writing `user-guide-14.1.md` from the code. The drafts checked are `docs/reference/running-14.1.md` and `docs/reference/switches.md` on branch `docs-overhaul-20261017`. The code is `scripts/AcadianGY_13.1.r`, `scripts/AcadianGY_14.0.4.r`, `scripts/AcadianGY_14.1.r` and `scripts/phaseD/2026-09-25_v141_phaseD_runner_p23_tst.R` on branch `engines-14.1-20260924`, plus the coefficient files in `data/v14/` on that branch. Each item gives what the draft says, what the code does, and where. Items marked omission are cases where the draft is silent on a code behavior that changes how a setting acts. Nothing in the repository was edited.

There are 19 items: 9 in `running-14.1.md` and 10 in `switches.md`.

## running-14.1.md

**R1. Layer 1 md5 and location.** The draft says `AcadianGY_13.1.r`, md5 5894df6013c701d09e7ba67ba6c2f090, is in `scripts/`. No copy in the repository has that md5. The branch `engines-14.1-20260924` copy is 6ec1823690ab6756b11e4f6fc684a325, and it differs from the Cardinal copy only in line 17 (`AcadianVersionTag = "AcadianV13.2"`, commit e9527d7). Reverting that line reproduces 5894df60, which was checked. The `scripts/AcadianGY_13.1.r` on `main` and on `docs-overhaul-20261017` is a different, older 4,842 line file (md5 5140bf9bc7d8be8051571ba413e0a6e4) without the 27 August 2026 hardwood vectorization fix in `calc_ddbh`.

**R2. The basal area target coefficient file.** The draft's coefficient table lists `v1404_dba_coef_FINAL_2026-09-17.rds` among the coefficient files under "Coefficients are separate files". 14.0.4 never reads it. The refitted target's coefficients are inline literals (`.acd_v14_dba_A0`, `_ALRD`, `_ALHW`, `_CLRD`, `_CLHW`, `_K` in `AcadianGY_14.0.4.r`), and the rds is fitting provenance only, as the engine header and VERSION_HISTORY Era 7 both say.

**R3. "Projections are driven by a benchmark runner, not called directly."** `AcadianGYOneStand(tree, stand, ops)` is a callable function, and the runner is one caller of it. The runner is bound to Cardinal: it calls `setwd("/users/PUOM0008/crsfaaron/magplot/verify")` and sources files by absolute Cardinal paths. A user outside the compute hosts has to call the engine directly.

**R4. Runner sourcing order and dependencies.** The draft gives the order as `MODEL_FILE`, then the v13.2 overlay (`V132`), then the 14.1 overlay. With `V132=1` the runner sources the v13.2 overlay, sources `MODEL_FILE` again, and calls `activate_v132()` before the 14.1 block. The draft's dependency list also omits the Phase D trajectory hooks, which the runner always sources from `/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/phaseD/scripts/2026-09-16_gydbreg-phaseD_trajhooks.R` (omission).

**R5. Levers that the code never reads.** The draft says the runner "sets the mortality, ingrowth and height anchor levers", and its minimal launch sets `USE_BRMS`, `USE_ANCHOR`, `ONSET`, `BREAK`, `BG`, `BS`, `SDMAX`, `NB_BREAK` and `QC_BREAK`. In the code, the runner turns these into `ops$use.brms.sdimax`, `ops$brms.sdimax.map`, `ops$use.esi.anchor.recal`, `ops$esi.anchor.coef`, `ops$sdimort.break.region` and the `ops$sdimort.*` fields. None of 13.1, 14.0.4 or 14.1 reads the first five fields. PREREG14 in `scripts/v14.2dev/2026-09-26/prereg14/` reports the same for the anchor fields across all four sourced files, `model_b0b1b2.r` included. With `LINKED=1`, `make_ops()` in 14.0.4 sets `use.sdimort` to FALSE and the runner leaves it so, which makes every `sdimort.*` value inert. In the 14.1 configuration the only active height lever is the per tree `dht.mult` set from `NB_AFAC` and `QC_AFAC`.

**R6. PAIRS_FILE columns.** The draft lists `STAND`, `SITE`, `PROV`, `Y1`, `Y2`, `interval_years`, `SCORE_MINDBH_OBS`, optional `MANAGED` and `TST`. It omits `ELEV`. The runner evaluates `if(is.finite(p$ELEV)&&p$ELEV>0)` outside the per stand `tryCatch`, so a pairs file without `ELEV` stops the whole run under R 4.3 and later (R 4.5.2 in the benchmarks). `Y1` and `Y2` are only carried into the output.

**R7. Minimal launch with `SRC_TST=UNKNOWN`.** The draft's launch block sets `THIN_V141=1 SRC_TST=UNKNOWN` and presents it as a 14.1 launch. In the code, UNKNOWN reaches the engine as NA, T is the identity on every stand, and the runner prints "THIN_V141=1 and no stand has a known years since thinning, so T is the identity everywhere in this run and this run does not test T". The draft does not say so (omission).

**R8. `V141_DLO` and `V141_DHI` in the launch block.** The draft sets `V141_DLO=12.7 V141_DHI=15.0` alongside `V141_COEF`. When `ops$v141.coef.file` names a file, `.acd_v141_coefs()` returns the rds contents and `calc_ddbh` takes `d_lo` and `d_hi` from the file (`st$d_lo <- cf$d_lo %||% 12.7`). The two variables therefore have no effect in that configuration. The r5 file holds 12.7 and 15.0, so the values agree, but setting the variables changes nothing.

**R9. md5 of the 14.x base.** The draft gives bb51eeada62796532ce3a7212a5c6451 for `p4e/model_b0b1b2.r`, as the cross-version benchmark README and its launchers do. The 14.2 launch scripts in the repository check the same path name against 04a0b71da081ae98d1473391c9976896, for example `scripts/v14.2dev/2026-09-29/prereg23/run_task_p23.sh` and the PREREG37 bundle line. The file is not in the repository, so which md5 belongs to the benchmarked 14.1 cannot be settled from the code [UNVERIFIED].

## switches.md

**S1. `V141_DLO` and `V141_DHI` as the smoothstep limits.** The draft describes them as the limits of L and describes L as the "identity below `V141_DLO`". With a coefficient file, as in the benchmark, the limits come from the file, and L is the identity below the file's `d_lo` (see R8). A related omission: the r5 file carries `rel_cap` 2.98478, but `make_ops()` stores `v141.rel.cap` as NA rather than NULL, so `ops$v141.rel.cap %||% cf$rel_cap` never reaches the file value. `V141_RELCAP` must be set even when the file is named.

**S2. `SPLIT`.** The draft says `SPLIT` applies `split_formrisk()` "to each projected list". The runner applies it once to the initial t1 list, `if(SPLIT){cur<-split_formrisk(cur)}`, before the annual loop, and never to projected lists.

**S3. `ONSET`.** The draft gives the benchmark value 0.55 as if it acts, and marks only `BREAK`, `BG`, `BS` and `SDMAX` as inert under `LINKED=1`. `ONSET` sets `ops$sdimort.onset`, read only inside the SDImax self-thinning block, which is off under `LINKED=1`. It is equally inert in the 14.1 benchmark.

**S4. `NB_BREAK`, `QC_BREAK`.** The draft calls them "regional break points". The runner stores them as `ops$sdimort.break.region`, which no engine file reads, and they would be inert under `LINKED=1` in any case.

**S5. `NB_IMULT`, `QC_IMULT`.** The draft calls them "regional ingrowth multipliers". The runner stores them as `ops$ingrowth.mult.region`, which none of 13.1, 14.0.4 or 14.1 reads. Only the scalar `ops$ingrowth.mult` (`IMULT`) acts.

**S6. `USE_BRMS`.** The draft says "stand SDImax from the brms map". `ops$use.brms.sdimax` and `ops$brms.sdimax.map` are read by none of 13.1, 14.0.4 or 14.1. Whether `model_b0b1b2.r` reads them is [UNVERIFIED].

**S7. `USE_ANCHOR`.** The draft says "ESI dominant height anchor recalibration". `ops$use.esi.anchor.recal` and `ops$esi.anchor.coef` are read by no engine file (see R5). The 13.1 ESI dominant height anchor is a different switch, `ops$use.esi.domht`, which the runner sets to FALSE.

**S8. `NB_AFAC`, `QC_AFAC`.** The draft calls them "provincial height anchor factors". In the code they set the per tree `dht.mult` column of the initial list, a multiplier on annual height increment (`dht = dht * ... * dht.mult` in `calc_dht`), not an anchor on height level. The draft also omits that recruits receive `dht.mult` 1, because the runner's `bf()` refills NA multipliers with 1 after each step (omission).

**S9. `SRC_TST` and `TST` values.** The draft says they accept "a number, `NEVER` or `UNKNOWN`". `.v141_parse_tst()` also maps `UNTHINNED` and `NONE` to never thinned and `NA` or an empty string to unknown, and it rejects a negative source level value with a stop.

**S10. `LINKED`.** The draft says "linked three stage mortality in place of SDImax self thinning". In 14.0.4 the lever replaces the whole 13.1 `calc_mortality`, meaning the stand basal area mortality and tree survival allocation, and `make_ops()` also turns off the SDImax self-thinning block. MORTCAL keeps its own gate, which the runner sets to FALSE. The draft names only the second of the two replacements.

## Not counted

`switches.md` says `B0NEW`, `B1NEW` and `B2NEW` are read by `model_b0b1b2.r`, which sources 13.1 and patches `ddbh()`. That agrees with the comment in `scripts/seven_islands/bakuzis_v13x_traj.R`, but the file is not in the repository, so it could not be checked [UNVERIFIED]. Every other default and benchmark value in both drafts matches the code: the 14.0.4 environment defaults (`LINKED_FIX1` to `FIX5`, `FIX1B`, `LINKED_DREF`, `SMALLTREE_*`, `DBA_V1404`), the base fallback order for `ACD_V14_BASE`, and the runner defaults for `MODEL_FILE`, `V132`, `V141_FILE`, `CONFIG_TAG`, `INDOMAIN` and `LEV3_*` (`LEV3_QMIN` 22).

#!/usr/bin/env Rscript
# run_acadiangy_long_v16_v125.R
# AcadianGY 12.5.0 long-horizon driver on the v16 CFI pair set (n=73).
# Uses the rewritten 12.5.0 input contract: make_stand() / make_ops() and
# lowercase tree columns. Recruit calibration columns are backfilled between
# annual cycles (12.5.0 create_ingrowth_tree leaves them NA).
#
# Parameterized by environment variables so one script serves both runs:
#   MODEL_FILE   path to model source (pristine 12.5.0 or the _mortcal variant)
#   USE_MORTCAL  TRUE/FALSE  (sets ops$use.mortcal; only acts in the _mortcal file)
#   OUT_CSV      output path
#   CONFIG_TAG   label written to the model_config column
#
# Volume/BA/cords/BdFt formulas are identical to run_acadiangy_long_v16.R so the
# results stay directly comparable to the v18 baseline.

.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(purrr) })

MODEL_FILE  <- Sys.getenv("MODEL_FILE",  "~/AcadianGY_12.6.0.r")
USE_MORTCAL <- toupper(Sys.getenv("USE_MORTCAL", "FALSE")) %in% c("TRUE","T","YES","Y","1")
OUT_CSV     <- Sys.getenv("OUT_CSV", "silc_cfi_long_agy_v125_results.csv")
CONFIG_TAG  <- Sys.getenv("CONFIG_TAG", ifelse(USE_MORTCAL, "AGY_12.5.0_MORTCAL", "AGY_12.5.0"))
source(MODEL_FILE)
cat(sprintf("Model: %s | use.mortcal=%s | tag=%s\n", MODEL_FILE, USE_MORTCAL, CONFIG_TAG))

ACRES_PER_HA <- 2.4710538147
CSI_M <- as.numeric(Sys.getenv("CSI_FLAT","12")); ELEV_M <- 305; REGION <- "ME"

acadgy_species <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB",
                    "HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM",
                    "RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP",
                    "WS","YB")
cfi_to_agy <- c("BF"="BF","RS"="RS","PB"="PB","YB"="YB","RM"="RM","SM"="SM",
                "WA"="WA","RO"="RO","BS"="BS","WS"="WS","JP"="JP","RP"="RP",
                "WP"="WP","EH"="EH","HM"="EH","CE"="WC","WC"="WC","BE"="BC",
                "QA"="QA","GB"="GB","BC"="BC","BA"="BA","AB"="AB","ST"="ST",
                "TA"="TA")
SPCD_to_AGY <- c("12"="BF","97"="RS","375"="PB","371"="YB","316"="RM",
                 "241"="WC","261"="EH","95"="BS","91"="WS","105"="JP",
                 "129"="WP","318"="SM","531"="BC","746"="QA","833"="RO",
                 "541"="WA","934"="GB")
COMMON_TO_AGY <- c("Balsam fir"="BF","Red spruce"="RS","Paper birch"="PB","Yellow birch"="YB",
                   "Red maple"="RM","Sugar maple"="SM","White ash"="WA","Northern red oak"="RO",
                   "Black spruce"="BS","White spruce"="WS","Jack pine"="JP","Red pine"="RP",
                   "White pine"="WP","Eastern hemlock"="EH","Northern white cedar"="WC",
                   "Black cherry"="BC","Quaking aspen"="QA","Eastern white pine"="WP",
                   "Gray birch"="GB","Bigtooth aspen"="BA","American beech"="AB",
                   "Striped maple"="ST","Tamarack"="TA")

# Build a 12.5.0-style tree dataframe (lowercase cols) from a CFI pair tree list
prep_tree <- function(td, year_prev) {
  sp <- rep(NA_character_, nrow(td))
  if ("SP" %in% names(td)) sp <- ifelse(td$SP %in% names(cfi_to_agy), cfi_to_agy[td$SP], NA)
  if ("COMMON_NAME" %in% names(td)) { m <- is.na(sp); sp[m] <- COMMON_TO_AGY[td$COMMON_NAME[m]] }
  if ("SP" %in% names(td)) { m <- is.na(sp); sp[m] <- COMMON_TO_AGY[td$SP[m]] } # v16 SP holds common name
  m <- is.na(sp) & !is.na(td$SPCD); sp[m] <- SPCD_to_AGY[as.character(td$SPCD[m])]
  bad <- is.na(sp) | !(sp %in% acadgy_species)
  sp[bad] <- ifelse(!is.na(td$SPCD[bad]) & td$SPCD[bad] >= 300, "OH", "OS")
  dbh_cm <- td$DBH * 2.54
  ht_m   <- ifelse(!is.na(td$HT) & td$HT > 0, td$HT * 0.3048, NA_real_)  # let 12.5.0 impute NA
  data.frame(year = year_prev, plot = 1L, tree = seq_len(nrow(td)),
             sp = sp, dbh = dbh_cm, ht = ht_m, hcb = NA_real_, cr = NA_real_,
             expf = td$EXPF * ACRES_PER_HA, form = NA_character_, risk = NA_character_,
             ddbh.mult = 1, dht.mult = 1, mort.mult = 1,
             max.dbh = 200, max.height = 50, stringsAsFactors = FALSE)
}

# Backfill calibration cols on fresh recruits (NA out of create_ingrowth_tree)
backfill_calib <- function(x) {
  x$ddbh.mult  <- ifelse(is.na(x$ddbh.mult),  1,   x$ddbh.mult)
  x$dht.mult   <- ifelse(is.na(x$dht.mult),   1,   x$dht.mult)
  x$mort.mult  <- ifelse(is.na(x$mort.mult),  1,   x$mort.mult)
  x$max.dbh    <- ifelse(is.na(x$max.dbh),    200, x$max.dbh)
  x$max.height <- ifelse(is.na(x$max.height), 50,  x$max.height)
  x
}

vol_intl_bdft_imp <- function(d, h, e) {
  ok <- d >= 9.0 & is.finite(d) & is.finite(h)
  sum(0.01 * d[ok]^2 * h[ok] * e[ok], na.rm = TRUE)
}

WD <- getwd()
manifest <- read.csv(file.path(WD, "silc_cfi_longhorizon_pairs_v16.csv"), stringsAsFactors = FALSE)
cat(sprintf("Running %s on %d v16 pairs\n", CONFIG_TAG, nrow(manifest)))

ops <- make_ops(verbose = FALSE, use.ingrowth = TRUE, ingrowth.min.dbh = 5.0,
                ingrowth.thrshld = 0.95, use.cap.dbh = TRUE, use.cap.ht = TRUE,
                use.hw.mod = FALSE, use.sbw.mod = FALSE, use.thin.mod = FALSE,
                use.vol = FALSE)
ops$use.mortcal <- USE_MORTCAL
ops$mortcal.interval <- 5
ops$mortcal.lambda <- as.numeric(Sys.getenv("MORTCAL_LAMBDA", "1"))
ops$ingrowth.mult <- as.numeric(Sys.getenv("INGROWTH_MULT", "1"))
.ent <- Sys.getenv("INGROWTH_ENTRY_DBH", "")
if (nzchar(.ent)) ops$ingrowth.entry.dbh <- as.numeric(.ent)
.thr <- Sys.getenv("INGROWTH_THRSHLD", "")
if (nzchar(.thr)) ops$ingrowth.thrshld <- as.numeric(.thr)  # 0 => expected-value ingrowth
ops$use.sdimort      <- toupper(Sys.getenv("USE_SDIMORT","TRUE")) %in% c("TRUE","T","YES","Y","1")
ops$sdimort.beta     <- as.numeric(Sys.getenv("SDIMORT_BETA","0.10"))
ops$sdimort.onset    <- as.numeric(Sys.getenv("SDIMORT_ONSET","0.55"))
ops$sdimort.max      <- as.numeric(Sys.getenv("SDIMORT_MAX","1.00"))
ops$sdimax.site.term <- toupper(Sys.getenv("SDIMAX_SITE_TERM","FALSE")) %in% c("TRUE","T","YES","Y","1")
ESI_FLAT <- Sys.getenv("ESI_FLAT","")
cat(sprintf("v126: use.sdimort=%s beta=%.2f onset=%.2f max=%.2f siteterm=%s esi=%s\n", ops$use.sdimort, ops$sdimort.beta, ops$sdimort.onset, ops$sdimort.max, ops$sdimax.site.term, ifelse(nzchar(ESI_FLAT),ESI_FLAT,"NA")))
cat(sprintf("mortcal.lambda=%.2f ingrowth.mult=%.2f entry.dbh=%s thrshld=%.2f\n",
            ops$mortcal.lambda, ops$ingrowth.mult, ifelse(nzchar(.ent), .ent, "default"), ops$ingrowth.thrshld))

OUT_TL <- Sys.getenv("OUT_TL", "")  # optional final-year tree-list dump
out_rows <- list(); tl_rows <- list(); fail <- 0
for (i in seq_len(nrow(manifest))) {
  pr <- manifest[i, ]
  tf <- file.path(WD, pr$tree_list_file)
  if (!file.exists(tf)) { fail <- fail + 1; next }
  td <- read.csv(tf, stringsAsFactors = FALSE)
  if (nrow(td) == 0) { fail <- fail + 1; next }
  cur   <- prep_tree(td, pr$YEAR_PREV)
  stand <- make_stand(stand.id = sprintf("CFI_%04d", pr$PLOT),
                      csi = CSI_M, elev = ELEV_M, region = REGION,
                      esi = if (nzchar(ESI_FLAT)) as.numeric(ESI_FLAT) else NA_real_)
  ok <- TRUE
  for (yr in seq_len(pr$PERIOD_YR)) {
    nxt <- tryCatch(AcadianGYOneStand(tree = cur, stand = stand, ops = ops),
                    error = function(e) { message(sprintf("plot %s yr %d: %s", pr$PLOT, yr, conditionMessage(e))); NULL })
    if (is.null(nxt) || nrow(nxt) == 0) { ok <- FALSE; break }
    cur <- backfill_calib(nxt)
  }
  if (!ok) { fail <- fail + 1; next }
  live <- cur[!is.na(cur$dbh) & cur$dbh >= 11.43, ]
  if (nrow(live) == 0) { fail <- fail + 1; next }
  DBH_in <- live$dbh / 2.54
  HT_ft  <- live$ht  / 0.3048
  EXPF_ac<- live$expf / ACRES_PER_HA
  BA  <- sum(0.005454 * DBH_in^2 * EXPF_ac, na.rm = TRUE)
  TPA <- sum(EXPF_ac, na.rm = TRUE)
  QMD <- if (TPA > 0) sqrt((BA / TPA) / 0.005454) else NA
  tcuft <- 0.0025 * DBH_in^2 * HT_ft
  Cords <- sum(tcuft * 0.90 * EXPF_ac, na.rm = TRUE) / 79
  BdFt_intl <- vol_intl_bdft_imp(DBH_in, HT_ft, EXPF_ac)
  out_rows[[length(out_rows) + 1]] <- data.frame(
    model_config = CONFIG_TAG,
    PLOT = pr$PLOT, YEAR_PREV = pr$YEAR_PREV, YEAR_CURR = pr$YEAR_CURR, PERIOD_YR = pr$PERIOD_YR,
    BA_PRED_ft2ac = BA, TPA_PRED = TPA, QMD_PRED_in = QMD,
    Cords_PRED_ac = Cords, BdFt_intl_PRED_ac = BdFt_intl,
    BA_OBS_PREV = pr$BA_PREV_FT2AC, BA_OBS_CURR = pr$BA_CURR_FT2AC)
  if (nzchar(OUT_TL)) {
    tl_rows[[length(tl_rows) + 1]] <- data.frame(
      model_config = CONFIG_TAG, PLOT = pr$PLOT, YEAR = pr$YEAR_CURR,
      sp = live$sp, dbh_cm = live$dbh, ht_m = live$ht, expf_tph = live$expf,
      stringsAsFactors = FALSE)
  }
  if (i %% 10 == 0) cat(sprintf("  pair %d/%d done\n", i, nrow(manifest)))
}
out <- do.call(rbind, out_rows)
write.csv(out, file.path(WD, OUT_CSV), row.names = FALSE)
if (nzchar(OUT_TL)) {
  write.csv(do.call(rbind, tl_rows), file.path(WD, OUT_TL), row.names = FALSE)
  cat(sprintf("Wrote tree list -> %s\n", OUT_TL))
}
cat(sprintf("\nDone %s. Wrote %d pairs (%d failed) -> %s\n", CONFIG_TAG, nrow(out), fail, OUT_CSV))

## BENCH141 FROZEN COPY (2026-09-25) of v1404/bench/score/R/2026-09-18_v1404_bench_score_core.R. Two changes: RES141 and its
## dispatch for V141_COLS. Every statistic, the seed, the draws and the population rule untouched. Diff in ../../diffs/.
## FROZEN COPY for the v1403 BENCHMARK track (2026-09-17) of the v1403 control track copy
## v1403/control/score/R/2026-09-17_v1403_score_core.R (md5 recorded in the job list). Two lines change and
## nothing else: RES1403B names the v1403 benchmark results root and the column-to-directory dispatch sends
## the columns listed in V1403B_COLS there. Every statistic, the seed, the draw count, the site draws, the
## population rule and the self-checks are untouched. Diff at v1403/diffs/score_core_bench.diff. No em dashes.
## FROZEN COPY for v1402 (2026-09-17) of score/R/2026-09-16_gydbreg-score_core.R. Changes (diff logged):
## V1 extra columns V1402_COLS read from v1402/results, reference column V1402_REF, optional set subset
##    V1402_SETS, outputs under v1402/score; V2 the site index matrices are READ from the Phase C files
##    score/work/siteidx_<set>.rds (the shared resample), the Phase C draw is repeated with the same seed
##    and set order and, on a full 19-set run, must be identical to the file (hard stop otherwise).
## 2026-09-16_gydbreg-score_core.R
## GYDB regional benchmark, Phase C (scoring). Core pass: loads the 152 Phase B result files,
## builds the common scored population per set, derives strata, draws ONE site-cluster bootstrap
## index matrix per set (shared by all eight columns, so column contrasts are paired) and stores
## weighted sufficient statistics per set x stratum x column x metric for the point sample and
## for each of the 2,000 draws. Tables, ranking and figures are built from these sums by the
## companion scripts, which are sourced by 2026-09-16_gydbreg-score_run.R in the same R session.
##
## Adapted from the FVS-ACD v12.10.1 benchmark suite (frozen reference copies with md5 in
## score/frozen_refs/). The helpers marked VERBATIM are copied unchanged. Adaptations, all
## documented in the Phase C report:
##  A1  inputs: the 8-column GYDB result files replace the per-source base/cand/v131/osm files.
##  A2  bootstrap unit: SITE clusters (task spec) instead of stand rows; B = 2000, seed 20260916
##      set once, one index matrix per set drawn in the fixed SETS order below, shared by columns.
##  A3  statistics are computed from weighted sums (weights = number of times a stand's site was
##      drawn); algebraically identical to recomputing rmse_pct/bias_pct/ols_coef on the
##      resampled rows; checked against the VERBATIM helpers on the point sample at run time.
##  A4  TPH is not in the harness contract; it is recovered exactly from BA and QMD, since the
##      harness defines QMD = sqrt((BA/TPH)/(pi/40000)) on the same tree set.
##  A5  common population per set = stands with RUN_OK == 1 and finite predictions in all eight
##      columns (drops the 28 OSM failures from every column); a non-OSM full-population pass
##      (seven columns) is kept as a sensitivity.
##  A6  forest group from the t1 tree lists with the master_scorecard.R rule (VERBATIM); the
##      frozen_subsidiary.R rule is computed alongside as a check only.
##  A7  maturity class is the v131_maturity_scorecard.R source role, extended to the new sets.
## Aggregates only leave this node. No coordinates are read.

suppressMessages(library(data.table))
ROOT <- path.expand("~/magplot/verify/gydbreg20260916")
RES  <- file.path(ROOT, "runs/results")
FR   <- file.path(ROOT, "frames")
OUT  <- if (exists("V1403B_OUT")) V1403B_OUT else file.path(ROOT, "v1403/control/score")
RES1402 <- file.path(ROOT, "v1402/results")
RES1403 <- file.path(ROOT, "v1403/control/results")   # v1403: region-fixed control reruns
RES1403B <- file.path(ROOT, "v1403/results")            # v1403 benchmark track: the new 14.0.3 columns            # v1403 benchmark track: the 14.0.3 columns
RES1404  <- file.path(ROOT, "v1404/bench/results")    # v1404 benchmark track: the new 14.0.4 columns
RES141   <- file.path(ROOT, "v142_20260925/bench141/results")   # PREREG4: the 14.1 columns
RESING   <- file.path(ROOT, "v142_20260925/recs/ingthr/results")   # PREREG9: the v141LTig column
RESHT    <- file.path(ROOT, "v142_20260925/recs/htfix/results")   # PREREG11: the v141LTh columns
if (!exists("V141_COLS")) V141_COLS <- character(0)
if (!exists("V1404_COLS")) V1404_COLS <- character(0)
if (!exists("V1403B_COLS")) V1403B_COLS <- character(0)
WK0  <- file.path(ROOT, "score/work")
TAB  <- file.path(OUT, V1402_TABSUB)
WK   <- file.path(OUT, paste0(V1402_TABSUB, "_work"))
for (d in c(TAB, WK)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

SEED <- 20260916L
B    <- 2000L
COLS <- c(v12101 = "v12.10.1", v1211 = "v12.11", v131base = "v13.1 baseline",
          v14L1 = "v14.0.1 L1", v14L2 = "v14.0.1 L2", osm = "OSM-ACD v2.26.1",
          fvsne_sim = "FVS-NE simulator heights", fvsne_htimp = "FVS-NE harness heights")
COLS <- c(COLS, V1402_COLS)
REFCOL <- V1402_REF
SETS <- c("baxter_c", "silc_l_c", "ctrn_c", "ctrn_fl", "pef_c", "pef_fl", "mefia_l_c",
          "memat_c", "memat_fl", "medev_c", "medev_fl", "mnap_c", "nb_c", "qc_c", "qc_fl",
          "ns_c", "ns_fl", "ns_long_c", "ns_long_fl")
V1402_FULL19 <- !exists("V1402_SETS")
if (!V1402_FULL19) SETS <- SETS[SETS %in% V1402_SETS]
IDXCHK <- list()
if (exists("SMOKE") && isTRUE(SMOKE)) {   # test only: three small sets, separate output folder
  SETS <- c("baxter_c", "ctrn_fl", "qc_fl", "ns_long_fl"); B <- 200L
  TAB <- file.path(OUT, "smoke"); WK <- file.path(OUT, "smoke/work")
  for (d in c(TAB, WK)) dir.create(d, recursive = TRUE, showWarnings = FALSE)
}
METRICS <- c("BA", "TPH", "SDI", "QMD", "TOPHT", "TOTVOL", "MERCHVOL", "SAWVOL", "BIOMASS", "VALUE")
STRAT_METRICS <- c("TOTVOL", "BA")
MAINE <- c("PEF", "CTRN", "SILC_L", "BAXTER", "MEMAT", "MEDEV", "MEFIA_L", "MNAP")
MIN_N_STRATUM <- 10L   # a set enters a stratum composite only with at least this many stands
set_dataset <- function(s) toupper(sub("_(c|fl)$", "", s))
set_frame   <- function(s) ifelse(grepl("_fl$", s), "first-last", "consecutive")
DS_LABEL <- c(BAXTER = "Baxter", SILC_L = "SILC", CTRN = "CFRU CTRN", PEF = "PEF",
              MEFIA_L = "Maine FIA whole-plot", MEMAT = "Maine FIA mature",
              MEDEV = "Maine FIA developing", MNAP = "MNAP ecoreserves", NB = "NB MagPlot",
              QC = "QC MagPlot", NS = "Nova Scotia", NS_LONG = "Nova Scotia long")
## A7: v131_maturity_scorecard.R roles (baxter mature; silc_l calibration; mefia_l, pef, nb
## developing; ctrn managed; ns, ns_long NS managed emphasis), extended: memat mature, medev
## developing, qc developing (as nb), mnap mature (ecoreserve, unmanaged).
MATURITY <- c(BAXTER = "Mature", MEMAT = "Mature", MNAP = "Mature",
              MEFIA_L = "Developing", MEDEV = "Developing", PEF = "Developing",
              NB = "Developing", QC = "Developing",
              CTRN = "Managed or calibration", SILC_L = "Managed or calibration",
              NS = "Nova Scotia", NS_LONG = "Nova Scotia")

## ---------------- VERBATIM helpers (v12.10.1 suite) ----------------
## composite_score_fourway.R / equivalence_tests_fourway_demeaned.R
rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)
ols_coef <- function(x, y) {
  mx <- mean(x); my <- mean(y)
  sxx <- sum((x - mx)^2)
  slope <- sum((x - mx) * (y - my)) / sxx
  intercept <- my - slope * mx
  c(intercept = intercept, slope = slope)
}
## master_scorecard.R
sp_type <- c(
  AB="HW", AS="HW", BA="HW", BC="HW", BF="SW", BP="HW", BS="SW", BT="HW",
  EC="HW", EH="SW", GA="HW", GB="HW", HH="HW", JP="SW", NS="SW", OH="HW",
  OS="SW", PB="HW", PC="HW", PR="HW", QA="HW", RB="HW", RM="HW", RP="SW",
  RN="SW", RO="HW", RS="SW", SB="HW", SM="HW", ST="HW", TA="SW", WA="HW",
  WC="SW", WP="SW", WS="SW", YB="HW", `99`="HW"
)
FG_SW_MAX <- 25; FG_HW_MIN <- 75
assign_fg <- function(pct_hw) fifelse(is.na(pct_hw), NA_character_,
  fifelse(pct_hw < FG_SW_MAX, "Softwood", fifelse(pct_hw > FG_HW_MIN, "Hardwood", "Mixedwood")))
interval_bucket <- function(iv) fifelse(iv < 15, "<15", fifelse(iv <= 30, "15-30", ">30"))
site_tercile <- function(esi) {
  ok <- is.finite(esi)
  if (sum(ok) < 15) return(list(class = rep(NA_character_, length(esi)),
                                 cuts = NA_real_, labels = character(0)))
  q <- quantile(esi[ok], probs = c(1/3, 2/3), na.rm = TRUE, type = 7)
  lab_lo <- sprintf("Low (esi8<%.1f)", q[1])
  lab_mid <- sprintf("Mid (esi8 %.1f-%.1f)", q[1], q[2])
  lab_hi <- sprintf("High (esi8>%.1f)", q[2])
  cls <- fifelse(is.na(esi), NA_character_,
           fifelse(esi < q[1], lab_lo, fifelse(esi <= q[2], lab_mid, lab_hi)))
  list(class = cls, cuts = q, labels = c(lab_lo, lab_mid, lab_hi))
}
## frozen_subsidiary.R softwood list (check only)
sw_frozen <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC","EC","WH","HE")

## composition: master_scorecard.R composition_from_treeinit() body (VERBATIM, unmapped -> SW),
## plus the frozen_subsidiary.R rule (DBH >= 4, <=25 / >=75) for the check table.
composition_both <- function(path) {
  ti <- fread(path)
  ti[, STAND := as.character(STAND)]
  unm <- ti[is.na(sp_type[SP]), .N, by = SP]
  ti[, sp_t := sp_type[SP]]
  ti[is.na(sp_t), sp_t := "SW"]
  ti[, ba := pi * (DBH/200)^2 * EXPF]
  agg <- ti[, .(BA_t1_calc = sum(ba, na.rm = TRUE), HW_BA_t1 = sum(ba[sp_t == "HW"], na.rm = TRUE),
                UNM_BA = sum(ba[is.na(sp_type[SP])], na.rm = TRUE)), by = STAND]
  agg[, pct_hw_t1 := 100 * HW_BA_t1 / BA_t1_calc]
  agg[, forest_group := assign_fg(pct_hw_t1)]
  tf <- ti[is.finite(DBH) & DBH >= 4]
  tf[, isHW := !(toupper(SP) %in% sw_frozen)]
  ft <- tf[, .(pctHW = 100 * sum(ba[isHW]) / sum(ba)), by = STAND]
  ft[, fortype_frozen := fifelse(pctHW <= 25, "Softwood", fifelse(pctHW >= 75, "Hardwood", "Mixedwood"))]
  agg <- merge(agg, ft[, .(STAND, fortype_frozen)], by = "STAND", all.x = TRUE)
  list(agg = agg, unmapped = unm)
}

## ---------------- weighted sufficient statistics (A3) ----------------
mk_sums <- function(W, o, p) {
  if (is.null(W)) return(list(Sw = length(o), So = sum(o), Sp = sum(p), Soo = sum(o * o),
                              Spp = sum(p * p), Spo = sum(p * o)))
  list(Sw = colSums(W), So = drop(crossprod(W, o)), Sp = drop(crossprod(W, p)),
       Soo = drop(crossprod(W, o * o)), Spp = drop(crossprod(W, p * p)),
       Spo = drop(crossprod(W, p * o)))
}
add_sums <- function(a, b) if (is.null(a)) b else Map(`+`, a, b)
st_bias  <- function(S) 100 * (S$Sp - S$So) / S$So
st_rmse  <- function(S) 100 * sqrt(pmax(0, (S$Spp - 2 * S$Spo + S$Soo) / S$Sw)) / (S$So / S$Sw)
st_slope <- function(S) (S$Spo - S$Sp * S$So / S$Sw) / (S$Spp - S$Sp^2 / S$Sw)
st_int   <- function(S) (S$So - st_slope(S) * S$Sp) / S$Sw
st_r2    <- function(S) (S$Spo - S$Sp * S$So / S$Sw)^2 /
                        ((S$Spp - S$Sp^2 / S$Sw) * (S$Soo - S$So^2 / S$Sw))
st_mo    <- function(S) S$So / S$Sw
st_mp    <- function(S) S$Sp / S$Sw

tph <- function(ba, q) ifelse(is.finite(q) & q > 0, ba / (pi / 40000 * q^2),
                              ifelse(is.finite(q), 0, NA_real_))

## equivalence figure bins (TOTVOL, demeaned), fixed grid as make_fig29 (axis cap 250)
AXIS_LIM <- 250; NBIN <- 60
BRK <- seq(-AXIS_LIM, AXIS_LIM, length.out = NBIN + 1)

S_str <- list(); SY <- list(); META <- list(); FAILS <- list(); FGCHK <- list()
UNMAP <- list(); BINS <- list(); SITE_CUTS <- list()
selfcheck_done <- FALSE

set.seed(SEED)
for (s in SETS) {
  t_s <- Sys.time()
  ds <- set_dataset(s)
  L <- setNames(lapply(names(COLS), function(k) {
    d <- fread(file.path(if (grepl("^v141LTh", k)) RESHT else if (grepl("^v141LTig", k)) RESING else if (k %in% V141_COLS) RES141 else if (k %in% V1404_COLS) RES1404 else if (k %in% V1403B_COLS) RES1403B else if (grepl("^v1403", k)) RES1403 else if (k %in% names(V1402_COLS)) RES1402 else RES, k, sprintf("gyr_%s_%s_results.csv", k, s)))
    d[, STAND := as.character(STAND)]
    d[, `:=`(TPH_o = tph(BA_o, QMD_o), TPH_p = tph(BA_p, QMD_p), TPH_t1 = tph(BA_t1, QMD_t1))]
    d
  }), names(COLS))
  ref <- L[["v12101"]]
  n_all <- nrow(ref)
  ## gate (a) re-check: same STAND order, identical observed columns
  for (k in names(L)) {
    stopifnot(identical(L[[k]]$STAND, ref$STAND))
    for (m in METRICS) {
      a <- L[[k]][[paste0(m, "_o")]]; b <- ref[[paste0(m, "_o")]]
      stopifnot(identical(is.na(a), is.na(b)), max(abs(a - b) / pmax(1, abs(b)), na.rm = TRUE) <= 1e-9)  # PREREG11 deviation: firebreather R 4.5.1 vs Cardinal 4.5.2, observed columns differ at 1e-14; tolerance 1e-9 scaled as H0
    }
  }
  okk <- sapply(L, function(d) d$RUN_OK == 1 &
                  Reduce(`&`, lapply(METRICS, function(m) is.finite(d[[paste0(m, "_p")]]))))
  ok_obs <- Reduce(`&`, lapply(METRICS, function(m) is.finite(ref[[paste0(m, "_o")]])))
  ok_common <- ok_obs & rowSums(!okk) == 0
  ok_full7  <- ok_obs & rowSums(!okk[, setdiff(names(COLS), "osm"), drop = FALSE]) == 0
  FAILS[[s]] <- data.table(set = s, column_id = names(COLS), column = unname(COLS),
                           n_admitted = n_all, n_not_ok = colSums(!okk))

  ## one site-cluster index matrix per set (A2), over all admitted sites
  site_all <- as.character(ref$SITE)
  sites <- unique(site_all); nsite <- length(sites)
  sid <- match(site_all, sites)
  IDX_redraw <- matrix(sample.int(nsite, nsite * B, replace = TRUE), nsite, B)
  IDX <- readRDS(file.path(WK0, sprintf("siteidx_%s.rds", s)))
  stopifnot(nrow(IDX) == nsite, ncol(IDX) == B)
  IDXCHK[[s]] <- data.table(set = s, nsite = nsite, redraw_identical = identical(IDX_redraw, IDX), full19 = V1402_FULL19)
  if (V1402_FULL19) stopifnot(identical(IDX_redraw, IDX))
  rm(IDX_redraw)
  CNT <- matrix(0L, nsite, B)
  for (b in seq_len(B)) CNT[, b] <- tabulate(IDX[, b], nbins = nsite)
  Wfull <- CNT[sid, , drop = FALSE]; storage.mode(Wfull) <- "double"
  rm(IDX, CNT)

  ## strata (A6, A7)
  fr <- ref[, .(STAND, SITE, MANAGED, CHURN_FLAG, NSL_SINGLE_REGIME, iv, esi8)]
  cb <- composition_both(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)))
  fr[, forest_group := cb$agg$forest_group[match(STAND, cb$agg$STAND)]]
  fr[, fortype_frozen := cb$agg$fortype_frozen[match(STAND, cb$agg$STAND)]]
  fr[, unm_ba_share := cb$agg$UNM_BA[match(STAND, cb$agg$STAND)] / cb$agg$BA_t1_calc[match(STAND, cb$agg$STAND)]]
  if (nrow(cb$unmapped)) UNMAP[[s]] <- cbind(set = s, cb$unmapped)
  FGCHK[[s]] <- fr[ok_common, .N, by = .(forest_group, fortype_frozen)][, set := s]
  tc <- site_tercile(fr$esi8)
  SITE_CUTS[[s]] <- data.table(set = s, esi8_q33 = tc$cuts[1], esi8_q67 = if (length(tc$cuts) > 1) tc$cuts[2] else NA_real_)
  fr[, site_class := sub("^(Low|Mid|High).*$", "\\1", tc$class)]
  fr[, bucket := interval_bucket(iv)]

  strata <- list("all|All" = rep(TRUE, n_all))
  for (lv in c(1, 0)) strata[[paste0("managed|", if (lv == 1) "Managed" else "Unmanaged")]] <- fr$MANAGED == lv
  strata[["churn|Churn-flag-free"]] <- fr$CHURN_FLAG == 0
  strata[["churn|Churn-flagged"]]   <- fr$CHURN_FLAG == 1
  for (fg in c("Softwood", "Mixedwood", "Hardwood")) strata[[paste0("forest_group|", fg)]] <- fr$forest_group %in% fg
  strata[[paste0("maturity|", MATURITY[[ds]])]] <- rep(TRUE, n_all)
  for (sc in c("Low", "Mid", "High")) strata[[paste0("site_productivity|", sc)]] <- fr$site_class %in% sc
  for (bk in c("<15", "15-30", ">30")) strata[[paste0("projection_length|", bk)]] <- fr$bucket %in% bk
  if (ds == "NS_LONG") strata[["nsl_regime|Single-regime"]] <- fr$NSL_SINGLE_REGIME %in% 1

  S_str[[s]] <- list(); SY[[s]] <- list()
  for (g in names(strata)) {
    idx <- which(ok_common & strata[[g]])
    if (!length(idx)) next
    Wg <- Wfull[idx, , drop = FALSE]
    SY[[s]][[g]] <- c(n = length(idx), stand_years = sum(ref$iv[idx]))
    mets <- if (g == "all|All") METRICS else STRAT_METRICS
    S_str[[s]][[g]] <- setNames(lapply(names(COLS), function(k) {
      setNames(lapply(mets, function(m) {
        o <- ref[[paste0(m, "_o")]][idx]; p <- L[[k]][[paste0(m, "_p")]][idx]
        e <- list(pt = mk_sums(NULL, o, p), bs = mk_sums(Wg, o, p))
        if (g == "all|All") {
          od <- o - mean(o); pd <- p - mean(p)
          e$dm <- list(pt = mk_sums(NULL, od, pd), bs = mk_sums(Wg, od, pd))
          if (m == "TOTVOL") {
            inside <- abs(od) <= AXIS_LIM & abs(pd) <= AXIS_LIM
            bx <- cut(pd[inside], BRK, include.lowest = TRUE, labels = FALSE)
            by <- cut(od[inside], BRK, include.lowest = TRUE, labels = FALSE)
            BINS[[length(BINS) + 1L]] <<- data.table(set = s, column_id = k, bx = bx, by = by)[
              , .(n = .N), by = .(set, column_id, bx, by)][, n_clipped := sum(!inside)]
          }
        }
        e
      }), mets)
    }), names(COLS))
  }
  ## non-OSM full-population sensitivity (A5)
  idx7 <- which(ok_full7)
  W7 <- Wfull[idx7, , drop = FALSE]
  SY[[s]][["full7|All"]] <- c(n = length(idx7), stand_years = sum(ref$iv[idx7]))
  S_str[[s]][["full7|All"]] <- setNames(lapply(setdiff(names(COLS), "osm"), function(k) {
    setNames(lapply(STRAT_METRICS, function(m) {
      o <- ref[[paste0(m, "_o")]][idx7]; p <- L[[k]][[paste0(m, "_p")]][idx7]
      list(pt = mk_sums(NULL, o, p), bs = mk_sums(W7, o, p))
    }), STRAT_METRICS)
  }), setdiff(names(COLS), "osm"))

  ## A3 self-check against the VERBATIM helpers on the point sample
  if (!selfcheck_done) {
    idx <- which(ok_common)
    for (k in names(COLS)) for (m in c("TOTVOL", "BA")) {
      o <- ref[[paste0(m, "_o")]][idx]; p <- L[[k]][[paste0(m, "_p")]][idx]
      S <- S_str[[s]][["all|All"]][[k]][[m]]$pt
      cf <- ols_coef(p, o)
      stopifnot(abs(st_rmse(S) - rmse_pct(o, p)) < 1e-9, abs(st_bias(S) - bias_pct(o, p)) < 1e-9,
                abs(st_slope(S) - cf[["slope"]]) < 1e-9, abs(st_int(S) - cf[["intercept"]]) < 1e-7)
    }
    ## draw 1 equals recomputation on the explicitly resampled rows
    IDX1 <- readRDS(file.path(WK0, sprintf("siteidx_%s.rds", s)))[, 1]
    rows <- unlist(lapply(IDX1, function(j) which(sid == j & ok_common)))
    o <- ref$TOTVOL_o[rows]; p <- L[["v14L2"]]$TOTVOL_p[rows]
    S <- S_str[[s]][["all|All"]][["v14L2"]][["TOTVOL"]]$bs
    stopifnot(abs(st_rmse(S)[1] - rmse_pct(o, p)) < 1e-9, abs(st_bias(S)[1] - bias_pct(o, p)) < 1e-9)
    cat("SELFCHECK_OK (point and draw-1 identity against verbatim helpers)\n")
    selfcheck_done <- TRUE
  }

  META[[s]] <- data.table(set = s, dataset = ds, dataset_label = DS_LABEL[[ds]], frame = set_frame(s),
                          maturity = MATURITY[[ds]], n_admitted = n_all, n_common = sum(ok_common),
                          n_dropped_common = n_all - sum(ok_common), n_full7 = sum(ok_full7),
                          n_sites = nsite, n_sites_common = uniqueN(site_all[ok_common]),
                          stand_years_common = sum(ref$iv[ok_common]),
                          mean_interval_yr = mean(ref$iv[ok_common]),
                          managed_share = mean(fr$MANAGED[ok_common] == 1),
                          churn_flag_share = mean(fr$CHURN_FLAG[ok_common] == 1),
                          mean_TOTVOL_o = mean(ref$TOTVOL_o[ok_common]),
                          mean_BA_o = mean(ref$BA_o[ok_common]))
  rm(L, ref, Wfull, W7); gc(verbose = FALSE)
  cat(sprintf("%-11s n=%5d common=%5d sites=%5d  %.1f s\n", s, n_all, sum(ok_common), nsite,
              as.numeric(difftime(Sys.time(), t_s, units = "secs"))))
}
META <- rbindlist(META)
cat("CORE_DONE\n")

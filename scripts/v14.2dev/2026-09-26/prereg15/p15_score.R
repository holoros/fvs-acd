## PREREG15 scorer. Adapted from recs/htfix/score/R/ht_score_core.R (md5 b36d0008) and ht_score_tables.R (md5 e0c917cc).
## VERBATIM from the core: METRICS, rmse_pct, bias_pct, ols_coef, mk_sums, st_bias, st_rmse, st_slope, st_int, st_r2,
## st_mo, st_mp, tph (A4), the weights from an index matrix (CNT via tabulate), B = 2000, seed 20260916, the RUN_OK and
## finite prediction population rule (A5, one column here). From the tables script: 95 percent percentile intervals
## (quantile type 7) and the per set row layout. Changes: one column (v141LT) instead of eight; sets are the three
## PREREG15 sets read from this job; no strata, ranking or equivalence tables; added observed over predicted ratio of
## means (So/Sp) with its interval; added unpaired contrasts between sets; S0 scoring identity against bench141.
## Aggregates only. No coordinates. No em dashes.
suppressMessages(library(data.table))
H <- path.expand("~/jobs/v142p15"); RES <- Sys.getenv("P15_RES", file.path(H, "results/v141LT"));  # env override for the dry run only
 FR <- file.path(H, "home/magplot/verify/gydbreg20260916/frames")
TAB <- Sys.getenv("P15_TAB", file.path(H, "tables")); dir.create(TAB, showWarnings = FALSE)
SEED <- 20260916L; B <- 2000L
METRICS <- c("BA", "TPH", "SDI", "QMD", "TOPHT", "TOTVOL", "MERCHVOL", "SAWVOL", "BIOMASS", "VALUE")
HEAD <- c("BA", "TPH", "QMD", "TOTVOL")
SETS <- c(mnap_c = "State (pass 29b, tag stable)", mnap_tnc_c = "TNC (pass 29b, flagged)", mnapfrz_c = "frozen mnap_c (all TNC)")
if (nzchar(Sys.getenv("P15_SETS"))) SETS <- SETS[strsplit(Sys.getenv("P15_SETS"), ",")[[1]]]   # dry run only
## ---- VERBATIM helpers ----
rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)
ols_coef <- function(x, y) { mx <- mean(x); my <- mean(y); sxx <- sum((x - mx)^2)
  slope <- sum((x - mx) * (y - my)) / sxx; intercept <- my - slope * mx; c(intercept = intercept, slope = slope) }
mk_sums <- function(W, o, p) {
  if (is.null(W)) return(list(Sw = length(o), So = sum(o), Sp = sum(p), Soo = sum(o * o), Spp = sum(p * p), Spo = sum(p * o)))
  list(Sw = colSums(W), So = drop(crossprod(W, o)), Sp = drop(crossprod(W, p)),
       Soo = drop(crossprod(W, o * o)), Spp = drop(crossprod(W, p * p)), Spo = drop(crossprod(W, p * o))) }
st_bias  <- function(S) 100 * (S$Sp - S$So) / S$So
st_rmse  <- function(S) 100 * sqrt(pmax(0, (S$Spp - 2 * S$Spo + S$Soo) / S$Sw)) / (S$So / S$Sw)
st_slope <- function(S) (S$Spo - S$Sp * S$So / S$Sw) / (S$Spp - S$Sp^2 / S$Sw)
st_int   <- function(S) (S$So - st_slope(S) * S$Sp) / S$Sw
st_r2    <- function(S) (S$Spo - S$Sp * S$So / S$Sw)^2 / ((S$Spp - S$Sp^2 / S$Sw) * (S$Soo - S$So^2 / S$Sw))
st_mo    <- function(S) S$So / S$Sw
st_mp    <- function(S) S$Sp / S$Sw
tph <- function(ba, q) ifelse(is.finite(q) & q > 0, ba / (pi / 40000 * q^2), ifelse(is.finite(q), 0, NA_real_))
qq  <- function(x, a) unname(quantile(x, a, na.rm = TRUE, type = 7))
lo95 <- function(x) qq(x, 0.025); hi95 <- function(x) qq(x, 0.975); r <- function(x, d = 3) round(x, d)
## ---- added ----
st_ratio <- function(S) S$So / S$Sp   # observed over predicted, ratio of means
rd <- function(s) { d <- fread(file.path(RES, sprintf("gyr_v141LT_%s_results.csv", s))); d[, STAND := as.character(STAND)]
  d[, `:=`(TPH_o = tph(BA_o, QMD_o), TPH_p = tph(BA_p, QMD_p), TPH_t1 = tph(BA_t1, QMD_t1))]; d }
wts <- function(IDX, sid, nsite) { CNT <- matrix(0L, nsite, ncol(IDX)); for (b in seq_len(ncol(IDX))) CNT[, b] <- tabulate(IDX[, b], nbins = nsite)
  W <- CNT[sid, , drop = FALSE]; storage.mode(W) <- "double"; W }
score_rows <- function(ref, idx, W, s) rbindlist(lapply(METRICS, function(m) {
  o <- ref[[paste0(m, "_o")]][idx]; p <- ref[[paste0(m, "_p")]][idx]; pt <- mk_sums(NULL, o, p); bs <- mk_sums(W[idx, , drop = FALSE], o, p)
  data.table(set = s, set_label = SETS[[s]], column_id = "v141LT", metric = m, n = pt$Sw,
    mean_obs = r(st_mo(pt), 4), mean_pred = r(st_mp(pt), 4),
    ratio_op = r(st_ratio(pt), 4), ratio_lo = r(lo95(st_ratio(bs)), 4), ratio_hi = r(hi95(st_ratio(bs)), 4),
    bias_pct = r(st_bias(pt)), bias_lo = r(lo95(st_bias(bs))), bias_hi = r(hi95(st_bias(bs))),
    rmse_pct = r(st_rmse(pt)), rmse_lo = r(lo95(st_rmse(bs))), rmse_hi = r(hi95(st_rmse(bs))),
    intercept = r(st_int(pt), 4), intercept_lo = r(lo95(st_int(bs)), 4), intercept_hi = r(hi95(st_int(bs)), 4),
    slope = r(st_slope(pt), 4), slope_lo = r(lo95(st_slope(bs)), 4), slope_hi = r(hi95(st_slope(bs)), 4),
    r2 = r(st_r2(pt), 4)) }))
DRAWS <- list(); PER <- list(); POP <- list()
for (s in names(SETS)) {
  ref <- rd(s); n_all <- nrow(ref)
  site_all <- as.character(ref$SITE); sites <- unique(site_all); nsite <- length(sites); sid <- match(site_all, sites)
  if (nsite != n_all) stop("SITE is not unique per stand in ", s, "; the stand bootstrap premise fails")
  if (s == "mnapfrz_c") {
    IDX <- readRDS(file.path(H, "in/cardinal/siteidx_mnap_c.rds")); src <- "Phase C siteidx_mnap_c.rds"
  } else { set.seed(SEED); IDX <- matrix(sample.int(nsite, nsite * B, replace = TRUE), nsite, B); src <- "set.seed(20260916) per set" }
  stopifnot(nrow(IDX) == nsite, ncol(IDX) == B)
  W <- wts(IDX, sid, nsite)
  ok <- ref$RUN_OK == 1 & Reduce(`&`, lapply(METRICS, function(m) is.finite(ref[[paste0(m, "_p")]]) & is.finite(ref[[paste0(m, "_o")]])))
  idx <- which(ok)
  PER[[s]] <- score_rows(ref, idx, W, s)
  DRAWS[[s]] <- setNames(lapply(HEAD, function(m) { o <- ref[[paste0(m, "_o")]][idx]; p <- ref[[paste0(m, "_p")]][idx]; bs <- mk_sums(W[idx, , drop = FALSE], o, p)
    list(ratio = st_ratio(bs), bias = st_bias(bs), rmse = st_rmse(bs)) }), HEAD)
  POP[[s]] <- data.table(set = s, set_label = SETS[[s]], n_results = n_all, n_scored = length(idx), n_sites = nsite, draws = src,
    smd_min = min(ref$SCORE_MINDBH_USED), smd_median = median(ref$SCORE_MINDBH_USED), smd_max = max(ref$SCORE_MINDBH_USED),
    mean_iv = mean(ref$iv[idx]), churn_flag_share = mean(ref$CHURN_FLAG[idx] == 1, na.rm = TRUE), tag_stable = paste(unique(ref$TAG_STABLE), collapse = "|"))
  ## A3 style self check on the point sample (as the core)
  for (m in c("TOTVOL", "BA")) { o <- ref[[paste0(m, "_o")]][idx]; p <- ref[[paste0(m, "_p")]][idx]; S <- mk_sums(NULL, o, p); cf <- ols_coef(p, o)
    stopifnot(abs(st_rmse(S) - rmse_pct(o, p)) < 1e-9, abs(st_bias(S) - bias_pct(o, p)) < 1e-9, abs(st_slope(S) - cf[["slope"]]) < 1e-9) }
  ## S0 on the frozen set: bench141 common population (osm failure dropped), same draws, same rounding
  if (s == "mnapfrz_c") {
    REF <- fread(file.path(H, "in/cardinal/bench141_perset_v141LT_mnap_c_REF.csv"))
    idx98 <- which(ok & ref$STAND != "MNAP__Debsconeags_287_287__2004_2015_C")
    X <- score_rows(ref, idx98, W, s)
    cols <- c("n", "mean_obs", "mean_pred", "bias_pct", "bias_lo", "bias_hi", "rmse_pct", "rmse_lo", "rmse_hi", "intercept", "intercept_lo", "intercept_hi", "slope", "slope_lo", "slope_hi", "r2")
    X <- X[match(REF$metric, metric)]
    dd <- sapply(cols, function(k) max(abs(X[[k]] - REF[[k]])))
    S0 <- data.table(check = "S0", column = cols, max_abs_diff = dd, pass = dd <= 0.0011)
    fwrite(S0, file.path(TAB, "p15-S0-scoring-identity_DATA_2026-09-26.csv"))
    cat(sprintf("S0 %s: worst abs diff %.4g over %d rows x %d columns\n", if (all(S0$pass)) "PASS" else "FAIL", max(dd), nrow(REF), length(cols)))
    if (!all(S0$pass)) { cat("S0_FAIL\n"); quit(status = 2) }
  }
  cat(sprintf("%-11s results=%d scored=%d sites=%d draws: %s\n", s, n_all, length(idx), nsite, src))
}
PERSET <- rbindlist(PER); fwrite(PERSET, file.path(TAB, "p15-perset-scores_DATA_2026-09-26.csv"))
fwrite(rbindlist(POP), file.path(TAB, "p15-population_DATA_2026-09-26.csv"))
fwrite(PERSET[metric %in% HEAD, .(set, set_label, metric, n, mean_obs, mean_pred, ratio_op, ratio_lo, ratio_hi, bias_pct, bias_lo, bias_hi, rmse_pct, rmse_lo, rmse_hi)],
       file.path(TAB, "p15-headline-BA-TPH-QMD-TOTVOL_DATA_2026-09-26.csv"))
## unpaired contrasts from independent draws
CT <- list(); pairs <- list(c("mnap_c", "mnap_tnc_c"), c("mnap_c", "mnapfrz_c"), c("mnap_tnc_c", "mnapfrz_c"))
pairs <- Filter(function(pp) all(pp %in% names(SETS)), pairs)
for (pp in pairs) for (m in HEAD) for (st in c("ratio", "bias", "rmse")) {
  a <- DRAWS[[pp[1]]][[m]][[st]]; b <- DRAWS[[pp[2]]][[m]][[st]]; d <- a - b
  pa <- PERSET[set == pp[1] & metric == m]; pb <- PERSET[set == pp[2] & metric == m]
  pt <- switch(st, ratio = pa$ratio_op - pb$ratio_op, bias = pa$bias_pct - pb$bias_pct, rmse = pa$rmse_pct - pb$rmse_pct)
  CT[[length(CT) + 1L]] <- data.table(contrast = paste(pp, collapse = " minus "), metric = m, statistic = st, diff = r(pt, 4), lo95 = r(lo95(d), 4), hi95 = r(hi95(d), 4))
}
if (length(CT)) fwrite(rbindlist(CT), file.path(TAB, "p15-contrasts_DATA_2026-09-26.csv"))
cat("SCORE_DONE\n")

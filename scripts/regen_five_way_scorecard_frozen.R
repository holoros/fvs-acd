# regen_five_way_scorecard.R
# Regenerate the FVS-ACD five-way accuracy scorecard from the per-stand benchmark
# result files (cb_*_results.csv), on the SAME harness as the FROZEN operational
# model AcadianGY_12.10.1.r (cb_v12101_results.csv). This replaces the stale, internally
# inconsistent 3 July scorecard_five_v1210.csv, whose pooled TOTVOL read about +4% (over)
# and TOPHT about +9%. Scored on the frozen harness, v12.10.1 pooled should read
# BA about -10%, TOPHT about +3%, TOTVOL about -4% (matching the freeze recipe table).
#
# Every model is re-scored from its current per-stand cb_*_results.csv so all models sit
# on one harness and the frozen numbers reproduce. Aggregates only; FIA true coordinates
# never leave Cardinal. Browser-free, non-interactive, headless. Run on Cardinal.
#
#   Rscript regen_five_way_scorecard.R
#
# ============================================================================
# CONFIG  ---- edit this single block on Cardinal ----
# ============================================================================
# Model label -> per-stand results CSV in ~/magplot/verify/. Each file shares columns
# STAND, PROV, esi_cov, and per-metric X_t1 / X_o / X_p for the nine metrics, plus ING_p.
# v12.10.1 (cb_v12101_results.csv) is the FROZEN, authoritative model.
VERIFY_DIR <- path.expand("~/magplot/verify")

MODEL_FILES <- list(
  "v12.5.0"  = "cb_v125_frozen_results.csv",
  "v12.7.0"  = "cb_v1270_frozen_results.csv",
  "v12.7.1"  = "cb_v1271_frozen_results.csv",
  "v12.9.x"  = "cb_v12101_results.csv",
  "v12.10.1" = "cb_v12101_results.csv"   # FROZEN operational model, authoritative
)

# OSM per-stand results filename is not yet confirmed on Cardinal. Set OSM_FILE to the
# correct name if you know it; otherwise the script tries the candidates in order and,
# if none is found, SKIPS OSM with a warning so the rest of the scorecard still runs.
OSM_LABEL      <- "OSM"
OSM_FILE       <- "cb_osm_results.csv"
OSM_CANDIDATES <- c("magplot_osm_verify_results.csv", "cb_osm_results.csv")

# Output (written on Cardinal)
OUT_CSV   <- "/users/PUOM0008/crsfaaron/magplot/verify/scorecard_five_v1210_frozen.csv"
ERROR_LOG <- "/users/PUOM0008/crsfaaron/magplot/verify/error_log.txt"

# Metrics scored (per-metric columns are METRIC_o / METRIC_p / METRIC_t1)
METRICS <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")

# ============================================================================
# THRESHOLDS  (named constants; documented flag rule)
# ============================================================================
# GREEN  if abs(bias_pct) < FLAG_BIAS_GREEN  AND nse > FLAG_NSE_GREEN
# RED    if abs(bias_pct) >= FLAG_BIAS_RED    OR  nse < FLAG_NSE_RED
# YELLOW otherwise
FLAG_BIAS_GREEN <- 5    # percent
FLAG_BIAS_RED   <- 10   # percent
FLAG_NSE_GREEN  <- 0.6
FLAG_NSE_RED    <- 0.4

# Bootstrap CI on bias_pct
BOOT_N    <- 2000
BOOT_SEED <- 42

# Strata (subset labels). Domain rule for POOLED_indomain matches bench_parity INDOMAIN:
#   a stand is in-domain if esi_cov == TRUE OR PROV == "NB". NB is always in-domain by
#   definition (the Acadian core); QC stands are in-domain only where the operational
#   ESI surface covers them (esi_cov TRUE), excluding the Quebec ESI over-read edge.
STRATA <- c("POOLED", "NB", "QC", "POOLED_indomain")

# ============================================================================
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})

main <- function() {
  setwd(VERIFY_DIR)

  # ---- resolve OSM file (explicit override, then candidate search, else skip) ----
  files <- MODEL_FILES
  osm_resolved <- NA_character_
  if (!is.na(OSM_FILE) && nzchar(OSM_FILE) && file.exists(OSM_FILE)) {
    osm_resolved <- OSM_FILE
  } else {
    hit <- OSM_CANDIDATES[file.exists(OSM_CANDIDATES)]
    if (length(hit) >= 1) osm_resolved <- hit[1]
  }
  if (!is.na(osm_resolved)) {
    files[[OSM_LABEL]] <- osm_resolved
    cat(sprintf("OSM: using per-stand file '%s'\n", osm_resolved))
  } else {
    cat(sprintf("WARNING: no OSM per-stand results file found (checked %s). Skipping %s.\n",
                paste(OSM_CANDIDATES, collapse=", "), OSM_LABEL))
  }

  # ---- load + dedup each model file ----
  load_one <- function(lbl, fn) {
    if (!file.exists(fn)) {
      cat(sprintf("WARNING: file for model '%s' not found: %s -- skipping this model\n", lbl, fn))
      return(NULL)
    }
    d <- fread(fn)
    d[, STAND := as.character(STAND)]
    if (!"PROV"    %in% names(d)) d[, PROV := NA_character_]
    if (!"esi_cov" %in% names(d)) d[, esi_cov := NA]
    d[, esi_cov := as.logical(esi_cov)]
    nb <- nrow(d)
    d <- d[!duplicated(STAND)]                 # keep first of any duplicate STAND rows
    if (nrow(d) < nb) cat(sprintf("  %s: dropped %d duplicate STAND rows (%d -> %d)\n",
                                  lbl, nb - nrow(d), nb, nrow(d)))
    d
  }
  loaded <- Map(load_one, names(files), unlist(files))
  loaded <- loaded[!vapply(loaded, is.null, logical(1))]
  if (!length(loaded)) stop("No model result files could be loaded.")

  # ---- subset rows for a stratum (documented domain rule) ----
  subset_rows <- function(d, stratum) {
    esi <- d$esi_cov; esi[is.na(esi)] <- FALSE
    switch(stratum,
      POOLED           = d,
      NB               = d[PROV == "NB"],
      QC               = d[PROV == "QC"],
      POOLED_indomain  = d[esi | PROV == "NB"],   # bench_parity INDOMAIN rule
      stop("unknown stratum ", stratum))
  }

  # ---- metrics for one obs/pred pair ----
  score_pair <- function(o, p) {
    ok <- is.finite(o) & is.finite(p); o <- o[ok]; p <- p[ok]
    n <- length(o)
    if (n < 3) return(NULL)
    sst <- sum((o - mean(o))^2)
    list(n = n, obs_mean = mean(o), pred_mean = mean(p),
         bias_pct = 100 * (mean(p) - mean(o)) / mean(o),
         rmse = sqrt(mean((p - o)^2)), mae = mean(abs(p - o)),
         nse  = if (sst > 0) 1 - sum((o - p)^2) / sst else NA_real_,
         cor  = if (sd(o) > 0 & sd(p) > 0) suppressWarnings(cor(o, p)) else NA_real_)
  }

  # ---- stratified (by PROV) bootstrap CI on bias_pct ----
  # Resample stands with replacement within each PROV level, preserving NB/QC counts,
  # then recompute bias_pct. 2000 replicates, seeded per stratum-model-metric for
  # reproducibility independent of loop order.
  boot_bias_ci <- function(prov, o, p, seed) {
    ok <- is.finite(o) & is.finite(p)
    prov <- prov[ok]; o <- o[ok]; p <- p[ok]
    if (length(o) < 3) return(c(NA_real_, NA_real_))
    idx_by <- split(seq_along(o), prov)
    set.seed(seed)
    bs <- numeric(BOOT_N)
    for (b in seq_len(BOOT_N)) {
      samp <- unlist(lapply(idx_by, function(ii) {
        if (length(ii) == 1L) ii else sample(ii, length(ii), replace = TRUE)
      }), use.names = FALSE)
      ob <- o[samp]; pb <- p[samp]
      bs[b] <- 100 * (mean(pb) - mean(ob)) / mean(ob)
    }
    unname(quantile(bs, c(0.025, 0.975), na.rm = TRUE, type = 7))
  }

  flag_of <- function(bias_pct, nse) {
    ab <- abs(bias_pct)
    if (!is.finite(ab) || !is.finite(nse)) return("red")
    if (ab < FLAG_BIAS_GREEN && nse > FLAG_NSE_GREEN) return("green")
    if (ab >= FLAG_BIAS_RED  || nse < FLAG_NSE_RED)   return("red")
    "yellow"
  }

  # ---- score every model x stratum x metric ----
  out <- list()
  model_labels <- names(loaded)
  for (si in seq_along(STRATA)) {
    stratum <- STRATA[si]
    for (mi in seq_along(model_labels)) {
      lbl <- model_labels[mi]
      dd  <- subset_rows(loaded[[lbl]], stratum)
      if (nrow(dd) < 3) next
      for (ki in seq_along(METRICS)) {
        m  <- METRICS[ki]
        oc <- paste0(m, "_o"); pc <- paste0(m, "_p")
        if (!all(c(oc, pc) %in% names(dd))) next
        o <- dd[[oc]]; p <- dd[[pc]]
        sc <- score_pair(o, p)
        if (is.null(sc)) next
        seed <- BOOT_SEED + 1000L * si + 100L * mi + ki
        ok <- is.finite(o) & is.finite(p)
        ci <- boot_bias_ci(dd$PROV[ok], o[ok], p[ok], seed)
        out[[length(out) + 1L]] <- data.table(
          subset = stratum, model = lbl, metric = m,
          n = sc$n, obs_mean = sc$obs_mean, pred_mean = sc$pred_mean,
          bias_pct = sc$bias_pct, bias_lo95 = ci[1], bias_hi95 = ci[2],
          rmse = sc$rmse, mae = sc$mae, nse = sc$nse, cor = sc$cor,
          flag = flag_of(sc$bias_pct, sc$nse))
      }
    }
  }
  S <- rbindlist(out)
  if (!nrow(S)) stop("No scorecard rows were produced.")

  fwrite(S, OUT_CSV)
  cat(sprintf("\nWrote %s (%d rows)\n", OUT_CSV, nrow(S)))

  # ---- compact POOLED eyeball table: BA, TOPHT, TOTVOL across models ----
  cat("\n=== POOLED bias_pct (95% CI) | NSE | flag  for BA, TOPHT, TOTVOL ===\n")
  cat("    (frozen v12.10.1 pooled expected ~ BA -10, TOPHT +3, TOTVOL -4)\n")
  eye <- S[subset == "POOLED" & metric %in% c("BA","TOPHT","TOTVOL"),
           .(model, metric,
             bias = round(bias_pct, 2),
             lo95 = round(bias_lo95, 2), hi95 = round(bias_hi95, 2),
             nse = round(nse, 3), flag)]
  setorder(eye, metric, model)
  print(eye, row.names = FALSE)
  cat("\nDONE_REGEN_FIVE_WAY\n")
  invisible(NULL)
}

# All IO wrapped so any failure lands in error_log.txt rather than a bare stack.
tryCatch(
  main(),
  error = function(e) {
    msg <- sprintf("[%s] regen_five_way_scorecard.R ERROR: %s\n",
                   format(Sys.time(), "%Y-%m-%d %H:%M:%S"), conditionMessage(e))
    try(cat(msg, file = ERROR_LOG, append = TRUE), silent = TRUE)
    cat(msg)
    quit(status = 1, save = "no")
  }
)

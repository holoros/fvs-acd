# scorecard_rmse_frozen.R
# Accuracy-and-precision extension to the FVS-ACD frozen benchmark.
# Aaron's ask: percent bias inflates on low means, so feature metrics that
# combine accuracy and precision (RMSE, %RMSE), the observed-on-predicted
# regression slope, and a Robinson & Froese (2004) region of equivalence.
#
# Single frozen source: frozen_subsidiary_W.rds (n=705). Same conventions as
# scorecard_fortype_composite_frozen.R: bias_pct = 100*(mean(p)-mean(o))/mean(o),
# NSE = 1 - SSE/SST. Adds RMSE, %RMSE (=100*RMSE/mean_obs), MAE, a within-PROV
# stratified bootstrap 95% CI on %RMSE (2000 reps, seed 42), an OLS obs~pred
# regression, and a TOST equivalence test on slope and intercept.
#
# Writes: scorecard_rmse_frozen.csv, equivalence_frozen.csv,
#         equivalence_frozen_REGION.txt, composite_rmse_frozen.csv,
#         composite_metric_scores_rmse_frozen.csv, composite_rmse_frozen_FORMULA.txt
#
# Aggregates only. FIA true coordinates never leave Cardinal. Headless.
# Does NOT touch operational AcadianGY_*.r or git.
#   Rscript scorecard_rmse_frozen.R
# ============================================================================
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})

VERIFY_DIR <- path.expand("~/magplot/verify")
setwd(VERIFY_DIR)

OUT_SC     <- file.path(VERIFY_DIR, "scorecard_rmse_frozen.csv")
OUT_EQ     <- file.path(VERIFY_DIR, "equivalence_frozen.csv")
OUT_EQ_RGN <- file.path(VERIFY_DIR, "equivalence_frozen_REGION.txt")
OUT_COMP   <- file.path(VERIFY_DIR, "composite_rmse_frozen.csv")
OUT_MS     <- file.path(VERIFY_DIR, "composite_metric_scores_rmse_frozen.csv")
OUT_FORM   <- file.path(VERIFY_DIR, "composite_rmse_frozen_FORMULA.txt")

# Five models. Label -> W column prefix. v12.9.x and v12.10.1 share the frozen
# per-stand file (cb_v12101); W carries them as v129x.* and v1210.* (verified
# identical below).
MODELS  <- c("v12.5.0"="v125", "v12.7.0"="v1270", "v12.9.x"="v129x",
             "v12.10.1"="v1210", "OSM"="osm")
METRICS <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")

# PRIMARY composite weights: total volume and stumpage value highest (3),
# other merchantable outputs next (2), structure metrics last (1); sum = 16.
PRIMARY_W <- c(BA=1, SDI=1, QMD=1, TOPHT=1,
               TOTVOL=3, MERCHVOL=2, SAWVOL=2, BIOMASS=2, VALUE=3)

BOOT_N <- 2000L; BOOT_SEED <- 42L
CAP    <- 100     # %RMSE cap for the composite: %RMSE 0 -> 100, >=100 -> 0
# Region of equivalence (Robinson & Froese 2004 style TOST, alpha = 0.05 -> 90% CI)
EQ_ALPHA       <- 0.05
INT_REGION_FRAC <- 0.25   # intercept region = +/- 25% of mean observed
SLOPE_REGION_HW <- 0.25   # slope region = 1 +/- 0.25

# ---------------------------------------------------------------------------
W <- readRDS("frozen_subsidiary_W.rds")
setDT(W)
W[, STAND := as.character(STAND)]
W[, PROV  := as.character(PROV)]
W[, esi_cov := as.logical(esi_cov)]

# adversarial check: v12.9.x and v12.10.1 columns should be identical
id_ok <- all(vapply(METRICS, function(m)
  isTRUE(all.equal(W[[paste0("v129x.", m)]], W[[paste0("v1210.", m)]])), logical(1)))
cat(sprintf("CHECK v12.9.x == v12.10.1 columns identical: %s\n", id_ok))

# ---- accuracy/precision metrics for an observed/predicted pair ----
score_pair <- function(o, p) {
  ok <- is.finite(o) & is.finite(p); o <- o[ok]; p <- p[ok]
  n <- length(o); if (n < 3) return(NULL)
  mo  <- mean(o)
  sst <- sum((o - mean(o))^2)
  rmse <- sqrt(mean((o - p)^2))
  list(n = n, mean_obs = mo,
       rmse     = rmse,
       pct_rmse = 100 * rmse / mo,
       mae      = mean(abs(o - p)),
       bias_pct = 100 * (mean(p) - mo) / mo,
       nse      = if (sst > 0) 1 - sum((o - p)^2) / sst else NA_real_)
}

# ---- within-PROV stratified bootstrap CI on %RMSE ----
boot_pctrmse_ci <- function(prov, o, p, seed) {
  ok <- is.finite(o) & is.finite(p); prov <- prov[ok]; o <- o[ok]; p <- p[ok]
  if (length(o) < 3) return(c(NA_real_, NA_real_))
  idx_by <- split(seq_along(o), prov)
  set.seed(seed)
  bs <- numeric(BOOT_N)
  for (b in seq_len(BOOT_N)) {
    samp <- unlist(lapply(idx_by, function(ii)
      if (length(ii) == 1L) ii else sample(ii, length(ii), replace = TRUE)),
      use.names = FALSE)
    ob <- o[samp]; pb <- p[samp]
    bs[b] <- 100 * sqrt(mean((ob - pb)^2)) / mean(ob)
  }
  unname(quantile(bs, c(0.025, 0.975), na.rm = TRUE, type = 7))
}

# ---- OLS observed = a + b*predicted, with TOST equivalence ----
equiv_pair <- function(o, p, mean_obs) {
  ok <- is.finite(o) & is.finite(p); o <- o[ok]; p <- p[ok]
  n <- length(o); if (n < 3) return(NULL)
  fit <- lm(o ~ p)
  cf  <- coef(fit); sm <- summary(fit)
  a  <- unname(cf[1]); b <- unname(cf[2])
  se <- sm$coefficients[, "Std. Error"]
  se_a <- unname(se[1]); se_b <- unname(se[2])
  tcrit <- qt(1 - EQ_ALPHA, df = n - 2)      # 90% CI for TOST at alpha = 0.05
  int_hw   <- INT_REGION_FRAC * mean_obs      # intercept region half-width
  a_lo <- a - tcrit * se_a; a_hi <- a + tcrit * se_a
  b_lo <- b - tcrit * se_b; b_hi <- b + tcrit * se_b
  int_equiv   <- (a_lo > -int_hw)        && (a_hi <  int_hw)
  slope_equiv <- (b_lo > 1 - SLOPE_REGION_HW) && (b_hi < 1 + SLOPE_REGION_HW)
  list(n = n, slope = b, intercept = a, r2 = sm$r.squared,
       slope_ci_lo = b_lo, slope_ci_hi = b_hi,
       int_ci_lo = a_lo, int_ci_hi = a_hi,
       int_region_hw = int_hw,
       intercept_equiv = int_equiv, slope_equiv = slope_equiv,
       overall_equiv = (int_equiv && slope_equiv))
}

# ---- strata (row filters on W) ----
strata <- list(
  "POOLED_indomain" = W[esi_cov %in% TRUE | PROV == "NB"],
  "Softwood"        = W[fortype == "Softwood"],
  "Mixedwood"       = W[fortype == "Mixedwood"],
  "Hardwood"        = W[fortype == "Hardwood"],
  "NB"              = W[PROV == "NB"],
  "QC"              = W[PROV == "QC"])

# ============================================================================
# PART 1  RMSE / %RMSE scorecard  (+ bootstrap CI on %RMSE)
# ============================================================================
sc_rows <- list(); eq_rows <- list()
for (si in seq_along(strata)) {
  sn <- names(strata)[si]; dft <- strata[[sn]]
  for (mi in seq_along(MODELS)) {
    lbl <- names(MODELS)[mi]; pref <- MODELS[[lbl]]
    for (ki in seq_along(METRICS)) {
      m <- METRICS[ki]
      o <- dft[[paste0(m, "_o")]]; p <- dft[[paste0(pref, ".", m)]]
      sc <- score_pair(o, p); if (is.null(sc)) next
      seed <- BOOT_SEED + 10000L * si + 100L * mi + ki
      ok <- is.finite(o) & is.finite(p)
      ci <- boot_pctrmse_ci(dft$PROV[ok], o[ok], p[ok], seed)
      sc_rows[[length(sc_rows) + 1L]] <- data.table(
        stratum = sn, model = lbl, metric = m, n = sc$n,
        mean_obs = round(sc$mean_obs, 4),
        rmse = round(sc$rmse, 4),
        pct_rmse = round(sc$pct_rmse, 3),
        pct_rmse_lo95 = round(ci[1], 3),
        pct_rmse_hi95 = round(ci[2], 3),
        mae = round(sc$mae, 4),
        bias_pct = round(sc$bias_pct, 3),
        nse = round(sc$nse, 4))
      eq <- equiv_pair(o, p, sc$mean_obs); if (is.null(eq)) next
      eq_rows[[length(eq_rows) + 1L]] <- data.table(
        stratum = sn, model = lbl, metric = m, n = eq$n,
        mean_obs = round(sc$mean_obs, 4),
        slope = round(eq$slope, 4), intercept = round(eq$intercept, 4),
        r2 = round(eq$r2, 4),
        slope_ci_lo = round(eq$slope_ci_lo, 4), slope_ci_hi = round(eq$slope_ci_hi, 4),
        int_ci_lo = round(eq$int_ci_lo, 4), int_ci_hi = round(eq$int_ci_hi, 4),
        int_region_hw = round(eq$int_region_hw, 4),
        intercept_equiv = eq$intercept_equiv, slope_equiv = eq$slope_equiv,
        overall_equiv = eq$overall_equiv)
    }
  }
}
SC <- rbindlist(sc_rows)
SC[, stratum := factor(stratum, levels = names(strata))]
SC[, model   := factor(model,   levels = names(MODELS))]
SC[, metric  := factor(metric,  levels = METRICS)]
setorder(SC, stratum, metric, model)
fwrite(SC, OUT_SC)
cat(sprintf("PART 1: wrote %s (%d rows).\n", OUT_SC, nrow(SC)))

EQ <- rbindlist(eq_rows)
EQ[, stratum := factor(stratum, levels = names(strata))]
EQ[, model   := factor(model,   levels = names(MODELS))]
EQ[, metric  := factor(metric,  levels = METRICS)]
setorder(EQ, stratum, metric, model)
fwrite(EQ, OUT_EQ)
cat(sprintf("PART 2: wrote %s (%d rows).\n", OUT_EQ, nrow(EQ)))

writeLines(c(
  "FVS-ACD frozen benchmark: region of equivalence (Robinson & Froese 2004 style)",
  "==============================================================================",
  "Regression: observed = a + b * predicted, fit by OLS per model x metric x stratum.",
  "Equivalence is assessed with two one-sided tests (TOST) at alpha = 0.05, which",
  "corresponds to checking that the 90% confidence interval of the parameter lies",
  "entirely inside the stated region of equivalence.",
  "",
  "Intercept region: a is equivalent to zero if its 90% CI falls within",
  "  +/- 25% of the mean observed value for that metric x stratum",
  "  (region half-width = 0.25 * mean_obs). A proportional region is used",
  "  because the nine metrics span very different units and magnitudes.",
  "",
  "Slope region: b is equivalent to one if its 90% CI falls within 1 +/- 0.25,",
  "  i.e. the interval [0.75, 1.25].",
  "",
  "overall_equiv = intercept_equiv AND slope_equiv (both parameters inside their",
  "  regions). This is the joint Robinson-Froese equivalence flag: the model is",
  "  statistically indistinguishable from a 1:1 observed-predicted line within the",
  "  region we are willing to treat as practically equivalent.",
  "",
  "Note on direction: observed is regressed ON predicted (the calibration/",
  "  validation convention), so slope > 1 means the model under-predicts the",
  "  high end and slope < 1 means it over-predicts it."),
  OUT_EQ_RGN)
cat(sprintf("PART 2: wrote %s\n", OUT_EQ_RGN))

# ============================================================================
# PART 3  COMPOSITE REBUILT ON %RMSE
# ============================================================================
# metric_score = 100 * max(0, 1 - %RMSE / CAP), CAP = 100.
# This single metric already blends accuracy and precision.
metric_score_rmse <- function(pct_rmse) 100 * pmax(0, 1 - pct_rmse / CAP)

comp_strata <- c("POOLED_indomain","Softwood","Mixedwood","Hardwood")
comp_rows <- list(); ms_rows <- list()
for (sn in comp_strata) {
  dft <- strata[[sn]]
  for (lbl in names(MODELS)) {
    pref <- MODELS[[lbl]]
    ms <- vapply(METRICS, function(m) {
      sc <- score_pair(dft[[paste0(m, "_o")]], dft[[paste0(pref, ".", m)]])
      if (is.null(sc)) return(NA_real_)
      metric_score_rmse(sc$pct_rmse)
    }, numeric(1))
    w <- PRIMARY_W[METRICS]
    comp_rows[[length(comp_rows) + 1L]] <- data.table(
      stratum = sn, model = lbl, n = nrow(dft),
      composite_primary_rmse     = round(sum(ms * w) / sum(w), 2),
      composite_equalweight_rmse = round(mean(ms), 2))
    ms_rows[[length(ms_rows) + 1L]] <- data.table(
      stratum = sn, model = lbl, metric = METRICS,
      metric_score_rmse = round(unname(ms), 2))
  }
}
COMP <- rbindlist(comp_rows)

# reference: prior bias-based composite
BIAS_COMP <- fread("composite_scores_frozen.csv")
BIAS_COMP <- BIAS_COMP[, .(stratum, model,
                           composite_primary_bias = composite_primary)]
COMP <- merge(COMP, BIAS_COMP, by = c("stratum", "model"), all.x = TRUE, sort = FALSE)
COMP[, stratum := factor(stratum, levels = comp_strata)]
COMP[, model   := factor(model,   levels = names(MODELS))]
COMP[, rank_primary_rmse := frank(-composite_primary_rmse, ties.method = "min"), by = stratum]
COMP[, rank_primary_bias := frank(-composite_primary_bias, ties.method = "min"), by = stratum]
setcolorder(COMP, c("stratum","model","n",
                    "composite_primary_rmse","rank_primary_rmse",
                    "composite_equalweight_rmse",
                    "composite_primary_bias","rank_primary_bias"))
setorder(COMP, stratum, rank_primary_rmse)
fwrite(COMP, OUT_COMP)
fwrite(rbindlist(ms_rows), OUT_MS)
cat(sprintf("PART 3: wrote %s (%d rows) + %s\n", OUT_COMP, nrow(COMP), OUT_MS))

writeLines(c(
  "FVS-ACD %RMSE composite score definition (0 to 100, higher is better)",
  "=====================================================================",
  "Per metric per model on a given stratum:",
  "  %RMSE        = 100 * RMSE / mean(observed)",
  "  metric_score = 100 * max(0, 1 - %RMSE / CAP),  CAP = 100",
  "                 (%RMSE 0 -> 100; %RMSE 100% or worse -> 0)",
  "  This single score blends accuracy and precision, which is what was asked:",
  "  it penalises both systematic error and scatter, unlike a bias-only score.",
  "",
  "PRIMARY composite (volume + value weighted) = weighted mean of the nine",
  "  metric_score values with volume and value carrying the highest weight:",
  "    TOTVOL 3, VALUE 3, MERCHVOL 2, SAWVOL 2, BIOMASS 2, BA 1, SDI 1, QMD 1,",
  "    TOPHT 1  (sum of weights = 16).",
  "EQUAL-WEIGHT composite (reference) = simple mean of the nine metric_score",
  "  values (every metric weight 1).",
  "",
  "Reference column composite_primary_bias is the prior bias-and-NSE composite",
  "  (composite_scores_frozen.csv), carried alongside so the change from the",
  "  bias basis to the %RMSE basis is visible in one table.",
  "",
  "Strata scored: POOLED_indomain (esi_cov TRUE or PROV==NB, n=705); Softwood;",
  "  Mixedwood; Hardwood. Frozen basis: frozen_subsidiary_W.rds."),
  OUT_FORM)
cat(sprintf("PART 3: wrote %s\n", OUT_FORM))

# ============================================================================
# CONSOLE REPORT (adversarial self-checks)
# ============================================================================
cat("\n===== SELF-CHECK: %RMSE = 100*RMSE/mean_obs (POOLED, v12.10.1, key metrics) =====\n")
print(SC[stratum == "POOLED_indomain" & model == "v12.10.1" &
         metric %in% c("BA","TOTVOL","VALUE"),
         .(metric, mean_obs, rmse, pct_rmse, bias_pct, nse)], row.names = FALSE)

cat("\n===== SELF-CHECK: hardwood %RMSE ~76 for v12.10.1 TOTVOL, ~81 VALUE; OSM ~75 =====\n")
print(SC[stratum == "Hardwood" & metric %in% c("TOTVOL","VALUE") &
         model %in% c("v12.10.1","OSM"),
         .(model, metric, mean_obs, bias_pct, pct_rmse)], row.names = FALSE)

cat("\n===== POOLED equivalence (key metrics): slope / intercept / flags =====\n")
print(EQ[stratum == "POOLED_indomain" & metric %in% c("BA","TOTVOL","VALUE"),
         .(model, metric, slope, intercept, r2, slope_equiv, intercept_equiv, overall_equiv)],
      row.names = FALSE)

cat("\n===== POOLED composite ranking: %RMSE vs bias =====\n")
print(COMP[stratum == "POOLED_indomain",
           .(model, composite_primary_rmse, rank_primary_rmse,
             composite_primary_bias, rank_primary_bias)], row.names = FALSE)

cat("\n===== Composite by forest type (primary %RMSE) =====\n")
print(dcast(COMP, model ~ stratum, value.var = "composite_primary_rmse"), row.names = FALSE)

cat("\nDONE_RMSE_SCORECARD\n")

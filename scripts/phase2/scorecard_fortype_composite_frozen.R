# scorecard_fortype_composite_frozen.R
# Two analytical additions to the FVS-ACD August benchmark, on the VERIFIED FROZEN basis.
#
#   PART 1  Full nine-metric five-way scorecard STRATIFIED BY FOREST TYPE
#           (Softwood, Mixedwood, Hardwood). Level bias percent, stratified
#           (within-PROV) bootstrap 95 percent CI on the bias, NSE, and a
#           green/yellow/red flag. Written to scorecard_five_by_fortype_frozen.csv.
#
#   PART 2  Weighted overall composite score (0 to 100, higher is better) per model,
#           on the POOLED in-domain set and on each of the three forest types.
#           PRIMARY (equal weight) and SENSITIVITY (merch outputs weighted 2x)
#           composites. Written to composite_scores_frozen.csv (+ a FORMULA sidecar).
#
# Single frozen source: frozen_subsidiary_W.rds (built by frozen_subsidiary.R on the
# frozen harness). W carries STAND, PROV, esi_cov, observed METRIC_o, per-model
# predictions (v125.*, v1270.*, v129x.*, v1210.*, osm.*), and the committed fortype
# label (softwood-BA fraction rule: <=25% HW = Softwood, >=75% = Hardwood, else
# Mixedwood; 20 unclassified = "Unknown"). Reused, not reinvented.
#
# Aggregates only. FIA true coordinates never leave Cardinal. Headless, non-interactive.
# Does NOT touch operational AcadianGY_*.r or git.
#   Rscript scorecard_fortype_composite_frozen.R
# ============================================================================
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})

VERIFY_DIR <- path.expand("~/magplot/verify")
setwd(VERIFY_DIR)

OUT_FT       <- file.path(VERIFY_DIR, "scorecard_five_by_fortype_frozen.csv")
OUT_COMP     <- file.path(VERIFY_DIR, "composite_scores_frozen.csv")
OUT_FORMULA  <- file.path(VERIFY_DIR, "composite_scores_frozen_FORMULA.txt")

# Five models (drop v12.7.1 to match the shipped five-way). Label -> W column prefix.
MODELS <- c("v12.5.0"="v125", "v12.7.0"="v1270", "v12.9.x"="v129x",
            "v12.10.1"="v1210", "OSM"="osm")

METRICS    <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
STRUCTURE  <- c("BA","SDI","QMD","TOPHT")                       # weight 1 in primary
MERCH_OUT  <- c("TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
# PRIMARY (volume + value) weights: total volume and stumpage value highest (3),
# the other merchantable outputs next (2), structure metrics last (1); sum = 16.
PRIMARY_W  <- c(BA=1, SDI=1, QMD=1, TOPHT=1,
                TOTVOL=3, MERCHVOL=2, SAWVOL=2, BIOMASS=2, VALUE=3)

# Flag rule (same named constants as the pooled scorecard)
FLAG_BIAS_GREEN <- 5; FLAG_BIAS_RED <- 10; FLAG_NSE_GREEN <- 0.6; FLAG_NSE_RED <- 0.4
# Bootstrap
BOOT_N <- 2000L; BOOT_SEED <- 42L
# Composite: bias scored to 0 at |bias| >= BIAS_CAP percent
BIAS_CAP <- 20

# ---------------------------------------------------------------------------
W <- readRDS("frozen_subsidiary_W.rds")
setDT(W)
W[, STAND := as.character(STAND)]
W[, PROV  := as.character(PROV)]
W[, esi_cov := as.logical(esi_cov)]

# ---- point metrics for an observed/predicted pair ----
score_pair <- function(o, p) {
  ok <- is.finite(o) & is.finite(p); o <- o[ok]; p <- p[ok]
  n <- length(o); if (n < 3) return(NULL)
  sst <- sum((o - mean(o))^2)
  list(n = n,
       bias_pct = 100 * (mean(p) - mean(o)) / mean(o),
       nse = if (sst > 0) 1 - sum((o - p)^2) / sst else NA_real_)
}

# ---- stratified (within-PROV) bootstrap CI on bias_pct ----
boot_bias_ci <- function(prov, o, p, seed) {
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

# ============================================================================
# PART 1  FOREST-TYPE SCORECARD  (exclude the 20 Unknown stands)
# ============================================================================
FORTYPES <- c("Softwood","Mixedwood","Hardwood")
model_lbls <- names(MODELS)

rows <- list()
for (fi in seq_along(FORTYPES)) {
  ft <- FORTYPES[fi]
  dft <- W[fortype == ft]
  for (mi in seq_along(model_lbls)) {
    lbl <- model_lbls[mi]; pref <- MODELS[[lbl]]
    for (ki in seq_along(METRICS)) {
      m <- METRICS[ki]
      o <- dft[[paste0(m, "_o")]]; p <- dft[[paste0(pref, ".", m)]]
      sc <- score_pair(o, p); if (is.null(sc)) next
      seed <- BOOT_SEED + 1000L * fi + 100L * mi + ki
      ok <- is.finite(o) & is.finite(p)
      ci <- boot_bias_ci(dft$PROV[ok], o[ok], p[ok], seed)
      rows[[length(rows) + 1L]] <- data.table(
        model = lbl, fortype = ft, metric = m, n = sc$n,
        bias_pct = round(sc$bias_pct, 3),
        bias_lo95 = round(ci[1], 3), bias_hi95 = round(ci[2], 3),
        nse = round(sc$nse, 4), flag = flag_of(sc$bias_pct, sc$nse))
    }
  }
}
FT <- rbindlist(rows)
FT[, metric := factor(metric, levels = METRICS)]
FT[, model  := factor(model,  levels = model_lbls)]
FT[, fortype := factor(fortype, levels = FORTYPES)]
setorder(FT, fortype, metric, model)
fwrite(FT, OUT_FT)
cat(sprintf("PART 1: wrote %s (%d rows). Excluded 20 Unknown stands.\n",
            OUT_FT, nrow(FT)))

# ============================================================================
# PART 2  WEIGHTED OVERALL COMPOSITE SCORE
# ============================================================================
# metric_score = 0.5*bias_score + 0.5*nse_score
#   bias_score = 100 * (1 - min(1, |bias_pct| / BIAS_CAP))
#   nse_score  = 100 * max(0, NSE)
# PRIMARY      = equal-weight mean of metric_score over the nine metrics
# SENSITIVITY  = weighted mean, merch outputs weight 2, structure metrics weight 1
metric_score <- function(bias_pct, nse) {
  bias_score <- 100 * (1 - pmin(1, abs(bias_pct) / BIAS_CAP))
  nse_score  <- 100 * pmax(0, nse)
  0.5 * bias_score + 0.5 * nse_score
}
composite_for <- function(dft, pref) {
  ms <- vapply(METRICS, function(m) {
    sc <- score_pair(dft[[paste0(m, "_o")]], dft[[paste0(pref, ".", m)]])
    if (is.null(sc)) return(NA_real_)
    metric_score(sc$bias_pct, sc$nse)
  }, numeric(1))
  w <- PRIMARY_W[METRICS]                       # volume + value weighted
  c(primary     = sum(ms * w) / sum(w),         # PRIMARY: volume + value weighting
    equalweight = mean(ms),                     # reference: every metric weight 1
    metricscores = ms)
}

# strata: POOLED in-domain (esi_cov TRUE OR PROV=="NB"); each forest type (full)
strata <- list(
  "POOLED_indomain" = W[esi_cov %in% TRUE | PROV == "NB"],
  "Softwood"        = W[fortype == "Softwood"],
  "Mixedwood"       = W[fortype == "Mixedwood"],
  "Hardwood"        = W[fortype == "Hardwood"])

comp_rows <- list(); ms_rows <- list()
for (sn in names(strata)) {
  dft <- strata[[sn]]
  for (lbl in model_lbls) {
    pref <- MODELS[[lbl]]
    cc <- composite_for(dft, pref)
    comp_rows[[length(comp_rows) + 1L]] <- data.table(
      stratum = sn, model = lbl, n = nrow(dft),
      composite_primary = round(unname(cc["primary"]), 2),
      composite_equalweight = round(unname(cc["equalweight"]), 2))
    msv <- cc[grepl("^metricscores", names(cc))]
    ms_rows[[length(ms_rows) + 1L]] <- data.table(
      stratum = sn, model = lbl, metric = METRICS,
      metric_score = round(unname(msv), 2))
  }
}
COMP <- rbindlist(comp_rows)
COMP[, stratum := factor(stratum, levels = names(strata))]
COMP[, model   := factor(model, levels = model_lbls)]
# ranks within stratum (1 = best), on each weighting
COMP[, rank_primary     := frank(-composite_primary,     ties.method = "min"), by = stratum]
COMP[, rank_equalweight := frank(-composite_equalweight, ties.method = "min"), by = stratum]
setorder(COMP, stratum, rank_primary)
fwrite(COMP, OUT_COMP)
fwrite(rbindlist(ms_rows),
       file.path(VERIFY_DIR, "composite_metric_scores_frozen.csv"))
cat(sprintf("PART 2: wrote %s (%d rows) + composite_metric_scores_frozen.csv\n",
            OUT_COMP, nrow(COMP)))

# formula sidecar (documents the composite in the outputs)
writeLines(c(
  "FVS-ACD frozen composite score definition (0 to 100, higher is better)",
  "=====================================================================",
  "Per metric per model on a given stratum:",
  "  bias_score   = 100 * (1 - min(1, |bias_pct| / 20))",
  "                 (0% bias -> 100; |bias| >= 20% -> 0)",
  "  nse_score    = 100 * max(0, NSE)",
  "  metric_score = 0.5 * bias_score + 0.5 * nse_score",
  "PRIMARY composite (volume + value weighted) = weighted mean of metric_score",
  "  with weights TOTVOL 3, VALUE 3, MERCHVOL 2, SAWVOL 2, BIOMASS 2, BA 1,",
  "  SDI 1, QMD 1, TOPHT 1 (sum 16). Total volume and stumpage value carry the",
  "  highest weight; this is the primary reported composite.",
  "EQUAL-WEIGHT composite (reference) = simple mean of metric_score over the 9",
  "  metrics; retained to show the ranking is not an artifact of the weighting.",
  "Strata: POOLED_indomain (esi_cov TRUE or PROV==NB); Softwood; Mixedwood; Hardwood.",
  "bias_pct and NSE are computed on the frozen basis (frozen_subsidiary_W.rds)."),
  OUT_FORMULA)

# ============================================================================
# CONSOLE REPORT
# ============================================================================
cat("\n===== PART 1 self-check: forest-type TOTVOL bias% (v12.10.1, OSM) =====\n")
print(FT[metric == "TOTVOL" & model %in% c("v12.10.1","OSM"),
         .(fortype, model, n, bias_pct, nse, flag)], row.names = FALSE)

cat("\n===== PART 2 POOLED in-domain composite ranking (primary = volume + value) =====\n")
print(COMP[stratum == "POOLED_indomain",
           .(rank_primary, model, composite_primary, composite_equalweight,
             rank_equalweight)], row.names = FALSE)

cat("\n===== PART 2 composites by forest type (primary) =====\n")
wide <- dcast(COMP, model ~ stratum, value.var = "composite_primary")
print(wide, row.names = FALSE)

cat("\n===== Ranking robustness (primary vs equal-weight) per stratum =====\n")
for (sn in names(strata)) {
  s <- COMP[stratum == sn]
  ord_p <- s[order(rank_primary)]$model; ord_e <- s[order(rank_equalweight)]$model
  cat(sprintf("  %-16s primary: %-45s | equal-weight: %-45s | identical order: %s\n",
      sn, paste(ord_p, collapse=" > "), paste(ord_e, collapse=" > "),
      identical(as.character(ord_p), as.character(ord_e))))
}
cat("\nDONE_FORTYPE_COMPOSITE\n")

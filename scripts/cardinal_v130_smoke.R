#!/usr/bin/env Rscript
# cardinal_v130_smoke.R
# -----------------------------------------------------------------------------
# Smoke test for a modified AcadianGY forest growth model on OSC Cardinal.
#
# Purpose: source a BASE model and a candidate V130 model, project the first
# 10 stands from the magplot verification tree list forward 10 years with each,
# and compare year-0 vs year-10 stand metrics. The test PASSES only if no stand
# errors under either model and all reported metrics are finite.
#
# Constraints: R 4.4.0, base R + dplyr/plyr/purrr only. No terra. Read-only
# against the verify inputs; does not touch the cluster job scheduler.
#
# Each model is sourced into its own environment (sys.source) so the two model
# definitions never collide in a single namespace.
# -----------------------------------------------------------------------------

suppressWarnings(suppressMessages({
  library(dplyr)
  library(plyr)
  library(purrr)
}))

# --- Configuration -----------------------------------------------------------

VERIFY_DIR <- "/users/PUOM0008/crsfaaron/magplot/verify/"
TREE_CSV   <- file.path(VERIFY_DIR, "magplot_tree_init.csv")
PAIRS_CSV  <- file.path(VERIFY_DIR, "magplot_pairs.csv")

BASE_MODEL <- Sys.getenv("BASE_MODEL", unset = path.expand("~/AcadianGY_12.10.2.r"))
V130_MODEL <- Sys.getenv("V130_MODEL", unset = path.expand("~/AcadianGY_13.0.r"))

N_STANDS <- 10L
N_YEARS  <- 10L

RESULTS_CSV <- path.expand("~/v130_smoke_results.csv")

# --- Helpers -----------------------------------------------------------------

fail <- function(reason) {
  cat(sprintf("SMOKE_FAIL: %s\n", reason))
  quit(save = "no", status = 1L)
}

# Cross-sectional stand-level snapshot from a tree list.
# Guards against empty tree lists, zero/NA expansion factors, and NA sizes.
stand_snapshot <- function(tr, stand_id, year) {
  na_row <- data.frame(
    STAND   = stand_id,
    YEAR    = year,
    NTREES  = 0L,
    BA      = NA_real_,
    TPH     = NA_real_,
    QMD     = NA_real_,
    TOPHT   = NA_real_,
    VOLPROXY = NA_real_,
    stringsAsFactors = FALSE
  )

  if (is.null(tr) || !is.data.frame(tr) || nrow(tr) == 0L) return(na_row)

  # keep only live, positive, finite records
  ok <- is.finite(tr$DBH) & is.finite(tr$EXPF) & tr$DBH > 0 & tr$EXPF > 0
  ok[is.na(ok)] <- FALSE
  tr <- tr[ok, , drop = FALSE]
  if (nrow(tr) == 0L) return(na_row)

  expf <- tr$EXPF
  dbh  <- tr$DBH
  ht   <- tr$HT

  totexpf <- sum(expf)
  if (!is.finite(totexpf) || totexpf <= 0) return(na_row)

  # BA (m2/ha):  0.00007854 * DBH(cm)^2 * EXPF, summed
  BA  <- sum(0.00007854 * dbh^2 * expf)
  # TPH (trees/ha)
  TPH <- totexpf
  # QMD (cm)
  QMD <- sqrt(sum(dbh^2 * expf) / totexpf)

  # Dominant-height proxy TOPHT: EXPF-weighted mean HT of the tallest (largest
  # DBH) trees whose cumulative EXPF, in descending DBH order, reaches 100
  # trees/ha. The tree that crosses 100 is included but weighted only by its
  # remaining share so the effective weight sums to exactly 100 (or to the
  # stand total if fewer than 100 stems/ha are present).
  ord    <- order(dbh, decreasing = TRUE)
  e_ord  <- expf[ord]
  h_ord  <- ht[ord]
  target <- min(100, totexpf)
  cum    <- cumsum(e_ord)
  last   <- which(cum >= target)[1]
  if (is.na(last)) last <- length(e_ord)
  w <- e_ord[seq_len(last)]
  # trim the crossing tree's weight so the set sums to exactly `target`
  prior <- if (last > 1) cum[last - 1] else 0
  w[last] <- target - prior
  h_sel <- h_ord[seq_len(last)]
  good  <- is.finite(h_sel) & is.finite(w) & w > 0
  TOPHT <- if (any(good)) sum(h_sel[good] * w[good]) / sum(w[good]) else NA_real_

  # Crude volume proxy (NOT NSVB): sum of 0.00007854*DBH^2 * HT * 0.5 * EXPF.
  # Sanity stand-in for total stand volume only; do not report as real volume.
  ht_v <- ifelse(is.finite(ht), ht, 0)
  VOLPROXY <- sum(0.00007854 * dbh^2 * ht_v * 0.5 * expf)

  data.frame(
    STAND    = stand_id,
    YEAR     = year,
    NTREES   = nrow(tr),
    BA       = BA,
    TPH      = TPH,
    QMD      = QMD,
    TOPHT    = TOPHT,
    VOLPROXY = VOLPROXY,
    stringsAsFactors = FALSE
  )
}

# Project one stand forward N_YEARS using a supplied one-year stepper function.
# Returns a list(y0 = snapshot, y10 = snapshot, error = character-or-NA).
project_stand <- function(step_fn, trees0, stand_row, ops, stand_id, nyears) {
  out <- list(
    y0    = stand_snapshot(trees0, stand_id, 0L),
    y10   = stand_snapshot(NULL, stand_id, nyears),
    error = NA_character_
  )

  res <- tryCatch({
    tr <- trees0
    for (yr in seq_len(nyears)) {
      if (is.null(tr) || nrow(tr) == 0L) break
      tr <- step_fn(tr, stand_row, ops)
    }
    tr
  }, error = function(e) {
    structure(list(), class = "smoke_error", msg = conditionMessage(e))
  })

  if (inherits(res, "smoke_error")) {
    out$error <- attr(res, "msg")
  } else {
    out$y10 <- stand_snapshot(res, stand_id, nyears)
  }
  out
}

# Run one full model: source into a fresh environment, project all stands.
run_model <- function(model_file, model_tag, tree_init, stand_init, ops,
                      stand_ids, nyears) {
  if (!file.exists(model_file)) {
    fail(sprintf("model file not found for %s: %s", model_tag, model_file))
  }

  model_env <- new.env(parent = globalenv())
  ok <- tryCatch({
    sys.source(model_file, envir = model_env)
    TRUE
  }, error = function(e) {
    cat(sprintf("ERROR sourcing %s (%s): %s\n", model_tag, model_file,
                conditionMessage(e)))
    FALSE
  })
  if (!ok) fail(sprintf("could not source %s model", model_tag))

  if (!exists("AcadianGYOneStand", envir = model_env, inherits = FALSE)) {
    fail(sprintf("%s model does not define AcadianGYOneStand", model_tag))
  }
  step_fn <- get("AcadianGYOneStand", envir = model_env)

  snaps  <- list()
  errors <- character(0)

  for (sid in stand_ids) {
    trees0 <- tree_init[tree_init$STAND == sid, , drop = FALSE]
    srow   <- stand_init[stand_init$STAND == sid, , drop = FALSE]
    if (nrow(trees0) == 0L || nrow(srow) == 0L) {
      errors <- c(errors, sprintf("stand %s: missing init rows", sid))
      next
    }

    pr <- project_stand(step_fn, trees0, srow, ops, sid, nyears)
    if (!is.na(pr$error)) {
      errors <- c(errors, sprintf("stand %s: %s", sid, pr$error))
    }

    y0  <- pr$y0;  y0$model  <- model_tag
    y10 <- pr$y10; y10$model <- model_tag
    snaps[[length(snaps) + 1L]] <- y0
    snaps[[length(snaps) + 1L]] <- y10
  }

  list(
    tag     = model_tag,
    snaps   = if (length(snaps)) plyr::rbind.fill(snaps) else NULL,
    n_error = length(errors),
    errors  = errors
  )
}

# --- Load inputs -------------------------------------------------------------

if (!file.exists(TREE_CSV))  fail(sprintf("tree init CSV not found: %s", TREE_CSV))
if (!file.exists(PAIRS_CSV)) fail(sprintf("pairs CSV not found: %s", PAIRS_CSV))

tree_raw  <- read.csv(TREE_CSV,  stringsAsFactors = FALSE)
pairs_raw <- read.csv(PAIRS_CSV, stringsAsFactors = FALSE)

req_tree <- c("STAND", "TREE", "SP", "DBH", "HT", "EXPF", "YEAR")
miss <- setdiff(req_tree, names(tree_raw))
if (length(miss)) fail(sprintf("tree init missing columns: %s",
                               paste(miss, collapse = ", ")))

# First N unique stands in file order.
stand_ids <- unique(tree_raw$STAND)
stand_ids <- head(stand_ids, N_STANDS)
if (length(stand_ids) == 0L) fail("no stands found in tree init")

tree_raw <- tree_raw[tree_raw$STAND %in% stand_ids, , drop = FALSE]

# --- Build AcadianGY schema --------------------------------------------------

tree_init <- data.frame(
  STAND      = tree_raw$STAND,
  PLOT       = 1L,
  TREE       = tree_raw$TREE,
  SP         = tree_raw$SP,
  DBH        = as.numeric(tree_raw$DBH),
  HT         = as.numeric(tree_raw$HT),
  HCB        = NA_real_,
  EXPF       = as.numeric(tree_raw$EXPF),
  YEAR       = tree_raw$YEAR,
  dDBH.mult  = 1,
  dHt.mult   = 1,
  mort.mult  = 1,
  max.dbh    = 200,
  max.height = 50,
  Form       = NA,
  Risk       = NA,
  stringsAsFactors = FALSE
)

# Stand table: one row per stand. ELEV taken from pairs where sensible,
# otherwise defaulted to 200 m. CSI fixed at 14.0 for the smoke run.
elev_lookup <- NULL
if (all(c("STAND", "ELEV") %in% names(pairs_raw))) {
  elev_lookup <- pairs_raw[!duplicated(pairs_raw$STAND),
                           c("STAND", "ELEV"), drop = FALSE]
}

stand_init <- data.frame(STAND = stand_ids, stringsAsFactors = FALSE)
if (!is.null(elev_lookup)) {
  stand_init <- dplyr::left_join(stand_init, elev_lookup, by = "STAND")
} else {
  stand_init$ELEV <- NA_real_
}
stand_init$CSI  <- 14.0
stand_init$ELEV <- ifelse(!is.na(stand_init$ELEV) & stand_init$ELEV > 0,
                          stand_init$ELEV, 200)
stand_init <- stand_init[, c("STAND", "CSI", "ELEV")]

# --- Operating options -------------------------------------------------------

ops_base <- list(verbose = FALSE, INGROWTH = "Y", MinDBH = 3.0)

ops_v130 <- ops_base
ops_v130$use.esi.domht <- TRUE

# --- Run both models ---------------------------------------------------------

cat("==================================================================\n")
cat("AcadianGY v13.0 smoke test\n")
cat(sprintf("  BASE model : %s\n", BASE_MODEL))
cat(sprintf("  V130 model : %s\n", V130_MODEL))
cat(sprintf("  Stands     : %d  (%s)\n", length(stand_ids),
            paste(stand_ids, collapse = ", ")))
cat(sprintf("  Projection : %d years\n", N_YEARS))
cat("==================================================================\n\n")

res_base <- run_model(BASE_MODEL, "BASE", tree_init, stand_init, ops_base,
                      stand_ids, N_YEARS)
res_v130 <- run_model(V130_MODEL, "V130", tree_init, stand_init, ops_v130,
                      stand_ids, N_YEARS)

# --- Assemble results --------------------------------------------------------

all_snaps <- plyr::rbind.fill(res_base$snaps, res_v130$snaps)

# Year-10 slices for the head-to-head comparison.
metrics <- c("BA", "TPH", "QMD", "TOPHT", "VOLPROXY")

y10 <- all_snaps[all_snaps$YEAR == N_YEARS, , drop = FALSE]

base10 <- y10[y10$model == "BASE",
              c("STAND", metrics), drop = FALSE]
v13010 <- y10[y10$model == "V130",
              c("STAND", metrics), drop = FALSE]

names(base10)[-1] <- paste0(metrics, "_base")
names(v13010)[-1] <- paste0(metrics, "_v130")

cmp <- dplyr::left_join(base10, v13010, by = "STAND")
for (m in metrics) {
  cmp[[paste0(m, "_delta")]] <- cmp[[paste0(m, "_v130")]] -
                                cmp[[paste0(m, "_base")]]
}

# --- Print per-stand year-10 comparison --------------------------------------

cat("Per-stand year-10 comparison (base vs v130, delta = v130 - base)\n")
cat("------------------------------------------------------------------\n")
for (m in metrics) {
  cat(sprintf("\n%s (year %d):\n", m, N_YEARS))
  sub <- data.frame(
    STAND = cmp$STAND,
    base  = round(cmp[[paste0(m, "_base")]], 3),
    v130  = round(cmp[[paste0(m, "_v130")]], 3),
    delta = round(cmp[[paste0(m, "_delta")]], 3),
    stringsAsFactors = FALSE
  )
  print(sub, row.names = FALSE)
}

# --- Means ------------------------------------------------------------------

mean_fin <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) NA_real_ else mean(x)
}

means <- data.frame(
  metric     = metrics,
  base_y10   = vapply(metrics, function(m) mean_fin(cmp[[paste0(m, "_base")]]),
                      numeric(1)),
  v130_y10   = vapply(metrics, function(m) mean_fin(cmp[[paste0(m, "_v130")]]),
                      numeric(1)),
  stringsAsFactors = FALSE
)
means$delta <- means$v130_y10 - means$base_y10

cat("\n==================================================================\n")
cat("Mean year-10 metrics across stands\n")
cat("------------------------------------------------------------------\n")
print(transform(means,
                base_y10 = round(base_y10, 3),
                v130_y10 = round(v130_y10, 3),
                delta    = round(delta, 3)),
      row.names = FALSE)

get_mean <- function(m, col) means[[col]][means$metric == m]

cat("\nDirectional expectations (v13.0 vs base):\n")
cat(sprintf("  mean TOPHT    : base=%.3f  v130=%.3f  delta=%+.3f   (expect v130 LOWER)\n",
            get_mean("TOPHT", "base_y10"), get_mean("TOPHT", "v130_y10"),
            get_mean("TOPHT", "delta")))
cat(sprintf("  mean BA       : base=%.3f  v130=%.3f  delta=%+.3f   (expect v130 HIGHER)\n",
            get_mean("BA", "base_y10"), get_mean("BA", "v130_y10"),
            get_mean("BA", "delta")))
cat(sprintf("  mean VOLPROXY : base=%.3f  v130=%.3f  delta=%+.3f\n",
            get_mean("VOLPROXY", "base_y10"), get_mean("VOLPROXY", "v130_y10"),
            get_mean("VOLPROXY", "delta")))

topht_ok <- is.finite(get_mean("TOPHT", "delta")) && get_mean("TOPHT", "delta") < 0
ba_ok    <- is.finite(get_mean("BA", "delta"))    && get_mean("BA", "delta")    > 0
cat(sprintf("\n  [note] TOPHT lower than base: %s | BA higher than base: %s\n",
            ifelse(topht_ok, "YES", "no"), ifelse(ba_ok, "YES", "no")))
cat("  (These are directional sanity notes only; they do not gate the pass.)\n")

# --- Error accounting --------------------------------------------------------

cat("\n==================================================================\n")
cat("Error accounting\n")
cat("------------------------------------------------------------------\n")
cat(sprintf("  BASE : %d of %d stands errored\n", res_base$n_error, length(stand_ids)))
if (res_base$n_error > 0) for (e in res_base$errors) cat("    - ", e, "\n", sep = "")
cat(sprintf("  V130 : %d of %d stands errored\n", res_v130$n_error, length(stand_ids)))
if (res_v130$n_error > 0) for (e in res_v130$errors) cat("    - ", e, "\n", sep = "")

# --- Write results CSV -------------------------------------------------------

out_ok <- tryCatch({
  write.csv(all_snaps[order(all_snaps$model, all_snaps$STAND, all_snaps$YEAR), ],
            RESULTS_CSV, row.names = FALSE)
  TRUE
}, error = function(e) {
  cat(sprintf("  WARNING: could not write results CSV: %s\n", conditionMessage(e)))
  FALSE
})
if (out_ok) cat(sprintf("\nResults written to %s\n", RESULTS_CSV))

# --- Final verdict -----------------------------------------------------------

reasons <- character(0)

if (res_base$n_error > 0)
  reasons <- c(reasons, sprintf("%d BASE stand(s) errored", res_base$n_error))
if (res_v130$n_error > 0)
  reasons <- c(reasons, sprintf("%d V130 stand(s) errored", res_v130$n_error))

# All year-0 and year-10 metrics must be finite for every stand under both models.
metric_mat <- as.matrix(all_snaps[, metrics])
n_nonfinite <- sum(!is.finite(metric_mat))
if (n_nonfinite > 0)
  reasons <- c(reasons, sprintf("%d non-finite metric value(s)", n_nonfinite))

# Sanity: we must actually have both models' year-10 rows for each stand.
if (nrow(base10) != length(stand_ids) || nrow(v13010) != length(stand_ids))
  reasons <- c(reasons, "missing year-10 rows for one or more stands")

cat("\n==================================================================\n")
if (length(reasons) == 0L) {
  cat("SMOKE_PASS\n")
  quit(save = "no", status = 0L)
} else {
  cat(sprintf("SMOKE_FAIL: %s\n", paste(reasons, collapse = "; ")))
  quit(save = "no", status = 1L)
}

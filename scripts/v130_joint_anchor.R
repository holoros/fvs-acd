# =====================================================================
# v130_joint_anchor.R
# FVS-ACD v13.0 joint re-anchor of dominant-height and BA increment
# Aaron Weiskittel, CRSF
#
# Purpose
#   v12.10.1 (shipped) shows offsetting errors on the held-out MagPlot
#   benchmark: pooled top height over-predicts about +9 percent while
#   basal area under-predicts about -8 percent, so total volume
#   (TOTVOL from FIA NSVB) lands roughly unbiased by cancellation.
#   Correcting height alone would push volume negative. v13.0 performs a
#   JOINT re-anchor: bring the dominant-height increment down to
#   unbiased AND bring the BA increment up to unbiased on the same
#   ME/NH/VT remeasurement pairs, base-age invariant, so each component
#   is individually unbiased and the volume identity stays unbiased.
#
#   Evaluation is IN-DOMAIN: the Acadian-core ESI + ecoregion mask
#   excludes the QC edge, where ESI over-reads productivity. ESI is the
#   settled site metric and is not changed here.
#
# Runs on Cardinal via SLURM (v130_joint.sbatch). All outputs to
# ~/v130_joint/.
# =====================================================================

# ---------------------------------------------------------------------
# 0. Setup
# ---------------------------------------------------------------------
suppressPackageStartupMessages(library(data.table))

# minpack.lm gives Levenberg-Marquardt (nlsLM), which is far more robust
# for the monomolecular difference forms. Optional; fall back to nls.
has_lm <- requireNamespace("minpack.lm", quietly = TRUE)
if (!has_lm) {
  message("WARNING: minpack.lm not available; falling back to stats::nls ",
          "for the nonlinear anchors.")
}

set.seed(42)

out_dir <- path.expand("~/v130_joint")
dir.create(out_dir, showWarnings = FALSE)

# Small helper for consistent output paths.
op <- function(f) file.path(out_dir, f)

# ---------------------------------------------------------------------
# 1. Height data: load, clean, and apply the in-domain mask
# ---------------------------------------------------------------------
ne <- readRDS(path.expand("~/bakeoff_v13/ne_plot_table.rds"))
setDT(ne)

# Attach ESI by rid (all.x so we keep every plot and can count coverage).
esi_tab <- fread(path.expand("~/bakeoff_v13/ne_plot_esi.csv"))
setkey(esi_tab, rid)
# Merge esi onto ne by rid; only pull the esi column across.
ne <- merge(ne, esi_tab[, .(rid, esi)], by = "rid", all.x = TRUE)

n_total <- nrow(ne)

# Cleaning filters. topht in metres, hgi_o is observed annual top-height
# increment (m/yr). These are physical-plausibility bounds, not domain.
clean_ok <- with(ne,
  is.finite(topht1) & topht1 > 2 &
  is.finite(topht2) & topht2 > 2 &
  is.finite(stdage) & stdage >= 5 & stdage <= 250 &
  is.finite(years)  & years  >= 1 &
  is.finite(hgi_o)  & hgi_o  > -0.5 & hgi_o < 2 &
  is.finite(esi)
)

# In-domain mask: Acadian-core EPA level III ecoregions with finite ESI.
# This is the mask that drops the QC edge where ESI over-reads.
acadian_L3 <- c("5.3.1", "8.1.7", "8.1.8", "8.1.1")
ne[, in_domain := is.finite(esi) & epaL3 %in% acadian_L3]

# Diagnostic counts.
n_esi_cov    <- ne[is.finite(esi), .N]
n_in_dom     <- ne[in_domain == TRUE, .N]
n_out_dom    <- ne[in_domain == FALSE, .N]
n_clean      <- sum(clean_ok, na.rm = TRUE)
n_clean_dom  <- sum(clean_ok & ne$in_domain, na.rm = TRUE)

cat("---- Height data counts ----\n")
cat("total rows          :", n_total, "\n")
cat("ESI-covered rows    :", n_esi_cov, "\n")
cat("in-domain rows      :", n_in_dom, "\n")
cat("out-of-domain rows  :", n_out_dom, "\n")
cat("clean rows (all)    :", n_clean, "\n")
cat("clean + in-domain   :", n_clean_dom, "\n")

# By-STATECD breakdown of clean + in-domain rows.
by_state <- ne[clean_ok & in_domain == TRUE, .N, by = STATECD][order(STATECD)]
cat("---- clean + in-domain by STATECD ----\n")
print(by_state)

# Persist the counts as a tidy long table.
counts_dt <- data.table(
  metric = c("total", "esi_covered", "in_domain", "out_of_domain",
             "clean_all", "clean_in_domain"),
  n      = c(n_total, n_esi_cov, n_in_dom, n_out_dom, n_clean, n_clean_dom)
)
state_dt <- by_state[, .(metric = paste0("clean_in_domain_STATECD_", STATECD),
                         n = N)]
fwrite(rbind(counts_dt, state_dt), op("v130_domain_counts.csv"))

# dd = the clean, in-domain height fit set used for everything below.
dd <- ne[clean_ok & in_domain == TRUE]
cat("dd rows for height anchor:", nrow(dd), "\n\n")

# ---------------------------------------------------------------------
# Spatial CV fold assignment (shared by height and BA sections)
#   cell = coarse 0.25-degree grid so nearby plots share a fold; folds
#   are assigned by cell, not by row, to blunt spatial leakage.
# ---------------------------------------------------------------------
assign_spatial_folds <- function(dt, k = 10, lat = "LAT", lon = "LON") {
  dt <- copy(dt)
  dt[, .cell := paste(round(get(lat) * 4), round(get(lon) * 4))]
  cells <- unique(dt$.cell)
  # Shuffle cells, then round-robin them into k folds.
  cells <- sample(cells)
  cell_fold <- data.table(.cell = cells,
                          .fold = rep_len(seq_len(k), length(cells)))
  dt <- merge(dt, cell_fold, by = ".cell", all.x = TRUE)
  dt
}

# Increment scoring metrics, computed on out-of-fold predictions.
score_increment <- function(pred, obs) {
  ok  <- is.finite(pred) & is.finite(obs)
  pred <- pred[ok]; obs <- obs[ok]
  n    <- length(obs)
  sse  <- sum((obs - pred)^2)
  sst  <- sum((obs - mean(obs))^2)
  list(
    n     = n,
    bias  = mean(pred) - mean(obs),          # increment bias
    ratio = mean(pred) / mean(obs),          # increment ratio, target 1.0
    rmse  = sqrt(sse / n),
    EF    = 1 - sse / sst                    # modelling efficiency
  )
}

# ---------------------------------------------------------------------
# 2. Height increment anchor (base-age invariant), two forms
# ---------------------------------------------------------------------
# M1: linear annual-increment model. hgi_o already annualized (m/yr).
fit_M1 <- function(train) {
  lm(hgi_o ~ esi + topht1 + log(stdage), data = train)
}
pred_M1 <- function(mod, newdata) {
  as.numeric(predict(mod, newdata = newdata))
}

# M2: monomolecular difference anchor, base-age invariant (no absolute
# age term). Asymptote A = a0 + a1*esi; growth to topht2 over `years`:
#   topht2 = A - (A - topht1) * exp(-k * years)
# The predicted ANNUAL increment for scoring is (topht2_pred - topht1)/years.
fit_M2 <- function(train) {
  tryCatch({
    if (has_lm) {
      minpack.lm::nlsLM(
        topht2 ~ (a0 + a1 * esi) -
                 ((a0 + a1 * esi) - topht1) * exp(-k * years),
        data    = train,
        start   = c(a0 = 8, a1 = 0.8, k = 0.02),
        lower   = c(a0 = -5, a1 = 0.1, k = 1e-3),
        upper   = c(a0 = 30, a1 = 3,   k = 0.3),
        control = minpack.lm::nls.lm.control(maxiter = 200)
      )
    } else {
      nls(
        topht2 ~ (a0 + a1 * esi) -
                 ((a0 + a1 * esi) - topht1) * exp(-k * years),
        data  = train,
        start = c(a0 = 8, a1 = 0.8, k = 0.02)
      )
    }
  }, error = function(e) {
    message("M2 fit failed: ", conditionMessage(e))
    NULL
  })
}
# M2 predicts topht2; convert to annual increment for scoring vs hgi_o.
pred_M2_incr <- function(mod, newdata) {
  if (is.null(mod)) return(rep(NA_real_, nrow(newdata)))
  th2 <- as.numeric(predict(mod, newdata = newdata))
  (th2 - newdata$topht1) / newdata$years
}

# 10-fold spatially blocked CV for both forms.
run_height_cv <- function(dd, k = 10) {
  dcv <- assign_spatial_folds(dd, k = k)
  p1  <- rep(NA_real_, nrow(dcv))
  p2  <- rep(NA_real_, nrow(dcv))
  for (f in sort(unique(dcv$.fold))) {
    tr <- dcv[.fold != f]
    te <- dcv[.fold == f]
    idx <- which(dcv$.fold == f)

    m1 <- tryCatch(fit_M1(tr), error = function(e) NULL)
    if (!is.null(m1)) p1[idx] <- pred_M1(m1, te)

    m2 <- fit_M2(tr)
    p2[idx] <- pred_M2_incr(m2, te)
  }
  obs <- dcv$hgi_o
  list(
    dcv = dcv,
    M1  = score_increment(p1, obs),
    M2  = score_increment(p2, obs)
  )
}

hcv <- run_height_cv(dd, k = 10)

cv_rows <- rbindlist(list(
  data.table(model = "M1_linear_incr",  as.data.table(hcv$M1)),
  data.table(model = "M2_monomolecular", as.data.table(hcv$M2))
), fill = TRUE)
cat("---- Height increment CV (spatially blocked, k=10) ----\n")
print(cv_rows)
fwrite(cv_rows, op("v130_height_cv.csv"))

# Refit both on all of dd and save coefficients + objects.
M1_full <- fit_M1(dd)
M2_full <- fit_M2(dd)

cat("\n---- M1 (full-fit) coefficients ----\n")
print(coef(M1_full))
if (!is.null(M2_full)) {
  cat("---- M2 (full-fit) coefficients ----\n")
  print(coef(M2_full))
} else {
  cat("WARNING: M2 full fit is NULL; height anchor relies on M1.\n")
}

saveRDS(list(M1 = M1_full, M2 = M2_full), op("v130_height_anchor.rds"))

# Store the in-domain M2 increment ratio for the joint check in section 4.
height_incr_ratio <- hcv$M2$ratio

# ---------------------------------------------------------------------
# 3. BA increment anchor (the joint half)
# ---------------------------------------------------------------------
# The BA-increment design matrix was built by v13.1 growth work. It is
# keyed by a CONUS stand id (NOT PLT_CHR) and does NOT carry esi. To fit
# the BA anchor in domain with esi we must (i) find the stand/plot key,
# (ii) subset to ME/NH/VT (STATECD 23,33,50) via `region`, and
# (iii) join esi through ne_plot_esi. The exact key column cannot be
# verified now (Cardinal is down), so the block below detects it live
# and documents a clean fallback.

v131g <- readRDS(path.expand("~/v13_kickoff/v131g_fitset.rds"))
setDT(v131g)

# RESOLVED-ON-RETURN (7 Jul 2026): the live v131g fitset names the interval
# column YEARS (uppercase); the BA anchor below refers to `years` (lowercase,
# matching the height/ne table). Alias it so the BA increment code resolves.
if (!("years" %in% names(v131g)) && "YEARS" %in% names(v131g)) {
  v131g[, years := as.numeric(YEARS)]
}

# ===================================================================
## CONFIRM-ON-RETURN: BA-increment key detection, NE subset, esi join
##
## When Cardinal is back, verify the following against the LIVE object.
## The code auto-detects; these diagnostics tell the operator what it
## found and which branch it took.
## ===================================================================
cat("\n---- v131g fitset structure (CONFIRM-ON-RETURN) ----\n")
cat("names(v131g):\n"); print(names(v131g))
cat("str(v131g):\n"); str(v131g, max.level = 1, list.len = 200)

# (ii) Subset to ME/NH/VT via the region grouping (region == STATECD).
#      CONFIRM-ON-RETURN: confirm `region` holds STATECD codes 23/33/50.
stopifnot("region" %in% names(v131g))
v131g[, region := as.integer(as.character(region))]
ba <- v131g[region %in% c(23L, 33L, 50L)]
cat("\nBA rows in ME/NH/VT (region 23/33/50):", nrow(ba), "\n")

# Fit the BA anchor on the held-out-safe training rows only (recent==0),
# matching the v13.1 convention (recent==1 is the recent-FIA proxy).
if ("recent" %in% names(ba)) {
  ba_fit_src <- ba[recent == 0]
  cat("BA rows with recent==0 (fit set):", nrow(ba_fit_src), "\n")
} else {
  ba_fit_src <- ba
  cat("WARNING: no `recent` flag found; fitting on all NE BA rows.\n")
}

# (i) Detect a plot/stand key we can carry to ne_plot_esi. We look for a
#     PLT_CHR-like column; if present we can join esi. Otherwise we defer
#     the esi-BA join and fall back to an esi-free BA anchor.
# CONFIRM-ON-RETURN: verify the detected key actually matches PLT_CHR in
# ne_plot_table / ne_plot_esi. Do NOT hard-code a guessed name.
key_candidates <- grep("PLT_CHR|PLT|PLOT|CN$|STAND|CONUS|_ID$|^ID$",
                       names(ba_fit_src), value = TRUE, ignore.case = TRUE)
cat("\nCandidate key columns in v131g:\n"); print(key_candidates)

# esi is joinable only if a PLT_CHR-compatible column exists AND we can
# map it to ne_plot_esi. ne_plot_esi is keyed by `rid`; esi reaches
# PLT_CHR through ne_plot_table (PLT_CHR <-> rid). Build that bridge.
plt_key <- intersect(c("PLT_CHR"), names(ba_fit_src))
esi_joinable <- length(plt_key) == 1L

esi_available_in_ba <- FALSE
if (esi_joinable) {
  # Bridge: PLT_CHR -> rid (from ne_plot_table) -> esi (from ne_plot_esi).
  # ne already has esi merged in above, keyed usably by PLT_CHR.
  bridge <- unique(ne[, .(PLT_CHR, esi)])
  ba_fit_src <- merge(ba_fit_src, bridge, by = "PLT_CHR", all.x = TRUE)
  esi_available_in_ba <- ba_fit_src[is.finite(esi), .N] > 0L
  cat("esi join via PLT_CHR succeeded; finite-esi BA rows:",
      ba_fit_src[is.finite(esi), .N], "\n")
} else {
  cat("WARNING: no PLT_CHR column in v131g; esi-BA join is DEFERRED.\n")
  cat("Falling back to esi-free BA anchor (rd + ln_qmd + ba).\n")
}
# ===================================================================
## END CONFIRM-ON-RETURN block
## ===================================================================

# Implied end-of-interval BA from the observed net increment. The anchor
# is fit to reproduce this, so BA increment is unbiased in domain.
#   ba2_obs = ba1 + net_ba_ann * years
# The monomolecular BA difference anchor:
#   ba2_pred = BAmax - (BAmax - ba1) * exp(-kb * years),  BAmax = b0 + b1*esi
# Predicted ANNUAL BA increment for scoring is (ba2_pred - ba1)/years,
# compared against observed net_ba_ann.
ba_fit_src[, ba2_obs := ba + net_ba_ann * years]

# Nonlinear (esi) BA anchor.
fit_BA_nl <- function(train) {
  tryCatch({
    if (has_lm) {
      minpack.lm::nlsLM(
        ba2_obs ~ (b0 + b1 * esi) -
                  ((b0 + b1 * esi) - ba) * exp(-kb * years),
        data    = train,
        start   = c(b0 = 60, b1 = 2, kb = 0.03),
        lower   = c(b0 = 5,  b1 = 0, kb = 1e-4),
        upper   = c(b0 = 200, b1 = 20, kb = 0.5),
        control = minpack.lm::nls.lm.control(maxiter = 200)
      )
    } else {
      nls(
        ba2_obs ~ (b0 + b1 * esi) -
                  ((b0 + b1 * esi) - ba) * exp(-kb * years),
        data  = train,
        start = c(b0 = 60, b1 = 2, kb = 0.03)
      )
    }
  }, error = function(e) {
    message("BA nonlinear fit failed: ", conditionMessage(e))
    NULL
  })
}
pred_BA_nl_incr <- function(mod, newdata) {
  if (is.null(mod)) return(rep(NA_real_, nrow(newdata)))
  ba2 <- as.numeric(predict(mod, newdata = newdata))
  (ba2 - newdata$ba) / newdata$years
}

# Linear-increment reference. If esi is available include it, otherwise
# fall back to rd + ln_qmd + ba only (esi omitted; noted loudly).
fit_BA_lin <- function(train, use_esi) {
  if (use_esi) {
    lm(net_ba_ann ~ esi + ba + rd + ln_qmd, data = train)
  } else {
    lm(net_ba_ann ~ ba + rd + ln_qmd, data = train)
  }
}
pred_BA_lin <- function(mod, newdata) {
  as.numeric(predict(mod, newdata = newdata))
}

# Fit set for BA: require finite responses/predictors. Drop esi from the
# completeness check when esi is not available.
ba_req <- c("net_ba_ann", "ba", "rd", "ln_qmd", "years", "ba2_obs")
if (esi_available_in_ba) ba_req <- c(ba_req, "esi")
ba_clean <- ba_fit_src[stats::complete.cases(ba_fit_src[, ..ba_req])]
# Guard the nonlinear response against pathological negatives.
ba_clean <- ba_clean[is.finite(ba2_obs) & ba2_obs > 0 & years >= 1]
cat("\nBA anchor fit rows (complete cases):", nrow(ba_clean), "\n")

# Spatial CV for BA. LAT/LON may or may not ride along on v131g; if not,
# use whatever coordinate columns exist, else fall back to random folds.
ba_has_ll <- all(c("LAT", "LON") %in% names(ba_clean))
if (!ba_has_ll) {
  cat("WARNING: LAT/LON absent from BA set; using random 10-fold CV.\n")
}

run_ba_cv <- function(dt, k = 10, use_esi) {
  if (ba_has_ll) {
    dcv <- assign_spatial_folds(dt, k = k)
  } else {
    dcv <- copy(dt)
    dcv[, .fold := sample(rep_len(seq_len(k), .N))]
  }
  pnl  <- rep(NA_real_, nrow(dcv))
  plin <- rep(NA_real_, nrow(dcv))
  for (f in sort(unique(dcv$.fold))) {
    tr  <- dcv[.fold != f]
    te  <- dcv[.fold == f]
    idx <- which(dcv$.fold == f)

    if (use_esi) {
      mnl <- fit_BA_nl(tr)
      pnl[idx] <- pred_BA_nl_incr(mnl, te)
    }
    mlin <- tryCatch(fit_BA_lin(tr, use_esi), error = function(e) NULL)
    if (!is.null(mlin)) plin[idx] <- pred_BA_lin(mlin, te)
  }
  obs <- dcv$net_ba_ann
  res <- list(lin = score_increment(plin, obs))
  if (use_esi) res$nl <- score_increment(pnl, obs)
  res
}

ba_cv <- run_ba_cv(ba_clean, k = 10, use_esi = esi_available_in_ba)

ba_cv_rows <- data.table(
  model = "BA_linear_incr",
  esi_used = esi_available_in_ba,
  as.data.table(ba_cv$lin)
)
if (!is.null(ba_cv$nl)) {
  ba_cv_rows <- rbind(ba_cv_rows,
    data.table(model = "BA_monomolecular", esi_used = TRUE,
               as.data.table(ba_cv$nl)),
    fill = TRUE)
}
if (!esi_available_in_ba) {
  cat("\nWARNING: esi OMITTED from BA anchor (esi-BA join deferred). ",
      "BA anchor fit on rd + ln_qmd + ba only.\n", sep = "")
  ba_cv_rows[, note := "esi omitted; esi-BA join deferred (see CONFIRM-ON-RETURN)"]
}
cat("\n---- BA increment CV (k=10) ----\n")
print(ba_cv_rows)
fwrite(ba_cv_rows, op("v130_ba_cv.csv"))

# Choose the anchor: prefer the nonlinear esi form when esi is available
# and it fits; else the linear reference. Report the ratio (target 1.0).
if (esi_available_in_ba) {
  BA_nl_full  <- fit_BA_nl(ba_clean)
} else {
  BA_nl_full  <- NULL
}
BA_lin_full <- tryCatch(fit_BA_lin(ba_clean, esi_available_in_ba),
                        error = function(e) NULL)

# Pick primary by which CV ratio is closest to 1 among the fitted forms.
ba_primary <- "BA_linear_incr"
ba_incr_ratio <- if (!is.null(ba_cv$lin)) ba_cv$lin$ratio else NA_real_
if (!is.null(ba_cv$nl) && is.finite(ba_cv$nl$ratio)) {
  if (abs(ba_cv$nl$ratio - 1) < abs(ba_cv$lin$ratio - 1)) {
    ba_primary <- "BA_monomolecular"
    ba_incr_ratio <- ba_cv$nl$ratio
  }
}
cat("\nBA primary anchor:", ba_primary,
    "| in-domain increment ratio:", round(ba_incr_ratio, 4), "\n")

saveRDS(list(
  primary     = ba_primary,
  nl          = BA_nl_full,
  linear      = BA_lin_full,
  esi_used    = esi_available_in_ba,
  incr_ratio  = ba_incr_ratio
), op("v130_ba_anchor.rds"))

# ---------------------------------------------------------------------
# 4. Joint volume-identity check (in domain, aggregate only)
# ---------------------------------------------------------------------
# The full NSVB volume re-scoring happens in the SEPARATE scoring step on
# MagPlot: the auto-submit session wires these two anchors into the
# MagPlot verify harness and re-scores TOTVOL from re-anchored height and
# BA increments. Here we only report the in-domain implied COMPONENT
# biases, so the operator can confirm each half is individually unbiased
# before the joint volume identity is re-checked downstream.
cat("\n---- Joint component check (in domain, aggregate) ----\n")
cat("Height increment ratio (M2, spatial CV): ",
    round(height_incr_ratio, 4), " (target 1.0)\n", sep = "")
cat("BA increment ratio (", ba_primary, ", CV): ",
    round(ba_incr_ratio, 4), " (target 1.0)\n", sep = "")

# Empirical elasticities of stand volume w.r.t. height and BA, IF a stand
# volume column is available on either table. The height/BA fit sets do
# not carry TOTVOL, so this is typically deferred to the MagPlot cb
# results in scoring; we compute it only when the columns exist.
vol_col <- intersect(c("TOTVOL", "totvol", "vol", "nsvb_vol"),
                     union(names(ne), names(ba_clean)))
if (length(vol_col) >= 1 &&
    all(c("topht1", "ba") %in% union(names(ne), names(ba_clean)))) {
  cat("NOTE: a volume column was found; elasticity computation is left ",
      "to the MagPlot scoring harness for a like-for-like NSVB basis.\n",
      sep = "")
} else {
  cat("NOTE: stand-volume elasticities are not computable from the height ",
      "and BA fit columns here; they come from the MagPlot cb results in ",
      "the scoring step.\n", sep = "")
}

# ---------------------------------------------------------------------
# 5. Done
# ---------------------------------------------------------------------
writeLines("fit_complete", op("v130_status.txt"))
cat("\nDONE_V130_JOINT\n")

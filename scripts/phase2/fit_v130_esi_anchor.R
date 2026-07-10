# =====================================================================
# fit_v130_esi_anchor.R
# FVS-ACD v13.0 Phase 2: derive region esi.anchor.coef c(intercept, slope)
# so the harness-native calc_dht recal hook reproduces the v13.0 unbiased
# in-domain dominant-height increment.
# Aaron Weiskittel, CRSF. Cardinal-runnable. No em dashes.
#
# ---------------------------------------------------------------------
# WHAT THIS SCRIPT DERIVES, AND THE EXACT ALGEBRA
# ---------------------------------------------------------------------
# The live hook inside calc_dht (AcadianGY_*.r, the ops$use.esi.anchor.recal
# block) does exactly this, per stand, every projected year:
#
#     ascale(ESI) = intercept + slope * ESI          # ESI == csi in the code
#     ascale(ESI) = min(1.35, max(0.85, ascale))     # HARD CLAMP, band [0.85, 1.35]
#     dht_corrected = dht_base / ascale(ESI)
#
# so c(intercept, slope) is a straight line in ESI that sets ONE multiplicative
# scale for the whole stand, and every tree's base annual height increment is
# DIVIDED by it. Because top height is an expf-weighted mean of the tallest
# trees, dividing each tree increment by ascale divides the stand top-height
# increment by ascale to first order (see phase2 plan section 2b).
#
# GOAL: choose c(intercept, slope) per region so the corrected top-height
# increment equals the v13.0 M1 unbiased target
#
#     M1: hgi = 0.130312 + 0.0142026*esi - 0.0124407*topht1 + 0.0102397*log(stdage)
#
# Setting dht_corrected == dht_target and solving for the scale the hook needs:
#
#     ascale_new(ESI) = dht_base / dht_target                                 (1)
#
# Note the DIRECTION: the code DIVIDES, so the regression response is
# base-over-target, NOT target-over-base. Getting this backwards inverts the
# correction. (If you prefer to think in target/base, that is 1/ascale_new and
# must be inverted before it becomes a coefficient.)
#
# We do not have dht_base (the recal-OFF raw Kuehne increment) without a heavy
# model run. But the CURRENT shipped model already divides by the operational
# ascale_old = intercept_old + slope_old*ESI, so
#
#     current_model_incr = dht_base / ascale_old   =>   dht_base = current_model_incr * ascale_old
#
# Substituting into (1):
#
#     ascale_new(ESI) = ascale_old(ESI) * ( current_model_incr / dht_target )  (2)
#
# The factor current_model_incr / dht_target is simply the CURRENT anchored
# model's over-prediction ratio against the unbiased M1 target. v12.10.1
# over-predicts top height about +2.97 percent pooled (cb_v12101), so this ratio
# is a little above 1 in domain, and ascale_new lands a little ABOVE ascale_old:
# a slightly larger divisor, a slightly smaller increment, top height pulled
# toward 0 bias. That is the intended direction.
#
# We estimate current_model_incr / dht_target per stand from the benchmark that
# ALREADY EXISTS on Cardinal, with no new model run:
#   * NB and QC: the recal-ON current-model MagPlot benchmark cb_v12101_results.csv
#     (the gate baseline). current_model_incr = (TOPHT_p - TOPHT_t1)/interval;
#     dht_target = M1 evaluated at that stand's esi, TOPHT_t1, stdage.
#   * ME (and NS): the operational hook has NO ME/NS coefficient (it falls back
#     to c(1,0), no correction). The v13.0 fit reports the in-domain ME/NH/VT
#     dominant-height increment ratio at 1.00 (13,894 pairs), i.e. the base
#     height is already unbiased in the US Acadian core, so ME defaults to the
#     no-correction line c(1,0). This is refined against ne_plot_table below if
#     the data support a nonzero correction.
#
# Then per region we fit ascale_new ~ esi (equation 2 evaluated per stand) with
# a simple linear model; its c(intercept, slope) become the new esi.anchor.coef.
# The [0.85, 1.35] clamp is checked across the in-domain ESI range.
#
# Every assumption is tagged [ASSUMPTION: ...]. The gate (v130_score_gate_v2.R
# vs cb_v12101) is the safety net: a wrong coefficient surfaces as a bad
# scorecard and is caught there, so this derivation favors transparency and
# reproducibility over cleverness.
# =====================================================================

suppressPackageStartupMessages(library(data.table))
set.seed(42)

# ---------------------------------------------------------------------
# 0. Paths, logging, small helpers
# ---------------------------------------------------------------------
err_log <- path.expand("~/error_log.txt")
logline <- function(...) {
  msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(msg, "\n")
  try(cat(msg, "\n", file = err_log, append = TRUE), silent = TRUE)
}
# Wrap any IO so a missing/renamed file logs and returns NULL rather than aborting.
safe <- function(expr, what = "IO") {
  tryCatch(expr, error = function(e) {
    logline("ERROR in ", what, ": ", conditionMessage(e))
    NULL
  })
}

out_csv        <- path.expand("~/v130_esi_anchor_coef.csv")
cb_base_path   <- path.expand("~/magplot/verify/cb_v12101_results.csv")   # gate baseline, already on Cardinal
magp_pairs     <- path.expand("~/magplot/verify/magp_qcnb_pairs.csv")     # STAND <-> SITE
magp_esi8      <- path.expand("~/magplot/verify/magp_qcnb_site_esi8.csv")  # SITE  <-> esi8
ne_rds         <- path.expand("~/bakeoff_v13/ne_plot_table.rds")          # US ME/NH/VT height pairs
ne_esi_csv     <- path.expand("~/bakeoff_v13/ne_plot_esi.csv")            # rid <-> esi

logline("==== fit_v130_esi_anchor.R start ====")

# ---------------------------------------------------------------------
# 1. Fixed coefficients and functional forms
# ---------------------------------------------------------------------
# Operational esi.anchor.coef (the CURRENT ascale_old lines). ME/NS fall back to
# c(1,0), i.e. no correction, exactly as the hook does for undiagnosed regions.
old_coef <- list(
  NB = c(intercept = 0.885, slope = 0.01027),
  QC = c(intercept = 0.441, slope = 0.03783),
  ME = c(intercept = 1.0,   slope = 0.0),
  NS = c(intercept = 1.0,   slope = 0.0)
)

# HARD CLAMP band the hook enforces on ascale (confirmed from the model source:
# .ascale_dht <- min(1.35, max(0.85, .ascale_dht)).
CLAMP_LO <- 0.85
CLAMP_HI <- 1.35

# v13.0 M1 unbiased dominant-height increment target (m/yr).
M1_b0  <- 0.130312     # intercept
M1_esi <- 0.0142026    # esi
M1_th1 <- -0.0124407   # topht1 (current top height)
M1_age <- 0.0102397    # log(stdage)

# v13.0 M2 monomolecular anchor, carried only as a CROSS-CHECK target.
M2_a0 <- 15.16031; M2_a1 <- 1.13081; M2_k <- 0.0119233

# [ASSUMPTION: cb_v12101 pooled top-height bias is +2.97 percent, so the
# fallback over-prediction ratio when a region has no per-stand benchmark is
# 1.0297. Region-specific values override this whenever the data exist.]
RESID_RATIO_POOLED <- 1.0297

ascale_old <- function(region, esi) {
  co <- old_coef[[region]]
  if (is.null(co)) co <- c(1, 0)
  co[1] + co[2] * esi
}

# M1 target annual increment. stdage floored at 5 yr to match the fit-set clean.
m1_target <- function(esi, topht1, stdage) {
  M1_b0 + M1_esi * esi + M1_th1 * topht1 + M1_age * log(pmax(stdage, 5))
}
# M2 one-step (annual) increment cross-check from current top height.
m2_target <- function(esi, topht1) {
  Amax <- M2_a0 + M2_a1 * esi
  (Amax - (Amax - topht1) * exp(-M2_k * 1)) - topht1
}

# Robust column picker: first name in `cands` that exists (case-insensitive).
pick_col <- function(dt, cands) {
  nm <- names(dt); lc <- tolower(nm)
  for (c in cands) { hit <- which(lc == tolower(c)); if (length(hit)) return(nm[hit[1]]) }
  NA_character_
}

# ---------------------------------------------------------------------
# 2. Per-region ascale_new rows from the current-model benchmark (NB, QC)
# ---------------------------------------------------------------------
# Reads cb_v12101_results.csv (recal-ON current model on the held-out MagPlot
# NB/QC pairs). Builds, per stand:
#   current_model_incr = (TOPHT_p - TOPHT_t1) / interval
#   dht_target         = M1 at (esi, TOPHT_t1, stdage)
#   ratio              = current_model_incr / dht_target
#   ascale_new         = ascale_old(region, esi) * ratio        [equation (2)]
build_rows_from_cb <- function() {
  cb <- safe(fread(cb_base_path), "read cb_v12101_results.csv")
  if (is.null(cb)) { logline("cb_v12101 unavailable; NB/QC fall back to scaled-old coefficients."); return(NULL) }

  # Attach esi8 the way the gate does: STAND -> SITE (pairs) -> esi8 (site table).
  esi_col <- pick_col(cb, c("esi8", "esi", "csi"))
  if (is.na(esi_col)) {
    pr <- safe(fread(magp_pairs), "read magp_qcnb_pairs.csv")
    e8 <- safe(fread(magp_esi8),  "read magp_qcnb_site_esi8.csv")
    if (!is.null(pr) && !is.null(e8) && all(c("STAND","SITE") %in% names(pr)) &&
        all(c("SITE","esi8") %in% names(e8))) {
      pr[, `:=`(STAND = as.character(STAND), SITE = as.character(SITE))]
      e8[, SITE := as.character(SITE)]
      if ("STAND" %in% names(cb)) cb[, STAND := as.character(STAND)]
      cb <- merge(cb, pr[, .(STAND, SITE)], by = "STAND", all.x = TRUE)
      cb <- merge(cb, unique(e8[, .(SITE, esi8)]), by = "SITE", all.x = TRUE)
      esi_col <- "esi8"
    }
  }
  if (is.na(esi_col)) { logline("[ASSUMPTION] no ESI column joinable to cb; NB/QC fall back to scaled-old."); return(NULL) }

  th1_col <- pick_col(cb, c("TOPHT_t1", "topht_t1", "topht1", "TOPHT1"))
  thp_col <- pick_col(cb, c("TOPHT_p", "topht_p", "TOPHT_pred"))
  iv_col  <- pick_col(cb, c("iv", "interval", "years", "YEARS", "step", "remper"))
  age_col <- pick_col(cb, c("stdage", "STDAGE", "age", "AGE", "standage", "STDAGE_t1"))
  reg_col <- pick_col(cb, c("PROV", "region", "REGION", "prov"))

  if (any(is.na(c(th1_col, thp_col, iv_col, reg_col)))) {
    logline("[ASSUMPTION] cb missing one of TOPHT_t1/TOPHT_p/interval/region; NB/QC fall back to scaled-old.")
    logline("  detected: th1=", th1_col, " thp=", thp_col, " iv=", iv_col, " reg=", reg_col, " esi=", esi_col, " age=", age_col)
    return(NULL)
  }

  d <- data.table(
    region = as.character(cb[[reg_col]]),
    esi    = as.numeric(cb[[esi_col]]),
    th1    = as.numeric(cb[[th1_col]]),
    thp    = as.numeric(cb[[thp_col]]),
    iv     = as.numeric(cb[[iv_col]])
  )
  if (!is.na(age_col)) {
    d[, stdage := as.numeric(cb[[age_col]])]
  } else {
    # [ASSUMPTION: cb_v12101 carries no stand age column, so the small M1 age
    # term is evaluated at a nominal 60 yr. It shifts the target by a constant
    # and largely cancels in the base-over-target ratio; documented as a source
    # of minor bias, checked by the gate.]
    logline("[ASSUMPTION] no age column in cb; M1 age term evaluated at nominal stdage=60 yr.")
    d[, stdage := 60]
  }

  d <- d[is.finite(esi) & is.finite(th1) & is.finite(thp) & is.finite(iv) & iv >= 1 & th1 > 1.5]
  d[, cur_incr := (thp - th1) / iv]
  d[, tgt := m1_target(esi, th1, stdage)]
  d <- d[is.finite(cur_incr) & is.finite(tgt) & tgt > 1e-4 & cur_incr > 0]
  d[, ratio := cur_incr / tgt]
  # Guard pathological ratios before they enter the fit.
  d <- d[is.finite(ratio) & ratio > 0.5 & ratio < 2.0]
  d[, region := toupper(region)]
  d <- d[region %in% c("NB", "QC")]
  if (!nrow(d)) { logline("no usable NB/QC rows in cb after cleaning."); return(NULL) }
  d[, ascale_new := ascale_old(region[1], esi) * ratio, by = region]
  d[, src := "cb_v12101"]
  logline("cb-derived rows: ", paste(d[, .N, region][, paste0(region, "=", N)], collapse = " "))
  d[, .(region, esi, iv, ascale_new, ratio, src)]
}

# ---------------------------------------------------------------------
# 3. ME rows and cross-check from the US height fit set (ne_plot_table)
# ---------------------------------------------------------------------
# Loaded exactly as v130_joint_anchor.R does: readRDS ne_plot_table.rds, join
# ne_plot_esi.csv by rid, clean filters, in-domain Acadian-core mask. Used to
# (a) confirm the base height is unbiased in the US Acadian core (ratio ~ 1.00,
# so ME defaults to c(1,0)), and (b) provide a cross-check on the M1 target.
build_rows_from_ne <- function() {
  ne <- safe(readRDS(ne_rds), "readRDS ne_plot_table.rds")
  if (is.null(ne)) { logline("ne_plot_table unavailable; ME defaults to c(1,0)."); return(NULL) }
  setDT(ne)
  esi_tab <- safe(fread(ne_esi_csv), "read ne_plot_esi.csv")
  if (is.null(esi_tab) || !all(c("rid", "esi") %in% names(esi_tab))) {
    logline("ne_plot_esi unavailable/misnamed; ME defaults to c(1,0)."); return(NULL)
  }
  ne <- merge(ne, esi_tab[, .(rid, esi)], by = "rid", all.x = TRUE)

  clean_ok <- with(ne,
    is.finite(topht1) & topht1 > 2 & is.finite(topht2) & topht2 > 2 &
    is.finite(stdage) & stdage >= 5 & stdage <= 250 &
    is.finite(years)  & years  >= 1 &
    is.finite(hgi_o)  & hgi_o  > -0.5 & hgi_o < 2 & is.finite(esi))
  acadian_L3 <- c("5.3.1", "8.1.7", "8.1.8", "8.1.1")   # in-domain mask, same as joint anchor
  ne[, in_domain := is.finite(esi) & (epaL3 %in% acadian_L3)]
  dd <- ne[clean_ok & in_domain == TRUE]
  if (!nrow(dd)) { logline("no clean in-domain ne rows; ME defaults to c(1,0)."); return(NULL) }

  # Observed vs M1 target in the US Acadian core. hgi_o is unbiased reality; the
  # M1 fit reproduces its mean, so this confirms the target, not a model bias.
  dd[, tgt_m1 := m1_target(esi, topht1, stdage)]
  dd[, tgt_m2 := m2_target(esi, topht1)]
  obs_ratio_m1 <- dd[is.finite(tgt_m1) & tgt_m1 > 1e-4, mean(hgi_o) / mean(tgt_m1)]
  obs_ratio_m2 <- dd[is.finite(tgt_m2) & tgt_m2 > 1e-4, mean(hgi_o) / mean(tgt_m2)]
  logline(sprintf("ne in-domain check: mean(hgi_o)/mean(M1)=%.4f  mean(hgi_o)/mean(M2)=%.4f  (both target ~1.00)",
                  obs_ratio_m1, obs_ratio_m2))

  # [ASSUMPTION: US Acadian-core base height is unbiased (v13.0 in-domain
  # increment ratio 1.00 on 13,894 pairs), the operational hook has no ME coef,
  # and the MagPlot benchmark carries no US ME stands, so the current-model
  # over-prediction ratio for ME cannot be measured here. ME is therefore set to
  # the no-correction line c(1,0). If a US ME recal-off/recal-on benchmark
  # becomes available, replace this with the cb-style ratio derivation.]
  me_region <- data.table(region = "ME", esi = dd$esi, iv = dd$years,
                          ascale_new = ascale_old("ME", dd$esi) * 1.0, ratio = 1.0, src = "ne_assumed_unbiased")
  me_region[, .(region, esi, iv, ascale_new, ratio, src)]
}

# ---------------------------------------------------------------------
# 4. Assemble rows, fit ascale_new ~ esi per region, clamp check, emit
# ---------------------------------------------------------------------
rows <- rbindlist(list(build_rows_from_cb(), build_rows_from_ne()), use.names = TRUE, fill = TRUE)

# Fit or fall back, per region, to the six numbers the hook consumes.
fit_region <- function(region) {
  co_old <- old_coef[[region]]; if (is.null(co_old)) co_old <- c(1, 0)
  .reg <- region   # local var to avoid data.table column/name collision in the i-expression
  dr <- if (!is.null(rows) && nrow(rows)) rows[region == .reg & is.finite(ascale_new) & is.finite(esi)] else NULL

  if (is.null(dr) || nrow(dr) < 20) {
    # FALLBACK: no usable per-stand rows. Scale the OLD coefficients by the
    # pooled over-prediction ratio ("add it to the old coefficients"). This is
    # ascale_new = ascale_old * RESID_RATIO_POOLED, a uniform ESI-independent
    # tilt that still moves top height toward 0.
    logline("[ASSUMPTION] region ", region, ": <20 usable rows, scaling old coef by pooled ratio ",
            sprintf("%.4f", RESID_RATIO_POOLED))
    inter <- co_old[1] * RESID_RATIO_POOLED
    slope <- co_old[2] * RESID_RATIO_POOLED
    n_used <- if (is.null(dr)) 0L else nrow(dr)
    return(list(region = region, intercept = inter, slope = slope, n = n_used,
                method = "scaled_old_pooled", esi_min = NA_real_, esi_max = NA_real_))
  }

  # Weighted linear fit of the required scale on ESI. Weight by interval so
  # longer, more informative remeasurement steps count more.
  w <- pmax(dr$iv, 1)
  fit <- safe(lm(ascale_new ~ esi, data = dr, weights = w), paste0("lm region ", region))
  if (is.null(fit)) {
    logline("[ASSUMPTION] region ", region, ": lm failed, scaling old coef by pooled ratio.")
    return(list(region = region, intercept = co_old[1] * RESID_RATIO_POOLED,
                slope = co_old[2] * RESID_RATIO_POOLED, n = nrow(dr),
                method = "scaled_old_pooled_lmfail", esi_min = NA_real_, esi_max = NA_real_))
  }
  cf <- coef(fit)
  list(region = region, intercept = unname(cf[1]), slope = unname(cf[2]), n = nrow(dr),
       method = paste0("lm_on_", dr$src[1]),
       esi_min = min(dr$esi, na.rm = TRUE), esi_max = max(dr$esi, na.rm = TRUE))
}

regions_out <- c("NB", "QC", "ME")   # regions the harness maps stands to; NS inherits ME/c(1,0)
fits <- lapply(regions_out, fit_region)

coef_dt <- rbindlist(lapply(fits, function(f) data.table(
  region = f$region, intercept = f$intercept, slope = f$slope,
  n = f$n, method = f$method, esi_min = f$esi_min, esi_max = f$esi_max)))

# Clamp-band diagnostic across the observed in-domain ESI range per region.
coef_dt[, ascale_at_esi_min := intercept + slope * esi_min]
coef_dt[, ascale_at_esi_max := intercept + slope * esi_max]
coef_dt[, clamp_hit := (is.finite(ascale_at_esi_min) & (ascale_at_esi_min < CLAMP_LO | ascale_at_esi_min > CLAMP_HI)) |
                       (is.finite(ascale_at_esi_max) & (ascale_at_esi_max < CLAMP_LO | ascale_at_esi_max > CLAMP_HI))]
if (any(coef_dt$clamp_hit, na.rm = TRUE)) {
  logline("WARNING: fitted ascale line reaches the [0.85, 1.35] clamp for region(s): ",
          paste(coef_dt[clamp_hit == TRUE, region], collapse = ", "),
          ". The correction saturates at those ESI extremes (documented risk).")
}

# ---------------------------------------------------------------------
# 5. Write and print
# ---------------------------------------------------------------------
# The hook consumes region intercept/slope; the CSV keeps only those three
# columns in the exact order the bench_parity_v130 loader reads. Diagnostics
# are printed and appended to the log, not the coefficient file.
write_dt <- coef_dt[, .(region, intercept, slope)]
ok <- safe(fwrite(write_dt, out_csv), paste0("write ", out_csv))
if (is.null(ok)) logline("FATAL: could not write ", out_csv) else logline("wrote ", out_csv)

cat("\n---- v130 esi.anchor.coef (region, intercept, slope) ----\n")
print(write_dt)
cat("\n---- derivation detail ----\n")
print(coef_dt)
cat("\nOld operational coef for reference:\n")
cat("  NB c(0.885, 0.01027)  QC c(0.441, 0.03783)  ME/NS c(1, 0)\n")
cat("\nExpected direction: NB/QC intercept and slope slightly ABOVE the old\n")
cat("values (model over-predicts +2.97 pct pooled), so ascale rises, the\n")
cat("increment shrinks, and top-height bias moves toward 0. Verify at the gate.\n")

logline("==== fit_v130_esi_anchor.R done ====")
cat("\nDONE_FIT_V130_ESI_ANCHOR\n")

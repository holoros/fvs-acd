# =====================================================================
# fit_v130_esi_anchor_cofit_v2.R
# FVS-ACD v13.0 Phase 2: iterative co-calibration of the region
# esi.anchor.coef WITH the basal-area post-mortality correction ACTIVE, so
# dominant-height increment is unbiased on the BA-corrected stand path.
# Aaron Weiskittel, CRSF. Cardinal-runnable. No em dashes.
#
# ---------------------------------------------------------------------
# WHAT v2 FIXES (why the v1 co-fit did not converge)
# ---------------------------------------------------------------------
# (1) FROZEN-BIAS DRIVER BUG. In v1 the pooled in-domain top-height bias
#     came back identical across all iterations even though the coefs
#     changed, because the loop read a STALE cb_v130_results.csv (the bench
#     was not actually re-running onto the new coefs, or its output was not
#     being refreshed). v2 deletes cb_v130_results.csv before every bench,
#     records the moment before the bench, and then ASSERTS the results
#     file was regenerated (exists and mtime newer than that moment). If it
#     was not, v2 STOPS loudly instead of silently reading a stale file.
# (2) FALSE-POSITIVE "FATAL: could not write". data.table::fwrite returns
#     NULL invisibly on SUCCESS, and v1 treated NULL as a failure, logging a
#     FATAL every pass. v2 ignores the fwrite return value and instead
#     verifies the write by RE-READING the file and confirming the 3 region
#     rows carry the exact values just written; only then does it proceed,
#     and it logs FATAL only if that re-read verification fails.
# (3) BENCH INPUT PROOF. After writing the coef csv each iteration, v2 echoes
#     back the exact coefs it just re-read from the file the bench will
#     consume, so the log proves the bench input changed between iterations.
# (4) GATE-EXACT IN-DOMAIN MASK. v1 optimised a looser bench mask
#     (esi_ok OR PROV==NB). v2 uses the gate's EXACT in-domain mask so the
#     loop optimises the same quantity the gate scores:
#       in_domain = esi_ok AND epaL3 in c("5.3.1","8.1.7","8.1.8","8.1.1")
#     when the ecoregion join is available, else the fallback
#       in_domain = esi_ok AND PROV != "QC".
# (5) STRUCTURAL CLAMP. The ascale band is now environment driven in the
#     model (patch_ascale_clamp.py rewrites the calc_dht clamp to read
#     ASCALE_LO / ASCALE_HI). The clamp-pin guard here reads the same env
#     values so its warnings reflect the widened band actually in force.
#
# ---------------------------------------------------------------------
# WHY THIS SCRIPT EXISTS (the interaction the joint gate exposed)
# ---------------------------------------------------------------------
# The v13.0 candidate applies two changes to operational v12.10.1: a region
# dominant-height re-anchor expressed as esi.anchor.coef c(intercept, slope),
# and a basal-area net-increment post-mortality correction. The joint gate
# PARKED with a clean split: the BA correction is now fixed and good (BA bias
# toward 0 in 4 of 5 subsets, no more sign flip), but height FAILS
# (height_toward0 FALSE in POOLED_indomain, ESI_low, ESI_high, QMD_large; only
# QMD_small passes).
#
# Root cause is an interaction, not a bad height fit in isolation. The current
# height anchor was fit one-step on remeasurement pairs, INDEPENDENT of the BA
# correction. With BA now corrected upward, the density and QMD trajectory of
# the stand shifts across the multi-year projection, which changes the ESI and
# top-height inputs feeding the anchor, and pushes height off. The anchor is
# therefore miscalibrated on the BA-corrected path.
#
# The fix is projection-in-the-loop, not a one-step re-fit: re-derive the region
# esi.anchor.coef WITH the BA correction switched on, benching the whole model
# each pass and correcting the residual top-height bias until it settles.
#
# ---------------------------------------------------------------------
# HOW THE ANCHOR ACTS INSIDE calc_dht (the hook this script tunes)
# ---------------------------------------------------------------------
#     ascale(ESI) = intercept + slope * ESI              # ESI == csi in the code
#     ascale(ESI) = min(ASCALE_HI, max(ASCALE_LO, ascale))  # clamp band (env driven)
#     dht_corrected = dht_base / ascale(ESI)
# Predicted dominant height is DIVIDED by ascale. Raising ascale LOWERS predicted
# height. So if top height is biased high, we must RAISE ascale; if biased low,
# LOWER it. Top height is an expf-weighted mean of the tallest trees, so dividing
# each tree increment by ascale divides the stand top-height increment by ascale
# to first order. The clamp band defaults to [0.85, 1.35] but is widened for this
# experiment via ASCALE_LO / ASCALE_HI so QC can be pulled off the old 1.35 ceiling.
#
# ---------------------------------------------------------------------
# ALGORITHM (damped Gauss-Seidel, default 3 iterations)
# ---------------------------------------------------------------------
# 1. Start from the current v13.0 coefs (the ones that failed jointly), or read
#    ~/v130_esi_anchor_coef.csv if present:
#        NB c(0.997968, 0.005844)   QC c(-0.153678, 0.069534)   ME c(1.0, 0.0)
# 2. Write the current coefs to ~/v130_esi_anchor_coef.csv, verify by re-read,
#    delete any prior results file, BENCH the full model, and assert the results
#    file was regenerated. Read the per-region pooled in-domain TOPHT relative
#    bias (a fraction, e.g. +0.042 for +4.2 percent).
# 3. Update each region intercept multiplicatively to counter the residual:
#        new_intercept = old_intercept * (1 + gain * topht_bias_frac)
#    gain default 0.9 (damped). Height biased high (+) raises ascale, which pulls
#    height down. Slope is held fixed in the first pass; COFIT_NUDGE_SLOPE=1
#    also nudges slope by the same factor.
# 4. Repeat for COFIT_ITERS iterations, logging per-iteration coefs and per-region
#    TOPHT and BA bias to ~/v130_cofit_log.csv.
# 5. Write the settled coefs to ~/v130_esi_anchor_coef.csv (and an archive copy).
#    If COFIT_FINAL_GATE=1 (default) run one final bench with the settled coefs
#    and the standard gate so the final verdict is captured.
#
# ---------------------------------------------------------------------
# DEFENSIVE NOTES
# ---------------------------------------------------------------------
# * Max intercept change per iteration is capped at 15 percent (COFIT_MAX_STEP),
#   so a single noisy bench cannot swing a region.
# * ascale clamp-pin guard: after every update the fitted line is evaluated
#   across the region in-domain ESI range; if any value falls outside
#   [ASCALE_LO, ASCALE_HI] the script logs a WARNING because the correction
#   saturates there and residual bias can remain at that ESI extreme.
# * KNOWN QC FRAGILITY. QC intercept is NEGATIVE (-0.153678). A pure
#   multiplicative update on a negative intercept moves ascale the WRONG way,
#   so a sign-direction guard falls back to a sign-correct level update
#        new_intercept = old_intercept + ascale_old(ESIbar) * (factor - 1).
# * ME carries no stands in the MagPlot NB/QC benchmark, so its residual height
#   bias cannot be measured here. ME is held fixed at c(1,0) and NS inherits it.
#
# ---------------------------------------------------------------------
# ENV KNOBS (all optional; defaults match the parked-gate context)
# ---------------------------------------------------------------------
#   COFIT_ITERS         iterations, default 3
#   COFIT_GAIN          damping gain, default 0.9
#   COFIT_MAX_STEP      max fractional intercept change per iter, default 0.15
#   COFIT_NUDGE_SLOPE   also nudge slope by the update factor, default 0 (off)
#   COFIT_START_FROM_CSV read start coefs from the coef CSV if it exists, default 1
#   COFIT_BUILD         (re)build the v13.0 model file before iterating, default 0
#   COFIT_FINAL_GATE    run the final bench + gate inside this script, default 1
#   COFIT_SKIP_BENCH    dry mode: skip the heavy bench, read whatever
#                       cb_v130_results.csv already exists, default 0
#   MODEL_FILE          v13.0 model file, default ~/AcadianGY_13.0.r (point at the
#                       wideclamp model for this experiment)
#   ASCALE_LO / ASCALE_HI  ascale clamp band; used here for the clamp-pin guard
#                       and enforced in the model by patch_ascale_clamp.py.
#                       Defaults 0.85 / 1.35.
#   Bench env passed through unchanged: NB_AFAC=0.579, QC_AFAC=0.111, CONFIG_TAG=cb_v130
# =====================================================================

suppressPackageStartupMessages(library(data.table))
set.seed(42)

# ---------------------------------------------------------------------
# 0. Paths, env, logging helpers
# ---------------------------------------------------------------------
getenv_num  <- function(k, d) { v <- suppressWarnings(as.numeric(Sys.getenv(k, ""))); if (is.na(v)) d else v }
getenv_flag <- function(k, d) { v <- Sys.getenv(k, ""); if (!nzchar(v)) return(d); isTRUE(as.logical(v)) || v %in% c("1","yes","YES","Y") }

N_ITER         <- as.integer(getenv_num("COFIT_ITERS", 3))
GAIN           <- getenv_num("COFIT_GAIN", 0.9)
MAX_STEP       <- getenv_num("COFIT_MAX_STEP", 0.15)
NUDGE_SLOPE    <- getenv_flag("COFIT_NUDGE_SLOPE", FALSE)
START_FROM_CSV <- getenv_flag("COFIT_START_FROM_CSV", TRUE)
DO_BUILD       <- getenv_flag("COFIT_BUILD", FALSE)
FINAL_GATE     <- getenv_flag("COFIT_FINAL_GATE", TRUE)
SKIP_BENCH     <- getenv_flag("COFIT_SKIP_BENCH", FALSE)

# The clamp band the model is actually enforcing this run (patch_ascale_clamp.py
# wires ASCALE_LO / ASCALE_HI into calc_dht). Read them here so the clamp-pin
# guard warns against the real band, not the old fixed [0.85, 1.35].
CLAMP_LO <- getenv_num("ASCALE_LO", 0.85)
CLAMP_HI <- getenv_num("ASCALE_HI", 1.35)
BIAS_TOL <- 1e-4   # ignore direction guard on essentially-zero bias

home         <- path.expand("~")
verify_dir   <- file.path(home, "magplot", "verify")
coef_csv     <- file.path(home, "v130_esi_anchor_coef.csv")
coef_prev    <- file.path(home, "v130_esi_anchor_coef_prev.csv")
coef_final   <- file.path(home, "v130_esi_anchor_coef_cofit_final.csv")
log_csv      <- file.path(home, "v130_cofit_log.csv")
cb_results   <- file.path(verify_dir, "cb_v130_results.csv")
bench_run    <- file.path(home, "bench_parity_v130_run.R")
gate_script  <- file.path(home, "v130_score_gate_v2.R")
model_file   <- path.expand(Sys.getenv("MODEL_FILE", file.path(home, "AcadianGY_13.0.r")))
base_model   <- file.path(home, "AcadianGY_12.10.2.r")
builder_py   <- file.path(home, "repos", "fvs-acd", "scripts", "phase2", "build_v130_baonly_v2.py")
err_log      <- file.path(home, "error_log.txt")

logline <- function(...) {
  msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(msg, "\n")
  try(cat(msg, "\n", file = err_log, append = TRUE), silent = TRUE)
}
safe <- function(expr, what = "IO") tryCatch(expr, error = function(e) { logline("ERROR in ", what, ": ", conditionMessage(e)); NULL })

logline("==== fit_v130_esi_anchor_cofit_v2.R start ====")
logline(sprintf("iters=%d gain=%.3f max_step=%.3f nudge_slope=%s start_from_csv=%s build=%s final_gate=%s skip_bench=%s",
                N_ITER, GAIN, MAX_STEP, NUDGE_SLOPE, START_FROM_CSV, DO_BUILD, FINAL_GATE, SKIP_BENCH))
logline(sprintf("ascale clamp band in force this run: [%.3f, %.3f] (ASCALE_LO / ASCALE_HI)", CLAMP_LO, CLAMP_HI))
logline("model file: ", model_file)

# ---------------------------------------------------------------------
# 1. Fixed references and starting coefficients
# ---------------------------------------------------------------------
# The v13.0 candidate coefs that failed the joint gate. These are the loop seed.
V130_START <- list(
  NB = c(intercept = 0.997968,  slope = 0.005844),
  QC = c(intercept = -0.153678, slope = 0.069534),
  ME = c(intercept = 1.0,       slope = 0.0)
)
# Operational v12.10.1 coefs, carried only for the direction sanity print.
OPS_COEF <- list(
  NB = c(intercept = 0.885, slope = 0.01027),
  QC = c(intercept = 0.441, slope = 0.03783),
  ME = c(intercept = 1.0,   slope = 0.0)
)
# Regions the harness maps stands to. NS inherits ME/c(1,0), never written here.
REGIONS <- c("NB", "QC", "ME")
# Only these carry stands in the MagPlot NB/QC benchmark, so only these get a
# measured height bias and an update. ME is held fixed.
MEASURED <- c("NB", "QC")
# Nominal in-domain ESI ranges used only when the results file has no joinable
# esi8 (for the clamp-pin guard and for ESIbar in the direction guard).
ESI_NOMINAL <- list(NB = c(8, 20), QC = c(15, 21), ME = c(5, 25))

read_start_coef <- function() {
  if (START_FROM_CSV && file.exists(coef_csv)) {
    d <- safe(fread(coef_csv), paste0("read start ", coef_csv))
    if (!is.null(d) && all(c("region", "intercept", "slope") %in% names(d))) {
      safe(file.copy(coef_csv, coef_prev, overwrite = TRUE), "backup start coef")
      d[, region := toupper(as.character(region))]
      co <- V130_START
      for (r in REGIONS) {
        hit <- d[region == r]
        if (nrow(hit) >= 1) co[[r]] <- c(intercept = as.numeric(hit$intercept[1]), slope = as.numeric(hit$slope[1]))
      }
      logline("start coefs read from ", coef_csv, " (backed up to ", coef_prev, ")")
      return(co)
    }
    logline("coef CSV present but unreadable/misshaped; using hardcoded v13.0 start coefs.")
  }
  logline("using hardcoded v13.0 start coefs (NB/QC/ME).")
  V130_START
}

# write_coef v2: fwrite returns NULL invisibly on SUCCESS, so we NEVER read its
# return value. We verify by re-reading the file the bench will consume and
# confirming all 3 region rows carry the exact values just written. FATAL is
# logged (and the run stopped) only if that verification fails.
write_coef <- function(co, path = coef_csv) {
  dt <- rbindlist(lapply(REGIONS, function(r) data.table(region = r, intercept = unname(co[[r]][1]), slope = unname(co[[r]][2]))))
  safe(fwrite(dt, path), paste0("write ", path))   # return value ignored on purpose
  rd <- safe(fread(path), paste0("verify-read ", path))
  ok <- FALSE
  if (!is.null(rd) && all(c("region", "intercept", "slope") %in% names(rd))) {
    rd2 <- copy(rd); rd2[, region := toupper(as.character(region))]
    have_all <- all(REGIONS %in% rd2$region)
    vals_ok  <- TRUE
    for (r in REGIONS) {
      hit <- rd2[region == r]
      if (nrow(hit) < 1) { vals_ok <- FALSE; next }
      if (!isTRUE(all.equal(as.numeric(hit$intercept[1]), unname(co[[r]][1]), tolerance = 1e-8)) ||
          !isTRUE(all.equal(as.numeric(hit$slope[1]),     unname(co[[r]][2]), tolerance = 1e-8))) vals_ok <- FALSE
    }
    ok <- have_all && vals_ok
  }
  if (!ok) {
    logline("FATAL: coef write verification failed for ", path,
            " (re-read did not return the 3 region rows with the values just written).")
    stop("coef file verification failed for ", path)
  }
  logline("wrote and verified ", path, " (3 region rows re-read and matched the values written).")
  invisible(dt)
}

# Echo the exact coefs the bench will consume, straight from the file on disk,
# so the log proves the bench input changed between iterations.
echo_coef_file <- function(path = coef_csv) {
  if (!file.exists(path)) { logline("cannot echo coefs; file missing: ", path); return(invisible(NULL)) }
  d <- safe(fread(path), paste0("echo ", path))
  if (is.null(d) || !all(c("region", "intercept", "slope") %in% names(d))) {
    logline("cannot echo coefs; file unreadable/misshaped: ", path); return(invisible(NULL))
  }
  logline("bench will consume these coefs from ", path, ":")
  for (i in seq_len(nrow(d)))
    logline(sprintf("    %-3s c(%.6g, %.6g)", as.character(d$region[i]),
                    as.numeric(d$intercept[i]), as.numeric(d$slope[i])))
  invisible(d)
}

# ---------------------------------------------------------------------
# 2. Build the v13.0 model file (once), if asked or if missing
# ---------------------------------------------------------------------
maybe_build <- function() {
  need <- DO_BUILD || !file.exists(model_file)
  if (!need) { logline("model file present, skipping build: ", model_file); return(invisible(TRUE)) }
  if (!file.exists(builder_py)) { logline("WARNING: builder not found at ", builder_py, "; cannot build ", model_file); return(invisible(FALSE)) }
  if (!file.exists(base_model)) { logline("WARNING: base model not found at ", base_model, "; cannot build ", model_file); return(invisible(FALSE)) }
  logline("building v13.0 model: python3 ", builder_py, " ", base_model, " ", model_file)
  out <- safe(system2("python3", c(shQuote(builder_py), shQuote(base_model), shQuote(model_file)), stdout = TRUE, stderr = TRUE), "build_v130_baonly_v2.py")
  if (!is.null(out)) cat(paste(out, collapse = "\n"), "\n")
  if (!file.exists(model_file)) logline("WARNING: build did not produce ", model_file)
  invisible(file.exists(model_file))
}

# ---------------------------------------------------------------------
# 3. Bench invocation (mirrors bench_parity_v130.sh env and cwd)
#    require_fresh: delete the results file first, then assert the bench
#    regenerated it (exists and mtime newer than the pre-bench moment). This is
#    the core fix for the frozen-bias bug: a stale results file is never read.
# ---------------------------------------------------------------------
run_bench <- function(require_fresh = FALSE) {
  if (SKIP_BENCH) { logline("COFIT_SKIP_BENCH set; not running bench, will read existing ", cb_results); return(file.exists(cb_results)) }
  if (!file.exists(bench_run)) { logline("FATAL: bench runner not found: ", bench_run); return(FALSE) }
  if (require_fresh) {
    unlink(cb_results)
    if (file.exists(cb_results)) {
      logline("FATAL: could not delete stale results file ", cb_results, "; refusing to bench onto a stale file.")
      stop("stale results file could not be removed: ", cb_results)
    }
    logline("deleted prior results file to force regeneration: ", cb_results)
  }
  old <- getwd(); on.exit(setwd(old), add = TRUE)
  if (dir.exists(verify_dir)) setwd(verify_dir) else logline("WARNING: verify dir missing: ", verify_dir)
  env <- c(paste0("MODEL_FILE=", model_file), "CONFIG_TAG=cb_v130", "NB_AFAC=0.579", "QC_AFAC=0.111")
  t0  <- Sys.time()
  logline("running bench: Rscript ", bench_run, " (MODEL_FILE=", model_file, ")")
  out <- safe(system2("Rscript", shQuote(bench_run), env = env, stdout = TRUE, stderr = TRUE), "bench_parity_v130_run.R")
  st  <- attr(out, "status")
  if (!is.null(out) && length(out)) cat(tail(out, 30), sep = "\n")
  if (!is.null(st) && st != 0) { logline("WARNING: bench exited with status ", st); return(FALSE) }
  if (require_fresh) {
    if (!file.exists(cb_results)) {
      logline("FATAL: bench completed but did NOT regenerate ", cb_results,
              ". Refusing to read an absent/stale results file (this was the frozen-bias bug).")
      stop("bench did not regenerate results file: ", cb_results)
    }
    mt <- file.info(cb_results)$mtime
    if (is.na(mt) || as.numeric(mt) < as.numeric(t0) - 2) {
      logline(sprintf("FATAL: results file mtime (%s) is not newer than the pre-bench moment (%s). Stale bench output; stopping the loop.",
                      format(mt), format(t0)))
      stop("bench results file not refreshed (mtime older than bench start): ", cb_results)
    }
    logline("bench freshness verified: ", cb_results, " regenerated at ", format(mt), ".")
  }
  file.exists(cb_results)
}

# ---------------------------------------------------------------------
# 4. Domain mask and per-region in-domain bias
#    v2 uses the gate's EXACT in-domain mask so the loop optimises the same
#    quantity the gate scores.
# ---------------------------------------------------------------------
acadian_L3 <- c("5.3.1", "8.1.7", "8.1.8", "8.1.1")

attach_domain <- function(cb) {
  esi_ok <- if ("esi_cov" %in% names(cb)) as.logical(cb$esi_cov) else rep(TRUE, nrow(cb))
  esi_ok[is.na(esi_ok)] <- FALSE
  eco_path <- if (file.exists(file.path(verify_dir, "magp_qcnb_ecol3_v2.csv"))) file.path(verify_dir, "magp_qcnb_ecol3_v2.csv") else
              if (file.exists(file.path(verify_dir, "magp_qcnb_ecol3.csv")))    file.path(verify_dir, "magp_qcnb_ecol3.csv")    else NA_character_
  have_eco <- FALSE
  if (!is.na(eco_path)) {
    et <- safe(fread(eco_path), "read ecol3")
    if (!is.null(et)) {
      keycols <- intersect(c("STAND", "PROV"), intersect(names(et), names(cb)))
      if (length(keycols) >= 1 && "eco" %in% names(et)) {
        cb <- merge(cb, unique(et[, c(keycols, "eco"), with = FALSE]), by = keycols, all.x = TRUE)
        cb[, epaL3 := as.character(eco)]; have_eco <- cb[epaL3 %in% acadian_L3, .N] > 0
      }
    }
  }
  # Gate-exact mask: ecoregion join when available, else fallback PROV != QC.
  if (have_eco) cb[, in_domain := esi_ok & (epaL3 %in% acadian_L3)]
  else          cb[, in_domain := esi_ok & (PROV != "QC")]
  attr(cb, "domain_rule") <- if (have_eco) paste0("ecoregion join via ", eco_path) else "fallback PROV != QC"
  cb
}

attach_esi <- function(cb) {
  pairs <- file.path(verify_dir, "magp_qcnb_pairs.csv"); e8f <- file.path(verify_dir, "magp_qcnb_site_esi8.csv")
  if (file.exists(pairs) && file.exists(e8f)) {
    pr <- safe(fread(pairs), "read pairs"); e8 <- safe(fread(e8f), "read esi8")
    if (!is.null(pr) && !is.null(e8) && all(c("STAND", "SITE") %in% names(pr)) && all(c("SITE", "esi8") %in% names(e8))) {
      pr[, `:=`(STAND = as.character(STAND), SITE = as.character(SITE))]; e8[, SITE := as.character(SITE)]
      cb[, STAND := as.character(STAND)]
      cb <- merge(cb, pr[, .(STAND, SITE)], by = "STAND", all.x = TRUE)
      cb <- merge(cb, unique(e8[, .(SITE, esi8)]), by = "SITE", all.x = TRUE)
    }
  }
  if (!"esi8" %in% names(cb)) cb[, esi8 := NA_real_]
  cb
}

rel_bias <- function(o, p) {
  ok <- is.finite(o) & is.finite(p); o <- o[ok]; p <- p[ok]
  if (length(o) < 3 || mean(o) == 0) return(list(bias = NA_real_, n = length(o)))
  list(bias = mean(p) / mean(o) - 1, n = length(o))
}

# Returns per-region in-domain TOPHT and BA relative bias plus ESI range.
measure_bias <- function() {
  if (!file.exists(cb_results)) { logline("no results file to measure: ", cb_results); return(NULL) }
  cb <- safe(fread(cb_results), "read cb_v130_results.csv")
  if (is.null(cb)) return(NULL)
  if (!"PROV" %in% names(cb)) { logline("results lack PROV column; cannot split by region."); return(NULL) }
  cb <- attach_esi(attach_domain(cb))
  logline("in-loop domain rule (gate-exact): ", attr(cb, "domain_rule"))
  cb[, PROV := toupper(as.character(PROV))]
  res <- list()
  for (r in MEASURED) {
    d <- cb[in_domain == TRUE & PROV == r]
    th <- if (all(c("TOPHT_o", "TOPHT_p") %in% names(d))) rel_bias(d$TOPHT_o, d$TOPHT_p) else list(bias = NA_real_, n = 0L)
    ba <- if (all(c("BA_o", "BA_p") %in% names(d)))       rel_bias(d$BA_o, d$BA_p)       else list(bias = NA_real_, n = 0L)
    esi_rng <- if (any(is.finite(d$esi8))) range(d$esi8[is.finite(d$esi8)]) else ESI_NOMINAL[[r]]
    res[[r]] <- list(topht = th$bias, ba = ba$bias, n = th$n, esi_min = esi_rng[1], esi_max = esi_rng[2],
                     esi_bar = if (any(is.finite(d$esi8))) mean(d$esi8[is.finite(d$esi8)]) else mean(ESI_NOMINAL[[r]]))
  }
  # Pooled in-domain, for the log and the per-iteration console line.
  dp <- cb[in_domain == TRUE]
  res[["POOLED"]] <- list(
    topht = if (all(c("TOPHT_o", "TOPHT_p") %in% names(dp))) rel_bias(dp$TOPHT_o, dp$TOPHT_p)$bias else NA_real_,
    ba    = if (all(c("BA_o", "BA_p") %in% names(dp)))       rel_bias(dp$BA_o, dp$BA_p)$bias       else NA_real_,
    n = nrow(dp), esi_min = NA_real_, esi_max = NA_real_, esi_bar = NA_real_)
  res
}

# ---------------------------------------------------------------------
# 5. The update rule (specified multiplicative form + sign-direction guard)
# ---------------------------------------------------------------------
ascale_at <- function(co, esi) unname(co[1] + co[2] * esi)

update_region <- function(region, co_in, meas) {
  if (is.null(meas) || is.na(meas$topht)) {
    return(list(intercept = unname(co_in[1]), slope = unname(co_in[2]),
                topht = if (is.null(meas)) NA_real_ else meas$topht,
                ba = if (is.null(meas)) NA_real_ else meas$ba,
                factor = 1, capped = FALSE, guard = FALSE, clamp_hit = FALSE, method = "held_no_bias"))
  }
  bias   <- meas$topht
  raw_f  <- 1 + GAIN * bias
  factor <- min(1 + MAX_STEP, max(1 - MAX_STEP, raw_f))
  capped <- !isTRUE(all.equal(factor, raw_f))

  old_int <- unname(co_in[1]); old_slope <- unname(co_in[2])
  esibar  <- if (is.finite(meas$esi_bar)) meas$esi_bar else mean(ESI_NOMINAL[[region]])
  asc_old <- ascale_at(co_in, esibar)

  # Candidate 1: the specified multiplicative intercept update.
  new_int_mult   <- old_int * factor
  new_slope      <- if (NUDGE_SLOPE) old_slope * factor else old_slope
  asc_new_mult   <- ascale_at(c(new_int_mult, new_slope), esibar)

  # Direction guard: for meaningful bias, ascale must move the intended way.
  intended_up <- bias > 0
  moved_up    <- asc_new_mult > asc_old
  guard       <- FALSE
  if (abs(bias) > BIAS_TOL && intended_up != moved_up) {
    # Sign-correct level update: shift the intercept so the ascale LEVEL at ESIbar
    # scales by the same (capped) factor. Slope held fixed here even if nudging,
    # because the guard fires exactly on the negative-intercept QC case.
    new_int   <- old_int + asc_old * (factor - 1)
    new_slope <- old_slope
    guard     <- TRUE
    logline(sprintf("DIRECTION GUARD region %s: multiplicative update inverted ascale (intercept<0). ", region),
            sprintf("Using level update instead. bias=%+.4f factor=%.4f ESIbar=%.2f", bias, factor, esibar))
    method <- "ascale_level_guard"
  } else {
    new_int <- new_int_mult
    method  <- if (NUDGE_SLOPE) "intercept_slope_mult" else "intercept_mult"
  }

  # Clamp-pin guard across the region in-domain ESI range (against the band in force).
  co_new  <- c(new_int, new_slope)
  a_lo    <- ascale_at(co_new, meas$esi_min); a_hi <- ascale_at(co_new, meas$esi_max)
  clamp_hit <- (is.finite(a_lo) & (a_lo < CLAMP_LO | a_lo > CLAMP_HI)) |
               (is.finite(a_hi) & (a_hi < CLAMP_LO | a_hi > CLAMP_HI))
  if (isTRUE(clamp_hit)) {
    logline(sprintf("WARNING region %s: ascale reaches the [%.2f,%.2f] clamp over ESI [%.2f,%.2f] (ascale %.3f..%.3f). ",
                    region, CLAMP_LO, CLAMP_HI, meas$esi_min, meas$esi_max, a_lo, a_hi),
            "Correction saturates at that ESI extreme; residual bias may remain there.")
    if (region == "QC") logline("  (QC fragility: with the widened band QC should now clear the old 1.35 ceiling.)")
  }

  list(intercept = new_int, slope = new_slope, topht = bias, ba = meas$ba,
       factor = factor, capped = capped, guard = guard, clamp_hit = isTRUE(clamp_hit), method = method)
}

# ---------------------------------------------------------------------
# 6. Iterative co-calibration loop
# ---------------------------------------------------------------------
maybe_build()
coef <- read_start_coef()
log_rows <- list()

for (it in seq_len(N_ITER)) {
  logline(sprintf("---- iteration %d / %d ----", it, N_ITER))
  write_coef(coef, coef_csv)                       # bench reads this file (verified by re-read)
  echo_coef_file(coef_csv)                         # prove the bench input changed this iteration
  ok <- run_bench(require_fresh = TRUE)            # delete + regenerate + assert freshness
  if (!ok) { logline("bench unavailable at iteration ", it, "; stopping loop, keeping current coefs."); break }
  meas <- measure_bias()
  if (is.null(meas)) { logline("could not measure bias at iteration ", it, "; stopping loop."); break }

  pooled <- meas[["POOLED"]]
  logline(sprintf("iter %d pooled in-domain: TOPHT bias %+.4f  BA bias %+.4f  (n=%d)",
                  it, pooled$topht, pooled$ba, pooled$n))

  new_coef <- coef
  for (r in REGIONS) {
    m   <- if (!is.null(meas[[r]])) meas[[r]] else NULL
    upd <- update_region(r, coef[[r]], m)
    new_coef[[r]] <- c(intercept = upd$intercept, slope = upd$slope)
    log_rows[[length(log_rows) + 1L]] <- data.table(
      iter = it, region = r,
      intercept_in = unname(coef[[r]][1]), slope_in = unname(coef[[r]][2]),
      topht_bias = upd$topht, ba_bias = upd$ba,
      factor = upd$factor, capped = upd$capped, dir_guard = upd$guard,
      clamp_hit = upd$clamp_hit, method = upd$method,
      intercept_out = upd$intercept, slope_out = upd$slope)
    logline(sprintf("  %s: in c(%.6g,%.6g) TOPHTbias %+.4f -> out c(%.6g,%.6g) [%s%s%s]",
                    r, coef[[r]][1], coef[[r]][2], ifelse(is.na(upd$topht), 0, upd$topht),
                    upd$intercept, upd$slope, upd$method,
                    ifelse(upd$capped, ",capped", ""), ifelse(upd$clamp_hit, ",clamp", "")))
  }
  coef <- new_coef
  # Persist the log after every iteration so a killed job still leaves a trail.
  safe(fwrite(rbindlist(log_rows), log_csv), paste0("write ", log_csv))
}

# ---------------------------------------------------------------------
# 7. Write the settled coefficients and archive; print summary
# ---------------------------------------------------------------------
write_coef(coef, coef_csv)
write_coef(coef, coef_final)
if (length(log_rows)) safe(fwrite(rbindlist(log_rows), log_csv), paste0("write ", log_csv))

cat("\n---- v130 esi.anchor.coef after co-calibration (region, intercept, slope) ----\n")
print(rbindlist(lapply(REGIONS, function(r) data.table(region = r, intercept = unname(coef[[r]][1]), slope = unname(coef[[r]][2])))))
cat("\nStart (parked joint) coefs:  NB c(0.997968, 0.005844)  QC c(-0.153678, 0.069534)  ME c(1, 0)\n")
cat("Operational v12.10.1 coefs:  NB c(0.885, 0.01027)       QC c(0.441, 0.03783)        ME c(1, 0)\n")
cat("ascale clamp band this run:  [", sprintf("%.3f", CLAMP_LO), ", ", sprintf("%.3f", CLAMP_HI), "]\n", sep = "")
cat("Per-iteration trail written to ", log_csv, "\n", sep = "")

# ---------------------------------------------------------------------
# 8. Final bench + gate (self-contained when run standalone)
# ---------------------------------------------------------------------
if (FINAL_GATE) {
  logline("running final bench + gate on settled coefs (COFIT_FINAL_GATE on).")
  if (run_bench(require_fresh = TRUE)) {
    if (file.exists(gate_script)) {
      old <- getwd(); if (dir.exists(verify_dir)) setwd(verify_dir)
      out <- safe(system2("Rscript", shQuote(gate_script), stdout = TRUE, stderr = TRUE), "v130_score_gate_v2.R")
      setwd(old)
      if (!is.null(out)) cat(paste(out, collapse = "\n"), "\n")
    } else logline("gate script not found: ", gate_script)
  } else logline("final bench did not run; gate skipped.")
} else {
  logline("COFIT_FINAL_GATE off; final bench + gate deferred to the caller (sbatch).")
}

logline("==== fit_v130_esi_anchor_cofit_v2.R done ====")
cat("\nDONE_FIT_V130_ESI_ANCHOR_COFIT_V2\n")

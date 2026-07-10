# =====================================================================
# bench_parity_v130.R
# FVS-ACD v13.0 Phase 2: the single-line modification to the operational
# ~/magplot/verify/bench_parity.R that redirects the height re-anchor onto the
# harness-native esi.anchor.coef hook, reading the FITTED region coefficients
# from ~/v130_esi_anchor_coef.csv instead of the hardcoded operational values.
# No em dashes.
#
# ---------------------------------------------------------------------
# WHAT bench_parity.R DOES TODAY (the operational recipe it hardcodes)
# ---------------------------------------------------------------------
# bench_parity.R reads MODEL_FILE, CONFIG_TAG, NB_AFAC, QC_AFAC and the other
# knobs from the environment, sources the model file, sets the operational ops
# (use.ingrowth, use.sdimort two-segment, use.brms.sdimax, region self-thinning
# break, ingrowth release, per-province dominant-height afac), turns the height
# recal ON, and hardcodes the region coefficients on ONE line:
#
#     ops$use.esi.anchor.recal <- TRUE
#     ops$esi.anchor.coef <- list(c(NB = c(0.885, 0.01027), QC = c(0.441, 0.03783)))
#
# (the list-wrapped named form the calc_dht hook unwraps via the is.null(names(...))
# line). That last assignment is the SINGLE LINE Phase 2 changes.
#
# ---------------------------------------------------------------------
# THE EXACT LINE TO CHANGE
# ---------------------------------------------------------------------
# In ~/magplot/verify/bench_parity.R, replace the one line
#
#     ops$esi.anchor.coef <- list(c(NB = c(0.885, 0.01027), QC = c(0.441, 0.03783)))
#
# with
#
#     source(path.expand("~/magplot/verify/bench_parity_v130.R"))
#     ops$esi.anchor.coef <- build_esi_anchor_from_csv("~/v130_esi_anchor_coef.csv")
#
# Everything else in bench_parity.R (MODEL_FILE, CONFIG_TAG, NB_AFAC/QC_AFAC,
# every other ops assignment, the run and the write of the results CSV) is
# UNCHANGED. bench_parity_v130.sh performs this replacement with sed so the
# generated ~/magplot/verify/bench_parity_v130.R (the runnable copy) is a true
# one-line change of the operational file; this file supplies the loader logic
# that line calls.
#
# ---------------------------------------------------------------------
# The loader: CSV (region, intercept, slope) -> the ops shape the hook consumes
# ---------------------------------------------------------------------
build_esi_anchor_from_csv <- function(csv_path = "~/v130_esi_anchor_coef.csv") {
  p <- path.expand(csv_path)
  if (!file.exists(p)) {
    stop("build_esi_anchor_from_csv: ", p, " not found. Run fit_v130_esi_anchor.R first.")
  }
  d <- utils::read.csv(p, stringsAsFactors = FALSE)
  need <- c("region", "intercept", "slope")
  if (!all(need %in% names(d))) {
    stop("build_esi_anchor_from_csv: ", p, " must have columns region, intercept, slope; found: ",
         paste(names(d), collapse = ", "))
  }
  # One named c(intercept, slope) per region, e.g. NB = c(0.912, 0.01058).
  named <- stats::setNames(
    lapply(seq_len(nrow(d)), function(i) c(as.numeric(d$intercept[i]), as.numeric(d$slope[i]))),
    as.character(d$region)
  )
  # The hook unwraps a length-one UNNAMED outer list around the named object,
  # matching list(c(NB=..., QC=...)); replicate that wrapping exactly.
  coef_list <- list(named)
  cat("v130 esi.anchor.coef loaded from ", p, ":\n", sep = "")
  for (r in names(named)) {
    cat(sprintf("  %s = c(%.6g, %.6g)\n", r, named[[r]][1], named[[r]][2]))
  }
  coef_list
}

# If sourced standalone for a quick check, print what it would load.
if (identical(environment(), globalenv()) &&
    isTRUE(as.logical(Sys.getenv("BENCH_PARITY_V130_SELFTEST", "FALSE")))) {
  invisible(build_esi_anchor_from_csv())
}

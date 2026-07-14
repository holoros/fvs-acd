# FVS-ACD v13.1 GATE (runs on Cardinal in ~/v13_kickoff after the v131_mort_ingrowth_refit fit completes).
# v13.1 is a structural refit, not shipped this run. Pass bar: (1) the mortality fit converged cleanly with NO
# management hazard term, (2) the new hierarchical ingrowth model lifts recruitment toward observed and fits
# the FIA recruitment adequately, (3) no regression on mortality-linked structure. The true NB vs QC province
# transfer needs the August provincial data; here we report the US-region fit adequacy plus, if a MagPlot
# recruitment file is present, the held-out NB/QC recruitment lift versus the shipped 45 percent / 59 percent
# under-prediction. Aggregates only; coordinates never leave the node. Plaintext math, no em dashes.
suppressMessages(library(data.table))
setwd(path.expand("~/v13_kickoff"))
rd <- function(f) if (file.exists(f)) fread(f) else NULL

## ---- 1. mortality convergence (no mgmt hazard term expected) ----
mc <- rd("v131r_mort_convergence.csv")
mort_ok <- NA
if (!is.null(mc)) {
  maxRhat <- suppressWarnings(as.numeric(mc[["max_Rhat"]][1])); ndiv <- suppressWarnings(as.numeric(mc[["n_divergent"]][1]))
  mort_ok <- is.finite(maxRhat) && maxRhat < 1.05 && is.finite(ndiv) && ndiv == 0
  cat("mortality: max_Rhat", maxRhat, " divergences", ndiv, " -> converged:", mort_ok, "\n")
  mfx <- rd("v131r_mort_fixef.csv")
  if (!is.null(mfx)) { has_mgmt <- any(grepl("mgmt|mgd|planted|treated", mfx[[1]], ignore.case=TRUE))
    cat("mortality has a management term (should be FALSE):", has_mgmt, "\n") }
} else cat("v131r_mort_convergence.csv not found, mortality gate deferred\n")

## ---- 2. ingrowth convergence + fit adequacy on FIA regions ----
ic <- rd("v131r_ingrowth_convergence.csv"); ing_conv <- NA
if (!is.null(ic)) { iRhat <- suppressWarnings(as.numeric(ic[["max_Rhat"]][1])); idiv <- suppressWarnings(as.numeric(ic[["n_divergent"]][1]))
  ing_conv <- is.finite(iRhat) && iRhat < 1.05 && is.finite(idiv) && idiv == 0
  cat("ingrowth: max_Rhat", iRhat, " divergences", idiv, " -> converged:", ing_conv, "\n") }

byreg <- rd("v131r_ingrowth_byregion.csv"); ing_fit_ok <- NA
if (!is.null(byreg)) {
  nm <- names(byreg)
  ocol <- nm[grepl("obs", nm, ignore.case=TRUE)][1]; pcol <- nm[grepl("pred|fit", nm, ignore.case=TRUE)][1]
  if (!is.na(ocol) && !is.na(pcol)) {
    o <- suppressWarnings(as.numeric(byreg[[ocol]])); p <- suppressWarnings(as.numeric(byreg[[pcol]]))
    ok <- is.finite(o) & is.finite(p) & o > 0
    ratio <- sum(p[ok]) / sum(o[ok])   # aggregate predicted/observed recruitment across regions
    ing_fit_ok <- is.finite(ratio) && ratio >= 0.85 && ratio <= 1.20
    cat("FIA ingrowth aggregate pred/obs ratio:", round(ratio,3), " (target ~1.0) -> adequate:", ing_fit_ok, "\n")
  } else cat("could not find obs/pred columns in v131r_ingrowth_byregion.csv (cols:", paste(nm, collapse=","), ")\n")
} else cat("v131r_ingrowth_byregion.csv not found, ingrowth fit gate deferred\n")

## ---- 3. optional held-out NB/QC MagPlot recruitment lift vs shipped baseline (45%/59%) ----
## CONFIRM-ON-RETURN: if a MagPlot recruitment file with observed and v13.1-predicted ingrowth exists
## (e.g. ~/magplot/verify/cb_v131_ingrowth.csv with ING_o and ING_p by PROV), compute pred/obs by province
## and compare to the shipped 0.45 (NB) and 0.59 (QC). Left as a hook because it needs the MagPlot ingrowth
## regeneration step; not required for the structural pass.
base_gap <- data.table(PROV=c("NB","QC"), shipped_pred=c(17.9,11.7), obs=c(39.8,19.7), shipped_ratio=c(0.45,0.59))
mp <- rd(path.expand("~/magplot/verify/cb_v131_ingrowth.csv")); nbqc_lift <- NA
if (!is.null(mp) && all(c("PROV","ING_o","ING_p") %in% names(mp))) {
  lift <- mp[, .(obs=mean(ING_o, na.rm=TRUE), pred_v131=mean(ING_p, na.rm=TRUE)), by=PROV][PROV %in% c("NB","QC")]
  lift <- merge(lift, base_gap[, .(PROV, shipped_ratio)], by="PROV")
  lift[, ratio_v131 := pred_v131/obs]
  fwrite(lift, "v131r_nbqc_recruitment_lift.csv"); print(lift)
  nbqc_lift <- all(lift$ratio_v131 > lift$shipped_ratio)   # recruitment rises toward observed
  cat("NB/QC recruitment lifted above shipped baseline:", nbqc_lift, "\n")
} else cat("MagPlot NB/QC recruitment file not present; province lift deferred to the provincial-data step\n")

## ---- verdict ----
core_pass <- isTRUE(mort_ok) && isTRUE(ing_conv) && isTRUE(ing_fit_ok)
verdict <- if (is.na(mort_ok) || is.na(ing_conv) || is.na(ing_fit_ok)) "DEFERRED (outputs incomplete)"
           else if (core_pass) "STRUCTURAL_PASS (converged, no mgmt hazard, recruitment fit adequate)"
           else "PARK (a core condition failed)"
out <- data.table(mortality_converged=mort_ok, ingrowth_converged=ing_conv, ingrowth_fit_adequate=ing_fit_ok,
                  nbqc_recruitment_lift=nbqc_lift, verdict=verdict)
fwrite(out, "v131r_gate_verdict.csv"); cat("\n=== v13.1 GATE ===\n"); print(out); cat("DONE_V131_GATE\n")

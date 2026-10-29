# Pass 30 scorecard: h1_v132_mortgate vs v13.2 baseline on the Canadian sources (NB, QC, NS,
# NS_LONG), using GYDB's current, wider pair coverage. Metrics and observed-basis gate identical
# to merge_v24/2026-08-21_merge-v24-scorecard-noncan_WIP.R (TOTVOL rmse_pct, bias_pct,
# observed-on-predicted OLS slope; gate requires hybrid STAND keys and TOTVOL_o to match the
# v13.2 reference file exactly).
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})
VERIFY <- path.expand("~/magplot/verify"); setwd(VERIFY)
MV <- file.path(VERIFY, "merge_v24")
P21 <- file.path(VERIFY, "p21")

rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)
obs_on_pred_slope <- function(p, o) {
  mx <- mean(p); my <- mean(o)
  sum((p - mx) * (o - my)) / sum((p - mx)^2)
}
rd <- function(f) fread(f)
obs_pair <- function(d) { x <- data.table(STAND = as.character(d$STAND), TOTVOL_o = d$TOTVOL_o)
                          setorder(x, STAND, TOTVOL_o); x }

gate_check <- function(a, b, label) {
  ok <- identical(a$STAND, b$STAND) && nrow(a) == nrow(b) && max(abs(a$TOTVOL_o - b$TOTVOL_o)) < 1e-6
  cat(sprintf("[gate] %-45s n_ref=%d n_hyb=%d pass=%s\n", label, nrow(a), nrow(b), ok))
  ok
}

score1 <- function(d, model, source) data.table(
  model = model, source = source, n = nrow(d),
  rmse_pct = round(rmse_pct(d$TOTVOL_o, d$TOTVOL_p), 2),
  bias_pct = round(bias_pct(d$TOTVOL_o, d$TOTVOL_p), 2),
  slope_obs_on_pred = round(obs_on_pred_slope(d$TOTVOL_p, d$TOTVOL_o), 4))

# ---- NB: baseline is PROV=="NB" subset of p9_v132_nb_v2; hybrid is PROV=="NB" subset of the
# pass-30 rerun h1_v132_mortgate_nb_v2 ----------------------------------------------------------
base_nbqc <- rd(file.path(P21, "p9_v132_nb_v2_results.csv"))
hyb_nbqc  <- rd(file.path(MV,  "h1_v132_mortgate_nb_v2_results.csv"))
base_nb <- base_nbqc[PROV == "NB"]; hyb_nb <- hyb_nbqc[PROV == "NB"]
base_qc <- base_nbqc[PROV == "QC"]; hyb_qc <- hyb_nbqc[PROV == "QC"]

gate_ok <- c(
  gate_check(obs_pair(base_nb), obs_pair(hyb_nb), "NB"),
  gate_check(obs_pair(base_qc), obs_pair(hyb_qc), "QC"),
  gate_check(obs_pair(base_nbqc), obs_pair(hyb_nbqc), "NB+QC combined")
)

# ---- NS: v13.2 baseline managed+unmanaged vs the EXISTING merge_v24 h1 files (verified this
# pass to match current p21 baseline STAND-for-STAND, reused as-is, not rerun) -------------------
base_ns_man <- rd(file.path(P21, "p9_v132_ns_managed_results.csv"))
base_ns_unm <- rd(file.path(P21, "p9_v132_ns_unmanaged_results.csv"))
hyb_ns_man  <- rd(file.path(MV,  "h1_v132_mortgate_ns_managed_results.csv"))
hyb_ns_unm  <- rd(file.path(MV,  "h1_v132_mortgate_ns_unmanaged_results.csv"))
gate_ok <- c(gate_ok,
  gate_check(obs_pair(base_ns_man), obs_pair(hyb_ns_man), "NS managed (reused merge_v24 file)"),
  gate_check(obs_pair(base_ns_unm), obs_pair(hyb_ns_unm), "NS unmanaged (reused merge_v24 file)"))
base_ns <- rbindlist(list(base_ns_man, base_ns_unm))
hyb_ns  <- rbindlist(list(hyb_ns_man,  hyb_ns_unm))

# ---- NS_LONG: v13.2 baseline managed_singleregime + unmanaged + multiregime vs the pass-30
# rerun h1 files (all three components rerun this pass, none pre-existed in merge_v24) ----------
base_nsl_man   <- rd(file.path(P21, "p9_v132_ns_long_managed_results.csv"))
base_nsl_unm   <- rd(file.path(P21, "p9_v132_ns_long_unmanaged_results.csv"))
base_nsl_multi <- rd(file.path(P21, "p9_v132_ns_long_multiregime_results.csv"))
hyb_nsl_man    <- rd(file.path(MV, "h1_v132_mortgate_ns_long_managed_singleregime_results.csv"))
hyb_nsl_unm    <- rd(file.path(MV, "h1_v132_mortgate_ns_long_unmanaged_results.csv"))
hyb_nsl_multi  <- rd(file.path(MV, "h1_v132_mortgate_ns_long_multiregime_results.csv"))
gate_ok <- c(gate_ok,
  gate_check(obs_pair(base_nsl_man), obs_pair(hyb_nsl_man), "NS_LONG managed singleregime (rerun)"),
  gate_check(obs_pair(base_nsl_unm), obs_pair(hyb_nsl_unm), "NS_LONG unmanaged (rerun)"),
  gate_check(obs_pair(base_nsl_multi), obs_pair(hyb_nsl_multi), "NS_LONG managed multiregime (rerun)"))
base_nsl <- rbindlist(list(base_nsl_man, base_nsl_unm, base_nsl_multi))
hyb_nsl  <- rbindlist(list(hyb_nsl_man,  hyb_nsl_unm,  hyb_nsl_multi))

if (any(!gate_ok)) stop("OBSERVED BASIS MISMATCH -- see [gate] lines above")
cat("\nAll observed-basis gates passed.\n\n")

# ---- metric table ------------------------------------------------------------------------------
rows <- list(
  score1(base_nb,  "v13.2 baseline",     "NB"),
  score1(hyb_nb,   "h1_v132_mortgate",   "NB"),
  score1(base_qc,  "v13.2 baseline",     "QC"),
  score1(hyb_qc,   "h1_v132_mortgate",   "QC"),
  score1(base_ns,  "v13.2 baseline",     "NS"),
  score1(hyb_ns,   "h1_v132_mortgate",   "NS"),
  score1(base_nsl, "v13.2 baseline",     "NS_LONG"),
  score1(hyb_nsl,  "h1_v132_mortgate",   "NS_LONG")
)
out <- rbindlist(rows)
out[, source := factor(source, levels = c("NB","QC","NS","NS_LONG"))]
setorder(out, source, model)
fwrite(out, file.path(P21, "pass30_h1_vs_v132_canadian.csv"))
cat("WROTE", file.path(P21, "pass30_h1_vs_v132_canadian.csv"), "rows =", nrow(out), "\n\n")
print(out, nrows = 50)
cat("\nDONE_PASS30_SCORECARD_CANADIAN\n")

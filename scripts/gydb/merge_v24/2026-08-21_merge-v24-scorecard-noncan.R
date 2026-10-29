# Pass 24 config-merge scorecard, NON-CANADIAN scope (Aaron, 21 Aug 2026): NB MagPlot, QC MagPlot,
# NS, and NS-long are excluded from the verdict. Sources scored: Baxter, CTRN, PEF, Maine FIA
# whole-plot (bench_mefia_long), Maine FIA mature (memat) and developing (medev), SILC_L.
# Hybrid files come from arrays 13776765 (baxter, ctrn) and 13796147 (mef, pef, silc_l, memat,
# medev). Metrics identical to p21 composite: TOTVOL rmse_pct, bias_pct, observed-on-predicted
# OLS slope. Observed-basis gate: every hybrid file must match the v13.2 file STAND keys and
# TOTVOL_o exactly. Baselines cross-checked against gydb_ws/comparison/v1211_vs_v132_comparison.csv.
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})
VERIFY <- path.expand("~/magplot/verify"); setwd(VERIFY)
MV <- file.path(VERIFY, "merge_v24")

rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)
obs_on_pred_slope <- function(p, o) {
  mx <- mean(p); my <- mean(o)
  sum((p - mx) * (o - my)) / sum((p - mx)^2)
}
rd <- function(f) fread(f)

hybrids <- c("h1_v132_mortgate", "h2_v132_dhthw", "h3_v132_mortgate_dhthw", "h4_v132_full1211")

src <- data.table(
  source = c("Baxter (mature, held-out)", "CFRU CTRN (managed)", "PEF (developing)",
             "Maine FIA whole-plot (= 20-yr long)", "Maine FIA mature (memat)",
             "Maine FIA developing (medev)", "SILC/Seven Islands (calibration, managed)"),
  tag    = c("baxter", "ctrn", "pef", "mef", "memat", "medev", "silc_l"),
  cand_f = c("p18osm/p18cand_baxter_results.csv", "cand_ctrn_results.csv", "cand_pef_results.csv",
             "cand_mefia_l_results.csv", NA, NA, "cand_silc_l_results.csv"),
  v132_f = c("p21/p9_bax_v132_results.csv", "p21/p9_v132_ctrn_results.csv",
             "p21/p9_v132_pef_results.csv", "p21/p9_mef_v132_results.csv",
             "p21/p9_v132_memat_results.csv", "p21/p9_v132_medev_results.csv",
             "p21/p9_v132_silc_l_results.csv"))

obs_pair <- function(d) { x <- data.table(STAND = as.character(d$STAND), TOTVOL_o = d$TOTVOL_o)
                          setorder(x, STAND, TOTVOL_o); x }

# ---- observed-basis gate ----------------------------------------------------------------------
gate <- list()
for (i in seq_len(nrow(src))) {
  a <- obs_pair(rd(src$v132_f[i]))
  for (h in hybrids) {
    f <- file.path(MV, sprintf("%s_%s_results.csv", h, src$tag[i]))
    if (!file.exists(f)) { gate[[length(gate)+1L]] <- data.table(hybrid=h, source=src$source[i],
        n_ref=nrow(a), n_hyb=NA_integer_, pass=NA); next }
    b <- obs_pair(rd(f))
    ok <- identical(a$STAND, b$STAND) && nrow(a) == nrow(b) && max(abs(a$TOTVOL_o - b$TOTVOL_o)) < 1e-6
    gate[[length(gate)+1L]] <- data.table(hybrid=h, source=src$source[i],
                                          n_ref=nrow(a), n_hyb=nrow(b), pass=ok)
  }
}
gate <- rbindlist(gate)
fwrite(gate, file.path(MV, "merge_v24_observed_check_noncan.csv"))
print(gate)
if (isTRUE(any(!gate$pass, na.rm = TRUE))) stop("OBSERVED BASIS MISMATCH")
cat("Observed basis verified (NA = hybrid file missing, disclosed).\n\n")

# ---- metric table -----------------------------------------------------------------------------
score1 <- function(d, model, source) data.table(
  model = model, source = source, n = nrow(d),
  rmse_pct = round(rmse_pct(d$TOTVOL_o, d$TOTVOL_p), 2),
  bias_pct = round(bias_pct(d$TOTVOL_o, d$TOTVOL_p), 2),
  slope_obs_on_pred = round(obs_on_pred_slope(d$TOTVOL_p, d$TOTVOL_o), 4))

rows <- list()
for (i in seq_len(nrow(src))) {
  if (!is.na(src$cand_f[i])) rows[[length(rows)+1L]] <- score1(rd(src$cand_f[i]),
      "v12.11 candidate", src$source[i])
  rows[[length(rows)+1L]] <- score1(rd(src$v132_f[i]), "v13.2 site-fsm (pass 20)", src$source[i])
  for (h in hybrids) {
    f <- file.path(MV, sprintf("%s_%s_results.csv", h, src$tag[i]))
    if (file.exists(f)) rows[[length(rows)+1L]] <- score1(rd(f), h, src$source[i])
  }
}
out <- rbindlist(rows)
out[, source := factor(source, levels = src$source)]
setorder(out, source)
fwrite(out, file.path(MV, "merge_v24_results_noncanadian.csv"))
cat("WROTE", file.path(MV, "merge_v24_results_noncanadian.csv"), "rows =", nrow(out), "\n")
print(out, nrows = 300)

# ---- baseline cross-check vs gydb comparison CSV ----------------------------------------------
cmp <- fread("/users/PUOM0008/crsfaaron/gydb_ws/comparison/v1211_vs_v132_comparison.csv")
chk <- merge(out[model == "v13.2 site-fsm (pass 20)",
                 .(source = as.character(source), rmse_here = rmse_pct, bias_here = bias_pct)],
             cmp[, .(source, rmse_v132, bias_v132)], by = "source")
chk[, ok := abs(rmse_here - rmse_v132) < 0.02 & abs(bias_here - bias_v132) < 0.02]
cat("\nBaseline cross-check (v13.2 vs comparison CSV):\n"); print(chk)
chk2 <- merge(out[model == "v12.11 candidate",
                  .(source = as.character(source), rmse_here = rmse_pct, bias_here = bias_pct)],
              cmp[, .(source, rmse_cand, bias_cand)], by = "source")
chk2[, ok := abs(rmse_here - rmse_cand) < 0.02 & abs(bias_here - bias_cand) < 0.02]
cat("\nBaseline cross-check (v12.11 cand vs comparison CSV):\n"); print(chk2)
cat("DONE_MERGE_V24_SCORECARD_NONCAN\n")

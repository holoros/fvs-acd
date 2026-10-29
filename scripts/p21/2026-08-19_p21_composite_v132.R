# PASS 21 composite: adds a v13.2 (site-fsm calc_ddbh patch, pass 20) column alongside the
# existing base / v12.11 candidate / v13.1 ship18 / OSM four-way composite from
# p18osm/p19_composite_ship18.R. Five-way comparison so the pass-20 patch's effect is visible
# directly against everything else in one table, not just against ship18 in isolation.
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})
RNG_SEED   <- 20260811L
N_BOOT     <- 2000L
VERIFY_DIR <- path.expand("~/magplot/verify")
P21_DIR    <- file.path(VERIFY_DIR, "p21")
OUT_COMP   <- file.path(P21_DIR, "p21_composite_v132.csv")
OUT_PERSRC <- file.path(P21_DIR, "p21_equivalence_persource.csv")
OUT_CHECK  <- file.path(P21_DIR, "p21_observed_check.csv")
OUT_WIDE   <- file.path(P21_DIR, "p21_v132_persource.csv")
setwd(VERIFY_DIR)
rd          <- function(f) fread(f)
rbind_files <- function(files) rbindlist(lapply(files, rd), fill = TRUE)
indomain_fix <- function(d) { stopifnot("esi_cov" %in% names(d)); d[esi_cov == TRUE] }
fixed_sources <- list(
  "Baxter (mature, held-out)" = list(interval = 11.0, base = rd("p18osm/p18base_baxter_results.csv"), cand = rd("p18osm/p18cand_baxter_results.csv"), v131 = rd("p9lev3/p9_bax_ship18_results.csv"), v132 = rd("p21/p9_bax_v132_results.csv"), osm  = rd("p18osm/p18_osm_score_baxter_results.csv")),
  "CFRU CTRN (managed)" = list(interval = 1.0, base = rd("base_ctrn_results.csv"), cand = rd("cand_ctrn_results.csv"), v131 = rd("p9lev3/p9_ship18_ctrn_results.csv"), v132 = rd("p21/p9_v132_ctrn_results.csv"), osm  = rd("osm_score_ctrn_results.csv")),
  "Maine FIA whole-plot (= 20-yr long)" = list(interval = 20.41, base = rd("base_mefia_l_results.csv"), cand = rd("cand_mefia_l_results.csv"), v131 = rd("p9lev3/p9_mef_ship18_results.csv"), v132 = rd("p21/p9_mef_v132_results.csv"), osm  = rd("osm_score_me_fia_l_results.csv")),
  "PEF (developing)" = list(interval = 5.61, base = rd("base_pef_results.csv"), cand = rd("cand_pef_results.csv"), v131 = rd("p9lev3/p9_ship18_pef_results.csv"), v132 = rd("p21/p9_v132_pef_results.csv"), osm  = rd("osm_score_pef_results.csv")),
  "SILC/Seven Islands (calibration, managed)" = list(interval = 10.37, base = rd("base_silc_l_results.csv"), cand = rd("cand_silc_l_results.csv"), v131 = rd("p9lev3/p9_ship18_silc_l_results.csv"), v132 = rd("p21/p9_v132_silc_l_results.csv"), osm  = rd("osm_score_silc_l_results.csv")),
  "NB MagPlot (managed)" = list(interval = 4.90, base = rd("base_nb_results.csv")[PROV == "NB"], cand = rd("cand_nb_results.csv")[PROV == "NB"], v131 = rd("p9lev3/p9_ship18_nb_results.csv")[PROV == "NB"], v132 = rd("p21/p9_v132_nb_results.csv")[PROV == "NB"], osm  = rd("g4_osm_score_nb_results.csv")[PROV == "NB"])
)
ns_long_interval <- (3939 * 5.00 + 506 * 21.9 + 903 * 36.3) / 5348
ns_row <- list(
  NS = list(interval = 5.00, base = rd("ns_base_results.csv"), cand = rbind_files(c("ns_cand_managed_results.csv", "ns_cand_unmanaged_results.csv")), v131 = indomain_fix(rbind_files(c("p9lev3/p9_ship18_ns_managed_results.csv", "p9lev3/p9_ship18_ns_unmanaged_results.csv"))), v132 = indomain_fix(rbind_files(c("p21/p9_v132_ns_managed_results.csv", "p21/p9_v132_ns_unmanaged_results.csv"))), osm  = rd("osm_score_ns_results.csv")),
  `NS-long` = list(interval = ns_long_interval, base = rbind_files(c("ns_long_base_managed_results.csv", "ns_long_base_unmanaged_results.csv")), cand = rbind_files(c("ns_long_cand_managed_results.csv", "ns_long_cand_unmanaged_results.csv")), v131 = indomain_fix(rbind_files(c("p9lev3/p9_ship18_ns_long_managed_results.csv", "p9lev3/p9_ship18_ns_long_unmanaged_results.csv"))), v132 = indomain_fix(rbind_files(c("p21/p9_v132_ns_long_managed_results.csv", "p21/p9_v132_ns_long_unmanaged_results.csv"))), osm  = rd("osm_score_ns_long_results.csv"))
)
obs_pair <- function(d) { x <- data.table(STAND = as.character(d$STAND), TOTVOL_o = d$TOTVOL_o); setorder(x, STAND, TOTVOL_o); x }
check_rows <- list()
add_check <- function(label, dbase, dv132) {
  a <- obs_pair(dbase); b <- obs_pair(dv132)
  keys_eq <- identical(a$STAND, b$STAND)
  maxd <- if (nrow(a) == nrow(b)) max(abs(a$TOTVOL_o - b$TOTVOL_o)) else NA_real_
  check_rows[[length(check_rows) + 1L]] <<- data.table(source = label, n_base = nrow(a), n_v132 = nrow(b), stand_keys_identical = keys_eq, max_abs_dTOTVOL_o = maxd)
}
for (s in names(fixed_sources)) add_check(s, fixed_sources[[s]]$base, fixed_sources[[s]]$v132)
add_check("NS (overall)",      ns_row$NS$base,        ns_row$NS$v132)
add_check("NS-long (overall)", ns_row$`NS-long`$base, ns_row$`NS-long`$v132)
check_df <- rbindlist(check_rows)
cat("OBSERVED-BASIS CHECK (v132 vs base column):\n"); print(check_df)
fwrite(check_df, OUT_CHECK)
if (!all(check_df$stand_keys_identical) || any(!is.finite(check_df$max_abs_dTOTVOL_o)) || max(check_df$max_abs_dTOTVOL_o) > 1e-6) {
  stop("OBSERVED BASIS MISMATCH: see p21_observed_check.csv. Nothing computed.")
}
cat("Observed basis verified: v132 matches the base observed side on all sources.\n\n")
rmse_pct <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)
bias_pct <- function(o, p) 100 * (mean(p) - mean(o)) / mean(o)
ols_coef <- function(p, o) { mx <- mean(p); my <- mean(o); slope <- sum((p - mx) * (o - my)) / sum((p - mx)^2); intercept <- my - slope * mx; c(intercept = intercept, slope = slope) }
run_scenario_model <- function(ns_treatment, model, seed_offset) {
  src_list <- fixed_sources
  src_list[["NS (overall)"]] <- ns_row[[ns_treatment]]
  srcs <- names(src_list)
  o_list <- setNames(vector("list", length(srcs)), srcs); p_list <- setNames(vector("list", length(srcs)), srcs)
  w_list <- setNames(numeric(length(srcs)), srcs); n_list <- setNames(integer(length(srcs)), srcs)
  for (s in srcs) {
    d <- src_list[[s]][[model]]; d <- d[is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
    o_list[[s]] <- d$TOTVOL_o; p_list[[s]] <- d$TOTVOL_p; n_list[[s]] <- nrow(d); w_list[[s]] <- nrow(d) * src_list[[s]]$interval
  }
  point_rmse <- vapply(srcs, function(s) rmse_pct(o_list[[s]], p_list[[s]]), numeric(1))
  point_bias <- vapply(srcs, function(s) bias_pct(o_list[[s]], p_list[[s]]), numeric(1))
  w <- w_list[srcs]; composite_rmse <- sum(w * point_rmse) / sum(w); composite_bias <- sum(w * point_bias) / sum(w)
  set.seed(RNG_SEED + seed_offset)
  rmse_draws <- numeric(N_BOOT); bias_draws <- numeric(N_BOOT)
  for (b in seq_len(N_BOOT)) {
    r_b  <- numeric(length(srcs)); bi_b <- numeric(length(srcs))
    for (i in seq_along(srcs)) { s <- srcs[i]; n_s <- n_list[[s]]; idx <- sample.int(n_s, n_s, replace = TRUE); ob <- o_list[[s]][idx]; pb <- p_list[[s]][idx]; r_b[i]  <- rmse_pct(ob, pb); bi_b[i] <- bias_pct(ob, pb) }
    rmse_draws[b] <- sum(w * r_b) / sum(w); bias_draws[b] <- sum(w * bi_b) / sum(w)
  }
  rmse_ci <- unname(quantile(rmse_draws, c(0.025, 0.975), type = 7)); bias_ci <- unname(quantile(bias_draws, c(0.025, 0.975), type = 7))
  list(ns_treatment = ns_treatment, model = model, n_sources = length(srcs), n_stands = sum(unlist(n_list)), rmse = composite_rmse, rmse_lo = rmse_ci[1], rmse_hi = rmse_ci[2], bias = composite_bias, bias_lo = bias_ci[1], bias_hi = bias_ci[2], o_list = o_list, p_list = p_list, n_list = n_list)
}
models    <- c("base", "cand", "v131", "v132", "osm")
model_lab <- c(base = "BASE (frozen v12.10.1)", cand = "CANDIDATE v12.11", v131 = "v13.1 ship18", v132 = "v13.2 site-fsm (pass 20)", osm = "OSM-ACD v2.26.1")
scenarios <- c("NS", "NS-long")
results <- list(); seed_off <- 0L
for (ns_treat in scenarios) { for (m in models) { seed_off <- seed_off + 1L; res <- run_scenario_model(ns_treat, m, seed_off); results[[paste(ns_treat, m)]] <- res } }
results_df <- rbindlist(lapply(results, function(r) { data.table(ns_treatment = r$ns_treatment, model = model_lab[r$model], n_sources = r$n_sources, n_stands = r$n_stands, rmse = round(r$rmse, 2), rmse_lo = round(r$rmse_lo, 2), rmse_hi = round(r$rmse_hi, 2), bias = round(r$bias, 2), bias_lo = round(r$bias_lo, 2), bias_hi = round(r$bias_hi, 2)) }))
cat(strrep("=", 100), "\n", sep = ""); cat("FIVE-WAY composite: base / v12.11 / v13.1 ship18 / v13.2 site-fsm / OSM\n"); cat(strrep("=", 100), "\n")
print(results_df); fwrite(results_df, OUT_COMP); cat(sprintf("\nWrote %s\n", OUT_COMP))
persource_rows <- list(); seed_ps <- 0L
for (ns_treat in scenarios) {
  for (m in models) {
    r <- results[[paste(ns_treat, m)]]
    for (s in names(r$o_list)) {
      seed_ps <- seed_ps + 1L
      o <- r$o_list[[s]]; p <- r$p_list[[s]]; n_s <- r$n_list[[s]]
      pt   <- ols_coef(p, o); pt_r <- rmse_pct(o, p); pt_b <- bias_pct(o, p)
      set.seed(RNG_SEED + 9000L + seed_ps)
      int_d <- numeric(N_BOOT); slp_d <- numeric(N_BOOT); rmse_d <- numeric(N_BOOT); bias_d <- numeric(N_BOOT)
      for (b in seq_len(N_BOOT)) { idx <- sample.int(n_s, n_s, replace = TRUE); ob <- o[idx]; pb <- p[idx]; cf <- ols_coef(pb, ob); int_d[b] <- cf["intercept"]; slp_d[b] <- cf["slope"]; rmse_d[b] <- rmse_pct(ob, pb); bias_d[b] <- bias_pct(ob, pb) }
      int_ci  <- unname(quantile(int_d, c(0.025, 0.975), type = 7)); slp_ci  <- unname(quantile(slp_d, c(0.025, 0.975), type = 7))
      rmse_ci <- unname(quantile(rmse_d, c(0.025, 0.975), type = 7)); bias_ci <- unname(quantile(bias_d, c(0.025, 0.975), type = 7))
      persource_rows[[length(persource_rows) + 1L]] <- data.table(ns_treatment = ns_treat, model = model_lab[m], source = s, n = n_s, mean_obs = round(mean(o), 2), intercept = round(unname(pt["intercept"]), 3), intercept_lo = round(int_ci[1], 3), intercept_hi = round(int_ci[2], 3), slope = round(unname(pt["slope"]), 4), slope_lo = round(slp_ci[1], 4), slope_hi = round(slp_ci[2], 4), rmse_pct = round(pt_r, 2), rmse_pct_lo = round(rmse_ci[1], 2), rmse_pct_hi = round(rmse_ci[2], 2), bias_pct = round(pt_b, 2), bias_pct_lo = round(bias_ci[1], 2), bias_pct_hi = round(bias_ci[2], 2))
    }
  }
}
persource_df <- rbindlist(persource_rows); fwrite(persource_df, OUT_PERSRC)
cat("\nPER-SOURCE (unpooled), 5 models x 8 sources x 2 scenarios:\n"); print(persource_df); cat(sprintf("\nWrote %s\n", OUT_PERSRC))
short <- c("BASE (frozen v12.10.1)" = "base", "CANDIDATE v12.11" = "cand", "v13.1 ship18" = "ship18", "v13.2 site-fsm (pass 20)" = "v132", "OSM-ACD v2.26.1" = "osm")
pw <- copy(persource_df); pw[, mkey := short[model]]
keep <- pw[ns_treatment == "NS" | source == "NS (overall)"]
keep[, row_source := ifelse(source == "NS (overall)", paste0("NS (overall) [", ns_treatment, " scenario]"), source)]
wide <- dcast(keep, row_source ~ mkey, value.var = c("n", "rmse_pct", "bias_pct", "slope", "intercept"))
best <- keep[, .SD[which.min(rmse_pct)], by = row_source][, .(row_source, best_rmse_model = model)]
wide <- merge(wide, best, by = "row_source")
out_wide <- wide[, .(source = row_source, n = n_ship18, n_equal_all_models = (n_base == n_cand & n_base == n_ship18 & n_base == n_v132 & n_base == n_osm), rmse_base = rmse_pct_base, bias_base = bias_pct_base, rmse_cand = rmse_pct_cand, bias_cand = bias_pct_cand, rmse_ship18 = rmse_pct_ship18, bias_ship18 = bias_pct_ship18, rmse_v132 = rmse_pct_v132, bias_v132 = bias_pct_v132, slope_ship18 = slope_ship18, slope_v132 = slope_v132, rmse_osm = rmse_pct_osm, bias_osm = bias_pct_osm, best_rmse_model)]
src_order <- c("Baxter (mature, held-out)", "CFRU CTRN (managed)", "Maine FIA whole-plot (= 20-yr long)", "PEF (developing)", "SILC/Seven Islands (calibration, managed)", "NB MagPlot (managed)", "NS (overall) [NS scenario]", "NS (overall) [NS-long scenario]")
out_wide <- out_wide[match(src_order, source)]
fwrite(out_wide, OUT_WIDE)
cat("\nCOMPACT PER-SOURCE TABLE (base / cand / ship18 / v132 / OSM):\n"); print(out_wide); cat(sprintf("\nWrote %s\n", OUT_WIDE))
cat("DONE_P21_V132_COMPOSITE\n")

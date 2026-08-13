#!/usr/bin/env Rscript
# equivalence_test_v25.R
# v25 copy of equivalence_test_v24.R -- same Robinson et al. (2005) bootstrap
# equivalence (TOST) methodology, unchanged. Retargeted to the v25 by-plot
# scorecard: FVSACD_v1211_silc73 retired (replaced by full-coverage
# FVSACD_v1211_full), FVSACD_v131_full added (new model, not in v24 at all).
# FVSACD_v131_ship18 added same day -- third v13.x candidate, addition only.

suppressMessages({
  library(equivalence)   # pulls in boot, ggplot2, lattice, PairedData
})
set.seed(20260812)

setwd("/users/PUOM0008/crsfaaron/silc_cfi")

REPS    <- 5000
ALPHA   <- 0.05
B0_PROP <- 0.25    # house default, applied to mean(OBSERVED) per rule 16
B1_PROP <- 0.25

by <- read.csv("silc_cfi_value_v25_byplot.csv", stringsAsFactors = FALSE)
obs <- by[by$model_config == "OBSERVED", c("PLOT","tot_cd","tot_val")]
names(obs) <- c("PLOT","tot_cd_obs","tot_val_obs")

model_cfg <- c("AGM_v835","FVSACD_v1211_full","FVSACD_v131_full","FVSACD_v131_ship18","FVS_ACD_default","FVS_NE_default","OSM_ACD")
model_lab <- c("AcadianGY v8.35","FVS-ACD v12.11 (full137)","FVS-ACD v13.1 (full137)","FVS-ACD v13.1 ship18 (full137)","FVS-ACD default","FVS-NE default","OSM-ACD")

equiv_analysis <- function(pred, obsv, reps = REPS, alpha = ALPHA,
                            b0_prop = B0_PROP, b1_prop = B1_PROP) {
  n <- length(pred)
  compare <- cbind(obsv, pred)
  m_pred <- mean(pred, na.rm = TRUE)
  m_obs  <- mean(obsv, na.rm = TRUE)

  fit0 <- lm(obsv ~ I(pred - m_pred))
  intercept_hat <- unname(coef(fit0)[1])   # == mean(obsv) by OLS centroid property
  slope_hat     <- unname(coef(fit0)[2])

  stat_fn <- function(cmp, idx) {
    o <- cmp[idx, 1]; p <- cmp[idx, 2]
    f <- lm(o ~ I(p - m_pred))   # m_pred fixed at ORIGINAL sample mean (equiv.boot.lm convention)
    c(intercept = unname(coef(f)[1]), slope = unname(coef(f)[2]))
  }
  bt <- boot::boot(compare, stat_fn, R = reps)

  ci_b0 <- quantile(bt$t[, 1], c(alpha, 1 - alpha))
  ci_b1 <- quantile(bt$t[, 2], c(alpha, 1 - alpha))

  region_b0 <- b0_prop * abs(m_obs)
  rs_b0 <- c(m_pred - region_b0, m_pred + region_b0)
  rs_b1 <- c(1 - b1_prop, 1 + b1_prop)

  pass_b0 <- (ci_b0[1] > rs_b0[1]) & (ci_b0[2] < rs_b0[2])
  pass_b1 <- (ci_b1[1] > rs_b1[1]) & (ci_b1[2] < rs_b1[2])

  grid_fine <- seq(0.01, 2.00, by = 0.005)
  ok_b0 <- sapply(grid_fine, function(r) (ci_b0[1] > (m_pred - r*abs(m_obs))) & (ci_b0[2] < (m_pred + r*abs(m_obs))))
  ok_b1 <- sapply(grid_fine, function(r) (ci_b1[1] > (1-r)) & (ci_b1[2] < (1+r)))
  smallest_b0 <- if (any(ok_b0)) min(grid_fine[ok_b0]) else NA
  smallest_b1 <- if (any(ok_b1)) min(grid_fine[ok_b1]) else NA
  smallest_combined <- max(smallest_b0, smallest_b1)

  grid5 <- seq(0.05, 0.50, by = 0.05)
  grid_tab <- data.frame(region = grid5,
    pass_b0 = sapply(grid5, function(r) (ci_b0[1] > (m_pred - r*abs(m_obs))) & (ci_b0[2] < (m_pred + r*abs(m_obs)))),
    pass_b1 = sapply(grid5, function(r) (ci_b1[1] > (1-r)) & (ci_b1[2] < (1+r))))
  grid_tab$pass_both <- grid_tab$pass_b0 & grid_tab$pass_b1

  list(n = n, m_obs = m_obs, m_pred = m_pred, bias_pct = 100*(m_pred/m_obs - 1),
       intercept_hat = intercept_hat, slope_hat = slope_hat,
       ci_b0 = ci_b0, ci_b1 = ci_b1, rs_b0 = rs_b0, rs_b1 = rs_b1,
       pass_b0 = pass_b0, pass_b1 = pass_b1,
       smallest_b0 = smallest_b0, smallest_b1 = smallest_b1, smallest_combined = smallest_combined,
       grid_tab = grid_tab, boot_b0 = bt$t[,1], boot_b1 = bt$t[,2],
       pred = pred, obsv = obsv)
}

metrics <- c("tot_val", "tot_cd")
metric_lab <- c(tot_val = "Value ($/ac)", tot_cd = "Volume (cords/ac)")

results <- list()
plotdat <- list()
for (mi in seq_along(model_cfg)) {
  cfgi <- model_cfg[mi]; labi <- model_lab[mi]
  mdl <- by[by$model_config == cfgi, c("PLOT","tot_cd","tot_val")]
  names(mdl) <- c("PLOT","tot_cd_pred","tot_val_pred")
  m <- merge(mdl, obs, by = "PLOT")
  for (met in metrics) {
    predv <- m[[paste0(met, "_pred")]]
    obsv  <- m[[paste0(met, "_obs")]]
    res <- equiv_analysis(predv, obsv)
    key <- paste(cfgi, met, sep = "__")
    results[[key]] <- res
    plotdat[[key]] <- data.frame(model = labi, model_cfg = cfgi, metric = met,
                                  metric_lab = metric_lab[met],
                                  PLOT = m$PLOT, observed = obsv, predicted = predv)
    cat(sprintf("%-22s %-8s n=%2d bias=%+6.1f%%  intercept.hat=%8.2f CI[%8.2f,%8.2f] region[%8.2f,%8.2f] %s | slope.hat=%.3f CI[%.3f,%.3f] region[%.2f,%.2f] %s | smallest region: b0=%.1f%% b1=%.1f%% combined=%.1f%%\n",
        labi, met, res$n, res$bias_pct, res$intercept_hat, res$ci_b0[1], res$ci_b0[2], res$rs_b0[1], res$rs_b0[2],
        ifelse(res$pass_b0,"PASS","FAIL"), res$slope_hat, res$ci_b1[1], res$ci_b1[2], res$rs_b1[1], res$rs_b1[2],
        ifelse(res$pass_b1,"PASS","FAIL"), 100*res$smallest_b0, 100*res$smallest_b1, 100*res$smallest_combined))
  }
}

# ---- summary table ----------------------------------------------------------
summary_rows <- lapply(names(results), function(key) {
  r <- results[[key]]
  parts <- strsplit(key, "__")[[1]]
  data.frame(model_cfg = parts[1], metric = parts[2], n = r$n,
             mean_obs = r$m_obs, mean_pred = r$m_pred, bias_pct = round(r$bias_pct,1),
             intercept_hat = round(r$intercept_hat,2),
             intercept_ci_lo = round(r$ci_b0[1],2), intercept_ci_hi = round(r$ci_b0[2],2),
             intercept_region_lo = round(r$rs_b0[1],2), intercept_region_hi = round(r$rs_b0[2],2),
             pass_intercept_25pct = r$pass_b0,
             slope_hat = round(r$slope_hat,3),
             slope_ci_lo = round(r$ci_b1[1],3), slope_ci_hi = round(r$ci_b1[2],3),
             pass_slope_25pct = r$pass_b1,
             smallest_region_intercept_pct = round(100*r$smallest_b0,1),
             smallest_region_slope_pct = round(100*r$smallest_b1,1),
             smallest_region_combined_pct = round(100*r$smallest_combined,1))
})
summary_df <- do.call(rbind, summary_rows)
write.csv(summary_df, "equivalence_test_results_v25.csv", row.names = FALSE)
cat("\n=== Summary table ===\n")
print(summary_df, row.names = FALSE)

# grid detail (5%-50% by 5%) for the primary value metric, all models
grid_rows <- lapply(model_cfg, function(cfgi) {
  r <- results[[paste(cfgi, "tot_val", sep = "__")]]
  gt <- r$grid_tab; gt$model_cfg <- cfgi; gt
})
grid_df <- do.call(rbind, grid_rows)
write.csv(grid_df, "equivalence_grid_value_v25.csv", row.names = FALSE)

saveRDS(results, "equivalence_test_results_v25.rds")
saveRDS(plotdat, "equivalence_plotdat_v25.rds")

cat("\nDONE\n")

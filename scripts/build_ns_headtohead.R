# build_ns_headtohead.R -- compact BASE vs CANDIDATE v12.11 vs OSM-ACD v2.26.1 head-to-head table on
# Nova Scotia, combining the short (bench_ns_scorecard.csv) and long-interval
# (bench_ns_long_scorecard.csv) NS scorecards. Keeps the overall / managed / forest_group splits from
# both, plus the long-only interval_bucket split (<15,15-30,>30 yr) -- the dimensions the task asked
# for a compact head-to-head on. Drops pair_type and the bucket_x_managed interaction from this
# compact table (they stay in the full bench_ns_long_scorecard.csv, not removed, just not duplicated
# here). New script; does not edit bench_ns_scorecard.R / bench_ns_long_scorecard.R.
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

short <- fread("bench_ns_scorecard.csv")
long  <- fread("bench_ns_long_scorecard.csv")

keep_dims <- c("overall","managed","forest_group")
s2 <- short[split_dim %in% keep_dims, .(interval_set="short (bench_ns)", split_dim, split_val, model, n,
  interval_mean=NA_real_, TOTVOL_bias_pct, TOTVOL_rmse_pct, BA_bias_pct, BA_rmse_pct)]
l2 <- long[split_dim %in% c(keep_dims,"interval_bucket"), .(interval_set="long (bench_ns_long)", split_dim, split_val, model, n,
  interval_mean, TOTVOL_bias_pct, TOTVOL_rmse_pct, BA_bias_pct, BA_rmse_pct)]

h2h <- rbindlist(list(s2, l2))
h2h[, split_dim := factor(split_dim, levels=c("overall","managed","forest_group","interval_bucket"))]
h2h[, model := factor(model, levels=c("BASE (frozen, no levers)","CANDIDATE v12.11","OSM-ACD v2.26.1"))]
setorder(h2h, interval_set, split_dim, split_val, model)
h2h[, split_dim := as.character(split_dim)]; h2h[, model := as.character(model)]

fwrite(h2h, "ns_headtohead.csv")
cat("=== NS HEAD-TO-HEAD (BASE vs v12.11 vs OSM) ===\n")
print(h2h, nrows=100)
cat("\nWROTE ns_headtohead.csv rows=", nrow(h2h), "\nDONE\n")

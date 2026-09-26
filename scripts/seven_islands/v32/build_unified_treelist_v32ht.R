#!/usr/bin/env Rscript
# v32 height-initialization factorial unified treelist (September 23, 2026).
# Floor: v29_run/silc_cfi_unified_treelists_v29b.csv, carried unchanged (its OBSERVED height repair
# already applied). Appends the September 23 cells: AGM v8.40 noHTdub (Carroll, September 21 delivery)
# and FVS-ACD v13.1 hierarchical, v14 L1 and v14 L2 under measured (meas) and imputed (dub) starting
# heights. The meas cells reproduce the v29 FVSACD_v131_full, FVSACD_v14_L1 and FVSACD_v14_L2 rows
# byte for byte (checked on the files, all columns but the label), so they are appended under new
# labels only so that each cell of the factorial is scored through one code path.
suppressPackageStartupMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
SCHEMA <- c("model_config","PLOT","YEAR","sp","dbh_cm","ht_m","expf_tph")
u <- fread("v29_run/silc_cfi_unified_treelists_v29b.csv")[, ..SCHEMA]
cat("v29b rows", nrow(u), "\n")
W <- "v32_htdub"
add <- list(
  AGM_v840_meas        = file.path(W,"agm_v840_treelist.csv"),
  AGM_v836_native      = file.path(W,"agm_v836_native_treelist.csv"),
  FVSACD_v131_hier_meas= file.path(W,"fvsacd_v131hier_meas_treelist.csv"),
  FVSACD_v131_hier_dub = file.path(W,"fvsacd_v131hier_dub_treelist.csv"),
  FVSACD_v14_L1_meas   = file.path(W,"fvsacd_v14L1_meas_treelist.csv"),
  FVSACD_v14_L1_dub    = file.path(W,"fvsacd_v14L1_dub_treelist.csv"),
  FVSACD_v14_L2_meas   = file.path(W,"fvsacd_v14L2_meas_treelist.csv"),
  FVSACD_v14_L2_dub    = file.path(W,"fvsacd_v14L2_dub_treelist.csv"))
for (k in names(add)) {
  f <- add[[k]]
  if (!file.exists(f)) { cat("MISSING, skipped:", k, f, "\n"); next }
  d <- fread(f)[, ..SCHEMA]; d[, model_config := k]; u <- rbind(u, d); cat("added", k, nrow(d), "\n")
}
fwrite(u, file.path(W, "silc_cfi_unified_treelists_v32ht.csv"))
print(u[, .N, by=model_config][order(model_config)])
cat("DONE\n")

#!/usr/bin/env Rscript
# v33 unified treelist (26 September 2026). Floor: v32_htdub/silc_cfi_unified_treelists_v32ht.csv carried
# unchanged. Appends FVS-ACD 14.0.4 (v141off) and 14.1 (v141L) cells from the SILC_L frame runs of array
# v33 (runner_v33_htswitch.R), restricted to the 65 benchmark stands and passed through the same floor
# as ingest_fvsacd_v14.R (DBH >= 11.43 cm, live expf). Frame and full137 t1 inputs for the 65 stands are
# identical in stems, basal area and heights (probe2.R). No em dashes.
suppressPackageStartupMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
SCHEMA <- c("model_config","PLOT","YEAR","sp","dbh_cm","ht_m","expf_tph")
u <- fread("v32_htdub/silc_cfi_unified_treelists_v32ht.csv")[, ..SCHEMA]
cat("v32ht rows", nrow(u), "\n")
raw <- fread("v32_htdub/fvsacd_v131hier_meas_full137_treelist_raw.csv")
bp  <- fread("v32_htdub/silc_cfi_v32ht_byplot_primary_DATA_2026-09-23.csv")[model_config=="OBSERVED"]
bk  <- unique(raw[RECORD=="PRED_T2" & PLOT %in% bp$PLOT, STAND])
stopifnot(length(bk) == 65)
W <- "v33_v141/out"
add <- c(FVSACD_v141_meas="v141L_meas", FVSACD_v1404_meas="v141off_meas", FVSACD_v1404_dub="v141off_dub",
         FVSACD_v141_dub="v141L_dub", FVSACD_v141_ftmfix="v141L_ftmfix", FVSACD_v1404_ftmfix="v141off_ftmfix")
for (k in names(add)) {
  f <- file.path(W, add[[k]], "c001_pred_t2_tree.csv")
  if (!file.exists(f)) { cat("MISSING, skipped:", k, f, "\n"); next }
  d <- fread(f); d[, key := sub("^SILC_L__(SILC[0-9]+)__([0-9]+_[0-9]+)_C$", "\\1_\\2", STAND)]
  d <- d[key %in% bk]
  d[, PLOT := as.integer(sub("^SILC([0-9]+)_.*$", "\\1", key))]
  d[, YEAR := as.integer(sub("^SILC[0-9]+_[0-9]+_([0-9]+)$", "\\1", key))]
  n0 <- nrow(d); d <- d[is.finite(dbh) & dbh >= 4.5*2.54 & is.finite(expf) & expf > 0]
  o <- d[, .(model_config=k, PLOT, YEAR, sp, dbh_cm=dbh, ht_m=ht, expf_tph=expf)]
  cat(sprintf("added %s: stands %d, rows %d -> %d after floor\n", k, uniqueN(d$key), n0, nrow(o)))
  stopifnot(uniqueN(d$key) == 65)
  u <- rbind(u, o)
}
fwrite(u, "v33_v141/silc_cfi_unified_treelists_v33.csv")
print(u[, .N, by=model_config][order(model_config)])

#!/usr/bin/env Rscript
# ingest_fvsacd_v131_ship18_full137.R
# v25 full-coverage ingest of the FVS-ACD v13.1 "ship18" rerun (AcadianGY_13.1.r
# engine, non-hierarchical driver, 120 of 137 SILC/CFI plots, per-tree treeout).
# NEW model_config for v25 -- a THIRD v13.x candidate alongside FVSACD_v1211_full
# and FVSACD_v131_full, not a replacement of either. Pattern copied exactly from
# ingest_fvsacd_v131_full137.R / ingest_fvsacd_v1211_full137.R: PRED_T2 filter,
# >=4.5in (11.43cm) DBH / live-expf floor, same output schema (model_config,
# PLOT, YEAR, sp, dbh_cm, ht_m, expf_tph).

suppressMessages(library(data.table))

RAW_PATH  <- Sys.getenv("FVS_V131_SHIP18_FULL_RAW_PATH",
                         "v25_inputs/fvsacd_v131_ship18_full137_treelist_raw.csv")
OUT_PATH  <- "results/treelists/fvsacd_v131_ship18_treelist.csv"
MODEL_TAG <- "FVSACD_v131_ship18"

MIN_DBH_IN <- 4.5
IN_TO_CM   <- 2.54
MIN_DBH_CM <- MIN_DBH_IN * IN_TO_CM

if (!file.exists(RAW_PATH)) {
  stop(sprintf("ingest_fvsacd_v131_ship18_full137.R: RAW_PATH ('%s') does not exist.", RAW_PATH))
}

raw <- fread(RAW_PATH)

expected_raw_cols <- c("STAND", "PLOT", "YEAR", "RECORD", "TREE", "sp", "dbh_cm", "ht_m", "expf_tph")
miss <- setdiff(expected_raw_cols, names(raw))
if (length(miss) > 0) {
  stop(sprintf("RAW_PATH is missing expected column(s): %s", paste(miss, collapse = ", ")))
}

cat(sprintf("ingest_fvsacd_v131_ship18_full137: raw rows %d, record counts: %s\n",
    nrow(raw), paste(sprintf("%s=%d", names(table(raw$RECORD)), table(raw$RECORD)), collapse=", ")))

pred <- raw[RECORD == "PRED_T2"]
n_before <- nrow(pred)
pred <- pred[is.finite(dbh_cm) & dbh_cm >= MIN_DBH_CM & is.finite(expf_tph) & expf_tph > 0]
cat(sprintf("ingest_fvsacd_v131_ship18_full137: PRED_T2 rows %d -> %d after the >=%.2fin (%.2fcm) DBH / live-expf floor\n",
    n_before, nrow(pred), MIN_DBH_IN, MIN_DBH_CM))

pred[, PLOT := as.integer(PLOT)]
pred[, YEAR := as.integer(YEAR)]
pred[, model_config := MODEL_TAG]

out <- pred[, .(model_config, PLOT, YEAR, sp, dbh_cm, ht_m, expf_tph)]

dir.create(dirname(OUT_PATH), recursive = TRUE, showWarnings = FALSE)
fwrite(out, OUT_PATH)
cat(sprintf("ingest_fvsacd_v131_ship18_full137: wrote %s -- %d rows, %d plots (of 120 succeeded / 137 input), species: %s\n",
    OUT_PATH, nrow(out), uniqueN(out$PLOT), paste(sort(unique(out$sp)), collapse = ",")))

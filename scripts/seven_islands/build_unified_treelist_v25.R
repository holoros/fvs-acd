#!/usr/bin/env Rscript
# build_unified_treelist_v25.R
# v25 full-coverage rerun. Assembles results/silc_cfi_unified_treelists_v25.csv
# from the v24 floor (results/silc_cfi_unified_treelists_v24.csv), retiring
# "FVSACD_v1211_silc73" (the old 73/154-plot partial-coverage FVS-ACD v12.11
# rerun -- REPLACED, not carried forward, per Aaron's explicit v25 task scope:
# the new full137 per-tree files are meant to replace the SILC73 result as
# the current-best FVS-ACD v12.11 number, not sit alongside it), and adding
# THREE new full-coverage ingests, all additions, none a replacement of another:
#   - FVSACD_v1211_full   (ingest_fvsacd_v1211_full137.R, replaces SILC73)
#   - FVSACD_v131_full    (ingest_fvsacd_v131_full137.R, hierarchical-posterior
#                           candidate, addition only)
#   - FVSACD_v131_ship18  (ingest_fvsacd_v131_ship18_full137.R, added same day
#                           -- AcadianGY_13.1.r engine, non-hierarchical driver,
#                           repo's own stated "current leading configuration"
#                           per README, addition only, does not replace
#                           FVSACD_v131_full or FVSACD_v1211_full)
#
# FVS_ACD_default, FVS_NE_default, AGM_v835, OSM_ACD, and OBSERVED all carry
# forward from v24 UNCHANGED -- no touch, per the house no-silent-removal rule.

suppressMessages(library(data.table))

PRIOR_UNI_PATH  <- "results/silc_cfi_unified_treelists_v24.csv"
FVS1211_TL_PATH <- "results/treelists/fvsacd_v1211_full_treelist.csv"
FVS131_TL_PATH  <- "results/treelists/fvsacd_v131_full_treelist.csv"
FVS131S18_TL_PATH <- "results/treelists/fvsacd_v131_ship18_treelist.csv"
OUT_PATH       <- "results/silc_cfi_unified_treelists_v25.csv"

RETIRED_CONFIG <- "FVSACD_v1211_silc73"   # replaced by FVSACD_v1211_full this round

missing_inputs <- c()
if (!file.exists(PRIOR_UNI_PATH))    missing_inputs <- c(missing_inputs, PRIOR_UNI_PATH)
if (!file.exists(FVS1211_TL_PATH))   missing_inputs <- c(missing_inputs, FVS1211_TL_PATH)
if (!file.exists(FVS131_TL_PATH))    missing_inputs <- c(missing_inputs, FVS131_TL_PATH)
if (!file.exists(FVS131S18_TL_PATH)) missing_inputs <- c(missing_inputs, FVS131S18_TL_PATH)
if (length(missing_inputs) > 0) {
  stop(sprintf("build_unified_treelist_v25.R: not ready to run. Missing: %s",
      paste(missing_inputs, collapse = ", ")))
}

prior <- fread(PRIOR_UNI_PATH)
retired <- RETIRED_CONFIG
carried <- prior[!(model_config %in% retired)]
dropped <- prior[model_config %in% retired]

carried_configs <- sort(unique(carried$model_config))
dropped_configs <- sort(unique(dropped$model_config))
cat("Carried forward unchanged from v24:", paste(carried_configs, collapse = ", "), "\n")
cat("Retired (replaced by v25 full-coverage ingest):", paste(dropped_configs, collapse = ", "), "\n")

fvs1211  <- fread(FVS1211_TL_PATH)
fvs131   <- fread(FVS131_TL_PATH)
fvs131s18 <- fread(FVS131S18_TL_PATH)

expected_cols <- c("model_config", "PLOT", "YEAR", "sp", "dbh_cm", "ht_m", "expf_tph")
for (nm in c("carried", "fvs1211", "fvs131", "fvs131s18")) {
  d <- get(nm)
  miss <- setdiff(expected_cols, names(d))
  if (length(miss) > 0) {
    stop(sprintf("%s is missing expected unified-schema column(s): %s", nm, paste(miss, collapse = ", ")))
  }
}

uni <- rbindlist(list(carried[, ..expected_cols], fvs1211[, ..expected_cols],
                       fvs131[, ..expected_cols], fvs131s18[, ..expected_cols]), use.names = TRUE)

dir.create(dirname(OUT_PATH), recursive = TRUE, showWarnings = FALSE)
fwrite(uni, OUT_PATH)

cat(sprintf("\nWrote %s -- %d rows across %d model_config values, %d distinct plots.\n",
    OUT_PATH, nrow(uni), uniqueN(uni$model_config), uniqueN(uni$PLOT)))
cat("Rows per model_config:\n")
print(uni[, .N, by = model_config][order(model_config)])

cat("\n=== v25 content-inventory diff vs v24 unified treelist ===\n")
cat("Added:    ", paste(setdiff(sort(unique(uni$model_config)), sort(unique(prior$model_config))), collapse = ", "), "\n")
cat("Removed:  ", paste(setdiff(sort(unique(prior$model_config)), sort(unique(uni$model_config))), collapse = ", "), "\n")
cat("Unchanged:", paste(intersect(sort(unique(prior$model_config)), sort(unique(uni$model_config))), collapse = ", "), "\n")

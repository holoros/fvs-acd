#!/usr/bin/env Rscript
# v25_stress_coverage_check.R
# v25 copy of the (unnamed-script-origin) per-model_config data-QC coverage
# check whose output is v24_stress_coverage_check.csv -- the source script
# that produced that file could not be located in this repo (grep for its
# distinctive columns turned up only the log and csv, not an .R file), so
# this is a faithful reconstruction of its schema and logic from the v24
# output, retargeted to the v25 unified treelist and its model_config list.
# For each model_config: row count, distinct-plot count, DBH/HT extrema (in
# inches / feet, matching the v24 file's units), and QC flags for negative
# DBH, negative HT, negative EXPF, and "tall thin" trees (DBH<6in with
# HT>80ft, an unrealistic combination -- same threshold choice as produces
# n_tall_thin=0 on the clean v24 data, kept identical here).

suppressMessages(library(data.table))

UNI_PATH <- "results/silc_cfi_unified_treelists_v25.csv"
OUT_PATH <- "v25_stress_coverage_check.csv"
IN_TO_CM <- 2.54
FT_TO_M  <- 0.3048

if (!file.exists(UNI_PATH)) stop(sprintf("v25_stress_coverage_check.R: UNI_PATH ('%s') does not exist.", UNI_PATH))

uni <- fread(UNI_PATH)
uni[, dbh_in := as.numeric(dbh_cm) / IN_TO_CM]
uni[, ht_ft  := as.numeric(ht_m)   / FT_TO_M]
uni[, expf_tph := as.numeric(expf_tph)]

cov <- uni[, .(
  n_rows      = .N,
  n_plots     = uniqueN(PLOT),
  dbh_in_min  = round(min(dbh_in, na.rm = TRUE), 2),
  dbh_in_max  = round(max(dbh_in, na.rm = TRUE), 2),
  ht_ft_min   = round(min(ht_ft, na.rm = TRUE), 1),
  ht_ft_max   = round(max(ht_ft, na.rm = TRUE), 1),
  n_neg_dbh   = sum(dbh_in < 0, na.rm = TRUE),
  n_neg_ht    = sum(ht_ft < 0, na.rm = TRUE),
  n_neg_expf  = sum(expf_tph < 0, na.rm = TRUE),
  n_tall_thin = sum(dbh_in < 6 & ht_ft > 80, na.rm = TRUE)
), by = model_config]

setorder(cov, model_config)
fwrite(cov, OUT_PATH)
cat(sprintf("v25_stress_coverage_check: wrote %s -- %d model_config rows\n", OUT_PATH, nrow(cov)))
print(cov)

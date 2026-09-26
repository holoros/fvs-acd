#!/usr/bin/env Rscript
# ingest_agm_v836_bystrata.R
# Ingest Bruce Carroll's AGM v8.36 SILCcfi byStrata run and transform it into
# the same unified-treelist schema used by ingest_agm_v835_byplot.R
# (model_config, PLOT, YEAR, sp, dbh_cm, ht_m, expf_tph), so it can be merged
# into the SILC four-model benchmark alongside AGM_v835, OSM-ACD, FVS-NE, and
# the FVS-ACD family.
#
# CONTEXT: unlike v8.35 (a single CFI_GrownDB_byPlot table, Imperial units,
# PLOTID field), v8.36's delivery (AcadianGrowthModel_v8.36_SILCcfi_byStrata.mdb)
# has NO table named CFI_GrownDB_byPlot or CFI_GrownDB_byStrata. The tree-level
# grown output lives in FR_Trees_Final (790,445 rows x 64 cols across the
# operator's full Acadian project, not just the 147 SILC CFI plots). Its
# PLOT_ID field is a placeholder constant (999999 on every sampled row, same
# pattern as the known TreeId=9999 placeholder) so it CANNOT be used to
# recover plot identity. Plot identity survives instead via STAND_ID, which
# still follows the same PLOT*10000+baseyear convention used throughout this
# benchmark (e.g. STAND_ID 11001986 -> PLOT 1100, base year 1986), verified
# against all 73 long-horizon pairs. FR_Trees_Final is also already METRIC
# (DIAMETER in cm, HT in m, EXPF in stems/ha -- confirmed by row-level
# arithmetic: EXPF 12.355258 = 5 trees/ac x 2.4710538147 ACRES_PER_HA, and
# DIAMETER 15.24 cm = origDBH 6.0 in x 2.54), unlike v8.35's Imperial delivery.
# No unit conversion is applied here as a result -- this is a real, confirmed
# difference from v8.35's ingestion, not an oversight.
#
# This script consumes agm_v840_frtrees_filtered.csv, the output of
# export_fr_trees_final.py, which has ALREADY restricted FR_Trees_Final to
# rows whose STAND_ID exactly matches one of the 73 pairs' PLOT*10000+YEAR_PREV
# (i.e. the multi-cohort dedup that ingest_agm_v835_byplot.R had to do in R
# via the `expected_standid` filter is already done in the Python export step
# for v8.36, because STAND_ID is the only plot key available and matching on
# it necessarily also fixes the cohort).

suppressMessages(library(data.table))

FILTERED_PATH <- "agm_v840_frtrees_filtered.csv"
PAIRS_PATH    <- "silc_cfi_longhorizon_pairs_v16.csv"
OUT_PATH      <- "agm_v840_treelist.csv"
MIN_DBH_CM    <- 4.5 * 2.54   # same 4.5 in benchmark floor as every other model, applied in cm since v8.36 delivers metric

CANON_SP <- c("BF","RS","BS","WS","NS","WP","RP","RN","EH","WC","JP","TA","OS",
              "SM","RM","YB","WA","BA","GA","AS","RO","AB","PB","GB","SB","QA",
              "BT","BP","OH","ST","BC","AE","BL","BW","NC","HH","PR")
map_species <- function(sp_raw) {
  sp <- trimws(toupper(as.character(sp_raw)))
  unknown <- sort(unique(sp[!is.na(sp) & !(sp %in% CANON_SP)]))
  if (length(unknown) > 0) {
    warning(sprintf(
      "ingest_agm_v840_bystrata: %d species code(s) not in the canonical vocabulary, mapped to OH: %s.",
      length(unknown), paste(unknown, collapse = ", ")))
  }
  ifelse(sp %in% CANON_SP, sp, "OH")
}

agm <- fread(FILTERED_PATH)
cat(sprintf("Loaded %s: %d rows, %d distinct PLOT, %d distinct STAND_ID\n",
    FILTERED_PATH, nrow(agm), uniqueN(agm$PLOT), uniqueN(agm$STAND_ID)))

# ---- HISTORY audit on the matched subset ------------------------------------
# CORRECTION (found by inspecting the full-table HISTORY distribution during
# this ingestion): in FR_Trees_Final, HISTORY is NOT the small standing-dead
# status code (6) documented for Ryan's TreeInit input table in MEMORY.md
# (2026-08-18 session). Here it is almost entirely CALENDAR YEARS (1986,
# 1991, ..., 2100) plus a single sentinel value 1 (177,317 of 790,445 rows),
# i.e. a base/initialization-year marker, not a live/dead flag. That v8.35
# convention does not transfer to this table and is not applied here. No
# HISTORY-based dead-tree filter is applied below; EXPF > 0 is the only live
# filter, same role TPA > 0 played for v8.35. Whether v8.36 achieves Bruce's
# promised dead-tree strip therefore cannot be confirmed from HISTORY in this
# table -- flag for Aaron/Bruce, not silently assumed either way.
cat("HISTORY value counts in the matched (benchmark) subset (calendar-year/init-marker field, NOT a status code here):\n")
print(agm[, .N, by = HISTORY][order(HISTORY)])

# ---- nearest-year match (same logic as ingest_agm_v835_byplot.R) -----------
ps <- fread(PAIRS_PATH)
setnames(ps, toupper(names(ps)))
ps_small <- unique(ps[, .(PLOT, YEAR_PREV, YEAR_CURR)])
agm <- merge(agm, ps_small, by = "PLOT", all.x = FALSE, all.y = FALSE)

setorder(agm, PLOT, Year)
plot_years <- unique(agm[, .(PLOT, Year, YEAR_CURR)])
plot_years[, gap := abs(Year - YEAR_CURR)]
best_year <- plot_years[, .SD[which.min(gap)], by = PLOT][, .(PLOT, best_year = Year, year_gap = gap)]
agm <- merge(agm, best_year, by = "PLOT")
agm <- agm[Year == best_year]
gaps <- unique(agm[, .(PLOT, year_gap)])
if (any(gaps$year_gap > 0)) {
  message(sprintf(
    "%d of %d plot(s) matched at the nearest available model year (median gap %.1f yr, max %d yr).",
    sum(gaps$year_gap > 0), nrow(gaps), median(gaps$year_gap[gaps$year_gap > 0]), max(gaps$year_gap)))
}

# ---- live filter + size floor -----------------------------------------------
# EXPF is the surviving expansion factor per hectare (already metric); mirrors
# the TPA > 0 live filter used for v8.35. No HISTORY-based filter (see note
# above -- that field is not a status code in this table).
n_before_live <- nrow(agm)
agm <- agm[EXPF > 0 & !is.na(DIAMETER) & DIAMETER >= MIN_DBH_CM]
cat(sprintf("Live + size-floor filter: %d -> %d rows\n", n_before_live, nrow(agm)))

# ---- schema mapping (already metric, no unit conversion) -------------------
agm[, `:=`(
  model_config = "AGM_v840_meas",
  YEAR         = as.integer(YEAR_CURR),
  sp           = map_species(SPECIES),
  dbh_cm       = as.numeric(DIAMETER),
  ht_m         = as.numeric(HT),
  expf_tph     = as.numeric(EXPF)
)]

out <- agm[, .(model_config, PLOT, YEAR, sp, dbh_cm, ht_m, expf_tph)]
fwrite(out, OUT_PATH)
cat(sprintf("ingest_agm_v840_bystrata: wrote %s -- %d rows, %d plots, species: %s\n",
    OUT_PATH, nrow(out), uniqueN(out$PLOT), paste(sort(unique(out$sp)), collapse = ",")))

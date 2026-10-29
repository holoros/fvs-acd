#!/usr/bin/env Rscript
# build_agm_v835_bakuzis_traj.R
# Build a long-format Bakuzis trajectory table (group,site,age,HT,TPH,BAPH,QMD,VOL)
# directly from AGM v8.35's CFI_GrownDB_byPlot per-tree output, for the
# bakuzis-assessment skill (bakuzis_check.R / bakuzis_matrix.R).
#
# CFI_GrownDB_byPlot bundles MULTIPLE independent growth trajectories per
# PLOTID, one per historical CFI measurement cycle the model was grown FROM
# (StandID = PLOT*10000 + base_year, confirmed against ingest_agm_v835_byplot.R's
# documented cohort-mixing bug fix). For a clean single long-horizon curve per
# plot (no cohort mixing), this script keeps ONLY the trajectory with the
# EARLIEST base_year per plot -- this maximizes the projected run length
# (longest real-measurement anchor + longest forward projection to 2125),
# which is exactly what the self-thinning (Reineke) and Eichhorn tests need.
#
# Site classification: ClimateSiteIndexMeters from Ryan Smith's extracted
# CFI_StandInit_All.csv, joined on STAND_ID == the chosen canonical StandID.
# Binned into 3 site classes (tertiles across the 147-plot universe).
#
# "age" = Year - base_year (years since this trajectory's start), since no
# true breast-height stand age field exists in this delivery -- documented
# assumption, not a silent substitution.
#
# VOL = BAPH * HT * 0.40 (skill default form factor), NOT the AGM per-tree
# TCuFt/MCuFt fields, which are populated only for merchantable-size trees in
# this delivery and would not represent whole-stand volume. Keeps this
# consistent with every prior Bakuzis run in this repo (acadgy_bakuzis_*).

suppressMessages(library(data.table))

IN  <- "~/silc_cfi/v24_inputs/CFI_GrownDB_byPlot.csv"
SI  <- "~/silc_cfi/v24_inputs/ryan_accdb/CFI_StandInit_All.csv"
OUT <- "~/silc_cfi/bakuzis_v835/agm_v835_bakuzis_trajectories.csv"
FF  <- 0.40
ACRES_PER_HA <- 2.4710538147
IN_TO_CM <- 2.54
FT_TO_M  <- 0.3048

cat("Reading CFI_GrownDB_byPlot ...\n")
d <- fread(IN, select = c("PLOTID","Year","StandID","DBH","Ht","TPA"))
d <- d[TPA > 0 & is.finite(DBH) & DBH > 0 & is.finite(Ht) & Ht > 0]
d[, base_year := StandID %% 10000L]

cat("Selecting the earliest-base-year (single, non-cohort-mixed) trajectory per plot ...\n")
canon <- d[, .(base_year = min(base_year)), by = PLOTID]
d <- merge(d, canon, by = c("PLOTID","base_year"))
canon_standid <- unique(d[, .(PLOTID, base_year, StandID)])
cat(sprintf("  %d plots, base years range %d-%d\n", uniqueN(d$PLOTID), min(d$base_year), max(d$base_year)))

cat("Aggregating to stand level per PLOTID x Year ...\n")
topht <- function(ht_m, dbh_cm, tph) {
  o <- order(dbh_cm, decreasing = TRUE)
  ht_m <- ht_m[o]; tph <- tph[o]
  cs <- cumsum(tph)
  k <- which(cs >= 100)[1]
  if (is.na(k)) k <- length(tph)
  weighted.mean(ht_m[1:k], tph[1:k], na.rm = TRUE)
}

d[, `:=`(dbh_cm = DBH * IN_TO_CM, ht_m = Ht * FT_TO_M, tph_i = TPA * ACRES_PER_HA)]

stand <- d[, {
  BAPH <- sum(pi * (dbh_cm/200)^2 * tph_i)
  TPH  <- sum(tph_i)
  QMD  <- sqrt((BAPH/TPH) / (pi/40000))
  HT   <- topht(ht_m, dbh_cm, tph_i)
  .(BAPH = BAPH, TPH = TPH, QMD = QMD, HT = HT)
}, by = .(PLOTID, base_year, Year)]
stand[, VOL := BAPH * HT * FF]
stand[, age := Year - base_year]

cat(sprintf("  %d plot x year rows, age range %d-%d\n", nrow(stand), min(stand$age), max(stand$age)))

cat("Joining site index (ClimateSiteIndexMeters) from CFI_StandInit_All ...\n")
si <- fread(SI, select = c("STAND_ID","ClimateSiteIndexMeters","SDImaxMetric"))
si <- unique(si[!is.na(ClimateSiteIndexMeters) | !is.na(SDImaxMetric)])
setnames(si, "STAND_ID", "StandID")
canon_standid <- merge(canon_standid, si, by = "StandID", all.x = TRUE)

# ClimateSiteIndexMeters is CONSTANT at 16.0 m across all 590 CFI stand-years
# in this delivery (checked directly: `awk -F, '{print $9}' CFI_StandInit_All.csv
# | sort -u` returns a single value) -- not usable as a productivity gradient,
# despite being the field the task brief named first. This is itself a finding
# (a placeholder/unfitted default rather than a real per-plot climate site
# index), not a script bug -- verified before switching. SDImaxMetric DOES vary
# genuinely (489.5-1656.5) and is used instead as the site/productivity class
# variable, per the task brief's explicit fallback ("SDI or site index").
# Caveat carried into the memo: SDImax is a species-composition-driven maximum
# density ceiling, not a classic height-based site index -- a real but weaker
# productivity proxy than a true site index would be.
n_missing <- sum(is.na(canon_standid$SDImaxMetric))
cat(sprintf("  %d/%d plots matched SDImaxMetric; %d unmatched (dropped)\n",
            sum(!is.na(canon_standid$SDImaxMetric)), nrow(canon_standid), n_missing))
canon_standid <- canon_standid[!is.na(SDImaxMetric)]

q <- quantile(canon_standid$SDImaxMetric, probs = c(1/3, 2/3), na.rm = TRUE)
canon_standid[, site := fifelse(SDImaxMetric <= q[1], "1_low",
                          fifelse(SDImaxMetric <= q[2], "2_mid", "3_high"))]
cat("Site class breakpoints (SDImaxMetric):\n"); print(q)
cat("Plots per site class:\n"); print(table(canon_standid$site))

stand <- merge(stand, canon_standid[, .(PLOTID, site, ClimateSiteIndexMeters, SDImaxMetric)],
               by = "PLOTID")

cat("Collapsing to one site-class-mean line per age (workhorse form for the matrix) ...\n")
byplot_out <- stand[, .(group = "AGM_v835", origin = paste0("plot", PLOTID), site, age,
                         HT = round(HT,3), TPH = round(TPH,1), BAPH = round(BAPH,3),
                         QMD = round(QMD,3), VOL = round(VOL,3))]
fwrite(byplot_out, sub("\\.csv$", "_byplot.csv", OUT))

site_mean <- stand[, .(HT = mean(HT), TPH = mean(TPH), BAPH = mean(BAPH), QMD = mean(QMD),
                        VOL = mean(VOL), n_plots = uniqueN(PLOTID)),
                    by = .(site, age)]
site_mean[, `:=`(group = "AGM_v835", origin = "all")]
setcolorder(site_mean, c("group","origin","site","age","HT","TPH","BAPH","QMD","VOL","n_plots"))
setorder(site_mean, site, age)
fwrite(site_mean[, .(group, origin, site, age, HT = round(HT,3), TPH = round(TPH,1),
                      BAPH = round(BAPH,3), QMD = round(QMD,3), VOL = round(VOL,3))], OUT)

cat(sprintf("wrote %s (%d rows, site classes: %s)\n", OUT, nrow(site_mean),
            paste(sort(unique(site_mean$site)), collapse=",")))
cat(sprintf("also wrote per-plot detail: %s (%d rows)\n", sub("\\.csv$","_byplot.csv",OUT), nrow(byplot_out)))
cat("DONE_TRAJ\n")

#!/usr/bin/env Rscript
# brms SDImax per Seven Islands plot for the x142sb arm, by the acd142 track G method as applied in sdib_assign.R (PREREG_GY2
# amendment 5): median brms SDImax of FIA plots in the CEC L3 ecoregion x forest type group, finest level with >= 30 FIA plots
# (L3 x type, L2 x type, type, all); type group from the starting tree list; value = track G round trip through FVS imperial units.
# Plot coordinates are read on the server only. Prints counts and summaries, no identifiers.
# usage (after source ~/opt/geos/activate.sh, no --vanilla): Rscript 02_sdib_silc.R RESTRICTED_DIR
source(path.expand("~/perseus_me/tracks/acd142/tools/sdimax/sdimax_fns.R"))
Sys.umask("077")
base <- normalizePath(commandArgs(TRUE)[1])
SHP <- path.expand("~/perseus_me/me_state/acd142/esi_r/work/gis/NA_Eco_L3_WGS84.shp")
LKF <- path.expand("~/perseus_me/me_state/acd142/sdimax/sdimax_lookup_brms_l3_l2_type.csv")
lk <- fread(LKF, colClasses = list(character = c("l3", "l2")))
rt <- function(v) round(round(v / 2.471054, 1) * 2.471054, 1)
eco <- st_read(SHP, quiet = TRUE)
P <- fread(file.path(base, "plots.csv"), colClasses = list(character = c("Stand", "Matrix", "Unit")))
T <- fread(file.path(base, "trees.csv")); T <- T[is.finite(DIAMETER) & DIAMETER * 2.54 >= 1]
fia <- c(BF = 12, SM = 318, RS = 97, YB = 371, RM = 316, WC = 241, CE = 241, AB = 531, WB = 375, PB = 375, ST = 315, WS = 94, QA = 746,
         BS = 95, WP = 129, AS = 540, PC = 761, PR = 761, OH = 998, GA = 544, TA = 71, WA = 541, BA = 543, PO = 740, NC = 299, HE = 261,
         RP = 125, BP = 741, BT = 743)
T[, SPCD := fia[toupper(trimws(SPECIES))]]; stopifnot(!anyNA(T$SPCD))
T[, tpa := TREE_COUNT * ifelse(DIAMETER >= 4.6, 20 / (pi * (DIAMETER / 24)^2), 500)]
g <- T[, .(grp = forest_type_group(SPCD, DIAMETER^2 * tpa)), by = PLOT_ID]
d <- merge(P[, .(PLOT_ID, Matrix, LONGITUDE, LATITUDE, SDImaxMetric)], g, by = "PLOT_ID")
d[, c("l3", "l2") := ecoregion_of(LONGITUDE, LATITUDE, eco)]
e <- sdimax_estimate(d$grp, d$l3, d$l2, lk, 30L)
d[, `:=`(sdimax = rt(e$sdimax), level = e$level, sid = paste0("P", PLOT_ID))]
stopifnot(!anyNA(d$sdimax), !anyDuplicated(d$sid))
fwrite(d[, .(sid, sdimax, level, grp, l3)], file.path(base, "silc_sdib.csv")); Sys.chmod(file.path(base, "silc_sdib.csv"), "0600")
cat("plots", nrow(d), "\nlevels:\n"); print(table(d$level)); cat("L3:\n"); print(table(d$l3, useNA = "ifany")); cat("type group:\n"); print(table(d$grp))
cat("brms SDImax (metric): "); print(round(quantile(d$sdimax, c(0, .25, .5, .75, 1)), 1))
cat("Seven Islands stand SDImaxMetric: "); print(round(quantile(d$SDImaxMetric, c(0, .25, .5, .75, 1)), 1))
cat("ratio brms / Seven Islands: "); print(round(quantile(d$sdimax / d$SDImaxMetric, c(0, .25, .5, .75, 1)), 3))
cat("Spearman rho:", round(cor(d$sdimax, d$SDImaxMetric, method = "spearman"), 3), "\ndone\n")

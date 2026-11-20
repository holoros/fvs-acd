#!/usr/bin/env Rscript
# Seven Islands Bakuzis design, 19 November 2026. Starting stands: per Matrix stratum, the (up to) two stands nearest the stratum
# median of stand basal area and stand density (percent-rank distance), preferring stands with 3 or more plots. All plots of a
# stand are pooled into one tree list (per-acre expansion divided by the stand's plot count, unstocked plots included).
# Each stand is projected from the same start at three fixed climate site index levels (12, 15, 18 m). Same tree filter and
# species rules as 01_build_bridge_inputs.R. Writes RESTRICTED/bakz/{keys/*.key, stands.csv, trees.csv, sdib.csv, eco.csv}.
# usage: Rscript 10_bakz_inputs.R RESTRICTED_DIR ARMDIR
.libPaths(c("~/Rlib", .libPaths()))
suppressPackageStartupMessages({ library(data.table); library(dplyr) })
a <- commandArgs(TRUE); base <- normalizePath(a[1]); armdir <- a[2]
invisible(capture.output(suppressMessages(source(file.path(armdir, "AcadianGY.R")))))
sp_valid <- unique(as.character(sp.attr$species))
mapsp <- function(s) { s <- toupper(trimws(as.character(s))); s[s == "CE"] <- "WC"; s[s == "WB"] <- "PB"
  s[s == "PC" & !("PC" %in% sp_valid)] <- "PR"; ifelse(s %in% sp_valid, s, ifelse(s %in% c("HE", "NC"), "OS", "OH")) }
SITES <- c(12, 15, 18)
P <- fread(file.path(base, "plots.csv"), colClasses = list(character = c("Stand", "Matrix", "Unit")))
T <- fread(file.path(base, "trees.csv")); T <- T[is.finite(DIAMETER) & DIAMETER * 2.54 >= 1]
T[, `:=`(sp = mapsp(SPECIES), tpa_plot = TREE_COUNT * ifelse(DIAMETER >= 4.6, 20 / (pi * (DIAMETER / 24)^2), 500))]
np <- P[, .(n_plots = .N, elev_m = ElevationMeters[1], csi_obs = ClimateSiteIndexMeters[1], matrix = Matrix[1], inv_year = INV_YEAR[1]), by = Stand]
T[, intersect(c("Stand", "Matrix", "Unit", "STAND_ID", "STAND_CN"), names(T)) := NULL]
T <- merge(T, P[, .(PLOT_ID, Stand)], by = "PLOT_ID")
T <- merge(T, np[, .(Stand, n_plots)], by = "Stand"); T[, tpa := tpa_plot / n_plots]
st <- T[, .(ba = sum(tpa * 0.005454154 * DIAMETER^2), tpa = sum(tpa), n_rec = .N), by = Stand]
st <- merge(np, st, by = "Stand")
# percent-rank distance to the stratum median, computed within the stratum on all stands, then restricted to candidates
st[, `:=`(rba = frank(ba) / .N, rtp = frank(tpa) / .N), by = matrix]; st[, dist := abs(rba - 0.5) + abs(rtp - 0.5)]
st[, cand := if (any(n_plots >= 3)) n_plots >= 3 else rep(TRUE, .N), by = matrix]
sel <- st[cand == TRUE][order(matrix, dist, Stand)][, head(.SD, 2), by = matrix]
sel[, label := paste0(matrix, " ", letters[seq_len(.N)]), by = matrix]
sel[, k := sprintf("B%02d", seq_len(.N))]
fprob <- function(v) { dg <- pmax(0, 5 - nchar(as.character(floor(v)))); mapply(function(x, d) formatC(x, width = 6, digits = d, format = "f"), v, dg) }
key <- function(sid, s, tt, csi) {
  rec <- sprintf("%4d%3d%s1%-3s%4.1f   %s", 1L, seq_len(nrow(tt)), fprob(tt$tpa), tt$sp, tt$DIAMETER,
                 ifelse(is.finite(tt$HT) & tt$HT > 0, sprintf("%3.0f", tt$HT), "   "))
  stopifnot(all(nchar(rec) == 27), nrow(tt) <= 999)
  c("STDIDENT", sid, "", "DESIGN          -1.0       1.0     999.0       1.0       0.0",
    sprintf("STDINFO   %9s%10s%10d%10.1f%10.1f%10.1f", "922", "", 60L, 0, 5, s$elev_m / 0.3048 / 100),
    sprintf("SITECODE  %10s%10.1f%10.1f", "BF", csi / 0.3048, 1), sprintf("INVYEAR   %10.1f", s$inv_year),
    sprintf("NUMCYCLE  %10.1f", 20), sprintf("TIMEINT            0%10d", 5),
    "ECHOSUM", "CALBSTAT", "NOTRIPLE", "TREELIST           0", "DATABASE", "DSNOUT", "fvsout.db", "SUMMARY            2", "TREELIDB           2", "END",
    "COMPUTE            0", sprintf("CSI = %.3f", csi), "END", sprintf("TREEDATA  %10d", 15L), rec, "-999", "", "PROCESS", "STOP")
}
O <- file.path(base, "bakz"); dir.create(file.path(O, "keys"), recursive = TRUE, showWarnings = FALSE)
SB <- fread(file.path(base, "silc_sdib.csv")); SB[, PLOT_ID := as.integer(sub("^P", "", sid))]
SB <- merge(SB, P[, .(PLOT_ID, Stand)], by = "PLOT_ID")[, .(sdimax = median(sdimax)), by = Stand]
rows <- list(); trows <- list()
for (i in seq_len(nrow(sel))) {
  s <- sel[i]; tt <- T[Stand == s$Stand][order(PLOT_ID, -DIAMETER)]
  trows[[i]] <- tt[, .(k = s$k, PLOT_ID, TREE_ID, SPECIES, sp, DIAMETER, HT, tpa)]
  for (csi in SITES) {
    sid <- sprintf("%ss%d", s$k, csi)
    writeLines(key(sid, s, tt, csi), file.path(O, "keys", paste0(sid, ".key")))
    rows[[length(rows) + 1]] <- data.table(sid = sid, k = s$k, label = s$label, Stand = s$Stand, matrix = s$matrix, site = csi,
      n_plots = s$n_plots, n_rec = nrow(tt), ba = s$ba, tpa = s$tpa, elev_m = s$elev_m, csi_obs = s$csi_obs, inv_year = s$inv_year,
      sdimax = SB[Stand == s$Stand, sdimax])
  }
}
S <- rbindlist(rows); fwrite(S, file.path(O, "stands.csv")); fwrite(rbindlist(trows), file.path(O, "trees.csv"))
fwrite(S[, .(sid, sdimax)], file.path(O, "sdib.csv")); fwrite(S[, .(sid, l3 = "5.3.1")], file.path(O, "eco.csv"))
for (f in list.files(O, full.names = TRUE, recursive = TRUE)) Sys.chmod(f, "0600")
cat("stands", nrow(sel), "runs", nrow(S), "strata", uniqueN(sel$matrix), "\n")
print(sel[, .(label, n_plots, n_rec, ba = round(ba, 1), tpa = round(tpa), csi_obs, all_stands_in_stratum = st[matrix == .BY$matrix, .N]), by = matrix][, -1])
cat("stratum medians vs selected (BA, TPA):\n")
print(merge(st[, .(med_ba = round(median(ba), 1), med_tpa = round(median(tpa))), by = matrix], sel[, .(sel_ba = round(mean(ba), 1), sel_tpa = round(mean(tpa))), by = matrix], by = "matrix"))

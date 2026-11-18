#!/usr/bin/env Rscript
# Seven Islands gap-fill, 17 November 2026: FVS keyfiles for the production FVS-ACD bridge (rFVS + customRun_fvsRunAcadian.R).
# One plot = one stand. Same tree filter, expansion and species rule as PR 30's research harness (run_acd_versions_100yr.R):
# DBH >= 1 cm; 20 BAF at DBH >= 4.6 in, else 1/500 ac; CE -> WC, WB -> PB; codes outside AcadianGY sp.attr -> OH (HE, NC -> OS).
# Keyfile layout follows the registered bridge keyfiles (DESIGN -1 1 999, per-acre expansion in PROB, CSI through COMPUTE).
# usage: Rscript 01_build_bridge_inputs.R RESTRICTED_DIR ARMDIR ; writes RESTRICTED_DIR/keys/{c5,c100}/P<plot>.key, key_start.csv
.libPaths(c("~/Rlib", .libPaths()))
suppressPackageStartupMessages({ library(data.table); library(dplyr) })
a <- commandArgs(TRUE); base <- normalizePath(a[1]); armdir <- a[2]
invisible(capture.output(suppressMessages(source(file.path(armdir, "AcadianGY.R")))))
sp_valid <- unique(as.character(sp.attr$species))
mapsp <- function(s) { s <- toupper(trimws(as.character(s))); s[s == "CE"] <- "WC"; s[s == "WB"] <- "PB"; s[s == "PC" & !("PC" %in% sp_valid)] <- "PR"
  ifelse(s %in% sp_valid, s, ifelse(s %in% c("HE", "NC"), "OS", "OH")) }
P <- fread(file.path(base, "plots.csv"), colClasses = list(character = c("Stand", "Matrix", "Unit")))
T <- fread(file.path(base, "trees.csv"))
T <- T[is.finite(DIAMETER) & DIAMETER * 2.54 >= 1]
T[, sp := mapsp(SPECIES)]
T[, tpa := TREE_COUNT * ifelse(DIAMETER >= 4.6, 20 / (pi * (DIAMETER / 24)^2), 500)]
stopifnot(all(nchar(T$sp) <= 3), all(T$DIAMETER < 99.95))
fprob <- function(v) { dg <- pmax(0, 5 - nchar(as.character(floor(v)))); mapply(function(x, d) formatC(x, width = 6, digits = d, format = "f"), v, dg) }
key <- function(p, tt, ncyc, clen) {
  rec <- sprintf("%4d%3d%s1%-3s%4.1f   %s", 1L, seq_len(nrow(tt)), fprob(tt$tpa), tt$sp, tt$DIAMETER,
                 ifelse(is.finite(tt$HT) & tt$HT > 0, sprintf("%3.0f", tt$HT), "   "))
  stopifnot(all(nchar(rec) == 27))
  c("STDIDENT", sprintf("P%d", p$PLOT_ID), "",
    "DESIGN          -1.0       1.0     999.0       1.0       0.0",
    sprintf("STDINFO   %9s%10s%10d%10.1f%10.1f%10.1f", "922", "", 60L, 0, 5, p$ElevationMeters / 0.3048 / 100),
    sprintf("SITECODE  %10s%10.1f%10.1f", "BF", p$ClimateSiteIndexMeters / 0.3048, 1),
    sprintf("INVYEAR   %10.1f", p$INV_YEAR),
    sprintf("NUMCYCLE  %10.1f", ncyc), sprintf("TIMEINT            0%10d", clen),
    "ECHOSUM", "CALBSTAT", "NOTRIPLE", "TREELIST           0", "DATABASE", "DSNOUT", "fvsout.db", "SUMMARY            2", "TREELIDB           2", "END",
    "COMPUTE            0", sprintf("CSI = %.3f", p$ClimateSiteIndexMeters), "END",
    sprintf("TREEDATA  %10d", 15L), rec, "-999", "", "PROCESS", "STOP")
}
for (d in c("keys/c5", "keys/c100")) dir.create(file.path(base, d), recursive = TRUE, showWarnings = FALSE)
st <- list(); n <- 0L
for (i in seq_len(nrow(P))) {
  p <- P[i]; tt <- T[PLOT_ID == p$PLOT_ID]; if (!nrow(tt)) next
  n <- n + 1L
  writeLines(key(p, tt, 20, 5), file.path(base, "keys/c5", sprintf("P%d.key", p$PLOT_ID)))
  writeLines(key(p, tt, 1, 100), file.path(base, "keys/c100", sprintf("P%d.key", p$PLOT_ID)))
  st[[n]] <- data.table(plot_id = p$PLOT_ID, stand_id = p$Stand, matrix = p$Matrix, inv_year = p$INV_YEAR, n_rec = nrow(tt),
                        ba_ft2ac = sum(tt$tpa * 0.005454154 * tt$DIAMETER^2), tpa = sum(tt$tpa), ht_missing = sum(!(is.finite(tt$HT) & tt$HT > 0)))
}
S <- rbindlist(st); fwrite(S, file.path(base, "key_start.csv"))
cat("keys", n, "plots without trees", nrow(P) - n, "records", nrow(T), "remapped to OH/OS", sum(!(toupper(T$SPECIES) %in% c(sp_valid, "CE", "WB", "PC"))),
    "mean BA", round(mean(S$ba_ft2ac), 2), "mean TPA", round(mean(S$tpa), 1), "\n")
print(T[!(toupper(SPECIES) %in% c(sp_valid, "CE", "WB", "PC")), .N, by = .(SPECIES, sp)])

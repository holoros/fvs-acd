## v143 PREREG4 exploratory reading E1 (before registration; NOT registered). Classification only, no outcome: agreement of two
## candidate composition rules for the lever class (SF versus not SF) with the FIA forest type group (FORTYPCD at the t1 visit,
## grouped as in the 16 October benchmark) on the 918 mefia_l_c stands. Aggregates only. No coordinates read.
suppressMessages(library(data.table))
H <- "/users/PUOM0008/crsfaaron"; FR <- file.path(H, "magplot/verify/gydbreg20260916/frames")
I0 <- fread(file.path(FR, "bench_gyr_mefia_l_c_tree_init.csv"))
I0[, sp2 := fifelse(SP == "RN", "RP", fifelse(SP == "PR", "PC", SP))][, ba := DBH^2 * pi / 40000 * EXPF]
SFG <- c("BF", "RS", "WS", "BS", "NS", "TA", "WC"); PHG <- c("WP", "RP", "JP", "EH", "OS")
C <- I0[is.finite(ba) & ba > 0, .(sfs = sum(ba[sp2 %in% SFG]) / sum(ba), phs = sum(ba[sp2 %in% PHG]) / sum(ba)), by = STAND]
C[, `:=`(plural = fifelse(sfs >= pmax(phs, 1 - sfs - phs), "SF", "NSF"), major = fifelse(sfs >= 0.5, "SF", "NSF"))]
pr <- fread(file.path(FR, "bench_gyr_mefia_l_c_pairs.csv"), select = c("STAND", "PLOTKEY", "Y1"))
pr[, ROOT := sub("^FIA", "", PLOTKEY)]
PL <- fread(file.path(H, "fia_data/ME_PLOT.csv"), select = c("CN", "STATECD", "UNITCD", "COUNTYCD", "PLOT", "MEASYEAR"), colClasses = list(character = "CN"))
PL[, pid := paste(STATECD, UNITCD, COUNTYCD, PLOT, sep = "_")]
pr <- merge(pr, PL[, .(ROOT = CN, pid)], by = "ROOT", all.x = TRUE)
pr <- merge(pr, PL[, .(pid, Y1 = MEASYEAR, CN1 = CN)], by = c("pid", "Y1"), all.x = TRUE)[!duplicated(STAND)]
CO <- fread(file.path(H, "fia_data/ME_COND.csv"), select = c("PLT_CN", "CONDID", "COND_STATUS_CD", "FORTYPCD"), colClasses = list(character = "PLT_CN"))
CO <- CO[COND_STATUS_CD == 1][order(PLT_CN, CONDID)][!duplicated(PLT_CN)]
CO[, g10 := (FORTYPCD %/% 10) * 10][, ftg := fcase(g10 == 120, "SF", g10 == 800, "MBB", g10 == 900, "AB", g10 == 100, "WRPH",
  g10 %in% c(400, 500, 510, 520), "OAK", g10 == 700, "EAC", default = "OTH")]
pr <- merge(pr, CO[, .(CN1 = PLT_CN, ftg)], by = "CN1", all.x = TRUE)
X <- merge(pr[, .(STAND, ftg)], C, by = "STAND", all.x = TRUE)
X[, fiaSF := fifelse(ftg == "SF", "SF", "NSF")]
for (r in c("plural", "major")) { cat("rule", r, "\n"); print(X[, .N, by = c("ftg", r)][order(ftg)]); cat(sprintf("agreement SF vs not SF: %.3f (n %d)\n", X[, mean(get(r) == fiaSF, na.rm = TRUE)], X[is.finite(sfs), .N])) }

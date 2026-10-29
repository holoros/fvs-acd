## PREREG50 step 3 (plan revision 1, md5 6ea850d4): pooled stems per arm (R0, E1, S2), explained shares X with the PREREG48
## site cluster bootstrap (B = 1000, seed 20261001, site draw count weights over the fold's sorted screened sites, copied
## from p48_boot.R 8c7a865c; the same draws for every arm), gate G0, the gate table G0 to G7, the decision rule of the plan
## in order, the floor group re-run, floor group tables, fold A replication, and the reported QMD, BA and C1 volume percent
## RMSE (R2S point formula). Thresholds are copied from the plan and not changed. Identifier free tables only.
## Usage: Rscript p50_boot.R <dir> [full|dry]   (reads and writes <dir>)
source("/home/aaron/jobs/v142p50/scripts/p50_common.R")
B <- 1000L; SEED <- 20261001L; A_PT <- 2 / 3; A_LO <- 0.5; R_PT <- 1 / 3; R_HI <- 0.5; OV <- 1 / 3; SR_LO <- 0.90; SR_HI <- 1.10
L <- fread(file.path(OUTD, "p50-stands_SERVERONLY.csv"), colClasses = list(character = c("STAND", "SITE")))
L <- L[cut == FALSE]                                     # PREREG19 screen
FOLDS <- if (MODE == "dry") "A" else c("A", "B")
q95 <- function(x) unname(quantile(x, c(0.025, 0.975), na.rm = TRUE))
WT <- list()
for (fd in FOLDS) { sites <- sort(unique(L[fold == fd & arm == "R0"]$SITE)); ns <- length(sites); set.seed(SEED)
  IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B); WT[[fd]] <- list(sites = sites, W = sapply(1:B, function(k) tabulate(IDX[, k], ns))) }
wsub <- function(x, fd) WT[[fd]]$W[match(x$SITE, WT[[fd]]$sites), , drop = FALSE]
## wide per stand: one row per stand, arm columns
WD <- dcast(L, STAND + SITE + fold + floor + N_o + S_o + U_o + I_o + R_o ~ arm, value.var = c("N_p", "S_p", "I_p"))
if (anyNA(WD[, .(N_p_R0, N_p_E1, N_p_S2)])) stop("arm missing for a stand")
WD[, grp := fifelse(floor <= 9.7 + 1e-9, "9.1 to 9.7 cm", fifelse(floor >= 31 - 1e-9, "31 to 34 cm", "other"))]
pool <- function(x, fd) { W <- wsub(x, fd); cs <- function(v) colSums(W * v)
  out <- list(); bD0 <- cs(x$N_o - x$N_p_R0); D0 <- sum(x$N_o - x$N_p_R0)
  for (a in c("R0", "E1", "S2")) { Np <- x[[paste0("N_p_", a)]]; Sp <- x[[paste0("S_p_", a)]]; Ip <- x[[paste0("I_p_", a)]]
    D <- sum(x$N_o - Np); bD <- cs(x$N_o - Np); bX <- (bD0 - bD) / bD0; bdev <- 100 * bD / cs(x$N_o); bSR <- cs(Sp) / cs(x$S_o)
    out[[a]] <- data.table(arm = a, stands = nrow(x), sites = uniqueN(x$SITE), N_o = sum(x$N_o), N_p = sum(Np), D = D,
      dev_pts = 100 * D / sum(x$N_o), dev_lo = q95(bdev)[1], dev_hi = q95(bdev)[2],
      X = (D0 - D) / D0, X_lo = q95(bX)[1], X_hi = q95(bX)[2], I_o = sum(x$I_o), I_p = sum(Ip), S_o = sum(x$S_o), S_p = sum(Sp),
      SR = sum(Sp) / sum(x$S_o), SR_lo = q95(bSR)[1], SR_hi = q95(bSR)[2]) }
  rbindlist(out) }
decide <- function(p) { r0 <- p[arm == "R0"]; e <- p[arm == "E1"]; s <- p[arm == "S2"]; D0 <- r0$D
  bar <- function(z) z$X >= A_PT && z$X_lo > A_LO && z$D > -OV * D0
  bE <- bar(e); bS <- bar(s)
  rule <- if (e$D < 0 && abs(e$D) >= OV * D0) "rule 2: overcorrection (HO); 14.3 track is the floor matched ingrowth rate on QC" else
    if (bE && bS) "rule 3: artifact (HA); 14.3 track is a benchmark and runner convention (ingrowth threshold matched to the inventory floor)" else
    if (bE != bS) "rule 4: convention dependent; 14.3 track is floor handling, open loop and closed loop disagree" else
    if (e$X < R_PT && s$X < R_PT && e$X_hi < R_HI && s$X_hi < R_HI) "rule 5: real shortfall (HR); 14.3 track is ingrowth rate or small tree growth, not separable on the QC frames" else
    "rule 6: mixed; no track named"
  data.table(D_R0 = D0, D_E1 = e$D, D_S2 = s$D, X_E1 = e$X, X_E1_lo = e$X_lo, X_E1_hi = e$X_hi, X_S2 = s$X, X_S2_lo = s$X_lo, X_S2_hi = s$X_hi,
    E1_meets_bar = bE, S2_meets_bar = bS, rule2_E1_overshoot = e$D < 0 && abs(e$D) >= OV * D0, S2_overshoots = s$D < -OV * D0, rule = rule) }
PO <- rbindlist(lapply(FOLDS, function(fd) rbindlist(list(
  cbind(data.table(fold = fd, pop = "all screened"), pool(WD[fold == fd], fd)),
  cbind(data.table(fold = fd, pop = "floor 9.1 to 9.7 cm"), pool(WD[fold == fd & grp == "9.1 to 9.7 cm"], fd)),
  if (WD[fold == fd & grp == "31 to 34 cm", .N]) cbind(data.table(fold = fd, pop = "floor 31 to 34 cm"), pool(WD[fold == fd & grp == "31 to 34 cm"], fd)) else NULL))))
wfile(PO, "p50-pools.csv")
GF <- WD[, .N, by = .(fold, grp)][order(fold, grp)]; wfile(GF, "p50-floorgroup-counts.csv"); print(GF)
DEC <- rbindlist(lapply(FOLDS, function(fd) rbindlist(lapply(c("all screened", "floor 9.1 to 9.7 cm"), function(pp)
  cbind(data.table(fold = fd, pop = pp, gated = fd == "B" & pp == "all screened"), decide(PO[fold == fd & pop == pp]))))), fill = TRUE)
## ---------------- gates
GT <- list()
if (MODE == "full") { r0 <- PO[fold == "B" & pop == "all screened" & arm == "R0"]
  GT$G0 <- data.table(gate = "G0", value = sprintf("dev %.5f points, D %.0f, I_o %.0f, I_p %.4f", r0$dev_pts, r0$D, r0$I_o, r0$I_p),
    threshold = "24.22615, 37465, 47607, 65.4935 to the published rounding",
    pass = sprintf("%.5f", r0$dev_pts) == "24.22615" & round(r0$D) == 37465 & round(r0$I_o) == 47607 & sprintf("%.4f", r0$I_p) == "65.4935")
  g1 <- fread(file.path(OUTD, "p50-G1.csv"))
  GT$G1 <- data.table(gate = "G1", value = sprintf("min %.1f cm, median %.2f cm, %d of %d records at the floor, all sizes %.0f", g1$min_dbh, g1$median_dbh, g1$records_at_floor, g1$records, g1$sum_all_sizes),
    threshold = "5.0, 5.67, 7 of 6042, 51728 to the published rounding", pass = g1$pass) }
g2 <- fread(file.path(OUTD, "p50-G2.csv"))
GT$G2 <- data.table(gate = "G2", value = paste(sprintf("%s %d of %d identical (header %s)", g2$kind, g2$identical, g2$stands, g2$header_ok), collapse = "; "),
  threshold = "identical text on every screened stand", pass = all(g2$pass))
g3 <- fread(file.path(OUTD, "p50-G3.csv"))
GT$G3 <- data.table(gate = "G3", value = paste(sprintf("%s %d of %d traced, max differences %.3g, %.3g, %.3g; %d year 1 records, max entry DBH minus floor %.3g", g3$arm, g3$traced, g3$stands,
  g3$max_ingmin_vs_threshold, g3$max_threshold_vs_results, g3$max_threshold_vs_floor, g3$yr1_ingrowth_records, g3$max_yr1_entry_dbh_vs_floor), collapse = "; "), threshold = "at or below 1e-9", pass = all(g3$pass))
g4 <- fread(file.path(OUTD, "p50-G4.csv"))[population == "20 stand sample (gated)"]
GT$G4 <- data.table(gate = "G4", value = sprintf("%d stands: max relative difference total %.3g, shares %.3g, species mismatches %d", g4$stands, g4$max_rel_total, g4$max_rel_share, g4$species_mismatch),
  threshold = "at or below 1e-9, no species mismatch", pass = g4$pass)
g5 <- fread(file.path(OUTD, "p50-G5.csv"))
GT$G5 <- data.table(gate = "G5", value = paste(sprintf("%s %d of %d RUN_OK", g5$arm, g5$run_ok, g5$stands_required), collapse = "; "), threshold = "0 failures", pass = all(g5$pass))
g6 <- fread(file.path(OUTD, "p50-G6.csv"))
GT$G6 <- data.table(gate = "G6", value = sprintf("%d stands; stand_frame against fold_of %d differ; fold_of against the PREREG22 rule %d differ", g6$stands, g6$stand_frame_vs_fold_of, g6$fold_of_vs_p22_rule),
  threshold = "identical", pass = g6$pass)
g7f <- file.path(J, "logs/lookups_G7.csv"); g7 <- fread(g7f, colClasses = "character"); nq <- if (nrow(g7)) sum(g7$qc_set_named == "TRUE") else 0L
GT$G7 <- data.table(gate = "G7", value = sprintf("%d files contain ING_MIN_FROM_SCORE=1; %d also name a QC set", nrow(g7), nq), threshold = "label only", pass = nq == 0)
GT <- rbindlist(GT, fill = TRUE); wfile(GT, "p50-gates.csv"); print(GT)
harness <- all(GT[gate %in% sprintf("G%d", 0:6)]$pass)
## ---------------- decision with labels
l2 <- readLines(file.path(J, "logs/lookups_L2.txt"))[1]
lab <- c("previously inspected population")
dB <- DEC[fold == (if (MODE == "dry") "A" else "B")]
main <- dB[pop == "all screened"]; sub <- dB[pop == "floor 9.1 to 9.7 cm"]
if (!harness) { verdict <- paste0("rule 1: no verdict, harness failure (", paste(GT[gate %in% sprintf("G%d", 0:6) & pass == FALSE]$gate, collapse = ", "), ")"); lab <- c(lab, "harness failed") } else verdict <- main$rule
if (main$rule != sub$rule) lab <- c(lab, "floor group sensitive")
if (grepl("not found", l2)) lab <- c(lab, "threshold support unknown")
if (isTRUE(main$S2_overshoots)) lab <- c(lab, "S2 overshoots")
if (nq > 0) lab <- c(lab, "floor matched QC run previously seen")
e1 <- PO[fold == (if (MODE == "dry") "A" else "B") & pop == "all screened" & arm == "E1"]
srn <- sprintf("E1 survivor ratio %.4f (%.4f to %.4f)%s", e1$SR, e1$SR_lo, e1$SR_hi, if (e1$SR < SR_LO || e1$SR > SR_HI) ", outside 0.90 to 1.10" else ", inside 0.90 to 1.10")
DEC[, verdict := fifelse(gated, verdict, NA_character_)]
wfile(DEC, "p50-decision.csv")
VL <- data.table(item = c("mode", "verdict", "labels", "survivor ratio note", "L2"), value = c(MODE, verdict, paste(lab, collapse = "; "), srn, l2))
wfile(VL, "p50-verdict.csv"); print(VL)
## ---------------- reported percent RMSE, R0 and E1, screened (fold B in full mode)
pm <- function(o, p) 100 * sqrt(mean((p - o)^2)) / mean(o)          # R2S line 81 point formula
RM <- rbindlist(lapply(FOLDS, function(fd) rbindlist(lapply(c("R0", "E1"), function(a) { x <- L[fold == fd & arm == a]
  data.table(fold = fd, arm = a, stands = nrow(x), QMD_rmse_pct = pm(x$QMD_o, x$QMD_p), BA_rmse_pct = pm(x$BA_o, x$BA_p), C1_vol_rmse_pct = pm(x$V_oh, x$V_ph),
    C1_vol_ratio = sum(x$V_ph) / sum(x$V_oh), QMD_ratio = sum(x$QMD_p) / sum(x$QMD_o), BA_ratio = sum(x$BA_p) / sum(x$BA_o)) }))))
wfile(RM, "p50-rmse.csv"); print(RM)
print(PO[pop == "all screened", .(fold, arm, stands, D, dev_pts, X, X_lo, X_hi, I_o, I_p, SR)])
cat("P50_BOOT_DONE\n")

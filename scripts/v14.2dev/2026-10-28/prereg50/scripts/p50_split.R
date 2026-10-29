## PREREG50 step 2 (plan revision 1, md5 6ea850d4): per stand stems at the scoring floor for R0 (frozen qc141, p19_a0111),
## E1 (ING_MIN_FROM_SCORE=1) and S2 (frozen qc141 survivors plus iv times the one step ingrowth from the t1 list, threshold
## at the floor), with the PREREG48 split (copied from p48_split.R b8829fa5: survivors S, upgrowth U, recruitment I,
## residual R; MAGPlot field tags pair t1 and t2; the run frame TREE column is never a key). Gates G1, G3, G4, G5, G6; the
## PREREG48 T1 frame check; QMD, BA and C1 volume inputs for the reported percent RMSE. Writes one SERVERONLY per stand file
## and identifier free tables. Nothing is fitted; frozen inputs are read only. No coordinates. No em dashes.
## Usage: Rscript p50_split.R <outdir> [full|dry]
source("/home/aaron/jobs/v142p50/scripts/p50_common.R")
source(HKEY)                               # FR (run frames), fold_of, tagok, mapsp, split_map, stand_frame, totvol
FR_RUN <- FR
INP <- c(R0_RES, CUTF, HKEY, P17, file.path(FR_FIELD, c("bench_gyr_qc_c_tree_init.csv", "bench_gyr_qc_c_tree_t2.csv")),
  file.path(FR_RUN, c("bench_gyr_qc_c_tree_init.csv", "bench_gyr_qc_c_tree_t2.csv")))
MD <- data.table(file = INP, md5 = unname(tools::md5sum(INP)))
## ---------------- stands (R0 RUN_OK 1, PREREG19 cut flag, fold) and G6
S0 <- stand_frame(R0_RES, "qc_c", CUTF)
.l9 <- readLines(P17)[9]; if (!grepl("^fold <- function\\(site\\)", .l9)) stop("PREREG22 rule line 9 not the fold function")
p22env <- new.env(); eval(parse(text = .l9), envir = p22env)
G6 <- data.table(gate = "G6", stands = nrow(S0), stand_frame_vs_fold_of = sum(S0$fold != fold_of(S0$SITE)),
  fold_of_vs_p22_rule = sum(fold_of(S0$SITE) != p22env$fold(as.character(S0$SITE))))
G6[, pass := stand_frame_vs_fold_of == 0 & fold_of_vs_p22_rule == 0]
S0 <- S0[, .(STAND, SITE = as.character(SITE), cut, fold, floor = SCORE_MINDBH_USED, iv_years = interval_years)]
if (MODE == "dry") { keep <- fread(KEEPF)$STAND; S0 <- S0[STAND %in% keep]; if (S0[fold != "A" | cut == TRUE, .N]) stop("dry stands must be screened fold A") }
ST <- S0$STAND
cat(sprintf("stands %d (screened A %d, screened B %d, cut %d)%s\n", nrow(S0), S0[cut == FALSE & fold == "A", .N], S0[cut == FALSE & fold == "B", .N], S0[cut == TRUE, .N], if (MODE == "dry") " DRY" else ""))
## ---------------- arm results and G5
RES <- list(R0 = fread(R0_RES)[, STAND := as.character(STAND)][STAND %in% ST],
  E1 = rd_runner(arm_dirs50("e1"), pat50("results")), S2 = rd_runner(arm_dirs50("s2"), pat50("results")))
for (a in c("E1", "S2")) if (!is.null(RES[[a]])) RES[[a]] <- RES[[a]][STAND %in% ST]
G5 <- rbindlist(lapply(c("E1", "S2"), function(a) { r <- RES[[a]]; ok <- if (is.null(r)) character(0) else r[RUN_OK == 1]$STAND
  data.table(gate = "G5", arm = a, stands_required = length(ST), run_ok = sum(ST %in% ok), failures = sum(!ST %in% ok)) }))
G5[, pass := failures == 0]
wfile(G6, "p50-G6.csv"); wfile(G5, "p50-G5.csv"); print(G6); print(G5)
if (!all(G5$pass)) { wfile(MD, "p50-input-md5.csv"); stop("G5 failed: harness failure, no per stand quantities") }
## ---------------- frames: field tag frames (pairing) and run frames (T1 comparison), row0 = row order within stand
rdf <- function(dir, tt) fread(file.path(dir, sprintf("bench_gyr_qc_c_tree_%s.csv", tt)))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% ST]
F1 <- rdf(FR_FIELD, "init"); F2 <- rdf(FR_FIELD, "t2"); R1 <- rdf(FR_RUN, "init"); R2 <- rdf(FR_RUN, "t2")
setnames(R1, "TREE", "ROWIDX_DO_NOT_JOIN"); setnames(R2, "TREE", "ROWIDX_DO_NOT_JOIN")   # run frame TREE is a row index
guard <- function(by) if (any(grepl("ROWIDX_DO_NOT_JOIN|^TREE$", by))) stop("join keyed on the run frame TREE column")
mrg <- function(a, b, by, ...) { guard(by); merge(a, b, by = by, ...) }
F1 <- mrg(F1, S0[, .(STAND, floor)], by = "STAND"); F2 <- mrg(F2, S0[, .(STAND, floor)], by = "STAND")
R1 <- mrg(R1, S0[, .(STAND, floor)], by = "STAND"); R2 <- mrg(R2, S0[, .(STAND, floor)], by = "STAND")
t1f <- F1[, .(n1_field = sum(EXPF[livef(DBH, EXPF, floor)])), by = STAND]; t1r <- R1[, .(n1_run = sum(EXPF[livef(DBH, EXPF, floor)])), by = STAND]
T1S <- mrg(mrg(S0[, .(STAND)], t1f, by = "STAND", all.x = TRUE), t1r, by = "STAND", all.x = TRUE)
for (cc in c("n1_field", "n1_run")) set(T1S, which(is.na(T1S[[cc]])), cc, 0)
T1S[, t1_scaled := abs(n1_field - n1_run) / pmax(1, abs(n1_run))][, t1_ok := t1_scaled <= 1e-6]
## ---------------- observed split on field tags (verbatim logic of p48_split.R)
F1[, `:=`(TAG = TREE, v = tagok(TREE))]; F2[, `:=`(TAG = TREE, v = tagok(TREE))]
F1[v == TRUE, nt := .N, by = .(STAND, TAG)]; F2[v == TRUE, nt := .N, by = .(STAND, TAG)]
t2u <- F2[v == TRUE & nt == 1, .(STAND, TAG, SP2 = SP)]; t2d <- unique(F2[v == TRUE & nt > 1, .(STAND, TAG, dup2 = TRUE)])
c1 <- F1[v == TRUE & nt == 1, .(STAND, TAG, row0, SP, D1 = DBH, E1 = EXPF, floor)]
c1 <- mrg(mrg(c1, t2u, by = c("STAND", "TAG"), all.x = TRUE), t2d, by = c("STAND", "TAG"), all.x = TRUE)
c1[, clean := is.na(dup2) & (is.na(SP2) | SP2 == SP)]
F1 <- mrg(F1, c1[, .(STAND, row0, clean)], by = c("STAND", "row0"), all.x = TRUE); F1[is.na(clean), clean := FALSE]
alltag1 <- unique(F1[v == TRUE, .(STAND, TAG, in1 = TRUE)])
X2 <- F2[livef(DBH, EXPF, floor)]
X2 <- mrg(X2, c1[clean == TRUE, .(STAND, TAG, D1, c1 = TRUE)], by = c("STAND", "TAG"), all.x = TRUE)
X2 <- mrg(X2, alltag1, by = c("STAND", "TAG"), all.x = TRUE)
X2[, comp := fifelse(v & nt == 1 & !is.na(c1) & D1 >= floor, "S", fifelse(v & nt == 1 & !is.na(c1) & D1 < floor, "U", fifelse(v & nt == 1 & is.na(in1), "I", "R")))]
X2[is.na(comp), comp := "R"]
OB <- X2[, .(S_o = sum(EXPF[comp == "S"]), U_o = sum(EXPF[comp == "U"]), I_o = sum(EXPF[comp == "I"]), R_o = sum(EXPF[comp == "R"]), N_o = sum(EXPF)), by = STAND]
## observed C1 volume (R2S lines 112 to 113: run frames at t2, heights set missing, at the stand floor)
VO <- R2[, .(V_oh = totvol(mapsp(SP), DBH, rep(NA_real_, .N), EXPF, floor[1])), by = STAND]
## ---------------- predicted split per arm (R0 frozen, E1)
M <- split_map(F1[, .(STAND, PLOT, TREE, SP, DBH, HT, EXPF, YEAR, row0, sp = mapsp(SP))])
ARMS <- list(R0 = list(dirs = R0_DIRS, pat = pat19), E1 = list(dirs = arm_dirs50("e1"), pat = pat50))
PR <- list(); MCH <- list(); P2 <- list()
for (a in names(ARMS)) {
  p1 <- rd_runner(ARMS[[a]]$dirs, ARMS[[a]]$pat("t1_split_tree"), select = c("STAND", "tree", "sp", "dbh", "expf"))[STAND %in% ST]
  p2 <- rd_runner(ARMS[[a]]$dirs, ARMS[[a]]$pat("pred_t2_tree"), select = c("STAND", "iv", "tree", "sp", "dbh", "expf", "ing"))[STAND %in% ST]
  if (!setequal(unique(p2$STAND), ST) || !setequal(unique(p1$STAND), ST)) stop("per tree outputs do not cover the stands ", a)
  if (anyDuplicated(p1[, .(STAND, tree)]) || anyDuplicated(p2[, .(STAND, tree)])) stop("runner tree key not unique ", a)
  P2[[a]] <- p2
  mm <- merge(M[, .(STAND, tree, row0, spm = sp, dm = dbh, em = expf)], p1, by = c("STAND", "tree"), all = TRUE)
  MCH[[a]] <- mm[, .(map_ok = all(!is.na(row0) & !is.na(sp) & spm == sp & abs(dm - dbh) <= 1e-6 & abs(em - expf) <= 1e-6 * pmax(1, expf))), by = STAND]
  q <- merge(p2, p1[, .(STAND, tree, d1 = dbh)], by = c("STAND", "tree"), all.x = TRUE)
  if (q[ing == 0 & is.na(d1), .N]) stop("survivor record without t1 record ", a)
  q <- merge(q, M[, .(STAND, tree, row0)], by = c("STAND", "tree"), all.x = TRUE)
  q <- mrg(q, F1[, .(STAND, row0, clean)], by = c("STAND", "row0"), all.x = TRUE); q[is.na(clean), clean := FALSE]
  q <- mrg(q, S0[, .(STAND, floor)], by = "STAND")
  vp <- q[, .(V_ph = totvol(sp, dbh, rep(NA_real_, .N), expf, floor[1])), by = STAND]
  q <- q[livef(dbh, expf, floor)]
  q[, comp := fifelse(ing == 1, "I", fifelse(clean & d1 >= floor, "S", fifelse(clean & d1 < floor, "U", "R")))]
  x <- q[, .(S_p = sum(expf[comp == "S"]), U_p = sum(expf[comp == "U"]), I_p = sum(expf[comp == "I"]), R_p = sum(expf[comp == "R"]), N_p = sum(expf)), by = STAND]
  rr <- RES[[a]][, .(STAND, QMD_o, QMD_p, BA_o, BA_p, SMD_res = SCORE_MINDBH_USED)]
  PR[[a]] <- Reduce(function(u, w) merge(u, w, by = "STAND", all.x = TRUE), list(S0[, .(STAND)], x, vp, rr))
  cat(a, "predicted split done\n") }
## ---------------- S2: one step ingrowth from the t1 list at the floor, times iv (iv from the frozen per tree t2 file)
IV <- unique(P2$R0[, .(STAND, iv)]); if (anyDuplicated(IV$STAND)) stop("iv not unique per stand")
Y <- list(E1 = rd_runner(arm_dirs50("e1"), pat50("pred_yr1_tree"), select = c("STAND", "tree", "sp", "dbh", "expf", "ing")),
          S2 = rd_runner(arm_dirs50("s2"), pat50("pred_yr1_tree"), select = c("STAND", "tree", "sp", "dbh", "expf", "ing")))
for (a in names(Y)) { Y[[a]] <- mrg(Y[[a]][STAND %in% ST], S0[, .(STAND, floor)], by = "STAND"); if (!setequal(unique(Y[[a]]$STAND), ST)) stop("year 1 capture does not cover the stands ", a) }
IS2 <- merge(merge(S0[, .(STAND)], Y$S2[ing == 1 & livef(dbh, expf, floor), .(i1 = sum(expf)), by = STAND], by = "STAND", all.x = TRUE), IV, by = "STAND")
IS2[is.na(i1), i1 := 0][, I_S2 := iv * i1]
s2 <- merge(PR$R0[, .(STAND, S_p, U_p, R_p)], IS2[, .(STAND, I_p = I_S2)], by = "STAND")
s2[, N_p := S_p + U_p + I_p + R_p]
PR$S2 <- merge(s2, S0[, .(STAND)], by = "STAND")
## ---------------- G1 (full mode: R0 entry facts on screened fold B)
if (MODE == "full") { B <- S0[cut == FALSE & fold == "B", .(STAND, floor)]; pi1 <- merge(P2$R0[ing == 1], B, by = "STAND")
  g1 <- data.table(min_dbh = min(pi1$dbh), median_dbh = median(pi1$dbh), records = nrow(pi1), records_at_floor = pi1[livef(dbh, expf, floor), .N], sum_all_sizes = sum(pi1$expf))
  g1[, pass := sprintf("%.1f", min_dbh) == "5.0" & sprintf("%.2f", median_dbh) == "5.67" & records == 6042L & records_at_floor == 7L & round(sum_all_sizes) == 51728]
  g1 <- cbind(data.table(gate = "G1", arm = "R0 qc141, screened fold B"), g1); wfile(g1, "p50-G1.csv"); print(g1) }
## ---------------- G3: traces and year 1 entry DBH (E1 and S2)
TR <- list(E1 = rd_runner(arm_dirs50("e1"), pat50("ingmin_trace"), header = FALSE, col.names = c("STAND", "ingmin", "smd")),
           S2 = rd_runner(arm_dirs50("s2"), pat50("ingmin_trace"), header = FALSE, col.names = c("STAND", "ingmin", "smd")))
G3 <- rbindlist(lapply(c("E1", "S2"), function(a) { t <- TR[[a]][STAND %in% ST]; t <- t[, .SD[.N], by = STAND]
  z <- merge(merge(S0[, .(STAND, floor)], t, by = "STAND", all.x = TRUE), RES[[a]][, .(STAND, SMD_res = SCORE_MINDBH_USED)], by = "STAND", all.x = TRUE)
  y <- Y[[a]][ing == 1]
  data.table(gate = "G3", arm = a, stands = nrow(z), traced = sum(!is.na(z$ingmin)), max_ingmin_vs_threshold = max(abs(z$ingmin - z$smd)),
    max_threshold_vs_results = max(abs(z$smd - z$SMD_res)), max_threshold_vs_floor = max(abs(z$smd - z$floor)),
    yr1_ingrowth_records = nrow(y), max_yr1_entry_dbh_vs_floor = if (nrow(y)) max(abs(y$dbh - y$floor)) else 0) }))
G3[, pass := traced == stands & max_ingmin_vs_threshold <= 1e-9 & max_threshold_vs_results <= 1e-9 & max_threshold_vs_floor <= 1e-9 & max_yr1_entry_dbh_vs_floor <= 1e-9]
wfile(G3, "p50-G3.csv"); print(G3)
## ---------------- G4: S2 pass against E1 year 1 capture, 20 stand sample of screened stands (set.seed(50))
rdif <- function(a, b) ifelse(a == 0 & b == 0, 0, abs(a - b) / pmax(abs(a), abs(b)))
yi <- function(y) y[ing == 1, .(e = sum(expf)), by = .(STAND, sp)]
cmp4 <- function(sts) { e <- yi(Y$E1)[STAND %in% sts][, sh := e / sum(e), by = STAND]; s <- yi(Y$S2)[STAND %in% sts][, sh := e / sum(e), by = STAND]
  tt <- merge(merge(data.table(STAND = sts), e[, .(te = sum(e)), by = STAND], by = "STAND", all.x = TRUE), s[, .(ts = sum(e)), by = STAND], by = "STAND", all.x = TRUE)
  tt[is.na(te), te := 0]; tt[is.na(ts), ts := 0]
  sh <- merge(e[, .(STAND, sp, she = sh)], s[, .(STAND, sp, shs = sh)], by = c("STAND", "sp"), all = TRUE); both <- sh[!is.na(she) & !is.na(shs)]
  data.table(stands = length(sts), max_rel_total = max(rdif(tt$te, tt$ts)), species_mismatch = sh[is.na(she) | is.na(shs), .N],
    max_rel_share = if (nrow(both)) max(rdif(both$she, both$shs)) else 0) }
scr <- sort(S0[cut == FALSE]$STAND); set.seed(50L); smp <- sample(scr, min(20L, length(scr)))
G4 <- rbind(cbind(data.table(gate = "G4", population = "20 stand sample (gated)"), cmp4(smp)),
            cbind(data.table(gate = "G4", population = "all stands (reported)"), cmp4(ST)))
G4[, pass := max_rel_total <= 1e-9 & species_mismatch == 0 & max_rel_share <= 1e-9]
wfile(G4, "p50-G4.csv"); print(G4)
## ---------------- per stand table (SERVERONLY: carries STAND and SITE)
PS <- Reduce(function(x, y) merge(x, y, by = "STAND", all.x = TRUE), list(S0, T1S, OB, VO))
for (cc in c("S_o", "U_o", "I_o", "R_o", "N_o")) set(PS, which(is.na(PS[[cc]])), cc, 0)
MALL <- merge(MCH$R0[, .(STAND, m0 = map_ok)], MCH$E1[, .(STAND, m1 = map_ok)], by = "STAND", all = TRUE)[, map_all := !is.na(m0) & !is.na(m1) & m0 & m1]
LONG <- rbindlist(lapply(names(PR), function(a) { x <- merge(PS, PR[[a]], by = "STAND"); x[, arm := a]
  for (cc in c("S_p", "U_p", "I_p", "R_p", "N_p")) set(x, which(is.na(x[[cc]])), cc, 0); x }), fill = TRUE)
LONG <- merge(LONG, MALL[, .(STAND, map_all)], by = "STAND", all.x = TRUE); LONG[is.na(map_all), map_all := FALSE]
LONG[, ident_o := abs(N_o - (S_o + U_o + I_o + R_o))][, ident_p := abs(N_p - (S_p + U_p + I_p + R_p))]
if (LONG[, max(ident_o, ident_p)] > 1e-6) stop("component identity fails")
LONG[, covered := t1_ok & map_all]
wfile(LONG, "p50-stands_SERVERONLY.csv")
CK <- LONG[arm == "R0", .(stands = .N, t1_fail = sum(!t1_ok), t1_worst_scaled = max(t1_scaled), map_fail = sum(!map_all), covered = sum(covered)), by = .(cut, fold)][order(cut, fold)]
wfile(CK, "p50-T1-coverage.csv"); print(CK)
wfile(MD, "p50-input-md5.csv")
cat("P50_SPLIT_DONE\n")

## PREREG41 Part B assembly (frozen outputs only): matched tree TOPHT bound B_MM for the ten PREREG38 arms, screened qc_c fold B,
## plus the reported Part A comparison of p38_fit with the frozen PREREG31 p28b_small relations. Plan
## ~/jobs/v142p41/plan/2026-10-02_v142_bakuzis-qc-p38fit_PREREG41.md (md5 a1aa4b35). Reproduction of the PREREG40 M observed
## stand values first. Site cluster bootstrap B = 1000 seed 20261041. No engine run. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")   # fold_of, tagok, mapsp, split_map, pred_ht, arm_dirs, P19
J <- "/home/aaron/jobs/v142p41"; P38 <- "/home/aaron/jobs/v142p38"; P23 <- "/home/aaron/jobs/v142p23"; P28B <- "/home/aaron/jobs/v142p28b"
P40 <- "/home/aaron/jobs/v142p40"; P31 <- "/home/aaron/jobs/v142p31"; FT <- "/home/aaron/jobs/v142p14/in/pass28qc"; DT <- "2026-10-02"; B <- 1000L; LIM <- 10
PLAN <- file.path(J, "plan/2026-10-02_v142_bakuzis-qc-p38fit_PREREG41.md")
if (unname(tools::md5sum(PLAN)) != "a1aa4b3532f0b3ac9ec30e63a3f7fcec") stop("plan md5 differs")
O <- file.path(J, "assembled"); dir.create(O, showWarnings = FALSE)   # shared with Part A; every file write refuses to overwrite
w_out <- function(x, n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f) }
RUN <- file.path(P38, "home/runner_p28_fb.R"); if (unname(tools::md5sum(RUN)) != "0a2b27421ee7b25eaab7f4591ce3af97") stop("runner md5 differs")
RL <- readLines(RUN); eval(parse(text = grep("^sw<-c\\(", RL, value = TRUE))); eval(parse(text = grep("^himp<-function", RL, value = TRUE)))
acadgy <- names(AGY2SPCD); mapsp_r <- function(s) { s <- toupper(s); ifelse(s %in% acadgy, s, ifelse(s %in% sw, "OS", "OH")) }
top_sel <- function(dbh, expf, mindbh) {
  live <- which(is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0); if (!length(live)) return(integer(0))
  o <- live[order(-dbh[live])]; cw <- cumsum(expf[o]); idx <- which(cw <= 100); if (!length(idx)) idx <- 1; o[idx] }
AR <- data.table(arm = c("p19_a0030", "p19_a0060", "p19_a0111", "p19_a0250", "p19_a0500", "p19_a1000", "p23_a1061", "p23_a1250", "p28b_small", "p38_fit"),
  qc_afac = c(0.030, 0.060, 0.111, 0.250, 0.500, 1.000, 1.061, 1.250, NA, 1.242))
AR[, root := fifelse(startsWith(arm, "p19"), P19, fifelse(startsWith(arm, "p23"), P23, fifelse(startsWith(arm, "p28b"), P28B, P38)))]
AR[, home := file.path(root, "home")][, res := file.path(root, "results", arm, sprintf("gyr_%s_qc_c_results.csv", arm))]
AR[, stands := fifelse(startsWith(arm, "p19"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p23"), file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p28b"), file.path(P28B, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), file.path(P38, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"))))]
FI <- file.path(FT, "bench_gyr_qc_c_tree_init.csv"); FG <- file.path(FT, "bench_gyr_qc_c_tree_t2.csv")
S40 <- file.path(P40, "assembled/gyr142-p40-stands_SERVERONLY_DATA_2026-10-02.csv")
if (unname(tools::md5sum(S40)) != "e2efb2b94a291ab1dfe362b420275669") stop("PREREG40 stands file md5 differs")
TL <- unlist(lapply(seq_len(nrow(AR)), function(i) unlist(lapply(arm_dirs(AR$home[i], AR$arm[i], "qc_c"), function(d) sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE))))))
inp <- c(PLAN, AR$res, unique(AR$stands), FI, FG, S40, RUN, "/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R", TL)
if (!all(file.exists(inp))) stop("missing input")
mf <- file.path(J, "logs/input_md5_b.txt"); if (file.exists(mf)) stop("REFUSE ", mf); writeLines(paste(unname(tools::md5sum(inp)), inp, sep = "  "), mf)
## frames and tag link (PREREG39 and 40 rules)
F0 <- fread(FI)[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
G0 <- fread(FG)[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
F0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]; G0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]
d1 <- F0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]; d2 <- G0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]
F0[d1, on = .(STAND, TAG), TAG := NA_character_]; G0[d2, on = .(STAND, TAG), TAG := NA_character_]
LK <- merge(F0[!is.na(TAG), .(STAND, TAG, row0)], G0[!is.na(TAG), .(STAND, TAG, row2 = row0)], by = c("STAND", "TAG"))
G0 <- merge(G0, LK[, .(STAND, row2, row1 = row0)], by.x = c("STAND", "row0"), by.y = c("STAND", "row2"), all.x = TRUE)
G0[, meas := !is.na(row1) & is.finite(HT) & HT > 0][, spm := mapsp_r(SP)]
F0[, sp := mapsp(SP)]; MAP <- split_map(F0)
S40d <- fread(S40)
PER <- list(); POP <- list(); REP <- list()
for (i in seq_len(nrow(AR))) { a <- AR$arm[i]
  r <- fread(AR$res[i])[, STAND := as.character(STAND)]; stn <- fread(AR$stands[i])[label == "qc_c" & arm == a][, STAND := as.character(STAND)]
  v <- merge(stn[, .(STAND, cut)], r[RUN_OK == 1, .(STAND, SITE, SMD = SCORE_MINDBH_USED)], by = "STAND"); v[, fold := fold_of(SITE)]
  pop <- v[cut == FALSE & fold == "B"]; POP[[a]] <- pop; st <- pop$STAND; smd <- setNames(pop$SMD, pop$STAND)
  Hp <- pred_ht(arm_dirs(AR$home[i], a, "qc_c"), MAP, st)               # STAND, row0 (t1), Hp
  GM <- split(G0[STAND %in% st & meas == TRUE], by = "STAND")
  S <- rbindlist(lapply(st, function(s) { g <- GM[[s]]; if (is.null(g)) return(data.table(STAND = s, O_M = NA_real_, O_MM = NA_real_, P_MM = NA_real_, n_sel = 0L, n_drop = 0L))
    k <- top_sel(g$DBH, g$EXPF, smd[[s]]); if (!length(k)) return(data.table(STAND = s, O_M = NA_real_, O_MM = NA_real_, P_MM = NA_real_, n_sel = 0L, n_drop = 0L))
    x <- g[k]; om <- mean(x$HT); x <- merge(x[, .(STAND, row1, HT)], Hp[STAND == s, .(STAND, row1 = row0, Hp)], by = c("STAND", "row1"), all.x = TRUE)
    nd <- sum(!is.finite(x$Hp)); x <- x[is.finite(Hp)]
    data.table(STAND = s, O_M = om, O_MM = if (nrow(x)) mean(x$HT) else NA_real_, P_MM = if (nrow(x)) mean(x$Hp) else NA_real_, n_sel = length(k), n_drop = nd) }))
  S <- merge(S, pop[, .(STAND, SITE)], by = "STAND"); PER[[a]] <- S
  ch <- merge(S[, .(STAND, O_M)], S40d[arm == a, .(STAND, O_M40 = O_M)], by = "STAND")
  REP[[a]] <- data.table(arm = a, check = "O_M against PREREG40 stands file", stands = nrow(ch),
    worst = max(c(0, abs(ch$O_M - ch$O_M40)[is.finite(ch$O_M) & is.finite(ch$O_M40)])), na_mismatch = sum(is.finite(ch$O_M) != is.finite(ch$O_M40)))
  cat(sprintf("%s: %d stands; O_M reproduction worst %.3g; dropped %d of %d selected\n", a, nrow(pop), REP[[a]]$worst, sum(S$n_drop), sum(S$n_sel))) }
REP <- rbindlist(REP); REP[, pass := is.finite(worst) & worst <= 1e-9 & na_mismatch == 0]; print(REP)
w_out(REP, sprintf("gyr142-p41-mm-repro_DATA_%s.csv", DT)); if (!all(REP$pass)) stop("REPRODUCTION STOP FAILED: no reading")
sites <- sort(unique(unlist(lapply(POP, function(p) p$SITE)))); ns <- length(sites)
set.seed(20261041); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B); W <- apply(IDX, 2, tabulate, nbins = ns)
MM <- rbindlist(lapply(AR$arm, function(a) { x <- PER[[a]][is.finite(P_MM) & is.finite(O_MM)]; w <- W[match(x$SITE, sites), , drop = FALSE]
  bb <- 100 * (colSums(w * x$P_MM) - colSums(w * x$O_MM)) / colSums(w * x$O_MM)
  data.table(arm = a, qc_afac = AR[arm == a]$qc_afac, B_MM = 100 * (mean(x$P_MM) - mean(x$O_MM)) / mean(x$O_MM), lo = unname(quantile(bb, .025)), hi = unname(quantile(bb, .975)),
    stands = nrow(x), selected = sum(PER[[a]]$n_sel), dropped = sum(PER[[a]]$n_drop), sel_per_stand = mean(x$n_sel)) }))
MM[, within_limit := abs(B_MM) <= LIM]; print(MM, digits = 4)
w_out(MM, sprintf("gyr142-p41-mm_DATA_%s.csv", DT))
w_out(rbindlist(lapply(AR$arm, function(a) PER[[a]][, .(arm = a, STAND, SITE, O_M, O_MM, P_MM, n_sel, n_drop)])), sprintf("gyr142-p41-mm-stands_SERVERONLY_DATA_%s.csv", DT))
robust <- abs(MM[arm == "p38_fit"]$B_MM) <= LIM
writeLines(c("plan_md5=a1aa4b3532f0b3ac9ec30e63a3f7fcec", sprintf("B_MM_p38_fit=%.4f within_limit=%s", MM[arm == "p38_fit"]$B_MM, robust),
  sprintf("PREREG40_rule3_reading=%s", if (robust) "robust to selection" else "not robust to selection"), "reported, not gated; limit unverified (PREREG40)"),
  file.path(O, sprintf("gyr142-p41-mm-verdict_DATA_%s.txt", DT)))
## reported: p38_fit against frozen PREREG31 p28b_small, per relation (Part A outputs must exist)
NB41 <- file.path(J, "assembled/gyr142-p41-ni-by-relation_DATA_2026-10-02.csv"); NB31 <- file.path(P31, "assembled/gyr142-p31-ni-by-relation_DATA_2026-09-30.csv")
if (file.exists(NB41) && file.exists(NB31)) { a41 <- fread(NB41); a31 <- fread(NB31)
  CMP <- merge(a41[, .(relation, p38_fit_flags = cand_flags, p38_fit_worst = cand_worst, qc141_flags = ref_flags, qc141_worst = ref_worst, p38_fit_new = new_flags, p38_fit_ni = ni_ok)],
               a31[, .(relation, p28b_small_flags = cand_flags, p28b_small_worst = cand_worst, p28b_small_new = new_flags, p28b_small_ni = ni_ok, qc141_worst_p31 = ref_worst)], by = "relation")
  w_out(CMP, sprintf("gyr142-p41-vs-p28b_DATA_%s.csv", DT)); print(CMP, digits = 4) } else cat("Part A outputs absent; comparison not written\n")
cat("P41B_ASSEMBLE_DONE\n")

## PREREG39 assembly: decomposition of the TOPHT gate against the field tag dominant cohort on frozen outputs only
## (p19_a0111 = qc141 and p38_fit), screened qc_c fold B. Plan ~/jobs/v142p39/plan/2026-10-02_v142_topht-gate-decomposition_PREREG39.md
## (md5 ba0a48ec). Ladder D0 to D6, deltas, groups, site cluster bootstrap B = 1000 seed 20261002, reproduction stops S1 to S4,
## diagnostics Q1 to Q4, outcome rule, figure. No engine run, no score, no coordinates. No em dashes.
## Revision 2 (r2): revision 1 kept a stand whose observed D5 selection was empty with an observed value of 0 (the runner's empty
## list return); the plan computes D1 to D6 over stands with at least one record on each side. r2 returns NA for an empty selection
## and drops such stands from D5; D6 must have a record on both sides in every stand. Outputs to assembled_r2/; r1 outputs kept.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")   # fold_of, tagok, split_map (scorer code), pred_ht, arm_dirs, P19
suppressMessages({ library(ggplot2); library(patchwork) })
J <- "/home/aaron/jobs/v142p39"; P38 <- "/home/aaron/jobs/v142p38"; FT <- "/home/aaron/jobs/v142p14/in/pass28qc"; DT <- "2026-10-02"; B <- 1000L
PLAN <- file.path(J, "plan/2026-10-02_v142_topht-gate-decomposition_PREREG39.md")
if (unname(tools::md5sum(PLAN)) != "ba0a48ec6d28cba30bb86d4e67f4465c") stop("plan md5 differs")
O <- file.path(J, "assembled_r2"); if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O)
w_out <- function(x, n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f) }
## ---- runner rules, copied from runner_p28_fb.R (0a2b2742) lines 182 to 184, 208 and the mapsp line
RUN <- file.path(P38, "home/runner_p28_fb.R"); if (unname(tools::md5sum(RUN)) != "0a2b27421ee7b25eaab7f4591ce3af97") stop("runner md5 differs")
RL <- readLines(RUN)
eval(parse(text = grep("^sw<-c\\(", RL, value = TRUE))); eval(parse(text = grep("^himp<-function", RL, value = TRUE)))
stopifnot(any(grepl("idx<-which\\(cw<=100\\); if\\(!length\\(idx\\)\\)idx<-1; TOPHT<-mean\\(ifelse\\(is.finite\\(ht\\[o\\]\\[idx\\]\\)", RL)))
acadgy <- names(AGY2SPCD); mapsp_r <- function(s) { s <- toupper(s); ifelse(s %in% acadgy, s, ifelse(s %in% sw, "OS", "OH")) }
top_sel <- function(sp, dbh, ht, expf, mindbh) {           # returns selected positions in input order of the live records
  live <- which(is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0); if (!length(live)) return(integer(0))
  o <- live[order(-dbh[live])]; cw <- cumsum(expf[o]); idx <- which(cw <= 100); if (!length(idx)) idx <- 1; o[idx] }
top_val <- function(sp, dbh, ht, expf, mindbh) { s <- top_sel(sp, dbh, ht, expf, mindbh); if (!length(s)) return(NA_real_)
  mean(ifelse(is.finite(ht[s]), ht[s], himp(sp[s], dbh[s]))) }
## ---- inputs and md5s
ARMS <- data.table(arm = c("p19_a0111", "p38_fit"), label = c("qc141", "p38_fit"), qc_afac = c(0.111, 1.242),
  res = c(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"), file.path(P38, "results/p38_fit/gyr_p38_fit_qc_c_results.csv")),
  stn = c(file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"), file.path(P38, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv")),
  home = c(file.path(P19, "home"), file.path(P38, "home")))
FI <- file.path(FT, "bench_gyr_qc_c_tree_init.csv"); FG <- file.path(FT, "bench_gyr_qc_c_tree_t2.csv")
RG <- file.path(P19, "home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_t2.csv")
SS38 <- file.path(P38, "assembled/gyr142-p38-stands-summary_DATA_2026-10-01.csv"); HI38 <- file.path(P38, "assembled/gyr142-p38-hinc_DATA_2026-10-01.csv")
tl <- unlist(lapply(seq_len(nrow(ARMS)), function(i) unlist(lapply(arm_dirs(ARMS$home[i], ARMS$arm[i], "qc_c"), function(d) sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE))))))
inp <- c(ARMS$res, ARMS$stn, FI, FG, RG, SS38, HI38, RUN, "/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R", tl)
mf <- file.path(J, "logs/input_md5_r2.txt"); if (file.exists(mf)) stop("REFUSE ", mf)
writeLines(paste(unname(tools::md5sum(inp)), inp, sep = "  "), mf); cat(sprintf("input md5s: %d files written to logs/input_md5.txt\n", length(inp)))
## ---- S4: field tag t2 frame against run frame t2, every column but TREE
g1 <- fread(FG); g2 <- fread(RG); cc <- setdiff(names(g2), "TREE")
S4 <- nrow(g1) == nrow(g2) && identical(names(g1), names(g2)) && all(sapply(cc, function(k) isTRUE(all.equal(g1[[k]], g2[[k]], tolerance = 0))))
cat(sprintf("S4: field tag and run t2 frames agree on %d columns other than TREE over %d rows: %s\n", length(cc), nrow(g1), S4)); if (!S4) stop("S4 FRAME FAIL")
rm(g1, g2)
## ---- frames and tag link (helper rules)
F0 <- fread(FI)[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
G0 <- fread(FG)[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
F0[, o := frank(-DBH, ties.method = "first"), by = STAND]; setorder(F0, STAND, o); F0[, cw := cumsum(EXPF), by = STAND]; F0[, dom := cw <= 100 | o == 1L]
setorder(F0, STAND, row0); F0[, c("o", "cw") := NULL]
F0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]; G0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]
d1 <- F0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]; d2 <- G0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]
F0[d1, on = .(STAND, TAG), TAG := NA_character_]; G0[d2, on = .(STAND, TAG), TAG := NA_character_]
LK <- merge(F0[!is.na(TAG), .(STAND, TAG, row0)], G0[!is.na(TAG), .(STAND, TAG, row2 = row0)], by = c("STAND", "TAG"))
F0 <- merge(F0, LK[, .(STAND, row0, row2)], by = c("STAND", "row0"), all.x = TRUE); F0[, surv := !is.na(row2)]
G0 <- merge(G0, LK[, .(STAND, row2, linked = TRUE)], by.x = c("STAND", "row0"), by.y = c("STAND", "row2"), all.x = TRUE); G0[is.na(linked), linked := FALSE]
F0[, sp := mapsp(SP)]; M <- split_map(F0)   # helper (scorer) mapsp, as tag_key
## dominant survivor records with their t2 row
DS <- merge(F0[dom == TRUE & surv == TRUE, .(STAND, row0, row2, SP1 = SP, D1 = DBH, HT1 = HT)],
            G0[, .(STAND, row2 = row0, SP2 = SP, D2 = DBH, HT2 = HT)], by = c("STAND", "row2"))
DS[, H1 := fifelse(is.finite(HT1) & HT1 > 0, HT1, NA_real_)][, H2 := fifelse(is.finite(HT2) & HT2 > 0, HT2, NA_real_)]
DS[, Hobs3 := fifelse(is.finite(HT2), HT2, himp(mapsp_r(SP2), D2))][, imp3 := !is.finite(HT2)]
## ---- per arm ladder
rd_all <- function(h, a) { acc <- NULL; for (d in arm_dirs(h, a, "qc_c")) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
SM <- function(x, pcol, ocol) x[, .(P = mean(get(pcol)), Ob = mean(get(ocol)), n = .N), by = .(STAND, SITE)]
PER <- list(); POP <- list(); DIAG <- list(); D0S <- list()
for (i in seq_len(nrow(ARMS))) { a <- ARMS$arm[i]
  r <- fread(ARMS$res[i])[, STAND := as.character(STAND)]; if (anyDuplicated(r$STAND)) stop("dup STAND ", a)
  stn <- fread(ARMS$stn[i])[label == "qc_c" & arm == a][, STAND := as.character(STAND)]
  v <- merge(stn[, .(STAND, cut)], r[RUN_OK == 1, .(STAND, SITE, SMD = SCORE_MINDBH_USED, TOPHT_o, TOPHT_p)], by = "STAND"); v[, fold := fold_of(SITE)]
  pop <- v[cut == FALSE & fold == "B"]; POP[[a]] <- pop; st <- pop$STAND
  P <- rd_all(ARMS$home[i], a)[STAND %in% st]; if (!setequal(unique(P$STAND), st)) stop("prediction stands differ ", a)
  Hp <- pred_ht(arm_dirs(ARMS$home[i], a, "qc_c"), M, st)                                   # STAND, row0, Hp (mean over split parts, ing 0)
  ds <- merge(DS[STAND %in% st], Hp[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE)
  if (anyNA(ds$Hp)) stop("dominant survivor without prediction ", a)
  ds <- merge(ds, pop[, .(STAND, SITE)], by = "STAND")
  ## D0 and D1 records: same species, H1 and H2 measured above 0
  r0 <- ds[SP1 == SP2 & is.finite(H1) & is.finite(H2)]; D0S[[a]] <- r0[, .(Hp = sum(Hp), H2 = sum(H2), n = .N), by = SITE]
  s1 <- SM(r0, "Hp", "H2")
  r2 <- ds[is.finite(H2)]; s2 <- SM(r2, "Hp", "H2")
  s3 <- SM(ds, "Hp", "Hobs3")
  fd <- merge(F0[dom == TRUE & STAND %in% st, .(STAND, row0, SP, DBH)], Hp[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE)
  fd[, Hp4 := fifelse(is.finite(Hp), Hp, himp(mapsp_r(SP), DBH))]; fd <- merge(fd, pop[, .(STAND, SITE)], by = "STAND")
  p4 <- fd[, .(P = mean(Hp4), np = .N), by = .(STAND, SITE)]; s4 <- merge(p4, s3[, .(STAND, Ob, n)], by = "STAND")[, .(STAND, SITE, P, Ob, n = np)]
  smd <- setNames(pop$SMD, pop$STAND)
  tp <- function(x, s) top_val(x$sp, x$dbh, x$ht, x$expf, smd[[s]])
  to <- function(x, s) top_val(mapsp_r(x$SP), x$DBH, x$HT, x$EXPF, smd[[s]])
  G1 <- G0[STAND %in% st]
  s5 <- rbindlist(lapply(st, function(s) data.table(STAND = s, P = tp(P[STAND == s & ing == 0], s), Ob = to(G1[STAND == s & linked == TRUE], s))))
  s6 <- rbindlist(lapply(st, function(s) data.table(STAND = s, P = tp(P[STAND == s], s), Ob = to(G1[STAND == s], s))))
  s5 <- merge(s5, pop[, .(STAND, SITE)], by = "STAND"); s6 <- merge(s6, pop[, .(STAND, SITE)], by = "STAND")
  cat(sprintf("%s: D5 stands without a record on both sides: %s\n", a, paste(s5[!(is.finite(P) & is.finite(Ob))]$STAND, collapse = " ")))
  s5 <- s5[is.finite(P) & is.finite(Ob)]; if (s6[, anyNA(P) || anyNA(Ob)]) stop("D6 stand without a record on both sides")
  ## S1: D6 stand values against results
  ch <- merge(s6, pop[, .(STAND, TOPHT_o, TOPHT_p)], by = "STAND")
  PER[[a]] <- list(s1 = s1, s2 = s2, s3 = s3, s4 = s4, s5 = s5, s6 = s6, S1o = max(abs(ch$Ob - ch$TOPHT_o)), S1p = max(abs(ch$P - ch$TOPHT_p)), n0 = nrow(r0))
  ## diagnostics Q1 to Q4
  oq <- rbindlist(lapply(st, function(s) { x <- G1[STAND == s]; k <- top_sel(mapsp_r(x$SP), x$DBH, x$HT, x$EXPF, smd[[s]]); x[k, .(STAND, SP, DBH, HT, linked, row0)] }))
  oq <- merge(oq, merge(LK, F0[, .(STAND, row0, dom)], by = c("STAND", "row0"))[, .(STAND, row0 = row2, dom1 = dom)], by = c("STAND", "row0"), all.x = TRUE)
  pq <- rbindlist(lapply(st, function(s) { x <- P[STAND == s]; k <- top_sel(x$sp, x$dbh, x$ht, x$expf, smd[[s]]); x[k, .(STAND, tree, ing)] }))
  pq <- merge(pq, merge(M[, .(STAND, tree, row0)], F0[, .(STAND, row0, dom)], by = c("STAND", "row0")), by = c("STAND", "tree"), all.x = TRUE)
  mh <- oq[is.finite(HT) & HT > 0]
  DIAG[[a]] <- data.table(arm = a, item = c("Q1 observed D6 set himp share", "Q1 observed D6 set finite heights at or below 1.3 m", "Q1 observed D6 set records",
      "Q1 observed D3 set himp share", "Q1 observed D3 set finite heights at or below 1.3 m", "Q1 observed D3 set records",
      "Q2 observed D6 set sum himp over sum measured height", "Q2 records", "Q3 observed D6 records that are t1 dom survivors, share",
      "Q3 predicted D6 records that are t1 dom rows with ing 0, share",
      paste("Q4 records per stand", c("D0 D1", "D2", "D3 observed", "D4 predicted"))),
    value = c(mean(!is.finite(oq$HT)), sum(is.finite(oq$HT) & oq$HT <= 1.3), nrow(oq), mean(ds$imp3), sum(is.finite(ds$HT2) & ds$HT2 <= 1.3), nrow(ds),
      sum(himp(mapsp_r(mh$SP), mh$DBH)) / sum(mh$HT), nrow(mh), mean(oq$linked & !is.na(oq$dom1) & oq$dom1), mean(pq$ing == 0 & !is.na(pq$dom) & pq$dom),
      mean(s1$n), mean(s2$n), mean(s3$n), mean(s4$n)))
  cat(sprintf("%s: %d stands on %d sites; S1 worst TOPHT_o %.3g, TOPHT_p %.3g\n", a, nrow(pop), uniqueN(pop$SITE), PER[[a]]$S1o, PER[[a]]$S1p)) }
## ---- point values and bootstrap
bs <- function(x) 100 * (mean(x$P) - mean(x$Ob)) / mean(x$Ob)
d0 <- function(z) 100 * (sum(z$Hp) / sum(z$H2) - 1)
sites <- sort(unique(unlist(lapply(POP, function(p) p$SITE)))); ns <- length(sites)
set.seed(20261002); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B); W <- apply(IDX, 2, tabulate, nbins = ns)   # ns by B site multiplicities
bw <- function(x) { w <- W[match(x$SITE, sites), , drop = FALSE]; 100 * (colSums(w * x$P) - colSums(w * x$Ob)) / colSums(w * x$Ob) }
bw0 <- function(z) { w <- W[match(z$SITE, sites), , drop = FALSE]; 100 * (colSums(w * z$Hp) / colSums(w * z$H2) - 1) }
LAD <- list(); BOOT <- list()
for (a in ARMS$arm) { p <- PER[[a]]
  pt <- c(D0 = d0(D0S[[a]]), D1 = bs(p$s1), D2 = bs(p$s2), D3 = bs(p$s3), D4 = bs(p$s4), D5 = bs(p$s5), D6 = bs(p$s6))
  bm <- cbind(D0 = bw0(D0S[[a]]), D1 = bw(p$s1), D2 = bw(p$s2), D3 = bw(p$s3), D4 = bw(p$s4), D5 = bw(p$s5), D6 = bw(p$s6))
  LAD[[a]] <- pt; BOOT[[a]] <- bm }
qq <- function(x) unname(quantile(x, c(.025, .975), na.rm = TRUE))
STEP <- c(D0 = "dominant cohort metric (pooled tree ratio)", D1 = "aggregation: stand means, bias percent", D2 = "tag record rules (species match, measured H1)",
  D3 = "observed height handling (himp where t2 height missing)", D4 = "fate: every t1 dominant row predicted", D5 = "t2 rank selection to 100 stems ha⁻¹, mindbh, record unit",
  D6 = "recruits and unlinked rows (published TOPHT)")
LT <- rbindlist(lapply(ARMS$arm, function(a) { p <- PER[[a]]; nst <- c(nrow(D0S[[a]]), nrow(p$s1), nrow(p$s2), nrow(p$s3), nrow(p$s4), nrow(p$s5), nrow(p$s6))
  data.table(arm = a, label = ARMS[arm == a]$label, qc_afac = ARMS[arm == a]$qc_afac, rung = names(LAD[[a]]), step = STEP[names(LAD[[a]])], value = unname(LAD[[a]]),
    lo = apply(BOOT[[a]], 2, function(x) qq(x)[1]), hi = apply(BOOT[[a]], 2, function(x) qq(x)[2]), units = c("sites", rep("stands", 6)), n_units = nst,
    records = c(p$n0, sum(p$s1$n), sum(p$s2$n), sum(p$s3$n), sum(p$s4$n), NA, NA)) }))
DL <- rbindlist(lapply(ARMS$arm, function(a) { v <- LAD[[a]]; bm <- BOOT[[a]]; dm <- bm[, -1] - bm[, -7]
  data.table(arm = a, delta = paste0("delta_", 1:6), rungs = paste0(names(v)[-1], " minus ", names(v)[-7]), value = unname(v[-1] - v[-7]),
    lo = apply(dm, 2, function(x) qq(x)[1]), hi = apply(dm, 2, function(x) qq(x)[2])) }))
GRP <- rbindlist(lapply(ARMS$arm, function(a) { bm <- BOOT[[a]]; v <- LAD[[a]]
  gm <- cbind(G1 = bm[, "D2"] - bm[, "D0"], G2 = bm[, "D3"] - bm[, "D2"], G3 = bm[, "D4"] - bm[, "D3"], G4 = bm[, "D5"] - bm[, "D4"], G5 = bm[, "D6"] - bm[, "D5"], gap = bm[, "D6"] - bm[, "D0"])
  gv <- c(G1 = v[["D2"]] - v[["D0"]], G2 = v[["D3"]] - v[["D2"]], G3 = v[["D4"]] - v[["D3"]], G4 = v[["D5"]] - v[["D4"]], G5 = v[["D6"]] - v[["D5"]], gap = v[["D6"]] - v[["D0"]])
  data.table(arm = a, group = names(gv), name = c("aggregation and record rules", "observed height handling", "fate", "t2 rank selection", "recruits and unlinked rows", "gap D6 minus D0"),
    value = unname(gv), share = unname(gv / gv[["gap"]]), lo = apply(gm, 2, function(x) qq(x)[1]), hi = apply(gm, 2, function(x) qq(x)[2])) }))
## ---- reproduction stops S1 to S3
ss <- fread(SS38)[set == "qc_c" & pop == "screened B"]; hi <- fread(HI38)[tagkey == "field tag" & set == "qc_c" & fold == "B" & group == "dominant"]
REP <- rbindlist(lapply(ARMS$arm, function(a) { p <- PER[[a]]; s <- ss[arm == a]; h <- hi[arm == a]
  data.table(arm = a, check = c("S1 stand TOPHT_o worst", "S1 stand TOPHT_p worst", "S1 D6 against PREREG38 topht_bias_pct", "S2 D0 against PREREG38 hinc level", "S2 D0 records against hinc trees", "S3 stands against PREREG38 stands"),
    worst = c(p$S1o, p$S1p, abs(LAD[[a]][["D6"]] - s$topht_bias_pct), abs(LAD[[a]][["D0"]] - 100 * (h$level_t2 - 1)), abs(p$n0 - h$trees), abs(nrow(POP[[a]]) - s$stands))) }))
REP[, pass := worst <= 1e-9]; print(REP)
REP <- rbind(REP, data.table(arm = "both", check = "S4 field tag t2 frame against run frame t2 (columns other than TREE)", worst = 0, pass = S4))
if (!all(REP$pass)) { w_out(REP, sprintf("gyr142-p39-repro_DATA_%s.csv", DT)); stop("REPRODUCTION STOP FAILED: harness failure, no reading") }
## ---- outcome rule
outc <- function(a) { g <- GRP[arm == a & group != "gap"]; q <- g[share >= 0.5 & (lo > 0 | hi < 0)]
  if (nrow(q) == 1) sprintf("dominant source %s (%s), %.2f points of a %.2f point gap (share %.3f, interval %.2f to %.2f)", q$group, q$name, q$value, GRP[arm == a & group == "gap"]$value, q$share, q$lo, q$hi) else
  sprintf("diffuse; groups at or above 0.25 of the gap: %s", paste(g[share >= 0.25]$group, collapse = ", ")) }
o38 <- outc("p38_fit"); o141 <- outc("p19_a0111")
key <- function(s) sub("^(dominant source G[0-9]|diffuse).*", "\\1", s); cons <- key(o38) == key(o141)
cat("OUTCOME p38_fit:", o38, "\nOUTCOME qc141:", o141, "\nconsistent across arms:", cons, "\n")
AD <- merge(LT[arm == "p38_fit", .(rung, p38 = value)], LT[arm == "p19_a0111", .(rung, q141 = value)], by = "rung")[, arm_diff := p38 - q141]
DIAG <- rbindlist(DIAG)
w_out(LT, sprintf("gyr142-p39-ladder_DATA_%s.csv", DT)); w_out(DL, sprintf("gyr142-p39-deltas_DATA_%s.csv", DT)); w_out(GRP, sprintf("gyr142-p39-groups_DATA_%s.csv", DT))
w_out(REP, sprintf("gyr142-p39-repro_DATA_%s.csv", DT)); w_out(DIAG, sprintf("gyr142-p39-diag_DATA_%s.csv", DT)); w_out(AD, sprintf("gyr142-p39-armdiff_DATA_%s.csv", DT))
STS <- rbindlist(lapply(ARMS$arm, function(a) { p <- PER[[a]]; rbindlist(lapply(c("s1", "s2", "s3", "s4", "s5", "s6"), function(k) p[[k]][, .(arm = a, rung = sub("s", "D", k), STAND, SITE, P, Ob)])) }))
w_out(STS, sprintf("gyr142-p39-stands_SERVERONLY_DATA_%s.csv", DT))
writeLines(c("plan_md5=ba0a48ec6d28cba30bb86d4e67f4465c", paste0("outcome_p38_fit=", o38), paste0("outcome_qc141=", o141), paste0("consistent_across_arms=", cons),
  "consequence=acted on only through a separate pre-registration; 14.1 keeps 0.111; no PREREG38 verdict changes"), file.path(O, sprintf("gyr142-p39-verdict_DATA_%s.txt", DT)))
## ---- figure
dir.create(file.path(J, "figs"), showWarnings = FALSE)
FD <- rbind(LT[, .(panel = "a", label, x = rung, value, lo, hi)], merge(DL, ARMS[, .(arm, label)], by = "arm")[, .(panel = "b", label, x = delta, value, lo, hi)])
fwrite(FD, file.path(J, "figs", sprintf("gyr142-p39-topht-ladder-r2_DATA_%s.csv", DT)))
th <- theme_classic(base_size = 9) + theme(legend.position = "bottom", plot.tag = element_text(face = "bold"))
cols <- c(qc141 = "grey35", p38_fit = "#b5452b"); pd <- position_dodge(width = 0.5)
fa <- ggplot(FD[panel == "a"], aes(x, value, colour = label, group = label)) + geom_hline(yintercept = 0, linetype = 2, colour = "grey50") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.25, position = pd) + geom_point(size = 1.8, position = pd) + geom_line(position = pd, linewidth = 0.3) +
  scale_colour_manual(values = cols) + labs(x = "Rung", y = "Bias (%)", colour = NULL) + th
fb <- ggplot(FD[panel == "b"], aes(x, value, fill = label)) + geom_hline(yintercept = 0, colour = "grey50") +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) + geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.2, position = position_dodge(width = 0.7)) +
  scale_fill_manual(values = cols) + scale_x_discrete(labels = c(delta_1 = "D1-D0\naggregation", delta_2 = "D2-D1\nrecord rules", delta_3 = "D3-D2\nobs. height",
  delta_4 = "D4-D3\nfate", delta_5 = "D5-D4\nt2 rank", delta_6 = "D6-D5\nrecruits")) + labs(x = NULL, y = "Step contribution (points)", fill = NULL) + th
ggsave(file.path(J, "figs", sprintf("gyr142-p39-topht-ladder-r2_%s.png", DT)), fa + fb + plot_layout(widths = c(1, 1.3)) + plot_annotation(tag_levels = "a"),
  width = 180, height = 110, units = "mm", dpi = 300)
print(LT[, .(arm, rung, value, lo, hi, n_units)], digits = 4); print(GRP, digits = 4); print(DIAG, digits = 4)
cat("P39_ASSEMBLE_DONE\n")

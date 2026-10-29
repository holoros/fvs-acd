## PREREG33 F9 re-derivation: copy of the PREREG28b re-derivation (md5 3227f525) with p33_dyn added and the comparison read
## from the PREREG33 benchmark assembly. No code shared with the assembly. No coordinates. No em dashes.
## PREREG28b F9 re-derivation: copy of the PREREG28 re-derivation (md5 2dd53738) with p28b_small added and the comparison read
## from the PREREG28b assembly. No code shared with the assembly. No coordinates. No em dashes.
## PREREG28 F9 re-derivation, written separately from the helper and the assembly (no source(), no shared code): its own fold
## code (openssl md5 of SITE), its own tag match, its own frame row to runner tree map (softwood tree id equals frame row and
## DBH must agree; each hardwood frame row claims the next appended split parts of equal DBH until their EXPF sums to the
## frame EXPF), its own retry replacement. Screened qc_c fold B quantities for p19_a0111, p23_a1061, p28_g0, p28_cand, compared
## with the PREREG28 assembled tables. No coordinates. No em dashes.
suppressMessages({ library(data.table); library(openssl) })
P19 <- "/home/aaron/jobs/v142p19"; P23 <- "/home/aaron/jobs/v142p23"; J <- "/home/aaron/jobs/v142p28"; JB <- "/home/aaron/jobs/v142p28b"; JC <- "/home/aaron/jobs/v142p33"
FRM <- file.path(P19, "home/magplot/verify/gydbreg20260916/frames")
cutt <- fread(file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))[label == "qc_c" & arm == "p19_a0111"]
cutt[, STAND := as.character(STAND)]
rs0 <- fread(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"))[, STAND := as.character(STAND)][RUN_OK == 1]
foldB <- function(site) { h <- as.character(md5(as.character(site))); as.integer(strtoi(substring(h, 1, 1), 16L)) %% 2L == 1L }
rs0[, isB := foldB(SITE)]
SB <- rs0[isB == TRUE & STAND %in% cutt[cut == FALSE]$STAND, .(STAND, SITE)]
cat(sprintf("screened qc_c fold B: %d stands, %d sites\n", nrow(SB), uniqueN(SB$SITE)))
FI <- fread(file.path(FRM, "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)]; FI[, row := seq_len(.N), by = STAND]; FI <- FI[STAND %in% SB$STAND]
F2 <- fread(file.path(FRM, "bench_gyr_qc_c_tree_t2.csv"))[, STAND := as.character(STAND)][STAND %in% SB$STAND]
good <- function(t) !is.na(t) & t < 9e6
a1 <- FI[good(TREE)]; a1 <- a1[a1[, .I[.N == 1], by = .(STAND, TREE)]$V1]
a2 <- F2[good(TREE)]; a2 <- a2[a2[, .I[.N == 1], by = .(STAND, TREE)]$V1]
TG <- merge(a1[, .(STAND, TREE, row, s1 = SP, D1 = DBH, H1 = HT)], a2[, .(STAND, TREE, s2 = SP, H2 = HT)], by = c("STAND", "TREE"))
TG <- TG[s1 == s2 & is.finite(H1) & H1 > 0 & is.finite(H2) & H2 > 0]
## dominant cohort at t1 (largest DBH first, cumulative EXPF up to 100 stems/ha, the largest always in)
setorder(FI, STAND, -DBH, row); FI[, cum := cumsum(EXPF), by = STAND]; FI[, first := seq_len(.N) == 1L, by = STAND]
TG <- merge(TG, FI[, .(STAND, row, dom = cum <= 100 | first)], by = c("STAND", "row")); setorder(FI, STAND, row)
cat(sprintf("tag trees %d on %d sites, dominant %d\n", nrow(TG), uniqueN(merge(TG, SB, by = "STAND")$SITE), sum(TG$dom)))
readdirs <- function(home, arm, pat) { acc <- NULL
  for (d in c(file.path(home, "out", arm, "qc_c"), file.path(home, paste0("out_retry_a", 1:3), arm, "qc_c"))) {
    fs <- list.files(d, pat, full.names = TRUE); if (length(fs) == 0) next
    x <- rbindlist(lapply(fs, fread)); x[, STAND := as.character(STAND)]
    if (!is.null(acc)) acc <- acc[!(STAND %in% x$STAND)]; acc <- rbind(acc, x) }
  acc[STAND %in% SB$STAND] }
map_pred <- function(home, arm) {
  s1 <- readdirs(home, arm, "_t1_split_tree[.]csv$"); p2 <- readdirs(home, arm, "_pred_t2_tree[.]csv$")[ing == 0]
  M <- vector("list", nrow(SB)); i <- 0L
  for (st in SB$STAND) { i <- i + 1L; f <- FI[STAND == st]; a <- s1[STAND == st][order(tree)]; n <- nrow(f)
    lo <- a[tree <= n]; up <- a[tree > n]
    if (nrow(lo) && max(abs(lo$dbh - f$DBH[lo$tree])) > 1e-6) stop("softwood DBH disagrees in ", st)
    rest <- f[!(row %in% lo$tree)]; part <- integer(nrow(up)); k <- 1L
    for (q in seq_len(nrow(rest))) { tot <- 0
      while (k <= nrow(up) && abs(up$dbh[k] - rest$DBH[q]) < 1e-6 && tot < rest$EXPF[q] - 1e-6 * max(1, rest$EXPF[q])) { part[k] <- rest$row[q]; tot <- tot + up$expf[k]; k <- k + 1L }
      if (abs(tot - rest$EXPF[q]) > 1e-6 * max(1, rest$EXPF[q])) stop("split parts do not sum in ", st, " row ", rest$row[q]) }
    if (k <= nrow(up)) stop("unclaimed split parts in ", st)
    M[[i]] <- data.table(STAND = st, tree = c(lo$tree, up$tree), row = c(lo$tree, part)) }
  M <- rbindlist(M); Z <- merge(M, p2[, .(STAND, tree, ht, iv)], by = c("STAND", "tree"))
  Z[, .(Hp = mean(ht), iv = iv[1]), by = .(STAND, row)] }
ARMS <- list(p19_a0111 = file.path(P19, "home"), p23_a1061 = file.path(P23, "home"), p28_g0 = file.path(J, "home"), p28_cand = file.path(J, "home"), p28b_small = file.path(JB, "home"), p33_dyn = file.path(JC, "home"))
out <- list()
for (a in names(ARMS)) { Z <- merge(TG, map_pred(ARMS[[a]], a), by = c("STAND", "row"))
  if (nrow(Z) != nrow(TG)) stop("tag records without prediction in ", a)
  Z[, `:=`(o = (H2 - H1) / iv, p = (Hp - H1) / iv)]; Z[, g := ifelse(D1 < 12.7, "below 12.7", ifelse(D1 < 25, "12.7 to 25", "25 and over"))]
  out[[a]] <- rbind(Z[, .(arm = a, group = "overall", trees = .N, ratio = sum(p) / sum(o), bias = mean(p - o), level = sum(Hp) / sum(H2))],
    Z[, .(arm = a, trees = .N, ratio = sum(p) / sum(o), bias = mean(p - o), level = sum(Hp) / sum(H2)), by = .(group = g)],
    Z[dom == TRUE, .(arm = a, group = "dominant", trees = .N, ratio = sum(p) / sum(o), bias = mean(p - o), level = sum(Hp) / sum(H2))]) }
V <- rbindlist(out)
## stand level: TOPHT, basal area, stems from results; C1 %RMSE from the scorer stand tables
root <- c(p19_a0111 = P19, p23_a1061 = P23, p28_g0 = J, p28_cand = J, p28b_small = JB, p33_dyn = JC)
stt <- c(p19_a0111 = file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"), p23_a1061 = file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"),
         p28_g0 = file.path(J, "tables/gyr142-p28-fb-stands_DATA_2026-09-27.csv"), p28_cand = file.path(J, "tables/gyr142-p28-fb-stands_DATA_2026-09-27.csv"), p28b_small = file.path(JB, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), p33_dyn = file.path(JC, "tables/gyr142-p33-fb-stands_DATA_2026-09-27.csv"))
SL <- rbindlist(lapply(names(root), function(a) { r <- fread(file.path(root[a], "results", a, sprintf("gyr_%s_qc_c_results.csv", a)))[, STAND := as.character(STAND)][RUN_OK == 1]
  r <- r[foldB(SITE)]; tb <- fread(stt[a])[label == "qc_c" & arm == a & cut == FALSE][, STAND := as.character(STAND)]; r <- r[STAND %in% tb$STAND]; v <- merge(r, tb, by = "STAND")
  n <- function(ba, q) ba / (pi * q^2 / 40000); ok <- is.finite(n(r$BA_o, r$QMD_o)) & is.finite(n(r$BA_p, r$QMD_p))
  data.table(arm = a, stands = nrow(r), topht_bias_pct = 100 * (mean(r$TOPHT_p, na.rm = TRUE) / mean(r$TOPHT_o, na.rm = TRUE) - 1),
    ba_ratio = sum(r$BA_p[ok]) / sum(r$BA_o[ok]), stems_ratio = sum(n(r$BA_p, r$QMD_p)[ok]) / sum(n(r$BA_o, r$QMD_o)[ok]),
    C1_rmse_pct = 100 * sqrt(mean((v$V_ph - v$V_oh)^2)) / mean(v$V_oh)) }))
print(V, digits = 6); print(SL, digits = 6)
fwrite(V, file.path(JC, "verify_20261001/p33_rederive_hinc_DATA_2026-10-01.csv")); fwrite(SL, file.path(JC, "verify_20261001/p33_rederive_stand_DATA_2026-10-01.csv"))
## comparison with the assembly
HT <- fread(file.path(JC, "assembled/bench/gyr142-p33-hinc_DATA_2026-10-01.csv"))[set == "qc_c" & fold == "B"]
C <- merge(V, HT[, .(arm, group, trees_a = trees, ratio_a = ratio, bias_a = bias_m_yr, level_a = level_t2)], by = c("arm", "group"))
ST <- fread(file.path(JC, "assembled/bench/gyr142-p33-stands-summary_DATA_2026-10-01.csv"))[set == "qc_c" & pop == "screened B"]
C2 <- merge(SL, ST[, .(arm, stands_a = stands, topht_a = topht_bias_pct, ba_a = ba_ratio, stems_a = stems_ratio, rmse_a = C1_rmse_pct)], by = "arm")
cat(sprintf("height rows compared %d: trees differ %d, worst |ratio| %.3g, |bias| %.3g, |level| %.3g\n", nrow(C), C[trees != trees_a, .N], C[, max(abs(ratio - ratio_a))], C[, max(abs(bias - bias_a))], C[, max(abs(level - level_a))]))
cat(sprintf("stand rows compared %d: stands differ %d, worst |TOPHT| %.3g, |BA| %.3g, |stems| %.3g, |RMSE| %.3g\n", nrow(C2), C2[stands != stands_a, .N], C2[, max(abs(topht_bias_pct - topht_a))], C2[, max(abs(ba_ratio - ba_a))], C2[, max(abs(stems_ratio - stems_a))], C2[, max(abs(C1_rmse_pct - rmse_a))]))
cat(sprintf("p33_dyn re-derived: TOPHT %+.3f percent, pooled ratio %.4f, C1 %%RMSE %.3f\n", SL[arm == "p33_dyn"]$topht_bias_pct, V[arm == "p33_dyn" & group == "overall"]$ratio, SL[arm == "p33_dyn"]$C1_rmse_pct))
cat("P33_BENCH_REDERIVE_DONE\n")

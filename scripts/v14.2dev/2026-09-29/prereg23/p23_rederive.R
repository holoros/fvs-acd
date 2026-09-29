## PREREG23 F9 re-derivation, independent of the helper and the assembly: its own fold code, its own tag match,
## and its own
## hardwood split grouping (consecutive split records of equal species and diameter whose expansion factors sum to the frame
## record), then the gate quantities for 0.111 (frozen) and 1.061 (new) on screened qc_c fold B. No coordinates. No em dashes.
suppressMessages({ library(data.table); library(digest) })
P19 <- "/home/aaron/jobs/v142p19"; J <- "/home/aaron/jobs/v142p23"
FR <- file.path(P19, "home/magplot/verify/gydbreg20260916/frames")
SW <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
st <- fread(file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))[label == "qc_c" & arm == "p19_a0111", .(STAND = as.character(STAND), cut)]
r0 <- fread(file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"))[RUN_OK == 1, .(STAND = as.character(STAND), SITE, Y1, Y2)]
r0[, fd := ifelse(strtoi(substr(sapply(SITE, digest, algo = "md5", serialize = FALSE), 1, 1), 16L) %% 2 == 0, "A", "B")]
SB <- merge(r0, st, by = "STAND")[fd == "B" & cut == FALSE]
cat(sprintf("screened fold B: %d stands on %d sites\n", nrow(SB), uniqueN(SB$SITE)))
I <- fread(file.path(FR, "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)][, r := 1:.N, by = STAND][STAND %in% SB$STAND]
T2 <- fread(file.path(FR, "bench_gyr_qc_c_tree_t2.csv"))[, STAND := as.character(STAND)][STAND %in% SB$STAND]
## tag match: keep keys unique at both ends, same species, heights measured at both ends
u1 <- I[is.finite(TREE) & TREE < 9e6][, n := .N, by = .(STAND, TREE)][n == 1]; u2 <- T2[is.finite(TREE) & TREE < 9e6][, n := .N, by = .(STAND, TREE)][n == 1]
X <- merge(u1[, .(STAND, TREE, r, SP, D1 = DBH, H1 = HT, EXPF)], u2[, .(STAND, TREE, SP2 = SP, H2 = HT)], by = c("STAND", "TREE"))[SP == SP2 & H1 > 0 & H2 > 0 & is.finite(H1) & is.finite(H2)]
## dominant cohort at t1: cumulative EXPF by decreasing DBH up to 100, always the largest tree
I[, rk := frank(-DBH, ties.method = "first"), by = STAND]; I <- I[order(STAND, rk)][, dom := cumsum(EXPF) <= 100 | rk == 1, by = STAND]
X <- merge(X, I[, .(STAND, r, dom)], by = c("STAND", "r"))
## map frame rows to runner trees through the t1 split list: softwood tree == row; hardwood by sequential grouping
pmap <- function(arm_home, arm) { d <- file.path(arm_home, "out", arm, "qc_c")
  t1 <- rbindlist(lapply(list.files(d, "_t1_split_tree\\.csv$", full.names = TRUE), fread))[, STAND := as.character(STAND)][STAND %in% SB$STAND]
  p2 <- rbindlist(lapply(list.files(d, "_pred_t2_tree\\.csv$", full.names = TRUE), fread))[, STAND := as.character(STAND)][STAND %in% SB$STAND & ing == 0]
  out <- list()
  for (s in unique(SB$STAND)) { f <- I[STAND == s][order(r)]; a <- t1[STAND == s][order(tree)]; n0 <- nrow(f)
    sw <- a[tree <= n0]; hw <- a[tree > n0];
    ids <- data.table(tree = sw$tree, r = sw$tree)
    hwrows <- f[!(r %in% sw$tree)]; j <- 1L; g <- 0L; acc <- 0
    if (nrow(hw)) for (k in seq_len(nrow(hw))) { if (acc == 0) { g <- g + 1L; tgt <- hwrows$EXPF[g] }
      ids <- rbind(ids, data.table(tree = hw$tree[k], r = hwrows$r[g])); acc <- acc + hw$expf[k]
      if (abs(acc - tgt) < 1e-6 * max(1, tgt)) acc <- 0 }
    if (nrow(hw) && (g != nrow(hwrows) || acc != 0)) stop("split grouping failed in ", s)
    out[[s]] <- merge(ids[, STAND := s], p2[STAND == s, .(STAND, tree, ht, iv)], by = c("STAND", "tree")) }
  rbindlist(out)[, .(Hp = mean(ht), iv = iv[1]), by = .(STAND, r)] }
res <- list()
for (A in list(c(file.path(P19, "home"), "p19_a0111", "0.111"), c(file.path(J, "home"), "p23_a1061", "1.061"), c(file.path(J, "home"), "p23_a0111", "0.111 rerun"))) {
  P <- pmap(A[1], A[2]); Z <- merge(X, P, by = c("STAND", "r")); Z[, `:=`(o = (H2 - H1) / iv, p = (Hp - H1) / iv)]
  Z[, cl := fifelse(D1 < 12.7, "below 12.7", fifelse(D1 < 25, "12.7 to 25", "25 and over"))]
  res[[A[2]]] <- rbind(Z[, .(arm = A[3], group = "overall", trees = .N, ratio = sum(p) / sum(o), bias = mean(p - o), level = sum(Hp) / sum(H2))],
    Z[, .(arm = A[3], trees = .N, ratio = sum(p) / sum(o), bias = mean(p - o), level = sum(Hp) / sum(H2)), by = .(group = cl)],
    Z[dom == TRUE, .(arm = A[3], group = "dominant", trees = .N, ratio = sum(p) / sum(o), bias = mean(p - o), level = sum(Hp) / sum(H2))], fill = TRUE) }
H <- rbindlist(res, use.names = TRUE)
## stand level: C1 volume, basal area, stems, TOPHT on screened fold B
stl <- function(root, arm, stf) { S <- fread(stf)[label == "qc_c" & arm == ..arm]; S[, STAND := as.character(STAND)]
  R <- fread(file.path(root, "results", arm, sprintf("gyr_%s_qc_c_results.csv", arm)))[, STAND := as.character(STAND)]
  v <- merge(S[STAND %in% SB$STAND], R, by = "STAND"); tp <- function(b, q) b / (pi / 40000 * q^2)
  v[, .(arm, stands = .N, C1 = sum(V_ph) / sum(V_oh), rmse = 100 * sqrt(mean((V_ph - V_oh)^2)) / mean(V_oh), ba = sum(BA_p) / sum(BA_o),
        stems = sum(tp(BA_p, QMD_p)) / sum(tp(BA_o, QMD_o)), topht = 100 * (mean(TOPHT_p) - mean(TOPHT_o)) / mean(TOPHT_o))] }
V <- rbind(stl(P19, "p19_a0111", file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")), stl(J, "p23_a1061", file.path(J, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv")))
print(H, digits = 5); print(V, digits = 6)
fwrite(H, "p23_rederive_hinc_DATA_2026-09-29.csv"); fwrite(V, "p23_rederive_stand_DATA_2026-09-29.csv"); cat("REDERIVE_DONE\n")

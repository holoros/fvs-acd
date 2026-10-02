## PREREG38 independent F9 verifier. Written from the plan alone. No coordinates read. No em dashes.
suppressMessages({ library(data.table); library(digest) })
J <- "/home/aaron/jobs"; P38 <- file.path(J, "v142p38"); V <- file.path(P38, "verify_20261001")
DRY <- Sys.getenv("DRY") == "1"
OUTC <- file.path(V, "p38_verify_DATA_2026-10-01.csv")
if (!DRY && file.exists(OUTC)) stop("refuse to overwrite ", OUTC)
PLAN <- file.path(P38, "plan/2026-10-01_v142_qc-anchor-fieldtag-refit_PREREG38.md")
stopifnot(unname(tools::md5sum(PLAN)) == "69223abd43fc3f2eff97f24beda0aac8")
cat("plan md5 ok\n")
## helper sourced only for split_map, mapsp, fold_of (file conventions)
source(file.path(P38, "scripts/2026-09-29_v142_p23_hkey.R"))
FRR <- file.path(J, "v142p19/home/magplot/verify/gydbreg20260916/frames"); FRT <- file.path(J, "v142p14/in/pass28qc")
cols <- c("STAND", "TREE", "SP", "DBH", "HT", "EXPF")
rd <- function(d, w) { x <- fread(file.path(d, sprintf("bench_gyr_qc_c_tree_%s.csv", w)), select = cols); x[, STAND := as.character(STAND)]; x[, row0 := seq_len(.N), by = STAND]; x }
R1 <- rd(FRR, "init"); T1 <- rd(FRT, "init"); R2 <- rd(FRR, "t2"); T2 <- rd(FRT, "t2")
for (cc in c("STAND", "SP", "DBH", "HT", "EXPF")) { stopifnot(identical(R1[[cc]], T1[[cc]]), identical(R2[[cc]], T2[[cc]])) }
cat("run and field tag frames agree on STAND SP DBH HT EXPF:", nrow(R1), nrow(R2), "\n")
## population
r0 <- fread(file.path(J, "v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"), select = c("STAND", "SITE", "RUN_OK"))[, STAND := as.character(STAND)]
stopifnot(!anyDuplicated(r0$STAND))
cu <- fread(file.path(J, "v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))[label == "qc_c" & arm == "p19_a0111", .(STAND = as.character(STAND), cut = as.character(cut))]
pop <- merge(r0[RUN_OK == 1], cu, by = "STAND", all.x = TRUE); stopifnot(!anyNA(pop$cut))
pop <- pop[cut == "FALSE"]; pop[, fold := fold_of(SITE)]
cat("population stands RUN_OK==1:", sum(r0$RUN_OK == 1), "screened:", nrow(pop), "fold A:", sum(pop$fold == "A"), "fold B:", sum(pop$fold == "B"), "\n")
## field tag survivors (own code)
okt <- function(t) is.finite(t) & t < 9e6
a1 <- T1[okt(TREE), .(STAND, TAG = TREE, row0, SP1 = SP, D1 = DBH, H1 = HT)]
a2 <- T2[okt(TREE), .(STAND, TAG = TREE, SP2 = SP, H2 = HT)]
a1 <- a1[!a1[, .N, by = .(STAND, TAG)][N > 1], on = .(STAND, TAG)]
a2 <- a2[!a2[, .N, by = .(STAND, TAG)][N > 1], on = .(STAND, TAG)]
K <- merge(a1, a2, by = c("STAND", "TAG"))[SP1 == SP2 & is.finite(H1) & H1 > 0 & is.finite(H2) & H2 > 0]
D <- copy(R1); D[, o := frank(-DBH, ties.method = "first"), by = STAND]; setorder(D, STAND, o)
D[, cw := cumsum(EXPF), by = STAND]; D[, dom := cw <= 100 | o == 1L]
K <- merge(K, D[, .(STAND, row0, dom)], by = c("STAND", "row0"))
K <- merge(K, pop[, .(STAND, fold)], by = "STAND")
K[, cls := fifelse(D1 < 12.7, "lt12.7", fifelse(D1 < 25, "12.7to25", "ge25"))]
out <- list(); add <- function(item, arm, value) out[[length(out) + 1L]] <<- data.table(item = item, arm = arm, value = value)
add("tag_records_foldA", "fieldtag", K[fold == "A", .N]); add("tag_records_foldB", "fieldtag", K[fold == "B", .N])
add("tag_sites_foldB", "fieldtag", uniqueN(pop[fold == "B" & STAND %in% K$STAND, SITE]))
cat("field tag records fold A:", K[fold == "A", .N], "fold B:", K[fold == "B", .N], "\n")
## split map on run frame
F0 <- copy(R1); F0[, sp := mapsp(SP)]; M <- split_map(F0)
pred_of <- function(home, arm, set = "qc_c") {
  dirs <- c(file.path(home, "out", arm, set), file.path(home, sprintf("out_retry_a%d", 1:3), arm, set)); acc <- NULL
  for (d in dirs) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
    cat("  pred dir", d, length(fs), "files\n")
    x <- rbindlist(lapply(fs, fread, select = c("STAND", "iv", "tree", "ht", "dbh", "expf", "ing")))[, STAND := as.character(STAND)]
    if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }
  acc }
hgt <- function(home, arm) {
  P <- pred_of(home, arm)[ing == 0 & STAND %in% pop$STAND]
  stopifnot(!anyDuplicated(P[, .(STAND, tree)]))
  P <- merge(P, M[, .(STAND, tree, row0)], by = c("STAND", "tree"))
  H <- P[, .(Hp = mean(ht), iv = iv[1], niv = uniqueN(iv)), by = .(STAND, row0)]; stopifnot(all(H$niv == 1))
  X <- merge(K[fold == "B"], H, by = c("STAND", "row0"))
  cat(arm, "fold B records with prediction:", nrow(X), "of", K[fold == "B", .N], "\n")
  X[, `:=`(io = (H2 - H1) / iv, ip = (Hp - H1) / iv)]
  add("hinc_n_foldB", arm, nrow(X))
  add("hinc_ratio", arm, sum(X$ip) / sum(X$io))
  for (cl in c("lt12.7", "12.7to25", "ge25")) add(paste0("hinc_bias_", cl), arm, X[cls == cl, (sum(ip) - sum(io)) / .N])
  add("dom_level", arm, X[dom == TRUE, sum(Hp) / sum(H2)]); add("dom_n", arm, X[dom == TRUE, .N]) }
ARMS <- list(p38_fit = c(file.path(J, "v142p38/home"), "p38_fit"), p19_a0111 = c(file.path(J, "v142p19/home"), "p19_a0111"),
             p28b_small = c(file.path(J, "v142p28b/home"), "p28b_small"), p23_a1061 = c(file.path(J, "v142p23/home"), "p23_a1061"))
if (DRY) ARMS$p38_fit <- NULL
for (a in names(ARMS)) hgt(ARMS[[a]][1], ARMS[[a]][2])
## stand level
RES <- list(p38_fit = file.path(J, "v142p38/results/p38_fit/gyr_p38_fit_qc_c_results.csv"),
            p19_a0111 = file.path(J, "v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"),
            p23_a1061 = file.path(J, "v142p23/results/p23_a1061/gyr_p23_a1061_qc_c_results.csv"))
TAB <- list(p38_fit = file.path(J, "v142p38/tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"),
            p19_a0111 = file.path(J, "v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
            p23_a1061 = file.path(J, "v142p23/tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"))
if (DRY) { RES$p38_fit <- NULL; TAB$p38_fit <- NULL }
for (a in names(RES)) {
  r <- fread(RES[[a]], select = c("STAND", "RUN_OK", "TOPHT_o", "TOPHT_p", "BA_o", "BA_p", "QMD_o", "QMD_p"))[, STAND := as.character(STAND)]
  stopifnot(!anyDuplicated(r$STAND))
  if (a == "p38_fit") { add("K1_runok_not1_qc_c_all", a, sum(r$RUN_OK != 1 | is.na(r$RUN_OK))) }
  s <- r[RUN_OK == 1 & STAND %in% pop[fold == "B", STAND]]
  add("stand_n_foldB", a, nrow(s))
  t <- s[is.finite(TOPHT_o) & is.finite(TOPHT_p)]
  add("topht_bias_pct", a, 100 * (mean(t$TOPHT_p) - mean(t$TOPHT_o)) / mean(t$TOPHT_o))
  b <- s[is.finite(BA_o) & is.finite(BA_p)]; add("ba_ratio", a, sum(b$BA_p) / sum(b$BA_o))
  s[, `:=`(tph_o = BA_o / (pi / 40000 * QMD_o^2), tph_p = BA_p / (pi / 40000 * QMD_p^2))]
  q <- s[is.finite(tph_o) & is.finite(tph_p)]; add("stems_ratio", a, sum(q$tph_p) / sum(q$tph_o))
  tb <- fread(TAB[[a]])[label == "qc_c" & arm == a, .(STAND = as.character(STAND), V_oh, V_ph)]
  stopifnot(!anyDuplicated(tb$STAND))
  z <- merge(s[, .(STAND)], tb, by = "STAND")[is.finite(V_oh) & is.finite(V_ph)]
  add("c1_n", a, nrow(z)); add("c1_rmse_pct", a, 100 * sqrt(mean((z$V_ph - z$V_oh)^2)) / mean(z$V_oh))
}
## H0
if (!DRY) {
  sd <- function(a, b) { d <- abs(a - b) / pmax(1, abs(b)); d[is.na(a) & is.na(b)] <- 0; d[xor(is.na(a), is.na(b))] <- Inf; d }
  wr <- 0; wt <- c(ht = 0, dbh = 0, expf = 0, ing = 0); nst <- 0; ntr <- 0; worstcol <- ""
  for (set in c("qc_c", "qc_fl")) {
    dirs <- c(file.path(P38, "home/out/p38_one", set), file.path(P38, "home", sprintf("out_retry_a%d", 1:3), "p38_one", set)); acc <- NULL
    for (d in dirs) { fs <- sort(list.files(d, "^c[0-9]+_results\\.csv$", full.names = TRUE)); if (!length(fs)) next
      x <- rbindlist(lapply(fs, fread), fill = TRUE)[, STAND := as.character(STAND)]
      if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x, fill = TRUE) }
    fz <- fread(file.path(J, sprintf("v142p19/results/p19_a1000/gyr_p19_a1000_%s_results.csv", set)))[, STAND := as.character(STAND)]
    stopifnot(!anyDuplicated(acc$STAND), all(acc$STAND %in% fz$STAND))
    cc <- unique(c(grep("_p$", names(acc), value = TRUE), "ING_p", "RUN_OK")); stopifnot(all(cc %in% names(fz)))
    m <- merge(acc[, c("STAND", cc), with = FALSE], fz[, c("STAND", cc), with = FALSE], by = "STAND", suffixes = c(".a", ".b"))
    stopifnot(nrow(m) == nrow(acc)); nst <- nst + nrow(m)
    for (k in cc) { w <- max(sd(as.numeric(m[[paste0(k, ".a")]]), as.numeric(m[[paste0(k, ".b")]]))); if (w > wr || worstcol == "") { if (w >= wr) { wr <- w; worstcol <- k } } }
    cat("H0", set, "stands", nrow(m), "columns", length(cc), "\n")
    pa <- pred_of(file.path(P38, "home"), "p38_one", set)
    pb <- pred_of(file.path(J, "v142p19/home"), "p19_a1000", set)[STAND %in% unique(acc$STAND)]
    stopifnot(!anyDuplicated(pa[, .(STAND, tree)]), !anyDuplicated(pb[, .(STAND, tree)]))
    mt <- merge(pa, pb, by = c("STAND", "tree"), all = TRUE, suffixes = c(".a", ".b")); ntr <- ntr + nrow(mt)
    cat("H0", set, "trees a", nrow(pa), "b", nrow(pb), "merged", nrow(mt), "\n")
    for (k in names(wt)) wt[k] <- max(wt[k], sd(mt[[paste0(k, ".a")]], mt[[paste0(k, ".b")]]))
  }
  add("H0_stands", "p38_one", nst); add("H0_trees", "p38_one", ntr)
  add("H0_worst_stand_scaled", "p38_one", wr); cat("H0 worst stand column", worstcol, wr, "\n")
  for (k in names(wt)) add(paste0("H0_worst_tree_", k), "p38_one", unname(wt[k]))
  add("H0_worst_all", "p38_one", max(wr, wt))
}
O <- rbindlist(out); g <- function(i, a) O[item == i & arm == a, value]
print(O)
if (!DRY) {
  A <- "p38_fit"; Q <- "p19_a0111"; gate <- list()
  gate$H0 <- g("H0_worst_all", "p38_one") <= 1e-9
  gate$K1 <- g("K1_runok_not1_qc_c_all", A) == 0
  gate$R3 <- g("tag_records_foldA", "fieldtag") == 698 && g("tag_records_foldB", "fieldtag") == 737
  gate$H1 <- g("hinc_ratio", A) >= 0.90 && g("hinc_ratio", A) <= 1.10
  cm <- sapply(c("lt12.7", "12.7to25", "ge25"), function(cl) abs(g(paste0("hinc_bias_", cl), A)) - abs(g(paste0("hinc_bias_", cl), Q)))
  for (cl in names(cm)) add(paste0("gate_class_excess_", cl), A, unname(cm[cl]))
  gate$HC <- all(cm <= 0.03)
  gate$TOPHT_level <- abs(g("topht_bias_pct", A)) <= abs(g("topht_bias_pct", "p23_a1061"))
  dd <- abs(g("dom_level", A) - 1) - (abs(g("dom_level", Q) - 1) + 0.02); add("gate_dom_excess", A, dd)
  gate$TOPHT_dom <- dd <= 0
  v2 <- g("c1_rmse_pct", Q) - g("c1_rmse_pct", A); add("gate_V2_diff", A, v2); gate$V2 <- v2 >= -0.5
  b1 <- 100 * (abs(g("ba_ratio", A) - 1) - abs(g("ba_ratio", Q) - 1)); add("gate_B1_excess_pts", A, b1); gate$B1 <- b1 <= 1.0
  b2 <- 100 * (abs(g("stems_ratio", A) - 1) - abs(g("stems_ratio", Q) - 1)); add("gate_B2_excess_pts", A, b2); gate$B2 <- b2 <= 2.0
  for (k in names(gate)) add(paste0("gate_pass_", k), A, as.numeric(gate[[k]]))
  fails <- names(gate)[!unlist(gate)]
  verdict <- if (!gate$H0 || !gate$K1 || !gate$R3) "harness failure, no verdict" else if (!gate$H1) "not adopted (H1 level)" else if (!gate$HC) paste0("not adopted (H classes: ", paste(names(cm)[cm > 0.03], collapse = " "), ")") else if (!gate$TOPHT_level || !gate$TOPHT_dom) "not adopted (TOPHT)" else if (!gate$V2 || !gate$B1 || !gate$B2) "not adopted (trade off: V2/B1/B2)" else "every gate passes: 14.2 QC candidate"
  cat("failing gates:", if (length(fails)) paste(fails, collapse = " ") else "none", "\n"); cat("VERDICT:", verdict, "\n")
  O <- rbindlist(out); O[, value := sprintf("%.17g", value)]
  O <- rbind(O, data.table(item = "verdict", arm = A, value = verdict))
  fwrite(O, OUTC); cat("wrote", OUTC, nrow(O), "rows\n")
}
cat("P38_VERIFY_DONE\n")

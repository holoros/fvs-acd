## PREREG39 independent F9 verifier. Written from the plan alone. No coordinates read. No em dashes.
suppressMessages({ library(data.table); library(digest) })
OUT <- "/home/aaron/jobs/v142p39/verify_20261002"
PLAN <- "/home/aaron/jobs/v142p39/plan/2026-10-02_v142_topht-gate-decomposition_PREREG39.md"
stopifnot(unname(tools::md5sum(PLAN)) == "ba0a48ec6d28cba30bb86d4e67f4465c")
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")  # fold_of, tagok, split_map, mapsp, himp, pred_ht, arm_dirs
TAGD <- "/home/aaron/jobs/v142p14/in/pass28qc"
RUNT2 <- "/home/aaron/jobs/v142p19/home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_t2.csv"
REF_S <- "/home/aaron/jobs/v142p38/assembled/gyr142-p38-stands-summary_DATA_2026-10-01.csv"
REF_H <- "/home/aaron/jobs/v142p38/assembled/gyr142-p38-hinc_DATA_2026-10-01.csv"
ARMS <- list(
  p19_a0111 = list(res = "/home/aaron/jobs/v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv",
                   tab = "/home/aaron/jobs/v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv",
                   home = "/home/aaron/jobs/v142p19/home"),
  p38_fit   = list(res = "/home/aaron/jobs/v142p38/results/p38_fit/gyr_p38_fit_qc_c_results.csv",
                   tab = "/home/aaron/jobs/v142p38/tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv",
                   home = "/home/aaron/jobs/v142p38/home"))
D <- list(); add <- function(arm, item, value) D[[length(D) + 1]] <<- data.table(arm = arm, item = item, value = as.numeric(value))
lg <- function(...) cat(sprintf(...), "\n", sep = "")
lg("plan md5 ok; helper md5 %s", unname(tools::md5sum("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")))
for (f in c(unlist(lapply(ARMS, `[`, c("res", "tab"))), file.path(TAGD, c("bench_gyr_qc_c_tree_init.csv", "bench_gyr_qc_c_tree_t2.csv")), RUNT2, REF_S, REF_H))
  lg("input %s %s", unname(tools::md5sum(f)), f)

## top(): copied from metrics() TOPHT line; returns value and the selected record indices (in input positions)
top <- function(sp, dbh, ht, expf, mindbh) {
  live <- which(is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0)
  if (!length(live)) return(list(v = NA_real_, sel = integer(0)))
  d <- dbh[live]; e <- expf[live]
  o <- order(-d); cw <- cumsum(e[o]); idx <- which(cw <= 100); if (!length(idx)) idx <- 1
  s <- live[o][idx]
  list(v = mean(ifelse(is.finite(ht[s]), ht[s], himp(sp[s], dbh[s]))), sel = s)
}

## frames
F0 <- fread(file.path(TAGD, "bench_gyr_qc_c_tree_init.csv"))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
G0 <- fread(file.path(TAGD, "bench_gyr_qc_c_tree_t2.csv"))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
lg("frames: init %d rows, t2 %d rows", nrow(F0), nrow(G0))
## S4: field tag t2 vs run frame t2, every column except TREE
R2 <- fread(RUNT2)[, STAND := as.character(STAND)]
cols <- setdiff(names(R2), "TREE")
s4 <- nrow(R2) == nrow(G0) && all(vapply(cols, function(cc) isTRUE(all.equal(R2[[cc]], G0[[cc]], tolerance = 0)) || identical(R2[[cc]], G0[[cc]]), TRUE))
lg("S4 run frame t2 equals field tag t2 except TREE: %s", s4); add("all", "S4_pass", s4)
rm(R2)

refS <- fread(REF_S); refH <- fread(REF_H)
RUNG <- paste0("D", 0:6)
store <- list()

for (a in names(ARMS)) {
  A <- ARMS[[a]]
  r <- fread(A$res)[, STAND := as.character(STAND)][RUN_OK == 1]
  if (anyDuplicated(r$STAND)) stop("dup stand")
  cu <- fread(A$tab)[label == "qc_c" & arm == a, .(STAND = as.character(STAND), cut)]
  P0 <- merge(r, cu, by = "STAND")
  P0[, fold := fold_of(SITE)]
  pop <- P0[cut == FALSE & fold == "B"]
  st <- pop$STAND
  lg("[%s] results RUN_OK %d, merged %d, population %d stands, %d sites", a, nrow(r), nrow(P0), length(st), uniqueN(pop$SITE))
  add(a, "pop_stands", length(st)); add(a, "pop_sites", uniqueN(pop$SITE))
  rs <- refS[set == "qc_c" & arm == a & pop == "screened B"]
  add(a, "S3_ref_stands", rs$stands); add(a, "S3_stands_diff", length(st) - rs$stands); add(a, "S3_ref_sites", rs$sites); add(a, "S3_sites_diff", uniqueN(pop$SITE) - rs$sites)
  smd <- setNames(pop$SCORE_MINDBH_USED, st); site <- setNames(pop$SITE, st)

  F <- F0[STAND %in% st]; G <- G0[STAND %in% st]
  F[, sp := mapsp(SP)]; M <- split_map(F)
  ## tag link
  t1 <- F[tagok(TREE), .(STAND, TAG = TREE, row0)]
  t2 <- G[tagok(TREE), .(STAND, TAG = TREE, row0t2 = row0)]
  d1 <- t1[, .N, by = .(STAND, TAG)][N > 1]; d2 <- t2[, .N, by = .(STAND, TAG)][N > 1]
  t1 <- t1[!d1, on = .(STAND, TAG)]; t2 <- t2[!d2, on = .(STAND, TAG)]
  L <- merge(t1, t2, by = c("STAND", "TAG"))   # survivors: t1 row0 <-> t2 row0t2
  ## dom on all F rows
  F[, o := frank(-DBH, ties.method = "first"), by = STAND]
  setorder(F, STAND, o); F[, cw := cumsum(EXPF), by = STAND]; F[, dom := cw <= 100 | o == 1L]
  setorder(F, STAND, row0)
  ## predictions
  dirs <- arm_dirs(A$home, a, "qc_c")
  acc <- NULL
  for (d in dirs) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]
    if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x, fill = TRUE); lg("[%s] pred dir %s: %d files", a, d, length(fs)) }
  PR <- acc[STAND %in% st]
  lg("[%s] pred stands in population %d of %d", a, uniqueN(PR$STAND), length(st))
  Hp <- pred_ht(dirs, M, st)    # STAND,row0,Hp over split parts ing 0

  ## t1 row table
  T1 <- F[, .(STAND, row0, SP, D1 = DBH, H1 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_), dom)]
  T1 <- merge(T1, Hp[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE)
  T1 <- merge(T1, L[, .(STAND, row0, row0t2)], by = c("STAND", "row0"), all.x = TRUE)
  G2 <- G[, .(STAND, row0t2 = row0, SP2 = SP, D2 = DBH, HT2raw = HT, H2 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]
  T1 <- merge(T1, G2, by = c("STAND", "row0t2"), all.x = TRUE)
  T1[, surv := !is.na(row0t2)]
  ## runner observed height rule: raw HT where finite, else himp(mapsp(SP2), D2)
  T1[, Hobs := fifelse(is.finite(HT2raw), HT2raw, himp(mapsp(SP2), D2))]
  T1[, Hobs_imp := !is.finite(HT2raw)]
  dom <- T1[dom == TRUE]
  R0 <- dom[surv & SP == SP2 & is.finite(H1) & is.finite(H2) & is.finite(Hp)]
  R2 <- dom[surv & is.finite(H2) & is.finite(Hp)]
  R3 <- dom[surv & is.finite(Hp)]
  lg("[%s] dom rows %d, dom survivors %d, survivors without Hp %d, dom rows without Hp %d", a, nrow(dom), dom[surv == TRUE, .N], dom[surv & !is.finite(Hp), .N], dom[!is.finite(Hp), .N])
  R4p <- copy(dom)[, Hp4 := fifelse(is.finite(Hp), Hp, himp(mapsp(SP), D1))]

  ## per stand values: list of data.tables STAND, P, O, nP, nO
  SV <- list()
  SV$D1 <- R0[, .(P = mean(Hp), O = mean(H2), nP = .N, nO = .N), by = STAND]
  SV$D2 <- R2[, .(P = mean(Hp), O = mean(H2), nP = .N, nO = .N), by = STAND]
  SV$D3 <- R3[, .(P = mean(Hp), O = mean(Hobs), nP = .N, nO = .N), by = STAND]
  o3 <- SV$D3[, .(STAND, O, nO)]
  p4 <- R4p[, .(P = mean(Hp4), nP = .N), by = STAND]
  SV$D4 <- merge(p4, o3, by = "STAND")
  ## D5/D6 top()
  Gs <- split(G, by = "STAND"); PRs <- split(PR, by = "STAND")
  survt2 <- L[, .(STAND, row0 = row0t2, sv = TRUE)]
  G <- merge(G, survt2, by = c("STAND", "row0"), all.x = TRUE); G[is.na(sv), sv := FALSE]; setorder(G, STAND, row0)
  domrow <- F[dom == TRUE, .(STAND, row0)]
  Mi <- M[, .(STAND, tree, row0)]
  q <- list(o6n = 0, o6imp = 0, o6le13 = 0, q2n = 0, q2d = 0, o6dom = 0, p6n = 0, p6dom = 0)
  r5 <- r6 <- vector("list", length(st)); i <- 0
  for (s in st) { i <- i + 1
    g <- G[STAND == s]; p <- PR[STAND == s]; m <- smd[[s]]
    gs <- g[sv == TRUE]; pi0 <- p[ing == 0]
    o5 <- top(mapsp(gs$SP), gs$DBH, gs$HT, gs$EXPF, m); p5 <- top(p$sp[p$ing == 0], pi0$dbh, pi0$ht, pi0$expf, m)
    o6 <- top(mapsp(g$SP), g$DBH, g$HT, g$EXPF, m); p6 <- top(p$sp, p$dbh, p$ht, p$expf, m)
    r5[[i]] <- data.table(STAND = s, P = p5$v, O = o5$v, nP = length(p5$sel), nO = length(o5$sel))
    r6[[i]] <- data.table(STAND = s, P = p6$v, O = o6$v, nP = length(p6$sel), nO = length(o6$sel))
    ## diagnostics on D6 selections
    gsel <- g[o6$sel]; q$o6n <- q$o6n + nrow(gsel); q$o6imp <- q$o6imp + sum(!is.finite(gsel$HT))
    q$o6le13 <- q$o6le13 + sum(is.finite(gsel$HT) & gsel$HT <= 1.3)
    ok <- is.finite(gsel$HT) & gsel$HT > 0
    q$q2n <- q$q2n + sum(himp(mapsp(gsel$SP[ok]), gsel$DBH[ok])); q$q2d <- q$q2d + sum(gsel$HT[ok])
    ## Q3 observed: t2 row is a survivor whose t1 row is dom
    lk <- L[STAND == s & row0t2 %in% gsel$row0]
    q$o6dom <- q$o6dom + sum(lk$row0 %in% domrow[STAND == s]$row0)
    psel <- p[p6$sel]; q$p6n <- q$p6n + nrow(psel)
    pr <- Mi[STAND == s][psel[ing == 0], on = "tree", nomatch = 0L]
    q$p6dom <- q$p6dom + sum(pr$row0 %in% domrow[STAND == s]$row0)
  }
  SV$D5 <- rbindlist(r5); SV$D6 <- rbindlist(r6)

  ## rung values
  Bfun <- function(x) { x <- x[is.finite(P) & is.finite(O) & nP > 0 & nO > 0]; 100 * (mean(x$P) - mean(x$O)) / mean(x$O) }
  val <- c(D0 = 100 * (sum(R0$Hp) / sum(R0$H2) - 1), sapply(SV, Bfun))
  for (k in RUNG) add(a, k, val[[k]])
  add(a, "D0_records", nrow(R0)); add(a, "D0_stands", uniqueN(R0$STAND))
  for (k in names(SV)) { x <- SV[[k]][is.finite(P) & is.finite(O) & nP > 0 & nO > 0]
    add(a, paste0(k, "_stands"), nrow(x)); add(a, paste0(k, "_records_pred"), sum(x$nP)); add(a, paste0(k, "_records_obs"), sum(x$nO))
    add(a, paste0(k, "_meanP"), mean(x$P)); add(a, paste0(k, "_meanO"), mean(x$O))
    add(a, paste0("Q4_", k, "_records_per_stand_pred"), mean(x$nP)); add(a, paste0("Q4_", k, "_records_per_stand_obs"), mean(x$nO)) }
  add(a, "D0_sumHp", sum(R0$Hp)); add(a, "D0_sumH2", sum(R0$H2))
  dl <- diff(val); names(dl) <- paste0("delta_", 1:6)
  for (k in names(dl)) add(a, k, dl[[k]])
  grp <- c(G1 = dl[[1]] + dl[[2]], G2 = dl[[3]], G3 = dl[[4]], G4 = dl[[5]], G5 = dl[[6]])
  for (k in names(grp)) { add(a, k, grp[[k]]); add(a, paste0(k, "_share_of_gap"), grp[[k]] / (val[["D6"]] - val[["D0"]])) }
  add(a, "gap", val[["D6"]] - val[["D0"]])
  lg("[%s] rungs: %s", a, paste(sprintf("%s=%.6f", names(val), val), collapse = " "))
  ## S1
  ch <- merge(SV$D6, pop[, .(STAND, TOPHT_o, TOPHT_p)], by = "STAND")
  add(a, "S1_stands_compared", nrow(ch))
  add(a, "S1_max_abs_diff_TOPHT_o", max(abs(ch$O - ch$TOPHT_o))); add(a, "S1_max_abs_diff_TOPHT_p", max(abs(ch$P - ch$TOPHT_p)))
  add(a, "S1_ref_topht_bias_pct", rs$topht_bias_pct); add(a, "S1_D6_minus_ref_topht_bias_pct", val[["D6"]] - rs$topht_bias_pct)
  ## S2
  rh <- refH[tagkey == "field tag" & set == "qc_c" & fold == "B" & group == "dominant" & arm == a]
  add(a, "S2_ref_D0", 100 * (rh$level_t2 - 1)); add(a, "S2_D0_minus_ref", val[["D0"]] - 100 * (rh$level_t2 - 1))
  add(a, "S2_ref_trees", rh$trees); add(a, "S2_count_match", nrow(R0) == rh$trees)
  ## Q1, Q2, Q3
  o3s <- R3
  add(a, "Q1_D6obs_records", q$o6n); add(a, "Q1_D6obs_himp_share", q$o6imp / q$o6n); add(a, "Q1_D6obs_finite_le_1.3_count", q$o6le13)
  add(a, "Q1_D3obs_records", nrow(o3s)); add(a, "Q1_D3obs_himp_share", mean(o3s$Hobs_imp)); add(a, "Q1_D3obs_finite_le_1.3_count", sum(is.finite(o3s$HT2raw) & o3s$HT2raw <= 1.3))
  add(a, "Q2_D6obs_sum_himp_over_sum_ht", q$q2n / q$q2d)
  add(a, "Q3_D6obs_share_t1dom_survivor", q$o6dom / q$o6n); add(a, "Q3_D6pred_share_t1dom_ing0", q$p6dom / q$p6n)
  store[[a]] <- list(val = val, SV = SV, R0 = R0, site = site, sites = unique(pop$SITE))
}

## S1/S2/S3 pass flags
DD <- rbindlist(D)
gv <- function(a, it) DD[arm == a & item == it, value]
for (a in names(ARMS)) {
  s1 <- gv(a, "S1_max_abs_diff_TOPHT_o") <= 1e-9 && gv(a, "S1_max_abs_diff_TOPHT_p") <= 1e-9 && abs(gv(a, "S1_D6_minus_ref_topht_bias_pct")) <= 1e-9 && gv(a, "S1_stands_compared") == gv(a, "pop_stands")
  s2 <- abs(gv(a, "S2_D0_minus_ref")) <= 1e-9 && gv(a, "S2_count_match") == 1
  s3 <- gv(a, "S3_stands_diff") == 0
  add(a, "S1_pass", s1); add(a, "S2_pass", s2); add(a, "S3_pass", s3)
  lg("[%s] S1 %s S2 %s S3 %s", a, s1, s2, s3)
}

## site cluster bootstrap, union of fold B sites of both populations, one matrix
sites <- sort(unique(c(store$p19_a0111$sites, store$p38_fit$sites))); ns <- length(sites)
add("all", "boot_sites", ns)
set.seed(20261002); NB <- 1000
W <- matrix(0L, ns, NB); for (b in seq_len(NB)) W[, b] <- tabulate(sample.int(ns, ns, replace = TRUE), ns)
rownames(W) <- sites
outc <- list()
for (a in names(ARMS)) {
  S <- store[[a]]; bt <- matrix(NA_real_, NB, 7, dimnames = list(NULL, RUNG))
  sp0 <- S$R0[, .(hp = sum(Hp), h2 = sum(H2)), by = .(SITE = S$site[STAND])]
  w0 <- W[sp0$SITE, , drop = FALSE]
  bt[, "D0"] <- 100 * (colSums(w0 * sp0$hp) / colSums(w0 * sp0$h2) - 1)
  for (k in RUNG[-1]) { x <- S$SV[[k]][is.finite(P) & is.finite(O) & nP > 0 & nO > 0]
    wk <- W[S$site[x$STAND], , drop = FALSE]
    bt[, k] <- 100 * (colSums(wk * x$P) - colSums(wk * x$O)) / colSums(wk * x$O) }
  dl <- bt[, -1] - bt[, -7]
  gb <- cbind(G1 = dl[, 1] + dl[, 2], G2 = dl[, 3], G3 = dl[, 4], G4 = dl[, 5], G5 = dl[, 6], gap = bt[, 7] - bt[, 1])
  ci <- function(v) quantile(v, c(0.025, 0.975), names = FALSE, type = 7)
  for (k in colnames(gb)) { cc <- ci(gb[, k]); add(a, paste0(k, "_lo"), cc[1]); add(a, paste0(k, "_hi"), cc[2]) }
  val <- S$val; gap <- val[["D6"]] - val[["D0"]]
  dlp <- diff(val); grp <- c(G1 = dlp[[1]] + dlp[[2]], G2 = dlp[[3]], G3 = dlp[[4]], G4 = dlp[[5]], G5 = dlp[[6]])
  qual <- names(grp)[sapply(names(grp), function(k) { cc <- ci(gb[, k]); grp[[k]] / gap >= 0.5 && (cc[1] > 0 || cc[2] < 0) })]
  oc <- if (length(qual)) paste0("dominant ", paste(qual, collapse = "+")) else paste0("diffuse: ", paste(names(grp)[grp / gap >= 0.25], collapse = ","))
  outc[[a]] <- oc
  for (g in names(grp)) add(a, paste0("outcome_qualifies_", g), g %in% qual)
  lg("[%s] gap %.6f groups %s outcome %s", a, gap, paste(sprintf("%s=%.4f", names(grp), grp), collapse = " "), oc)
}
add("p38_fit", "outcome_consistent_with_qc141", outc$p38_fit == outc$p19_a0111)
for (k in RUNG) add("p38_fit_minus_p19_a0111", k, store$p38_fit$val[[k]] - store$p19_a0111$val[[k]])
DD <- rbindlist(D)
fwrite(DD, file.path(OUT, "p39_verify_DATA_2026-10-02.csv"))
writeLines(c(sprintf("p19_a0111,%s", outc$p19_a0111), sprintf("p38_fit,%s", outc$p38_fit)), file.path(OUT, "p39_verify_outcome_2026-10-02.txt"))
lg("rows written %d", nrow(DD))
cat("P39_VERIFY_DONE\n")

## PREREG40 independent F9 verifier, written from the plan (md5 63692615) alone. Re-derives R0a to R0d, the fold A height and
## diameter fit, B_M and B_H per arm, D2 to D4 and the decision. No bootstrap. No coordinates read. No em dashes.
source("/home/aaron/jobs/v142p38/scripts/2026-09-29_v142_p23_hkey.R")   # fold_of, tagok, split_map, arm_dirs, P19
suppressMessages(library(data.table))
V <- "/home/aaron/jobs/v142p40/verify_20261002"; DT <- "2026-10-02"
PLAN <- "/home/aaron/jobs/v142p40/plan/2026-10-02_v142_topht-measured-gate_PREREG40.md"
stopifnot(unname(tools::md5sum(PLAN)) == "63692615e60cf1287f0eb03512ceeeda")
OUTF <- file.path(V, sprintf("p40_verify_DATA_%s.csv", DT)); if (file.exists(OUTF)) stop("REFUSE ", OUTF)
P38 <- "/home/aaron/jobs/v142p38"; P23 <- "/home/aaron/jobs/v142p23"; P28B <- "/home/aaron/jobs/v142p28b"
FT <- "/home/aaron/jobs/v142p14/in/pass28qc"
## ---- runner rules parsed from runner_p28_fb.R
RUN <- file.path(P38, "home/runner_p28_fb.R"); stopifnot(unname(tools::md5sum(RUN)) == "0a2b27421ee7b25eaab7f4591ce3af97")
RL <- readLines(RUN); e <- new.env()
ia <- grep("^AGY2SPCD<-c\\(", RL); eval(parse(text = RL[ia:(ia + 2)]), e)
eval(parse(text = grep("^sw<-c\\(", RL, value = TRUE)), e); eval(parse(text = grep("^himp<-function", RL, value = TRUE)), e)
stopifnot(grepl("^himp<-function", RL[184]), any(grepl("idx<-which\\(cw<=100\\); if\\(!length\\(idx\\)\\)idx<-1; TOPHT<-mean\\(ifelse\\(is.finite\\(ht\\[o\\]\\[idx\\]\\),ht\\[o\\]\\[idx\\],himp", RL[208])))
sw_r <- e$sw; himp_r <- e$himp; acadgy <- names(e$AGY2SPCD)
mapsp_r <- function(s) { s <- toupper(s); ifelse(s %in% acadgy, s, ifelse(s %in% sw_r, "OS", "OH")) }
## top(): runner TOPHT rule with a fill function
top_sel <- function(dbh, expf, mindbh) { live <- which(is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0); if (!length(live)) return(integer(0))
  o <- live[order(-dbh[live])]; cw <- cumsum(expf[o]); idx <- which(cw <= 100); if (!length(idx)) idx <- 1; o[idx] }
top <- function(sp, dbh, ht, expf, mindbh, fill = himp_r) { s <- top_sel(dbh, expf, mindbh); if (!length(s)) return(NA_real_)
  mean(ifelse(is.finite(ht[s]), ht[s], fill(sp[s], dbh[s]))) }
Bpct <- function(P, O) { k <- is.finite(P) & is.finite(O); 100 * (mean(P[k]) - mean(O[k])) / mean(O[k]) }
OUT <- list(); put <- function(item, arm, value) OUT[[length(OUT) + 1]] <<- data.table(item = item, arm = arm, value = as.character(value))
putn <- function(item, arm, value) OUT[[length(OUT) + 1]] <<- data.table(item = item, arm = arm, value = format(value, digits = 17))
## ---- arms (PREREG38 AR table)
AR <- data.table(arm = c("p19_a0030", "p19_a0060", "p19_a0111", "p19_a0250", "p19_a0500", "p19_a1000", "p23_a1061", "p23_a1250", "p28b_small", "p38_fit"))
AR[, root := fifelse(startsWith(arm, "p19"), P19, fifelse(startsWith(arm, "p23"), P23, fifelse(startsWith(arm, "p28b"), P28B, P38)))]
AR[, home := file.path(root, "home")]
AR[, stands := fifelse(startsWith(arm, "p19"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p23"), file.path(P23, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv"),
  fifelse(startsWith(arm, "p28b"), file.path(P28B, "tables/gyr142-p28b-fb-stands_DATA_2026-09-27.csv"), file.path(P38, "tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv"))))]
AR[, resf := file.path(root, "results", arm, sprintf("gyr_%s_qc_c_results.csv", arm))]
rd <- function(h, arm) { acc <- NULL; for (d in arm_dirs(h, arm, "qc_c")) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
GA <- fread(file.path(P38, "assembled/gyr142-p38-gates-all_DATA_2026-10-01.csv"))
SS <- fread(file.path(P38, "assembled/gyr142-p38-stands-summary_DATA_2026-10-01.csv"))[set == "qc_c" & pop == "screened B"]
## ---- R0d: pass28qc t2 frame against run frame t2
FG <- file.path(FT, "bench_gyr_qc_c_tree_t2.csv"); FI <- file.path(FT, "bench_gyr_qc_c_tree_init.csv")
RG <- file.path(P19, "home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_t2.csv")
g1 <- fread(FG); g2 <- fread(RG); cc <- setdiff(names(g2), "TREE")
R0d <- nrow(g1) == nrow(g2) && identical(names(g1), names(g2)) && all(sapply(cc, function(k) isTRUE(all.equal(g1[[k]], g2[[k]], tolerance = 0))))
cat(sprintf("R0d frames agree on %d non TREE columns over %d rows: %s\n", length(cc), nrow(g1), R0d)); put("R0d frames agree", "all", R0d); rm(g1, g2)
## ---- frames and tag link
F0 <- fread(FI)[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]
G0 <- fread(FG)[, STAND := as.character(STAND)][, row2 := seq_len(.N), by = STAND]
F0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]; G0[, TAG := fifelse(tagok(TREE), as.character(TREE), NA_character_)]
d1 <- F0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]; d2 <- G0[!is.na(TAG), .N, by = .(STAND, TAG)][N > 1]
F0[d1, on = .(STAND, TAG), TAG := NA_character_]; G0[d2, on = .(STAND, TAG), TAG := NA_character_]
LK <- merge(F0[!is.na(TAG), .(STAND, TAG, row0)], G0[!is.na(TAG), .(STAND, TAG, row2)], by = c("STAND", "TAG"))
stopifnot(!anyDuplicated(LK[, .(STAND, row0)]), !anyDuplicated(LK[, .(STAND, row2)]))
G0[, linked := FALSE]; G0[LK, on = .(STAND, row2), linked := TRUE]
G0[, meas := is.finite(HT) & HT > 0]; G0[, setM := linked & meas]; G0[, spr := mapsp_r(SP)]
cat(sprintf("t2 rows %d, linked %d, linked and measured %d; dup keys dropped t1 %d t2 %d\n", nrow(G0), sum(G0$linked), sum(G0$setM), nrow(d1), nrow(d2)))
F0[, sp := mapsp(SP)]; MP <- split_map(F0)
## t1 rows whose linked t2 row is in the variant M observed set
LM <- merge(LK, G0[setM == TRUE, .(STAND, row2)], by = c("STAND", "row2"))[, .(STAND, row0)]
MPM <- merge(MP[, .(STAND, tree, row0)], LM, by = c("STAND", "row0"))
## ---- fold A height and diameter fit
s19 <- fread(AR[arm == "p19_a0111"]$stands)[label == "qc_c" & arm == "p19_a0111"][, STAND := as.character(STAND)]
r19 <- fread(AR[arm == "p19_a0111"]$resf)[, STAND := as.character(STAND)]; stopifnot(!anyDuplicated(r19$STAND))
fa <- merge(s19[cut == FALSE, .(STAND)], r19[, .(STAND, SITE, RUN_OK)], by = "STAND"); fa[, fold := fold_of(SITE)]
cat(sprintf("fit stands: p19_a0111 qc_c cut FALSE %d, with results %d, fold A %d (RUN_OK != 1 among fold A: %d)\n", nrow(s19[cut == FALSE]), nrow(fa), sum(fa$fold == "A"), sum(fa$fold == "A" & fa$RUN_OK != 1)))
stA <- fa[fold == "A"]$STAND; stopifnot(!any(fa[fold == "B"]$STAND %in% stA))
FD <- G0[STAND %in% stA & is.finite(DBH) & DBH > 0 & is.finite(HT) & HT > 1.3, .(STAND, DBH, HT, grp = fifelse(spr %in% sw_r, "softwood", "hardwood"))]
ST <- list(softwood = list(a = 27, b = 0.030, c = 1), hardwood = list(a = 25, b = 0.028, c = 1)); CO <- list()
for (g in c("softwood", "hardwood")) { d <- FD[grp == g]
  m <- tryCatch(nls(HT ~ 1.3 + a * (1 - exp(-b * DBH))^c, data = d, start = ST[[g]]), error = function(e) { cat("nls 3p failed ", g, ": ", conditionMessage(e), "\n"); NULL })
  form <- "three parameter"
  if (is.null(m)) { form <- "two parameter c = 1"; m <- tryCatch(nls(HT ~ 1.3 + a * (1 - exp(-b * DBH)), data = d, start = ST[[g]][c("a", "b")]), error = function(e) { cat("nls 2p failed ", g, "\n"); NULL }) }
  if (is.null(m)) { CO[[g]] <- NULL; next }
  cf <- coef(m); if (!"c" %in% names(cf)) cf <- c(cf, c = 1)
  CO[[g]] <- cf; cat(sprintf("%s fit (%s): n %d\n", g, form, nrow(d))); print(summary(m)$coefficients); cat(sprintf("residual SE %.6f\n", summary(m)$sigma))
  for (k in c("a", "b", "c")) putn(sprintf("hd %s %s", g, k), "all", unname(cf[k])); putn(sprintf("hd %s records", g), "all", nrow(d)); put(sprintf("hd %s form", g), "all", form) }
fitok <- !is.null(CO$softwood) && !is.null(CO$hardwood)
fA <- function(sp, d) { s <- sp %in% sw_r; cs <- CO$softwood; ch <- CO$hardwood
  ifelse(s, 1.3 + cs[["a"]] * (1 - exp(-cs[["b"]] * d))^cs[["c"]], 1.3 + ch[["a"]] * (1 - exp(-ch[["b"]] * d))^ch[["c"]]) }
## ---- per arm
RES <- list()
for (i in seq_len(nrow(AR))) { a <- AR$arm[i]
  r <- fread(AR$resf[i])[, STAND := as.character(STAND)]; stopifnot(!anyDuplicated(r$STAND))
  stn <- fread(AR$stands[i])[label == "qc_c" & arm == a][, STAND := as.character(STAND)]
  v <- merge(stn[, .(STAND, cut)], r[RUN_OK == 1, .(STAND, SITE, SMD = SCORE_MINDBH_USED, TOPHT_o, TOPHT_p)], by = "STAND"); v[, fold := fold_of(SITE)]
  pop <- v[cut == FALSE & fold == "B"]; st <- pop$STAND
  P <- rd(AR$home[i], a)[STAND %in% st]; if (!setequal(unique(P$STAND), st)) stop("prediction stands differ ", a)
  P[, ing := as.integer(ing)]
  PM <- merge(P[ing == 0], MPM, by = c("STAND", "tree"))
  Gs <- split(G0[STAND %in% st], by = "STAND"); Ps <- split(P, by = "STAND"); PMs <- split(PM, by = "STAND")
  rows <- rbindlist(lapply(st, function(s) { m <- pop[STAND == s]$SMD; g <- Gs[[s]]; p <- Ps[[s]]; pm <- PMs[[s]]; gm <- g[setM == TRUE]
    so <- top_sel(g$DBH, g$EXPF, m); sel <- g[so]
    data.table(STAND = s, To = top(g$spr, g$DBH, g$HT, g$EXPF, m), Tp = top(p$sp, p$dbh, p$ht, p$expf, m),
      ToM = if (nrow(gm)) top(gm$spr, gm$DBH, gm$HT, gm$EXPF, m) else NA_real_,
      TpM = if (!is.null(pm) && nrow(pm)) top(pm$sp, pm$dbh, pm$ht, pm$expf, m) else NA_real_,
      ToH = if (fitok) top(g$spr, g$DBH, g$HT, g$EXPF, m, fA) else NA_real_,
      TpH = if (fitok) top(p$sp, p$dbh, p$ht, p$expf, m, fA) else NA_real_,
      nsel = nrow(sel), nselM = sum(sel$setM), nfill = sum(!is.finite(sel$HT)),
      sm_h = sum(sel[meas == TRUE]$HT), sm_himp = sum(himp_r(sel[meas == TRUE]$spr, sel[meas == TRUE]$DBH)),
      sm_fa = if (fitok) sum(fA(sel[meas == TRUE]$spr, sel[meas == TRUE]$DBH)) else NA_real_,
      nfM = if (is.null(pm)) 0L else sum(!is.finite(pm$ht)), nfP = sum(!is.finite(p$ht)),
      nfPsel = sum(!is.finite(p$ht[top_sel(p$dbh, p$expf, m)])), nrecM_o = nrow(gm), nrecM_p = if (is.null(pm)) 0L else nrow(pm)) }))
  rows <- merge(rows, pop[, .(STAND, TOPHT_o, TOPHT_p)], by = "STAND")
  eo <- abs(rows$To - rows$TOPHT_o); ep <- abs(rows$Tp - rows$TOPHT_p)
  nao <- sum(!is.finite(rows$To)); nap <- sum(!is.finite(rows$Tp))
  wo <- if (nao) Inf else max(eo); wp <- if (nap) Inf else max(ep)
  Bpub <- Bpct(rows$TOPHT_p, rows$TOPHT_o); Bmine <- Bpct(rows$Tp, rows$To); Bga <- GA[arm == a]$topht
  sdiff <- nrow(pop) - SS[arm == a]$stands
  kM <- is.finite(rows$ToM) & is.finite(rows$TpM); BM <- Bpct(rows$TpM, rows$ToM)
  kH <- is.finite(rows$ToH) & is.finite(rows$TpH); BH <- if (fitok) Bpct(rows$TpH, rows$ToH) else NA_real_
  cat(sprintf("%-10s stands %d (summary %d) R0a o %.3g p %.3g (empty o %d p %d) R0b %.3g | Bpub %.6f B_M %.6f (n %d) B_H %.6f (n %d) | fill share %.4f D3 %.4f nfM %d nfP %d nfPsel %d\n",
    a, nrow(pop), SS[arm == a]$stands, wo, wp, nao, nap, abs(Bmine - Bga), Bpub, BM, sum(kM), BH, sum(kH), sum(rows$nfill) / sum(rows$nsel), sum(rows$nselM) / sum(rows$nsel), sum(rows$nfM), sum(rows$nfP), sum(rows$nfPsel)))
  putn("R0a TOPHT_o worst", a, wo); putn("R0a TOPHT_p worst", a, wp); putn("R0b worst", a, abs(Bmine - Bga)); putn("R0c stands diff", a, sdiff)
  putn("B_published", a, Bpub); putn("B_M", a, BM); putn("B_H", a, BH); putn("stands_M", a, sum(kM)); putn("stands_H", a, sum(kH))
  putn("D2 himp ratio", a, sum(rows$sm_himp) / sum(rows$sm_h)); putn("D2 fold A ratio", a, sum(rows$sm_fa) / sum(rows$sm_h))
  putn("D3 share", a, sum(rows$nselM) / sum(rows$nsel)); putn("D4 nonfinite pred ht", a, sum(rows$nfM))
  putn("D4 nonfinite pred ht published set", a, sum(rows$nfP)); putn("D1 fill share published", a, sum(rows$nfill) / sum(rows$nsel))
  putn("records per stand M observed", a, mean(rows$nrecM_o[kM])); putn("records per stand M predicted", a, mean(rows$nrecM_p[kM]))
  RES[[a]] <- list(wo = wo, wp = wp, r0b = abs(Bmine - Bga), sdiff = sdiff, BM = BM, BH = BH) }
## ---- decision
r0ok <- R0d && all(sapply(RES, function(x) x$wo <= 1e-9 && x$wp <= 1e-9 && x$r0b <= 1e-9 && x$sdiff == 0))
BM <- RES$p38_fit$BM; BH <- RES$p38_fit$BH; TM <- abs(BM) <= 10; TH <- if (fitok) abs(BH) <= 10 else NA
dec <- if (!r0ok) "rule 1: reproduction stop failed, harness failure, no reading" else
  if (!fitok) sprintf("rule 2 then T_M alone: T_M %s (|B_M| %.4f); %s", if (TM) "passes" else "fails", abs(BM), if (TM) "T_M passes, variant H not read" else "rule 5: measured height TOPHT gate also rejects 1.242") else
  if (TM && TH) sprintf("rule 3: T_M passes (|B_M| %.4f <= 10) and T_H passes (|B_H| %.4f <= 10); published TOPHT rejection of 1.242 attributed to the observed height rule; p38_fit eligible for the Bakuzis QC grid under a separate pre-registration", abs(BM), abs(BH)) else
  if (TM && !TH) sprintf("rule 4: T_M passes (|B_M| %.4f <= 10) and T_H fails (|B_H| %.4f > 10); conflicting, no carry forward", abs(BM), abs(BH)) else
  sprintf("rule 5: T_M fails (|B_M| %.4f > 10; |B_H| %.4f); the measured height TOPHT gate also rejects 1.242, anchor not carried forward", abs(BM), abs(BH))
cat("reproduction R0a to R0d all pass:", r0ok, "\nDECISION:", dec, "\n")
put("decision", "p38_fit", dec)
fwrite(rbindlist(OUT), OUTF)
cat("P40_VERIFY_DONE\n")

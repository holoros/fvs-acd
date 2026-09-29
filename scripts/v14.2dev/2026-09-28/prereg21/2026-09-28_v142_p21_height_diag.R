## PREREG21: why MNAP State model heights run tall. Diagnostic only: reads frozen PREREG15 r1 per tree outputs and the
## pass 29b frames; no model run, engine, coefficient or default changes. Volume, himp, species map and form/risk split
## verbatim from the PREREG16 scorer (2026-09-27_v142_volconv_score.R, md5 019df238). Host agnostic via env vars so the
## same file can run the mefia_l_c control where its per tree outputs live. Aggregates only; no stand keys, plot names or
## coordinates are written. Heights outside 1 to 45 m are flagged, never silently dropped. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) }); options(width = 200)
setDTthreads(2L)
SEED <- 20260916L; B <- 2000L
ev <- function(k, d = "") Sys.getenv(k, d)
OUT <- ev("P21_OUT"); SET <- ev("P21_SET"); RES <- ev("P21_RES"); TDIRS <- ev("P21_TREEDIRS"); FR <- ev("P21_FR")
REFD <- path.expand(ev("P21_REFDIR")); SPLITF <- path.expand(ev("P21_SPLIT")); IDXS <- ev("P21_IDX", "SEED:20260916:2000")
GAPREF <- ev("P21_GAPREF"); GAPLAB <- ev("P21_GAPLAB"); LAB <- ev("P21_LABEL", SET)
CTRL_FR <- ev("P21_CTRL_FR"); CTRL_SET <- ev("P21_CTRL_SET", "mefia_l_c")
DSTAMP <- "2026-09-28"
if (!nzchar(OUT) || !nzchar(SET) || !nzchar(RES) || !nzchar(TDIRS) || !nzchar(FR)) stop("P21_OUT, P21_SET, P21_RES, P21_TREEDIRS, P21_FR required")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
cat(sprintf("p21 R %s data.table %s ggplot2 %s host=%s set=%s seed=%d B=%d\n", getRversion(), packageVersion("data.table"),
            packageVersion("ggplot2"), Sys.info()[["nodename"]], SET, SEED, B))
hs <- function(fmt, ...) { m <- sprintf(fmt, ...); cat("HARD STOP:", m, "\n"); cat(m, "\n", file = file.path(OUT, "_hardstop.txt"), append = TRUE); quit(save = "no", status = 3) }
wout <- function(x, nm) { f <- file.path(OUT, sprintf("gyr142-p21-%s-%s_DATA_%s.csv", LAB, nm, DSTAMP)); fwrite(x, f); cat(sprintf("wrote %s (%d rows)\n", basename(f), nrow(x))) }
need <- function(d, cols, what) { m <- setdiff(cols, names(d)); if (length(m)) hs("%s lacks column(s): %s", what, paste(m, collapse = ", ")) }
q95 <- function(x) quantile(x, c(0.025, 0.975), names = FALSE, na.rm = TRUE)
rel <- function(a, b) abs(a - b) / pmax(1, abs(b))

## ---- verbatim from the PREREG16 scorer: species codes, himp, NSVB emulator --------------------------------------
co <- fread(file.path(REFD, "nsvb_emulator_coefs.csv")); sp2g <- fread(file.path(REFD, "spcd_spgrpcd.csv"))
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=125,BC=762,PR=761,ST=315,HH=701,SB=372,RB=370,AS=541,SW=299,HW=998,OH=998,OS=299,PC=761)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes<-names(AGY2SPCD)
if (anyDuplicated(sp2g$SPCD)) hs("spcd_spgrpcd.csv has duplicated SPCD keys")
spcd2grp<-setNames(sp2g$SPGRPCD, as.character(sp2g$SPCD))
agy_grp<-sapply(AGY2SPCD, function(s){ g<-spcd2grp[as.character(s)]; if(is.na(g)) 998L else as.integer(g) })
ci<-match(agy_grp, co$SPGRPCD); ci[is.na(ci)]<-match(998, co$SPGRPCD); ci[is.na(ci)]<-1
RESP<-c("VOLCFGRS"); CF<-list()
for(r in RESP) CF[[r]]<-list(a=setNames(co[[paste0(r,"_a")]][ci],agy_codes),
  b=setNames(co[[paste0(r,"_b")]][ci],agy_codes), sm=setNames(co[[paste0(r,"_sm")]][ci],agy_codes))
nsvb<-function(agy,dbh_cm,ht_m,resp){
  ht<-ifelse(is.finite(ht_m)&ht_m>0,ht_m,himp(agy,dbh_cm))
  lX<-log((dbh_cm/2.54)^2*(ht/0.3048))
  a<-CF[[resp]]$a[agy]; b<-CF[[resp]]$b[agy]; sm<-CF[[resp]]$sm[agy]
  y<-sm*exp(a+b*lX); y[!is.finite(y)]<-0; unname(y)
}
FT3_M3<-0.0283168
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
## per record volume under the metrics() live filter (the scorer's totvol, before the stand sum)
vrec <- function(sp, dbh, ht, expf, smd) { live <- is.finite(dbh) & dbh >= smd & is.finite(expf) & expf > 0
  v <- numeric(length(dbh)); if (any(live)) v[live] <- nsvb(sp[live], dbh[live], ht[live], "VOLCFGRS") * expf[live] * FT3_M3; v }

## ---- form/risk split id map, verbatim from the scorer ------------------------------------------------------------
split_map <- NULL
if (nzchar(SPLITF)) { .SPLIT_QUIET <- TRUE; source(SPLITF)
  subw <- lapply(setNames(rownames(.pform), rownames(.pform)), function(key) { Jm <- outer(.pform[key, ], .prisk[key, ]); Jm[Jm < 0.03] <- 0
    if (sum(Jm) == 0) Jm <- outer(.pform[key, ], .prisk[key, ]); Jm <- Jm / sum(Jm); idx <- which(Jm > 0, arr.ind = TRUE); Jm[idx] })
  split_map <- function(F) {
    F <- copy(F); F[, n0 := .N, by = STAND]; F[, is_hw := toupper(sp) %in% .a9$sp]
    a <- F[is_hw == FALSE, .(STAND, tree = row0, row0, sp, dbh = DBH, expf = EXPF, hw = FALSE)]
    h <- F[is_hw == TRUE][, key := fifelse(toupper(sp) %in% HW_SPP, toupper(sp), "OH")]
    h[, k := lengths(subw[key])]; hx <- h[rep(seq_len(.N), k)]; hx[, j := seq_len(.N), by = .(STAND, row0)]
    hx[, w := mapply(function(kk, jj) subw[[kk]][jj], key, j)]; setorder(hx, STAND, row0, j)
    hx[, tree := n0 + seq_len(.N), by = STAND]
    rbind(a, hx[, .(STAND, tree, row0, sp, dbh = DBH, expf = EXPF * w, hw = TRUE)])
  } }

rd_chunks <- function(dirs, pat) { dirs <- strsplit(dirs, ";", fixed = TRUE)[[1]]; acc <- NULL
  for (d in dirs) { fs <- sort(list.files(d, pattern = pat, full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, STAND := as.character(STAND)]
    if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]
    acc <- rbind(acc, x, fill = TRUE) }
  acc }
wts <- function(IDX, sid, nsite) { CNT <- matrix(0L, nsite, ncol(IDX)); for (b in seq_len(ncol(IDX))) CNT[, b] <- tabulate(IDX[, b], nbins = nsite)
  W <- CNT[sid, , drop = FALSE]; storage.mode(W) <- "double"; W }
mkW <- function(site_all, idxs) { sites <- unique(site_all); nsite <- length(sites); sid <- match(site_all, sites)
  IDX <- if (startsWith(idxs, "SEED:")) { a <- as.integer(strsplit(idxs, ":")[[1]][2:3]); set.seed(a[1]); matrix(sample.int(nsite, nsite * a[2], replace = TRUE), nsite, a[2]) } else readRDS(idxs)
  if (nrow(IDX) != nsite) hs("bootstrap index rows %d differ from %d sites", nrow(IDX), nsite)
  wts(IDX, sid, nsite) }
dbhcls <- function(d) cut(d, c(-Inf, 15, 25, 35, Inf), labels = c("<15", "15-25", "25-35", ">=35"), right = FALSE)
htcls  <- function(h) cut(h, c(-Inf, 15, 20, 25, Inf), labels = c("<15", "15-20", "20-25", ">=25"), right = FALSE)
flag_ht <- function(h) is.finite(h) & (h < 1 | h > 45)
tagok <- function(t) if (is.numeric(t)) is.finite(t) & t < 9e6 else !is.na(t) & nzchar(as.character(t))

## ======================= observed side tests (E1 to E3, observed increment, levels): any frame ====================
obs_side <- function(fr, set, smd_dt, site_dt, idxs, lab) {
  F1 <- fread(file.path(fr, sprintf("bench_gyr_%s_tree_init.csv", set))); F2 <- fread(file.path(fr, sprintf("bench_gyr_%s_tree_t2.csv", set)))
  need(F1, c("STAND", "TREE", "SP", "DBH", "HT", "EXPF"), paste(set, "tree_init")); need(F2, c("STAND", "TREE", "SP", "DBH", "HT", "EXPF"), paste(set, "tree_t2"))
  F1[, STAND := as.character(STAND)][, spm := mapsp(SP)]; F2[, STAND := as.character(STAND)][, spm := mapsp(SP)]
  F1 <- merge(F1, smd_dt, by = "STAND"); F2 <- merge(F2, smd_dt, by = "STAND")
  F1 <- F1[is.finite(DBH) & DBH >= SMD & is.finite(EXPF) & EXPF > 0]; F2 <- F2[is.finite(DBH) & DBH >= SMD & is.finite(EXPF) & EXPF > 0]
  m1 <- is.finite(F1$HT) & F1$HT > 0; m2 <- is.finite(F2$HT) & F2$HT > 0
  ## E3 ranges and grids
  grid <- function(h, u) { z <- h / u; abs(z - round(z)) < 0.005 / u * 1 }
  E <- data.table(set = lab, occasion = c("t1", "t2"), trees = c(nrow(F1), nrow(F2)), measured_share = c(mean(m1), mean(m2)),
    ht_min = c(min(F1$HT[m1]), min(F2$HT[m2])), ht_p50 = c(median(F1$HT[m1]), median(F2$HT[m2])), ht_max = c(max(F1$HT[m1]), max(F2$HT[m2])),
    n_out_1_45 = c(sum(flag_ht(F1$HT[m1])), sum(flag_ht(F2$HT[m2]))),
    share_foot_grid = c(mean(grid(F1$HT[m1], 0.3048)), mean(grid(F2$HT[m2], 0.3048))),
    share_whole_m = c(mean(grid(F1$HT[m1], 1)), mean(grid(F2$HT[m2], 1))),
    share_half_m = c(mean(grid(F1$HT[m1], 0.5)), mean(grid(F2$HT[m2], 0.5))),
    share_dm = c(mean(grid(F1$HT[m1], 0.1)), mean(grid(F2$HT[m2], 0.1))))
  ## survivors on tags, same species, both heights measured
  t1 <- F1[tagok(TREE), .(STAND, TREE, SP1 = SP, D1 = DBH, H1 = HT, EXPF, spm, SMD)]; t2 <- F2[tagok(TREE), .(STAND, TREE, SP2 = SP, D2 = DBH, H2 = HT)]
  t1 <- t1[!t1[, .N, by = .(STAND, TREE)][N > 1], on = .(STAND, TREE)]; t2 <- t2[!t2[, .N, by = .(STAND, TREE)][N > 1], on = .(STAND, TREE)]
  sv <- merge(t1, t2, by = c("STAND", "TREE"))[SP1 == SP2 & is.finite(H1) & H1 > 0 & is.finite(H2) & H2 > 0]
  sv <- merge(sv, site_dt, by = "STAND")
  sv[, dH := H2 - H1][, dH10 := dH * 10 / IV]
  sv[, ratio_units := H2 / H1][, units_flag := abs(ratio_units / 3.281 - 1) < 0.03 | abs(ratio_units / 0.3048 - 1) < 0.03]
  sv[, v1 := vrec(spm, D1, H1, EXPF, SMD)]
  ## levels against himp, volume weighted, stand sums
  F1[, `:=`(vm = vrec(spm, DBH, fifelse(is.finite(HT) & HT > 0, HT, NA_real_), EXPF, SMD), vh = vrec(spm, DBH, rep(NA_real_, .N), EXPF, SMD))]
  F2[, `:=`(vm = vrec(spm, DBH, fifelse(is.finite(HT) & HT > 0, HT, NA_real_), EXPF, SMD), vh = vrec(spm, DBH, rep(NA_real_, .N), EXPF, SMD))]
  F2[, vm05 := vrec(spm, DBH, fifelse(is.finite(HT) & HT > 0, HT + 0.5, NA_real_), EXPF, SMD)]
  st <- site_dt[, .(STAND, SITE)]
  a1 <- F1[, .(v1m = sum(vm), v1h = sum(vh)), by = STAND]; a2 <- F2[, .(v2m = sum(vm), v2h = sum(vh), v2m05 = sum(vm05)), by = STAND]
  as_ <- sv[, .(ns = .N, sdH = sum(dH), sH1 = sum(H1), sH2 = sum(H2), nneg1 = sum(dH < -1), nbig = sum(dH10 > 8), nunits = sum(units_flag)), by = STAND]
  S <- Reduce(function(a, b) merge(a, b, by = "STAND", all.x = TRUE), list(st, a1, a2, as_)); for (cc in names(S)[-(1:2)]) set(S, which(is.na(S[[cc]])), cc, 0)
  W <- mkW(site_dt$SITE, idxs); rownames(W) <- site_dt$STAND; W <- W[S$STAND, , drop = FALSE]   # draws on sites in the given (results) order
  r <- function(num, den) { pt <- sum(num) / sum(den); bb <- colSums(W * num) / colSums(W * den); c(pt, q95(bb)) }
  L <- rbind(
    data.table(set = lab, quantity = "H_o t1: V(measured HT1)/V(himp)", t(r(S$v1m, S$v1h))),
    data.table(set = lab, quantity = "H_o t2: V(measured HT2)/V(himp)", t(r(S$v2m, S$v2h))),
    data.table(set = lab, quantity = "E1 bound: V(HT2 + 0.5 m)/V(HT2)", t(r(S$v2m05, S$v2m))),
    data.table(set = lab, quantity = "Survivor mean HT2/HT1", t(r(S$sH2, S$sH1))),
    data.table(set = lab, quantity = "Survivor share dH < -1 m", t(r(S$nneg1, S$ns))),
    data.table(set = lab, quantity = "Survivor share dH > 8 m per decade", t(r(S$nbig, S$ns))),
    data.table(set = lab, quantity = "Survivor share units flag (HT2/HT1 near 3.281 or 0.3048)", t(r(S$nunits, S$ns))))
  setnames(L, c("V1", "V2", "V3"), c("est", "lo", "hi"))
  dist <- sv[, .(set = lab, survivors = .N, stands = uniqueN(STAND), dH_mean = mean(dH), dH_p05 = quantile(dH, .05), dH_p25 = quantile(dH, .25), dH_p50 = median(dH),
                 dH_p75 = quantile(dH, .75), dH_p95 = quantile(dH, .95), share_dH_neg = mean(dH < 0), share_dH_lt_m1 = mean(dH < -1), share_dH_lt_m3 = mean(dH < -3),
                 dH10_mean = mean(dH10), vol_share_dH_lt_m1 = sum(v1[dH < -1]) / sum(v1))]
  dcl <- sv[, .(set = lab, n = .N, dH10_mean = mean(dH10), dH10_p50 = median(dH10), share_dH_lt_m1 = mean(dH < -1), H1_mean = mean(H1)), by = .(dbh_class = dbhcls(D1))][order(dbh_class)]
  hcl <- sv[, .(set = lab, n = .N, dH10_mean = mean(dH10), dH10_p50 = median(dH10), share_dH_lt_m1 = mean(dH < -1)), by = .(ht1_class = htcls(H1))][order(ht1_class)]
  list(E = E, L = L, dist = dist, dcl = dcl, hcl = hcl, units_n = sum(sv$units_flag), out_n = sum(flag_ht(sv$H1)) + sum(flag_ht(sv$H2)))
}

## ======================= model side: the full decomposition on the target set ====================================
r <- fread(RES); need(r, c("STAND", "SITE", "RUN_OK", "SCORE_MINDBH_USED", "TOTVOL_o", "TOTVOL_p"), "results")
r[, STAND := as.character(STAND)]; if (anyDuplicated(r$STAND)) hs("duplicated STAND in results")
r[, scored := RUN_OK == 1 & is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]; SC <- r[scored == TRUE, STAND]
sm <- r[scored == TRUE, .(STAND, SMD = SCORE_MINDBH_USED)]
prs <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", SET))); need(prs, c("STAND", "SITE", "INTERVAL_DEC"), "pairs"); prs[, STAND := as.character(STAND)]
P <- rd_chunks(TDIRS, "^c[0-9]+_pred_t2_tree\\.csv$"); need(P, c("STAND", "tree", "sp", "dbh", "ht", "expf", "ing"), "pred_t2_tree"); P <- P[STAND %in% SC]
T1 <- rd_chunks(TDIRS, "^c[0-9]+_t1_split_tree\\.csv$"); need(T1, c("STAND", "tree", "sp", "dbh", "ht", "expf"), "t1_split_tree"); T1 <- T1[STAND %in% SC]
Y1 <- rd_chunks(TDIRS, "^c[0-9]+_pred_yr1_tree\\.csv$"); need(Y1, c("STAND", "tree", "sp", "dbh", "ht", "pht", "expf", "ing"), "pred_yr1_tree"); Y1 <- Y1[STAND %in% SC]
F <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", SET))); need(F, c("STAND", "TREE", "SP", "DBH", "HT", "EXPF"), "tree_init")
O2 <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_t2.csv", SET))); need(O2, c("STAND", "TREE", "SP", "DBH", "HT", "EXPF"), "tree_t2")
F[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]; F <- F[STAND %in% SC]; F[, sp := mapsp(SP)]
O2[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND]; O2 <- O2[STAND %in% SC]; O2[, spm := mapsp(SP)]
if (!setequal(unique(P$STAND), SC)) hs("per tree t2 list covers %d of %d scored stands", uniqueN(P$STAND), length(SC))
O2 <- merge(O2, sm, by = "STAND"); P <- merge(P, sm, by = "STAND")
cat(sprintf("stands %d, pred records %d (ingrowth %d), t1 frame %d, t2 frame %d\n", length(SC), nrow(P), sum(P$ing == 1), nrow(F), nrow(O2)))

## ---- V0 identity and the gap reference
O2[, `:=`(vo = vrec(spm, DBH, HT, EXPF, SMD), voh = vrec(spm, DBH, rep(NA_real_, .N), EXPF, SMD))]
P[, `:=`(vp = vrec(sp, dbh, ht, expf, SMD), vph = vrec(sp, dbh, rep(NA_real_, .N), expf, SMD))]
VV <- merge(merge(r[scored == TRUE, .(STAND, SITE, TOTVOL_o, TOTVOL_p)], O2[, .(V_o = sum(vo), V_oh = sum(voh)), by = STAND], by = "STAND", all.x = TRUE),
            P[, .(V_p = sum(vp), V_ph = sum(vph)), by = STAND], by = "STAND", all.x = TRUE)
for (cc in c("V_o", "V_oh", "V_p", "V_ph")) set(VV, which(is.na(VV[[cc]])), cc, 0)
v0o <- max(rel(VV$V_o, VV$TOTVOL_o)); v0p <- max(rel(VV$V_p, VV$TOTVOL_p))
if (!(v0o <= 1e-6 && v0p <= 1e-6)) hs("V0: C0 not reproduced (max rel o %.2e p %.2e)", v0o, v0p)
G0 <- (sum(VV$V_p) / sum(VV$V_ph)) / (sum(VV$V_o) / sum(VV$V_oh))
GATES <- list(data.table(gate = "V0 identity", value = sprintf("max rel o %.2e p %.2e", v0o, v0p), pass = TRUE))
if (nzchar(GAPREF)) { gr <- fread(GAPREF)[label == GAPLAB & arm == "v141LT" & pop == "all" & conv == "gap C0/C1"]
  if (nrow(gr) != 1) hs("gap reference row not found for %s", GAPLAB)
  if (abs(G0 - gr$ratio) > 0.001) hs("G %.5f differs from PREREG16 gap %.5f by more than 0.001", G0, gr$ratio)
  GATES[[2]] <- data.table(gate = "G reproduces PREREG16 gap", value = sprintf("%.5f vs %.5f", G0, gr$ratio), pass = TRUE) }
cat(sprintf("G = %.5f\n", G0))

## ---- split map and tags
if (is.null(split_map)) hs("P21_SPLIT is required for the model side")
M <- split_map(F)
x <- merge(M, T1, by = c("STAND", "tree"), all = TRUE, suffixes = c("", "_r"))
bad <- x[is.na(row0) | is.na(sp_r) | sp != sp_r | abs(dbh - dbh_r) > 1e-6 | abs(expf - expf_r) > 1e-6 * pmax(1, expf)]
if (nrow(bad)) hs("split map disagrees with the runner t1 list on %d records", nrow(bad))
GATES[[length(GATES) + 1]] <- data.table(gate = "split map vs runner t1 list", value = sprintf("%d records agree", nrow(x)), pass = TRUE)
## (a) model t1 height against measured HT1, record level
x <- merge(x, F[, .(STAND, row0, HT1 = HT, TAG1 = TREE)], by = c("STAND", "row0"))
x <- merge(x, sm, by = "STAND")
x[, meas1 := is.finite(HT1) & HT1 > 0]
x[, `:=`(v_mod1 = vrec(sp, dbh, ht, expf, SMD), v_meas1 = vrec(sp, dbh, fifelse(meas1, HT1, NA_real_), expf, SMD), v_h1 = vrec(sp, dbh, rep(NA_real_, .N), expf, SMD))]
x[, differs := !(meas1 & is.finite(ht) & abs(ht - HT1) <= 1e-4)]
A1 <- x[, .(v_mod1 = sum(v_mod1), v_meas1 = sum(v_meas1), v_h1 = sum(v_h1), v_diff = sum(v_mod1[differs]), n = .N, ndiff = sum(differs)), by = STAND]
## year 1: pht (the height diameter equation) against the grown measured height
Y1 <- merge(Y1, sm, by = "STAND")[ing == 0]
Y1[, `:=`(v_ht = vrec(sp, dbh, ht, expf, SMD), v_pht = vrec(sp, dbh, pht, expf, SMD), v_hi = vrec(sp, dbh, rep(NA_real_, .N), expf, SMD))]
AY <- Y1[, .(v_ht = sum(v_ht), v_pht = sum(v_pht), v_hi = sum(v_hi), sht = sum((ht * expf)[is.finite(pht)]), spht = sum((pht * expf)[is.finite(pht)])), by = STAND]
YC <- Y1[is.finite(pht), .(n = .N, pht_over_ht = sum(pht * expf) / sum(ht * expf), himp_over_ht = sum(himp(sp, dbh) * expf) / sum(ht * expf)), by = .(dbh_class = dbhcls(dbh))][order(dbh_class)]

## ---- groups S, D, I on the predicted list
t1g <- F[tagok(TREE), .(STAND, TAG = TREE, row0)]; t2g <- O2[tagok(TREE), .(STAND, TAG = TREE, row2 = row0, SP2 = SP, H2 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]
d1 <- t1g[, .N, by = .(STAND, TAG)][N > 1]; d2 <- t2g[, .N, by = .(STAND, TAG)][N > 1]
t1g <- t1g[!d1, on = .(STAND, TAG)]; t2g <- t2g[!d2, on = .(STAND, TAG)]
sv <- merge(merge(t1g, F[, .(STAND, row0, SP1 = SP, HT1 = HT, D1 = DBH)], by = c("STAND", "row0")), t2g, by = c("STAND", "TAG"))
Ssv <- sv[SP1 == SP2 & is.finite(H2)]
cat(sprintf("tags: t1 %d, t2 %d, matched %d, same SP with HT2 %d; duplicate keys t1 %d t2 %d\n", nrow(t1g), nrow(t2g), nrow(sv), nrow(Ssv), nrow(d1), nrow(d2)))
PX <- merge(P, M[, .(STAND, tree, row0)], by = c("STAND", "tree"), all.x = TRUE)
PX[ing == 1, row0 := NA_integer_]
if (PX[ing == 0 & is.na(row0), .N]) hs("%d non ingrowth predicted records do not map to a t1 frame row", PX[ing == 0 & is.na(row0), .N])
PX <- merge(PX, Ssv[, .(STAND, row0, H2, HT1, D1, row2)], by = c("STAND", "row0"), all.x = TRUE)
PX[, grp := fifelse(ing == 1, "I", fifelse(is.finite(H2), "S", "D"))]
PX[, swg := fifelse(sp %in% sw, "SW", "HW")][, dcl := dbhcls(dbh)]
PX[, flag_any := flag_ht(ht) | flag_ht(H2) | flag_ht(HT1)]
## survivor calibration ratio for D (by DBH class and group, pooled if fewer than 30 survivors)
cal <- PX[grp == "S", .(n = uniqueN(paste(STAND, row0)), rS = sum(H2 * expf) / sum(ht * expf)), by = .(dcl, swg)]
rS_pool <- PX[grp == "S", sum(H2 * expf) / sum(ht * expf)]
cal[, rS_use := fifelse(n >= 30, rS, rS_pool)]
PX <- merge(PX, cal[, .(dcl, swg, rS_use)], by = c("dcl", "swg"), all.x = TRUE); PX[is.na(rS_use), rS_use := rS_pool]
## observed ingrowth level (observed t2 trees without a t1 tag match) for I
O2[, matched := FALSE]; O2[sv, on = .(STAND, row0 = row2), matched := TRUE]
O2[, `:=`(dcl = dbhcls(DBH), swg = fifelse(spm %in% sw, "SW", "HW"))]
oi <- O2[matched == FALSE & DBH >= SMD, .(n = .N, Ro = sum(vo) / sum(voh)), by = .(dcl, swg)]
Ro_pool <- O2[matched == FALSE & DBH >= SMD, sum(vo) / sum(voh)]
oi[, Ro_use := fifelse(n >= 30, Ro, Ro_pool)]
PX <- merge(PX, oi[, .(dcl, swg, Ro_use)], by = c("dcl", "swg"), all.x = TRUE); PX[is.na(Ro_use), Ro_use := Ro_pool]
## substituted heights and volumes
PX[, ht_sub := ht]
PX[grp == "S", ht_sub := H2]
PX[grp == "D", ht_sub := ht * rS_use]
PX[grp == "I", ht_sub := himp(sp, dbh) * Ro_use]
PX[, vsub := vrec(sp, dbh, ht_sub, expf, SMD)]
PX[, dv := vp - vsub]            # volume removed by substituting this record
## species (top six by predicted volume), DBH class, t1 height class for the S breakdown
topsp <- PX[, .(v = sum(vp)), by = sp][order(-v)][1:min(6, .N), sp]
PX[, spk := fifelse(sp %in% topsp, sp, "other")][, h1c := htcls(HT1)]
## E2: anomalous survivors (observed increment below -1 m, or above 8 m per decade)
PX <- merge(PX, prs[, .(STAND, IV = INTERVAL_DEC)], by = "STAND", all.x = TRUE)
PX[, anom := grp == "S" & ((H2 - HT1) < -1 | (H2 - HT1) * 10 / IV > 8)]

## ---- stand level sums
st <- r[scored == TRUE, .(STAND, SITE)]
sumby <- function(expr_dt, nm) { z <- expr_dt; setnames(z, "val", nm); z }
agg <- PX[, .(dS = sum(dv[grp == "S"]), dD = sum(dv[grp == "D"]), dI = sum(dv[grp == "I"]), dSanom = sum(dv[anom]), dSflag = sum(dv[grp == "S" & flag_any]),
              vS = sum(vp[grp == "S"]), vD = sum(vp[grp == "D"]), vI = sum(vp[grp == "I"])), by = STAND]
Z <- Reduce(function(a, b) merge(a, b, by = "STAND", all.x = TRUE), list(st, VV[, .(STAND, V_o, V_oh, V_p, V_ph)], agg, A1, AY))
for (cc in setdiff(names(Z), c("STAND", "SITE"))) set(Z, which(is.na(Z[[cc]])), cc, 0)
catmat <- function(col) { d <- PX[grp == "S", .(v = sum(dv)), by = c("STAND", col)]; w <- dcast(d, as.formula(paste("STAND ~", col)), value.var = "v", fill = 0)
  w <- merge(st[, .(STAND)], w, by = "STAND", all.x = TRUE, sort = FALSE); w[is.na(w)] <- 0; w }
Csp <- catmat("spk"); Cd <- catmat("dcl"); Ch <- catmat("h1c")
stopifnot(identical(Csp$STAND, Z$STAND), identical(Cd$STAND, Z$STAND), identical(Ch$STAND, Z$STAND))

## ---- bootstrap weights exactly as PREREG15 (sites in results order)
W <- mkW(as.character(r$SITE), IDXS); rownames(W) <- r$STAND; W <- W[Z$STAND, , drop = FALSE]
cs <- function(v) c(sum(v), colSums(W * v))          # element 1 = point, 2..B+1 = draws
Vp <- cs(Z$V_p); Vph <- cs(Z$V_ph); Vo <- cs(Z$V_o); Voh <- cs(Z$V_oh)
Ho <- Vo / Voh; logG <- function(vp) log(vp / Vph) - log(Ho)
lG0 <- logG(Vp)
dS <- cs(Z$dS); dD <- cs(Z$dD); dI <- cs(Z$dI)
## Shapley over three disjoint substitutions
comb <- list(S = dS, D = dD, I = dI); nm <- names(comb)
lGset <- function(sel) { v <- Vp; for (k in sel) v <- v - comb[[k]]; logG(v) }
shap <- lapply(nm, function(k) { oth <- setdiff(nm, k); acc <- 0
  for (s in list(character(0), oth[1], oth[2], oth)) { wgt <- factorial(length(s)) * factorial(3 - length(s) - 1) / factorial(3)
    acc <- acc + wgt * (lGset(s) - lGset(c(s, k))) }
  acc }); names(shap) <- nm
lRes <- lGset(nm)
sm3 <- function(v) c(est = v[1], lo = q95(v[-1])[1], hi = q95(v[-1])[2])
share <- function(v) sm3(v / lG0)
COMP <- rbindlist(lapply(c(nm, "residual"), function(k) { v <- if (k == "residual") lRes else shap[[k]]
  data.table(set = LAB, component = k, logpts = sm3(v)[1], logpts_lo = sm3(v)[2], logpts_hi = sm3(v)[3], share = share(v)[1], share_lo = share(v)[2], share_hi = share(v)[3]) }))
COMP <- rbind(data.table(set = LAB, component = "total log G", logpts = lG0[1], logpts_lo = q95(lG0[-1])[1], logpts_hi = q95(lG0[-1])[2], share = 1, share_lo = NA_real_, share_hi = NA_real_), COMP)
COMP[, `:=`(G_pct = 100 * (exp(logpts) - 1))]
## S plus D (explanation b), with share and interval
bSD <- shap$S + shap$D
COMP <- rbind(COMP, data.table(set = LAB, component = "S+D (b)", logpts = sm3(bSD)[1], logpts_lo = sm3(bSD)[2], logpts_hi = sm3(bSD)[3],
                               share = share(bSD)[1], share_lo = share(bSD)[2], share_hi = share(bSD)[3], G_pct = 100 * (exp(bSD[1]) - 1)))
## single substitution contributions and E2 / flag sensitivities for S
single <- function(dv) lG0 - logG(Vp - dv)
S1 <- single(dS); S1_noanom <- single(dS - cs(Z$dSanom)); S1_noflag <- single(dS - cs(Z$dSflag))
SENS <- rbind(
  data.table(set = LAB, quantity = "S single substitution, log points", t(sm3(S1))),
  data.table(set = LAB, quantity = "S single, anomalous survivors kept at model heights (E2)", t(sm3(S1_noanom))),
  data.table(set = LAB, quantity = "E2 reduction share of S single", t(sm3(1 - S1_noanom / S1))),
  data.table(set = LAB, quantity = "S single, survivors with any height outside 1 to 45 m kept at model heights", t(sm3(S1_noflag))))
setnames(SENS, c("V1", "V2", "V3"), c("est", "lo", "hi"), skip_absent = TRUE)
## S breakdown by species, DBH class, t1 height class (single substitution of that category, share of S single)
brk <- function(C, what) rbindlist(lapply(setdiff(names(C), "STAND"), function(k) { c1 <- single(cs(C[[k]]))
  data.table(set = LAB, by = what, level = k, logpts = c1[1], lo = q95(c1[-1])[1], hi = q95(c1[-1])[2], share_of_S = c1[1] / S1[1],
             share_lo = q95(c1[-1] / S1[-1])[1], share_hi = q95(c1[-1] / S1[-1])[2]) }))
BRK <- rbind(brk(Csp, "species"), brk(Cd, "dbh_class"), brk(Ch, "ht1_class"))
## height levels
lev <- function(num, den, q) { a <- cs(num); b <- cs(den); v <- a / b; data.table(set = LAB, quantity = q, est = v[1], lo = q95(v[-1])[1], hi = q95(v[-1])[2]) }
LEV <- rbind(
  lev(Z$V_p, Z$V_ph, "H_p t2: V(model HT2)/V(himp)"), lev(Z$V_o, Z$V_oh, "H_o t2: V(measured HT2)/V(himp)"),
  lev(Z$v_mod1, Z$v_meas1, "(a) t1: V(model t1 ht)/V(measured HT1)"), lev(Z$v_diff, Z$v_mod1, "(a) share of t1 volume on records whose model ht differs from HT1"),
  lev(Z$v_meas1, Z$v_h1, "H_o t1: V(measured HT1)/V(himp), split records"),
  lev(Z$v_pht, Z$v_ht, "(a latent) yr1: V(pht)/V(ht)"), lev(Z$spht, Z$sht, "(a latent) yr1: sum pht/sum ht, expf weighted"),
  lev(Z$v_hi, Z$v_ht, "yr1: V(himp)/V(ht)"),
  lev(Z$vS, Z$V_p, "S share of predicted volume"), lev(Z$vD, Z$V_p, "D share of predicted volume"), lev(Z$vI, Z$V_p, "I share of predicted volume"))
## survivor tree level: model over measured HT2 and model over observed increment, by class (stand sums, expf weighted, one row per t1 tree)
TS <- PX[grp == "S", .(mH2 = sum(ht * expf) / sum(expf), H2 = H2[1], HT1 = HT1[1], D1 = D1[1], dbh2 = sum(dbh * expf) / sum(expf), sp = sp[1], ex = sum(expf)), by = .(STAND, row0)]
TS[, `:=`(mdH = mH2 - HT1, odH = H2 - HT1)]
clsr <- function(byv, what) { d <- TS[, .(mH2 = sum(mH2 * ex), H2 = sum(H2 * ex), mdH = sum(mdH * ex), odH = sum(odH * ex), n = .N), by = c("STAND", byv)]
  rbindlist(lapply(sort(unique(as.character(d[[byv]]))), function(k) { dd <- merge(st[, .(STAND)], d[as.character(get(byv)) == k], by = "STAND", all.x = TRUE, sort = FALSE)
    for (cc in c("mH2", "H2", "mdH", "odH", "n")) set(dd, which(is.na(dd[[cc]])), cc, 0)
    a <- cs(dd$mH2) / cs(dd$H2); b <- cs(dd$mdH) / cs(dd$odH)
    data.table(set = LAB, by = what, level = k, trees = sum(dd$n), mH2_over_H2 = a[1], lo = q95(a[-1])[1], hi = q95(a[-1])[2],
               mdH_over_odH = b[1], dlo = q95(b[-1])[1], dhi = q95(b[-1])[2], odH_mean = sum(dd$odH) / sum(TS[as.character(get(byv)) == k, ex]),
               mdH_mean = sum(dd$mdH) / sum(TS[as.character(get(byv)) == k, ex])) })) }
TS[, `:=`(all = "all", dcl1 = as.character(dbhcls(D1)), h1c = as.character(htcls(HT1)), spk = fifelse(sp %in% topsp, sp, "other"))]
SURV <- rbind(clsr("all", "all"), clsr("dcl1", "dbh_class_t1"), clsr("h1c", "ht1_class"), clsr("spk", "species"))
FLAGS <- data.table(set = LAB, item = c("model t2 ht outside 1 to 45 m", "survivor HT1 outside 1 to 45 m", "survivor HT2 outside 1 to 45 m", "pred records S", "pred records D", "pred records I",
                                        "D cells pooled", "I cells pooled", "survivor calibration pooled rS", "observed ingrowth pooled Ro"),
                    value = c(sum(flag_ht(P$ht)), sum(flag_ht(TS$HT1)), sum(flag_ht(TS$H2)), PX[grp == "S", .N], PX[grp == "D", .N], PX[grp == "I", .N],
                              cal[n < 30, .N], oi[n < 30, .N], rS_pool, Ro_pool))
CAL <- rbind(cal[, .(set = LAB, kind = "D survivor ratio", dcl, swg, n, value = rS, used = rS_use)], oi[, .(set = LAB, kind = "I observed level", dcl, swg, n, value = Ro, used = Ro_use)])

## ---- observed side tests on this set (and the control frame if given)
smd_dt <- sm; site_dt <- merge(r[scored == TRUE, .(STAND, SITE)], prs[, .(STAND, IV = INTERVAL_DEC)], by = "STAND"); site_dt <- site_dt[match(r[scored == TRUE, STAND], STAND)]
if (nrow(site_dt) != nrow(r)) hs("observed side bootstrap needs every results row scored (%d of %d)", nrow(site_dt), nrow(r))
OBS <- list(obs_side(FR, SET, smd_dt, site_dt, IDXS, LAB))
if (nzchar(CTRL_FR)) { cp <- fread(file.path(CTRL_FR, sprintf("bench_gyr_%s_pairs.csv", CTRL_SET))); need(cp, c("STAND", "SITE", "INTERVAL_DEC", "SCORE_MINDBH_OBS"), "control pairs")
  cp[, STAND := as.character(STAND)]
  OBS[[2]] <- obs_side(CTRL_FR, CTRL_SET, cp[, .(STAND, SMD = SCORE_MINDBH_OBS)], cp[, .(STAND, SITE, IV = INTERVAL_DEC)], "SEED:20260916:2000", paste0(CTRL_SET, "_obs")) }
OE <- rbindlist(lapply(OBS, `[[`, "E")); OL <- rbindlist(lapply(OBS, `[[`, "L")); OD <- rbindlist(lapply(OBS, `[[`, "dist"))
ODC <- rbindlist(lapply(OBS, `[[`, "dcl")); OHC <- rbindlist(lapply(OBS, `[[`, "hcl"))
## E1 bound as a share of log G on the target set
e1 <- OL[set == LAB & quantity == "E1 bound: V(HT2 + 0.5 m)/V(HT2)"]
SENS <- rbind(SENS, data.table(set = LAB, quantity = "E1 bound share of log G (0.5 m added to all HT2)", est = log(e1$est) / lG0[1], lo = NA_real_, hi = NA_real_))

## ---- write
wout(rbindlist(GATES), "gates"); wout(COMP, "components"); wout(SENS, "sensitivity"); wout(BRK, "S-breakdown"); wout(LEV, "levels")
wout(SURV, "survivors"); wout(YC, "yr1-pht-by-dbh"); wout(FLAGS, "flags"); wout(CAL, "calibration")
wout(OE, "obs-grids-ranges"); wout(OL, "obs-levels"); wout(OD, "obs-dH-dist"); wout(ODC, "obs-dH-by-dbh"); wout(OHC, "obs-dH-by-ht1")

## ---- figures (headless, theme_classic, 300 dpi, 7 by 5 in)
f1 <- COMP[component %in% c("S", "D", "I", "residual")]
f1[, component := factor(component, levels = c("S", "D", "I", "residual"), labels = c("S survivors", "D unmatched", "I ingrowth", "Residual"))]
g1 <- ggplot(f1, aes(component, G_pct)) + geom_hline(yintercept = 0, colour = "grey60") +
  geom_col(fill = "grey70", width = 0.6) + geom_errorbar(aes(ymin = 100 * (exp(logpts_lo) - 1), ymax = 100 * (exp(logpts_hi) - 1)), width = 0.15) +
  labs(x = NULL, y = "Contribution to C0/C1 volume gap (%)", title = sprintf("%s: Shapley decomposition of the +%.1f%% gap", LAB, 100 * (G0 - 1))) + theme_classic(base_size = 11)
ggsave(file.path(OUT, sprintf("gyr142-p21-%s-components_%s.png", LAB, DSTAMP)), g1, width = 7, height = 5, dpi = 300)
f2 <- SURV[by %in% c("dbh_class_t1", "ht1_class")]
f2[, by := factor(by, levels = c("dbh_class_t1", "ht1_class"), labels = c("t1 DBH class (cm)", "t1 height class (m)"))]
f2[, level := factor(level, levels = c("<15", "15-25", "25-35", ">=35", "15-20", "20-25", ">=25"))]
g2 <- ggplot(f2, aes(level, mH2_over_H2)) + geom_hline(yintercept = 1, colour = "grey60") + geom_pointrange(aes(ymin = lo, ymax = hi)) +
  facet_wrap(~by, scales = "free_x") + labs(x = NULL, y = "Model t2 height / measured t2 height (m/m)",
  title = sprintf("%s: tag matched survivors, site cluster 95%% intervals", LAB)) + theme_classic(base_size = 11)
ggsave(file.path(OUT, sprintf("gyr142-p21-%s-survivor-ht_%s.png", LAB, DSTAMP)), g2, width = 7, height = 5, dpi = 300)
print(COMP); print(SENS); print(LEV); print(SURV[by %in% c("all", "dbh_class_t1", "ht1_class")]); print(OL); print(OD); print(OE)
cat("P21_DONE\n")

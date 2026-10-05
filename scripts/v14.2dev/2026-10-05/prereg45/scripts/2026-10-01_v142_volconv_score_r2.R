## PREREG16: symmetric height convention for benchmark volume scoring. Scoring only: reads frozen per tree outputs,
## changes no engine, coefficient, default or run. C0 as published, C1 himp on both sides (primary), C2 measured
## height where measured on tag matched survivors, himp elsewhere, both sides (tag stable sets). Volume code verbatim
## from runner md5 300a0d61 through firebreather ~/jobs/v142p14/scripts/p14_common.R. Host agnostic: a plan CSV names
## every input. Aggregates only are written; no coordinates are read or written. No em dashes.
## r2 (PREREG35, 2026-10-01): additions only. Adds three checks, reported and not used for admission unless VC_R2_ENFORCE=1:
## (a) defect gate, a V_o = 0 stand whose source t2 frame holds a live stem at or above SCORE_MINDBH_USED with EXPF > 0;
## (b) exclusion as harvested or lost only on a positive record; (c) an established at t1 stratum (V_o1 > 0) reported beside
## the all stands row where more than 5 percent of scored stands have V_o1 = 0. Every PREREG16 output is unchanged.
suppressMessages(library(data.table)); options(width = 220, datatable.print.nrows = 200)
SEED <- 20260927L; set.seed(SEED)
OUT  <- Sys.getenv("VC_OUT"); PLANF <- Sys.getenv("VC_PLAN"); REFD <- path.expand(Sys.getenv("VC_REFDIR"))
SPLITF <- path.expand(Sys.getenv("VC_SPLIT")); TRTF <- Sys.getenv("VC_TRT", ""); TAGOUT <- Sys.getenv("VC_TAG", "vc")
if (!nzchar(OUT) || !nzchar(PLANF)) stop("VC_OUT and VC_PLAN are required")
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
DSTAMP <- "2026-09-27"
ERR <- file.path(OUT, "error_log.txt")
cat(sprintf("volconv R %s data.table %s OUT=%s PLAN=%s host=%s seed=%d\n", getRversion(), packageVersion("data.table"), OUT, PLANF, Sys.info()[["nodename"]], SEED))
hs <- function(fmt, ...) { m <- sprintf(fmt, ...); cat("HARD STOP:", m, "\n"); cat(m, "\n", file = file.path(OUT, "_hardstop.txt"), append = TRUE); quit(save = "no", status = 3) }
wout <- function(x, nm) { f <- file.path(OUT, sprintf("gyr142-%s-%s_PROVISIONAL_%s.csv", TAGOUT, nm, DSTAMP)); fwrite(x, f); cat(sprintf("wrote %s (%d rows)\n", basename(f), nrow(x))) }
eqna <- function(a, b, tol = 1e-6) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
rel <- function(a, b) abs(a - b) / pmax(1, abs(b))

## ---- verbatim from the runner (via p14_common.R): species codes, himp, NSVB emulator ------------------------
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
RESP<-c("VOLCFGRS","VOLCFNET","VOLCSNET","DRYBIO_AG"); CF<-list()
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
## TOTVOL exactly as metrics(): live filter, then sum(nsvb(VOLCFGRS) * expf) * FT3_M3
totvol <- function(sp, dbh, ht, expf, mindbh) { live <- is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0
  if (!any(live)) return(0); sum(nsvb(sp[live], dbh[live], ht[live], "VOLCFGRS") * expf[live]) * FT3_M3 }

## ---- form/risk split id map, verbatim from p14_common.R (hw_formrisk_split.R md5 0b604bab, prune 0.03) --------
.SPLIT_QUIET <- TRUE; source(SPLITF)
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
}

## ---- QC harvest screen, rule verbatim from recs/diag3/2026-09-26_v142_qcscreen_nsvol.R (via p14_common.R) -----
trt <- if (nzchar(TRTF)) fread(TRTF, colClasses = list(character = "magp_site_id")) else NULL
cut_stands <- function(p) { p <- copy(p)[, site := substr(as.character(PLOTKEY), 1, 8)]
  trt[p, on = .(magp_site_id = site), allow.cartesian = TRUE, nomatch = 0L][substr(treatment_type, 1, 1) == "C" & treatment_year > Y1 & treatment_year <= Y2, unique(STAND)] }

## ---- helpers --------------------------------------------------------------------------------------------------
rd_chunks <- function(dirs, pat) { dirs <- strsplit(dirs, ";", fixed = TRUE)[[1]]; acc <- NULL
  for (d in dirs) { fs <- sort(list.files(d, pattern = pat, full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, STAND := as.character(STAND)]
    if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]   # later directory (retry) replaces whole stands
    acc <- rbind(acc, x, fill = TRUE) }
  acc }
wts <- function(IDX, sid, nsite) { CNT <- matrix(0L, nsite, ncol(IDX)); for (b in seq_len(ncol(IDX))) CNT[, b] <- tabulate(IDX[, b], nbins = nsite)
  W <- CNT[sid, , drop = FALSE]; storage.mode(W) <- "double"; W }
q95 <- function(x) quantile(x, c(0.025, 0.975), names = FALSE, na.rm = TRUE)
## point and bootstrap: ratio of sums, bias percent, percent RMSE, all weighted by site draw counts
sc <- function(o, p, W) { r0 <- sum(p) / sum(o); b0 <- 100 * (mean(p) - mean(o)) / mean(o); m0 <- 100 * sqrt(mean((p - o)^2)) / mean(o)
  sw_ <- colSums(W); so <- colSums(W * o); sp_ <- colSums(W * p); rb <- sp_ / so
  mb <- 100 * sqrt(colSums(W * (p - o)^2) / sw_) / (so / sw_)
  list(pt = c(ratio = r0, bias_pct = b0, rmse_pct = m0), rb = rb, ci_ratio = q95(rb), ci_rmse = q95(mb)) }

PLAN <- fread(PLANF, colClasses = "character")
print(PLAN[, .(label, set, arm, c2, v0_hard)])
ST <- list(); GT <- list(); SH <- list(); STANDS <- list(); C2COV <- list(); ADM <- list(); ALN <- list()
## ---- r2 additions: containers, enforcement switch, stratum threshold, stand basal area and stems at the floor
DEF <- list(); EXC <- list(); STRS <- list(); STR <- list(); R2ENF <- Sys.getenv("VC_R2_ENFORCE", "") == "1"; R2THR <- 0.05
livef <- function(dbh, expf, mindbh) is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0
bastem <- function(dbh, expf, mindbh) { l <- livef(dbh, expf, mindbh); c(BA = sum(pi / 40000 * dbh[l]^2 * expf[l]), N = sum(expf[l])) }
for (i in seq_len(nrow(PLAN))) {
  pl <- PLAN[i]; t0 <- Sys.time(); lab <- pl$label; s <- pl$set; arm <- pl$arm; v0_hard <- pl$v0_hard == "TRUE"
  cat(sprintf("==== %s (%s, %s)\n", lab, s, arm))
  r <- tryCatch(fread(pl$res), error = function(e) { cat(conditionMessage(e), "\n", file = ERR, append = TRUE); NULL })
  if (is.null(r)) hs("%s %s: published results unreadable", lab, arm)
  r[, STAND := as.character(STAND)]
  for (cc in c("SITE", "RUN_OK", "SCORE_MINDBH_USED", "TOTVOL_o", "TOTVOL_p")) if (!cc %in% names(r)) hs("%s %s: results lack %s", lab, arm, cc)
  if (anyDuplicated(r$STAND)) hs("%s %s: duplicated STAND in results", lab, arm)
  r[, scored := RUN_OK == 1 & is.finite(TOTVOL_o) & is.finite(TOTVOL_p)]
  SC <- r[scored == TRUE, STAND]
  P <- rd_chunks(pl$tree_dirs, "^c[0-9]+_pred_t2_tree\\.csv$")
  if (is.null(P)) { ADM[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, admitted = FALSE, reason = "no per tree outputs"); if (v0_hard) hs("%s %s: no per tree outputs", lab, arm); next }
  P <- P[STAND %in% SC]
  O2 <- fread(file.path(pl$fr, sprintf("bench_gyr_%s_tree_t2.csv", s)))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% SC]
  if (!setequal(unique(P$STAND), SC)) {
    msg <- sprintf("per tree t2 list covers %d of %d scored stands", uniqueN(P$STAND), length(SC))
    if (v0_hard) hs("%s %s: %s", lab, arm, msg)
    ADM[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, admitted = FALSE, reason = msg); next }
  sm <- r[scored == TRUE, .(STAND, SMD = SCORE_MINDBH_USED)]
  vo <- merge(O2, sm, by = "STAND")[, .(V_o = totvol(mapsp(SP), DBH, HT, EXPF, SMD[1]), V_oh = totvol(mapsp(SP), DBH, rep(NA_real_, .N), EXPF, SMD[1])), by = STAND]
  vp <- merge(P, sm, by = "STAND")[, .(V_p = totvol(sp, dbh, ht, expf, SMD[1]), V_ph = totvol(sp, dbh, rep(NA_real_, .N), expf, SMD[1])), by = STAND]
  VV <- Reduce(function(a, b) merge(a, b, by = "STAND", all = TRUE), list(r[scored == TRUE, .(STAND, SITE, TOTVOL_o, TOTVOL_p)], vo, vp))
  ## ---- V0 identity (PREREG14 C5 formulation)
  v0o <- max(rel(VV$V_o, VV$TOTVOL_o), na.rm = FALSE); v0p <- max(rel(VV$V_p, VV$TOTVOL_p), na.rm = FALSE)
  v0 <- is.finite(v0o) && is.finite(v0p) && v0o <= 1e-6 && v0p <= 1e-6
  GT[[paste(lab, arm, "V0")]] <- data.table(label = lab, arm = arm, gate = "V0 identity", value = sprintf("max rel o %.2e p %.2e", v0o, v0p), pass = v0)
  if (!v0) { if (v0_hard) hs("V0 %s %s: C0 not reproduced (max rel o %.2e p %.2e)", lab, arm, v0o, v0p)
    ADM[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, admitted = FALSE, reason = sprintf("V0 failed: max rel o %.2e p %.2e", v0o, v0p)); next }
  ## ---- V1 coverage and V2 bounds on C1
  v1 <- nrow(VV) == length(SC) && all(is.finite(VV$V_oh)) && all(is.finite(VV$V_ph))
  GT[[paste(lab, arm, "V1")]] <- data.table(label = lab, arm = arm, gate = "V1 coverage", value = sprintf("C1 finite on %d of %d scored stands", VV[is.finite(V_oh) & is.finite(V_ph), .N], length(SC)), pass = v1)
  if (!v1) hs("V1 %s %s: C1 coverage differs from the published scored stands", lab, arm)
  rng <- range(c(VV$V_oh, VV$V_ph))
  v2 <- rng[1] >= 0 && rng[2] <= 1500
  GT[[paste(lab, arm, "V2")]] <- data.table(label = lab, arm = arm, gate = "V2 bounds", value = sprintf("C1 stand volume %.1f to %.1f m3/ha", rng[1], rng[2]), pass = v2)
  if (!v2) hs("V2 %s %s: C1 stand volume outside 0 to 1500 (%.1f to %.1f)", lab, arm, rng[1], rng[2])
  ## ---- measured height share at t2 (observed trees scored at t2: live, at or above the scoring floor)
  o2 <- merge(O2, sm, by = "STAND")[is.finite(DBH) & DBH >= SMD & is.finite(EXPF) & EXPF > 0][, meas := is.finite(HT) & HT > 0]
  o2[, vol := nsvb(mapsp(SP), DBH, HT, "VOLCFGRS") * EXPF]
  SH[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, trees_t2 = nrow(o2), share_trees = mean(o2$meas), share_expf = sum(o2$EXPF * o2$meas) / sum(o2$EXPF),
                                      share_vol = sum(o2$vol * o2$meas) / sum(o2$vol))
  ## ---- C2 on tag stable sets
  VV[, `:=`(V_o2 = NA_real_, V_p2 = NA_real_)]
  if (pl$c2 == "TRUE") {
    F <- fread(file.path(pl$fr, sprintf("bench_gyr_%s_tree_init.csv", s)))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% SC]
    F[, sp := mapsp(SP)]
    T1 <- rd_chunks(pl$tree_dirs, "^c[0-9]+_t1_split_tree\\.csv$")[STAND %in% SC]
    M <- split_map(F)
    x <- merge(M, T1, by = c("STAND", "tree"), all = TRUE, suffixes = c("", "_r"))
    bad <- x[is.na(row0) | is.na(sp_r) | sp != sp_r | abs(dbh - dbh_r) > 1e-6 | abs(expf - expf_r) > 1e-6 * pmax(1, expf)]
    if (nrow(bad)) hs("C2 %s %s: split map disagrees with the runner t1 list on %d records", lab, arm, nrow(bad))
    for (tt in c("init", "t2")) {
      G <- fread(file.path(pl$tagfr, sprintf("bench_gyr_%s_tree_%s.csv", s, tt)))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% SC]
      B <- if (tt == "init") F else O2
      z <- merge(B[, .(STAND, row0, SP, DBH, HT, EXPF)], G[, .(STAND, row0, SP2 = SP, DBH2 = DBH, HT2 = HT, EXPF2 = EXPF, TAG = TREE)], by = c("STAND", "row0"), all = TRUE)
      aligned <- nrow(z) == nrow(B) && nrow(z) == nrow(G) && !anyNA(z$SP) && !anyNA(z$SP2) && all(z$SP == z$SP2) && all(eqna(z$DBH, z$DBH2)) &&
          all(eqna(z$HT, z$HT2)) && all(eqna(z$EXPF, z$EXPF2))
      if (!aligned) {  ## r1: the pass 28 NS frames hold the same records reordered within stand; link on the full record key
        kf <- function(d) paste(d$STAND, d$SP, format(d$DBH, digits = 15), format(d$HT, digits = 15), format(d$EXPF, digits = 15), sep = "|")
        kb <- kf(B); kg <- kf(G)
        if (length(kb) != length(kg) || !identical(sort(kb), sort(kg))) hs("C2 %s: tag %s frame holds different records from the scored frame", lab, tt)
        dup <- unique(kb[duplicated(kb)])
        gk <- data.table(k = kg, TAG = G$TREE)[!k %in% dup]
        z <- data.table(STAND = B$STAND, row0 = B$row0, k = kb)
        z <- merge(z, gk, by = "k", all.x = TRUE)[, k := NULL]
        cat(sprintf("C2 %s %s: frame reordered, linked on record key; %d records in %d tied keys left untagged\n", lab, tt, sum(kb %in% dup), length(dup)))
        ALN[[paste(lab, tt)]] <- data.table(label = lab, frame = tt, method = "record key", records = length(kb), tied_untagged = sum(kb %in% dup))
      } else ALN[[paste(lab, tt)]] <- data.table(label = lab, frame = tt, method = "row aligned", records = nrow(z), tied_untagged = 0L)
      if (tt == "init") F <- merge(F, z[, .(STAND, row0, TAG)], by = c("STAND", "row0")) else O2 <- merge(O2, z[, .(STAND, row0, TAG)], by = c("STAND", "row0"))
    }
    tagok <- function(t) if (is.numeric(t)) is.finite(t) & t < 9e6 else !is.na(t) & nzchar(as.character(t))
    t1g <- F[tagok(TAG), .(STAND, TAG, row0, SP)]
    t2g <- O2[tagok(TAG), .(STAND, TAG, row2 = row0, SP2 = SP, H2 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]
    d1 <- t1g[, .N, by = .(STAND, TAG)][N > 1]; d2 <- t2g[, .N, by = .(STAND, TAG)][N > 1]
    t1g <- t1g[!d1, on = .(STAND, TAG)]; t2g <- t2g[!d2, on = .(STAND, TAG)]
    sv <- merge(t1g, t2g, by = c("STAND", "TAG")); S <- sv[SP == SP2 & is.finite(H2)]
    cat(sprintf("C2 tags: %d t1 tags, %d t2 tags, %d matched, %d same SP with measured HT2; duplicate keys dropped t1 %d t2 %d\n",
                nrow(t1g), nrow(t2g), nrow(sv), nrow(S), nrow(d1), nrow(d2)))
    O2c <- merge(O2, S[, .(STAND, row0 = row2, Hc = H2)], by = c("STAND", "row0"), all.x = TRUE)
    PX <- merge(P, M[, .(STAND, tree, row0)], by = c("STAND", "tree"), all.x = TRUE)
    PX <- merge(PX, S[, .(STAND, row0, Hc = H2)], by = c("STAND", "row0"), all.x = TRUE); PX[ing == 1, Hc := NA_real_]
    vo2 <- merge(O2c, sm, by = "STAND")[, .(V_o2 = totvol(mapsp(SP), DBH, Hc, EXPF, SMD[1]),
             cov_o = sum(EXPF[is.finite(Hc) & DBH >= SMD[1] & EXPF > 0]) / sum(EXPF[DBH >= SMD[1] & EXPF > 0])), by = STAND]
    vp2 <- merge(PX, sm, by = "STAND")[, .(V_p2 = totvol(sp, dbh, Hc, expf, SMD[1])), by = STAND]
    VV[, c("V_o2", "V_p2") := NULL]; VV <- merge(merge(VV, vo2, by = "STAND", all.x = TRUE), vp2, by = "STAND", all.x = TRUE)
    if (VV[!is.finite(V_o2) | !is.finite(V_p2), .N] > 0) hs("C2 %s %s: non finite C2 volume", lab, arm)
    C2COV[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, t1_tags = nrow(t1g), t2_tags = nrow(t2g), matched = nrow(sv), matched_sameSP_HT2 = nrow(S),
      stand_mean_share_expf_measured_tag = mean(VV$cov_o, na.rm = TRUE))
    VV[, cov_o := NULL]
    rm(F, T1, M, x, PX, O2c)
  }
  ## ---- QC screen
  VV[, cut := FALSE]
  if (grepl("^qc", s) && !is.null(trt)) { pr <- fread(file.path(pl$fr, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "PLOTKEY", "Y1", "Y2"))
    pr[, STAND := as.character(STAND)]; cs <- cut_stands(pr); VV[, cut := STAND %in% cs]
    cat(sprintf("QC screen: %d cut stands among %d scored\n", sum(VV$cut), nrow(VV))) }
  ## ---- site cluster bootstrap (the benchmark's draws)
  site_all <- as.character(r$SITE); sites <- unique(site_all); nsite <- length(sites); sid <- match(site_all, sites)
  IDX <- if (startsWith(pl$idx, "SEED:")) { a <- as.integer(strsplit(pl$idx, ":")[[1]][2:3]); set.seed(a[1]); m <- matrix(sample.int(nsite, nsite * a[2], replace = TRUE), nsite, a[2]); set.seed(SEED); m } else readRDS(pl$idx)
  if (nrow(IDX) != nsite) hs("%s: bootstrap index rows %d differ from %d sites", lab, nrow(IDX), nsite)
  Wall <- wts(IDX, sid, nsite); rownames(Wall) <- r$STAND; rm(IDX)
  STANDS[[paste(lab, arm)]] <- VV[, .(label = lab, arm, STAND, cut, V_o, V_p, V_oh, V_ph, V_o2, V_p2)]
  pops <- if (any(VV$cut)) c("all", "screened") else "all"
  for (pop in pops) { v <- if (pop == "all") VV else VV[cut == FALSE]; W <- Wall[v$STAND, , drop = FALSE]
    s0 <- sc(v$V_o, v$V_p, W); s1 <- sc(v$V_oh, v$V_ph, W); s2 <- if (pl$c2 == "TRUE") sc(v$V_o2, v$V_p2, W) else NULL
    gap_b <- s0$rb / s1$rb
    row <- function(k, z) if (is.null(z)) NULL else data.table(label = lab, arm = arm, pop = pop, stands = nrow(v), conv = k,
      ratio = z$pt[["ratio"]], ratio_lo = z$ci_ratio[1], ratio_hi = z$ci_ratio[2], bias_pct = z$pt[["bias_pct"]],
      rmse_pct = z$pt[["rmse_pct"]], rmse_lo = z$ci_rmse[1], rmse_hi = z$ci_rmse[2])
    ST[[paste(lab, arm, pop)]] <- rbind(row("C0", s0), row("C1", s1), row("C2", s2),
      data.table(label = lab, arm = arm, pop = pop, stands = nrow(v), conv = "gap C0/C1", ratio = s0$pt[["ratio"]] / s1$pt[["ratio"]],
                 ratio_lo = q95(gap_b)[1], ratio_hi = q95(gap_b)[2]), fill = TRUE) }
  ## ---- r2 (PREREG35) checks, reported only. They read copies; VV, Wall and every PREREG16 container are left untouched
  ## (a) defect gate
  src2 <- merge(O2[, .(STAND, DBH, EXPF)], sm, by = "STAND")[livef(DBH, EXPF, SMD), .(n_src_live = .N), by = STAND]
  z0 <- VV[V_o == 0, STAND]; dstd <- intersect(z0, src2$STAND)
  DEF[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, scored = nrow(VV), vo_zero = length(z0), vo_zero_with_source_stem = length(dstd), pass = length(dstd) == 0L)
  if (length(dstd)) { fwrite(data.table(label = lab, arm = arm, STAND = dstd), file.path(OUT, sprintf("r2-defect-stands_SERVERONLY_%s_%s.csv", lab, arm)))
    cat(sprintf("R2 CHECK A FAIL %s %s: %d V_o = 0 stands hold a live source stem at the floor\n", lab, arm, length(dstd)))
    if (R2ENF) hs("R2 check a %s %s: %d defect stands", lab, arm, length(dstd)) }
  ## (b) positive record exclusion: stands leave the screened population only through cut_stands(), a treatment record
  csr <- if (any(VV$cut)) cs else character(0); nrec <- sum(VV$cut & VV$STAND %in% csr)
  EXC[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, in_results = nrow(r), scored = nrow(VV), not_run_runok = r[RUN_OK != 1, .N],
    not_run_nonfinite = r[RUN_OK == 1 & !(is.finite(TOTVOL_o) & is.finite(TOTVOL_p)), .N], excluded_harvest = sum(VV$cut), excluded_with_record = nrec,
    excluded_without_record = sum(VV$cut) - nrec, excluded_lost = 0L, vo_zero_retained = VV[V_o == 0 & cut == FALSE, .N], pass = sum(VV$cut) == nrec)
  if (sum(VV$cut) != nrec && R2ENF) hs("R2 check b %s %s: exclusion without a positive record", lab, arm)
  ## (c) established at t1 stratum: observed t1 volume from the source t1 frame, same live filter and floor as V_o
  F1 <- fread(file.path(pl$fr, sprintf("bench_gyr_%s_tree_init.csv", s)), select = c("STAND", "SP", "DBH", "HT", "EXPF"))[, STAND := as.character(STAND)][STAND %in% VV$STAND]
  v1 <- merge(F1, sm, by = "STAND")[, .(V_o1 = totvol(mapsp(SP), DBH, HT, EXPF, SMD[1])), by = STAND]
  X <- merge(VV[, .(STAND, V_o, V_p, V_oh, V_ph, V_o2, V_p2)], v1, by = "STAND", all.x = TRUE); no_t1 <- X[is.na(V_o1), .N]; X[is.na(V_o1), V_o1 := 0]
  bo <- merge(O2[, .(STAND, DBH, EXPF)], sm, by = "STAND")[, { z <- bastem(DBH, EXPF, SMD[1]); .(BA_o = z[["BA"]], N_o = z[["N"]]) }, by = STAND]
  bp <- merge(P[, .(STAND, dbh, expf)], sm, by = "STAND")[, { z <- bastem(dbh, expf, SMD[1]); .(BA_p = z[["BA"]], N_p = z[["N"]]) }, by = STAND]
  X <- merge(merge(X, bo, by = "STAND", all.x = TRUE), bp, by = "STAND", all.x = TRUE)
  for (cc in c("BA_o", "N_o", "BA_p", "N_p")) set(X, which(is.na(X[[cc]])), cc, 0)
  nz1 <- X[V_o1 == 0, .N]; shr <- nz1 / nrow(X); fires <- shr > R2THR
  STRS[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, scored = nrow(X), t1_zero = nz1, t1_zero_share = shr, threshold = R2THR, fires = fires,
    stands_no_t1_rows = no_t1, established = nrow(X) - nz1)
  for (st in if (fires) c("all", "established_t1") else character(0)) { v <- if (st == "all") X else X[V_o1 > 0]; W <- Wall[v$STAND, , drop = FALSE]
    vs <- list("volume C0" = c("V_o", "V_p"), "volume C1" = c("V_oh", "V_ph"), "volume C2" = c("V_o2", "V_p2"), "basal area" = c("BA_o", "BA_p"), "stems" = c("N_o", "N_p"))
    if (pl$c2 != "TRUE") vs[["volume C2"]] <- NULL
    for (vn in names(vs)) { z <- sc(v[[vs[[vn]][1]]], v[[vs[[vn]][2]]], W)
      STR[[paste(lab, arm, st, vn)]] <- data.table(label = lab, arm = arm, stratum = st, stands = nrow(v), variable = vn, ratio = z$pt[["ratio"]],
        ratio_lo = z$ci_ratio[1], ratio_hi = z$ci_ratio[2], bias_pct = z$pt[["bias_pct"]], rmse_pct = z$pt[["rmse_pct"]], rmse_lo = z$ci_rmse[1], rmse_hi = z$ci_rmse[2],
        sum_o = sum(v[[vs[[vn]][1]]]), sum_p = sum(v[[vs[[vn]][2]]])) } }
  cat(sprintf("R2 %s %s: check a %s (%d V_o = 0, %d with source stem); check b %s; t1 zero %d of %d (%.4f), stratum %s\n", lab, arm,
    if (length(dstd)) "FAIL" else "pass", length(z0), length(dstd), if (sum(VV$cut) == nrec) "pass" else "FAIL", nz1, nrow(X), shr, if (fires) "fires" else "not met"))
  rm(F1, v1, X, bo, bp, src2)
  rm(P, O2, VV, Wall); gc(verbose = FALSE)
  ADM[[paste(lab, arm)]] <- data.table(label = lab, arm = arm, admitted = TRUE, reason = "")
  cat(sprintf("%s %s done in %.1f s\n", lab, arm, as.numeric(difftime(Sys.time(), t0, units = "secs"))))
}
ST <- rbindlist(ST, fill = TRUE); GT <- rbindlist(GT); SH <- rbindlist(SH); ADM <- rbindlist(ADM)
## ---- V3 QC check against PREREG14 (screened qc_c, v141LT, C1 = 1.088 within 0.001)
q <- ST[label == "qc_c" & arm == "v141LT" & pop == "screened" & conv == "C1"]
if (nrow(q) == 1) { v3 <- abs(q$ratio - 1.088) <= 0.001
  GT <- rbind(GT, data.table(label = "qc_c", arm = "v141LT", gate = "V3 QC check", value = sprintf("C1 screened %.4f vs 1.088", q$ratio), pass = v3))
  wout(GT, "gates"); if (!v3) hs("V3: screened qc_c C1 %.4f not within 0.001 of 1.088", q$ratio) } else wout(GT, "gates")
wout(ST, "scores"); wout(SH, "htshare"); wout(ADM, "admission")
if (length(C2COV)) wout(rbindlist(C2COV, fill = TRUE), "c2cov")
if (length(ALN)) wout(rbindlist(ALN), "c2align")
wout(rbindlist(STANDS, fill = TRUE)[, lapply(.SD, function(z) if (is.numeric(z)) round(z, 6) else z)], "stands")
## ---- r2 outputs (new files only)
if (length(DEF)) wout(rbindlist(DEF), "r2defect")
if (length(EXC)) wout(rbindlist(EXC), "r2exclusion")
if (length(STRS)) wout(rbindlist(STRS), "r2stratumshare")
if (length(STR)) wout(rbindlist(STR, fill = TRUE), "r2stratum")
cat("VC_DONE\n")

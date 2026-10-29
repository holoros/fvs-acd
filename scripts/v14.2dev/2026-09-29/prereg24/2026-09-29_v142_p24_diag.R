## PREREG24: why QC stems run low and QMD runs high. Diagnostic only; reads the frozen PREREG19 0.111 arm (v141LT with
## QC_AFAC 0.111), the scored QC frames, the pass28qc QC tag frames and the scorer stand table. No model run, no engine or
## coefficient change. Split map and threshold logic verbatim from 2026-09-27_v142_volconv_score.R (md5 019df238).
## Headless, data.table, one core. Aggregates only; no stand keys, plot ids or coordinates are written. No em dashes.
suppressMessages({library(data.table); library(ggplot2); library(digest); library(patchwork)})
setDTthreads(1L); options(width = 220)
SEED <- 20260929L; B <- 1000L; DST <- "2026-09-29"
J  <- "/home/aaron/jobs/v142p19"; H <- file.path(J, "home"); ARM <- "p19_a0111"
FR <- file.path(H, "magplot/verify/gydbreg20260916/frames"); TG <- "/home/aaron/jobs/v142p14/in/pass28qc"
OUT <- "/home/aaron/jobs/v142p24/tables"; dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
TREE_DIRS <- file.path(H, c("out", "out_retry_a1", "out_retry_a2", "out_retry_a3"), ARM, "qc_c")
hs <- function(fmt, ...) { m <- sprintf(fmt, ...); cat("HARD STOP:", m, "\n"); cat(m, "\n", file = file.path(OUT, "_hardstop.txt"), append = TRUE); quit(save = "no", status = 3) }
wout <- function(x, nm) { f <- file.path(OUT, sprintf("gyr142-p24-%s_DATA_%s.csv", nm, DST)); fwrite(x, f); cat(sprintf("wrote %s (%d rows)\n", basename(f), nrow(x))) }
q95 <- function(x) quantile(x, c(0.025, 0.975), names = FALSE, na.rm = TRUE)
cat(sprintf("p24 R %s data.table %s host %s seed %d B %d\n", getRversion(), packageVersion("data.table"), Sys.info()[["nodename"]], SEED, B))

## ---- verbatim from the scorer: species mapping, softwood list, split map --------------------------------------
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=125,BC=762,PR=761,ST=315,HH=701,SB=372,RB=370,AS=541,SW=299,HW=998,OH=998,OS=299,PC=761)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
.SPLIT_QUIET <- TRUE; source(file.path(H, "hw_formrisk_split.R"))
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
rd_chunks <- function(dirs, pat) { acc <- NULL
  for (d in dirs) { fs <- sort(list.files(d, pattern = pat, full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, fread), fill = TRUE); x[, STAND := as.character(STAND)]
    if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x, fill = TRUE) }
  acc }
eqna <- function(a, b, tol = 1e-6) (is.na(a) & is.na(b)) | (!is.na(a) & !is.na(b) & abs(a - b) <= tol)
fold <- function(site) ifelse(strtoi(substr(vapply(as.character(site), function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
tph <- function(ba, qmd) ba / (pi / 40000 * qmd^2)

## ---- populations -------------------------------------------------------------------------------------------------
r <- fread(file.path(J, "results", ARM, sprintf("gyr_%s_qc_c_results.csv", ARM))); r[, STAND := as.character(STAND)]
STN <- fread(list.files(file.path(J, "tables"), "^gyr142-p19-fb-stands_DATA_.*\\.csv$", full.names = TRUE))[label == "qc_c" & arm == ARM]
STN[, STAND := as.character(STAND)]
GRID <- fread(file.path(J, "assembled/gyr142-p19-grid_DATA_2026-09-28.csv"))[set == "qc_c" & arm == ARM]
ST <- merge(r[RUN_OK == 1, .(STAND, SITE, SMD = SCORE_MINDBH_USED, INT = interval_years, BA_o, BA_p, QMD_o, QMD_p)], STN[, .(STAND, cut)], by = "STAND")
ST <- ST[is.finite(tph(BA_o, QMD_o)) & is.finite(tph(BA_p, QMD_p)) & cut == FALSE]
ST[, fold := fold(SITE)]
cat(sprintf("screened stands %d (A %d, B %d), sites %d\n", nrow(ST), ST[fold == "A", .N], ST[fold == "B", .N], uniqueN(ST$SITE)))
SC <- ST$STAND

## ---- frames, tags (scorer linking: row aligned on every field, else stop), runner lists ---------------------------
rdF <- function(dir, tt) fread(file.path(dir, sprintf("bench_gyr_qc_c_tree_%s.csv", tt)))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% SC]
F <- rdF(FR, "init"); O2 <- rdF(FR, "t2")
for (tt in c("init", "t2")) { Bf <- if (tt == "init") F else O2; G <- rdF(TG, tt)
  z <- merge(Bf[, .(STAND, row0, SP, DBH, HT, EXPF)], G[, .(STAND, row0, SP2 = SP, DBH2 = DBH, HT2 = HT, EXPF2 = EXPF, TAG = TREE)], by = c("STAND", "row0"), all = TRUE)
  aligned <- nrow(z) == nrow(Bf) && nrow(z) == nrow(G) && !anyNA(z$SP) && !anyNA(z$SP2) && all(z$SP == z$SP2) && all(eqna(z$DBH, z$DBH2)) && all(eqna(z$HT, z$HT2)) && all(eqna(z$EXPF, z$EXPF2))
  if (!aligned) hs("tag frame %s not row aligned with the scored frame", tt)
  if (z[, .N, by = .(STAND, TAG)][N > 1, .N] > 0) hs("duplicated tags in %s", tt)
  if (tt == "init") F <- merge(F, z[, .(STAND, row0, TAG)], by = c("STAND", "row0")) else O2 <- merge(O2, z[, .(STAND, row0, TAG)], by = c("STAND", "row0")) }
F[, sp := mapsp(SP)]
P  <- rd_chunks(TREE_DIRS, "^c[0-9]+_pred_t2_tree\\.csv$")[STAND %in% SC]
T1 <- rd_chunks(TREE_DIRS, "^c[0-9]+_t1_split_tree\\.csv$")[STAND %in% SC]
if (!setequal(unique(P$STAND), SC) || !setequal(unique(T1$STAND), SC)) hs("per tree lists do not cover the screened stands")
M <- split_map(F)
x <- merge(M, T1, by = c("STAND", "tree"), all = TRUE, suffixes = c("", "_r"))
bad <- x[is.na(row0) | is.na(sp_r) | sp != sp_r | abs(dbh - dbh_r) > 1e-6 | abs(expf - expf_r) > 1e-6 * pmax(1, expf)]
if (nrow(bad)) hs("split map disagrees with the runner t1 list on %d records", nrow(bad))
rm(x, T1)

## ---- cohorts ---------------------------------------------------------------------------------------------------------
ST[, INT := as.numeric(INT)]
C <- merge(F[, .(STAND, row0, TAG, SPc = sp, d1 = DBH, E1 = EXPF)], ST[, .(STAND, SMD, INT)], by = "STAND")
C[, grp := fifelse(SPc %in% sw, "Softwood", "Hardwood")]
CL <- c(-Inf, 12, 15, 20, 30, Inf); CLN <- c("below 12", "12 to 15", "15 to 20", "20 to 30", "30 and over")
C[, cls := factor(CLN[findInterval(d1, CL, left.open = FALSE)], levels = CLN)]
obs2 <- O2[, .(STAND, TAG, d_o = DBH, e_o = EXPF, SP2 = SP)]
C <- merge(C, obs2, by = c("STAND", "TAG"), all.x = TRUE); C[, alive := !is.na(d_o)]; C[alive == FALSE, e_o := 0]
REC_O <- O2[!C[alive == TRUE, .(STAND, TAG)], on = .(STAND, TAG), .(STAND, TAG, d = DBH, e = EXPF, SPr = mapsp(SP))]
PR <- merge(P[ing == 0, .(STAND, tree, d_r = dbh, e_r = expf)], M[, .(STAND, tree, row0)], by = c("STAND", "tree"), all.x = TRUE)
if (PR[is.na(row0), .N]) hs("%d predicted survivor records do not map to a t1 row", PR[is.na(row0), .N])
ep <- PR[, .(e_p = sum(e_r), dq_p = sum(e_r * d_r) / sum(e_r)), by = .(STAND, row0)]
C <- merge(C, ep, by = c("STAND", "row0"), all.x = TRUE); C[is.na(e_p), e_p := 0]
REC_P <- P[ing == 1, .(STAND, d = dbh, e = expf)]
n_nopred_alive <- C[alive == TRUE & e_p <= 0, .N]; cat(sprintf("cohorts observed alive with no predicted record: %d\n", n_nopred_alive))
cat(sprintf("t1 cohorts %d, observed alive %d, species mismatch among matched %d\n", nrow(C), C[alive == TRUE, .N], C[alive == TRUE & mapsp(SP2) != SPc, .N]))

## ---- survivor increment ratio by class x group (full sample of screened stands, held fixed in the bootstrap) --------
C[, `:=`(inc_o = d_o - d1, inc_p = dq_p - d1)]
cal <- C[alive == TRUE & e_p > 0, .(n = .N, rc = sum(E1 * inc_p) / sum(E1 * inc_o)), by = .(cls, grp)]
calc <- C[alive == TRUE & e_p > 0, .(rcc = sum(E1 * inc_p) / sum(E1 * inc_o)), by = cls]
cal <- merge(cal, calc, by = "cls"); cal[, rc_use := fifelse(n >= 30, rc, rcc)]
C <- merge(C, cal[, .(cls, grp, rc_use)], by = c("cls", "grp"), all.x = TRUE)
if (C[is.na(rc_use), .N] || any(cal$rc_use <= 0)) hs("increment calibration missing or non positive")

## ---- counterfactual stand sums: survivors under (M, G), recruits under I -------------------------------------------
R <- merge(PR, C[, .(STAND, row0, d1, alive, d_o, e_o, e_p, rc_use)], by = c("STAND", "row0"))
R <- merge(R, ST[, .(STAND, SMD)], by = "STAND")
extra <- C[alive == TRUE & e_p <= 0, .(STAND, row0, tree = NA_integer_, d_r = d1 + inc_o * rc_use, e_r = 0, d1, alive, d_o, e_o, e_p, rc_use, SMD)]
R <- rbind(R, extra, use.names = TRUE)
surv_sums <- function(R, Mx, Gx) {
  d <- if (Gx) fifelse(R$alive, R$d_o, R$d1 + (R$d_r - R$d1) / R$rc_use) else R$d_r
  w <- if (Mx) fifelse(R$e_p > 0, R$e_r * R$e_o / R$e_p, fifelse(R$alive, R$e_o, 0)) else R$e_r
  data.table(STAND = R$STAND, k = d >= R$SMD, w = w, d = d)[, .(N = sum(w[k]), D2 = sum(w[k] * d[k]^2)), by = STAND] }
rec_sums <- function(X) merge(X[, .(STAND, d, e)], ST[, .(STAND, SMD)], by = "STAND")[, .(N = sum(e[d >= SMD]), D2 = sum(e[d >= SMD] * d[d >= SMD]^2)), by = STAND]
build_cf <- function(R, REC_O) {
  base <- ST[, .(STAND)]
  RI <- list(`0` = merge(base, rec_sums(REC_P), all.x = TRUE), `1` = merge(base, rec_sums(REC_O), all.x = TRUE))
  out <- list()
  for (m in 0:1) for (g in 0:1) { s <- merge(base, surv_sums(R, m == 1, g == 1), all.x = TRUE)
    for (i in 0:1) { ri <- RI[[as.character(i)]]; z <- merge(s, ri, by = "STAND", suffixes = c("", "_i"))
      for (v in c("N", "D2", "N_i", "D2_i")) set(z, which(is.na(z[[v]])), v, 0)
      out[[paste0(m, g, i)]] <- z[, .(STAND, N = N + N_i, D2 = D2 + D2_i)] } }
  out }
CF <- build_cf(R, REC_O)
## identity: all three substitutions reproduce the observed t2 list
ob <- merge(O2, ST[, .(STAND, SMD)], by = "STAND")[, .(N = sum(EXPF[DBH >= SMD]), D2 = sum(EXPF[DBH >= SMD] * DBH[DBH >= SMD]^2)), by = STAND]
chk <- merge(CF[["111"]], ob, by = "STAND"); idd <- chk[, max(abs(N.x - N.y) / pmax(1, N.y), abs(D2.x - D2.y) / pmax(1, D2.y))]
cat(sprintf("identity all substitutions vs observed: max rel %.2e\n", idd)); if (idd > 1e-9) hs("counterfactual 111 does not reproduce the observed list (%.2e)", idd)

## ---- stand level accounting columns ------------------------------------------------------------------------------
acc <- C[, .(N1 = sum(E1), N1s = sum(E1[d1 >= SMD[1]]), Sa_o = sum(e_o), Sa_p = sum(e_p), INT = INT[1], SMD = SMD[1],
             inc_o_w = sum((E1 * inc_o)[alive & e_p > 0]), inc_p_w = sum((E1 * inc_p)[alive & e_p > 0]),
             bai_o_w = sum((E1 * (d_o^2 - d1^2))[alive & e_p > 0]), bai_p_w = sum((E1 * (dq_p^2 - d1^2))[alive & e_p > 0])), by = STAND]
S_o <- merge(O2, C[alive == TRUE, .(STAND, TAG)], by = c("STAND", "TAG"))
S_o <- merge(S_o, ST[, .(STAND, SMD)], by = "STAND")[, .(Ss_o = sum(EXPF[DBH >= SMD])), by = STAND]
S_p <- merge(PR, ST[, .(STAND, SMD)], by = "STAND")[, .(Ss_p = sum(e_r[d_r >= SMD])), by = STAND]
I_o <- rec_sums(REC_O)[, .(STAND, I_o = N)]; I_p <- rec_sums(REC_P)[, .(STAND, I_p = N)]
I_pall <- REC_P[, .(I_pall = sum(e), I_pmax = max(d)), by = STAND]
T1m <- merge(M, ST[, .(STAND, SMD)], by = "STAND")[, .(N1s_m = sum(expf[dbh >= SMD])), by = STAND]
A <- Reduce(function(a, b) merge(a, b, by = "STAND", all.x = TRUE), list(ST[, .(STAND, SITE, fold, BA_o, BA_p, QMD_o, QMD_p)], acc, S_o, S_p, I_o, I_p, I_pall, T1m))
for (v in c("Ss_o", "Ss_p", "I_o", "I_p", "I_pall")) set(A, which(is.na(A[[v]])), v, 0)
A[, `:=`(N2_o = Ss_o + I_o, N2_p = Ss_p + I_p, tph_o = tph(BA_o, QMD_o), tph_p = tph(BA_p, QMD_p))]
A[, `:=`(Mo_y = (N1 - Sa_o) / INT, Mp_y = (N1 - Sa_p) / INT, Io_y = I_o / INT, Ip_y = I_p / INT)]
tl <- max(abs(A$N2_o - A$tph_o) / A$tph_o, abs(A$N2_p - A$tph_p) / A$tph_p)
cat(sprintf("stand stems from tree lists vs TPH from BA and QMD: max rel %.2e\n", tl))
## ---- observed data tests: large recruits and churn -------------------------------------------------------------------
q99 <- C[alive == TRUE, quantile(inc_o / INT, 0.99, names = FALSE)]
cat(sprintf("99th percentile observed survivor annual DBH increment %.3f cm/yr\n", q99))
REC_O <- merge(REC_O, ST[, .(STAND, SMD, INT)], by = "STAND"); REC_O[, big := d > SMD + q99 * INT]
churn <- function(C, REC_O) { un <- C[alive == FALSE, .(STAND, row0, SPc, d1, INT)]; rc <- REC_O[, .(STAND, TAG, SPr, d, e)]
  cand <- merge(un, rc, by = "STAND", allow.cartesian = TRUE)[SPc == SPr & d >= d1 - 1 & d <= d1 + q99 * INT]
  cand[, gap := abs(d - d1)]; setorder(cand, STAND, gap); used1 <- new.env(); used2 <- new.env(); keep <- logical(nrow(cand))
  k1 <- paste(cand$STAND, cand$row0); k2 <- paste(cand$STAND, cand$TAG)
  for (i in seq_len(nrow(cand))) if (is.null(used1[[k1[i]]]) && is.null(used2[[k2[i]]])) { keep[i] <- TRUE; assign(k1[i], 1, used1); assign(k2[i], 1, used2) }
  cand[keep] }
CH <- churn(C, REC_O); cat(sprintf("churn matches %d\n", nrow(CH)))
C2 <- copy(C); C2[CH, on = .(STAND, row0), `:=`(alive = TRUE, d_o = i.d, e_o = i.e)]
REC_O2 <- REC_O[!CH, on = .(STAND, TAG)]
R2 <- merge(PR, C2[, .(STAND, row0, d1, alive, d_o, e_o, e_p, rc_use)], by = c("STAND", "row0")); R2 <- merge(R2, ST[, .(STAND, SMD)], by = "STAND")
extra2 <- C2[alive == TRUE & e_p <= 0, .(STAND, row0, tree = NA_integer_, d_r = d1 + (d_o - d1) * rc_use, e_r = 0, d1, alive, d_o, e_o, e_p, rc_use, SMD)]
R2 <- rbind(R2, extra2, use.names = TRUE)
CF2 <- build_cf(R2, REC_O2[, .(STAND, TAG, d, e, SPr)])
bigS <- REC_O[d >= SMD, .(Ib_o = sum(e[big])), by = STAND]; A <- merge(A, bigS, by = "STAND", all.x = TRUE); A[is.na(Ib_o), Ib_o := 0]

## ---- Shapley and bootstrap -------------------------------------------------------------------------------------------
orders <- list(c("M","G","I"), c("M","I","G"), c("G","M","I"), c("G","I","M"), c("I","M","G"), c("I","G","M"))
key <- function(S) paste0(as.integer("M" %in% S), as.integer("G" %in% S), as.integer("I" %in% S))
shap <- function(v) { phi <- c(M = 0, G = 0, I = 0); for (o in orders) { S <- character(0); for (p in o) { phi[p] <- phi[p] + v[[key(S)]] - v[[key(c(S, p))]]; S <- c(S, p) } }; phi / 6 }
mat <- function(CF, stands) { K <- names(CF); Nm <- sapply(K, function(k) CF[[k]][match(stands, STAND), N]); Dm <- sapply(K, function(k) CF[[k]][match(stands, STAND), D2]); list(N = Nm, D = Dm) }
cols <- c("N1", "N1s", "N1s_m", "Sa_o", "Sa_p", "Ss_o", "Ss_p", "I_o", "I_p", "I_pall", "N2_o", "N2_p", "tph_o", "tph_p", "BA_o", "BA_p", "QMD_o", "QMD_p",
          "Mo_y", "Mp_y", "Io_y", "Ip_y", "inc_o_w", "inc_p_w", "bai_o_w", "bai_p_w", "Ib_o")
stat <- function(s, n, Nm, Dm, N2m, D2m) {  # s: column sums of cols; Nm/Dm: sums of counterfactual N, D2 (named by key)
  vN <- as.list(log(Nm)); vQ <- as.list(0.5 * (log(Dm) - log(Nm)))
  pN <- shap(vN); pQ <- shap(vQ); pN2 <- shap(as.list(log(N2m))); pQ2 <- shap(as.list(0.5 * (log(D2m) - log(N2m))))
  lN <- log(Nm[["000"]] / Nm[["111"]]); lQ <- 0.5 * (log(Dm[["000"]] / Nm[["000"]]) - log(Dm[["111"]] / Nm[["111"]]))
  c(stems_ratio = s[["N2_p"]] / s[["N2_o"]], stems_ratio_tph = s[["tph_p"]] / s[["tph_o"]], ba_ratio = s[["BA_p"]] / s[["BA_o"]],
    qmd_pooled_ratio = exp(lQ), qmd_mean_ratio = s[["QMD_p"]] / s[["QMD_o"]],
    t1_stems_ha = s[["N1"]] / n, t1_admission_ratio = s[["N1s_m"]] / s[["N1s"]],
    surv_all_ratio = s[["Sa_p"]] / s[["Sa_o"]], surv_thr_ratio = s[["Ss_p"]] / s[["Ss_o"]],
    obs_survival = s[["Sa_o"]] / s[["N1"]], pred_survival = s[["Sa_p"]] / s[["N1"]],
    mort_o_ha_yr = s[["Mo_y"]] / n, mort_p_ha_yr = s[["Mp_y"]] / n, mort_ratio = s[["Mp_y"]] / s[["Mo_y"]],
    rec_o_ha_yr = s[["Io_y"]] / n, rec_p_ha_yr = s[["Ip_y"]] / n, rec_ratio = s[["Ip_y"]] / s[["Io_y"]], rec_p_all_ha = s[["I_pall"]] / n,
    N2_o_ha = s[["N2_o"]] / n, N2_p_ha = s[["N2_p"]] / n,
    deficit_share_survivors = (s[["Ss_p"]] - s[["Ss_o"]]) / (s[["N2_p"]] - s[["N2_o"]]), deficit_share_recruits = (s[["I_p"]] - s[["I_o"]]) / (s[["N2_p"]] - s[["N2_o"]]),
    inc_ratio = s[["inc_p_w"]] / s[["inc_o_w"]], bai_ratio = s[["bai_p_w"]] / s[["bai_o_w"]], big_rec_share = s[["Ib_o"]] / s[["I_o"]],
    shN_M = pN[["M"]] / lN, shN_G = pN[["G"]] / lN, shN_I = pN[["I"]] / lN, shQ_M = pQ[["M"]] / lQ, shQ_G = pQ[["G"]] / lQ, shQ_I = pQ[["I"]] / lQ,
    shN_I_churn = pN2[["I"]] / log(N2m[["000"]] / N2m[["111"]]), shN_M_churn = pN2[["M"]] / log(N2m[["000"]] / N2m[["111"]]),
    shQ_G_churn = pQ2[["G"]] / (0.5 * (log(D2m[["000"]] / N2m[["000"]]) - log(D2m[["111"]] / N2m[["111"]]))),
    log_stems_ratio = lN, log_qmd_ratio = lQ, resid_N = lN - sum(pN), resid_Q = lQ - sum(pQ)) }
POPS <- list(`screened A` = ST[fold == "A", STAND], `screened B` = ST[fold == "B", STAND], screened = ST$STAND)
set.seed(SEED); RES <- list(); BOOT <- list()
for (pn in names(POPS)) { stn <- POPS[[pn]]; a <- A[match(stn, STAND)]; X <- as.matrix(a[, ..cols]); m <- mat(CF, stn); m2 <- mat(CF2, stn)
  pt <- stat(colSums(X), nrow(X), colSums(m$N), colSums(m$D), colSums(m2$N), colSums(m2$D))
  sites <- unique(a$SITE); sid <- match(a$SITE, sites); ns <- length(sites)
  IDX <- matrix(sample.int(ns, ns * B, replace = TRUE), ns, B)
  bs <- t(sapply(seq_len(B), function(b) { w <- tabulate(IDX[, b], nbins = ns)[sid]; nb <- sum(w)
    stat(colSums(X * w), nb, colSums(m$N * w), colSums(m$D * w), colSums(m2$N * w), colSums(m2$D * w)) }))
  ci <- apply(bs, 2, q95)
  RES[[pn]] <- data.table(pop = pn, stands = length(stn), sites = ns, stat = names(pt), value = unname(pt), lo = ci[1, ], hi = ci[2, ]) }
RES <- rbindlist(RES)
RES[stat %in% c("resid_N", "resid_Q"), `:=`(lo = NA, hi = NA)]
print(dcast(RES, stat ~ pop, value.var = "value"), digits = 4)

## ---- magnitude check against PREREG19's grid table (read) and the task's stated values ---------------------------------
mc <- merge(RES[stat == "stems_ratio", .(pop, dec = value)], GRID[, .(pop, p19 = stems_ratio)], by = "pop")
mc[, stated := c(`screened A` = 0.781, `screened B` = 0.758, screened = 0.769)[pop]]
mc[, `:=`(d_p19 = dec - p19, d_stated = dec - stated, pass = abs(dec - p19) <= 0.005 & abs(dec - stated) <= 0.005)]
print(mc); wout(mc, "magcheck")
if (nrow(mc) != 3 || !all(mc$pass)) hs("decomposition stems ratio does not reproduce PREREG19 within 0.005")
if (RES[stat %in% c("resid_N", "resid_Q"), max(abs(value))] > 1e-9) hs("Shapley residual not zero")

## ---- class tables: survival and increment by t1 DBH class and species group ------------------------------------------
Cs <- merge(C, ST[, .(STAND, SITE, fold)], by = "STAND")
Cs[, `:=`(mo = (E1 - e_o) / INT, mp = (E1 - e_p) / INT, io = fifelse(alive & e_p > 0, E1 * inc_o, 0), ip = fifelse(alive & e_p > 0, E1 * inc_p, 0), nm = as.numeric(alive & e_p > 0))]
CC <- c("n","E1","eo","ep","mo","mp","io","ip","nm","io_y","ip_y","E1m")
cls_stat <- function(z) c(trees = z[["n"]], t1_E = z[["E1"]], obs_surv = z[["eo"]] / z[["E1"]], pred_surv = z[["ep"]] / z[["E1"]],
  obs_mort_yr = z[["mo"]] / z[["E1"]], pred_mort_yr = z[["mp"]] / z[["E1"]], mort_ratio = z[["mp"]] / z[["mo"]],
  surv_trees = z[["nm"]], obs_inc_cm_yr = z[["io_y"]] / z[["E1m"]], pred_inc_cm_yr = z[["ip_y"]] / z[["E1m"]], inc_ratio = z[["ip"]] / z[["io"]])
CLT <- list()
for (pn in names(POPS)) { stn <- POPS[[pn]]; cz <- Cs[STAND %in% stn]
  for (gv in c("All", "Softwood", "Hardwood")) { cg <- if (gv == "All") cz else cz[grp == gv]
    sdt <- cg[, .(n = .N, E1 = sum(E1), eo = sum(e_o), ep = sum(e_p), mo = sum(mo), mp = sum(mp), io = sum(io), ip = sum(ip), nm = sum(nm),
                  io_y = sum(io / INT), ip_y = sum(ip / INT), E1m = sum(E1 * nm)), by = .(cls, STAND, SITE)]
    for (cv in c(CLN, "All")) { zz <- if (cv == "All") sdt[, lapply(.SD, sum), by = .(STAND, SITE), .SDcols = CC] else sdt[cls == cv]
      if (!nrow(zz)) next
      ZM <- as.matrix(zz[, ..CC]); pt <- cls_stat(colSums(ZM)); sites <- unique(zz$SITE); sid <- match(zz$SITE, sites); ns <- length(sites)
      IDX <- matrix(sample.int(ns, ns * B, replace = TRUE), ns, B)
      bm <- sapply(seq_len(B), function(b) { w <- tabulate(IDX[, b], nbins = ns)[sid]; r <- cls_stat(colSums(ZM * w)); r[c("mort_ratio", "inc_ratio")] })
      CLT[[paste(pn, gv, cv)]] <- data.table(pop = pn, group = gv, dbh_class = cv, t(pt), mort_ratio_lo = q95(bm[1, ])[1], mort_ratio_hi = q95(bm[1, ])[2],
                                            inc_ratio_lo = q95(bm[2, ])[1], inc_ratio_hi = q95(bm[2, ])[2]) } } }
CLT <- rbindlist(CLT, fill = TRUE)
print(CLT[group == "All", .(pop, dbh_class, trees, obs_surv, pred_surv, mort_ratio, mort_ratio_lo, mort_ratio_hi, inc_ratio, inc_ratio_lo, inc_ratio_hi)], digits = 3)

## ---- structural facts: t1 floor and model recruit sizes (aggregates) ---------------------------------------------------
STR <- data.table(item = c("t1 frame minimum DBH, cm", "t1 records below the stand threshold, share of t1 stems", "model recruits, all sizes, stems per ha at t2",
                           "model recruits at or above threshold, stems per ha at t2", "largest model recruit DBH at t2, cm", "observed recruits at or above threshold, stems per ha at t2",
                           "observed recruit median DBH at t2, cm", "q99 observed survivor DBH increment, cm per yr", "churn matches, trees", "tag matched survivors with no predicted record",
                           "increment calibration cells pooled to class"),
  value = c(min(C$d1), C[, sum(E1[d1 < SMD]) / sum(E1)], sum(REC_P$e) / nrow(ST), rec_sums(REC_P)[, sum(N)] / nrow(ST), if (nrow(REC_P)) max(REC_P$d) else NA_real_,
            rec_sums(REC_O)[, sum(N)] / nrow(ST), REC_O[d >= SMD, median(d)], q99, nrow(CH), n_nopred_alive, cal[n < 30, .N]))
print(STR)
wout(RES, "decomp"); wout(CLT, "classes"); wout(STR, "structure"); wout(cal[, .(dbh_class = cls, group = grp, survivors = n, inc_ratio = rc, inc_ratio_used = rc_use)], "inccal")

## ---- reading rules (PREREG24 section "Reading rules") -----------------------------------------------------------------
g <- function(pn, s) RES[pop == pn & stat == s]
ex0 <- function(z) z$lo > 0 | z$hi < 0
rules <- function(pn) { d <- function(s) g(pn, s)
  r1 <- d("shN_M")$value >= 0.5 && ex0(d("shN_M")) && d("mort_ratio")$lo > 1
  r2 <- d("shN_I")$value >= 0.5 && ex0(d("shN_I")) && d("rec_ratio")$hi < 1
  r3 <- d("shQ_G")$value >= 0.5 && ex0(d("shQ_G")) && d("inc_ratio")$lo > 1
  mi <- d("shQ_M")$value + d("shQ_I")$value
  r4 <- mi >= 0.5 && (!(d("inc_ratio")$lo > 1) || d("shQ_G")$value < 0.5)
  r5i <- d("big_rec_share")$value >= 0.25; r5ii <- d("shN_I_churn")$value < 0.5 || d("shN_I_churn")$value <= 0.5 * d("shN_I")$value
  r5iii <- abs(d("t1_admission_ratio")$value - 1) > 0.005
  data.table(pop = pn, R1_mortality = r1, R2_ingrowth = r2, R3_diameter_growth = r3, R4_composition = r4, R5i_big_recruits = r5i, R5ii_churn = r5ii, R5iii_admission = r5iii,
             shQ_M_plus_I = mi) }
RU <- rbindlist(lapply(names(POPS), rules)); print(RU); wout(RU, "rules")

## ---- figure: (a) Shapley shares, (b) mortality and increment ratios by DBH class --------------------------------------
fa <- RES[pop %in% c("screened A", "screened B") & stat %in% c("shN_M", "shN_G", "shN_I", "shQ_M", "shQ_G", "shQ_I")]
fa[, `:=`(target = fifelse(startsWith(stat, "shN"), "Stems ratio", "QMD ratio"),
          comp = factor(c(M = "Mortality", G = "Diameter growth", I = "Ingrowth")[sub("sh[NQ]_", "", stat)], levels = c("Mortality", "Diameter growth", "Ingrowth")),
          fold = sub("screened ", "Fold ", pop))]
fa[, target := factor(target, levels = c("Stems ratio", "QMD ratio"))]
pa <- ggplot(fa, aes(comp, value, colour = fold)) + geom_hline(yintercept = 0, colour = "grey50") + geom_hline(yintercept = 0.5, linetype = "dotted", colour = "grey50") +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.5), size = 0.35) + facet_wrap(~target) +
  scale_colour_manual(values = c(`Fold A` = "#1b6ca8", `Fold B` = "#b5452b")) +
  labs(x = NULL, y = "Share of log(predicted / observed)", colour = NULL, title = "a") + theme_classic(base_size = 10) + theme(legend.position = "top")
fb <- CLT[group == "All" & dbh_class != "All" & pop %in% c("screened A", "screened B")]
fb <- rbind(fb[, .(pop, dbh_class, metric = "Annual mortality", y = mort_ratio, lo = mort_ratio_lo, hi = mort_ratio_hi)],
            fb[, .(pop, dbh_class, metric = "DBH increment, survivors", y = inc_ratio, lo = inc_ratio_lo, hi = inc_ratio_hi)])
fb[, `:=`(dbh_class = factor(dbh_class, levels = CLN), fold = sub("screened ", "Fold ", pop))]
pb <- ggplot(fb, aes(dbh_class, y, colour = fold)) + geom_hline(yintercept = 1, colour = "grey50") +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.5), size = 0.35) + facet_wrap(~metric) +
  scale_colour_manual(values = c(`Fold A` = "#1b6ca8", `Fold B` = "#b5452b")) +
  labs(x = "DBH class at t1 (cm)", y = "Predicted / observed", colour = NULL, title = "b") + theme_classic(base_size = 10) +
  theme(legend.position = "none", axis.text.x = element_text(angle = 30, hjust = 1))
ggsave(file.path(OUT, sprintf("gyr142-p24-qc-stems-qmd_%s.png", DST)), pa / pb, width = 7, height = 6.5, dpi = 300)
cat("P24_DONE\n")

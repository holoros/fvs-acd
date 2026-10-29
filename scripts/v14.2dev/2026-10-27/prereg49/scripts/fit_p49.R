## PREREG49 stage 1 fit (plan revision 1, md5 c2188088), form sf_fr (choice 1a), fold A only, frozen before any engine run.
## (1) Reproduction [F9]: the PREREG27 fold A survivor and recruit table (v142p27/fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv,
##     md5 f1134901, 68 cells) is rebuilt with the code of 2026-09-30_v142_p27_confirm.R (b0b80b61; its K, fold, comp and tab
##     lines, copied) and p27_lib.R (6da99284, through the p49_lib.R copy); the script stops unless every cell matches to 1e-9.
##     Folds: PREREG11 rule as coded in PREREG22 (2026-09-27_v142_p17_summ.R line 9, md5 14c53082): fold A when the first hex
##     digit of md5(SITE) is even. (2) Fit data: NS_OP stands of ns_c fold A, survivors paired as in PREREG27 (stand level, expansion
##     weighted: alive_obs is surv_o, the fold A t1 trees at or above the threshold alive at t2). Each t1 record at or above the
##     threshold carries its frozen v141LTfi interval survival S = e2/e1 over the runner interval iv; p = S^(1/iv) is held
##     at that annualized value [ASSUMPTION, reported]; h = -log p; H_t = (t - 1) h is the record's cumulative engine hazard before
##     year t; S_pred(theta) = prod over t = 1..iv of [1 - (1 - p)/(1 + theta H_t)], so S_pred(0) = S. (3) Estimating equation, first
##     moment only (one parameter form): sum over stands of (surv_o - sum over records e1 S_pred(theta)) = 0, Newton with the
##     analytic derivative from theta 0 (a step is halved only where the form is undefined), stop when the step is below 1e-10.
##     (4) Site cluster bootstrap B = 1000, set.seed(20261026), each draw re-solved from theta 0 as the point estimate is. Fit stop (PREREG46 rule 1): no convergence, an estimate on the null side
##     (theta at or below 0), or more than 5 percent of draws nonconverged; on a stop the fit file says so and the script exits 10.
## Reads no fold B row past the fold assignment and no ns_long_c file except the fold A rows the 68 cell reproduction needs
## (logged as a deviation). Writes aggregates only. P49_ROOT and P49_DRY=1 (10 percent of fold A sites, B = 20, into the dry root)
## are for the dry run only. No coordinates. No em dashes.
suppressMessages({library(data.table); library(digest)}); options(width = 200)
J <- Sys.getenv("P49_ROOT", "/home/aaron/jobs/v142p49"); DRY <- identical(Sys.getenv("P49_DRY", ""), "1")
source("/home/aaron/jobs/v142p49/scripts/p49_lib.R"); OUT <- file.path(J, "fit"); dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
f_out <- function(n) { f <- file.path(OUT, n); if (file.exists(f)) stop("REFUSE ", f); f }
FREP <- f_out("gyr142-p49-repro-foldA_DATA_2026-10-26.csv"); FFIT <- f_out("gyr142-p49-sffr-fit_DATA_2026-10-26.csv"); FCEL <- f_out("gyr142-p49-sffr-foldA-cells_DATA_2026-10-26.csv")
chk <- function(f, m) { x <- unname(tools::md5sum(f)); if (is.na(x) || x != m) stop("md5 ", f, " ", x, " != ", m); invisible(f) }
P27 <- "/home/aaron/jobs/v142p27"
chk(file.path(P27, "fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv"), "f11349019596f6b8f198fba680973f5a")
chk(file.path(P27, "scripts/2026-09-30_v142_p27_confirm.R"), "b0b80b6146149b73663381d3b48fe0a6"); chk(file.path(P27, "scripts/p27_lib.R"), "6da99284aac424a1187cbbe899679ab4")
chk("/home/aaron/jobs/v142p22/scripts/2026-09-27_v142_p17_summ.R", "14c530827fd9e8f5685911c9bb1dacb3")
RMD5 <- c(ns_c = "9fe608de2e4261bd60d637019c83022e", ns_fl = "52c8b5882d9f18ab7c2f807b0297306a", ns_long_c = "9ac03bc21b372d26791b9919f83a5948", ns_long_fl = "cf8bf849176715a9b1dfad9c8c715e17")
for (s in names(RMD5)) chk(sprintf(RES$fi, s), RMD5[[s]])
## ---- (1) reproduction, PREREG27 confirm.R lines (fold A only)
SETS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl"); BRK <- c(0, 5, 10, 15, 20, 30, 60); LAB <- c("iv05", "iv06_10", "iv11_15", "iv16_20", "iv21_30", "iv31_60")
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
K <- rbindlist(lapply(SETS, function(s) { r <- fread(sprintf(RES$fi, s), select = c("STAND", "SITE", "interval_years", "SCORE_MINDBH_USED"))
  p <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "PLOTKEY"))
  merge(r, p, by = "STAND")[, `:=`(set = s, STAND = as.character(STAND), SITE = as.character(SITE))] }))
FM <- unique(K[, .(SITE)])[, fold := fold(SITE)]; K <- merge(K, FM, by = "SITE"); K[, ivc := cut(interval_years, BRK, labels = LAB)]
K[, `:=`(sidx = as.integer(factor(SITE)), pidx = as.integer(factor(paste(set, PLOTKEY))))][, `:=`(SITE = NULL, PLOTKEY = NULL)]
K <- K[fold == "A"]   # PREREG49: nothing past the fold assignment is kept for fold B
comp <- function(a, fo) { X <- rbindlist(lapply(SETS, function(s) stand_comp(s, a, K[set == s & fold == fo, .(STAND, thr = SCORE_MINDBH_USED)])))
  X <- merge(X, K[, .(set, STAND, sidx, pidx, ivc, iv = interval_years, fold)], by = c("set", "STAND")); X[, prog := prog_of(STAND)]
  X[, iv3 := fcase(iv <= 5, "iv05", iv <= 15, "iv06_15", default = "iv16_60")]; X[, iv21 := iv > 20]; X }
tab <- function(d, by, ci = TRUE) { R <- d[, .(stands = .N, sites = uniqueN(sidx), iv_mean = mean(iv), n1 = sum(n1), surv_o = sum(surv_o), surv_p = sum(surv_p), rec_o = sum(rec_o), rec_p = sum(rec_p)), by = by]
  R[, `:=`(surv_ratio = surv_p / surv_o, rec_ratio = rec_p / rec_o, stems_ratio = (surv_p + rec_p) / (surv_o + rec_o),
           d_surv_pct = 100 * (surv_p - surv_o) / (surv_o + rec_o), d_rec_pct = 100 * (rec_p - rec_o) / (surv_o + rec_o),
           ann_surv_o = (surv_o / n1)^(1 / iv_mean), ann_surv_p = (surv_p / n1)^(1 / iv_mean))]
  if (!ci) return(R); stop("not used") }
XA <- comp("fi", "A"); FA <- fread(file.path(P27, "fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv"))
RA <- rbind(rbind(tab(XA, c("set", "ivc"), FALSE), tab(XA, "set", FALSE)[, ivc := "all"])[, prog := "all"],
            rbind(tab(XA, c("set", "ivc", "prog"), FALSE), tab(XA, c("set", "prog"), FALSE)[, ivc := "all"]), use.names = TRUE)
ck <- merge(RA[, .(set, prog, ivc = as.character(ivc), stands, s1 = surv_ratio, r1 = rec_ratio)], FA[, .(set, prog, ivc, stands0 = stands, s0 = surv_ratio, r0 = rec_ratio)], by = c("set", "prog", "ivc"))
e <- ck[, max(abs(c(s1 - s0, r1 - r0)), na.rm = TRUE)]; rp <- nrow(ck) == nrow(FA) && nrow(FA) == 68L && all(ck$stands == ck$stands0) && e <= 1e-9
KA27 <- readRDS(file.path(P27, "in/p27_foldA_keys.rds"))$KA; kx <- setequal(paste(KA27$set, KA27$STAND), paste(K$set, K$STAND))
fwrite(data.table(check = "foldA_survrec_PREREG27", cells = nrow(ck), cells_expected = nrow(FA), worst = e, foldA_keys_equal_PREREG27 = kx, pass = rp), FREP)
cat(sprintf("Reproduction: fold A table %d of %d cells, worst %.3g, fold A keys equal PREREG27: %s\n", nrow(ck), nrow(FA), e, kx))
if (!rp) { cat("REPRO FAIL fold A table: fit stop\n"); quit(save = "no", status = 3) }
## ---- (2) fit data: ns_c, fold A, NS_OP
k <- K[set == "ns_c" & prog_of(STAND) == "NS_OP", .(STAND, thr = SCORE_MINDBH_USED, sidx)]
X <- XA[set == "ns_c" & prog == "NS_OP"]
if (DRY) { k <- k[sidx %% 10L == 0L]; X <- X[STAND %in% k$STAND] }
R <- rec_comp("ns_c", "fi", k[STAND %in% X$STAND]); R <- merge(R, X[, .(STAND, sidx)], by = "STAND")
cs <- merge(X[, .(STAND, surv_o, surv_p)], R[, .(sp = sum(e2)), by = STAND], by = "STAND", all.x = TRUE)[is.na(sp), sp := 0]
wr <- cs[, max(abs(sp - surv_p) / pmax(1, abs(surv_p)))]; cat(sprintf("record level surv_p against stand_comp: worst scaled %.3g over %d stands\n", wr, nrow(cs)))
if (wr > 1e-9) { cat("record reconstruction differs from stand_comp: fit stop\n"); quit(save = "no", status = 3) }
R[, p := (e2 / e1)^(1 / iv)][, h := -log(p)]; if (R[, any(!is.finite(p) | p <= 0 | p > 1 + 1e-12)]) { cat("annual survival outside (0, 1]: fit stop\n"); quit(save = "no", status = 3) }
R[p > 1, p := 1][, h := -log(p)]
st <- X[order(STAND)][, si := .I]; R <- merge(R, st[, .(STAND, si)], by = "STAND"); NSs <- nrow(st); TMAX <- max(R$iv)
## S_pred and its derivative in theta, every record, vectorized over years
IDXT <- lapply(seq_len(TMAX), function(t) which(R$iv >= t)); PP <- R$p; HH <- R$h
spred <- function(th) { S <- rep(1, nrow(R)); dl <- rep(0, nrow(R))
  for (t in seq_len(TMAX)) { a <- IDXT[[t]]; Ht <- (t - 1) * HH[a]; den <- 1 + th * Ht
    if (any(den <= 0)) return(NULL); s <- 1 - (1 - PP[a]) / den
    if (any(s <= 0)) return(NULL)
    S[a] <- S[a] * s; dl[a] <- dl[a] + ((1 - PP[a]) * Ht / den^2) / s }
  list(S = S, dS = S * dl) }
solve_th <- function(w, th0 = 0) { th <- th0
  for (it in 1:100) { z <- spred(th); if (is.null(z)) return(c(NA, it))
    pr <- rowsum(R$e1 * z$S, R$si, reorder = TRUE)[, 1]; dp <- rowsum(R$e1 * z$dS, R$si, reorder = TRUE)[, 1]
    idx <- as.integer(names(pr)); U <- sum(w * st$surv_o) - sum(w[idx] * pr); dU <- -sum(w[idx] * dp)
    if (!is.finite(U) || !is.finite(dU) || dU == 0) return(c(NA, it)); stp <- U / dU
    if (th - stp < 0) for (hv in 0:30) { if (!is.null(spred(th - stp))) break; stp <- stp / 2 }   # step halving only where the form is undefined (theta below 0)
    th <- th - stp; if (abs(stp) < 1e-10) return(c(th, it)) }
  c(NA, 100) }
pt <- solve_th(rep(1, NSs)); th_hat <- pt[1]; cat(sprintf("theta point estimate %.15g, Newton iterations %d\n", th_hat, as.integer(pt[2])))
set.seed(20261026); B <- if (DRY) 20L else 1000L; sites <- sort(unique(st$sidx)); ns <- length(sites)
stop_reason <- ""; bt <- rep(NA_real_, B)
if (!is.finite(th_hat)) stop_reason <- "no convergence at the point estimate" else if (th_hat <= 0) stop_reason <- "estimate on the null side (theta at or below 0)"
if (!nzchar(stop_reason)) {
  IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B)
  for (b in seq_len(B)) { w <- tabulate(IDX[, b], ns)[match(st$sidx, sites)]; bt[b] <- solve_th(w, 0)[1] }
  if (sum(!is.finite(bt)) > 0.05 * B) stop_reason <- "more than 5 percent of bootstrap draws nonconverged" }
fit_stop <- nzchar(stop_reason)
ratio <- function(th) { z <- spred(th); sum(R$e1 * z$S) / sum(st$surv_o) }
q <- if (any(is.finite(bt))) quantile(bt, c(.025, .975), na.rm = TRUE, names = FALSE) else c(NA_real_, NA_real_)
F <- data.table(form = "sf_fr", param = "theta", estimate = th_hat, lo = q[1], hi = q[2], newton_iter = as.integer(pt[2]), boot_B = B, boot_nonconverged = sum(!is.finite(bt)),
  boot_negative = sum(is.finite(bt) & bt <= 0), seed = 20261026L, stands = NSs, sites = ns, records = nrow(R), surv_o = sum(st$surv_o), surv_ratio_null = ratio(0),
  surv_ratio_fit = if (is.finite(th_hat)) ratio(th_hat) else NA_real_, fit_stop = fit_stop, stop_reason = stop_reason, dry = DRY,
  note = "H_t = (t - 1) h, h = -log p, p = (e2/e1)^(1/iv) from frozen v141LTfi; ns_c fold A NS_OP")
fwrite(F, FFIT)
## fold A cells, reported: survivor ratio by PREREG27 interval class at the null and at the estimate
st2 <- merge(st[, .(STAND, si, surv_o)], K[set == "ns_c", .(STAND, ivc)], by = "STAND")
if (is.finite(th_hat) && !fit_stop) { z0 <- spred(0)$S; z1 <- spred(th_hat)$S
  P <- R[, .(si, e1)][, `:=`(s0 = e1 * z0, s1 = e1 * z1)][, .(p0 = sum(s0), p1 = sum(s1)), by = si]
  C <- merge(st2, P, by = "si", all.x = TRUE)[is.na(p0), `:=`(p0 = 0, p1 = 0)][, .(stands = .N, surv_o = sum(surv_o), ratio_null = sum(p0) / sum(surv_o), ratio_fit = sum(p1) / sum(surv_o)), by = ivc][order(ivc)]
  fwrite(C, FCEL); print(C, digits = 4) }
print(F); if (fit_stop) { cat("FIT STOP:", stop_reason, "\n"); quit(save = "no", status = 10) }
cat("FIT_DONE\n")

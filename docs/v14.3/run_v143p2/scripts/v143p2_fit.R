## v143p2_fit.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b), step 3: fit, identifiability, leave one installation out CV and
## selection, ending with the selection record and its md5. Reads ONLY the step 2 fit frame (CTRN, plus PEF if it
## passed the link test); no mefia_ph_c or sealed path is opened (gate H6).
##
## Registered objective: weighted least squares on interval diameter increment (cm yr-1), weights the expansion
## factors (r5's E = e2o), predicted by integrating annual steps open loop:
##   d_0 = d1;  m_k = m_T(tst + k, d_k / Dq);  d_{k+1} = d_k + G1 * m_k;  yhat = (d_iv - d1) / iv
## with G1 the A0 engine's first annual step increment of the tree (held), Dq the engine's start-of-interval Dq.
## Candidates (fixed before any fit): C0f (frozen r5), C0r, C1, C2, C3, C4, C5, C6, with the plan's bounds:
## alpha [0, 2], beta [0.005, 1], gamma [0, 4], tau [0.5, 10]; C2 and C3 thresholds from the 9 pair grid
## r_lo {0.5, 0.6, 0.7} x r_hi {0.75, 0.85, 1.0}, chosen inside each CV training fold by inner fit error; the full-data
## pair is the lowest full-data fit error, held fixed across bootstrap draws.
## H2 (r5 mode): r5's cell level log ratio objective, frame, weights, annualization and bounds reproduce alpha 0.37109 and
## beta 0.08220 within 1e-4; C0r is reported under both objectives.
## Bootstrap: installation clustered, 2,000 draws, seed 20261020; a candidate with more than 5% of draws at a registered
## bound (within 1e-5) is ineligible. Profiles (25 points per parameter) and the bootstrap correlation matrix reported;
## |r| > 0.95 flagged. CV: leave one installation out; metric the expansion weighted MSE of held-out interval diameter
## increment, pooled over folds; SE across folds as the SE of a cluster weighted mean (fold weights W_f = sum of e):
##   CV = sum_f W_f MSE_f / sum_f W_f;  SE = sqrt( K / (K - 1) * sum_f (W_f / W)^2 (MSE_f - CV)^2 ), the same for a
## paired difference with MSE_f(a) - MSE_f(b). Class gate on pooled held-out predictions: observed over predicted
## (sum e y / sum e max(yhat, 0.05)) within 0.10 of 1 in every d / Dq class at or above 0.6 with 30 or more records;
## the class below 0.6 is reported. Selection as the plan, in order; HL criterion at C2's full-data pair.
## Usage: Rscript v143p2_fit.R <root> [STRESS variant name] ; cores from SLURM_CPUS_PER_TASK. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(data.table); library(parallel)})
a <- commandArgs(TRUE); ROOT <- a[1]; VARIANT <- if (length(a) > 1) a[2] else "primary"
DRY <- identical(Sys.getenv("V143P2_DRY"), "1")
NCORE <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "4"))
H <- "/users/PUOM0008/crsfaaron"
W <- file.path(ROOT, "work"); O <- file.path(ROOT, "out"); L <- file.path(ROOT, "logs")
TAGV <- if (VARIANT == "primary") "" else paste0("_", VARIANT)
fo <- file.path(W, sprintf("fit%s_SERVERONLY.rds", TAGV)); if (file.exists(fo)) stop("exists ", fo)
wout <- function(x, nm) { f <- file.path(O, sprintf("fit%s_%s_DATA.csv", TAGV, nm)); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "inst", "tree", "cn"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
NB <- if (DRY) 40L else 2000L
GR <- file.path(H, "magplot/verify/gydbreg20260916")
r5 <- readRDS(file.path(GR, "v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds"))
CAP <- 2.9848; RELB <- c(0, 0.6, 0.85, 1.15, 1.5, Inf)
GRID <- CJ(rlo = c(0.5, 0.6, 0.7), rhi = c(0.75, 0.85, 1.0))
if (VARIANT == "gridext") GRID <- CJ(rlo = c(0.4, 0.5, 0.6, 0.7), rhi = c(0.75, 0.85, 1.0, 1.15))

ff <- readRDS(file.path(W, "fitframe_SERVERONLY.rds"))
FFall <- as.data.table(ff$FF); LINK <- ff$LINK
use_pef <- isTRUE(LINK$PEF_JOINS)
if (VARIANT == "pef_excluded") use_pef <- FALSE
if (VARIANT == "pef_included_exploratory") use_pef <- TRUE
X <- FFall[src == "CTRN" | (src == "PEF" & use_pef)]
X <- X[is.finite(G1) & is.finite(DQ_ENG) & DQ_ENG > 0]
## dry run only: a subset of 5 installations, so that no full-data selection is seen before the step 2 md5
if (DRY) X <- X[INST %in% head(sort(unique(INST)), 5)]
if (VARIANT == "dq127") { X <- X[is.finite(DQ_ENG127) & DQ_ENG127 > 0]; X[, DQ := DQ_ENG127] } else X[, DQ := DQ_ENG]
X[, r := d1 / DQ]
setorder(X, INST, STAND, TREE_IDX)
cat(sprintf("variant %s: fit records %d (CTRN %d, PEF %d), clusters %d, PEF joins %s\n", VARIANT, nrow(X), X[src == "CTRN", .N], X[src == "PEF", .N],
            uniqueN(X$INST), use_pef))
INST <- sort(unique(X$INST)); X[, ci := match(INST, ..INST)]
K <- max(X$iv)
RESP <- if (VARIANT == "bai") "bai" else "dbh"
CAPALL <- if (VARIANT == "cap15") 1.5 else NA_real_
FLOOR127 <- VARIANT == "floor127"
## secondary control: CTRN unthinned A0 ratio by d / Dq class (pooled below 30 records), applied to predictions
CTRL <- NULL
if (VARIANT == "symcontrol") {
  C <- FFall[src == "CTRN_CONTROL" & is.finite(G1) & is.finite(DQ_ENG)]
  C[, rcl := cut(d1 / DQ_ENG, RELB, right = FALSE)]
  pooled <- C[, sum(e * y) / sum(e * G1)]
  CTRL <- C[, .(n = .N, ratio = sum(e * y) / sum(e * G1)), by = rcl][, ratio := fifelse(n >= 30, ratio, pooled)]
  X[, rcl := cut(r, RELB, right = FALSE)]; X[CTRL, on = "rcl", ctl := i.ratio]; X[is.na(ctl), ctl := pooled]
  print(CTRL); cat(sprintf("pooled control %.4f\n", pooled))
} else X[, ctl := 1]

## ---------------------------------------------------------------- candidate forms
CANDS <- c("C0r", "C1", "C2", "C3", "C4", "C5", "C6")
PNAMES <- list(C0f = character(0), C0r = c("alpha", "beta"), C1 = c("alpha", "beta", "gamma"), C2 = c("alpha", "beta"), C3 = c("alpha", "tau"),
               C4 = c("alpha", "beta", "gamma"), C5 = c("alpha", "beta"), C6 = c("alpha"))
LB <- c(alpha = 0, beta = 0.005, gamma = 0, tau = 0.5); UB <- c(alpha = 2, beta = 1, gamma = 4, tau = 10)
NPAR <- c(C0r = 2, C1 = 3, C2 = 4, C3 = 4, C4 = 3, C5 = 2, C6 = 1)
ORDER <- c("C6", "C5", "C2", "C1", "C4", "C3")
sm <- function(r, lo, hi) { u <- pmin(pmax((r - lo) / (hi - lo), 0), 1); 3 * u^2 - 2 * u^3 }
capr <- function(r, cap) { if (is.finite(CAPALL)) pmin(r, min(cap, CAPALL)) else pmin(r, cap) }
mTc <- function(cand, p, t, r, pair) {
  m <- switch(cand,
    C0f = 1 + r5$alpha * exp(-r5$beta * t) * capr(r, CAP)^2,
    C0r = 1 + p[1] * exp(-p[2] * t) * capr(r, CAP)^2,
    C1  = 1 + p[1] * exp(-p[2] * t) * capr(r, CAP)^p[3],
    C2  = 1 + p[1] * exp(-p[2] * t) * sm(capr(r, Inf), pair[1], pair[2]),
    C3  = 1 + p[1] * (t / p[2]) * exp(1 - t / p[2]) * sm(capr(r, Inf), pair[1], pair[2]),
    C4  = 1 + p[1] * exp(-p[2] * t) * capr(r, 1.5)^p[3],
    C5  = 1 + p[1] * exp(-p[2] * t),
    C6  = 1 + p[1] * exp(-0.08220 * t) * capr(r, CAP)^2)
  m }
## open loop integration over each record's annual steps
pred <- function(cand, p, Z, pair = c(NA, NA)) {
  d <- Z$d1; n <- nrow(Z)
  for (k in 0:(K - 1)) { act <- Z$iv > k; if (!any(act)) break
    t <- Z$tst[act] + k; r <- d[act] / Z$DQ[act]
    m <- mTc(cand, p, t, r, pair); if (FLOOR127) m <- ifelse(d[act] >= 12.7, m, 1)
    d[act] <- d[act] + Z$G1[act] * m }
  if (RESP == "bai") (pi / 40000) * (d^2 - Z$d1^2) / Z$iv * Z$ctl else (d - Z$d1) / Z$iv * Z$ctl }
obsv <- function(Z) if (RESP == "bai") (pi / 40000) * (Z$d2o^2 - Z$d1^2) / Z$iv else Z$y
X[, yobs := obsv(X)]
wsse <- function(cand, p, Z, w, pair) { yh <- pred(cand, p, Z, pair); sum(w * Z$e * (Z$yobs - yh)^2) }
STARTS <- list(C0r = list(c(0.37, 0.08), c(1.0, 0.02), c(0.1, 0.3)), C1 = list(c(0.37, 0.08, 2), c(1.0, 0.02, 0.5), c(0.1, 0.3, 3)),
  C2 = list(c(0.37, 0.08), c(1.0, 0.02), c(0.1, 0.3)), C3 = list(c(0.37, 2), c(1.0, 5), c(0.1, 1)),
  C4 = list(c(0.37, 0.08, 2), c(1.0, 0.02, 0.5), c(0.1, 0.3, 3)), C5 = list(c(0.37, 0.08), c(1.0, 0.02), c(0.1, 0.3)), C6 = list(0.37, 1.0, 0.1))
fit1 <- function(cand, Z, w = rep(1, nrow(Z)), pair = c(NA, NA), starts = STARTS[[cand]]) {
  lo <- LB[PNAMES[[cand]]]; hi <- UB[PNAMES[[cand]]]; best <- NULL
  for (st in starts) { st <- pmin(pmax(st, lo), hi)
    o <- tryCatch(optim(st, function(q) wsse(cand, q, Z, w, pair), method = "L-BFGS-B", lower = lo, upper = hi, control = list(factr = 1e7, maxit = 500)),
                  error = function(e) NULL)
    if (!is.null(o) && (is.null(best) || o$value < best$value)) best <- o }
  if (is.null(best)) list(par = rep(NA_real_, length(lo)), value = NA_real_, conv = NA_integer_) else list(par = setNames(best$par, names(lo)), value = best$value, conv = best$convergence) }
fitc <- function(cand, Z, w = rep(1, nrow(Z)), pair = NULL) {
  if (cand %in% c("C2", "C3") && is.null(pair)) {     # choose the pair by inner fit error
    fs <- lapply(seq_len(nrow(GRID)), function(i) c(fit1(cand, Z, w, unlist(GRID[i])), list(pair = unlist(GRID[i]))))
    v <- vapply(fs, function(f) f$value, 0); fs[[which.min(v)]] }
  else c(fit1(cand, Z, w, if (is.null(pair)) c(NA, NA) else pair), list(pair = if (is.null(pair)) c(NA, NA) else pair)) }

## ---------------------------------------------------------------- H2: r5 mode
H2 <- NULL
if (VARIANT == "primary") {
  T5 <- X[src == "CTRN"]
  T5[, `:=`(tbin = cut(tst, c(1, 3, 6, 11, Inf), right = FALSE), rbin = cut(d1 / Dq_r5, c(0, 0.6, 0.85, 1.1, 1.4, Inf), right = FALSE))]
  ss <- function(d) { u <- pmin(pmax((d - 12.7) / (15 - 12.7), 0), 1); 3 * u^2 - 2 * u^3 }
  T5[, DpL := Dp * (1 + (r5$lambda - 1) * ss(d1))]
  keep <- T5[, .(Do = sum(Do)), by = .(tbin, rbin)][Do > 0, .(tbin, rbin)]
  TF <- merge(T5, keep, by = c("tbin", "rbin"))
  obj5 <- function(p) { mt <- 1 + p[1] * exp(-p[2] * TF$tst) * (TF$d1 / TF$Dq_r5)^2
    z <- TF[, .(num = DpL * mt, den = Do, E = E, tbin, rbin)][, .(num = sum(num), den = sum(den), E = sum(E)), by = .(tbin, rbin)][den > 0 & num > 0 & E > 0]
    sum(z$E * log(z$num / z$den)^2) / sum(z$E) }
  best <- NULL; for (st in list(c(0.30, 0.10), c(1.00, 0.02), c(0.10, 0.30))) {
    o <- optim(st, obj5, method = "L-BFGS-B", lower = c(0, 0), upper = c(5, 1)); if (is.null(best) || o$value < best$value) best <- o }
  H2 <- data.table(records = nrow(TF), alpha = best$par[1], beta = best$par[2], alpha_r5 = r5$alpha, beta_r5 = r5$beta,
                   abs_diff_alpha = abs(best$par[1] - 0.37109), abs_diff_beta = abs(best$par[2] - 0.08220))
  H2[, pass := abs_diff_alpha <= 1e-4 & abs_diff_beta <= 1e-4]
  print(H2)
}

## ---------------------------------------------------------------- full data fits
FULL <- list()
for (cn in CANDS) { FULL[[cn]] <- fitc(cn, X); cat(sprintf("full %s: %s pair %s wsse %.6f\n", cn, paste(sprintf("%.5f", FULL[[cn]]$par), collapse = " "),
  paste(FULL[[cn]]$pair, collapse = "/"), FULL[[cn]]$value)) }
FULL$C0f <- list(par = numeric(0), value = wsse("C0f", NULL, X, rep(1, nrow(X)), c(NA, NA)), pair = c(NA, NA))
## full-data pair table for C2 and C3, edge flag
PAIRS <- rbindlist(lapply(c("C2", "C3"), function(cn) rbindlist(lapply(seq_len(nrow(GRID)), function(i) { f <- fit1(cn, X, pair = unlist(GRID[i]))
  data.table(cand = cn, rlo = GRID$rlo[i], rhi = GRID$rhi[i], wsse = f$value, alpha = f$par[1], p2 = f$par[2]) }))))
PAIRS[, picked := wsse == min(wsse), by = cand]
EDGE <- PAIRS[picked == TRUE, .(cand, rlo, rhi, edge = rlo == min(GRID$rlo) | rhi == max(GRID$rhi))]
print(EDGE)

## ---------------------------------------------------------------- bootstrap (installation clustered)
set.seed(20261020L)
WI <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(INST), length(INST), TRUE), length(INST)), integer(length(INST)))
BOOT <- rbindlist(mclapply(seq_len(NB), function(b) { w <- WI[X$ci, b]
  rbindlist(lapply(CANDS, function(cn) { f <- fit1(cn, X, w, FULL[[cn]]$pair, starts = c(list(FULL[[cn]]$par), STARTS[[cn]][1]))
    data.table(draw = b, cand = cn, param = names(f$par), value = unname(f$par)) })) }, mc.cores = NCORE))
BOOT[, at_bound := abs(value - LB[param]) < 1e-5 | abs(value - UB[param]) < 1e-5]
BND <- BOOT[, .(draws = uniqueN(draw), share_at_bound = mean(at_bound), lo = quantile(value, .025, na.rm = TRUE), hi = quantile(value, .975, na.rm = TRUE)), by = .(cand, param)]
BND[, estimate := mapply(function(c, p) unname(FULL[[c]]$par[p]), cand, param)]
ELIG_B <- BND[, .(bound_ok = max(share_at_bound) <= 0.05), by = cand]
print(BND)
COR <- rbindlist(lapply(CANDS, function(cn) { z <- dcast(BOOT[cand == cn], draw ~ param, value.var = "value")
  pn <- setdiff(names(z), "draw"); if (length(pn) < 2) return(NULL)
  cm <- suppressWarnings(cor(as.matrix(z[, ..pn]), use = "complete.obs"))
  rbindlist(lapply(seq_along(pn), function(i) rbindlist(lapply(seq_along(pn), function(j) if (j > i) data.table(cand = cn, p1 = pn[i], p2 = pn[j], r = cm[i, j]) else NULL)))) }))
if (nrow(COR)) COR[, flag_abs_gt_0.95 := abs(r) > 0.95]
## profile likelihood (wsse) on 25 point grids inside the bounds, other parameters refitted
PROF <- rbindlist(mclapply(CANDS, function(cn) { pn <- PNAMES[[cn]]; est <- FULL[[cn]]$par
  rbindlist(lapply(seq_along(pn), function(j) { gv <- seq(LB[pn[j]], UB[pn[j]], length.out = 25)
    rbindlist(lapply(gv, function(v) {
      if (length(pn) == 1) return(data.table(cand = cn, param = pn[j], value = v, wsse = wsse(cn, v, X, rep(1, nrow(X)), FULL[[cn]]$pair)))
      lo <- LB[pn[-j]]; hi <- UB[pn[-j]]
      g <- function(q) { p <- numeric(length(pn)); p[j] <- v; p[-j] <- q; wsse(cn, p, X, rep(1, nrow(X)), FULL[[cn]]$pair) }
      o <- tryCatch(optim(pmin(pmax(est[-j], lo), hi), g, method = "L-BFGS-B", lower = lo, upper = hi), error = function(e) NULL)
      data.table(cand = cn, param = pn[j], value = v, wsse = if (is.null(o)) NA_real_ else o$value) })) })) }, mc.cores = min(NCORE, length(CANDS))))
PROF[, dwsse := wsse - min(wsse, na.rm = TRUE), by = .(cand, param)]

## ---------------------------------------------------------------- leave one installation out CV
FOLDPAR <- list()
cvfold <- function(f) { tr <- X[INST != f]; ho <- X[INST == f]
  out <- list(); fp <- list()
  for (cn in c("C0f", CANDS)) {
    if (cn == "C0f") { yh <- pred("C0f", NULL, ho); pr <- c(NA, NA); pp <- numeric(0) } else {
      fx <- fitc(cn, tr); yh <- pred(cn, fx$par, ho, fx$pair); pr <- fx$pair; pp <- fx$par
      fp[[cn]] <- data.table(fold = f, cand = cn, param = c(names(pp), "rlo", "rhi"), value = c(unname(pp), pr)) }
    out[[cn]] <- data.table(fold = f, cand = cn, rec = which(X$INST == f), yh = yh, rlo = pr[1], rhi = pr[2], pars = paste(sprintf("%.6g", pp), collapse = " ")) }
  fpt <- rbindlist(fp)
  ## HL comparison: C2 and C3 at C2's full-data pair
  for (cn in c("C2", "C3")) { fx <- fit1(cn, tr, pair = FULL$C2$pair)
    out[[paste0(cn, "_HLpair")]] <- data.table(fold = f, cand = paste0(cn, "_HLpair"), rec = which(X$INST == f), yh = pred(cn, fx$par, ho, FULL$C2$pair),
      rlo = FULL$C2$pair[1], rhi = FULL$C2$pair[2], pars = paste(sprintf("%.6g", fx$par), collapse = " ")) }
  list(pred = rbindlist(out), fp = fpt) }
CVL <- mclapply(INST, cvfold, mc.cores = min(NCORE, length(INST)))
CVP <- rbindlist(lapply(CVL, `[[`, "pred")); FOLDPAR <- rbindlist(lapply(CVL, `[[`, "fp"))
CVP[, `:=`(y = X$yobs[rec], e = X$e[rec], r = X$r[rec])]
FW <- CVP[, .(Wf = sum(e), MSEf = sum(e * (y - yh)^2) / sum(e)), by = .(cand, fold)]
Kf <- uniqueN(FW$fold)
cvse <- function(w, m) { cv <- sum(w * m) / sum(w); se <- sqrt(Kf / (Kf - 1) * sum((w / sum(w))^2 * (m - cv)^2)); c(cv, se) }
CV <- FW[, { z <- cvse(Wf, MSEf); .(CV = z[1], SE = z[2], folds = .N) }, by = cand]
pdiff <- function(a, b) { x <- merge(FW[cand == a, .(fold, Wf, ma = MSEf)], FW[cand == b, .(fold, mb = MSEf)], by = "fold"); cvse(x$Wf, x$ma - x$mb) }
PD <- rbindlist(lapply(c("C0f", CANDS, "C3_HLpair"), function(cn) { b <- if (cn == "C3_HLpair") "C2_HLpair" else "C0r"; z <- pdiff(cn, b)
  data.table(cand = cn, ref = b, diff = z[1], se_diff = z[2]) }))
print(CV); print(PD)
## class gate on pooled held-out predictions
CG <- CVP[, .(n = .N, ratio = sum(e * y) / sum(e * pmax(yh, 0.05))), by = .(cand, rcl = cut(r, RELB, right = FALSE))][order(cand, rcl)]
CG[, gated := as.numeric(sub("^\\[([0-9.]+),.*$", "\\1", as.character(rcl))) >= 0.6 & n >= 30]
CG[, pass := !gated | abs(ratio - 1) <= 0.10]
GATE <- CG[, .(class_gate = all(pass)), by = cand]
print(CG)

## ---------------------------------------------------------------- selection
SEL <- merge(merge(CV[cand %in% CANDS], PD[cand %in% CANDS, .(cand, diff, se_diff)], by = "cand"), merge(GATE, ELIG_B, by = "cand"), by = "cand")
SEL[, beats_C0r := (-diff) > se_diff]
SEL[, eligible := class_gate & bound_ok & beats_C0r & cand != "C0r"]
SEL[, npar := NPAR[cand]][, ord := match(cand, ORDER)]
print(SEL)
selected <- NA_character_; verdict <- "H0: no eligible candidate beats C0r by more than one SE of the paired CV difference"
if (SEL[eligible == TRUE, .N] > 0) {
  b <- SEL[eligible == TRUE][which.min(CV)]
  tied <- SEL[eligible == TRUE & CV <= b$CV + b$SE]
  setorder(tied, npar, ord); selected <- tied$cand[1]
  verdict <- sprintf("selected %s (best eligible %s; tied set %s)", selected, b$cand, paste(tied$cand, collapse = " "))
}
HL <- PD[cand == "C3_HLpair"][, .(c3_minus_c2 = diff, se = se_diff, HL_supported = (-diff) > se_diff)]
cat("SELECTION:", verdict, "\n"); print(HL)
labels <- c(if (!is.na(selected) && selected %in% c("C3", "C4")) "FIA motivated",
            if (!is.na(selected) && selected %in% c("C2", "C3") && EDGE[cand == selected, edge]) "threshold pair on a grid edge")
REC <- list(variant = VARIANT, plan_md5 = "b7562e8bbe8e2fb6a0f748d26844940f", records = nrow(X), clusters = length(INST), pef_joins = use_pef,
            selected = selected, verdict = verdict, labels = labels,
            coefficients = if (!is.na(selected)) as.list(c(FULL[[selected]]$par, rlo = FULL[[selected]]$pair[1], rhi = FULL[[selected]]$pair[2])) else NULL,
            FULL = lapply(FULL, function(f) list(par = f$par, pair = f$pair, wsse = f$value)), CV = CV, PD = PD, SEL = SEL, HL = HL, H2 = H2,
            created = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
saveRDS(list(REC = REC, BOOT = BOOT, BND = BND, COR = COR, PROF = PROF, CVP = CVP[, .(fold, cand, rec, yh, rlo, rhi, pars)], FOLDPAR = FOLDPAR,
             CG = CG, PAIRS = PAIRS, EDGE = EDGE, CTRL = CTRL), fo)
cat(sprintf("%s  %s\n", unname(tools::md5sum(fo)), fo))
## the selection record: written, md5 logged (primary only) before any candidate prediction on mefia_ph_c or the sealed set
srec <- file.path(O, sprintf("fit%s_selection_record.txt", TAGV)); if (file.exists(srec)) stop("exists ", srec)
fullt <- rbindlist(lapply(names(FULL), function(cn) data.table(cand = cn, params = paste(sprintf("%s=%.8g", names(FULL[[cn]]$par), FULL[[cn]]$par), collapse = " "),
  pair = paste(FULL[[cn]]$pair, collapse = "/"), wsse = FULL[[cn]]$value)))
sink(srec); cat(sprintf("14.3 PREREG2 selection record, variant %s, %s\nplan md5 b7562e8bbe8e2fb6a0f748d26844940f\nfit frame md5 %s\nrecords %d, clusters %d, PEF joins %s\n",
  VARIANT, REC$created, unname(tools::md5sum(file.path(W, "fitframe_SERVERONLY.rds"))), nrow(X), length(INST), use_pef))
cat("VERDICT:", verdict, "\nLABELS:", paste(labels, collapse = "; "), "\n\nFull data fits\n"); print(fullt)
cat("\nCV (pooled LOIO MSE) and SE\n"); print(CV); cat("\nPaired differences against C0r\n"); print(PD); cat("\nSelection table\n"); print(SEL)
cat("\nHL criterion\n"); print(HL); if (!is.null(H2)) { cat("\nH2\n"); print(H2) }; sink()
m <- unname(tools::md5sum(srec)); cat(sprintf("%s  %s\n", m, srec))
if (VARIANT == "primary" && !DRY) cat(sprintf("%s  %s  selection record written %s\n", m, basename(srec), REC$created), file = file.path(L, "selection_md5.txt"), append = TRUE)
wout(CV, "cv"); wout(PD, "cv_paired"); wout(CG, "class_gate"); wout(SEL, "selection"); wout(BND, "bootstrap_bounds"); if (nrow(COR)) wout(COR, "bootstrap_cor")
wout(PROF, "profiles"); wout(PAIRS, "threshold_pairs"); wout(fullt, "full_fits"); wout(HL, "hl"); if (!is.null(H2)) wout(H2, "h2")
cat("FIT_DONE\n")

## v143p3_fit.R
## 14.3 pre-registration 3 (revision 1, md5 20364c4b, registered 2026-10-28T06:00:59-0400), step 3: fit, identifiability,
## CV, the fit-set class gate screen on CTRN and mefia_ph_c, and selection, ending with the selection record and its md5.
## Built from a copy of PREREG2's fitter (p2ref/v143p2_fit.R, md5 1214208c): same response, open loop annual integration,
## optimizer, bound rule, cluster weighted CV SE. Changes are the plan's revision 1 readings:
##   forms T0f (14.1 frozen, reference), T0c (C2 refitted, reference), T1, T2, T4 (candidates), T3 and TL (diagnostic);
##   joint fit set CTRN plus mefia_ph_c survivors (src "FIA"); two stages per form and grid cell: stage A fits every free
##   parameter on CTRN alone and keeps beta; stage B fixes beta and fits the rest on Q = 0.5 SSE_C / W_C + 0.5 SSE_F / W_F;
##   the grid cell with the lowest stage B Q is taken (inside each training fold for CV, on all data for the full fit);
##   27 CV folds (17 CTRN installations, 10 seeded mefia_ph_c plot folds), each held out once with every other record in
##   training; pooled CV = 0.5 CV_C + 0.5 CV_F, SE = sqrt(0.25 SE_C^2 + 0.25 SE_F^2), paired differences alike;
##   bootstrap 2,000 draws (seed 20261020), clusters resampled within source, grid cell held at the full-data pick.
## Selection: eligible = class gate passed on both sources, bound share <= 5%, beats T0c by more than one SE of the paired
## pooled difference; lowest pooled CV; tied within the best's SE; fewest parameters, then T2, T4, T1. TL is compared with
## the selected form (rule 3). T3 and TL never change the selection.
## VARIANT: primary | p2repro (gate H2b: C2, CTRN only, one stage, PREREG2 9 pair grid, full fit only) | fiashare |
##   ctrnonly | dq127 | floor127 | bai | rdext (stress variants, 200 draws, exploratory).
## Usage: Rscript v143p3_fit.R <root> [variant]; cores from SLURM_CPUS_PER_TASK; V143P3_DRY=1 for the dry run
## (5 CTRN installations, 50 mefia_ph_c plots, 40 draws, outputs under <root> given, which must be the dry directory).
## Never overwrites. Aggregates only in out/. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(data.table); library(parallel)})
a <- commandArgs(TRUE); ROOT <- a[1]; VARIANT <- if (length(a) > 1) a[2] else "primary"
DRY <- identical(Sys.getenv("V143P3_DRY"), "1")
NCORE <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", "4"))
H <- "/users/PUOM0008/crsfaaron"
W <- file.path(ROOT, "work"); O <- file.path(ROOT, "out"); L <- file.path(ROOT, "logs"); dir.create(W, FALSE, TRUE); dir.create(O, FALSE, TRUE); dir.create(L, FALSE, TRUE)
TAGV <- if (VARIANT == "primary") "" else paste0("_", VARIANT)
fo <- file.path(W, sprintf("fit3%s_SERVERONLY.rds", TAGV)); if (file.exists(fo)) stop("exists ", fo)
wout <- function(x, nm) { f <- file.path(O, sprintf("fit3%s_%s_DATA.csv", TAGV, nm)); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "inst", "tree", "cn"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
NB <- if (DRY) 40L else if (VARIANT == "primary") 2000L else 200L
r5 <- readRDS(file.path(H, "magplot/verify/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds"))
CAP <- 2.9848; RELB <- c(0, 0.6, 0.85, 1.15, 1.5, Inf)
PAIRS <- CJ(rlo = c(0.4, 0.5, 0.6, 0.7), rhi = c(0.75, 0.85, 1.0, 1.15))
RD <- if (VARIANT == "rdext") c(1.0, 1.15, 1.5, 1.7) else c(1.0, 1.15, 1.5)
if (VARIANT == "p2repro") PAIRS <- CJ(rlo = c(0.5, 0.6, 0.7), rhi = c(0.75, 0.85, 1.0))
GPR <- PAIRS[, .(rlo, rhi, rd = NA_real_)]
GPRD <- PAIRS[, .(rd = RD), by = .(rlo, rhi)][, .(rlo, rhi, rd)]
GNONE <- data.table(rlo = NA_real_, rhi = NA_real_, rd = NA_real_)

## ---------------------------------------------------------------- frame
FFP <- file.path(W, "fitframe3_SERVERONLY.rds")   # the dry run root holds its own dry frame
X <- as.data.table(readRDS(FFP)$FF)
if (DRY) { ci5 <- head(sort(unique(X[src == "CTRN", INST])), 5); set.seed(1L); p50 <- sample(sort(unique(X[src == "FIA", PLOTKEY])), 50)
  X <- X[(src == "CTRN" & INST %in% ci5) | (src == "FIA" & PLOTKEY %in% p50)] }
if (VARIANT == "p2repro") X <- X[src == "CTRN"]
if (VARIANT == "dq127") { X <- X[is.finite(DQ_ENG127) & DQ_ENG127 > 0]; X[, DQ := DQ_ENG127] } else X[, DQ := DQ_ENG]
X[, r := d1 / DQ]
setorder(X, src, INST, PLOTKEY, STAND, TREE_IDX)
X[, CL := fifelse(src == "CTRN", paste0("C:", INST), paste0("F:", PLOTKEY))]
X[, FOLDID := fifelse(src == "CTRN", paste0("C:", INST), paste0("F:", fold))]
isC <- X$src == "CTRN"; isF <- !isC
K <- max(X$iv)
RESP <- if (VARIANT == "bai") "bai" else "dbh"
FLOOR127 <- VARIANT == "floor127"
X[, yobs := if (RESP == "bai") (pi / 40000) * ((d1 + y * iv)^2 - d1^2) / iv else y]
cat(sprintf("variant %s: records %d (CTRN %d, FIA %d), CTRN installations %d, FIA plots %d, K %d, draws %d\n", VARIANT, nrow(X), sum(isC), sum(isF),
            uniqueN(X[src == "CTRN", INST]), uniqueN(X[src == "FIA", PLOTKEY]), K, NB))
SRCW <- if (VARIANT == "fiashare") c(C = sum(isC) / nrow(X), F = sum(isF) / nrow(X)) else if (VARIANT == "ctrnonly") c(C = 1, F = 0) else c(C = 0.5, F = 0.5)
SRCW_CV <- if (VARIANT == "fiashare") SRCW else c(C = 0.5, F = 0.5)   # CV metric weights: half each, except the record share variant

## ---------------------------------------------------------------- forms
FORMS <- list(
  T0c = list(p = c("alpha", "beta"), grid = "pair"),
  T1  = list(p = c("alpha", "beta", "delta", "gmin"), grid = "pairrd"),
  T2  = list(p = c("alpha", "beta", "rm", "s"), grid = "none"),
  T4  = list(p = c("alpha", "beta", "kappa"), grid = "pairrd"),
  T3  = list(p = c("alpha", "beta", "c1", "c2", "c4", "c5"), grid = "none"),
  TL  = list(p = c("alpha", "beta", "kfia"), grid = "pair"))
if (VARIANT == "p2repro") FORMS <- FORMS["T0c"]
CANDS <- intersect(c("T1", "T2", "T4"), names(FORMS)); DIAG <- intersect(c("T3", "TL"), names(FORMS))
NPAR <- c(T0c = 4, T1 = 7, T2 = 4, T4 = 6, T3 = 6, TL = 5); ORDER <- c("T2", "T4", "T1")
LB <- c(alpha = 0, beta = 0.005, delta = 0, gmin = 0, rm = 0.3, s = 0.1, kappa = 0, c1 = 0, c2 = 0, c4 = 0, c5 = 0, kfia = -0.5)
UB <- c(alpha = 2, beta = 1, delta = 2, gmin = 1, rm = 3, s = 3, kappa = 4, c1 = 3, c2 = 3, c4 = 3, c5 = 3, kfia = 1)
STARTS <- list(T0c = if (VARIANT == "p2repro") list(c(0.37, 0.08), c(1.0, 0.02), c(0.1, 0.3)) else list(c(0.55, 0.06), c(1.0, 0.02), c(0.2, 0.3)),
  T1 = list(c(0.6, 0.06, 0.5, 0.3), c(1.0, 0.03, 1.0, 0.0), c(0.3, 0.2, 0.1, 0.7)),
  T2 = list(c(0.6, 0.06, 1.0, 0.6), c(1.0, 0.03, 0.8, 0.3), c(0.3, 0.2, 1.5, 1.5)),
  T4 = list(c(0.6, 0.06, 1.0), c(1.0, 0.03, 2.5), c(0.3, 0.2, 0.3)),
  T3 = list(c(0.6, 0.06, 0.3, 0.8, 1.0, 0.8), c(1.0, 0.03, 0.1, 1.0, 1.0, 0.5), c(0.3, 0.2, 0.6, 0.6, 1.0, 1.0)),
  TL = list(c(0.55, 0.06, 0.0), c(1.0, 0.02, 0.2), c(0.2, 0.3, -0.2)))
sm <- function(r, lo, hi) { u <- pmin(pmax((r - lo) / (hi - lo), 0), 1); 3 * u^2 - 2 * u^3 }
gfun <- function(fm, P, r, g) switch(fm,
  T0c = , TL = sm(r, g$rlo, g$rhi),
  T1 = sm(r, g$rlo, g$rhi) * pmax(P[["gmin"]], 1 - P[["delta"]] * pmax(0, r - g$rd)),
  T2 = exp(-(log(r / P[["rm"]]))^2 / (2 * P[["s"]]^2)),
  T4 = sm(r, g$rlo, g$rhi) * pmin(1, (g$rd / r)^P[["kappa"]]),
  T3 = c(P[["c1"]], P[["c2"]], 1, P[["c4"]], P[["c5"]])[findInterval(r, RELB[2:5]) + 1L])
## open loop integration; fm "T0f" is 14.1's frozen arithmetic (r5 alpha, beta, cap 2.9848, gamma 2)
pred <- function(fm, P, Z, g) {
  d <- Z$d1
  for (k in 0:(K - 1)) { act <- Z$iv > k; if (!any(act)) break
    t <- Z$tst[act] + k; r <- d[act] / Z$DQ[act]
    m <- if (fm == "T0f") 1 + r5$alpha * exp(-r5$beta * t) * pmin(r, CAP)^2 else 1 + P[["alpha"]] * exp(-P[["beta"]] * t) * gfun(fm, P, r, g)
    if (FLOOR127) m <- ifelse(d[act] >= 12.7, m, 1)
    d[act] <- d[act] + Z$G1[act] * m }
  yh <- if (RESP == "bai") (pi / 40000) * (d^2 - Z$d1^2) / Z$iv else (d - Z$d1) / Z$iv
  if (fm == "TL") yh <- yh * ifelse(Z$src == "FIA", 1 + P[["kfia"]], 1)
  yh }
qobj <- function(fm, P, Z, w, g, stage) {
  yh <- pred(fm, P, Z, g); se <- w * Z$e * (Z$yobs - yh)^2; c_ <- Z$src == "CTRN"
  if (stage == "A") return(if (VARIANT == "p2repro") sum(se[c_]) else sum(se[c_]) / sum((w * Z$e)[c_]))   # p2repro: PREREG2's raw wsse
  qC <- if (SRCW[["C"]] > 0) SRCW[["C"]] * sum(se[c_]) / sum((w * Z$e)[c_]) else 0
  qF <- if (SRCW[["F"]] > 0 && any(!c_)) SRCW[["F"]] * sum(se[!c_]) / sum((w * Z$e)[!c_]) else 0
  qC + qF }
opt <- function(fm, free, fixed, Z, w, g, stage, starts) {
  lo <- LB[free]; hi <- UB[free]; best <- NULL
  for (st in starts) { st <- pmin(pmax(st, lo), hi)
    f <- function(q) { P <- c(setNames(q, free), fixed); qobj(fm, P, Z, w, g, stage) }
    o <- tryCatch(optim(st, f, method = "L-BFGS-B", lower = lo, upper = hi, control = list(factr = 1e7, maxit = 500)), error = function(e) NULL)
    if (!is.null(o) && is.finite(o$value) && (is.null(best) || o$value < best$value)) best <- o }
  if (is.null(best)) NULL else list(par = setNames(best$par, free), value = best$value) }
## two stages for one grid cell
fit_cell <- function(fm, Z, w, g, starts = STARTS[[fm]]) {
  pn <- FORMS[[fm]]$p
  if (VARIANT == "p2repro") { o <- opt(fm, pn, numeric(0), Z, w, g, "A", starts); return(if (is.null(o)) NULL else list(par = o$par, value = o$value, beta_A = o$par[["beta"]])) }
  ## stage A on CTRN: TL is fitted as T0c there (k_FIA does not act on CTRN)
  fA <- if (fm == "TL") "T0c" else fm; pA <- FORMS[[fA]]$p
  sA <- lapply(starts, function(s) s[match(pA, pn)])
  oA <- opt(fA, pA, numeric(0), Z, w, g, "A", sA); if (is.null(oA)) return(NULL)
  bA <- oA$par[["beta"]]
  fr <- setdiff(pn, "beta"); sB <- lapply(c(list(c(oA$par, kfia = 0)[pn]), starts), function(s) unname(s[match(fr, pn)]))
  oB <- opt(fm, fr, c(beta = bA), Z, w, g, "B", sB); if (is.null(oB)) return(NULL)
  list(par = c(oB$par, beta = bA)[pn], value = oB$value, beta_A = bA) }
gridof <- function(fm) switch(FORMS[[fm]]$grid, pair = GPR, pairrd = GPRD, none = GNONE)
fit_form <- function(fm, Z, w = rep(1, nrow(Z)), cell = NULL, starts = STARTS[[fm]]) {
  G <- if (is.null(cell)) gridof(fm) else cell
  fs <- lapply(seq_len(nrow(G)), function(i) { f <- fit_cell(fm, Z, w, G[i], starts); if (is.null(f)) NULL else c(f, list(cell = G[i])) })
  v <- vapply(fs, function(f) if (is.null(f)) Inf else f$value, 0)
  if (all(!is.finite(v))) return(NULL)
  res <- fs[[which.min(v)]]; res$gridtab <- cbind(G, value = v); res }

## ---------------------------------------------------------------- full data fits
FULL <- setNames(mclapply(names(FORMS), function(fm) fit_form(fm, X), mc.cores = min(NCORE, length(FORMS)), mc.preschedule = FALSE), names(FORMS))
for (fm in names(FORMS)) { if (is.null(FULL[[fm]]) || inherits(FULL[[fm]], "try-error")) stop("no full-data fit for ", fm)
  cat(sprintf("full %s: %s cell %s/%s/%s value %.8g\n", fm, paste(sprintf("%s=%.6g", names(FULL[[fm]]$par), FULL[[fm]]$par), collapse = " "),
              FULL[[fm]]$cell$rlo, FULL[[fm]]$cell$rhi, FULL[[fm]]$cell$rd, FULL[[fm]]$value)) }
fullt <- rbindlist(lapply(names(FULL), function(fm) data.table(form = fm, params = paste(sprintf("%s=%.8g", names(FULL[[fm]]$par), FULL[[fm]]$par), collapse = " "),
  rlo = FULL[[fm]]$cell$rlo, rhi = FULL[[fm]]$cell$rhi, rd = FULL[[fm]]$cell$rd, objective = FULL[[fm]]$value)))
GRIDT <- rbindlist(lapply(names(FULL), function(fm) cbind(form = fm, FULL[[fm]]$gridtab)))
EDGE <- fullt[, .(form, edge = (!is.na(rlo) & rlo == min(PAIRS$rlo)) | (!is.na(rhi) & rhi == max(PAIRS$rhi)) | (!is.na(rd) & (rd == min(RD) | rd == max(RD))),
                  rd_at_top = !is.na(rd) & rd == max(RD))]
print(fullt); print(EDGE)
if (VARIANT == "p2repro") {
  p <- FULL$T0c$par; H2B <- data.table(alpha = p[["alpha"]], beta = p[["beta"]], rlo = FULL$T0c$cell$rlo, rhi = FULL$T0c$cell$rhi,
    alpha_p2 = 0.54768802, beta_p2 = 0.062357835, rlo_p2 = 0.5, rhi_p2 = 1.0)
  H2B[, `:=`(abs_diff_alpha = abs(alpha - alpha_p2), abs_diff_beta = abs(beta - beta_p2))][, pass := abs_diff_alpha <= 1e-4 & abs_diff_beta <= 1e-4 & rlo == rlo_p2 & rhi == rhi_p2]
  print(H2B); wout(H2B, "h2b"); wout(fullt, "full_fits"); saveRDS(list(FULL = FULL, H2B = H2B), fo); cat("FIT3_DONE\n"); quit(save = "no")
}

## ---------------------------------------------------------------- CV, 27 folds
FOLDS <- sort(unique(X$FOLDID))
cvfold <- function(f) { tr <- X[FOLDID != f]; hoi <- which(X$FOLDID == f); ho <- X[hoi]
  out <- list(data.table(fold = f, form = "T0f", rec = hoi, yh = pred("T0f", NULL, ho, NULL)))
  for (fm in names(FORMS)) { fx <- fit_form(fm, tr); if (is.null(fx)) stop("no fit for ", fm, " in fold ", f)
    out[[fm]] <- data.table(fold = f, form = fm, rec = hoi, yh = if (is.null(fx)) NA_real_ else pred(fm, fx$par, ho, fx$cell),
      rlo = fx$cell$rlo, rhi = fx$cell$rhi, rd = fx$cell$rd, pars = if (is.null(fx)) NA_character_ else paste(sprintf("%s=%.6g", names(fx$par), fx$par), collapse = " ")) }
  rbindlist(out, fill = TRUE) }
t0 <- Sys.time()
CVP <- rbindlist(mclapply(FOLDS, cvfold, mc.cores = min(NCORE, length(FOLDS)), mc.preschedule = FALSE), fill = TRUE)
cat(sprintf("CV done in %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
if (CVP[, any(is.na(yh))]) stop("CV fold without a prediction")
CVP[, `:=`(y = X$yobs[rec], e = X$e[rec], r = X$r[rec], src = X$src[rec], RF = X$RF[rec])]
FW <- CVP[, .(Wf = sum(e), MSEf = sum(e * (y - yh)^2) / sum(e)), by = .(form, fold, src)]
cvse <- function(w, m) { k <- length(w); cv <- sum(w * m) / sum(w); se <- sqrt(k / (k - 1) * sum((w / sum(w))^2 * (m - cv)^2)); c(cv, se) }
CVS <- FW[, { z <- cvse(Wf, MSEf); .(CV = z[1], SE = z[2], folds = .N) }, by = .(form, src)]
wC <- SRCW_CV[["C"]]; wF <- SRCW_CV[["F"]]
CV <- CVS[, .(CV = wC * CV[src == "CTRN"] + wF * CV[src == "FIA"], SE = sqrt(wC^2 * SE[src == "CTRN"]^2 + wF^2 * SE[src == "FIA"]^2),
              CV_CTRN = CV[src == "CTRN"], SE_CTRN = SE[src == "CTRN"], CV_FIA = CV[src == "FIA"], SE_FIA = SE[src == "FIA"]), by = form]
pdiff <- function(a, b) { x <- merge(FW[form == a, .(fold, src, Wf, ma = MSEf)], FW[form == b, .(fold, src, mb = MSEf)], by = c("fold", "src"))
  zc <- x[src == "CTRN", cvse(Wf, ma - mb)]; zf <- x[src == "FIA", cvse(Wf, ma - mb)]
  c(diff = wC * zc[1] + wF * zf[1], se = sqrt(wC^2 * zc[2]^2 + wF^2 * zf[2]^2), diff_C = zc[1], se_C = zc[2], diff_F = zf[1], se_F = zf[2]) }
PD <- rbindlist(lapply(c("T0f", names(FORMS)), function(fm) { z <- pdiff(fm, "T0c"); data.table(form = fm, ref = "T0c", diff = z[["diff"]], se_diff = z[["se"]],
  diff_CTRN = z[["diff_C"]], se_CTRN = z[["se_C"]], diff_FIA = z[["diff_F"]], se_FIA = z[["se_F"]]) }))
print(CV); print(PD)
## class gate on held-out predictions, per source
CG <- CVP[, .(n = .N, ratio = sum(e * y) / sum(e * pmax(yh, 0.05))), by = .(form, src, rcl = cut(r, RELB, right = FALSE))][order(form, src, rcl)]
CG[, gated := as.numeric(sub("^\\[([0-9.]+),.*$", "\\1", as.character(rcl))) >= 0.6 & n >= 30][, pass := !gated | abs(ratio - 1) <= 0.10]
GATE <- CG[, .(class_gate_CTRN = all(pass[src == "CTRN"]), class_gate_FIA = all(pass[src == "FIA"])), by = form][, class_gate := class_gate_CTRN & class_gate_FIA]
print(CG)
## removal intensity, reported (held-out mefia_ph_c predictions)
RFT <- CVP[src == "FIA" & is.finite(RF), .(n = .N, ratio = sum(e * y) / sum(e * pmax(yh, 0.05))),
           by = .(form, rf_class = cut(RF, c(-Inf, 0.35, 0.65, Inf), labels = c("RF up to 0.35", "0.35 to 0.65", "above 0.65")))][order(form, rf_class)]

## ---------------------------------------------------------------- bootstrap (clusters within source)
CLS <- sort(unique(X$CL)); X[, ci := match(CL, CLS)]
cC <- which(startsWith(CLS, "C:")); cF <- which(startsWith(CLS, "F:"))
set.seed(20261020L)
WI <- vapply(seq_len(NB), function(b) { v <- integer(length(CLS)); v[cC] <- tabulate(sample(cC, length(cC), TRUE), length(CLS))[cC]
  if (length(cF)) v[cF] <- tabulate(sample(cF, length(cF), TRUE), length(CLS))[cF]; v }, integer(length(CLS)))
t0 <- Sys.time()
BOOT <- rbindlist(mclapply(seq_len(NB), function(b) { w <- WI[X$ci, b]
  rbindlist(lapply(names(FORMS), function(fm) { st <- c(list(unname(FULL[[fm]]$par)), STARTS[[fm]][1])
    f <- fit_form(fm, X, w, cell = FULL[[fm]]$cell, starts = st)
    if (is.null(f)) data.table(draw = b, form = fm, param = FORMS[[fm]]$p, value = NA_real_) else data.table(draw = b, form = fm, param = names(f$par), value = unname(f$par)) })) },
  mc.cores = NCORE, mc.preschedule = TRUE))
cat(sprintf("bootstrap done in %.1f min\n", as.numeric(difftime(Sys.time(), t0, units = "mins"))))
BOOT[, at_bound := abs(value - LB[param]) < 1e-5 | abs(value - UB[param]) < 1e-5]
BND <- BOOT[, .(draws = sum(is.finite(value)), failed = sum(!is.finite(value)), share_at_bound = mean(at_bound, na.rm = TRUE),
                lo = quantile(value, .025, na.rm = TRUE), hi = quantile(value, .975, na.rm = TRUE)), by = .(form, param)]
BND[, estimate := mapply(function(f, p) unname(FULL[[f]]$par[p]), form, param)]
ELIG_B <- BND[, .(bound_ok = max(share_at_bound, na.rm = TRUE) <= 0.05), by = form]
COR <- rbindlist(lapply(names(FORMS), function(fm) { z <- dcast(BOOT[form == fm], draw ~ param, value.var = "value")
  pn <- setdiff(names(z), "draw"); if (length(pn) < 2) return(NULL)
  cm <- suppressWarnings(cor(as.matrix(z[, ..pn]), use = "complete.obs"))
  rbindlist(lapply(seq_along(pn), function(i) rbindlist(lapply(seq_along(pn), function(j) if (j > i) data.table(form = fm, p1 = pn[i], p2 = pn[j], r = cm[i, j]) else NULL)))) }))
if (nrow(COR)) COR[, flag_abs_gt_0.95 := abs(r) > 0.95]
print(BND)

## ---------------------------------------------------------------- selection
SEL <- merge(merge(CV[form %in% CANDS], PD[form %in% CANDS, .(form, diff, se_diff)], by = "form"), merge(GATE, ELIG_B, by = "form"), by = "form")
SEL[, beats_T0c := (-diff) > se_diff][, eligible := class_gate & bound_ok & beats_T0c][, npar := NPAR[form]][, ord := match(form, ORDER)]
print(SEL)
selected <- NA_character_; verdict <- "H0: no eligible form beats T0c by more than one SE of the paired pooled CV difference"
if (SEL[eligible == TRUE, .N] > 0) {
  b <- SEL[eligible == TRUE][which.min(CV)]
  tied <- SEL[eligible == TRUE & CV <= b$CV + b$SE]; setorder(tied, npar, ord); selected <- tied$form[1]
  verdict <- sprintf("selected %s (best eligible %s; tied set %s)", selected, b$form, paste(tied$form, collapse = " ")) }
HV2 <- if (!is.na(selected) && "TL" %in% names(FORMS)) { z <- pdiff("TL", selected); data.table(TL_minus_selected = z[["diff"]], se = z[["se"]])[, TL_beats_selected := (-TL_minus_selected) > se] } else
  data.table(TL_minus_selected = NA_real_, se = NA_real_, TL_beats_selected = NA)
cat("SELECTION:", verdict, "\n"); print(HV2)
labels <- c(if (!is.na(selected) && EDGE[form == selected, edge]) "grid edge", if (!is.na(selected)) "tail estimated from FIA")
REC <- list(variant = VARIANT, plan_md5 = "20364c4b065615317ea7feccb87f5919", frame_md5 = unname(tools::md5sum(FFP)), records = nrow(X),
            records_CTRN = sum(isC), records_FIA = sum(isF), selected = selected, verdict = verdict, labels = labels,
            coefficients = if (!is.na(selected)) c(as.list(FULL[[selected]]$par), as.list(FULL[[selected]]$cell)) else NULL,
            FULL = lapply(FULL, function(f) list(par = f$par, cell = f$cell, value = f$value)), CV = CV, PD = PD, SEL = SEL, HV2 = HV2, created = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
saveRDS(list(REC = REC, BOOT = BOOT, BND = BND, COR = COR, CVP = CVP[, .(fold, form, rec, yh, rlo, rhi, rd, pars)], CG = CG, GRIDT = GRIDT, EDGE = EDGE), fo)
cat(sprintf("%s  %s\n", unname(tools::md5sum(fo)), fo))
srec <- file.path(O, sprintf("fit3%s_selection_record.txt", TAGV)); if (file.exists(srec)) stop("exists ", srec)
sink(srec); cat(sprintf("14.3 PREREG3 selection record, variant %s, %s\nplan md5 20364c4b065615317ea7feccb87f5919\nfit frame md5 %s\nrecords %d (CTRN %d, FIA %d), draws %d\n",
  VARIANT, REC$created, REC$frame_md5, nrow(X), sum(isC), sum(isF), NB))
cat("VERDICT:", verdict, "\nLABELS:", paste(labels, collapse = "; "), "\n\nFull data fits\n"); print(fullt)
cat("\nCV (pooled, per source) and SE\n"); print(CV); cat("\nPaired differences against T0c\n"); print(PD); cat("\nSelection table\n"); print(SEL)
cat("\nHV2 (TL against the selected form)\n"); print(HV2); sink()
m <- unname(tools::md5sum(srec)); cat(sprintf("%s  %s\n", m, srec))
if (VARIANT == "primary" && !DRY) cat(sprintf("%s  %s  selection record written %s\n", m, basename(srec), REC$created), file = file.path(L, "selection_md5.txt"), append = TRUE)
wout(CV, "cv"); wout(CVS, "cv_by_source"); wout(PD, "cv_paired"); wout(CG[, .(form, src, rcl = as.character(rcl), n, ratio, gated, pass)], "class_gate"); wout(GATE, "class_gate_summary")
wout(SEL, "selection"); wout(BND, "bootstrap_bounds"); if (nrow(COR)) wout(COR, "bootstrap_cor"); wout(fullt, "full_fits"); wout(GRIDT, "grid_objective")
wout(EDGE, "edge"); wout(HV2, "hv2"); wout(RFT[, .(form, rf_class = as.character(rf_class), n, ratio)], "fia_by_rf")
cat("FIT3_DONE\n")

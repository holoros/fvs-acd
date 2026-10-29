## v143p2_score5.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b), step 5: confirmation on the SEALED New Hampshire and Vermont set,
## in the registered order, each stage's output md5 logged by the caller:
##   (a) after the selection md5: A0 and 14.1 on the sealed set; the sealed decomposition with its identity check, S_obs,
##       the implied release, and P1-NW's set-specific bounds (stage "a");
##   (b) the open conditions: "open" if 14.1's P1-S there is not an overshoot (not above +0.10 x S_obs), if ESI coverage
##       is below 80%, if fewer than 30 heavy stands qualify, or if fewer than 3 V1 classes have 30 or more trees (stage "a");
##   (c) the candidate scored once on V1, V1-L, P1-S, P1-NW, P2, P3, P5 (tol 25%; read also at 15% and 35%) (stage "c").
## Aaron's decision of 27 October 2026: every quantity is reported overall and split by site input (ESI, CSI fallback).
## Usage: Rscript v143p2_score5.R <root> <stage: a|c>. Writes out/score5<stage>_*_DATA.csv. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- a[1]; STAGE <- a[2]
H <- "/users/PUOM0008/crsfaaron"
SD <- dirname(normalizePath(sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE)[1])))
source(file.path(SD, "v143p2_decomp_lib.R"))
O <- file.path(ROOT, "out"); W <- file.path(ROOT, "work"); A <- file.path(O, "arms"); SLD <- file.path(ROOT, "sealed_SERVERONLY")
if (STAGE == "a" && !file.exists(file.path(ROOT, "logs/selection_md5.txt"))) stop("no selection record md5: the sealed set stays closed")
wout <- function(x, nm) { f <- file.path(O, sprintf("score5%s_%s_DATA.csv", STAGE, nm)); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "cn", "tree"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
rd <- function(dir) rbindlist(lapply(list.files(dir, pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE), fread), fill = TRUE)
rdt <- function(dir, pat) rbindlist(lapply(list.files(dir, pattern = pat, full.names = TRUE), fread), fill = TRUE)
ci <- function(v) unname(quantile(v, c(.025, .975), na.rm = TRUE))
pr <- fread(file.path(SLD, "bench_gyr_nhvt_ph_c_pairs.csv"))
ti <- fread(file.path(SLD, "bench_gyr_nhvt_ph_c_tree_init.csv")); t2 <- fread(file.path(SLD, "bench_gyr_nhvt_ph_c_tree_t2.csv"))
cl <- fread(file.path(SLD, "nhvt_ph_class_SERVERONLY.csv"), colClasses = list(character = c("CN_V0", "CN_V1", "CN_V2")))
chk <- fread(file.path(SLD, "nhvt_ph_build_checks_DATA.csv"))
trees <- rbindlist(lapply(c("NH", "VT"), function(s) fread(file.path(H, sprintf("fia_data/%s_TREE.csv", s)), select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "DIA", "AGENTCD", "AGENTCD_NERS"),
  colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))))[PLT_CN %in% c(cl$CN_V1, cl$CN_V2)]
arms <- if (STAGE == "a") c("A0", "v141") else c("A0", "v141", "SEL")
ok <- Reduce(function(x, y) merge(x, y, by = "STAND"), lapply(arms, function(k) { z <- rd(file.path(A, k, "nhvt_ph_c"))[, .(STAND, RUN_OK)]; setnames(z, "RUN_OK", paste0("ok_", k)); z }))
okc <- grep("^ok_", names(ok), value = TRUE); POP <- merge(ok[ok[, Reduce(`&`, lapply(.SD, function(v) v == 1)), .SDcols = okc]][, .(STAND)], cl[, .(STAND, PLOTKEY, HARVEST_TYPE, CN_V1, CN_V2, ESI_SRC)], by = "STAND")
lk <- fia_link(POP, trees)
DEC <- lapply(setNames(arms, arms), function(k) { d <- file.path(A, k, "nhvt_ph_c")
  decompose(ti, t2, rd(d)[RUN_OK == 1], rdt(d, "_t1_split_tree\\.csv$"), rdt(d, "_pred_t2_tree\\.csv$"), lk, pr, POP$STAND) })
IDC <- rbindlist(lapply(arms, function(k) { D <- merge(DEC[[k]]$D, POP[, .(STAND, HARVEST_TYPE)], by = "STAND")
  D[, .(arm = k, stands = .N, abs_diff_mean = abs(mean(gap) - mean(S + M + I + R - W)), max_abs_stand_resid = max(abs(resid))), by = HARVEST_TYPE] }))[, pass := abs_diff_mean <= 1e-6 & max_abs_stand_resid <= 1e-6]
M <- Reduce(function(x, y) merge(x, y, by = "STAND"), c(list(POP[, .(STAND, PLOTKEY, HARVEST_TYPE, ESI_SRC)]),
  lapply(arms, function(k) { z <- DEC[[k]]$D[, .(STAND, iv, t1 = BIOMASS_t1, o = BIOMASS_o, p = BIOMASS_p, g = gap, S, M, I, R, W, S_obs = S_obs_rate, S_pred = S_pred_rate)]
    nn <- setdiff(names(z), "STAND"); setnames(z, nn, paste0(nn, "_", k)); z })))
setnames(M, c("iv_A0", "t1_A0", "o_A0", "S_obs_A0"), c("iv", "t1", "o", "S_obs"))
## survivors (V1, V1-L, number of gated classes)
dq <- DEC$A0$r1[is.finite(e1) & e1 > 0 & d1 > 0, .(DQ = sqrt(sum(e1 * d1^2) / sum(e1))), by = STAND]
svt <- function(z, lab) { r <- z$r1[fate == "surv", .(dp = sum(e1 * dp) / sum(e1), d1 = d1[1], e1 = sum(e1), TREE2 = TREE2[1]), by = .(STAND, TREE_IDX)]
  r[t2[, .(STAND, TREE2 = TREE, d2 = DBH)], on = .(STAND, TREE2), d2 := i.d2]; setnames(r, "dp", paste0("dp_", lab)); r }
sv <- Reduce(function(x, y) merge(x, y[, c("STAND", "TREE_IDX", grep("^dp_", names(y), value = TRUE)), with = FALSE], by = c("STAND", "TREE_IDX")), lapply(arms, function(k) svt(DEC[[k]], k)))
sv <- merge(merge(sv, dq, by = "STAND"), M[, .(STAND, PLOTKEY, HARVEST_TYPE, ESI_SRC, iv)], by = "STAND")
sv[, `:=`(r = d1 / DQ, io = e1 * (d2 - d1))][, rcl := cut(r, c(0, 0.6, 0.85, 1.15, 1.5, Inf), right = FALSE)]
for (k in arms) sv[, (paste0("ip_", k)) := e1 * pmax(get(paste0("dp_", k)) - d1, 0.05 * iv)]
set.seed(20261017L); NB <- 1000L
lb <- function(rcl) as.numeric(sub("^\\[([0-9.]+),.*$", "\\1", as.character(rcl)))
SUBS <- list(overall = function(x) rep(TRUE, nrow(x)), ESI = function(x) x$ESI_SRC == "cov30m", CSI_fallback = function(x) x$ESI_SRC == "csi_fallback")
res <- list()
for (sn in names(SUBS)) {
  Ms <- M[SUBS[[sn]](M)]; PL <- sort(unique(Ms$PLOTKEY))
  WB <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(PL), length(PL), TRUE), length(PL)), integer(length(PL)))
  WS <- WB[match(Ms$PLOTKEY, PL), , drop = FALSE]
  cm <- function(x, i) { w <- WS[i, , drop = FALSE]; colSums(w * x[i]) / colSums(w) }
  cls <- function(k) which(Ms$HARVEST_TYPE == k); h <- cls("heavy")
  tolf <- function(k, f) f * mean(Ms$o[cls(k)] - Ms$t1[cls(k)]) / mean(Ms$iv[cls(k)])
  obsr <- if (length(h)) mean(Ms$o[h] - Ms$t1[h]) / mean(Ms$iv[h]) else NA_real_
  pre <- data.table(subset = sn, stands = nrow(Ms), heavy_stands = length(h), esi_coverage = mean(Ms$ESI_SRC == "cov30m"),
    S_obs_heavy = mean(Ms$S_obs[h]), implied_release = mean(Ms$S_obs[h] - Ms$S_pred_A0[h]),
    gap_A0_heavy = mean(Ms$g_A0[h]), gap_141_heavy = mean(Ms$g_v141[h]), P1S_141 = mean(Ms$S_v141[h]), P1S_A0 = mean(Ms$S_A0[h]),
    P1NW_bound_release = mean(Ms$g_A0[h]) + mean(Ms$S_obs[h] - Ms$S_pred_A0[h]) + 0.25 * obsr, P1NW_bound_141 = mean(Ms$g_v141[h]))
  svs <- sv[SUBS[[sn]](sv)]
  ncls <- svs[HARVEST_TYPE %in% c("heavy", "intermediate"), .N, by = rcl][lb(rcl) >= 0.6 & N >= 30, .N]
  pre[, `:=`(v1_classes_30 = ncls, open_141_not_overshoot = !(P1S_141 > 0.10 * S_obs_heavy), open_esi_lt_80 = esi_coverage < 0.80,
             open_heavy_lt_30 = heavy_stands < 30, open_v1_classes_lt_3 = ncls < 3)]
  pre[, open := open_141_not_overshoot | open_esi_lt_80 | open_heavy_lt_30 | open_v1_classes_lt_3]
  out <- list(pre = pre)
  if (STAGE == "c") {
    PG <- rbindlist(lapply(c("heavy", "intermediate", "light", "low_volume"), function(k) { i <- cls(k); if (!length(i)) return(NULL)
      b <- cm(Ms$g_SEL, i); b1 <- cm(Ms$g_v141, i); wors <- ci(abs(b) - abs(b1))[2]
      rbindlist(lapply(c(0.15, 0.25, 0.35), function(f) { t <- tolf(k, f); g <- mean(Ms$g_SEL[i])
        data.table(subset = sn, class = k, gate = c(heavy = "P1", intermediate = "P2", light = "P3", low_volume = "P3")[[k]], tol_frac = f, n = length(i), gap_SEL = g,
                   lo = ci(b)[1], hi = ci(b)[2], gap_141 = mean(Ms$g_v141[i]), gap_A0 = mean(Ms$g_A0[i]), worsen_ul95 = wors,
                   pass = if (k %in% c("heavy", "intermediate")) abs(g) <= t else abs(g) <= t && wors <= 0.5 * t) })) }))
    P1S <- data.table(subset = sn, P1S = mean(Ms$S_SEL[h]), tol = 0.10 * mean(Ms$S_obs[h]))[, pass := abs(P1S) <= tol]
    P1NW <- data.table(subset = sn, gap_SEL = mean(Ms$g_SEL[h]), bound_release = pre$P1NW_bound_release, bound_141 = pre$P1NW_bound_141)[, pass := gap_SEL <= bound_release & gap_SEL <= bound_141]
    P5 <- data.table(subset = sn, agb_bias_pct = 100 * (mean(Ms$p_SEL) - mean(Ms$o)) / mean(Ms$o))[, pass := abs(agb_bias_pct) <= 5]
    svs[, PJ := match(PLOTKEY, PL)]
    v1c <- function(z) z[, { bS <- vapply(seq_len(NB), function(b) { w <- WB[PJ, b]; sum(w * io) / sum(w * ip_SEL) }, 0)
        b1 <- vapply(seq_len(NB), function(b) { w <- WB[PJ, b]; sum(w * io) / sum(w * ip_v141) }, 0)
        .(n_trees = .N, ratio_SEL = sum(io) / sum(ip_SEL), lo = ci(bS)[1], hi = ci(bS)[2], ratio_141 = sum(io) / sum(ip_v141), ratio_A0 = sum(io) / sum(ip_A0),
          worsen_ul95 = ci(abs(bS - 1) - abs(b1 - 1))[2]) }, by = rcl][order(rcl)]
    V1 <- v1c(svs[HARVEST_TYPE %in% c("heavy", "intermediate")])[, gated := lb(rcl) >= 0.6 & n_trees >= 30][, pass := !gated | abs(ratio_SEL - 1) <= 0.10][, subset := sn]
    V1L <- v1c(svs[HARVEST_TYPE %in% c("light", "low_volume")])[, gated := lb(rcl) >= 0.6 & n_trees >= 30][, pass := !gated | worsen_ul95 <= 0.05][, subset := sn]
    out <- c(out, list(PG = PG, P1S = P1S, P1NW = P1NW, P5 = P5, V1 = V1, V1L = V1L))
  }
  res[[sn]] <- out
}
PRE <- rbindlist(lapply(res, `[[`, "pre")); print(PRE)
wout(IDC, "identity"); wout(PRE, "preconditions")
if (STAGE == "c") {
  for (nm in c("PG", "P1S", "P1NW", "P5", "V1", "V1L")) wout(rbindlist(lapply(res, `[[`, nm), fill = TRUE), tolower(nm))
  o <- res$overall
  fails <- c(if (!all(o$V1$pass)) "V1", if (!all(o$V1L$pass)) "V1-L", if (!o$P1S$pass) "P1-S", if (!o$P1NW$pass) "P1-NW",
             if (!all(o$PG[tol_frac == 0.25 & gate %in% c("P2", "P3"), pass])) "P2/P3", if (!o$P5$pass) "P5")
  verdict <- if (PRE[subset == "overall", open]) "open" else if (length(fails)) "not confirmed" else "confirmed"
  wout(data.table(verdict = verdict, failing = paste(fails, collapse = " ")), "decision"); print(verdict)
}
cat("SCORE5_DONE\n")

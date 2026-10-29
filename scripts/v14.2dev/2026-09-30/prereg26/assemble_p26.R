## PREREG26 assembly (plan md5 ad80d059). Usage: Rscript assemble_p26.R primary|followup [OUTDIR]. Reads out/traj_<arm>_<mix>.csv,
## the harness gate files and the re-derived thresholds; writes gates, relations, trajectories, realism, checker cross check,
## two figures and the verdict. Refuses to overwrite. No coordinates. No em dashes.
suppressMessages({library(data.table); library(ggplot2)})
a <- commandArgs(TRUE); MODE <- a[1]; J <- "/home/aaron/jobs/v142p26"; OD <- if (length(a) >= 2) a[2] else file.path(J, "assembled")
IN <- if (length(a) >= 3) a[3] else file.path(J, "out"); dir.create(OD, showWarnings = FALSE, recursive = TRUE)
DT <- "2026-09-30"; f <- function(x) file.path(OD, sprintf("gyr142-p26-%s", sub("^(.*)(\\.[a-z]+)$", paste0("\\1_", DT, "\\2"), x)))
wr <- function(x, nm) { fn <- f(nm); if (file.exists(fn)) stop("REFUSE ", fn); fwrite(x, fn); fn }
MIXES <- c("BF","RS","MX"); ESI <- c(9,12,15,18); N0 <- c(1500,3000,6000)
rd_arm <- function(arm) rbindlist(lapply(MIXES, function(m) { fn <- file.path(IN, sprintf("traj_%s_%s.csv", arm, m)); if (!file.exists(fn)) NULL else fread(fn) }))
TH <- fread(file.path(J, "assembled/thresholds_p26_DATA_2026-09-30.csv")); th <- setNames(TH$value, TH$quantity)
say <- function(...) cat(..., "\n", sep = "")
## ---------------- relations for one arm ----------------
relations <- function(tr) {
  d <- tr[age %% 5 == 0][order(mix, esi, n0, age)]
  d[, QMD_s := fifelse(TPH_s > 0, sqrt((BAPH_s/TPH_s)/(pi/40000)), NA_real_)][, SDI_s := fifelse(TPH_s > 0, TPH_s*(QMD_s/25)^1.605, 0)]
  out <- list()
  for (k in unique(d$cell)) { g <- d[cell == k]; u <- k
    keep <- c(TRUE, diff(g$QMD) > 0.10*5); gk <- g[keep]; loses <- (max(g$TPH) - min(g$TPH))/max(g$TPH) > 0.01
    if (nrow(gk) >= 3 && sd(log(gk$QMD)) > 1e-3) { sl <- unname(coef(lm(log(TPH) ~ log(QMD), gk))[2]); fl <- !(is.finite(sl) && sl > -2.2 && sl < -1.2)
      mg <- if (!fl) 0 else if (!is.finite(sl)) Inf else if (sl >= -1.2) sl + 1.2 else -2.2 - sl
      out[[length(out)+1]] <- data.table(relation = "Reineke", unit = u, evaluated = TRUE, flag = fl, margin = mg, stat = sl, npts = nrow(gk))
    } else out[[length(out)+1]] <- data.table(relation = "Reineke", unit = u, evaluated = FALSE, flag = loses, margin = if (loses) Inf else 0, stat = NA_real_, npts = nrow(gk))
    h <- g[TPH_s > 0]; exc <- if (nrow(h)) log10(h$TPH_s) - (th[["frontier_a"]] + th[["frontier_b"]]*log10(h$QMD_s)) else -Inf
    out[[length(out)+1]] <- data.table(relation = "Frontier", unit = u, evaluated = nrow(h) > 0, flag = any(exc > 0), margin = max(0, exc), stat = max(exc), npts = nrow(h))
    r <- max(max(g$BAPH_s)/th[["BA_q999"]], max(g$SDI_s)/th[["SDI_q999"]])
    out[[length(out)+1]] <- data.table(relation = "Magnitude", unit = u, evaluated = TRUE, flag = r > 1, margin = max(0, r - 1), stat = r, npts = nrow(g))
    fall <- max(0, -diff(g$HT))
    out[[length(out)+1]] <- data.table(relation = "HT_monotone", unit = u, evaluated = TRUE, flag = fall > 0.01, margin = if (fall > 0.01) fall else 0, stat = fall, npts = nrow(g)) }
  for (m in MIXES) for (n in N0) { g <- d[mix == m & n0 == n]; u <- sprintf("%s_N%d", m, n)
    hi <- max(sapply(ESI, function(s) min(g[esi == s]$HT))); hx <- min(sapply(ESI, function(s) max(g[esi == s]$HT)))
    if (hx > hi) { gr <- seq(hi, hx, length.out = 8)
      cv <- mean(sapply(gr, function(hg) { vv <- sapply(ESI, function(s) { z <- g[esi == s]; approx(z$HT, z$VOL, hg, rule = 2, ties = mean)$y }); sd(vv)/mean(vv) }))
      out[[length(out)+1]] <- data.table(relation = "Eichhorn", unit = u, evaluated = TRUE, flag = cv >= 0.15, margin = max(0, cv - 0.15), stat = cv, npts = 8L)
    } else out[[length(out)+1]] <- data.table(relation = "Eichhorn", unit = u, evaluated = FALSE, flag = TRUE, margin = Inf, stat = NA_real_, npts = 0L)
    for (v in c("HT","VOL","BAPH")) { inv <- 0L; mx <- 0
      for (ag in seq(5, 100, 5)) { z <- g[age == ag][order(esi)][[v]]; if (length(z) == 4 && is.unsorted(z)) { inv <- inv + 1L; mx <- max(mx, max(cummax(z) - z)/max(z)) } }
      out[[length(out)+1]] <- data.table(relation = paste0("SiteOrder_", v), unit = u, evaluated = TRUE, flag = inv > 0, margin = inv, stat = mx, npts = 20L) } }
  for (m in MIXES) for (s in ESI) { g <- d[mix == m & esi == s]; u <- sprintf("%s_E%g", m, s)
    viol <- 0L; for (ag in c(50, 100)) { z <- g[age == ag][order(n0)]; lost <- z$n0 - z$TPH_cohort; viol <- viol + sum(diff(lost) <= 0) }
    out[[length(out)+1]] <- data.table(relation = "Sukachev", unit = u, evaluated = TRUE, flag = viol > 0, margin = viol, stat = viol, npts = 6L)
    v100 <- g[age == 100]$VOL; v30 <- g[age == 30]$VOL; c100 <- sd(v100)/mean(v100); c30 <- sd(v30)/mean(v30)
    fl <- !(c100 < 0.15 && c100 < c30)
    out[[length(out)+1]] <- data.table(relation = "YieldDensity", unit = u, evaluated = TRUE, flag = fl, margin = if (fl) max(c100 - 0.15, c100 - c30) else 0, stat = c100, npts = 3L) }
  rbindlist(out) }
## ---------------- harness gates ----------------
gates <- list(); G <- function(g, val, thr, pass, prov) gates[[length(gates)+1]] <<- data.table(gate = g, value = as.character(val), threshold = thr, pass = isTRUE(pass), provenance = prov)
g0 <- tryCatch(fread(file.path(J, "logs/g0_result.csv")), error = function(e) NULL)
G("G0", if (is.null(g0)) "missing" else sprintf("worst scaled %.3g over %d stands, %d columns", g0$worst_scaled, g0$stands, g0$columns), "<= 1e-9", !is.null(g0) && g0$pass, "frozen Cardinal v141LT ns_c chunk 1, md5 a31786f8; logs/g0_result.csv")
g0c <- tryCatch(readLines(file.path(J, "logs/g0c_status.txt")), error = function(e) "missing")
G("G0c", g0c[1], "G0C_PASS", identical(g0c[1], "G0C_PASS"), "stored v1402 report md5 7a04368c; logs/g0c_diff.txt")
ARMS <- c("v141LT","v141LTfi"); if (MODE == "followup") ARMS <- c(ARMS, Filter(function(z) file.exists(file.path(IN, sprintf("traj_%s_MX.csv", z))), c("v141LTf","v141LTi","v141LTfi5")))
TR <- rbindlist(lapply(ARMS, rd_arm))
nt <- TR[, .(rows = .N, ok = all(run_ok == 1)), by = .(arm, cell)]
G("G1", sprintf("%d of %d trajectories complete with 101 rows (arms %s)", nt[rows == 101 & ok, .N], 36L*length(ARMS), paste(ARMS, collapse = " ")), "all", nt[rows == 101 & ok, .N] == 36L*length(ARMS), "out/traj_<arm>_<mix>.csv")
dr <- tryCatch(fread(file.path(J, "dry/dry_v141LT_MX_E18_N6000.csv")), error = function(e) NULL)
if (!is.null(dr)) { gg <- TR[arm == "v141LT" & cell == "MX_E18_N6000"]; num <- setdiff(names(dr)[sapply(dr, is.numeric)], character(0))
  same <- nrow(gg) == nrow(dr) && isTRUE(all.equal(as.matrix(dr[, ..num]), as.matrix(gg[, ..num]), tolerance = 0)) } else same <- FALSE
G("G2", if (same) "identical" else "differs or missing", "identical", same, "dry/dry_v141LT_MX_E18_N6000.csv against the grid cell")
harness_ok <- all(sapply(gates, function(x) x$pass))
## ---------------- relations and NI ----------------
REL <- rbindlist(lapply(ARMS, function(ar) { x <- TR[arm == ar]; if (!nrow(x)) return(NULL); r <- relations(x); r[, arm := ar]; r }))
setcolorder(REL, "arm")
ni <- function(cand) { A <- merge(REL[arm == cand], REL[arm == "v141LT"], by = c("relation","unit"), suffixes = c("", "_ref"))
  A[, newflag := flag & !flag_ref]
  B <- A[, .(cand_flags = sum(flag), ref_flags = sum(flag_ref), new_flags = sum(newflag), cand_worst = if (any(flag)) max(margin[flag]) else 0,
             ref_worst = if (any(flag_ref)) max(margin_ref[flag_ref]) else 0), by = relation]
  B[, marginB_ok := cand_flags == 0 | cand_worst <= ref_worst + 1e-9][, ni_ok := new_flags == 0 & marginB_ok]; list(A = A, B = B) }
N <- ni("v141LTfi")
for (i in seq_len(nrow(N$B))) with(N$B[i], G(sprintf("NI %s", relation), sprintf("flags fi %d, 14.1 %d, new %d; worst margin fi %.4g, 14.1 %.4g", cand_flags, ref_flags, new_flags, cand_worst, ref_worst), "no new flag; fi worst margin <= 14.1 worst", ni_ok, "PREREG26 relations, thresholds in plan"))
NI_ok <- all(N$B$ni_ok)
## ---------------- realism ----------------
RL <- dcast(TR[age %in% c(50, 100), .(arm, mix, esi, n0, age, HT, TPH, TPH_s, VOL)], mix + esi + n0 + age ~ arm, value.var = c("HT","TPH","TPH_s","VOL"))
RL[, HT_ratio := HT_v141LTfi/HT_v141LT][, TPH_ratio := TPH_v141LTfi/TPH_v141LT][, TPHs_ratio := TPH_s_v141LTfi/TPH_s_v141LT][, VOL_ratio := VOL_v141LTfi/VOL_v141LT]
implaus <- RL[esi >= 15 & ((HT_ratio < 0.90) | (age == 50 & HT_v141LTfi < 0.85*esi))]
implaus_ref <- RL[esi >= 15 & age == 50 & HT_v141LT < 0.85*esi]
## ---------------- checker cross check ----------------
CK <- list(); dir.create(file.path(OD, "checker"), showWarnings = FALSE)
for (ar in ARMS) for (m in MIXES) { x <- TR[arm == ar & mix == m & age %% 5 == 0, .(site = esi, origin = paste0("N0=", n0), age, HT, TPH, BAPH, QMD, VOL)]
  fn <- file.path(OD, "checker", sprintf("traj5_%s_%s.csv", ar, m)); if (file.exists(fn)) stop("REFUSE ", fn); fwrite(x, fn)
  o <- system2("Rscript", c("--vanilla", "/home/aaron/jobs/acd_bakuzis/bakuzis_check_step-aware_FINAL_2026-09-07.R", fn), stdout = TRUE, stderr = TRUE)
  writeLines(o, sub("\\.csv$", "_check.txt", fn)); fl <- grep("^FLAGS:", o, value = TRUE)
  CK[[length(CK)+1]] <- data.table(arm = ar, mix = m, summary = fl, reineke_flags = length(grep("Reineke slope", o)), eichhorn_flags = length(grep("^  - Eichhorn", o)), tph_nonmono = length(grep("TPH not monotone", o))) }
CK <- rbindlist(CK)
## ---------------- write ----------------
files <- c(wr(rbindlist(gates), "gates_DATA.csv"), wr(REL, "relations_DATA.csv"), wr(N$A, "relations-paired_DATA.csv"), wr(TR, "traj-annual_DATA.csv"),
  wr(TR[age %% 5 == 0], "traj-5yr_DATA.csv"), wr(RL, "realism_DATA.csv"), wr(CK, "checker_DATA.csv"))
theme_p26 <- function() theme_bw(base_size = 8) + theme(panel.background = element_rect(fill = "white", colour = NA), strip.background = element_rect(fill = "white"), panel.grid.minor = element_blank(), legend.position = "bottom")
F5 <- TR[age %% 5 == 0 & arm %in% c("v141LT","v141LTfi")]; F5[, ESI := factor(esi)][, N0 := factor(n0)]
p1 <- ggplot(F5[TPH > 0], aes(QMD, TPH, colour = ESI, linetype = N0, group = cell)) + geom_path(linewidth = 0.4) + scale_x_log10() + scale_y_log10() +
  geom_abline(slope = -1.605, intercept = log10(10^5.2), colour = "grey40", linewidth = 0.3, linetype = "dotted") + facet_grid(arm ~ mix) +
  scale_colour_viridis_d(end = 0.9) + labs(x = "QMD (cm, trees 4 cm and over)", y = "Stems per ha (4 cm and over)", title = "PREREG26 Reineke view, 100 yr, 5 yr points; dotted slope -1.605") + theme_p26()
ggsave(f("reineke.png"), p1, width = 7, height = 5, dpi = 300)
L <- melt(F5[n0 == 3000], id.vars = c("arm","mix","ESI","age"), measure.vars = c("HT","TPH","VOL"))
p2 <- ggplot(L, aes(age, value, colour = ESI, linetype = arm)) + geom_line(linewidth = 0.4) + facet_grid(variable ~ mix, scales = "free_y") +
  scale_colour_viridis_d(end = 0.9) + labs(x = "Projection year", y = NULL, title = "PREREG26 top height (m), stems (ha-1, 4 cm) and NSVB volume (m3 ha-1), N0 = 3,000") + theme_p26()
ggsave(f("height-stems-volume.png"), p2, width = 7, height = 6, dpi = 300)
outcome <- if (!harness_ok) "RULE1_HARNESS_FAILURE" else if (!NI_ok) "RULE2_NOT_CLEARED" else "RULE3_CLEARED"
V <- c("plan_md5=291bb1ecedaf59bbb13f53408077d20e (revision 2; revision 1 ad80d059)", sprintf("mode=%s", MODE), sprintf("outcome=%s", outcome),
  sprintf("harness_ok=%s NI_ok=%s", harness_ok, NI_ok), sprintf("new_flags=%d", sum(N$A$newflag)),
  sprintf("new_flag_units=%s", paste(N$A[newflag == TRUE, paste(relation, unit, sep = ":")], collapse = ";")),
  sprintf("realism_implausible_rows=%d (14.1 below 0.85 ESI at 50: %d)", nrow(implaus), nrow(implaus_ref)),
  sprintf("HT_ratio_range=%.4f..%.4f TPH100_ratio_range=%.3f..%.3f", min(RL$HT_ratio), max(RL$HT_ratio), min(RL[age == 100]$TPH_ratio), max(RL[age == 100]$TPH_ratio)))
if ("v141LTfi5" %in% ARMS) { S5 <- ni("v141LTfi5"); files <- c(files, wr(S5$B, "sens-fi5-NI_DATA.csv"))
  r5 <- dcast(TR[arm %in% c("v141LT","v141LTfi5") & age %in% c(50,100), .(arm, mix, esi, n0, age, HT, TPH)], mix + esi + n0 + age ~ arm, value.var = c("HT","TPH"))
  V <- c(V, sprintf("sens_fi5_NI_ok=%s new_flags=%d units=%s", all(S5$B$ni_ok), sum(S5$A$newflag), paste(S5$A[newflag == TRUE, paste(relation, unit, sep = ":")], collapse = ";")),
    sprintf("sens_fi5_HT_ratio_range=%.4f..%.4f TPH100_ratio_range=%.3f..%.3f", min(r5$HT_v141LTfi5/r5$HT_v141LT), max(r5$HT_v141LTfi5/r5$HT_v141LT), min(r5[age==100]$TPH_v141LTfi5/r5[age==100]$TPH_v141LT), max(r5[age==100]$TPH_v141LTfi5/r5[age==100]$TPH_v141LT))) }
if (MODE == "followup" && all(c("v141LTf","v141LTi") %in% ARMS) && !NI_ok) {
  lab <- function(f1, f2) fifelse(f1 & f2, "both", fifelse(f1, "height form", fifelse(f2, "ingrowth", "neither (interaction)")))
  Cf <- ni("v141LTf"); Ci <- ni("v141LTi"); at <- list()
  nf <- N$A[newflag == TRUE, .(relation, unit)]
  if (nrow(nf)) { x <- merge(nf, Cf$A[, .(relation, unit, f = newflag)], by = c("relation","unit")); x <- merge(x, Ci$A[, .(relation, unit, i = newflag)], by = c("relation","unit"))
    at[[1]] <- x[, .(kind = "new flag", relation, unit, v141LTf = f, v141LTi = i, component = lab(f, i))] }
  bf <- N$B[marginB_ok == FALSE, .(relation)]
  if (nrow(bf)) { x <- merge(bf, Cf$B[, .(relation, f = !marginB_ok)], by = "relation"); x <- merge(x, Ci$B[, .(relation, i = !marginB_ok)], by = "relation")
    at[[2]] <- x[, .(kind = "worse margin", relation, unit = "all", v141LTf = f, v141LTi = i, component = lab(f, i))] }
  at <- rbindlist(at, fill = TRUE)
  files <- c(files, wr(at, "attribution_DATA.csv")); V <- c(V, sprintf("attribution=%s", paste(at[, paste(kind, relation, unit, component, sep = ":")], collapse = ";"))) }
vf <- f(if (MODE == "followup") "verdict-followup_DATA.txt" else "verdict_DATA.txt"); if (file.exists(vf)) stop("REFUSE ", vf); writeLines(V, vf)
print(rbindlist(gates)); print(N$B); cat(V, sep = "\n"); cat("ASSEMBLY_DONE\n")

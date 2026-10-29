## PREREG49 stage 1 assembly (plan revision 1, md5 c2188088): every stage 1 gate with its source file and the decision rule in
## order. Harness: fit stop (fit file and its exit code), H0 (logs/h0_result.csv), TR (logs/tr_result.csv), K1 (PREREG17 summary
## K1 table, v141LTfis, NS four, after the retry rule). M1, M2: survivor ratio, 16 to 60 years, NS_OP, fold B of ns_c and of
## ns_long_c, v141LTfis, 0.90 to 1.10 (PREREG27 stand_comp and tab code, confirm.R lines, site cluster interval seed 20260930).
## M3: predicted annual survival (surv_p/n1)^(1/mean interval) by PREREG27 interval class with 30 or more measured t1 trees, NS_OP
## fold B of ns_c and ns_long_c, inside the observed site bootstrap 95 percent interval (B = 1000, seed 20260930). M4: PREREG22
## gates H1, S1, E3, E6b as coded in 2026-09-29_v142_p22_assemble.R (gates_at copied, v141LT references read and md5 checked)
## and H2 (h2_p49.R). M5: C1 %RMSE, v141LTfi minus v141LTfis at or above -0.5 on ns_c and ns_long_c (both scored by r2 here).
## Reported, not gated: whole frame survivor ratios, ns_fl and ns_long_fl, NS_RS, stems. Writes assembled/s1 (aggregates only)
## and the verdict line fis_enters_stage2. Refuses to overwrite. Headless, theme_classic, 300 dpi. No coordinates. No em dashes.
suppressMessages({library(data.table); library(digest); library(ggplot2)}); options(width = 220)
J <- Sys.getenv("P49_ROOT", "/home/aaron/jobs/v142p49"); O <- file.path(J, "assembled/s1"); TB <- file.path(J, "out/tables"); LG <- file.path(J, "logs")
if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O, recursive = TRUE)
source("/home/aaron/jobs/v142p49/scripts/p49_lib.R")
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
rdq <- function(f) if (file.exists(f)) fread(f) else NULL
rdm <- function(f, m) { x <- unname(tools::md5sum(f)); if (is.na(x) || x != m) stop("md5 ", f, " ", x, " != ", m); fread(f) }
GT <- list(); G <- function(g, val, thr, pass, src) GT[[length(GT) + 1L]] <<- data.table(gate = g, value = val, threshold = thr, pass = pass, source = src)
## ---- harness
FF <- file.path(J, "fit/gyr142-p49-sffr-fit_DATA_2026-10-26.csv"); FRp <- file.path(J, "fit/gyr142-p49-repro-foldA_DATA_2026-10-26.csv")
fit <- rdq(FF); rep <- rdq(FRp); rc <- suppressWarnings(as.integer(readLines(file.path(LG, "fit_rc.txt"), warn = FALSE)[1]))
G("Fit reproduction", if (is.null(rep)) "missing" else sprintf("%d of %d cells, worst %.3g", rep$cells, rep$cells_expected, rep$worst), "68 cells at or below 1e-9", !is.null(rep) && isTRUE(rep$pass), "fit/gyr142-p49-repro-foldA_DATA_2026-10-26.csv")
fit_ok <- !is.null(fit) && identical(rc, 0L) && !isTRUE(fit$fit_stop) && !is.null(rep) && isTRUE(rep$pass)
G("Fit stop", if (is.null(fit)) sprintf("no fit file, exit %s", rc) else sprintf("theta %.6g (%.6g to %.6g), %d of %d draws nonconverged, Newton %d; %s", fit$estimate, fit$lo, fit$hi, fit$boot_nonconverged, fit$boot_B, fit$newton_iter, if (nzchar(fit$stop_reason)) fit$stop_reason else "no stop"),
  "converged, theta above 0, at most 5 percent of draws nonconverged", fit_ok, "fit/gyr142-p49-sffr-fit_DATA_2026-10-26.csv; logs/fit_rc.txt")
H0 <- rdq(file.path(LG, "h0_result.csv")); h0_ok <- !is.null(H0) && isTRUE(H0$pass)
G("H0", if (is.null(H0)) "not run" else sprintf("worst results %.3g (%s), worst per tree %.3g (%s), %d stands, %d tree rows", H0$worst_results, H0$worst_results_col, H0$worst_trees, H0$worst_trees_col, H0$stands, H0$tree_rows), "at or below 1e-9", h0_ok, "logs/h0_result.csv")
TR <- rdq(file.path(LG, "tr_result.csv")); tr_ok <- !is.null(TR) && isTRUE(TR$pass)
G("TR", if (is.null(TR)) "not run" else sprintf("worst H %.3g, worst survival %.3g, %d stands, %d rows checked, %d with H above 0", TR$worst_abs_H, TR$worst_abs_surv, TR$stands, TR$rows_checked, TR$rows_H_pos), "below 1e-12, 2 stands, 3 years", tr_ok, "logs/tr_result.csv")
K1 <- rdq(file.path(TB, "gyr142-p49-fb-K1_DATA_2026-09-27.csv")); if (!is.null(K1)) K1 <- K1[arm == "v141LTfis"]
k1_ok <- !is.null(K1) && nrow(K1) == 4L && sum(K1$run_not_ok) == 0L
G("K1", if (is.null(K1)) "not run" else sprintf("%d RUN_OK other than 1 in %d stands, NS four, after the retry rule", sum(K1$run_not_ok), sum(K1$stands)), "0", k1_ok, "out/tables/gyr142-p49-fb-K1_DATA_2026-09-27.csv")
harness_ok <- fit_ok && h0_ok && tr_ok && k1_ok
m_ok <- c(M1 = NA, M2 = NA, M3 = NA, M4 = NA, M5 = NA)
if (!is.null(K1) && nrow(K1) == 4L) tryCatch({
  ## ---- survivor tables, PREREG27 confirm.R lines
  SETS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl"); BRK <- c(0, 5, 10, 15, 20, 30, 60); LAB <- c("iv05", "iv06_10", "iv11_15", "iv16_20", "iv21_30", "iv31_60")
  fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
  K <- rbindlist(lapply(SETS, function(s) { r <- fread(sprintf(RES$fi, s), select = c("STAND", "SITE", "interval_years", "SCORE_MINDBH_USED"))
    p <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "PLOTKEY"))
    merge(r, p, by = "STAND")[, `:=`(set = s, STAND = as.character(STAND), SITE = as.character(SITE))] }))
  FM <- unique(K[, .(SITE)])[, fold := fold(SITE)]; K <- merge(K, FM, by = "SITE"); K[, ivc := cut(interval_years, BRK, labels = LAB)]
  K[, `:=`(sidx = as.integer(factor(SITE)), pidx = as.integer(factor(paste(set, PLOTKEY))))][, `:=`(SITE = NULL, PLOTKEY = NULL)]
  comp <- function(a, fo) { X <- rbindlist(lapply(SETS, function(s) stand_comp(s, a, K[set == s & fold == fo, .(STAND, thr = SCORE_MINDBH_USED)])))
    X <- merge(X, K[, .(set, STAND, sidx, pidx, ivc, iv = interval_years, fold)], by = c("set", "STAND")); X[, prog := prog_of(STAND)]
    X[, iv3 := fcase(iv <= 5, "iv05", iv <= 15, "iv06_15", default = "iv16_60")]; X[, iv21 := iv > 20]; X }
  tab <- function(d, by, ci = TRUE) { R <- d[, .(stands = .N, sites = uniqueN(sidx), iv_mean = mean(iv), n1 = sum(n1), surv_o = sum(surv_o), surv_p = sum(surv_p), rec_o = sum(rec_o), rec_p = sum(rec_p)), by = by]
    R[, `:=`(surv_ratio = surv_p / surv_o, rec_ratio = rec_p / rec_o, stems_ratio = (surv_p + rec_p) / (surv_o + rec_o),
             d_surv_pct = 100 * (surv_p - surv_o) / (surv_o + rec_o), d_rec_pct = 100 * (rec_p - rec_o) / (surv_o + rec_o),
             ann_surv_o = (surv_o / n1)^(1 / iv_mean), ann_surv_p = (surv_p / n1)^(1 / iv_mean))]
    if (!ci) return(R); set.seed(20260930)
    CI <- d[, { a <- bsr(.SD, "surv_p", "surv_o"); b <- bsr(.SD, "rec_p", "rec_o"); .(surv_lo = a$lo, surv_hi = a$hi, rec_lo = b$lo, rec_hi = b$hi) }, by = by]
    merge(R, CI, by = by) }
  XS <- comp("fis", "B"); XF <- comp("fi", "B")
  T3 <- rbind(rbind(tab(XS, c("set", "prog", "iv3")), tab(XS, c("set", "iv3"))[, prog := "all"], use.names = TRUE)[, arm := "v141LTfis"],
              rbind(tab(XF, c("set", "prog", "iv3")), tab(XF, c("set", "iv3"))[, prog := "all"], use.names = TRUE)[, arm := "v141LTfi"], use.names = TRUE)[order(arm, set, prog, iv3)]
  TC <- rbind(rbind(tab(XS, c("set", "prog", "ivc")), tab(XS, c("set", "ivc"))[, prog := "all"], use.names = TRUE)[, arm := "v141LTfis"],
              rbind(tab(XF, c("set", "prog", "ivc")), tab(XF, c("set", "ivc"))[, prog := "all"], use.names = TRUE)[, arm := "v141LTfi"], use.names = TRUE)[order(arm, set, prog, ivc)]
  fwrite(T3, f_out("gyr142-p49-s1-survivors-iv3-foldB_DATA_2026-10-26.csv")); fwrite(TC, f_out("gyr142-p49-s1-survivors-ivc-foldB_DATA_2026-10-26.csv"))
  m12 <- function(s) { x <- T3[arm == "v141LTfis" & set == s & prog == "NS_OP" & iv3 == "iv16_60"]; f <- T3[arm == "v141LTfi" & set == s & prog == "NS_OP" & iv3 == "iv16_60"]; w <- T3[arm == "v141LTfis" & set == s & prog == "all" & iv3 == "iv16_60"]
    if (nrow(x) != 1L) return(list(v = "no cell", p = FALSE))
    list(v = sprintf("%.3f (%.3f to %.3f), %d stands; v141LTfi %.3f; whole frame v141LTfis %.3f", x$surv_ratio, x$surv_lo, x$surv_hi, x$stands, f$surv_ratio, w$surv_ratio), p = x$surv_ratio >= 0.90 && x$surv_ratio <= 1.10) }
  a <- m12("ns_c"); G("M1", a$v, "0.90 to 1.10", a$p, "assembled/s1/gyr142-p49-s1-survivors-iv3-foldB_DATA_2026-10-26.csv"); m_ok["M1"] <- a$p
  a <- m12("ns_long_c"); G("M2", a$v, "0.90 to 1.10", a$p, "assembled/s1/gyr142-p49-s1-survivors-iv3-foldB_DATA_2026-10-26.csv"); m_ok["M2"] <- a$p
  ## M3
  set.seed(20260930)
  M3 <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) { d <- XS[set == s & prog == "NS_OP"]
    nt <- stand_ntrees(s, K[set == s & fold == "B", .(STAND, thr = SCORE_MINDBH_USED)]); d <- merge(d, nt, by = "STAND", all.x = TRUE)[is.na(n1_trees), n1_trees := 0L]
    d[, { S <- .SD[, .(o = sum(surv_o), n = sum(n1), ivs = sum(iv), k = .N), by = sidx]; ns <- nrow(S)
      bo <- if (ns >= 2) replicate(1000, { i <- sample.int(ns, ns, TRUE); (sum(S$o[i]) / sum(S$n[i]))^(1 / (sum(S$ivs[i]) / sum(S$k[i]))) }) else NA_real_
      .(trees = sum(n1_trees), stands = .N, sites = ns, iv_mean = mean(iv), ann_surv_p = (sum(surv_p) / sum(n1))^(1 / mean(iv)), ann_surv_o = (sum(surv_o) / sum(n1))^(1 / mean(iv)),
        ann_o_lo = quantile(bo, .025, na.rm = TRUE, names = FALSE), ann_o_hi = quantile(bo, .975, na.rm = TRUE, names = FALSE)) }, by = ivc][, set := s] }))
  M3[, evaluated := trees >= 30L][, inside := ann_surv_p >= ann_o_lo & ann_surv_p <= ann_o_hi][, pass := !evaluated | inside]; setcolorder(M3, c("set", "ivc")); setorder(M3, set, ivc)
  fwrite(M3, f_out("gyr142-p49-s1-M3-annual-survival_DATA_2026-10-26.csv"))
  m_ok["M3"] <- all(M3$pass) && any(M3$evaluated)
  G("M3", paste(M3[evaluated == TRUE, sprintf("%s %s %.4f in (%.4f, %.4f) %s", set, ivc, ann_surv_p, ann_o_lo, ann_o_hi, fifelse(inside, "yes", "no"))], collapse = "; "), "inside the observed 95 percent interval, classes with 30 or more trees", m_ok[["M3"]], "assembled/s1/gyr142-p49-s1-M3-annual-survival_DATA_2026-10-26.csv")
  ## M4: PREREG22 gates as coded (gates_at copied from 2026-09-29_v142_p22_assemble.R)
  NS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl"); ARMX <- "v141LTfis"
  REF <- rdm("/home/aaron/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv", "a3ed3b76590441b8ac9985a429060041")[arm == "v141LT" & label %in% NS]
  RST <- rdm("/home/aaron/jobs/v142p17/in/cardinal/gyr142-p17-cardinal-structure_DATA_2026-09-27.csv", "732b553f9e9e3f984e014c51141e0dad")[arm == "v141LT" & set %in% NS]
  SCa <- fread(file.path(TB, "gyr142-p49-fb-scores_DATA_2026-09-27.csv")); STa <- fread(file.path(TB, "gyr142-p49-fb-structure_DATA_2026-09-27.csv"))
  SC <- SCa[arm == ARMX & label %in% NS]; ST <- STa[arm == ARMX & set %in% NS]
  one <- function(x, what) { if (nrow(x) != 1) stop(sprintf("%s: %d rows", what, nrow(x))); x }
  sc <- function(d, s, cv = "C1", a = unique(d$arm)) one(d[label == s & pop == "all" & conv == cv], sprintf("score %s %s %s", paste(a, collapse = "+"), s, cv))
  st <- function(d, s, p = "all") one(d[set == s & pop == p], sprintf("structure %s %s %s", paste(unique(d$arm), collapse = "+"), s, p))
  S1SETS <- list(c("ns_c", "B"), c("ns_long_c", "all"), c("ns_fl", "all"), c("ns_long_fl", "all"))
  gates_at <- function(SCx, STx, lab) rbind(
    rbindlist(lapply(NS, function(s) data.table(test = "H1", set = s, pop = "all", ref = st(RST, s)$topht_bias_pct, val = st(STx, s)$topht_bias_pct)))[, pass := abs(val) < abs(ref)],
    rbindlist(lapply(S1SETS, function(z) data.table(test = "S1", set = z[1], pop = z[2], ref = st(RST, z[1], z[2])$stems_ratio, val = st(STx, z[1], z[2])$stems_ratio,
      pass = st(STx, z[1], z[2])$abs_log_stems < st(RST, z[1], z[2])$abs_log_stems))),
    rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) data.table(test = "E3", set = s, pop = "all", ref = sc(REF, s)$rmse_pct, val = sc(SCx, s)$rmse_pct)))[, pass := (ref - val) >= -0.5],
    rbindlist(lapply(c("ns_fl", "ns_long_fl"), function(s) data.table(test = "E6b", set = s, pop = "all", ref = sc(REF, s)$bias_pct, val = sc(SCx, s)$bias_pct)))[, pass := abs(val) <= abs(ref)],
    fill = TRUE)[, arm := lab]
  D <- rbind(gates_at(SC, ST, ARMX), gates_at(SCa[arm == "v141LTfi" & label %in% NS], STa[arm == "v141LTfi" & set %in% NS], "v141LTfi (reported)"))
  H2 <- rdq(file.path(TB, "gyr142-p49-h2-gate_DATA_2026-10-26.csv"))
  D <- if (is.null(H2)) rbind(D, data.table(test = "H2", set = "missing", pop = "h2 gate file missing", ref = NA_real_, val = NA_real_, pass = FALSE, arm = ARMX), fill = TRUE) else
    rbind(D, H2[, .(test = "H2", set, pop = "fold B, 25 cm and over", ref = pmin(dev141, devh), val = devfis, pass, arm = ARMX)], fill = TRUE)
  fwrite(D, f_out("gyr142-p49-s1-M4-detail_DATA_2026-10-26.csv"))
  dd <- function(t) D[arm == ARMX & test == t, paste(sprintf("%s %s %.4g against %.4g", set, pop, val, ref), collapse = "; ")]
  m4 <- sapply(c("H1", "H2", "S1", "E3", "E6b"), function(t) all(D[arm == ARMX & test == t, pass]) && D[arm == ARMX & test == t, .N] > 0)
  for (t in names(m4)) G(paste0("M4 ", t), dd(t), switch(t, H1 = "|TOPHT bias| below v141LT, NS four", H2 = "|ratio - 1| below 14.1 and PREREG11, fold B, 25 cm and over", S1 = "|log stems ratio| below v141LT",
    E3 = "%RMSE(v141LT) minus %RMSE at or above -0.5", E6b = "|C1 bias| no worse than v141LT"), m4[[t]], if (t == "H2") "out/tables/gyr142-p49-h2-gate_DATA_2026-10-26.csv" else "assembled/s1/gyr142-p49-s1-M4-detail_DATA_2026-10-26.csv")
  m_ok["M4"] <- all(m4)
  ## M5
  M5 <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) data.table(set = s, rmse_fi = sc(SCa[arm == "v141LTfi" & label %in% NS], s)$rmse_pct, rmse_fis = sc(SC, s)$rmse_pct)))[, d := rmse_fi - rmse_fis][, pass := d >= -0.5]
  fwrite(M5, f_out("gyr142-p49-s1-M5_DATA_2026-10-26.csv")); m_ok["M5"] <- all(M5$pass)
  G("M5", paste(M5[, sprintf("%s %.3f against v141LTfi %.3f (difference %+.3f)", set, rmse_fis, rmse_fi, d)], collapse = "; "), "%RMSE(v141LTfi) minus %RMSE(v141LTfis) at or above -0.5", m_ok[["M5"]], "assembled/s1/gyr142-p49-s1-M5_DATA_2026-10-26.csv")
  ## reproduction of the PREREG22 v141LTfi rows by the r2 scorer and the structure summary (reported check)
  S22 <- fread("/home/aaron/jobs/v142p22/tables/gyr142-p22-fb-scores_DATA_2026-09-27.csv")[arm == "v141LTfi"]; T22 <- fread("/home/aaron/jobs/v142p22/tables/gyr142-p22-fb-structure_DATA_2026-09-27.csv")[arm == "v141LTfi"]
  cs <- merge(SCa[arm == "v141LTfi", .(label, pop, conv, ratio, bias_pct, rmse_pct)], S22[, .(label, pop, conv, ratio0 = ratio, bias0 = bias_pct, rmse0 = rmse_pct)], by = c("label", "pop", "conv"))
  ct <- merge(STa[arm == "v141LTfi", .(set, pop, stems_ratio, topht_bias_pct)], T22[, .(set, pop, s0 = stems_ratio, t0 = topht_bias_pct)], by = c("set", "pop"))
  RP <- data.table(check = c("r2 scores v141LTfi against PREREG22 scores", "structure v141LTfi against PREREG22 structure"), rows = c(nrow(cs), nrow(ct)), rows_ref = c(nrow(S22), nrow(T22)),
    na_mismatch = c(cs[, sum(is.na(ratio) != is.na(ratio0)) + sum(is.na(bias_pct) != is.na(bias0)) + sum(is.na(rmse_pct) != is.na(rmse0))], ct[, sum(is.na(stems_ratio) != is.na(s0)) + sum(is.na(topht_bias_pct) != is.na(t0))]),
    worst = c(cs[, max(abs(c(ratio - ratio0, bias_pct - bias0, rmse_pct - rmse0)), na.rm = TRUE)], ct[, max(abs(c(stems_ratio - s0, topht_bias_pct - t0)), na.rm = TRUE)]))
  fwrite(RP, f_out("gyr142-p49-s1-reproduction_DATA_2026-10-26.csv")); print(RP)
  VG <- rdq(file.path(TB, "gyr142-p49-fb-gates_DATA_2026-09-27.csv")); if (!is.null(VG)) fwrite(VG, f_out("gyr142-p49-s1-scorer-gates_DATA_2026-10-26.csv"))
  ## reported: stems and structure for both arms
  fwrite(STa[set %in% NS], f_out("gyr142-p49-s1-structure_DATA_2026-10-26.csv")); fwrite(SCa[label %in% NS], f_out("gyr142-p49-s1-scores_DATA_2026-10-26.csv"))
  ## figure: survivor ratio by interval class, fold B, NS_OP, ns_c and ns_long_c, v141LTfi and v141LTfis
  Fg <- TC[prog == "NS_OP" & set %in% c("ns_c", "ns_long_c") & ivc != "all" & stands >= 3]
  g <- ggplot(Fg, aes(iv_mean, surv_ratio, colour = arm, shape = arm)) + geom_hline(yintercept = 1, linetype = 2) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = 0.9, ymax = 1.1, alpha = 0.08) +
    geom_pointrange(aes(ymin = surv_lo, ymax = surv_hi), position = position_dodge(width = 1.2), size = 0.3) + geom_line(position = position_dodge(width = 1.2)) + facet_wrap(~ set) +
    scale_colour_manual(values = c(v141LTfi = "grey40", v141LTfis = "#1b6ca8")) + labs(x = "Mean interval length in class (years)", y = "Survivors, predicted over observed", colour = NULL, shape = NULL,
    title = "NS_OP fold B (held out): survivor ratio by interval class, 95% site cluster interval") + theme_classic(base_size = 9) + theme(legend.position = "bottom", strip.background = element_blank())
  png(f_out("gyr142-p49-s1-survivors-foldB_2026-10-26.png"), width = 7.5, height = 3.8, units = "in", res = 300); print(g); invisible(dev.off())
}, error = function(e) { cat("M EVALUATION ERROR:", conditionMessage(e), "\n"); G("M evaluation", paste("error:", conditionMessage(e)), "no error", FALSE, "logs/assemble_s1.log") })
GA <- rbindlist(GT); fwrite(GA, f_out("gyr142-p49-s1-gates_DATA_2026-10-26.csv"))
pm <- function(k) isTRUE(m_ok[[k]])
rule <- if (!harness_ok) "RULE1_HARNESS_FAILURE" else if (!(pm("M1") && pm("M2") && pm("M3"))) "RULE2_NOT_ADOPTED" else if (!(pm("M4") && pm("M5"))) "RULE3_NOT_ADOPTED_TRADEOFF" else "RULE4_ENTERS_STAGE2"
fails <- GA[pass == FALSE, gate]
V <- c(sprintf("plan_md5=%s", Sys.getenv("P49_PLAN_MD5", "unset")), sprintf("outcome=%s", rule), sprintf("fis_enters_stage2=%s", rule == "RULE4_ENTERS_STAGE2"),
  sprintf("harness_ok=%s fit_ok=%s H0=%s TR=%s K1=%s", harness_ok, fit_ok, h0_ok, tr_ok, k1_ok), sprintf("M=%s", paste(names(m_ok), m_ok, sep = ":", collapse = " ")),
  sprintf("failing=%s", paste(fails, collapse = ";")), "decision_weight=informs 14.3 only; 14.2 is unchanged")
writeLines(V, f_out("gyr142-p49-s1-verdict_DATA_2026-10-26.txt")); print(GA); cat(V, sep = "\n"); cat("S1_ASSEMBLY_DONE\n")

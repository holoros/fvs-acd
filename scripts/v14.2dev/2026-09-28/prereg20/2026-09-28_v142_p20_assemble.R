## PREREG20 assembly: gates, decision rule outcome, tables and figures into ~/jobs/v142p20/assembled/. Every v141LT reference
## is read from its frozen table, never typed in: C0 and C1 from PREREG16 tables_r1 (firebreather copy
## ~/jobs/v142vc/cardinal/tables_r1), structure and TOPHT from the PREREG17 Cardinal structure table
## (~/jobs/v142p17/in/cardinal). Headless, theme_classic, 300 dpi. No coordinates. No em dashes.
suppressMessages({library(data.table); library(ggplot2)}); options(width = 200)
J <- "/home/aaron/jobs/v142p20"; T <- file.path(J, "tables"); F <- file.path(J, "fit"); O <- file.path(J, "assembled"); dir.create(O, showWarnings = FALSE)
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
NS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl"); ARM <- "v141LTf"
REF <- fread("/home/aaron/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv")[arm == "v141LT" & pop == "all" & label %in% NS]
RST <- fread("/home/aaron/jobs/v142p17/in/cardinal/gyr142-p17-cardinal-structure_DATA_2026-09-27.csv")[arm == "v141LT" & pop == "all" & set %in% c(NS, "memat_c")]
SC <- fread(file.path(T, "gyr142-p20-fb-scores_DATA_2026-09-27.csv"))[arm == ARM & pop == "all"]
ST <- fread(file.path(T, "gyr142-p20-fb-structure_DATA_2026-09-27.csv"))[arm == ARM & pop == "all"]
K1 <- fread(file.path(T, "gyr142-p20-fb-K1_DATA_2026-09-27.csv"))
G0 <- fread(file.path(T, "gyr142-p20-G0-control_DATA_2026-09-28.csv"))
H2 <- fread(file.path(T, "gyr142-p20-h2-gate_DATA_2026-09-28.csv")); HS <- fread(file.path(T, "gyr142-p20-h2-sizeclass_DATA_2026-09-28.csv"))
c1 <- function(d, s, cv = "C1") d[label == s & conv == cv]
## gates
h1 <- merge(RST[set %in% NS, .(set, ref = topht_bias_pct)], ST[, .(set, arm = topht_bias_pct)], by = "set")[, pass := abs(arm) < abs(ref)]
e3 <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) data.table(set = s, ref = c1(REF, s)$rmse_pct, arm = c1(SC, s)$rmse_pct)))[, d_rmse := ref - arm][, pass := d_rmse >= -0.5]
e6 <- rbindlist(lapply(c("ns_fl", "ns_long_fl"), function(s) data.table(set = s, ref = c1(REF, s)$bias_pct, arm = c1(SC, s)$bias_pct)))[, pass := abs(arm) <= abs(ref)]
g0 <- G0[grepl("^G0", gate)]; ctl <- G0[grepl("control", gate)]
GT <- data.table(gate = c("G0 harness", "Maine control", "K1 failures", "H1 TOPHT", "H2 large tree height increment", "E3 (C1)", "E6b (C1)"),
  detail = c(sprintf("worst scaled %.3g over %d stands (%s)", g0$worst_scaled, g0$stands, g0$worst_col),
             sprintf("memat_c correction on: worst scaled %.3g over %d stands", ctl$worst_scaled, ctl$stands),
             sprintf("%d RUN_OK other than 1 in %d NS stands", sum(K1$run_not_ok), sum(K1$stands)),
             paste(sprintf("%s %+.2f to %+.2f", h1$set, h1$ref, h1$arm), collapse = "; "),
             paste(sprintf("%s fold B: 14.1 %.3f, PREREG11 %.3f, PREREG20 %.3f", H2$set, H2$r141, H2$rh, H2$rf), collapse = "; "),
             paste(sprintf("%s %.2f to %.2f, d_rmse %+.2f", e3$set, e3$ref, e3$arm, e3$d_rmse), collapse = "; "),
             paste(sprintf("%s %+.2f to %+.2f", e6$set, e6$ref, e6$arm), collapse = "; ")),
  pass = c(g0$pass, ctl$pass, sum(K1$run_not_ok) == 0, all(h1$pass), all(H2$pass), all(e3$pass), all(e6$pass)))
p <- setNames(GT$pass, c("G0", "CTL", "K1", "H1", "H2", "E3", "E6b"))
rule <- if (!p["G0"] || !p["CTL"] || !p["K1"]) "Outcome 1: harness failure; no verdict on the form" else
  if (all(p)) "Outcome 2: every gate passes; candidate 14.2 NS height calibration, pending a Bakuzis NS grid" else
  if (!p["H2"]) "Outcome 4: H2 fails; the form is still wrong for large trees; not adopted" else
  if (!p["H1"]) "Outcome 5: H1 fails with H2 passing; not adopted" else
  if (!p["E3"]) "Outcome 6: E3 fails; not adopted" else
  if (!p["E6b"]) "Outcome 3: height gates pass, E6b fails; height form right, long frame volume still carried by the stem deficit; not adopted alone" else "Outside rules"
fwrite(GT, f_out("gyr142-p20-gates_DATA_2026-09-28.csv")); writeLines(rule, f_out("gyr142-p20-verdict_DATA_2026-09-28.txt"))
## attribute table, NS four plus memat_c reference
AT <- merge(RST[, .(set, stems_141 = stems_ratio, ba_141 = ba_ratio, qmd_141 = qmd_ratio, topht_141 = topht_bias_pct)],
  ST[, .(set, stems_f = stems_ratio, ba_f = ba_ratio, qmd_f = qmd_ratio, topht_f = topht_bias_pct)], by = "set", all.x = TRUE)
VV <- rbindlist(lapply(NS, function(s) data.table(set = s, c0_141 = c1(REF, s, "C0")$bias_pct, c0_f = c1(SC, s, "C0")$bias_pct, c1_141 = c1(REF, s)$bias_pct, c1_f = c1(SC, s)$bias_pct,
  c1_f_lo = 100 * (c1(SC, s)$ratio_lo - 1), c1_f_hi = 100 * (c1(SC, s)$ratio_hi - 1), rmse1_141 = c1(REF, s)$rmse_pct, rmse1_f = c1(SC, s)$rmse_pct)))
AT <- merge(AT, VV, by = "set", all.x = TRUE); fwrite(AT, f_out("gyr142-p20-attributes_DATA_2026-09-28.csv"))
fwrite(HS, f_out("gyr142-p20-h2-sizeclass_DATA_2026-09-28.csv"))
for (n in c("gyr142-p20-fit-params_DATA_2026-09-28.csv", "gyr142-p20-fit-multiplier_DATA_2026-09-28.csv", "gyr142-p20-diag-dbhclass-foldA_DATA_2026-09-28.csv", "gyr142-p20-fit-insample-foldA_DATA_2026-09-28.csv"))
  file.copy(file.path(F, n), f_out(n))
## Figure 1: multiplier and the fit evidence (ns_c fold A)
PR <- fread(file.path(F, "gyr142-p20-fit-params_DATA_2026-09-28.csv")); BS <- fread(file.path(F, "gyr142-p20-fit-bootstrap_DATA_2026-09-28.csv"))
m2 <- function(D, b1, b2) exp(-b1 * pmax(0, pmin(D, 25) - 12.7) - b2 * pmax(0, D - 25))
dd <- seq(5, 55, 0.25); b1 <- PR[form == "two segment"]$b1; b2 <- PR[form == "two segment"]$b2
band <- data.table(D = dd, lo = sapply(dd, function(d) quantile(m2(d, BS$b1, BS$b2), .025)), hi = sapply(dd, function(d) quantile(m2(d, BS$b1, BS$b2), .975)))
cur <- rbind(data.table(D = dd, m = m2(dd, b1, b2), form = "PREREG20 two segment"), data.table(D = dd, m = m2(dd, 0.030906, 0.030906), form = "PREREG11 single exponential"))
DG <- fread(file.path(F, "gyr142-p20-diag-dbhclass-foldA_DATA_2026-09-28.csv"))[set == "ns_c" & dbh_mean >= 7.5]
g1 <- ggplot() + geom_ribbon(data = band, aes(D, ymin = lo, ymax = hi), fill = "grey80") + geom_line(data = cur, aes(D, m, linetype = form)) +
  geom_point(data = DG, aes(dbh_mean, m_needed, size = trees), shape = 21, fill = "white") + geom_vline(xintercept = c(12.7, 25), linetype = "dotted") +
  scale_size_area(max_size = 4, name = "Trees") + scale_linetype_manual(values = c("dashed", "solid"), name = NULL) + coord_cartesian(ylim = c(0.3, 1.15)) +
  labs(x = "Diameter at breast height at t1 (cm)", y = "Height increment multiplier (observed over 14.1 predicted)") + theme_classic(base_size = 10) + theme(legend.position = "right")
ggsave(f_out("gyr142-p20-multiplier_2026-09-28.png"), g1, width = 7, height = 4.5, dpi = 300)
## Figure 2: size class check, fold B, predicted over observed height increment with 95 percent site intervals
L <- rbind(HS[fold == "B", .(set, cls, arm = "14.1 (v141LT)", r = r141, lo = r141_lo, hi = r141_hi)], HS[fold == "B", .(set, cls, arm = "PREREG11 (v141LTh)", r = rh, lo = rh_lo, hi = rh_hi)],
  HS[fold == "B", .(set, cls, arm = "PREREG20 (v141LTf)", r = rf, lo = rf_lo, hi = rf_hi)])
L[, cls := factor(cls, c("below 12.7", "12.7 to 25", "25 and over"), c("below 12.7 cm", "12.7 to 25 cm", "25 cm and over"))]; L[, set := factor(set, NS)]
g2 <- ggplot(L, aes(cls, r, shape = arm)) + geom_hline(yintercept = 1, linetype = "dotted") + geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(0.5), size = 0.3) +
  facet_wrap(~set, nrow = 1) + labs(x = "Diameter class at t1", y = "Predicted over observed height increment (fold B)", shape = NULL) +
  theme_classic(base_size = 10) + theme(legend.position = "bottom", axis.text.x = element_text(angle = 30, hjust = 1))
ggsave(f_out("gyr142-p20-sizeclass_2026-09-28.png"), g2, width = 7.5, height = 4, dpi = 300)
print(GT); cat(rule, "\n"); print(AT, digits = 4); cat("ASSEMBLE_DONE\n")

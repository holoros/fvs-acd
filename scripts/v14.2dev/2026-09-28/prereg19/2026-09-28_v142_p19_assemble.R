## PREREG19 assembly: H0, N0, K1, selection on screened qc_c fold A, held out gates on fold B, decision rule, grid tables
## and figure into ~/jobs/v142p19/assembled/. Every rule is PREREG19 revision 1 (laptop md5 4b2c2488). Point estimates use
## the PREREG16 scorer's formulas (ratio of sums; bias = 100 (mean p - mean o) / mean o; %RMSE = 100 sqrt(mean((p - o)^2)) /
## mean o) applied to its per stand table. Headless, theme_classic, 300 dpi. No coordinates. No em dashes.
suppressMessages({library(data.table); library(ggplot2); library(digest)}); options(width = 200); set.seed(20260928L)
J <- "/home/aaron/jobs/v142p19"; H <- file.path(J, "home"); X <- file.path(J, "in/xfer/v142_20260925/bench141/results/v141LT")
O <- file.path(J, "assembled"); if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O)
ERR <- file.path(O, "error_log.txt")
rd <- function(f) tryCatch(fread(f), error = function(e) { cat(conditionMessage(e), "\n", file = ERR, append = TRUE); stop(e) })
one <- function(pat, dir = file.path(J, "tables")) { f <- list.files(dir, pat, full.names = TRUE); if (length(f) != 1) stop("expected one file for ", pat, " in ", dir, ", found ", length(f)); f }
AR <- c(p19_a0030 = 0.030, p19_a0060 = 0.060, p19_a0111 = 0.111, p19_a0250 = 0.250, p19_a0500 = 0.500, p19_a1000 = 1.000)
fold <- function(site) ifelse(strtoi(substr(vapply(as.character(site), function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
res <- function(a, s) { r <- rd(file.path(J, "results", a, sprintf("gyr_%s_%s_results.csv", a, s))); r[, STAND := as.character(STAND)]; r }

## ---- H0 and N0: firebreather against frozen Cardinal bench141 v141LT, every predicted column, ING_p and RUN_OK
cmp <- function(gate, a, s, ref, rows = NULL) {
  x <- res(a, s); b <- rd(file.path(X, ref)); b[, STAND := as.character(STAND)]
  if (!is.null(rows)) b <- b[STAND %in% x$STAND]
  pc <- unique(c(grep("_p$", names(b), value = TRUE), "RUN_OK")); m <- merge(x[, c("STAND", pc), with = FALSE], b[, c("STAND", pc), with = FALSE], by = "STAND")
  d <- sapply(pc, function(v) { u <- m[[paste0(v, ".x")]]; w <- m[[paste0(v, ".y")]]
    if (any(is.na(u) != is.na(w))) return(Inf); k <- !is.na(w); if (!any(k)) 0 else max(abs(u[k] - w[k]) / pmax(1, abs(w[k]))) })
  data.table(gate = gate, set = s, stands = nrow(m), stands_run = nrow(x), ref_stands = nrow(b), worst_scaled = max(d), worst_col = names(d)[which.max(d)],
             pass = nrow(m) == nrow(x) && nrow(m) == nrow(b) && max(d) <= 1e-9) }
H0 <- rbind(cmp("H0 harness", "p19_a0111", "qc_c", "gyr_v141LT_qc_c_results.csv"), cmp("H0 harness", "p19_a0111", "qc_fl", "gyr_v141LT_qc_fl_results.csv"),
            cmp("N0 regional (nb_c rows 1 to 40 at 1.000)", "nbctl_a1000", "nb_c", "gyr_v141LT_nb_c_results.csv", rows = TRUE))
print(H0)

## ---- per stand table from the scorer (C0, C1) and the reported C2 pass
STN <- rd(one("^gyr142-p19-fb-stands_DATA_.*\\.csv$")); STN[, STAND := as.character(STAND)]
SCR <- rd(one("^gyr142-p19-fb-scores_DATA_.*\\.csv$"))
C2F <- list.files(file.path(J, "tables_c2"), "^gyr142-p19-fb-c2-stands_DATA_.*\\.csv$", full.names = TRUE)
C2 <- if (length(C2F) == 1) { z <- fread(C2F); z[, STAND := as.character(STAND)]; z[, .(label, arm, STAND, V_o2, V_p2)] } else NULL
cat(sprintf("C2 pass %s\n", if (is.null(C2)) "not available (reported as not scored)" else "available"))

## ---- V3 check on the 0.111 arm (PREREG16 V3: screened qc_c C1 within 0.001 of 1.088)
v3 <- SCR[label == "qc_c" & arm == "p19_a0111" & pop == "screened" & conv == "C1"]
V3 <- data.table(gate = "H0 V3 check", set = "qc_c", stands = v3$stands, worst_scaled = abs(v3$ratio - 1.088), worst_col = sprintf("screened C1 %.4f", v3$ratio), pass = abs(v3$ratio - 1.088) <= 0.001)

## ---- population summaries: screened fold A, screened fold B, screened, all
pt <- function(o, p) c(ratio = sum(p) / sum(o), bias_pct = 100 * (mean(p) - mean(o)) / mean(o), rmse_pct = 100 * sqrt(mean((p - o)^2)) / mean(o))
tph <- function(ba, qmd) ba / (pi / 40000 * qmd^2)
S <- rbindlist(lapply(names(AR), function(a) rbindlist(lapply(c("qc_c", "qc_fl"), function(s) {
  r <- res(a, s)[RUN_OK == 1]; r[, fold := fold(SITE)]
  v <- merge(STN[label == s & arm == a], r[, .(STAND, SITE, fold, BA_o, BA_p, QMD_o, QMD_p, TOPHT_o, TOPHT_p)], by = "STAND")
  if (!is.null(C2)) v <- merge(v[, !c("V_o2", "V_p2")], C2[label == s & arm == a, .(STAND, V_o2, V_p2)], by = "STAND", all.x = TRUE)
  pops <- list(`screened A` = v[cut == FALSE & fold == "A"], `screened B` = v[cut == FALSE & fold == "B"], screened = v[cut == FALSE], all = v)
  rbindlist(lapply(names(pops), function(pn) { x <- pops[[pn]]; if (!nrow(x)) return(NULL)
    c0 <- pt(x$V_o, x$V_p); c1 <- pt(x$V_oh, x$V_ph); c2 <- if (all(is.finite(c(x$V_o2, x$V_p2)))) pt(x$V_o2, x$V_p2) else rep(NA_real_, 3)
    x <- x[is.finite(tph(BA_o, QMD_o)) & is.finite(tph(BA_p, QMD_p))]
    data.table(set = s, arm = a, qc_afac = AR[[a]], pop = pn, stands = nrow(x), sites = uniqueN(x$SITE),
      C0_ratio = c0[[1]], C1_ratio = c1[[1]], C1_bias_pct = c1[[2]], C1_rmse_pct = c1[[3]], C2_ratio = c2[[1]],
      ba_ratio = sum(x$BA_p) / sum(x$BA_o), stems_ratio = sum(tph(x$BA_p, x$QMD_p)) / sum(tph(x$BA_o, x$QMD_o)), qmd_ratio = mean(x$QMD_p) / mean(x$QMD_o),
      topht_bias_pct = 100 * (mean(x$TOPHT_p, na.rm = TRUE) - mean(x$TOPHT_o, na.rm = TRUE)) / mean(x$TOPHT_o, na.rm = TRUE)) })) }))))
S <- S[order(set, pop, qc_afac)]
## the scorer's own screened and all stands C1 must be reproduced by this summary (identity of formulas)
chk <- merge(S[set == "qc_c" & pop %in% c("screened", "all"), .(arm, pop, C1_ratio)], SCR[label == "qc_c" & conv == "C1", .(arm, pop, r = ratio)], by = c("arm", "pop"))
if (nrow(chk) != 12 || chk[, max(abs(C1_ratio - r))] > 1e-9) stop("population summary does not reproduce the scorer's C1 ratios")

## ---- selection on screened qc_c fold A
SEL <- S[set == "qc_c" & pop == "screened A", .(arm, qc_afac, stands, sites, C1_ratio, loss = abs(log(C1_ratio)))][order(qc_afac)]
astar_arm <- SEL[which.min(loss), arm]; astar <- AR[[astar_arm]]; flat <- diff(range(SEL$C1_ratio)) < 0.010
edge_pass <- !(astar %in% range(AR))
print(SEL, digits = 4); cat(sprintf("a* = %.3f (%s); fold A C1 span %.4f; edge %s\n", astar, astar_arm, diff(range(SEL$C1_ratio)), if (edge_pass) "interior" else "AT EDGE"))

## ---- gates on screened fold B, a* against 0.111
B <- S[set == "qc_c" & pop == "screened B"]; bs <- B[arm == astar_arm]; b0 <- B[arm == "p19_a0111"]
K1 <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(astar_arm, s); data.table(set = s, stands = nrow(r), run_not_ok = sum(r$RUN_OK != 1)) }))
GT <- rbindlist(list(
  data.table(gate = "H0 harness", detail = H0[gate == "H0 harness", paste(sprintf("%s worst %.2e on %d stands (%s)", set, worst_scaled, stands, worst_col), collapse = "; ")], pass = all(H0[gate == "H0 harness"]$pass) && V3$pass),
  data.table(gate = "H0 V3 check", detail = V3$worst_col, pass = V3$pass),
  data.table(gate = "N0 regional", detail = H0[grepl("^N0", gate), sprintf("nb_c worst %.2e on %d stands (%s)", worst_scaled, stands, worst_col)], pass = H0[grepl("^N0", gate)]$pass),
  data.table(gate = "K1 failures", detail = sprintf("%d RUN_OK other than 1 in %d stands at a*", sum(K1$run_not_ok), sum(K1$stands)), pass = sum(K1$run_not_ok) == 0),
  data.table(gate = "V1 held out bias", detail = sprintf("fold B C1 bias %+.2f at a* against %+.2f at 0.111", bs$C1_bias_pct, b0$C1_bias_pct), pass = abs(bs$C1_bias_pct) < abs(b0$C1_bias_pct)),
  data.table(gate = "V2 %RMSE", detail = sprintf("fold B C1 %%RMSE %.2f at a* against %.2f, d %+.2f", bs$C1_rmse_pct, b0$C1_rmse_pct, b0$C1_rmse_pct - bs$C1_rmse_pct), pass = b0$C1_rmse_pct - bs$C1_rmse_pct >= -0.5),
  data.table(gate = "B1 basal area", detail = sprintf("fold B |BA - 1| %.2f against %.2f points", 100 * abs(bs$ba_ratio - 1), 100 * abs(b0$ba_ratio - 1)), pass = 100 * (abs(bs$ba_ratio - 1) - abs(b0$ba_ratio - 1)) <= 1.0),
  data.table(gate = "B2 stems", detail = sprintf("fold B |stems - 1| %.2f against %.2f points", 100 * abs(bs$stems_ratio - 1), 100 * abs(b0$stems_ratio - 1)), pass = 100 * (abs(bs$stems_ratio - 1) - abs(b0$stems_ratio - 1)) <= 2.0),
  data.table(gate = "Edge", detail = sprintf("a* = %.3f on grid %s", astar, paste(AR, collapse = ", ")), pass = edge_pass)))
print(GT)
p <- setNames(GT$pass, c("H0", "V3", "N0", "K1", "V1", "V2", "B1", "B2", "Edge"))
verdict <- if (!p["H0"] || !p["K1"]) "Rule 1: harness or failure gate failed; no verdict" else
  if (!p["N0"]) "Rule 2: the anchor is not regional as coded; stop" else
  if (flat) "Rule 3: flat; C1 volume is insensitive to the anchor; not adopted; refit the anchor on tag height increment, not on volume" else
  if (astar == min(AR)) "Rule 4: a* at 0.030 (edge); not adopted; the QC C1 excess belongs to diameters and stems" else
  if (astar == max(AR)) "Rule 5: a* at 1.000 (edge); not adopted here; values above 1 need a new pre-registration with a height increment gate" else
  if (astar == 0.111) "Rule 6: a* = 0.111; the shipped value is the C1 optimum on the grid; 14.1 confirmed under C1" else
  if (!p["V1"]) "Rule 7: a* interior and not 0.111, V1 fails; the fold A optimum does not transfer; not adopted" else
  if (!all(p[c("V2", "B1", "B2")])) "Rule 8: V1 passes, V2, B1 or B2 fails; not adopted; trade off reported" else
  sprintf("Rule 9: every gate passes; QC_AFAC = %.3f is the 14.2 candidate QC regional setting, pending a QC tag height increment check and a Bakuzis check", astar)
cat("VERDICT:", verdict, "\n")

## ---- write
fwrite(H0, file.path(O, "gyr142-p19-H0N0_DATA_2026-09-28.csv")); fwrite(SEL, file.path(O, "gyr142-p19-selection_DATA_2026-09-28.csv"))
fwrite(GT, file.path(O, "gyr142-p19-gates_DATA_2026-09-28.csv")); fwrite(S, file.path(O, "gyr142-p19-grid_DATA_2026-09-28.csv"))
writeLines(c(sprintf("a_star=%.3f", astar), sprintf("a_star_arm=%s", astar_arm), sprintf("foldA_C1_span=%.5f", diff(range(SEL$C1_ratio))), paste0("verdict=", verdict)),
           file.path(O, "gyr142-p19-verdict_DATA_2026-09-28.txt"))

## ---- figure: C1 volume, basal area and stems ratios against QC_AFAC, screened fold A and fold B
F <- S[set == "qc_c" & pop %in% c("screened A", "screened B")]
L <- rbind(F[, .(pop, qc_afac, metric = "Volume, C1", y = C1_ratio)], F[, .(pop, qc_afac, metric = "Basal area", y = ba_ratio)], F[, .(pop, qc_afac, metric = "Stems", y = stems_ratio)])
pl <- ggplot(L, aes(qc_afac, y, colour = metric, shape = metric)) + geom_hline(yintercept = 1, colour = "grey40", linewidth = 0.3) +
  geom_vline(xintercept = 0.111, linetype = "dotted", colour = "grey55", linewidth = 0.4) + geom_vline(xintercept = astar, linetype = "dashed", colour = "grey35", linewidth = 0.3) +
  geom_line(linewidth = 0.5) + geom_point(size = 1.8) + facet_wrap(~ pop, nrow = 1) +
  scale_x_log10(breaks = unname(AR), labels = format(unname(AR), nsmall = 3)) +
  scale_colour_manual(values = c(`Volume, C1` = "#b5452b", `Basal area` = "#1b6ca8", Stems = "#4d8a3f")) +
  labs(x = "QC height increment anchor (QC_AFAC, log scale)", y = "Predicted / observed", colour = NULL, shape = NULL) +
  theme_classic(base_size = 9) + theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_text(face = "bold"))
ggsave(file.path(O, "gyr142-p19-grid_2026-09-28.png"), pl, width = 7.0, height = 3.2, dpi = 300, device = "png")
gc(verbose = FALSE); cat("ASSEMBLE_DONE\n")

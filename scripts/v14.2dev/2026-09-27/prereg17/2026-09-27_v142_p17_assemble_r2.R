## PREREG17 assembly, r2 (replaces 2026-09-27_v142_p17_assemble.R md5 5bd0b478, which dropped the IMULT 3.0 row from the
## written selection table through an inner merge with the Maine loss; m* and every gate are computed before that merge and
## are unchanged). Adds a post hoc table that applies the same gates to every interior grid point, labelled post hoc.
## Original header follows.
## PREREG17 assembly: selection, gates, verdict, grid tables and the figure. Reads the Cardinal tables (arms IMULT 1.0 to
## 2.5), the firebreather tables (IMULT 3.0), the G0 table, and the v141LT C1 references from PREREG16 tables_r1 (job
## 14937306), which are read here, never typed in [F9]. Every rule is PREREG17 revision 1 (md5 4a32d96f), unchanged in revision 2 (md5 b9dbd707). Headless.
## No coordinates. No em dashes.
suppressMessages({library(data.table); library(ggplot2)})
J <- "/home/aaron/jobs/v142p17"; OUT <- file.path(J, "assembled_r2"); dir.create(OUT, showWarnings = FALSE)
ERR <- file.path(OUT, "error_log.txt"); set.seed(20260927L)
rd <- function(f) tryCatch(fread(f), error = function(e) { cat(conditionMessage(e), "\n", file = ERR, append = TRUE); stop(e) })
IM <- c(v141LTig_m10 = 1.0, v141LTig_m15 = 1.5, v141LTig_m20 = 2.0, v141LTig = 2.5, v141LTig_m30 = 3.0)
NS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl"); MAINE <- c("memat_c", "medev_c", "mefia_l_c", "pef_c", "ctrn_c", "baxter_c")
SC <- rbind(rd(file.path(J, "in/cardinal/gyr142-p17-scores_DATA_2026-09-27.csv")), rd(file.path(J, "tables/gyr142-p17-fb-scores_DATA_2026-09-27.csv")), fill = TRUE)
REF <- rd("/home/aaron/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv")[arm == "v141LT"]
SC <- rbind(SC, REF[label %in% c(NS, MAINE, "qc_c")], fill = TRUE)
ST <- rbind(rd(file.path(J, "in/cardinal/gyr142-p17-cardinal-structure_DATA_2026-09-27.csv")), rd(file.path(J, "tables/gyr142-p17-fb-structure_DATA_2026-09-27.csv")))
K1 <- rbind(rd(file.path(J, "in/cardinal/gyr142-p17-cardinal-K1_DATA_2026-09-27.csv")), rd(file.path(J, "tables/gyr142-p17-fb-K1_DATA_2026-09-27.csv")))
G0 <- rd(file.path(J, "tables/gyr142-p17-G0_DATA_2026-09-27.csv"))
VG <- rbind(rd(file.path(J, "in/cardinal/gyr142-p17-gates_DATA_2026-09-27.csv")), rd(file.path(J, "tables/gyr142-p17-fb-gates_DATA_2026-09-27.csv")))
if (!all(VG$pass)) stop("a scorer gate (V0 to V2) failed; the scorer should have hard stopped")
for (a in names(IM)) for (s in NS) if (!nrow(ST[set == s & arm == a & pop == "all"])) stop(sprintf("missing structure %s %s", s, a))

## ---- selection: ns_c fold A, absolute log pooled stems ratio
SEL <- ST[set == "ns_c" & pop == "A" & arm %in% names(IM), .(arm, imult = IM[arm], stands, sites, stems_ratio, loss = abs_log_stems)][order(imult)]
mstar_arm <- SEL[which.min(loss), arm]; mstar <- IM[[mstar_arm]]; edge_pass <- !(mstar %in% range(IM))
SEL[, `:=`(also_nsc_B = ST[set == "ns_c" & pop == "B"][match(SEL$arm, arm), abs_log_stems], also_ns_long_c = ST[set == "ns_long_c" & pop == "all"][match(SEL$arm, arm), abs_log_stems])]
MA <- ST[set %in% MAINE & pop == "all" & arm %in% names(IM), .(maine_loss = mean(abs_log_stems)), by = arm][, imult := IM[arm]][order(imult)]
SEL <- merge(SEL, MA[, .(arm, maine_loss)], by = "arm", all.x = TRUE)[order(imult)]
if (nrow(SEL) != length(IM)) stop("selection table does not carry every grid point")
print(SEL, digits = 4); cat(sprintf("m* = %.1f (%s); edge %s\n", mstar, mstar_arm, if (edge_pass) "interior" else "AT EDGE"))

## ---- gates
g <- list()
g$G0 <- data.table(gate = "G0 harness", detail = sprintf("worst scaled %.2e on %d stands (%s)", G0$worst_scaled, G0$stands, G0$worst_col), pass = G0$pass)
k <- K1[label %in% NS & arm == mstar_arm]; g$K1 <- data.table(gate = "K1 failures", detail = sprintf("%d RUN_OK other than 1 in %d NS stands", sum(k$run_not_ok), sum(k$stands)), pass = sum(k$run_not_ok) == 0)
s1 <- rbindlist(lapply(list(c("ns_c", "B"), c("ns_long_c", "all"), c("ns_fl", "all"), c("ns_long_fl", "all")), function(z) {
  a <- ST[set == z[1] & pop == z[2] & arm == mstar_arm]; r <- ST[set == z[1] & pop == z[2] & arm == "v141LT"]
  data.table(set = z[1], pop = z[2], ref = r$stems_ratio, arm = a$stems_ratio, pass = a$abs_log_stems < r$abs_log_stems) }))
g$S1 <- data.table(gate = "S1 stems (held out)", detail = s1[, paste(sprintf("%s %s %.3f to %.3f", set, pop, ref, arm), collapse = "; ")], pass = all(s1$pass))
c1 <- function(s, a) { x <- SC[label == s & arm == a & conv == "C1" & pop == "all"]; if (nrow(x) != 1) stop(sprintf("C1 row %s %s: %d", s, a, nrow(x))); x }
e3 <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) data.table(set = s, ref = c1(s, "v141LT")$rmse_pct, arm = c1(s, mstar_arm)$rmse_pct)))[, d_rmse := ref - arm][, pass := d_rmse >= -0.5]
g$E3 <- data.table(gate = "E3 (C1)", detail = e3[, paste(sprintf("%s %%RMSE %.2f to %.2f, d_rmse %+.2f", set, ref, arm, d_rmse), collapse = "; ")], pass = all(e3$pass))
e6 <- rbindlist(lapply(c("ns_fl", "ns_long_fl"), function(s) data.table(set = s, ref = c1(s, "v141LT")$bias_pct, arm = c1(s, mstar_arm)$bias_pct)))[, pass := abs(arm) <= abs(ref)]
g$E6b <- data.table(gate = "E6b (C1)", detail = e6[, paste(sprintf("%s bias %+.2f to %+.2f", set, ref, arm), collapse = "; ")], pass = all(e6$pass))
g$Edge <- data.table(gate = "Edge", detail = sprintf("m* = %.1f on grid %s", mstar, paste(IM, collapse = ", ")), pass = edge_pass)
GT <- rbindlist(g); print(GT)

## ---- verdict, PREREG17 decision rule
p <- setNames(GT$pass, c("G0", "K1", "S1", "E3", "E6b", "Edge"))
s1_long_only <- !s1[set == "ns_long_fl", pass] && all(s1[set != "ns_long_fl", pass])
verdict <- if (!p["G0"] || !p["K1"]) "Rule 1: harness or failure gate failed; no verdict" else
  if (all(p)) sprintf("Rule 2: all gates pass; threshold matching with IMULT %.1f on NS is the 14.2 candidate NS configuration, pending a Bakuzis NS grid", mstar) else
  if (!p["Edge"]) "Rule 3: m* at the grid edge; not adopted" else
  if (!p["S1"] && s1_long_only) "Rule 4: S1 fails on ns_long_fl only; the long frame deficit is not an ingrowth rate problem (next suspect: survival over long intervals)" else
  if (p["S1"] && !p["E6b"]) "Rule 5: stems pass, E6b (C1) fails; the long frame deficit is not carried by stems (next suspect: survivor diameter growth)" else
  if (p["S1"] && p["E6b"] && !p["E3"]) "Rule 6: E3 fails; not adopted" else "Not adopted: gate combination outside rules 2 to 6, read in the RESULT"
cat("VERDICT:", verdict, "\n")

## ---- post hoc: the same gates at every interior grid point (NOT the pre-registered selection; reported only)
ph <- rbindlist(lapply(setdiff(names(IM), names(IM)[IM %in% range(IM)]), function(a) {
  k1 <- K1[label %in% NS & arm == a]
  s1p <- all(sapply(list(c("ns_c", "B"), c("ns_long_c", "all"), c("ns_fl", "all"), c("ns_long_fl", "all")), function(z)
    ST[set == z[1] & pop == z[2] & arm == a]$abs_log_stems < ST[set == z[1] & pop == z[2] & arm == "v141LT"]$abs_log_stems))
  d3 <- sapply(c("ns_c", "ns_long_c"), function(s) c1(s, "v141LT")$rmse_pct - c1(s, a)$rmse_pct)
  b6 <- sapply(c("ns_fl", "ns_long_fl"), function(s) c1(s, a)$bias_pct); r6 <- sapply(c("ns_fl", "ns_long_fl"), function(s) c1(s, "v141LT")$bias_pct)
  data.table(arm = a, imult = IM[[a]], K1 = sum(k1$run_not_ok) == 0, S1 = s1p, d_rmse_ns_c = d3[1], d_rmse_ns_long_c = d3[2], E3 = all(d3 >= -0.5),
             bias_ns_fl = b6[1], bias_ns_long_fl = b6[2], E6b = all(abs(b6) <= abs(r6)), label = "post hoc, not the pre-registered selection") }))
ph[, all_pass := K1 & S1 & E3 & E6b]; print(ph, digits = 3)
fwrite(ph, file.path(OUT, "gyr142-p17-posthoc-gridgates_DATA_2026-09-27.csv"))

## ---- grid table, NS four and controls
arms_all <- c(names(IM), "v141LT")
GR <- ST[pop == "all" & arm %in% arms_all, .(set, arm, stands, stems_ratio, ba_ratio, qmd_ratio, topht_bias_pct)]
w <- dcast(SC[pop == "all" & conv %in% c("C0", "C1", "C2") & arm %in% arms_all], label + arm ~ conv, value.var = c("ratio", "ratio_lo", "ratio_hi", "bias_pct", "rmse_pct"))
GR <- merge(GR, w, by.x = c("set", "arm"), by.y = c("label", "arm"), all.x = TRUE); GR[, imult := fifelse(arm == "v141LT", NA_real_, IM[arm])]
qs <- SC[label == "qc_c" & pop == "screened" & conv == "C1" & arm %in% arms_all, .(set = "qc_c screened", arm, ratio_C1 = ratio, ratio_lo_C1 = ratio_lo, ratio_hi_C1 = ratio_hi, bias_pct_C1 = bias_pct, rmse_pct_C1 = rmse_pct)]
GR <- rbind(GR, qs, fill = TRUE)[order(set, imult)]
fwrite(SEL, file.path(OUT, "gyr142-p17-selection_DATA_2026-09-27.csv")); fwrite(GT, file.path(OUT, "gyr142-p17-gates_DATA_2026-09-27.csv"))
fwrite(GR, file.path(OUT, "gyr142-p17-grid_DATA_2026-09-27.csv")); fwrite(rbind(s1[, .(test = "S1", set, pop, ref, arm, pass)], e3[, .(test = "E3", set, pop = "all", ref, arm, pass)], e6[, .(test = "E6b", set, pop = "all", ref, arm, pass)], fill = TRUE), file.path(OUT, "gyr142-p17-gatedetail_DATA_2026-09-27.csv"))
writeLines(c(sprintf("m_star=%.1f", mstar), sprintf("m_star_arm=%s", mstar_arm), paste0("verdict=", verdict)), file.path(OUT, "gyr142-p17-verdict_DATA_2026-09-27.txt"))

## ---- figure: stems and C1 volume ratio against IMULT, NS four; 14.1 as a dotted reference
F <- GR[set %in% NS & !is.na(imult)]
L <- rbind(F[, .(set, imult, metric = "Stems", y = stems_ratio, lo = NA_real_, hi = NA_real_)],
           F[, .(set, imult, metric = "Volume, C1", y = ratio_C1, lo = ratio_lo_C1, hi = ratio_hi_C1)])
R <- rbind(GR[set %in% NS & arm == "v141LT", .(set, metric = "Stems", y = stems_ratio)], GR[set %in% NS & arm == "v141LT", .(set, metric = "Volume, C1", y = ratio_C1)])
pl <- ggplot(L, aes(imult, y, colour = metric, shape = metric)) + geom_hline(yintercept = 1, colour = "grey40", linewidth = 0.3) +
  geom_hline(data = R, aes(yintercept = y, colour = metric), linetype = "dotted", linewidth = 0.5) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.08, na.rm = TRUE) + geom_line(linewidth = 0.5) + geom_point(size = 1.8) +
  geom_vline(xintercept = mstar, linetype = "dashed", colour = "grey55", linewidth = 0.3) +
  facet_wrap(~ set, nrow = 1) + scale_colour_manual(values = c(Stems = "#1b6ca8", `Volume, C1` = "#b5452b")) +
  scale_x_continuous(breaks = unname(IM), labels = format(unname(IM), nsmall = 1)) + labs(x = "Ingrowth multiplier (IMULT)", y = "Predicted / observed", colour = NULL, shape = NULL) +
  theme_classic(base_size = 9) + theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_text(face = "bold"))
ggsave(file.path(OUT, "gyr142-p17-grid_2026-09-27.png"), pl, width = 7.5, height = 3.2, dpi = 300, device = "png")
gc(verbose = FALSE); cat("ASSEMBLE_DONE\n")

## PREREG22 assembly: gates, decision rule outcome, component comparison and one figure, every rule as written in
## 2026-09-29_v142_ns-height-by-ingrowth_PREREG22.md (revision 1). Joint arm v141LTfi = PREREG20 height form plus PREREG9
## threshold matching with IMULT m* (PREREG18 selection, ../plan/mstar.env). Every v141LT reference is read from its frozen
## table, never typed in [F9]: C0 and C1 from PREREG16 tables_r1 (md5 a3ed3b76, checked here), structure, stems and TOPHT
## from the PREREG17 Cardinal structure table (md5 732b553f, checked here). Components (reported, not gated): PREREG20
## v141LTf (~/jobs/v142p20/tables) and the PREREG18 m* arm (PREREG17 Cardinal tables for 1.5 and 2.0, PREREG18 firebreather
## tables for 1.75 and 2.25). Refuses to run if assembled/ exists. Hard stops on any missing gated row. Headless,
## theme_classic, png then dev.off, 300 dpi. No coordinates. No em dashes.
suppressMessages({library(data.table); library(ggplot2)}); options(width = 200)
J <- Sys.getenv("P22_J", "/home/aaron/jobs/v142p22"); TB <- file.path(J, "tables"); O <- Sys.getenv("P22_AS_OUT", file.path(J, "assembled"))
if (dir.exists(O)) stop("REFUSE: ", O, " exists; the PREREG22 assembly never overwrites")
dir.create(O, recursive = TRUE)
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
hs <- function(fmt, ...) { m <- sprintf(fmt, ...); cat("HARD STOP:", m, "\n"); cat(m, "\n", file = file.path(O, "error_log.txt"), append = TRUE); quit(save = "no", status = 3) }
rd <- function(f, md5 = NULL) { if (!file.exists(f)) hs("missing input %s", f)
  if (!is.null(md5) && unname(tools::md5sum(f)) != md5) hs("md5 of %s is %s, expected %s", f, unname(tools::md5sum(f)), md5); fread(f) }
NS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl"); ARM <- "v141LTfi"
## ---- m* provenance
ms <- readLines(file.path(J, "plan/mstar.env")); kv <- function(k) gsub("'", "", sub(paste0("^", k, "="), "", grep(paste0("^", k, "="), ms, value = TRUE)))
MSTAR <- as.numeric(kv("P22_IMULT")); MARM <- kv("P18_MSTAR_ARM"); P18RULE <- kv("P18_RULE")
if (length(MSTAR) != 1 || !MSTAR %in% c(1.5, 1.75, 2.0, 2.25)) hs("m* in mstar.env is not a grid value")
## ---- references, read and md5 checked, never typed in
REF <- rd("/home/aaron/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv", "a3ed3b76590441b8ac9985a429060041")[arm == "v141LT" & label %in% NS]
P17ST <- "/home/aaron/jobs/v142p17/in/cardinal/gyr142-p17-cardinal-structure_DATA_2026-09-27.csv"
RST <- rd(P17ST, "732b553f9e9e3f984e014c51141e0dad")[arm == "v141LT" & set %in% NS]
## ---- this arm
SC <- rd(file.path(TB, "gyr142-p22-fb-scores_DATA_2026-09-27.csv"))[arm == ARM & label %in% NS]
ST <- rd(file.path(TB, "gyr142-p22-fb-structure_DATA_2026-09-27.csv"))[arm == ARM & set %in% NS]
K1 <- rd(file.path(TB, "gyr142-p22-fb-K1_DATA_2026-09-27.csv"))[arm == ARM & label %in% NS]
VG <- rd(file.path(TB, "gyr142-p22-fb-gates_DATA_2026-09-27.csv")); if (!all(VG$pass)) hs("a scorer gate (V0 to V3) failed")
G0 <- rd(file.path(TB, "gyr142-p22-G0-control_DATA_2026-09-29.csv"))
H2 <- rd(file.path(TB, "gyr142-p22-h2-gate_DATA_2026-09-29.csv")); HS <- rd(file.path(TB, "gyr142-p22-h2-sizeclass_DATA_2026-09-29.csv"))
if (nrow(K1) != 4) hs("K1 rows %d of 4", nrow(K1)); if (nrow(H2) != 2) hs("H2 gate rows %d of 2", nrow(H2))
one <- function(x, what) { if (nrow(x) != 1) hs("%s: %d rows", what, nrow(x)); x }
sc <- function(d, s, cv = "C1", a = unique(d$arm)) one(d[label == s & pop == "all" & conv == cv], sprintf("score %s %s %s", paste(a, collapse = "+"), s, cv))
st <- function(d, s, p = "all") one(d[set == s & pop == p], sprintf("structure %s %s %s", paste(unique(d$arm), collapse = "+"), s, p))
for (s in NS) { sc(SC, s, "C0"); sc(SC, s); st(ST, s); sc(REF, s, "C0"); sc(REF, s); st(RST, s) }; st(ST, "ns_c", "B"); st(RST, "ns_c", "B")
## ---- gates (the same functions give the reported component rows)
S1SETS <- list(c("ns_c", "B"), c("ns_long_c", "all"), c("ns_fl", "all"), c("ns_long_fl", "all"))
gates_at <- function(SCx, STx, lab) rbind(
  rbindlist(lapply(NS, function(s) data.table(test = "H1", set = s, pop = "all", ref = st(RST, s)$topht_bias_pct, val = st(STx, s)$topht_bias_pct)))[, pass := abs(val) < abs(ref)],
  rbindlist(lapply(S1SETS, function(z) data.table(test = "S1", set = z[1], pop = z[2], ref = st(RST, z[1], z[2])$stems_ratio, val = st(STx, z[1], z[2])$stems_ratio,
    pass = st(STx, z[1], z[2])$abs_log_stems < st(RST, z[1], z[2])$abs_log_stems))),
  rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) data.table(test = "E3", set = s, pop = "all", ref = sc(REF, s)$rmse_pct, val = sc(SCx, s)$rmse_pct)))[, pass := (ref - val) >= -0.5],
  rbindlist(lapply(c("ns_fl", "ns_long_fl"), function(s) data.table(test = "E6b", set = s, pop = "all", ref = sc(REF, s)$bias_pct, val = sc(SCx, s)$bias_pct)))[, pass := abs(val) <= abs(ref)],
  fill = TRUE)[, arm := lab]
D <- gates_at(SC, ST, ARM)
g0 <- one(G0[grepl("^G0", gate)], "G0 row"); ctl <- one(G0[grepl("control", gate)], "control row")
dd <- function(t, f) D[test == t, paste(sprintf(f, set, pop, ref, val), collapse = "; ")]
GT <- data.table(gate = c("G0 harness", "CTL Maine", "K1 failures", "H1 TOPHT bias", "H2 large tree height increment, fold B", "S1 stems (held out)", "E3 (C1)", "E6b (C1)"),
  detail = c(sprintf("both parts off, ns_c chunk 1 against frozen v141LT: worst scaled %.3g over %d stands (%s)", g0$worst_scaled, g0$stands, g0$worst_col),
             sprintf("height part on, memat_c chunk 2 against frozen v141LT: worst scaled %.3g over %d stands", ctl$worst_scaled, ctl$stands),
             sprintf("%d RUN_OK other than 1 in %d NS stands, after retry", sum(K1$run_not_ok), sum(K1$stands)),
             dd("H1", "%s %s %+.2f to %+.2f"),
             paste(sprintf("%s: 14.1 %.3f, PREREG11 %.3f, PREREG20 %.3f, joint %.3f (%.3f to %.3f)", H2$set, H2$r141, H2$rh, H2$rf, H2$rfi, H2$rfi_lo, H2$rfi_hi), collapse = "; "),
             dd("S1", "%s %s %.3f to %.3f"),
             D[test == "E3", paste(sprintf("%s %%RMSE %.2f to %.2f, d_rmse %+.2f", set, ref, val, ref - val), collapse = "; ")],
             dd("E6b", "%s %s bias %+.2f to %+.2f")),
  pass = c(g0$pass, ctl$pass, sum(K1$run_not_ok) == 0, all(D[test == "H1", pass]), all(H2$pass), all(D[test == "S1", pass]), all(D[test == "E3", pass]), all(D[test == "E6b", pass])))
p <- setNames(GT$pass, c("G0", "CTL", "K1", "H1", "H2", "S1", "E3", "E6b"))
## ---- decision rule, PREREG22, evaluated in order; exactly one outcome
e6s <- D[test == "E6b" & !pass, paste(sprintf("%s %+.2f (%s)", set, val, fifelse(val > 0, "overshoot, bounds IMULT from above", "deficit, bounds IMULT from below")), collapse = "; ")]
rule <- if (!p[["G0"]] || !p[["CTL"]] || !p[["K1"]]) "Rule 1: harness failure (G0, CTL or K1); no verdict on the pair" else
  if (all(p)) sprintf("Rule 2: every gate passes; the PREREG20 height form with threshold matching at IMULT %s on NS is the 14.2 candidate NS configuration, pending a Bakuzis NS grid; PREREG18 closed with %s", format(MSTAR), P18RULE) else
  if (!p[["H2"]]) "Rule 3: H2 fails; the pairing undoes the large tree height fix; not adopted" else
  if (!p[["H1"]]) "Rule 4: H1 fails with H2 passing; not adopted" else
  if (!p[["S1"]]) "Rule 5: S1 fails; stems under the pair are not better than 14.1 on a named held out set; not adopted" else
  if (!p[["E3"]]) "Rule 6: E3 fails; the pair costs consecutive accuracy; not adopted" else
  sprintf("Rule 7: only E6b fails; not adopted; failing set and sign: %s", e6s)
fwrite(GT, f_out("gyr142-p22-gates_DATA_2026-09-29.csv")); fwrite(D, f_out("gyr142-p22-gatedetail_DATA_2026-09-29.csv"))
writeLines(c(sprintf("m_star=%s", format(MSTAR)), sprintf("m_star_arm=%s", MARM), sprintf("p18_rule=%s", P18RULE), paste0("verdict=", rule),
             paste0("failing=", paste(names(p)[!p], collapse = ","))), f_out("gyr142-p22-verdict_DATA_2026-09-29.txt"))
## ---- components, reported, not gated
soft <- function(f, a) { if (!file.exists(f)) { cat("NOTE: component file missing", f, "\n"); return(NULL) }; x <- fread(f)[arm == a]; if (!nrow(x)) { cat("NOTE: no rows for", a, "in", f, "\n"); return(NULL) }; x }
if (MARM %in% c("v141LTig_m15", "v141LTig_m20")) { fsc <- "/home/aaron/jobs/v142p17/in/cardinal/gyr142-p17-scores_DATA_2026-09-27.csv"; fst <- P17ST } else {
  fsc <- "/home/aaron/jobs/v142p18/tables/gyr142-p18-fb-scores_DATA_2026-09-28.csv"; fst <- "/home/aaron/jobs/v142p18/tables/gyr142-p18-fb-structure_DATA_2026-09-28.csv" }
COMP <- list(v141LTf = list(sc = soft("/home/aaron/jobs/v142p20/tables/gyr142-p20-fb-scores_DATA_2026-09-27.csv", "v141LTf"),
                            st = soft("/home/aaron/jobs/v142p20/tables/gyr142-p20-fb-structure_DATA_2026-09-27.csv", "v141LTf")))
COMP[[MARM]] <- list(sc = soft(fsc, MARM), st = soft(fst, MARM))
cat(sprintf("component files: %s | %s\n", fsc, fst))
LAB <- c(v141LT = "14.1 (v141LT)", v141LTf = "PREREG20 height only (v141LTf)", v141LTfi = sprintf("Joint, height + IMULT %s (v141LTfi)", format(MSTAR)))
LAB[MARM] <- sprintf("PREREG18 ingrowth only, IMULT %s (%s)", format(MSTAR), MARM)
row_at <- function(SCx, STx, a) rbindlist(lapply(c(NS, "ns_c fold B"), function(s) { ss <- if (s == "ns_c fold B") "ns_c" else s; pp <- if (s == "ns_c fold B") "B" else "all"
  x <- STx[set == ss & pop == pp]; y1 <- if (pp == "all") SCx[label == ss & pop == "all" & conv == "C1"] else SCx[0]; y0 <- if (pp == "all") SCx[label == ss & pop == "all" & conv == "C0"] else SCx[0]
  g <- function(d, v) if (nrow(d) == 1) d[[v]] else NA_real_
  data.table(set = s, arm = a, stems_ratio = g(x, "stems_ratio"), ba_ratio = g(x, "ba_ratio"), qmd_ratio = g(x, "qmd_ratio"), topht_bias_pct = g(x, "topht_bias_pct"),
             c0_bias_pct = g(y0, "bias_pct"), c1_bias_pct = g(y1, "bias_pct"), c1_lo_pct = 100 * (g(y1, "ratio_lo") - 1), c1_hi_pct = 100 * (g(y1, "ratio_hi") - 1), c1_rmse_pct = g(y1, "rmse_pct")) }))
CT <- rbind(row_at(REF, RST, "v141LT"), rbindlist(lapply(names(COMP), function(a) if (!is.null(COMP[[a]]$sc) && !is.null(COMP[[a]]$st)) row_at(COMP[[a]]$sc, COMP[[a]]$st, a))), row_at(SC, ST, ARM))
CT[, label := LAB[arm]]
## additivity (reported): joint change against the sum of the two single component changes, from 14.1
add <- function(v) { w <- dcast(CT, set ~ arm, value.var = v); if (!all(c("v141LT", "v141LTf", MARM, ARM) %in% names(w))) return(NULL)
  w[, .(set, metric = v, d_height = v141LTf - v141LT, d_ingrowth = get(MARM) - v141LT, d_joint = get(ARM) - v141LT, interaction = get(ARM) - v141LTf - get(MARM) + v141LT)] }
AD <- rbindlist(lapply(c("stems_ratio", "ba_ratio", "qmd_ratio", "topht_bias_pct", "c1_bias_pct", "c1_rmse_pct"), add))
CG <- rbindlist(lapply(names(COMP), function(a) if (!is.null(COMP[[a]]$sc) && !is.null(COMP[[a]]$st)) tryCatch(gates_at(COMP[[a]]$sc, COMP[[a]]$st, a), error = function(e) NULL)))
fwrite(CT, f_out("gyr142-p22-components_DATA_2026-09-29.csv")); fwrite(AD, f_out("gyr142-p22-additivity_DATA_2026-09-29.csv"))
fwrite(CG[, label := "reported, not gated"], f_out("gyr142-p22-componentgates_DATA_2026-09-29.csv")); fwrite(HS, f_out("gyr142-p22-h2-sizeclass_DATA_2026-09-29.csv"))
## ---- figure: C1 volume bias (95 percent site cluster interval) and stems ratio by set, 14.1, each component and the pair
L <- rbind(CT[set %in% NS, .(set, label, metric = "C1 total volume bias (percent)", y = c1_bias_pct, lo = c1_lo_pct, hi = c1_hi_pct)],
           CT[, .(set, label, metric = "Stems, predicted over observed", y = stems_ratio, lo = NA_real_, hi = NA_real_)])[is.finite(y)]
L[, set := factor(set, c(NS, "ns_c fold B"))]; L[, label := factor(label, unique(LAB[c("v141LT", "v141LTf", MARM, ARM)]))]
HL <- data.table(metric = c("C1 total volume bias (percent)", "Stems, predicted over observed"), y = c(0, 1))
pl <- ggplot(L, aes(set, y, shape = label)) + geom_hline(data = HL, aes(yintercept = y), linetype = "dotted") +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(0.6), size = 0.3, na.rm = TRUE) +
  geom_point(data = L[is.na(lo)], position = position_dodge(0.6), size = 1.6) + facet_wrap(~ metric, scales = "free_y", nrow = 1) +
  scale_shape_manual(values = c(1, 2, 0, 16)) + labs(x = NULL, y = NULL, shape = NULL) +
  theme_classic(base_size = 9) + theme(legend.position = "bottom", legend.direction = "vertical", strip.background = element_blank(), strip.text = element_text(face = "bold"), axis.text.x = element_text(angle = 30, hjust = 1))
png(f_out("gyr142-p22-components_2026-09-29.png"), width = 7.5, height = 4.8, units = "in", res = 300); print(pl); invisible(dev.off())
print(GT); cat("VERDICT:", rule, "\n"); print(CT, digits = 4); print(AD, digits = 3); cat("ASSEMBLE_DONE\n")

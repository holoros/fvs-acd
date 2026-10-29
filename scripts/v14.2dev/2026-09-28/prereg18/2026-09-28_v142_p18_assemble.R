## PREREG18 assembly: selection, gates, verdict, grid tables and the figure, every rule as written in
## 2026-09-28_v142_ns-imult-refine_PREREG18.md (revision 1, md5 c78b477c). Reads the Cardinal PREREG17 tables (IMULT 1.0,
## 1.5, 2.0, 2.5 and the v141LT structure rows), the firebreather PREREG18 tables (1.75, 2.25), the firebreather PREREG17
## tables (3.0, context only), the fold volume table (2026-09-28_v142_p18_foldvol.R) and the v141LT C1 references from
## PREREG16 tables_r1 (Cardinal job 14937306, scores md5 a3ed3b76), read here and never typed in [F9]. Hard stops on any
## missing row; no silent drops. Headless ggplot2, theme_classic, 300 dpi, 7.5 x 4.8 in. No coordinates. No em dashes.
suppressMessages({library(data.table); library(ggplot2)})
J   <- Sys.getenv("P18_J", "/home/aaron/jobs/v142p18")
OUT <- Sys.getenv("P18_AS_OUT", file.path(J, "assembled")); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
DST <- Sys.getenv("P18_AS_DATE", "2026-09-28"); TAG <- Sys.getenv("P18_AS_TAG", "p18")
FBT <- Sys.getenv("P18_FB_TABLES", file.path(J, "tables"))      # firebreather PREREG18 scores, structure, K1, gates
FBP <- Sys.getenv("P18_FB_PREFIX", "gyr142-p18-fb"); FBD <- Sys.getenv("P18_FB_DATE", "2026-09-28")
FVF <- Sys.getenv("P18_FOLDVOL", file.path(J, "tables/gyr142-p18-foldvol_DATA_2026-09-28.csv"))
gs  <- strsplit(strsplit(Sys.getenv("P18_GRID", "v141LTig_m15=1.5,v141LTig_m175=1.75,v141LTig_m20=2.0,v141LTig_m225=2.25"), ",")[[1]], "=")
G   <- setNames(as.numeric(sapply(gs, `[`, 2)), sapply(gs, `[`, 1))
CTX <- c(v141LTig_m10 = 1.0, v141LTig = 2.5, v141LTig_m30 = 3.0)     # PREREG17 points, context only
CTX <- CTX[!names(CTX) %in% names(G)]; IM <- sort(c(G, CTX))
TIE <- 0.0005; NS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl")
ERR <- file.path(OUT, "error_log.txt")
hs <- function(fmt, ...) { m <- sprintf(fmt, ...); cat("HARD STOP:", m, "\n"); cat(m, "\n", file = ERR, append = TRUE); quit(save = "no", status = 3) }
rd <- function(f) { if (!file.exists(f)) hs("missing input %s", f); fread(f) }
fbt <- function(x) file.path(FBT, sprintf("%s-%s_DATA_%s.csv", FBP, x, FBD))
P17 <- "/home/aaron/jobs/v142p17/tables"

SC <- rbind(rd(file.path(J, "in/cardinal/gyr142-p17-scores_DATA_2026-09-27.csv")), rd(fbt("scores")),
            rd(file.path(P17, "gyr142-p17-fb-scores_DATA_2026-09-27.csv")),
            rd("/home/aaron/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv")[arm == "v141LT"], fill = TRUE)
SC <- unique(SC[label %in% NS])
ST <- unique(rbind(rd(file.path(J, "in/cardinal/gyr142-p17-cardinal-structure_DATA_2026-09-27.csv")), rd(fbt("structure")),
            rd(file.path(P17, "gyr142-p17-fb-structure_DATA_2026-09-27.csv")))[set %in% NS])
K1 <- rbind(rd(file.path(J, "in/cardinal/gyr142-p17-cardinal-K1_DATA_2026-09-27.csv")), rd(fbt("K1")))
VG <- rbind(rd(file.path(J, "in/cardinal/gyr142-p17-gates_DATA_2026-09-27.csv")), rd(fbt("gates")), fill = TRUE)
FV <- rd(FVF)
if (!all(VG$pass)) hs("a scorer gate (V0 to V3) failed; the scorer should have hard stopped")

## ---- completeness: every row the rules need, or stop
arms_need <- c(names(G), "v141LT")
for (a in arms_need) {
  for (s in NS) { if (nrow(ST[set == s & arm == a & pop == "all"]) != 1) hs("structure row %s %s all: %d", s, a, nrow(ST[set == s & arm == a & pop == "all"]))
    for (cv in c("C0", "C1")) if (nrow(SC[label == s & arm == a & pop == "all" & conv == cv]) != 1) hs("score row %s %s %s: %d", s, a, cv, nrow(SC[label == s & arm == a & pop == "all" & conv == cv])) }
  for (p in c("A", "B")) { if (nrow(ST[set == "ns_c" & arm == a & pop == p]) != 1) hs("structure row ns_c %s %s", a, p)
    if (nrow(FV[arm == a & pop == p & conv == "C1"]) != 1) hs("fold volume row %s %s", a, p) } }
for (a in names(G)) if (nrow(K1[label %in% NS & arm == a]) != 4) hs("K1 rows for %s: %d of 4", a, nrow(K1[label %in% NS & arm == a]))
c1  <- function(s, a) SC[label == s & arm == a & conv == "C1" & pop == "all"]
fv  <- function(a, p) FV[arm == a & pop == p & conv == "C1"]
stc <- function(s, p, a) ST[set == s & pop == p & arm == a]

## ---- selection: ns_c fold A, absolute log pooled C1 volume ratio, tie rule 0.0005 to the smaller IMULT
SEL <- data.table(arm = names(G), imult = unname(G))
SEL[, `:=`(stands_A = sapply(arm, function(a) fv(a, "A")$stands), vol_ratio_A = sapply(arm, function(a) fv(a, "A")$ratio))]
SEL[, loss := abs(log(vol_ratio_A))]
SEL[, `:=`(loss_foldB = sapply(arm, function(a) abs(log(fv(a, "B")$ratio))), loss_ns_long_c = sapply(arm, function(a) abs(log(c1("ns_long_c", a)$ratio))),
           ba_loss_A = sapply(arm, function(a) abs(log(stc("ns_c", "A", a)$ba_ratio))), stems_loss_A = sapply(arm, function(a) stc("ns_c", "A", a)$abs_log_stems))]
SEL[, maxloss_A := pmax(loss, stems_loss_A)]
o <- SEL[order(loss, imult)]; tie <- (o$loss[2] - o$loss[1]) < TIE
mstar_arm <- if (tie) o[1:2][which.min(imult), arm] else o$arm[1]; mstar <- G[[mstar_arm]]
edge_pass <- !(mstar %in% range(G)); SEL[, chosen := arm == mstar_arm]
alt <- sapply(c("ba_loss_A", "stems_loss_A", "maxloss_A"), function(k) SEL[which.min(get(k)), imult])
print(SEL, digits = 4); cat(sprintf("m* = %s (%s); tie %s; edge %s; reported alternatives BA %s, stems %s, max %s\n", format(mstar), mstar_arm, tie,
  if (edge_pass) "interior" else "AT EDGE", alt[1], alt[2], alt[3]))

## ---- gates at a given arm (used for m*; the same function gives the reported all grid table)
gates_at <- function(a) {
  k <- K1[label %in% NS & arm == a]
  s1 <- rbindlist(lapply(list(c("ns_c", "B"), c("ns_long_c", "all"), c("ns_fl", "all"), c("ns_long_fl", "all")), function(z)
    data.table(test = "S1", set = z[1], pop = z[2], ref = stc(z[1], z[2], "v141LT")$stems_ratio, arm = stc(z[1], z[2], a)$stems_ratio,
               pass = stc(z[1], z[2], a)$abs_log_stems < stc(z[1], z[2], "v141LT")$abs_log_stems)))
  e3 <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) data.table(test = "E3", set = s, pop = "all", ref = c1(s, "v141LT")$rmse_pct, arm = c1(s, a)$rmse_pct)))[, pass := (ref - arm) >= -0.5]
  e6 <- rbindlist(lapply(c("ns_fl", "ns_long_fl"), function(s) data.table(test = "E6b", set = s, pop = "all", ref = c1(s, "v141LT")$bias_pct, arm = c1(s, a)$bias_pct)))[, pass := abs(arm) <= abs(ref)]
  b <- fv(a, "B"); rB <- fv("v141LT", "B")
  vb <- rbind(data.table(test = "VB(a)", set = "ns_c", pop = "B", ref = rB$ratio, arm = b$ratio, lo = b$ratio_lo, hi = b$ratio_hi, pass = b$ratio_lo <= 1 & b$ratio_hi >= 1),
              data.table(test = "VB(b)", set = "ns_c", pop = "B", ref = rB$rmse_pct, arm = b$rmse_pct, pass = (rB$rmse_pct - b$rmse_pct) >= -0.5), fill = TRUE)
  list(k1 = data.table(n = sum(k$stands), bad = sum(k$run_not_ok)), detail = rbind(s1, e3, e6, vb, fill = TRUE)) }
g <- gates_at(mstar_arm); D <- g$detail
pp <- c(K1 = g$k1$bad == 0, S1 = all(D[test == "S1", pass]), E3 = all(D[test == "E3", pass]), E6b = all(D[test == "E6b", pass]), Edge = edge_pass, VB = all(D[test %like% "^VB", pass]))
fm <- function(x, f = "%.3f") sprintf(f, x)
GT <- data.table(gate = c("K1 failures", "S1 stems (held out)", "E3 (C1)", "E6b (C1)", "Edge", "VB volume (held out, ns_c fold B)"),
  detail = c(sprintf("%d RUN_OK other than 1 in %d NS stands at m*", g$k1$bad, g$k1$n),
             D[test == "S1", paste(sprintf("%s %s %.3f to %.3f", set, pop, ref, arm), collapse = "; ")],
             D[test == "E3", paste(sprintf("%s %%RMSE %.2f to %.2f, d_rmse %+.2f", set, ref, arm, ref - arm), collapse = "; ")],
             D[test == "E6b", paste(sprintf("%s bias %+.2f to %+.2f", set, ref, arm), collapse = "; ")],
             sprintf("m* = %s on grid %s", format(mstar), paste(format(G), collapse = ", ")),
             sprintf("ratio %.4f (%.4f to %.4f) against 14.1 %.4f; fold B %%RMSE %.2f against %.2f, d_rmse %+.2f",
               D[test == "VB(a)", arm], D[test == "VB(a)", lo], D[test == "VB(a)", hi], D[test == "VB(a)", ref],
               D[test == "VB(b)", arm], D[test == "VB(b)", ref], D[test == "VB(b)", ref - arm])),
  pass = unname(pp[c("K1", "S1", "E3", "E6b", "Edge", "VB")]))
print(GT)

## ---- verdict, PREREG18 decision rule (evaluated in order; exactly one outcome)
rest <- c(S1 = pp[["S1"]], E3 = pp[["E3"]], E6b = pp[["E6b"]], VB = pp[["VB"]]); nf <- sum(!rest)
verdict <- if (!pp[["K1"]]) "Rule 1: K1 fails at m*; no verdict" else
  if (!edge_pass && mstar == min(G)) sprintf("Rule 2a: m* = %s, the lower edge; not adopted. The held out consecutive volume criterion asks for no more ingrowth than %s; a flat NS multiplier cannot be placed inside the window from consecutive held out data", format(mstar), format(mstar)) else
  if (!edge_pass) sprintf("Rule 2b: m* = %s, the upper edge; not adopted; scoring audited before any reading", format(mstar)) else
  if (nf == 0) sprintf("Rule 3: all gates pass; threshold matching with IMULT %s on NS is the 14.2 candidate NS regional setting, pending a Bakuzis NS grid", format(mstar)) else
  if (nf == 1 && !rest[["VB"]]) "Rule 4: only VB fails; not adopted" else
  if (nf == 1 && !rest[["S1"]]) "Rule 5: only S1 fails; not adopted" else
  if (nf == 1 && !rest[["E6b"]]) "Rule 6: only E6b fails; not adopted" else
  if (nf == 1 && !rest[["E3"]]) "Rule 7: only E3 fails; not adopted" else
  sprintf("Rule 8: %s fail; not adopted", paste(names(rest)[!rest], collapse = ", "))
cat("VERDICT:", verdict, "\n")

## ---- reported, not the pre-registered selection: the same gates at every grid point
GG <- rbindlist(lapply(names(G), function(a) { x <- gates_at(a); d <- x$detail
  data.table(arm = a, imult = G[[a]], K1 = x$k1$bad == 0, S1 = all(d[test == "S1", pass]),
    d_rmse_ns_c = d[test == "E3" & set == "ns_c", ref - arm], d_rmse_ns_long_c = d[test == "E3" & set == "ns_long_c", ref - arm], E3 = all(d[test == "E3", pass]),
    bias_ns_fl = d[test == "E6b" & set == "ns_fl", arm], bias_ns_long_fl = d[test == "E6b" & set == "ns_long_fl", arm], E6b = all(d[test == "E6b", pass]),
    foldB_ratio = d[test == "VB(a)", arm], foldB_lo = d[test == "VB(a)", lo], foldB_hi = d[test == "VB(a)", hi], foldB_d_rmse = d[test == "VB(b)", ref - arm],
    VB = all(d[test %like% "^VB", pass]), label = "reported, not the pre-registered selection") }))
GG[, all_but_edge := K1 & S1 & E3 & E6b & VB]; print(GG, digits = 3)

## ---- grid table, NS four plus ns_c folds, every IMULT available and 14.1
arms_all <- c(names(IM), "v141LT"); imv <- function(a) ifelse(a == "v141LT", NA_real_, IM[a])
GR <- ST[pop == "all" & arm %in% arms_all, .(set, pop, arm, stands, stems_ratio, ba_ratio, qmd_ratio, topht_bias_pct)]
w <- dcast(SC[pop == "all" & conv %in% c("C0", "C1") & arm %in% arms_all], label + arm ~ conv, value.var = c("ratio", "ratio_lo", "ratio_hi", "bias_pct", "rmse_pct"))
GR <- merge(GR, w, by.x = c("set", "arm"), by.y = c("label", "arm"), all.x = TRUE)
FF <- ST[set == "ns_c" & pop %in% c("A", "B") & arm %in% arms_all, .(set, pop, arm, stands, stems_ratio, ba_ratio, qmd_ratio, topht_bias_pct)]
fw <- dcast(FV[pop %in% c("A", "B") & arm %in% arms_all], arm + pop ~ conv, value.var = c("ratio", "ratio_lo", "ratio_hi", "bias_pct", "rmse_pct"))
FF <- merge(FF, fw, by = c("arm", "pop"), all.x = TRUE)
GR <- rbind(GR, FF, fill = TRUE)[, imult := imv(arm)][, in_grid := arm %in% names(G)][order(set, pop, imult)]
if (GR[arm %in% arms_need & (is.na(ratio_C1) | is.na(stems_ratio)), .N] > 0) hs("grid table has missing values for required arms")

fwrite(SEL, file.path(OUT, sprintf("gyr142-%s-selection_DATA_%s.csv", TAG, DST))); fwrite(GT, file.path(OUT, sprintf("gyr142-%s-gates_DATA_%s.csv", TAG, DST)))
fwrite(D, file.path(OUT, sprintf("gyr142-%s-gatedetail_DATA_%s.csv", TAG, DST))); fwrite(GG, file.path(OUT, sprintf("gyr142-%s-gridgates_DATA_%s.csv", TAG, DST)))
fwrite(GR, file.path(OUT, sprintf("gyr142-%s-grid_DATA_%s.csv", TAG, DST)))
writeLines(c(sprintf("m_star=%s", format(mstar)), sprintf("m_star_arm=%s", mstar_arm), sprintf("tie=%s", tie),
             sprintf("alt_ba=%s alt_stems=%s alt_max=%s", alt[1], alt[2], alt[3]), paste0("verdict=", verdict)),
           file.path(OUT, sprintf("gyr142-%s-verdict_DATA_%s.txt", TAG, DST)))

## ---- figure: stems and C1 volume ratio against IMULT; ns_c fold A (fit), ns_c fold B and the NS four; grid window shaded
pan <- c("ns_c fold A (fit)", "ns_c fold B", "ns_c", "ns_fl", "ns_long_c", "ns_long_fl")
GR[, panel := fifelse(pop == "A", pan[1], fifelse(pop == "B", pan[2], set))]
F <- GR[!is.na(imult)]
L <- rbind(F[, .(panel, imult, in_grid, metric = "Stems", y = stems_ratio, lo = NA_real_, hi = NA_real_)],
           F[, .(panel, imult, in_grid, metric = "Volume, C1", y = ratio_C1, lo = ratio_lo_C1, hi = ratio_hi_C1)])
R <- rbind(GR[arm == "v141LT", .(panel, metric = "Stems", y = stems_ratio)], GR[arm == "v141LT", .(panel, metric = "Volume, C1", y = ratio_C1)])
L[, panel := factor(panel, pan)]; R[, panel := factor(panel, pan)]
pl <- ggplot(L, aes(imult, y, colour = metric)) +
  annotate("rect", xmin = min(G), xmax = max(G), ymin = -Inf, ymax = Inf, fill = "grey92") +
  geom_hline(yintercept = 1, colour = "grey40", linewidth = 0.3) +
  geom_hline(data = R, aes(yintercept = y, colour = metric), linetype = "dotted", linewidth = 0.5) +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.07, na.rm = TRUE) + geom_line(linewidth = 0.45) +
  geom_point(aes(shape = in_grid), size = 1.7) + scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 1), labels = c(`TRUE` = "PREREG18 grid", `FALSE` = "PREREG17 context")) +
  geom_vline(xintercept = mstar, linetype = "dashed", colour = "grey45", linewidth = 0.3) +
  facet_wrap(~ panel, nrow = 2) + scale_colour_manual(values = c(Stems = "#1b6ca8", `Volume, C1` = "#b5452b")) +
  scale_x_continuous(breaks = unname(IM), labels = format(unname(IM))) +
  labs(x = "Ingrowth multiplier (IMULT)", y = "Predicted / observed", colour = NULL, shape = NULL) +
  theme_classic(base_size = 9) + theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_text(face = "bold"),
                                       axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(OUT, sprintf("gyr142-%s-grid_%s.png", TAG, DST)), pl, width = 7.5, height = 4.8, dpi = 300, device = "png")
cat("ASSEMBLE_DONE\n")

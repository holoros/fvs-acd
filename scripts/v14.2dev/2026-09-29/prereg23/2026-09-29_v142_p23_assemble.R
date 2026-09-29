## PREREG23 assembly: H0 harness reproduction, K1, H_inc (fold B pooled and by diameter class), TOPHT with the symmetric
## dominant cohort level check, V2, B1 and B2 on screened qc_c fold B, the decision rule in the pre-registered order, tables
## and figure into ~/jobs/v142p23/assembled/ (refuses if it exists). Candidate arm p23_a1061 (QC_AFAC 1.061), reference
## frozen p19_a0111 (QC_AFAC 0.111). Point estimates use the PREREG19 assembly formulas. Height increment uses the PREREG23
## key (2026-09-29_v142_p23_hkey.R). Site cluster bootstrap B = 1000, seed 20260929. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p23/scripts/2026-09-29_v142_p23_hkey.R")
suppressMessages(library(ggplot2)); set.seed(20260929); B <- 1000L
J <- "/home/aaron/jobs/v142p23"; O <- file.path(J, "assembled"); if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O)
w_out <- function(x, n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); fwrite(x, f) }
CAND <- "p23_a1061"; REF <- "p19_a0111"; M_CLS <- 0.03; M_DOM <- 0.02
## arm registry: frozen grid (PREREG19 bundle) and new arms (this bundle)
AR <- data.table(arm = c(sprintf("p19_a%04d", c(30, 60, 111, 250, 500, 1000)), "p23_a0111", "p23_a1061", "p23_a1250"),
                 qc_afac = c(0.030, 0.060, 0.111, 0.250, 0.500, 1.000, 0.111, 1.061, 1.250))
AR[, `:=`(root = fifelse(startsWith(arm, "p19"), P19, J))]
AR[, `:=`(home = file.path(root, "home"), stands = fifelse(startsWith(arm, "p19"), file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"),
                                                        file.path(J, "tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv")))]
res <- function(a, s) { x <- AR[arm == a]; fread(file.path(x$root, "results", a, sprintf("gyr_%s_%s_results.csv", a, s)))[, STAND := as.character(STAND)] }
CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
## ---- H0: p23_a0111 reproduces frozen p19_a0111, results (every _p column, ING_p, RUN_OK) and per tree t2 lists
H0 <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { a <- res("p23_a0111", s); b <- res("p19_a0111", s)
  if (!setequal(a$STAND, b$STAND)) stop("H0 stand sets differ ", s); setkey(a, STAND); setkey(b, STAND)
  cols <- c(grep("_p$", names(b), value = TRUE), "ING_p", "RUN_OK")
  wr <- max(sapply(cols, function(k) { d <- abs(a[[k]] - b[[k]]) / pmax(1, abs(b[[k]])); d[is.na(a[[k]]) & is.na(b[[k]])] <- 0; max(d) }))
  rd <- function(h, arm) { acc <- NULL; for (d in arm_dirs(h, arm, s)) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
  ta <- rd(file.path(J, "home"), "p23_a0111"); tb <- rd(file.path(P19, "home"), "p19_a0111")
  m <- merge(ta, tb, by = c("STAND", "tree")); if (nrow(m) != nrow(ta) || nrow(m) != nrow(tb)) stop("H0 per tree rows differ ", s)
  wt <- max(abs(m$ht.x - m$ht.y) / pmax(1, abs(m$ht.y)), abs(m$dbh.x - m$dbh.y) / pmax(1, abs(m$dbh.y)), abs(m$expf.x - m$expf.y) / pmax(1, abs(m$expf.y)), abs(m$ing.x - m$ing.y))
  data.table(set = s, stands = nrow(b), trees = nrow(m), worst_results = wr, worst_trees = wt, pass = is.finite(wr) && is.finite(wt) && wr <= 1e-9 && wt <= 1e-9) }))
print(H0)
## ---- K1: RUN_OK other than 1 after retries, candidate arm (and the others reported)
K1 <- rbindlist(lapply(c("p23_a0111", "p23_a1061", "p23_a1250"), function(a) rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(a, s)
  data.table(arm = a, set = s, stands = nrow(r), not_ok = sum(r$RUN_OK != 1), timelimit_left = sum(grepl("elapsed time limit", r$FAIL_REASON))) }))))
k1_pass <- K1[arm == CAND, sum(not_ok)] == 0
## ---- stand level summaries by fold (PREREG19 assembly formulas)
pt <- function(o, p) c(ratio = sum(p) / sum(o), bias_pct = 100 * (mean(p) - mean(o)) / mean(o), rmse_pct = 100 * sqrt(mean((p - o)^2)) / mean(o))
tph <- function(ba, qmd) ba / (pi / 40000 * qmd^2)
STS <- rbindlist(lapply(AR$arm, function(a) { x <- AR[arm == a]; STN <- fread(x$stands)[, STAND := as.character(STAND)]
  rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { r <- res(a, s)[RUN_OK == 1]; r[, fold := fold_of(SITE)]
    v <- merge(STN[label == s & arm == a], r[, .(STAND, SITE, fold, BA_o, BA_p, QMD_o, QMD_p, TOPHT_o, TOPHT_p)], by = "STAND")
    pops <- list(`screened A` = v[cut == FALSE & fold == "A"], `screened B` = v[cut == FALSE & fold == "B"], screened = v[cut == FALSE], all = v)
    rbindlist(lapply(names(pops), function(pn) { z <- pops[[pn]]; c1 <- pt(z$V_oh, z$V_ph); z2 <- z[is.finite(tph(BA_o, QMD_o)) & is.finite(tph(BA_p, QMD_p))]
      data.table(set = s, arm = a, qc_afac = x$qc_afac, pop = pn, stands = nrow(z), sites = uniqueN(z$SITE), C0_ratio = sum(z$V_p) / sum(z$V_o),
        C1_ratio = c1[[1]], C1_bias_pct = c1[[2]], C1_rmse_pct = c1[[3]], ba_ratio = sum(z2$BA_p) / sum(z2$BA_o),
        stems_ratio = sum(tph(z2$BA_p, z2$QMD_p)) / sum(tph(z2$BA_o, z2$QMD_o)), qmd_ratio = mean(z2$QMD_p) / mean(z2$QMD_o),
        topht_bias_pct = 100 * (mean(z$TOPHT_p, na.rm = TRUE) - mean(z$TOPHT_o, na.rm = TRUE)) / mean(z$TOPHT_o, na.rm = TRUE)) })) })) }))
## reproduction of the PREREG19 assembled grid for the frozen arms (hard stop)
G19 <- fread(file.path(P19, "assembled/gyr142-p19-grid_DATA_2026-09-28.csv"))
chk <- merge(STS[startsWith(arm, "p19")], G19, by = c("set", "arm", "pop"), suffixes = c("", ".g"))
rep19 <- chk[, max(abs(C1_ratio - C1_ratio.g), abs(C1_rmse_pct - C1_rmse_pct.g), abs(ba_ratio - ba_ratio.g), abs(stems_ratio - stems_ratio.g), abs(topht_bias_pct - topht_bias_pct.g))]
cat(sprintf("PREREG19 grid reproduction: worst %.3g over %d rows\n", rep19, nrow(chk))); if (nrow(chk) < 48 || rep19 > 1e-9) stop("P19 GRID REPRO FAIL")
## ---- height increment key, all qc_c and qc_fl RUN_OK stands, both folds
HK <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) { S0 <- stand_frame(file.path(P19, sprintf("results/p19_a0111/gyr_p19_a0111_%s_results.csv", s)), s, CUTF)
  TK <- tag_key(s, S0$STAND); K <- merge(TK$K, S0[, .(STAND, SITE, cut, fold)], by = "STAND")
  for (a in AR$arm) { p <- pred_ht(arm_dirs(AR[arm == a]$home, a, s), TK$M, S0$STAND)
    if (a == AR$arm[1]) K <- merge(K, p[, .(STAND, row0, iv)], by = c("STAND", "row0"), all.x = TRUE)
    K <- merge(K, p[, .(STAND, row0, Hp)], by = c("STAND", "row0"), all.x = TRUE); setnames(K, "Hp", paste0("Hp_", a)) }
  if (K[, anyNA(.SD), .SDcols = paste0("Hp_", AR$arm)]) stop("tag record without prediction ", s)
  K[, set := s] }))
HK[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
HK[, dho := (H2 - H1) / iv]; for (a in AR$arm) HK[, paste0("dp_", a) := (get(paste0("Hp_", a)) - H1) / iv]
## per population x group: ratio, bias (m/yr), t2 level; bootstrap by site with the same draws across arms
HT <- list()
for (s in c("qc_c", "qc_fl")) for (fd in c("A", "B")) { X <- HK[set == s & fold == fd & cut == FALSE]
  sites <- unique(X$SITE); ns <- length(sites); IDX <- matrix(sample.int(ns, ns * B, TRUE), ns, B)
  grp <- list(overall = X, `below 12.7` = X[cls == "below 12.7"], `12.7 to 25` = X[cls == "12.7 to 25"], `25 and over` = X[cls == "25 and over"], dominant = X[dom == TRUE])
  for (g in names(grp)) { Y <- grp[[g]]; if (!nrow(Y)) next
    SS <- Y[, c(list(n = .N, o = sum(dho), h2 = sum(H2)), lapply(setNames(AR$arm, paste0("d_", AR$arm)), function(a) sum(get(paste0("dp_", a)))),
                lapply(setNames(AR$arm, paste0("L_", AR$arm)), function(a) sum(get(paste0("Hp_", a))))), by = SITE]
    w <- matrix(0, nrow(SS), B); m <- match(SS$SITE, sites); for (b in 1:B) w[, b] <- tabulate(IDX[, b], ns)[m]
    for (a in AR$arm) { d <- SS[[paste0("d_", a)]]; L <- SS[[paste0("L_", a)]]
      rb <- colSums(w * d) / colSums(w * SS$o); bb <- (colSums(w * d) - colSums(w * SS$o)) / colSums(w * SS$n); lb <- colSums(w * L) / colSums(w * SS$h2)
      HT[[paste(s, fd, g, a)]] <- data.table(set = s, fold = fd, group = g, arm = a, qc_afac = AR[arm == a]$qc_afac, trees = sum(SS$n), sites = nrow(SS),
        obs_m_yr = sum(SS$o) / sum(SS$n), pred_m_yr = sum(d) / sum(SS$n), ratio = sum(d) / sum(SS$o), ratio_lo = quantile(rb, .025, na.rm = TRUE), ratio_hi = quantile(rb, .975, na.rm = TRUE),
        bias_m_yr = (sum(d) - sum(SS$o)) / sum(SS$n), bias_lo = quantile(bb, .025, na.rm = TRUE), bias_hi = quantile(bb, .975, na.rm = TRUE),
        level_t2 = sum(L) / sum(SS$h2), level_lo = quantile(lb, .025, na.rm = TRUE), level_hi = quantile(lb, .975, na.rm = TRUE)) } } }
HT <- rbindlist(HT); w_out(HT, "gyr142-p23-hinc_DATA_2026-09-29.csv")
## in sample check (reported): fold A screened qc_c pooled ratio at the candidate against the step 1 fit table
FIT <- fread(file.path(J, "fit/gyr142-p23-fit-hinc-foldA_DATA_2026-09-29.csv"))
fitchk <- merge(HT[set == "qc_c" & fold == "A" & startsWith(arm, "p19")], FIT[pop == "screened", .(group, qc_afac = QC_AFAC, ratio_fit = ratio)], by = c("group", "qc_afac"))
cat(sprintf("step 1 fit reproduction (fold A, frozen arms): worst %.3g over %d cells\n", fitchk[, max(abs(ratio - ratio_fit))], nrow(fitchk)))
if (fitchk[, max(abs(ratio - ratio_fit))] > 1e-9) stop("FIT REPRO FAIL")
## ---- gates on screened qc_c fold B, candidate against the frozen 0.111 reference
hb <- function(a, g) HT[set == "qc_c" & fold == "B" & group == g & arm == a]
sb <- function(a) STS[set == "qc_c" & pop == "screened B" & arm == a]
c0 <- hb(REF, "overall"); c1 <- hb(CAND, "overall")
cls_tab <- rbindlist(lapply(c("below 12.7", "12.7 to 25", "25 and over"), function(g) { r <- hb(REF, g); c <- hb(CAND, g)
  data.table(group = g, trees = c$trees, bias_ref = r$bias_m_yr, bias_cand = c$bias_m_yr, worse_by = abs(c$bias_m_yr) - abs(r$bias_m_yr), pass = abs(c$bias_m_yr) - abs(r$bias_m_yr) <= M_CLS) }))
d0 <- hb(REF, "dominant"); d1 <- hb(CAND, "dominant"); s0 <- sb(REF); s1 <- sb(CAND)
top_worse <- abs(s1$topht_bias_pct) > abs(s0$topht_bias_pct); dom_real <- abs(d1$level_t2 - 1) > abs(d0$level_t2 - 1) + M_DOM
GATES <- rbind(
  data.table(gate = "H0 harness", detail = sprintf("p23_a0111 against frozen p19_a0111: qc_c results %.2e, trees %.2e; qc_fl results %.2e, trees %.2e", H0[set == "qc_c"]$worst_results, H0[set == "qc_c"]$worst_trees, H0[set == "qc_fl"]$worst_results, H0[set == "qc_fl"]$worst_trees), pass = all(H0$pass)),
  data.table(gate = "K1 failures", detail = sprintf("RUN_OK other than 1 at 1.061 after retries: qc_c %d, qc_fl %d", K1[arm == CAND & set == "qc_c"]$not_ok, K1[arm == CAND & set == "qc_fl"]$not_ok), pass = k1_pass),
  data.table(gate = "H_inc pooled", detail = sprintf("fold B ratio %.3f at 1.061 against %.3f at 0.111 (|dev| %.3f against %.3f); %d trees on %d sites", c1$ratio, c0$ratio, abs(c1$ratio - 1), abs(c0$ratio - 1), c1$trees, c1$sites), pass = abs(c1$ratio - 1) < abs(c0$ratio - 1)),
  data.table(gate = "H_inc classes", detail = paste(sprintf("%s: bias %+.3f against %+.3f m/yr (worse by %+.3f)", cls_tab$group, cls_tab$bias_cand, cls_tab$bias_ref, cls_tab$worse_by), collapse = "; "), pass = all(cls_tab$pass)),
  data.table(gate = "TOPHT reading", detail = sprintf("published TOPHT bias %+.2f against %+.2f percent (%s); dominant cohort t2 level %.3f against %.3f (%s)", s1$topht_bias_pct, s0$topht_bias_pct, if (top_worse) "worse" else "not worse", d1$level_t2, d0$level_t2, if (dom_real) "real conflict" else "within margin"), pass = !(top_worse && dom_real)),
  data.table(gate = "V2 %RMSE", detail = sprintf("fold B C1 %%RMSE %.2f against %.2f, d %+.2f", s1$C1_rmse_pct, s0$C1_rmse_pct, s0$C1_rmse_pct - s1$C1_rmse_pct), pass = s0$C1_rmse_pct - s1$C1_rmse_pct >= -0.5),
  data.table(gate = "B1 basal area", detail = sprintf("fold B |BA - 1| %.2f against %.2f points", 100 * abs(s1$ba_ratio - 1), 100 * abs(s0$ba_ratio - 1)), pass = 100 * (abs(s1$ba_ratio - 1) - abs(s0$ba_ratio - 1)) <= 1.0),
  data.table(gate = "B2 stems", detail = sprintf("fold B |stems - 1| %.2f against %.2f points", 100 * abs(s1$stems_ratio - 1), 100 * abs(s0$stems_ratio - 1)), pass = 100 * (abs(s1$stems_ratio - 1) - abs(s0$stems_ratio - 1)) <= 2.0))
print(GATES)
p <- setNames(GATES$pass, c("H0", "K1", "HP", "HC", "TOP", "V2", "B1", "B2"))
verdict <- if (!p["H0"] || !p["K1"]) "Rule 1: harness or failure gate fails; no verdict" else
  if (!p["HP"]) "Rule 2: fold B pooled height increment not improved; the fold A anchor does not transfer; not adopted" else
  if (!p["HC"]) "Rule 3: a diameter class is worse by more than 0.03 m/yr; one multiplier does not serve every size; not adopted; route is a size dependent QC anchor" else
  if (!p["TOP"]) "Rule 4: top height conflict is real on the dominant cohort; not adopted; route is a size dependent QC anchor" else
  if (!(p["V2"] && p["B1"] && p["B2"])) "Rule 5: height gates pass but volume, basal area or stems fail; not adopted; trade off reported" else
  "Rule 6: every gate passes; QC_AFAC 1.061 is the 14.2 candidate QC height anchor, not adopted into a release before a Bakuzis check"
cat("VERDICT:", verdict, "\n")
w_out(GATES, "gyr142-p23-gates_DATA_2026-09-29.csv"); w_out(H0, "gyr142-p23-H0_DATA_2026-09-29.csv"); w_out(K1, "gyr142-p23-K1_DATA_2026-09-29.csv")
w_out(cls_tab, "gyr142-p23-classgate_DATA_2026-09-29.csv"); w_out(STS, "gyr142-p23-stands-summary_DATA_2026-09-29.csv")
writeLines(c(sprintf("candidate=%s", CAND), sprintf("reference=%s", REF), paste0("verdict=", verdict)), file.path(O, "gyr142-p23-verdict_DATA_2026-09-29.txt"))
## ---- figure: fold A and fold B, screened qc_c, pooled ratio (overall) and mean bias by class against QC_AFAC
F <- HT[set == "qc_c" & arm != "p23_a0111" & group != "dominant"]
F[, panel := factor(fifelse(group == "overall", "Pooled ratio, all trees", paste0("Bias (m/yr), ", group, " cm")),
                    levels = c("Pooled ratio, all trees", "Bias (m/yr), below 12.7 cm", "Bias (m/yr), 12.7 to 25 cm", "Bias (m/yr), 25 and over cm"))]
F[, `:=`(y = fifelse(group == "overall", ratio, bias_m_yr), lo = fifelse(group == "overall", ratio_lo, bias_lo), hi = fifelse(group == "overall", ratio_hi, bias_hi))]
F[, ref := fifelse(group == "overall", 1, 0)]; F[, Fold := fifelse(fold == "A", "Fold A (fit)", "Fold B (held out)")]
g <- ggplot(F, aes(qc_afac, y, colour = Fold)) + geom_hline(aes(yintercept = ref), linetype = 2, colour = "grey40") +
  geom_vline(xintercept = c(0.111, 1.061), linetype = 3, colour = "grey55") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.05, position = position_dodge(width = 0.08)) + geom_point(size = 1.8, position = position_dodge(width = 0.08)) +
  geom_line(position = position_dodge(width = 0.08)) + scale_x_log10(breaks = c(0.03, 0.111, 0.25, 0.5, 1, 1.25), labels = c("0.030", "0.111", "0.250", "0.500", "1.000", "1.250")) +
  scale_colour_manual(values = c(`Fold A (fit)` = "#1b6ca8", `Fold B (held out)` = "#b5452b")) + facet_wrap(~panel, scales = "free_y", ncol = 2) +
  labs(x = "QC_AFAC (log scale)", y = "Predicted against observed annual height increment", colour = NULL) +
  theme_classic(base_size = 10) + theme(legend.position = "bottom", plot.margin = margin(10, 12, 6, 6))
ggsave(file.path(O, "gyr142-p23-hinc_2026-09-29.png"), g, width = 7.5, height = 6, dpi = 300)
cat("P23_ASSEMBLE_DONE\n")

## PREREG16 assembly: joins the Cardinal (19 sets) and firebreather (State MNAP) score tables, applies the
## pre-registered 3 percent rule to the C0/C1 gap, regresses the gap on measured height share at t2, and draws
## the gap figure. Reads aggregates only. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) })
J <- "/home/aaron/jobs/v142vc"; OUT <- file.path(J, "assembled"); dir.create(OUT, showWarnings = FALSE)
D <- "2026-09-27"; set.seed(20260927)
rd <- function(a, b) rbind(fread(a), fread(b), fill = TRUE)
S <- rd(file.path(J, "cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv"), file.path(J, "tables_state_r1/gyr142-volconv-state-scores_DATA_2026-09-27.csv"))
H <- rd(file.path(J, "cardinal/tables_r1/gyr142-volconv-htshare_DATA_2026-09-27.csv"), file.path(J, "tables_state_r1/gyr142-volconv-state-htshare_DATA_2026-09-27.csv"))
G <- rd(file.path(J, "cardinal/tables_r1/gyr142-volconv-gates_DATA_2026-09-27.csv"), file.path(J, "tables_state_r1/gyr142-volconv-state-gates_DATA_2026-09-27.csv"))
stopifnot(all(G$pass))
W <- dcast(S[conv != "gap C0/C1"], label + arm + pop + stands ~ conv, value.var = "ratio")
gap <- S[conv == "gap C0/C1", .(label, arm, pop, gap = ratio, gap_lo = ratio_lo, gap_hi = ratio_hi)]
W <- merge(merge(W, gap, by = c("label", "arm", "pop")), H[, .(label, arm, share_trees, share_expf, share_vol)], by = c("label", "arm"))
W[, `:=`(gap_pct = 100 * (gap - 1), over3 = abs(gap - 1) > 0.03, ci_excl3 = gap_lo > 1.03 | gap_hi < 0.97)]
setorder(W, arm, -gap)
fwrite(W, file.path(OUT, sprintf("gyr142-volconv-bysets_DATA_%s.csv", D)))
## decision rule, point estimates, population 'all' (QC screened reported alongside)
dec <- W[pop == "all", .(sets = .N, sets_over3 = sum(over3), sets_ci_excl3 = sum(ci_excl3), max_abs_gap_pct = max(abs(gap_pct)),
                         set_max = label[which.max(abs(gap_pct))]), by = arm]
fwrite(dec, file.path(OUT, sprintf("gyr142-volconv-decision_DATA_%s.csv", D))); print(dec)
## gap against measured height share at t2, v141LT, one row per set (population all)
X <- W[arm == "v141LT" & pop == "all"]
fits <- rbindlist(lapply(c("share_trees", "share_expf", "share_vol"), function(v) {
  m <- lm(gap_pct ~ x, data = X[, .(gap_pct, x = get(v))]); cf <- summary(m)$coefficients; ci <- confint(m)
  data.table(share = v, n = nrow(X), intercept = cf[1, 1], slope = cf[2, 1], slope_lo = ci[2, 1], slope_hi = ci[2, 2], p = cf[2, 4], r2 = summary(m)$r.squared) }))
fwrite(fits, file.path(OUT, sprintf("gyr142-volconv-gapreg_DATA_%s.csv", D))); print(fits)
## paired arms on the sets both carry
P <- dcast(W[pop == "all"], label ~ arm, value.var = "gap")[!is.na(v1404_L2)]
fwrite(P, file.path(OUT, sprintf("gyr142-volconv-armpair_DATA_%s.csv", D)))
## figure: gap by set against measured tree share at t2, 95 percent site cluster intervals
X[, lab := sub("_c$| _all$", "", label)]
p <- ggplot(X, aes(share_trees, gap_pct)) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = -3, ymax = 3, fill = "grey90") +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  geom_errorbar(aes(ymin = 100 * (gap_lo - 1), ymax = 100 * (gap_hi - 1)), width = 0.015, linewidth = 0.4, colour = "grey35") +
  geom_point(size = 2, colour = "#1b4f72") +
  geom_text(aes(label = label), size = 2.4, hjust = -0.12, vjust = -0.4, colour = "grey20", check_overlap = TRUE) +
  scale_x_continuous("Measured height share at t2 (trees)", limits = c(0, 1.08), breaks = seq(0, 1, 0.2)) +
  scale_y_continuous("C0 / C1 volume gap (%)") +
  theme_classic(base_size = 10) + theme(panel.grid = element_blank())
ggsave(file.path(OUT, sprintf("gyr142-volconv-gap-vs-share_%s.png", D)), p, width = 170, height = 110, units = "mm", dpi = 300)
cat("ASSEMBLE_DONE\n")

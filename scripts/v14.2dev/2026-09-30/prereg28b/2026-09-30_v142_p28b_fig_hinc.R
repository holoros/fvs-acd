## PREREG28b reported figure: the assembly figure redrawn from the assembled height table with wrapped arm labels and
## axis units in SI form (the assembly figure's two long labels overlap). No number changes. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) })
HT <- fread("/home/aaron/jobs/v142p28b/assembled/gyr142-p28b-hinc_DATA_2026-09-30.csv")
F <- HT[set == "qc_c" & arm != "p28_g0" & group != "dominant"]
lv <- c("0.030", "0.111", "1.061", "1.250", "Pair\n1.265 and\n0.030", "Small only\n1.265 and\n0.111")
F[, armlab := factor(c(p19_a0030 = lv[1], p19_a0111 = lv[2], p23_a1061 = lv[3], p23_a1250 = lv[4], p28_cand = lv[5], p28b_small = lv[6])[arm], levels = lv)]
pl <- c("Pooled~ratio~(all~trees)", "Bias~(m~yr^{-1})*','~below~12.7~cm", "Bias~(m~yr^{-1})*','~12.7~to~25~cm", "Bias~(m~yr^{-1})*','~25~cm~and~over")
F[, panel := factor(fcase(group == "overall", pl[1], group == "below 12.7", pl[2], group == "12.7 to 25", pl[3], default = pl[4]), levels = pl)]
F[, `:=`(y = fifelse(group == "overall", ratio, bias_m_yr), lo = fifelse(group == "overall", ratio_lo, bias_lo), hi = fifelse(group == "overall", ratio_hi, bias_hi))]
F[, ref := fifelse(group == "overall", 1, 0)]; F[, Fold := fifelse(fold == "A", "Fold A (fit)", "Fold B (held out)")]
g <- ggplot(F, aes(armlab, y, colour = Fold)) + geom_hline(aes(yintercept = ref), linetype = 2, colour = "grey40") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = 0.2, position = position_dodge(width = 0.5)) + geom_point(size = 1.8, position = position_dodge(width = 0.5)) +
  scale_colour_manual(values = c(`Fold A (fit)` = "#1b6ca8", `Fold B (held out)` = "#b5452b")) +
  facet_wrap(~panel, scales = "free_y", ncol = 2, labeller = label_parsed) +
  labs(x = "QC height anchor (single multiplier, or below 25 cm / 25 cm and over)", y = "Predicted against observed annual height increment", colour = NULL) +
  theme_classic(base_size = 10) + theme(legend.position = "bottom", strip.background = element_blank(), axis.text.x = element_text(size = 7.5), plot.margin = margin(10, 12, 6, 6))
ggsave("gyr142-p28b-hinc-labelled_2026-09-30.png", g, width = 180, height = 150, units = "mm", dpi = 300)
cat("FIG_DONE\n")

## PREREG35 figure: pooled ratios, all stands against established at t1, for sets where the stratum fires. Headless.
## Reads the r2 stratum table only. No em dashes.
suppressMessages({library(data.table); library(ggplot2)})
J <- "/home/aaron/jobs/v142p35"; S <- fread(file.path(J, "tables/r2_fb/gyr142-volconv-r2stratum_DATA_2026-09-27.csv"))
S <- S[variable %in% c("volume C0", "volume C1", "basal area", "stems")]
S[, var := factor(variable, levels = rev(c("volume C0", "volume C1", "basal area", "stems")),
  labels = rev(c("Volume~C0~(m^3~ha^-1)", "Volume~C1~(m^3~ha^-1)", "Basal~area~(m^2~ha^-1)", "Stems~(ha^-1)")))]
n <- S[, .(n = stands[1]), by = stratum]
S[, grp := factor(stratum, levels = c("all", "established_t1"), labels = c(sprintf("All stands (%d)", n[stratum == "all", n]), sprintf("Established at t1 (%d)", n[stratum == "established_t1", n])))]
fwrite(S[, .(label, stratum, stands, variable, ratio, ratio_lo, ratio_hi)], file.path(J, "assembled", "gyr142-p35-fig_DATA_2026-10-01.csv"))
g <- ggplot(S, aes(x = ratio, y = var, colour = grp, shape = grp)) +
  geom_vline(xintercept = 1, linetype = 2, colour = "grey45", linewidth = 0.4) +
  geom_errorbarh(aes(xmin = ratio_lo, xmax = ratio_hi), height = 0.25, linewidth = 0.6, position = position_dodge(width = 0.55)) +
  geom_point(size = 2.4, position = position_dodge(width = 0.55)) +
  scale_y_discrete(labels = function(x) parse(text = x)) +
  scale_colour_manual(values = c("#1b4f72", "#c0392b"), name = NULL) + scale_shape_manual(values = c(16, 17), name = NULL) +
  facet_wrap(~ label, labeller = as_labeller(c(nb_c = "nb_c, v141LT"))) +
  labs(x = "Pooled ratio, predicted / observed", y = NULL) +
  theme_classic(base_size = 10) + theme(legend.position = "bottom", strip.background = element_blank(), strip.text = element_text(face = "bold"),
    panel.background = element_rect(fill = "white", colour = NA), plot.background = element_rect(fill = "white", colour = NA))
f <- file.path(J, "figs", "gyr142-p35-stratum-ratios_2026-10-01.png")
ggsave(f, g, width = 180, height = 90, units = "mm", dpi = 300, bg = "white"); cat("wrote", f, "\n"); cat("P35_FIG_DONE\n")

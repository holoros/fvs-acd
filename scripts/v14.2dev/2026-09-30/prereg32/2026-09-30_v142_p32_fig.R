## PREREG32 figure, redrawn from assembled/gyr142-p32-fig_DATA_2026-09-30.csv: ratio panel first, left margin widened so no label is clipped. No value changes. No em dashes.
suppressMessages({library(data.table); library(ggplot2)})
A <- "/home/aaron/jobs/v142p32/assembled"; L <- fread(file.path(A, "gyr142-p32-fig_DATA_2026-09-30.csv"))
L[, var := factor(var, levels = c("Volume~C0~(m^3~ha^-1)", "Volume~C1~(m^3~ha^-1)", "Basal~area~(m^2~ha^-1)", "Stems~(ha^-1)"))]
L[, metric := factor(metric, levels = c("Pooled~ratio~(predicted/observed)", "Percent~RMSE"))]
L[, adm := factor(adm, levels = c("A0 published (355 stands)", "A1 V_o = 0 excluded (322 stands)"))]
hl <- data.table(metric = factor("Pooled~ratio~(predicted/observed)", levels = levels(L$metric)), y = 1)
p <- ggplot(L, aes(x = var, y = est, colour = adm, shape = adm)) +
  geom_hline(data = hl, aes(yintercept = y), linetype = 2, colour = "grey50") +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.5), size = 0.4) +
  facet_wrap(~metric, ncol = 2, scales = "free_y", labeller = label_parsed) +
  scale_x_discrete(labels = function(z) parse(text = z)) + scale_colour_manual(values = c("#1b4f72", "#c0392b")) +
  labs(x = NULL, y = NULL, colour = NULL, shape = NULL) + theme_classic(base_size = 9) +
  theme(legend.position = "bottom", strip.background = element_blank(), axis.text.x = element_text(angle = 25, hjust = 1),
        plot.margin = margin(4, 4, 2, 14, "mm"))
ggsave(file.path(A, "gyr142-p32-nb-admission_2026-09-30.png"), p, width = 180, height = 95, units = "mm", dpi = 300)
cat("P32_FIG_DONE\n")

## PREREG37 figure revision 2: redraw of figs/gyr142-p37-height-structure_2026-10-01.png from its data file only (no value
## recomputed). Same panels and values as the verdict script; y titles on two lines, panel tags by patchwork plot_annotation.
## The rev 1 PNG is kept as figs/gyr142-p37-height-structure_rev1_truncated_2026-10-01.png.bak. No em dashes.
suppressMessages({ library(data.table); library(ggplot2); library(patchwork) })
J <- "/home/aaron/jobs/v142p37"; O <- file.path(J, "figs/gyr142-p37-height-structure_2026-10-01.png")
if (file.exists(O)) stop("REFUSE ", O)
FD <- fread(file.path(J, "figs/gyr142-p37-height-structure_DATA_2026-10-01.csv"))
fa <- FD[panel == "a"][, group := factor(group, levels = c("below 12.7", "12.7 to 25", "25 and over"))]
fb <- FD[panel == "b"][, group := factor(group, levels = c("below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25", "1.25 and over"))]
TR <- FD[panel == "c"]; BAND <- c(0.85, 1.15)
ylab_R <- "Observed / unanchored\npredicted increment, R"
pd <- position_dodge(width = 0.4); th <- theme_classic(base_size = 8) + theme(legend.position = "bottom", legend.title = element_blank(), strip.background = element_blank())
ga <- ggplot(fa, aes(group, R, colour = tagkey)) + geom_hline(yintercept = c(1.265, 0.111), linetype = c(2, 3), colour = "grey40") + geom_hline(yintercept = 0, colour = "grey80") +
  geom_errorbar(aes(ymin = R_lo, ymax = R_hi), width = 0.15, position = pd) + geom_point(position = pd, size = 1.6) +
  scale_colour_manual(values = c("field tag" = "#1b6ca8", "row index" = "#c0392b")) + labs(x = "DBH at t1 (cm)", y = ylab_R) + th
gb <- ggplot(fb, aes(group, R)) + geom_hline(yintercept = 1, colour = "grey60") + geom_errorbar(aes(ymin = R_lo, ymax = R_hi), width = 0.15, colour = "#1b6ca8") +
  geom_point(colour = "#1b6ca8", size = 1.6) + labs(x = "Relative height, HT1 / ESI", y = ylab_R) + th + theme(axis.text.x = element_text(angle = 20, hjust = 1))
gc <- ggplot(TR, aes(age, HT_over_ESI, colour = arm)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = BAND[1], ymax = BAND[2], fill = "grey90") + geom_line(linewidth = 0.6) +
  facet_wrap(~cell, nrow = 1) + scale_colour_manual(values = c("#1b6ca8", "#7f7f7f", "#e08e0b")) +
  labs(x = "Stand age (yr)", y = "Top height / ESI") + th + guides(colour = guide_legend(nrow = 1))
g <- (ga | gb) / gc + plot_layout(heights = c(1, 0.9)) + plot_annotation(tag_levels = "a") & theme(plot.tag = element_text(size = 9, face = "bold"), plot.tag.position = c(0, 1))
ggsave(O, g, width = 180, height = 150, units = "mm", dpi = 300)
cat("P37_FIG_REV2_DONE\n")

## v143p4_fig_r1.R, PREREG4: figure re-render only (r1). The assembly figure (v143p4_assemble.R, md5 62610094) clipped its caption
## at the right edge. This script redraws the same figure from the assembled aggregate CSV (no other input) with the caption
## wrapped and the fold B stand count in each panel title. New file names (_r1); the assembly figure is kept. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) })
P <- "/users/PUOM0008/crsfaaron/v143p4"
o1 <- file.path(P, "fig/v143p4_fig_share_declining_2026-10-28_r1.png"); o2 <- sub("png$", "pdf", o1)
if (file.exists(o1) || file.exists(o2)) stop("REFUSE")
D <- fread(file.path(P, "assembled/v143p4_long200_decline_DATA_2026-10-28.csv"))
FTN <- c(SF = "Spruce-fir", MBB = "Maple-beech-birch", AB = "Aspen-birch", WRPH = "White-red pine-hemlock", OAK = "Oak and oak-pine", EAC = "Elm-ash-cottonwood")
VL <- c(v131h = "13.1h", v141LT = "14.1", D1 = "D1: 14.1 with the floor removed in NSF stands")
d <- D[FOLD == "B" & ftg %in% names(FTN) & arm %in% names(VL)]
nn <- d[arm == "v141LT", .(ftg, n)]
d[, ftgl := factor(sprintf("%s (n = %d)", FTN[ftg], n), levels = nn[match(names(FTN), ftg), sprintf("%s (n = %d)", FTN[ftg], n)])]
d[, version := factor(VL[arm], levels = VL)]
cols <- setNames(c("#8c5a3c", "#1a3d28", "#9a9a9a"), VL)
cp <- unique(d[, .(ftgl, curve_p)])
p <- ggplot(d, aes(version, share_declining, colour = version)) +
  geom_hline(data = cp, aes(yintercept = curve_p), linetype = "dashed", linewidth = 0.4, colour = "grey30") +
  geom_errorbar(aes(ymin = dec_lo, ymax = dec_hi), width = 0.25) + geom_point(size = 2) +
  facet_wrap(~ftgl, nrow = 2) + scale_colour_manual(values = cols, name = NULL) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.25)) +
  labs(x = NULL, y = "Share of stands declining by year 200",
       caption = paste("Fold B unmanaged Maine FIA stands grown 200 yr without harvest. A stand is declining when its year 200 aboveground",
                       "biomass is below 95% of its projection maximum. Bars: 95% stand bootstrap intervals (1,000 resamples).",
                       "Dashed line: probability that the Maine FIA aboveground biomass curve peaks before 250 yr.", sep = "\n")) +
  theme_bw(base_size = 9) + theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
    strip.background = element_rect(fill = "grey95"), axis.text.x = element_blank(), axis.ticks.x = element_blank(),
    legend.position = "bottom", plot.caption = element_text(hjust = 0, size = 7), plot.caption.position = "plot")
ggsave(o1, p, width = 7.2, height = 5.2, dpi = 300, bg = "white"); ggsave(o2, p, width = 7.2, height = 5.2, bg = "white")
cat("FIG_R1_DONE\n")

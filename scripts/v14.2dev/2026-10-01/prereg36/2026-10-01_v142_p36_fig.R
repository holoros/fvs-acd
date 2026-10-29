## PREREG36 figure (firebreather), drawn from figs/gyr142-p36-dbhchange_DATA_2026-10-01.csv (0.1 cm binned counts written by
## the A12 script) after the A12 figure call stopped on a geom_vline aesthetic. No value changes. No em dashes.
suppressMessages(library(data.table)); library(ggplot2)
J <- "/home/aaron/jobs/v142p36"
D <- fread(file.path(J, "figs/gyr142-p36-dbhchange_DATA_2026-10-01.csv")); G <- fread(file.path(J, "tables/gyr142-p36-a2-groups_DATA_2026-10-01.csv"))[set == "qc_c"]
D[, bin := floor(dd / 0.5) * 0.5 + 0.25]; B <- D[bin >= -15 & bin <= 15, .(N = sum(N)), by = .(grp, bin)]
lv <- c("row index only", "both", "field tag only")
lab <- setNames(G[match(lv, grp), sprintf("%s: n = %d pairs, %.1f percent with DBH loss over 1 cm", c("Row index tag only", "Both tag systems", "Field tag only"), n, 100 * dbh_shrink_share)], lv)
B[, grp := factor(grp, lv)]
p <- ggplot(B, aes(bin, N)) + geom_col(width = 0.5, fill = "grey35") + geom_vline(xintercept = -1, linetype = "dashed", linewidth = 0.3) +
  geom_vline(xintercept = 0, linewidth = 0.3) + facet_wrap(~ grp, ncol = 1, scales = "free_y", labeller = as_labeller(lab)) +
  labs(x = "DBH at t2 minus DBH at t1 (cm)", y = "Tree pairs") + theme_classic(base_size = 9) +
  theme(strip.background = element_blank(), strip.text = element_text(hjust = 0))
ggsave(file.path(J, "figs/gyr142-p36-qc-c2-pairs-dbhchange_2026-10-01.png"), p, width = 180, height = 150, units = "mm", dpi = 300)
cat("P36_FIG_DONE\n")

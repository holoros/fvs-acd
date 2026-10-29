## PREREG37 verdict and figure. Reads the fold A and fold B assembled tables, the seedling run at QC_AFAC 1 and the PREREG31
## annual trajectories (read only), applies the plan's decision rules 1 to 5 to fold B, writes the rules table, the seedling
## table, the verdict file and the figure with its data file. No coordinates. No em dashes.
suppressMessages({ library(data.table); library(ggplot2); library(patchwork) })
J <- "/home/aaron/jobs/v142p37"; A <- file.path(J, "assembled"); DT <- "2026-10-01"
rd <- function(n, f) fread(file.path(A, sprintf("gyr142-p37-%s-fold%s_DATA_%s.csv", n, f, DT)))
o_ <- function(n) { f <- file.path(A, n); if (file.exists(f)) stop("REFUSE ", f); f }
Sb <- rd("S", "B"); Jb <- rd("joint", "B"); Ja <- rd("joint", "A"); Lb <- rd("slopes", "B"); Db <- rd("dominant", "B"); Rb <- rd("ratio", "B")
Sstar <- sqrt(1.265 / 0.111); TH_SITE <- (19.8 - 17.3) / 18.55; BAND <- c(0.85, 1.15)
sf <- Sb[tagkey == "field tag"]; sr <- Sb[tagkey == "row index"]
G0 <- if (sf$S >= Sstar && sf$S_lo > 1) "REPRODUCED" else if (sf$S_hi < Sstar) "NOT REPRODUCED" else "INDETERMINATE"
ART <- G0 == "NOT REPRODUCED" && sr$S >= Sstar
jq <- function(T, q) T[quantity == q]
lnS <- log(sf$S); sg <- sign(lnS)
ex0 <- function(r) (r$lo > 0 & r$hi > 0) | (r$lo < 0 & r$hi < 0)
H1 <- with(list(d = jq(Jb, "D_H1"), s1 = jq(Jb, "s_H1")$estimate, s2 = jq(Jb, "s_H2")$estimate, br = Lb[covariate == "rel"]),
  sign(d$estimate) == sg && ex0(d) && s1 >= 0.5 && s2 < 0.25 && ex0(data.table(lo = br$beta_lo, hi = br$beta_hi)) && sign(jq(Ja, "D_H1")$estimate) == sign(d$estimate))
H2 <- with(list(d = jq(Jb, "D_H2"), s1 = jq(Jb, "s_H1")$estimate, s2 = jq(Jb, "s_H2")$estimate),
  sign(d$estimate) == sg && ex0(d) && s2 >= 0.5 && s1 < 0.25 && sign(jq(Ja, "D_H2")$estimate) == sign(d$estimate))
m <- Db[quantity == "m_site_curve"]; H3 <- (m$lo > 1 | m$hi < 1) && abs(m$estimate - 1) >= TH_SITE
## seedling
SE <- fread(file.path(J, sprintf("tables/gyr142-p37-seedling-afac1_DATA_%s.csv", DT)))
P31 <- fread("/home/aaron/jobs/v142p31/assembled/gyr142-p31-traj-annual_DATA_2026-09-30.csv")[cell %in% unique(SE$cell)]
TR <- rbind(SE[, .(arm = "QC_AFAC 1 (PREREG37)", cell, esi, age, HT, run_ok)], P31[, .(arm = fifelse(arm == "qc141", "QC_AFAC 0.111 (PREREG31 qc141)", "QC_AFAC 1.265 below 25 cm (PREREG31 p28b_small)"), cell, esi, age, HT, run_ok)])
TR <- TR[age <= 50]
SEt <- TR[age %in% c(0, 25, 50), .(HT = HT[1], HT_over_ESI = HT[1] / esi[1], run_ok = run_ok[1]), by = .(arm, cell, esi, age)]
fwrite(SEt, o_(sprintf("gyr142-p37-seedling_DATA_%s.csv", DT))); print(SEt, digits = 3)
r50 <- SEt[arm == "QC_AFAC 1 (PREREG37)" & age == 50]$HT_over_ESI
STALL <- if (all(r50 >= BAND[1] & r50 <= BAND[2])) "stall set by the anchor value" else if (any(r50 < BAND[1])) "unanchored equation also stalls" else "overshoot"
RU <- data.table(rule = c("G0", "G0 row index artifact", "H1", "H2", "H3 (dominant level)", "Stall"),
  result = c(G0, ART, H1, H2, H3, STALL),
  basis = c(sprintf("S_field %.3f (%.3f to %.3f) against S* %.3f", sf$S, sf$S_lo, sf$S_hi, Sstar), sprintf("S_row %.3f (%.3f to %.3f)", sr$S, sr$S_lo, sr$S_hi),
    sprintf("D_H1 %.3f (%.3f to %.3f), s_H1 %.2f, s_H2 %.2f, beta_rel %.3f (%.3f to %.3f), fold A D_H1 %.3f", jq(Jb, "D_H1")$estimate, jq(Jb, "D_H1")$lo, jq(Jb, "D_H1")$hi,
      jq(Jb, "s_H1")$estimate, jq(Jb, "s_H2")$estimate, Lb[covariate == "rel"]$beta, Lb[covariate == "rel"]$beta_lo, Lb[covariate == "rel"]$beta_hi, jq(Ja, "D_H1")$estimate),
    sprintf("D_H2 %.3f (%.3f to %.3f), s_H2 %.2f, fold A D_H2 %.3f", jq(Jb, "D_H2")$estimate, jq(Jb, "D_H2")$lo, jq(Jb, "D_H2")$hi, jq(Jb, "s_H2")$estimate, jq(Ja, "D_H2")$estimate),
    sprintf("m %.3f (%.3f to %.3f), threshold %.3f", m$estimate, m$lo, m$hi, TH_SITE), sprintf("HT50/ESI at QC_AFAC 1: %s", paste(sprintf("%.3f", r50), collapse = ", "))))
fwrite(RU, o_(sprintf("gyr142-p37-rules_DATA_%s.csv", DT))); print(RU)
VERD <- if (ART) "size pattern: none of H1 to H3, row index pairing artifact" else if (H1) "size pattern: H1" else if (H2) "size pattern: H2" else "size pattern: none identifiable"
writeLines(c(sprintf("PREREG37 verdict (fold B): %s; G0 %s; H3 dominant level %s; stall: %s", VERD, G0, if (H3) "named" else "not named", STALL)), o_(sprintf("gyr142-p37-verdict_DATA_%s.txt", DT)))
## figure
fa <- Rb[scheme == "cls3"][, panel := "a"][, group := factor(group, levels = c("below 12.7", "12.7 to 25", "25 and over"))]
fb <- Rb[scheme == "relht" & tagkey == "field tag"][, panel := "b"][, group := factor(group, levels = c("below 0.5", "0.5 to 0.75", "0.75 to 1", "1 to 1.25", "1.25 and over"))]
FD <- rbind(fa[, .(panel, tagkey, group = as.character(group), trees, R, R_lo, R_hi, arm = NA_character_, cell = NA_character_, age = NA_real_, HT_over_ESI = NA_real_)],
            fb[, .(panel, tagkey, group = as.character(group), trees, R, R_lo, R_hi, arm = NA_character_, cell = NA_character_, age = NA_real_, HT_over_ESI = NA_real_)],
            TR[, .(panel = "c", tagkey = NA_character_, group = NA_character_, trees = NA_integer_, R = NA_real_, R_lo = NA_real_, R_hi = NA_real_, arm, cell, age, HT_over_ESI = HT / esi)])
fwrite(FD, file.path(J, "figs", sprintf("gyr142-p37-height-structure_DATA_%s.csv", DT)))
pd <- position_dodge(width = 0.4); th <- theme_classic(base_size = 8) + theme(legend.position = "bottom", legend.title = element_blank(), strip.background = element_blank())
ga <- ggplot(fa, aes(group, R, colour = tagkey)) + geom_hline(yintercept = c(1.265, 0.111), linetype = c(2, 3), colour = "grey40") + geom_hline(yintercept = 0, colour = "grey80") +
  geom_errorbar(aes(ymin = R_lo, ymax = R_hi), width = 0.15, position = pd) + geom_point(position = pd, size = 1.6) +
  scale_colour_manual(values = c("field tag" = "#1b6ca8", "row index" = "#c0392b")) +
  labs(x = "DBH at t1 (cm)", y = "Observed / unanchored predicted height increment", tag = "a") + th
gb <- ggplot(fb, aes(group, R)) + geom_hline(yintercept = 1, colour = "grey60") + geom_errorbar(aes(ymin = R_lo, ymax = R_hi), width = 0.15, colour = "#1b6ca8") +
  geom_point(colour = "#1b6ca8", size = 1.6) + labs(x = "Relative height, HT1 / ESI", y = "Observed / unanchored predicted height increment", tag = "b") + th +
  theme(axis.text.x = element_text(angle = 20, hjust = 1))
gc <- ggplot(TR, aes(age, HT / esi, colour = arm)) + annotate("rect", xmin = -Inf, xmax = Inf, ymin = BAND[1], ymax = BAND[2], fill = "grey90") + geom_line(linewidth = 0.6) +
  facet_wrap(~cell, nrow = 1) + scale_colour_manual(values = c("#1b6ca8", "#7f7f7f", "#e08e0b")) +
  labs(x = "Stand age (yr)", y = "Top height / ESI", tag = "c") + th + guides(colour = guide_legend(nrow = 1))
g <- (ga | gb) / gc + plot_layout(heights = c(1, 0.9))
ggsave(file.path(J, "figs", sprintf("gyr142-p37-height-structure_%s.png", DT)), g, width = 180, height = 150, units = "mm", dpi = 300)
cat("P37_VERDICT_DONE\n")

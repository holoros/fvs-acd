# =============================================================================
# Figure 5. The offsetting bias signature, in domain.
#
# Level bias (%) for v12.10.1 on the Acadian-core operational domain (n = 492):
# basal area under-predicts, top height over-predicts, and the two cancel in
# total volume. Diverging semantic: cool for under-prediction, warm for over.
#
# R-first house standard. A matching matplotlib renderer (fig5_offsetting_bias.py)
# produced the shipped PNG because R was unavailable in the build sandbox. This
# is the reproducible R path.
#
# Values read verbatim from the frozen operational-domain recompute; NOT
# recomputed. BA -9.20, TOPHT +4.16, TOTVOL -1.63.
#   Source: _context/v13_autosubmit/pulled/scorecard_domain_v12101.csv
#           (subset POOLED_indomain)
# Author: A. Weiskittel (CRSF-Cowork)
# =============================================================================
suppressMessages({library(tidyverse)})

repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
data <- file.path(repo, "_context/v13_autosubmit/pulled/scorecard_domain_v12101.csv")
out  <- file.path(repo, "figures/fig5_offsetting_bias.png")

met_lab <- c(BA = "Basal area", TOPHT = "Top height", TOTVOL = "Total volume")

d <- read_csv(data, show_col_types = FALSE) |>
  filter(subset == "POOLED_indomain", metric %in% names(met_lab)) |>
  mutate(label = factor(met_lab[metric], levels = unname(met_lab)),
         dir   = if_else(bias_pct >= 0, "over", "under"),
         ytxt  = if_else(bias_pct >= 0, bias_pct + 0.28, bias_pct - 0.28),
         vtxt  = if_else(bias_pct >= 0, "bottom", "top"))
n_val <- d$n[1]

p <- ggplot(d, aes(label, bias_pct, fill = dir)) +
  geom_col(width = 0.62, colour = "grey20", linewidth = 0.25) +
  geom_hline(yintercept = 0, colour = "grey10", linewidth = 0.5) +
  geom_text(aes(y = ytxt, vjust = if_else(bias_pct >= 0, 0, 1),
                label = sprintf("%+.2f%%", bias_pct)),
            fontface = "bold", size = 4.4, colour = "grey10") +
  scale_fill_manual(values = c(under = "#3B6FA0", over = "#C0504D"),
                    guide = "none") +
  labs(title = "The offsetting bias signature, in domain",
       caption = paste0("v12.10.1 in the Acadian-core domain (n = ", n_val,
                        "). Basal area under-predicts and top height ",
                        "over-predicts,\ncanceling in total volume. ",
                        "Target of the v13.0 joint re-anchor."),
       x = NULL, y = "Level bias (%)") +
  theme_minimal(base_size = 12) +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 13),
        plot.caption = element_text(colour = "grey40", hjust = 0.5, size = 9))

ggsave(out, p, width = 19, height = 14, units = "cm", dpi = 300, bg = "white")
cat("Wrote", out, "\n")
print(d |> select(metric, label, bias_pct))

#!/usr/bin/env Rscript
# build_v25_report_figs.R
# v25: adds FVSACD_v1211_full and FVSACD_v131_full (full-137 rerun), retiring
# FVSACD_v1211_silc73. Same house style as build_v24_report_figs.R (theme_silc,
# named palette, real axis expressions, no default gray panel).

suppressMessages({ library(ggplot2); library(scales); library(data.table) })

theme_silc <- function(base_size = 11) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      plot.title = element_text(face = "bold", size = base_size + 2),
      plot.subtitle = element_text(color = "grey30", size = base_size - 1),
      axis.title = element_text(face = "bold"),
      legend.position = "bottom",
      strip.text = element_text(face = "bold")
    )
}

sc <- fread("silc_cfi_value_v25_scorecard.csv")
sc[, model := factor(model, levels = model[order(-value_bias)])]

pal <- c("AcadianGY v8.35 (byPlot)" = "#7B3F00",
         "OSM-ACD" = "#2C7FB8",
         "FVS-NE default" = "#41AB5D",
         "FVS-ACD default (v16-v22 vintage)" = "#238B45",
         "FVS-ACD v12.11 (full137 rerun, tree-level)" = "#FDAE61",
         "FVS-ACD v13.1 (full137 rerun, tree-level)" = "#E31A1C")

## Figure 1: mean value per acre by model, with the observed floor -----------
obs_val <- 387
p1 <- ggplot(sc, aes(x = model, y = mean_val, fill = model)) +
  geom_col(width = 0.65, show.legend = FALSE) +
  geom_hline(yintercept = obs_val, linetype = "dashed", color = "grey20") +
  annotate("text", x = 1, y = obs_val + 25, label = paste0("Observed floor $", obs_val, " ac⁻¹"),
           hjust = 0, size = 3.2, color = "grey20") +
  geom_text(aes(label = paste0("$", mean_val)), vjust = -0.5, size = 3.4, fontface = "bold") +
  scale_fill_manual(values = pal) +
  scale_y_continuous(labels = dollar_format(), expand = expansion(mult = c(0, 0.15))) +
  labs(title = "v25 projected stumpage value by model",
       subtitle = "Routine n = 65 (OSM-ACD n = 63), Aroostook County 2024 $, SILC merch spec",
       x = NULL, y = expression(Mean~stumpage~value~(USD~ac^-1))) +
  theme_silc() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))
ggsave("v25_docbuild/fig1_value_by_model_v25.png", p1, width = 8.2, height = 4.8, dpi = 300, bg = "white")

## Figure 2: total volume + value bias by model -------------------------------
bl <- melt(sc[, .(model, `Total volume bias (%)` = totvol_bias, `Value bias (%)` = value_bias)],
           id.vars = "model", variable.name = "metric", value.name = "bias")
p2 <- ggplot(bl, aes(x = model, y = bias, fill = metric)) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  geom_hline(yintercept = 0, color = "grey30") +
  geom_text(aes(label = paste0(ifelse(bias > 0, "+", ""), bias, "%")),
            position = position_dodge(width = 0.7), vjust = ifelse(bl$bias >= 0, -0.4, 1.2), size = 2.9) +
  scale_fill_manual(values = c("Total volume bias (%)" = "#525252", "Value bias (%)" = "#D95F02")) +
  scale_y_continuous(labels = function(x) paste0(x, "%"), expand = expansion(mult = c(0.12, 0.18))) +
  labs(title = "v25 total volume and value bias vs. observed, by model",
       subtitle = "Bias = 100 x (model mean / observed mean - 1); routine n = 65 (OSM-ACD n = 63)",
       x = NULL, y = "Bias (%)", fill = NULL) +
  theme_silc() +
  theme(axis.text.x = element_text(angle = 25, hjust = 1))
ggsave("v25_docbuild/fig2_bias_by_model_v25.png", p2, width = 8.4, height = 4.9, dpi = 300, bg = "white")

cat("Wrote fig1_value_by_model_v25.png, fig2_bias_by_model_v25.png to v25_docbuild/\n")

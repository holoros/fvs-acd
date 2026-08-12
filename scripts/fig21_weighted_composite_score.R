#!/usr/bin/env Rscript
# fig21_weighted_composite_score.R
#
# Canonical R/ggplot2 rebuild of figures/fig21_weighted_composite_score.png, matching the
# advanced-viz house-style uncertainty and disclosure gates applied in the Python smoke render
# this session (scripts/fig21_rebuild_advanced_viz.py). This script is WRITTEN BUT NOT EXECUTED:
# no R installation is reachable in this Cowork sandbox and Cardinal SSH timed out this session
# (both confirmed down; see CLAUDE.md sandbox provisioning notes). Run this on Cardinal
# (module purge; module load gcc/12.3.0 R/4.5.2) the next time HPC access returns, against the
# unchanged figures/_data/composite_score_weighted.csv, and diff the PNG against the Python
# version for visual parity. This script performs NO recomputation: every number plotted is read
# from the frozen CSV, the output of scripts/composite_score_weighted.py / .R (composite
# computation), and this script does not touch that computation.
#
# [STACK: Python smoke render this session; R/ggplot2 script written for Cardinal, not executed]
#
# Palette: panel (a) has three model categories (base v12.10.1 / candidate v12.11 / OSM-ACD
# v2.26.1), so it uses three discrete stops sampled from the GSEA-style purple-to-blue-to-
# lavender-to-pink-to-red journal-register ramp (purple start, lavender midpoint, red end); the
# paired teal/salmon scheme is reserved for genuine two-way splits and does not map cleanly onto
# three categories. Panel (b) is a real two-way split (Maine-labeled sources vs NB/QC/NS sources),
# so it uses the paired teal (#1B9E9E) / salmon (#E15554) scheme instead.
#
# No theme_pub_journal() definition was found anywhere under scripts/ in this repo at the time of
# writing (grepped scripts/*.R for "theme_pub"; only scripts/hennigar_figs_v1210.R and
# scripts/hennigar_figs_robust.R define a similarly-named `theme_pub`, a plain
# theme_minimal()-based theme, not a project-wide theme_pub_journal()). This script defines an
# equivalent minimal theme inline, matching that project convention: theme_minimal base, no minor
# gridlines, bold plot title, grey subtitle, bottom-anchored legend.
#
# Run (on Cardinal, after module load):  Rscript scripts/fig21_weighted_composite_score.R

suppressPackageStartupMessages({
  library(data.table)
  library(ggplot2)
  library(patchwork)
  library(scales)
})

REPO_ROOT <- normalizePath(file.path(dirname(sys.frame(1)$ofile %||% "."), ".."), mustWork = FALSE)
`%||%` <- function(a, b) if (is.null(a)) b else a
if (interactive() || identical(REPO_ROOT, "..")) REPO_ROOT <- getwd()

IN_CSV  <- file.path(REPO_ROOT, "figures/_data/composite_score_weighted.csv")
OUT_PNG <- file.path(REPO_ROOT, "figures/fig21_weighted_composite_score.png")

# ---------------------------------------------------------------------------------------------
# 1. Parse the frozen, multi-section CSV: row detail first, then "# --- composite results ---",
#    then the NS-long bucket table, then the exclusion list. Split on the "# ---" markers.
# ---------------------------------------------------------------------------------------------
raw_lines <- readLines(IN_CSV)
section_idx <- grep("^# ---", raw_lines)

detail_block  <- raw_lines[1:(section_idx[1] - 1)]
detail_dt <- fread(paste(detail_block, collapse = "\n"))

results_block <- raw_lines[(section_idx[1] + 1):(section_idx[2] - 1)]
results_block <- results_block[nzchar(trimws(results_block))]
results_dt <- fread(paste(results_block, collapse = "\n"))

cat(sprintf("Read %d detail rows, %d composite result rows from %s\n",
            nrow(detail_dt), nrow(results_dt), IN_CSV))

# ---------------------------------------------------------------------------------------------
# 2. Palette + minimal house theme (theme_pub_journal-equivalent; see header note)
# ---------------------------------------------------------------------------------------------
model_colors <- c("Base (v12.10.1)" = "#762A83",
                   "Candidate (v12.11)" = "#9970AB",
                   "OSM-ACD (v2.26.1)" = "#B2182B")
TEAL <- "#1B9E9E"
SALMON <- "#E15554"

theme_pub_journal_equiv <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    legend.position = "top",
    plot.title = element_text(size = 12, face = "bold"),
    plot.subtitle = element_text(size = 9.5, colour = "grey30"),
    plot.margin = margin(10, 10, 10, 10),
    axis.title = element_text(face = "plain")
  )

# ---------------------------------------------------------------------------------------------
# 3. Panel (a): common-cells composite %RMSE by model, both NS treatments, 95% bootstrap CI
# ---------------------------------------------------------------------------------------------
plot_rows <- results_dt[comparison == "common_cells"]
plot_rows[, model_label := factor(model, levels = c("base", "v1211", "osm"),
                                   labels = names(model_colors))]
plot_rows[, ns_label := factor(
  ns_treatment, levels = c("NS", "NS-long"),
  labels = c(sprintf("NS treatment\n(overall)\n7 source-clusters, n=%s-%s stands",
                      comma(min(plot_rows[ns_treatment == "NS", n_stands])),
                      comma(max(plot_rows[ns_treatment == "NS", n_stands]))),
             sprintf("NS-long treatment\n(all-consecutive-pairs)\n7 source-clusters, n=%s-%s stands",
                      comma(min(plot_rows[ns_treatment == "NS-long", n_stands])),
                      comma(max(plot_rows[ns_treatment == "NS-long", n_stands])))))]

p1 <- ggplot(plot_rows, aes(x = ns_label, y = rmse, fill = model_label)) +
  geom_col(position = position_dodge(width = 0.75), width = 0.7) +
  geom_errorbar(aes(ymin = rmse_lo, ymax = rmse_hi),
                position = position_dodge(width = 0.75), width = 0.2, linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.1f", rmse), y = rmse + 4),
            position = position_dodge(width = 0.75), size = 2.9, vjust = 0) +
  scale_fill_manual(values = model_colors, name = NULL) +
  labs(x = NULL, y = "Stand-years-weighted composite TOTVOL %RMSE",
       title = "(a) Common-cells composite %RMSE by model",
       subtitle = "7 shared sources; error bars = 95% bootstrap percentile CI") +
  theme_pub_journal_equiv

# ---------------------------------------------------------------------------------------------
# 4. Panel (b): stand-years weight per source (NS treatment), n and interval annotated per bar
# ---------------------------------------------------------------------------------------------
d_ns <- detail_dt[ns_treatment == "NS"]
d_ns[, is_maine := grepl("Maine|Baxter|PEF|SILC|CFRU|CTRN", dataset, ignore.case = TRUE)]
d_ns <- d_ns[order(weight_v1211)]
d_ns[, dataset := factor(dataset, levels = dataset)]
d_ns[, bar_label := sprintf("n=%s, %.1f yr", comma(n_v1211), interval_years)]

maine_pct <- d_ns[is_maine == TRUE, sum(weight_v1211)] / d_ns[, sum(weight_v1211)]

p2 <- ggplot(d_ns, aes(x = weight_v1211, y = dataset, fill = is_maine)) +
  geom_col() +
  geom_text(aes(label = bar_label), hjust = -0.05, size = 2.9) +
  scale_fill_manual(values = c(`TRUE` = TEAL, `FALSE` = SALMON), guide = "none") +
  scale_x_continuous(expand = expansion(mult = c(0, 0.35)), labels = comma) +
  labs(x = expression(Stand-years~(n%*%interval[years])*", v12.11 weight basis"), y = NULL,
       title = "(b) Stand-years weight per source",
       subtitle = "NS treatment; n and interval annotated per bar") +
  annotate("text", x = max(d_ns$weight_v1211) * 0.98,
           y = 1.4, label = sprintf("Maine sources = %s of total stand-years weight",
                                     percent(maine_pct, accuracy = 1)),
           hjust = 1, size = 3, fontface = "italic") +
  theme_pub_journal_equiv +
  theme(legend.position = "none")

# manual legend proxy for the Maine / non-Maine split (since scale_fill guide is off above)
legend_df <- data.table(x = 1, y = c("Maine source", "NB / QC / NS source"),
                         col = c(TEAL, SALMON))

# ---------------------------------------------------------------------------------------------
# 5. Assemble, title, and below-figure caption (journal register: bold label, upright sentence)
# ---------------------------------------------------------------------------------------------
n_common_ns <- plot_rows[ns_treatment == "NS", sum(unique(n_stands))]

caption_text <- paste0(
  "Common-cells composite total-volume percent RMSE (panel a) pools seven benchmark sources ",
  "shared by all three models, weighted by stand-years of observation (n × remeasurement ",
  "interval in years); panel b shows the stand-years weight each source contributes under the ",
  "NS treatment, with each source's n and interval in years labeled directly on its bar. Error ",
  "bars are 95% bootstrap percentile intervals from a source-level cluster resample (resampling ",
  "unit = benchmark source, not plot), n = 2,000 resamples, seed 20260811; the common-cells ",
  "comparison in panel a resamples 7 source-clusters in both scenarios shown, rising to 9 in the ",
  "fuller v12.11-only composite reported in the text but not plotted here, which is coarser than ",
  "a plot-level bootstrap and widens the intervals accordingly. Total n across the seven ",
  "common-cells sources is 9,880 stands (NS treatment) / 10,724 stands (NS-long treatment), ",
  "summing to roughly 89,000 and 113,000 stand-years respectively. Data: ",
  "figures/_data/composite_score_weighted.csv. Source write-up: 20260811_weighted_composite_score.md."
)

fig21 <- (p1 | p2) +
  plot_annotation(
    title = "Figure 21. Stand-years-weighted composite benchmark score, FVS-ACD v12.11 vs OSM-ACD v2.26.1 vs base v12.10.1",
    caption = caption_text,
    theme = theme(
      plot.title = element_text(size = 13, face = "bold", hjust = 0),
      plot.caption = element_text(size = 8, hjust = 0, colour = "black", lineheight = 1.15),
      plot.caption.position = "plot"
    )
  )

ggsave(OUT_PNG, fig21, width = 14, height = 8.2, dpi = 300, bg = "white")
cat(sprintf("Wrote %s\n", OUT_PNG))

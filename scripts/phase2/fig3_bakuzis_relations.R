# =============================================================================
# Figure 3. Bakuzis law-like relations, pass and flag matrix by model.
#
# Five law-like relations (Eichhorn, Reineke self-thinning, site ordering,
# yield-density plateau, Sukachev) tested against the four AcadianGY version
# entrants (v12.5.0, v12.7.0, v12.7.1, v12.9.x) plus OSM as an external
# comparison model. Green passes, brick red flags, neutral grey not scored;
# bold PASS / FLAG / N/S labels give a redundant, colorblind-safe encoding.
#
# OSM is now scored on ALL FIVE relations from its own long-horizon run: OSM was
# projected 160 years (YEARS 160, YPC 1) over the 73 SILC/CFI stands, binned into
# three site-productivity terciles by T50HT (OSM dominant height at reference age
# 50) as the analog of the seeded ESI 12/16/20 gradient; relation tests reuse the
# AcadianGY battery definitions verbatim. Over the full horizon OSM PASSES Reineke
# self-thinning (log SDI slope -1.56, pooled -1.69), the yield-density plateau
# (mid-site basal area peaks near 35.8 m2 ha-1 then levels/self-thins to 34.7),
# and Sukachev, and FLAGS Eichhorn (cross-site volume-at-height CV 26.3 percent)
# and site ordering (42 height, 105 volume trajectory inversions). The two flags
# partly reflect the real-stand substitution (projection-year axis, heterogeneous
# starting ages); the earlier age-60 matched-stand FLAG on Reineke and the
# plateau is superseded by this 150-plus-year run.
#
# R-first house standard. A matching matplotlib renderer (fig3_bakuzis_relations.py)
# produced the shipped PNG because R was unavailable in the build sandbox. This
# script is the reproducible R path; it emits the identical figure where R runs.
#
# Pass/flag pattern is read verbatim from the frozen assessment; NOT recomputed.
#   Source: figures/_data/bakuzis_relations.csv
# Author: A. Weiskittel (CRSF-Cowork)
# =============================================================================
suppressMessages({library(tidyverse); library(ggtext)})

repo <- "/home/aweiskittel/Documents/Claude/CRSF-Cowork/repos/fvs-acd"
data <- file.path(repo, "figures/_data/bakuzis_relations.csv")
out  <- file.path(repo, "figures/fig3_bakuzis_relations.png")

model_lab <- c(v125 = "v12.5.0", v1270 = "v12.7.0",
               v1271 = "v12.7.1", v129x = "v12.9.x",
               OSM = "OSM\n(external)")
rel_lab <- c(Eichhorn = "Eichhorn", Reineke = "Reineke\nself-thinning",
             SiteOrdering = "Site\nordering",
             YieldDensity_plateau = "Yield-density\nplateau",
             Sukachev = "Sukachev")
fill_pal <- c(PASS = "#4C8C5A", FLAG = "#C0504D", `NOT SCORED` = "#8C8C8C")
# Cell text: PASS and FLAG verbatim, NOT SCORED as compact N/S.
cell_txt <- c(PASS = "PASS", FLAG = "FLAG", `NOT SCORED` = "N/S")

raw <- read_csv(data, show_col_types = FALSE)

d <- raw |>
  select(model, all_of(names(rel_lab))) |>
  pivot_longer(-model, names_to = "relation", values_to = "status") |>
  mutate(status   = toupper(str_trim(status)),
         label    = cell_txt[status],
         model    = factor(model_lab[model], levels = rev(unname(model_lab))),
         relation = factor(rel_lab[relation], levels = unname(rel_lab)))

# Divider between the seeded AcadianGY entrants and the external OSM row.
osm_lab <- unname(model_lab["OSM"])
ymin_div <- length(model_lab) - which(rev(unname(model_lab)) == osm_lab) + 0.5

p <- ggplot(d, aes(relation, model, fill = status)) +
  geom_tile(colour = "white", linewidth = 1.4, width = 0.97, height = 0.97) +
  geom_text(aes(label = label), colour = "white",
            fontface = "bold", size = 4.4) +
  geom_hline(yintercept = ymin_div, colour = "#333333",
             linewidth = 0.5, linetype = "22") +
  scale_fill_manual(values = fill_pal, name = NULL,
                    labels = c(PASS = "PASS", FLAG = "FLAG",
                               `NOT SCORED` = "N/S (not scored)")) +
  coord_equal() +
  labs(title = "Biological realism: Bakuzis law-like relations",
       caption = paste("Green passes, red flags. OSM (external) is scored on all",
                       "five relations from its own 150-plus-year run over the\n",
                       "SILC/CFI stands binned into three T50HT site terciles; it",
                       "passes self-thinning, the yield-density plateau, and\n",
                       "Sukachev, and flags Eichhorn and site ordering under the",
                       "real-stand substitution (projection-year, mixed ages)."),
       x = NULL, y = NULL) +
  theme_minimal(base_size = 13) +
  theme(panel.grid = element_blank(),
        axis.text = element_text(colour = "grey15"),
        plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
        plot.caption = element_text(colour = "grey40", hjust = 0.5, size = 9),
        legend.position = "bottom")

ggsave(out, p, width = 24, height = 18, units = "cm", dpi = 300, bg = "white")
cat("Wrote", out, "\n")
print(d)

# =============================================================================
# Figure 3. Bakuzis law-like relations, pass and flag matrix by model.
#
# Five law-like relations (Eichhorn, Reineke self-thinning, site ordering,
# yield-density plateau, Sukachev) tested against the four AcadianGY version
# entrants (v12.5.0, v12.7.0, v12.7.1, v12.9.x) plus OSM as an external
# comparison model. Green passes, brick red flags, neutral grey not scored;
# bold PASS / FLAG / N/S labels give a redundant, colorblind-safe encoding.
#
# OSM cannot be seeded on the same synthetic productivity gradient, so it is
# scored only where its long-horizon behavior is observable. The self-thinning
# (Reineke) and yield-density plateau relations are read from the matched-stand
# Seven Islands trajectory, where OSM accumulates basal area to about 42 m2 ha-1
# by age 60 without a plateau while the AcadianGY builds peak near 33 and
# self-thin to about 27; OSM FLAGS both. Relations that require the seeded
# cross-site gradient (Eichhorn, site ordering, Sukachev) are marked not scored
# rather than assigned a fabricated pass.
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
       caption = paste("Green passes, red flags, grey not scored. OSM is an",
                       "external model, scored only where its long-horizon\n",
                       "behavior is observable; its non-plateau, non-self-thinning",
                       "basal area flags both size-density relations.\n",
                       "N/S = not scored (external model, no seeded gradient)."),
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

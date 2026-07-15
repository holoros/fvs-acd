# =============================================================================
# Figure 3. Bakuzis law-like relations, pass and flag matrix by model.
#
# Five law-like relations (Eichhorn, Reineke self-thinning, site ordering,
# yield-density plateau, Sukachev) tested against the four version entrants
# (v12.5.0, v12.7.0, v12.7.1, v12.9.x). Green passes, brick red flags; bold
# PASS / FLAG labels give a redundant, colorblind-safe encoding.
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
               v1271 = "v12.7.1", v129x = "v12.9.x")
rel_lab <- c(Eichhorn = "Eichhorn", Reineke = "Reineke\nself-thinning",
             SiteOrdering = "Site\nordering",
             YieldDensity_plateau = "Yield-density\nplateau",
             Sukachev = "Sukachev")
fill_pal <- c(PASS = "#4C8C5A", FLAG = "#C0504D")

raw <- read_csv(data, show_col_types = FALSE)

d <- raw |>
  select(model, all_of(names(rel_lab))) |>
  pivot_longer(-model, names_to = "relation", values_to = "status") |>
  mutate(status   = toupper(str_trim(status)),
         model    = factor(model_lab[model], levels = rev(unname(model_lab))),
         relation = factor(rel_lab[relation], levels = unname(rel_lab)))

p <- ggplot(d, aes(relation, model, fill = status)) +
  geom_tile(colour = "white", linewidth = 1.4, width = 0.97, height = 0.97) +
  geom_text(aes(label = status), colour = "white",
            fontface = "bold", size = 4.4) +
  scale_fill_manual(values = fill_pal, name = NULL) +
  coord_equal() +
  labs(title = "Biological realism: Bakuzis law-like relations",
       caption = paste("Green passes, red flags. Reineke self-thinning slope",
                       "and the yield-density plateau separate the models."),
       x = NULL, y = NULL) +
  theme_minimal(base_size = 13) +
  theme(panel.grid = element_blank(),
        axis.text = element_text(colour = "grey15"),
        plot.title = element_text(face = "bold", hjust = 0.5, size = 15),
        plot.caption = element_text(colour = "grey40", hjust = 0.5, size = 10),
        legend.position = "bottom")

ggsave(out, p, width = 24, height = 16, units = "cm", dpi = 300, bg = "white")
cat("Wrote", out, "\n")
print(d)

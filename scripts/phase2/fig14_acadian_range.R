## Figure 14. Geographic range of the FVS-ACD (Acadian) variant.
##
## A region / applicability map (not a plot-point map). It shows the Acadian
## Forest region of the northeastern United States and Maritime Canada, the
## area over which the FVS-ACD (Acadian) variant applies. No individual stands
## and NO FIA true plot coordinates are plotted: the independent benchmark
## (705 remeasured MagPlot stands, New Brunswick and Quebec) is indicated only
## by a text note, never by point locations.
##
## Boundary source: Natural Earth 1:50m admin-1 states/provinces bundled in the
## rnaturalearthdata package (states50), plus 1:50m country outlines. All data
## are public generalized administrative boundaries; nothing is restricted.
##
## Run on OSC Cardinal (account PUOM0008):
##   module load gcc/12.3.0 R/4.4.0 gdal/3.7.3 geos/3.12.0 proj/9.2.1
##   Rscript fig14_acadian_range.R
suppressMessages({
  library(sf); library(ggplot2); library(rnaturalearth); library(rnaturalearthdata)
  library(ggspatial); library(dplyr)
})
sf_use_s2(FALSE)

outd <- "/users/PUOM0008/crsfaaron/magplot/verify/data_maps"
dir.create(outd, showWarnings = FALSE, recursive = TRUE)

## ---- CRS: a Lambert conformal conic centred on the Maritimes ----
lcc <- paste("+proj=lcc +lat_1=44 +lat_2=48 +lat_0=46 +lon_0=-65",
             "+x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs")

## ---- admin-1 boundaries (states + provinces), clipped to a working window ----
prov <- st_as_sf(rnaturalearthdata::states50)
prov <- prov[prov$admin %in% c("Canada", "United States of America"), ]
win  <- st_as_sfc(st_bbox(c(xmin = -76, ymin = 41, xmax = -56, ymax = 51),
                          crs = st_crs(4326)))
prov <- suppressWarnings(st_crop(prov, win))

## national land outline for a clean coast backstop
land <- ne_countries(scale = "medium",
        country = c("Canada", "United States of America"), returnclass = "sf")
land <- suppressWarnings(st_crop(land, win))

## ---- define the FVS-ACD applicability area (Acadian Forest region) ----
## Core: Maine, New Brunswick, Nova Scotia, Prince Edward Island (full).
## Plus southern Quebec (Estrie, Chaudiere-Appalaches, Bas-Saint-Laurent,
## Gaspesie), taken as the Quebec area south of about 48.6 N.
core_names <- c("Maine", "New Brunswick", "Nova Scotia", "Prince Edward Island")
core <- prov[prov$name %in% core_names, ]

qc <- prov[grepl("^Qu", prov$name), ]
qc_clip <- st_as_sfc(st_bbox(c(xmin = -72, ymin = 44.5, xmax = -63, ymax = 48.6),
                             crs = st_crs(4326)))
qc_south <- suppressWarnings(st_intersection(qc, qc_clip))

applic <- dplyr::bind_rows(
  dplyr::transmute(core, geometry = geometry),
  dplyr::transmute(qc_south, geometry = geometry)
)

## ---- project everything to the LCC ----
prov_p     <- st_transform(prov, lcc)
land_p     <- st_transform(land, lcc)
applic_p   <- st_transform(applic, lcc)

## ---- plotting window ----
frame <- st_as_sfc(st_bbox(c(xmin = -73.5, ymin = 43.0, xmax = -58.5, ymax = 49.4),
                           crs = st_crs(4326))) |> st_transform(lcc)
fb <- st_bbox(frame)
xlim <- c(fb["xmin"], fb["xmax"]); ylim <- c(fb["ymin"], fb["ymax"])

## ---- labels (land and water) ----
land_labs <- st_as_sf(data.frame(
  name = c("Maine", "New Brunswick", "Nova Scotia",
           "Prince Edward Island", "Quebec", "Vermont", "New Hampshire"),
  lon  = c(-69.2, -66.3, -62.9, -63.9, -70.7, -72.7, -71.5),
  lat  = c(45.3,  46.5,  45.0,  47.0,  47.9,  44.0,  43.9)),
  coords = c("lon", "lat"), crs = 4326) |> st_transform(lcc)
land_xy <- cbind(st_drop_geometry(land_labs), st_coordinates(land_labs))

water_labs <- st_as_sf(data.frame(
  name = c("Gulf of St. Lawrence", "Atlantic Ocean"),
  lon  = c(-61.6, -62.6),
  lat  = c(48.2,  43.4)),
  coords = c("lon", "lat"), crs = 4326) |> st_transform(lcc)
water_xy <- cbind(st_drop_geometry(water_labs), st_coordinates(water_labs))

## PEI leader dot (island is small; anchor the label with a marker)
pei_pt <- st_as_sf(data.frame(lon = -63.2, lat = 46.4),
                   coords = c("lon", "lat"), crs = 4326) |> st_transform(lcc)
pei_xy <- st_coordinates(pei_pt)

## ---- CRSF-compatible green ramp (colourblind safe: single-hue green + grey) ----
green_fill <- "#4e8060"   # lighter tint of the CRSF primary #1a3d28
green_line <- "#1a3d28"   # CRSF primary, used for the applicability keyline
land_fill  <- "#e7e6e1"   # muted neutral for surrounding context land
water_fill <- "#d8e7ee"   # subtle water

theme_map <- theme_minimal(base_size = 12) +
  theme(panel.grid = element_line(color = "grey85", linewidth = 0.25),
        panel.background = element_rect(fill = water_fill, color = NA),
        panel.border = element_rect(color = "grey55", fill = NA, linewidth = 0.5),
        plot.title = element_text(face = "bold", size = 14),
        plot.subtitle = element_text(size = 11, color = "grey25"),
        plot.caption = element_text(size = 9, color = "grey35", hjust = 0),
        legend.position = c(0.015, 0.015),
        legend.justification = c(0, 0),
        legend.background = element_rect(fill = "white", color = "grey70",
                                         linewidth = 0.3),
        legend.margin = margin(6, 8, 6, 8),
        legend.title = element_text(face = "bold", size = 10),
        legend.text = element_text(size = 9.5),
        axis.title = element_blank(),
        axis.text = element_text(size = 8, color = "grey40"))

p <- ggplot() +
  ## base land + context provinces/states
  geom_sf(data = land_p, fill = land_fill, color = NA) +
  geom_sf(data = prov_p, fill = land_fill, color = "grey70", linewidth = 0.3) +
  ## applicability area
  geom_sf(data = applic_p, aes(fill = "Acadian Forest region\n(FVS-ACD applicability)"),
          color = green_line, linewidth = 0.45, alpha = 0.92) +
  scale_fill_manual(name = NULL, values = green_fill) +
  ## PEI marker
  annotate("point", x = pei_xy[1], y = pei_xy[2], color = green_line,
           size = 1.1) +
  ## water labels
  geom_text(data = water_xy, aes(X, Y, label = name), fontface = "italic",
            color = "#4a7c94", size = 3.1) +
  ## land labels
  geom_text(data = subset(land_xy, name != "Prince Edward Island"),
            aes(X, Y, label = name), color = "grey15", size = 3.5,
            fontface = "bold") +
  geom_text(data = subset(land_xy, name == "Prince Edward Island"),
            aes(X, Y, label = name), color = "grey15", size = 3.0,
            fontface = "bold") +
  ## benchmark note (no stands plotted; a text indication only), stacked above
  ## the scale bar in the bottom-right corner
  annotate("label", x = xlim[1] + 0.985 * diff(xlim),
           y = ylim[1] + 0.115 * diff(ylim),
           hjust = 1, vjust = 0, size = 3.05,
           color = "grey15", fill = "white", label.r = unit(2, "pt"),
           label = paste0("Independent benchmark within region:\n",
                          "705 remeasured stands\n",
                          "(New Brunswick 355, Quebec 350)")) +
  annotation_scale(location = "br", width_hint = 0.26, text_cex = 0.7,
                   pad_y = unit(0.2, "cm")) +
  annotation_north_arrow(location = "tr", which_north = "true",
     height = unit(1.05, "cm"), width = unit(1.05, "cm"),
     pad_x = unit(0.25, "cm"), pad_y = unit(0.25, "cm"),
     style = north_arrow_fancy_orienteering()) +
  coord_sf(xlim = xlim, ylim = ylim, expand = FALSE, crs = lcc) +
  labs(title = "Figure 14. Geographic range of the FVS-ACD (Acadian) variant",
       subtitle = paste("Acadian Forest region of the northeastern United",
                        "States and Maritime Canada"),
       caption = paste("Lambert conformal conic projection (standard parallels",
                       "44 and 48 N). Boundaries: Natural Earth 1:50m.")) +
  theme_map

ggsave(file.path(outd, "fig14_acadian_range.png"), p,
       width = 9.5, height = 7.6, dpi = 300, bg = "white")
ggsave(file.path(outd, "fig14_thumb.png"), p,
       width = 5.3, height = 4.2, dpi = 72, bg = "white")

cat("applicability polygons:", nrow(applic_p), "\n")
cat("FIG14 DONE:", file.path(outd, "fig14_acadian_range.png"), "\n")

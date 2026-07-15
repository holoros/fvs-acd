## Data-description maps for the FVS-ACD benchmark (705 remeasured stands).
## PRIVACY: true plot coordinates are used ONLY to build a 50 km equal-area hex
## count grid on Cardinal. No coordinate leaves this script; released objects
## (gpkg, csv, png) contain hex polygons and counts only. True coordinates never
## leave the server.
suppressMessages({
  library(data.table); library(sf); library(dplyr); library(ggplot2)
  library(rnaturalearth); library(ggspatial)
})
sf_use_s2(FALSE)
base <- "/users/PUOM0008/crsfaaron/magplot"
outd <- file.path(base, "verify/data_maps"); dir.create(outd, showWarnings=FALSE, recursive=TRUE)

## ---- join benchmark to true coords (stays on Cardinal) ----
W <- readRDS(file.path(base, "verify/frozen_subsidiary_W.rds"))
setDT(W); W[, sid := sub("^([0-9]+).*$","\\1", STAND)]
s1 <- fread(file.path(base,"magp_sites.csv")); s2 <- fread(file.path(base,"magp_sites_nb_ns.csv"))
setnames(s1, tolower(names(s1))); setnames(s2, tolower(names(s2)))
cols <- c("magp_site_id","province","latitude","longitude")
sites <- unique(rbindlist(list(s1[,..cols], s2[,..cols])))
sites[, magp_site_id := as.character(magp_site_id)]
m <- merge(W[,.(sid,PROV,fortype)], sites, by.x="sid", by.y="magp_site_id", all.x=TRUE)
stopifnot(sum(is.na(m$latitude))==0)

## equal-area CRS centered on the Acadian region
laea <- "+proj=laea +lat_0=46.5 +lon_0=-68 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs"
pts <- st_as_sf(m, coords=c("longitude","latitude"), crs=4326) |> st_transform(laea)

## ---- 50 km equal-area hex grid, count stands per hex ----
hexsz <- 50000
grd <- st_make_grid(st_as_sfc(st_bbox(st_buffer(pts, hexsz))), cellsize=hexsz, square=FALSE)
hex <- st_sf(hex_id = seq_along(grd), geometry = grd)
ji  <- st_join(pts, hex, join=st_within)
jt  <- as.data.table(st_drop_geometry(ji))
tot <- jt[, .(n = .N), by=hex_id]
byft<- jt[fortype %in% c("Softwood","Mixedwood","Hardwood"),
          .(n = .N), by=.(hex_id, fortype)]
hex_tot <- merge(hex, tot, by="hex_id")            # count>0 hexes only
hex_ft  <- merge(hex, byft, by="hex_id")
## PRIVACY ASSERT: no coordinate columns in released objects
stopifnot(!any(c("latitude","longitude") %in% names(hex_tot)))
stopifnot(!any(c("latitude","longitude") %in% names(hex_ft)))

st_write(hex_tot, file.path(outd,"hex_counts_50km.gpkg"), delete_dsn=TRUE, quiet=TRUE)
st_write(hex_ft,  file.path(outd,"hex_counts_by_fortype_50km.gpkg"), delete_dsn=TRUE, quiet=TRUE)
fwrite(m[, .(n=.N), by=PROV][order(PROV)], file.path(outd,"stand_counts_by_province.csv"))
fwrite(m[, .(n=.N), by=fortype][order(-n)], file.path(outd,"stand_counts_by_fortype.csv"))
fwrite(m[, .(n=.N), by=.(PROV,fortype)][order(PROV,-n)], file.path(outd,"stand_counts_prov_x_fortype.csv"))
cat("n hex (tot):", nrow(hex_tot), " total stands:", sum(hex_tot$n), "\n")
cat("hex count range:", range(hex_tot$n), " median:", median(hex_tot$n), "\n")

## ---- basemap context (country outlines + Maine, NH, VT) ----
na <- ne_countries(scale="medium",
        country=c("Canada","United States of America"), returnclass="sf") |>
        st_transform(laea)
me <- st_read("/fs/scratch/PUOM0008/crsfaaron/FIA/asym_agb_analysis/environmental_data/boundaries/cb_2023_us_state_20m.shp", quiet=TRUE)
me <- me[me$NAME %in% c("Maine","New Hampshire","Vermont"),] |> st_transform(laea)
maine <- me[me$NAME=="Maine",]

## plotting window from the data extent, padded
bb <- st_bbox(st_buffer(hex_tot, 55000))
xlim <- c(bb["xmin"], bb["xmax"]); ylim <- c(bb["ymin"], bb["ymax"])

## province / state labels (nudged inside the frame)
labs <- st_as_sf(data.frame(
  name=c("Quebec","New Brunswick","Nova Scotia","Maine"),
  lon =c(-70.4, -66.4, -63.9, -69.3),
  lat =c(47.9,  46.7,  45.2,  45.3)),
  coords=c("lon","lat"), crs=4326) |> st_transform(laea)
labs_xy <- cbind(st_drop_geometry(labs), st_coordinates(labs))

theme_map <- theme_minimal(base_size=11) +
  theme(panel.grid=element_line(color="grey92", linewidth=0.3),
        panel.background=element_rect(fill="#EAF1F5", color=NA),
        plot.title=element_text(face="bold", size=13),
        plot.subtitle=element_text(size=10, color="grey30"),
        plot.margin=margin(8, 14, 8, 8),
        legend.position="right",
        axis.title=element_blank())

## ---- FIG 12: locator with stand-count hex choropleth ----
f12 <- ggplot() +
  geom_sf(data=na, fill="grey96", color="grey70", linewidth=0.3) +
  geom_sf(data=maine, fill="grey92", color="grey65", linewidth=0.35) +
  geom_sf(data=hex_tot, aes(fill=n), color="white", linewidth=0.15) +
  scale_fill_viridis_c(option="mako", direction=-1, name="Stands\nper hex",
                       breaks=scales::pretty_breaks(5)) +
  geom_text(data=labs_xy, aes(X, Y, label=name), fontface="italic",
            color="grey25", size=3.2) +
  annotation_scale(location="bl", width_hint=0.28, text_cex=0.7) +
  annotation_north_arrow(location="tr", which_north="true",
     height=unit(0.9,"cm"), width=unit(0.9,"cm"),
     style=north_arrow_minimal()) +
  coord_sf(xlim=xlim, ylim=ylim, expand=FALSE, crs=laea) +
  labs(title="FVS-ACD benchmark: Acadian study region",
       subtitle="705 remeasured stands; 50 km equal-area hex counts") +
  theme_map
ggsave(file.path(outd,"fig12_data_locator.png"), f12, width=9.0, height=7.2, dpi=300, bg="white")
ggsave(file.path(outd,"fig12_thumb.png"), f12, width=5.4, height=4.3, dpi=72, bg="white")

## ---- FIG 13: forest type small multiples ----
hex_ft$fortype <- factor(hex_ft$fortype, levels=c("Softwood","Mixedwood","Hardwood"))
strip_cols <- c(Softwood="#2E5E3A", Mixedwood="#4E8060", Hardwood="#8A6D3B")
f13 <- ggplot() +
  geom_sf(data=na, fill="grey96", color="grey70", linewidth=0.25) +
  geom_sf(data=maine, fill="grey92", color="grey65", linewidth=0.3) +
  geom_sf(data=hex_ft, aes(fill=n), color="white", linewidth=0.12) +
  scale_fill_viridis_c(option="mako", direction=-1, name="Stands\nper hex",
                       breaks=scales::pretty_breaks(4)) +
  coord_sf(xlim=xlim, ylim=ylim, expand=FALSE, crs=laea) +
  facet_wrap(~fortype, nrow=1) +
  annotation_scale(location="bl", width_hint=0.30, text_cex=0.6) +
  labs(title="Benchmark stand distribution by forest type",
       subtitle="50 km equal-area hex counts (softwood, mixedwood, hardwood)") +
  theme_map +
  theme(strip.text=element_text(face="bold", size=11, color="white"),
        strip.background=element_rect(fill="#2E5E3A", color=NA),
        axis.text=element_text(size=6))
ggsave(file.path(outd,"fig13_data_by_fortype.png"), f13, width=12.5, height=5.4, dpi=300, bg="white")
ggsave(file.path(outd,"fig13_thumb.png"), f13, width=7.0, height=3.0, dpi=72, bg="white")

cat("FIGS DONE\n")

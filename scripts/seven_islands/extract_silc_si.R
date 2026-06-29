suppressPackageStartupMessages(library(terra))
SI <- "/users/PUOM0008/crsfaaron/SiteIndex"
co <- read.csv("~/silc_cfi/silc_plot_coords.csv", stringsAsFactors=FALSE)
co <- co[!duplicated(co$PLOT) & is.finite(co$LAT) & is.finite(co$LON), ]
cat("unique plots with coords:", nrow(co), "\n")
pts <- vect(co, geom=c("LON","LAT"), crs="EPSG:4326")
legacy <- rast(file.path(SI,"ClimateNA_SI_m.tif"))[[1]]
esi    <- rast(file.path(SI,"Final_SI_Output.tif"))[[1]]
co$legacyCSI <- terra::extract(legacy, project(pts, crs(legacy)))[[2]]
co$ESI       <- terra::extract(esi,    project(pts, crs(esi)))[[2]]
cat("legacyCSI NA:", sum(is.na(co$legacyCSI)), " ESI NA:", sum(is.na(co$ESI)), "\n")
cat("legacyCSI range:", round(range(co$legacyCSI,na.rm=TRUE),2), " mean", round(mean(co$legacyCSI,na.rm=TRUE),2),"\n")
cat("ESI range:", round(range(co$ESI,na.rm=TRUE),2), " mean", round(mean(co$ESI,na.rm=TRUE),2),"\n")
write.csv(co[,c("PLOT","LAT","LON","COORD_UNC_KM","legacyCSI","ESI")], "~/silc_cfi/silc_plot_si.csv", row.names=FALSE)
cat("wrote silc_plot_si.csv\n")

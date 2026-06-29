# Resummarize the brms plot-level SDImax (metric) for the Acadian region
# (northern New England: ME, NH, VT) by ecoregion (L3), FIA forest-type group,
# and CSI / ESI quartile. Compares to FIA's own SDIMAX_RMRS and to the current
# AcadianGY (Weiskittel & Kuehne 2019) SDImax range. Use median (robust).
suppressPackageStartupMessages({ library(data.table); library(terra) })
FIA <- "/users/PUOM0008/crsfaaron/fia_data"; SI <- "/users/PUOM0008/crsfaaron/SiteIndex"
ACL <- "/users/PUOM0008/crsfaaron/SiteIndex/acd_clim"; ECO <- "/users/PUOM0008/crsfaaron/SiteIndex/NA_Eco_L3_WGS84.shp"
OUT <- "/users/PUOM0008/crsfaaron/acadgy_fia_verify"; STATES <- c(23,33,50)

br <- fread(file.path(OUT,"brms.SDImax.1-27-24.csv"))
br <- br[STATECD %in% STATES & is.finite(SDImax.median) & SDImax.median>50 & SDImax.median<3000]
br[, pkey := paste(STATECD,UNITCD,COUNTYCD,PLOT, sep="-")]
cat("brms plots (ME/NH/VT, trimmed):", nrow(br), "\n")

pl <- rbindlist(lapply(c("ME","NH","VT"), function(s)
  fread(file.path(FIA, paste0(s,"_PLOT.csv")), select=c("CN","STATECD","UNITCD","COUNTYCD","PLOT","LAT","LON","INVYR"))), fill=TRUE)
pl[, pkey := paste(STATECD,UNITCD,COUNTYCD,PLOT, sep="-")][, CN:=as.character(CN)]
setorder(pl, pkey, -INVYR); plU <- pl[, .SD[1], by=pkey]
d <- merge(br, plU[, .(pkey,CN,LAT,LON)], by="pkey")
cd <- rbindlist(lapply(c("ME","NH","VT"), function(s)
  fread(file.path(FIA, paste0(s,"_COND.csv")), select=c("PLT_CN","FORTYPCD","BALIVE","SDIMAX_RMRS")) ), fill=TRUE)
cd[, PLT_CN:=as.character(PLT_CN)]
cd <- cd[is.finite(BALIVE)]; setorder(cd, PLT_CN, -BALIVE); cdU <- cd[, .SD[1], by=PLT_CN]
d <- merge(d, cdU, by.x="CN", by.y="PLT_CN", all.x=TRUE)
d <- d[is.finite(LAT)&is.finite(LON)]
cat("joined to coords + cond:", nrow(d), "\n")

## spatial extracts
pts <- vect(as.data.frame(d[, .(LON,LAT)]), geom=c("LON","LAT"), crs="EPSG:4326")
eco <- vect(ECO); enm <- grep("NA_L3NAME|US_L3NAME|L3NAME", names(eco), value=TRUE, ignore.case=TRUE)
ecocol <- if(length(enm)) enm[1] else grep("L3", names(eco), value=TRUE)[1]
d[, eco := terra::extract(eco[,ecocol], project(pts, crs(eco)))[[2]]]
d[, ESI := terra::extract(rast(file.path(SI,"Final_SI_Output.tif"))[[1]], project(pts, crs(rast(file.path(SI,"Final_SI_Output.tif")))))[[2]]]
d[, CSI := terra::extract(rast(file.path(SI,"ClimateNA_SI_m.tif"))[[1]], project(pts, crs(rast(file.path(SI,"ClimateNA_SI_m.tif")))))[[2]]]
d[, CSI2030 := terra::extract(rast(file.path(ACL,"AcadianSIm_2030.tif"))[[1]], project(pts, crs(rast(file.path(ACL,"AcadianSIm_2030.tif")))))[[2]]]

## forest-type group (FIA FORTYPCD)
d[, ftgrp := fcase(
  FORTYPCD %in% 121:129, "Spruce-fir",
  FORTYPCD %in% 101:105, "Pine",
  FORTYPCD %in% 381:384, "Other softwood",
  FORTYPCD %in% 401:409, "Oak-pine",
  FORTYPCD %in% 501:599, "Oak-hickory",
  FORTYPCD %in% 700:799, "Elm-ash-cottonwood",
  FORTYPCD %in% 801:809, "Northern hardwood",
  FORTYPCD %in% 901:909, "Aspen-birch",
  default = "Other/nonstocked")]
qbin <- function(x){ q<-quantile(x, c(0,.25,.5,.75,1), na.rm=TRUE); cut(x, unique(q), include.lowest=TRUE) }
d[, ESIq := qbin(ESI)][, CSIq := qbin(CSI)]

smr <- function(by){ d[is.finite(SDImax.median), .(n=.N, SDImax_mean=round(mean(SDImax.median),0),
  SDImax_median=round(median(SDImax.median),0), p25=round(quantile(SDImax.median,.25),0),
  p75=round(quantile(SDImax.median,.75),0), FIA_SDImax_RMRS_med=round(median(SDIMAX_RMRS,na.rm=TRUE),0)), by=by][order(-n)] }
ovr <- d[is.finite(SDImax.median), .(n=.N, SDImax_mean=round(mean(SDImax.median),0), SDImax_median=round(median(SDImax.median),0),
  p25=round(quantile(SDImax.median,.25),0), p75=round(quantile(SDImax.median,.75),0))]
cat("\n=== OVERALL brms SDImax (metric), ME/NH/VT ===\n"); print(ovr)
cat("\n=== by FIA forest-type group ===\n"); print(smr("ftgrp"))
cat("\n=== by Level 3 ecoregion ===\n"); print(smr("eco"))
cat("\n=== by ESI quartile ===\n"); print(smr("ESIq"))
cat("\n=== by CSI quartile ===\n"); print(smr("CSIq"))
fwrite(smr("ftgrp"), file.path(OUT,"sdimax_by_fortype.csv"))
fwrite(smr("eco"), file.path(OUT,"sdimax_by_ecoregion.csv"))
fwrite(smr("ESIq"), file.path(OUT,"sdimax_by_ESIq.csv"))
fwrite(d[, .(STATECD,UNITCD,COUNTYCD,PLOT,SDImax_brms=SDImax.median,SDIMAX_RMRS,FORTYPCD,ftgrp,eco,ESI,CSI,CSI2030)], file.path(OUT,"sdimax_plot_join.csv"))
# correlation of brms vs FIA RMRS, and vs CSI/ESI
ok <- d[is.finite(SDImax.median)&is.finite(SDIMAX_RMRS)]
cat(sprintf("\nbrms vs FIA SDIMAX_RMRS: r=%.3f (n=%d); brms median %.0f vs FIA RMRS median %.0f\n",
  cor(ok$SDImax.median, ok$SDIMAX_RMRS), nrow(ok), median(ok$SDImax.median), median(ok$SDIMAX_RMRS,na.rm=TRUE)))
ce <- d[is.finite(SDImax.median)&is.finite(CSI)]; ee <- d[is.finite(SDImax.median)&is.finite(ESI)]
cat(sprintf("brms SDImax vs CSI: r=%.3f ; vs ESI: r=%.3f\n", cor(ce$SDImax.median,ce$CSI), cor(ee$SDImax.median,ee$ESI)))
cat("DONE\n")

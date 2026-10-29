## qc_esi_predict.R -- pointwise ESI prediction for QC magplot sites outside the Acadian
## raster's extent, reusing the existing trained model (acadian_v8_model.rds) rather than
## fitting anything new. Mirrors acadian_render_30m.R's predictor construction exactly.
suppressPackageStartupMessages({library(terra); library(data.table); library(ranger)})
WD <- "/fs/scratch/PUOM0008/crsfaaron/canada/qc_esi"
CNA <- "/users/PUOM0008/crsfaaron/SiteIndex/rasters/ClimateNA/Normal_1991_2020_bioclim"
MODEL <- "/fs/scratch/PUOM0008/crsfaaron/canada/acadian/acadian_v8_model.rds"
setwd(WD)

clvars <- c("mat","map","gsp","mtcm","mtwm","mmin","mmax","sday","fday","ffp","dd5","d100","dd0",
  "mmindd0","tdiff","pratio","adi","sdi","adimindd0","dd5mtcm","gspdd5","gspmtcm","gsptd","mapdd5",
  "mapmtcm","maptd","mtcmgsp","mtcmmap","tdgsp","tdmap","prdd5","prmtcm")
terr <- c("elev","slope","aspect","north","east","elev_sq")
preds <- c(clvars, terr)

sites <- fread("qc_missing_sites.csv")
cat("sites to predict:", nrow(sites), "\n")
pts <- vect(sites, geom=c("lon","lat"), crs="EPSG:4326")

## ---- terrain, per DEM tile (cheap: 1x1 deg tiles, not one giant mosaic) ----
tm <- fread("dem_tile_map.txt", header=FALSE, col.names=c("tlat","tlon","path"))
cat("DEM tiles fetched:", nrow(tm), "\n")
sites[, tlat := floor(lat)][, tlon := floor(lon)]
terr_out <- vector("list", nrow(tm))
for (i in seq_len(nrow(tm))) {
  sub <- sites[tlat == tm$tlat[i] & tlon == -tm$tlon[i]]
  if (nrow(sub) == 0) next
  g <- rast(tm$path[i]); names(g) <- "elev"
  slope <- terrain(g, "slope", unit="degrees"); aspect <- terrain(g, "aspect", unit="degrees")
  north <- cos(aspect*pi/180); east <- sin(aspect*pi/180); elev_sq <- g^2
  names(slope)<-"slope"; names(aspect)<-"aspect"; names(north)<-"north"; names(east)<-"east"; names(elev_sq)<-"elev_sq"
  stk <- c(g, slope, aspect, north, east, elev_sq)
  p <- vect(sub, geom=c("lon","lat"), crs="EPSG:4326")
  ex <- extract(stk, p)
  ex$SITE <- sub$SITE
  terr_out[[i]] <- as.data.table(ex)[, .(SITE, elev, slope, aspect, north, east, elev_sq)]
  rm(g, slope, aspect, north, east, elev_sq, stk); gc()
}
terr_dt <- rbindlist(terr_out, fill=TRUE)
cat("terrain extracted for:", nrow(terr_dt), "of", nrow(sites), "\n")

## ---- climate, extracted directly from continental ClimateNA rasters (no crop needed) ----
raw <- c("MAT","MAP","MSP","MCMT","MWMT","DD5","DD_0","DD1040","FFP","bFFP","eFFP","EMT","EXT")
cna <- rast(file.path(CNA, paste0("Normal_1991_2020_", raw, ".tif"))); names(cna) <- raw
pts_laea <- project(pts, crs(cna))
cvals <- as.data.table(extract(cna, pts_laea))
cvals$SITE <- sites$SITE
MAT<-cvals$MAT; MAP<-cvals$MAP; MSP<-cvals$MSP; MCMT<-cvals$MCMT; MWMT<-cvals$MWMT
DD5<-cvals$DD5; DD_0<-cvals$DD_0; DD1040<-cvals$DD1040; FFP<-cvals$FFP
bFFP<-cvals$bFFP; eFFP<-cvals$eFFP; EMT<-cvals$EMT; EXT<-cvals$EXT
clim_dt <- data.table(SITE=cvals$SITE,
  mat=MAT, map=MAP, gsp=MSP, mtcm=MCMT, mtwm=MWMT, mmin=EMT, mmax=EXT,
  sday=bFFP, fday=eFFP, ffp=FFP, dd5=DD5, d100=DD1040, dd0=DD_0,
  mmindd0=(EMT*DD_0)/1000, tdiff=MWMT-MCMT, pratio=MSP/MAP,
  adi=sqrt(DD5)/MAP, sdi=sqrt(DD5)/MSP, adimindd0=(sqrt(DD5)/MAP)*DD_0,
  dd5mtcm=(DD5*MCMT)/1000, gspdd5=(MSP*DD5)/1000, gspmtcm=(MSP*MCMT)/1000,
  gsptd=(MSP*(MWMT-MCMT))/100, mapdd5=(MAP*DD5)/1000, mapmtcm=(MAP*MCMT)/1000,
  maptd=(MAP*(MWMT-MCMT))/100, mtcmgsp=MCMT/MSP, mtcmmap=MCMT/MAP,
  tdgsp=(MWMT-MCMT)/MSP, tdmap=(MWMT-MCMT)/MAP, prdd5=(MSP/MAP)*DD5, prmtcm=(MSP/MAP)*MCMT)
cat("climate extracted for:", nrow(clim_dt), "of", nrow(sites), "\n")

## ---- assemble, predict ----
all_dt <- merge(clim_dt, terr_dt, by="SITE")
cat("sites with BOTH climate and terrain:", nrow(all_dt), "of", nrow(sites), "\n")
ok <- complete.cases(all_dt[, ..preds])
cat("complete predictor rows:", sum(ok), "of", nrow(all_dt), "\n")
m <- readRDS(MODEL)
pred_si <- rep(NA_real_, nrow(all_dt))
pred_si[ok] <- predict(m, as.data.frame(all_dt[ok, ..preds]))$predictions
all_dt[, esi8_pred := pred_si]
all_dt[, esi8_valid := is.finite(esi8_pred) & esi8_pred > 2 & esi8_pred < 60]
cat("valid predictions (2<SI<60):", sum(all_dt$esi8_valid, na.rm=TRUE), "of", nrow(all_dt), "\n")
fwrite(all_dt[, .(SITE, esi8_pred, esi8_valid)], "qc_esi8_predicted.csv")

## ---- merge into an updated site file, fill blanks only, never overwrite a real value ----
orig <- fread("/users/PUOM0008/crsfaaron/magplot/verify/magp_qcnb_site_esi8.csv", colClasses=c(SITE="character"))
upd <- copy(orig)
fillmap <- setNames(round(all_dt[esi8_valid==TRUE, esi8_pred], 2), all_dt[esi8_valid==TRUE, SITE])
n_filled <- 0L
for (i in seq_len(nrow(upd))) {
  if (upd$esi8[i] == "" && upd$SITE[i] %in% names(fillmap)) {
    upd$esi8[i] <- as.character(fillmap[[upd$SITE[i]]]); n_filled <- n_filled + 1L
  }
}
cat("blanks filled with predicted SI:", n_filled, "\n")
fwrite(upd, "magp_qcnb_site_esi8_v2.csv")
cat("DONE_QC_ESI_PREDICT\n")

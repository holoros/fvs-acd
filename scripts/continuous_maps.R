# Continuous interpolated bias and RMSE surfaces for AcadianGY basal-area prediction,
# 12.5.0 vs 12.7.0 vs OSM, with coastline/border boundaries. Manual inverse-distance
# interpolation (no terra/sf needed); pure base R + maps/mapdata for boundaries.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table); library(maps); library(mapdata) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
ob  <- fread("region_obs_fullmetric.csv")[,.(pid,region,BA_obs=BA)]
p127<- fread("region_pred_fullmetric.csv")[,.(pid,BA_127=BA)]
p125<- fread("region_pred_fullmetric_125.csv")[,.(pid,BA_125=BA)]
osm <- if(file.exists("region_osm_pred.csv")) fread("region_osm_pred.csv")[,.(pid,BA_osm)] else data.table(pid=character(),BA_osm=numeric())
co  <- fread("pid_coords.csv")[,.(pid,lat,long)]
d <- Reduce(function(a,b) merge(a,b,by="pid",all.x=TRUE), list(ob,p127,p125,osm,co))
d <- d[is.finite(lat)&is.finite(long)&is.finite(BA_obs)&BA_obs>0]

# fine grid over the data extent
gx <- seq(min(d$long)-0.2, max(d$long)+0.2, by=0.05)
gy <- seq(min(d$lat)-0.2,  max(d$lat)+0.2,  by=0.05)
G  <- expand.grid(long=gx, lat=gy)
asp <- 1/cos(45*pi/180)
# IDW of a per-plot value v onto the grid; radius in degrees, power p; returns NA where sparse
idw <- function(lon, lat, v, radius=0.6, p=2, minw=0.5){
  out <- numeric(nrow(G))
  for(i in seq_len(nrow(G))){
    dx <- (G$long[i]-lon); dy <- (G$lat[i]-lat)*asp
    dd <- sqrt(dx*dx+dy*dy)
    sel <- dd <= radius
    if(!any(sel)){ out[i]<-NA; next }
    w <- 1/(dd[sel]^p + 1e-6)
    if(sum(w) < minw){ out[i]<-NA; next }
    out[i] <- sum(w*v[sel])/sum(w)
  }
  matrix(out, nrow=length(gx))
}
models <- list("12.5.0 (production)"="BA_125","12.7.0 (operational)"="BA_127","OSM v2.26.1"="BA_osm")
# sequential palette for RMSE (low good = green/teal -> high = red), diverging for bias
seqcol <- colorRampPalette(c("#2c7fb8","#7fcdbb","#ffffcc","#fd8d3c","#bd0026"))(100)
divcol <- colorRampPalette(c("#2166ac","#67a9cf","#f7f7f7","#ef8a62","#b2182b"))(100)
drawbound <- function(){ map("worldHires", c("Canada","USA"), add=TRUE, col="grey25", lwd=0.8)
  map("state","maine", add=TRUE, col="grey25", lwd=0.6) }
plotsurf <- function(M, zr, cols, ttl){
  M <- matrix(as.numeric(M), nrow=length(gx), ncol=length(gy))
  image(gx,gy,M, col=cols, zlim=zr, xlab="longitude", ylab="latitude", main=ttl, asp=asp)
  drawbound() }

# ---- RMSE surfaces (local RMSE = sqrt IDW of squared residual) ----
png("acadgy_rmse_surface_3way.png", width=2400, height=1000, res=200)
par(mfrow=c(1,3), mar=c(3.2,3.2,2.4,1), mgp=c(2,0.6,0))
rlist <- list()
for(nm in names(models)){ col<-models[[nm]]; if(!col %in% names(d)) next
  dd<-d[is.finite(get(col))]; res2<-(dd[[col]]-dd$BA_obs)^2
  rlist[[nm]] <- sqrt(idw(dd$long, dd$lat, res2, radius=0.7, p=2)) }
zr <- c(0, quantile(unlist(rlist), 0.97, na.rm=TRUE))
for(nm in names(rlist)) plotsurf(rlist[[nm]], zr, seqcol, paste0(nm,"\nBA RMSE (m2/ha)"))
dev.off()
# legend strip note
cat("RMSE zr:", round(zr,1), "\n")

# ---- Bias surfaces (signed, diverging at 0) ----
png("acadgy_bias_surface_3way.png", width=2400, height=1000, res=200)
par(mfrow=c(1,3), mar=c(3.2,3.2,2.4,1), mgp=c(2,0.6,0))
blist<-list()
for(nm in names(models)){ col<-models[[nm]]; if(!col %in% names(d)) next
  dd<-d[is.finite(get(col))]; bias<-100*(dd[[col]]-dd$BA_obs)/dd$BA_obs
  blist[[nm]]<-idw(dd$long, dd$lat, bias, radius=0.7, p=2) }
bz<-c(-25,25)
for(nm in names(blist)){ M<-pmax(bz[1],pmin(bz[2],blist[[nm]])); plotsurf(M,bz,divcol,paste0(nm,"\nBA bias (%)")) }
dev.off()
cat("DONE  n plots:", nrow(d), " grid:", length(gx),"x",length(gy), "\n")

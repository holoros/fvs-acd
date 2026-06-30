# Refined continuous surfaces: TOTAL VOLUME (the integrator) bias for 12.5.0 vs 12.7.0,
# and BA bias 3-way incl OSM. Land-masked (ocean removed via maps::map.where) with a
# value colorbar legend. Manual IDW; pure base R + maps/mapdata.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table); library(maps); library(mapdata) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
ob  <- fread("region_obs_fullmetric.csv")[,.(pid,region,BA_obs=BA,VOL_obs=totvol)]
p127<- fread("region_pred_fullmetric.csv")[,.(pid,BA_127=BA,VOL_127=totvol)]
p125<- fread("region_pred_fullmetric_125.csv")[,.(pid,BA_125=BA,VOL_125=totvol)]
osm <- fread("region_osm_pred.csv")[,.(pid,BA_osm)]
co  <- fread("pid_coords.csv")[,.(pid,lat,long)]
d <- Reduce(function(a,b) merge(a,b,by="pid",all.x=TRUE), list(ob,p127,p125,osm,co))
d <- d[is.finite(lat)&is.finite(long)&is.finite(BA_obs)&BA_obs>0]

gx <- seq(min(d$long)-0.2, max(d$long)+0.2, by=0.05)
gy <- seq(min(d$lat)-0.2,  max(d$lat)+0.2,  by=0.05)
G  <- expand.grid(long=gx, lat=gy); asp <- 1/cos(45*pi/180)
# land mask: TRUE where the grid cell falls on land (worldHires region not NA)
landv <- !is.na(map.where("worldHires", G$long, G$lat))
landmask <- matrix(landv, nrow=length(gx))
idw <- function(lon,lat,v,radius=0.7,p=2,minw=0.5){
  out<-rep(NA_real_, nrow(G))
  for(i in seq_len(nrow(G))){ if(!landv[i]) next
    dx<-(G$long[i]-lon); dy<-(G$lat[i]-lat)*asp; dd<-sqrt(dx*dx+dy*dy); sel<-dd<=radius
    if(!any(sel)) next; w<-1/(dd[sel]^p+1e-6); if(sum(w)<minw) next; out[i]<-sum(w*v[sel])/sum(w) }
  matrix(out, nrow=length(gx)) }
divcol <- colorRampPalette(c("#2166ac","#67a9cf","#f7f7f7","#ef8a62","#b2182b"))(100)
drawbound <- function(){ map("worldHires", c("Canada","USA"), add=TRUE, col="grey20", lwd=0.9)
  map("state","maine", add=TRUE, col="grey20", lwd=0.6) }
colorbar <- function(zr, cols, lab){  # small vertical colorbar in current plot's right margin via par(new)
  usr<-par("usr"); xr<-usr[2]-usr[1]; yr<-usr[4]-usr[3]
  xl<-usr[2]-0.04*xr; xrt<-usr[2]-0.015*xr; yb<-usr[3]+0.08*yr; yt<-usr[3]+0.42*yr
  ny<-length(cols); ys<-seq(yb,yt,length.out=ny+1)
  for(i in seq_len(ny)) rect(xl,ys[i],xrt,ys[i+1],col=cols[i],border=NA)
  rect(xl,yb,xrt,yt,border="grey30",lwd=0.5)
  text(xrt+0.005*xr, c(yb,(yb+yt)/2,yt), labels=c(zr[1],round(mean(zr)),zr[2]), pos=4, cex=0.65, xpd=NA)
  text((xl+xrt)/2, yt+0.03*yr, lab, cex=0.62, xpd=NA) }
plotsurf <- function(M,zr,cols,ttl,leglab){
  M<-matrix(as.numeric(M),nrow=length(gx),ncol=length(gy)); M[M<zr[1]]<-zr[1]; M[M>zr[2]]<-zr[2]
  image(gx,gy,M,col=cols,zlim=zr,xlab="longitude",ylab="latitude",main=ttl,asp=asp)
  drawbound(); colorbar(zr,cols,leglab) }
bz<-c(-25,25)
# Figure 1: TOTAL VOLUME bias, 12.5.0 vs 12.7.0 vs OSM(BA proxy noted)
png("acadgy_totvol_bias_surface.png", width=1700, height=900, res=200)
par(mfrow=c(1,2), mar=c(3.2,3.2,2.6,1), mgp=c(2,0.6,0))
for(cfg in list(c("VOL_125","12.5.0 (production)"),c("VOL_127","12.7.0 (operational)"))){
  dd<-d[is.finite(get(cfg[1]))]; b<-100*(dd[[cfg[1]]]-dd$VOL_obs)/dd$VOL_obs
  plotsurf(idw(dd$long,dd$lat,b),bz,divcol,paste0(cfg[2],"\nTotal volume bias (%)"),"bias %") }
dev.off()
# Figure 2: BA bias 3-way incl OSM
png("acadgy_ba_bias_surface_3way.png", width=2400, height=900, res=200)
par(mfrow=c(1,3), mar=c(3.2,3.2,2.6,1), mgp=c(2,0.6,0))
for(cfg in list(c("BA_125","12.5.0 (production)"),c("BA_127","12.7.0 (operational)"),c("BA_osm","OSM v2.26.1"))){
  dd<-d[is.finite(get(cfg[1]))]; b<-100*(dd[[cfg[1]]]-dd$BA_obs)/dd$BA_obs
  plotsurf(idw(dd$long,dd$lat,b),bz,divcol,paste0(cfg[2],"\nBasal area bias (%)"),"bias %") }
dev.off()
cat("DONE land-masked maps; n", nrow(d), "\n")

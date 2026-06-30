# Corrected bias surfaces: interpolate PREDICTED and OBSERVED separately, then take the
# local ratio of means -> 100*(pred_surface/obs_surface - 1). This is aggregate-consistent
# (matches ratio-of-means, ~+2%) and not inflated by the per-plot percent-ratio skew that
# made the earlier maps look uniformly red (per-plot median bias is ~0). Land-masked, legend.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table); library(maps); library(mapdata) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
ob  <- fread("region_obs_fullmetric.csv")[,.(pid,region,BA_o=BA,VOL_o=totvol)]
p127<- fread("region_pred_fullmetric.csv")[,.(pid,BA_127=BA,VOL_127=totvol)]
p125<- fread("region_pred_fullmetric_125.csv")[,.(pid,BA_125=BA,VOL_125=totvol)]
osm <- fread("region_osm_pred.csv")[,.(pid,BA_osm)]
co  <- fread("pid_coords.csv")[,.(pid,lat,long)]
d <- Reduce(function(a,b) merge(a,b,by="pid",all.x=TRUE), list(ob,p127,p125,osm,co))
d <- d[is.finite(lat)&is.finite(long)&is.finite(BA_o)&BA_o>0]
gx <- seq(min(d$long)-0.2,max(d$long)+0.2,by=0.05); gy <- seq(min(d$lat)-0.2,max(d$lat)+0.2,by=0.05)
G  <- expand.grid(long=gx,lat=gy); asp <- 1/cos(45*pi/180)
landv <- !is.na(map.where("worldHires", G$long, G$lat))
idwvec <- function(lon,lat,v,radius=0.7,p=2,minw=0.5){
  out<-rep(NA_real_,nrow(G))
  for(i in seq_len(nrow(G))){ if(!landv[i]) next
    dx<-(G$long[i]-lon);dy<-(G$lat[i]-lat)*asp;dd<-sqrt(dx*dx+dy*dy);sel<-dd<=radius
    if(!any(sel)) next; w<-1/(dd[sel]^p+1e-6); if(sum(w)<minw) next; out[i]<-sum(w*v[sel])/sum(w) }
  out }
# bias surface = 100*(IDW(pred)/IDW(obs) - 1), the local ratio of means
biassurf <- function(lon,lat,pred,obs){ ps<-idwvec(lon,lat,pred); os<-idwvec(lon,lat,obs)
  matrix(100*(ps/os-1), nrow=length(gx)) }
divcol <- colorRampPalette(c("#2166ac","#67a9cf","#f7f7f7","#ef8a62","#b2182b"))(100)
drawbound<-function(){map("worldHires",c("Canada","USA"),add=TRUE,col="grey20",lwd=0.9);map("state","maine",add=TRUE,col="grey20",lwd=0.6)}
colorbar<-function(zr,cols,lab){usr<-par("usr");xr<-usr[2]-usr[1];yr<-usr[4]-usr[3]
  xl<-usr[2]-0.045*xr;xrt<-usr[2]-0.02*xr;yb<-usr[3]+0.07*yr;yt<-usr[3]+0.40*yr;ny<-length(cols);ys<-seq(yb,yt,length.out=ny+1)
  for(i in seq_len(ny))rect(xl,ys[i],xrt,ys[i+1],col=cols[i],border=NA);rect(xl,yb,xrt,yt,border="grey30",lwd=0.5)
  text(xrt+0.004*xr,c(yb,(yb+yt)/2,yt),labels=c(zr[1],0,zr[2]),pos=4,cex=0.62,xpd=NA);text((xl+xrt)/2,yt+0.03*yr,lab,cex=0.6,xpd=NA)}
plotsurf<-function(M,zr,ttl){M<-matrix(as.numeric(M),nrow=length(gx),ncol=length(gy));M[M<zr[1]]<-zr[1];M[M>zr[2]]<-zr[2]
  image(gx,gy,M,col=divcol,zlim=zr,xlab="longitude",ylab="latitude",main=ttl,asp=asp);drawbound();colorbar(zr,divcol,"bias %")}
zr<-c(-15,15)
png("acadgy_totvol_bias_surface.png",width=1700,height=900,res=200)
par(mfrow=c(1,2),mar=c(3.2,3.2,2.6,1.4),mgp=c(2,0.6,0))
for(cfg in list(c("VOL_125","12.5.0 (production)"),c("VOL_127","12.7.0 (operational)"))){
  dd<-d[is.finite(get(cfg[1]))];plotsurf(biassurf(dd$long,dd$lat,dd[[cfg[1]]],dd$VOL_o),zr,paste0(cfg[2],"\nTotal volume bias (% of observed)"))}
dev.off()
png("acadgy_ba_bias_surface_3way.png",width=2400,height=900,res=200)
par(mfrow=c(1,3),mar=c(3.2,3.2,2.6,1.4),mgp=c(2,0.6,0))
for(cfg in list(c("BA_125","12.5.0 (production)"),c("BA_127","12.7.0 (operational)"),c("BA_osm","OSM v2.26.1"))){
  dd<-d[is.finite(get(cfg[1]))];plotsurf(biassurf(dd$long,dd$lat,dd[[cfg[1]]],dd$BA_o),zr,paste0(cfg[2],"\nBasal area bias (% of observed)"))}
dev.off()
cat("DONE corrected (ratio-of-means) surfaces; n",nrow(d),"\n")

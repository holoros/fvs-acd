# Annual-increment maps (the honest growth-model assessment). Absolute units (m2/ha/yr),
# so no ratio skew. RMSE focus + signed bias, 3-way (12.5.0/12.7.0/OSM), land-masked, legend.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table); library(maps); library(mapdata) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
d <- fread("region_annual_increment.csv")
co <- fread("pid_coords.csv")[,.(pid,lat,long)]
d <- merge(d, co, by="pid"); d <- d[is.finite(lat)&is.finite(long)]
gx<-seq(min(d$long)-0.2,max(d$long)+0.2,by=0.05); gy<-seq(min(d$lat)-0.2,max(d$lat)+0.2,by=0.05)
G<-expand.grid(long=gx,lat=gy); asp<-1/cos(45*pi/180)
landv<-!is.na(map.where("worldHires",G$long,G$lat))
idw<-function(lon,lat,v,radius=0.7,p=2,minw=0.5){out<-rep(NA_real_,nrow(G))
  for(i in seq_len(nrow(G))){if(!landv[i])next; dx<-(G$long[i]-lon);dy<-(G$lat[i]-lat)*asp;dd<-sqrt(dx*dx+dy*dy);sel<-dd<=radius
   if(!any(sel))next;w<-1/(dd[sel]^p+1e-6);if(sum(w)<minw)next;out[i]<-sum(w*v[sel])/sum(w)};matrix(out,nrow=length(gx))}
drawbound<-function(){map("worldHires",c("Canada","USA"),add=TRUE,col="grey20",lwd=0.9);map("state","maine",add=TRUE,col="grey20",lwd=0.6)}
cbar<-function(zr,cols,lab){usr<-par("usr");xr<-usr[2]-usr[1];yr<-usr[4]-usr[3]
  xl<-usr[2]-0.05*xr;xrt<-usr[2]-0.022*xr;yb<-usr[3]+0.07*yr;yt<-usr[3]+0.40*yr;ny<-length(cols);ys<-seq(yb,yt,length.out=ny+1)
  for(i in seq_len(ny))rect(xl,ys[i],xrt,ys[i+1],col=cols[i],border=NA);rect(xl,yb,xrt,yt,border="grey30",lwd=0.5)
  text(xrt+0.004*xr,c(yb,(yb+yt)/2,yt),labels=round(c(zr[1],mean(zr),zr[2]),2),pos=4,cex=0.6,xpd=NA);text((xl+xrt)/2,yt+0.03*yr,lab,cex=0.58,xpd=NA)}
plots<-function(M,zr,cols,ttl,leg){M<-matrix(as.numeric(M),nrow=length(gx),ncol=length(gy));M[M<zr[1]]<-zr[1];M[M>zr[2]]<-zr[2]
  image(gx,gy,M,col=cols,zlim=zr,xlab="longitude",ylab="latitude",main=ttl,asp=asp);drawbound();cbar(zr,cols,leg)}
seqcol<-colorRampPalette(c("#ffffcc","#a1dab4","#41b6c4","#2c7fb8","#253494"))(100)  # RMSE: low light -> high dark
divcol<-colorRampPalette(c("#2166ac","#67a9cf","#f7f7f7","#ef8a62","#b2182b"))(100)
# RMSE surface (sqrt of IDW of squared annual-increment error)
png("acadgy_annual_rmse_3way.png",width=2400,height=900,res=200)
par(mfrow=c(1,3),mar=c(3.2,3.2,2.6,1.6),mgp=c(2,0.6,0))
rl<-list(); for(c in c("dBA_5","dBA_7","dBA_os")) rl[[c]]<-sqrt(idw(d$long,d$lat,(d[[c]]-d$dBA_obs)^2))
zr<-c(0,quantile(unlist(rl),0.95,na.rm=TRUE))
for(nm in list(c("dBA_5","12.5.0 (production)"),c("dBA_7","12.7.0 (operational)"),c("dBA_os","OSM v2.26.1")))
  plots(rl[[nm[1]]],zr,seqcol,paste0(nm[2],"\nAnnual BA increment RMSE (m2/ha/yr)"),"RMSE")
dev.off()
# Signed bias surface (m2/ha/yr), diverging at 0
png("acadgy_annual_bias_3way.png",width=2400,height=900,res=200)
par(mfrow=c(1,3),mar=c(3.2,3.2,2.6,1.6),mgp=c(2,0.6,0))
bz<-c(-0.6,0.6)
for(nm in list(c("dBA_5","12.5.0 (production)"),c("dBA_7","12.7.0 (operational)"),c("dBA_os","OSM v2.26.1")))
  plots(idw(d$long,d$lat,d[[nm[1]]]-d$dBA_obs),bz,divcol,paste0(nm[2],"\nAnnual BA increment bias (m2/ha/yr)"),"bias")
dev.off()
cat("RMSE zr",round(zr,2)," DONE n",nrow(d),"\n")

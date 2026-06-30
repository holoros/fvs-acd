.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths())); suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
pr<-fread("region_pred_fullmetric.csv"); ob<-fread("region_obs_fullmetric.csv"); co<-fread("pid_coords.csv")
m<-merge(pr,ob,by=c("region","pid"),suffixes=c(".p",".o")); m<-merge(m,co[,.(pid,lat,long)],by="pid")
m<-m[is.finite(lat)&is.finite(long)]
GR<-0.25  # 0.25 degree aggregation (hot-spot grid; no individual plots shown)
m[, gx:=round(long/GR)*GR]; m[, gy:=round(lat/GR)*GR]
mets<-c("BA","QMD","topht","totvol"); labs<-c("Basal area","QMD","Top height","Total volume")
divcol<-function(b){ b<-pmax(-30,pmin(30,b)); r<-(b+30)/60
  rgb(colorRamp(c("#2166ac","#f7f7f7","#b2182b"))(r)/255) }
png("acadgy_v1270_spatial_bias.png", width=2000, height=1700, res=200)
par(mfrow=c(2,2), mar=c(3.5,3.5,2.5,1), mgp=c(2,0.6,0))
for(i in seq_along(mets)){
  mt<-mets[i]; m[, bias:=100*(get(paste0(mt,".p"))/get(paste0(mt,".o"))-1)]
  g<-m[is.finite(bias), .(b=mean(bias), n=.N), by=.(gx,gy)][n>=2]
  plot(g$gx,g$gy,type="n",xlab="longitude",ylab="latitude",main=paste0(labs[i]," bias (%)  [0.25deg cells, n>=2]"),
       xlim=range(m$long)+c(-0.3,0.3), ylim=range(m$lat)+c(-0.3,0.3), asp=1/cos(45*pi/180))
  rect(g$gx-GR/2,g$gy-GR/2,g$gx+GR/2,g$gy+GR/2,col=divcol(g$b),border=NA)
  legend("topright",legend=c("+30%","0","-30%"),fill=divcol(c(30,0,-30)),bty="n",cex=0.8,title="pred-obs")
}
dev.off(); cat("WROTE acadgy_v1270_spatial_bias.png  cells/metric ~",nrow(m[,.N,by=.(gx,gy)]),"\n")
# also dump grid bias table (no coords below 0.25deg) for hot-spot id

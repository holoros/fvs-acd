suppressMessages(library(data.table)); setwd("/users/PUOM0008/crsfaaron/silc_cfi")
man<-fread("region_manifest.csv"); e8<-fread("pid_esi8.csv"); e8[,esi8:=as.numeric(esi8)]; e8<-e8[is.finite(esi8)&esi8>0]
m<-merge(man,e8[,.(pid,esi8)],by="pid",all.x=TRUE)
cat("manifest",nrow(man)," with ESI8",sum(is.finite(m$esi8)),"\n")
for(rg in c("ME","NB","NS")){s<-m[region==rg]; cat(sprintf("%s legacy %.2f  esi8 %.2f  cor %.2f\n",rg,mean(s$csi,na.rm=T),mean(s$esi8,na.rm=T),suppressWarnings(cor(s$csi,s$esi8,use="complete.obs"))))}
m[,csi_legacy:=csi]; m[is.finite(esi8),csi:=round(esi8,2)]; m<-m[is.finite(csi)]
fwrite(m[,.(region,pid,t1,t2,remper,csi,elev,csi_legacy)],"region_manifest_esi8.csv")
# legacy on SAME plots/order
ml<-copy(m); ml[,csi:=csi_legacy]; fwrite(ml[,.(region,pid,t1,t2,remper,csi,elev,csi_legacy)],"region_manifest_leg8.csv")
cat("wrote esi8 + leg8 manifests rows",nrow(m),"\n")

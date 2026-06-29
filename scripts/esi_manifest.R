suppressPackageStartupMessages(library(data.table)); setwd("/users/PUOM0008/crsfaaron/silc_cfi")
man <- fread("region_manifest.csv"); esi <- fread("pid_esi.csv")
esi[, esi := as.numeric(esi)]; esi <- esi[is.finite(esi) & esi>0]
m <- merge(man, esi[,.(pid,esi)], by="pid", all.x=TRUE)
cat("manifest", nrow(man), " with ESI", sum(is.finite(m$esi)), " ESI NA", sum(!is.finite(m$esi)),"\n")
for(rg in c("ME","NB","NS")){ s<-m[region==rg]
  cat(sprintf("%s  legacy mean %.2f (%.2f-%.2f)  ESI mean %.2f (%.2f-%.2f)  cor %.2f\n", rg,
    mean(s$csi,na.rm=TRUE),min(s$csi,na.rm=TRUE),max(s$csi,na.rm=TRUE),
    mean(s$esi,na.rm=TRUE),min(s$esi,na.rm=TRUE),max(s$esi,na.rm=TRUE),
    suppressWarnings(cor(s$csi,s$esi,use="complete.obs")))) }
m[, csi_legacy := csi]; m[is.finite(esi), csi := round(esi,2)]
m <- m[is.finite(csi)]
fwrite(m[,.(region,pid,t1,t2,remper,csi,elev,csi_legacy)], "region_manifest_esi.csv")
cat("wrote region_manifest_esi.csv rows", nrow(m),"\n")

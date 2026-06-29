suppressPackageStartupMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
d <- fread("/fs/scratch/PUOM0008/crsfaaron/maine_cfi/DBHout.csv", nThread=4,
           select=c("Source","Stand","Plot","year1","climatesi","elev","lat","long"))
d <- d[is.finite(climatesi) & climatesi>0 & climatesi<40]
d[, region := fifelse(Source=="Nova Scotia PSP","NS", fifelse(Source=="NB PSP","NB",
               fifelse(Source %in% c("PEF","FIA_99_05"),"ME","X")))]
d <- d[region!="X"]
d[, pid := sprintf("%s_%s_%s_%d", region, gsub("[^A-Za-z0-9]","",as.character(Stand)), as.character(Plot), year1)]
co <- d[, .(lat=median(lat,na.rm=TRUE), long=median(long,na.rm=TRUE), legacy_csi=round(median(climatesi),2)), by=.(pid,region)]
co <- co[is.finite(lat) & is.finite(long)]
fwrite(co, "pid_coords.csv")
cat("pid_coords rows", nrow(co), " lat range", round(range(co$lat),2)," long range", round(range(co$long),2),"\n")
man <- fread("region_manifest.csv"); cat("manifest pids", nrow(man), " matched in coords:", sum(man$pid %in% co$pid),"\n")

# Build NB / NS / ME remeasurement intervals from DBHout. Input = inventory at t1
# (rows with year1==t1); observed = full inventory at t2 (rows with year1==t2, so
# recruits are included and mortality excluded). Samples N per region, writes the
# input tree lists, the observed metrics (volume+value), and a manifest.
suppressPackageStartupMessages({ library(data.table); library(dplyr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
source("value_fns.R")
NPER <- as.integer(Sys.getenv("NPER","250")); set.seed(7)
d <- fread("/fs/scratch/PUOM0008/crsfaaron/maine_cfi/DBHout.csv", nThread=4,
           select=c("Source","Stand","Plot","year1","sp1","dbh1","expf1","climatesi","elev"))
setnames(d, c("sp1","dbh1","expf1","climatesi"), c("sp","dbh","expf","csi"))
d <- d[is.finite(dbh) & dbh>0 & is.finite(expf) & expf>0 & csi>0 & csi<40]
d[, region := fifelse(Source=="Nova Scotia PSP","NS",
               fifelse(Source=="NB PSP","NB",
               fifelse(Source %in% c("PEF","FIA_99_05"),"ME","X")))]
d <- d[region!="X"]
d[, sp := toupper(gsub('"','',sp))]

starts <- unique(d[,.(region,Source,Stand,Plot,year1)])
setorder(starts, Source,Stand,Plot,year1)
starts[, nexty := shift(year1,-1L), by=.(Source,Stand,Plot)]
starts[, rem := nexty-year1]
cand <- starts[is.finite(rem) & rem>=3 & rem<=15]
samp <- cand[, .SD[sample(.N, min(.N, NPER))], by=region]
samp[, pid := sprintf("%s_%s_%s_%d", region, gsub("[^A-Za-z0-9]","",as.character(Stand)), as.character(Plot), year1)]
cat("sampled intervals: "); print(table(samp$region))

inp <- list(); obsm <- list(); man <- list()
for (i in seq_len(nrow(samp))){
  s <- samp[i]
  it <- d[Source==s$Source & Stand==s$Stand & Plot==s$Plot & year1==s$year1]
  ot <- d[Source==s$Source & Stand==s$Stand & Plot==s$Plot & year1==s$nexty]
  if (nrow(it)<5 || nrow(ot)<3) next
  inp[[s$pid]] <- data.table(region=s$region, pid=s$pid, sp=it$sp, dbh_cm=it$dbh, expf_tph=it$expf)
  ov <- plot_value(ot$sp, ot$dbh, ot$expf)
  obsm[[s$pid]] <- data.table(region=s$region, pid=s$pid, ov)
  man[[s$pid]] <- data.table(region=s$region, pid=s$pid, t1=s$year1, t2=s$nexty, remper=s$rem,
                             csi=round(median(it$csi),2), elev=round(median(it$elev),0))
}
INP <- rbindlist(inp); OBS <- rbindlist(obsm); MAN <- rbindlist(man)
fwrite(INP, "region_input_trees.csv"); fwrite(OBS, "region_obs_metrics.csv"); fwrite(MAN, "region_manifest.csv")
cat(sprintf("plots kept: %d  (NS %d, NB %d, ME %d)\n", nrow(MAN),
  sum(MAN$region=="NS"), sum(MAN$region=="NB"), sum(MAN$region=="ME")))
cat("obs medians value_ac by region:\n")
print(OBS[, .(value_ac=round(median(value_ac),0), sawMBF=round(median(sawMBF_ac),2), BA=round(median(BA_m2ha),1)), by=region])
cat("DONE\n")

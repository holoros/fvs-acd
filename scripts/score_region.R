# Score regional predicted vs observed on BA, TPA, QMD, sawlog MBF, pulp cords, value.
suppressPackageStartupMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
obs <- fread("region_obs_metrics.csv")
files <- list.files(".", pattern="^region_pred_.*\\.csv$")
bias <- function(p,o){ ok<-is.finite(p)&is.finite(o); if(!any(ok)) return(NA); round(100*(mean(p[ok])/mean(o[ok])-1),1) }
rows <- list()
for (f in files){
  pr <- fread(f); tag <- sub("^region_pred_","",sub("\\.csv$","",f))
  m <- merge(pr, obs, by=c("region","pid"), suffixes=c(".p",".o"))
  for (rg in c("ALL","NS","NB","ME")){
    s <- if (rg=="ALL") m else m[region==rg]
    if (nrow(s)==0) next
    rows[[paste(tag,rg)]] <- data.table(config=tag, region=rg, n=nrow(s),
      BA=bias(s$BA_m2ha.p,s$BA_m2ha.o), TPA=bias(s$TPH.p,s$TPH.o), QMD=bias(s$QMD_cm.p,s$QMD_cm.o),
      sawMBF=bias(s$sawMBF_ac.p,s$sawMBF_ac.o), pulp=bias(s$pulpcord_ac.p,s$pulpcord_ac.o),
      value=bias(s$value_ac.p,s$value_ac.o)) }
}
tab <- rbindlist(rows); fwrite(tab, "region_value_scorecard.csv")
cat("=== Regional bias (%): predicted vs observed ===\n")
print(tab[order(config,region)], row.names=FALSE)
cat("\n=== ALL-region summary by config ===\n")
print(tab[region=="ALL"][order(config)], row.names=FALSE)
cat("DONE\n")

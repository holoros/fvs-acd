# Diagnose Wfull.rds vs published mgmt_scorecard_byclass.csv discrepancy, correct MAE (abs), re-derive.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
W <- as.data.table(readRDS("Wfull.rds"))
cat("Wfull nrow=",nrow(W)," classes:\n"); print(W[,.N,by=mgmt][order(-N)])
cat("\nPublished CSV:\n"); print(fread("mgmt_scorecard_byclass.csv")[metric=="TOTVOL"])
cat("\nclass counts csv:\n"); print(fread("mgmt_class_counts.csv"))

# increment means for PCT/PLANTED in Wfull
for(cls in c("PLANTED","PCT")){
  i <- which(W$mgmt==cls)
  oi <- mean(W$BA_o[i]-W$BA_t1[i]); pi <- mean(W$v129x.BA[i]-W$BA_t1[i])
  cat(sprintf("\n%s n=%d  BA obs_inc=%.3f pred_inc=%.3f ratio=%.3f\n", cls, length(i), oi, pi, oi/pi))
}
# does Wfull already contain v1210 columns? compare stored v1210 to v129x for PCT
i <- which(W$mgmt=="PCT")
cat("\nStored-in-Wfull PCT TOTVOL: v129x=", round(100*(mean(W$v129x.TOTVOL[i])/mean(W$TOTVOL_o[i])-1),1),
    " v1210(stored)=", round(100*(mean(W$v1210.TOTVOL[i])/mean(W$TOTVOL_o[i])-1),1),
    " osm=", round(100*(mean(W$osm.TOTVOL[i])/mean(W$TOTVOL_o[i])-1),1), "\n")
i <- which(W$mgmt=="PLANTED")
cat("Stored-in-Wfull PLANTED TOTVOL: v129x=", round(100*(mean(W$v129x.TOTVOL[i])/mean(W$TOTVOL_o[i])-1),1),
    " v1210(stored)=", round(100*(mean(W$v1210.TOTVOL[i])/mean(W$TOTVOL_o[i])-1),1),
    " osm=", round(100*(mean(W$osm.TOTVOL[i])/mean(W$TOTVOL_o[i])-1),1), "\n")

# Proper ABSOLUTE MAE gap closure from STORED v1210, matching published method
biaspct <- function(col,obs,idx) 100*(mean(col[idx],na.rm=TRUE)/mean(obs[idx],na.rm=TRUE)-1)
mae <- function(mdl,idx) mean(abs(sapply(M, function(m) biaspct(W[[paste0(mdl,".",m)]], W[[paste0(m,"_o")]], idx))))
managed <- which(W$mgmt %in% c("PLANTED","PCT"))
cat("\n== ABSOLUTE MAE from STORED v1210 (Wfull) ==\n")
for(cls in c("PLANTED","PCT","MANAGED")){
  idx <- if(cls=="MANAGED") managed else which(W$mgmt==cls)
  cat(sprintf("  %-8s n=%d  MAE v129x=%.1f v1210=%.1f osm=%.1f\n", cls, length(idx),
     mae("v129x",idx), mae("v1210",idx), mae("osm",idx)))
}
cat("DONE\n")

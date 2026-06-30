# Fit an NSVB emulator from FIA's own NSVB outputs (ME_TREE) so model predictions and MagPlot trees
# can be scored on FIA-grade NSVB volume and biomass. Robust combined-variable form per species group
# (SPGRPCD): log(y) ~ log(DIA^2 * HT), with Duan smearing for an unbiased back-transform. DIA in inches,
# HT in feet (FIA units); VOLCFGRS/NET/CSNET in cubic ft, DRYBIO_AG in lb.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
tr <- fread("~/fia_data/ME_TREE.csv", select=c("SPCD","SPGRPCD","DIA","HT","STATUSCD","VOLCFGRS","VOLCFNET","VOLCSNET","DRYBIO_AG"))
tr <- tr[STATUSCD==1 & is.finite(DIA) & DIA>0 & is.finite(HT) & HT>0]
tr[, D2H := DIA^2 * HT][, lX := log(D2H)]
resp <- c("VOLCFGRS","VOLCFNET","VOLCSNET","DRYBIO_AG")
rows <- list()
for(sg in sort(unique(tr$SPGRPCD))){
  s <- tr[SPGRPCD==sg]; if(nrow(s)<40) next
  row <- data.frame(SPGRPCD=sg, n=nrow(s))
  for(r in resp){
    y <- s[[r]]; ok <- is.finite(y) & y>0 & is.finite(s$lX)
    if(sum(ok)<40){ row[[paste0(r,"_a")]]<-NA; row[[paste0(r,"_b")]]<-NA; row[[paste0(r,"_sm")]]<-1; row[[paste0(r,"_r2")]]<-NA; next }
    d <- data.frame(ly=log(y[ok]), lX=s$lX[ok])
    m <- lm(ly ~ lX, data=d)
    yhat <- exp(predict(m))
    row[[paste0(r,"_a")]] <- unname(coef(m)[1]); row[[paste0(r,"_b")]] <- unname(coef(m)[2])
    row[[paste0(r,"_sm")]] <- mean(y[ok])/mean(yhat); row[[paste0(r,"_r2")]] <- summary(m)$r.squared
  }
  rows[[as.character(sg)]] <- row
}
co <- rbindlist(rows, fill=TRUE); fwrite(co, "~/magplot/verify/nsvb_emulator_coefs.csv")
cat("=== NSVB emulator (combined-variable log(DIA^2*HT), by SPGRPCD) ===\n")
cat(sprintf("groups: %d, trees: %d\n", nrow(co), sum(co$n)))
for(r in resp) cat(sprintf("  %-10s mean R2 %.3f (n-wt)\n", r, weighted.mean(co[[paste0(r,"_r2")]], co$n, na.rm=TRUE)))
spmap <- unique(fread("~/fia_data/ME_TREE.csv", select=c("SPCD","SPGRPCD"))); fwrite(spmap, "~/magplot/verify/spcd_spgrpcd.csv")
cat("wrote nsvb_emulator_coefs.csv, spcd_spgrpcd.csv\nDONE\n")

suppressPackageStartupMessages(library(data.table))
W <- "/users/PUOM0008/crsfaaron/silc_cfi/v32_htdub"
m <- fread(file.path(W,"fvsacd_v131hier_meas_full137_treelist_raw.csv"))
d <- fread(file.path(W,"fvsacd_v131hier_dub_full137_treelist_raw.csv"))
rt <- unique(fread(file.path(W,"silc_cfi_v32ht_byplot_primary_DATA_2026-09-23.csv"))[model_config=="OBSERVED",PLOT])
t1 <- m[RECORD=="T1" & PLOT %in% rt, .(STAND,PLOT,TREE,sp,dbh1=dbh_cm,ht1=ht_m)]
pm <- m[RECORD=="PRED_T2", .(STAND,TREE,htm=ht_m,dbhm=dbh_cm,expf=expf_tph)]
pd <- d[RECORD=="PRED_T2", .(STAND,TREE,htd=ht_m)]
pm <- pm[, .(htm=weighted.mean(htm,expf), dbhm=weighted.mean(dbhm,expf), expf=sum(expf)), by=.(STAND,TREE)]
pd <- pd[, .(htd=mean(htd)), by=.(STAND,TREE)]
x <- merge(merge(t1, pm, by=c("STAND","TREE")), pd, by=c("STAND","TREE"))
x <- x[is.finite(ht1) & ht1>0]
x[, hd1 := ht1/(dbh1/100)]; x[, r := htm/htd]
x[, cls := fifelse(hd1>130,"hd>130 (feet as m)", fifelse(r<0.6,"r<0.6 (short: broken top or error)", "plausible"))]
cat("trees with measured t1 height, matched:", nrow(x), "\n")
print(x[, .(n=.N, share=round(.N/nrow(x),3), mean_htm=round(mean(htm),2), mean_htd=round(mean(htd),2), ratio_of_means=round(mean(htd)/mean(htm),3)), by=cls])
cat("ALL ratio of means dub/meas:", round(mean(x$htd)/mean(x$htm),3), "\n")
cat("plausible only:", round(x[cls=="plausible", mean(htd)/mean(htm)],3), "\n")
cat("plausible r quantiles:\n"); print(round(quantile(x[cls=="plausible",r],c(.05,.25,.5,.75,.95)),3))
cat("short class by sp:\n"); print(x[cls!="plausible" & hd1<=130, .N, by=sp][order(-N)])
cat("short class plots (n trees):\n"); print(x[cls!="plausible" & hd1<=130, .N, by=PLOT][order(-N)][1:15])
fwrite(x, "t1_height_classes_DATA_2026-09-26.csv")

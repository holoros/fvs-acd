suppressPackageStartupMessages(library(data.table))
W <- "/users/PUOM0008/crsfaaron/silc_cfi/v32_htdub"
m <- fread(file.path(W,"fvsacd_v131hier_meas_full137_treelist_raw.csv"))
d <- fread(file.path(W,"fvsacd_v131hier_dub_full137_treelist_raw.csv"))
rt <- unique(fread(file.path(W,"silc_cfi_v32ht_byplot_primary_DATA_2026-09-23.csv"))[model_config=="OBSERVED",PLOT])
t1 <- m[RECORD=="T1" & PLOT %in% rt]; t1d <- d[RECORD=="PRED_T2"]
t1[, hd := ht_m/(dbh_cm/100)]
cat("T1 routine trees:", nrow(t1), " with ht:", t1[is.finite(ht_m)&ht_m>0,.N], "\n")
cat("T1 h/d quantiles:\n"); print(round(quantile(t1$hd, c(0,.01,.05,.25,.5,.75,.95,.99,1), na.rm=TRUE),1))
cat("T1 h/d > 130 (the OBSERVED t2 feet-as-metres rule, NOT applied to T1):", t1[hd>130,.N], " plots:", paste(sort(unique(t1[hd>130,PLOT])),collapse=" "), "\n")
cat("T1 h/d < 30:", t1[hd<30,.N], " plots:", paste(sort(unique(t1[hd<30,PLOT])),collapse=" "), "\n")
print(t1[hd>130, .(PLOT,TREE,sp,dbh_cm,ht_m,hd=round(hd))])
o2 <- m[RECORD=="OBS_T2" & PLOT %in% rt]; o2[, hd := ht_m/(dbh_cm/100)]
cat("OBS_T2 in raw (pre repair) h/d>130:", o2[hd>130,.N], "\n")
fwrite(t1, "t1_routine_heights_DATA_2026-09-26.csv")

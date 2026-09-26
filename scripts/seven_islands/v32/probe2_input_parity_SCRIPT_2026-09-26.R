suppressPackageStartupMessages(library(data.table))
FR <- "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames"
MS <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
bp <- fread("../v32_htdub/silc_cfi_v32ht_byplot_primary_DATA_2026-09-23.csv")[model_config=="OBSERVED"]
tl <- fread("../v32_htdub/fvsacd_v131hier_meas_treelist.csv"); k <- unique(tl[,.(PLOT,YEAR)])
cat("benchmark plots", nrow(k), " in byplot", length(unique(bp$PLOT)), "\n")
raw <- fread("../v32_htdub/fvsacd_v131hier_meas_full137_treelist_raw.csv"); rs <- unique(raw[RECORD=="PRED_T2",.(STAND,PLOT)])
cat("raw stands", nrow(rs), "\n"); print(head(rs))
fp <- fread(file.path(FR,"bench_gyr_silc_l_c_pairs.csv"))
fp[, key := sub("^SILC_L__(SILC[0-9]+)__([0-9]+_[0-9]+)_C$","\\1_\\2",STAND)]
bk <- unique(raw[RECORD=="PRED_T2" & PLOT %in% bp$PLOT, STAND])
cat("benchmark stands", length(bk), " found in frames", sum(bk %in% fp$key), "\n"); print(setdiff(bk, fp$key))
fi <- fread(file.path(FR,"bench_gyr_silc_l_c_tree_init.csv")); mi <- fread(file.path(MS,"bench_silc_l_tree_init_full137.csv"))
fi[, key := sub("^SILC_L__(SILC[0-9]+)__([0-9]+_[0-9]+)_C$","\\1_\\2",STAND)]
a <- fi[key %in% bk, .(nF=.N, baF=sum(pi*(DBH/200)^2*EXPF), htF=sum(is.finite(HT)&HT>0), hmF=mean(HT[HT>0],na.rm=TRUE)), by=key]
b <- mi[STAND %in% bk, .(nM=.N, baM=sum(pi*(DBH/200)^2*EXPF), htM=sum(is.finite(HT)&HT>0), hmM=mean(HT[HT>0],na.rm=TRUE)), by=.(key=STAND)]
m <- merge(a,b,by="key"); m[, dba := round(baF-baM,3)]
cat("stands compared", nrow(m), " identical n", sum(m$nF==m$nM), " |dBA|<0.01", sum(abs(m$dba)<0.01), " same n heights", sum(m$htF==m$htM), "\n")
print(m[nF!=nM | abs(dba)>=0.01 | htF!=htM][1:15])
cat("frames max h/d:", fi[key %in% bk & HT>0, max(HT/(DBH/100))], " multisrc max h/d:", mi[STAND %in% bk & HT>0, max(HT/(DBH/100))], "\n")
fwrite(data.table(key=bk), "benchmark_stands_65_DATA_2026-09-26.csv")

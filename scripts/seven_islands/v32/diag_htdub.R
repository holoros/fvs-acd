# Height-treatment diagnostic, September 23, 2026. Pairs each surviving original tree between the
# measured-height (meas) and imputed-height (dub) runs of the same configuration, and compares the
# measured t1 heights with the model's own equation on the same trees via the t2 predictions.
suppressPackageStartupMessages(library(data.table))
ps <- fread("../silc_cfi_longhorizon_pairs_v16.csv"); ps[, estbl := (BA_CURR_FT2AC/pmax(BA_PREV_FT2AC,1)) > 2.0]
rt <- ps[estbl==FALSE, PLOT]
res <- list()
for (cfg in c("v131hier","v14L1","v14L2")) {
  a <- fread(sprintf("fvsacd_%s_meas_full137_treelist_raw.csv", cfg)); b <- fread(sprintf("fvsacd_%s_dub_full137_treelist_raw.csv", cfg))
  t1 <- a[RECORD=="T1" & PLOT %in% rt]
  pa <- a[RECORD=="PRED_T2" & PLOT %in% rt, .(STAND, TREE, dbh_a=dbh_cm, ht_a=ht_m, ex_a=expf_tph)]
  pb <- b[RECORD=="PRED_T2" & PLOT %in% rt, .(STAND, TREE, dbh_b=dbh_cm, ht_b=ht_m, ex_b=expf_tph)]
  m <- merge(merge(pa, pb, by=c("STAND","TREE")), t1[, .(STAND, TREE, dbh1=dbh_cm, ht1=ht_m)], by=c("STAND","TREE"))
  m <- m[dbh1 >= 11.43]
  hasht <- is.finite(m$ht1) & m$ht1 > 0
  res[[cfg]] <- data.table(cfg=cfg, n_trees=nrow(m), n_t1_measured=sum(hasht),
    ht2_ratio_all = round(sum(m$ht_b*m$ex_b)/sum(m$ht_a*m$ex_a),4),
    ht2_ratio_t1measured = round(sum((m$ht_b*m$ex_b)[hasht])/sum((m$ht_a*m$ex_a)[hasht]),4),
    ht2_ratio_t1missing = round(sum((m$ht_b*m$ex_b)[!hasht])/sum((m$ht_a*m$ex_a)[!hasht]),4),
    dbh2_ratio = round(sum(m$dbh_b*m$ex_b)/sum(m$dbh_a*m$ex_a),4),
    expf2_ratio = round(sum(m$ex_b)/sum(m$ex_a),4),
    ba2_ratio = round(sum(pi*(m$dbh_b/200)^2*m$ex_b)/sum(pi*(m$dbh_a/200)^2*m$ex_a),4),
    t1_measured_mean_ht = round(mean(m$ht1[hasht]),2),
    t1_measured_trees_meanht_t2_meas = round(mean(m$ht_a[hasht]),2),
    t1_measured_trees_meanht_t2_dub = round(mean(m$ht_b[hasht]),2))
}
r <- rbindlist(res); print(r)
fwrite(r, "silc_cfi_v32ht_height_diagnostic_DATA_2026-09-23.csv")

#!/usr/bin/env Rscript
# Value and merchantable volume stress test (26 September 2026). Seven Islands' priorities are stumpage
# value and merchantable volume by product, so the 14.1 draft pick is checked on those axes: bias and R2 by
# product and for value, all 65 routine plots and the refined screen (n = 51), both specifications, plus a
# paired plot bootstrap of value and net merchantable volume differences. Seed 20260926, B = 5000. No em dashes.
suppressPackageStartupMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi/v33_v141"); set.seed(20260926); B <- 5000
ex <- c(1273,1196,1130,1194,1193,1232,1234,1235,1244,1251,1200,1205,1206,1133)
CF <- c("AGM_v840_meas","FVSACD_v131_hier_meas","FVSACD_v14_L2_meas","FVSACD_v1404_meas","FVSACD_v141_meas","FVSACD_v141_ftmfix","OSM_ACD","FVS_NE_default")
V  <- c(net_merch_cd="tot_cd", gross4_cd="gross4_cd", saw_cd="saw_cd", stud_cd="stud_cd", pallet_cd="pallet_cd", pulp_cd="pulp_cd",
        saw_val="saw_val", stud_val="stud_val", pallet_val="pallet_val", pulp_val="pulp_val", value="tot_val")
bias <- function(p,o) 100*(mean(p)-mean(o))/mean(o); r2 <- function(p,o) 1-sum((p-o)^2)/sum((o-mean(o))^2)
res <- list(); bo <- list()
for (spec in c("primary","specliteral")) {
  bp <- fread(sprintf("silc_cfi_v33_byplot_%s_DATA_2026-09-26.csv", spec)); ob <- bp[model_config=="OBSERVED"]
  for (scr in c("all65","refined_n51")) {
    keep <- if (scr=="all65") ob$PLOT else setdiff(ob$PLOT, ex)
    om <- ob[PLOT %in% keep]
    res[[length(res)+1]] <- data.table(spec=spec, screen=scr, config="OBSERVED (mean)", n=nrow(om),
      t(sapply(names(V), function(k) round(mean(om[[V[k]]]),3))))
    for (c in CF) {
      x <- merge(bp[model_config==c], ob, by="PLOT", suffixes=c("",".o"))[PLOT %in% keep]
      if (!nrow(x)) next
      b <- sapply(names(V), function(k) { o <- x[[paste0(V[k],".o")]]; if (mean(o)==0) NA_real_ else round(bias(x[[V[k]]], o),1) })
      res[[length(res)+1]] <- data.table(spec=spec, screen=scr, config=c, n=nrow(x), t(b),
        value_R2=round(r2(x$tot_val,x$tot_val.o),3), net_merch_R2=round(r2(x$tot_cd,x$tot_cd.o),3))
    }
    for (pr in list(c("FVSACD_v141_meas","FVSACD_v131_hier_meas"), c("FVSACD_v141_meas","FVSACD_v14_L2_meas"), c("FVSACD_v141_meas","AGM_v840_meas"))) for (k in c("tot_val","tot_cd")) {
      x <- merge(merge(bp[model_config==pr[1],.(PLOT,a=get(k))], bp[model_config==pr[2],.(PLOT,b=get(k))], by="PLOT"), ob[,.(PLOT,o=get(k))], by="PLOT")[PLOT %in% keep]
      f <- function(i) 100*(mean(x$a[i])-mean(x$b[i]))/mean(x$o[i]); n <- nrow(x); bs <- replicate(B, f(sample.int(n,n,TRUE)))
      bo[[length(bo)+1]] <- data.table(spec=spec, screen=scr, metric=k, a=pr[1], b=pr[2], n=n, diff=round(f(seq_len(n)),1), lo95=round(quantile(bs,.025),1), hi95=round(quantile(bs,.975),1))
    }
  }
}
res <- rbindlist(res, fill=TRUE); bo <- rbindlist(bo)
fwrite(res, "v33st_value_merch_by_product_DATA_2026-09-26.csv"); fwrite(bo, "v33st_value_merch_bootstrap_DATA_2026-09-26.csv")
print(res[spec=="primary", .(screen, config, n, net_merch_cd, saw_cd, stud_cd, pallet_cd, pulp_cd, value, value_R2, net_merch_R2)])
print(res[spec=="specliteral", .(screen, config, net_merch_cd, saw_cd, pallet_cd, pulp_cd, value, value_R2)]); print(bo)

#!/usr/bin/env Rscript
# Draft pick check (26 September 2026): paired plot bootstrap of FVS-ACD 14.1 against v13.1 hierarchical
# and v14 L2, gross volume and value, all 65 and screened 51. Seed 20260926, 5,000 resamples. No em dashes.
suppressPackageStartupMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi/v33_v141"); set.seed(20260926); B <- 5000
bp <- fread("silc_cfi_v33_byplot_primary_DATA_2026-09-26.csv"); ob <- bp[model_config=="OBSERVED"]
ex <- c(1273,1196,1130,1194,1193,1232,1234,1235,1244,1251,1200,1205,1206,1133)
bt <- function(c1,c2,var,scr){
  x <- merge(merge(bp[model_config==c1,.(PLOT,a=get(var))],bp[model_config==c2,.(PLOT,b=get(var))],by="PLOT"),ob[,.(PLOT,o=get(var))],by="PLOT")
  if (scr) x <- x[!PLOT %in% ex]
  f <- function(i) 100*(mean(x$a[i])-mean(x$b[i]))/mean(x$o[i]); n <- nrow(x); bs <- replicate(B, f(sample.int(n,n,TRUE)))
  data.table(metric=var,screen=if(scr)"refined_n51" else "all65",a=c1,b=c2,n=n,diff=round(f(seq_len(n)),1),lo95=round(quantile(bs,.025),1),hi95=round(quantile(bs,.975),1))}
out <- rbindlist(lapply(c("gross4_cd","tot_val"), function(v) rbindlist(lapply(c(FALSE,TRUE), function(s) rbind(
  bt("FVSACD_v141_meas","FVSACD_v131_hier_meas",v,s), bt("FVSACD_v141_meas","FVSACD_v14_L2_meas",v,s))))))
fwrite(out, "v33st_pick_bootstrap_DATA_2026-09-26.csv"); print(out)

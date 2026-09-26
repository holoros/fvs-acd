#!/usr/bin/env Rscript
# v32 stress test (September 26, 2026). Reads only the shipped v32 scoring outputs and the raw
# v13.1 hierarchical treelists. Writes DATA files for every number quoted in the v32 revision.
suppressPackageStartupMessages(library(data.table))
W <- "/users/PUOM0008/crsfaaron/silc_cfi/v32_htdub"; set.seed(20260926); B <- 5000
bp <- fread(file.path(W,"silc_cfi_v32ht_byplot_primary_DATA_2026-09-23.csv"))
rr <- fread(file.path(W,"silc_cfi_rates_byplot_v32ht_DATA_2026-09-23.csv"))
loss14 <- c(1106,1273,1196,1130,1194,1193,1232,1234,1235,1244,1251,1200,1205,1206)
ftm <- c(1150,1178)
SCR <- list(all65=integer(), refined_n51=c(setdiff(loss14,1106),1133), no_ftm_n63=ftm,
            refined_no_ftm_n49=c(setdiff(loss14,1106),1133,ftm))
CF <- c("AGM_v836","AGM_v840_meas","FVSACD_v131_hier_meas","FVSACD_v131_hier_dub","FVSACD_v14_L1_meas",
        "FVSACD_v14_L1_dub","FVSACD_v14_L2_meas","FVSACD_v14_L2_dub","FVSACD_v1211_full","FVSACD_v131_ship18",
        "FVS_NE_default","FVS_ACD_default","OSM_ACD")
ob <- bp[model_config=="OBSERVED"]
bias <- function(p,o) 100*(mean(p)-mean(o))/mean(o)
r2 <- function(p,o) 1-sum((p-o)^2)/sum((o-mean(o))^2)
st <- rbindlist(lapply(names(SCR), function(s) rbindlist(lapply(CF, function(c){
  x <- merge(bp[model_config==c,.(PLOT,g=gross4_cd,v=tot_val)], ob[,.(PLOT,go=gross4_cd,vo=tot_val)], by="PLOT")[!PLOT %in% SCR[[s]]]
  data.table(screen=s,config=c,n=nrow(x),gross4_bias=round(bias(x$g,x$go),1),gross4_R2=round(r2(x$g,x$go),3),
             value_bias=round(bias(x$v,x$vo),1),value_R2=round(r2(x$v,x$vo),3))}))))
fwrite(st,"v32st_state_by_screen_DATA_2026-09-26.csv")
# patched: feet-as-metres plots take the imputed-height run value (AGM: v8.36)
pp <- list(AGM_v840_meas="AGM_v836",FVSACD_v131_hier_meas="FVSACD_v131_hier_dub",FVSACD_v14_L1_meas="FVSACD_v14_L1_dub",FVSACD_v14_L2_meas="FVSACD_v14_L2_dub")
pat <- rbindlist(lapply(names(pp), function(c){
  x <- merge(bp[model_config==c,.(PLOT,g=gross4_cd,v=tot_val)], ob[,.(PLOT,go=gross4_cd,vo=tot_val)], by="PLOT")
  y <- bp[model_config==pp[[c]] & PLOT %in% ftm,.(PLOT,g2=gross4_cd,v2=tot_val)]
  x <- merge(x,y,by="PLOT",all.x=TRUE); x[!is.na(g2), `:=`(g=g2,v=v2)]
  data.table(config=c,n=nrow(x),gross4_bias=round(bias(x$g,x$go),1),gross4_R2=round(r2(x$g,x$go),3),value_bias=round(bias(x$v,x$vo),1),value_R2=round(r2(x$v,x$vo),3))}))
fwrite(pat,"v32st_state_patched_ftm_DATA_2026-09-26.csv")
# rates by screen
ro <- rr[model_config=="OBSERVED"]
rt <- rbindlist(lapply(c("all65","refined_n51","refined_no_ftm_n49"), function(s) rbindlist(lapply(c("OBSERVED",CF[!grepl("dub",CF)]), function(c){
  x <- merge(rr[model_config==c,.(PLOT,v=pai_gross4_cdacyr,b=pai_ba_m2hayr,t=pai_tpa_yr)], ro[,.(PLOT,vo=pai_gross4_cdacyr,bo=pai_ba_m2hayr)], by="PLOT")[!PLOT %in% SCR[[s]]]
  data.table(screen=s,config=c,n=nrow(x),mean_volPAI=round(mean(x$v),4),mean_baPAI=round(mean(x$b),4),volPAI_bias=round(bias(x$v,x$vo),1),
             baPAI_bias=round(bias(x$b,x$bo),1),mean_net_stem_loss_tpa_yr=round(mean(x$t),2))}))))
fwrite(rt,"v32st_rates_by_screen_DATA_2026-09-26.csv")
# paired plot bootstrap of bias differences (gross4)
bt <- function(c1,c2,s,var="gross4_cd",tab=bp,obs=ob){
  x <- merge(merge(tab[model_config==c1,.(PLOT,a=get(var))],tab[model_config==c2,.(PLOT,b=get(var))],by="PLOT"),obs[,.(PLOT,o=get(var))],by="PLOT")[!PLOT %in% SCR[[s]]]
  f <- function(i) 100*(mean(x$a[i])-mean(x$b[i]))/mean(x$o[i]); n <- nrow(x)
  bs <- replicate(B, f(sample.int(n,n,TRUE)))
  data.table(metric=var,screen=s,a=c1,b=c2,n=n,diff=round(f(seq_len(n)),1),lo95=round(quantile(bs,.025),1),hi95=round(quantile(bs,.975),1))}
P <- list(c("AGM_v836","AGM_v840_meas"),c("FVSACD_v131_hier_dub","FVSACD_v131_hier_meas"),c("FVSACD_v14_L1_dub","FVSACD_v14_L1_meas"),
          c("FVSACD_v14_L2_dub","FVSACD_v14_L2_meas"),c("AGM_v840_meas","FVSACD_v131_hier_meas"),c("AGM_v840_meas","FVSACD_v14_L2_meas"))
bo <- rbindlist(lapply(P, function(p) rbindlist(lapply(c("all65","refined_n51"), function(s) bt(p[1],p[2],s)))))
rP <- list(c("AGM_v840_meas","FVSACD_v131_hier_meas"),c("AGM_v840_meas","FVSACD_v14_L2_meas"))
bo2 <- rbindlist(lapply(rP, function(p) bt(p[1],p[2],"refined_n51","pai_ba_m2hayr",rr,ro)))
fwrite(rbind(bo,bo2),"v32st_bootstrap_DATA_2026-09-26.csv")
print(st[screen %in% c("all65","no_ftm_n63")]); print(pat); print(rt); print(rbind(bo,bo2))

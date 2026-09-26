#!/usr/bin/env Rscript
# v33 stress test (26 September 2026): 14.0.4 and 14.1 cells, same screens, bootstrap and seed as the v32
# stress test (v32_stresstest/stresstest_v32_SCRIPT_2026-09-26.R). No em dashes.
suppressPackageStartupMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi/v33_v141"); set.seed(20260926); B <- 5000
bp <- fread("silc_cfi_v33_byplot_primary_DATA_2026-09-26.csv")
rr <- fread("silc_cfi_rates_byplot_v33_DATA_2026-09-26.csv")
loss14 <- c(1106,1273,1196,1130,1194,1193,1232,1234,1235,1244,1251,1200,1205,1206); ftm <- c(1150,1178)
SCR <- list(all65=integer(), refined_n51=c(setdiff(loss14,1106),1133), no_ftm_n63=ftm, refined_no_ftm_n49=c(setdiff(loss14,1106),1133,ftm))
CF <- c("AGM_v840_meas","FVSACD_v131_hier_meas","FVSACD_v14_L2_meas","FVSACD_v1404_meas","FVSACD_v1404_dub","FVSACD_v1404_ftmfix",
        "FVSACD_v141_meas","FVSACD_v141_dub","FVSACD_v141_ftmfix")
ob <- bp[model_config=="OBSERVED"]
bias <- function(p,o) 100*(mean(p)-mean(o))/mean(o); r2 <- function(p,o) 1-sum((p-o)^2)/sum((o-mean(o))^2)
st <- rbindlist(lapply(names(SCR), function(s) rbindlist(lapply(CF, function(c){
  x <- merge(bp[model_config==c,.(PLOT,g=gross4_cd,v=tot_val)], ob[,.(PLOT,go=gross4_cd,vo=tot_val)], by="PLOT")[!PLOT %in% SCR[[s]]]
  data.table(screen=s,config=c,n=nrow(x),gross4_bias=round(bias(x$g,x$go),1),gross4_R2=round(r2(x$g,x$go),3),value_bias=round(bias(x$v,x$vo),1),value_R2=round(r2(x$v,x$vo),3))}))))
fwrite(st,"v33st_state_by_screen_DATA_2026-09-26.csv")
ro <- rr[model_config=="OBSERVED"]
rt <- rbindlist(lapply(c("all65","refined_n51"), function(s) rbindlist(lapply(c("OBSERVED",CF), function(c){
  x <- merge(rr[model_config==c,.(PLOT,v=pai_gross4_cdacyr,b=pai_ba_m2hayr,q=pai_qmd_inyr,t=pai_tpa_yr)], ro[,.(PLOT,vo=pai_gross4_cdacyr,bo=pai_ba_m2hayr)], by="PLOT")[!PLOT %in% SCR[[s]]]
  data.table(screen=s,config=c,n=nrow(x),mean_volPAI=round(mean(x$v),4),mean_baPAI=round(mean(x$b),4),volPAI_bias=round(bias(x$v,x$vo),1),baPAI_bias=round(bias(x$b,x$bo),1),mean_qmdPAI_inyr=round(mean(x$q),4),mean_net_stem_change_tpa_yr=round(mean(x$t),2))}))))
fwrite(rt,"v33st_rates_by_screen_DATA_2026-09-26.csv")
bt <- function(c1,c2,s,var="gross4_cd",tab=bp,obs=ob){
  x <- merge(merge(tab[model_config==c1,.(PLOT,a=get(var))],tab[model_config==c2,.(PLOT,b=get(var))],by="PLOT"),obs[,.(PLOT,o=get(var))],by="PLOT")[!PLOT %in% SCR[[s]]]
  f <- function(i) 100*(mean(x$a[i])-mean(x$b[i]))/mean(x$o[i]); n <- nrow(x); bs <- replicate(B, f(sample.int(n,n,TRUE)))
  data.table(metric=var,screen=s,a=c1,b=c2,n=n,diff=round(f(seq_len(n)),1),lo95=round(quantile(bs,.025),1),hi95=round(quantile(bs,.975),1))}
P <- list(c("FVSACD_v141_meas","FVSACD_v1404_meas"),c("FVSACD_v141_dub","FVSACD_v141_meas"),c("FVSACD_v1404_dub","FVSACD_v1404_meas"),
          c("FVSACD_v1404_meas","FVSACD_v14_L2_meas"),c("FVSACD_v141_meas","FVSACD_v14_L2_meas"),c("AGM_v840_meas","FVSACD_v141_meas"),
          c("FVSACD_v141_meas","FVSACD_v141_ftmfix"),c("FVSACD_v1404_meas","FVSACD_v1404_ftmfix"))
bo <- rbindlist(lapply(P, function(p) rbindlist(lapply(c("all65","refined_n51"), function(s) bt(p[1],p[2],s)))))
bo2 <- rbindlist(lapply(list(c("FVSACD_v141_meas","FVSACD_v1404_meas"),c("AGM_v840_meas","FVSACD_v141_meas")), function(p) bt(p[1],p[2],"refined_n51","pai_ba_m2hayr",rr,ro)))
fwrite(rbind(bo,bo2),"v33st_bootstrap_DATA_2026-09-26.csv")
x <- merge(bp[model_config=="FVSACD_v141_meas",.(PLOT,p=gross4_cd)], ob[,.(PLOT,o=gross4_cd)], by="PLOT")
l <- rbindlist(lapply(x$PLOT, function(k){y<-x[PLOT!=k]; data.table(left_out=k,bias=round(bias(y$p,y$o),2),R2=round(r2(y$p,y$o),3))}))
fwrite(l,"v33st_loo_v141_DATA_2026-09-26.csv")
d <- merge(bp[model_config=="FVSACD_v141_meas",.(PLOT,a=gross4_cd)], bp[model_config=="FVSACD_v1404_meas",.(PLOT,b=gross4_cd)], by="PLOT")
cat("L effect per plot (cd/ac): "); print(summary(d$a-d$b)); cat("share raised", mean(d$a>d$b+1e-9), " share equal", mean(abs(d$a-d$b)<1e-9), "\n")
fwrite(d[, .(PLOT, v141=round(a,4), v1404=round(b,4), diff=round(a-b,4))], "v33st_L_effect_by_plot_DATA_2026-09-26.csv")
print(st[screen %in% c("all65","refined_n51")]); print(rt); print(rbind(bo,bo2)); print(range(l$bias)); print(range(l$R2))

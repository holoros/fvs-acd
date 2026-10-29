## boot_ci_allsites.R -- bootstrap 95% CIs on the all-sites total-volume bias.
## Bias is a ratio of means, 100*(mean(pred)/mean(obs)-1), so the CI is taken by
## resampling STANDS with replacement rather than by any normal approximation.
## Aggregates only.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths()))
suppressMessages(library(data.table))
V<-"/users/PUOM0008/crsfaaron/magplot/verify"; setwd(V)
set.seed(20260804); B<-4000
bias<-function(o,p) 100*(mean(p)/mean(o)-1)
boot<-function(R){
  n<-nrow(R); if(n<5) return(c(NA,NA,NA))
  est<-bias(R$TOTVOL_o,R$TOTVOL_p)
  bs<-replicate(B,{i<-sample.int(n,n,TRUE); bias(R$TOTVOL_o[i],R$TOTVOL_p[i])})
  c(est,unname(quantile(bs,c(.025,.975),na.rm=TRUE)))
}
J<-list(
 list(src="Baxter (mature, held out)", f=c(base="base_baxter_results.csv",v1211="cand_baxter_results.csv",osm="osm_score_baxter_results.csv"),pv=NA),
 list(src="CFRU CTRN (managed)",       f=c(base="base_ctrn_results.csv",v1211="cand_ctrn_results.csv",osm="osm_score_ctrn_results.csv"),pv=NA),
 list(src="Maine FIA (developing)",    f=c(base="base_mefia_l_results.csv",v1211="cand_mefia_l_results.csv",osm="osm_score_me_fia_l_results.csv"),pv=NA),
 list(src="Penobscot Exp. Forest",     f=c(base="base_pef_results.csv",v1211="cand_pef_results.csv",osm="osm_score_pef_results.csv"),pv=NA),
 list(src="SILC/Seven Islands CFI",    f=c(base="base_silc_l_results.csv",v1211="cand_silc_l_results.csv",osm="osm_score_silc_l_results.csv"),pv=NA),
 list(src="NB MagPlot (managed)",      f=c(base="base_nb_results.csv",v1211="cand_nb_results.csv",osm="g4_osm_score_nb_results.csv"),pv="NB"),
 list(src="QC MagPlot (managed)",      f=c(base="base_nb_results.csv",v1211="cand_nb_results.csv"),pv="QC")
)
out<-list()
for(j in J) for(m in names(j$f)){
  fp<-j$f[[m]]; if(!file.exists(fp)){cat("missing",fp,"\n"); next}
  R<-fread(fp)
  if(!all(c("TOTVOL_o","TOTVOL_p")%in%names(R))) next
  if(!is.na(j$pv)){ if(!"PROV"%in%names(R)) next; R<-R[PROV==j$pv] }
  R<-R[is.finite(TOTVOL_o)&is.finite(TOTVOL_p)&TOTVOL_o>0]
  b<-boot(R)
  out[[length(out)+1]]<-data.table(source=j$src,model=m,n=nrow(R),
    bias_pct=round(b[1],4),bias_lo95=round(b[2],4),bias_hi95=round(b[3],4))
}
RT<-rbindlist(out); print(RT)
fwrite(RT,file.path(V,"allsites_bias_ci.csv"))
cat("\nDONE_BOOT_CI\n")

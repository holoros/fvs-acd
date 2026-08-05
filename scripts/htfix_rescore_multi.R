## htfix_rescore_multi.R
## Rescores benchmark sources under three height treatments to separate the
## diameter-only-curve artifact from real model bias. Reuses the validated
## group height curve from htprov/htprov_hd_coefs.csv. Aggregates only.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths()))
suppressMessages(library(data.table))
V<-"/users/PUOM0008/crsfaaron/magplot/verify"; MS<-file.path(V,"multisrc"); setwd(V)
IN_CM<-2.54; FT_M<-0.3048; FT3_M3<-0.0283168
co<-fread("nsvb_emulator_coefs.csv"); sp2g<-fread("spcd_spgrpcd.csv")
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=833,BC=762,PR=761,ST=315,HH=701,SB=935,RB=370,AS=541,SW=298,HW=998,OH=998,OS=298,PC=68)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes<-names(AGY2SPCD); spcd2grp<-setNames(sp2g$SPGRPCD,as.character(sp2g$SPCD))
agy_grp<-sapply(AGY2SPCD,function(s){g<-spcd2grp[as.character(s)];if(is.na(g))998L else as.integer(g)})
ci<-match(agy_grp,co$SPGRPCD); ci[is.na(ci)]<-match(998,co$SPGRPCD); ci[is.na(ci)]<-1
CF<-list(); for(r in c("VOLCFGRS")) CF[[r]]<-list(a=setNames(co[[paste0(r,"_a")]][ci],agy_codes),
  b=setNames(co[[paste0(r,"_b")]][ci],agy_codes), sm=setNames(co[[paste0(r,"_sm")]][ci],agy_codes))
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
cfd<-fread(file.path(V,"htprov","htprov_hd_coefs.csv"))
gS<-cfd[level=="group"&code=="SW"]; gH<-cfd[level=="group"&code=="HW"]
hfit_grp<-function(sp,d){isw<-sp%in%sw; 1.3+ifelse(isw,gS$a,gH$a)*(1-exp(-ifelse(isw,gS$b,gH$b)*d))^ifelse(isw,gS$c,gH$c)}
nsvb2<-function(agy,dbh,ht,resp,hfun){h<-ifelse(is.finite(ht)&ht>0,ht,hfun(agy,dbh))
  lX<-log((dbh/IN_CM)^2*(h/FT_M)); y<-CF[[resp]]$sm[agy]*exp(CF[[resp]]$a[agy]+CF[[resp]]$b[agy]*lX)
  y[!is.finite(y)]<-0; unname(y)}
sm<-function(d,hfun,use_meas){d2<-copy(d); d2[,HTuse:=if(use_meas) HT else NA_real_]
  d2[is.finite(DBH)&DBH>=4&is.finite(EXPF)&EXPF>0,
     .(BA=sum(pi*(DBH/200)^2*EXPF), TV=sum(nsvb2(AGY,DBH,HTuse,"VOLCFGRS",hfun)*EXPF)*FT3_M3), by=STAND]}
bp<-function(o,p) round(100*(mean(p)/mean(o)-1),2)

JOBS<-list(
 baxter=list(tree=file.path(MS,"bench_baxter_tree_t2.csv"),
   res=c(BASE="v131base_baxter_results.csv", V1211="cand_baxter_results.csv",
         V131="v131_baxter_results.csv", OSM="osm_score_baxter_results.csv")),
 ctrn=list(tree=file.path(MS,"bench_ctrn_tree_t2.csv"),
   res=c(BASE="base_ctrn_results.csv", V1211="cand_ctrn_results.csv", OSM="osm_score_ctrn_results.csv")),
 nb=list(tree=file.path(V,"magp_qcnb_tree_t2.csv"),
   res=c(BASE="base_nb_results.csv", V1211="cand_nb_results.csv", OSM="magp_qcnb_osm_results.csv"))
)
out<-list()
for(src in names(JOBS)){
  J<-JOBS[[src]]
  if(!file.exists(J$tree)){cat("MISSING TREE",src,J$tree,"\n"); next}
  DD<-fread(J$tree); setnames(DD,toupper(names(DD)))
  if(!"EXPF" %in% names(DD)) DD[,EXPF:=1]
  DD[,AGY:=mapsp(SP)]
  cov<-DD[is.finite(DBH)&DBH>=4,.(ba=sum(pi*(DBH/200)^2*EXPF),
        ba_m=sum(ifelse(is.finite(HT)&HT>0,pi*(DBH/200)^2*EXPF,0)))]
  cat(sprintf("\n### %s  measured-HT share of BA = %.2f%%\n",src,100*cov$ba_m/cov$ba))
  for(mdl in names(J$res)){
    f<-J$res[[mdl]]; if(!file.exists(f)){cat("  missing results:",mdl,f,"\n"); next}
    R<-fread(f); if(!all(c("STAND","TOTVOL_o","TOTVOL_p")%in%names(R))){cat("  bad cols",f,"\n"); next}
    dd<-DD[STAND %in% R$STAND]
    A<-sm(dd,himp,FALSE); setnames(A,2:3,c("BA_A","TV_A"))
    C<-sm(dd,himp,TRUE);  setnames(C,2:3,c("BA_C","TV_C"))
    G<-sm(dd,hfit_grp,TRUE); setnames(G,2:3,c("BA_G","TV_G"))
    MM<-Reduce(function(x,y) merge(x,y,by="STAND"),list(R[,.(STAND,TOTVOL_o,TOTVOL_p,BA_o,BA_p)],A,C,G))
    if(!nrow(MM)){cat("  no stand overlap",mdl,"\n"); next}
    out[[length(out)+1]]<-data.table(source=src,model=mdl,n=nrow(MM),
      repro_maxabs=max(abs(MM$TV_A-MM$TOTVOL_o)),
      bias_published=bp(MM$TOTVOL_o,MM$TOTVOL_p),
      bias_curve_only=bp(MM$TV_A,MM$TOTVOL_p),
      bias_meas_curve=bp(MM$TV_C,MM$TOTVOL_p),
      bias_meas_fitted=bp(MM$TV_G,MM$TOTVOL_p),
      BA_maxabsdiff=max(abs(MM$BA_o-MM$BA_G)))
  }
}
RT<-rbindlist(out,fill=TRUE); print(RT)
fwrite(RT,file.path(V,"htfix_rescore_multi.csv"))
cat("\nBA CONTROL max =",max(RT$BA_maxabsdiff,na.rm=TRUE),"\nDONE_HTFIX_MULTI\n")

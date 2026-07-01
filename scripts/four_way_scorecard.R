# Four-model quantitative scorecard: v12.5.0, v12.7.0, v12.7.1, OSM v2.26.1 vs observed,
# identical in-domain MagPlot NB/QC pairs, all metrics FIA NSVB. Adds bias%, RMSE, NSE, PAI bias.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M<-c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")

cb0<-fread("cb_v1270_results.csv"); cb1<-fread("cb_v1271cB_results.csv"); cb5<-fread("cb_v125_results.csv")
otl<-fread("osm_h2h_treelist.csv")

# OSM per-stand metrics via the SAME metric function used in score_headtohead.R
co<-fread("nsvb_emulator_coefs.csv"); sp2g<-fread("spcd_spgrpcd.csv")
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,RO=833,RN=833,BC=762,PR=761,ST=315,HH=701,SB=935,RB=370,AS=541,SW=298,HW=998,OH=998,OS=298,PC=68)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes<-names(AGY2SPCD); spcd2grp<-setNames(sp2g$SPGRPCD,as.character(sp2g$SPCD))
agy_grp<-sapply(AGY2SPCD,function(s){g<-spcd2grp[as.character(s)]; if(is.na(g)) 998L else as.integer(g)})
ci<-match(agy_grp,co$SPGRPCD); ci[is.na(ci)]<-match(998,co$SPGRPCD); ci[is.na(ci)]<-1
RESP<-c("VOLCFGRS","VOLCFNET","VOLCSNET","DRYBIO_AG"); CF<-list()
for(r in RESP) CF[[r]]<-list(a=setNames(co[[paste0(r,"_a")]][ci],agy_codes),b=setNames(co[[paste0(r,"_b")]][ci],agy_codes),sm=setNames(co[[paste0(r,"_sm")]][ci],agy_codes))
nsvb<-function(agy,d,ht,resp){h<-ifelse(is.finite(ht)&ht>0,ht,himp(agy,d));lX<-log((d/2.54)^2*(h/0.3048));a<-CF[[resp]]$a[agy];b<-CF[[resp]]$b[agy];s<-CF[[resp]]$sm[agy];y<-s*exp(a+b*lX);y[!is.finite(y)]<-0;unname(y)}
FT3<-0.0283168; LBK<-0.453592; SAWSW<-50; SAWHW<-75; PULP<-10
mapsp<-function(s){s<-toupper(s);ifelse(s%in%agy_codes,s,ifelse(s%in%sw,"OS","OH"))}
metrics<-function(sp,dbh,ht,expf){
  ok<-is.finite(dbh)&dbh>=4&is.finite(expf)&expf>0; sp<-mapsp(sp[ok]);dbh<-dbh[ok];ht<-ht[ok];expf<-expf[ok]
  if(!length(dbh)) return(setNames(rep(0,9),M))
  BA<-sum(pi*(dbh/200)^2*expf);TPH<-sum(expf);QMD<-sqrt((BA/TPH)/(pi/40000));SDI<-TPH*(QMD/25.0)^1.605
  o<-order(-dbh);cw<-cumsum(expf[o]);idx<-which(cw<=100);if(!length(idx))idx<-1;TOPHT<-mean(ifelse(is.finite(ht[o][idx]),ht[o][idx],himp(sp[o][idx],dbh[o][idx])))
  tot<-sum(nsvb(sp,dbh,ht,"VOLCFGRS")*expf)*FT3;mer<-sum(nsvb(sp,dbh,ht,"VOLCFNET")*expf)*FT3;saw<-sum(nsvb(sp,dbh,ht,"VOLCSNET")*expf)*FT3
  bio<-sum(nsvb(sp,dbh,ht,"DRYBIO_AG")*expf)*LBK/1000
  issw<-sp%in%sw;sawsw<-sum(nsvb(sp[issw],dbh[issw],ht[issw],"VOLCSNET")*expf[issw])*FT3;val<-sawsw*SAWSW+(saw-sawsw)*SAWHW+max(0,mer-saw)*PULP
  setNames(c(BA,SDI,QMD,TOPHT,tot,mer,saw,bio,val),M)}
otl[,STAND:=as.character(STAND)]
om<-otl[,as.list(metrics(SP,DBH,HT,EXPF)),by=STAND]

prov<-cb1[,.(STAND=as.character(STAND),PROV,esi_cov,iv)]
obs<-cb1[,c("STAND",paste0(M,"_o")),with=FALSE]; setnames(obs,c("STAND",M)); obs[,STAND:=as.character(STAND)]
t1<-cb1[,c("STAND",paste0(M,"_t1")),with=FALSE]; setnames(t1,c("STAND",M)); t1[,STAND:=as.character(STAND)]
f0<-cb0[,c("STAND",paste0(M,"_p")),with=FALSE]; setnames(f0,c("STAND",M)); f0[,STAND:=as.character(STAND)]
f1<-cb1[,c("STAND",paste0(M,"_p")),with=FALSE]; setnames(f1,c("STAND",M)); f1[,STAND:=as.character(STAND)]
f5<-cb5[,c("STAND",paste0(M,"_p")),with=FALSE]; setnames(f5,c("STAND",M)); f5[,STAND:=as.character(STAND)]

common<-Reduce(intersect,list(obs$STAND,f0$STAND,f1$STAND,f5$STAND,om$STAND))
pm<-merge(prov,data.table(STAND=common),by="STAND")
cat(sprintf("=== FOUR-WAY SCORECARD, in-domain common stands n=%d (NB %d, QC %d) ===\n",length(common),sum(pm$PROV=="NB"),sum(pm$PROV=="QC")))

modlist<-list(v125=f5,v1270=f0,v1271=f1,osm=om)
res<-list()
for(pv in c("NB","QC","POOLED")){
  st<-if(pv=="POOLED") pm$STAND else pm[PROV==pv]$STAND
  if(length(st)<5) next
  O<-obs[STAND%in%st]; T1<-t1[STAND%in%st]; setkey(O,STAND); setkey(T1,STAND)
  ivv<-pm[match(st,pm$STAND)]$iv
  for(mod in names(modlist)){
    P<-modlist[[mod]][STAND%in%st]; setkey(P,STAND)
    for(m in M){
      o<-O[[m]]; p<-P[[m]]; t1v<-T1[[m]]
      bias<-100*(mean(p)/mean(o)-1)
      rmse<-sqrt(mean((p-o)^2))
      nse<-1-sum((o-p)^2)/sum((o-mean(o))^2)
      paio<-mean((o-t1v)/ivv); paip<-mean((p-t1v)/ivv)
      res[[length(res)+1]]<-data.table(stratum=pv,model=mod,metric=m,n=length(st),
        obs_mean=mean(o),pred_mean=mean(p),bias_pct=bias,rmse=rmse,nse=nse,
        pai_obs=paio,pai_pred=paip,pai_bias=paip-paio)
    }
  }
}
R<-rbindlist(res)
R[,flag:=fifelse(abs(bias_pct)<5,"green",fifelse(abs(bias_pct)<15,"yellow","red"))]
fwrite(R,"four_way_scorecard.csv")
cat("Wrote four_way_scorecard.csv, rows:",nrow(R),"\n")
cat("DONE\n")

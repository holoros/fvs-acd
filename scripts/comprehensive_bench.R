# Comprehensive independent benchmark of AcadianGY on MagPlot QC+NB, all metrics on FIA NSVB.
# Metrics: BA, SDI, QMD, top height, total volume (NSVB VOLCFGRS), merch volume (VOLCFNET),
# sawlog volume (VOLCSNET), aboveground biomass (NSVB DRYBIO_AG), stand value ($/ha), each as a
# t2 LEVEL (obs vs pred) and a PAI (periodic annual increment). Self-thinning params are env-driven
# so the same harness runs v12.7.0 (ONSET 0.55 BETA 0.10) and v12.7.1 (0.45 / 0.20). Per-stand time
# guard avoids pathological-stand hangs. Volume/biomass via the NSVB emulator (R2 0.96-0.99 vs FIA NSVB).
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify"); source(Sys.getenv("MODEL_FILE","~/AcadianGY_12.7.0.r"))
ONSET<-as.numeric(Sys.getenv("ONSET","0.55")); BETA<-as.numeric(Sys.getenv("BETA","0.10")); TAG<-Sys.getenv("CONFIG_TAG","cb_v1270")
CSI_DEFAULT<-14
co<-fread("nsvb_emulator_coefs.csv"); sp2g<-fread("spcd_spgrpcd.csv"); setkey(sp2g,SPCD)
g2i<-function(g) match(g, co$SPGRPCD)
# AcadianGY 2-letter -> representative FIA SPCD
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=833,BC=762,PR=761,ST=315,HH=701,SB=935,RB=370,AS=541,GA=544,SW=298,HW=998,OH=998,OS=298,PC=68)
spcd_of<-function(agy){ s<-AGY2SPCD[as.character(agy)]; s[is.na(s)]<-998L; as.integer(s) }
# NSVB emulator: agy sp, dbh cm, ht m -> per-tree NSVB (metric) for each response
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
nsvb<-function(agy,dbh_cm,ht_m,resp){
  ht<-ifelse(is.finite(ht_m)&ht_m>0,ht_m,himp(agy,dbh_cm))
  Din<-dbh_cm/2.54; Hft<-ht/0.3048; lX<-log(Din^2*Hft)
  gi<-g2i(sp2g[.(spcd_of(agy)), SPGRPCD, on="SPCD"]); gi[is.na(gi)]<-which(co$SPGRPCD==998)[1]; if(all(is.na(gi))) gi[is.na(gi)]<-1
  a<-co[[paste0(resp,"_a")]][gi]; b<-co[[paste0(resp,"_b")]][gi]; sm<-co[[paste0(resp,"_sm")]][gi]
  yhat<-sm*exp(a+b*lX)            # cubic ft (vol) or lb (biomass)
  yhat[!is.finite(yhat)]<-0; yhat
}
FT3_M3<-0.0283168; LB_KG<-0.453592
# stand metrics from a tree list (sp, dbh cm, ht m, expf/ha)
SAWSW<-50; SAWHW<-75; PULP<-10   # illustrative Maine stumpage $/m3 (sawlog SW/HW, pulp)
metrics<-function(sp,dbh,ht,expf){
  live<-is.finite(dbh)&dbh>=4&is.finite(expf)&expf>0
  sp<-sp[live];dbh<-dbh[live];ht<-ht[live];expf<-expf[live]
  if(!length(dbh)) return(c(BA=0,SDI=0,QMD=0,TOPHT=0,TOTVOL=0,MERCHVOL=0,SAWVOL=0,BIOMASS=0,VALUE=0))
  BA<-sum(pi*(dbh/200)^2*expf); TPH<-sum(expf); QMD<-sqrt((BA/TPH)/(pi/40000))
  SDI<-sum((dbh/25.4)^1.6*expf)*0 + sum((QMD/25.4)^1.605)*TPH*0 + TPH*(QMD/25.0)^1.605  # Reineke SDI (QMD cm/25 ~ 10in ref)
  o<-order(-dbh); cw<-cumsum(expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1; TOPHT<-mean(ifelse(is.finite(ht[o][idx]),ht[o][idx],himp(sp[o][idx],dbh[o][idx])))
  tot<-sum(nsvb(sp,dbh,ht,"VOLCFGRS")*expf)*FT3_M3; mer<-sum(nsvb(sp,dbh,ht,"VOLCFNET")*expf)*FT3_M3; saw<-sum(nsvb(sp,dbh,ht,"VOLCSNET")*expf)*FT3_M3
  bio<-sum(nsvb(sp,dbh,ht,"DRYBIO_AG")*expf)*LB_KG/1000   # tonnes/ha
  issw<-sp %in% sw; sawv_sw<-sum(nsvb(sp[issw],dbh[issw],ht[issw],"VOLCSNET")*expf[issw])*FT3_M3; sawv_hw<-saw-sawv_sw
  val<-sawv_sw*SAWSW + sawv_hw*SAWHW + max(0,mer-saw)*PULP
  c(BA=BA,SDI=SDI,QMD=QMD,TOPHT=TOPHT,TOTVOL=tot,MERCHVOL=mer,SAWVOL=saw,BIOMASS=bio,VALUE=val)
}
prs<-fread("magp_qcnb_pairs.csv"); ti<-fread("magp_qcnb_tree_init.csv"); t2<-fread("magp_qcnb_tree_t2.csv")
e8<-fread("magp_qcnb_site_esi8.csv"); e8[,esi8:=as.numeric(esi8)]; prs<-merge(prs,e8,by="SITE",all.x=TRUE)
prs[,csi_site:=ifelse(is.finite(esi8)&esi8>2,esi8,CSI_DEFAULT)][,esi_cov:=is.finite(esi8)&esi8>2]
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
bf<-function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
ops<<-make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort<-TRUE;ops$sdimort.onset<-ONSET;ops$sdimort.beta<-BETA;ops$sdimort.max<-1.0;ops$sdimax.site.term<-FALSE;ops$use.mortcal<-FALSE
setkey(ti,STAND);setkey(t2,STAND);setDF(prs)
MNAMES<-c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
out<-list();fail<-0
for(k in seq_len(nrow(prs))){ p<-prs[k,];sid<-p$STAND
  it<-ti[.(sid)];ot<-t2[.(sid)]; if(nrow(it)<3||nrow(ot)<3){fail<-fail+1;next}
  iv<-max(1,round(p$interval_years)); elev<-if(is.finite(p$ELEV)&&p$ELEV>0)p$ELEV else 200
  setTimeLimit(elapsed=7,transient=TRUE)
  res<-tryCatch({
    cur<-data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    csi_use<-if(is.finite(p$csi_site)&&p$csi_site>2)p$csi_site else CSI_DEFAULT; reg<-if(p$PROV=="NB")"NB" else "ME"
    stand<<-make_stand(stand.id=sid,csi=csi_use,elev=elev,region=reg)
    for(yr in seq_len(iv)){nx<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops); if(is.null(nx)||nrow(nx)==0)stop("empty"); cur<-bf(nx)}
    cur},error=function(e)NULL)
  setTimeLimit()
  if(is.null(res)){fail<-fail+1;next}
  m1<-metrics(mapsp(it$SP),it$DBH,it$HT,it$EXPF); m2o<-metrics(mapsp(ot$SP),ot$DBH,ot$HT,ot$EXPF); m2p<-metrics(res$sp,res$dbh,res$ht,res$expf)
  out[[k]]<-data.frame(STAND=sid,PROV=p$PROV,esi_cov=p$esi_cov,iv=iv,lat=p$lat,lon=p$lon,
    t(setNames(m1,paste0(MNAMES,"_t1"))),t(setNames(m2o,paste0(MNAMES,"_o"))),t(setNames(m2p,paste0(MNAMES,"_p"))))
}
r<-rbindlist(out,fill=TRUE); fwrite(r,paste0(TAG,"_results.csv"))
cat(sprintf("=== %s (ONSET %.2f BETA %.2f) MagPlot QC+NB, n=%d (%d fail) ===\n",TAG,ONSET,BETA,nrow(r),fail))
for(pv in c("NB","QC")){ s<-r[PROV==pv]; if(nrow(s)<5)next; cat(sprintf("-- %s n=%d --\n",pv,nrow(s)))
 for(M in MNAMES){ o<-s[[paste0(M,"_o")]];pp<-s[[paste0(M,"_p")]];t1<-s[[paste0(M,"_t1")]]
   lvb<-100*(mean(pp)/mean(o)-1); pao<-mean((o-t1)/s$iv); pap<-mean((pp-t1)/s$iv)
   cat(sprintf("   %-9s level obs %8.2f pred %8.2f bias %+6.1f%% | PAI obs %+7.3f pred %+7.3f bias %+7.3f\n",M,mean(o),mean(pp),lvb,pao,pap,pap-pao)) }}
cat("DONE\n")

# Comprehensive metric validation of AcadianGY 12.7.0 (ESI v8) on the regional
# NB/NS/ME remeasurement set: predicted-vs-observed on BA, SDI, QMD, top height,
# total volume, merch volume, sawlog MBF, and stumpage value. Height-free, single
# regional H-D applied identically to predicted and observed so the comparison is fair.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table); library(dplyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); source("value_fns.R")
source(Sys.getenv("MODEL_FILE","~/AcadianGY_12.7.0.r"))
MAXPR <- as.integer(Sys.getenv("MAXPLOTS_PER_REGION","400"))

plot_metrics <- function(sp, dbh_cm, expf){
  ok <- is.finite(dbh_cm)&is.finite(expf)&dbh_cm>0; sp<-sp[ok]; d<-dbh_cm[ok]; e<-expf[ok]
  sw <- .spgrp(sp) %in% c("PINE","SF","OSW")
  ht <- ifelse(sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
  live <- d>=4; merch <- d>=11.43
  BA <- sum(pi*(d[merch]/200)^2*e[merch]); TPH<-sum(e[merch])
  QMD <- if(TPH>0) sqrt((BA/TPH)/(pi/40000)) else NA_real_
  SDI <- sum((d[live]/25.4)^1.6 * e[live])
  o<-order(d,decreasing=TRUE); cs<-cumsum(e[o]); k<-which(cs>=100)[1]; if(is.na(k))k<-length(e)
  topht <- weighted.mean(ht[o][seq_len(k)], e[o][seq_len(k)], na.rm=TRUE)
  vol <- pi*(d/200)^2*ht*0.45
  totvol <- sum(vol[live]*e[live]); merchvol <- sum(vol[merch]*e[merch])
  pv <- plot_value(sp, d, e)
  data.frame(BA=BA, SDI=SDI, QMD=QMD, topht=topht, totvol=totvol, merchvol=merchvol,
             sawMBF=pv$sawMBF_ac, value=pv$value_ac)
}

d <- fread("/fs/scratch/PUOM0008/crsfaaron/maine_cfi/DBHout.csv", nThread=4,
           select=c("Source","Stand","Plot","year1","sp1","dbh1","expf1","climatesi","elev"))
setnames(d, c("sp1","dbh1","expf1","climatesi"), c("sp","dbh","expf","csi"))
d <- d[is.finite(dbh)&dbh>0&is.finite(expf)&expf>0&csi>0&csi<40]
d[, region := fifelse(Source=="Nova Scotia PSP","NS", fifelse(Source=="NB PSP","NB",
              fifelse(Source %in% c("PEF","FIA_99_05"),"ME","X")))]
d <- d[region!="X"]; d[, sp:=toupper(gsub('"','',sp))]
d[, pid := sprintf("%s_%s_%s_%d", region, gsub("[^A-Za-z0-9]","",as.character(Stand)), as.character(Plot), year1)]
d[, skey := sprintf("%s_%s_%s", region, gsub("[^A-Za-z0-9]","",as.character(Stand)), as.character(Plot))]
man <- fread("region_manifest_esi8.csv")
set.seed(3); man <- man[, .SD[sample(.N, min(.N,MAXPR))], by=region]
acadgy <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
swc <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
mapsp <- function(s){s<-toupper(s); ifelse(s %in% acadgy,s,ifelse(s %in% swc,"OS","OH"))}
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
o <- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
o$use.sdimort<-TRUE;o$sdimort.onset<-0.55;o$sdimort.beta<-0.10;o$sdimort.max<-1;o$sdimax.site.term<-FALSE;o$use.mortcal<-FALSE
ops<<-o; setDF(d); setDF(man)
P<-list(); O<-list()
for (k in seq_len(nrow(man))){
  m<-man[k,]; pid<-m$pid; t1<-m$t1; t2<-m$t2; skey<-sub("_[0-9]+$","",pid)
  it<-d[d$skey==skey & d$year1==t1,,drop=FALSE]
  ot<-d[d$skey==skey & d$year1==t2,,drop=FALSE]
  if(nrow(it)<5 || nrow(ot)<3) next
  cur<-data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$sp),dbh=it$dbh,ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=it$expf,
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
  stand<<-make_stand(stand.id=pid,csi=m$csi,elev=m$elev,region="ME"); okk<-TRUE
  for(yr in seq_len(m$remper)){nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL);if(is.null(nx)){okk<-FALSE;break};cur<-bf(nx)}
  if(!okk) next
  P[[pid]]<-data.frame(region=m$region,pid=pid,plot_metrics(cur$sp,cur$dbh,cur$expf))
  O[[pid]]<-data.frame(region=m$region,pid=pid,plot_metrics(mapsp(ot$sp),ot$dbh,ot$expf))
}
PR<-rbindlist(P); OB<-rbindlist(O)
mets<-c("BA","SDI","QMD","topht","totvol","merchvol","sawMBF","value")
cat(sprintf("=== v12.7.0 (ESI v8) full-metric validation, n=%d plots ===\n", nrow(PR)))
cat("region    ", paste(sprintf("%9s",mets),collapse=""), "\n")
for(rg in c("ALL","ME","NB","NS")){
  ip<-if(rg=="ALL") seq_len(nrow(PR)) else which(PR$region==rg)
  io<-if(rg=="ALL") seq_len(nrow(OB)) else which(OB$region==rg)
  b<-sapply(mets,function(mt){ round(100*(mean(PR[[mt]][ip],na.rm=T)/mean(OB[[mt]][io],na.rm=T)-1),1) })
  cat(sprintf("%-8s n=%-4d", rg, length(ip)), paste(sprintf("%+8.1f%%",b),collapse=""), "\n")
}
fwrite(PR,"region_pred_fullmetric.csv"); fwrite(OB,"region_obs_fullmetric.csv")
cat("DONE\n")

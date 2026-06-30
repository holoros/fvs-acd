# MagPlot QC+NB independent benchmark of AcadianGY 12.7.0 in the Hennigar 2018 frame.
# Scores MERCHANTABLE VOLUME INCREMENT (m3/ha/yr) by province, plus BA increment.
# Volume per tree = pi*(dbh/200)^2 * ht * FF (FF=0.45), merch dbh>=9.1cm, missing heights
# imputed by a single softwood/hardwood H-D so obs and pred volumes are strictly comparable.
# The relative increment bias (pred-obs, same volume function) is the Hennigar metric.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table) })
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
MODEL <- Sys.getenv("MODEL_FILE","~/AcadianGY_12.7.0.r"); source(MODEL)
TAG <- Sys.getenv("CONFIG_TAG","magp_qcnb_v1270"); CSI_DEFAULT <- 14
prs <- fread("magp_qcnb_pairs.csv"); ti <- fread("magp_qcnb_tree_init.csv"); t2 <- fread("magp_qcnb_tree_t2.csv")
prs[, STAND:=as.character(STAND)]; ti[, STAND:=as.character(STAND)]; t2[, STAND:=as.character(STAND)]
if (file.exists("magp_qcnb_site_esi8.csv")) {
  e8 <- fread("magp_qcnb_site_esi8.csv"); e8[, esi8:=as.numeric(esi8)]
  prs <- merge(prs, e8, by="SITE", all.x=TRUE)
  prs[, csi_site := ifelse(is.finite(esi8)&esi8>2, esi8, CSI_DEFAULT)]
  prs[, esi_cov := is.finite(esi8)&esi8>2]
} else { prs[, csi_site:=CSI_DEFAULT]; prs[, esi_cov:=FALSE] }
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
himp <- function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
FF <- 0.45; MERCH <- 9.1
vol <- function(sp,d,ht){ h<-ifelse(is.finite(ht)&ht>0,ht,himp(sp,d)); v<-pi*(d/200)^2*h*FF; sum(v[d>=MERCH]) }
acadgy <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
mapsp <- function(s){ s<-toupper(s); ifelse(s %in% acadgy, s, ifelse(s %in% sw,"OS","OH")) }
bf <- function(x){ for(c in c("ddbh.mult","dht.mult","mort.mult")) x[[c]][is.na(x[[c]])]<-1; x$max.dbh[is.na(x$max.dbh)]<-200; x$max.height[is.na(x$max.height)]<-50; x }
ops <<- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort<-TRUE; ops$sdimort.onset<-0.55; ops$sdimort.beta<-0.10; ops$sdimort.max<-1.0; ops$sdimax.site.term<-FALSE; ops$use.mortcal<-FALSE
setkey(ti,STAND); setkey(t2,STAND); setDF(prs)
out<-list(); fail<-0
for(k in seq_len(nrow(prs))){ p<-prs[k,]; sid<-p$STAND
  it<-ti[.(sid)]; ot<-t2[.(sid)]
  if(nrow(it)<3 || nrow(ot)<3){fail<-fail+1;next}
  iv<-max(1,round(p$interval_years)); elev<-if(is.finite(p$ELEV)&&p$ELEV>0)p$ELEV else 200
  cur<-data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA_real_,cr=NA_real_,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
  csi_use<-if(is.finite(p$csi_site)&&p$csi_site>2)p$csi_site else CSI_DEFAULT
  reg<-if(p$PROV=="NB")"NB" else "ME"
  stand<<-make_stand(stand.id=sid,csi=csi_use,elev=elev,region=reg); ok<-TRUE
  for(yr in seq_len(iv)){nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL);if(is.null(nx)||nrow(nx)==0){ok<-FALSE;break};cur<-bf(nx)}
  if(!ok){fail<-fail+1;next}
  live<-cur[cur$dbh>=4&is.finite(cur$dbh),]
  V1<-vol(mapsp(it$SP),it$DBH,it$HT); V2o<-vol(mapsp(ot$SP),ot$DBH,ot$HT); V2p<-vol(live$sp,live$dbh,live$ht)
  BA1<-sum(pi*(it$DBH/200)^2*it$EXPF); BA2o<-p$BA_t2_obs; BA2p<-sum(pi*(live$dbh/200)^2*live$expf)
  out[[k]]<-data.frame(STAND=sid,PROV=p$PROV,esi_cov=p$esi_cov,iv=iv,
    V1=V1,V2o=V2o,V2p=V2p,BA1=BA1,BA2o=BA2o,BA2p=BA2p,lat=p$lat,lon=p$lon)
}
r<-rbindlist(out)
r[, dVobs:=(V2o-V1)/iv]; r[, dVpred:=(V2p-V1)/iv]
r[, dBAobs:=(BA2o-BA1)/iv]; r[, dBApred:=(BA2p-BA1)/iv]
fwrite(r, paste0(TAG,"_results.csv"))
cat(sprintf("=== %s: MagPlot QC+NB, AcadianGY %s, n=%d (%d failed) ===\n",TAG,basename(MODEL),nrow(r),fail))
cat("VOLUME INCREMENT (m3/ha/yr), Hennigar metric:\n")
for(pv in c("NB","QC")){ s<-r[PROV==pv]; if(nrow(s)<5)next
  cat(sprintf("  %s n=%4d  obs %+.2f  pred %+.2f  bias %+.2f  RMSE %.2f  (ESI-cov n=%d)\n",
    pv,nrow(s),mean(s$dVobs),mean(s$dVpred),mean(s$dVpred-s$dVobs),sqrt(mean((s$dVpred-s$dVobs)^2)),sum(s$esi_cov))) }
cat("BA INCREMENT (m2/ha/yr):\n")
for(pv in c("NB","QC")){ s<-r[PROV==pv]; if(nrow(s)<5)next
  cat(sprintf("  %s n=%4d  obs %+.3f  pred %+.3f  bias %+.3f  RMSE %.3f\n",
    pv,nrow(s),mean(s$dBAobs),mean(s$dBApred),mean(s$dBApred-s$dBAobs),sqrt(mean((s$dBApred-s$dBAobs)^2)))) }
cat("BA LEVEL t2 bias:\n")
for(pv in c("NB","QC")){ s<-r[PROV==pv]; if(nrow(s)<5)next
  cat(sprintf("  %s  obs %.1f pred %.1f  bias %+.1f%%  R2 %.3f\n",pv,mean(s$BA2o),mean(s$BA2p),100*(mean(s$BA2p)/mean(s$BA2o)-1),1-sum((s$BA2p-s$BA2o)^2)/sum((s$BA2o-mean(s$BA2o))^2))) }
cat("DONE\n")

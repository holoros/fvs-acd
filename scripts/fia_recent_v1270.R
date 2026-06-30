# Recent Maine FIA INDEPENDENT benchmark of AcadianGY 12.7.0, scored on the ANNUAL
# INCREMENT. Pairs from ME_PLOT/ME_TREE (CN/PREV_PLT_CN, REMPER). Filtered to recent
# remeasurements (curr MEASYEAR >= 2010) so they are independent in time from the
# 1999-2005 FIA used to fit the increment equations. New 12.7.0 contract. Site is a
# weak BA lever (BA cap regulates), so a default site index is used; the metric is the
# annual BA increment bias and RMSE (the honest growth-model metric).
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table); library(dplyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); source("~/AcadianGY_12.7.0.r")
FIA <- "/users/PUOM0008/crsfaaron/fia_data"; CSI_DEFAULT <- 14
pl <- fread(file.path(FIA,"ME_PLOT.csv"), select=c("CN","PREV_PLT_CN","MEASYEAR","REMPER","LAT","LON","ELEV"))
pl[, CN:=as.character(CN)][, PREV_PLT_CN:=as.character(PREV_PLT_CN)]
pr <- pl[!is.na(PREV_PLT_CN) & PREV_PLT_CN!="" & PREV_PLT_CN!="NA" &
         is.finite(REMPER) & REMPER>=4 & REMPER<=15 & MEASYEAR>=2010]
cat("recent (>=2010) remeasurement pairs:", nrow(pr), "\n")
tr <- fread(file.path(FIA,"ME_TREE.csv"), select=c("PLT_CN","SPCD","DIA","HT","TPA_UNADJ","STATUSCD"))
tr[, PLT_CN:=as.character(PLT_CN)]; tr <- tr[STATUSCD==1 & is.finite(DIA) & DIA>0]
tr[, tpa := fifelse(is.finite(TPA_UNADJ)&TPA_UNADJ>0, TPA_UNADJ, fifelse(DIA<5,74.965,6.018))]
# observed metrics at t1 (prev) and t2 (curr): BA m2/ha (merch >= 4.5in)
bam <- function(d) 0.005454*d^2          # ft2/ac per tree-tpa (DIA in)
mm <- function(D) D>=4.5
obs2 <- tr[, .(BA_t2=sum(bam(DIA)*tpa*mm(DIA))/4.35), by=PLT_CN]   # -> m2/ha
obs1 <- tr[, .(BA_t1=sum(bam(DIA)*tpa*mm(DIA))/4.35), by=PLT_CN]
pr <- merge(pr, obs2, by.x="CN", by.y="PLT_CN"); pr <- merge(pr, obs1, by.x="PREV_PLT_CN", by.y="PLT_CN")
pr <- pr[is.finite(BA_t2)&BA_t2>0&is.finite(BA_t1)&BA_t1>0]
t1n <- tr[,.N,by=PLT_CN]; pr <- pr[PREV_PLT_CN %in% t1n$PLT_CN]
cat("pairs with t1+t2:", nrow(pr), "\n")
SPCD_to_AGY <- c("12"="BF","97"="RS","375"="PB","371"="YB","316"="RM","241"="WC","261"="EH","95"="BS","91"="WS","105"="JP","129"="WP","318"="SM","531"="BC","746"="QA","833"="RO","541"="WA","934"="GB","126"="PR","136"="RP","743"="BP","356"="HH","409"="EC","491"="PC")
agy <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
mapsp <- function(spcd){ s<-SPCD_to_AGY[as.character(spcd)]; s[is.na(s)]<-ifelse(spcd[is.na(s)]>=300,"OH","OS"); s }
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
ops <<- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort<-TRUE;ops$sdimort.onset<-0.55;ops$sdimort.beta<-0.10;ops$sdimort.max<-1;ops$sdimax.site.term<-FALSE;ops$use.mortcal<-FALSE
setkey(tr,PLT_CN); setDF(pr)
N <- min(nrow(pr), as.integer(Sys.getenv("NFIA","800"))); set.seed(7); pr<-pr[sample(nrow(pr),N),]
out<-list(); fail<-0
for(k in seq_len(nrow(pr))){ p<-pr[k,]; it<-tr[.(p$PREV_PLT_CN)]
  if(nrow(it)<5){fail<-fail+1;next}; iv<-max(1,round(p$REMPER)); elev<-if(is.finite(p$ELEV)&&p$ELEV>0)p$ELEV*0.3048 else 200
  cur<-data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SPCD),dbh=it$DIA*2.54,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT*0.3048,NA_real_),hcb=NA_real_,cr=NA_real_,expf=it$tpa*2.4710538147,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
  stand<<-make_stand(stand.id=p$CN,csi=CSI_DEFAULT,elev=elev,region="ME"); ok<-TRUE
  for(yr in seq_len(iv)){nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL);if(is.null(nx)){ok<-FALSE;break};cur<-bf(nx)}
  if(!ok){fail<-fail+1;next}
  live<-cur[cur$dbh>=11.43&is.finite(cur$dbh),]; BA_pred<-sum(pi*(live$dbh/200)^2*live$expf)
  out[[k]]<-data.frame(CN=p$CN,iv=iv,BA_t1=p$BA_t1,BA_t2=p$BA_t2,BA_pred=BA_pred)
}
r<-rbindlist(out); fwrite(r,"fia_recent_v1270_results.csv")
r[, dBA_obs:=(BA_t2-BA_t1)/iv]; r[, dBA_pred:=(BA_pred-BA_t1)/iv]
cat(sprintf("=== RECENT MAINE FIA (independent, >=2010), AcadianGY 12.7.0, n=%d (%d failed) ===\n",nrow(r),fail))
cat(sprintf("LEVEL: obs BA t2 %.1f  pred %.1f  bias %+.1f%%  R2 %.3f\n",mean(r$BA_t2),mean(r$BA_pred),100*(mean(r$BA_pred)/mean(r$BA_t2)-1),1-sum((r$BA_pred-r$BA_t2)^2)/sum((r$BA_t2-mean(r$BA_t2))^2)))
cat(sprintf("ANNUAL INCREMENT: obs %.3f  pred %.3f  bias %+.3f m2/ha/yr (%+.0f%%)  RMSE %.3f\n",mean(r$dBA_obs),mean(r$dBA_pred),mean(r$dBA_pred-r$dBA_obs),100*mean(r$dBA_pred-r$dBA_obs)/mean(r$dBA_obs),sqrt(mean((r$dBA_pred-r$dBA_obs)^2))))
cat("DONE\n")

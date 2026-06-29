# FVS-ACD vs OSM head-to-head on the Seven Islands stands. Projects AcadianGY
# 12.6.1 forward from the same OSM starting inventories and records the BA/QMD
# trajectory by 5-year age, to compare against OSM's silc_StandListProjections.
# Model-vs-model long-term comparison (no observed; forward to ~2106).
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table); library(dplyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); source("~/AcadianGY_12.6.1.r"); set.seed(7)
tr <- fread("silc_osm_trees.csv")          # SurveyID, Species, DBH(cm), HT(m), Stems(per ha)
lk <- fread("/users/PUOM0008/crsfaaron/OSM/work/silc_100yr_v4/silc_stand_id_lookup.csv")
setnames(lk, tolower(names(lk)))
acadgy <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
mapsp <- function(s){s<-toupper(s); ifelse(s %in% acadgy,s,ifelse(s %in% sw,"OS","OH"))}
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
o <- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0)
o$use.sdimort<-TRUE;o$sdimort.onset<-0.55;o$sdimort.beta<-0.10;o$sdimort.max<-1;o$sdimax.site.term<-FALSE;o$use.mortcal<-FALSE
ops <<- o
HORIZON <- 80; sids <- unique(tr$SurveyID); out <- list()
for (sid in sids){
  t1 <- tr[SurveyID==sid]; if(nrow(t1)<5) next
  csi <- lk$csi_m[match(sid, lk$surveyid)]; if(!is.finite(csi)) csi <- 14
  cur <- data.frame(year=0,plot=1L,tree=seq_len(nrow(t1)),sp=mapsp(t1$Species),
    dbh=t1$DBH, ht=ifelse(is.finite(t1$HT)&t1$HT>0,t1$HT,NA_real_), hcb=NA_real_, cr=NA_real_,
    expf=t1$Stems, form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,
    max.dbh=200,max.height=50,stringsAsFactors=FALSE)
  stand <<- make_stand(stand.id=as.character(sid), csi=csi, elev=305, region="ME")
  rec <- list(); ok<-TRUE
  for (yr in 0:HORIZON){
    if (yr>0){ nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL); if(is.null(nx)){ok<-FALSE;break}; cur<-bf(nx) }
    if (yr %% 5 == 0){ live<-cur[cur$dbh>=4 & is.finite(cur$dbh),]
      if(nrow(live)>0){ BAPH<-sum(pi*(live$dbh/200)^2*live$expf); TPH<-sum(live$expf); QMD<-sqrt((BAPH/TPH)/(pi/40000))
        rec[[length(rec)+1]]<-data.frame(SurveyID=sid, Age=yr, BA=BAPH, QMD=QMD, TPH=TPH) } } }
  if(ok && length(rec)) out[[as.character(sid)]] <- do.call(rbind, rec)
}
R <- rbindlist(out); fwrite(R, "fvsacd_osm_stands_traj.csv")
agg <- R[, .(BA=round(mean(BA),1), QMD=round(mean(QMD),1), TPH=round(mean(TPH),0), n=.N), by=Age][order(Age)]
fwrite(agg, "fvsacd_osm_traj_mean.csv")
cat("=== FVS-ACD 12.6.1 forward on", length(out), "Seven Islands OSM stands (mean by Age) ===\n"); print(agg)
cat("DONE\n")

# Long-horizon trajectories of AcadianGY 12.7.0 across a site (ESI) gradient, to read off the
# basal-area/SDI asymptote (the Bakuzis recalibration target). Projects a young pure spruce-fir
# stand on three ESI classes to 120 years; records HT(dom), TPH, BAPH, QMD, SDI, VOL by age.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify"); source("~/AcadianGY_12.5.0.r")
sw <- c("WP","RP","JP","RS","BF","BS","WS","EH","WC","TA","OS")
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
ops <<- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort<-TRUE; ops$sdimort.onset<-0.55; ops$sdimort.beta<-0.10; ops$sdimort.max<-1.0; ops$sdimax.site.term<-FALSE; ops$use.mortcal<-FALSE
init <- function(){ # young dense spruce-fir, ~3000 stems/ha, dbh ~2-4cm
  n<-40; data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("BF","RS","BS","WS"),each=n/4),
    dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=rep(3000/n,n),
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
sdi_of <- function(d){ live<-d[d$dbh>=4&is.finite(d$dbh),]; sum((live$dbh/25.4)^1.6*live$expf*(1/2.471)) } # SDI/ha metric->TPH (dbh cm->in)
out<-list()
for(esi in c(12,16,20)){
  cur<-init(); stand<<-make_stand(stand.id=paste0("E",esi),csi=esi,elev=200,region="ME")
  for(age in 1:120){
    nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL)
    if(is.null(nx)||nrow(nx)==0) break
    cur<-bf(nx)
    live<-cur[cur$dbh>=4&is.finite(cur$dbh),]
    if(nrow(live)<1) break
    ba<-sum(pi*(live$dbh/200)^2*live$expf); tph<-sum(live$expf); qmd<-sqrt((ba/tph)/(pi/40000))
    htd<-{o<-order(-live$dbh); cw<-cumsum(live$expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1; mean(live$ht[o][idx],na.rm=TRUE)}
    sdi<-sum((live$dbh/25.4)^1.6*live$expf)
    vol<-ba*ifelse(is.finite(htd),htd,15)*0.45
    out[[length(out)+1]]<-data.frame(group=paste0("ESI",esi),site=esi,age=age,HT=round(htd,2),TPH=round(tph,0),BAPH=round(ba,2),QMD=round(qmd,2),SDI=round(sdi,0),VOL=round(vol,1))
  }
}
tr<-rbindlist(out); fwrite(tr,"traj_v125.csv")
cat("=== v12.5.0 long-horizon asymptotes (max over age, by site) ===\n")
for(g in unique(tr$group)){ s<-tr[group==g]
  cat(sprintf("%s: BA max %.1f @age%d | SDI max %.0f @age%d | TPH@120 %.0f | QMD@120 %.1f | HTdom@120 %.1f\n",
    g, max(s$BAPH), s$age[which.max(s$BAPH)], max(s$SDI), s$age[which.max(s$SDI)],
    s$TPH[s$age==max(s$age)], s$QMD[s$age==max(s$age)], s$HT[s$age==max(s$age)])) }
cat("DONE\n")

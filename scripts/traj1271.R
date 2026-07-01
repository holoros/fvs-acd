# 160-yr trajectory for v12.7.1 coupled self-thinning; reads plateau + oscillation.
# Slopes come from env: BG (gentle), BS (steep), ONSET, BREAK.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify"); source("~/AcadianGY_12.7.1.r")
BG<-as.numeric(Sys.getenv("BG","0.03")); BS<-as.numeric(Sys.getenv("BS","0.30"))
ONSET<-as.numeric(Sys.getenv("ONSET","0.30")); BREAK<-as.numeric(Sys.getenv("BREAK","0.60"))
IRC<-as.numeric(Sys.getenv("IRC","0.55")); IRK<-as.numeric(Sys.getenv("IRK","8"))
SDMAX<-as.numeric(Sys.getenv("SDMAX","1.0")); IMULT<-as.numeric(Sys.getenv("IMULT","1.0"))
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
ops <<- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort<-TRUE; ops$sdimort.onset<-ONSET; ops$sdimort.break<-BREAK
ops$sdimort.beta.gentle<-BG; ops$sdimort.beta.steep<-BS; ops$sdimort.max<-SDMAX; ops$ingrowth.mult<-IMULT
ops$sdimax.site.term<-FALSE; ops$use.mortcal<-FALSE
ops$use.ingrowth.release<-TRUE; ops$ingrowth.rd.center<-IRC; ops$ingrowth.rd.k<-IRK
init <- function(){ n<-40; data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("BF","RS","BS","WS"),each=n/4),
    dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=rep(3000/n,n),
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
out<-list()
set.seed(1)
for(esi in c(12,16,20)){
  cur<-init(); stand<<-make_stand(stand.id=paste0("E",esi),csi=esi,elev=200,region="ME")
  for(age in 1:160){
    nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL)
    if(is.null(nx)||nrow(nx)==0) break
    cur<-bf(nx)
    live<-cur[cur$dbh>=4&is.finite(cur$dbh),]
    if(nrow(live)<1) break
    ba<-sum(pi*(live$dbh/200)^2*live$expf); tph<-sum(live$expf); qmd<-sqrt((ba/tph)/(pi/40000))
    htd<-{o<-order(-live$dbh); cw<-cumsum(live$expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1; mean(live$ht[o][idx],na.rm=TRUE)}
    sdi<-sum((live$dbh/25.4)^1.6*live$expf)
    out[[length(out)+1]]<-data.frame(group=paste0("ESI",esi),site=esi,age=age,HT=round(htd,2),TPH=round(tph,0),BAPH=round(ba,2),QMD=round(qmd,2),SDI=round(sdi,0))
  }
}
tr<-rbindlist(out); fwrite(tr, paste0("traj_v1271_", Sys.getenv("TAG","a"), ".csv"))
# oscillation stats: on ages>=60, detrended BA range and peak-to-peak period
osc<-function(s){ z<-s[age>=50]; if(nrow(z)<10) return(c(NA,NA,NA))
  pk<-max(z$BAPH); tr2<-min(z$BAPH[z$age>=z$age[which.max(z$BAPH)]])
  amp<-pk-tr2
  # crude period: mean age spacing between local maxima
  b<-z$BAPH; loc<-which(diff(sign(diff(b)))==-2)+1; ages<-z$age[loc]
  per<-if(length(ages)>=2) mean(diff(ages)) else NA
  c(pk,amp,per) }
cat(sprintf("=== v12.7.1 coupled ONSET %.2f BREAK %.2f BG %.3f BS %.3f IRC %.2f IRK %.1f ===\n",ONSET,BREAK,BG,BS,IRC,IRK))
for(g in unique(tr$group)){ s<-tr[group==g]
  o<-osc(s); pl<-mean(s$BAPH[s$age>=90&s$age<=140])
  cat(sprintf("%s: BAmax %.1f @age%d | plateau(90-140) %.1f | oscPeak %.1f amp %.1f period ~%.0f | BA@160 %.1f | SDI@160 %.0f TPH@160 %.0f QMD@160 %.1f HT@160 %.1f\n",
    g, max(s$BAPH), s$age[which.max(s$BAPH)], pl, o[1], o[2], o[3],
    s$BAPH[s$age==max(s$age)], s$SDI[s$age==max(s$age)], s$TPH[s$age==max(s$age)], s$QMD[s$age==max(s$age)], s$HT[s$age==max(s$age)])) }
cat("DONE\n")

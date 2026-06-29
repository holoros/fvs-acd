# Bakuzis Reineke self-thinning test for AcadianGY 12.6.0.
# Projects an even-aged stand 120 yr across a site gradient under five configs
# and reports the realized Reineke slope (target -1.605). Uses the 12.6 contract;
# calc_* read GLOBAL `stand`/`ops`, so both are assigned to the global env.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
source("~/AcadianGY_12.6.0.r"); set.seed(47)

project <- function(ops_extra){
  out <- list()
  for (csi in c(8,11,14,17,20)){
    n<-200; d0<-pmax(2,rnorm(n,4,1))
    cur<-data.frame(year=0,plot=1L,tree=1:n,sp=sample(c("BF","RS","RM","YB","SM"),n,TRUE,prob=c(.4,.2,.2,.1,.1)),
      dbh=d0,ht=1.3+25*(1-exp(-0.04*d0)),hcb=NA_real_,cr=NA_real_,
      expf=rep(2500/n,n),form=NA_character_,risk=NA_character_,
      ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    o<-make_ops(verbose=FALSE,use.ingrowth=FALSE)
    for(nm in names(ops_extra)) o[[nm]]<-ops_extra[[nm]]
    ops<<-o; stand<<-make_stand("BZ",csi=csi,elev=305,region="ME")
    rec<-list()
    for(y in 1:120){
      nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL); if(is.null(nx))break
      for(cc in c("ddbh.mult","dht.mult","mort.mult")) nx[[cc]][is.na(nx[[cc]])]<-1
      nx$max.dbh[is.na(nx$max.dbh)]<-200; nx$max.height[is.na(nx$max.height)]<-50
      cur<-nx
      if(y%%5==0){ live<-cur[cur$dbh>=4 & is.finite(cur$dbh),]
        if(nrow(live)>0){ BAPH<-sum(pi*(live$dbh/200)^2*live$expf); TPH<-sum(live$expf)
          QMD<-sqrt((BAPH/TPH)/(pi/40000)); rec[[length(rec)+1]]<-data.frame(site=csi,age=y,TPH=TPH,QMD=QMD,BAPH=BAPH) } } }
    out[[as.character(csi)]]<-do.call(rbind,rec)
  }
  do.call(rbind,out)
}
reineke <- function(tr){
  sl<-sapply(unique(tr$site),function(s){g<-tr[tr$site==s,];g<-g[order(g$age),];keep<-c(TRUE,diff(g$QMD)>0.5);g<-g[keep,]
    if(nrow(g)>=4 && sd(log(g$QMD))>1e-3) coef(lm(log(TPH)~log(QMD),g))[2] else NA}); mean(sl,na.rm=TRUE)}

configs<-list(
  legacy  = list(use.sdimort=FALSE, sdimax.site.term=TRUE,  use.mortcal=FALSE),
  v126def = list(use.sdimort=TRUE,  sdimort.beta=0.10, sdimort.onset=0.55, sdimort.max=1.0, sdimax.site.term=FALSE, use.mortcal=FALSE),
  b15     = list(use.sdimort=TRUE,  sdimort.beta=0.15, sdimort.onset=0.55, sdimort.max=1.0, sdimax.site.term=FALSE, use.mortcal=FALSE),
  b20     = list(use.sdimort=TRUE,  sdimort.beta=0.20, sdimort.onset=0.55, sdimort.max=1.0, sdimax.site.term=FALSE, use.mortcal=FALSE),
  mortcal = list(use.sdimort=FALSE, sdimax.site.term=TRUE, use.mortcal=TRUE, mortcal.interval=5, mortcal.lambda=1))
res<-list()
for(cn in names(configs)){ tr<-project(configs[[cn]]); write.csv(tr,paste0("bz_v126_",cn,".csv"),row.names=FALSE)
  sl<-reineke(tr); g14<-tr[tr$site==14,]; te<-if(nrow(g14))tail(g14$TPH,1) else NA
  res[[cn]]<-data.frame(config=cn,reineke_slope=round(sl,2),tph_end_site14=round(te,0),ordered=cn)
  cat(cn," Reineke",round(sl,2)," TPHend(14)",round(te,0),"\n") }
# site ordering check: does higher site carry more volume (BAPH) at age 60? (Bakuzis site ordering)
ord<-do.call(rbind,res); write.csv(ord,"bz_v126_reineke.csv",row.names=FALSE)
cat("\n=== v12.6 Bakuzis Reineke slope by config (target -1.605) ===\n"); print(ord[,1:3],row.names=FALSE); cat("DONE\n")

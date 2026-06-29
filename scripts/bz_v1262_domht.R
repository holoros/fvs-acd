# v12.6.2 prototype: does the ESI-anchored dominant-height constraint separate the
# Bakuzis site curves? Even-aged (ingrowth off) so site curves are clean. Two configs:
# domht OFF (= 12.6.1 height) and domht ON. Emits site,age,HT,TPH,BAPH,QMD,VOL.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); source("~/AcadianGY_12.6.2_proto.r"); set.seed(47)
topht<-function(ht,dbh,expf){o<-order(dbh,decreasing=TRUE);ht<-ht[o];e<-expf[o];cs<-cumsum(e);k<-which(cs>=100)[1];if(is.na(k))k<-length(e);weighted.mean(ht[1:k],e[1:k],na.rm=TRUE)}
bf<-function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
gen <- function(domht){
  rec<-list()
  for (csi in c(8,11,14,17,20)){
    n<-200; d0<-pmax(2,rnorm(n,4,1))
    cur<-data.frame(year=0,plot=1L,tree=1:n,sp=sample(c("BF","RS","RM","YB","SM"),n,TRUE,prob=c(.4,.2,.2,.1,.1)),
      dbh=d0,ht=1.3+25*(1-exp(-0.04*d0)),hcb=NA_real_,cr=NA_real_,expf=rep(2500/n,n),
      form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    o<-make_ops(verbose=FALSE,use.ingrowth=FALSE)
    o$use.sdimort<-TRUE;o$sdimort.onset<-0.55;o$sdimort.beta<-0.10;o$sdimort.max<-1.0;o$sdimax.site.term<-FALSE
    o$use.mortcal<-FALSE; o$use.esi.domht<-domht; o$esi.domht.gain<-1
    ops<<-o; stand<<-make_stand("BZ",csi=csi,elev=305,region="ME")
    for (yr in 1:150){ nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL); if(is.null(nx))break; cur<-bf(nx)
      if (yr%%5==0){ live<-cur[cur$dbh>=4 & is.finite(cur$dbh),]
        if(nrow(live)>0){ BAPH<-sum(pi*(live$dbh/200)^2*live$expf);TPH<-sum(live$expf);QMD<-sqrt((BAPH/TPH)/(pi/40000));HT<-topht(live$ht,live$dbh,live$expf)
          rec[[length(rec)+1]]<-data.frame(site=csi,age=yr,HT=round(HT,2),TPH=round(TPH,1),BAPH=round(BAPH,2),QMD=round(QMD,2),VOL=round(BAPH*HT*0.45,2)) } } }
  }
  do.call(rbind,rec)
}
write.csv(gen(FALSE),"bz_v1262_domht_off.csv",row.names=FALSE)
write.csv(gen(TRUE), "bz_v1262_domht_on.csv", row.names=FALSE)
# quick HT-separation summary at age 50/100
for (f in c("bz_v1262_domht_off.csv","bz_v1262_domht_on.csv")){ t<-read.csv(f)
  cat("\n",f,"\n"); for(a in c(50,100,150)){s<-t[t$age==a,];cat(" age",a,"HT:",paste(s$site,round(s$HT,1),sep="=",collapse=" "),"\n")} }
cat("DONE\n")

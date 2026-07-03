.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
source("~/AcadianGY_12.10.r")
cat("VersionTag:", AcadianVersionTag, "\n")
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
base_ops <- function(){
  o <- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
  o$use.sdimort<-TRUE;o$sdimort.onset<-0.30;o$sdimort.break<-0.62;o$sdimort.beta.gentle<-0.02;o$sdimort.beta.steep<-0.80;o$sdimort.max<-1.0;o$sdimax.site.term<-FALSE;o$use.mortcal<-FALSE
  o$use.ingrowth.release<-TRUE;o$ingrowth.rd.center<-0.58;o$ingrowth.rd.k<-12
  o$sdimax.region.mult<-list(c(NB=1.0,QC=1.0,ME=1.0,NS=1.0));o$sdimax.fortype.tight.mult<-0.65
  o$sdimax.fortype.tight.groups<-list(c("SM","BCH","QA","OH","AB"));o$sdimax.fortype.region<-list("OTHER_ECO");o$active_ecobucket<-"OTHER_ECO"
  o
}
init <- function(seed){ set.seed(seed); n<-40
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("RS","WS","BF"),length.out=n),dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,
    expf=rep(3000/n,n),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
run_traj <- function(mult){
  cur<-init(101); o<-base_ops()
  if(mult>1){ o$use.mgmt.mod<-TRUE; o$mgmt.class<-"PLANTED"; o$mgmt.planted.mult<-mult } else o$use.mgmt.mod<-FALSE
  ops<<-o                              # assign FULLY-modified ops to global (engine reads global ops)
  stand<<-make_stand(stand.id="plateau",csi=18,elev=200,region="ME")
  bh<-numeric()
  for(age in 1:160){ nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL)
    if(is.null(nx)||nrow(nx)==0)break; cur<-bf(nx); live<-cur[cur$dbh>=4&is.finite(cur$dbh),]; if(nrow(live)<1)break
    bh[age]<-sum(pi*(live$dbh/200)^2*live$expf) }
  bh
}
cat("\n== PLATEAU SWEEP (planted RS/WS/BF ESI18): BA trajectory summary ==\n")
cat(sprintf("%-8s %8s %8s %8s %8s %8s\n","mult","BA@60","BA@100","BA@160","max","sd_last20"))
for(mult in c(1.0,1.6,2.0,2.5,3.0)){ b<-run_traj(mult)
  g<-function(i) if(length(b)>=i && is.finite(b[i])) b[i] else NA
  cat(sprintf("%-8.2f %8.1f %8.1f %8.1f %8.1f %8.2f\n", mult, g(60),g(100),g(length(b)),max(b,na.rm=TRUE),sd(tail(b,20),na.rm=TRUE))) }
cur<-init(101); o<-base_ops(); o$use.mgmt.mod<-FALSE; ops<<-o; stand<<-make_stand(stand.id="s",csi=18,elev=200,region="ME")
s_off<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
o2<-base_ops(); o2$use.mgmt.mod<-TRUE; o2$mgmt.class<-"NONE"; ops<<-o2
s_none<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
o3<-base_ops(); o3$use.mgmt.mod<-TRUE; o3$mgmt.class<-"PLANTED"; o3$mgmt.planted.mult<-2.0; ops<<-o3
s_pl<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
cat(sprintf("\ngate-OFF vs gate-ON-class-NONE max|dbh diff| = %.3e (must be ~0)\n", max(abs(s_off$dbh-s_none$dbh),na.rm=TRUE)))
cat(sprintf("single-step mean dbh growth: OFF=%.4f PLANTED(2.0)=%.4f (planted larger => modifier engaged)\n",
   mean(s_off$dbh-cur$dbh,na.rm=TRUE), mean(s_pl$dbh-cur$dbh,na.rm=TRUE)))
cat("DONE\n")

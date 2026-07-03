.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table)); setwd("/users/PUOM0008/crsfaaron/magplot/verify")
source("~/AcadianGY_12.10.1.r"); cat("VersionTag:", AcadianVersionTag, "\n")
cat("mgmt_dg_mod defaults: PLANTED=", mgmt_dg_mod("PLANTED"),
    " PCT@tst0=", mgmt_dg_mod("PCT",0), " PCT@10=", mgmt_dg_mod("PCT",10), " NONE=", mgmt_dg_mod("NONE"), "\n")
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
base_ops <- function(){ o <- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
  o$use.sdimort<-TRUE;o$sdimort.onset<-0.30;o$sdimort.break<-0.62;o$sdimort.beta.gentle<-0.02;o$sdimort.beta.steep<-0.80;o$sdimort.max<-1.0;o$sdimax.site.term<-FALSE;o$use.mortcal<-FALSE
  o$use.ingrowth.release<-TRUE;o$ingrowth.rd.center<-0.58;o$ingrowth.rd.k<-12
  o$sdimax.region.mult<-list(c(NB=1.0,QC=1.0,ME=1.0,NS=1.0));o$sdimax.fortype.tight.mult<-0.65
  o$sdimax.fortype.tight.groups<-list(c("SM","BCH","QA","OH","AB"));o$sdimax.fortype.region<-list("OTHER_ECO");o$active_ecobucket<-"OTHER_ECO"; o }
init <- function(){ set.seed(101); n<-40
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("RS","WS","BF"),length.out=n),dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,
    expf=rep(3000/n,n),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
cur<-init(); o<-base_ops(); o$use.mgmt.mod<-FALSE; ops<<-o; stand<<-make_stand(stand.id="s",csi=18,elev=200,region="ME")
s_off<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
o2<-base_ops(); o2$use.mgmt.mod<-TRUE; o2$mgmt.class<-"NONE"; ops<<-o2; s_none<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
o3<-base_ops(); o3$use.mgmt.mod<-TRUE; o3$mgmt.class<-"PLANTED"; ops<<-o3; s_pl<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
m <- merge(s_off[,c("tree","dbh")], s_none[,c("tree","dbh")], by="tree", suffixes=c(".off",".none"))
mp <- merge(s_off[,c("tree","dbh")], s_pl[,c("tree","dbh")], by="tree", suffixes=c(".off",".pl"))
cat(sprintf("GATE-OFF vs gate-ON class NONE: max|dbh diff| = %.3e (must be 0 => gate-off == v12.9.x)\n", max(abs(m$dbh.off-m$dbh.none))))
cat(sprintf("PLANTED default(2.0) mean dbh growth = %.4f vs OFF %.4f (planted larger => engaged)\n",
   mean(mp$dbh.pl-cur$dbh[match(mp$tree,cur$tree)]), mean(mp$dbh.off-cur$dbh[match(mp$tree,cur$tree)])))
cat("SMOKE_OK\n")

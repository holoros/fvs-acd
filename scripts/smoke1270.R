.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths())); suppressMessages({library(dplyr);library(purrr)})
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); source("~/AcadianGY_12.7.0.r")
bf<-function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
n<-150; set.seed(1); d0<-pmax(3,rnorm(n,12,4))
cur<-data.frame(year=0,plot=1L,tree=1:n,sp=sample(c("BF","RS","RM","YB"),n,TRUE),dbh=d0,ht=1.3+22*(1-exp(-0.04*d0)),hcb=NA_real_,cr=NA_real_,expf=rep(1800/n,n),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
o<-make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.thrshld=0); o$use.sdimort<-TRUE;o$sdimax.site.term<-FALSE;o$use.mortcal<-FALSE
o$use.esi.domht<-TRUE; o$esi.domht.age0<-40; o$esi.domht.gain<-1
ops<<-o; stand<<-make_stand("S",csi=14,elev=305,region="ME")
topht<-function(ht,dbh,e){o<-order(-dbh);cs<-cumsum(e[o]);k<-which(cs>=100)[1];if(is.na(k))k<-length(e);weighted.mean(ht[o][1:k],e[o][1:k],na.rm=TRUE)}
cat("start: BA",round(sum(pi*(cur$dbh/200)^2*cur$expf),1)," TPH",round(sum(cur$expf))," topht",round(topht(1.3+22*(1-exp(-0.04*cur$dbh)),cur$dbh,cur$expf),1),"\n")
for(yr in 1:10){nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e){cat("ERR",conditionMessage(e),"\n");NULL});if(is.null(nx))break;cur<-bf(nx)}
live<-cur[cur$dbh>=4,]
cat("yr10: BA",round(sum(pi*(live$dbh/200)^2*live$expf),1)," TPH",round(sum(live$expf))," QMD",round(sqrt((sum(pi*(live$dbh/200)^2*live$expf)/sum(live$expf))/(pi/40000)),1)," topht",round(topht(live$ht,live$dbh,live$expf),1)," anchor target(age50)~14\n")
cat("SMOKE_OK\n")

# Self-thinning recalibration sweep for AcadianGY 12.7.0: vary sdimort.onset and sdimort.beta,
# project the young dense spruce-fir stand to 120 yr on ESI 16, and report the BA asymptote, the age
# of BA plateau, the BA increment late in the rotation, and TPH at 120. Goal: find parameters where
# the BA trajectory plateaus near the observed mature Acadian maximum (~24-30 m2/ha on good sites)
# instead of climbing to 35+, i.e. the density-dependent mortality reaches the self-thinning line.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify"); source("~/AcadianGY_12.7.0.r")
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
init <- function(){ n<-40; data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("BF","RS","BS","WS"),each=n/4),
    dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=rep(3000/n,n),
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
run1 <- function(onset,beta,smax){
  ops <<- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
  ops$use.sdimort<-TRUE; ops$sdimort.onset<-onset; ops$sdimort.beta<-beta; ops$sdimort.max<-smax; ops$sdimax.site.term<-FALSE; ops$use.mortcal<-FALSE
  set.seed(1); cur<-init(); stand<<-make_stand(stand.id="E16",csi=16,elev=200,region="ME")
  ba<-numeric(0)
  for(age in 1:120){ nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL)
    if(is.null(nx)||nrow(nx)==0)break; cur<-bf(nx); live<-cur[cur$dbh>=4&is.finite(cur$dbh),]
    if(!nrow(live))break; ba[age]<-sum(pi*(live$dbh/200)^2*live$expf) }
  live<-cur[cur$dbh>=4&is.finite(cur$dbh),]; tph<-sum(live$expf)
  inc_late<-if(length(ba)>=120) ba[120]-ba[110] else NA
  list(bamax=max(ba),ageofmax=which.max(ba),ba120=tail(ba,1),inc_late=inc_late,tph=tph)
}
grid<-expand.grid(onset=c(0.55,0.45,0.40,0.35),beta=c(0.10,0.20,0.30,0.40),smax=1.0)
cat("=== self-thinning recalibration sweep (ESI16, young dense SF to 120yr) ===\n")
cat(sprintf("%-6s %-5s | %-7s %-7s %-7s %-9s %-6s\n","onset","beta","BAmax","ageMax","BA@120","incl110_120","TPH120"))
for(i in seq_len(nrow(grid))){ r<-run1(grid$onset[i],grid$beta[i],grid$smax[i])
  cat(sprintf("%-6.2f %-5.2f | %-7.1f %-7d %-7.1f %-9.2f %-6.0f\n",grid$onset[i],grid$beta[i],r$bamax,r$ageofmax,r$ba120,ifelse(is.na(r$inc_late),0,r$inc_late),r$tph)) }
cat("DONE\n")

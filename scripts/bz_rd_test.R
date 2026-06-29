# Self-thinning calibration test: does enabling the relative-density modifiers
# (useMORT/useDBH/useHT_RDmodifier, off by default) steepen AcadianGY's
# self-thinning toward the Reineke -1.605 law? Generates Bakuzis site-gradient
# trajectories under five configs and reports the Reineke slope for each.
# AcadianGY 12.3.9.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(plyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); ACRES_PER_HA <- 2.4710538147
source("~/AcadianGY_12.3.9.r"); set.seed(47)
nT<-200; tph0<-2500
sp<-sample(c("BF","RS","RM","YB","SM"),nT,replace=TRUE,prob=c(.4,.2,.2,.1,.1))
dbh<-pmax(1.0,rnorm(nT,3.0,0.8)); ht<-pmax(1.5,1.3+25*(1-exp(-0.04*dbh)))
metrics<-function(df){live<-df$DBH>=4.0&is.finite(df$DBH); d<-df$DBH[live];h<-df$HT[live];e<-df$EXPF[live]
  if(length(d)==0) return(c(TPH=0,BAPH=0,QMD=NA))
  BAPH<-sum(pi*(d/200)^2*e); TPH<-sum(e); QMD<-sqrt((BAPH/TPH)/(pi/40000)); c(TPH=TPH,BAPH=BAPH,QMD=QMD)}
gen <- function(ops_extra){
  out<-list()
  for(csi in c(8,11,14,17,20)){
    cur<-data.frame(STAND="BZ",PLOT=1L,TREE=seq_len(nT),SP=sp,DBH=dbh,HT=ht,HCB=NA_real_,EXPF=rep(tph0/nT,nT),
      YEAR=0,dDBH.mult=1,dHt.mult=1,mort.mult=1,max.dbh=200,max.height=50,Form=NA,Risk=NA,stringsAsFactors=FALSE)
    rec<-list()
    for(yr in seq_len(120)){
      ops<-c(list(verbose=FALSE,INGROWTH="N",MinDBH=4.0), ops_extra)
      nx<-tryCatch(AcadianGYOneStand(cur,stand=list(CSI=csi,ELEV=305),ops=ops),error=function(e)NULL)
      if(is.null(nx)) break; cur<-nx; cur$YEAR<-yr
      if(yr%%5==0){m<-metrics(cur); rec[[length(rec)+1]]<-data.frame(site=csi,age=yr,t(m))} }
    out[[as.character(csi)]]<-do.call(rbind,rec) }
  do.call(rbind,out) }
# Reineke slope on the self-thinning phase (QMD increasing), averaged across sites
reineke <- function(tr){
  sl<-sapply(unique(tr$site), function(s){ g<-tr[tr$site==s,]; g<-g[order(g$age),]
    keep<-c(TRUE, diff(g$QMD)>0.5); g<-g[keep,]
    if(nrow(g)>=4 && sd(log(g$QMD))>1e-3) coef(lm(log(TPH)~log(QMD),g))[2] else NA })
  mean(sl, na.rm=TRUE) }
configs <- list(
  base            = list(),
  mortcal         = list(MORTCAL=TRUE, MORTCAL_INTERVAL=5),
  rd_mort         = list(useMORT_RDmodifier=TRUE, maxRD=1.0),
  rd_all          = list(useMORT_RDmodifier=TRUE, useDBH_RDmodifier=TRUE, useHT_RDmodifier=TRUE, maxRD=1.0),
  mortcal_rd_all  = list(MORTCAL=TRUE, MORTCAL_INTERVAL=5, useMORT_RDmodifier=TRUE, useDBH_RDmodifier=TRUE, useHT_RDmodifier=TRUE, maxRD=1.0))
res <- list()
for (cn in names(configs)){
  tr <- gen(configs[[cn]])
  write.csv(tr, paste0("bz_rd_", cn, ".csv"), row.names=FALSE)
  sl <- reineke(tr)
  # terminal density at age 120, site 14 (mid) as a stem-count proxy
  g14 <- tr[tr$site==14,]; tph_end <- if(nrow(g14)) tail(g14$TPH,1) else NA
  res[[cn]] <- data.frame(config=cn, reineke_slope=round(sl,2), tph_end_site14=round(tph_end,0))
  cat(cn, "Reineke slope", round(sl,2), " TPH_end(site14)", round(tph_end,0), "\n")
}
tab <- do.call(rbind, res)
write.csv(tab, "bz_rd_reineke.csv", row.names=FALSE)
cat("\n=== Reineke self-thinning slope by config (target -1.605) ===\n"); print(tab, row.names=FALSE)
cat("DONE\n")

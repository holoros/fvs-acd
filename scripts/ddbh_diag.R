# Growth-side diagnosis: is the Maine long-horizon BA over-prediction the diameter
# increment equation, or the density brake failing? Compares predicted vs observed
# periodic annual diameter increment per tree on matched DBHout pairs (ME/NB/NS),
# decomposed by region, species group, DBH class, and relative-density class.
# Reports bias (pred-obs), MAE, RMSE (not R^2), per Weiskittel philosophy.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(data.table); library(dplyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); source("~/AcadianGY_12.6.1.r"); set.seed(19)
NPER <- as.integer(Sys.getenv("NPER_DIAG","150"))

d <- fread("/fs/scratch/PUOM0008/crsfaaron/maine_cfi/DBHout.csv", nThread=4,
  select=c("Source","Stand","Plot","Tree","year1","year2","sp1","dbh1","dbh2","expf1","rd_mix1","sdi1","sdi_max1","climatesi","elev"))
setnames(d, c("sp1","dbh1","expf1","climatesi"), c("sp","dbh","expf","csi"))
d <- d[is.finite(dbh)&dbh>0&is.finite(dbh2)&dbh2>0&is.finite(expf)&expf>0&csi>0&csi<40]
d[, rem := year2-year1]; d <- d[rem>=3 & rem<=15]
d[, region := fifelse(Source=="Nova Scotia PSP","NS", fifelse(Source=="NB PSP","NB",
              fifelse(Source %in% c("PEF","FIA_99_05"),"ME","X")))]
d <- d[region!="X"]; d[, sp:=toupper(gsub('"','',sp))]
d[, pid := paste(region,Stand,Plot,year1, sep="_")]
samp <- unique(d[,.(region,pid)])[, .SD[sample(.N, min(.N,NPER))], by=region]
d <- d[pid %in% samp$pid]
cat("diag plots:", uniqueN(d$pid), " trees:", nrow(d), "\n")

acadgy <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
mapsp <- function(s){s<-toupper(s); ifelse(s %in% acadgy, s, ifelse(s %in% sw,"OS","OH"))}
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
o <- make_ops(verbose=FALSE,use.ingrowth=FALSE); o$use.sdimort<-TRUE;o$sdimort.onset<-0.55;o$sdimort.beta<-0.10;o$sdimort.max<-1;o$sdimax.site.term<-FALSE;o$use.mortcal<-FALSE
ops <<- o
setDF(d)
res <- list()
for (pp in unique(d$pid)){
  pl <- d[d$pid==pp, ]
  cur <- data.frame(year=0,plot=1L,tree=seq_len(nrow(pl)),sp=mapsp(pl$sp),dbh=pl$dbh,ht=NA_real_,hcb=NA_real_,cr=NA_real_,
    expf=pl$expf,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
  stand <<- make_stand(stand.id=pp, csi=median(pl$csi), elev=median(pl$elev), region="ME")
  rem <- pl$year2[1]-pl$year1[1]; start_dbh <- pl$dbh; tid <- seq_len(nrow(pl))
  ok<-TRUE
  for (yr in seq_len(rem)){ nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL); if(is.null(nx)){ok<-FALSE;break}; cur<-bf(nx) }
  if(!ok) next
  m <- match(tid, cur$tree)            # survivors keep tree id
  pred_end <- cur$dbh[m]
  res[[pp]] <- data.frame(region=pl$region, sp=pl$sp, dbh1=pl$dbh, rd=pl$rd_mix1, rem=rem,
    pred_ddbh=(pred_end - start_dbh)/rem, obs_ddbh=(pl$dbh2 - pl$dbh)/rem)
}
R <- rbindlist(res); R <- R[is.finite(R$pred_ddbh)&is.finite(R$obs_ddbh),]
fwrite(R, "ddbh_diag_trees.csv")
sw_grp <- function(s) ifelse(toupper(s) %in% sw | toupper(s) %in% c("WP","RP","RS","BF","BS","WS","EH","WC","TA","JP","NS","OS"),"softwood","hardwood")
R[, spgrp := sw_grp(sp)]
R[, dbhcl := cut(dbh1, c(0,10,20,30,200), labels=c("<10","10-20","20-30","30+"))]
R[, rdcl  := cut(rd, c(-1,0.4,0.6,0.8,5), labels=c("<0.4","0.4-0.6","0.6-0.8","0.8+"))]
summ <- function(by){ R[, .(n=.N, obs=round(mean(obs_ddbh),3), pred=round(mean(pred_ddbh),3),
   bias=round(mean(pred_ddbh-obs_ddbh),3), bias_pct=round(100*(mean(pred_ddbh)/mean(obs_ddbh)-1),1),
   MAE=round(mean(abs(pred_ddbh-obs_ddbh)),3), RMSE=round(sqrt(mean((pred_ddbh-obs_ddbh)^2)),3)), by=by] }
cat("\n=== overall annual dDBH (cm/yr) ===\n"); print(R[, .(n=.N, obs=round(mean(obs_ddbh),3), pred=round(mean(pred_ddbh),3), bias=round(mean(pred_ddbh-obs_ddbh),3), bias_pct=round(100*(mean(pred_ddbh)/mean(obs_ddbh)-1),1), MAE=round(mean(abs(pred_ddbh-obs_ddbh)),3), RMSE=round(sqrt(mean((pred_ddbh-obs_ddbh)^2)),3))])
cat("\n=== by region ===\n"); print(summ("region")[order(region)])
cat("\n=== by region x spgrp ===\n"); print(summ(c("region","spgrp"))[order(region,spgrp)])
cat("\n=== by DBH class ===\n"); print(summ("dbhcl")[order(dbhcl)])
cat("\n=== by relative-density class (KEY: does bias grow with RD?) ===\n"); print(summ("rdcl")[order(rdcl)])
cat("\n=== ME by RD class (the over-prediction locus) ===\n"); print(R[region=="ME", .(n=.N, bias=round(mean(pred_ddbh-obs_ddbh),3), bias_pct=round(100*(mean(pred_ddbh)/mean(obs_ddbh)-1),1)), by=rdcl][order(rdcl)])
fwrite(summ("region"), "ddbh_diag_by_region.csv"); fwrite(summ("rdcl"), "ddbh_diag_by_rd.csv")
cat("DONE\n")

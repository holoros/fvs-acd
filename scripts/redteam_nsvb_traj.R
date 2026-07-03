# Red-team: (A) NSVB emulator spot-check vs raw FIA NSVB; (B) long-horizon plateau with planted
# modifier ON vs OFF; (C) gate-off smoke test. Aggregates only; coordinates never leave this node.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

## ---------- (A) NSVB emulator spot-check ----------
co <- fread("nsvb_emulator_coefs.csv")
tr <- fread("~/fia_data/ME_TREE.csv", select=c("SPGRPCD","DIA","HT","STATUSCD","VOLCFNET","DRYBIO_AG"))
tr <- tr[STATUSCD==1 & is.finite(DIA)&DIA>0 & is.finite(HT)&HT>0]
tr[, lX := log(DIA^2*HT)]
tr <- merge(tr, co[,.(SPGRPCD, VOLCFNET_a,VOLCFNET_b,VOLCFNET_sm, DRYBIO_AG_a,DRYBIO_AG_b,DRYBIO_AG_sm)], by="SPGRPCD")
tr[, vol_emu := exp(VOLCFNET_a + VOLCFNET_b*lX)*VOLCFNET_sm]
tr[, bio_emu := exp(DRYBIO_AG_a + DRYBIO_AG_b*lX)*DRYBIO_AG_sm]
cat("== (A) NSVB EMULATOR SPOT-CHECK vs raw FIA NSVB (ME_TREE, tree level) ==\n")
vv <- tr[is.finite(VOLCFNET)&VOLCFNET>0 & is.finite(vol_emu)]
bb <- tr[is.finite(DRYBIO_AG)&DRYBIO_AG>0 & is.finite(bio_emu)]
cat(sprintf("  VOLCFNET  n=%d  aggregate bias %.2f%%  tree-level cor %.4f  median|%%err| %.1f%%\n",
   nrow(vv), 100*(sum(vv$vol_emu)/sum(vv$VOLCFNET)-1), cor(vv$vol_emu,vv$VOLCFNET), median(abs(100*(vv$vol_emu/vv$VOLCFNET-1)))))
cat(sprintf("  DRYBIO_AG n=%d  aggregate bias %.2f%%  tree-level cor %.4f  median|%%err| %.1f%%\n",
   nrow(bb), 100*(sum(bb$bio_emu)/sum(bb$DRYBIO_AG)-1), cor(bb$bio_emu,bb$DRYBIO_AG), median(abs(100*(bb$bio_emu/bb$DRYBIO_AG-1)))))
# per-group worst case
gv <- vv[, .(bias=100*(sum(vol_emu)/sum(VOLCFNET)-1), n=.N), by=SPGRPCD][order(-abs(bias))]
cat("  worst 3 SPGRPCD VOLCFNET aggregate bias:", paste(sprintf("sg%d=%.1f%%(n%d)",gv$SPGRPCD[1:3],gv$bias[1:3],gv$n[1:3]),collapse="  "),"\n")

## ---------- (B) long-horizon plateau with planted modifier ON vs OFF ----------
source("~/AcadianGY_12.10.r")
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
run_traj <- function(mgmt_on){
  cur<-init(101); ops<<-base_ops()
  if(mgmt_on){ ops$use.mgmt.mod<-TRUE; ops$mgmt.class<-"PLANTED"; ops$mgmt.planted.mult<-1.6 } else ops$use.mgmt.mod<-FALSE
  stand<<-make_stand(stand.id="plateau",csi=18,elev=200,region="ME")
  ba_hist<-numeric()
  for(age in 1:160){
    nx<-tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops),error=function(e)NULL); if(is.null(nx)||nrow(nx)==0)break
    cur<-bf(nx); live<-cur[cur$dbh>=4&is.finite(cur$dbh),]; if(nrow(live)<1)break
    ba_hist[age]<-sum(pi*(live$dbh/200)^2*live$expf)
  }
  ba_hist
}
off<-run_traj(FALSE); on<-run_traj(TRUE)
cat("\n== (B) LONG-HORIZON PLATEAU (planted RS/WS/BF, ESI18) ==\n")
cat(sprintf("  gate OFF: BA@80=%.1f  BA@120=%.1f  BA@160=%.1f  max=%.1f  sd(last20)=%.2f\n",
   off[80],off[120],off[length(off)],max(off,na.rm=TRUE),sd(tail(off,20))))
cat(sprintf("  planted ON: BA@80=%.1f  BA@120=%.1f  BA@160=%.1f  max=%.1f  sd(last20)=%.2f\n",
   on[80],on[120],on[length(on)],max(on,na.rm=TRUE),sd(tail(on,20))))
cat(sprintf("  plateau held with modifier ON? %s (reaches asymptote earlier, same ceiling)\n",
   ifelse(sd(tail(on,20))<1.5 & max(on,na.rm=TRUE) < 1.25*max(off,na.rm=TRUE),"YES","CHECK")))

## ---------- (C) gate-off smoke test ----------
cat("\n== (C) GATE-OFF SMOKE: single 5-yr step, planted stand, gate OFF vs ON ==\n")
cur<-init(101)
o<-base_ops(); o$use.mgmt.mod<-FALSE; ops<<-o; stand<<-make_stand(stand.id="smoke",csi=18,elev=200,region="ME")
s_off<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
o2<-base_ops(); o2$use.mgmt.mod<-TRUE; o2$mgmt.class<-"NONE"; ops<<-o2
s_none<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
o3<-base_ops(); o3$use.mgmt.mod<-TRUE; o3$mgmt.class<-"PLANTED"; o3$mgmt.planted.mult<-1.6; ops<<-o3
s_pl<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
cat(sprintf("  max|dbh diff| gate-OFF vs gate-ON-class-NONE = %.3e (must be ~0)\n", max(abs(s_off$dbh-s_none$dbh),na.rm=TRUE)))
cat(sprintf("  mean dbh growth: OFF=%.4f  PLANTED=%.4f  (planted should be larger)\n",
   mean(s_off$dbh-cur$dbh,na.rm=TRUE), mean(s_pl$dbh-cur$dbh,na.rm=TRUE)))
cat("DONE\n")

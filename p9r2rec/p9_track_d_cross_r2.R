# p9_track_d_cross_r2.R -- exact copy of p6ing/p6_cross.R with the r2 ddbh refit coefficients
# set as env vars before model_p6ing.r sources p4e/model_b0b1b2.r. Closes pass 9 Track D's
# flagged [UNKNOWN: no tree level output] for r2 alone on mefia_l. Aggregates only.
Sys.setenv(B0NEW="-1.88365516930746", B1NEW="0.497878016309701", B2NEW="-0.0293425859449079")
Sys.setenv(P6FIX="1", P6ALPHA="1", P6DIAG="/users/PUOM0008/crsfaaron/magplot/verify/p9r2rec/p9_track_d_cross_r2_diag.csv")
suppressMessages(library(data.table)); setwd("/users/PUOM0008/crsfaaron/magplot/verify")
source("p6ing/model_p6ing.r"); source("~/hw_sawfrac_smith.R"); source("~/hw_formrisk_split.R")
ecobucket_lookup <- fread("v129_gate3_dedup.csv"); ecobucket_lookup[, STAND:=as.character(STAND)]
bmapdt <- fread("v129x_brms_sdimax_map.csv"); BV <- setNames(bmapdt$sdimax_brms, as.character(bmapdt$STAND))
prs<-fread("multisrc/bench_mefia_long_pairs.csv"); ti<-fread("multisrc/bench_mefia_long_tree_init.csv")
e8<-fread("multisrc/bench_mefia_long_site_esi.csv"); e8[,esi8:=as.numeric(esi8)]
prs<-merge(prs,e8,by="SITE",all.x=TRUE)
prs[,csi_site:=ifelse(is.finite(esi8)&esi8>2,esi8,14)]
AGY<-c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA","BT","BP","EC",
 "AB","WA","BA","GA","RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC")
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
mapsp<-function(s){s<-toupper(s);ifelse(s %in% AGY,s,ifelse(s %in% sw,"OS","OH"))}
bf<-function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
ops<<-make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,
  use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort<-TRUE;ops$sdimort.onset<-0.30;ops$sdimort.break<-0.62;ops$sdimort.beta.gentle<-0.02
ops$sdimort.beta.steep<-0.80;ops$sdimort.max<-1.0;ops$sdimax.site.term<-FALSE;ops$use.mortcal<-FALSE
ops$use.ingrowth.release<-TRUE;ops$ingrowth.rd.center<-0.58;ops$ingrowth.rd.k<-8;ops$ingrowth.mult<-1
ops$use.esi.domht<-FALSE; ops$use.brms.sdimax<-TRUE; ops$brms.sdimax.map<-list(BV)
ops$use.esi.anchor.recal<-TRUE
ops$esi.anchor.coef<-list(list(NB=c(0.885,0.01027), QC=c(0.441,0.03783)))
ops$sdimort.break.region<-list(c(NB=0.70,QC=0.62)); ops$ingrowth.mult.region<-list(c(NB=1,QC=1))
ops$use.hier.ingrowth<-FALSE; ops$use.hier.mortality<-FALSE
setkey(ti,STAND); setDF(prs); nf<-0
for(k in seq_len(nrow(prs))){ p<-prs[k,]; sid<-p$STAND; it<-ti[.(sid)]; if(nrow(it)<3){nf<-nf+1;next}
  r<-tryCatch({ cur<-data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,
      ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,
      risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    cur<-split_formrisk(cur)
    stand<<-make_stand(stand.id=sid,csi=if(is.finite(p$csi_site)&&p$csi_site>2)p$csi_site else 14,
      elev=if(is.finite(p$ELEV)&&p$ELEV>0)p$ELEV else 200,region="ME")
    ops$active_ecobucket <- ecobucket_lookup[STAND==sid, gate3][1]
    AcadianGYOneStand(tree=cur,stand=stand,ops=ops); TRUE}, error=function(e){ if(nf<2) cat("ERR:",conditionMessage(e),"\n"); FALSE })
  if(!isTRUE(r)) nf<-nf+1
}
cat("stands attempted",nrow(prs)," failures",nf,"\n")
.p6_diag_write()
d<-fread("/users/PUOM0008/crsfaaron/magplot/verify/p9r2rec/p9_track_d_cross_r2_diag.csv")
cat("diag rows",nrow(d),"\n")
cat("\n=== YEAR-1 DOUBLE COUNT, mefia_l, r2 CONFIG, per plot (stems ha-1 yr-1) ===\n")
print(d[,.(n=.N, gross_mean=round(mean(gross),2), cross_mean=round(mean(cross),2),
   pool_mean=round(mean(pool),1), net_mean=round(mean(net),2),
   cross_over_gross=round(mean(cross)/mean(gross),3),
   pct_plots_fully_netted=round(100*mean(net<=0),1),
   mean_scale=round(mean(scale),3))])
cat("\nquantiles of cross/gross:\n"); print(round(quantile(d$cross/pmax(d$gross,1e-9),c(.05,.25,.5,.75,.95)),3))
cat("DONE_P9_TRACK_D_CROSS_R2\n")

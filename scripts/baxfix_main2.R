## baxfix_main2.R -- Baxter height-provenance staging fix (exact-carry version).
## The rebuilt t2 is the EXISTING staged t2 with the HT column populated from the
## validated positional join back to BaxterCFI_raw.csv. Every other field is carried
## verbatim, so nothing but HT can move. NAMESPACED; writes only into baxterfix/.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths()))
suppressMessages(library(data.table))
V  <- "/users/PUOM0008/crsfaaron/magplot/verify"; MS <- file.path(V,"multisrc"); BF <- file.path(V,"baxterfix")
setwd(V)
IN_CM <- 2.54; FT_M <- 0.3048

co<-fread("nsvb_emulator_coefs.csv"); sp2g<-fread("spcd_spgrpcd.csv")
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=833,BC=762,PR=761,ST=315,HH=701,SB=935,RB=370,AS=541,SW=298,HW=998,OH=998,OS=298,PC=68)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes<-names(AGY2SPCD); spcd2grp<-setNames(sp2g$SPGRPCD,as.character(sp2g$SPCD))
agy_grp<-sapply(AGY2SPCD,function(s){g<-spcd2grp[as.character(s)];if(is.na(g))998L else as.integer(g)})
ci<-match(agy_grp,co$SPGRPCD); ci[is.na(ci)]<-match(998,co$SPGRPCD); ci[is.na(ci)]<-1
RESP<-c("VOLCFGRS","VOLCFNET","VOLCSNET","DRYBIO_AG"); CF<-list()
for(r in RESP) CF[[r]]<-list(a=setNames(co[[paste0(r,"_a")]][ci],agy_codes),
  b=setNames(co[[paste0(r,"_b")]][ci],agy_codes), sm=setNames(co[[paste0(r,"_sm")]][ci],agy_codes))
FT3_M3<-0.0283168; acadgy<-names(AGY2SPCD)
mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
cfd<-fread(file.path(V,"htprov","htprov_hd_coefs.csv"))
gS<-cfd[level=="group"&code=="SW"]; gH<-cfd[level=="group"&code=="HW"]; spd<-cfd[level=="species"]
hfit_grp<-function(sp,d){ isw<-sp %in% sw
  1.3+ifelse(isw,gS$a,gH$a)*(1-exp(-ifelse(isw,gS$b,gH$b)*d))^ifelse(isw,gS$c,gH$c) }
hfit<-function(sp,d){ isw<-sp %in% sw
  a<-ifelse(isw,gS$a,gH$a); b<-ifelse(isw,gS$b,gH$b); cc<-ifelse(isw,gS$c,gH$c)
  for(k in seq_len(nrow(spd))){ i<-which(sp==spd$code[k]); if(length(i)){a[i]<-spd$a[k];b[i]<-spd$b[k];cc[i]<-spd$c[k]} }
  1.3+a*(1-exp(-b*d))^cc }
nsvb2<-function(agy,dbh,ht,resp,hfun){ h<-ifelse(is.finite(ht)&ht>0,ht,hfun(agy,dbh))
  lX<-log((dbh/IN_CM)^2*(h/FT_M)); y<-CF[[resp]]$sm[agy]*exp(CF[[resp]]$a[agy]+CF[[resp]]$b[agy]*lX)
  y[!is.finite(y)]<-0; unname(y)}

## ===================== B1/B2 rebuild: staged t2 + recovered HT =============================
raw <- fread(file.path(MS,"BaxterCFI_raw.csv"))
old <- fread(file.path(MS,"bench_baxter_tree_t2.csv"))
pr  <- fread(file.path(MS,"bench_baxter_pairs.csv"))
pr[, PLOTN:=as.integer(tstrsplit(STAND,"_")[[2]])][, Y1:=as.integer(tstrsplit(STAND,"_")[[3]])][, Y2:=as.integer(tstrsplit(STAND,"_")[[4]])]
r2 <- merge(raw, pr[,.(STAND,plot=PLOTN,year=Y2)], by=c("plot","year"))
cand <- r2[is.na(th) | !(th %in% c(6,8))][order(STAND,tree)]
cand[, TREE := seq_len(.N), by=STAND]
new <- merge(old, cand[,.(STAND,TREE,raw_tree=tree,raw_dbh=dbh,raw_ht=ht,predHT)],
             by=c("STAND","TREE"), all.x=TRUE, sort=FALSE)
setorder(new, STAND, TREE)
cat("\n=========== B1 JOIN AUDIT (staged t2 vs BaxterCFI_raw) ===========\n")
cat(sprintf("staged rows %d ; joined rows %d ; unjoined %d\n", nrow(old), nrow(new), sum(is.na(new$predHT))))
cat(sprintf("DBH reconstruction max abs diff (staged vs raw_dbh*2.54, 2dp): %.12g\n",
            max(abs(new$DBH - round(new$raw_dbh*IN_CM,2)))))
new[, HT := ifelse(predHT==0 & is.finite(raw_ht) & raw_ht>0, round(raw_ht*FT_M,2), NA_real_)]
OUTT <- new[, .(STAND,PLOT,TREE,SP,DBH,HT,EXPF,YEAR)]
fwrite(OUTT, file.path(BF,"bench_baxter_tree_t2_htfix.csv"))
cat("WROTE", file.path(BF,"bench_baxter_tree_t2_htfix.csv"), "\n")

cat("\n=========== B2 DIFF: old staged t2 vs t2_htfix ===========\n")
D <- merge(old, OUTT, by=c("STAND","TREE"), suffixes=c("_old","_new"))
new[, BA := pi*(DBH/200)^2*EXPF]
sc <- new[is.finite(DBH)&DBH>=4&EXPF>0]
cat(sprintf("field|old|new|match\n"))
cat(sprintf("rows|%d|%d|%s\n", nrow(old), nrow(OUTT), nrow(old)==nrow(OUTT)))
cat(sprintf("stands|%d|%d|%s\n", uniqueN(old$STAND), uniqueN(OUTT$STAND),
            identical(sort(unique(old$STAND)),sort(unique(OUTT$STAND)))))
cat(sprintf("SP mismatches|-|-|%d\n", sum(D$SP_old!=D$SP_new)))
cat(sprintf("max abs DBH diff|-|-|%.3g\n", max(abs(D$DBH_old-D$DBH_new))))
cat(sprintf("max abs EXPF diff|-|-|%.3g\n", max(abs(D$EXPF_old-D$EXPF_new))))
cat(sprintf("YEAR mismatches|-|-|%d\n", sum(D$YEAR_old!=D$YEAR_new)))
cat(sprintf("HT non-NA|%d|%d|-\n", sum(!is.na(old$HT)), sum(!is.na(OUTT$HT))))
cat(sprintf("total BA (sum m2/ha units)|%.9f|%.9f|%s\n",
            sum(pi*(old$DBH/200)^2*old$EXPF), sum(new$BA),
            identical(sum(pi*(old$DBH/200)^2*old$EXPF), sum(new$BA))))
cat(sprintf("measured stems %d = %.2f pct of stems ; %.3f pct of all-row BA ; %.3f pct of scored (DBH>=4cm) BA\n",
    sum(!is.na(new$HT)), 100*mean(!is.na(new$HT)),
    100*sum(new$BA[!is.na(new$HT)])/sum(new$BA),
    100*sum(sc$BA[!is.na(sc$HT)])/sum(sc$BA)))
r1 <- merge(raw, pr[,.(STAND,plot=PLOTN,year=Y1)], by=c("plot","year"))
r1[, BAi := pi*(dbh*IN_CM/200)^2*12.3553]
cat(sprintf("INIT side available but deliberately NOT applied: %d of %d stems (%.2f pct), %.2f pct of init BA\n",
    sum(r1$predHT==0), nrow(r1), 100*mean(r1$predHT==0), 100*sum(r1$BAi[r1$predHT==0])/sum(r1$BAi)))

## ===================== B3 curve validation ================================================
cat("\n=========== B3 CURVE VALIDATION ===========\n")
M <- sc[!is.na(HT)]
M[, AGY := mapsp(SP)][, grp := ifelse(AGY %in% sw,"SW","HW")]
cat(sprintf("n=%d measured stems in the scored window (SW %d, HW %d)\n",nrow(M),sum(M$grp=="SW"),sum(M$grp=="HW")))
cat(sprintf("UNIT CHECK  raw ht (ft): %.1f - %.1f ; converted HT (m): %.2f - %.2f ; median %.2f\n",
    min(M$raw_ht), max(M$raw_ht), min(M$HT), max(M$HT), median(M$HT)))
cat(sprintf("UNIT CHECK  raw dbh (in): %.2f - %.2f ; staged DBH (cm): %.1f - %.1f ; median %.1f\n",
    min(M$raw_dbh), max(M$raw_dbh), min(M$DBH), max(M$DBH), median(M$DBH)))
cat(sprintf("UNIT CHECK  H/D (m per cm) p05=%.3f p50=%.3f p95=%.3f\n",
    quantile(M$HT/M$DBH,.05), median(M$HT/M$DBH), quantile(M$HT/M$DBH,.95)))
M[, `:=`(p_himp=himp(AGY,DBH), p_fitg=hfit_grp(AGY,DBH), p_fits=hfit(AGY,DBH))]
f <- function(x) list(n=length(x$HT), obs=round(mean(x$HT),2),
   himp=round(mean(x$p_himp),2), bias_himp=round(mean(x$p_himp-x$HT),2),
   biaspct_himp=round(100*mean(x$p_himp-x$HT)/mean(x$HT),2), rmse_himp=round(sqrt(mean((x$p_himp-x$HT)^2)),2),
   CRg=round(mean(x$p_fitg),2), bias_CRg=round(mean(x$p_fitg-x$HT),2),
   biaspct_CRg=round(100*mean(x$p_fitg-x$HT)/mean(x$HT),2), rmse_CRg=round(sqrt(mean((x$p_fitg-x$HT)^2)),2),
   CRs=round(mean(x$p_fits),2), bias_CRs=round(mean(x$p_fits-x$HT),2),
   biaspct_CRs=round(100*mean(x$p_fits-x$HT)/mean(x$HT),2), rmse_CRs=round(sqrt(mean((x$p_fits-x$HT)^2)),2))
allr <- as.data.table(f(M))[, grp:="ALL"]
byg  <- M[, f(.SD), by=grp]
M[, dcl := cut(DBH, c(4,10,20,30,40,Inf), right=FALSE, labels=c("04-10","10-20","20-30","30-40","40+"))]
byd  <- M[, f(.SD), by=dcl][order(dcl)]
bygd <- M[, f(.SD), by=.(grp,dcl)][order(grp,dcl)]
cat("\n-- ALL --\n");   print(allr)
cat("\n-- GROUP --\n"); print(byg)
cat("\n-- DIAMETER CLASS --\n"); print(byd)
cat("\n-- GROUP x DIAMETER CLASS --\n"); print(bygd)
fwrite(rbind(allr[,.(grp,dcl="ALL",n,obs,himp,bias_himp,biaspct_himp,rmse_himp,CRg,bias_CRg,biaspct_CRg,rmse_CRg,CRs,bias_CRs,biaspct_CRs,rmse_CRs)],
             byg[,.(grp,dcl="ALL",n,obs,himp,bias_himp,biaspct_himp,rmse_himp,CRg,bias_CRg,biaspct_CRg,rmse_CRg,CRs,bias_CRs,biaspct_CRs,rmse_CRs)],
             bygd[,.(grp,dcl=as.character(dcl),n,obs,himp,bias_himp,biaspct_himp,rmse_himp,CRg,bias_CRg,biaspct_CRg,rmse_CRg,CRs,bias_CRs,biaspct_CRs,rmse_CRs)]),
       file.path(BF,"baxfix_curve_validation.csv"))
fwrite(M[,.(STAND,TREE,SP,grp,DBH,HT,p_himp,p_fitg,p_fits)], file.path(BF,"baxfix_measured_stems.csv"))
ST <- sc[, .(BA=sum(BA), TPH=sum(EXPF), hw=sum(BA[!(mapsp(SP) %in% sw)])), by=STAND]
ST[, QMD := sqrt((BA/TPH)/(pi/40000))]
cat(sprintf("\nBaxter stand context: n=%d stands, mean QMD %.2f cm, hardwood BA share %.1f pct\n",
    nrow(ST), mean(ST$QMD), 100*sum(ST$hw)/sum(ST$BA)))
## representativeness of the measured subsample
cat("\n-- measured vs imputed subsample representativeness (scored window) --\n")
print(sc[, .(n=.N, mean_DBH=round(mean(DBH),2), p90_DBH=round(quantile(DBH,.9),1),
             hw_BA_pct=round(100*sum(BA[!(mapsp(SP) %in% sw)])/sum(BA),1),
             BA_pct=round(100*sum(BA)/sum(sc$BA),2)), by=.(measured=!is.na(HT))])

## ===================== B4 rescore =========================================================
cat("\n=========== B4 RESCORE ===========\n")
sm <- function(d,hfun,use_meas){
  d2 <- copy(d); d2[, HTuse := if(use_meas) HT else NA_real_]
  d2[is.finite(DBH)&DBH>=4&is.finite(EXPF)&EXPF>0,
     .(BA=sum(pi*(DBH/200)^2*EXPF),
       TOTVOL=sum(nsvb2(AGY,DBH,HTuse,"VOLCFGRS",hfun)*EXPF)*FT3_M3), by=STAND]
}
DD <- copy(new); DD[, AGY := mapsp(SP)]
res <- list(BASE="v131base_baxter_results.csv", CAND="v131_baxter_results.csv", OSM="osm_score_baxter_results.csv")
bp <- function(o,p) round(100*(mean(p)/mean(o)-1),2)
rows <- list()
for(mdl in names(res)){
  R <- tryCatch(fread(res[[mdl]]), error=function(e) NULL); if(is.null(R)) next
  dd <- DD[STAND %in% R$STAND]
  A<-sm(dd,himp,FALSE);    setnames(A,2:3,c("BA_A","TV_A"))
  B<-sm(dd,hfit,FALSE);    setnames(B,2:3,c("BA_B","TV_B"))
  C<-sm(dd,himp,TRUE);     setnames(C,2:3,c("BA_C","TV_C"))
  E<-sm(dd,hfit,TRUE);     setnames(E,2:3,c("BA_E","TV_E"))
  G<-sm(dd,hfit_grp,TRUE); setnames(G,2:3,c("BA_G","TV_G"))
  MM<-Reduce(function(x,y) merge(x,y,by="STAND"), list(R[,.(STAND,TOTVOL_o,TOTVOL_p,BA_o,BA_p)],A,B,C,E,G))
  rows[[mdl]] <- data.table(model=mdl, n=nrow(MM),
    repro_maxabs=max(abs(MM$TV_A-MM$TOTVOL_o)),
    obs_current=round(mean(MM$TOTVOL_o),2), obs_CRall=round(mean(MM$TV_B),2),
    obs_meas_himp=round(mean(MM$TV_C),2), obs_meas_CR=round(mean(MM$TV_E),2),
    obs_meas_CRgrp=round(mean(MM$TV_G),2), pred=round(mean(MM$TOTVOL_p),2),
    bias_current=bp(MM$TOTVOL_o,MM$TOTVOL_p), bias_CRall=bp(MM$TV_B,MM$TOTVOL_p),
    bias_meas_himp=bp(MM$TV_C,MM$TOTVOL_p), bias_meas_CR=bp(MM$TV_E,MM$TOTVOL_p),
    bias_meas_CRgrp=bp(MM$TV_G,MM$TOTVOL_p),
    BA_o_current=round(mean(MM$BA_o),6), BA_o_rebuilt=round(mean(MM$BA_E),6),
    BA_maxabsdiff=max(abs(MM$BA_o-MM$BA_E)), BA_p=round(mean(MM$BA_p),6), ba_bias=bp(MM$BA_o,MM$BA_p))
}
RT <- rbindlist(rows,fill=TRUE); print(t(RT)); fwrite(RT, file.path(BF,"baxfix_rescore_3model.csv"))
cat("\nBA CONTROL max abs per-stand diff =", max(RT$BA_maxabsdiff),
    if(max(RT$BA_maxabsdiff)<1e-9) " -> PASS (bit-identical)\n" else " -> *** FAIL, STOP ***\n")
cat("\nDONE_BAXFIX_MAIN2\n")

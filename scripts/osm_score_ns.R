# osm_score_ns.R -- Score the OSM-ACD v2.26.1 projected NS treelist (short 'ns' or long 'ns_long') on
# the SAME NSVB emulator + metrics() used by the FVS-ACD scorecard (bench_parity_split_ms.R, verbatim
# below, copied the same way osm_score_multisrc.R already does for the other five sources), then join
# the observed (_o) and initial (_t1) side from the NS BASE FVS results so the observed side is
# byte-for-byte identical across FVS and OSM. Writes osm_score_<src>_results.csv with the SAME column
# schema as ns_base_results.csv / score_<src>_results.csv. New script (does not edit
# osm_score_multisrc.R, bench_ns_scorecard.R, bench_ns_long_scorecard.R, or any frozen harness file).
# Usage: Rscript osm_score_ns.R <ns|ns_long>
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
SRC <- commandArgs(trailingOnly=TRUE)[1]
stopifnot(SRC %in% c("ns","ns_long"))

# ===== VERBATIM from bench_parity_split_ms.R: coefficient setup, himp, nsvb, metrics =====
co<-fread("nsvb_emulator_coefs.csv"); sp2g<-fread("spcd_spgrpcd.csv")
AGY2SPCD<-c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=833,BC=762,PR=761,ST=315,HH=701,SB=935,RB=370,AS=541,SW=298,HW=998,OH=998,OS=298,PC=68)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes<-names(AGY2SPCD)
spcd2grp<-setNames(sp2g$SPGRPCD, as.character(sp2g$SPCD))
agy_grp<-sapply(AGY2SPCD, function(s){ g<-spcd2grp[as.character(s)]; if(is.na(g)) 998L else as.integer(g) })
ci<-match(agy_grp, co$SPGRPCD); ci[is.na(ci)]<-match(998, co$SPGRPCD); ci[is.na(ci)]<-1
RESP<-c("VOLCFGRS","VOLCFNET","VOLCSNET","DRYBIO_AG"); CF<-list()
for(r in RESP) CF[[r]]<-list(a=setNames(co[[paste0(r,"_a")]][ci],agy_codes),
  b=setNames(co[[paste0(r,"_b")]][ci],agy_codes), sm=setNames(co[[paste0(r,"_sm")]][ci],agy_codes))
nsvb<-function(agy,dbh_cm,ht_m,resp){
  ht<-ifelse(is.finite(ht_m)&ht_m>0,ht_m,himp(agy,dbh_cm))
  lX<-log((dbh_cm/2.54)^2*(ht/0.3048))
  a<-CF[[resp]]$a[agy]; b<-CF[[resp]]$b[agy]; sm<-CF[[resp]]$sm[agy]
  y<-sm*exp(a+b*lX); y[!is.finite(y)]<-0; unname(y)
}
FT3_M3<-0.0283168; LB_KG<-0.453592
SAWSW<-50; SAWHW<-75; PULP<-10
metrics<-function(sp,dbh,ht,expf,form=NULL,risk=NULL){
  live<-is.finite(dbh)&dbh>=4&is.finite(expf)&expf>0
  sp<-sp[live];dbh<-dbh[live];ht<-ht[live];expf<-expf[live]
  if(!is.null(form)) form<-form[live]; if(!is.null(risk)) risk<-risk[live]
  if(!length(dbh)) return(c(BA=0,SDI=0,QMD=0,TOPHT=0,TOTVOL=0,MERCHVOL=0,SAWVOL=0,BIOMASS=0,VALUE=0,SAWVOL_s=0,VALUE_s=0))
  BA<-sum(pi*(dbh/200)^2*expf); TPH<-sum(expf); QMD<-sqrt((BA/TPH)/(pi/40000))
  SDI<-TPH*(QMD/25.0)^1.605
  o<-order(-dbh); cw<-cumsum(expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1; TOPHT<-mean(ifelse(is.finite(ht[o][idx]),ht[o][idx],himp(sp[o][idx],dbh[o][idx])))
  tot<-sum(nsvb(sp,dbh,ht,"VOLCFGRS")*expf)*FT3_M3; mer<-sum(nsvb(sp,dbh,ht,"VOLCFNET")*expf)*FT3_M3; saw<-sum(nsvb(sp,dbh,ht,"VOLCSNET")*expf)*FT3_M3
  bio<-sum(nsvb(sp,dbh,ht,"DRYBIO_AG")*expf)*LB_KG/1000
  issw<-sp %in% sw; sawv_sw<-sum(nsvb(sp[issw],dbh[issw],ht[issw],"VOLCSNET")*expf[issw])*FT3_M3; sawv_hw<-saw-sawv_sw
  val<-sawv_sw*SAWSW + sawv_hw*SAWHW + max(0,mer-saw)*PULP
  sawv_hw_s<-sawv_hw
  # OSM treelist carries no field form/risk -> _s columns collapse to base (identical to FVS baseline w/o SPLIT)
  saw_s<-sawv_sw + sawv_hw_s
  val_s<-sawv_sw*SAWSW + sawv_hw_s*SAWHW + max(0,mer-saw_s)*PULP
  c(BA=BA,SDI=SDI,QMD=QMD,TOPHT=TOPHT,TOTVOL=tot,MERCHVOL=mer,SAWVOL=saw,BIOMASS=bio,VALUE=val,SAWVOL_s=saw_s,VALUE_s=val_s)
}
# ===== END VERBATIM =====
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
MNAMES<-c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE","SAWVOL_s","VALUE_s")

tl<-fread(sprintf("osm_%s_treelist.csv",SRC)); tl[,STAND:=as.character(STAND)]; setkey(tl,STAND)
unmapped<-setdiff(unique(toupper(tl$SP)), acadgy)
cat(sprintf("[%s] OSM treelist rows=%d stands=%d uniqueSP=%d\n",SRC,nrow(tl),uniqueN(tl$STAND),uniqueN(tl$SP)))
cat("  SP not in AGY set (fallback via mapsp):", if(length(unmapped)) paste(unmapped,collapse=" ") else "NONE","\n")
cat("  HT missing (NA/<=0) rows:", sum(!(is.finite(tl$HT)&tl$HT>0)),"\n")

stands<-unique(tl$STAND)
pred<-rbindlist(lapply(stands, function(sid){
  d<-tl[.(sid)]; m<-metrics(mapsp(d$SP), d$DBH, d$HT, d$EXPF)
  data.table(STAND=sid, t(setNames(m, paste0(MNAMES,"_p"))))
}))

if (SRC=="ns") {
  obs<-fread("ns_base_results.csv")
} else {
  obs<-rbindlist(list(fread("ns_long_base_managed_results.csv"), fread("ns_long_base_unmanaged_results.csv")), fill=TRUE)
}
obs[, STAND := as.character(STAND)]
keepcols<-c("STAND","PROV","esi_cov","iv", paste0(MNAMES,"_t1"), paste0(MNAMES,"_o"))
obs2<-obs[, ..keepcols]
res<-merge(obs2, pred, by="STAND", all.x=FALSE, all.y=FALSE)   # inner: identical observed side
res[, ING_p := NA_real_]                                       # OSM treelist has no ingrowth id; keep schema col
setcolorder(res, c("STAND","PROV","esi_cov","iv",
  paste0(MNAMES,"_t1"), paste0(MNAMES,"_o"), paste0(MNAMES,"_p"), "ING_p"))
fwrite(res, sprintf("osm_score_%s_results.csv",SRC))
cat(sprintf("[%s] OSM predicted stands=%d ; FVS-scored stands=%d ; joined=%d ; FVS-only(dropped)=%d\n",
  SRC, uniqueN(tl$STAND), nrow(obs2), nrow(res), length(setdiff(obs2$STAND,pred$STAND))))
cat(sprintf("WROTE osm_score_%s_results.csv rows=%d cols=%d\nDONE\n", SRC, nrow(res), ncol(res)))

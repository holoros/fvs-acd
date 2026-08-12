# bench_parity_split_ms_v1211_silc_treeout.R
# Tree-output variant of bench_parity_split_ms_v1211.R (the driver that produced
# ~/magplot/verify/cand_silc_l_results.csv for the FVS-ACD v12.11 benchmark report).
# NO model logic changed. The only additions vs the original are:
#   (1) collection of per-tree t1 / predicted-t2 / observed-t2 records inside the
#       existing per-stand loop, and
#   (2) a second fwrite() at the end that writes those tree records to
#       ~/silc_cfi/v24_inputs/fvsacd_v1211_silc73_treelist.csv
# The original stand-aggregate output (fwrite(r, paste0(TAG,"_results.csv"))) is
# left completely intact so the published cand_silc_l_results.csv is reproducible
# byte-for-byte from this script under the same CONFIG_TAG/env, and this script is
# run under a DIFFERENT CONFIG_TAG (v1211_treeout_silc_l) so it never overwrites
# the original file.
#
# Written 2026-08-12 for the SILC73 tree-level rerun task. Diff against
# bench_parity_split_ms_v1211.R is confined to blocks marked "TREEOUT ADDITION".

.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify"); source(Sys.getenv("MODEL_FILE","~/AcadianGY_12.9.2.r")); source("~/hw_sawfrac_smith.R"); source("~/hw_formrisk_split.R"); SPLIT<-as.logical(Sys.getenv("SPLIT","FALSE"))
ecobucket_lookup <- fread("v129_gate3_dedup.csv"); ecobucket_lookup[, STAND:=as.character(STAND)]
bmapdt <- fread("v129x_brms_sdimax_map.csv"); BV <- setNames(bmapdt$sdimax_brms, as.character(bmapdt$STAND))

ONSET<-as.numeric(Sys.getenv("ONSET","0.30")); BREAK<-as.numeric(Sys.getenv("BREAK","0.62")); BG<-as.numeric(Sys.getenv("BG","0.02")); BS<-as.numeric(Sys.getenv("BS","0.80")); IRC<-as.numeric(Sys.getenv("IRC","0.58")); IRK<-as.numeric(Sys.getenv("IRK","8")); SDMAX<-as.numeric(Sys.getenv("SDMAX","1.0")); IMULT<-as.numeric(Sys.getenv("IMULT","1.0")); TAG<-Sys.getenv("CONFIG_TAG","cb_v129x")
NB_BREAK<-as.numeric(Sys.getenv("NB_BREAK","0.70")); QC_BREAK<-as.numeric(Sys.getenv("QC_BREAK","0.62"))
NB_IMULT<-as.numeric(Sys.getenv("NB_IMULT","1.0")); QC_IMULT<-as.numeric(Sys.getenv("QC_IMULT","1.0"))
USE_BRMS<-as.logical(Sys.getenv("USE_BRMS","TRUE")); USE_ANCHOR<-as.logical(Sys.getenv("USE_ANCHOR","TRUE"))
CSI_DEFAULT<-14
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
  if(!is.null(form) && !is.null(risk) && any(!is.na(form))){
    ishw<-!issw; hwm<-sp %in% c('AB','PB','QA','RM','RO','SM','WA','YB','OH')
    merch_i<-nsvb(sp,dbh,ht,"VOLCFNET"); nsaw_i<-nsvb(sp,dbh,ht,"VOLCSNET")
    ba_i<-pi*(dbh/200)^2*expf; baL<-sapply(seq_along(dbh),function(z) sum(ba_i[dbh>dbh[z]]))
    htu<-ifelse(is.finite(ht)&ht>0,ht,himp(sp,dbh)); htdbh<-htu/dbh
    sf<-rep(NA_real_,length(dbh))
    for(z in which(hwm & !is.na(form) & !is.na(risk))) sf[z]<-hw_sawfrac_discrete(sp[z],dbh[z],htdbh[z],baL[z],form[z],risk[z])
    hw_saw_i<-ifelse(hwm & is.finite(sf), sf*merch_i, nsaw_i)
    sawv_hw_s<-sum((hw_saw_i*expf)[ishw])*FT3_M3
  }
  saw_s<-sawv_sw + sawv_hw_s
  val_s<-sawv_sw*SAWSW + sawv_hw_s*SAWHW + max(0,mer-saw_s)*PULP
  c(BA=BA,SDI=SDI,QMD=QMD,TOPHT=TOPHT,TOTVOL=tot,MERCHVOL=mer,SAWVOL=saw,BIOMASS=bio,VALUE=val,SAWVOL_s=saw_s,VALUE_s=val_s)
}
PAIRS_FILE<-Sys.getenv("PAIRS_FILE","magp_qcnb_pairs.csv"); INIT_FILE<-Sys.getenv("INIT_FILE","magp_qcnb_tree_init.csv"); T2_FILE<-Sys.getenv("T2_FILE","magp_qcnb_tree_t2.csv"); SITE_FILE<-Sys.getenv("SITE_FILE","magp_qcnb_site_esi8.csv")
prs<-fread(PAIRS_FILE); ti<-fread(INIT_FILE); t2<-fread(T2_FILE)
e8<-fread(SITE_FILE); e8[,esi8:=as.numeric(esi8)]; prs<-merge(prs,e8,by="SITE",all.x=TRUE)
prs[,csi_site:=ifelse(is.finite(esi8)&esi8>2,esi8,CSI_DEFAULT)][,esi_cov:=is.finite(esi8)&esi8>2]
NB_AFAC<-as.numeric(Sys.getenv("NB_AFAC","1")); QC_AFAC<-as.numeric(Sys.getenv("QC_AFAC","1"))
# --- FROZEN-BASELINE GUARD (comment + warning only; no logic or default change) -------------
if (isTRUE(NB_AFAC==1) && isTRUE(QC_AFAC==1)) {
  message("WARNING: NB_AFAC/QC_AFAC at 1.0 (default) does NOT reproduce the frozen cb_v12101; the freeze uses 0.579/0.111. Set them explicitly (run_bench_frozen.sh / bench_frozen.sbatch).")
}
# --------------------------------------------------------------------------------------------
if(Sys.getenv("INDOMAIN","1")=="1") prs <- prs[PROV=="NB" | esi_cov==TRUE]
if(nchar(Sys.getenv("NMAX"))>0) prs <- prs[seq_len(min(nrow(prs),as.integer(Sys.getenv("NMAX")))),]
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
bf<-function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
ops<<-make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE); ops$use.hw.mod <- as.logical(Sys.getenv("USE_MODS","FALSE"))
ops$use.sdimort<-TRUE;ops$sdimort.onset<-ONSET;ops$sdimort.break<-BREAK;ops$sdimort.beta.gentle<-BG;ops$sdimort.beta.steep<-BS;ops$sdimort.max<-SDMAX;ops$sdimax.site.term<-FALSE;ops$use.mortcal<-FALSE;ops$use.ingrowth.release<-TRUE;ops$ingrowth.rd.center<-IRC;ops$ingrowth.rd.k<-IRK;ops$ingrowth.mult<-IMULT
ops$use.esi.domht <- FALSE
ops$use.brms.sdimax <- USE_BRMS; ops$brms.sdimax.map <- list(BV)
ops$use.esi.anchor.recal <- USE_ANCHOR
ops$esi.anchor.coef <- list(list(NB=c(0.885,0.01027), QC=c(0.441,0.03783)))
ops$sdimort.break.region <- list(c(NB=NB_BREAK, QC=QC_BREAK))
ops$ingrowth.mult.region <- list(c(NB=NB_IMULT, QC=QC_IMULT))

## ===== v12.11 gated levers (env-driven; all default OFF => reproduces the MODEL_FILE base
## byte-for-byte). Set one diameter form (REIN or STANDCON), not both. =====
V1211_REIN     <- as.logical(Sys.getenv("V1211_REIN","FALSE"))
V1211_STANDCON <- as.logical(Sys.getenv("V1211_STANDCON","FALSE"))
V1211_MORTGATE <- as.logical(Sys.getenv("V1211_MORTGATE","FALSE"))
V1211_IGTAPER  <- as.logical(Sys.getenv("V1211_IGTAPER","FALSE"))
V1211_IGMULT   <- as.numeric(Sys.getenv("V1211_IGMULT","1.0"))
V1211_MANAGED  <- as.logical(Sys.getenv("V1211_MANAGED","FALSE"))
SC_LO <- as.numeric(Sys.getenv("SC_LO","0.60")); SC_HI <- as.numeric(Sys.getenv("SC_HI","0.80"))
SC_QMIN <- as.numeric(Sys.getenv("SC_QMIN","0"))
REIN_R <- as.numeric(Sys.getenv("REIN_R","0.90"))
V1211_DHTHW <- as.logical(Sys.getenv("V1211_DHTHW","FALSE"))
if (isTRUE(V1211_REIN))     { ops$use.ddbh.rein <- TRUE; ops$ddbh.rein.r <- REIN_R }
if (isTRUE(V1211_STANDCON)) { ops$use.ddbh.standcon <- TRUE; ops$ddbh.standcon.lo <- SC_LO; ops$ddbh.standcon.hi <- SC_HI; ops$ddbh.standcon.qmin <- SC_QMIN }
if (isTRUE(V1211_DHTHW))    { ops$use.dht.hw.mod <- TRUE }
if (isTRUE(V1211_MORTGATE)) { ops$mort.dens.scale <- TRUE; ops$stand.managed <- isTRUE(V1211_MANAGED)
  ops$mort.dens.fmin <- as.numeric(Sys.getenv("MORT_FMIN","0.13"))
  ops$mort.dens.k    <- as.numeric(Sys.getenv("MORT_K","12.4"))
  ops$mort.dens.rd0  <- as.numeric(Sys.getenv("MORT_RD0","0.38")) }
if (isTRUE(V1211_IGTAPER))  { ops$use.ingrowth.rdtaper <- TRUE }
if (is.finite(V1211_IGMULT) && V1211_IGMULT != 1.0) { ops$ingrowth.mult <- V1211_IGMULT }
cat(sprintf("V1211 levers: REIN=%s STANDCON=%s(lo%.2f hi%.2f) MORTGATE=%s(managed=%s) IGTAPER=%s IGMULT=%.2f\n",
  V1211_REIN,V1211_STANDCON,SC_LO,SC_HI,V1211_MORTGATE,V1211_MANAGED,V1211_IGTAPER,V1211_IGMULT))

setkey(ti,STAND);setkey(t2,STAND);setDF(prs)
MNAMES<-c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
out<-list();fail<-0
tree_out<-list()  # TREEOUT ADDITION: per-tree t1/pred-t2/obs-t2 accumulator
for(k in seq_len(nrow(prs))){ p<-prs[k,];sid<-p$STAND
  it<-ti[.(sid)];ot<-t2[.(sid)]; if(nrow(it)<3||nrow(ot)<3){fail<-fail+1;next}
  iv<-max(1,round(p$interval_years)); elev<-if(is.finite(p$ELEV)&&p$ELEV>0)p$ELEV else 200
  setTimeLimit(elapsed=60,transient=TRUE)
  res<-tryCatch({
    cur<-data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=(if(p$PROV=="NB") NB_AFAC else if(p$PROV=="QC") QC_AFAC else 1),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    if(SPLIT){cur<-split_formrisk(cur)}
    csi_use<-if(is.finite(p$csi_site)&&p$csi_site>2)p$csi_site else CSI_DEFAULT; reg<-if(p$PROV=="NB")"NB" else if(p$PROV=="QC")"QC" else "ME"
    stand<<-make_stand(stand.id=sid,csi=csi_use,elev=elev,region=reg)
    ops$active_ecobucket <- ecobucket_lookup[STAND==sid, gate3][1]
    n_init <- max(cur$tree)
    for(yr in seq_len(iv)){nx<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops); if(is.null(nx)||nrow(nx)==0)stop("empty"); cur<-bf(nx)}
    attr(cur,"n_init") <- n_init
    cur},error=function(e)NULL)
  setTimeLimit()
  if(is.null(res)){fail<-fail+1;next}
  n_init <- attr(res,"n_init")
  ing_expf <- sum(res$expf[res$tree > n_init & is.finite(res$dbh) & res$dbh>=5], na.rm=TRUE)
  ing_rate <- ing_expf / iv
  m1<-metrics(mapsp(it$SP),it$DBH,it$HT,it$EXPF); m2o<-metrics(mapsp(ot$SP),ot$DBH,ot$HT,ot$EXPF); m2p<-metrics(res$sp,res$dbh,res$ht,res$expf,res$form,res$risk)
  out[[k]]<-data.frame(STAND=sid,PROV=p$PROV,esi_cov=p$esi_cov,iv=iv,
    t(setNames(m1,paste0(names(m1),"_t1"))),t(setNames(m2o,paste0(names(m2o),"_o"))),t(setNames(m2p,paste0(names(m2p),"_p"))),ING_p=ing_rate)

  ## ===== TREEOUT ADDITION: per-tree t1 / predicted-t2 / observed-t2 records =====
  ## PLOT is the true SILC plot number (prs$SITE), not the internal STAND pair-id.
  ## YEAR uses each side's own measurement year (it$YEAR / ot$YEAR), which is the
  ## plot's actual t1 and t2 calendar year for its own longest reliable interval.
  y1 <- if("YEAR" %in% names(it)) it$YEAR[1] else NA_integer_
  y2 <- if("YEAR" %in% names(ot)) ot$YEAR[1] else NA_integer_
  t1_dt <- data.table(STAND=sid, PLOT=p$SITE, YEAR=y1, RECORD="T1",
                       TREE=it$TREE, sp=mapsp(it$SP), dbh_cm=it$DBH, ht_m=it$HT, expf_tph=it$EXPF)
  p2_dt <- data.table(STAND=sid, PLOT=p$SITE, YEAR=y2, RECORD="PRED_T2",
                       TREE=res$tree, sp=res$sp, dbh_cm=res$dbh, ht_m=res$ht, expf_tph=res$expf)
  o2_dt <- data.table(STAND=sid, PLOT=p$SITE, YEAR=y2, RECORD="OBS_T2",
                       TREE=ot$TREE, sp=mapsp(ot$SP), dbh_cm=ot$DBH, ht_m=ot$HT, expf_tph=ot$EXPF)
  tree_out[[k]] <- rbindlist(list(t1_dt, p2_dt, o2_dt), use.names=TRUE, fill=TRUE)
  ## ===== end TREEOUT ADDITION =====
}
r<-rbindlist(out,fill=TRUE); fwrite(r,paste0(TAG,"_results.csv"))
cat(sprintf("=== %s v12.9.2 O%.2f BG%.3f BS%.3f IRC%.2f IRK%.1f SDMx%.2f NBbrk%.2f QCbrk%.2f NBimult%.2f QCimult%.2f BRMS%s ANCHOR%s n=%d (%d fail) ===\n",TAG,ONSET,BG,BS,IRC,IRK,SDMAX,NB_BREAK,QC_BREAK,NB_IMULT,QC_IMULT,USE_BRMS,USE_ANCHOR,nrow(r),fail))
for(pv in c("NB","QC","SILC","SILC_L")){ s<-r[PROV==pv]; if(nrow(s)<5)next; cat(sprintf("-- %s n=%d --\n",pv,nrow(s)))
 for(M in MNAMES){ o<-s[[paste0(M,"_o")]];pp<-s[[paste0(M,"_p")]];t1<-s[[paste0(M,"_t1")]]
   lvb<-100*(mean(pp)/mean(o)-1); pao<-mean((o-t1)/s$iv); pap<-mean((pp-t1)/s$iv)
   cat(sprintf("   %-9s level obs %8.2f pred %8.2f bias %+6.1f%% | PAI obs %+7.3f pred %+7.3f bias %+7.3f\n",M,mean(o),mean(pp),lvb,pao,pap,pap-pao)) }
}

## ===== TREEOUT ADDITION: write per-tree output =====
treedt <- rbindlist(tree_out, fill=TRUE)
TREE_OUT_PATH <- Sys.getenv("TREE_OUT_PATH", "/users/PUOM0008/crsfaaron/silc_cfi/v24_inputs/fvsacd_v1211_silc73_treelist.csv")
dir.create(dirname(TREE_OUT_PATH), recursive=TRUE, showWarnings=FALSE)
fwrite(treedt, TREE_OUT_PATH)
cat(sprintf("=== TREEOUT: wrote %s -- %d rows (%d stands, %d plots, records: %s) ===\n",
    TREE_OUT_PATH, nrow(treedt), uniqueN(treedt$STAND), uniqueN(treedt$PLOT),
    paste(sprintf("%s=%d", names(table(treedt$RECORD)), table(treedt$RECORD)), collapse=", ")))
## ===== end TREEOUT ADDITION =====
cat("DONE\n")

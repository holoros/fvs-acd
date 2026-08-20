# v13.1 posterior-scoring benchmark harness (DRAFT). Scores AcadianGY v13.1 through the same
# multi-source MagPlot / CFI benchmark battery used for v12.11, on FIA NSVB currency, but invoking
# the HIERARCHICAL ingrowth and mortality posteriors through the v13.1 model-file ops switches
# instead of the v12.11 hand levers. Built by swapping the V1211_* env-lever block of
# bench_parity_split_ms_v1211.R for the v13.1 posterior-enable switches; every other block (NSVB
# emulator, metrics, per-stand projection loop, per-source result CSV) is reused byte-for-byte so
# the v1211 aggregators (v1211_allsites_scorecard.R, v1211_maturity_scorecard.R) read the output
# unchanged.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
bias_pct <- function(o,p) 100*(mean(p,na.rm=TRUE)/mean(o,na.rm=TRUE)-1)
rmse_pct <- function(o,p){ rmse<-sqrt(mean((p-o)^2,na.rm=TRUE)); mo<-mean(o,na.rm=TRUE); if(is.finite(mo)&&abs(mo)>1e-9) 100*rmse/mo else NA_real_ }
if (identical(Sys.getenv("SCORECARD"), "1")) {
  CAND_PREFIX <- Sys.getenv("CAND_PREFIX", "v131"); CAND_LABEL  <- Sys.getenv("CAND_LABEL",  "CANDIDATE v13.1"); BASE_PREFIX <- Sys.getenv("BASE_PREFIX", "v131base")
  rd <- function(f) if(file.exists(f)) fread(f) else NULL
  summ_row <- function(region, source, grain, model, d, prov_filter=NULL){
    if(!is.null(prov_filter)) d <- d[PROV==prov_filter]
    if(is.null(d) || nrow(d)==0) return(NULL)
    data.table(region=region, source=source, grain=grain, model=model, n=nrow(d),
      TOTVOL_bias_pct = round(bias_pct(d$TOTVOL_o, d$TOTVOL_p),2), BA_bias_pct = round(bias_pct(d$BA_o, d$BA_p),2), TOTVOL_rmse_pct = round(rmse_pct(d$TOTVOL_o, d$TOTVOL_p),2))
  }
  rows <- list()
  specs <- list(
    list(region="ME", source="Baxter (mature, held-out)",                 grain="stand",      src="baxter",     osm="osm_score_baxter_results.csv"),
    list(region="ME", source="SILC/Seven Islands (calibration, managed)",  grain="stand",      src="silc_l",     osm="osm_score_silc_l_results.csv"),
    list(region="ME", source="PEF (developing)",                           grain="stand",      src="pef",        osm="osm_score_pef_results.csv"),
    list(region="ME", source="CFRU CTRN (managed)",                        grain="stand",      src="ctrn",       osm="osm_score_ctrn_results.csv"),
    list(region="ME", source="Maine FIA (developing)",                     grain="whole-plot", src="mefia_l",    osm="osm_score_me_fia_l_results.csv"),
    list(region="ME", source="Maine FIA (developing)",                     grain="subplot",    src="mefia_subp", osm=NULL)
  )
  for(sp in specs){
    b <- rd(sprintf("%s_%s_results.csv", BASE_PREFIX, sp$src)); c <- rd(sprintf("%s_%s_results.csv", CAND_PREFIX, sp$src)); o <- if(!is.null(sp$osm)) rd(sp$osm) else NULL
    if(!is.null(b)) rows[[length(rows)+1]] <- summ_row(sp$region, sp$source, sp$grain, "BASE (frozen, no levers)", b)
    if(!is.null(c)) rows[[length(rows)+1]] <- summ_row(sp$region, sp$source, sp$grain, CAND_LABEL, c)
    if(!is.null(o)) rows[[length(rows)+1]] <- summ_row(sp$region, sp$source, sp$grain, "OSM-ACD v2.26.1", o)
  }
  b_nb <- rd(sprintf("%s_nb_results.csv", BASE_PREFIX)); c_nb <- rd(sprintf("%s_nb_results.csv", CAND_PREFIX)); o_nb <- rd("g4_osm_score_nb_results.csv")
  rows[[length(rows)+1]] <- summ_row("NB", "NB MagPlot (managed)", "stand", "BASE (frozen, no levers)", b_nb, prov_filter="NB")
  rows[[length(rows)+1]] <- summ_row("NB", "NB MagPlot (managed)", "stand", CAND_LABEL, c_nb, prov_filter="NB")
  if(!is.null(o_nb)) rows[[length(rows)+1]] <- summ_row("NB", "NB MagPlot (managed)", "stand", "OSM-ACD v2.26.1", o_nb, prov_filter="NB")
  rows[[length(rows)+1]] <- summ_row("QC", "QC MagPlot (managed)", "stand", "BASE (frozen, no levers)", b_nb, prov_filter="QC")
  rows[[length(rows)+1]] <- summ_row("QC", "QC MagPlot (managed)", "stand", CAND_LABEL, c_nb, prov_filter="QC")
  ns_base <- rbindlist(list(rd(sprintf("%s_ns_managed_results.csv",Sys.getenv("BASE_PREFIX","v131base"))), rd(sprintf("%s_ns_unmanaged_results.csv",Sys.getenv("BASE_PREFIX","v131base")))), fill=TRUE)
  ns_cand <- rbindlist(list(rd(sprintf("%s_ns_managed_results.csv", CAND_PREFIX)), rd(sprintf("%s_ns_unmanaged_results.csv", CAND_PREFIX))), fill=TRUE)
  if(is.null(ns_cand) || nrow(ns_cand)==0) ns_cand <- NULL
  ns_osm  <- rd("osm_score_ns_results.csv")
  if(!is.null(ns_base)) rows[[length(rows)+1]] <- summ_row("NS","NS remeasurement (managed+unmanaged)","stand","BASE (frozen, no levers)", ns_base)
  if(!is.null(ns_cand)) rows[[length(rows)+1]] <- summ_row("NS","NS remeasurement (managed+unmanaged)","stand", CAND_LABEL, ns_cand)
  if(!is.null(ns_osm))  rows[[length(rows)+1]] <- summ_row("NS","NS remeasurement (managed+unmanaged)","stand","OSM-ACD v2.26.1", ns_osm)
  nsl_base <- rbindlist(list(rd(sprintf("%s_ns_long_managed_results.csv",Sys.getenv("BASE_PREFIX","v131base"))), rd(sprintf("%s_ns_long_unmanaged_results.csv",Sys.getenv("BASE_PREFIX","v131base")))), fill=TRUE); if(is.null(nsl_base)||nrow(nsl_base)==0) nsl_base<-NULL
  nsl_cand <- rbindlist(list(rd(sprintf("%s_ns_long_managed_results.csv", CAND_PREFIX)), rd(sprintf("%s_ns_long_unmanaged_results.csv", CAND_PREFIX))), fill=TRUE); if(is.null(nsl_cand)||nrow(nsl_cand)==0) nsl_cand<-NULL
  nsl_osm  <- rd("osm_score_ns_long_results.csv")
  if(!is.null(nsl_base)) rows[[length(rows)+1]] <- summ_row("NS","NS long CFI (managed emphasis)","stand","BASE (frozen, no levers)", nsl_base)
  if(!is.null(nsl_cand)) rows[[length(rows)+1]] <- summ_row("NS","NS long CFI (managed emphasis)","stand", CAND_LABEL, nsl_cand)
  if(!is.null(nsl_osm))  rows[[length(rows)+1]] <- summ_row("NS","NS long CFI (managed emphasis)","stand","OSM-ACD v2.26.1", nsl_osm)
  sc <- rbindlist(rows, fill=TRUE); sc[, region := factor(region, levels=c("ME","NB","QC","NS"))]; sc[, model  := factor(model, levels=c("BASE (frozen, no levers)", CAND_LABEL, "OSM-ACD v2.26.1"))]
  setorder(sc, region, source, grain, model)
  OUT <- Sys.getenv("SCORECARD_OUT", "v131_allsites_scorecard.csv"); fwrite(sc, OUT); cat("WROTE", OUT, "rows=", nrow(sc), "\n"); print(sc); cat("DONE_ALLSITES_SCORECARD\n")
  quit(save="no", status=0)
}
source(Sys.getenv("MODEL_FILE","~/AcadianGY_13.1.r")); source("~/hw_sawfrac_smith.R"); source("~/hw_formrisk_split.R"); SPLIT<-as.logical(Sys.getenv("SPLIT","FALSE"))
## ---- PASS 21 addition: stack the pass-20 v13.2 site-fsm calc_ddbh patch ON TOP of whatever
## MODEL_FILE was just sourced above. Order matters: the overlay's own source(NEW) re-sources
## plain AcadianGY_13.1.r, which would silently undo the MODEL_FILE ddbh patch if left last, so
## MODEL_FILE is re-sourced AFTER the overlay to reapply it; calc_ddbh_v132 calls `ddbh` by name
## at run time so it picks up the reapplied patch. Verified this pass (stack-verify script):
## ddbh(test) patched -> wiped by overlay source -> reapplied -> activate_v132 confirmed
## identical(calc_ddbh, calc_ddbh_v132) and NOT identical to shipped calc_ddbh. Gated on V132=1 so
## this file is a superset of bench_p9.R (V132=0 reproduces bench_p9.R exactly, verified
## byte-identical against p9_bax_ship18_results.csv on the observed/t1 basis this pass).
if (identical(Sys.getenv("V132","1"), "1")) {
  source("~/magplot/verify/p20_v132/2026-08-19_v132_sitefsm_overlay_WIP.R")
  source(Sys.getenv("MODEL_FILE","~/AcadianGY_13.1.r"))
  activate_v132()
  cat("PASS21: v13.2 site-fsm overlay active on top of MODEL_FILE=", Sys.getenv("MODEL_FILE","~/AcadianGY_13.1.r"), "\n")
} else {
  cat("PASS21: V132=0, running plain MODEL_FILE with no v13.2 overlay (bench_p9.R-equivalent)\n")
}
ecobucket_lookup <- fread("v129_gate3_dedup.csv"); ecobucket_lookup[, STAND:=as.character(STAND)]
bmapdt <- fread("v129x_brms_sdimax_map.csv"); BV <- setNames(bmapdt$sdimax_brms, as.character(bmapdt$STAND))
ONSET<-as.numeric(Sys.getenv("ONSET","0.30")); BREAK<-as.numeric(Sys.getenv("BREAK","0.62")); BG<-as.numeric(Sys.getenv("BG","0.02")); BS<-as.numeric(Sys.getenv("BS","0.80")); IRC<-as.numeric(Sys.getenv("IRC","0.58")); IRK<-as.numeric(Sys.getenv("IRK","8")); SDMAX<-as.numeric(Sys.getenv("SDMAX","1.0")); IMULT<-as.numeric(Sys.getenv("IMULT","1.0")); TAG<-Sys.getenv("CONFIG_TAG","cb_v131")
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
for(r in RESP) CF[[r]]<-list(a=setNames(co[[paste0(r,"_a")]][ci],agy_codes), b=setNames(co[[paste0(r,"_b")]][ci],agy_codes), sm=setNames(co[[paste0(r,"_sm")]][ci],agy_codes))
nsvb<-function(agy,dbh_cm,ht_m,resp){
  ht<-ifelse(is.finite(ht_m)&ht_m>0,ht_m,himp(agy,dbh_cm)); lX<-log((dbh_cm/2.54)^2*(ht/0.3048))
  a<-CF[[resp]]$a[agy]; b<-CF[[resp]]$b[agy]; sm<-CF[[resp]]$sm[agy]; y<-sm*exp(a+b*lX); y[!is.finite(y)]<-0; unname(y)
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
  saw_s<-sawv_sw + sawv_hw_s; val_s<-sawv_sw*SAWSW + sawv_hw_s*SAWHW + max(0,mer-saw_s)*PULP
  c(BA=BA,SDI=SDI,QMD=QMD,TOPHT=TOPHT,TOTVOL=tot,MERCHVOL=mer,SAWVOL=saw,BIOMASS=bio,VALUE=val,SAWVOL_s=saw_s,VALUE_s=val_s)
}
PAIRS_FILE<-Sys.getenv("PAIRS_FILE","magp_qcnb_pairs.csv"); INIT_FILE<-Sys.getenv("INIT_FILE","magp_qcnb_tree_init.csv"); T2_FILE<-Sys.getenv("T2_FILE","magp_qcnb_tree_t2.csv"); SITE_FILE<-Sys.getenv("SITE_FILE","magp_qcnb_site_esi8.csv")
prs<-fread(PAIRS_FILE); ti<-fread(INIT_FILE); t2<-fread(T2_FILE)
e8<-fread(SITE_FILE); e8[,esi8:=as.numeric(esi8)]; prs<-merge(prs,e8,by="SITE",all.x=TRUE)
prs[,csi_site:=ifelse(is.finite(esi8)&esi8>2,esi8,CSI_DEFAULT)][,esi_cov:=is.finite(esi8)&esi8>2]
NB_AFAC<-as.numeric(Sys.getenv("NB_AFAC","1")); QC_AFAC<-as.numeric(Sys.getenv("QC_AFAC","1"))
if (isTRUE(NB_AFAC==1) && isTRUE(QC_AFAC==1)) {
  message("WARNING: NB_AFAC/QC_AFAC at 1.0 (default) does NOT reproduce the frozen cb_v12101; the freeze uses 0.579/0.111. Set them explicitly.")
}
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
if(nzchar(Sys.getenv("NOCON",""))){ops$use.ddbh.standcon<-TRUE;ops$ddbh.standcon.hi<-5;ops$ddbh.standcon.lo<-5;ops$ddbh.standcon.qmin<-0;cat("P6: Ch10 BA CONSTRAINT DISABLED\n")}
if(nzchar(Sys.getenv("NOSDI",""))){ops$sdimort.onset<-9.99;ops$sdimort.break<-9.99;cat("P6: SDIMAX SELF-THINNING DISABLED (onset pushed out of reach)\n")}
if(nzchar(Sys.getenv("LEV3",""))){
  ops$use.ddbh.standcon<-TRUE
  ops$ddbh.standcon.hi<-as.numeric(Sys.getenv("LEV3_HI","0.45"))
  ops$ddbh.standcon.lo<-as.numeric(Sys.getenv("LEV3_LO","0.35"))
  ops$ddbh.standcon.qmin<-as.numeric(Sys.getenv("LEV3_QMIN","22"))
  cat(sprintf("P9 LEVER 3b ON: hi=%.4f lo=%.4f qmin=%.4f\n", ops$ddbh.standcon.hi, ops$ddbh.standcon.lo, ops$ddbh.standcon.qmin))
} else { cat("P9 LEVER 3b OFF (gate-off path)\n") }
if(nzchar(Sys.getenv("REIN",""))){ stop("P9: lever 3a (ddbh.rein) is banned by standing warning; refusing to run") }
cat(sprintf("P6 config: IMULT=%.4f NOCON=%s NOSDI=%s\n", IMULT, Sys.getenv("NOCON",""), Sys.getenv("NOSDI","")))
USE_HIER_ING  <- as.logical(Sys.getenv("USE_HIER_ING","FALSE"))
USE_HIER_MORT <- as.logical(Sys.getenv("USE_HIER_MORT","FALSE"))
HIER_POSTDIR  <- Sys.getenv("HIER_POSTDIR","~/v13_kickoff")
ops$use.hier.ingrowth  <- USE_HIER_ING
ops$use.hier.mortality <- USE_HIER_MORT
ops$hier.postdir       <- HIER_POSTDIR
cat(sprintf("v13.1 posterior switches: use.hier.ingrowth=%s use.hier.mortality=%s hier.postdir=%s\n", USE_HIER_ING, USE_HIER_MORT, HIER_POSTDIR))
setkey(ti,STAND);setkey(t2,STAND);setDF(prs)
MNAMES<-c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
out<-list();fail<-0
TREE_OUT<-Sys.getenv("TREE_OUT","")
tlp<-list(); tly1<-list(); tl0<-list(); y1cap<-NULL; t0cap<-NULL
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
    if(nzchar(TREE_OUT)) t0cap<<-cur
    for(yr in seq_len(iv)){nx<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops); if(is.null(nx)||nrow(nx)==0)stop("empty"); cur<-bf(nx); if(nzchar(TREE_OUT) && yr==1L) y1cap<<-cur}
    attr(cur,"n_init") <- n_init
    cur},error=function(e)NULL)
  setTimeLimit()
  if(is.null(res)){fail<-fail+1;next}
  n_init <- attr(res,"n_init")
  ing_expf <- sum(res$expf[res$tree > n_init & is.finite(res$dbh) & res$dbh>=5], na.rm=TRUE)
  ing_rate <- ing_expf / iv
  if(nzchar(TREE_OUT)){
    tlp[[length(tlp)+1]] <- data.table::data.table(STAND=sid, iv=iv, tree=res$tree, sp=res$sp, dbh=res$dbh, ht=res$ht, expf=res$expf, ing=as.integer(res$tree > n_init))
    if(!is.null(t0cap)) tl0[[length(tl0)+1]] <- data.table::data.table(STAND=sid, tree=t0cap$tree, sp=t0cap$sp, dbh=t0cap$dbh, ht=t0cap$ht, expf=t0cap$expf)
    t0cap<<-NULL
    if(!is.null(y1cap)) tly1[[length(tly1)+1]] <- data.table::data.table(STAND=sid, tree=y1cap$tree, sp=y1cap$sp, dbh=y1cap$dbh, ht=y1cap$ht, pht=if(!is.null(y1cap$pht)) y1cap$pht else NA_real_, expf=y1cap$expf, ing=as.integer(y1cap$tree > n_init))
    y1cap<<-NULL
  }
  m1<-metrics(mapsp(it$SP),it$DBH,it$HT,it$EXPF); m2o<-metrics(mapsp(ot$SP),ot$DBH,ot$HT,ot$EXPF); m2p<-metrics(res$sp,res$dbh,res$ht,res$expf,res$form,res$risk)
  out[[k]]<-data.frame(STAND=sid,PROV=p$PROV,esi_cov=p$esi_cov,iv=iv, t(setNames(m1,paste0(names(m1),"_t1"))),t(setNames(m2o,paste0(names(m2o),"_o"))),t(setNames(m2p,paste0(names(m2p),"_p"))),ING_p=ing_rate)
}
r<-rbindlist(out,fill=TRUE); fwrite(r,paste0(TAG,"_results.csv"))
if(nzchar(TREE_OUT)){
  tp<-rbindlist(tlp,fill=TRUE); fwrite(tp,paste0(TREE_OUT,"_pred_t2_tree.csv"))
  t0<-rbindlist(tl0,fill=TRUE); fwrite(t0,paste0(TREE_OUT,"_t1_split_tree.csv"))
  ty<-rbindlist(tly1,fill=TRUE); fwrite(ty,paste0(TREE_OUT,"_pred_yr1_tree.csv"))
  cat(sprintf("WROTE tree lists: pred_t2 rows=%d stands=%d ; yr1 rows=%d stands=%d\n", nrow(tp),uniqueN(tp$STAND),nrow(ty),uniqueN(ty$STAND)))
}
cat(sprintf("=== %s v13.1 IGhier=%s MORThier=%s O%.2f BG%.3f BS%.3f IRC%.2f IRK%.1f SDMx%.2f NBbrk%.2f QCbrk%.2f BRMS%s ANCHOR%s n=%d (%d fail) ===\n",TAG,USE_HIER_ING,USE_HIER_MORT,ONSET,BG,BS,IRC,IRK,SDMAX,NB_BREAK,QC_BREAK,USE_BRMS,USE_ANCHOR,nrow(r),fail))
for(pv in c("NB","QC")){ s<-r[PROV==pv]; if(nrow(s)<5)next; cat(sprintf("-- %s n=%d --\n",pv,nrow(s)))
 for(M in MNAMES){ o<-s[[paste0(M,"_o")]];pp<-s[[paste0(M,"_p")]];t1<-s[[paste0(M,"_t1")]]
   lvb<-100*(mean(pp)/mean(o)-1); pao<-mean((o-t1)/s$iv); pap<-mean((pp-t1)/s$iv)
   cat(sprintf("   %-9s level obs %8.2f pred %8.2f bias %+6.1f%% | PAI obs %+7.3f pred %+7.3f bias %+7.3f\n",M,mean(o),mean(pp),lvb,pao,pap,pap-pao)) }
 cat(sprintf("   %-9s PRED ingrowth stems/ha/yr = %.2f (observed MagPlot ~%.1f)\n","ING",mean(s$ING_p),if(pv=="NB") 39.8 else 19.7))
}
cat("DONE\n")

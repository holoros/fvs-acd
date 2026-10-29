# PREREG44 DRIVER (2026-10-05), built by build_driver_p44.sh from the PREREG31 driver driver_p31.R (md5 467fb518) with
# exactly two edits, both checked to match once: (1) the mode check admits slgrid beside g0 and grid; (2) a new slgrid
# branch (parts/slgrid_branch.R) is inserted before the g0 branch, whose line becomes "} else if (P31_MODE == "g0") {".
# Every other line, including the g0 and grid modes, the runner lines 1 to 419 and the dht.mult expression, is driver_p31.R
# byte for byte; gates G0 and G0b test that the existing modes are unchanged. Diff in ../diffs/. No coordinates. No em dashes.
# PREREG31 LONG HORIZON DRIVER (2026-09-30), built by build_driver_p31.sh as: this header, then lines 1 to 419 of
# ~/jobs/v142p28b/home/runner_p28_fb.R (md5 0a2b27421ee7b25eaab7f4591ce3af97) byte for byte, then the PREREG31 block
# (parts/p31_block.R), which replaces runner lines 420 to 486 (the PHASE D hooks, the one interval per stand loop and the
# result writer). The model setup, ops, the 14.1 overlay and every switch are the runner's own lines. The per stand
# projection is the runner's lines 426 to 437 moved into a function without the PHASE D recording hooks and with a longer
# time limit, as in PREREG26 driver_p26.R. The QC dht.mult expression is runner line 425's, copied by the build script
# from the runner text (placeholder in parts/p31_block.R). Diff against the runner in ../diffs/. No coordinates. No em dashes.
# V142 COPY (2026-09-25) of v141_20260923/phaseD_v141/scripts/2026-09-25_v141_phaseD_runner_p23_tst.R
# (parent md5 8471121e3a880e838b42923250a94cdd). One change: the overlay counter file is named
# <set>_<chunk>_v141_counters.csv instead of <chunk>_v141_counters.csv, because the parent's name
# collided across sources when one V141_REPORT_DIR served several (ref141 step 0, 25 September).
# Projection, scoring and every output file are unchanged. Diff in ../diffs/. No em dashes.
# V141 COPY (2026-09-25) of v1404/phaseD/scripts/2026-09-18_v1404D_runner_p23.R
# (parent md5 3ec6df2131e5429d1420c099e85468c3). Adds exactly three things and changes nothing
# else: an optional source of the 14.1 option 3 overlay, a per stand years-since-thinning
# resolved from data, and the per year advance of ops$stand.tst inside the projection loop.
# With V141 unset this file behaves as its parent. Diff in ../diffs/. Built for gate E6 under
# pre-registration 2 revision 5. No em dashes.
# PHASE D COPY (2026-09-16) of /users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/runs/scripts/2026-09-16_gydbreg_runner_p23.R (md5 01f0d07934389e1036b4edbd93994a4f), built by 2026-09-16_gydbreg-phaseD_make_runners.py.
# Adds read-only trajectory and tree-list recording hooks (/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/phaseD/scripts/2026-09-16_gydbreg-phaseD_trajhooks.R); projection and scoring unchanged.
# FROZEN COPY for gydbreg20260916 Phase B, built 2026-09-16 from /users/PUOM0008/crsfaaron/magplot/verify/p23/2026-09-07_p23_bench_v14.R (md5 a16e52bb4dd12f66b451c03e6be456ec).
# Every change is in runs/diffs/2026-09-16_gydbreg_runner_p23.R.diff. No em dashes.
# v13.1 posterior-scoring benchmark harness (DRAFT). Scores AcadianGY v13.1 through the same
# multi-source MagPlot / CFI benchmark battery used for v12.11, on FIA NSVB currency, but invoking
# the HIERARCHICAL ingrowth and mortality posteriors through the v13.1 model-file ops switches
# instead of the v12.11 hand levers. Built by swapping the V1211_* env-lever block of
# bench_parity_split_ms_v1211.R for the v13.1 posterior-enable switches; every other block (NSVB
# emulator, metrics, per-stand projection loop, per-source result CSV) is reused byte-for-byte so
# the v1211 aggregators (v1211_allsites_scorecard.R, v1211_maturity_scorecard.R) read the output
# unchanged. Draft and syntax-check only: do NOT source a model file that does not yet exist, do
# NOT run scoring or submit jobs. Aggregates only; benchmark data and FIA coordinates stay on node.
#
# MODEL-INVOCATION CONTRACT (exposed by the v13.1 model file AcadianGY_13.1[_DRAFT].r):
#   ops$use.hier.ingrowth  (default FALSE)  enable fitted hierarchical recruitment posterior
#   ops$use.hier.mortality (default FALSE)  enable fitted hierarchical hazard posterior
#   ops$hier.postdir       (default ~/v13_kickoff)  dir holding the posterior summary CSVs
#                          (v131r_ingrowth_ranef.csv/_fixef.csv/_varcomp.csv,
#                           v131r_mortBNS_fixef.csv/_varcomp.csv/_scaling.csv; NS-inclusive whole-plot
#                           mortality, job 12554985), read by the model file, not by this harness.
#   Gate-off  = both switches FALSE and no v12.11 levers  => reproduces frozen v12.10.1 byte-for-byte.
#   Candidate = both switches TRUE                        => fitted recruitment + hazard.
#
# Two v12.11 -> v13.1 swap points (everything else identical):
#   (1) MODEL_FILE default -> the v13.1 model file (base rows still set MODEL_FILE=12.10.1).
#   (2) the V1211_* gated hand-lever block (REIN/STANDCON/MORTGATE/IGTAPER/IGMULT/DHTHW) is deleted
#       and replaced by the three USE_HIER_*/HIER_POSTDIR ops switches above.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd(path.expand("~/magplot/verify"))

# ---- level-bias and RMSE helpers (shared by generator summary and SCORECARD mode) --------------
bias_pct <- function(o,p) 100*(mean(p,na.rm=TRUE)/mean(o,na.rm=TRUE)-1)
rmse_pct <- function(o,p){ rmse<-sqrt(mean((p-o)^2,na.rm=TRUE)); mo<-mean(o,na.rm=TRUE); if(is.finite(mo)&&abs(mo)>1e-9) 100*rmse/mo else NA_real_ }

## ===============================================================================================
## SCORECARD mode (SCORECARD=1): aggregate the per-source result CSVs this harness writes (BASE
## gate-off, v13.1 CANDIDATE, reused OSM) into the all-sites scorecard in the exact format of
## figures/_data/v1211_allsites_scorecard.csv. Runs without a model file (pure aggregation) and
## quits. This is the three-model, per region/source/grain table: total-volume level bias %, BA
## level bias %, total-volume %RMSE, for BASE (frozen v12.10.1), CANDIDATE v13.1, and OSM v2.26.1.
## The maturity gradient (Baxter held out) is carried here by the Baxter row's held-out label; the
## dedicated maturity matrix is emitted by v1211_maturity_scorecard.R after a cand-prefix edit.
## ===============================================================================================
if (identical(Sys.getenv("SCORECARD"), "1")) {
  CAND_PREFIX <- Sys.getenv("CAND_PREFIX", "v131")           # candidate result-file prefix
  CAND_LABEL  <- Sys.getenv("CAND_LABEL",  "CANDIDATE v13.1")# model factor label
  BASE_PREFIX <- Sys.getenv("BASE_PREFIX", "v131base")           # frozen v12.10.1 gate-off rows
  rd <- function(f) if(file.exists(f)) fread(f) else NULL
  summ_row <- function(region, source, grain, model, d, prov_filter=NULL){
    # RT10-M repair, 9 September 2026 (rb20260909). The null guard now precedes the province
    # filter. With the filter first, an absent per-source result file arrives as NULL from rd()
    # and d[PROV==prov_filter] raises "object PROV not found", which stopped the whole
    # aggregator rather than dropping one row. The move is inert whenever d is not NULL,
    # since the filter and the nrow test are unchanged and still run in the same order on
    # every non-NULL table, including a zero-row one. Same repair as the agg/ aggregators.
    if(is.null(d)) return(NULL)
    if(!is.null(prov_filter)) d <- d[PROV==prov_filter]
    if(nrow(d)==0) return(NULL)
    data.table(region=region, source=source, grain=grain, model=model, n=nrow(d),
      TOTVOL_bias_pct = round(bias_pct(d$TOTVOL_o, d$TOTVOL_p),2),
      BA_bias_pct     = round(bias_pct(d$BA_o, d$BA_p),2),
      TOTVOL_rmse_pct = round(rmse_pct(d$TOTVOL_o, d$TOTVOL_p),2))
  }
  rows <- list()
  # ---- ME sources (src token drives both base_<src> and <cand>_<src> file names) ----
  specs <- list(
    list(region="ME", source="Baxter (mature, held-out)",                 grain="stand",      src="baxter",     osm="osm_score_baxter_results.csv"),
    list(region="ME", source="SILC/Seven Islands (calibration, managed)",  grain="stand",      src="silc_l",     osm="osm_score_silc_l_results.csv"),
    list(region="ME", source="PEF (developing)",                           grain="stand",      src="pef",        osm="osm_score_pef_results.csv"),
    list(region="ME", source="CFRU CTRN (managed)",                        grain="stand",      src="ctrn",       osm="osm_score_ctrn_results.csv"),
    list(region="ME", source="Maine FIA (developing)",                     grain="whole-plot", src="mefia_l",    osm="osm_score_me_fia_l_results.csv"),
    list(region="ME", source="Maine FIA (developing)",                     grain="subplot",    src="mefia_subp", osm=NULL)
  )
  for(sp in specs){
    b <- rd(sprintf("%s_%s_results.csv", BASE_PREFIX, sp$src))
    c <- rd(sprintf("%s_%s_results.csv", CAND_PREFIX, sp$src))
    o <- if(!is.null(sp$osm)) rd(sp$osm) else NULL
    if(!is.null(b)) rows[[length(rows)+1]] <- summ_row(sp$region, sp$source, sp$grain, "BASE (frozen, no levers)", b)
    if(!is.null(c)) rows[[length(rows)+1]] <- summ_row(sp$region, sp$source, sp$grain, CAND_LABEL, c)
    if(!is.null(o)) rows[[length(rows)+1]] <- summ_row(sp$region, sp$source, sp$grain, "OSM-ACD v2.26.1", o)
  }
  # ---- NB and QC (magp_qcnb, one candidate/base file split by PROV) ----
  b_nb <- rd(sprintf("%s_nb_results.csv", BASE_PREFIX)); c_nb <- rd(sprintf("%s_nb_results.csv", CAND_PREFIX)); o_nb <- rd("g4_osm_score_nb_results.csv")
  rows[[length(rows)+1]] <- summ_row("NB", "NB MagPlot (managed)", "stand", "BASE (frozen, no levers)", b_nb, prov_filter="NB")
  rows[[length(rows)+1]] <- summ_row("NB", "NB MagPlot (managed)", "stand", CAND_LABEL, c_nb, prov_filter="NB")
  if(!is.null(o_nb)) rows[[length(rows)+1]] <- summ_row("NB", "NB MagPlot (managed)", "stand", "OSM-ACD v2.26.1", o_nb, prov_filter="NB")
  rows[[length(rows)+1]] <- summ_row("QC", "QC MagPlot (managed)", "stand", "BASE (frozen, no levers)", b_nb, prov_filter="QC")
  rows[[length(rows)+1]] <- summ_row("QC", "QC MagPlot (managed)", "stand", CAND_LABEL, c_nb, prov_filter="QC")
  # no OSM v2.26.1 run exists for QC MagPlot; row intentionally omitted, not fabricated
  # ---- NS remeasurement (NEW scored source): candidate split managed/unmanaged, base combined,
  #      OSM combined. NS is now IN the whole-plot mortality fit and ALSO scored here as a benchmark. ----
  ns_base <- rbindlist(list(rd(sprintf("%s_ns_managed_results.csv",Sys.getenv("BASE_PREFIX","v131base"))), rd(sprintf("%s_ns_unmanaged_results.csv",Sys.getenv("BASE_PREFIX","v131base")))), fill=TRUE)
  ns_cand <- rbindlist(list(rd(sprintf("%s_ns_managed_results.csv", CAND_PREFIX)),
                            rd(sprintf("%s_ns_unmanaged_results.csv", CAND_PREFIX))), fill=TRUE)
  if(is.null(ns_cand) || nrow(ns_cand)==0) ns_cand <- NULL
  ns_osm  <- rd("osm_score_ns_results.csv")
  if(!is.null(ns_base)) rows[[length(rows)+1]] <- summ_row("NS","NS remeasurement (managed+unmanaged)","stand","BASE (frozen, no levers)", ns_base)
  if(!is.null(ns_cand)) rows[[length(rows)+1]] <- summ_row("NS","NS remeasurement (managed+unmanaged)","stand", CAND_LABEL, ns_cand)
  if(!is.null(ns_osm))  rows[[length(rows)+1]] <- summ_row("NS","NS remeasurement (managed+unmanaged)","stand","OSM-ACD v2.26.1", ns_osm)
  # ---- NS long CFI (managed emphasis): base + candidate each split managed/unmanaged ----
  nsl_base <- rbindlist(list(rd(sprintf("%s_ns_long_managed_results.csv",Sys.getenv("BASE_PREFIX","v131base"))), rd(sprintf("%s_ns_long_unmanaged_results.csv",Sys.getenv("BASE_PREFIX","v131base")))), fill=TRUE); if(is.null(nsl_base)||nrow(nsl_base)==0) nsl_base<-NULL
  nsl_cand <- rbindlist(list(rd(sprintf("%s_ns_long_managed_results.csv", CAND_PREFIX)), rd(sprintf("%s_ns_long_unmanaged_results.csv", CAND_PREFIX))), fill=TRUE); if(is.null(nsl_cand)||nrow(nsl_cand)==0) nsl_cand<-NULL
  nsl_osm  <- rd("osm_score_ns_long_results.csv")
  if(!is.null(nsl_base)) rows[[length(rows)+1]] <- summ_row("NS","NS long CFI (managed emphasis)","stand","BASE (frozen, no levers)", nsl_base)
  if(!is.null(nsl_cand)) rows[[length(rows)+1]] <- summ_row("NS","NS long CFI (managed emphasis)","stand", CAND_LABEL, nsl_cand)
  if(!is.null(nsl_osm))  rows[[length(rows)+1]] <- summ_row("NS","NS long CFI (managed emphasis)","stand","OSM-ACD v2.26.1", nsl_osm)
  sc <- rbindlist(rows, fill=TRUE)
  sc[, region := factor(region, levels=c("ME","NB","QC","NS"))]
  sc[, model  := factor(model, levels=c("BASE (frozen, no levers)", CAND_LABEL, "OSM-ACD v2.26.1"))]
  setorder(sc, region, source, grain, model)
  OUT <- Sys.getenv("SCORECARD_OUT", "v131_allsites_scorecard.csv")
  fwrite(sc, OUT); cat("WROTE", OUT, "rows=", nrow(sc), "\n"); print(sc); cat("DONE_ALLSITES_SCORECARD\n")
  quit(save="no", status=0)
}

## ===============================================================================================
## GENERATOR mode (default): score one source under one config, write <TAG>_results.csv with the
## per-stand *_t1 / *_o / *_p columns the aggregators expect. Env-driven per source and per config,
## exactly as bench_parity_split_ms_v1211.R; driven by the v131 candidate array (one source/task).
## ===============================================================================================
source(Sys.getenv("MODEL_FILE","~/AcadianGY_13.1.r")); source("~/hw_sawfrac_smith.R"); source("~/hw_formrisk_split.R"); SPLIT<-as.logical(Sys.getenv("SPLIT","FALSE"))

## ---- PASS 21 addition: stack the pass-20 v13.2 site-fsm calc_ddbh patch ON TOP of whatever
## MODEL_FILE was just sourced above (ship18-comparable runs set MODEL_FILE to the p4e r2 ddbh
## refit). The pass-20 overlay script re-sources plain AcadianGY_13.1.r at its own top, which
## would silently undo the MODEL_FILE ddbh patch if left last, so MODEL_FILE is re-sourced AFTER
## the overlay to reapply it; calc_ddbh_v132 is a separate object that calls `ddbh` by name at
## run time, so it picks up the reapplied patch. Verified by 2026-08-19_v132_stack_verify_WIP.R
## (ddbh(test-input) patched -> wiped by overlay source -> reapplied -> activate_v132 confirmed
## identical(calc_ddbh, calc_ddbh_v132) and NOT identical to the shipped calc_ddbh). Gated on
## V132=1 so this file stays a superset of bench_p9.R (V132 unset reproduces bench_p9.R exactly).
if (identical(Sys.getenv("V132","1"), "1")) {
  source("~/magplot/verify/p20_v132/2026-08-19_v132_sitefsm_overlay_WIP.R")
  source(Sys.getenv("MODEL_FILE","~/AcadianGY_13.1.r"))
  activate_v132()
  cat("PASS21: v13.2 site-fsm overlay active on top of MODEL_FILE=", Sys.getenv("MODEL_FILE","~/AcadianGY_13.1.r"), "\n")
} else {
  cat("PASS21: V132=0, running plain MODEL_FILE with no v13.2 overlay (bench_p9.R-equivalent)\n")
}

## ---- 14.1 option 3 overlay --------------------------------------------------------------------
## The overlay captures `ddbh` and `calc_ddbh` at source time and rewraps `make_ops`, so it must
## be sourced AFTER the V132 block, which re-sources MODEL_FILE, and BEFORE the make_ops call
## below, so that ops carries the v141 fields. Gated on V141=1: with V141 unset this file
## reproduces its parent runner.
V141 <- identical(Sys.getenv("V141","0"), "1")
if (V141) {
  .v141_file <- path.expand(Sys.getenv("V141_FILE","~/v14_1_20260923/AcadianGY_14.1.r"))
  if (!file.exists(.v141_file)) stop("v141: V141=1 but the overlay file does not exist: ", .v141_file)
  source(.v141_file)
  cat(sprintf("v141: overlay %s md5 %s\n", .v141_file, as.character(tools::md5sum(.v141_file))))
  cat(sprintf("v141: LSDG_V141=%s THIN_V141=%s V141_COEF=%s V141_RELCAP=%s\n",
      Sys.getenv("LSDG_V141","0"), Sys.getenv("THIN_V141","0"),
      Sys.getenv("V141_COEF",""), Sys.getenv("V141_RELCAP","")))
} else {
  cat("v141: V141=0, no 14.1 overlay, this run is the unhooked reference\n")
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
 RO=833,RN=125,BC=762,PR=761,ST=315,HH=701,SB=372,RB=370,AS=541,SW=299,HW=998,OH=998,OS=299,PC=761)
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
himp<-function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes<-names(AGY2SPCD)
if (anyDuplicated(sp2g$SPCD)) stop(sprintf("p23: spcd_spgrpcd.csv carries %d duplicated SPCD keys (%s); setNames would resolve them silently by first row, refusing to guess", sum(duplicated(sp2g$SPCD)), paste(unique(sp2g$SPCD[duplicated(sp2g$SPCD)]), collapse=" ")))
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
metrics<-function(sp,dbh,ht,expf,form=NULL,risk=NULL,mindbh=4){
  live<-is.finite(dbh)&dbh>=mindbh&is.finite(expf)&expf>0
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
# The frozen August operational baseline (cb_v12101_results.csv) uses per-province
# dominant-height anchor factors NB_AFAC=0.579 QC_AFAC=0.111. A bare run leaves them at the
# inflating default of 1.0, which over-predicts dominant height and inflates NSVB volume for
# every model. The per-province AFAC assembly of the scored population is reused unchanged from
# v12.11; it is a scoring input, not a growth lever (red-team reframe 1). Reproduce the freeze
# with the frozen harness driver (see FROZEN_HARNESS_README.md); the default is left at 1.0.
if (isTRUE(NB_AFAC==1) && isTRUE(QC_AFAC==1)) {
  message("WARNING: NB_AFAC/QC_AFAC at 1.0 (default) does NOT reproduce the frozen cb_v12101; the freeze uses 0.579/0.111. Set them explicitly.")
}
# --------------------------------------------------------------------------------------------
if(Sys.getenv("INDOMAIN","1")=="1") prs <- prs[PROV=="NB" | esi_cov==TRUE]
if(nchar(Sys.getenv("NMAX"))>0) prs <- prs[seq_len(min(nrow(prs),as.integer(Sys.getenv("NMAX")))),]
## ==== GYDBREG 2026-09-16 PHASE B BLOCK (inserted by 2026-09-16_gydbreg_make_runners.py) ============
## (1) scoring threshold = the pair's SCORE_MINDBH_OBS (or SCORE_MINDBH_FIXED for the control), applied
##     by the same metrics() call to _t1, _o and _p; (2) OLD_STAND aliasing for the ecobucket and brms
##     SDImax lookups; (3) optional stand-keep file and row-range chunking of the admitted population;
## (4) a run-failure row (observed and initial computed, predicted NA) replaces the silent drop, with
##     RUN_OK/FAIL_REASON and the frame's carry columns (tag churn flags untouched) appended after ING_p.
if(!("SCORE_MINDBH_OBS" %in% names(prs))) stop("gydbreg: pairs frame carries no SCORE_MINDBH_OBS")
GYR_FIXED <- Sys.getenv("SCORE_MINDBH_FIXED","")
GYR_smd <- function(p){ v <- if(nzchar(GYR_FIXED)) as.numeric(GYR_FIXED) else as.numeric(p$SCORE_MINDBH_OBS); if(length(v)!=1L || !is.finite(v)) stop("gydbreg: no finite scoring threshold for ", p$STAND); v }
GYR_alias <- function(p,sid){ o <- if("OLD_STAND" %in% names(p)) as.character(p$OLD_STAND) else NA_character_; if(length(o)==1L && !is.na(o) && nzchar(o)) o else sid }
GYR_CARRY <- intersect(c("DATASET","SET","SITE","OLD_STAND","MANAGED","MANAGED_RULE","LINK_SRC","ESI_SRC","ESI_OLD","esi8","Y1","Y2","interval_years","INTERVAL_DEC","FRAME_MINDBH","SCORE_MINDBH","PLOT_OBS_MINDBH","SCORE_MINDBH_OBS","TAG_STABLE","N_NEWTAG","N_UNRELOC","CHURN_NEWTAG_BIG","CHURN_UNRELOC_SAMESP","CHURN_TF_NEWBIG","CHURN_FLAG","N_INGROWTH_MEMB","TRT_AT_Y1","DUPVIS_DISCORD","NSL_SINGLE_REGIME"), names(prs))
GYR_tail <- function(p, ok, why){ d <- data.frame(RUN_OK=as.integer(ok), FAIL_REASON=as.character(why), SCORE_MINDBH_USED=GYR_smd(p), stringsAsFactors=FALSE); for(cc in GYR_CARRY) d[[cc]] <- p[[cc]]; d }
GYR_lasterr <- ""
GYR_failrow <- function(p, sid, it, ot, why){
  SMD <- GYR_smd(p); iv <- max(1,round(p$interval_years))
  m1<-metrics(mapsp(it$SP),it$DBH,it$HT,it$EXPF,mindbh=SMD); m2o<-metrics(mapsp(ot$SP),ot$DBH,ot$HT,ot$EXPF,mindbh=SMD)
  m2p<-m1; m2p[]<-NA_real_
  data.frame(STAND=sid,PROV=p$PROV,esi_cov=p$esi_cov,iv=iv,
    t(setNames(m1,paste0(names(m1),"_t1"))),t(setNames(m2o,paste0(names(m2o),"_o"))),t(setNames(m2p,paste0(names(m2p),"_p"))),ING_p=NA_real_, GYR_tail(p,0L,why))
}
if(nzchar(Sys.getenv("STAND_KEEP_FILE"))){ .k <- fread(Sys.getenv("STAND_KEEP_FILE"))$STAND; prs <- prs[STAND %in% .k]; cat(sprintf("gydbreg STAND_KEEP_FILE: %d stands kept\n", nrow(prs))) }
GYR_N_INDOMAIN <- nrow(prs)
if(nzchar(Sys.getenv("CHUNK_FROM"))){ .a <- as.integer(Sys.getenv("CHUNK_FROM")); .b <- min(nrow(prs), as.integer(Sys.getenv("CHUNK_TO"))); if(!is.finite(.a) || .a<1L || .a>nrow(prs)) stop("gydbreg: chunk start outside the admitted population"); prs <- prs[.a:.b]; cat(sprintf("gydbreg chunk rows %d..%d of %d admitted stands, first %s last %s\n", .a, .b, GYR_N_INDOMAIN, prs$STAND[1], prs$STAND[nrow(prs)])) }
if("OLD_STAND" %in% names(prs)){ .o <- as.character(prs$OLD_STAND); .h <- !is.na(.o) & nzchar(.o) & (.o %in% names(BV)) & !(as.character(prs$STAND) %in% names(BV)); if(any(.h)) BV <- c(BV, setNames(unname(BV[.o[.h]]), as.character(prs$STAND[.h]))); cat(sprintf("gydbreg OLD_STAND alias: %d of %d stands aliased into the brms SDImax map; ecobucket keyed on OLD_STAND where present (%d hits)\n", sum(.h), nrow(prs), sum(!is.na(.o) & nzchar(.o) & .o %in% ecobucket_lookup$STAND))) }
cat(sprintf("gydbreg threshold: %s\n", if(nzchar(GYR_FIXED)) paste0("FIXED ", GYR_FIXED, " cm") else "per-pair SCORE_MINDBH_OBS"))
## ==== END GYDBREG BLOCK ==============================================================================
acadgy<-names(AGY2SPCD); mapsp<-function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
bf<-function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}
ops<<-make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE); ops$use.hw.mod <- as.logical(Sys.getenv("USE_MODS","FALSE"))
if(Sys.getenv("LINKED","0")!="1")ops$use.sdimort<-TRUE;  # p23: do NOT override the v14 lever gate (make_ops sets use.sdimort=FALSE when LINKED=1)
ops$sdimort.onset<-ONSET;ops$sdimort.break<-BREAK;ops$sdimort.beta.gentle<-BG;ops$sdimort.beta.steep<-BS;ops$sdimort.max<-SDMAX;ops$sdimax.site.term<-FALSE;ops$use.mortcal<-FALSE;ops$use.ingrowth.release<-TRUE;ops$ingrowth.rd.center<-IRC;ops$ingrowth.rd.k<-IRK;ops$ingrowth.mult<-IMULT
ops$use.esi.domht <- FALSE  # gated Chapman-Richards anchor path; off in all benchmark scoring
ops$use.brms.sdimax <- USE_BRMS; ops$brms.sdimax.map <- list(BV)
ops$use.esi.anchor.recal <- USE_ANCHOR
ops$esi.anchor.coef <- list(list(NB=c(0.885,0.01027), QC=c(0.441,0.03783)))
ops$sdimort.break.region <- list(c(NB=NB_BREAK, QC=QC_BREAK))
ops$ingrowth.mult.region <- list(c(NB=NB_IMULT, QC=QC_IMULT))
## ---- p6ing pathway switches (overlay copy of bench_v131_treetag.R; model of record untouched)
if(nzchar(Sys.getenv("NOCON",""))){ops$use.ddbh.standcon<-TRUE;ops$ddbh.standcon.hi<-5;ops$ddbh.standcon.lo<-5;ops$ddbh.standcon.qmin<-0;cat("P6: Ch10 BA CONSTRAINT DISABLED\n")}
if(nzchar(Sys.getenv("NOSDI",""))){ops$sdimort.onset<-9.99;ops$sdimort.break<-9.99;cat("P6: SDIMAX SELF-THINNING DISABLED (onset pushed out of reach)\n")}
## ---- p9lev3 overlay: LEVER 3b survivor-increment correction (Ch 10 stand constraint retune).
## Model of record AcadianGY_13.1.r is UNMODIFIED; 3b is an existing gated lever, this only sets ops$.
## Placed AFTER the NOCON block so an explicit LEV3 request always wins. Inert unless LEV3 is set,
## so with LEV3 unset this file is behaviourally identical to p6ing/bench_p6.R.
if(nzchar(Sys.getenv("LEV3",""))){
  ops$use.ddbh.standcon<-TRUE
  ops$ddbh.standcon.hi<-as.numeric(Sys.getenv("LEV3_HI","0.45"))
  ops$ddbh.standcon.lo<-as.numeric(Sys.getenv("LEV3_LO","0.35"))
  ops$ddbh.standcon.qmin<-as.numeric(Sys.getenv("LEV3_QMIN","22"))
  cat(sprintf("P9 LEVER 3b ON: hi=%.4f lo=%.4f qmin=%.4f\n", ops$ddbh.standcon.hi, ops$ddbh.standcon.lo, ops$ddbh.standcon.qmin))
} else { cat("P9 LEVER 3b OFF (gate-off path)\n") }
if(nzchar(Sys.getenv("REIN",""))){ stop("P9: lever 3a (ddbh.rein) is banned by standing warning; refusing to run") }
cat(sprintf("P6 config: IMULT=%.4f NOCON=%s NOSDI=%s\n", IMULT, Sys.getenv("NOCON",""), Sys.getenv("NOSDI","")))


## ===== v13.1 hierarchical posterior switches (replaces the v12.11 V1211_* hand-lever block) =====
## Gate-off (both FALSE, no v12.11 levers) reproduces frozen v12.10.1 byte-for-byte; the model file
## reads the posterior summary CSVs under ops$hier.postdir when a switch is TRUE. This harness only
## sets the switches; it never parses the posteriors (that is the v13.1 model file's job).
USE_HIER_ING  <- as.logical(Sys.getenv("USE_HIER_ING","FALSE"))   # fitted recruitment posterior
USE_HIER_MORT <- as.logical(Sys.getenv("USE_HIER_MORT","FALSE"))  # fitted hazard posterior
HIER_POSTDIR  <- Sys.getenv("HIER_POSTDIR","~/v13_kickoff")       # dir of v131r_*_fixef/_varcomp CSVs
ops$use.hier.ingrowth  <- USE_HIER_ING
ops$use.hier.mortality <- USE_HIER_MORT
ops$hier.postdir       <- HIER_POSTDIR
cat(sprintf("v13.1 posterior switches: use.hier.ingrowth=%s use.hier.mortality=%s hier.postdir=%s\n",
  USE_HIER_ING, USE_HIER_MORT, HIER_POSTDIR))

## ---- p23 fix, September 7 2026: stand.managed is set from data rather than left unset -------
## The v14 lever reads ops$stand.managed and falls back to 0 when it is absent, so every stand in
## the pass 23 arrays as first submitted was scored as unmanaged. The consequence is bounded and
## it is worth stating rather than assuming. In the shipped coefficient bundle the management
## term appears only in stage 3, at +0.4907 on the cloglog scale, while stage 1, the density
## stage and the floor carry no management term at all, so the flag cannot change how many stems
## leave a plot. It acts only on the within plot ranking, where it is a plot constant, and a
## common shift on the cloglog scale is order preserving, so the ranking does not change either.
## What does change is the proportional allocation weight, since 1 - exp(-exp(eta + c)) is not
## proportional in c. The residual is second order rather than zero, and setting the flag removes
## the need for the argument. Precedence is a per stand MANAGED column, then a per stand
## treatment file named in MGD_FILE, then the source level SRC_MANAGED. There is no silent
## default and an unset source stops the run.
.p23_mgd_note <- ""
if ("MANAGED" %in% names(prs)) {
  prs[, MGD_USE := as.integer(as.character(MANAGED) %in% c("1","TRUE","T","Y","YES","true","yes"))]
  .p23_mgd_note <- "per-stand MANAGED column"
} else if (nzchar(Sys.getenv("MGD_FILE",""))) {
  .mf <- fread(Sys.getenv("MGD_FILE")); .mc <- Sys.getenv("MGD_COL","")
  if (!nzchar(.mc) || !(.mc %in% names(.mf))) stop("p23: MGD_FILE is set but MGD_COL is missing or absent from that file")
  .unm <- strsplit(Sys.getenv("MGD_UNMANAGED",""), "\\|", fixed=FALSE)[[1]]
  if (!length(.unm)) stop("p23: MGD_FILE is set but MGD_UNMANAGED is empty, so nothing marks an unmanaged stand")
  .mf[, mgd_flag := as.integer(!(as.character(get(.mc)) %in% .unm))]
  prs[.mf, on = "STAND", MGD_USE := i.mgd_flag]
  if (anyNA(prs$MGD_USE)) stop(sprintf("p23: %d of %d stands have no row in MGD_FILE", sum(is.na(prs$MGD_USE)), nrow(prs)))
  .p23_mgd_note <- sprintf("per-stand %s from %s", .mc, basename(Sys.getenv("MGD_FILE")))
} else {
  .sm <- Sys.getenv("SRC_MANAGED","")
  if (!(.sm %in% c("0","1"))) stop("p23: this source carries no per-stand management information and SRC_MANAGED is not 0 or 1, refusing to guess the management state")
  prs[, MGD_USE := as.integer(.sm == "1")]
  .p23_mgd_note <- sprintf("source-level SRC_MANAGED=%s", .sm)
}
cat(sprintf("p23 stand.managed: %s, %d of %d stands managed\n", .p23_mgd_note, sum(prs$MGD_USE), nrow(prs)))

## ---- 14.1 option 3: stand.tst is set from data -------------------------------------------------
## The overlay contracts on ops$stand.tst, the years since the last thinning at the START of the
## current step, per stand, advanced by one each projection year, exactly as ops$stand.managed is
## set above. It applies the thinning release term T only where that value is finite and at or
## above zero, and is the identity everywhere else. It never guesses a thinning date, so this
## runner never supplies one.
##
## Precedence follows the p23 management block: a per stand TST column, then a per stand file
## named in TST_FILE keyed on STAND with the value column named in TST_COL, then the source level
## SRC_TST. Each accepts a non-negative number, the literal NEVER for a stand that was never
## thinned, or the literal UNKNOWN for a stand that carries no thinning record. There is no
## silent default: with THIN_V141=1 an unset source stops the run, for the same reason the p23
## fix stops on an unset SRC_MANAGED. A benchmark that silently scores every stand as unthinned
## is the defect that fix was written to remove.
##
## NEVER and UNKNOWN both reach the engine as NA and both leave T as the identity, since m_T
## tends to 1 as tst grows. They are counted apart because they are different facts. NEVER is a
## stand the term correctly does not act on. UNKNOWN is a stand the term could not be tested on,
## and a run whose T coverage is mostly UNKNOWN has not tested T.
.v141_parse_tst <- function(x) {
  ss <- toupper(trimws(as.character(x)))
  v <- suppressWarnings(as.numeric(ss))
  v[ss %in% c("NEVER","UNTHINNED","NONE")] <- Inf
  v[ss %in% c("UNKNOWN","NA","")]          <- NA_real_
  v
}
.v141_tst_note <- ""
if ("TST" %in% names(prs)) {
  prs[, TST_RAW := .v141_parse_tst(TST)]
  .v141_tst_note <- "per-stand TST column"
} else if (nzchar(Sys.getenv("TST_FILE",""))) {
  .tf <- fread(Sys.getenv("TST_FILE")); .tc <- Sys.getenv("TST_COL","")
  if (!nzchar(.tc) || !(.tc %in% names(.tf))) stop("v141: TST_FILE is set but TST_COL is missing or absent from that file")
  if (!("STAND" %in% names(.tf))) stop("v141: TST_FILE has no STAND column to key on")
  if (is.character(prs$STAND)) .tf[, STAND := as.character(STAND)]
  .tf[, tst_val := .v141_parse_tst(get(.tc))]
  prs[, TST_RAW := NA_real_]
  prs[.tf, on = "STAND", TST_RAW := i.tst_val]
  .v141_tst_note <- sprintf("per-stand %s from %s", .tc, basename(Sys.getenv("TST_FILE")))
} else {
  .st <- Sys.getenv("SRC_TST","")
  if (!nzchar(.st)) {
    if (identical(Sys.getenv("THIN_V141","0"), "1"))
      stop("v141: THIN_V141=1 but this source carries no per-stand years-since-thinning and SRC_TST is unset, refusing to guess a thinning date")
    prs[, TST_RAW := NA_real_]
    .v141_tst_note <- "unset, and THIN_V141 is off, so the thinning term is the identity"
  } else {
    .stv <- .v141_parse_tst(.st)
    if (length(.stv) != 1L || (is.finite(.stv) && .stv < 0))
      stop("v141: SRC_TST must be a non-negative number, NEVER or UNKNOWN, got: ", .st)
    prs[, TST_RAW := .stv]
    .v141_tst_note <- sprintf("source-level SRC_TST=%s", .st)
  }
}
if (any(is.finite(prs$TST_RAW) & prs$TST_RAW < 0)) stop("v141: negative years since thinning in the stand table")
prs[, TST_STATE := fifelse(is.na(TST_RAW), "unknown", fifelse(is.finite(TST_RAW), "known", "never"))]
cat(sprintf("v141 stand.tst: %s, %d known, %d never thinned, %d unknown, of %d stands\n",
  .v141_tst_note, sum(prs$TST_STATE == "known"), sum(prs$TST_STATE == "never"),
  sum(prs$TST_STATE == "unknown"), nrow(prs)))
if (identical(Sys.getenv("THIN_V141","0"), "1") && !any(prs$TST_STATE == "known"))
  cat("v141 WARNING: THIN_V141=1 and no stand has a known years since thinning, so T is the identity everywhere in this run and this run does not test T\n")
setkey(ti,STAND);setkey(t2,STAND);setDF(prs)
## PREREG11: NS size dependent height increment multiplier, identity unless HTFIX_B is set. dht.mult for NS stands is 1 in
## the frozen configuration, so m(D) replaces it; every other province is untouched.
HTFIX_B <- suppressWarnings(as.numeric(Sys.getenv("HTFIX_B", "")))
## PREREG45 (2026-10-05): per year relative height multiplier for QC, active only when QC_RH_A and QC_RH_B are set (with
## QC_RH_RFILL). With them unset htfx below is the original function (the NS HTFIX_B branch), byte for byte in its logic.
QC_RH_A <- suppressWarnings(as.numeric(Sys.getenv("QC_RH_A", ""))); QC_RH_B <- suppressWarnings(as.numeric(Sys.getenv("QC_RH_B", ""))); QC_RH_RFILL <- suppressWarnings(as.numeric(Sys.getenv("QC_RH_RFILL", "")))
if (xor(is.finite(QC_RH_A), is.finite(QC_RH_B)) || (is.finite(QC_RH_A) && !is.finite(QC_RH_RFILL))) stop("PREREG45: QC_RH_A, QC_RH_B and QC_RH_RFILL must be set together")
htfx_rh <- function(x, p) { cs <- if (is.finite(p$csi_site) && p$csi_site > 2) p$csi_site else CSI_DEFAULT; ok <- is.finite(x$ht) & x$ht > 0
  m <- exp(QC_RH_A + QC_RH_B * x$ht / cs); w <- x$expf; w[!is.finite(w)] <- 0; k <- ok & w > 0
  fill <- if (any(k)) sum(m[k] * w[k]) / sum(w[k]) else exp(QC_RH_A + QC_RH_B * QC_RH_RFILL)
  m[!ok] <- fill; x$dht.mult <- m; x }
htfx <- function(x, p) { if (is.finite(QC_RH_A) && p$PROV == "QC") return(htfx_rh(x, p)); if (!is.finite(HTFIX_B) || p$PROV != "NS") return(x); x$dht.mult <- exp(-HTFIX_B * pmax(0, x$dbh - 12.7)); x }
## PREREG45b (2026-10-05): the PREREG45 per year relative height multiplier for NB, active only when NB_RH_A and NB_RH_B are
## set (with NB_RH_RFILL). With them unset htfx is the PREREG45 function unchanged (htfx_p45 below).
NB_RH_A <- suppressWarnings(as.numeric(Sys.getenv("NB_RH_A", ""))); NB_RH_B <- suppressWarnings(as.numeric(Sys.getenv("NB_RH_B", ""))); NB_RH_RFILL <- suppressWarnings(as.numeric(Sys.getenv("NB_RH_RFILL", "")))
if (xor(is.finite(NB_RH_A), is.finite(NB_RH_B)) || (is.finite(NB_RH_A) && !is.finite(NB_RH_RFILL))) stop("PREREG45b: NB_RH_A, NB_RH_B and NB_RH_RFILL must be set together")
htfx_rh_nb <- function(x, p) { cs <- if (is.finite(p$csi_site) && p$csi_site > 2) p$csi_site else CSI_DEFAULT; ok <- is.finite(x$ht) & x$ht > 0
  m <- exp(NB_RH_A + NB_RH_B * x$ht / cs); w <- x$expf; w[!is.finite(w)] <- 0; k <- ok & w > 0
  fill <- if (any(k)) sum(m[k] * w[k]) / sum(w[k]) else exp(NB_RH_A + NB_RH_B * NB_RH_RFILL)
  m[!ok] <- fill; x$dht.mult <- m; x }
htfx_p45 <- htfx
htfx <- function(x, p) { if (is.finite(NB_RH_A) && p$PROV == "NB") return(htfx_rh_nb(x, p)); htfx_p45(x, p) }
cat(sprintf("PREREG11 HTFIX_B=%s\n", if (is.finite(HTFIX_B)) format(HTFIX_B) else "unset"))
source(path.expand("~/magplot/verify/gydbreg20260916/phaseD/scripts/2026-09-16_gydbreg-phaseD_trajhooks.R"))  # PHASE D hooks
MNAMES<-c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
out<-list();fail<-0
TREE_OUT<-Sys.getenv("TREE_OUT","")
tlp<-list(); tly1<-list(); tl0<-list(); y1cap<-NULL; t0cap<-NULL
## ==== PREREG31 BLOCK (replaces runner lines 420 to 486) ===========================================================
## Modes: P31_MODE=g0 projects named real QC stands (P31_G0_STANDS, comma separated) for their own interval and writes one
## result row per stand in the runner's column layout; P31_MODE=grid projects the synthetic cells listed in P31_CELLS
## (a CSV: cell,mix,esi,n0) for P31_NYR years and writes one summary row per cell per year. Same structure as PREREG26.
P31_MODE <- Sys.getenv("P31_MODE"); P31_OUT <- Sys.getenv("P31_OUT"); P31_ARM <- Sys.getenv("P31_ARM")
if (!(P31_MODE %in% c("g0","grid","slgrid")) || !nzchar(P31_OUT) || !nzchar(P31_ARM)) stop("p31: need P31_MODE g0|grid, P31_OUT, P31_ARM")
if (file.exists(P31_OUT)) stop("p31: REFUSE, output exists: ", P31_OUT)
cat(sprintf("p31: mode=%s arm=%s IMULT=%s QC_AFAC=%s QC_AFAC_SMALL=%s QC_AFAC_LARGE=%s QC_AFAC_KNOT=%s ING_MIN_FROM_SCORE=%s HTFIX_B=%s\n", P31_MODE, P31_ARM, format(IMULT),
  format(QC_AFAC), Sys.getenv("QC_AFAC_SMALL","unset"), Sys.getenv("QC_AFAC_LARGE","unset"), Sys.getenv("QC_AFAC_KNOT","unset"),
  Sys.getenv("ING_MIN_FROM_SCORE","unset"), Sys.getenv("HTFIX_B","unset")))
## the initial dht.mult, set once per tree from its initial DBH: runner line 425's expression, inserted verbatim by the build
p31_dht <- function(p, it) (if(p$PROV=="NB") NB_AFAC else if(p$PROV=="QC") (if(any(nzchar(Sys.getenv(c("QC_AFAC_SMALL","QC_AFAC_LARGE","QC_AFAC_KNOT"))))) { .qk<-as.numeric(Sys.getenv(c("QC_AFAC_SMALL","QC_AFAC_LARGE","QC_AFAC_KNOT"))); if(any(!is.finite(.qk))||any(!is.finite(it$DBH))) stop("PREREG28: QC_AFAC_SMALL, QC_AFAC_LARGE and QC_AFAC_KNOT must all be set, and DBH finite"); ifelse(it$DBH<.qk[3],.qk[1],.qk[2]) } else QC_AFAC) else 1)
## one stand, nyr annual steps; the per stand setup and the per year loop are runner lines 426 to 437 without PD_* hooks.
## rec(cur, yr) is called at yr = 0 (after htfx on the initial list) and after every step.
p31_project <- function(cur, p, nyr, rec = NULL, tlim = 60) {
  sid <- p$STAND; elev <- if (is.finite(p$ELEV) && p$ELEV > 0) p$ELEV else 200
  setTimeLimit(elapsed = tlim, transient = TRUE); on.exit(setTimeLimit(), add = TRUE)
  if (SPLIT) { cur <- split_formrisk(cur) }
  csi_use <- if (is.finite(p$csi_site) && p$csi_site > 2) p$csi_site else CSI_DEFAULT
  reg <- if (p$PROV == "NB") "NB" else if (p$PROV == "QC") "QC" else if (p$PROV == "NS") "NS" else "ME"
  stand <<- make_stand(stand.id = sid, csi = csi_use, elev = elev, region = reg)
  o <- ops
  o$stand.managed <- as.logical(p$MGD_USE)
  .tst0 <<- { v <- suppressWarnings(as.numeric(p$TST_RAW)); if (length(v) != 1L || !is.finite(v)) NA_real_ else v }
  o$stand.tst <- .tst0
  if (identical(Sys.getenv("ING_MIN_FROM_SCORE", "0"), "1")) o$ingrowth.min.dbh <- GYR_smd(p)   # PREREG9 threshold matching
  o$active_ecobucket <- ecobucket_lookup[STAND == GYR_alias(p, sid), gate3][1]
  ops <<- o
  n_init <- max(cur$tree)
  cur <- htfx(cur, p); if (!is.null(rec)) rec(cur, 0L, n_init)
  for (yr in seq_len(nyr)) {
    ops$stand.tst <<- if (is.na(.tst0)) NA_real_ else .tst0 + (yr - 1L)
    nx <- AcadianGYOneStand(tree = cur, stand = stand, ops = ops)
    if (is.null(nx) || nrow(nx) == 0) stop("empty")
    cur <- htfx(bf(nx), p); if (!is.null(rec)) rec(cur, yr, n_init)
  }
  attr(cur, "n_init") <- n_init; cur
}
if (P31_MODE == "slgrid") {
  ## PREREG44: measured qc_c t1 stand lists. P44_STANDS is a CSV (STAND, cell, esi_bin, sdi_bin); each stand starts from its
  ## own t1 tree list, built exactly as mode g0 builds it, and is projected P31_NYR annual steps with the mode grid recorder
  ## (same columns, plus STAND, esi_bin and sdi_bin; mix is OBS, esi is the stand's csi_site, n0 its t1 stems of all sizes).
  sl <- fread(Sys.getenv("P44_STANDS"), colClasses = list(character = "STAND")); NYR <- as.integer(Sys.getenv("P31_NYR", "100"))
  SMD <- as.numeric(Sys.getenv("P31_SMD")); if (!is.finite(SMD)) stop("p44 slgrid: P31_SMD (the scoring threshold for the _s metrics) must be set")
  setDT(prs); out <- list(); wm <- function(v, w) if (sum(w) > 0) sum(v*w)/sum(w) else NA_real_
  for (k in seq_len(nrow(sl))) { sid <- sl$STAND[k]; t0 <- Sys.time()
    p <- as.list(prs[STAND == sid]); if (length(p$STAND) != 1L) stop("p44 slgrid: stand not admitted once: ", sid)
    it <- ti[.(sid)]; if (nrow(it) < 1L) stop("p44 slgrid: no t1 trees for ", sid)
    cur <- data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=p31_dht(p, it),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    n0 <- sum(it$EXPF); acc <- list()
    rec <- function(x, yr, n_init) { lv <- is.finite(x$dbh) & is.finite(x$expf) & x$expf > 0; co <- lv & x$tree <= n_init; ig <- lv & x$tree > n_init
      m4 <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = 4); ms <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = SMD)
      acc[[length(acc) + 1L]] <<- data.table(arm = P31_ARM, cell = sl$cell[k], mix = "OBS", esi = p$csi_site, n0 = n0, age = yr,
        HT = m4[["TOPHT"]], TPH = sum(x$expf[lv & x$dbh >= 4]), BAPH = m4[["BA"]], QMD = m4[["QMD"]], SDI = m4[["SDI"]], VOL = m4[["TOTVOL"]],
        MERCHVOL = m4[["MERCHVOL"]], TPH_s = sum(x$expf[lv & x$dbh >= SMD]), BAPH_s = ms[["BA"]], VOL_s = ms[["TOTVOL"]],
        TPH_all = sum(x$expf[lv]), TPH_cohort = sum(x$expf[co]), TPH_ing = sum(x$expf[ig]),
        TPH_cohort_ge25 = sum(x$expf[co & x$dbh >= 25]), DHTM_cohort = wm(x$dht.mult[co], x$expf[co]),
        DHTM_cohort_ge25 = wm(x$dht.mult[co & x$dbh >= 25], x$expf[co & x$dbh >= 25]), DHTM_ing = wm(x$dht.mult[ig], x$expf[ig]),
        nrec = sum(lv), smd = SMD, STAND = sid, esi_bin = sl$esi_bin[k], sdi_bin = sl$sdi_bin[k]) }
    ok <- tryCatch({ p31_project(cur, p, NYR, rec, tlim = 5400); TRUE }, error = function(e) { cat("p44 FAIL stand", sl$cell[k], conditionMessage(e), "\n"); FALSE })
    d <- rbindlist(acc); d[, run_ok := as.integer(ok && nrow(d) == NYR + 1L)]; out[[k]] <- d
    cat(sprintf("p44 stand %s done ok=%s rows=%d secs=%.0f\n", sl$cell[k], ok, nrow(d), as.numeric(difftime(Sys.time(), t0, units = "secs")))) }
  fwrite(rbindlist(out), P31_OUT); cat("p44 slgrid WROTE", P31_OUT, "\n")
} else if (P31_MODE == "g0") {
  ids <- strsplit(Sys.getenv("P31_G0_STANDS"), ",")[[1]]; setDT(prs); rows <- list()
  for (sid in ids) { p <- as.list(prs[STAND == sid]); if (length(p$STAND) != 1L) stop("p31 g0: stand not admitted once: ", sid)
    it <- ti[.(sid)]; iv <- max(1, round(p$interval_years))
    cur <- data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=p31_dht(p, it),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    res <- p31_project(cur, p, iv)
    n_init <- attr(res, "n_init"); ing_rate <- sum(res$expf[res$tree > n_init & is.finite(res$dbh) & res$dbh >= 5], na.rm = TRUE) / iv
    m2p <- metrics(res$sp, res$dbh, res$ht, res$expf, res$form, res$risk, mindbh = GYR_smd(p))
    rows[[sid]] <- data.table(STAND = sid, iv = iv, t(setNames(m2p, paste0(names(m2p), "_p"))), ING_p = ing_rate) }
  fwrite(rbindlist(rows), P31_OUT); cat("p31 g0 WROTE", P31_OUT, "\n")
} else {
  cells <- fread(Sys.getenv("P31_CELLS")); NYR <- as.integer(Sys.getenv("P31_NYR", "100")); SMD <- as.numeric(Sys.getenv("P31_SMD"))
  if (!is.finite(SMD)) stop("p31 grid: P31_SMD (the synthetic stand's scoring threshold) must be set")
  ELEV31 <- as.numeric(Sys.getenv("P31_ELEV")); if (!is.finite(ELEV31)) stop("p31 grid: P31_ELEV must be set")
  MIX <- list(BF = c(BF = 40), SM = c(SM = 40), MX = c(BF = 15, SM = 5, PB = 4, WS = 3, RM = 3, QA = 3, BS = 3, YB = 2, WC = 2))
  set.seed(20260930); D0 <- runif(40, 2, 5)          # one draw, shared by every cell and arm (the PREREG26 draw)
  out <- list()
  for (k in seq_len(nrow(cells))) { cc <- cells[k]; t0 <- Sys.time()
    sp <- rep(names(MIX[[cc$mix]]), MIX[[cc$mix]]); if (length(sp) != 40L) stop("mix size")
    if (!all(mapsp(sp) == sp)) stop("p31 grid: a mix species is not an AcadianGY code: ", paste(unique(sp[mapsp(sp) != sp]), collapse = " "))
    p <- list(STAND = sprintf("P31_%s", cc$cell), PROV = "QC", ELEV = ELEV31, csi_site = cc$esi, MGD_USE = 1L, TST_RAW = NA_real_, SCORE_MINDBH_OBS = SMD)
    it0 <- data.frame(DBH = D0)
    cur <- data.frame(year=0,plot=1L,tree=1:40,sp=sp,dbh=D0,ht=NA_real_,hcb=NA,cr=NA,expf=rep(cc$n0/40,40),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=p31_dht(p, it0),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    acc <- list()
    wm <- function(v, w) if (sum(w) > 0) sum(v*w)/sum(w) else NA_real_
    rec <- function(x, yr, n_init) { lv <- is.finite(x$dbh) & is.finite(x$expf) & x$expf > 0; co <- lv & x$tree <= n_init; ig <- lv & x$tree > n_init
      m4 <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = 4); ms <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = SMD)
      acc[[length(acc) + 1L]] <<- data.table(arm = P31_ARM, cell = cc$cell, mix = cc$mix, esi = cc$esi, n0 = cc$n0, age = yr,
        HT = m4[["TOPHT"]], TPH = sum(x$expf[lv & x$dbh >= 4]), BAPH = m4[["BA"]], QMD = m4[["QMD"]], SDI = m4[["SDI"]], VOL = m4[["TOTVOL"]],
        MERCHVOL = m4[["MERCHVOL"]], TPH_s = sum(x$expf[lv & x$dbh >= SMD]), BAPH_s = ms[["BA"]], VOL_s = ms[["TOTVOL"]],
        TPH_all = sum(x$expf[lv]), TPH_cohort = sum(x$expf[co]), TPH_ing = sum(x$expf[ig]),
        TPH_cohort_ge25 = sum(x$expf[co & x$dbh >= 25]), DHTM_cohort = wm(x$dht.mult[co], x$expf[co]),
        DHTM_cohort_ge25 = wm(x$dht.mult[co & x$dbh >= 25], x$expf[co & x$dbh >= 25]), DHTM_ing = wm(x$dht.mult[ig], x$expf[ig]),
        nrec = sum(lv), smd = SMD) }
    ok <- tryCatch({ p31_project(cur, p, NYR, rec, tlim = 5400); TRUE }, error = function(e) { cat("p31 FAIL cell", cc$cell, conditionMessage(e), "\n"); FALSE })
    d <- rbindlist(acc); d[, run_ok := as.integer(ok && nrow(d) == NYR + 1L)]; out[[k]] <- d
    cat(sprintf("p31 cell %s done ok=%s rows=%d secs=%.0f\n", cc$cell, ok, nrow(d), as.numeric(difftime(Sys.time(), t0, units = "secs")))) }
  fwrite(rbindlist(out), P31_OUT); cat("p31 grid WROTE", P31_OUT, "\n")
}
if (V141 && exists(".acd_v141_report")) { .rep <- .acd_v141_report(); cat("v141 overlay counters:\n"); print(.rep) }
cat("DONE\n")

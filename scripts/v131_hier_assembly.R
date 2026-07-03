## FVS-ACD v13.1 : hierarchical mortality + pooled management effect (fast glmer go/no-go)
## Deliverable 1: managed/unmanaged design matrix with region/ecoregion/fortype/mgmt grouping (+counts).
## Deliverable 2: hierarchical cloglog mortality fit; test (a) management partial-pooling transfer under
##   leave-one-region-out vs a capped constant, (b) region/composition RE separation of mortality tails.
## MagPlot + recent-FIA held out of fitting. Aggregates only; no coordinates in any output.
suppressPackageStartupMessages({library(data.table)})
set.seed(20260703); OUT<-"~/v13_kickoff"; dir.create(OUT,showWarnings=FALSE)
PAIRS<-"/users/PUOM0008/crsfaaron/fvs-conus/calibration/data/conus_remeasurement_pairs_metric_cond_v2.rds"
TAU_M<-10
cat("== v13.1 assembly ==\n"); d<-as.data.table(readRDS(PAIRS)); cat("rows:",nrow(d),"\n")
nm<-names(d)
pick<-function(cands) { h<-cands[cands %in% nm]; if(length(h)) h[1] else NA }
cSTAT<-pick(c("STATECD","STATECD_cond1","STATECD1")); cORG<-pick(c("STDORGCD","STDORGCD_cond1","STDORGCD1"))
cTRT<-pick(c("TRTCD1","TRTCD1_cond1","TRTCD_cond1","TRTCD")); cFOR<-pick(c("FORTYPCD","FORTYPCD_cond1","FLDTYPCD1","FORTYPCD1"))
cL2<-pick(c("EPA_L2_CODE","EPA_L2","US_L2CODE")); cL3<-pick(c("EPA_L3_CODE","EPA_L3","US_L3CODE")); cL1<-pick(c("EPA_L1_CODE","EPA_L1"))
cat("mapped cols: state=",cSTAT," org=",cORG," trt=",cTRT," fortyp=",cFOR," L1=",cL1," L2=",cL2," L3=",cL3,"\n")
d<-d[TREESTATUS1==1 & !is.na(TREESTATUS2) & TREESTATUS2 %in% c(1,2) & is.finite(TPA1)&TPA1>0 &
     is.finite(YEARS)&YEARS>=1&YEARS<=20 & is.finite(DBH1)&DBH1>=2.54]
d[, stand_key:=paste(PLT_CN_cond1,CONDID_cond1,INVYR1,INVYR2,sep="_")]
d[, died:=as.numeric(TREESTATUS2==2)]
g<-d[, .(YEARS=YEARS[1], trials=sum(TPA1), deaths=sum(TPA1*died),
   ba=weighted.mean(BA1,TPA1,na.rm=T), qmd=weighted.mean(QMD1,TPA1,na.rm=T),
   sdi_add=weighted.mean(sdi_additive1,TPA1,na.rm=T), sdimax=weighted.mean(SDImax_brms,TPA1,na.rm=T),
   rd_row=weighted.mean(rd_add,TPA1,na.rm=T), yst=suppressWarnings(min(years_since_trt,na.rm=T)),
   STATE=if(!is.na(cSTAT)) get(cSTAT)[1] else NA, ORG=if(!is.na(cORG)) get(cORG)[1] else NA_integer_,
   TRT=if(!is.na(cTRT)) get(cTRT)[1] else NA_integer_, FOR=if(!is.na(cFOR)) get(cFOR)[1] else NA_integer_,
   L1=if(!is.na(cL1)) as.character(get(cL1)[1]) else NA, L2=if(!is.na(cL2)) as.character(get(cL2)[1]) else NA,
   L3=if(!is.na(cL3)) as.character(get(cL3)[1]) else NA, INVYR2=INVYR2[1]), by=stand_key]
rm(d);gc()
g[, rd:=ifelse(is.finite(sdi_add)&is.finite(sdimax)&sdimax>0, sdi_add/sdimax, rd_row)]
g<-g[is.finite(trials)&trials>0&is.finite(deaths)&deaths>=0&deaths<=trials&is.finite(rd)&rd>0&rd<2&is.finite(qmd)&qmd>0&is.finite(ba)]
g[, ln_qmd:=log(qmd)][, log_years:=log(YEARS)]
## management class: planted (STDORGCD==1); treated (any TRTCD cutting/silv & not planted); none else
g[, planted:=as.integer(is.finite(ORG)&ORG==1)]
g[, treated:=as.integer((is.finite(TRT)&TRT>0) | (is.finite(yst)&yst>=0&yst<40))]
g[, mgmt:=ifelse(planted==1,"planted", ifelse(treated==1,"treated","none"))]
g[, region:=as.character(STATE)][is.na(region)|region=="NA", region:=L1]
g[, eco:=fifelse(!is.na(L3)&L3!="NA",L3, fifelse(!is.na(L2)&L2!="NA",L2,L1))]
g[, fortype:=as.character(FOR)][is.na(fortype), fortype:="unk"]
g<-g[!is.na(region)&region!="NA"&!is.na(eco)&eco!="NA"]
## recent-FIA holdout proxy: hold out the most recent inventory cycle per state (test), fit on the rest
g[, recent:=as.integer(INVYR2>=quantile(INVYR2,0.9,na.rm=T)), by=region]
gf<-g[recent==0]  # fit set (recent-FIA proxy held out)
## ---- DELIVERABLE 1: design matrix counts (write EARLY) ----
dm<-g[, .(n_stands=.N, mort=round(mean(deaths/trials),4)), by=.(mgmt)][order(mgmt)]
fwrite(dm, file.path(OUT,"v131_designmatrix_bymgmt.csv"))
dmr<-g[, .(n=.N), by=.(region,mgmt)][order(region,mgmt)]; fwrite(dmr, file.path(OUT,"v131_designmatrix_region_mgmt.csv"))
fwrite(g[, .(n=.N,mort=round(mean(deaths/trials),4)), by=.(eco)][order(-n)][1:40], file.path(OUT,"v131_designmatrix_eco.csv"))
cat("=== DESIGN MATRIX by mgmt ===\n"); print(dm)
cat("regions:",uniqueN(g$region)," ecoregions:",uniqueN(g$eco)," fortypes:",uniqueN(g$fortype),"\n")
cat("fit stands:",nrow(gf)," held-out(recent proxy):",nrow(g)-nrow(gf),"\n")
fwrite(data.table(metric=c("n_all","n_fit","n_heldout","n_region","n_eco","n_fortype",
   "n_planted","n_treated","n_none"),
   value=c(nrow(g),nrow(gf),nrow(g)-nrow(gf),uniqueN(g$region),uniqueN(g$eco),uniqueN(g$fortype),
   sum(g$mgmt=="planted"),sum(g$mgmt=="treated"),sum(g$mgmt=="none"))), file.path(OUT,"v131_designmatrix_summary.csv"))
saveRDS(gf, file.path(OUT,"v131_fitset.rds"))
cat("DESIGN_MATRIX_WRITTEN\n"); flush.console()
## subsample for speed (oversample managed)
ev<-gf[mgmt!="none"]; bg<-gf[mgmt=="none"]; ne<-min(nrow(ev),60000); nb<-min(nrow(bg),90000)
ds<-rbind(ev[sample(.N,ne)], bg[sample(.N,nb)]); ds[, resp:=cbind(deaths_i<-as.integer(round(deaths)), trials_i<-as.integer(round(trials)))]
ds[, deaths_i:=as.integer(round(deaths))][, trials_i:=as.integer(pmax(round(trials),deaths_i))]
ds[, mgmt:=factor(mgmt,levels=c("none","treated","planted"))]
ds[, region:=factor(region)][, eco:=factor(eco)][, fortype:=factor(fortype)]
cat("fit sample:",nrow(ds)," managed:",ne,"\n")
## ---- DELIVERABLE 2: hierarchical fit ----
suppressPackageStartupMessages({okL<-requireNamespace("lme4",quietly=TRUE)})
if(!okL){cat("NO lme4\n"); quit(status=0)}; library(lme4)
ctrl<-glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5))
t0<-Sys.time()
## Model C: capped-constant analog (management as single global fixed effect, minimal RE)
mC<-tryCatch(glmer(cbind(deaths_i,trials_i-deaths_i) ~ rd+ln_qmd+ba+mgmt+(1|eco)+offset(log_years),
   data=ds, family=binomial("cloglog"), control=ctrl, nAGQ=0), error=function(e){cat("mC err:",conditionMessage(e),"\n");NULL})
## Model H: hierarchical, management partially pooled across regions + crossed RE
mH<-tryCatch(glmer(cbind(deaths_i,trials_i-deaths_i) ~ rd+ln_qmd+ba+mgmt+(1|region)+(1|eco)+(1|fortype)+(0+I(mgmt!="none")|region)+offset(log_years),
   data=ds, family=binomial("cloglog"), control=ctrl, nAGQ=0), error=function(e){cat("mH err:",conditionMessage(e),"\n");NULL})
cat("fit time:",round(difftime(Sys.time(),t0,units="mins"),1),"min\n")
if(!is.null(mH)){
  cat("\n=== Model H fixed effects (log-hazard scale) ===\n"); print(round(summary(mH)$coefficients,4))
  vc<-as.data.table(VarCorr(mH)); cat("\n=== variance components (RE sd) -> tail separation ===\n"); print(vc[,.(grp,var1,sdcor=round(sdcor,4))])
  fwrite(vc[,.(grp,var1,sdcor)], file.path(OUT,"v131_varcomp.csv"))
  fe<-as.data.table(summary(mH)$coefficients,keep.rownames="term"); fwrite(fe, file.path(OUT,"v131_fixef_H.csv"))
}
if(!is.null(mC)&!is.null(mH)){ cat("\nAIC  C(capped):",round(AIC(mC),0)," H(hier):",round(AIC(mH),0)," dAIC:",round(AIC(mC)-AIC(mH),0),"\n") }
## ---- leave-one-region-out transfer: pooled vs capped ----
regs<-ds[, .N, by=region][N>1500][order(-N)]$region; regs<-head(as.character(regs),6)
loro<-list()
for(rg in regs){ tr<-ds[region!=rg]; te<-ds[region==rg]
  ## capped: single global mgmt effect
  fc<-tryCatch(glmer(cbind(deaths_i,trials_i-deaths_i)~rd+ln_qmd+ba+mgmt+(1|eco)+offset(log_years),data=tr,family=binomial("cloglog"),control=ctrl,nAGQ=0),error=function(e)NULL)
  ## pooled/hier: mgmt fixed + region RE (held-out region uses shrinkage target = global)
  fh<-tryCatch(glmer(cbind(deaths_i,trials_i-deaths_i)~rd+ln_qmd+ba+mgmt+(1|region)+(1|eco)+(0+I(mgmt!="none")|region)+offset(log_years),data=tr,family=binomial("cloglog"),control=ctrl,nAGQ=0),error=function(e)NULL)
  if(is.null(fc)|is.null(fh)) next
  pc<-predict(fc,te,type="response",re.form=~(1|eco),allow.new.levels=TRUE)
  ph<-predict(fh,te,type="response",re.form=~(1|eco),allow.new.levels=TRUE)
  om<-te$deaths_i/te$trials_i
  ## focus on managed stands in the held-out region
  mi<-te$mgmt!="none"
  loro[[rg]]<-data.table(region=rg, n_mgd=sum(mi),
     capped_MAE=round(mean(abs(pc[mi]-om[mi])),4), hier_MAE=round(mean(abs(ph[mi]-om[mi])),4))
}
LO<-rbindlist(loro); cat("\n=== LEAVE-ONE-REGION-OUT managed-mortality transfer (MAE, lower=better) ===\n"); print(LO)
if(nrow(LO)) fwrite(LO, file.path(OUT,"v131_loro_transfer.csv"))
cat("V131_DONE\n")

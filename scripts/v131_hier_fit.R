suppressPackageStartupMessages({library(data.table); library(lme4)})
set.seed(20260703); OUT<-"~/v13_kickoff"
gf<-readRDS(file.path(OUT,"v131_fitset.rds")); setDT(gf)
gf[, deaths_i:=as.integer(round(deaths))][, trials_i:=as.integer(pmax(round(trials),deaths_i))]
ev<-gf[mgmt!="none"]; bg<-gf[mgmt=="none"]; ne<-min(nrow(ev),40000); nb<-min(nrow(bg),80000)
ds<-rbind(ev[sample(.N,ne)], bg[sample(.N,nb)])
ds[, mgmt:=factor(mgmt,levels=c("none","treated","planted"))]
ds[, region:=factor(region)][, eco:=factor(eco)][, fortype:=factor(fortype)][, mgd:=as.integer(mgmt!="none")]
cat("fit sample:",nrow(ds)," managed:",ne,"\n")
ctrl<-glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5))
t0<-Sys.time()
mC<-tryCatch(glmer(cbind(deaths_i,trials_i-deaths_i)~rd+ln_qmd+ba+mgmt+(1|eco)+offset(log_years),
   data=ds,family=binomial("cloglog"),control=ctrl,nAGQ=0),error=function(e){cat("mC:",conditionMessage(e),"\n");NULL})
mH<-tryCatch(glmer(cbind(deaths_i,trials_i-deaths_i)~rd+ln_qmd+ba+mgmt+(1|region)+(1|eco)+(1|fortype)+(0+mgd|region)+offset(log_years),
   data=ds,family=binomial("cloglog"),control=ctrl,nAGQ=0),error=function(e){cat("mH:",conditionMessage(e),"\n");NULL})
cat("fit time:",round(difftime(Sys.time(),t0,units="mins"),1),"min\n")
if(!is.null(mH)){cat("\n=== Model H fixed effects (log-hazard) ===\n"); print(round(summary(mH)$coefficients,4))
  vc<-as.data.table(VarCorr(mH)); cat("\n=== variance components (RE sd) ===\n"); print(vc[,.(grp,var1,sdcor=round(sdcor,4))])
  fwrite(vc[,.(grp,var1,sdcor)],file.path(OUT,"v131_varcomp.csv"))
  fwrite(as.data.table(summary(mH)$coefficients,keep.rownames="term"),file.path(OUT,"v131_fixef_H.csv"))}
if(!is.null(mC)&!is.null(mH)) cat("\nAIC C(capped):",round(AIC(mC),0)," H(hier):",round(AIC(mH),0)," dAIC:",round(AIC(mC)-AIC(mH),0),"\n")
## leave-one-region-out transfer of the managed effect
regs<-head(as.character(ds[mgd==1,.N,by=region][N>800][order(-N)]$region),5)
lo<-list()
for(rg in regs){tr<-ds[region!=rg]; te<-ds[region==rg&mgd==1]; if(nrow(te)<30) next
  fc<-tryCatch(glmer(cbind(deaths_i,trials_i-deaths_i)~rd+ln_qmd+ba+mgmt+(1|eco)+offset(log_years),tr,family=binomial("cloglog"),control=ctrl,nAGQ=0),error=function(e)NULL)
  fh<-tryCatch(glmer(cbind(deaths_i,trials_i-deaths_i)~rd+ln_qmd+ba+mgmt+(1|region)+(1|eco)+(0+mgd|region)+offset(log_years),tr,family=binomial("cloglog"),control=ctrl,nAGQ=0),error=function(e)NULL)
  if(is.null(fc)|is.null(fh)) next
  om<-te$deaths_i/te$trials_i
  pc<-predict(fc,te,type="response",re.form=~(1|eco),allow.new.levels=TRUE)
  ph<-predict(fh,te,type="response",re.form=~(1|eco),allow.new.levels=TRUE)
  lo[[rg]]<-data.table(region=rg,n_mgd=nrow(te),capped_MAE=round(mean(abs(pc-om)),4),hier_MAE=round(mean(abs(ph-om)),4))}
LO<-rbindlist(lo); cat("\n=== LEAVE-ONE-REGION-OUT managed mortality transfer (MAE) ===\n"); print(LO)
if(length(lo)) fwrite(LO,file.path(OUT,"v131_loro_transfer.csv"))
cat("V131FIT_DONE\n")

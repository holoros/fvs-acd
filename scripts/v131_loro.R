suppressPackageStartupMessages({library(data.table); library(lme4)})
set.seed(20260703); OUT<-path.expand("~/v13_kickoff")
gf<-readRDS(file.path(OUT,"v131_fitset.rds")); setDT(gf)
gf[, deaths_i:=as.integer(round(deaths))][, trials_i:=as.integer(pmax(round(trials),deaths_i))]
gf[, mgmt:=factor(mgmt,levels=c("none","treated","planted"))]
gf[, region:=factor(region)][, eco:=factor(eco)][, fortype:=factor(fortype)][, mgd:=as.integer(mgmt!="none")]
ds<-gf[recent==0]
ctrl<-glmerControl(optimizer="bobyqa", optCtrl=list(maxfun=2e5))
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
LO<-rbindlist(lo); print(LO); fwrite(LO,file.path(OUT,"v131_loro_transfer_full.csv"))
cat("wins_hier:", sum(LO$hier_MAE<LO$capped_MAE), "of", nrow(LO), "\n")
cat("LORO_DONE\n")

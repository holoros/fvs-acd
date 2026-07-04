## v13.1 mortality brms REPAIR v2: faster sampler settings to land a converged posterior this run.
## Same balanced subsample + tight mgd-slope-SD prior; adapt_delta 0.9, treedepth 10, lighter iter,
## managed capped at 25k to reduce the stiff-geometry cost. Confirms whether ANY mgmt hazard effect survives.
suppressPackageStartupMessages({library(data.table); library(brms)})
set.seed(20260704); OUT<-path.expand("~/v13_kickoff"); setwd(OUT); t0<-Sys.time()
gf<-readRDS(file.path(OUT,"v131_fitset.rds")); setDT(gf)
gf[, deaths_i:=as.integer(round(deaths))][, trials_i:=as.integer(pmax(round(trials),deaths_i))]
gf[, mgmt:=factor(mgmt,levels=c("none","treated","planted"))][, mgd:=as.integer(mgmt!="none")]
sc<-function(x) as.numeric(scale(x))
gf[, rd_z:=sc(rd)][, lnqmd_z:=sc(ln_qmd)][, ba_z:=sc(ba)]
fitall<-gf[recent==0]
ev<-fitall[mgd==1]; if(nrow(ev)>25000) ev<-ev[sample(.N,25000)]
bg<-fitall[mgd==0][sample(.N, nrow(ev))]
ds<-rbind(ev,bg)
ds[, region:=factor(region)][, eco:=factor(eco)][, fortype:=factor(fortype)]
cat("v2 balanced rows:",nrow(ds)," managed:",nrow(ev),"\n")
form<-bf(deaths_i | trials(trials_i) ~ rd_z+lnqmd_z+ba_z+mgmt+offset(log_years)+
          (1|region)+(1|eco)+(1|fortype)+(0+mgd|region))
pr<-c(set_prior("normal(-2,1)",class="Intercept"), set_prior("normal(0,1)",class="b"),
      set_prior("student_t(3,0,0.5)",class="sd"),
      set_prior("student_t(3,0,0.3)",class="sd",group="region",coef="mgd"))
init_fun<-function() list(Intercept=-2, b=as.array(rnorm(5,0,0.05)),
  sd_1=as.array(0.3),sd_2=as.array(0.3),sd_3=as.array(0.3),sd_4=as.array(0.2))
fit<-brm(form,data=ds,family=binomial("cloglog"),prior=pr,chains=4,iter=1200,warmup=600,
  seed=20260704,backend="cmdstanr",threads=threading(8),cores=4,init=init_fun,
  control=list(adapt_delta=0.9,max_treedepth=10),refresh=200,output_dir=OUT,silent=0)
saveRDS(fit,file.path(OUT,"v131_mort_repair_v2_fit.rds"))
cat("v2 fit time:",round(difftime(Sys.time(),t0,units="mins"),1),"min\n")
sm<-summary(fit)
conv<-data.table(max_Rhat=max(rhat(fit),na.rm=TRUE),min_bulk_ESS=min(sm$fixed[,"Bulk_ESS"],na.rm=TRUE),
  min_tail_ESS=min(sm$fixed[,"Tail_ESS"],na.rm=TRUE),
  n_divergent=sum(subset(nuts_params(fit),Parameter=="divergent__")$Value))
fwrite(conv,file.path(OUT,"v131_mort_repair_v2_convergence.csv")); print(conv)
post<-as_draws_df(fit); bt<-post[["b_mgmttreated"]]; bp<-post[["b_mgmtplanted"]]
me<-data.table(class=c("treated","planted"),loghaz_mean=c(mean(bt),mean(bp)),
  l95=c(quantile(bt,.025),quantile(bp,.025)),u95=c(quantile(bt,.975),quantile(bp,.975)),
  HR=c(mean(exp(bt)),mean(exp(bp))),p_neg=c(mean(bt<0),mean(bp<0)))
fwrite(me,file.path(OUT,"v131_mort_repair_v2_mgmt_effect.csv")); print(me)
vc<-VarCorr(fit); sdr<-rbindlist(lapply(names(vc),function(g){s<-vc[[g]]$sd
  data.table(grouping=g,term=rownames(s),sd_est=s[,"Estimate"],l95=s[,"Q2.5"],u95=s[,"Q97.5"])}),fill=TRUE)
fwrite(sdr,file.path(OUT,"v131_mort_repair_v2_varcomp.csv")); print(sdr)
cat("MORT_REPAIR_V2_DONE at",format(Sys.time()),"\n")

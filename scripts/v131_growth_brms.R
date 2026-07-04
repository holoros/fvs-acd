## v13.1 GROWTH-scale full Bayesian hierarchical fit (brms, Gaussian) on gross survivor BA increment.
## Provides posterior management release by class + region-slope heterogeneity + prediction intervals + convergence.
suppressPackageStartupMessages({library(data.table); library(brms)})
set.seed(20260704); OUT <- path.expand("~/v13_kickoff"); setwd(OUT); t0 <- Sys.time()
gf <- readRDS(file.path(OUT, "v131g_fitset.rds")); setDT(gf)
gf[, mgmt := factor(mgmt, levels=c("none","treated","planted"))]
gf[, mgd := as.integer(mgmt!="none")]
sc <- function(x) as.numeric(scale(x))
gf[, rd_z := sc(rd)][, lnqmd_z := sc(ln_qmd)][, ba_z := sc(ba)]
fwrite(data.table(var=c("rd","ln_qmd","ba"), mean=c(mean(gf$rd),mean(gf$ln_qmd),mean(gf$ba)),
  sd=c(sd(gf$rd),sd(gf$ln_qmd),sd(gf$ba))), file.path(OUT,"v131g_brms_scaling.csv"))
## keep all managed + 90k background so posterior is tractable and matches the go/no-go sample basis
ev <- gf[mgd==1]; bg <- gf[mgd==0]; nb <- min(nrow(bg), 90000)
ds <- rbind(ev, bg[sample(.N, nb)])
ds[, region := factor(region)][, eco := factor(eco)][, fortype := factor(fortype)]
cat("brms growth rows:", nrow(ds), " managed:", nrow(ev), "\n")
form <- bf(gross_ba_ann ~ rd_z + lnqmd_z + ba_z + mgmt +
             (1|region) + (1|eco) + (1|fortype) + (0 + mgd | region))
pr <- c(set_prior("normal(0,1)", class="b"),
        set_prior("student_t(3,0,1)", class="sd"),
        set_prior("student_t(3,0,1)", class="sigma"))
fit <- brm(form, data=ds, family=gaussian(), prior=pr, chains=4, iter=2000, warmup=1000,
  seed=20260704, backend="cmdstanr", threads=threading(8), cores=4,
  control=list(adapt_delta=0.95, max_treedepth=12), refresh=200, output_dir=OUT, silent=0)
saveRDS(fit, file.path(OUT, "v131g_brms_fit.rds"))
cat("brms growth fit time:", round(difftime(Sys.time(),t0,units="mins"),1), "min\n")
fx <- as.data.frame(fixef(fit)); fx <- data.table(term=rownames(fx), fx)
fwrite(fx, file.path(OUT,"v131g_brms_fixef.csv")); print(fx)
vc <- VarCorr(fit); sdr <- rbindlist(lapply(names(vc), function(g){s <- vc[[g]]$sd
  data.table(grouping=g, term=rownames(s), sd_est=s[,"Estimate"], l95=s[,"Q2.5"], u95=s[,"Q97.5"])}), fill=TRUE)
fwrite(sdr, file.path(OUT,"v131g_brms_varcomp.csv")); print(sdr)
sm <- summary(fit)
conv <- data.table(max_Rhat=max(rhat(fit),na.rm=TRUE), min_bulk_ESS=min(sm$fixed[,"Bulk_ESS"],na.rm=TRUE),
  min_tail_ESS=min(sm$fixed[,"Tail_ESS"],na.rm=TRUE),
  n_divergent=sum(subset(nuts_params(fit),Parameter=="divergent__")$Value))
fwrite(conv, file.path(OUT,"v131g_brms_convergence.csv")); print(conv)
post <- as_draws_df(fit); bt <- post[["b_mgmttreated"]]; bp <- post[["b_mgmtplanted"]]
me <- data.table(class=c("treated","planted"), release_mean=c(mean(bt),mean(bp)),
  l95=c(quantile(bt,.025),quantile(bp,.025)), u95=c(quantile(bt,.975),quantile(bp,.975)),
  p_positive=c(mean(bt>0),mean(bp>0)))
fwrite(me, file.path(OUT,"v131g_brms_mgmt_effect.csv")); print(me)
rs <- ranef(fit)$region
if("mgd" %in% dimnames(rs)[[3]]){
  rsl <- data.table(region=dimnames(rs)[[1]], mgd_slope=rs[,"Estimate","mgd"], l95=rs[,"Q2.5","mgd"], u95=rs[,"Q97.5","mgd"])
  fwrite(rsl, file.path(OUT,"v131g_brms_region_mgmt_slopes.csv")); cat("region slope range:\n"); print(range(rsl$mgd_slope))}
cat("V131G_BRMS_DONE at", format(Sys.time()), "\n")

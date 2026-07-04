# v13.1 full Bayesian hierarchical mortality + management fit (brms/cmdstanr)
# Robust: scaled predictors + informative inits OFF the cloglog exposure boundary (Intercept ~ -4.5, slopes 0).
suppressPackageStartupMessages({library(data.table); library(brms)})
set.seed(20260703)
OUT <- path.expand("~/v13_kickoff"); setwd(OUT)
t0 <- Sys.time()
gf <- readRDS(file.path(OUT, "v131_fitset.rds")); setDT(gf)
gf[, deaths_i := as.integer(round(deaths))]
gf[, trials_i := as.integer(pmax(round(trials), deaths_i))]
gf[, mgmt := factor(mgmt, levels=c("none","treated","planted"))]
gf[, region := factor(region)][, eco := factor(eco)][, fortype := factor(fortype)]
gf[, mgd := as.integer(mgmt != "none")]
sc <- function(x) as.numeric(scale(x))
gf[, rd_z := sc(rd)][, lnqmd_z := sc(ln_qmd)][, ba_z := sc(ba)]
fwrite(data.table(var=c("rd","ln_qmd","ba"), mean=c(mean(gf$rd),mean(gf$ln_qmd),mean(gf$ba)),
  sd=c(sd(gf$rd),sd(gf$ln_qmd),sd(gf$ba))), file.path(OUT,"v131_brms_scaling.csv"))
fitdt <- gf[recent == 0]
cat("fit rows:", nrow(fitdt), " managed:", fitdt[mgd==1,.N], "\n")
form <- bf(deaths_i | trials(trials_i) ~ rd_z + lnqmd_z + ba_z + mgmt + offset(log_years) +
             (1 | region) + (1 | eco) + (1 | fortype) + (0 + mgd | region))
fam  <- binomial(link = "cloglog")
pr <- c(set_prior("normal(-4.5, 1)", class = "Intercept"),
        set_prior("normal(0, 1)",  class = "b"),
        set_prior("student_t(3, 0, 1)", class = "sd"))
# inits off the boundary: baseline log-hazard ~ -4.5, zero slopes, modest RE sds
init_fun <- function() list(Intercept = -4.5, b = as.array(rnorm(5,0,0.05)),
  sd_1 = as.array(0.3), sd_2 = as.array(0.3), sd_3 = as.array(0.3), sd_4 = as.array(1.0))
fit <- brm(formula = form, data = fitdt, family = fam, prior = pr,
  chains = 4, iter = 1500, warmup = 750, seed = 20260703,
  backend = "cmdstanr", threads = threading(8), cores = 4, init = init_fun,
  control = list(adapt_delta = 0.95, max_treedepth = 12),
  refresh = 100, output_dir = OUT, silent = 0)
saveRDS(fit, file.path(OUT, "v131_brms_fit.rds"))
cat("brms fit time:", round(difftime(Sys.time(), t0, units="mins"),1), "min\n")
fx <- as.data.frame(fixef(fit)); fx <- data.table(term=rownames(fx), fx)
fwrite(fx, file.path(OUT, "v131_brms_fixef.csv")); cat("=== fixef ===\n"); print(fx)
vc <- VarCorr(fit)
sd_rows <- rbindlist(lapply(names(vc), function(g){s <- vc[[g]]$sd
  data.table(grouping=g, term=rownames(s), sd_est=s[,"Estimate"], sd_l95=s[,"Q2.5"], sd_u95=s[,"Q97.5"])}), fill=TRUE)
fwrite(sd_rows, file.path(OUT, "v131_brms_varcomp.csv")); cat("=== varcomp ===\n"); print(sd_rows)
sm <- summary(fit)
conv <- data.table(max_Rhat = max(rhat(fit), na.rm=TRUE),
  min_bulk_ESS = min(sm$fixed[,"Bulk_ESS"], na.rm=TRUE),
  min_tail_ESS = min(sm$fixed[,"Tail_ESS"], na.rm=TRUE),
  n_divergent = sum(subset(nuts_params(fit), Parameter=="divergent__")$Value))
fwrite(conv, file.path(OUT, "v131_brms_convergence.csv")); cat("=== convergence ===\n"); print(conv)
post <- as_draws_df(fit)
b_treat <- post[["b_mgmttreated"]]; b_plant <- post[["b_mgmtplanted"]]
mgmt_eff <- data.table(class=c("treated","planted"),
  loghaz_mean=c(mean(b_treat),mean(b_plant)),
  loghaz_l95=c(quantile(b_treat,.025),quantile(b_plant,.025)),
  loghaz_u95=c(quantile(b_treat,.975),quantile(b_plant,.975)),
  HR_mean=c(mean(exp(b_treat)),mean(exp(b_plant))),
  p_negative=c(mean(b_treat<0),mean(b_plant<0)))
fwrite(mgmt_eff, file.path(OUT, "v131_brms_mgmt_effect.csv")); cat("=== mgmt effect ===\n"); print(mgmt_eff)
rs <- ranef(fit)$region
if("mgd" %in% dimnames(rs)[[3]]){
  rsl <- data.table(region=dimnames(rs)[[1]], mgd_slope=rs[,"Estimate","mgd"], l95=rs[,"Q2.5","mgd"], u95=rs[,"Q97.5","mgd"])
  fwrite(rsl, file.path(OUT, "v131_brms_region_mgmt_slopes.csv"))
  cat("=== region slopes range ===\n"); print(range(rsl$mgd_slope))}
cat("V131_BRMS_DONE at", format(Sys.time()), "\n")

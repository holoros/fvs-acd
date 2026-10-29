## =====================================================================================
## FVS-ACD v13.1 SUBPLOT-GRAIN PRODUCTION REFIT  (2026-07-22)
## -------------------------------------------------------------------------------------
## Full CONUS subplot fitset. Fits BOTH submodels at the target grouping
##   (1|region) + (1|region:eco) + (1|fortype) + (1|plot)
## RECRUITMENT  = single negbinomial (log link, offset log_years)   [PRIMARY]
## MORTALITY    = binomial cloglog, deaths | trials(trials), offset log_years
##
## Config chosen from the 40,030-subplot / 11,519-plot feasibility probe (job 12527808):
##   probe fit BOTH submodels + a hurdle-NB sensitivity at the full grouping cleanly
##   (0 divergences, 0 treedepth hits, E-BFMI > 0.3). LOO put single-NB within noise of
##   the hurdle (elpd_diff -8.6, se 15.0) and the zero PPC of single-NB brackets the
##   observed 0.905 zero fraction, so the hurdle is NOT adopted; single-NB is primary.
##
## Outputs prefixed v131sp_ into ~/v13_subplot. Aggregates only; proprietary tree records
## and FIA coordinates stay on the node. No em dashes. R first. brms / cmdstanr, R/4.4.0.
## DO NOT run while job 12526556 (v131r_mortB_*) is writing ~/v13_kickoff.
## =====================================================================================
suppressPackageStartupMessages({library(data.table); library(brms)})
set.seed(20260722)
OUT <- path.expand("~/v13_subplot"); dir.create(OUT, showWarnings = FALSE); setwd(OUT)
t0 <- Sys.time(); cat("== v13.1 SUBPLOT PRODUCTION REFIT ==\n")
sc <- function(x) as.numeric(scale(x))

## ---- production sampler config (from probe extrapolation) ----
CH   <- 4L                 ## chains
WU   <- 1000L              ## warmup
IT   <- 2000L              ## total iters (1000 warmup + 1000 sampling)
TH   <- threading(8)       ## within-chain threads (reduce_sum over the 724k-row likelihood)
CTRL <- list(adapt_delta = 0.99, max_treedepth = 15)

## =====================================================================================
## 1. LOAD + PREP THE SUBPLOT FITSET
## =====================================================================================
sp <- as.data.table(readRDS(file.path(OUT, "v131sp_fitset.rds")))
sp <- sp[recent == 0]                                      ## fit subplots only
cat("fit rows (recent==0):", nrow(sp),
    " plots:", length(unique(sp$plot_id)), "\n")

## standardize predictors; record scaling for identical FVS back-transform
sp[, rd_z := sc(rd)][, lnqmd_z := sc(ln_qmd)][, ba_z := sc(ba)]
scaling <- data.table(var  = c("rd","ln_qmd","ba"),
                      mean = c(mean(sp$rd, na.rm=TRUE), mean(sp$ln_qmd, na.rm=TRUE), mean(sp$ba, na.rm=TRUE)),
                      sd   = c(sd(sp$rd, na.rm=TRUE),   sd(sp$ln_qmd, na.rm=TRUE),   sd(sp$ba, na.rm=TRUE)))
fwrite(scaling, file.path(OUT, "v131sp_scaling.csv"))

## grouping factors
sp[, region  := factor(region)]
sp[, eco     := factor(eco)]
sp[, fortype := factor(fortype)]
sp[, plot    := factor(plot_id)]

## fit frames
fitREC <- sp[is.finite(rd_z) & is.finite(lnqmd_z) & is.finite(ba_z) & is.finite(log_years)]
fitMOR <- fitREC[trials > 0]
fitMOR[, deaths_i := as.integer(round(deaths))]
fitMOR[, trials_i := as.integer(pmax(round(trials), deaths_i))]
cat("recruit rows:", nrow(fitREC), " | mort rows:", nrow(fitMOR),
    " | recruit zero frac:", round(mean(fitREC$recruit_count == 0), 4), "\n")

## =====================================================================================
## 2. GUARDED FULL GROUPING (all four terms bind on the CONUS fitset)
## =====================================================================================
build_re <- function(d) {
  terms <- character(0)
  if (nlevels(droplevels(d$region))  >= 2) terms <- c(terms, "(1 | region)")
  if (nlevels(droplevels(d$region))  >= 2 &&
      nlevels(droplevels(d$eco))     >= 2) terms <- c(terms, "(1 | region:eco)")
  else if (nlevels(droplevels(d$eco)) >= 2) terms <- c(terms, "(1 | eco)")
  if (nlevels(droplevels(d$fortype)) >= 2) terms <- c(terms, "(1 | fortype)")
  if (nlevels(droplevels(d$plot))    >= 2) terms <- c(terms, "(1 | plot)")
  paste(terms, collapse = " + ")
}
sd_priors <- function(d) {
  ps <- list()
  if (nlevels(droplevels(d$region)) >= 2) ps[[length(ps)+1]] <- set_prior("normal(0, 1)", class="sd", group="region")
  if (nlevels(droplevels(d$region)) >= 2 && nlevels(droplevels(d$eco)) >= 2)
    ps[[length(ps)+1]] <- set_prior("gamma(2, 4)", class="sd", group="region:eco")
  else if (nlevels(droplevels(d$eco)) >= 2)
    ps[[length(ps)+1]] <- set_prior("gamma(2, 4)", class="sd", group="eco")
  if (nlevels(droplevels(d$fortype)) >= 2) ps[[length(ps)+1]] <- set_prior("normal(0, 1)", class="sd", group="fortype")
  if (nlevels(droplevels(d$plot))    >= 2) ps[[length(ps)+1]] <- set_prior("normal(0, 1)", class="sd", group="plot")
  if (length(ps) == 0) return(NULL)
  do.call(c, ps)
}
re_rec <- build_re(fitREC); re_mor <- build_re(fitMOR)
cat("recruitment grouping:", re_rec, "\n")
cat("mortality   grouping:", re_mor, "\n")

diag_of <- function(fit, label){
  sm <- summary(fit); np <- nuts_params(fit)
  ebfmi <- tryCatch({ e <- rstan::get_bfmi(fit$fit); paste(round(e,3), collapse=";") }, error=function(e) NA_character_)
  data.table(model=label,
    max_Rhat=round(max(rhat(fit),na.rm=TRUE),4),
    min_bulk_ESS=round(min(sm$fixed[,"Bulk_ESS"],na.rm=TRUE),1),
    min_tail_ESS=round(min(sm$fixed[,"Tail_ESS"],na.rm=TRUE),1),
    n_divergent=sum(subset(np,Parameter=="divergent__")$Value),
    n_maxtree=sum(subset(np,Parameter=="treedepth__")$Value>=15),
    ebfmi=ebfmi)
}

## =====================================================================================
## 3. RECRUITMENT FIT: single negbinomial (PRIMARY)
## =====================================================================================
cat("\n########## RECRUITMENT FIT (single negbinomial) ##########\n")
formREC <- bf(as.formula(paste("recruit_count ~ rd_z + lnqmd_z + ba_z + offset(log_years) +", re_rec)))
prREC <- c(set_prior("normal(0, 2)",  class = "Intercept"),
           set_prior("normal(0, 2)",  class = "b"),
           set_prior("gamma(2, 0.5)", class = "shape"),
           sd_priors(fitREC))
tm <- Sys.time()
recfit <- brm(formula = formREC, data = fitREC, family = negbinomial(), prior = prREC,
              chains = CH, iter = IT, warmup = WU, seed = 20260722,
              backend = "cmdstanr", threads = TH, cores = CH,
              init = function() list(Intercept = -2.0, b = as.array(rnorm(3, 0, 0.05))),
              control = CTRL, refresh = 100, output_dir = OUT)
cat("recruit wall min:", round(as.numeric(difftime(Sys.time(), tm, units="mins")),1), "\n")
saveRDS(recfit, file.path(OUT, "v131sp_recruit_fit.rds"))
rfx <- data.table(term = rownames(fixef(recfit)), as.data.frame(fixef(recfit)))
fwrite(rfx, file.path(OUT, "v131sp_recruit_fixef.csv")); print(rfx)
rvc <- VarCorr(recfit)
rsd <- rbindlist(lapply(names(rvc), function(g){ s <- rvc[[g]]$sd
  data.table(grouping=g, term=rownames(s), sd_est=s[,"Estimate"], sd_l95=s[,"Q2.5"], sd_u95=s[,"Q97.5"])}), fill=TRUE)
fwrite(rsd, file.path(OUT, "v131sp_recruit_varcomp.csv")); print(rsd)
fwrite(diag_of(recfit, "recruit_singleNB"), file.path(OUT, "v131sp_recruit_convergence.csv"))
print(diag_of(recfit, "recruit_singleNB"))

## ---- RECRUITMENT SENSITIVITY (commented): hurdle_negbinomial + LOO / zero PPC. ----
## The probe found single-NB adequate (LOO within noise, zero PPC brackets observed),
## so the hurdle is not fit in production. Uncomment to reproduce the sensitivity.
## formHUR <- bf(as.formula(paste("recruit_count ~ rd_z + lnqmd_z + ba_z + offset(log_years) +", re_rec)),
##               as.formula(paste("hu ~ rd_z + lnqmd_z + ba_z +", re_rec)))
## prHUR <- c(set_prior("normal(0,2)",class="Intercept"), set_prior("normal(0,2)",class="b"),
##            set_prior("gamma(2,0.5)",class="shape"),
##            set_prior("normal(0,2)",class="Intercept",dpar="hu"),
##            set_prior("normal(0,2)",class="b",dpar="hu"), sd_priors(fitREC))
## hurfit <- brm(formHUR, data=fitREC, family=hurdle_negbinomial(), prior=prHUR,
##               chains=CH, iter=IT, warmup=WU, seed=20260722, backend="cmdstanr",
##               threads=TH, cores=CH, control=CTRL, refresh=100, output_dir=OUT)
## saveRDS(hurfit, file.path(OUT,"v131sp_recruit_hurdle_fit.rds"))
## cmp <- loo_compare(loo(recfit), loo(hurfit)); print(cmp)
## fwrite(as.data.table(cmp, keep.rownames="model"), file.path(OUT,"v131sp_recruit_loo.csv"))

## =====================================================================================
## 4. MORTALITY FIT: binomial cloglog
## =====================================================================================
cat("\n########## MORTALITY FIT (binomial cloglog) ##########\n")
formMOR <- bf(as.formula(paste("deaths_i | trials(trials_i) ~ rd_z + lnqmd_z + ba_z + offset(log_years) +", re_mor)))
prMOR <- c(set_prior("normal(-4.5, 2)", class = "Intercept"),
           set_prior("normal(0, 2)",    class = "b"),
           sd_priors(fitMOR))
tm <- Sys.time()
morfit <- brm(formula = formMOR, data = fitMOR, family = binomial(link = "cloglog"), prior = prMOR,
              chains = CH, iter = IT, warmup = WU, seed = 20260722,
              backend = "cmdstanr", threads = TH, cores = CH,
              init = function() list(Intercept = -4.5, b = as.array(rnorm(3, 0, 0.05))),
              control = CTRL, refresh = 100, output_dir = OUT)
cat("mort wall min:", round(as.numeric(difftime(Sys.time(), tm, units="mins")),1), "\n")
saveRDS(morfit, file.path(OUT, "v131sp_mort_fit.rds"))
mfx <- data.table(term = rownames(fixef(morfit)), as.data.frame(fixef(morfit)))
fwrite(mfx, file.path(OUT, "v131sp_mort_fixef.csv")); print(mfx)
mvc <- VarCorr(morfit)
msd <- rbindlist(lapply(names(mvc), function(g){ s <- mvc[[g]]$sd
  data.table(grouping=g, term=rownames(s), sd_est=s[,"Estimate"], sd_l95=s[,"Q2.5"], sd_u95=s[,"Q97.5"])}), fill=TRUE)
fwrite(msd, file.path(OUT, "v131sp_mort_varcomp.csv")); print(msd)
fwrite(diag_of(morfit, "mortality"), file.path(OUT, "v131sp_mort_convergence.csv"))
print(diag_of(morfit, "mortality"))

cat("\n########## DONE ##########\n")
cat("total wall:", round(difftime(Sys.time(), t0, units="mins"), 1), "min\n")
writeLines("subplot_production_complete", file.path(OUT, "v131sp_status.txt"))
cat("V131SP_PROD_DONE at", format(Sys.time()), "\n")

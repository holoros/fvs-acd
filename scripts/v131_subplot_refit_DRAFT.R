## =====================================================================================
## FVS-ACD v13.1 SUBPLOT-GRAIN REFIT  ***UNSUBMITTED DRAFT*** (2026-07-22)
## -------------------------------------------------------------------------------------
## STATUS: DRAFT ONLY. This script has NOT been submitted and MUST NOT be submitted as-is.
##   It is the planning artifact for the FIA subplot-grain recruitment + mortality refit.
##   Do NOT launch it while job 12526556 (v131r_mortB_*) is writing ~/v13_kickoff.
##   Outputs are prefixed v131sp_ and written to a NEW dir (~/v13_subplot) so nothing
##   collides with the whole-plot v131r_* / v131r_mortB_* fits.
##
## WHY SUBPLOT GRAIN: v12.11 closed managed and mature gaps but the developing Maine FIA
##   end stayed under-predicted and did NOT improve at subplot grain (-24.9 to -24.8 pct),
##   because a stand-level ingrowth multiplier cannot represent patchy subplot recruitment.
##   The whole-plot v5 fit uses (1|region)+(1|region:eco)+(1|fortype) for mortality (v6
##   re-nest). At subplot grain, subplots nest in plot, so we ADD (1|plot).
##
## KEY EMPIRICAL FINDING driving the recruitment likelihood (measured 2026-07-22 on the
##   2858 ME_FIA_S benchmark units, gross ingrowth via FIA RECONCILECD 1/2):
##     zero fraction 0.356 ; mean 1.565 ; var 3.332 ; var/mean 2.13 ; MoM NB theta 1.39.
##     A single negbinomial reproduces the observed zeros: NB-implied zero fraction 0.351
##     vs observed 0.356 (a 0.5 point gap). This OVERTURNS the stand-level red-team lean
##     toward hurdle/ZI: the 72.4 pct zeros / shape 0.042 pathology was an artifact of
##     modeling EXPANDED recruits-per-hectare (mean 1705, max ~430,000), NOT a subplot
##     COUNT. On the count response there is no zero-excess beyond NB, so:
##       PRIMARY recruitment likelihood = single negbinomial (log link, offset log_years).
##       SENSITIVITY = hurdle_negbinomial, selected by LOO / posterior-predictive zero
##         check only if the PPC shows residual zero-inflation (block 5B, commented).
##
## RESPONSE PROVENANCE (important): the shipped bench_mefia_subp_* CSVs carry a POSITIONAL
##   tree index (TREE = 1..N, renumbered each snapshot; species agree only 52 pct on
##   id-matched pairs), so death/recruit responses CANNOT be built from those four files.
##   They are re-derived here from ME_TREE.csv on the LATER measurement (last_cn) using the
##   canonical FIA remeasurement fields: RECONCILECD (1,2 = ingrowth) for recruitment and
##   PREV_STATUS_CD / STATUSCD for mortality. The benchmark CSVs are still used for the t1
##   design predictors (rd, ln_qmd, ba), the plot/subplot keys, interval_years, and esi8.
##
## GROUPING NOTE for the ME-only benchmark: PROV is ME_FIA_S throughout (region single-
##   valued) and the chains are undisturbed AND untreated by construction (mgmt single-
##   valued). So on THIS dataset region and mgmt are NOT identifiable and (1|region:eco)
##   collapses to (1|eco). The full re-nested structure is written below and GUARDED: a
##   grouping factor is included only if it has >=2 levels. To fit the full
##   (1|region)+(1|region:eco)+(1|fortype)+(1|plot) you need a CONUS subplot-grain fitset
##   (the analogue of ~/v13_kickoff/v131_fitset.rds), which does not yet exist (BLOCKER,
##   see the plan .md). eco requires a coordinate-based ecoregion assignment that stays
##   server-side; fortype is joined here from ME_COND.FORTYPCD by PLT_CN.
##
## Aggregates only; proprietary tree records and FIA coordinates stay on the node.
## No em dashes. R first. brms/cmdstanr, matching the v5/v6 toolchain (R/4.4.0).
## =====================================================================================

suppressPackageStartupMessages({library(data.table); library(brms)})
set.seed(20260722)

FIA <- "/users/PUOM0008/crsfaaron/fia_data"
BEN <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
OUT <- path.expand("~/v13_subplot"); dir.create(OUT, showWarnings = FALSE); setwd(OUT)
t0  <- Sys.time(); cat("== v13.1 SUBPLOT REFIT (DRAFT) ==\n")
sc  <- function(x) as.numeric(scale(x))

## =====================================================================================
## 1. ASSEMBLE THE SUBPLOT FITSET (responses + design predictors)
##    Prefer a pre-built v131sp_fitset.rds if present; else assemble it here.
## =====================================================================================
FITSET <- file.path(OUT, "v131sp_fitset.rds")
if (file.exists(FITSET)) {
  sp <- as.data.table(readRDS(FITSET)); cat("loaded existing subplot fitset:", nrow(sp), "rows\n")
} else {
  cat("assembling subplot fitset from ME_TREE.csv + benchmark CSVs ...\n")

  ## --- 1a. chain map first_cn -> last_cn (same pointer-jump as build_mefia_subp_bench.R) ---
  pl <- fread(file.path(FIA, "ME_PLOT.csv"), select = c("CN","PREV_PLT_CN","MEASYEAR"))
  pl[, CN := as.character(CN)][, PREV_PLT_CN := as.character(PREV_PLT_CN)]
  pl[, prev := PREV_PLT_CN][prev %in% c("","NA") | is.na(prev), prev := NA_character_]
  parent <- pl$prev; parent[!(parent %in% pl$CN)] <- NA_character_; names(parent) <- pl$CN
  root <- pl$CN
  for (i in 1:50) { p <- parent[root]; mv <- !is.na(p); if (!any(mv)) break; root[mv] <- p[mv] }
  pl[, root := root]; setorder(pl, root, MEASYEAR, CN)
  chains <- pl[, .(first_cn = CN[1], last_cn = CN[.N]), by = root]

  ## --- 1b. benchmark unit list -> first_cn, SUBP, plot id, interval, esi8 ---
  pairs <- fread(file.path(BEN, "bench_mefia_subp_pairs.csv"))
  esi   <- fread(file.path(BEN, "bench_mefia_subp_site_esi.csv"))
  pairs <- merge(pairs, esi, by.x = "SITE", by.y = "SITE", all.x = TRUE)
  pairs[, first_cn := sub("^ME_S_([0-9]+)_[1-4]$", "\\1", STAND)]
  pairs[, SUBP     := as.integer(sub("^ME_S_[0-9]+_([1-4])$", "\\1", STAND))]
  pairs[, plot     := first_cn]                          ## plot id = chain root; subplots nest in it
  pairs[, region   := "ME"]                              ## single-valued in this benchmark (guarded below)
  pairs[, mgmt     := "none"]                            ## undisturbed AND untreated by construction (guarded)
  pairs <- merge(pairs, chains[, .(first_cn, last_cn)], by = "first_cn", all.x = TRUE)

  ## --- 1c. RESPONSES from ME_TREE.csv on the LATER measurement (last_cn), keyed (PLT_CN,SUBP) ---
  tr <- fread(file.path(FIA, "ME_TREE.csv"),
              select = c("PLT_CN","SUBP","STATUSCD","PREV_STATUS_CD","PREV_TRE_CN","RECONCILECD"))
  tr[, PLT_CN := as.character(PLT_CN)]
  tr <- tr[PLT_CN %in% pairs$last_cn & SUBP %in% 1:4]
  tr[is.na(RECONCILECD),    RECONCILECD    := 0L]
  tr[is.na(PREV_STATUS_CD), PREV_STATUS_CD := 0L]
  tr[, recruit := as.integer(RECONCILECD %in% c(1, 2))]                 ## FIA canonical gross ingrowth
  tr[, trial   := as.integer(PREV_STATUS_CD == 1)]                      ## live at t1 = at-risk
  tr[, death   := as.integer(PREV_STATUS_CD == 1 & STATUSCD == 2)]      ## live t1 -> dead t2
  resp <- tr[, .(recruits = sum(recruit), trials = sum(trial), deaths = sum(death)),
             by = .(last_cn = PLT_CN, SUBP)]

  ## --- 1d. DESIGN PREDICTORS (rd, ln_qmd, ba) from the t1 subplot tree list (init CSV) ---
  ##   NB: rd here is a Reineke SDI relative density. It MUST be reconciled to the exact rd
  ##   definition used in ~/v13_kickoff/v131_fitset.rds before any cross-model comparison;
  ##   flagged in the plan .md. ba in m2/ha, qmd in cm, tph in stems/ha (subplot EXPF).
  ti <- fread(file.path(BEN, "bench_mefia_subp_tree_init.csv"))
  SDIMAX <- 1200  ## stems/ha at 25.4 cm QMD; PLACEHOLDER, replace with the fitset SDImax basis
  dsg <- ti[is.finite(DBH) & DBH > 0, {
    tph <- sum(EXPF); ba <- sum(pi * (DBH/200)^2 * EXPF)
    qmd <- sqrt(sum(DBH^2 * EXPF) / tph)
    sdi <- tph * (qmd/25.4)^1.605
    .(ba = ba, qmd = qmd, ln_qmd = log(qmd), rd = sdi/SDIMAX, tph = tph, ntree = .N)
  }, by = STAND]

  ## --- 1e. fortype from ME_COND.FORTYPCD (join by PLT_CN = first_cn), bucketed ---
  co <- fread(file.path(FIA, "ME_COND.csv"), select = c("PLT_CN","CONDID","FORTYPCD","COND_STATUS_CD"))
  co[, PLT_CN := as.character(PLT_CN)]
  co <- co[COND_STATUS_CD == 1 & is.finite(FORTYPCD) & FORTYPCD > 0]
  ## dominant forest type per plot (first forested condition); refine to subplot CONDID if desired
  ftp <- co[, .(FORTYPCD = FORTYPCD[1]), by = PLT_CN]
  pairs <- merge(pairs, ftp, by.x = "first_cn", by.y = "PLT_CN", all.x = TRUE)
  ## coarse FIA forest-type-group bucket (FORTYPCD %/% 10 * 10); refine as needed
  pairs[, fortype := ifelse(is.finite(FORTYPCD), as.character((FORTYPCD %/% 10L) * 10L), "unk")]

  ## --- 1f. merge responses + predictors + design into one subplot fitset ---
  sp <- merge(pairs[, .(STAND, first_cn, SUBP, last_cn, plot, region, eco = NA_character_,
                        fortype, mgmt, interval_years, esi8)],
              resp, by = c("last_cn","SUBP"), all.x = TRUE)
  sp <- merge(sp, dsg[, .(STAND, ba, qmd, ln_qmd, rd, tph, ntree)], by = "STAND", all.x = TRUE)
  for (cc in c("recruits","trials","deaths")) sp[is.na(get(cc)), (cc) := 0L]
  sp[, log_years := log(pmax(interval_years, 1))]        ## count offset / exposure
  saveRDS(sp, FITSET)
  cat("assembled subplot fitset:", nrow(sp), "rows; saved to", FITSET, "\n")
}

## =====================================================================================
## 2. STANDARDIZE PREDICTORS (record scaling for identical back-transform in FVS scoring)
## =====================================================================================
setDT(sp)
sp[, region  := factor(region)]
sp[, fortype := factor(fortype)]
sp[, plot    := factor(plot)]
## eco: only becomes a real factor once a server-side ecoregion assignment is joined
sp[, eco := if (all(is.na(eco))) factor("ME") else factor(eco)]

sp[, rd_z := sc(rd)][, lnqmd_z := sc(ln_qmd)][, ba_z := sc(ba)]
scaling <- data.table(var  = c("rd","ln_qmd","ba"),
                      mean = c(mean(sp$rd, na.rm=TRUE), mean(sp$ln_qmd, na.rm=TRUE), mean(sp$ba, na.rm=TRUE)),
                      sd   = c(sd(sp$rd, na.rm=TRUE),   sd(sp$ln_qmd, na.rm=TRUE),   sd(sp$ba, na.rm=TRUE)))
fwrite(scaling, file.path(OUT, "v131sp_scaling.csv"))

fitREC <- sp[is.finite(rd_z) & is.finite(lnqmd_z) & is.finite(ba_z) & is.finite(log_years)]
fitMOR <- fitREC[trials > 0]
fitMOR[, deaths_i := as.integer(round(deaths))]
fitMOR[, trials_i := as.integer(pmax(round(trials), deaths_i))]
cat("recruitment fit rows:", nrow(fitREC), " | mortality fit rows:", nrow(fitMOR), "\n")

## =====================================================================================
## 3. GUARDED GROUPING TERMS: re-nested (1|region)+(1|region:eco)+(1|fortype) + (1|plot).
##    Include a term only if its factor has >=2 levels on the fit data (ME-only collapses
##    region and mgmt; on a CONUS subplot fitset all four terms bind).
## =====================================================================================
build_re <- function(d) {
  terms <- character(0)
  if (nlevels(droplevels(d$region))  >= 2) terms <- c(terms, "(1 | region)")
  if (nlevels(droplevels(d$region))  >= 2 &&
      nlevels(droplevels(d$eco))     >= 2) terms <- c(terms, "(1 | region:eco)")
  else if (nlevels(droplevels(d$eco)) >= 2) terms <- c(terms, "(1 | eco)")   ## ME-only fallback
  if (nlevels(droplevels(d$fortype)) >= 2) terms <- c(terms, "(1 | fortype)")
  if (nlevels(droplevels(d$plot))    >= 2) terms <- c(terms, "(1 | plot)")   ## subplots nest in plot
  paste(terms, collapse = " + ")
}
re_rec <- build_re(fitREC); re_mor <- build_re(fitMOR)
cat("recruitment grouping:", re_rec, "\n")
cat("mortality   grouping:", re_mor, "\n")

## boundary-avoiding, weakly-informative sd priors; only set for groups that are present
sd_priors <- function(d) {
  pr <- c()
  if (nlevels(droplevels(d$region))  >= 2) pr <- c(pr, set_prior("normal(0, 1)", class="sd", group="region"))
  if (nlevels(droplevels(d$region))  >= 2 && nlevels(droplevels(d$eco)) >= 2)
    pr <- c(pr, set_prior("gamma(2, 4)", class="sd", group="region:eco"))
  else if (nlevels(droplevels(d$eco)) >= 2)
    pr <- c(pr, set_prior("gamma(2, 4)", class="sd", group="eco"))
  if (nlevels(droplevels(d$fortype)) >= 2) pr <- c(pr, set_prior("normal(0, 1)", class="sd", group="fortype"))
  if (nlevels(droplevels(d$plot))    >= 2) pr <- c(pr, set_prior("normal(0, 1)", class="sd", group="plot"))
  pr
}

## =====================================================================================
## 4. RECRUITMENT FIT: single negbinomial (PRIMARY), log link, offset(log_years).
##    Recommended by the empirical zero fraction (0.356) matching the NB-implied zero
##    (0.351): no zero-excess beyond NB at subplot count grain. Boundary-avoiding priors,
##    adapt_delta 0.99, max_treedepth 15.
## =====================================================================================
cat("\n########## RECRUITMENT FIT (single negbinomial) ##########\n")
formREC <- bf(as.formula(paste("recruits ~ rd_z + lnqmd_z + ba_z + offset(log_years) +", re_rec)))
prREC <- c(set_prior("normal(0, 2)", class = "Intercept"),   ## log recruits/subplot over interval; mean ~1.6
           set_prior("normal(0, 2)", class = "b"),            ## weakly-informative on standardized covariates
           set_prior("gamma(2, 0.5)", class = "shape"),       ## NB shape > 0, mode ~2, covers theta ~1.4
           sd_priors(fitREC))
initREC <- function() list(Intercept = 0.4, b = as.array(rnorm(3, 0, 0.05)))
recfit <- brm(formula = formREC, data = fitREC, family = negbinomial(), prior = prREC,
              chains = 4, iter = 2500, warmup = 1500, seed = 20260722,
              backend = "cmdstanr", threads = threading(4), cores = 4, init = initREC,
              control = list(adapt_delta = 0.99, max_treedepth = 15),
              refresh = 100, output_dir = OUT, silent = 0)
saveRDS(recfit, file.path(OUT, "v131sp_recruit_fit.rds"))
rfx <- data.table(term = rownames(fixef(recfit)), as.data.frame(fixef(recfit)))
fwrite(rfx, file.path(OUT, "v131sp_recruit_fixef.csv")); print(rfx)
rvc <- VarCorr(recfit)
rsd <- rbindlist(lapply(names(rvc), function(g){ s <- rvc[[g]]$sd
  data.table(grouping=g, term=rownames(s), sd_est=s[,"Estimate"], sd_l95=s[,"Q2.5"], sd_u95=s[,"Q97.5"])}), fill=TRUE)
fwrite(rsd, file.path(OUT, "v131sp_recruit_varcomp.csv")); print(rsd)
rsm <- summary(recfit)
rconv <- data.table(max_Rhat = max(rhat(recfit), na.rm=TRUE),
  min_bulk_ESS = min(rsm$fixed[,"Bulk_ESS"], na.rm=TRUE),
  min_tail_ESS = min(rsm$fixed[,"Tail_ESS"], na.rm=TRUE),
  n_divergent  = sum(subset(nuts_params(recfit), Parameter=="divergent__")$Value))
fwrite(rconv, file.path(OUT, "v131sp_recruit_convergence.csv")); print(rconv)

## =====================================================================================
## 5B. RECRUITMENT SENSITIVITY (commented): hurdle_negbinomial + LOO / PPC zero check.
##     Only adopt the hurdle if pp_check(type="bars") or the LOO comparison shows the
##     single NB under-fits the zeros. On current diagnostics it should NOT.
## =====================================================================================
## formHUR <- bf(
##   as.formula(paste("recruits ~ rd_z + lnqmd_z + ba_z + offset(log_years) +", re_rec)),
##   as.formula(paste("hu ~ rd_z + lnqmd_z + ba_z +", re_rec)))   ## presence process its own predictors
## prHUR <- c(set_prior("normal(0,2)", class="Intercept"),
##            set_prior("normal(0,2)", class="b"),
##            set_prior("gamma(2,0.5)", class="shape"),
##            set_prior("normal(0,2)", class="Intercept", dpar="hu"),
##            set_prior("normal(0,2)", class="b",         dpar="hu"),
##            sd_priors(fitREC))
## hurfit <- brm(formHUR, data=fitREC, family=hurdle_negbinomial(), prior=prHUR,
##               chains=4, iter=2500, warmup=1500, seed=20260722, backend="cmdstanr",
##               threads=threading(4), cores=4,
##               control=list(adapt_delta=0.99, max_treedepth=15), refresh=100, output_dir=OUT)
## saveRDS(hurfit, file.path(OUT, "v131sp_recruit_hurdle_fit.rds"))
## loo_cmp <- loo::loo_compare(loo::loo(recfit), loo::loo(hurfit))
## print(loo_cmp); fwrite(as.data.table(loo_cmp, keep.rownames=TRUE), file.path(OUT,"v131sp_recruit_loo.csv"))

## =====================================================================================
## 6. MORTALITY FIT: binomial cloglog, offset(log_years), same re-nested + (1|plot).
##    Mirrors the whole-plot v6 repair structure; deaths/trials from ME_TREE PREV_STATUS_CD.
## =====================================================================================
cat("\n########## MORTALITY FIT (binomial cloglog) ##########\n")
formMOR <- bf(as.formula(paste("deaths_i | trials(trials_i) ~ rd_z + lnqmd_z + ba_z + offset(log_years) +", re_mor)))
prMOR <- c(set_prior("normal(-4.5, 2)", class = "Intercept"),   ## annual log-hazard baseline ~ exp(-4.5)
           set_prior("normal(0, 2)",    class = "b"),
           sd_priors(fitMOR))
initMOR <- function() list(Intercept = -4.5, b = as.array(rnorm(3, 0, 0.05)))
morfit <- brm(formula = formMOR, data = fitMOR, family = binomial(link = "cloglog"), prior = prMOR,
              chains = 4, iter = 2500, warmup = 1500, seed = 20260722,
              backend = "cmdstanr", threads = threading(4), cores = 4, init = initMOR,
              control = list(adapt_delta = 0.99, max_treedepth = 15),
              refresh = 100, output_dir = OUT, silent = 0)
saveRDS(morfit, file.path(OUT, "v131sp_mort_fit.rds"))
mfx <- data.table(term = rownames(fixef(morfit)), as.data.frame(fixef(morfit)))
fwrite(mfx, file.path(OUT, "v131sp_mort_fixef.csv")); print(mfx)
mvc <- VarCorr(morfit)
msd <- rbindlist(lapply(names(mvc), function(g){ s <- mvc[[g]]$sd
  data.table(grouping=g, term=rownames(s), sd_est=s[,"Estimate"], sd_l95=s[,"Q2.5"], sd_u95=s[,"Q97.5"])}), fill=TRUE)
fwrite(msd, file.path(OUT, "v131sp_mort_varcomp.csv")); print(msd)
msm <- summary(morfit)
mconv <- data.table(max_Rhat = max(rhat(morfit), na.rm=TRUE),
  min_bulk_ESS = min(msm$fixed[,"Bulk_ESS"], na.rm=TRUE),
  min_tail_ESS = min(msm$fixed[,"Tail_ESS"], na.rm=TRUE),
  n_divergent  = sum(subset(nuts_params(morfit), Parameter=="divergent__")$Value),
  n_maxtree    = sum(subset(nuts_params(morfit), Parameter=="treedepth__")$Value >= 15))
fwrite(mconv, file.path(OUT, "v131sp_mort_convergence.csv")); print(mconv)

cat("\n########## DONE (DRAFT) ##########\n")
cat("recruitment:\n"); print(rconv)
cat("mortality:\n");   print(mconv)
cat("total wall:", round(difftime(Sys.time(), t0, units="mins"), 1), "min\n")
writeLines("subplot_fit_complete", file.path(OUT, "v131sp_status.txt"))
cat("V131SP_DONE at", format(Sys.time()), "\n")

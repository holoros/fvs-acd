## FVS-ACD v13.1 REFIT: hierarchical mortality + INGROWTH (brms/cmdstanr)
## Resolved 4 July growth-scale finding: management acts through DIAMETER GROWTH (deferred to v13.2),
## NOT mortality. So this mortality refit DROPS the mgmt fixed effect and the (0+mgd|region)
## management random slope. It keeps region/eco/fortype crossed intercepts and the cloglog exposure
## structure. The new response added here is INGROWTH: per-stand annual recruitment modeled as its own
## hierarchical count so it can be raised to the observed level with the correct density and composition
## dependence. Shipped model under-predicts recruitment (NB 17.9 vs 39.8, QC 11.7 vs 19.7 stems/ha/yr);
## density (rd, ba) and composition (fortype, eco) are the levers that must lift it.
## Standing evaluation is the FIA NSVB multi-dimensional scorecard; MagPlot and the recent-FIA benchmark
## stay held OUT of every fit (fit on recent==0). Aggregates only; no coordinates.
suppressPackageStartupMessages({library(data.table); library(brms)})
set.seed(20260707)
OUT <- path.expand("~/v13_kickoff"); dir.create(OUT, showWarnings=FALSE); setwd(OUT)
t0 <- Sys.time(); cat("== v13.1 REFIT (mortality + ingrowth) ==\n")

sc <- function(x) as.numeric(scale(x))

## =====================================================================================
## 1. MORTALITY REFIT (no mgmt terms)
## =====================================================================================
cat("\n########## MORTALITY REFIT ##########\n")
gf <- readRDS(file.path(OUT, "v131_fitset.rds")); setDT(gf)
gf[, deaths_i := as.integer(round(deaths))]
gf[, trials_i := as.integer(pmax(round(trials), deaths_i))]
gf[, region := factor(region)][, eco := factor(eco)][, fortype := factor(fortype)]
gf[, rd_z := sc(rd)][, lnqmd_z := sc(ln_qmd)][, ba_z := sc(ba)]

## record scaling so predictions can be back-transformed identically
scaling <- data.table(
  var  = c("rd", "ln_qmd", "ba"),
  mean = c(mean(gf$rd), mean(gf$ln_qmd), mean(gf$ba)),
  sd   = c(sd(gf$rd),   sd(gf$ln_qmd),   sd(gf$ba)))
fwrite(scaling, file.path(OUT, "v131r_scaling.csv"))

fitM <- gf[recent == 0]
cat("mortality fit rows:", nrow(fitM), "\n")

formM <- bf(deaths_i | trials(trials_i) ~ rd_z + lnqmd_z + ba_z + offset(log_years) +
              (1 | region) + (1 | eco) + (1 | fortype))   # NO mgmt fixed effect, NO region mgd slope
famM  <- binomial(link = "cloglog")
prM <- c(set_prior("normal(-4.5, 1)",     class = "Intercept"),
         set_prior("normal(0, 1)",        class = "b"),
         set_prior("student_t(3, 0, 1)",  class = "sd"))
## inits off the cloglog exposure boundary: baseline log-hazard ~ -4.5, near-zero slopes, modest RE sds
initM <- function() list(Intercept = -4.5, b = as.array(rnorm(3, 0, 0.05)),
  sd_1 = as.array(0.3), sd_2 = as.array(0.3), sd_3 = as.array(0.3))
mfit <- brm(formula = formM, data = fitM, family = famM, prior = prM,
  chains = 4, iter = 1500, warmup = 750, seed = 20260707,
  backend = "cmdstanr", threads = threading(8), cores = 4, init = initM,
  control = list(adapt_delta = 0.95, max_treedepth = 12),
  refresh = 100, output_dir = OUT, silent = 0)
saveRDS(mfit, file.path(OUT, "v131r_mort_fit.rds"))
cat("mortality fit time:", round(difftime(Sys.time(), t0, units="mins"), 1), "min\n")

mfx <- as.data.frame(fixef(mfit)); mfx <- data.table(term = rownames(mfx), mfx)
fwrite(mfx, file.path(OUT, "v131r_mort_fixef.csv")); cat("=== mort fixef ===\n"); print(mfx)
mvc <- VarCorr(mfit)
msd <- rbindlist(lapply(names(mvc), function(g){ s <- mvc[[g]]$sd
  data.table(grouping=g, term=rownames(s), sd_est=s[,"Estimate"], sd_l95=s[,"Q2.5"], sd_u95=s[,"Q97.5"])}), fill=TRUE)
fwrite(msd, file.path(OUT, "v131r_mort_varcomp.csv")); cat("=== mort varcomp ===\n"); print(msd)
msm <- summary(mfit)
mconv <- data.table(max_Rhat = max(rhat(mfit), na.rm=TRUE),
  min_bulk_ESS = min(msm$fixed[,"Bulk_ESS"], na.rm=TRUE),
  min_tail_ESS = min(msm$fixed[,"Tail_ESS"], na.rm=TRUE),
  n_divergent  = sum(subset(nuts_params(mfit), Parameter=="divergent__")$Value))
fwrite(mconv, file.path(OUT, "v131r_mort_convergence.csv")); cat("=== mort convergence ===\n"); print(mconv)

## =====================================================================================
## 2. INGROWTH ASSEMBLY  ## CONFIRM-ON-RETURN block
## =====================================================================================
## Ingrowth is NOT present in either fit set; it must be assembled from the CONUS tree pairs and aggregated to
## the SAME stand-remeasurement key used by v131_growth_assembly_fit.R
## (paste(PLT_CN_cond1, CONDID_cond1, INVYR1, INVYR2)). FIA ingrowth convention: a tree with a valid t2 record
## and NO qualifying t1 record at or above the DBH ingrowth threshold, scaled by its t2 per-hectare expansion
## (TPH2 / TPA2), then annualized by the interval in years. Because the tree-level column names cannot be
## verified while Cardinal is down, everything below is guarded and self-describing: it prints names() first,
## resolves each needed column by trying a list of candidate names, and falls back to a documented TPH-of-
## smallest-class derivation if the recruit flag cannot be built. Do NOT hardcode unknown column names.
cat("\n########## INGROWTH ASSEMBLY (CONFIRM-ON-RETURN) ##########\n")
PAIRS <- "/users/PUOM0008/crsfaaron/fvs-conus/calibration/data/conus_remeasurement_pairs_metric_cond_v2.rds"
DBH_INGROWTH_CM <- 2.54   ## ingrowth DBH threshold (cm); matches the 2.54 cm floor used in the mortality/growth assembly

## helper: pick the first candidate column that exists, else NA
pick <- function(dt, cands){ hit <- cands[cands %in% names(dt)]; if(length(hit)) hit[1] else NA_character_ }

ing <- NULL
if (file.exists(PAIRS)) {
  tp <- as.data.table(readRDS(PAIRS)); cat("tree-pair rows:", nrow(tp), "\n")
  cat("=== names(tree pairs) ===\n"); print(names(tp))   ## CONFIRM-ON-RETURN: verify columns below against this

  ## --- resolve stand key columns (mirror the growth assembly key) ---
  c_pltcn <- pick(tp, c("PLT_CN_cond1", "PLT_CN1", "PLT_CN"))
  c_cond  <- pick(tp, c("CONDID_cond1", "CONDID1", "CONDID"))
  c_iy1   <- pick(tp, c("INVYR1"))
  c_iy2   <- pick(tp, c("INVYR2"))
  c_yrs   <- pick(tp, c("YEARS", "REMPER", "interval_years"))

  ## --- resolve tree-level fields ---
  c_stat2 <- pick(tp, c("TREESTATUS2", "STATUSCD2", "STATUS2"))   ## t2 live status (1 = live)
  c_stat1 <- pick(tp, c("TREESTATUS1", "STATUSCD1", "STATUS1"))   ## t1 status (NA/absent => not present at t1)
  c_dbh1  <- pick(tp, c("DBH1", "DIA1"))                          ## t1 diameter (cm)
  c_dbh2  <- pick(tp, c("DBH2", "DIA2"))                          ## t2 diameter (cm)
  c_tph2  <- pick(tp, c("TPH2", "TPH1"))                          ## per-hectare expansion (t2 preferred)
  c_tpa2  <- pick(tp, c("TPA2", "TPA_UNADJ2", "TPA1", "TPA_UNADJ1"))  ## per-acre fallback expansion

  ## build the stand key (same recipe as v131_growth_assembly_fit.R)
  if (!any(is.na(c(c_pltcn, c_cond, c_iy1, c_iy2)))) {
    tp[, stand_key := paste(get(c_pltcn), get(c_cond), get(c_iy1), get(c_iy2), sep="_")]
  } else {
    stop("CONFIRM-ON-RETURN: cannot build stand_key; verify PLT_CN/CONDID/INVYR column names above.")
  }
  ## interval years for annualization
  if (!is.na(c_yrs)) tp[, .yrs := as.numeric(get(c_yrs))] else tp[, .yrs := NA_real_]

  ## per-hectare expansion: prefer a TPH column; else convert TPA (per acre) to per hectare (x 2.47105)
  if (!is.na(c_tph2)) {
    tp[, .exp := as.numeric(get(c_tph2))]
  } else if (!is.na(c_tpa2)) {
    tp[, .exp := as.numeric(get(c_tpa2)) * 2.47105]
  } else {
    tp[, .exp := NA_real_]
  }

  ## recruit flag: live at t2 AND (absent at t1 OR below threshold at t1)
  have_recruit <- !is.na(c_stat2) && !is.na(c_dbh2)
  if (have_recruit) {
    live2 <- if (!is.na(c_stat2)) tp[[c_stat2]] == 1 else TRUE
    d2ok  <- is.finite(tp[[c_dbh2]]) & tp[[c_dbh2]] >= DBH_INGROWTH_CM
    ## "no qualifying t1 record": either absent at t1 (status NA / not live) or t1 diameter below threshold
    if (!is.na(c_stat1)) {
      present1 <- tp[[c_stat1]] == 1
    } else {
      present1 <- rep(TRUE, nrow(tp))   ## conservative: assume present if no t1 status column
    }
    below1 <- if (!is.na(c_dbh1)) (!is.finite(tp[[c_dbh1]]) | tp[[c_dbh1]] < DBH_INGROWTH_CM) else rep(NA, nrow(tp))
    ## qualifying t1 = present at t1 AND at/above threshold at t1
    qual1 <- present1 & (if (!is.na(c_dbh1)) (is.finite(tp[[c_dbh1]]) & tp[[c_dbh1]] >= DBH_INGROWTH_CM) else FALSE)
    tp[, .recruit := as.integer(live2 & d2ok & !qual1)]

    ing <- tp[, .(
      YEARS      = suppressWarnings(as.numeric(.yrs[1])),
      recruit_tph = sum(fifelse(.recruit == 1, .exp, 0), na.rm = TRUE)   ## stems/ha recruited over the interval
    ), by = stand_key]
    ing[, ingrowth_ann := recruit_tph / YEARS]   ## stems/ha/yr
    cat("ingrowth via recruit flag; stands:", nrow(ing),
        " mean stems/ha/yr:", round(mean(ing$ingrowth_ann, na.rm=TRUE), 2), "\n")
  } else {
    ## ---- DOCUMENTED FALLBACK ----
    ## If a usable recruit flag cannot be built (e.g. no t2 status/diameter), derive recruitment from the change in
    ## per-hectare density of the smallest size class: recruits ~ increase in stems/ha of trees between the ingrowth
    ## threshold and the next size boundary. This is coarser but preserves the sign and the density signal, and is
    ## clearly flagged in the outputs so the live rerun can replace it with the exact recruit-flag version.
    cat("CONFIRM-ON-RETURN: recruit flag unavailable; using smallest-size-class TPH-change fallback.\n")
    UP <- 12.7   ## upper bound of the smallest class (cm); confirm against FIA size-class convention on return
    if (!is.na(c_dbh1) && !is.na(c_dbh2) && !is.na(c_tph2)) {
      tp[, .sc2 := as.integer(is.finite(get(c_dbh2)) & get(c_dbh2) >= DBH_INGROWTH_CM & get(c_dbh2) < UP)]
      tp[, .sc1 := as.integer(is.finite(get(c_dbh1)) & get(c_dbh1) >= DBH_INGROWTH_CM & get(c_dbh1) < UP)]
      ing <- tp[, .(
        YEARS = suppressWarnings(as.numeric(.yrs[1])),
        tph_sc2 = sum(fifelse(.sc2 == 1, .exp, 0), na.rm = TRUE),
        tph_sc1 = sum(fifelse(.sc1 == 1, .exp, 0), na.rm = TRUE)
      ), by = stand_key]
      ing[, ingrowth_ann := pmax(tph_sc2 - tph_sc1, 0) / YEARS]
      ing[, recruit_tph := pmax(tph_sc2 - tph_sc1, 0)]
    } else {
      stop("CONFIRM-ON-RETURN: neither recruit flag nor size-class fallback buildable; verify DBH/TPH columns above.")
    }
  }
  rm(tp); gc()
} else {
  stop("CONFIRM-ON-RETURN: tree-pair file not found at ", PAIRS, "; verify path on Cardinal.")
}

## =====================================================================================
## 3. INGROWTH FIT
## =====================================================================================
## Join ingrowth to the growth fit set (same stand key) to inherit the design columns: rd, ln_qmd, ba,
## region, eco, fortype, recent, mgmt, and log_years for the count offset. The growth set already carries the
## identical stand-remeasurement key, region/eco/fortype construction, holdout flag, and predictors, so the
## join keeps the ingrowth response on the exact same design as mortality and growth.
cat("\n########## INGROWTH FIT ##########\n")
gset <- as.data.table(readRDS(file.path(OUT, "v131g_fitset.rds")))
if (!("stand_key" %in% names(gset)))
  stop("CONFIRM-ON-RETURN: v131g_fitset.rds lacks stand_key; verify the growth-set key column name.")

id <- merge(gset, ing[, .(stand_key, ingrowth_ann, recruit_tph, YEARS)], by = "stand_key", all.x = TRUE)
id[is.na(ingrowth_ann), ingrowth_ann := 0]
id[is.na(recruit_tph),  recruit_tph  := 0]
## interval years for the count offset: prefer the ingrowth-side YEARS, fall back to the growth-set YEARS
id[, ing_years := fifelse(is.finite(YEARS) & YEARS > 0, YEARS,
                          if ("YEARS.x" %in% names(id)) YEARS.x else NA_real_)]
if ("YEARS.y" %in% names(id) && all(is.na(id$ing_years))) id[, ing_years := YEARS.y]
if (!("ing_years" %in% names(id)) || all(!is.finite(id$ing_years))) id[, ing_years := 5]  ## last-resort constant
id[!is.finite(ing_years) | ing_years <= 0, ing_years := 5]
id[, log_years := log(ing_years)]

## response as an integer count of recruits over the interval (stems, not stems/ha, when a per-tree count exists);
## because recruit_tph is a per-hectare expansion sum, round it to an integer count for the NB likelihood and let
## the log_years offset carry the annualization. Predictions divide back out to stems/ha/yr for the gate summary.
id[, ingrowth_count := as.integer(round(pmax(recruit_tph, 0)))]
id[, region := factor(region)][, eco := factor(eco)][, fortype := factor(fortype)]
id[, rd_z := (rd - scaling$mean[scaling$var=="rd"]) / scaling$sd[scaling$var=="rd"]]
id[, lnqmd_z := (ln_qmd - scaling$mean[scaling$var=="ln_qmd"]) / scaling$sd[scaling$var=="ln_qmd"]]
id[, ba_z := (ba - scaling$mean[scaling$var=="ba"]) / scaling$sd[scaling$var=="ba"]]

fitI <- id[recent == 0 & is.finite(rd_z) & is.finite(lnqmd_z) & is.finite(ba_z) & is.finite(log_years)]
cat("ingrowth fit rows:", nrow(fitI),
    " mean observed stems/ha/yr:", round(mean(fitI$ingrowth_ann, na.rm=TRUE), 2), "\n")

formI <- bf(ingrowth_count ~ rd_z + lnqmd_z + ba_z + offset(log_years) +
              (1 | region) + (1 | eco) + (1 | fortype))
famI  <- negbinomial()
prI <- c(set_prior("normal(2, 2)",       class = "Intercept"),   ## log mean recruits over a ~5 yr interval
         set_prior("normal(0, 1)",        class = "b"),
         set_prior("student_t(3, 0, 1)",  class = "sd"))
initI <- function() list(Intercept = 2, b = as.array(rnorm(3, 0, 0.05)),
  sd_1 = as.array(0.3), sd_2 = as.array(0.3), sd_3 = as.array(0.3))
ifit <- brm(formula = formI, data = fitI, family = famI, prior = prI,
  chains = 4, iter = 1500, warmup = 750, seed = 20260707,
  backend = "cmdstanr", threads = threading(8), cores = 4, init = initI,
  control = list(adapt_delta = 0.95, max_treedepth = 12),
  refresh = 100, output_dir = OUT, silent = 0)
saveRDS(ifit, file.path(OUT, "v131r_ingrowth_fit.rds"))
cat("ingrowth fit time:", round(difftime(Sys.time(), t0, units="mins"), 1), "min (cumulative)\n")

ifx <- as.data.frame(fixef(ifit)); ifx <- data.table(term = rownames(ifx), ifx)
fwrite(ifx, file.path(OUT, "v131r_ingrowth_fixef.csv")); cat("=== ingrowth fixef ===\n"); print(ifx)
ivc <- VarCorr(ifit)
isd <- rbindlist(lapply(names(ivc), function(g){ s <- ivc[[g]]$sd
  data.table(grouping=g, term=rownames(s), sd_est=s[,"Estimate"], sd_l95=s[,"Q2.5"], sd_u95=s[,"Q97.5"])}), fill=TRUE)
fwrite(isd, file.path(OUT, "v131r_ingrowth_varcomp.csv")); cat("=== ingrowth varcomp ===\n"); print(isd)
ism <- summary(ifit)
iconv <- data.table(max_Rhat = max(rhat(ifit), na.rm=TRUE),
  min_bulk_ESS = min(ism$fixed[,"Bulk_ESS"], na.rm=TRUE),
  min_tail_ESS = min(ism$fixed[,"Tail_ESS"], na.rm=TRUE),
  n_divergent  = sum(subset(nuts_params(ifit), Parameter=="divergent__")$Value))
fwrite(iconv, file.path(OUT, "v131r_ingrowth_convergence.csv")); cat("=== ingrowth convergence ===\n"); print(iconv)

## ---- predicted vs observed stems/ha/yr, by management and by region (the gate check for NB/QC) ----
## posterior expected count per stand, divided by per-hectare basis and interval to return stems/ha/yr.
## recruit_tph is a per-hectare expansion sum, so the count IS already on a per-hectare basis; dividing the
## expected count by ing_years returns stems/ha/yr directly.
pe <- fitpred <- NULL
pe <- tryCatch(fitted(ifit, newdata = fitI, re_formula = NULL, summary = TRUE)[, "Estimate"],
               error = function(e) rep(NA_real_, nrow(fitI)))
fitI[, pred_count := pe]
fitI[, pred_stems_ha_yr := pred_count / ing_years]
fitI[, obs_stems_ha_yr  := ingrowth_ann]

byregion <- fitI[, .(n = .N,
   obs_stems_ha_yr  = round(mean(obs_stems_ha_yr,  na.rm=TRUE), 2),
   pred_stems_ha_yr = round(mean(pred_stems_ha_yr, na.rm=TRUE), 2)), by = region][order(region)]
byregion[, ratio_pred_obs := round(pred_stems_ha_yr / obs_stems_ha_yr, 3)]
fwrite(byregion, file.path(OUT, "v131r_ingrowth_byregion.csv"))
cat("=== ingrowth predicted vs observed by region (stems/ha/yr) ===\n"); print(byregion)

if ("mgmt" %in% names(fitI)) {
  fitI[, mgmt := factor(mgmt, levels = intersect(c("none","treated","planted"), unique(as.character(mgmt))))]
  bymgmt <- fitI[, .(n = .N,
     obs_stems_ha_yr  = round(mean(obs_stems_ha_yr,  na.rm=TRUE), 2),
     pred_stems_ha_yr = round(mean(pred_stems_ha_yr, na.rm=TRUE), 2)), by = mgmt][order(mgmt)]
  bymgmt[, ratio_pred_obs := round(pred_stems_ha_yr / obs_stems_ha_yr, 3)]
  fwrite(bymgmt, file.path(OUT, "v131r_ingrowth_bymgmt.csv"))
  cat("=== ingrowth predicted vs observed by mgmt (stems/ha/yr) ===\n"); print(bymgmt)
}

## =====================================================================================
## 4. DIAGNOSTICS + STATUS
## =====================================================================================
cat("\n########## CONVERGENCE DIAGNOSTICS ##########\n")
cat("-- mortality --\n");  print(mconv)
cat("-- ingrowth  --\n");  print(iconv)
cat("total wall time:", round(difftime(Sys.time(), t0, units="mins"), 1), "min\n")

writeLines("fit_complete", file.path(OUT, "v131r_status.txt"))
cat("V131R_DONE at", format(Sys.time()), "\n")

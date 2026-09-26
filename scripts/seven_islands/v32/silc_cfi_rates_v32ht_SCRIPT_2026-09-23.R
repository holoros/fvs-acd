# silc_cfi_rates_v32ht_SCRIPT_2026-09-23.R: v29b rates script copied unchanged except the unified
# treelist path, OUT, output names, and LABEL entries for the September 23 height factorial cells.
#!/usr/bin/env Rscript
# silc_cfi_rates_v29_SCRIPT_2026-09-08.R
#
# NEW SCORECARD AXIS: growth and mortality RATES, not t2 state.
#
# Aaron's instruction, September 8, 2026: "we should also compute various growth
# and mortality metrics from first/last measurement and then compare to the model
# predictions for things like PAI/MAI, which are equally important."
#
# The v23-v29 benchmark scores STATE at t2 only (standing gross4 volume, biomass,
# value). A growth and yield model does not claim a state, it claims a RATE, and a
# model can land on the right standing volume through compensating errors in growth
# and in mortality. This script closes that gap. It computes periodic annual
# increment over each plot's own remeasurement interval, for OBSERVED and for every
# model configuration, running the SAME merchandiser over both ends of the increment
# so that no part of the difference is a merchandising artifact.
#
# ARCHITECTURE
#   t1  = the shared model INPUT tree list, pair_input_long_v16/pair_<PLOT>_<YEAR>_tree.csv.
#         Every configuration was initialised from this identical list, so one t1 state
#         serves all of them and the PAI difference between two configurations is purely
#         a difference in projected t2.
#   t2  = each configuration's rows in v32_htdub/silc_cfi_unified_treelists_v32ht.csv,
#         OBSERVED included, exactly as the state scorecard reads them.
#   PAI = (X_t2 - X_t1) / PERIOD_YR, per plot, per configuration.
#
# THE HEIGHT PROBLEM, AND WHAT WAS DONE ABOUT IT
#   30.2% of t1 trees on routine plots carry no measured height, and 17 of the 65
#   routine plots carry no t1 height at all. merch_silc_tree returns zero volume for a
#   tree with a missing height, so an unimputed t1 would silently zero out those plots
#   and inflate every PAI. Heights are therefore imputed from a Wykoff-form
#   height-diameter model, ht_m = 1.37 + exp(b0 + b1/(dbh_cm+1)), fitted by species on
#   the pooled measured heights of this same CFI (the OBSERVED t2 unified rows plus the
#   measured t1 heights), with a Duan smearing correction, and with a plot-level
#   multiplicative calibration wherever a plot carries at least MIN_CAL measured t1
#   heights. Two sensitivity variants are run and reported so the reader can see how
#   much of the observed volume PAI is imputation.
#
#   The height screen matters on its own account. 116 of the 1,860 OBSERVED t2 trees
#   carry heights above 100 ft, concentrated in plots 1114, 1130, 1133 and 1252 and in
#   measurement years 1994, 1999 and 2001, at height-to-diameter ratios up to 367,
#   which is not a tree. Those records are screened OUT OF THE HEIGHT MODEL, but they
#   are left untouched in the OBSERVED t2 volume so this axis stays comparable with the
#   state scorecard. That is a defect in the underlying CFI heights and it inflates
#   observed standing volume on those four plots on BOTH axes. Flagged, not fixed here.
#
# WHAT THE DATA CAN AND CANNOT DECOMPOSE
#   Net PAI is fully supported for every configuration. The survivor, mortality and
#   ingrowth decomposition is supported for OBSERVED only, from the GRM bookkeeping
#   chained across the intervening five-year steps. It is NOT supported for any model,
#   because the unified treelist carries no tree identifier and a stand-level change in
#   stems per acre cannot separate a tree that died from a tree that grew past the
#   4.5 in tally threshold. Scoring a model on mortality would require each model's
#   own treelist to retain a tree id and a status code. Said plainly in the log.
#
# WRITES ONLY under v29_run/rates/. Nothing elsewhere in silc_cfi/ is touched.

t0 <- Sys.time()
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
source("kozak_taper.R"); source("merch_cords.R"); source("merch_asg.R")
source("v29_run/merch_silcspec_v29.R")
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(parallel))

OUT   <- "/users/PUOM0008/crsfaaron/silc_cfi/v32_htdub"
TAB   <- "/users/PUOM0008/crsfaaron/silc_cfi/v29_run/rates/tables"
ACRES_PER_HA <- 2.4710538147
BA_FT2_PER_IN2 <- pi/576          # ft2 of basal area per in2 of DIA
HT_SCREEN_FT   <- 100             # height-model plausibility screen
HD_SCREEN      <- 130             # max height-to-diameter ratio, m per m
MIN_CAL        <- 3               # measured t1 heights needed for plot calibration
spec  <- .load_silc_specs("silc_merch_specs.csv")
CF    <- M3_TO_FT3/CORD_FT3
ncores <- max(1, detectCores()-1)
cat(sprintf("=== SILC CFI v29 RATES axis | %s | %d cores ===\n\n", format(Sys.time()), ncores))

# ============================================================================
# 1. ROSTER AND ROUTINE FILTER (identical to the state scorecard)
# ============================================================================
ps <- as.data.table(read.csv("silc_cfi_longhorizon_pairs_v16.csv", stringsAsFactors=FALSE))
ps[, estbl := (BA_CURR_FT2AC / pmax(BA_PREV_FT2AC,1)) > 2.0]
routine <- ps[estbl==FALSE, PLOT]
psr <- ps[PLOT %in% routine]
cat(sprintf("Pairs %d | routine plots %d | interval %d-%d yr (mean %.1f)\n",
    nrow(ps), length(routine), min(psr$PERIOD_YR), max(psr$PERIOD_YR), mean(psr$PERIOD_YR)))

# ============================================================================
# 2. SHARED t1 TREE LIST (the model input), with species recode
# ============================================================================
# AGY 2-letter -> FIA SPCD, same crosswalk value_silcspec_v29.R uses. Inverted here.
AGY2SPCD <- c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,RN=125,JP=105,TA=71,EH=261,
  WC=241,OS=299,SM=318,RM=316,YB=371,PB=375,GB=379,SB=372,AB=531,QA=746,BT=743,BP=741,
  WA=541,BA=543,GA=544,AS=541,RO=833,OH=999,ST=935,BC=762,AE=972,BL=951,BW=951,NC=241,
  HH=701,PR=760)
SPCD2AGY <- setNames(names(AGY2SPCD)[!duplicated(AGY2SPCD)], AGY2SPCD[!duplicated(AGY2SPCD)])

t1 <- rbindlist(lapply(seq_len(nrow(ps)), function(i){
  f <- ps$tree_list_file[i]
  if (!file.exists(f)) return(NULL)
  d <- as.data.table(read.csv(f, stringsAsFactors=FALSE))
  d[, `:=`(PLOT=ps$PLOT[i], YEAR=ps$YEAR_PREV[i])]
  d
}), fill=TRUE)
t1[, sp := SPCD2AGY[as.character(SPCD)]]
cat("\nt1 species crosswalk (SPCD -> AGY code):\n")
print(t1[, .(n=.N, common=SP[1], sp=sp[1]), by=SPCD][order(-n)])
if (any(is.na(t1$sp))) { t1[is.na(sp), sp := "OH"]
  cat("NOTE: unmapped SPCD recoded to OH, n =", sum(is.na(SPCD2AGY[as.character(t1$SPCD)])), "\n") }
t1[, `:=`(dbh_cm = DBH*2.54, ht_m_meas = ifelse(is.finite(HT), HT*0.3048, NA_real_),
          expf_tph = EXPF*ACRES_PER_HA, expf_ac = as.numeric(EXPF))]
t1r <- t1[PLOT %in% routine]
cat(sprintf("\nt1 rows %d (routine %d) | measured heights %d, missing %d (%.1f%% of routine)\n",
    nrow(t1), nrow(t1r), sum(is.finite(t1r$ht_m_meas)), sum(!is.finite(t1r$ht_m_meas)),
    100*mean(!is.finite(t1r$ht_m_meas))))

# ============================================================================
# 3. t2 UNIFIED TREELIST
# ============================================================================
uni <- as.data.table(fread("v32_htdub/silc_cfi_unified_treelists_v32ht.csv"))
uni <- uni[is.finite(as.numeric(dbh_cm))]
uni[, `:=`(dbh_cm=as.numeric(dbh_cm), ht_m=as.numeric(ht_m), expf_tph=as.numeric(expf_tph))]
uni <- uni[PLOT %in% routine]
uni[, expf_ac := expf_tph/ACRES_PER_HA]
cat("\nt2 configurations and routine-plot coverage:\n")
print(uni[, .(rows=.N, plots=uniqueN(PLOT)), by=model_config][order(model_config)])

# ============================================================================
# 4. HEIGHT-DIAMETER MODEL FOR THE t1 IMPUTATION
# ============================================================================
ob <- uni[model_config=="OBSERVED", .(PLOT, sp, dbh_cm, ht_m)]
hd_train <- rbindlist(list(
  ob[, .(sp, dbh_cm, ht_m, src="t2_observed")],
  t1r[is.finite(ht_m_meas), .(sp, dbh_cm, ht_m=ht_m_meas, src="t1_measured")]))
hd_train[, hd := ht_m/(dbh_cm/100)]
keep <- hd_train$ht_m > 1.4 & hd_train$ht_m <= HT_SCREEN_FT*0.3048 & hd_train$hd <= HD_SCREEN
cat(sprintf("\nHeight training records %d, screened out %d (%.1f%%) for ht > %d ft or h/d > %d\n",
    nrow(hd_train), sum(!keep), 100*mean(!keep), HT_SCREEN_FT, HD_SCREEN))
print(head(hd_train[!keep, .N, by=.(src, sp)][order(-N)], 10))
hd_train <- hd_train[keep]

fit_wykoff <- function(d){
  if (nrow(d) < 15) return(NULL)
  x <- 1/(d$dbh_cm+1); y <- log(pmax(d$ht_m-1.37, 0.05))
  m <- lm(y ~ x)
  res <- d$ht_m - (1.37 + exp(fitted(m)))
  list(b0=unname(coef(m)[1]), b1=unname(coef(m)[2]),
       sm=mean(exp(residuals(m))), n=nrow(d),
       r2=summary(m)$r.squared, rmse=sqrt(mean(res^2)))
}
GLOB <- fit_wykoff(hd_train)
SPFIT <- list(); for (s in sort(unique(hd_train$sp))) { f <- fit_wykoff(hd_train[sp==s]); if (!is.null(f)) SPFIT[[s]] <- f }
cat(sprintf("\nWykoff ht_m = 1.37 + exp(b0 + b1/(dbh_cm+1)), Duan smearing\n  %-8s n=%4d b0=%7.4f b1=%9.4f smear=%.3f r2=%.3f rmse=%.2f m\n",
    "POOLED", GLOB$n, GLOB$b0, GLOB$b1, GLOB$sm, GLOB$r2, GLOB$rmse))
for (s in names(SPFIT)) { f <- SPFIT[[s]]
  cat(sprintf("  %-8s n=%4d b0=%7.4f b1=%9.4f smear=%.3f r2=%.3f rmse=%.2f m\n",
      s, f$n, f$b0, f$b1, f$sm, f$r2, f$rmse)) }

predict_ht <- function(sp, dbh_cm, use_species=TRUE){
  f <- if (use_species && !is.null(SPFIT[[sp]])) SPFIT[[sp]] else GLOB
  1.37 + exp(f$b0 + f$b1/(dbh_cm+1)) * f$sm
}
t1[, ht_pred_sp := mapply(predict_ht, sp, dbh_cm, MoreArgs=list(use_species=TRUE))]
t1[, ht_pred_gl := mapply(predict_ht, sp, dbh_cm, MoreArgs=list(use_species=FALSE))]

# plot-level multiplicative calibration from measured t1 heights, screened
t1[, ht_ok := is.finite(ht_m_meas) & ht_m_meas > 1.4 &
              ht_m_meas <= HT_SCREEN_FT*0.3048 & (ht_m_meas/(dbh_cm/100)) <= HD_SCREEN]
cal <- t1[ht_ok==TRUE, .(nmeas=.N, k=mean(ht_m_meas)/mean(ht_pred_sp)), by=PLOT][nmeas >= MIN_CAL]
t1 <- merge(t1, cal[, .(PLOT, k)], by="PLOT", all.x=TRUE)
t1[is.na(k), k := 1.0]
cat(sprintf("\nPlot-level height calibration applied on %d of %d routine plots (k range %s)\n",
    uniqueN(cal[PLOT %in% routine]$PLOT), length(routine),
    if (nrow(cal)>0) sprintf("%.2f to %.2f", min(cal$k), max(cal$k)) else "none"))

# three height variants for the t1 tree list
t1[, ht_A := ifelse(ht_ok, ht_m_meas, ht_pred_sp * k)]   # PRIMARY: species curve + plot calibration
t1[, ht_B := ifelse(ht_ok, ht_m_meas, ht_pred_sp)]       # sensitivity: species curve, no calibration
t1[, ht_C := ifelse(ht_ok, ht_m_meas, ht_pred_gl)]       # sensitivity: pooled curve, no calibration
cat(sprintf("t1 heights: measured-and-kept %d | imputed %d | measured-but-screened-then-imputed %d\n",
    sum(t1$ht_ok), sum(!is.finite(t1$ht_m_meas)), sum(is.finite(t1$ht_m_meas) & !t1$ht_ok)))

# ============================================================================
# 5. MERCHANDISE BOTH ENDS WITH THE SAME RULE
# ============================================================================
merch_gross4 <- function(sp, dbh_cm, ht_m){
  key <- paste(sp, round(dbh_cm,1), round(ht_m,1), sep="|"); uk <- unique(key)
  g <- unlist(mclapply(uk, function(kk){
    p <- strsplit(kk, "\\|")[[1]]
    tryCatch(as.numeric(merch_silc_tree(p[1], as.numeric(p[2]), as.numeric(p[3]), spec)[["gross4"]]),
             error=function(e) NA_real_)
  }, mc.cores=ncores))
  g <- as.numeric(g)
  names(g) <- uk; unname(g[key])
}
cat("\nMerchandising t1 (3 height variants) ...\n")
t1[, g4_A := merch_gross4(sp, dbh_cm, ht_A)]
t1[, g4_B := merch_gross4(sp, dbh_cm, ht_B)]
t1[, g4_C := merch_gross4(sp, dbh_cm, ht_C)]
cat("Merchandising t2 (all configurations) ...\n")
uni[, g4 := merch_gross4(sp, dbh_cm, ht_m)]

# ---- stand states ----------------------------------------------------------
st1 <- t1[PLOT %in% routine, .(
  gross4_cd_1 = sum(g4_A * CF * expf_ac),
  gross4_cd_1B= sum(g4_B * CF * expf_ac),
  gross4_cd_1C= sum(g4_C * CF * expf_ac),
  ba_ft2ac_1  = sum(BA_FT2_PER_IN2 * DBH^2 * expf_ac),
  ba_m2ha_1   = sum(pi*(dbh_cm/200)^2 * expf_tph),
  tpa_1       = sum(expf_ac),
  n_trees_1   = .N), by=PLOT]
st1[, qmd_in_1 := sqrt(ba_ft2ac_1/(BA_FT2_PER_IN2*tpa_1))]

st2 <- uni[, .(
  gross4_cd_2 = sum(g4 * CF * expf_ac),
  ba_ft2ac_2  = sum(BA_FT2_PER_IN2 * (dbh_cm/2.54)^2 * expf_ac),
  ba_m2ha_2   = sum(pi*(dbh_cm/200)^2 * expf_tph),
  tpa_2       = sum(expf_ac),
  n_trees_2   = .N), by=.(model_config, PLOT)]
st2[, qmd_in_2 := sqrt(ba_ft2ac_2/(BA_FT2_PER_IN2*tpa_2))]

# reconciliation against the pairs file, which is an independent stand-level summary
rec <- merge(st1, psr[, .(PLOT, BA_PREV_FT2AC, BA_CURR_FT2AC, TPA_PREV, TPA_CURR, PERIOD_YR)], by="PLOT")
cat(sprintf("\nRECONCILIATION t1 vs pairs file: BA mean diff %.3f ft2/ac (max abs %.3f) | TPA mean diff %.2f\n",
    mean(rec$ba_ft2ac_1-rec$BA_PREV_FT2AC), max(abs(rec$ba_ft2ac_1-rec$BA_PREV_FT2AC)),
    mean(rec$tpa_1-rec$TPA_PREV)))
rec2 <- merge(st2[model_config=="OBSERVED"], psr[, .(PLOT, BA_CURR_FT2AC, TPA_CURR)], by="PLOT")
cat(sprintf("RECONCILIATION OBSERVED t2 vs pairs file: BA mean diff %.3f ft2/ac (max abs %.3f) | TPA mean diff %.2f\n",
    mean(rec2$ba_ft2ac_2-rec2$BA_CURR_FT2AC), max(abs(rec2$ba_ft2ac_2-rec2$BA_CURR_FT2AC)),
    mean(rec2$tpa_2-rec2$TPA_CURR)))
cat("  The t2 gap is the unified OBSERVED treelist dropping trees with no recorded diameter;\n")
cat("  it is carried as-is because the state scorecard scores against that same treelist.\n")

# ============================================================================
# 6. PERIODIC ANNUAL INCREMENT, PER PLOT PER CONFIGURATION
# ============================================================================
byplot <- merge(st2, st1, by="PLOT")
byplot <- merge(byplot, psr[, .(PLOT, YEAR_PREV, YEAR_CURR, PERIOD_YR)], by="PLOT")
byplot[, `:=`(
  pai_gross4_cdacyr = (gross4_cd_2 - gross4_cd_1)/PERIOD_YR,
  pai_ba_m2hayr     = (ba_m2ha_2  - ba_m2ha_1)/PERIOD_YR,
  pai_ba_ft2acyr    = (ba_ft2ac_2 - ba_ft2ac_1)/PERIOD_YR,
  pai_qmd_inyr      = (qmd_in_2   - qmd_in_1)/PERIOD_YR,
  pai_tpa_yr        = (tpa_2      - tpa_1)/PERIOD_YR,
  ann_stem_rate_pct = 100*((tpa_2/tpa_1)^(1/PERIOD_YR) - 1),
  pai_gross4_cdacyr_htB = (gross4_cd_2 - gross4_cd_1B)/PERIOD_YR,
  pai_gross4_cdacyr_htC = (gross4_cd_2 - gross4_cd_1C)/PERIOD_YR)]

# ============================================================================
# 7. OBSERVED DECOMPOSITION, FROM THE GRM BOOKKEEPING
# ============================================================================
g <- as.data.table(fread(file.path(TAB, "GRM.csv")))
ba_m2 <- function(dia_in) pi*((dia_in*2.54)/200)^2      # m2 per tree
EXPF_TPH <- 5*ACRES_PER_HA                              # uniform 5 TPA throughout this CFI
# The GRM table is written one row per tree per FIVE-YEAR STEP, and a scored interval
# spans up to three steps, so a naive sum over records counts one ingrowth tree once per
# step it appears in and inflates ingrowth roughly twofold against the STAND_METRICS
# TPA_INGROWTH bookkeeping. The decomposition below is therefore TREE-RESOLVED: each
# tree in the interval is classified once, from its own sequence of step records, and
# contributes to exactly one of survivor growth, mortality, or ingrowth.
dec <- rbindlist(lapply(which(ps$PLOT %in% routine), function(i){
  P <- ps$PLOT[i]; y1 <- ps$YEAR_PREV[i]; y2 <- ps$YEAR_CURR[i]; Lp <- ps$PERIOD_YR[i]
  s <- g[PLOT==P & YEAR_PREV>=y1 & YEAR_CURR<=y2]
  steps <- unique(s[, .(YEAR_PREV, YEAR_CURR)])[order(YEAR_PREV)]
  covered <- nrow(steps)>0 && min(steps$YEAR_PREV)==y1 && max(steps$YEAR_CURR)==y2 &&
             all(steps$YEAR_CURR[-nrow(steps)] == steps$YEAR_PREV[-1])
  if (nrow(s)==0) return(data.table(PLOT=P, grm_covered=FALSE, grm_nsteps=0L,
    n_surv_tree=0L, n_mort_tree=0L, n_ingr_tree=0L, n_unknown_tree=0L, n_subthr_rec=0L,
    pai_ba_surv_m2hayr=NA_real_, pai_ba_mort_m2hayr=NA_real_, pai_ba_ingr_m2hayr=NA_real_,
    n_t1_stems_grm=0L))
  setorder(s, TREE, YEAR_PREV)
  tw <- s[, {
    cls  <- GRM_CLASS
    d1   <- DIA_PREV_IN[1]
    dl   <- DIA_CURR_IN[.N]
    dead <- any(cls=="MORTALITY")
    ingr <- (!dead) && any(cls=="INGROWTH")
    surv <- (!dead) && (!ingr) && any(cls=="SURVIVOR")
    dmort <- if (dead) DIA_PREV_IN[which(cls=="MORTALITY")[1]] else NA_real_
    # an ingrowth tree's contribution is its basal area at t2, its post-ingrowth growth included
    ding <- if (ingr) { j <- which(cls=="INGROWTH")[1]
                        if (is.finite(dl)) dl else DIA_CURR_IN[j] } else NA_real_
    .(dead=dead, ingr=ingr, surv=surv, d1=d1, dl=dl, dmort=dmort, ding=ding,
      unk=all(cls %in% c("UNKNOWN","SUB_THRESHOLD")))
  }, by=TREE]
  sv <- tw[surv==TRUE & is.finite(d1) & is.finite(dl)]
  data.table(PLOT=P, grm_covered=covered, grm_nsteps=nrow(steps),
    n_surv_tree=nrow(sv), n_mort_tree=sum(tw$dead), n_ingr_tree=sum(tw$ingr),
    n_unknown_tree=sum(tw$unk), n_subthr_rec=sum(s$GRM_CLASS=="SUB_THRESHOLD"),
    pai_ba_surv_m2hayr = sum((ba_m2(sv$dl)-ba_m2(sv$d1))*EXPF_TPH)/Lp,
    pai_ba_mort_m2hayr = sum(ba_m2(tw[dead==TRUE]$dmort)*EXPF_TPH, na.rm=TRUE)/Lp,
    pai_ba_ingr_m2hayr = sum(ba_m2(tw[ingr==TRUE]$ding)*EXPF_TPH, na.rm=TRUE)/Lp,
    n_t1_stems_grm = nrow(tw[dead==TRUE | surv==TRUE]))
}))
dec[, stem_mort_pctyr_grm := 100*n_mort_tree/pmax(n_t1_stems_grm,1)/
       ps$PERIOD_YR[match(PLOT, ps$PLOT)]]
dec[, pai_ba_net_grm_m2hayr := pai_ba_surv_m2hayr + pai_ba_ingr_m2hayr - pai_ba_mort_m2hayr]
cat(sprintf("\nGRM chained decomposition, tree-resolved: %d of %d routine plots fully covered\n",
    sum(dec$grm_covered), nrow(dec)))
cat(sprintf("  trees classified: survivor %d | mortality %d | ingrowth %d | unclassifiable %d\n",
    sum(dec$n_surv_tree), sum(dec$n_mort_tree), sum(dec$n_ingr_tree), sum(dec$n_unknown_tree)))

# stand-level bookkeeping cross-check
sm <- as.data.table(fread(file.path(TAB, "STAND_METRICS.csv")))
bk <- rbindlist(lapply(which(ps$PLOT %in% routine), function(i){
  s <- sm[PLOT==ps$PLOT[i] & MEASYEAR > ps$YEAR_PREV[i] & MEASYEAR <= ps$YEAR_CURR[i]]
  data.table(PLOT=ps$PLOT[i], n_dead_bk=sum(s$N_DEAD,na.rm=TRUE),
             n_removed_bk=sum(s$N_REMOVED,na.rm=TRUE), tpa_ingr_bk=sum(s$TPA_INGROWTH,na.rm=TRUE))
}))
# identity-match upper bound from TREE.csv
tr <- as.data.table(fread(file.path(TAB, "TREE.csv")))
idm <- rbindlist(lapply(which(ps$PLOT %in% routine), function(i){
  P <- ps$PLOT[i]
  a <- tr[PLOT==P & MEASYEAR==ps$YEAR_PREV[i] & STATUSCD==1 & is.finite(DIA_IN) & DIA_IN>0]
  b <- tr[PLOT==P & MEASYEAR==ps$YEAR_CURR[i] & STATUSCD==1 & is.finite(DIA_IN) & DIA_IN>0]
  ia <- paste(a$SUBP,a$TREE); ib <- paste(b$SUBP,b$TREE)
  data.table(PLOT=P, n1_id=nrow(a), n2_id=nrow(b), n_surv_id=sum(ia %in% ib),
             n_lost_id=sum(!(ia %in% ib)), n_new_id=sum(!(ib %in% ia)))
}))
obs_dec <- Reduce(function(x,y) merge(x,y,by="PLOT"), list(dec, bk, idm))
obs_dec <- merge(obs_dec, psr[, .(PLOT, PERIOD_YR)], by="PLOT")
obs_dec[, `:=`(stem_mort_pctyr_bk = 100*n_dead_bk/(n1_id)/PERIOD_YR,
               stem_mort_pctyr_id = 100*n_lost_id/(n1_id)/PERIOD_YR)]
cat(sprintf("\nOBSERVED stem mortality, three independent accountings (annual %% of initial stems):\n"))
cat(sprintf("  GRM MORTALITY, tree-resolved %.2f %%/yr  (total %d stems)\n",
    mean(obs_dec$stem_mort_pctyr_grm, na.rm=TRUE), sum(obs_dec$n_mort_tree)))
cat(sprintf("  STAND_METRICS N_DEAD       %.2f %%/yr  (total %d stems)\n",
    mean(obs_dec$stem_mort_pctyr_bk, na.rm=TRUE), sum(obs_dec$n_dead_bk)))
cat(sprintf("  tree-id not relocated      %.2f %%/yr  (total %d stems) UPPER BOUND, see log note\n",
    mean(obs_dec$stem_mort_pctyr_id, na.rm=TRUE), sum(obs_dec$n_lost_id)))
cat(sprintf("  recorded removals (harvest) %d stems on %d routine plots\n",
    sum(obs_dec$n_removed_bk), sum(obs_dec$n_removed_bk>0)))

# gross PAI where the decomposition is covered
ob_pai <- byplot[model_config=="OBSERVED"]
ob_pai <- merge(ob_pai, obs_dec, by="PLOT")
ob_pai[, pai_ba_gross_m2hayr := pai_ba_m2hayr + pai_ba_mort_m2hayr]
cv <- ob_pai[grm_covered==TRUE]
cat(sprintf("\nOBSERVED BA increment, m2 ha-1 yr-1, on the %d GRM-covered routine plots:\n", nrow(cv)))
cat(sprintf("  NET (t2 minus t1 tree lists)      %+.4f\n", mean(cv$pai_ba_m2hayr)))
cat(sprintf("  GRM survivor growth               %+.4f\n", mean(cv$pai_ba_surv_m2hayr)))
cat(sprintf("  GRM ingrowth                      %+.4f\n", mean(cv$pai_ba_ingr_m2hayr)))
cat(sprintf("  GRM mortality                     %-.4f\n", mean(cv$pai_ba_mort_m2hayr)))
cat(sprintf("  GRM net (surv + ingr - mort)      %+.4f\n", mean(cv$pai_ba_net_grm_m2hayr)))
cat(sprintf("  GROSS (net + mortality)           %+.4f\n", mean(cv$pai_ba_gross_m2hayr)))
cat(sprintf("  residual, GRM net minus tree-list net: %+.4f m2 ha-1 yr-1\n",
    mean(cv$pai_ba_net_grm_m2hayr - cv$pai_ba_m2hayr)))
cat(sprintf("  ingrowth stem cross-check: GRM tree-resolved %d stems vs STAND_METRICS TPA_INGROWTH %d stems\n",
    sum(cv$n_ingr_tree), round(sum(cv$tpa_ingr_bk)/5)))
cat("  A residual that does not close is a property of the source bookkeeping, not of this\n")
cat("  script. It is reported rather than forced, and the NET increment, which comes straight\n")
cat("  from the two tree lists and needs no bookkeeping at all, is what the scorecard scores.\n")

# ============================================================================
# 8. SCORECARD
# ============================================================================
bias <- function(p,o) 100*(mean(p,na.rm=TRUE)/mean(o,na.rm=TRUE)-1)
r2 <- function(p,o){ ok<-is.finite(p)&is.finite(o); if(sum(ok)<3) return(NA_real_)
  1-sum((o[ok]-p[ok])^2)/sum((o[ok]-mean(o[ok]))^2) }
obs2 <- byplot[model_config=="OBSERVED",
  .(PLOT, o_vol=pai_gross4_cdacyr, o_bam=pai_ba_m2hayr, o_baf=pai_ba_ft2acyr,
    o_qmd=pai_qmd_inyr, o_tpa=pai_tpa_yr, o_rate=ann_stem_rate_pct, o_v2=gross4_cd_2)]

STATE <- c("AGM_v835","AGM_v836","OSM_ACD","FVS_NE_default","FVS_ACD_default",
           "FVSACD_v1211_full","FVSACD_v131_full","FVSACD_v131_ship18",
           "FVSACD_v14_L1","FVSACD_v14_L2")
LABEL <- c(AGM_v835="AGM v8.35 (byPlot)", AGM_v836="AGM v8.36 (byStrata)", OSM_ACD="OSM-ACD",
  FVS_NE_default="FVS-NE default", FVS_ACD_default="FVS-ACD default (v16-v22 vintage)",
  FVSACD_v1211_full="FVS-ACD v12.11 (full137)", FVSACD_v131_full="FVS-ACD v13.1 hierarchical (full137)",
  FVSACD_v131_ship18="FVS-ACD v13.1 ship18 (full137)", FVSACD_v14_L1="FVS-ACD v14 L1 (full137)",
  FVSACD_v14_L2="FVS-ACD v14 L2 (full137)", AGY_12.5.0="AcadianGY 12.5.0 (standalone)",
  FVS_NE_calibrated="FVS-NE calibrated", FVS_ACD_calibrated="FVS-ACD calibrated",
  AGM_v836_native="AGM v8.36 (byStrata, native table)", AGM_v840_meas="AGM v8.40 (byStrata, measured heights)",
  FVSACD_v131_hier_meas="FVS-ACD v13.1 hierarchical, measured heights", FVSACD_v131_hier_dub="FVS-ACD v13.1 hierarchical, imputed heights",
  FVSACD_v14_L1_meas="FVS-ACD v14 L1, measured heights", FVSACD_v14_L1_dub="FVS-ACD v14 L1, imputed heights",
  FVSACD_v14_L2_meas="FVS-ACD v14 L2, measured heights", FVSACD_v14_L2_dub="FVS-ACD v14 L2, imputed heights")
cfgs <- setdiff(sort(unique(byplot$model_config)), "OBSERVED")
rows <- list()
for (k in cfgs) {
  m <- merge(byplot[model_config==k], obs2, by="PLOT")
  if (nrow(m)==0) next
  rows[[k]] <- data.table(
    model = ifelse(is.na(LABEL[k]), k, LABEL[k]), config = k,
    in_state_scorecard = k %in% STATE, n = nrow(m),
    volPAI_bias  = round(bias(m$pai_gross4_cdacyr, m$o_vol),1),
    volPAI_R2    = round(r2(m$pai_gross4_cdacyr, m$o_vol),3),
    baPAI_bias   = round(bias(m$pai_ba_m2hayr, m$o_bam),1),
    baPAI_R2     = round(r2(m$pai_ba_m2hayr, m$o_bam),3),
    qmdPAI_bias  = round(bias(m$pai_qmd_inyr, m$o_qmd),1),
    qmdPAI_R2    = round(r2(m$pai_qmd_inyr, m$o_qmd),3),
    netstem_bias = round(bias(m$pai_tpa_yr, m$o_tpa),1),
    netstem_R2   = round(r2(m$pai_tpa_yr, m$o_tpa),3),
    stemrate_bias= round(bias(m$ann_stem_rate_pct, m$o_rate),1),
    stemrate_R2  = round(r2(m$ann_stem_rate_pct, m$o_rate),3),
    mean_volPAI  = round(mean(m$pai_gross4_cdacyr),4),
    mean_baPAI   = round(mean(m$pai_ba_m2hayr),4),
    mean_qmdPAI  = round(mean(m$pai_qmd_inyr),4),
    mean_netstem = round(mean(m$pai_tpa_yr),3),
    mean_stemrate= round(mean(m$ann_stem_rate_pct),3),
    state_volume_bias = NA_real_)
}
sc <- rbindlist(rows)

om <- byplot[model_config=="OBSERVED"]
cat(sprintf("\n=== OBSERVED MEAN RATES over %d routine plots, mean interval %.1f yr ===\n",
    nrow(om), mean(psr$PERIOD_YR)))
cat(sprintf("  gross4 volume PAI   %+.4f cd ac-1 yr-1   (t1 %.2f -> t2 %.2f cd ac-1)\n",
    mean(om$pai_gross4_cdacyr), mean(om$gross4_cd_1), mean(om$gross4_cd_2)))
cat(sprintf("     height sensitivity: no plot calibration %+.4f | pooled curve %+.4f cd ac-1 yr-1\n",
    mean(om$pai_gross4_cdacyr_htB), mean(om$pai_gross4_cdacyr_htC)))
cat(sprintf("  basal area PAI      %+.4f m2 ha-1 yr-1  = %+.4f ft2 ac-1 yr-1 (t1 %.2f -> t2 %.2f m2 ha-1)\n",
    mean(om$pai_ba_m2hayr), mean(om$pai_ba_ft2acyr), mean(om$ba_m2ha_1), mean(om$ba_m2ha_2)))
cat(sprintf("  QMD PAI             %+.4f in yr-1        (t1 %.2f -> t2 %.2f in)\n",
    mean(om$pai_qmd_inyr), mean(om$qmd_in_1), mean(om$qmd_in_2)))
cat(sprintf("  net stem change     %+.3f TPA yr-1       (t1 %.1f -> t2 %.1f TPA), %+.3f %% yr-1 compound\n",
    mean(om$pai_tpa_yr), mean(om$tpa_1), mean(om$tpa_2), mean(om$ann_stem_rate_pct)))
cat("\n  observed plot-level spread, which is what the Nash-Sutcliffe denominator sees:\n")
qq <- function(x) paste(sprintf("%+.3f", quantile(x, c(0,.25,.5,.75,1))), collapse="  ")
cat(sprintf("    volume PAI  min/Q1/med/Q3/max  %s  (sd %.3f)\n", qq(om$pai_gross4_cdacyr), sd(om$pai_gross4_cdacyr)))
cat(sprintf("    BA PAI      min/Q1/med/Q3/max  %s  (sd %.3f)\n", qq(om$pai_ba_m2hayr), sd(om$pai_ba_m2hayr)))
cat(sprintf("    QMD PAI     min/Q1/med/Q3/max  %s  (sd %.3f)\n", qq(om$pai_qmd_inyr), sd(om$pai_qmd_inyr)))
cat(sprintf("    net stems   min/Q1/med/Q3/max  %s  (sd %.3f)\n", qq(om$pai_tpa_yr), sd(om$pai_tpa_yr)))
cat("  Plot-level increment on a 1/5 acre CFI plot is a small difference between two large\n")
cat("  numbers, so its variance is dominated by tally noise. A negative Nash-Sutcliffe on this\n")
cat("  axis therefore says the model does not beat the observed mean plot by plot, which is a\n")
cat("  weaker claim than it sounds, while the bias column, which is a ratio of means, is the\n")
cat("  part of this scorecard that carries the weight.\n")

# ============================================================================
# 9. RANK CONTRAST, RATES AXIS AGAINST STATE AXIS
# ============================================================================
stf <- file.path("/users/PUOM0008/crsfaaron/silc_cfi/v29_run",
                 "silc_cfi_v29_scorecard_primary_DATA_2026-09-08.csv")
if (file.exists(stf)) {
  stsc <- as.data.table(read.csv(stf, stringsAsFactors=FALSE))
  stsc[, config := names(LABEL)[match(model, LABEL)]]
  cmp <- merge(sc, stsc[, .(config, state_gross4_bias=gross4_bias, state_gross4_R2=gross4_R2)],
               by="config", all.x=TRUE)
  # Ranks are computed WITHIN the ten configurations the state scorecard carries, so the two
  # ladders have the same rungs. Ranking the rate axis over all thirteen and the state axis
  # over ten would manufacture shifts out of the three extra rows.
  cmp[, `:=`(rank_state_bias = NA_real_, rank_rate_bias = NA_real_,
             rank_state_R2 = NA_real_, rank_rate_R2 = NA_real_)]
  cmp[in_state_scorecard==TRUE, `:=`(
    rank_state_bias = rank(abs(state_gross4_bias), na.last="keep"),
    rank_rate_bias  = rank(abs(volPAI_bias), na.last="keep"),
    rank_state_R2   = rank(-state_gross4_R2, na.last="keep"),
    rank_rate_R2    = rank(-volPAI_R2, na.last="keep"))]
  cmp[, `:=`(shift_bias = rank_rate_bias - rank_state_bias,
             shift_R2   = rank_rate_R2  - rank_state_R2)]
  cat("\n=== RANK CONTRAST: t2 STATE (gross4 standing volume) vs RATE (gross4 volume PAI) ===\n")
  cat("   positive shift = ranks WORSE on rates than on state\n")
  print(as.data.frame(cmp[in_state_scorecard==TRUE][order(rank_rate_bias),
    .(model, state_bias=state_gross4_bias, rate_bias=volPAI_bias,
      rk_state=rank_state_bias, rk_rate=rank_rate_bias, shift_bias,
      state_R2=state_gross4_R2, rate_R2=volPAI_R2,
      rkR2_state=rank_state_R2, rkR2_rate=rank_rate_R2, shift_R2)]),
    row.names=FALSE)
  sc <- merge(sc, cmp[, .(config, state_gross4_bias, state_gross4_R2,
                          rank_state_bias, rank_rate_bias, shift_bias,
                          rank_state_R2, rank_rate_R2, shift_R2)], by="config", all.x=TRUE)
  sc[, state_volume_bias := NULL]
} else cat("\nSTATE SCORECARD NOT FOUND at", stf, "-- rank contrast skipped.\n")

cat("\n=== RATES SCORECARD ===\n")
print(as.data.frame(sc[order(abs(volPAI_bias)),
  .(model, n, volPAI_bias, volPAI_R2, baPAI_bias, baPAI_R2, qmdPAI_bias, qmdPAI_R2,
    netstem_bias, netstem_R2, mean_volPAI, mean_baPAI)]), row.names=FALSE)

# ============================================================================
# 10. MAI VERDICT
# ============================================================================
cat("\n=== MAI VERDICT ===\n")
age_cols <- function(f){ h <- names(fread(f, nrows=1)); grep("AGE|STDAGE|BHAGE|SICOND", h, value=TRUE, ignore.case=TRUE) }
for (f in c("STAND_METRICS.csv","STAND_PAI.csv","PLOT.csv","COND.csv")) {
  p <- file.path(TAB, f)
  if (file.exists(p)) cat(sprintf("  %-20s age-like columns: %s\n", f,
    ifelse(length(age_cols(p))==0, "NONE", paste(age_cols(p), collapse=","))))
  else cat(sprintf("  %-20s not staged on Cardinal; inspected on the source side instead\n", f))
}
# is there a recoverable stand origin year on the routine plots?
pcv <- file.path(TAB, "PLOT.csv"); ccv <- file.path(TAB, "COND.csv")
if (file.exists(pcv) && file.exists(ccv)) {
  pl <- as.data.table(fread(pcv)); cd <- as.data.table(fread(ccv))
  plr <- pl[PLOT %in% routine]; cdr <- cd[PLOT %in% routine]
  cat(sprintf("  routine plots with a nonzero PLOT.DSTRBYR1 disturbance year: %d of %d\n",
      uniqueN(plr[is.finite(DSTRBYR1) & DSTRBYR1 > 0]$PLOT), length(routine)))
  cat(sprintf("  routine plots with a nonzero COND.TRTYR1 treatment year:     %d of %d\n",
      uniqueN(cdr[is.finite(TRTYR1) & TRTYR1 > 0]$PLOT), length(routine)))
  cat("  Neither field is a stand origin. A disturbance or treatment year records that something\n")
  cat("  happened, not that the stand started then, and on a partially cut uneven-aged plot the\n")
  cat("  residual cohort predates it. Using either as an age would manufacture a number.\n")
}
cat(sprintf("  %-20s age-like columns: %s\n", "pairs v16",
  ifelse(length(grep("AGE", names(ps), value=TRUE, ignore.case=TRUE))==0, "NONE",
         paste(grep("AGE", names(ps), value=TRUE, ignore.case=TRUE), collapse=","))))
cat("  PLOT.csv and COND.csv were inspected on the source side and carry no STDAGE, no BHAGE,\n")
cat("  and no SICOND. CSIZE and STDSZCD are size classes, not ages.\n")
cat("  VERDICT: mean annual increment is NOT COMPUTABLE on this benchmark. MAI is volume\n")
cat("  divided by total stand age, and no stand age exists anywhere in the SILC CFI tables.\n")
cat("  These are uneven-aged, multi-cohort spruce-fir CFI plots, so even a recovered age would\n")
cat("  not carry the meaning MAI needs, since MAI presumes a single cohort dated from one origin.\n")
cat("  Nothing was substituted. Breast-height age and a site-index-inverted age were both\n")
cat("  available in principle and both were rejected, since neither is total stand age and\n")
cat("  neither is measured here. What an MAI axis would need: a total-age field on each plot,\n")
cat("  or an even-aged subset with a known origin year, neither of which this dataset has.\n")
cat("  PAI is therefore the whole of the rate axis, which is the correct choice for uneven-aged\n")
cat("  management anyway, as the management question is periodic yield, not rotation-age yield.\n")

# ============================================================================
# 11. WRITE
# ============================================================================
byplot <- merge(byplot, obs_dec[, .(PLOT, grm_covered, n_surv_tree, n_mort_tree, n_ingr_tree,
  n_unknown_tree, pai_ba_surv_m2hayr, pai_ba_mort_m2hayr, pai_ba_ingr_m2hayr,
  pai_ba_net_grm_m2hayr, n_dead_bk, n_removed_bk, tpa_ingr_bk, n1_id, n2_id, n_surv_id,
  n_lost_id, n_new_id, stem_mort_pctyr_grm, stem_mort_pctyr_bk, stem_mort_pctyr_id)],
  by="PLOT", all.x=TRUE)
byplot[model_config!="OBSERVED", `:=`(
  pai_ba_surv_m2hayr=NA_real_, pai_ba_mort_m2hayr=NA_real_, pai_ba_ingr_m2hayr=NA_real_,
  pai_ba_net_grm_m2hayr=NA_real_, stem_mort_pctyr_grm=NA_real_, stem_mort_pctyr_bk=NA_real_,
  stem_mort_pctyr_id=NA_real_)]
omref <- data.table(config="OBSERVED", model="OBSERVED (reference)", in_state_scorecard=FALSE,
  n=nrow(om), volPAI_bias=NA_real_, volPAI_R2=NA_real_, baPAI_bias=NA_real_, baPAI_R2=NA_real_,
  qmdPAI_bias=NA_real_, qmdPAI_R2=NA_real_, netstem_bias=NA_real_, netstem_R2=NA_real_,
  stemrate_bias=NA_real_, stemrate_R2=NA_real_,
  mean_volPAI=round(mean(om$pai_gross4_cdacyr),4), mean_baPAI=round(mean(om$pai_ba_m2hayr),4),
  mean_qmdPAI=round(mean(om$pai_qmd_inyr),4), mean_netstem=round(mean(om$pai_tpa_yr),3),
  mean_stemrate=round(mean(om$ann_stem_rate_pct),3))
sc <- rbindlist(list(sc, omref), use.names=TRUE, fill=TRUE)
setorder(byplot, model_config, PLOT)
write.csv(byplot, file.path(OUT, "silc_cfi_rates_byplot_v32ht_DATA_2026-09-23.csv"), row.names=FALSE)
write.csv(sc,     file.path(OUT, "silc_cfi_rates_scorecard_v32ht_DATA_2026-09-23.csv"), row.names=FALSE)
cat(sprintf("\nWrote byplot (%d rows) and scorecard (%d rows) to %s\n", nrow(byplot), nrow(sc), OUT))

cat("\n=== WHAT THIS AXIS CANNOT DO, STATED PLAINLY ===\n")
cat("1. No model can be scored on mortality or on ingrowth. The unified treelist carries\n")
cat("   model_config, PLOT, YEAR, sp, dbh_cm, ht_m and expf_tph, and no tree identifier and no\n")
cat("   status code, so a stand-level change in stems per acre cannot be split between a tree\n")
cat("   that died and a tree that grew past the 4.5 in tally threshold. Net stem change and the\n")
cat("   compound annual stem rate are scored instead, and QMD PAI is scored alongside them,\n")
cat("   since the two together constrain the mortality and ingrowth mix without resolving it.\n")
cat("   Fixing this needs each model's own treelist to retain a tree id and a status code.\n")
cat("2. The observed decomposition itself is not clean. The GRM bookkeeping and the\n")
cat("   STAND_METRICS N_DEAD field agree with each other on roughly a hundred dead stems across\n")
cat("   the routine plots, while direct tree-identity matching between the two measurement years\n")
cat("   leaves several hundred t1 stems unrelocated with no death record of any kind. Tree\n")
cat("   numbers are evidently reused or reassigned between occasions, so identity matching is an\n")
cat("   upper bound on mortality and not a measurement of it. Both accountings are carried in\n")
cat("   the by-plot file and neither is presented as the single truth.\n")
cat("3. Recorded harvest removals exist on a small number of routine plots and no model was\n")
cat("   told about them, so those plots charge the models for a change they could not predict.\n")
cat(sprintf("\nDONE in %.1f min\n", as.numeric(difftime(Sys.time(), t0, units="mins"))))

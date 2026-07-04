## FVS-ACD v13.1 GROWTH-SCALE hierarchical management fit (go/no-go, lmer)
## Response: stand-level annual basal-area increment (gross survivor + net) and survivor dbh increment.
## Grouping mirrors the mortality design exactly (region/eco/fortype/mgmt) so results are comparable.
## Tests: (a) pooled management growth release by class + region-slope heterogeneity,
##        (b) leave-one-region-out transfer of a partially pooled release vs a capped constant,
##        (c) whether region/composition REs separate the NB-growing / QC-mature tails.
## MagPlot is not in FIA (out by construction); recent-FIA proxy held out. Aggregates only; no coordinates.
suppressPackageStartupMessages({library(data.table); library(lme4)})
set.seed(20260704); OUT <- path.expand("~/v13_kickoff"); dir.create(OUT, showWarnings=FALSE)
PAIRS <- "/users/PUOM0008/crsfaaron/fvs-conus/calibration/data/conus_remeasurement_pairs_metric_cond_v2.rds"
t0 <- Sys.time(); cat("== v13.1 GROWTH assembly ==\n")
d <- as.data.table(readRDS(PAIRS)); cat("rows:", nrow(d), "\n")

## survivors with valid diameters (gross growth); keep t1>=2.54 cm as in mortality assembly
d <- d[TREESTATUS1==1 & is.finite(TPA1) & TPA1>0 & is.finite(YEARS) & YEARS>=1 & YEARS<=20 &
       is.finite(DBH1) & DBH1>=2.54]
d[, stand_key := paste(PLT_CN_cond1, CONDID_cond1, INVYR1, INVYR2, sep="_")]
## tree basal area in m2 from cm dbh
baT <- function(dbh_cm) (pi/4) * (dbh_cm/100)^2
d[, surv := as.integer(TREESTATUS2==1 & is.finite(DBH2))]
d[, gtree := fifelse(surv==1, TPH1 * (baT(DBH2) - baT(DBH1)), 0)]   # m2/ha survivor BA increment contribution
d[, dtree := fifelse(surv==1, (DBH2 - DBH1)/YEARS, NA_real_)]        # annual dbh increment, survivors

g <- d[, .(YEARS = YEARS[1],
   ba1 = BA1[1], ba2 = BA2[1], qmd1 = QMD1[1],
   sdi_add = weighted.mean(sdi_additive1, TPA1, na.rm=TRUE),
   sdimax  = weighted.mean(SDImax_brms,   TPA1, na.rm=TRUE),
   rd_row  = weighted.mean(rd_add,        TPA1, na.rm=TRUE),
   gross_ba_ann = sum(gtree, na.rm=TRUE) / YEARS[1],                 # gross survivor BA incr, m2/ha/yr
   dq_ann = weighted.mean(dtree, TPH1, na.rm=TRUE),                  # TPH-weighted survivor dbh incr, cm/yr
   n_surv = sum(surv), n_t1 = .N,
   yst = suppressWarnings(min(years_since_trt, na.rm=TRUE)),
   STATE = STATECD[1], ORG = STDORGCD_cond1[1], TRT = TRTCD1_cond1[1], FOR = FORTYPCD[1],
   L1 = as.character(EPA_L1_CODE[1]), L2 = as.character(EPA_L2_CODE[1]), L3 = as.character(EPA_L3_CODE[1]),
   INVYR2 = INVYR2[1]), by = stand_key]
rm(d); gc()

g[, net_ba_ann := (ba2 - ba1) / YEARS]
g[, rd := ifelse(is.finite(sdi_add) & is.finite(sdimax) & sdimax>0, sdi_add/sdimax, rd_row)]
g <- g[is.finite(rd) & rd>0 & rd<2 & is.finite(qmd1) & qmd1>0 & is.finite(ba1) &
       is.finite(gross_ba_ann) & is.finite(net_ba_ann) & n_surv>=1]
g[, ln_qmd := log(qmd1)][, ba := ba1]

## management class: identical logic to the mortality assembly
g[, planted := as.integer(is.finite(ORG) & ORG==1)]
g[, treated := as.integer((is.finite(TRT) & TRT>0) | (is.finite(yst) & yst>=0 & yst<40))]
g[, mgmt := ifelse(planted==1, "planted", ifelse(treated==1, "treated", "none"))]
g[, region := as.character(STATE)][is.na(region)|region=="NA", region := L1]
g[, eco := fifelse(!is.na(L3)&L3!="NA", L3, fifelse(!is.na(L2)&L2!="NA", L2, L1))]
g[, fortype := as.character(FOR)][is.na(fortype), fortype := "unk"]
g <- g[!is.na(region) & region!="NA" & !is.na(eco) & eco!="NA"]

## winsorize growth responses to kill measurement-error tails (per year)
wz <- function(x, lo, hi) pmin(pmax(x, lo), hi)
g[, gross_ba_ann := wz(gross_ba_ann, -0.5, 3.0)]
g[, net_ba_ann   := wz(net_ba_ann,   -3.0, 3.0)]
g[, dq_ann       := wz(dq_ann,       -0.25, 2.5)]

## recent-FIA holdout proxy: most recent inventory decile per region held out
g[, recent := as.integer(INVYR2 >= quantile(INVYR2, 0.9, na.rm=TRUE)), by=region]
gf <- g[recent==0]

## design-matrix summaries
dm <- g[, .(n=.N, gross=round(mean(gross_ba_ann),4), net=round(mean(net_ba_ann),4),
            dq=round(mean(dq_ann),4)), by=mgmt][order(mgmt)]
cat("=== GROWTH design matrix by mgmt (m2/ha/yr, cm/yr) ===\n"); print(dm)
fwrite(dm, file.path(OUT, "v131g_designmatrix_bymgmt.csv"))
fwrite(data.table(metric=c("n_all","n_fit","n_heldout","n_region","n_eco","n_fortype",
   "n_planted","n_treated","n_none"),
   value=c(nrow(g), nrow(gf), nrow(g)-nrow(gf), uniqueN(g$region), uniqueN(g$eco), uniqueN(g$fortype),
   sum(g$mgmt=="planted"), sum(g$mgmt=="treated"), sum(g$mgmt=="none"))),
   file.path(OUT, "v131g_designmatrix_summary.csv"))
saveRDS(gf, file.path(OUT, "v131g_fitset.rds"))
cat("regions:", uniqueN(g$region), " eco:", uniqueN(g$eco), " fortype:", uniqueN(g$fortype),
    " fit:", nrow(gf), " heldout:", nrow(g)-nrow(gf), "\n"); flush.console()

## subsample for the go/no-go: all managed + 90k background (mirrors mortality go/no-go)
ev <- gf[mgmt!="none"]; bg <- gf[mgmt=="none"]
nb <- min(nrow(bg), 90000)
ds <- rbind(ev, bg[sample(.N, nb)])
ds[, mgmt := factor(mgmt, levels=c("none","treated","planted"))]
ds[, mgd := as.integer(mgmt!="none")]
ds[, region := factor(region)][, eco := factor(eco)][, fortype := factor(fortype)]
cat("fit sample:", nrow(ds), " managed:", nrow(ev), " background:", nb, "\n")

fitG <- function(resp){
  cat("\n########## RESPONSE:", resp, "##########\n")
  ds[, y := ds[[resp]]]
  ## capped-constant analog: mgmt global fixed effect, minimal RE
  mC <- lmer(y ~ rd + ln_qmd + ba + mgmt + (1|eco), data=ds, REML=FALSE,
             control=lmerControl(optimizer="bobyqa"))
  ## hierarchical: crossed intercepts + region random slope on management
  mH <- lmer(y ~ rd + ln_qmd + ba + mgmt + (1|region) + (1|eco) + (1|fortype) + (0+mgd|region),
             data=ds, REML=FALSE, control=lmerControl(optimizer="bobyqa"))
  fe <- as.data.table(summary(mH)$coefficients, keep.rownames="term")
  cat("--- Model H fixed effects ---\n"); print(round(as.matrix(fe[,-1,with=FALSE]),4)); print(fe$term)
  vc <- as.data.table(VarCorr(mH)); vc <- vc[, .(grp, var1, sdcor=round(sdcor,4))]
  cat("--- variance components (RE sd) ---\n"); print(vc)
  cat("AIC C(capped):", round(AIC(mC),0), " H(hier):", round(AIC(mH),0),
      " dAIC:", round(AIC(mC)-AIC(mH),0), "\n")
  fwrite(fe, file.path(OUT, paste0("v131g_fixef_", resp, ".csv")))
  fwrite(vc, file.path(OUT, paste0("v131g_varcomp_", resp, ".csv")))
  fwrite(data.table(resp=resp, AIC_capped=AIC(mC), AIC_hier=AIC(mH), dAIC=AIC(mC)-AIC(mH)),
         file.path(OUT, paste0("v131g_aic_", resp, ".csv")))
  invisible(list(mC=mC, mH=mH))
}
fits_gross <- fitG("gross_ba_ann")
fits_net   <- fitG("net_ba_ann")
fits_dq    <- fitG("dq_ann")

## ---- leave-one-region-out transfer: pooled(hier) vs capped, on gross_ba_ann (primary) ----
ds[, y := gross_ba_ann]
regs <- ds[, .N, by=region][N>1500][order(-N)]$region; regs <- head(as.character(regs), 6)
loro <- list()
for(rg in regs){
  tr <- ds[region!=rg]; te <- ds[region==rg]
  fc <- tryCatch(lmer(y ~ rd+ln_qmd+ba+mgmt+(1|eco), data=tr, REML=FALSE,
                      control=lmerControl(optimizer="bobyqa")), error=function(e) NULL)
  fh <- tryCatch(lmer(y ~ rd+ln_qmd+ba+mgmt+(1|region)+(1|eco)+(0+mgd|region), data=tr, REML=FALSE,
                      control=lmerControl(optimizer="bobyqa")), error=function(e) NULL)
  if(is.null(fc)|is.null(fh)) next
  pc <- predict(fc, te, re.form=~(1|eco), allow.new.levels=TRUE)
  ph <- predict(fh, te, re.form=~(1|eco), allow.new.levels=TRUE)   # held-out region -> shrink to pooled mean
  mi <- te$mgmt!="none"
  loro[[rg]] <- data.table(region=rg, n_mgd=sum(mi),
     capped_MAE=round(mean(abs(pc[mi]-te$y[mi])),4),
     hier_MAE  =round(mean(abs(ph[mi]-te$y[mi])),4))
}
LO <- rbindlist(loro)
cat("\n=== LEAVE-ONE-REGION-OUT managed gross-BA-increment transfer (MAE, lower=better) ===\n"); print(LO)
if(nrow(LO)){ LO[, pooled_wins := hier_MAE < capped_MAE]; fwrite(LO, file.path(OUT, "v131g_loro_transfer.csv"))
  cat("pooled wins:", sum(LO$pooled_wins), "of", nrow(LO), "\n") }
cat("fit time:", round(difftime(Sys.time(), t0, units="mins"),1), "min\n")
cat("V131G_DONE\n")

## Maine FIA GRM growth/mortality fit for 8 hardwood species + OH pool, form/risk crosswalk covariate.
## New analysis (26 Aug 2026), beyond Castle (2017/2018) and Smith (2022): those are CFRU/NHRI-network
## and value-model based; this is a Maine-statewide FIA GRM remeasurement fit using the FIA field-call
## crosswalk (TREECLCD/TREEGRCD/CULL_FLD/DAMAGE_AGENT_CD1-3), independent of both.
##
## Crosswalk logic reused VERBATIM from magplot/verify/formrisk_crosswalk/apply_formrisk_crosswalk.R's
## cw() function (the same one behind bench_mefia_fr_tree_{init,t2}.csv, 98%/100% coverage), not
## re-derived, so this stays consistent with prior form/risk work in this codebase.
##
## Form/risk covariates are read from the tree's BEGIN-of-interval record (via PREV_TRE_CN into
## ME_TREE.csv), never the end-of-interval record, so a dying tree's terminal condition never leaks
## into the predictor for its own mortality/growth.
suppressMessages({ library(data.table); library(glmmTMB); library(broom.mixed) })
set.seed(42)

FIA <- "/users/PUOM0008/crsfaaron/fia_data"
OUT <- "/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
LOG <- function(...) cat(sprintf(...), "\n")

## ---- species crosswalk, verified against REF_SPECIES.csv 26 Aug 2026 (not from memory) ----
SPCD_MAP <- c(`316`="RM", `318`="SM", `371`="YB", `375`="PB", `531`="AB", `541`="WA", `746`="QA", `833`="RO")

LOG("Loading FIA tables...")
tr  <- fread(file.path(FIA, "ME_TREE.csv"))
grm <- fread(file.path(FIA, "ME_TREE_GRM_COMPONENT.csv"))
pl  <- fread(file.path(FIA, "ME_PLOT.csv"))
LOG("ME_TREE %d rows, GRM_COMPONENT %d rows, ME_PLOT %d rows", nrow(tr), nrow(grm), nrow(pl))

tr  <- tr[STATECD == 23]
grm <- grm[STATECD == 23]
pl  <- pl[STATECD == 23]

## ---- form/risk crosswalk, verbatim from apply_formrisk_crosswalk.R ----
dis <- function(x) is.finite(x) & x >= 20000 & x < 30000
cw <- function(spcd, tc, gr, cf, dmg1, dmg2, dmg3) {
  hw <- is.finite(spcd) & spcd >= 300
  form <- rep(NA_character_, length(spcd)); risk <- rep(NA_character_, length(spcd))
  decay_dmg <- dis(dmg1) | dis(dmg2) | dis(dmg3)
  i <- hw & tc == 3;                      form[i] <- "F2"
  i <- hw & tc == 2 & gr %in% c(1,2);     form[i] <- "F1"
  i <- hw & tc == 2 & gr %in% c(4,5);     form[i] <- "F2"
  i <- hw & tc == 2 & gr == 3;            form[i] <- "F1"
  i <- hw & tc == 2 & is.na(gr);          form[i] <- "F1"
  i <- hw & tc == 4 & gr %in% c(1,2);     form[i] <- "F1"
  i <- hw & tc == 4 & gr %in% c(3,4,5);   form[i] <- "F2"
  i <- hw & tc == 4;                                              risk[i] <- "R3"
  i <- hw & tc != 4 & is.finite(cf) & cf > 20;                    risk[i] <- "R3"
  i <- hw & tc != 4 & is.na(risk) & ((is.finite(cf) & cf > 5 & cf <= 20) | decay_dmg); risk[i] <- "R2"
  i <- hw & tc %in% c(2,3) & is.na(risk) & ((is.finite(cf) & cf <= 5) | is.na(cf)) & !decay_dmg; risk[i] <- "R1"
  list(form = form, risk = risk)
}

tr[, gr := as.integer(ifelse(is.na(TREEGRCD) | TREEGRCD == "", TREE_GRADE_NCRS, TREEGRCD))]
fr <- cw(tr$SPCD, as.integer(tr$TREECLCD), tr$gr, as.numeric(tr$CULL_FLD),
         as.numeric(tr$DAMAGE_AGENT_CD1), as.numeric(tr$DAMAGE_AGENT_CD2), as.numeric(tr$DAMAGE_AGENT_CD3))
tr[, `:=`(form_begin = fr$form, risk_begin = fr$risk)]
tr_begin <- tr[, .(CN, SPCD_begin = SPCD, STATUSCD_begin = STATUSCD, DIA_begin_chk = DIA,
                    form_begin, risk_begin)]

LOG("Coverage of the crosswalk on hardwood rows in ME_TREE: form %.2f%%, risk %.2f%%",
    100*mean(!is.na(tr[SPCD>=300]$form_begin)), 100*mean(!is.na(tr[SPCD>=300]$risk_begin)))

## ---- attach begin-of-interval attributes to the GRM record via PREV_TRE_CN ----
grm2 <- merge(grm, tr_begin, by.x = "PREV_TRE_CN", by.y = "CN", all.x = TRUE)
LOG("GRM rows with a resolvable PREV_TRE_CN in ME_TREE: %d of %d", sum(!is.na(grm2$SPCD_begin)), nrow(grm2))

## ---- REMPER from the current plot visit ----
pl_remper <- pl[, .(PLT_CN = CN, REMPER)]
grm2 <- merge(grm2, pl_remper, by = "PLT_CN", all.x = TRUE)

## ---- component classification (all-live basis) ----
compcol <- "SUBP_COMPONENT_AL_FOREST"
stopifnot(compcol %in% names(grm2))
setnames(grm2, compcol, "COMPONENT")

## ---- filter to analysis population ----
grm2[, SP := SPCD_MAP[as.character(SPCD_begin)]]
grm2[is.na(SP) & is.finite(SPCD_begin) & SPCD_begin >= 300, SP := "OH"]
d <- grm2[!is.na(SP) & !is.na(form_begin) & !is.na(risk_begin) &
          is.finite(DIA_BEGIN) & DIA_BEGIN >= 5.0 &
          is.finite(REMPER) & REMPER > 0 &
          COMPONENT %in% c("SURVIVOR","MORTALITY1","MORTALITY2")]
LOG("Analysis population after filters: %d rows (of %d GRM rows)", nrow(d), nrow(grm2))
LOG("Species counts:"); print(table(d$SP))
LOG("Form counts:"); print(table(d$form_begin))
LOG("Risk counts:"); print(table(d$risk_begin))
LOG("Component counts:"); print(table(d$COMPONENT))

d[, MORT := as.integer(COMPONENT %in% c("MORTALITY1","MORTALITY2"))]
d[, SP := factor(SP, levels = c("RM","SM","YB","PB","AB","WA","QA","RO","OH"))]
d[, form_begin := factor(form_begin, levels = c("F1","F2"))]
d[, risk_begin := factor(risk_begin, levels = c("R1","R2","R3"))]

fwrite(d, file.path(OUT, "grm_formrisk_analysis_population_2026-08-26.csv"))

## ---- data validity screen ----
tab <- d[, .(n = .N, n_mort = sum(MORT), mort_rate = mean(MORT),
             mean_ann_growth_survivor = mean(ANN_DIA_GROWTH[COMPONENT=="SURVIVOR"], na.rm=TRUE),
             n_plots = uniqueN(PLT_CN)),
         by = .(SP, form_begin, risk_begin)]
setorder(tab, SP, form_begin, risk_begin)
fwrite(tab, file.path(OUT, "p_formrisk_grm_validity_screen_2026-08-26.csv"))
LOG("Validity screen written, %d species x form x risk cells", nrow(tab))
LOG("Cells with n < 30: %d", sum(tab$n < 30))
print(tab)

## ---- growth model: survivors only, Gamma GLMM, log link, plot random intercept ----
g <- d[COMPONENT == "SURVIVOR" & is.finite(ANN_DIA_GROWTH) & ANN_DIA_GROWTH > 0]
LOG("Growth model n = %d (dropped %d non-positive/NA ANN_DIA_GROWTH survivors, %.2f%% of survivors)",
    nrow(g), sum(d$COMPONENT=="SURVIVOR") - nrow(g),
    100*(sum(d$COMPONENT=="SURVIVOR") - nrow(g))/sum(d$COMPONENT=="SURVIVOR"))

fit_growth <- glmmTMB(ANN_DIA_GROWTH ~ SP * form_begin + SP * risk_begin + log(DIA_BEGIN) + (1 | PLT_CN),
                      family = Gamma(link = "log"), data = g)
saveRDS(fit_growth, file.path(OUT, "fit_growth_gamma_glmmTMB.rds"))
gt <- broom.mixed::tidy(fit_growth, effects = "fixed", conf.int = TRUE)
fwrite(gt, file.path(OUT, "growth_model_coefficients_2026-08-26.csv"))
LOG("=== GROWTH MODEL, fixed effects ==="); print(gt)
LOG("Growth model convergence: %s", fit_growth$sdr$pdHess)

## ---- mortality model: binomial GLMM, cloglog link, log(REMPER) offset, plot random intercept ----
fit_mort <- glmmTMB(MORT ~ SP * form_begin + SP * risk_begin + DIA_BEGIN + offset(log(REMPER)) + (1 | PLT_CN),
                   family = binomial(link = "cloglog"), data = d)
saveRDS(fit_mort, file.path(OUT, "fit_mortality_binomial_glmmTMB.rds"))
mt <- broom.mixed::tidy(fit_mort, effects = "fixed", conf.int = TRUE)
fwrite(mt, file.path(OUT, "mortality_model_coefficients_2026-08-26.csv"))
LOG("=== MORTALITY MODEL, fixed effects ==="); print(mt)
LOG("Mortality model convergence: %s", fit_mort$sdr$pdHess)

LOG("DONE_GRM_FORMRISK_FIT")

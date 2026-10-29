## Stage 1: inventory the GRM analysis population for sugar maple (Acer saccharum Marshall)
## and test whether density covariates (plot BA, BAL) can be derived from the begin-of-interval
## FIA record. Writes an SM analysis frame to disk for the stage 2 fit.
## Aaron Weiskittel / CRSF, 26 August 2026.

suppressMessages({ library(data.table) })
set.seed(42)

FIA  <- "/users/PUOM0008/crsfaaron/fia_data"
POP  <- "/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/grm_formrisk_analysis_population_2026-08-26.csv"
OUT  <- "/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/sm_refit"
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
LOG <- function(...) { cat(sprintf(...), "\n"); flush.console() }

LOG("=== STAGE 1: SM GRM population inventory ===")
d <- fread(POP)
LOG("Full analysis population: %d rows, %d cols, %d plots", nrow(d), ncol(d), uniqueN(d$PLT_CN))

## ---------- 1. Column inventory: what is actually populated, overall and for SM ----------
sm <- d[SP == "SM"]
LOG("SM rows: %d on %d plots; deaths %d (%.3f%% of SM rows)",
    nrow(sm), uniqueN(sm$PLT_CN), sum(sm$MORT), 100*mean(sm$MORT))

## row-count reconciliation against the prior write-up's claimed n
LOG("RECONCILIATION: population rows %d, distinct PLT_CN %d, COMPONENT table below",
    nrow(d), uniqueN(d$PLT_CN))
print(table(d$COMPONENT, useNA = "ifany"))
LOG("rows with any NA in the mortality model frame columns: %d",
    sum(!complete.cases(d[, .(MORT, SP, form_begin, risk_begin, DIA_BEGIN, REMPER, PLT_CN)])))

nonmiss <- function(x) {
  if (is.character(x)) sum(!is.na(x) & x != "") else sum(!is.na(x))
}
inv <- data.table(column = names(d))
inv[, class_all := sapply(d, function(x) class(x)[1])]
inv[, n_nonmiss_SM := sapply(names(d), function(cn) nonmiss(sm[[cn]]))]
inv[, pct_nonmiss_SM := round(100 * n_nonmiss_SM / nrow(sm), 2)]
inv[, n_distinct_SM := sapply(names(d), function(cn) uniqueN(sm[[cn]]))]
fwrite(inv, file.path(OUT, "sm_column_inventory.csv"))
LOG("--- columns populated for SM (>0 pct non-missing) ---")
print(inv[pct_nonmiss_SM > 0][order(-pct_nonmiss_SM)][, .(column, class_all, pct_nonmiss_SM, n_distinct_SM)],
      nrows = 200)
LOG("--- columns EMPTY for SM ---")
print(inv[pct_nonmiss_SM == 0]$column)

## ---------- 2. Units check on DIA_BEGIN (write-up claimed 5.0 cm; FIA DIA is inches) ----------
LOG("--- DIA_BEGIN distribution, all species ---")
print(summary(d$DIA_BEGIN))
LOG("--- DIA_BEGIN distribution, SM ---")
print(summary(sm$DIA_BEGIN))
LOG("DIA_BEGIN quantiles SM: %s",
    paste(sprintf("%.2f", quantile(sm$DIA_BEGIN, c(0,.01,.05,.25,.5,.75,.95,.99,1), na.rm=TRUE)), collapse=", "))
LOG("--- DIA_begin_chk (ME_TREE.DIA at begin) vs DIA_BEGIN, SM ---")
print(summary(sm$DIA_begin_chk))
LOG("corr(DIA_BEGIN, DIA_begin_chk) = %.5f", cor(sm$DIA_BEGIN, sm$DIA_begin_chk, use="complete.obs"))
LOG("--- REMPER, SM ---"); print(summary(sm$REMPER))
LOG("--- ANN_DIA_GROWTH, SM survivors ---")
print(summary(sm[COMPONENT=="SURVIVOR"]$ANN_DIA_GROWTH))

## ---------- 3. form x risk cells for SM ----------
cells <- sm[, .(n = .N, n_plots = uniqueN(PLT_CN), n_mort = sum(MORT),
                mort_rate = mean(MORT),
                mean_remper = mean(REMPER),
                mean_dia_begin = mean(DIA_BEGIN)),
            by = .(form_begin, risk_begin)][order(form_begin, risk_begin)]
cells[, ann_mort_rate := 1 - (1 - mort_rate)^(1/mean_remper)]
LOG("--- SM form x risk cells ---"); print(cells)
fwrite(cells, file.path(OUT, "sm_cells_stage1.csv"))

## ---------- 4. Can we derive plot BA and BAL at begin-of-interval? ----------
LOG("=== testing derivation of begin-of-interval density covariates ===")
tr <- fread(file.path(FIA, "ME_TREE.csv"),
            select = c("CN","PLT_CN","PREV_TRE_CN","SUBP","TREE","CONDID","STATUSCD","SPCD","DIA","TPA_UNADJ"))
tr <- tr[!is.na(PLT_CN)]
LOG("ME_TREE rows loaded: %d", nrow(tr))

## the begin-of-interval tree record is the one whose CN == GRM PREV_TRE_CN
setkey(tr, CN)
beg <- tr[J(sm$PREV_TRE_CN), .(CN, BEG_PLT_CN = PLT_CN, BEG_SUBP = SUBP, BEG_TREE = TREE,
                               BEG_CONDID = CONDID, BEG_STATUSCD = STATUSCD,
                               BEG_DIA = DIA, BEG_TPA = TPA_UNADJ)]
LOG("SM rows with a resolvable begin tree record: %d of %d (%.2f pct)",
    sum(!is.na(beg$BEG_PLT_CN)), nrow(sm), 100*mean(!is.na(beg$BEG_PLT_CN)))
sm2 <- cbind(sm, beg[, !"CN"])

## plot-level basal area at the BEGIN visit, from all live trees on that plot visit
## FIA DIA in inches, TPA_UNADJ trees/acre -> ft2/ac via 0.005454154; ft2/ac -> m2/ha via 0.2295684
FT2AC_TO_M2HA <- 0.2295684
tr[, ba_ft2ac := 0.005454154 * DIA^2 * TPA_UNADJ]
live <- tr[STATUSCD == 1 & is.finite(ba_ft2ac) & is.finite(DIA)]
plotba <- live[, .(ba_plot_m2ha = sum(ba_ft2ac) * FT2AC_TO_M2HA,
                   tph = sum(TPA_UNADJ) * 2.471054,
                   n_trees_on_plot = .N,
                   qmd_cm = sqrt(sum(DIA^2 * TPA_UNADJ)/sum(TPA_UNADJ)) * 2.54),
               by = PLT_CN]
setnames(plotba, "PLT_CN", "BEG_PLT_CN")
sm2 <- merge(sm2, plotba, by = "BEG_PLT_CN", all.x = TRUE, sort = FALSE)
LOG("SM rows with a derived begin plot basal area: %d of %d (%.2f pct)",
    sum(is.finite(sm2$ba_plot_m2ha)), nrow(sm2), 100*mean(is.finite(sm2$ba_plot_m2ha)))
LOG("--- derived begin ba_plot (m2 ha-1), SM ---"); print(summary(sm2$ba_plot_m2ha))
LOG("--- derived begin tph, SM ---"); print(summary(sm2$tph))
LOG("--- derived begin qmd (cm), SM ---"); print(summary(sm2$qmd_cm))

## BAL: basal area in larger trees on the same begin plot visit
setorder(live, PLT_CN, -DIA)
live[, bal_ft2ac := cumsum(ba_ft2ac) - ba_ft2ac, by = PLT_CN]
live[, bal_m2ha := bal_ft2ac * FT2AC_TO_M2HA]
bal <- live[, .(CN, bal_m2ha)]
setnames(bal, "CN", "PREV_TRE_CN")
sm2 <- merge(sm2, bal, by = "PREV_TRE_CN", all.x = TRUE, sort = FALSE)
LOG("SM rows with a derived begin BAL: %d of %d (%.2f pct)",
    sum(is.finite(sm2$bal_m2ha)), nrow(sm2), 100*mean(is.finite(sm2$bal_m2ha)))
LOG("--- derived begin BAL (m2 ha-1), SM ---"); print(summary(sm2$bal_m2ha))

## ---------- 5. condition-level covariates from ME_COND at the begin visit ----------
cnd <- fread(file.path(FIA, "ME_COND.csv"),
             select = c("PLT_CN","CONDID","SITECLCD","STDAGE","STDORGCD","FORTYPCD",
                        "PHYSCLCD","TRTCD1","DSTRBCD1","COND_STATUS_CD"))
setnames(cnd, c("PLT_CN","CONDID"), c("BEG_PLT_CN","BEG_CONDID"))
sm2 <- merge(sm2, cnd, by = c("BEG_PLT_CN","BEG_CONDID"), all.x = TRUE, sort = FALSE)
for (v in c("SITECLCD","STDAGE","FORTYPCD","PHYSCLCD","TRTCD1","DSTRBCD1")) {
  LOG("cond covariate %s: %.2f pct non-missing for SM, %d distinct values",
      v, 100*mean(!is.na(sm2[[v]])), uniqueN(sm2[[v]]))
}
LOG("--- SITECLCD, SM ---");  print(table(sm2$SITECLCD, useNA="ifany"))
LOG("--- STDAGE, SM ---");    print(summary(sm2$STDAGE))
LOG("--- TRTCD1, SM ---");    print(table(sm2$TRTCD1, useNA="ifany"))
LOG("--- DSTRBCD1, SM ---");  print(table(sm2$DSTRBCD1, useNA="ifany"))
LOG("--- FORTYPCD top 12, SM ---"); print(head(sort(table(sm2$FORTYPCD), decreasing=TRUE), 12))

## ---------- 6. measurement-year span ----------
try({
  cd <- as.character(sm2$CREATED_DATE); cd <- cd[!is.na(cd) & cd != ""]
  LOG("CREATED_DATE range: %s to %s", min(cd), max(cd))
}, silent = TRUE)

saveRDS(sm2, file.path(OUT, "sm_analysis_frame_stage1.rds"))
LOG("SM analysis frame saved: %d rows, %d cols", nrow(sm2), ncol(sm2))
LOG("DONE_SM_STAGE1")

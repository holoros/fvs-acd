## Stage 4: extrapolation domain for the sugar maple survival modifier, plus a compact
## characterisation of what tsurv_hw_mod actually returns on the same covariate ranges.
## Replaces the stage 2 domain block, which failed on a bad rbindlist call.
## Aaron Weiskittel / CRSF, 26 August 2026.

suppressMessages({ library(data.table) })
setDTthreads(1)
OUT  <- "/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/sm_refit"
REPO <- "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd"
LOG  <- function(...) { cat(sprintf(...), "\n"); flush.console() }

sm <- as.data.table(readRDS(file.path(OUT, "sm_analysis_frame_stage1.rds")))
sm[, `:=`(dbh_cm = DIA_BEGIN * 2.54, ba_c = ba_plot_m2ha, bal_c = bal_m2ha,
          form_begin = factor(form_begin, levels=c("F1","F2")),
          risk_begin = factor(risk_begin, levels=c("R1","R2","R3")))]
mf <- sm[is.finite(dbh_cm) & dbh_cm > 0 & is.finite(REMPER) & REMPER > 0 &
         is.finite(ba_c) & ba_c > 0 & is.finite(bal_c)]
LOG("domain computed on %d rows, %d plots", nrow(mf), uniqueN(mf$PLT_CN))

qs <- c(0, .01, .05, .25, .5, .75, .95, .99, 1)
vars <- list(dbh_begin_cm = mf$dbh_cm, REMPER_yr = mf$REMPER,
             ba_plot_m2ha = mf$ba_c, bal_m2ha = mf$bal_c,
             qmd_cm = as.numeric(mf$qmd_cm), tph_trees_ha = as.numeric(mf$tph),
             stand_age_yr = as.numeric(mf$STDAGE))
dom <- rbindlist(lapply(names(vars), function(nm) {
  v <- vars[[nm]]; v <- v[is.finite(v)]
  cbind(data.table(variable = nm, n = length(v)),
        as.data.table(as.list(round(as.numeric(quantile(v, qs)), 3))))
}))
setnames(dom, c("variable","n", sprintf("p%02.0f", 100*qs)))
LOG("--- extrapolation domain, SM survival refit ---"); print(dom)
fwrite(dom, file.path(OUT, "sm_extrapolation_domain_2026-08-26.csv"))

LOG("SITECLCD (FIA site productivity class, 1 best to 7 poorest):")
print(table(mf$SITECLCD, useNA = "ifany"))
LOG("FORTYPCD, top 10:"); print(head(sort(table(mf$FORTYPCD), decreasing = TRUE), 10))
LOG("TRTCD1 (0 none, 10 cutting, 20 site prep, 30 planting, 50 other):")
print(table(mf$TRTCD1, useNA = "ifany"))
LOG("DSTRBCD1 non-zero share: %.2f pct", 100*mean(mf$DSTRBCD1 != 0))
LOG("STATECD present: %s", paste(sort(unique(mf$STATECD)), collapse = ", "))
LOG("PHYSCLCD:"); print(table(mf$PHYSCLCD, useNA = "ifany"))

cellrange <- mf[, .(n = .N, n_deaths = sum(MORT), n_plots = uniqueN(PLT_CN),
                    dbh_p01 = round(quantile(dbh_cm, .01),1), dbh_p50 = round(quantile(dbh_cm, .50),1),
                    dbh_p99 = round(quantile(dbh_cm, .99),1), dbh_max = round(max(dbh_cm),1),
                    ba_p05 = round(quantile(ba_c, .05),1), ba_p95 = round(quantile(ba_c, .95),1),
                    bal_p05 = round(quantile(bal_c, .05),1), bal_p95 = round(quantile(bal_c, .95),1)),
                by = .(form_begin, risk_begin)][order(form_begin, risk_begin)]
LOG("--- per-cell covariate coverage ---"); print(cellrange)
fwrite(cellrange, file.path(OUT, "sm_percell_coverage_2026-08-26.csv"))

## ------------- compact characterisation of tsurv_hw_mod over the SM covariate ranges -------------
src <- file.path(REPO, "scripts", "AcadianGY_12.11.r")
L <- readLines(src)
i0 <- grep("^tsurv_hw_mod = function", L)[1]
i1 <- i0 + which(grepl("^\\}", L[(i0+1):(i0+80)]))[1]
eval(parse(text = paste(L[i0:i1], collapse = "\n")))
LOG("tsurv_hw_mod extracted verbatim, %s lines %d-%d", basename(src), i0, i1)
spp <- data.table(sp = c("QA","RM","RO","YB","PB"),
                  b0 = c(-2.7907,-3.9809,-0.7937, 5.2531, 0),
                  b1 = c( 0.0791, 0.8343, 0.8944, 0.1528, 0))
## evaluate on the observed SM covariate quantiles, so the comparison is on this population's range
gr <- CJ(sp = spp$sp,
         dbh = round(as.numeric(quantile(mf$dbh_cm, c(.05,.25,.5,.75,.95))), 1),
         bal = round(as.numeric(quantile(mf$bal_c, c(.25,.5,.75))), 1),
         ba.plot = round(as.numeric(quantile(mf$ba_c, c(.25,.5,.75))), 1),
         form = c("F1","F2"), sorted = FALSE)
gr <- merge(gr, spp, by = "sp", sort = FALSE)
gr[, tsurv_hw_mod_value := mapply(tsurv_hw_mod, dbh, bal, ba.plot, form, b0, b1)]
setorder(gr, sp, form, dbh, bal, ba.plot)
fwrite(gr, file.path(OUT, "tsurv_hw_mod_reference_grid_2026-08-26.csv"))
LOG("--- tsurv_hw_mod on the SM covariate range, by species and form ---")
print(gr[, .(n = .N, min = round(min(tsurv_hw_mod_value),4),
             median = round(median(tsurv_hw_mod_value),4),
             max = round(max(tsurv_hw_mod_value),4),
             pct_within_1e4_of_1 = round(100*mean(abs(tsurv_hw_mod_value-1) < 1e-4),1)),
          by = .(sp, form)])
LOG("--- tsurv_hw_mod, form F2 only, by species and dbh ---")
print(dcast(gr[form == "F2"], sp + dbh ~ ., value.var = "tsurv_hw_mod_value",
            fun.aggregate = function(x) round(median(x), 4)))
LOG("overall grid range: %.6f to %.6f; share within 1e-4 of 1: %.1f pct",
    min(gr$tsurv_hw_mod_value), max(gr$tsurv_hw_mod_value),
    100*mean(abs(gr$tsurv_hw_mod_value - 1) < 1e-4))

LOG("DONE_SM_DOMAIN")

## =====================================================================================
## Sugar maple (Acer saccharum Marshall) survival modifier for FVS-ACD, refit on a
## functional form the Maine FIA GRM analysis population can actually support.
##
## Deliberately abandons tsurv_hw_mod's functional form for this species. tsurv_hw_mod is a
## ratio of two logistic, paper-birch-referenced survival probabilities in dbh, BAL and
## sqrt(ba.plot), keyed to a four-level NHRI form collapse (STM/SWP/MST/OTHER), carrying no
## risk term at all. The GRM record supports neither the NHRI form levels nor the
## paper-birch-referenced logistic scale. What it does support is an annualized proportional
## hazard on the complementary log-log scale with a log(REMPER) offset, which is what is fit
## here. Begin-of-interval plot basal area and BAL are derived from ME_TREE at the previous
## plot visit, so the covariate footing matches the engine function even though the link,
## the reference, and the form definition do not.
##
## Aaron Weiskittel / CRSF, 26 August 2026.
## =====================================================================================

suppressMessages({
  library(data.table); library(glmmTMB); library(broom.mixed)
  library(MASS); library(parallel)
})
set.seed(20260826)
setDTthreads(1)

IN    <- "/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/sm_refit"
OUT   <- IN
REPO  <- "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd"
JOINT <- "/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/fit_mortality_binomial_glmmTMB.rds"
LOG   <- function(...) { cat(sprintf(...), "\n"); flush.console() }
NCORE <- max(1L, as.integer(Sys.getenv("SLURM_CPUS_ON_NODE", "8")))
NBOOT <- 600L
NMC   <- 50000L

LOG("=== SM SURVIVAL REFIT ===   cores=%d  B=%d  MC=%d", NCORE, NBOOT, NMC)

## ------------------------------------------------------------------ 1. model frame ----
sm <- as.data.table(readRDS(file.path(IN, "sm_analysis_frame_stage1.rds")))
sm[, dbh_cm     := DIA_BEGIN * 2.54]                 # FIA DIA is INCHES, not cm
sm[, form_begin := factor(form_begin, levels = c("F1","F2"))]
sm[, risk_begin := factor(risk_begin, levels = c("R1","R2","R3"))]
sm[, plot_id    := factor(PLT_CN)]
sm[, ba_c       := ba_plot_m2ha]
sm[, bal_c      := bal_m2ha]

need <- c("MORT","form_begin","risk_begin","dbh_cm","REMPER","plot_id","ba_c","bal_c")
mf <- sm[complete.cases(sm[, ..need]) & is.finite(dbh_cm) & dbh_cm > 0 &
         is.finite(REMPER) & REMPER > 0 & is.finite(ba_c) & ba_c > 0 & is.finite(bal_c)]
mf[, plot_id := droplevels(plot_id)]
LOG("SM model frame: %d rows (of %d SM rows), %d plots, %d deaths (%.3f pct)",
    nrow(mf), nrow(sm), uniqueN(mf$plot_id), sum(mf$MORT), 100*mean(mf$MORT))

## ------------------------------------------------------------- 2. candidate models ----
## each candidate carries a full formula (for glmmTMB) and a fixed-only, offset-free RHS
## formula used to build exact contrast matrices later
mk <- function(rhs) list(
  full = as.formula(paste("MORT ~", rhs, "+ offset(log(REMPER)) + (1 | plot_id)")),
  fix  = as.formula(paste("~", rhs)))
cands <- list(
  A = mk("form_begin + risk_begin"),
  B = mk("form_begin + risk_begin + log(dbh_cm)"),
  C = mk("form_begin + risk_begin + log(dbh_cm) + sqrt(ba_c) + bal_c"),
  D = mk("form_begin + risk_begin + dbh_cm + sqrt(ba_c) + bal_c"),      # tsurv_hw_mod covariate set
  E = mk("form_begin * risk_begin + log(dbh_cm) + sqrt(ba_c) + bal_c")
)
fitm <- function(fml, dat) glmmTMB(fml, family = binomial(link = "cloglog"), data = dat)

fits <- lapply(names(cands), function(nm) {
  t0 <- Sys.time()
  f <- try(suppressWarnings(fitm(cands[[nm]]$full, mf)), silent = TRUE)
  LOG("model %s: %s, %.1f s", nm,
      if (inherits(f, "try-error")) "FAILED" else
        sprintf("AIC=%.2f pdHess=%s", AIC(f), isTRUE(f$sdr$pdHess)),
      as.numeric(difftime(Sys.time(), t0, units = "secs")))
  f
})
names(fits) <- names(cands)
ok <- !sapply(fits, inherits, "try-error")
sel <- data.table(model = names(fits)[ok],
                  rhs = sapply(cands[ok], function(x) paste(deparse(x$fix[[2]]), collapse=" ")),
                  npar = sapply(fits[ok], function(f) attr(logLik(f), "df")),
                  logLik = sapply(fits[ok], function(f) as.numeric(logLik(f))),
                  AIC = sapply(fits[ok], AIC),
                  BIC = sapply(fits[ok], BIC),
                  pdHess = sapply(fits[ok], function(f) isTRUE(f$sdr$pdHess)))
sel[, dAIC := AIC - min(AIC)]
setorder(sel, AIC)
LOG("--- candidate model comparison ---"); print(sel)
fwrite(sel, file.path(OUT, "sm_model_selection_2026-08-26.csv"))

if (ok["C"] && ok["E"]) {
  LOG("--- LRT, form x risk interaction (C vs E) ---")
  print(anova(fits[["C"]], fits[["E"]]))
}

BEST <- sel[pdHess == TRUE][1]$model
LOG("selected model: %s   (%s)", BEST, sel[model == BEST]$rhs)
fit  <- fits[[BEST]]
saveRDS(fit, file.path(OUT, "sm_fit_mortality_cloglog_glmmTMB.rds"))

## ------------------------------------------------------------- 3. coefficient table ----
ct <- as.data.table(broom.mixed::tidy(fit, effects = "fixed", conf.int = TRUE, conf.level = 0.95))
ct[, `:=`(hazard_ratio = exp(estimate), hr_lwr = exp(conf.low), hr_upr = exp(conf.high))]
LOG("--- selected model fixed effects (Wald 95 pct) ---"); print(ct)
sd_re <- sqrt(as.numeric(VarCorr(fit)$cond$plot_id[1,1]))
LOG("plot random intercept SD on the cloglog scale: %.4f", sd_re)

## ----------------------------------- 4. form x risk hazard ratios, MC + cluster bootstrap ----
CELLS <- data.table(
  form_begin = factor(rep(c("F1","F2"), each = 3), levels = c("F1","F2")),
  risk_begin = factor(rep(c("R1","R2","R3"), 2),  levels = c("R1","R2","R3")))

make_K <- function(fixfml, dat) {
  nd <- copy(CELLS)
  nd[, `:=`(dbh_cm = median(dat$dbh_cm), ba_c = median(dat$ba_c), bal_c = median(dat$bal_c))]
  X <- model.matrix(fixfml, data = as.data.frame(nd))
  sweep(X, 2, X[1, ], "-")          # each row is (cell - F1/R1) on the linear predictor
}
K <- make_K(cands[[BEST]]$fix, mf)
beta <- fixef(fit)$cond
V    <- vcov(fit)$cond
stopifnot(identical(colnames(K), names(beta)))
LOG("contrast matrix columns match fixed-effect names: TRUE")

log_hr <- as.numeric(K %*% beta)
se_hr  <- sqrt(diag(K %*% V %*% t(K)))
mc     <- MASS::mvrnorm(NMC, mu = beta, Sigma = V) %*% t(K)
mc_q   <- t(apply(mc, 2, quantile, probs = c(0.025, 0.975)))

hr <- data.table(CELLS, log_hr = log_hr, se_log_hr = se_hr, hr = exp(log_hr),
                 hr_wald_lwr = exp(log_hr - qnorm(0.975)*se_hr),
                 hr_wald_upr = exp(log_hr + qnorm(0.975)*se_hr),
                 hr_mc_lwr = exp(mc_q[,1]), hr_mc_upr = exp(mc_q[,2]))
LOG("--- SM hazard ratios by form x risk, referenced to F1/R1 (Wald and MC) ---"); print(hr)

LOG("cluster bootstrap over plots, B=%d on %d cores ...", NBOOT, NCORE)
plots <- levels(mf$plot_id); np <- length(plots)
idx_by_plot <- split(seq_len(nrow(mf)), mf$plot_id)
fml_best <- cands[[BEST]]$full; fix_best <- cands[[BEST]]$fix
boot_one <- function(b) {
  set.seed(20260826L + b)
  pick <- sample.int(np, np, replace = TRUE)
  rows <- unlist(idx_by_plot[pick], use.names = FALSE)
  db <- mf[rows]
  db[, plot_id := factor(rep(seq_along(pick), lengths(idx_by_plot[pick])))]
  f <- try(suppressWarnings(fitm(fml_best, db)), silent = TRUE)
  if (inherits(f, "try-error")) return(rep(NA_real_, nrow(K)))
  if (!isTRUE(f$sdr$pdHess)) return(rep(NA_real_, nrow(K)))
  bb <- fixef(f)$cond
  if (!identical(names(bb), colnames(K))) return(rep(NA_real_, nrow(K)))
  as.numeric(K %*% bb)
}
t0 <- Sys.time()
bres <- mclapply(seq_len(NBOOT), boot_one, mc.cores = NCORE)
LOG("bootstrap wall time: %.1f min", as.numeric(difftime(Sys.time(), t0, units = "mins")))
Bm <- do.call(rbind, bres)
good <- stats::complete.cases(Bm)
LOG("bootstrap replicates usable: %d of %d (%.1f pct)", sum(good), NBOOT, 100*mean(good))
Bq <- t(apply(Bm[good, , drop = FALSE], 2, quantile, probs = c(0.025, 0.5, 0.975)))
hr[, `:=`(hr_boot_lwr = exp(Bq[,1]), hr_boot_med = exp(Bq[,2]), hr_boot_upr = exp(Bq[,3]),
          n_boot = sum(good))]
LOG("--- SM hazard ratios with plot-level cluster-bootstrap intervals ---"); print(hr)
saveRDS(Bm, file.path(OUT, "sm_bootstrap_loghr_draws.rds"))

## reference-cell absolute annual hazard at the median tree, plot random effect at zero
nd0 <- CELLS[1]
nd0[, `:=`(dbh_cm = median(mf$dbh_cm), ba_c = median(mf$ba_c), bal_c = median(mf$bal_c))]
X0 <- model.matrix(fix_best, data = as.data.frame(nd0))
eta0 <- as.numeric(X0 %*% beta); se0 <- sqrt(as.numeric(X0 %*% V %*% t(X0)))
h0 <- exp(eta0)
LOG("reference cell F1/R1 at median tree: annual hazard %.5f (95 pct %.5f to %.5f), annual survival %.5f",
    h0, exp(eta0 - 1.96*se0), exp(eta0 + 1.96*se0), exp(-h0))
ref_tab <- data.table(quantity = "reference-cell annual hazard, median tree, RE=0",
                      estimate = h0, lwr = exp(eta0 - 1.96*se0), upr = exp(eta0 + 1.96*se0),
                      annual_survival = exp(-h0))
fwrite(ref_tab, file.path(OUT, "sm_reference_hazard_2026-08-26.csv"))

## ------------------------------------------------ 5. physical validity screen ----
scr <- mf[, .(n = .N, n_plots = uniqueN(plot_id), n_mort = sum(MORT),
              mean_remper = mean(REMPER), mean_dbh_cm = mean(dbh_cm),
              mean_ba_m2ha = mean(ba_c), mean_bal_m2ha = mean(bal_c),
              obs_period_mort = mean(MORT)),
          by = .(form_begin, risk_begin)]
setorder(scr, form_begin, risk_begin)
scr[, obs_ann_mort := 1 - (1 - obs_period_mort)^(1/mean_remper)]
bi <- t(mapply(function(x, n) as.numeric(binom.test(as.integer(x), as.integer(n))$conf.int),
               scr$n_mort, scr$n))
scr[, `:=`(obs_period_mort_lwr = bi[,1], obs_period_mort_upr = bi[,2])]
ref_ann <- scr[form_begin == "F1" & risk_begin == "R1"]$obs_ann_mort
scr[, obs_ann_hazard_ratio := log(1 - obs_ann_mort) / log(1 - ref_ann)]
scr <- merge(scr, hr[, .(form_begin, risk_begin, model_hr = hr,
                         model_hr_lwr = hr_boot_lwr, model_hr_upr = hr_boot_upr)],
             by = c("form_begin","risk_begin"), sort = FALSE)
setorder(scr, form_begin, risk_begin)

mono <- function(v) all(diff(v) > 0)
chk <- rbindlist(c(
  lapply(c("F1","F2"), function(f) {
    s <- scr[form_begin == f][order(risk_begin)]
    data.table(test = sprintf("mortality rises R1 < R2 < R3 within form %s", f),
               observed_pass = mono(s$obs_ann_mort), model_pass = mono(s$model_hr),
               observed_values = paste(sprintf("%.5f", s$obs_ann_mort), collapse = " < "),
               model_hr_values = paste(sprintf("%.3f", s$model_hr), collapse = " < "),
               min_cell_n = min(s$n), cell_ns = paste(s$n, collapse = ", "))
  }),
  lapply(c("R1","R2","R3"), function(r) {
    s <- scr[risk_begin == r][order(form_begin)]
    data.table(test = sprintf("mortality rises F1 < F2 within risk %s", r),
               observed_pass = mono(s$obs_ann_mort), model_pass = mono(s$model_hr),
               observed_values = paste(sprintf("%.5f", s$obs_ann_mort), collapse = " < "),
               model_hr_values = paste(sprintf("%.3f", s$model_hr), collapse = " < "),
               min_cell_n = min(s$n), cell_ns = paste(s$n, collapse = ", "))
  })))
LOG("--- physical validity screen, SM ---"); print(scr)
LOG("--- monotonicity tests ---"); print(chk)
LOG("SCREEN VERDICT: observed all-pass = %s, model all-pass = %s",
    all(chk$observed_pass), all(chk$model_pass))
fwrite(scr, file.path(OUT, "sm_validity_screen_2026-08-26.csv"))
fwrite(chk, file.path(OUT, "sm_validity_monotonicity_2026-08-26.csv"))

## ------------------------------------------------------- 6. the engine-ready modifier ----
## Fitted model is a proportional hazard on the annualized cloglog scale:
##   -log(S_annual) = h = exp(eta),   eta = eta_ref + delta(form, risk)
## so S(form,risk) = S_ref ^ HR with HR = exp(delta), and the MULTIPLICATIVE modifier on
## annual survival probability is  M = S(form,risk) / S_ref = S_ref^(HR - 1),
## exactly 1 at the reference cell (form F1, risk R1) by construction.
HR_LO <- 0.75; HR_HI <- 6.00
M_LO  <- 0.50; M_HI  <- 1.02
hr[, hr_clamped := pmin(pmax(hr, HR_LO), HR_HI)]
mod_fun <- function(S_ref, HR) {
  S_ref <- pmin(pmax(S_ref, 1e-6), 1 - 1e-9)
  pmin(pmax(S_ref^(HR - 1), M_LO), M_HI)
}
hr[, cell := paste(form_begin, risk_begin, sep = "/")]
grid <- CJ(S_ref_annual = c(0.900, 0.950, 0.975, 0.985, 0.990, 0.995, 0.999),
           cell = hr$cell, sorted = FALSE)
grid <- merge(grid, hr[, .(cell, hr_clamped, hr_boot_lwr, hr_boot_upr)], by = "cell", sort = FALSE)
grid[, `:=`(modifier_annual = mod_fun(S_ref_annual, hr_clamped),
            modifier_annual_lwr = mod_fun(S_ref_annual, pmin(pmax(hr_boot_upr, HR_LO), HR_HI)),
            modifier_annual_upr = mod_fun(S_ref_annual, pmin(pmax(hr_boot_lwr, HR_LO), HR_HI)))]
grid[, `:=`(modifier_5yr = pmin(pmax((S_ref_annual^5)^(hr_clamped - 1), M_LO), M_HI))]
setorder(grid, S_ref_annual, cell)
LOG("--- modifier lookup ---"); print(grid, nrows = 100)
fwrite(grid, file.path(OUT, "sm_modifier_lookup_2026-08-26.csv"))

coef_out <- copy(hr)
coef_out[, `:=`(reference_cell = "F1/R1",
                scale = "annualized cloglog proportional hazard; multiplicative on annual hazard",
                modifier_form = "M = S_ref^(HR-1), clamped",
                hr_clamp_lo = HR_LO, hr_clamp_hi = HR_HI,
                modifier_clamp_lo = M_LO, modifier_clamp_hi = M_HI,
                selected_model = BEST, n = nrow(mf), n_plots = uniqueN(mf$plot_id),
                n_deaths = sum(mf$MORT))]
fwrite(coef_out, file.path(OUT, "sm_survival_modifier_coefficients_2026-08-26.csv"))
fwrite(ct, file.path(OUT, "sm_fixed_effects_2026-08-26.csv"))

## ------------------------------------------- 7. cross-check against the joint nine-pool fit ----
jf <- try(readRDS(JOINT), silent = TRUE)
if (!inherits(jf, "try-error")) {
  bj <- fixef(jf)$cond; Vj <- vcov(jf)$cond; nmz <- names(bj)
  jcells <- list("F1/R1" = character(0),
                 "F1/R2" = c("risk_beginR2","SPSM:risk_beginR2"),
                 "F1/R3" = c("risk_beginR3","SPSM:risk_beginR3"),
                 "F2/R1" = c("form_beginF2","SPSM:form_beginF2"),
                 "F2/R2" = c("form_beginF2","SPSM:form_beginF2","risk_beginR2","SPSM:risk_beginR2"),
                 "F2/R3" = c("form_beginF2","SPSM:form_beginF2","risk_beginR3","SPSM:risk_beginR3"))
  miss <- setdiff(unlist(jcells), nmz)
  if (length(miss)) LOG("WARNING joint-fit terms NOT found: %s", paste(miss, collapse = ", "))
  Kj <- do.call(rbind, lapply(jcells, function(tv) { k <- numeric(length(bj)); k[match(tv, nmz)] <- 1; k }))
  lhj <- as.numeric(Kj %*% bj); sej <- sqrt(diag(Kj %*% Vj %*% t(Kj)))
  cmp <- merge(data.table(cell = names(jcells), joint_hr = exp(lhj),
                          joint_hr_lwr = exp(lhj - 1.96*sej), joint_hr_upr = exp(lhj + 1.96*sej)),
               hr[, .(cell, smonly_hr = hr, smonly_lwr = hr_boot_lwr, smonly_upr = hr_boot_upr)],
               by = "cell", sort = FALSE)
  LOG("--- SM hazard ratios: joint nine-pool fit vs SM-only refit ---"); print(cmp)
  fwrite(cmp, file.path(OUT, "sm_joint_vs_smonly_hr_2026-08-26.csv"))
} else LOG("WARNING: joint mortality fit could not be read, cross-check skipped")

## --------------------------- 8. what tsurv_hw_mod actually returns, for the scale statement ----
src <- file.path(REPO, "scripts", "AcadianGY_12.11.r")
if (file.exists(src)) {
  L <- readLines(src)
  i0 <- grep("^tsurv_hw_mod = function", L)[1]
  i1 <- i0 + which(grepl("^\\}", L[(i0+1):(i0+80)]))[1]
  eval(parse(text = paste(L[i0:i1], collapse = "\n")))
  LOG("extracted tsurv_hw_mod verbatim from %s lines %d-%d", basename(src), i0, i1)
  spp <- data.table(sp = c("QA","RM","RO","YB","PB"),
                    b0 = c(-2.7907,-3.9809,-0.7937, 5.2531, 0),
                    b1 = c( 0.0791, 0.8343, 0.8944, 0.1528, 0))
  gr <- CJ(sp = spp$sp, dbh = c(15, 25, 40, 60), bal = c(10, 20), ba.plot = 25,
           form = c("F1","F2","F5"), sorted = FALSE)
  gr <- merge(gr, spp, by = "sp", sort = FALSE)
  gr[, tsurv_hw_mod_value := mapply(tsurv_hw_mod, dbh, bal, ba.plot, form, b0, b1)]
  setorder(gr, sp, form, dbh, bal)
  LOG("--- tsurv_hw_mod evaluated on a realistic grid (engine source, verbatim) ---")
  print(gr[, .(sp, form, dbh, bal, ba.plot, tsurv_hw_mod_value)], nrows = 200)
  fwrite(gr, file.path(OUT, "tsurv_hw_mod_reference_grid_2026-08-26.csv"))
  LOG("tsurv_hw_mod value range across the grid: %.6f to %.6f",
      min(gr$tsurv_hw_mod_value), max(gr$tsurv_hw_mod_value))
  LOG("share of grid cells within 1e-4 of 1.0: %.1f pct",
      100*mean(abs(gr$tsurv_hw_mod_value - 1) < 1e-4))
} else LOG("WARNING: engine source not found at %s", src)

## ------------------------------------------------------- 9. extrapolation domain ----
qs <- c(0, .01, .05, .25, .5, .75, .95, .99, 1)
dom <- rbindlist(lapply(
  list(dbh_begin_cm = mf$dbh_cm, REMPER_yr = mf$REMPER, ba_plot_m2ha = mf$ba_c,
       bal_m2ha = mf$bal_c, qmd_cm = as.numeric(mf$qmd_cm), tph_trees_ha = as.numeric(mf$tph),
       STDAGE_yr = as.numeric(mf$STDAGE)),
  function(v) as.data.table(as.list(quantile(v[is.finite(v)], qs))), idcol = "variable"))
setnames(dom, c("variable", sprintf("p%02.0f", 100*qs)))
LOG("--- extrapolation domain ---"); print(dom)
fwrite(dom, file.path(OUT, "sm_extrapolation_domain_2026-08-26.csv"))
LOG("SITECLCD:"); print(table(mf$SITECLCD, useNA = "ifany"))
LOG("FORTYPCD top 10:"); print(head(sort(table(mf$FORTYPCD), decreasing = TRUE), 10))
LOG("TRTCD1:"); print(table(mf$TRTCD1, useNA = "ifany"))
LOG("STATECD present: %s", paste(sort(unique(mf$STATECD)), collapse = ", "))

cellrange <- mf[, .(n = .N, n_deaths = sum(MORT),
                    dbh_p01 = quantile(dbh_cm, .01), dbh_p50 = quantile(dbh_cm, .50),
                    dbh_p99 = quantile(dbh_cm, .99), dbh_max = max(dbh_cm),
                    ba_p05 = quantile(ba_c, .05), ba_p95 = quantile(ba_c, .95)),
                by = .(form_begin, risk_begin)][order(form_begin, risk_begin)]
LOG("--- per-cell covariate coverage ---"); print(cellrange)
fwrite(cellrange, file.path(OUT, "sm_percell_coverage_2026-08-26.csv"))

LOG("DONE_SM_SURVIVAL_REFIT")

## =====================================================================================
## Stage 3: finalize the sugar maple (Acer saccharum Marshall) survival modifier.
##
## Corrects the clamp specification used in the stage 2 pass. Stage 2 carried a preset
## hazard-ratio clamp of [0.75, 6.00] chosen before the coefficients were seen; the fitted
## F2/R3 hazard ratio is far above 6, so that clamp would have silently truncated the single
## largest effect in the fit. The hazard-ratio clamp is therefore dropped entirely, since the
## modifier is a six-cell lookup with no interpolation and nothing to extrapolate over, and
## the only clamp retained acts on the returned survival modifier, where it guards against
## the engine handing the modifier a reference survival far below anything the fit saw.
## The clamp is then verified to be inactive across every tree in the fitted sample.
##
## Aaron Weiskittel / CRSF, 26 August 2026.
## =====================================================================================

suppressMessages({ library(data.table); library(glmmTMB) })
setDTthreads(1)
OUT <- "/users/PUOM0008/crsfaaron/castle_2017/grm_formrisk/sm_refit"
LOG <- function(...) { cat(sprintf(...), "\n"); flush.console() }

fit <- readRDS(file.path(OUT, "sm_fit_mortality_cloglog_glmmTMB.rds"))
Bm  <- readRDS(file.path(OUT, "sm_bootstrap_loghr_draws.rds"))
sm  <- as.data.table(readRDS(file.path(OUT, "sm_analysis_frame_stage1.rds")))
sm[, `:=`(dbh_cm = DIA_BEGIN * 2.54,
          form_begin = factor(form_begin, levels = c("F1","F2")),
          risk_begin = factor(risk_begin, levels = c("R1","R2","R3")),
          plot_id = factor(PLT_CN), ba_c = ba_plot_m2ha, bal_c = bal_m2ha)]
need <- c("MORT","form_begin","risk_begin","dbh_cm","REMPER","plot_id","ba_c","bal_c")
mf <- sm[complete.cases(sm[, ..need]) & is.finite(dbh_cm) & dbh_cm > 0 &
         is.finite(REMPER) & REMPER > 0 & is.finite(ba_c) & ba_c > 0 & is.finite(bal_c)]
mf[, plot_id := droplevels(plot_id)]

FIX <- ~ form_begin + risk_begin + dbh_cm + sqrt(ba_c) + bal_c
CELLS <- data.table(form_begin = factor(rep(c("F1","F2"), each = 3), levels = c("F1","F2")),
                    risk_begin = factor(rep(c("R1","R2","R3"), 2),  levels = c("R1","R2","R3")))
nd <- copy(CELLS)[, `:=`(dbh_cm = median(mf$dbh_cm), ba_c = median(mf$ba_c), bal_c = median(mf$bal_c))]
X  <- model.matrix(FIX, data = as.data.frame(nd))
K  <- sweep(X, 2, X[1, ], "-")
beta <- fixef(fit)$cond; V <- vcov(fit)$cond
stopifnot(identical(colnames(K), names(beta)))

log_hr <- as.numeric(K %*% beta)
se     <- sqrt(diag(K %*% V %*% t(K)))
good   <- stats::complete.cases(Bm)
Bq     <- t(apply(Bm[good, , drop = FALSE], 2, quantile, probs = c(0.025, 0.5, 0.975)))
hr <- data.table(CELLS, cell = paste(CELLS$form_begin, CELLS$risk_begin, sep = "/"),
                 log_hr = log_hr, se_log_hr = se, hr = exp(log_hr),
                 hr_wald_lwr = exp(log_hr - qnorm(0.975)*se),
                 hr_wald_upr = exp(log_hr + qnorm(0.975)*se),
                 hr_boot_lwr = exp(Bq[,1]), hr_boot_med = exp(Bq[,2]), hr_boot_upr = exp(Bq[,3]),
                 n_boot = sum(good))
LOG("bootstrap replicates usable: %d of %d", sum(good), nrow(Bm))
LOG("--- final SM hazard ratios ---"); print(hr)

## ------------------------------------------------------------ the modifier and its clamp ----
M_LO <- 0.60; M_HI <- 1.00
sm_surv_mod <- function(S_ref_annual, HR) {
  S <- pmin(pmax(S_ref_annual, 1e-6), 1 - 1e-12)
  pmin(pmax(S^(HR - 1), M_LO), M_HI)
}

## in-sample verification: per-tree reference annual survival with the tree's own plot random
## effect, then the modifier that would be returned for the tree's actual form/risk cell
re <- ranef(fit)$cond$plot_id
mf[, re_i := re[as.character(plot_id), 1]]
Xi <- model.matrix(FIX, data = as.data.frame(mf))
mf[, eta_i := as.numeric(Xi %*% beta) + re_i]
## reference-cell linear predictor for the same tree (form F1, risk R1)
mfr <- copy(mf)[, `:=`(form_begin = factor("F1", levels = c("F1","F2")),
                       risk_begin = factor("R1", levels = c("R1","R2","R3")))]
Xr <- model.matrix(FIX, data = as.data.frame(mfr))
mf[, eta_ref_i := as.numeric(Xr %*% beta) + re_i]
mf[, S_ref_annual := exp(-exp(eta_ref_i))]
mf <- merge(mf, hr[, .(form_begin, risk_begin, hr)], by = c("form_begin","risk_begin"), sort = FALSE)
mf[, M_raw := S_ref_annual^(hr - 1)]
mf[, M_clamped := sm_surv_mod(S_ref_annual, hr)]
LOG("--- in-sample reference annual survival, S_ref ---"); print(summary(mf$S_ref_annual))
LOG("--- in-sample raw modifier M = S_ref^(HR-1) ---"); print(summary(mf$M_raw))
LOG("CLAMP CHECK: trees whose raw modifier falls below the %.2f floor: %d of %d (%.4f pct)",
    M_LO, sum(mf$M_raw < M_LO), nrow(mf), 100*mean(mf$M_raw < M_LO))
LOG("CLAMP CHECK: trees whose raw modifier exceeds %.2f: %d", M_HI, sum(mf$M_raw > M_HI))
LOG("minimum raw modifier anywhere in the fitted sample: %.4f", min(mf$M_raw))
LOG("S_ref_annual at which the floor first binds, by cell:")
bind <- hr[, .(cell, hr, S_ref_at_floor = M_LO^(1/(hr - 1)))]
print(bind)

insamp <- mf[, .(n = .N, S_ref_p05 = quantile(S_ref_annual, .05),
                 S_ref_p50 = quantile(S_ref_annual, .50),
                 S_ref_p95 = quantile(S_ref_annual, .95),
                 M_p05 = quantile(M_raw, .05), M_p50 = quantile(M_raw, .50),
                 M_p95 = quantile(M_raw, .95), M_min = min(M_raw)),
             by = .(form_begin, risk_begin)][order(form_begin, risk_begin)]
LOG("--- in-sample modifier distribution by cell ---"); print(insamp)
fwrite(insamp, file.path(OUT, "sm_modifier_insample_distribution_2026-08-26.csv"))

## ------------------------------------------------------------------- lookup tables ----
grid <- CJ(S_ref_annual = c(0.900, 0.950, 0.960, 0.970, 0.980, 0.985, 0.990, 0.995, 0.999),
           cell = hr$cell, sorted = FALSE)
grid <- merge(grid, hr[, .(cell, hr, hr_boot_lwr, hr_boot_upr)], by = "cell", sort = FALSE)
grid[, `:=`(modifier_annual      = sm_surv_mod(S_ref_annual, hr),
            modifier_annual_lwr  = sm_surv_mod(S_ref_annual, hr_boot_upr),
            modifier_annual_upr  = sm_surv_mod(S_ref_annual, hr_boot_lwr),
            modifier_annual_raw  = S_ref_annual^(hr - 1),
            clamp_active         = S_ref_annual^(hr - 1) < M_LO)]
setorder(grid, S_ref_annual, cell)
LOG("--- modifier lookup on an annual survival basis ---"); print(grid, nrows = 100)
fwrite(grid, file.path(OUT, "sm_modifier_lookup_2026-08-26.csv"))

coef_out <- copy(hr)
coef_out[, `:=`(reference_cell = "F1/R1",
                model = "MORT ~ form_begin + risk_begin + dbh_cm + sqrt(ba_plot) + bal + offset(log(REMPER)) + (1|PLT_CN)",
                family = "binomial, complementary log-log link",
                scale = "annualized proportional hazard; HR multiplies the annual hazard",
                modifier_form = "M = clamp(S_ref_annual^(HR-1), 0.60, 1.00)",
                modifier_clamp_lo = M_LO, modifier_clamp_hi = M_HI,
                interval_basis = "plot-level cluster bootstrap, 2.5/97.5 percentile; Wald shown alongside",
                n = nrow(mf), n_plots = uniqueN(mf$plot_id), n_deaths = sum(mf$MORT))]
fwrite(coef_out, file.path(OUT, "sm_survival_modifier_coefficients_2026-08-26.csv"))
LOG("--- final coefficient table written ---"); print(coef_out[, .(cell, hr, hr_boot_lwr, hr_boot_upr, hr_wald_lwr, hr_wald_upr)])

## bootstrap intervals on the three underlying model terms, back-transformed
tm <- data.table(term = c("form F2 vs F1", "risk R2 vs R1", "risk R3 vs R1"),
                 log_hr = c(beta["form_beginF2"], beta["risk_beginR2"], beta["risk_beginR3"]))
Kt <- rbind(K[4,] - K[1,], K[2,] - K[1,], K[3,] - K[1,])
Bt <- Bm[good, c(4,2,3), drop = FALSE]
tq <- t(apply(Bt, 2, quantile, probs = c(0.025, 0.975)))
tm[, `:=`(hr = exp(log_hr), boot_lwr = exp(tq[,1]), boot_upr = exp(tq[,2]))]
LOG("--- main-effect hazard ratios with cluster-bootstrap intervals ---"); print(tm)
fwrite(tm, file.path(OUT, "sm_main_effect_hr_2026-08-26.csv"))

LOG("DONE_SM_FINALIZE")

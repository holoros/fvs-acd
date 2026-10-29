suppressMessages({library(data.table)})
options(warn=1)
OUT <- "/users/PUOM0008/crsfaaron/castle_2017/garcia_selfthin"
allm <- fread(file.path(OUT, "garcia_stand_pairs_2026-08-26.csv"))

# refinement: keep only pairs with measurable mortality (>0.5% N loss), since near-zero-mortality
# pairs carry no information about the self-thinning curve shape and were likely swamping the fit
allm[, mort_frac := 1 - N2/N1]
cat("mortality fraction distribution by source (median, among pairs with any loss):\n")
print(allm[, .(n=.N, n_with_mort=sum(mort_frac>0.005), median_mort_frac=median(mort_frac[mort_frac>0.005])), by=source])

fit_garcia_bounded <- function(d) {
  nll <- function(par) {
    alpha <- par[1]; beta <- par[2]; gamma <- par[3]
    inner <- d$S1^alpha - (beta*d$H1)^gamma + (beta*d$H2)^gamma
    if (any(!is.finite(inner)) || any(inner<=0)) return(1e10)
    pred_lnS2 <- log(inner)/alpha
    if (any(!is.finite(pred_lnS2))) return(1e10)
    sum((log(d$S2) - pred_lnS2)^2, na.rm=TRUE)
  }
  best <- NULL
  starts <- expand.grid(alpha=c(2,4,6), beta=c(0.03,0.07,0.12), gamma=c(3,6,10))
  for (i in seq_len(nrow(starts))) {
    st <- as.numeric(starts[i,])
    opt <- tryCatch(optim(st, nll, method="L-BFGS-B", lower=c(0.3,0.001,0.3), upper=c(30,2,40),
                          control=list(maxit=2000)), error=function(e) NULL)
    if (!is.null(opt) && is.finite(opt$value) && (is.null(best) || opt$value < best$value)) best <- opt
  }
  if (is.null(best)) return(NULL)
  list(alpha=best$par[1], beta=best$par[2], gamma=best$par[3], sse=best$value, n=nrow(d), convergence=best$convergence)
}

fitres <- list()
for (nm in unique(allm$source)) {
  d <- allm[source==nm & mort_frac>0.005]
  if (nrow(d) < 10) { cat(nm, ": n with measurable mortality too small (", nrow(d), "), skipped\n"); next }
  f <- fit_garcia_bounded(d)
  if (!is.null(f)) { f$source <- nm; f$n_total_pairs <- nrow(allm[source==nm]); fitres[[nm]] <- as.data.table(f) }
}
fitdt <- rbindlist(fitres, fill=TRUE)
fitdt[, slope_2g_a := 2*gamma/alpha]
fitdt[, rmse_log := sqrt(sse/n)]
fwrite(fitdt, file.path(OUT, "garcia_fit_by_source_mortonly_2026-08-26.csv"))
cat("=== REFINED FIT RESULTS (mortality-only pairs, bounded multi-start) ===\n")
print(fitdt[, .(source, n, n_total_pairs, alpha, beta, gamma, slope_2g_a, rmse_log, convergence)])
cat("DONE_GARCIA_FIT2\n")

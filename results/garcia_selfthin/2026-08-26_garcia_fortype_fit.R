suppressMessages({library(data.table)})
options(warn=1)
OUT <- "/users/PUOM0008/crsfaaron/castle_2017/garcia_selfthin"
allm2 <- fread(file.path(OUT, "garcia_stand_pairs_with_fortype_2026-08-26.csv"))

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
  starts <- expand.grid(alpha=c(1.5,2,3,4,6), beta=c(0.03,0.05,0.07,0.10,0.15), gamma=c(2,3,4,6,8,10))
  for (i in seq_len(nrow(starts))) {
    st <- as.numeric(starts[i,])
    opt <- tryCatch(optim(st, nll, method="L-BFGS-B", lower=c(0.3,0.001,0.3), upper=c(30,2,40),
                          control=list(maxit=3000)), error=function(e) NULL)
    if (!is.null(opt) && is.finite(opt$value) && (is.null(best) || opt$value < best$value)) best <- opt
  }
  if (is.null(best)) return(NULL)
  at_lower <- any(abs(best$par - c(0.3,0.001,0.3)) < 1e-3)
  at_upper <- any(abs(best$par - c(30,2,40)) < 1e-3)
  list(alpha=best$par[1], beta=best$par[2], gamma=best$par[3], sse=best$value, n=nrow(d),
       convergence=best$convergence, boundary_hit = at_lower || at_upper)
}

run_group <- function(dt, groupvar, label) {
  res <- list()
  for (g in unique(dt[[groupvar]])) {
    d <- dt[get(groupvar)==g & mort_frac>0.005]
    if (nrow(d) < 30) { cat(label, g, ": n too small (", nrow(d), "), skipped\n"); next }
    f <- fit_garcia_bounded(d)
    if (!is.null(f)) { f$group <- g; f$grouping <- label; res[[as.character(g)]] <- as.data.table(f) }
  }
  rbindlist(res, fill=TRUE)
}

fit_fortype <- run_group(allm2, "fortype", "fortype")
fit_juris <- run_group(allm2, "juris", "juris")
fitall <- rbindlist(list(fit_fortype, fit_juris), fill=TRUE)
fitall[, slope_2g_a := 2*gamma/alpha]
fitall[, rmse_log := sqrt(sse/n)]
setcolorder(fitall, c("grouping","group","n","alpha","beta","gamma","slope_2g_a","rmse_log","boundary_hit","convergence"))
fwrite(fitall, file.path(OUT, "garcia_fit_by_fortype_juris_2026-08-26.csv"))
cat("=== BROAD-SCALE FIT RESULTS ===\n")
print(fitall)
cat("DONE_FORTYPE_FIT\n")

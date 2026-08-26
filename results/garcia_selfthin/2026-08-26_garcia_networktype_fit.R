suppressMessages({library(data.table)})
options(warn=1)
OUT <- "/users/PUOM0008/crsfaaron/castle_2017/garcia_selfthin"
allm2 <- fread(file.path(OUT, "garcia_stand_pairs_with_fortype_2026-08-26.csv"))

# network_type: 'experimental' only for sources with a confirmed treatment schedule file
# (bench_ctrn_treatments.csv, bench_pef_treatments.csv exist; no equivalent found for any other
# source). This is an evidence-based proxy, not a guess about management intensity elsewhere.
experimental_sources <- c("ctrn","pef")
allm2[, network_type := fifelse(source %in% experimental_sources, "experimental", "operational_or_natural")]

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

run_group <- function(dt, groupvars, label) {
  dt[, grpkey := do.call(paste, c(.SD, sep="__")), .SDcols = groupvars]
  res <- list()
  for (g in unique(dt$grpkey)) {
    d <- dt[grpkey==g & mort_frac>0.005]
    if (nrow(d) < 30) { cat(label, g, ": n too small (", nrow(d), "), skipped\n"); next }
    f <- fit_garcia_bounded(d)
    if (!is.null(f)) { f$group <- g; f$grouping <- label; res[[g]] <- as.data.table(f) }
  }
  rbindlist(res, fill=TRUE)
}

fit_nt <- run_group(copy(allm2), "network_type", "network_type")
fit_nt_ft <- run_group(copy(allm2), c("network_type","fortype"), "network_type_x_fortype")
fitall <- rbindlist(list(fit_nt, fit_nt_ft), fill=TRUE)
fitall[, slope_2g_a := 2*gamma/alpha]
fitall[, rmse_log := sqrt(sse/n)]
setcolorder(fitall, c("grouping","group","n","alpha","beta","gamma","slope_2g_a","rmse_log","boundary_hit","convergence"))
fwrite(fitall, file.path(OUT, "garcia_fit_by_networktype_2026-08-26.csv"))
cat("=== NETWORK-TYPE FIT RESULTS ===\n")
print(fitall)
cat("DONE_NETWORKTYPE_FIT\n")

suppressMessages({library(data.table)})
options(warn=1)
BASE1 <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
BASE2 <- "/users/PUOM0008/crsfaaron/magplot/verify/p5m"
OUT <- "/users/PUOM0008/crsfaaron/castle_2017/garcia_selfthin"
dir.create(OUT, showWarnings=FALSE, recursive=TRUE)

sources <- list(
  ctrn = list(base=BASE1, tag="ctrn"),
  pef = list(base=BASE1, tag="pef"),
  baxter = list(base=BASE1, tag="baxter"),
  silc = list(base=BASE1, tag="silc"),
  silc_l = list(base=BASE1, tag="silc_l"),
  silc137 = list(base=BASE1, tag="silc137"),
  ns = list(base=BASE1, tag="ns"),
  ns_long = list(base=BASE1, tag="ns_long"),
  mefia = list(base=BASE1, tag="mefia"),
  mefia_long = list(base=BASE1, tag="mefia_long"),
  mefia_subp = list(base=BASE1, tag="mefia_subp"),
  memat = list(base=BASE2, tag="p5m_memat"),
  medev = list(base=BASE2, tag="p5m_medev")
)

topN_per_ha <- 100

calc_stand <- function(dt) {
  dt <- dt[is.finite(DBH) & is.finite(HT) & is.finite(EXPF) & EXPF>0]
  if (nrow(dt)==0) return(data.table(STAND=character(0), H=numeric(0), N=numeric(0)))
  dt[, N := sum(EXPF), by=STAND]
  setorder(dt, STAND, -DBH)
  dt[, cum_expf := cumsum(EXPF), by=STAND]
  topdt <- dt[cum_expf - EXPF < topN_per_ha]
  top <- topdt[, .(H = weighted.mean(HT, EXPF), N=N[1]), by=STAND]
  top
}

results <- list()
for (nm in names(sources)) {
  s <- sources[[nm]]
  f1 <- file.path(s$base, paste0("bench_", s$tag, "_tree_init.csv"))
  f2 <- file.path(s$base, paste0("bench_", s$tag, "_tree_t2.csv"))
  fp <- file.path(s$base, paste0("bench_", s$tag, "_pairs.csv"))
  if (!file.exists(f1) || !file.exists(f2) || !file.exists(fp)) { cat("SKIP", nm, "missing file(s)\n"); next }
  t1 <- fread(f1); t2 <- fread(f2); pr <- fread(fp)
  st1 <- calc_stand(copy(t1)); setnames(st1, c("H","N"), c("H1","N1"))
  st2 <- calc_stand(copy(t2)); setnames(st2, c("H","N"), c("H2","N2"))
  m <- merge(st1, st2, by="STAND")
  if (!"interval_years" %in% names(pr)) { cat("SKIP", nm, "no interval_years\n"); next }
  m <- merge(m, unique(pr[, .(STAND, interval_years)]), by="STAND")
  m <- m[is.finite(N1)&is.finite(N2)&is.finite(H1)&is.finite(H2)&N1>0&N2>0&H1>0&H2>0&N2<=N1*1.01]
  if (nrow(m)==0) { cat("SKIP", nm, "no valid pairs after filter\n"); next }
  m[, S1 := 100/sqrt(N1)][, S2 := 100/sqrt(N2)]
  m[, source := nm]
  results[[nm]] <- m
  cat(nm, ": n_stand_pairs =", nrow(m), "\n")
}
allm <- rbindlist(results, fill=TRUE)
fwrite(allm, file.path(OUT, "garcia_stand_pairs_2026-08-26.csv"))
cat("TOTAL rows:", nrow(allm), "\n")

fit_garcia <- function(d) {
  nll <- function(par) {
    alpha <- exp(par[1]); beta <- exp(par[2]); gamma <- exp(par[3])
    inner <- d$S1^alpha - (beta*d$H1)^gamma + (beta*d$H2)^gamma
    pred_lnS2 <- log(pmax(1e-8, inner))/alpha
    sum((log(d$S2) - pred_lnS2)^2, na.rm=TRUE)
  }
  init <- c(log(4), log(0.07), log(6))
  opt <- tryCatch(optim(init, nll, method="Nelder-Mead", control=list(maxit=5000, reltol=1e-10)), error=function(e) NULL)
  if (is.null(opt)) return(NULL)
  list(alpha=exp(opt$par[1]), beta=exp(opt$par[2]), gamma=exp(opt$par[3]), sse=opt$value, n=nrow(d), convergence=opt$convergence)
}

fitres <- list()
for (nm in unique(allm$source)) {
  d <- allm[source==nm]
  if (nrow(d) < 10) { cat(nm, ": n too small (", nrow(d), "), skipped\n"); next }
  f <- fit_garcia(d)
  if (!is.null(f)) { f$source <- nm; fitres[[nm]] <- as.data.table(f) }
}
fitdt <- rbindlist(fitres, fill=TRUE)
fitdt[, slope_2g_a := 2*gamma/alpha]
fwrite(fitdt, file.path(OUT, "garcia_fit_by_source_2026-08-26.csv"))
cat("=== FIT RESULTS ===\n")
print(fitdt)
cat("DONE_GARCIA_FIT\n")

suppressMessages({library(data.table); library(nlme)})
options(warn=1)
OUT <- "/users/PUOM0008/crsfaaron/castle_2017/garcia_selfthin"
d <- fread(file.path(OUT, "garcia_stand_pairs_with_fortype_2026-08-26.csv"))
d <- d[mort_frac > 0.005]

garcia_pred <- function(S1, H1, H2, alpha, beta, gamma) {
  inner <- S1^alpha - (beta*H1)^gamma + (beta*H2)^gamma
  inner <- pmax(inner, 1e-8)
  log(inner)/alpha
}

# Restrict to the three sources whose individual nls fit converged to a non-extreme, physically
# plausible optimum in the prior stage (ns, ns_long, mefia_subp). ctrn's individual fit converged
# to an extreme, implausible point (alpha=41.7, gamma=78.3) and mefia/mefia_long never converged
# individually at all; including any of those poisoned the PNLS step in the full hierarchical fit.
# This is a disclosed restriction, not a silent one: a mixed model cannot borrow strength from a
# group whose own likelihood is flat or degenerate, it needs an individually sane starting point.
keep <- c("ns","ns_long","mefia_subp")
d <- d[source %in% keep]
d[, source := factor(source)]
d[, logS2 := log(S2)]
cat("n rows:", nrow(d), " by source:\n"); print(d[,.N,by=source])

nlsl <- tryCatch(
  nlsList(logS2 ~ garcia_pred(S1, H1, H2, alpha, beta, gamma) | source,
          data = d, start = c(alpha=3, beta=0.07, gamma=5),
          control = nls.control(maxiter=200, warnOnly=TRUE)),
  error = function(e) { cat("nlsList ERROR:", conditionMessage(e), "\n"); NULL })
cat("=== per-source nls coefficients (restricted set) ===\n"); print(coef(nlsl))

fit <- tryCatch({
  nlme(nlsl, random = beta ~ 1 | source,
       control = nlmeControl(maxIter=300, msMaxIter=300, pnlsMaxIter=100, tolerance=1e-4, pnlsTol=1e-3))
}, error = function(e) { cat("nlme(nlsList) ERROR:", conditionMessage(e), "\n"); NULL })

if (is.null(fit)) {
  cat("Trying random effects on alpha instead of beta\n")
  fit <- tryCatch({
    nlme(nlsl, random = alpha ~ 1 | source,
         control = nlmeControl(maxIter=300, msMaxIter=300, pnlsMaxIter=100, tolerance=1e-4, pnlsTol=1e-3))
  }, error = function(e) { cat("nlme(alpha random) ERROR:", conditionMessage(e), "\n"); NULL })
}

if (!is.null(fit)) {
  cat("=== NLME SUCCEEDED (restricted 3-source set) ===\n")
  print(summary(fit))
  fe <- fixef(fit); re <- ranef(fit)
  cat("\n=== fixed effects ===\n"); print(fe)
  cat("\n=== random effects ===\n"); print(re)
  cat("\n=== intervals (may fail on boundary) ===\n")
  print(tryCatch(intervals(fit), error=function(e) paste("intervals() failed:", conditionMessage(e))))
  saveRDS(fit, file.path(OUT, "garcia_nlme_fit_restricted3_2026-08-26.rds"))
  fwrite(as.data.table(coef(fit), keep.rownames="source"), file.path(OUT, "garcia_nlme_coef_restricted3_2026-08-26.csv"))
  cat("DONE_NLME_RESTRICTED_SUCCESS\n")
} else {
  cat("DONE_NLME_RESTRICTED_FAILED\n")
}

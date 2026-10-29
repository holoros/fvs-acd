## 2026-08-26_garcia_managed_split_fit.R
## Does the Garcia (2009) relative-spacing self-thinning curve move when managed pairs are
## removed? Refits the committed pooled specification verbatim on four subsets.
##
## Two estimators, both taken unchanged from the committed chain:
##   PRIMARY   nlme spec copied from 2026-08-26_garcia_nlme_restricted3.R (nlsList start
##             c(3, 0.07, 5), random beta ~ 1 | source with alpha fallback, same nlmeControl).
##   SECONDARY bounded multi-start least squares copied from 2026-08-26_garcia_fit_bounded.R
##             (L-BFGS-B, 27 starts, lower c(0.3,0.001,0.3), upper c(30,2,40)), with a
##             nonparametric bootstrap over stand pairs for intervals. Needed because the
##             nlme estimator is not guaranteed to converge on every subset, and a subset
##             whose primary fit fails still has to be reported with an interval.
## The pooled nlme random-effect SD is 1.3e-06, so the two estimators target the same
## optimum on the pooled set; agreement there is the internal check on the secondary.
##
## Commits nothing, edits no committed file.

suppressMessages({library(data.table); library(nlme); library(MASS)})
options(warn = 1)

DAT   <- "/users/PUOM0008/crsfaaron/castle_2017/garcia_selfthin"
BASE1 <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
OUT   <- "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/results/garcia_selfthin"

set.seed(20260826)
NBOOT <- 500

## ------------------------------------------------- data, identical to the committed pooled fit
d0 <- fread(file.path(DAT, "garcia_stand_pairs_with_fortype_2026-08-26.csv"))
d0 <- d0[mort_frac > 0.005]
keep <- c("ns", "ns_long", "mefia_subp")
d0 <- d0[source %in% keep]
d0[, logS2 := log(S2)]
COLS <- names(d0)   # freeze the committed column set; nlsList uses na.fail on the data frame

## ------------------------------------------------- attach MANAGED
## The committed chain drops MANAGED at 2026-08-26_garcia_stand_extraction.R line 49, which
## selects only STAND and interval_years off the pairs file. Recover it by re-joining.
## bench_mefia_subp_pairs.csv has no MANAGED column at all, so those 321 pairs are unlabelled,
## an absence rather than a measured zero.
man <- rbindlist(list(
  fread(file.path(BASE1, "bench_ns_pairs.csv"))[,      .(STAND, MANAGED)][, source := "ns"],
  fread(file.path(BASE1, "bench_ns_long_pairs.csv"))[, .(STAND, MANAGED)][, source := "ns_long"]
), fill = TRUE)
man <- unique(man, by = c("STAND", "source"))

d <- merge(d0, man, by = c("STAND", "source"), all.x = TRUE)
d[, managed_flag := fifelse(is.na(MANAGED), "unlabelled", fifelse(MANAGED == 1, "managed", "unmanaged"))]

cat("=== pair counts entering the pooled fit ===\n")
print(d[, .N, by = .(source, managed_flag)][order(source, managed_flag)])
cat("total n:", nrow(d), " managed:", d[managed_flag == "managed", .N],
    " pct managed:", round(100 * d[managed_flag == "managed", .N] / nrow(d), 4), "\n\n")

## ------------------------------------------------- model, verbatim
garcia_pred <- function(S1, H1, H2, alpha, beta, gamma) {
  inner <- S1^alpha - (beta * H1)^gamma + (beta * H2)^gamma
  inner <- pmax(inner, 1e-8)
  log(inner) / alpha
}

## ------------------------------------------------- PRIMARY: nlme, spec unchanged
fit_nlme <- function(dd, label) {
  dd <- copy(dd)[, ..COLS]              # exactly the committed columns, no NA-bearing extras
  dd[, source := factor(as.character(source))]
  cat("\n########## PRIMARY nlme:", label, " n =", nrow(dd), " groups =", nlevels(dd$source), "\n")
  print(dd[, .N, by = source])

  nlsl <- tryCatch(
    nlsList(logS2 ~ garcia_pred(S1, H1, H2, alpha, beta, gamma) | source,
            data = dd, start = c(alpha = 3, beta = 0.07, gamma = 5),
            control = nls.control(maxiter = 200, warnOnly = TRUE)),
    error = function(e) { cat("nlsList ERROR:", conditionMessage(e), "\n"); NULL })
  if (is.null(nlsl)) return(list(label = label, ok = FALSE, n = nrow(dd),
                                 mode = "nlsList error"))
  cat("--- per-source nls coefficients ---\n"); print(coef(nlsl))

  ctl <- nlmeControl(maxIter = 300, msMaxIter = 300, pnlsMaxIter = 100,
                     tolerance = 1e-4, pnlsTol = 1e-3)
  m1 <- tryCatch(nlme(nlsl, random = beta ~ 1 | source, control = ctl),
                 error = function(e) { cat("nlme(beta random) ERROR:", conditionMessage(e), "\n")
                                       assign("e1", conditionMessage(e), envir = .GlobalEnv); NULL })
  rand <- "beta ~ 1 | source"
  if (is.null(m1)) {
    cat("Trying random effects on alpha instead of beta\n")
    rand <- "alpha ~ 1 | source"
    m1 <- tryCatch(nlme(nlsl, random = alpha ~ 1 | source, control = ctl),
                   error = function(e) { cat("nlme(alpha random) ERROR:", conditionMessage(e), "\n")
                                         assign("e2", conditionMessage(e), envir = .GlobalEnv); NULL })
  }
  if (is.null(m1)) return(list(label = label, ok = FALSE, n = nrow(dd),
                               mode = paste0("nlme failed under both random-effect structures; beta: ",
                                             get0("e1", ifnotfound = "NA"), " | alpha: ",
                                             get0("e2", ifnotfound = "NA"))))
  print(summary(m1))
  ci <- tryCatch(intervals(m1, which = "fixed"), error = function(e) NULL)
  cat("--- intervals ---\n"); print(if (is.null(ci)) "intervals() failed" else ci)
  list(label = label, ok = TRUE, fit = m1, ci = ci, n = nrow(dd),
       ngroup = nlevels(dd$source), rand = rand)
}

## ------------------------------------------------- SECONDARY: bounded multi-start LS
STARTS <- as.matrix(expand.grid(alpha = c(2, 4, 6), beta = c(0.03, 0.07, 0.12), gamma = c(3, 6, 10)))
fit_bounded <- function(S1, H1, H2, S2, starts = STARTS) {
  lS2 <- log(S2)
  nll <- function(par) {
    inner <- S1^par[1] - (par[2] * H1)^par[3] + (par[2] * H2)^par[3]
    if (any(!is.finite(inner)) || any(inner <= 0)) return(1e10)
    p <- log(inner) / par[1]
    if (any(!is.finite(p))) return(1e10)
    sum((lS2 - p)^2, na.rm = TRUE)
  }
  best <- NULL
  for (i in seq_len(nrow(starts))) {
    opt <- tryCatch(optim(as.numeric(starts[i, ]), nll, method = "L-BFGS-B",
                          lower = c(0.3, 0.001, 0.3), upper = c(30, 2, 40),
                          control = list(maxit = 2000)), error = function(e) NULL)
    if (!is.null(opt) && is.finite(opt$value) && (is.null(best) || opt$value < best$value)) best <- opt
  }
  if (is.null(best)) return(NULL)
  c(alpha = best$par[1], beta = best$par[2], gamma = best$par[3], sse = best$value)
}

## limiting curve: S^alpha = (beta H)^gamma  =>  S = (beta H)^(gamma/alpha),  N = 1e4 S^-2
dens_ceiling <- function(alpha, beta, gamma, H) 10000 * (beta * H)^(-2 * gamma / alpha)

boot_bounded <- function(dd, label, nboot = NBOOT) {
  cat("\n########## SECONDARY bounded LS + bootstrap:", label, " n =", nrow(dd), "\n")
  f0 <- fit_bounded(dd$S1, dd$H1, dd$H2, dd$S2)
  if (is.null(f0)) { cat("bounded fit failed\n"); return(NULL) }
  cat(sprintf("point: alpha %.6f beta %.7f gamma %.6f sse %.4f\n", f0[1], f0[2], f0[3], f0[4]))
  st2 <- rbind(STARTS, matrix(f0[1:3], nrow = 1, dimnames = list(NULL, c("alpha", "beta", "gamma"))))
  n <- nrow(dd); B <- matrix(NA_real_, nboot, 3)
  for (b in seq_len(nboot)) {
    i <- sample.int(n, n, replace = TRUE)
    fb <- fit_bounded(dd$S1[i], dd$H1[i], dd$H2[i], dd$S2[i],
                      starts = st2[c(nrow(st2), 1, 5, 9, 14, 18, 23, 27), , drop = FALSE])
    if (!is.null(fb)) B[b, ] <- fb[1:3]
  }
  B <- B[complete.cases(B), , drop = FALSE]
  colnames(B) <- c("alpha", "beta", "gamma")
  cat("bootstrap replicates retained:", nrow(B), "of", nboot, "\n")
  q <- function(x) as.numeric(quantile(x, c(0.025, 0.975), na.rm = TRUE))
  sl <- 2 * B[, "gamma"] / B[, "alpha"]
  data.table(
    subset = label, estimator = "bounded LS + nonparametric bootstrap", n = n, nboot_ok = nrow(B),
    alpha = f0[1], alpha_lo = q(B[, "alpha"])[1], alpha_hi = q(B[, "alpha"])[2],
    beta  = f0[2], beta_lo  = q(B[, "beta"])[1],  beta_hi  = q(B[, "beta"])[2],
    gamma = f0[3], gamma_lo = q(B[, "gamma"])[1], gamma_hi = q(B[, "gamma"])[2],
    slope = 2 * f0[3] / f0[1], slope_lo = q(sl)[1], slope_hi = q(sl)[2],
    N_H10 = dens_ceiling(f0[1], f0[2], f0[3], 10),
    N_H10_lo = q(dens_ceiling(B[, 1], B[, 2], B[, 3], 10))[1],
    N_H10_hi = q(dens_ceiling(B[, 1], B[, 2], B[, 3], 10))[2],
    N_H20 = dens_ceiling(f0[1], f0[2], f0[3], 20),
    N_H20_lo = q(dens_ceiling(B[, 1], B[, 2], B[, 3], 20))[1],
    N_H20_hi = q(dens_ceiling(B[, 1], B[, 2], B[, 3], 20))[2],
    N_H30 = dens_ceiling(f0[1], f0[2], f0[3], 30),
    N_H30_lo = q(dens_ceiling(B[, 1], B[, 2], B[, 3], 30))[1],
    N_H30_hi = q(dens_ceiling(B[, 1], B[, 2], B[, 3], 30))[2],
    rmse_log = sqrt(f0[4] / n)
  )
}

## nlme rows: Wald intervals from intervals(), MC on the fixed-effect vcov for derived quantities
derive_nlme <- function(res, nsim = 40000) {
  fe <- fixef(res$fit); V <- as.matrix(vcov(res$fit))
  sim <- MASS::mvrnorm(nsim, mu = as.numeric(fe), Sigma = V); colnames(sim) <- names(fe)
  ok <- sim[, "alpha"] > 0 & sim[, "beta"] > 0 & sim[, "gamma"] > 0
  sim <- sim[ok, , drop = FALSE]
  sl <- 2 * sim[, "gamma"] / sim[, "alpha"]
  dq <- function(H) as.numeric(quantile(dens_ceiling(sim[, "alpha"], sim[, "beta"], sim[, "gamma"], H),
                                        c(0.025, 0.975)))
  ciw <- function(p) if (is.null(res$ci)) c(NA_real_, NA_real_) else
    as.numeric(res$ci$fixed[p, c("lower", "upper")])
  pt <- 2 * fe["gamma"] / fe["alpha"]
  data.table(
    subset = res$label, estimator = paste0("nlme (", res$rand, ")"), n = res$n, nboot_ok = NA_integer_,
    alpha = as.numeric(fe["alpha"]), alpha_lo = ciw("alpha")[1], alpha_hi = ciw("alpha")[2],
    beta  = as.numeric(fe["beta"]),  beta_lo  = ciw("beta")[1],  beta_hi  = ciw("beta")[2],
    gamma = as.numeric(fe["gamma"]), gamma_lo = ciw("gamma")[1], gamma_hi = ciw("gamma")[2],
    slope = as.numeric(pt), slope_lo = quantile(sl, 0.025), slope_hi = quantile(sl, 0.975),
    N_H10 = dens_ceiling(fe["alpha"], fe["beta"], fe["gamma"], 10), N_H10_lo = dq(10)[1], N_H10_hi = dq(10)[2],
    N_H20 = dens_ceiling(fe["alpha"], fe["beta"], fe["gamma"], 20), N_H20_lo = dq(20)[1], N_H20_hi = dq(20)[2],
    N_H30 = dens_ceiling(fe["alpha"], fe["beta"], fe["gamma"], 30), N_H30_lo = dq(30)[1], N_H30_hi = dq(30)[2],
    rmse_log = sigma(res$fit))
}

## ------------------------------------------------- subsets
runs <- list(
  pooled_all_2987                      = d,
  unmanaged_or_unlabelled_2360         = d[managed_flag != "managed"],
  managed_only_627                     = d[managed_flag == "managed"],
  unmanaged_labelled_only_no_mefia_2039 = d[managed_flag == "unmanaged"]
)

prim <- list(); fails <- list(); sec <- list()
for (nm in names(runs)) {
  r <- fit_nlme(runs[[nm]], nm)
  if (isTRUE(r$ok)) prim[[nm]] <- derive_nlme(r) else {
    cat("\n!!! PRIMARY nlme FAILED:", nm, "\n    mode:", r$mode, "\n")
    fails[[nm]] <- data.table(subset = nm, n = r$n, failure_mode = r$mode)
  }
  sec[[nm]] <- boot_bounded(runs[[nm]], nm)
}

tab <- rbindlist(c(prim, sec), fill = TRUE)
setorder(tab, subset, estimator)
cat("\n\n================= COEFFICIENT TABLE =================\n")
print(tab[, .(subset, estimator, n, alpha, alpha_lo, alpha_hi, beta, beta_lo, beta_hi,
               gamma, gamma_lo, gamma_hi, slope, slope_lo, slope_hi)])
cat("\n--- density ceilings, trees ha-1 ---\n")
print(tab[, .(subset, estimator, N_H10, N_H10_lo, N_H10_hi, N_H20, N_H20_lo, N_H20_hi,
               N_H30, N_H30_lo, N_H30_hi, rmse_log)])
fwrite(tab, file.path(OUT, "garcia_managed_split_coef_2026-08-26.csv"))

if (length(fails)) {
  ftab <- rbindlist(fails, fill = TRUE); cat("\n=== PRIMARY nlme FAILURES ===\n"); print(ftab)
  fwrite(ftab, file.path(OUT, "garcia_managed_split_nlme_failures_2026-08-26.csv"))
}

## ------------------------------------------------- reproduction check
comm <- c(alpha = 3.22205915150016, beta = 0.0680769837735114, gamma = 5.68833514337564)
cat("\n=== REPRODUCTION CHECK vs committed pooled fit (alpha 3.222059, beta 0.06807698, gamma 5.688335) ===\n")
for (est in tab[subset == "pooled_all_2987", unique(estimator)]) {
  p <- tab[subset == "pooled_all_2987" & estimator == est]
  cat(sprintf("[%s] alpha %.6f (d %.2e)  beta %.8f (d %.2e)  gamma %.6f (d %.2e)\n", est,
              p$alpha, abs(p$alpha - comm["alpha"]), p$beta, abs(p$beta - comm["beta"]),
              p$gamma, abs(p$gamma - comm["gamma"])))
}
cat("committed pooled ceilings:",
    sprintf("%.0f %.0f %.0f\n", dens_ceiling(comm[1], comm[2], comm[3], 10),
            dens_ceiling(comm[1], comm[2], comm[3], 20), dens_ceiling(comm[1], comm[2], comm[3], 30)))

## ------------------------------------------------- is the unmanaged curve outside pooled uncertainty
cat("\n=== unmanaged vs pooled, within the bootstrap estimator (like for like) ===\n")
a <- tab[subset == "pooled_all_2987" & estimator %like% "bootstrap"]
for (s in c("unmanaged_or_unlabelled_2360", "managed_only_627", "unmanaged_labelled_only_no_mefia_2039")) {
  b <- tab[subset == s & estimator %like% "bootstrap"]
  if (!nrow(b)) next
  cat("\n--", s, "\n")
  for (p in c("alpha", "beta", "gamma", "slope")) {
    cat(sprintf("  %-6s %.6f [%.6f, %.6f]   pooled %.6f [%.6f, %.6f]  outside pooled CI: %s\n",
                p, b[[p]], b[[paste0(p, "_lo")]], b[[paste0(p, "_hi")]],
                a[[p]], a[[paste0(p, "_lo")]], a[[paste0(p, "_hi")]],
                b[[p]] < a[[paste0(p, "_lo")]] || b[[p]] > a[[paste0(p, "_hi")]]))
  }
  for (h in c("N_H10", "N_H20", "N_H30")) {
    cat(sprintf("  %-6s %.0f [%.0f, %.0f]   pooled %.0f [%.0f, %.0f]   ratio %.4f  outside: %s\n",
                h, b[[h]], b[[paste0(h, "_lo")]], b[[paste0(h, "_hi")]],
                a[[h]], a[[paste0(h, "_lo")]], a[[paste0(h, "_hi")]], b[[h]] / a[[h]],
                b[[h]] < a[[paste0(h, "_lo")]] || b[[h]] > a[[paste0(h, "_hi")]]))
  }
}

cat("\nDONE_GARCIA_MANAGED_SPLIT\n")

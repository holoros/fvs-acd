# ------------------------------------------------------------------ AcadianGY 14.1
# Overlay on AcadianGY 14.0.4. Two switchable diameter increment terms, gated
# independently, both identity when their gate is FALSE. Nothing in 14.0.4 is
# modified; this file sources it and wraps ddbh and calc_ddbh the same way 14.0.3
# wrapped them for the small-tree blend. No em dashes.
#
#   ops$use.lsdg.v141   (LSDG_V141, default FALSE)  unmanaged level term L
#   ops$use.thin.v141   (THIN_V141, default FALSE)  thinning release term T
#
# L, applied as a multiplier on the predicted annual diameter increment:
#     m_L(d) = 1 + (lambda - 1) s(d)
#     s(d) = 0 below ops$v141.d.lo, 1 above ops$v141.d.hi, and the smoothstep
#     3u^2 - 2u^3 between, with u = (d - d.lo) / (d.hi - d.lo)
# Identity below d.lo by construction, not by estimate.
#
# T, applied after L, only on stands with a known years-since-thinning:
#     m_T(tst, d, Dq) = 1 + alpha exp(-beta tst) (min(d / Dq, cap))^gamma
# The cap is ops$v141.rel.cap, default the maximum d / Dq in the T estimation set. gamma above 1
# makes m_T unbounded in relative size, and the fitted support stops at that maximum, so beyond it
# the term is not extrapolating, it is unconstrained. Gate GT6 of pre-registration 2 revision 2.
# Dq is the quadratic mean diameter of the current tree list,
# sqrt(sum(expf d^2) / sum(expf)), which is algebraically identical to the
# sqrt(BA / TPH * 40000 / pi) used in the offline fit.
#
# RUNNER CONTRACT. The caller must set ops$stand.tst to the years since the last
# thinning at the start of the current step, per stand, and advance it by one each
# projection year, exactly as it already sets ops$stand.managed. When ops$stand.tst
# is NULL, NA or negative, T is NOT applied to that stand and the call is counted.
# T is never applied by guessing a thinning date.
#
# Coefficients come from ops$v141.coef.file, an rds written by the C2 offline stage,
# or from ops$v141.lambda, ops$v141.alpha, ops$v141.beta and ops$v141.gamma when
# that file is absent. A gate that is TRUE with no coefficient stops the run rather
# than silently falling back to the identity.

if (!exists(".acd_v14_ddbh_base")) stop("AcadianGY 14.1: load AcadianGY 14.0.4 first, this file is an overlay")

.acd_v141_base <- tryCatch(get(".acd_v14_base"), error = function(e) "unknown")
`%||%` <- function(a, b) if (is.null(a)) b else a

.acd_v141_state <- new.env(parent = emptyenv())
.acd_v141_state$on_L <- FALSE
.acd_v141_state$on_T <- FALSE
.acd_v141_state$n_L  <- 0L
.acd_v141_state$n_T  <- 0L
.acd_v141_state$n_T_skipped_no_tst <- 0L
.acd_v141_state$n_T_capped <- 0L
.acd_v141_state$max_rel_seen <- -Inf

.acd_v141_reset <- function() {
  .acd_v141_state$n_L <- 0L; .acd_v141_state$n_T <- 0L
  .acd_v141_state$n_T_skipped_no_tst <- 0L
.acd_v141_state$n_T_capped <- 0L
.acd_v141_state$max_rel_seen <- -Inf; invisible(NULL)
}
.acd_v141_report <- function() data.frame(
  level_term_calls   = .acd_v141_state$n_L,
  thinning_term_calls = .acd_v141_state$n_T,
  thinning_skipped_no_tst = .acd_v141_state$n_T_skipped_no_tst,
  thinning_calls_at_cap = .acd_v141_state$n_T_capped,
  max_rel_dq_seen = .acd_v141_state$max_rel_seen)

.acd_v141_smoothstep <- function(d, lo, hi) {
  u <- pmin(pmax((d - lo) / (hi - lo), 0), 1)
  3 * u^2 - 2 * u^3
}
.acd_v141_mL <- function(d, lambda, lo, hi) 1 + (lambda - 1) * .acd_v141_smoothstep(d, lo, hi)
.acd_v141_mT <- function(tst, d, Dq, alpha, beta, gamma, cap = Inf) {
  rel <- pmin(d / Dq, cap)
  1 + alpha * exp(-beta * tst) * rel^gamma
}

.acd_v141_coefs <- local({
  cache <- NULL; cache_path <- NULL
  function(ops) {
    f <- tryCatch(as.character(ops$v141.coef.file), error = function(e) NA_character_)
    if (length(f) == 1 && !is.na(f) && nzchar(f)) {
      if (!identical(f, cache_path)) {
        if (!file.exists(f)) stop("AcadianGY 14.1: ops$v141.coef.file does not exist: ", f)
        cache <<- readRDS(f); cache_path <<- f
      }
      return(cache)
    }
    list(lambda = tryCatch(as.numeric(ops$v141.lambda), error = function(e) NA_real_),
         alpha  = tryCatch(as.numeric(ops$v141.alpha),  error = function(e) NA_real_),
         beta   = tryCatch(as.numeric(ops$v141.beta),   error = function(e) NA_real_),
         gamma  = tryCatch(as.numeric(ops$v141.gamma),  error = function(e) NA_real_),
         d_lo   = tryCatch(as.numeric(ops$v141.d.lo %||% 12.7), error = function(e) 12.7),
         d_hi   = tryCatch(as.numeric(ops$v141.d.hi %||% 15.0), error = function(e) 15.0),
         rel_cap = tryCatch(as.numeric(ops$v141.rel.cap %||% Inf), error = function(e) Inf))
  }
})

.acd_v141_ddbh_base      <- ddbh
.acd_v141_calc_ddbh_base <- calc_ddbh

ddbh <- function(dbh, cr, bal.sw, bal.hw, csi, ddbh.b0.spp, ddbh.b2.spp, ddbh.b3.spp, ddbh.b4.spp, ht) {
  lt <- .acd_v141_ddbh_base(dbh, cr, bal.sw, bal.hw, csi,
                            ddbh.b0.spp, ddbh.b2.spp, ddbh.b3.spp, ddbh.b4.spp, ht)
  st <- .acd_v141_state
  if (!isTRUE(st$on_L) && !isTRUE(st$on_T)) return(lt)
  # row alignment is verified, never assumed, exactly as the 14.0.3 small-tree hook does
  if (!identical(length(dbh), length(st$dbh)) || !isTRUE(all.equal(as.numeric(dbh), as.numeric(st$dbh))))
    stop("AcadianGY 14.1: the option 3 hook lost row alignment with the tree list")
  out <- lt
  if (isTRUE(st$on_L)) {
    out <- out * .acd_v141_mL(dbh, st$lambda, st$d_lo, st$d_hi)
    st$n_L <- st$n_L + length(dbh)
  }
  if (isTRUE(st$on_T)) {
    if (is.null(st$tst) || !is.finite(st$tst) || st$tst < 0 || !is.finite(st$Dq) || st$Dq <= 0) {
      st$n_T_skipped_no_tst <- st$n_T_skipped_no_tst + length(dbh)
    } else {
      out <- out * .acd_v141_mT(st$tst, dbh, st$Dq, st$alpha, st$beta, st$gamma, st$rel_cap)
      st$n_T <- st$n_T + length(dbh)
      st$n_T_capped <- st$n_T_capped + sum(dbh / st$Dq > st$rel_cap, na.rm = TRUE)
      st$max_rel_seen <- max(st$max_rel_seen, max(dbh / st$Dq, na.rm = TRUE), na.rm = TRUE)
    }
  }
  # the base gives zero growth below breast height and no multiplier may undo it
  out <- ifelse(ht < 1.3716, 0, out)
  out
}

calc_ddbh <- function(tree.data, plot.data, ...) {
  onL <- tryCatch(isTRUE(ops$use.lsdg.v141), error = function(e) FALSE)
  onT <- tryCatch(isTRUE(ops$use.thin.v141), error = function(e) FALSE)
  if (!onL && !onT) return(.acd_v141_calc_ddbh_base(tree.data, plot.data, ...))
  cf <- .acd_v141_coefs(ops)
  if (onL && !is.finite(cf$lambda %||% NA_real_))
    stop("AcadianGY 14.1: ops$use.lsdg.v141 is TRUE but no lambda is available")
  if (onT && !all(is.finite(c(cf$alpha %||% NA_real_, cf$beta %||% NA_real_, cf$gamma %||% NA_real_))))
    stop("AcadianGY 14.1: ops$use.thin.v141 is TRUE but alpha, beta and gamma are not all available")
  st <- .acd_v141_state
  st$on_L <- onL; st$on_T <- onT
  st$lambda <- cf$lambda; st$alpha <- cf$alpha; st$beta <- cf$beta; st$gamma <- cf$gamma
  st$d_lo <- cf$d_lo %||% 12.7; st$d_hi <- cf$d_hi %||% 15.0
  rc <- tryCatch(as.numeric(ops$v141.rel.cap %||% cf$rel_cap %||% Inf), error = function(e) Inf)
  if (onT && (!is.finite(rc) || rc <= 0))
    stop("AcadianGY 14.1: ops$use.thin.v141 is TRUE but no finite relative size cap is set, which gate GT6 forbids")
  st$rel_cap <- rc
  st$dbh <- as.numeric(tree.data$dbh)
  e <- as.numeric(tree.data$expf); d <- as.numeric(tree.data$dbh)
  ok <- is.finite(e) & is.finite(d) & e > 0 & d > 0
  st$Dq <- if (any(ok)) sqrt(sum(e[ok] * d[ok]^2) / sum(e[ok])) else NA_real_
  st$tst <- tryCatch({ v <- ops$stand.tst; if (is.null(v)) NA_real_ else as.numeric(v)[1] },
                     error = function(e) NA_real_)
  on.exit({ st$on_L <- FALSE; st$on_T <- FALSE }, add = TRUE)
  .acd_v141_calc_ddbh_base(tree.data, plot.data, ...)
}

.acd_v141_env <- function(nm, default) { v <- Sys.getenv(nm, ""); if (!nzchar(v)) default else v }
.acd_v141_make_ops_base <- make_ops
make_ops <- function(...,
                     use.lsdg.v141 = .acd_v141_env("LSDG_V141", "0") == "1",
                     use.thin.v141 = .acd_v141_env("THIN_V141", "0") == "1",
                     v141.coef.file = .acd_v141_env("V141_COEF", NA_character_),
                     v141.d.lo = as.numeric(.acd_v141_env("V141_DLO", "12.7")),
                     v141.d.hi = as.numeric(.acd_v141_env("V141_DHI", "15.0")),
                     v141.rel.cap = as.numeric(.acd_v141_env("V141_RELCAP", "NA"))) {
  o <- .acd_v141_make_ops_base(...)
  o$use.lsdg.v141  <- as.logical(use.lsdg.v141)
  o$use.thin.v141  <- as.logical(use.thin.v141)
  o$v141.coef.file <- as.character(v141.coef.file)
  o$v141.d.lo      <- as.numeric(v141.d.lo)
  o$v141.d.hi      <- as.numeric(v141.d.hi)
  o$v141.rel.cap   <- as.numeric(v141.rel.cap)
  o
}

# ------------------------------------------------------------------ self-test
# E1 and E3 in miniature, on whatever tree list the caller holds. The full engine
# gates of pre-registration 2 run against the Phase D harness, not here.
.acd_v141_selftest <- function(tree, stand, ops, years = 5) {
  run <- function(o) { cur <- tree
    for (y in seq_len(years)) cur <- AcadianGYOneStand(tree = cur, stand = stand, ops = o)
    cur }
  o_off <- ops; o_off$use.lsdg.v141 <- FALSE; o_off$use.thin.v141 <- FALSE
  a <- run(o_off); b <- run(o_off)
  cat("E1 switch-off reproducible      ", isTRUE(all.equal(a, b)), "\n")
  o_L <- o_off; o_L$use.lsdg.v141 <- TRUE
  cL <- run(o_L)
  cat("E3 L only changes dbh           ", !isTRUE(all.equal(a$dbh, cL$dbh)), "\n")
  o_T <- o_off; o_T$use.thin.v141 <- TRUE
  cT <- run(o_T)
  cat("E3 T only with no stand.tst     ", isTRUE(all.equal(a$dbh, cT$dbh)),
      " (identity when years since thinning is unknown, as contracted)\n")
  invisible(list(off = a, L = cL, T = cT))
}

cat("AcadianGY 14.1 r2 loaded over 14.0.4 on ", .acd_v141_base,
    "  (both option 3 gates OFF by default)\n", sep = "")

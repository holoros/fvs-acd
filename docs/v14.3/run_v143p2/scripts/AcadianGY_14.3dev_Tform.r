## AcadianGY_14.3dev_Tform.r
## 14.3 development overlay for pre-registration 2 (revision 5, md5 b7562e8b), 27 October 2026.
## Replaces ONE function of 14.1, the thinning release multiplier .acd_v141_mT, with a candidate form of the plan's
## table (C0f, C0r, C1 to C6), and is the identity when off. Nothing else of 14.1 changes: L, Dq, tst handling, the
## height floor and every other component are 14.1's own code, which calls .acd_v141_mT by name at run time.
##
## HOW IT IS CUT. The caller points V141_FILE at this file. It sources the frozen 14.1 file named in V143_V141_BASE
## (md5 0bf27dde asserted) and then, if TFORM is on, rebinds .acd_v141_mT in the global environment.
##
## SWITCHES (environment, read once at source time)
##   TFORM          "0" (default): identity, 14.1's .acd_v141_mT is kept untouched. "1": the candidate below is used.
##   TFORM_CAND     one of C0f C0r C1 C2 C3 C4 C5 C6.
##   TFORM_COEF     CSV with columns KEY, alpha, beta, gamma, tau, rlo, rhi (unused ones NA). KEY "ALL" applies to every
##                  stand; otherwise KEY is stand$stand.id (leave one installation out runs, gate N1). A stand with no
##                  row and no ALL row stops that stand: coefficients are never guessed.
##   TFORM_TRACE    optional path (*_SERVERONLY.rds): every call is recorded (key, tst, d, Dq, m) and written at exit.
## CAPS (gate H5): C0f, C0r, C1, C6 cap r at 2.9848 (14.1's); C4 at 1.5; C2, C3, C5 have none. The cap passed by 14.1
## (V141_RELCAP) is checked against the coefficient file's rel_cap as in PREREG1 and is used only by C0f, C0r, C1, C6.
## FORMS: m_T = 1 + alpha * f(tst) * g(r), r = d / Dq.
##   C0f, C0r: f = exp(-beta tst), g = min(r, cap)^2 (C0f takes alpha, beta from the frozen r5 file)
##   C1: f = exp(-beta tst), g = min(r, 2.9848)^gamma        C4: f = exp(-beta tst), g = min(r, 1.5)^gamma
##   C2: f = exp(-beta tst), g = smoothstep(r; rlo, rhi)     C3: f = (tst / tau) exp(1 - tst / tau), g as C2
##   C5: f = exp(-beta tst), g = 1                           C6: f = exp(-0.08220 tst), g = min(r, 2.9848)^2
## C0f uses 14.1's own arithmetic (rel <- pmin(d / Dq, cap); 1 + alpha * exp(-beta * tst) * rel^gamma) so that gate H1
## (byte identity with frozen 14.1) tests this code path. No coordinates. No em dashes.

.v143t_base <- path.expand(Sys.getenv("V143_V141_BASE", ""))
if (!nzchar(.v143t_base) || !file.exists(.v143t_base)) stop("v143 Tform: V143_V141_BASE must name the frozen 14.1 file")
if (!identical(unname(as.character(tools::md5sum(.v143t_base))), "0bf27dde81240e6bdf59c9a90f0051bd"))
  stop("v143 Tform: V143_V141_BASE is not the frozen 14.1 file (md5 0bf27dde)")
source(.v143t_base)

local({
  cf <- Sys.getenv("V141_COEF", ""); rc <- suppressWarnings(as.numeric(Sys.getenv("V141_RELCAP", "NA")))
  if (nzchar(cf) && file.exists(cf)) {
    r <- readRDS(cf)$rel_cap
    if (!is.finite(rc) || !is.finite(r) || abs(rc - r) >= 5e-5)
      stop(sprintf("v143 Tform CAP: V141_RELCAP %s does not equal the coefficient rel_cap %.10f at 4 decimals", format(rc), r))
    cat(sprintf("v143 Tform CAP ok: V141_RELCAP %.4f, coefficient rel_cap %.10f\n", rc, r))
  }
})

.v143t <- new.env()
.v143t$on <- identical(Sys.getenv("TFORM", "0"), "1")
.v143t$trace_file <- Sys.getenv("TFORM_TRACE", "")
.v143t$tr <- list(); .v143t$ncall <- 0L
.v143t_CAPS <- c(C0f = 2.9848, C0r = 2.9848, C1 = 2.9848, C2 = Inf, C3 = Inf, C4 = 1.5, C5 = Inf, C6 = 2.9848)

if (.v143t$on) {
  .v143t$cand <- Sys.getenv("TFORM_CAND", "")
  if (!(.v143t$cand %in% names(.v143t_CAPS))) stop("v143 Tform: TFORM_CAND must be one of ", paste(names(.v143t_CAPS), collapse = " "))
  f <- Sys.getenv("TFORM_COEF", "")
  if (!nzchar(f) || !file.exists(f)) stop("v143 Tform: TFORM=1 but TFORM_COEF is missing")
  cc <- utils::read.csv(f, colClasses = c(KEY = "character"), stringsAsFactors = FALSE)
  need <- c("KEY", "alpha", "beta", "gamma", "tau", "rlo", "rhi")
  if (!all(need %in% names(cc))) stop("v143 Tform: TFORM_COEF needs columns ", paste(need, collapse = " "))
  if (anyDuplicated(cc$KEY)) stop("v143 Tform: duplicate KEY in TFORM_COEF")
  .v143t$coef <- cc; rownames(.v143t$coef) <- cc$KEY
  .v143t$cap <- unname(.v143t_CAPS[.v143t$cand])
  if (.v143t$cand == "C0f") {
    ## C0f takes alpha and beta from the frozen r5 coefficient file itself (no text round trip), every key
    r5 <- readRDS(Sys.getenv("V141_COEF"))
    if (!isTRUE(all.equal(r5$gamma, 2))) stop("v143 Tform: the r5 file's gamma is not 2")
    .v143t$coef$alpha <- r5$alpha; .v143t$coef$beta <- r5$beta
  }
  cat(sprintf("v143 Tform on: candidate %s, cap %s, %d coefficient rows, file md5 %s\n", .v143t$cand, format(.v143t$cap), nrow(cc),
              unname(as.character(tools::md5sum(f)))))
  .v143t_mT_141 <- .acd_v141_mT
  .v143t_key <- function() {
    s <- tryCatch(get("stand", envir = globalenv()), error = function(e) NULL)
    sid <- tryCatch(as.character(s$stand.id)[1], error = function(e) NA_character_)
    if (is.na(sid)) "ALL" else sid }
  .v143t_row <- function() {
    k <- .v143t_key(); cf <- .v143t$coef
    if (k %in% cf$KEY) return(cf[k, ])
    if ("ALL" %in% cf$KEY) return(cf["ALL", ])
    stop("v143 Tform: no coefficient row for stand ", k, " and no ALL row; coefficients are never guessed") }
  .acd_v141_mT <- function(tst, d, Dq, alpha, beta, gamma, cap = Inf) {
    p <- .v143t_row(); cand <- .v143t$cand
    if (cand %in% c("C0f", "C0r")) {
      ## 14.1's arithmetic, with the candidate's coefficients and 14.1's cap (H5: equals 2.9848)
      if (abs(cap - .v143t$cap) >= 5e-5) stop(sprintf("v143 Tform H5: cap passed %.6f is not the candidate's %.4f", cap, .v143t$cap))
      rel <- pmin(d / Dq, cap)
      m <- 1 + p$alpha * exp(-p$beta * tst) * rel^2
    } else {
      r <- d / Dq
      fT <- switch(cand, C3 = (tst / p$tau) * exp(1 - tst / p$tau), C6 = exp(-0.08220 * tst), exp(-p$beta * tst))
      gR <- switch(cand,
        C1 = pmin(r, .v143t$cap)^p$gamma, C4 = pmin(r, .v143t$cap)^p$gamma, C6 = pmin(r, .v143t$cap)^2, C5 = rep(1, length(r)),
        C2 = , C3 = { u <- pmin(pmax((r - p$rlo) / (p$rhi - p$rlo), 0), 1); 3 * u^2 - 2 * u^3 })
      m <- 1 + p$alpha * fT * gR
    }
    if (nzchar(.v143t$trace_file)) { .v143t$ncall <- .v143t$ncall + 1L
      .v143t$tr[[length(.v143t$tr) + 1L]] <- data.frame(CALL = .v143t$ncall, KEY = .v143t_key(), TST = tst, D = d, DQ = Dq, M = m, stringsAsFactors = FALSE) }
    m }
} else {
  cat("v143 Tform off: .acd_v141_mT is the 14.1 function (identity overlay)\n")
  if (nzchar(.v143t$trace_file)) {
    .v143t_mT_141 <- .acd_v141_mT
    .acd_v141_mT <- function(tst, d, Dq, alpha, beta, gamma, cap = Inf) {
      m <- .v143t_mT_141(tst, d, Dq, alpha, beta, gamma, cap)
      .v143t$ncall <- .v143t$ncall + 1L
      s <- tryCatch(as.character(get("stand", envir = globalenv())$stand.id)[1], error = function(e) NA_character_)
      .v143t$tr[[length(.v143t$tr) + 1L]] <- data.frame(CALL = .v143t$ncall, KEY = s, TST = tst, D = d, DQ = Dq, M = m, stringsAsFactors = FALSE)
      m }
  }
}
if (nzchar(.v143t$trace_file)) reg.finalizer(.v143t, function(e) {
  if (length(e$tr)) saveRDS(do.call(rbind, e$tr), e$trace_file) }, onexit = TRUE)

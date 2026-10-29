## AcadianGY_14.3dev_senft.r
## 14.3 development overlay for pre-registration 4 (revision 1, md5 a15bd92a), 28 October 2026: the 14.0.4 L2 floor hazard
## conditioned on a forest type class. Identity when off. Nothing of 14.1 is edited: this file sources the frozen 14.1 file
## and then wraps two engine functions in the global environment, which the engine calls by name at run time:
##   .acd_v14_mortality       sets the stand's class (SF or NSF, plurality rule) and the weight w for this annual call
##   .acd_v14_stand_decrement adds delta_class * w to the floor intercept in a COPY of the bundle, then calls 14.0.4's own
##                            function; with delta * w equal to 0 the bundle is passed untouched
## SWITCHES (environment, read once at source time)
##   V143_V141_BASE  the frozen 14.1 file (md5 0bf27dde asserted)
##   SENFT           "0" (default) identity; "1" on
##   SENFT_FORM      L (w = 1) or S (w = smoothstep of stand Dq from 15 to 25 cm)
##   SENFT_COEF      CSV with columns CLASS (SF, NSF) and delta; both rows required, never guessed
##   SENFT_TRACE     optional *_SERVERONLY.rds: per plot year KEY, YEAR, CLASS, DQ, W, DELTA, FLOOR_SETS (works when off too)
## Class rule (plan, "The lever"): basal area shares of the current tree list, expansion weighted; SF group BF RS WS BS NS TA WC;
## pine-hemlock group WP RP RN JP EH OS; SF when the SF share is at least the pine-hemlock share and at least the remaining
## share; no live basal area gives class NA and no shift. No coordinates. No em dashes.

.v143s_base <- path.expand(Sys.getenv("V143_V141_BASE", ""))
if (!nzchar(.v143s_base) || !file.exists(.v143s_base)) stop("v143 senft: V143_V141_BASE must name the frozen 14.1 file")
if (!identical(unname(as.character(tools::md5sum(.v143s_base))), "0bf27dde81240e6bdf59c9a90f0051bd"))
  stop("v143 senft: V143_V141_BASE is not the frozen 14.1 file (md5 0bf27dde)")
source(.v143s_base)
if (!exists(".acd_v14_mortality") || !exists(".acd_v14_stand_decrement")) stop("v143 senft: 14.0.4 lever functions not found")

.v143s <- new.env()
.v143s$on <- identical(Sys.getenv("SENFT", "0"), "1")
.v143s$trace_file <- Sys.getenv("SENFT_TRACE", "")
.v143s$tr <- list(); .v143s$cur_shift <- 0; .v143s$cur <- NULL
.v143s_SFG <- c("BF", "RS", "WS", "BS", "NS", "TA", "WC")
.v143s_PHG <- c("WP", "RP", "RN", "JP", "EH", "OS")

.v143s_state <- function(td) {
  sp <- as.character(td$sp); e <- suppressWarnings(as.numeric(td$expf)); d <- suppressWarnings(as.numeric(td$dbh))
  ok <- is.finite(e) & e > 0 & is.finite(d) & d > 0
  ba <- (d[ok]^2) * pi / 40000 * e[ok]; tot <- sum(ba)
  if (!(tot > 0)) return(list(cls = NA_character_, dq = NA_real_))
  sfs <- sum(ba[sp[ok] %in% .v143s_SFG]) / tot; phs <- sum(ba[sp[ok] %in% .v143s_PHG]) / tot
  list(cls = if (sfs >= phs && sfs >= 1 - sfs - phs) "SF" else "NSF", dq = sqrt(sum(d[ok]^2 * e[ok]) / sum(e[ok])))
}
.v143s_w <- function(dq, form) {
  if (form == "L") return(1)
  if (!is.finite(dq)) return(0)
  u <- min(max((dq - 15) / 10, 0), 1); 3 * u^2 - 2 * u^3
}

if (.v143s$on) {
  .v143s$form <- Sys.getenv("SENFT_FORM", "")
  if (!(.v143s$form %in% c("L", "S"))) stop("v143 senft: SENFT_FORM must be L or S")
  f <- Sys.getenv("SENFT_COEF", "")
  if (!nzchar(f) || !file.exists(f)) stop("v143 senft: SENFT=1 but SENFT_COEF is missing")
  cc <- utils::read.csv(f, stringsAsFactors = FALSE)
  if (!all(c("CLASS", "delta") %in% names(cc)) || anyDuplicated(cc$CLASS) || !all(c("SF", "NSF") %in% cc$CLASS) || any(!is.finite(cc$delta)))
    stop("v143 senft: SENFT_COEF needs one finite delta for each of SF and NSF")
  .v143s$delta <- setNames(as.numeric(cc$delta), cc$CLASS)
  cat(sprintf("v143 senft on: form %s, delta SF %.6f, delta NSF %.6f, coefficient file md5 %s\n", .v143s$form,
              .v143s$delta[["SF"]], .v143s$delta[["NSF"]], unname(as.character(tools::md5sum(f)))))
} else cat("v143 senft off: 14.0.4 lever functions unchanged (identity overlay)\n")

if (.v143s$on || nzchar(.v143s$trace_file)) {
  .v143s_mort_141 <- .acd_v14_mortality
  .v143s_dec_141 <- .acd_v14_stand_decrement
  .acd_v14_mortality <- function(tree.data, plot.data, stand, ops) {
    s <- .v143s_state(tree.data)
    sh <- 0; w <- NA_real_
    if (.v143s$on && !is.na(s$cls)) { w <- .v143s_w(s$dq, .v143s$form); sh <- .v143s$delta[[s$cls]] * w }
    key <- tryCatch(as.character(stand$stand.id)[1], error = function(e) NA_character_)
    yr <- if (!is.null(tree.data$year)) suppressWarnings(as.numeric(tree.data$year[1])) else NA_real_
    .v143s$cur_shift <- sh; .v143s$cur <- list(KEY = key, YEAR = yr, CLASS = s$cls, DQ = s$dq, W = w)
    on.exit({ .v143s$cur_shift <- 0; .v143s$cur <- NULL }, add = TRUE)
    .v143s_mort_141(tree.data, plot.data, stand, ops)
  }
  .acd_v14_stand_decrement <- function(st, B, jur = NA_character_, use_jur_re = TRUE, fix = NULL) {
    sh <- .v143s$cur_shift
    if (is.finite(sh) && sh != 0) B$floor$beta[["(Intercept)"]] <- B$floor$beta[["(Intercept)"]] + sh
    dec <- .v143s_dec_141(st, B, jur, use_jur_re, fix)
    if (nzchar(.v143s$trace_file) && !is.null(.v143s$cur)) {
      fs <- (!isTRUE(dec$fit_ok)) || (st$N1 * (1 - dec$pf) < dec$N2_L1)
      .v143s$tr[[length(.v143s$tr) + 1L]] <- data.frame(.v143s$cur, DELTA = sh, FLOOR_SETS = as.integer(fs), stringsAsFactors = FALSE)
    }
    dec
  }
}
if (nzchar(.v143s$trace_file)) reg.finalizer(.v143s, function(e) {
  if (length(e$tr)) saveRDS(do.call(rbind, e$tr), e$trace_file) }, onexit = TRUE)

## AcadianGY_14.3dev_thinelig.r
## 14.3 development overlay for pre-registration 1 (registered revision 1, md5 7f3e67c2), 18 October 2026.
## Limits the 14.1 thinning release term T to stands named eligible in a per stand file. Nothing else changes.
##
## HOW IT IS CUT. The caller points V141_FILE at this file. It first sources the frozen 14.1 file named in
## V143_V141_BASE (md5 0bf27dde asserted), so the runner and the grid harness load 14.1 exactly as before, and
## then rebinds one function, calc_ddbh. 14.1's T reads ops$stand.tst and is the identity when that is NA (the
## 14.1 runner contract). For a stand the eligibility file marks 0, the wrapper sets the global ops$stand.tst to
## NA for the duration of that one calc_ddbh call and restores it on exit, so 14.1's own code skips T and counts
## the skip. L, mortality, ingrowth and height growth never read stand.tst, so they are untouched.
##
## SWITCHES (environment, read once at source time)
##   THINELIG        "0" (default) or "1". With "0" calc_ddbh is 14.1's function called through one wrapper
##                   frame with the same arguments: the identity, checked by gate E0.
##   THINELIG_FILE   CSV with columns KEY and ELIG (0 or 1). Required when THINELIG=1. A stand whose key is
##                   absent stops the run: eligibility is never guessed.
##   THINELIG_KEY    "stand" (default; key = stand$stand.id) or "gridcell" (key = the trailing cellNN of
##                   stand$stand.id, for the Bakuzis grid harness, whose stand.id is <CONFIG>_cellNN).
##   THINELIG_TRACE  optional path. When set, every call of 14.1's m_T and every wrapped calc_ddbh call is
##                   recorded and written there at exit (gate TR). Off in every arm run.
##   THINELIG_REPORT optional path (named *_SERVERONLY.csv: it holds stand keys). Per stand counters written there
##                   at exit: calls kept and withheld, and, for stands where T acts, the trees above the relative size
##                   cap and the largest d / Dq seen, computed exactly as 14.1 computes Dq. Reading only.
## CAP. V141_RELCAP must equal the coefficient file's rel_cap at the setting's printed precision (4 decimals);
## the overlay stops otherwise (finding F12, gate CAP).
## No coordinates. No em dashes.

.v143_base <- path.expand(Sys.getenv("V143_V141_BASE", ""))
if (!nzchar(.v143_base) || !file.exists(.v143_base)) stop("v143: V143_V141_BASE must name the frozen 14.1 file")
if (!identical(unname(as.character(tools::md5sum(.v143_base))), "0bf27dde81240e6bdf59c9a90f0051bd"))
  stop("v143: V143_V141_BASE is not the frozen 14.1 file (md5 0bf27dde)")
source(.v143_base)

local({
  cf <- Sys.getenv("V141_COEF", ""); rc <- suppressWarnings(as.numeric(Sys.getenv("V141_RELCAP", "NA")))
  if (nzchar(cf) && file.exists(cf)) {
    r <- readRDS(cf)$rel_cap
    if (!is.finite(rc) || !is.finite(r) || abs(rc - r) >= 5e-5)
      stop(sprintf("v143 CAP: V141_RELCAP %s does not equal the coefficient rel_cap %.10f at 4 decimals", format(rc), r))
    cat(sprintf("v143 CAP ok: V141_RELCAP %.4f, coefficient rel_cap %.10f, difference %.2e\n", rc, r, rc - r))
  }
})

.v143 <- new.env()
.v143$on <- identical(Sys.getenv("THINELIG", "0"), "1")
.v143$keymode <- Sys.getenv("THINELIG_KEY", "stand")
.v143$perkey <- new.env()
.v143$call_id <- 0L
if (!(.v143$keymode %in% c("stand", "gridcell"))) stop("v143: THINELIG_KEY must be stand or gridcell")
.v143$trace_file <- Sys.getenv("THINELIG_TRACE", "")
.v143$report_file <- Sys.getenv("THINELIG_REPORT", "")
.v143$n_kept <- 0L; .v143$n_withheld <- 0L; .v143$keys_kept <- character(0); .v143$keys_withheld <- character(0)
.v143$tr_calls <- list(); .v143$tr_mT <- list()

if (.v143$on) {
  f <- Sys.getenv("THINELIG_FILE", "")
  if (!nzchar(f) || !file.exists(f)) stop("v143: THINELIG=1 but THINELIG_FILE is missing")
  e <- utils::read.csv(f, colClasses = c(KEY = "character"), stringsAsFactors = FALSE)
  if (!all(c("KEY", "ELIG") %in% names(e))) stop("v143: THINELIG_FILE needs KEY and ELIG")
  if (anyDuplicated(e$KEY)) stop("v143: duplicate KEY in THINELIG_FILE")
  if (!all(e$ELIG %in% c(0L, 1L))) stop("v143: ELIG must be 0 or 1")
  .v143$elig <- stats::setNames(as.integer(e$ELIG), e$KEY)
  cat(sprintf("v143 THINELIG on: %s, %d keys, %d eligible, key mode %s, md5 %s\n", basename(f), length(.v143$elig),
              sum(.v143$elig == 1L), .v143$keymode, unname(as.character(tools::md5sum(f)))))
} else {
  cat("v143 THINELIG off: calc_ddbh is the 14.1 function (identity overlay)\n")
}

.v143_key <- function() {
  s <- tryCatch(get("stand", envir = globalenv()), error = function(e) NULL)
  sid <- tryCatch(as.character(s$stand.id)[1], error = function(e) NA_character_)
  if (is.null(s) || length(sid) != 1L || is.na(sid) || !nzchar(sid)) stop("v143: no global stand$stand.id to key eligibility on")
  if (.v143$keymode == "gridcell") {
    k <- sub("^.*_(cell[0-9]{2})$", "\\1", sid)
    if (identical(k, sid)) stop("v143: grid key mode but stand.id has no trailing cellNN: ", sid)
    k
  } else sid
}

.v143_calc_ddbh_141 <- calc_ddbh
calc_ddbh <- function(tree.data, plot.data, ...) {
  if (!.v143$on && !nzchar(.v143$trace_file) && !nzchar(.v143$report_file)) return(.v143_calc_ddbh_141(tree.data, plot.data, ...))
  key <- .v143_key()
  el <- if (.v143$on) unname(.v143$elig[key]) else 1L
  ## a stand absent from the file stops this stand's projection; the runner records it RUN_OK 0, which gate K1 counts
  if (is.na(el)) stop("v143: stand ", key, " is not in THINELIG_FILE; eligibility is never guessed")
  go <- get("ops", envir = globalenv())
  tst_in <- tryCatch(as.numeric(go$stand.tst)[1], error = function(e) NA_real_)
  e <- as.numeric(tree.data$expf); d <- as.numeric(tree.data$dbh); ok <- is.finite(e) & is.finite(d) & e > 0 & d > 0
  dq <- if (any(ok)) sqrt(sum(e[ok] * d[ok]^2) / sum(e[ok])) else NA_real_          # as 14.1 computes Dq
  .v143$call_id <- .v143$call_id + 1L
  if (nzchar(.v143$trace_file))
    .v143$tr_calls[[length(.v143$tr_calls) + 1L]] <- data.frame(CALL = .v143$call_id, KEY = key, ELIG = el, TST_IN = tst_in, DQ_LIST = dq,
      N_T_BEFORE = .acd_v141_state$n_T, stringsAsFactors = FALSE)
  pk <- .v143$perkey[[key]]; if (is.null(pk)) pk <- c(kept = 0, withheld = 0, t_calls = 0, cap_trees = 0, max_rel = NA_real_)
  if (el == 1L) pk[["kept"]] <- pk[["kept"]] + 1 else pk[["withheld"]] <- pk[["withheld"]] + 1
  if (el == 1L && isTRUE(go$use.thin.v141) && is.finite(tst_in) && tst_in >= 0 && is.finite(dq) && dq > 0) {
    cap <- suppressWarnings(as.numeric(go$v141.rel.cap)); rel <- d / dq
    pk[["t_calls"]] <- pk[["t_calls"]] + 1; pk[["cap_trees"]] <- pk[["cap_trees"]] + sum(rel > cap, na.rm = TRUE)
    pk[["max_rel"]] <- max(c(pk[["max_rel"]], rel), na.rm = TRUE) }
  assign(key, pk, envir = .v143$perkey)
  .v143$cur_key <- key
  if (el == 1L) {
    .v143$n_kept <- .v143$n_kept + 1L
    if (!(key %in% .v143$keys_kept)) .v143$keys_kept <- c(.v143$keys_kept, key)
    return(.v143_calc_ddbh_141(tree.data, plot.data, ...))
  }
  .v143$n_withheld <- .v143$n_withheld + 1L
  if (!(key %in% .v143$keys_withheld)) .v143$keys_withheld <- c(.v143$keys_withheld, key)
  g <- globalenv()
  if (!exists("ops", envir = g, inherits = FALSE)) stop("v143: no global ops to withhold T in")
  old <- g$ops$stand.tst
  o <- g$ops; o$stand.tst <- NA_real_; assign("ops", o, envir = g)
  on.exit({ o2 <- get("ops", envir = g); o2$stand.tst <- old; assign("ops", o2, envir = g) }, add = TRUE)
  .v143_calc_ddbh_141(tree.data, plot.data, ...)
}

if (nzchar(.v143$trace_file)) {
  .v143_mT_141 <- .acd_v141_mT
  .acd_v141_mT <- function(tst, d, Dq, alpha, beta, gamma, cap = Inf) {
    v <- .v143_mT_141(tst, d, Dq, alpha, beta, gamma, cap)
    .v143$tr_mT[[length(.v143$tr_mT) + 1L]] <- data.frame(CALL = .v143$call_id, KEY = .v143$cur_key, TST = tst, D = d, DQ = Dq, ALPHA = alpha,
      BETA = beta, GAMMA = gamma, CAP = cap, MT = v, stringsAsFactors = FALSE)
    v
  }
}

.v143_report <- function() data.frame(THINELIG = as.integer(.v143$on), calls_kept = .v143$n_kept,
  calls_withheld = .v143$n_withheld, stands_kept = length(.v143$keys_kept), stands_withheld = length(.v143$keys_withheld))

.v143_flush <- function(e) {
  if (nzchar(.v143$report_file)) {
    ks <- ls(.v143$perkey)
    pr <- if (length(ks)) do.call(rbind, lapply(ks, function(k) data.frame(KEY = k, t(.v143$perkey[[k]]), stringsAsFactors = FALSE))) else
      data.frame(KEY = character(0), kept = numeric(0), withheld = numeric(0), t_calls = numeric(0), cap_trees = numeric(0), max_rel = numeric(0))
    utils::write.csv(pr, .v143$report_file, row.names = FALSE) }
  if (nzchar(.v143$trace_file)) {
    a <- if (length(.v143$tr_calls)) do.call(rbind, .v143$tr_calls) else data.frame()
    b <- if (length(.v143$tr_mT)) do.call(rbind, .v143$tr_mT) else data.frame()
    saveRDS(list(calls = a, mT = b), .v143$trace_file)
  }
}
reg.finalizer(.v143, .v143_flush, onexit = TRUE)

cat(sprintf("AcadianGY 14.3dev thinelig overlay loaded over %s (THINELIG=%s)\n", basename(.v143_base), as.integer(.v143$on)))

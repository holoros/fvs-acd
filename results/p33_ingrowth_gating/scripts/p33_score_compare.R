# p33_score_compare.R -- pass 33 short-interval regression check.
# Compares the maturity-gate results against the EXISTING pass 24/30 h1_v132_mortgate result
# files (not a rerun), on TOTVOL, per source. Enforces an observed-basis gate before trusting any
# metric: the STAND key set and the observed TOTVOL column must match exactly between the two
# files, so a difference in the metric is attributable to the lever and not to a coverage change.
suppressMessages(library(data.table))
V  <- "/users/PUOM0008/crsfaaron/magplot/verify"
MV <- file.path(V, "merge_v24")
P  <- file.path(V, "p33")

srcs <- c("baxter","ctrn","nb","ns_managed","ns_unmanaged")
met <- function(o, p) {
  ok <- is.finite(o) & is.finite(p) & o > 0
  o <- o[ok]; p <- p[ok]
  if (length(o) < 3) return(list(n=length(o), rmse=NA, bias=NA, slope=NA))
  fit <- tryCatch(coef(lm(o ~ p))[2], error = function(e) NA_real_)
  list(n = length(o), rmse = 100*sqrt(mean((p-o)^2))/mean(o),
       bias = 100*mean(p-o)/mean(o), slope = unname(fit))
}
pick <- function(d, pat) { nm <- grep(pat, names(d), value=TRUE); if (length(nm)) nm[1] else NA_character_ }

out <- list()
for (s in srcs) {
  fh <- file.path(MV, sprintf("h1_v132_mortgate_%s_results.csv", s))
  fm <- file.path(P,  sprintf("h2_matgate_%s_results.csv", s))
  if (!file.exists(fh) || !file.exists(fm)) { cat(sprintf("[%s] SKIP: h1=%s matgate=%s\n", s, file.exists(fh), file.exists(fm))); next }
  h <- fread(fh); m <- fread(fm)
  oc <- pick(h, "^TOTVOL_o$"); pc <- pick(h, "^TOTVOL_p$")
  if (is.na(oc) || is.na(pc)) { cat(sprintf("[%s] SKIP: no TOTVOL_o/_p columns; have %s\n", s, paste(head(names(h),25), collapse=","))); next }
  ## observed-basis gate
  kh <- sort(as.character(h$STAND)); km <- sort(as.character(m$STAND))
  if (!identical(kh, km)) { cat(sprintf("[%s] GATE FAIL: STAND key sets differ (h1 n=%d, matgate n=%d)\n", s, length(kh), length(km))); next }
  setkey(h, STAND); setkey(m, STAND)
  if (!isTRUE(all.equal(h[[oc]][order(h$STAND)], m[[oc]][order(m$STAND)], tolerance = 1e-8))) {
    cat(sprintf("[%s] GATE FAIL: observed TOTVOL differs between files\n", s)); next }
  cat(sprintf("[%s] observed-basis gate PASS (n=%d stands)\n", s, nrow(h)))
  a <- met(h[[oc]], h[[pc]]); b <- met(m[[oc]], m[[pc]])
  out[[s]] <- data.table(source = s, n = a$n,
    rmse_h1 = a$rmse, rmse_mg = b$rmse, d_rmse = b$rmse - a$rmse,
    bias_h1 = a$bias, bias_mg = b$bias, d_bias = b$bias - a$bias,
    slope_h1 = a$slope, slope_mg = b$slope)
}
if (length(out)) {
  r <- rbindlist(out)
  num <- names(r)[sapply(r, is.numeric)]
  r[, (num) := lapply(.SD, function(x) round(x, 3)), .SDcols = num]
  cat("\n=== Short-interval TOTVOL regression check, h1_v132_mortgate vs h2_matgate ===\n")
  print(r)
  cat("\nd_rmse negative = the gate improves RMSE. Adoption gate: no source may regress by more\n")
  cat("than 0.5 RMSE points against the pass 31 production default.\n")
  worst <- r[which.max(d_rmse)]
  cat(sprintf("\nWorst regression: %s, d_rmse = %+.3f points\n", worst$source, worst$d_rmse))
  fwrite(r, file.path(P, "p33_shortinterval_comparison.csv"))
  cat(sprintf("wrote %s\n", file.path(P, "p33_shortinterval_comparison.csv")))
} else cat("\nNO SOURCES COMPARED\n")

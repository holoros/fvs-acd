# =====================================================================
# v130_score_gate_v3.R
# FVS-ACD v13.0 SCORING AND GATE, corrected. Runs on Cardinal in ~/magplot/verify.
# Aaron Weiskittel, CRSF. Headless, plaintext math, no em dashes.
#
# WHY v3 EXISTS (the defect v2 carried)
# ---------------------------------------------------------------------
# v130_score_gate_v2.R line 60 applied attach_esi() to the CANDIDATE only and
# line 61 did not apply it to the BASELINE. attach_esi merges on STAND against
# magp_qcnb_pairs.csv, which carries 126 duplicated STAND keys, so the candidate
# table was multiplied from 733 rows to 789 (in-domain 492 -> 526) while the
# baseline stayed at 733 / 492. Every delta the gate reported since 10 July
# therefore compared 526 duplicated candidate rows against 492 baseline rows.
# Recomputed on a matched 492 stand set the same artifacts give
# POOLED_indomain TOTVOL dNSE +0.0148 rather than the reported -0.0403, which
# flips the deciding condition. The PARK verdicts are a join artifact.
#
# A second, smaller asymmetry: add_tails() used esi8 for the candidate and
# TOPHT_t1 for the baseline (the baseline never received an esi8 column), so
# ESI_low and ESI_high compared different stand sets by construction.
#
# WHAT v3 CHANGES
# ---------------------------------------------------------------------
#  1. attach_domain AND attach_esi are applied to BOTH files, identically.
#  2. The pairs table is deduplicated to one row per STAND before any merge.
#  3. Hard structural assertions: candidate and baseline must have the same row
#     count and the same STAND multiset, and no merge may change a row count.
#     Violation exits nonzero and promotes nothing.
#  4. Tail membership is defined ONCE from the baseline medians and applied to
#     both files, so a subset always contains the same stands in both models.
#  5. Value-range gate on physical bounds, as a hard exit.
#  6. Two conditions added to the four inherited from v2: no sign flip in bias
#     (v2 used abs() only, so BA -9.81 -> +9.80 would have PASSED ba_toward0),
#     and no RMSE regression beyond tolerance.
#
# Threshold provenance (firewall F4, nothing anchored to an unverified internal
# number): the 0.02 / 0.03 NSE tolerances and the 1.0 point volume allowance are
# carried UNCHANGED from v130_score_gate_v2.R so v3 is comparable to every prior
# harvest. The physical bounds are external: basal area 0 to 100 m2 ha-1 and top
# height 0 to 45 m bracket the Acadian maximum observed in the FIA and provincial
# PSP record with margin; total volume 0 to 1500 m3 ha-1 likewise. The sign and
# RMSE conditions are new and are stated as such in the verdict file.
#
# ENV
#   CAND_FILE  candidate results csv, default cb_v130_results.csv
#   BASE_FILE  baseline results csv, default cb_v12101_results.csv (frozen v12.10.1)
#   OUT_TAG    suffix for output files, default "" (e.g. "_b100")
#   STRICT_N   1 (default) to hard exit on a row-count or STAND mismatch, 0 to warn
# =====================================================================

suppressMessages(library(data.table))
setwd(path.expand("~/magplot/verify"))
set.seed(42)

err_log <- path.expand("~/error_log.txt")
logline <- function(...) {
  msg <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(msg, "\n"); try(cat(msg, "\n", file = err_log, append = TRUE), silent = TRUE)
}
die <- function(code, ...) { logline("GATE ABORT (", code, "): ", ...); quit(save = "no", status = code) }

CAND_FILE <- Sys.getenv("CAND_FILE", "cb_v130_results.csv")
BASE_FILE <- Sys.getenv("BASE_FILE", "cb_v12101_results.csv")
OUT_TAG   <- Sys.getenv("OUT_TAG", "")
STRICT_N  <- Sys.getenv("STRICT_N", "1") %in% c("1", "TRUE", "true", "yes")

acadian_L3 <- c("5.3.1", "8.1.7", "8.1.8", "8.1.1")

logline("v130_score_gate_v3 start. cand=", CAND_FILE, " base=", BASE_FILE, " tag='", OUT_TAG, "'")
if (!file.exists(CAND_FILE)) { logline("candidate not found: ", CAND_FILE, "; gate deferred."); quit(save = "no", status = 0) }
if (!file.exists(BASE_FILE)) die(4, "baseline not found: ", BASE_FILE)

cand_raw <- tryCatch(fread(CAND_FILE), error = function(e) NULL)
base_raw <- tryCatch(fread(BASE_FILE), error = function(e) NULL)
if (is.null(cand_raw) || is.null(base_raw)) die(4, "could not read candidate or baseline")
cand_raw[, STAND := as.character(STAND)]; base_raw[, STAND := as.character(STAND)]

n_cand0 <- nrow(cand_raw); n_base0 <- nrow(base_raw)
logline(sprintf("rows as read: candidate %d, baseline %d", n_cand0, n_base0))

## ---------------------------------------------------------------------
## Domain mask. Identical logic for both files.
## ---------------------------------------------------------------------
eco_path <- if (file.exists("magp_qcnb_ecol3_v2.csv")) "magp_qcnb_ecol3_v2.csv" else
            if (file.exists("magp_qcnb_ecol3.csv"))    "magp_qcnb_ecol3.csv"    else NA_character_
eco_tab <- NULL
if (!is.na(eco_path)) {
  et <- tryCatch(fread(eco_path), error = function(e) NULL)
  if (!is.null(et) && "eco" %in% names(et) && "STAND" %in% names(et)) {
    et[, STAND := as.character(STAND)]
    # dedupe: one ecoregion per stand, else the join multiplies rows
    eco_tab <- unique(et[, .(STAND, eco = as.character(eco))], by = "STAND")
    logline(sprintf("ecoregion table %s: %d rows in, %d unique stands out", eco_path, nrow(et), nrow(eco_tab)))
  }
}

attach_domain <- function(cb, label) {
  n0 <- nrow(cb)
  esi_ok <- if ("esi_cov" %in% names(cb)) as.logical(cb$esi_cov) else rep(TRUE, nrow(cb))
  esi_ok[is.na(esi_ok)] <- FALSE
  have_eco <- FALSE
  if (!is.null(eco_tab)) {
    cb <- merge(cb, eco_tab, by = "STAND", all.x = TRUE, sort = FALSE)
    cb[, epaL3 := as.character(eco)]
    have_eco <- cb[epaL3 %in% acadian_L3, .N] > 0
  }
  if (nrow(cb) != n0) die(3, sprintf("ecoregion merge changed %s row count %d -> %d", label, n0, nrow(cb)))
  if (have_eco) cb[, in_domain := esi_ok & (epaL3 %in% acadian_L3)]
  else          cb[, in_domain := esi_ok & (PROV != "QC")]
  cb[is.na(in_domain), in_domain := FALSE]
  attr(cb, "domain_rule") <- if (have_eco) paste0("ecoregion join via ", eco_path) else "fallback PROV != QC"
  cb
}

## ---------------------------------------------------------------------
## ESI attach. Applied to BOTH files, from a DEDUPED pairs table.
## ---------------------------------------------------------------------
esi_tab <- NULL
if (file.exists("magp_qcnb_pairs.csv") && file.exists("magp_qcnb_site_esi8.csv")) {
  pr <- tryCatch(fread("magp_qcnb_pairs.csv"), error = function(e) NULL)
  e8 <- tryCatch(fread("magp_qcnb_site_esi8.csv"), error = function(e) NULL)
  if (!is.null(pr) && !is.null(e8) && all(c("STAND", "SITE") %in% names(pr)) && all(c("SITE", "esi8") %in% names(e8))) {
    pr[, `:=`(STAND = as.character(STAND), SITE = as.character(SITE))]
    e8[, SITE := as.character(SITE)]
    n_pr <- nrow(pr)
    pr_u <- unique(pr[, .(STAND, SITE)], by = "STAND")     # THE FIX: one row per stand
    e8_u <- unique(e8[, .(SITE, esi8)], by = "SITE")
    esi_tab <- merge(pr_u, e8_u, by = "SITE", all.x = TRUE)[, .(STAND, esi8)]
    esi_tab <- unique(esi_tab, by = "STAND")
    logline(sprintf("pairs table: %d rows in, %d unique stands out (%d duplicate stand keys removed)",
                    n_pr, nrow(pr_u), n_pr - nrow(pr_u)))
  }
}

attach_esi <- function(cb, label) {
  n0 <- nrow(cb)
  if (!is.null(esi_tab)) cb <- merge(cb, esi_tab, by = "STAND", all.x = TRUE, sort = FALSE)
  if (!"esi8" %in% names(cb)) cb[, esi8 := NA_real_]
  if (nrow(cb) != n0) die(3, sprintf("esi merge changed %s row count %d -> %d", label, n0, nrow(cb)))
  cb
}

cand <- attach_esi(attach_domain(copy(cand_raw), "candidate"), "candidate")
base <- attach_esi(attach_domain(copy(base_raw), "baseline"),  "baseline")

logline("domain rule: ", attr(cand, "domain_rule"))

## ---------------------------------------------------------------------
## GATE AXIS 1, LOCATION. Structural identity of the two tables.
## This is the check whose absence produced every PARK verdict since 10 July.
## ---------------------------------------------------------------------
struct_ok <- TRUE
if (nrow(cand) != nrow(base)) {
  logline(sprintf("STRUCTURAL FAIL: candidate %d rows vs baseline %d rows after joins", nrow(cand), nrow(base)))
  struct_ok <- FALSE
}
if (!identical(sort(cand$STAND), sort(base$STAND))) {
  logline("STRUCTURAL FAIL: candidate and baseline STAND multisets differ")
  struct_ok <- FALSE
}
nd_c <- sum(cand$in_domain); nd_b <- sum(base$in_domain)
if (nd_c != nd_b) {
  logline(sprintf("STRUCTURAL FAIL: in-domain counts differ, candidate %d vs baseline %d", nd_c, nd_b))
  struct_ok <- FALSE
}
logline(sprintf("in-domain: candidate %d of %d, baseline %d of %d", nd_c, nrow(cand), nd_b, nrow(base)))
pc <- cand[in_domain == TRUE, .N, by = PROV][order(PROV)]
logline("in-domain by PROV (candidate): ", paste0(pc$PROV, "=", pc$N, collapse = " "))
if (!struct_ok && STRICT_N) die(3, "structural identity check failed; refusing to score mismatched tables")
if (!struct_ok) logline("WARNING: STRICT_N off, scoring mismatched tables anyway. Deltas are NOT trustworthy.")

## ---------------------------------------------------------------------
## GATE AXIS 2, VALUE RANGE. Physical bounds, external provenance. Hard exit.
## ---------------------------------------------------------------------
bounds <- list(BA = c(0, 100), TOPHT = c(0, 45), TOTVOL = c(0, 1500), QMD = c(0, 120), SDI = c(0, 3000))
range_fail <- character(0)
for (m in names(bounds)) {
  for (sfx in c("_o", "_p")) {
    col <- paste0(m, sfx)
    if (!col %in% names(cand)) next
    v <- cand[[col]]; v <- v[!is.na(v)]
    if (!length(v)) next
    if (any(!is.finite(v)) || min(v) < bounds[[m]][1] || max(v) > bounds[[m]][2])
      range_fail <- c(range_fail, sprintf("%s [%.3g, %.3g] outside [%g, %g]", col, min(v), max(v), bounds[[m]][1], bounds[[m]][2]))
  }
}
if (length(range_fail)) die(5, "value-range gate failed: ", paste(range_fail, collapse ="; "))
logline("value-range gate passed on all bounded metrics")

## ---------------------------------------------------------------------
## Scoring
## ---------------------------------------------------------------------
score <- function(o, p) {
  ok <- is.finite(o) & is.finite(p); o <- o[ok]; p <- p[ok]
  if (length(o) < 3) return(data.table(n = length(o), obs_mean = NA_real_, pred_mean = NA_real_,
                                       bias_pct = NA_real_, rmse = NA_real_, mae = NA_real_, nse = NA_real_, cor = NA_real_))
  sst <- sum((o - mean(o))^2)
  data.table(n = length(o), obs_mean = mean(o), pred_mean = mean(p),
             bias_pct = 100 * (mean(p) / mean(o) - 1),
             rmse = sqrt(mean((p - o)^2)), mae = mean(abs(p - o)),
             nse = 1 - sum((o - p)^2) / sst, cor = suppressWarnings(cor(o, p)))
}

metrics <- c("BA", "SDI", "QMD", "TOPHT", "TOTVOL", "MERCHVOL", "SAWVOL", "BIOMASS")
metrics <- metrics[paste0(metrics, "_o") %in% names(cand) & paste0(metrics, "_p") %in% names(cand) &
                   paste0(metrics, "_o") %in% names(base) & paste0(metrics, "_p") %in% names(base)]
logline("metrics scored: ", paste(metrics, collapse = ", "))

## Tail membership defined ONCE from the baseline and applied to both, so a
## subset always contains the same stands in both models.
prod_var_b <- if (any(is.finite(base$esi8))) "esi8" else "TOPHT_t1"
med_prod <- median(base[[prod_var_b]][base$in_domain], na.rm = TRUE)
med_size <- median(base$QMD_t1[base$in_domain], na.rm = TRUE)
logline(sprintf("tail splits from baseline: prod var %s median %.4f, QMD_t1 median %.4f", prod_var_b, med_prod, med_size))

tails <- base[, .(STAND,
                  prod_tail = ifelse(get(prod_var_b) <= med_prod, "LOW", "HIGH"),
                  size_tail = ifelse(QMD_t1 <= med_size, "SMALL", "LARGE"))]
tails <- unique(tails, by = "STAND")
add_tails <- function(cb, label) {
  n0 <- nrow(cb); cb <- merge(cb, tails, by = "STAND", all.x = TRUE, sort = FALSE)
  if (nrow(cb) != n0) die(3, sprintf("tail merge changed %s row count", label))
  cb
}
cand <- add_tails(cand, "candidate"); base <- add_tails(base, "baseline")

subsets <- c("POOLED_indomain", "POOLED_all", "ESI_low", "ESI_high", "QMD_small", "QMD_large")
subset_rows <- function(cb, sn) {
  if (sn == "POOLED_indomain") cb[in_domain == TRUE]
  else if (sn == "POOLED_all") cb
  else if (sn == "ESI_low")   cb[in_domain == TRUE & prod_tail == "LOW"]
  else if (sn == "ESI_high")  cb[in_domain == TRUE & prod_tail == "HIGH"]
  else if (sn == "QMD_small") cb[in_domain == TRUE & size_tail == "SMALL"]
  else if (sn == "QMD_large") cb[in_domain == TRUE & size_tail == "LARGE"]
}
build_card <- function(cb, model) rbindlist(lapply(subsets, function(sn) {
  d <- subset_rows(cb, sn)
  rbindlist(lapply(metrics, function(m) cbind(model = model, subset = sn, metric = m,
                                              score(d[[paste0(m, "_o")]], d[[paste0(m, "_p")]]))))
}))
card <- rbind(build_card(cand, "v130"), build_card(base, "v1210"))
fwrite(card, paste0("scorecard_v130", OUT_TAG, "_v3.csv"))
logline("wrote scorecard_v130", OUT_TAG, "_v3.csv")

## Per-subset n must match between models, or that subset is not comparable.
nchk <- merge(card[model == "v130",  .(subset, metric, n_cand = n)],
              card[model == "v1210", .(subset, metric, n_base = n)], by = c("subset", "metric"))
if (nrow(nchk[n_cand != n_base])) {
  logline("SUBSET N MISMATCH:"); print(nchk[n_cand != n_base])
  if (STRICT_N) die(3, "per-subset n differs between candidate and baseline")
}
logline("per-subset n matched between candidate and baseline on every metric")

## ---------------------------------------------------------------------
## Delta table and gate
## ---------------------------------------------------------------------
gate_subsets <- c("POOLED_indomain", "ESI_low", "ESI_high", "QMD_small", "QMD_large")
delta <- rbindlist(lapply(gate_subsets, function(sn) rbindlist(lapply(c("BA", "TOPHT", "TOTVOL"), function(m) {
  a <- card[model == "v130" & subset == sn & metric == m]
  b <- card[model == "v1210" & subset == sn & metric == m]
  data.table(subset = sn, metric = m, n = a$n,
             bias_v1210 = b$bias_pct, bias_v130 = a$bias_pct,
             dabs_bias = abs(a$bias_pct) - abs(b$bias_pct),
             rmse_v1210 = b$rmse, rmse_v130 = a$rmse, drmse = a$rmse - b$rmse,
             nse_v1210 = b$nse, nse_v130 = a$nse, dnse = a$nse - b$nse)
}))))
fwrite(delta, paste0("v130_gate_delta", OUT_TAG, "_v3.csv"))
logline("wrote v130_gate_delta", OUT_TAG, "_v3.csv"); print(delta)

pass_subset <- function(sn) {
  g <- function(m, col) delta[subset == sn & metric == m][[col]][1]
  c1 <- abs(g("TOPHT", "bias_v130")) <= abs(g("TOPHT", "bias_v1210"))
  c2 <- abs(g("BA", "bias_v130"))    <= abs(g("BA", "bias_v1210"))
  c3 <- abs(g("TOTVOL", "bias_v130")) <= abs(g("TOTVOL", "bias_v1210")) + 1.0 &&
        g("TOTVOL", "nse_v130") >= g("TOTVOL", "nse_v1210") - 0.02
  nse_ok <- all(sapply(metrics, function(m) {
    d <- card[model == "v130" & subset == sn & metric == m]$nse - card[model == "v1210" & subset == sn & metric == m]$nse
    is.na(d) || d >= -0.03 }))
  # NEW in v3: a bias sign flip is a failure even if the magnitude fell. v2 used
  # abs() alone, so BA -9.81 -> +9.80 would have passed ba_toward0. That is the
  # 10 July run 12299814 failure mode, which was caught only by luck of landing
  # at +9.83 rather than +9.80.
  sign_ok <- all(sapply(c("BA", "TOPHT", "TOTVOL"), function(m) {
    b0 <- g(m, "bias_v1210"); b1 <- g(m, "bias_v130")
    is.na(b0) || is.na(b1) || abs(b1) < 0.5 || sign(b1) == sign(b0) }))
  # NEW in v3: RMSE may not regress by more than 5 percent of the baseline RMSE.
  rmse_ok <- all(sapply(c("BA", "TOPHT", "TOTVOL"), function(m) {
    r0 <- g(m, "rmse_v1210"); r1 <- g(m, "rmse_v130")
    is.na(r0) || is.na(r1) || r1 <= r0 * 1.05 }))
  data.table(subset = sn, n = delta[subset == sn & metric == "BA"]$n[1],
             height_toward0 = c1, ba_toward0 = c2, volume_held = c3,
             nse_no_regress = nse_ok, sign_no_flip = sign_ok, rmse_no_regress = rmse_ok,
             pass = (c1 & c2 & c3 & nse_ok & sign_ok & rmse_ok))
}
gate <- rbindlist(lapply(gate_subsets, pass_subset))

## ---------------------------------------------------------------------
## NULL-DELTA GUARD (added 11 Aug 2026, after this gate produced a live false
## positive on its very first run).
##
## Re-scoring cb_v130h_results.csv returned dabs_bias = 0 and dnse = 0 on all 15
## delta rows, to 15 significant figures, and the gate duly reported
## ADOPT_PENDING on all five subsets. A candidate whose predictions are identical
## to the baseline passes every condition trivially: bias is not worse, NSE is not
## worse, RMSE is not worse, no sign flips. It is not a model improvement, it is
## a candidate that never differed from the baseline, which means the run that
## produced it did not apply the change it claimed to apply.
##
## This is exactly the adversarial gate question, what wrong output would still
## pass every gate, and the answer turned out to be sitting in the repo already.
## So: an all-zero delta is now an explicit verdict of its own, never a pass.
## Set ALLOW_NULL_DELTA=1 for the deliberate null-control run, where a zero delta
## is the intended result and the point of the exercise.
## ---------------------------------------------------------------------
ALLOW_NULL <- Sys.getenv("ALLOW_NULL_DELTA", "0") %in% c("1", "TRUE", "true", "yes")
null_delta <- all(abs(delta$dabs_bias) < 1e-9, na.rm = TRUE) &&
              all(abs(delta$dnse)      < 1e-9, na.rm = TRUE)
if (null_delta) {
  logline("NULL-DELTA DETECTED: candidate is numerically identical to the baseline on every subset and metric.")
  if (ALLOW_NULL) {
    logline("ALLOW_NULL_DELTA set: this is the intended null control, reporting NULL_CONTROL_OK.")
  } else {
    logline("The candidate did not differ from the baseline, so the run that produced it did not apply its change.")
    logline("Reporting INVALID_NULL_DELTA rather than a pass.")
  }
}

overall <- if (null_delta && !ALLOW_NULL) "INVALID_NULL_DELTA" else
           if (null_delta &&  ALLOW_NULL) "NULL_CONTROL_OK"    else
           if (all(gate$pass))            "ADOPT_PENDING"      else "PARK"
if (null_delta && !ALLOW_NULL) gate[, pass := FALSE]
gate[, overall := overall]
fwrite(gate, paste0("v130_gate_verdict", OUT_TAG, "_v3.csv"))

cat("\n=== v13.0 GATE v3 (matched stand sets) ===\n"); print(gate)
if (overall == "PARK") {
  fail <- gate[pass == FALSE]
  cat("VERDICT: PARK. Failing subset(s):", paste(fail$subset, collapse = ", "), "\n")
  cond <- c("height", "BA", "volume", "nse", "sign", "rmse")
  for (i in seq_len(nrow(fail))) cat("  ", fail$subset[i], "->",
    paste(cond[!unlist(fail[i, .(height_toward0, ba_toward0, volume_held, nse_no_regress, sign_no_flip, rmse_no_regress)])],
          collapse = ","), "failed\n")
} else {
  cat("VERDICT: ADOPT_PENDING. Beats or holds v12.10.1 in domain and in both tails on matched stand sets.\n")
  cat("Still requires Bakuzis + plateau, and adoption remains a separate human decision.\n")
}
cat("DONE_V130_GATE_V3\n")
gc()

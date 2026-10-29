## PREREG47 thresholds (plan revision 5, md5 d93f3035, thresholds unchanged from revision 3; HM unchanged from revision 1, 7f64d22c): HM gate thresholds F_HT and S_HT, MG_LO (r3), and the remeasurement interval
## distribution behind them, from measured inputs only. Registered procedure: F_HT is the 99th percentile of the measured t1 to
## t2 TOPHT decrease over admitted qc_c stands with a decrease; S_HT is the ceiling of 36 times the share of admitted qc_c stands
## whose measured TOPHT decreases by more than 0.01 m. Source: frozen p19_a0111 observed columns (md5 979101be), admitted as in
## frontier_p45.R (esi8 finite and above 2; 378 stands), TOPHT_t1 and TOPHT_o (the gate C frontier basis). Run once, before any
## PREREG47 reading; writes plan/thresholds_p47_DATA.csv and logs/thresholds_md5.txt and refuses to overwrite either.
## Deviation note (red team 15 Oct 2026, must fix 1): the plan names these columns (md5 979101be) and also says "measured heights
## only (the PREREG40 basis)". TOPHT_t1 and TOPHT_o are the runner's published top height, which fills an unmeasured top tree
## height with himp. The gated F_HT and S_HT follow the named, md5 pinned columns; the PREREG40 variant M basis (top 100 per ha
## chosen among trees with a measured height, pass28qc t1 and t2 frames, md5 521d6468 and 7fd42665) and the himp share among
## published top trees are computed beside them and REPORTED (F_HT_M, S_HT_M), never gated. Changing the gated basis needs a
## plan revision before the first reading.
## Aggregates only: no stand, site or tree identifier is written or printed. No coordinates. No em dashes.
suppressMessages(library(data.table))
J <- Sys.getenv("P47_ROOT", "/home/aaron/jobs/v142p47")
PLAN <- file.path(J, "plan/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r5.md")
SRC <- Sys.getenv("P47_P19_RESULTS", "/home/aaron/jobs/v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv")
OUT <- file.path(J, "plan/thresholds_p47_DATA.csv"); MD <- file.path(J, "logs/thresholds_md5.txt")
md5 <- function(f) unname(tools::md5sum(f))
if (md5(PLAN) != "d93f3035f8b9cb691c4c413bcc84bb1d") stop("plan md5 differs (revision 5)")
if (md5(SRC) != "979101bedafe16c090ce84d1e5e46a07") stop("source md5 differs from the frozen record 979101be")
if (file.exists(OUT) || file.exists(MD)) stop("REFUSE: thresholds file or its md5 record exists")
dir.create(dirname(MD), showWarnings = FALSE, recursive = TRUE)
x <- fread(SRC)
need <- c("esi8", "TOPHT_t1", "TOPHT_o"); if (!all(need %in% names(x))) stop("missing columns: ", paste(setdiff(need, names(x)), collapse = " "))
x <- x[is.finite(esi8) & esi8 > 2]
if (nrow(x) != 378) stop("admitted count ", nrow(x), " is not 378 (frontier_p45.R)")
if (!all(is.finite(x$TOPHT_t1) & is.finite(x$TOPHT_o))) stop("an admitted stand lacks TOPHT_t1 or TOPHT_o; the share denominator would change")
NST <- 36L                                       # stands on the PREREG44 grid
y <- x[is.finite(TOPHT_t1) & is.finite(TOPHT_o)]
dec <- y$TOPHT_t1 - y$TOPHT_o                    # positive = top height fell between t1 and t2
has <- dec > 0
if (sum(has) < 1) stop("no admitted stand with a measured TOPHT decrease; F_HT undefined")
F_HT <- unname(quantile(dec[has], 0.99))         # type 7, as frontier_p45.R
share <- mean(dec > 0.01); S_HT <- as.integer(ceiling(NST * share))
## remeasurement interval (r3: the MG_LO divisor, so a gated input). Column name hard coded: `interval_years`, the stand frame's
## decimal interval that driver_p44.R carries into the results (GYR_CARRY) and rounds for projection; absent, stops (rule 1)
ic <- "interval_years"
if (!ic %in% names(x)) stop("interval_years absent from the p19 results: MG_LO undefined (PREREG47 r3, rule 1)")
ivq <- { v <- suppressWarnings(as.numeric(y[[ic]])); v <- v[is.finite(v)]; if (length(v)) quantile(v, c(0, .1, .5, .9, 1)) else rep(NA_real_, 5) }
## r3: MG_LO, 25th percentile of measured annual TOPHT increment over admitted stands with a finite positive interval.
## Two fail safe stops beyond the plan text, recorded as deviations: fewer than 90 percent of intervals valid, or any outside 1 to 20 yr
cat("interval column used:", ic, "\n")
ivv <- suppressWarnings(as.numeric(y[[ic[1]]])); okv <- is.finite(ivv) & ivv > 0
if (sum(okv) < 0.9 * nrow(y) || any(ivv[okv] < 1 | ivv[okv] > 20)) stop("interval column ", ic[1], " not a plausible remeasurement interval in years")
inc <- (y$TOPHT_o[okv] - y$TOPHT_t1[okv]) / ivv[okv]; MG_LO <- unname(quantile(inc, 0.25)); incq <- quantile(inc, c(.1, .5, .9))
ivd <- if (length(ic)) { v <- suppressWarnings(as.numeric(y[[ic[1]]][has])); v <- v[is.finite(v)]; if (length(v)) median(v) else NA_real_ } else NA_real_
dq <- quantile(dec[has], c(.5, .9, .95, .99, 1))
## reported only: PREREG40 variant M (measured heights only) and the himp share among published top trees
FI <- Sys.getenv("P47_FI", "/home/aaron/jobs/v142p14/in/pass28qc/bench_gyr_qc_c_tree_init.csv")
FG <- Sys.getenv("P47_FG", "/home/aaron/jobs/v142p14/in/pass28qc/bench_gyr_qc_c_tree_t2.csv")
top_sel <- function(dbh, expf, mindbh) { live <- which(is.finite(dbh) & dbh >= mindbh & is.finite(expf) & expf > 0); if (!length(live)) return(integer(0))
  o <- live[order(-dbh[live])]; cw <- cumsum(expf[o]); idx <- which(cw <= 100); if (!length(idx)) idx <- 1; o[idx] }   # assemble_p40.R top_sel
VM <- tryCatch({
  if (md5(FI) != "521d6468861b66b8f73864fb9a6bf0fc" || md5(FG) != "7fd42665dccd3c3e9e188ee0ad9ca5d0") stop("pass28qc frame md5 differs from the PREREG40 record")
  if (!"SCORE_MINDBH_USED" %in% names(x) || !"STAND" %in% names(x)) stop("STAND or SCORE_MINDBH_USED absent")
  smd <- setNames(x$SCORE_MINDBH_USED, as.character(x$STAND))
  one <- function(f) { g <- fread(f, colClasses = list(character = "STAND"))[STAND %in% names(smd)]
    if (!all(c("STAND", "DBH", "HT", "EXPF") %in% names(g))) stop("frame columns absent in ", basename(f))
    g[, { m <- smd[[.BY$STAND]]; pub <- top_sel(DBH, EXPF, m); me <- which(is.finite(HT)); s2 <- me[top_sel(DBH[me], EXPF[me], m)]
      .(top_M = if (length(s2)) mean(HT[s2]) else NA_real_, n_top = length(pub), n_top_himp = sum(!is.finite(HT[pub]))) }, by = STAND] }
  a <- one(FI); b <- one(FG); z <- merge(a, b, by = "STAND", suffixes = c("_1", "_2")); z <- z[is.finite(top_M_1) & is.finite(top_M_2)]
  dM <- z$top_M_1 - z$top_M_2; hM <- dM > 0
  list(F_HT_M = if (any(hM)) unname(quantile(dM[hM], 0.99)) else NA_real_, S_HT_M = as.integer(ceiling(NST * mean(dM > 0.01))), stands_M = nrow(z),
    himp_share_t1 = sum(a$n_top_himp) / sum(a$n_top), himp_share_t2 = sum(b$n_top_himp) / sum(b$n_top), note = "computed")
}, error = function(e) list(F_HT_M = NA_real_, S_HT_M = NA_real_, stands_M = NA_real_, himp_share_t1 = NA_real_, himp_share_t2 = NA_real_, note = conditionMessage(e)))
T <- data.table(
  quantity = c("F_HT_m", "S_HT_stands", "admitted_stands", "stands_both_topht", "stands_with_decrease", "stands_decrease_over_0.01",
    "share_decrease_over_0.01", "decrease_q50_m", "decrease_q90_m", "decrease_q95_m", "decrease_q99_m", "decrease_max_m",
    "interval_min_yr", "interval_q10_yr", "interval_q50_yr", "interval_q90_yr", "interval_max_yr", "interval_median_decreasing_yr",
    "REPORTED_F_HT_M_measured_only_m", "REPORTED_S_HT_M_measured_only_stands", "REPORTED_stands_M", "REPORTED_himp_share_top_trees_t1", "REPORTED_himp_share_top_trees_t2", "MG_LO_m_yr", "inc_stands", "inc_q10_m_yr", "inc_q50_m_yr", "inc_q90_m_yr"),
  value = c(F_HT, S_HT, nrow(x), nrow(y), sum(has), sum(dec > 0.01), share, unname(dq), unname(ivq), ivd,
    VM$F_HT_M, VM$S_HT_M, VM$stands_M, VM$himp_share_t1, VM$himp_share_t2, MG_LO, sum(okv), unname(incq)))
T[, `:=`(variant_M_note = VM$note, interval_column = if (length(ic)) ic[1] else "none found", grid_stands = NST, md5_input = md5(SRC),
  source = "frozen p19_a0111 qc_c results, observed TOPHT_t1 and TOPHT_o, admitted esi8 finite and above 2",
  procedure = "F_HT q99 (type 7) of t1 minus t2 TOPHT over stands with a decrease; S_HT ceiling(36 x share with decrease over 0.01 m)")]
fwrite(T, OUT)
stamp <- format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
writeLines(sprintf("%s  plan/thresholds_p47_DATA.csv  written by thresholds_p47.R (md5 %s) at %s, before any PREREG47 reading",
  md5(OUT), md5(file.path(J, "scripts/thresholds_p47.R")), stamp), MD)
print(T[, .(quantity, value)], digits = 6); cat(readLines(MD), sep = "\n"); cat("P47_THRESHOLDS_DONE\n")

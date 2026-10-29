## PREREG49 trace gate TR (PREREG45 ST1 and PREREG46 TR pattern): recompute the traced survival from the form and the frozen fit,
## two stands, three years each. For every record traced in years 1 to 3 of each stand: (a) the cumulative engine hazard H is
## recomputed from the record's earlier traced calls as the sum of -log(1 - dexpf_eng/expf) (0 at the first call and at a
## record's first call) and compared with the H the overlay used; (b) the realized annual survival, expf at the next call over
## expf at this call, is compared with 1 - (1 - p)/(1 + theta H), p = 1 - dexpf_eng/expf, theta read from the fit file (records
## that reach the engine's 1e-5 expansion floor are excluded and counted). Pass: both worst absolute differences below 1e-12,
## 2 stands with 3 checked years each, and some record with H > 0. Writes aggregates only.
## Usage: Rscript tr_check_p49.R TRACE FITFILE RESULT. No coordinates. No em dashes.
suppressMessages(library(data.table)); a <- commandArgs(TRUE)
if (file.exists(a[3])) stop("REFUSE ", a[3])
th <- fread(a[2])$estimate; stopifnot(length(th) == 1L, is.finite(th))
x <- fread(a[1], colClasses = list(character = "STAND")); x[, s := as.integer(factor(STAND))]
x[, h := fifelse(is.finite(expf) & expf > 0 & is.finite(1 - dexpf_eng / expf), -log(pmin(1, pmax(1 - dexpf_eng / expf, 1e-12))), 0)]
setorder(x, s, tree, call); x[, Hrec := cumsum(h) - h, by = .(s, tree)]
nx <- x[, .(s, tree, call = call - 1L, expf_next = expf)]
y <- merge(x[call <= 3], nx, by = c("s", "tree", "call"), all.x = TRUE)
y[, p := 1 - dexpf_eng / expf][, s_form := 1 - (1 - p) / (1 + th * H)][, s_real := expf_next / expf][, floored := expf_next <= 1e-5 * (1 + 1e-9)]
ev <- y[is.finite(expf_next) & !floored]
out <- data.table(gate = "TR", theta = th, stands = uniqueN(x$s), years_checked_min = y[, uniqueN(call), by = s][, min(V1)],
  rows_checked = nrow(ev), rows_floored = y[floored == TRUE, .N], rows_no_next = y[!is.finite(expf_next), .N], rows_H_pos = y[H > 0, .N],
  worst_abs_H = max(abs(y$H - y$Hrec)), worst_abs_surv = max(abs(ev$s_real - ev$s_form)), ann_surv_min = min(ev$s_real))
out[, pass := stands == 2L & years_checked_min == 3L & rows_H_pos > 0 & worst_abs_H < 1e-12 & worst_abs_surv < 1e-12]
print(out); fwrite(out, a[3]); if (!out$pass) quit(status = 1); cat("TR_PASS\n")

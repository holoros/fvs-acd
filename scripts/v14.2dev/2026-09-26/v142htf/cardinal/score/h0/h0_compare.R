## PREREG11 H0: baxter_c v141LTh (firebreather, R 4.5.1) against Cardinal v141LT (R 4.5.2). Deviation from md5: tolerance 1e-9. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths())); suppressMessages(library(data.table))
H <- "~/magplot/verify/gydbreg20260916/v142_20260925"
a <- fread(file.path(H, "recs/htfix/fbout/h0/v141LTh_baxter_c_c001_results.csv"))
b <- fread(file.path(H, "bench141/results/v141LT/gyr_v141LT_baxter_c_results.csv"))
stopifnot(identical(names(a), names(b)), nrow(a) == nrow(b))
num <- names(a)[vapply(a, is.numeric, TRUE)]; chr <- setdiff(names(a), num)
chr_ok <- all(vapply(chr, function(k) identical(a[[k]], b[[k]]), TRUE))
na_ok <- all(vapply(num, function(k) identical(is.na(a[[k]]), is.na(b[[k]])), TRUE))
d <- rbindlist(lapply(num, function(k) { x <- a[[k]]; y <- b[[k]]; ok <- is.finite(x) & is.finite(y)
  data.table(col = k, max_abs = if (any(ok)) max(abs(x[ok] - y[ok])) else 0, max_rel = if (any(ok)) max(abs(x[ok] - y[ok]) / pmax(1, abs(y[ok]))) else 0) }))
cat(sprintf("rows %d, cols %d numeric %d, char identical %s, NA pattern identical %s\n", nrow(a), ncol(a), length(num), chr_ok, na_ok))
print(d[order(-max_rel)][1:5]); worst <- max(d$max_rel)
v <- chr_ok && na_ok && worst <= 1e-9
cat(sprintf("H0 %s: worst scaled difference %.3g (tolerance 1e-9)\n", if (v) "PASS" else "FAIL", worst))
fwrite(d, file.path(H, "recs/htfix/score/h0/gyr142-htfix-h0_DATA_2026-09-26.csv"))

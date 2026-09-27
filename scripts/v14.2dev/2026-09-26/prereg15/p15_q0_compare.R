## PREREG15 Q0: frozen mnap_c rerun on firebreather (R 4.5.1) vs Cardinal bench141 v141LT mnap_c (R 4.5.2).
## Copy of recs/htfix/score/h0/h0_compare.R (md5 db1e0508); changes: file paths from the command line, optional
## restriction of the reference to the rerun's STAND rows (smoke), .libPaths line dropped, verdict written to a file.
## Statistic and tolerance untouched (1e-9 scaled). No em dashes.
## Usage: Rscript p15_q0_compare.R <rerun results> <cardinal results> <out csv> [subset]
suppressMessages(library(data.table))
args <- commandArgs(TRUE); a <- fread(args[1]); b <- fread(args[2]); OUTF <- args[3]
if (length(args) >= 4 && args[4] == "subset") b <- b[match(a$STAND, b$STAND)]
stopifnot(identical(names(a), names(b)), nrow(a) == nrow(b))
num <- names(a)[vapply(a, is.numeric, TRUE)]; chr <- setdiff(names(a), num)
chr_ok <- all(vapply(chr, function(k) identical(a[[k]], b[[k]]), TRUE))
na_ok <- all(vapply(num, function(k) identical(is.na(a[[k]]), is.na(b[[k]])), TRUE))
d <- rbindlist(lapply(num, function(k) { x <- a[[k]]; y <- b[[k]]; ok <- is.finite(x) & is.finite(y)
  data.table(col = k, max_abs = if (any(ok)) max(abs(x[ok] - y[ok])) else 0, max_rel = if (any(ok)) max(abs(x[ok] - y[ok]) / pmax(1, abs(y[ok]))) else 0) }))
cat(sprintf("rows %d, cols %d numeric %d, char identical %s, NA pattern identical %s\n", nrow(a), ncol(a), length(num), chr_ok, na_ok))
print(d[order(-max_rel)][1:5]); worst <- max(d$max_rel)
v <- chr_ok && na_ok && worst <= 1e-9
cat(sprintf("Q0 %s: worst scaled difference %.3g (tolerance 1e-9)\n", if (v) "PASS" else "FAIL", worst))
fwrite(d, OUTF)
if (!v) quit(status = 1)

## PREREG46 gate G0x: driver_p46 arm qc_rh (form exp) on the PREREG44 S1 list against the frozen PREREG45 trajectory. Every numeric
## column compared after sorting by cell and age; worst scaled difference |x - y| / max(1, |y|) at or below 1e-9. The exp branch
## keeps the PREREG45 expression b * ht / cs, so the expected difference is 0. Aggregates only.
suppressMessages(library(data.table)); a <- commandArgs(TRUE)
x <- fread(a[1], colClasses = list(character = "STAND")); y <- fread(a[2], colClasses = list(character = "STAND"))
k <- intersect(c("cell", "STAND", "age"), names(y)); setorderv(x, k); setorderv(y, k)
ok_shape <- nrow(x) == nrow(y) && identical(sort(names(x)), sort(names(y)))
num <- names(y)[sapply(y, is.numeric)]; w <- if (ok_shape) max(sapply(num, function(v) max(abs(x[[v]] - y[[v]]) / pmax(1, abs(y[[v]])), na.rm = TRUE))) else Inf
nan_mismatch <- if (ok_shape) sum(sapply(num, function(v) sum(is.na(x[[v]]) != is.na(y[[v]])))) else NA
out <- data.table(gate = "G0x", rows = nrow(x), rows_ref = nrow(y), same_columns = ok_shape, worst_scaled = w, na_mismatch = nan_mismatch, pass = ok_shape && w <= 1e-9 && nan_mismatch == 0)
print(out); fwrite(out, a[3]); if (!out$pass) quit(status = 1)

## PREREG49 G0 (PREREG44 G0, g0_cmp_p26.R pattern): driver_p49.R mode g0, arm v141LTfi, switch off (overlay not sourced), on the
## three PREREG26 G0 stands (read from ~/jobs/v142p26/dry/g0_v141LT.csv, md5 988dd346), against frozen v141LTfi ns_c results
## (PREREG22, md5 9fe608de); every _p column and ING_p; worst scaled |a - b| / max(1, |b|) at or below 1e-9. Writes the result;
## exits nonzero on failure. Usage: Rscript g0_cmp_p49.R NEW RESULT. No coordinates. No em dashes.
suppressMessages(library(data.table)); a <- commandArgs(TRUE); if (file.exists(a[2])) stop("REFUSE ", a[2])
FZ <- "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_c_results.csv"; stopifnot(unname(tools::md5sum(FZ)) == "9fe608de2e4261bd60d637019c83022e")
A <- fread(a[1], colClasses = list(character = "STAND")); B <- fread(FZ, colClasses = list(character = "STAND"))
pc <- unique(c(grep("_p$", names(A), value = TRUE), "ING_p")); m <- merge(A[, c("STAND", pc), with = FALSE], B[RUN_OK == 1, c("STAND", pc), with = FALSE], by = "STAND")
d <- sapply(pc, function(v) { x <- m[[paste0(v, ".x")]]; y <- m[[paste0(v, ".y")]]; if (any(is.na(x) != is.na(y))) Inf else max(abs(x - y)/pmax(1, abs(y)), 0, na.rm = TRUE) })
R <- data.table(gate = "G0", stands = nrow(m), requested = nrow(A), columns = length(pc), worst_scaled = max(d), worst_col = names(d)[which.max(d)], pass = nrow(m) == nrow(A) && nrow(m) >= 1 && max(d) <= 1e-9)
print(R); fwrite(R, a[2]); if (!R$pass) quit(status = 3); cat("G0_PASS\n")

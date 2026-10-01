## PREREG31 G0: driver_p31.R (mode g0, arm qc141) against frozen p19_a0111 qc_c results on its first three RUN_OK stands;
## every _p column the driver writes and ING_p; worst scaled |a - b| / max(1, |b|) <= 1e-9. Exits nonzero on failure. No coordinates.
suppressMessages(library(data.table)); a <- commandArgs(TRUE)
FZ <- "/home/aaron/jobs/v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"
stopifnot(as.character(tools::md5sum(FZ)) == "979101bedafe16c090ce84d1e5e46a07")
A <- fread(a[1]); B <- fread(FZ)
pc <- c(grep("_p$", names(A), value = TRUE)); m <- merge(A[, c("STAND", pc), with = FALSE], B[RUN_OK == 1, c("STAND", pc), with = FALSE], by = "STAND")
d <- sapply(pc, function(v) { x <- m[[paste0(v, ".x")]]; y <- m[[paste0(v, ".y")]]; if (any(is.na(x) != is.na(y))) Inf else max(abs(x - y)/pmax(1, abs(y)), 0, na.rm = TRUE) })
R <- data.table(gate = "G0", stands = nrow(m), requested = nrow(A), columns = length(pc), worst_scaled = max(d), worst_col = names(d)[which.max(d)], pass = nrow(m) == nrow(A) && nrow(m) >= 1 && max(d) <= 1e-9)
print(R); if (file.exists(a[2])) stop("REFUSE ", a[2]); fwrite(R, a[2]); if (!R$pass) quit(status = 3); cat("G0_PASS\n")

## PREREG26 G0: driver_p26.R (mode g0, v141LT) against frozen Cardinal v141LT ns_c chunk 1; every _p column and ING_p;
## worst scaled |a - b| / max(1, |b|) <= 1e-9. Exits nonzero on failure. No coordinates.
suppressMessages(library(data.table)); a <- commandArgs(TRUE)
A <- fread(a[1]); B <- fread("/home/aaron/jobs/v142p22/in/xfer/cardinal_v141LT_ns_c_c001_results.csv")
stopifnot(as.character(tools::md5sum("/home/aaron/jobs/v142p22/in/xfer/cardinal_v141LT_ns_c_c001_results.csv")) == "a31786f85685f36c3cb57c5a722adbee")
pc <- c(grep("_p$", names(A), value = TRUE)); m <- merge(A[, c("STAND", pc), with = FALSE], B[RUN_OK == 1, c("STAND", pc), with = FALSE], by = "STAND")
d <- sapply(pc, function(v) { x <- m[[paste0(v, ".x")]]; y <- m[[paste0(v, ".y")]]; if (any(is.na(x) != is.na(y))) Inf else max(abs(x - y)/pmax(1, abs(y)), 0, na.rm = TRUE) })
R <- data.table(gate = "G0", stands = nrow(m), requested = nrow(A), columns = length(pc), worst_scaled = max(d), worst_col = names(d)[which.max(d)], pass = nrow(m) == nrow(A) && nrow(m) >= 1 && max(d) <= 1e-9)
print(R); fwrite(R, a[2]); if (!R$pass) quit(status = 3); cat("G0_PASS\n")

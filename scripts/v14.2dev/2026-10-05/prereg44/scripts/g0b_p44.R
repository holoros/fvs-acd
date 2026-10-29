## PREREG44 G0b: the grid mode of driver_p44.R reproduces the frozen PREREG31 dry trajectory (qc141, MX_E19.8_N6000, 100 years)
## exactly, every numeric column, tolerance 0. Exits nonzero on failure. Usage: Rscript g0b_p44.R NEW RESULT. No coordinates.
suppressMessages(library(data.table)); a <- commandArgs(TRUE)
FZ <- "/home/aaron/jobs/v142p31/dry/dry_qc141_MX_E19.8_N6000.csv"; fz_md5 <- unname(tools::md5sum(FZ))
A <- fread(a[1]); B <- fread(FZ); num <- names(B)[sapply(B, is.numeric)]
same <- nrow(A) == nrow(B) && all(num %in% names(A)) && isTRUE(all.equal(as.matrix(A[, ..num]), as.matrix(B[, ..num]), tolerance = 0, check.attributes = FALSE))
R <- data.table(gate = "G0b", rows_new = nrow(A), rows_frozen = nrow(B), columns = length(num), frozen_md5 = fz_md5, pass = same)
print(R); if (file.exists(a[2])) stop("REFUSE ", a[2]); fwrite(R, a[2]); if (!same) quit(status = 3); cat("G0B_PASS\n")

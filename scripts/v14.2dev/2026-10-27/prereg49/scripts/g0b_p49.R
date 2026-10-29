## PREREG49 G0b (PREREG44 G0b, g0b_p44.R pattern): driver_p49.R mode grid, arm v141LTfi, switch off, run on the full PREREG26
## balsam fir cell file (plan/cells_BF.csv, md5 04f96034, so the run repeats the frozen run's conditions), against the frozen
## PREREG26 trajectory (~/jobs/v142p26/out/traj_v141LTfi_BF.csv, md5 b10a03bb; seed 20260930 kept in the driver). Gate: the balsam
## fir 6,000 trees per ha cells identical in every numeric column (tolerance 0); the whole file's identity is reported.
## Usage: Rscript g0b_p49.R NEW RESULT. No coordinates. No em dashes.
suppressMessages(library(data.table)); a <- commandArgs(TRUE); if (file.exists(a[2])) stop("REFUSE ", a[2])
FZ <- "/home/aaron/jobs/v142p26/out/traj_v141LTfi_BF.csv"; fz_md5 <- unname(tools::md5sum(FZ)); stopifnot(fz_md5 == "b10a03bb2be602196c18838afb2fc8aa")
A <- fread(a[1]); B <- fread(FZ); num <- names(B)[sapply(B, is.numeric)]
same <- function(x, y) nrow(x) == nrow(y) && nrow(x) > 0 && all(num %in% names(x)) && isTRUE(all.equal(as.matrix(x[, ..num]), as.matrix(y[, ..num]), tolerance = 0, check.attributes = FALSE)) && identical(x$cell, y$cell)
a6 <- A[n0 == 6000]; b6 <- B[n0 == 6000]
R <- data.table(gate = "G0b", cells_N6000 = uniqueN(b6$cell), rows_new_N6000 = nrow(a6), rows_frozen_N6000 = nrow(b6), columns = length(num), frozen_md5 = fz_md5,
  whole_file_identical = same(A, B), rows_new = nrow(A), rows_frozen = nrow(B), pass = same(a6, b6))
print(R); fwrite(R, a[2]); if (!R$pass) quit(status = 3); cat("G0B_PASS\n")

## PREREG15 TST files. Copy of the bench141 tstfile rule for the Maine sources with no treatment records (block
## "Maine sources with no treatment records" of 2026-09-25_v142_bench141_tstfile.R, md5 67ef9e07): TST = NEVER for
## MANAGED 0, UNKNOWN for MANAGED 1. Frozen set: the Cardinal bench141 file verbatim. Identifiers only. No em dashes.
suppressMessages(library(data.table))
H <- path.expand("~/jobs/v142p15"); FR <- file.path(H, "home/magplot/verify/gydbreg20260916/frames"); WK <- file.path(H, "home/work")
wrt <- function(x, s) {
  out <- x[, .(STAND, TST)]
  f <- file.path(WK, sprintf("v142_p15_tst_%s_DATA_2026-09-26.csv", s))
  if (file.exists(f)) stop("REFUSE overwrite ", f)
  fwrite(out, f); cat(sprintf("[%s] %d stands, %s\n", s, nrow(out), paste(names(table(out$TST)), table(out$TST), collapse = " ")))
}
for (s in c("mnap_c", "mnap_tnc_c")) {
  pr <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)))
  wrt(pr[, .(STAND, TST = fifelse(MANAGED == 0, "NEVER", "UNKNOWN"))], s)
}
## frozen: verbatim copy, and a check that the rule regenerates it byte for byte
f0 <- file.path(H, "in/cardinal/v142_bench141_tst_mnap_c_DATA_2026-09-25.csv")
f1 <- file.path(WK, "v142_p15_tst_mnapfrz_c_DATA_2026-09-26.csv")
if (file.exists(f1)) stop("REFUSE overwrite ", f1)
file.copy(f0, f1)
pr <- fread(file.path(FR, "bench_gyr_mnapfrz_c_pairs.csv")); tmp <- tempfile(fileext = ".csv")
fwrite(pr[, .(STAND, TST = fifelse(MANAGED == 0, "NEVER", "UNKNOWN"))], tmp)
cat(sprintf("frozen tst: verbatim md5 %s, rule regenerates it: %s\n", unname(tools::md5sum(f1)),
            identical(unname(tools::md5sum(tmp)), unname(tools::md5sum(f0)))))
cat("TSTFILE_DONE\n")

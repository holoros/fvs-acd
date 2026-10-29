## Replace the 5 failed rows with their retry rows; everything else byte for byte from the first run. No em dashes.
suppressMessages(library(data.table)); dir.create("results_r1/v141LT", recursive = TRUE, showWarnings = FALSE)
for (s in c("mnap_c", "mnap_tnc_c", "mnapfrz_c")) {
  f <- sprintf("results/v141LT/gyr_v141LT_%s_results.csv", s); o <- sprintf("results_r1/v141LT/gyr_v141LT_%s_results.csv", s)
  if (s == "mnapfrz_c") { file.copy(f, o); next }
  a <- fread(f); r <- fread(sprintf("home/out_retry/v141LT/%s/c900_results.csv", s)); bad <- a[RUN_OK != 1 | is.na(RUN_OK), STAND]
  stopifnot(all(bad %in% r$STAND), identical(names(a), names(r)))
  for (st in bad) a[STAND == st] <- r[STAND == st]
  cat(s, "replaced", length(bad), "rows; RUN_OK all 1:", all(a$RUN_OK == 1), "\n"); fwrite(a, o) }

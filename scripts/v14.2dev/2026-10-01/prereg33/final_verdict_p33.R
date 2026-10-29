## PREREG33 decision rule, in order, from the benchmark and grid verdict files. Writes assembled/gyr142-p33-final-verdict_DATA_2026-10-01.txt. No em dashes.
J <- "/home/aaron/jobs/v142p33"; O <- file.path(J, "assembled/gyr142-p33-final-verdict_DATA_2026-10-01.txt"); if (file.exists(O)) stop("REFUSE")
b <- readLines(file.path(J, "assembled/bench/gyr142-p33-verdict_DATA_2026-10-01.txt")); g <- readLines(file.path(J, "assembled/grid/gyr142-p33grid-verdict_DATA_2026-10-01.txt"))
kv <- function(x, k) sub(paste0("^", k, "="), "", grep(paste0("^", k, "="), x, value = TRUE))
bh <- kv(b, "harness_ok") == "TRUE"; bp <- kv(b, "bench_pass") == "TRUE"; go <- kv(g, "outcome")
rule <- if (!bh || go == "GRID_HARNESS_FAILURE") "Rule 1: harness failure; no verdict" else
  if (!bp) paste0("Rule 2: a benchmark gate fails; not adopted. ", kv(b, "verdict")) else
  if (go == "NI_FAIL") paste0("Rule 3: benchmark passes and non inferiority fails; not cleared. new_flag_units=", kv(g, "new_flag_units"), " marginB_fail_relations=", kv(g, "marginB_fail_relations")) else
  "Rule 4: benchmark and non inferiority pass; the dynamic anchor is the 14.2 QC candidate cleared for release consideration as a QC regional setting"
writeLines(c(paste0("bench_verdict=", kv(b, "verdict")), paste0("grid_outcome=", go), paste0("final=", rule)), O); cat(rule, "\nP33_FINAL_DONE\n")

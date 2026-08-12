# Byte-level comparison of the 11 August v13.0 artifacts against the 12 August
# frozen-base rebuild. Run on Cardinal in ~/magplot/verify. Aggregates only.
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
cmp <- function(a, b) {
  if (!file.exists(a) || !file.exists(b)) return(sprintf("%-34s vs %-30s  MISSING", basename(a), basename(b)))
  A <- fread(a); B <- fread(b); setkey(A, STAND); setkey(B, STAND)
  if (nrow(A) != nrow(B)) return(sprintf("%-34s vs %-30s  ROWS %d/%d", basename(a), basename(b), nrow(A), nrow(B)))
  cols <- intersect(names(A), names(B)); cols <- cols[sapply(A[, ..cols], is.numeric)]
  d <- max(sapply(cols, function(cc) max(abs(A[[cc]] - B[[cc]]), na.rm = TRUE)))
  sprintf("%-34s vs %-30s  max|diff| = %.6g", basename(a), basename(b), d)
}
pairs <- list(
  c("cb_G_wide_jointrefit_g0_results.csv", "cb_v130null_results.csv"),
  c("cb_G_wide_jointrefit_g0_results.csv", "cb_v130honly_results.csv"),
  c("cb_F_null_noafac_results.csv",         "cb_v130null_results.csv"),
  c("cb_E_both_results.csv",                "cb_v130b100_results.csv"),
  c("cb_C_baonly_results.csv",              "cb_v130null_results.csv"),
  c("cb_D_honly_results.csv",               "cb_v130honly_results.csv"))
for (x in pairs) cat(cmp(x[1], x[2]), "\n")
cat("DONE_CMP\n")

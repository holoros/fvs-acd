## PREREG38 fit, fold A only: QC_AFAC_FIT = round(pooled field tag R on screened qc_c fold A, 3), read from the PREREG37
## assembled fold A ratio file and checked against the PREREG37 verifier comparison row. Reads no fold B value. Refuses to
## overwrite. No coordinates. No em dashes.
suppressMessages(library(data.table))
J <- "/home/aaron/jobs/v142p38"; P37 <- "/home/aaron/jobs/v142p37"
fa <- file.path(P37, "assembled/gyr142-p37-ratio-foldA_DATA_2026-10-01.csv")
fv <- file.path(P37, "verify_20261001/p37_verify_compare_DATA_2026-10-01.csv")
if (unname(tools::md5sum(fa)) != "2315212d0cd4ef05f50e288f892a5ed8") stop("PREREG37 fold A ratio file md5 differs")
out <- file.path(J, "fit/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv"); if (file.exists(out)) stop("REFUSE ", out)
r <- fread(fa)[tagkey == "field tag" & scheme == "all" & group == "all"]
if (nrow(r) != 1) stop("expected one field tag pooled row, got ", nrow(r))
v <- fread(fv)[fold == "A" & tagkey == "field" & item == "R all all"]
if (nrow(v) != 1) stop("verifier row not found")
if (abs(v$mine - r$R) > 1e-12 || abs(v$theirs - r$R) > 1e-12) stop("fold A R differs from the PREREG37 verifier row")
fit <- round(r$R, 3)
res <- data.table(item = "QC_AFAC_FIT", value = sprintf("%.3f", fit), R_foldA = sprintf("%.15f", r$R), R_lo = r$R_lo, R_hi = r$R_hi,
  records = r$trees, sites = r$sites, source = fa, source_md5 = unname(tools::md5sum(fa)), verifier_file = fv, verifier_md5 = unname(tools::md5sum(fv)))
dir.create(dirname(out), showWarnings = FALSE); fwrite(res, out); print(res)
cat("P38_FIT_DONE", sprintf("%.3f", fit), "\n")

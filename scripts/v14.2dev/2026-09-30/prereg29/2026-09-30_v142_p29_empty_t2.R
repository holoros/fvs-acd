## PREREG29 side item, read only: stands with RUN_OK 1 and no observed trees at t2 (BA_o == 0, QMD_o == 0 or TOTVOL_o == 0)
## in the frozen v141LT benchmark results. The v141LT results for most sets live on Cardinal and are not on firebreather;
## the PREREG16 volconv stands table (v142p18/in/cardinal, one row per scored stand, V_o = TOTVOL_o to 1e-6 by the V0
## gate) is used for all 19 labels, and every results file that is on firebreather is read directly for BA_o, QMD_o and
## TOTVOL_o. For NS sets the observed columns are read from the frozen v141LTf results (observed side is engine
## independent). Admission follows the volconv scorer rule: scored = RUN_OK == 1 & is.finite(TOTVOL_o) & is.finite(TOTVOL_p).
## No coordinates. No em dashes.
suppressMessages(library(data.table)); options(width = 220)
J <- "/home/aaron/jobs/v142p29_nsrs"; O <- file.path(J, "side"); if (dir.exists(O)) stop("REFUSE ", O); dir.create(O)
VC <- fread("/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv")[arm == "v141LT"]
A <- VC[, .(scored_stands = .N, V_o_zero = sum(V_o == 0), V_o_na = sum(!is.finite(V_o)), stands_zero = paste(STAND[V_o == 0], collapse = ";")), by = label][order(label)]
fwrite(A, file.path(O, "p29-side-volconv-vo-zero_DATA_2026-09-30.csv")); print(A[, .(label, scored_stands, V_o_zero, V_o_na)])
fl <- c(nb_c = "/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv",
  qc_c = "/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_qc_c_results.csv",
  qc_fl = "/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_qc_fl_results.csv",
  mnap_c = "/home/aaron/jobs/v142p15/results_r1/v141LT/gyr_v141LT_mnap_c_results.csv",
  mnap_tnc_c = "/home/aaron/jobs/v142p15/results_r1/v141LT/gyr_v141LT_mnap_tnc_c_results.csv",
  mnapfrz_c = "/home/aaron/jobs/v142p15/results_r1/v141LT/gyr_v141LT_mnapfrz_c_results.csv",
  ns_c = "/home/aaron/jobs/v142p20/results/v141LTf/gyr_v141LTf_ns_c_results.csv", ns_fl = "/home/aaron/jobs/v142p20/results/v141LTf/gyr_v141LTf_ns_fl_results.csv",
  ns_long_c = "/home/aaron/jobs/v142p20/results/v141LTf/gyr_v141LTf_ns_long_c_results.csv", ns_long_fl = "/home/aaron/jobs/v142p20/results/v141LTf/gyr_v141LTf_ns_long_fl_results.csv")
R <- rbindlist(lapply(names(fl), function(s) { r <- fread(fl[[s]], select = c("STAND", "RUN_OK", "BA_o", "QMD_o", "TOTVOL_o", "TOTVOL_p"))
  z <- r[RUN_OK == 1 & ((is.finite(BA_o) & BA_o == 0) | (is.finite(QMD_o) & QMD_o == 0) | (is.finite(TOTVOL_o) & TOTVOL_o == 0) | is.na(QMD_o))]
  data.table(set = s, file = basename(fl[[s]]), md5 = unname(tools::md5sum(fl[[s]])), run_ok = r[RUN_OK == 1, .N], empty_t2 = nrow(z),
    ba0 = z[is.finite(BA_o) & BA_o == 0, .N], qmd0_or_na = z[!is.finite(QMD_o) | QMD_o == 0, .N], totvol0 = z[is.finite(TOTVOL_o) & TOTVOL_o == 0, .N],
    admitted_by_scorer = z[is.finite(TOTVOL_o) & is.finite(TOTVOL_p), .N], stands = paste(z$STAND, collapse = ";")) }))
fwrite(R, file.path(O, "p29-side-results-empty-t2_DATA_2026-09-30.csv")); print(R[, !"stands"]); print(R[empty_t2 > 0 & empty_t2 < 6, .(set, stands)])
cat("P29_SIDE_DONE\n")

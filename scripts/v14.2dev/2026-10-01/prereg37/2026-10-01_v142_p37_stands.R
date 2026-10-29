## PREREG37 stand lists per fold (no model output read): PREREG28 population, RUN_OK qc_c stands of the PREREG19 p19_a0111
## results with the PREREG19 cut flag FALSE, via stand_frame of the PREREG23 helper (sourced read only). Writes SERVERONLY
## stand lists (identifiers) and an aggregate count file. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p28/scripts/2026-09-29_v142_p23_hkey.R")
J <- "/home/aaron/jobs/v142p37"; f_out <- function(n) { f <- file.path(J, n); if (file.exists(f)) stop("REFUSE ", f); f }
RES <- file.path(P19, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"); CUTF <- file.path(P19, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv")
S <- stand_frame(RES, "qc_c", CUTF)[cut == FALSE]
for (fd in c("A", "B")) fwrite(S[fold == fd, .(STAND, SITE, fold)], f_out(sprintf("tables/gyr142-p37-stands_SERVERONLY_fold%s_2026-10-01.csv", fd)))
fwrite(S[, .(stands = .N, sites = uniqueN(SITE)), by = fold][order(fold)], f_out("tables/gyr142-p37-stands-count_DATA_2026-10-01.csv"))
print(S[, .(stands = .N, sites = uniqueN(SITE)), by = fold]); cat("P37_STANDS_DONE\n")

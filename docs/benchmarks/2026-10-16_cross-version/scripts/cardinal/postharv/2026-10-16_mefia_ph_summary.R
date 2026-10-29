## 2026-10-16_mefia_ph_summary.R
## Completion and biomass sanity summary for the mefia_ph_c hindcast array (arms v131h, v141LT, v141off).
## BIOMASS is NSVB DRYBIO_AG, Mg/ha, from the runner results (t1, observed t2, predicted t2). Harvest type from the
## r1 classification. Writes postharv/out/mefia_ph_summary_DATA_2026-10-16.csv. No coordinates. No em dashes.
suppressMessages(library(data.table))
R1 <- "/users/PUOM0008/crsfaaron/acdx_20261016/postharv"
fo <- file.path(R1, "out", "mefia_ph_summary_DATA_2026-10-16.csv"); if (file.exists(fo)) stop("refusing to overwrite ", fo)
cl <- fread(file.path(R1, "work", "mefia_ph_class_DATA_2026-10-16_r1.csv"))[, .(STAND, HARVEST_TYPE)]
pr <- fread(file.path(R1, "work", "bench_gyr_mefia_ph_c_pairs.csv"))
res <- rbindlist(lapply(c("v131h", "v141LT", "v141off"), function(a) {
  fs <- list.files(file.path(R1, "out", a, "mefia_ph_c"), pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE)
  d <- rbindlist(lapply(fs, fread), fill = TRUE); d[, arm := a]; d[, nfile := length(fs)]; d }), fill = TRUE)
cat("rows per arm, RUN_OK, failures, duplicates, coverage of the frame:\n")
print(res[, .(files = nfile[1], rows = .N, run_ok = sum(RUN_OK == 1), fail = sum(RUN_OK != 1), dup = sum(duplicated(STAND)),
              missing_from_frame = sum(!(pr$STAND %in% STAND))), by = arm])
if (res[RUN_OK != 1, .N]) { cat("failure reasons:\n"); print(res[RUN_OK != 1, .N, by = .(arm, FAIL_REASON)]) }
res <- merge(res, cl, by = "STAND", all.x = TRUE)
s <- rbind(res[RUN_OK == 1, .(n = .N, BIOMASS_t1 = mean(BIOMASS_t1), BIOMASS_o = mean(BIOMASS_o), BIOMASS_p = mean(BIOMASS_p)), by = .(arm, HARVEST_TYPE)],
           res[RUN_OK == 1, .(HARVEST_TYPE = "all", n = .N, BIOMASS_t1 = mean(BIOMASS_t1), BIOMASS_o = mean(BIOMASS_o), BIOMASS_p = mean(BIOMASS_p)), by = arm])
s[, `:=`(BIAS_p_minus_o = BIOMASS_p - BIOMASS_o, PCT_BIAS = 100 * (BIOMASS_p - BIOMASS_o) / BIOMASS_o)]
num <- names(s)[sapply(s, is.numeric) & names(s) != "n"]; s[, (num) := lapply(.SD, round, 2), .SDcols = num]
setorder(s, arm, HARVEST_TYPE); print(s)
fwrite(s, fo); cat(sprintf("%s  %s\nSUMMARY_DONE\n", unname(tools::md5sum(fo)), fo))

suppressMessages(library(data.table)); options(width = 220)
T <- "tables/r2_fb"; CR <- "/home/aaron/jobs/v142vc/cardinal/tables_r1"; LAB <- c("nb_c", "qc_c", "qc_fl")
a <- fread(file.path(T, "gyr142-volconv-scores_DATA_2026-09-27.csv")); b <- fread(file.path(CR, "gyr142-volconv-scores_DATA_2026-09-27.csv"))[label %in% LAB & arm == "v141LT"]
m <- merge(a, b, by = c("label", "arm", "pop", "conv"), suffixes = c(".r2", ".cr"))
for (cc in c("stands", "ratio", "ratio_lo", "ratio_hi", "bias_pct", "rmse_pct", "rmse_lo", "rmse_hi")) m[, (paste0("d_", cc)) := abs(get(paste0(cc, ".r2")) - get(paste0(cc, ".cr")))]
print(m[, c("label", "pop", "conv", grep("^d_", names(m), value = TRUE)), with = FALSE])
print(fread(file.path(T, "gyr142-volconv-admission_DATA_2026-09-27.csv"))); print(fread(file.path(CR, "gyr142-volconv-admission_DATA_2026-09-27.csv"))[label %in% LAB])
print(fread(file.path(T, "gyr142-volconv-c2cov_DATA_2026-09-27.csv"))); print(fread(file.path(CR, "gyr142-volconv-c2cov_DATA_2026-09-27.csv"))[label %in% LAB])
s <- fread(file.path(T, "gyr142-volconv-stands_DATA_2026-09-27.csv")); t <- fread("/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv")[label %in% LAB & arm == "v141LT"]
s[, STAND := as.character(STAND)]; t[, STAND := as.character(STAND)]; z <- merge(s, t, by = c("label", "arm", "STAND"), suffixes = c(".r2", ".cr"))
for (cc in c("V_o", "V_p", "V_oh", "V_ph", "V_o2", "V_p2")) { d <- abs(z[[paste0(cc, ".r2")]] - z[[paste0(cc, ".cr")]]); cat(cc, "max", max(d, na.rm = TRUE), "n>1e-12", sum(d > 1e-12, na.rm = TRUE), "NA mismatch", sum(is.na(z[[paste0(cc, ".r2")]]) != is.na(z[[paste0(cc, ".cr")]])), "\n") }
print(z[, .(cut_diff = sum(cut.r2 != cut.cr)), by = label])

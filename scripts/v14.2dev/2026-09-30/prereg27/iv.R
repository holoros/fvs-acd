suppressMessages(library(data.table))
for (s in c("ns_c","ns_fl","ns_long_c","ns_long_fl")) { r <- fread(sprintf("/home/aaron/jobs/v142p18/results/v141LTig_m175/gyr_v141LTig_m175_%s_results.csv", s), select=c("STAND","interval_years","RUN_OK"))
 cat(s, nrow(r), "\n"); print(table(cut(r$interval_years, c(0,5,7,10,12,15,20,30,60)))) }
x <- fread("/home/aaron/jobs/v142p18/in/cardinal/gyr142-p17-stands_DATA_2026-09-27.csv"); print(x[, .N, by=.(label,arm)][grepl("^ns", label)])

## ST2 (post hoc stress test): gate C with the engine first year height offset removed. Offset per stand = qc141 HT(1) - HT(0)
## minus qc141's mean annual gain over years 1 to 100 (the jump not explained by growth); subtracted from every arm. Aggregates only.
suppressMessages(library(data.table))
rt <- function(d, ar) rbindlist(lapply(1:3, function(s) fread(file.path(d, sprintf("traj_%s_S%d.csv", ar, s)), colClasses = list(character = "STAND"))))
T <- rbind(rt("/home/aaron/jobs/v142p44/out", "qc141"), rt("/home/aaron/jobs/v142p44/out", "p38_fit"), rt("/home/aaron/jobs/v142p45/out", "qc_rh"), fill = TRUE)
r <- T[arm == "qc141", .(off = (HT[age == 1] - HT[age == 0]) - (HT[age == 100] - HT[age == 1]) / 99, off5 = HT[age == 5] - HT[age == 0]), by = cell]
Z <- merge(T[age == 100, .(arm, cell, esi, HT100 = HT)], r, by = "cell")
out <- Z[, .(stands = .N, median_off_m = median(off), median_rel100 = median(HT100 / esi), median_rel100_corr = median((HT100 - off) / esi),
  n_over = sum(HT100 / esi > 1.175), n_over_corr = sum((HT100 - off) / esi > 1.175)), by = arm]
out[, pass_C_corr := median_rel100_corr <= 1.175 & n_over_corr <= 3]; print(out); fwrite(out, "/home/aaron/jobs/v142p45st/assembled/st2_gatec-offset_DATA_2026-10-05.csv")
cross <- T[arm == "qc_rh", .(rel = median(HT / esi)), by = age][rel > 1.175][1]; print(cross)

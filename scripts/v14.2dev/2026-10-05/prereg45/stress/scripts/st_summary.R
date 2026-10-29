## Post hoc stress test summary (not registered): gate C and PREREG44 non inferiority for the ST3 and ST4 arms against frozen
## PREREG44 qc141, with qc_rh (PREREG45) and p38_fit for reference. relations() parsed from assemble_p44_r2.R. Aggregates only.
suppressMessages(library(data.table)); P44 <- "/home/aaron/jobs/v142p44"; J <- "/home/aaron/jobs/v142p45st"
L44 <- readLines(file.path(P44, "scripts/assemble_p44_r2.R")); i1 <- grep("^## ---------------- relations for one arm", L44); i2 <- grep("^## ---------------- harness gates", L44)
TH <- fread("/home/aaron/jobs/v142p31/assembled/thresholds_p31_DATA_2026-09-30.csv"); th <- setNames(TH$value, TH$quantity); ESIB <- 1:4; SDIB <- 1:3
frontTPH <- function(q) 10^(th[["frontier_a"]] + th[["frontier_b"]] * log10(q)); eval(parse(text = L44[(i1 + 1):(i2 - 1)]))
rt <- function(d, ar) rbindlist(lapply(1:3, function(s) fread(file.path(d, sprintf("traj_%s_S%d.csv", ar, s)), colClasses = list(character = "STAND"))))
ARMS <- c("qc_rh_blo", "qc_rh_bhi", "qc_rh_ing1"); have <- ARMS[sapply(ARMS, function(a) all(file.exists(file.path(J, "out", sprintf("traj_%s_S%d.csv", a, 1:3)))))]
TR <- rbind(rt(file.path(P44, "out"), "qc141"), rt(file.path(P44, "out"), "p38_fit"), rt("/home/aaron/jobs/v142p45/out", "qc_rh"), rbindlist(lapply(have, function(a) rt(file.path(J, "out"), a))), fill = TRUE)
REL <- rbindlist(lapply(unique(TR$arm), function(ar) { r <- relations(TR[arm == ar]); r[, arm := ar]; r }))
NI <- rbindlist(lapply(setdiff(unique(TR$arm), "qc141"), function(ar) { A <- merge(REL[arm == ar], REL[arm == "qc141"], by = c("relation", "unit"), suffixes = c("", "_ref"))
  B <- A[, .(new = sum(flag & !flag_ref), cw = if (any(flag)) max(margin[flag]) else 0, rw = if (any(flag_ref)) max(margin_ref[flag_ref]) else 0, cf = sum(flag)), by = relation]
  B[, ok := new == 0 & (cf == 0 | cw <= rw + 1e-9)]; data.table(arm = ar, ni_ok = all(B$ok), failing = paste(B[ok == FALSE]$relation, collapse = ";"), new_flags = sum(B$new)) }))
off <- TR[arm == "qc141", .(off = (HT[age == 1] - HT[age == 0]) - (HT[age == 100] - HT[age == 1]) / 99), by = cell]
CS <- merge(TR[age == 100, .(arm, cell, esi, HT100 = HT)], off, by = "cell")[, .(stands = .N, median_rel100 = median(HT100 / esi), n_over = sum(HT100 / esi > 1.175),
  median_rel100_corr = median((HT100 - off) / esi), n_over_corr = sum((HT100 - off) / esi > 1.175), mean_HT100 = mean(HT100)), by = arm]
DM <- TR[age == 100, .(DHTM_cohort = mean(as.numeric(DHTM_cohort), na.rm = TRUE), DHTM_ing = mean(as.numeric(DHTM_ing), na.rm = TRUE), ing_share_TPH = mean(TPH_ing / TPH_all)), by = arm]
OUT <- merge(merge(CS, NI, by = "arm", all.x = TRUE), DM, by = "arm"); OUT[, pass_C := median_rel100 <= 1.175 & n_over <= 3]
print(OUT); fwrite(OUT, file.path(J, "assembled/st_summary_DATA_2026-10-05.csv")); cat("arms present:", paste(have, collapse = ","), "\nST_SUMMARY_DONE\n")

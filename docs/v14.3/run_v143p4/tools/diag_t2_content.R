## PREREG4 post-selection diagnostic 2 (NOT registered; fold A only; frames only). Does the mefia_l_c t2 list hold only live
## trees? Among t1 trees found at t2 (same STAND, PLOT, TREE): share whose t2 DBH is not larger than t1 DBH over intervals that
## average about 20 yr, and the same by t1 size class. Aggregates only. No em dashes.
suppressMessages(library(data.table))
H <- "/users/PUOM0008/crsfaaron"; SO <- file.path(H, "v143p4/serveronly_SERVERONLY"); FR <- file.path(H, "magplot/verify/gydbreg20260916/frames")
fa <- fread(file.path(SO, "folds_mefia_l_c_SERVERONLY.csv"))[FOLD == "A", STAND]
I0 <- fread(file.path(FR, "bench_gyr_mefia_l_c_tree_init.csv"))[STAND %in% fa]
T2 <- fread(file.path(FR, "bench_gyr_mefia_l_c_tree_t2.csv"))[STAND %in% fa]
m <- merge(I0[, .(STAND, PLOT, TREE, D1 = DBH, E1 = EXPF, H1 = HT)], T2[, .(STAND, PLOT, TREE, D2 = DBH, E2 = EXPF, H2 = HT)], by = c("STAND", "PLOT", "TREE"))
cat(sprintf("t1 trees %d; found at t2 %d (%.4f); t2 trees %d of which new tags %d\n", nrow(I0), nrow(m), nrow(m) / nrow(I0), nrow(T2), nrow(T2) - nrow(m)))
cat(sprintf("found trees with t2 DBH <= t1 DBH: %.4f; with t2 DBH < t1 DBH: %.4f; with growth < 0.1 cm: %.4f\n", m[, mean(D2 <= D1)], m[, mean(D2 < D1)], m[, mean(D2 - D1 < 0.1)]))
m[, cls := cut(D1, c(0, 12.7, 25, 40, Inf), right = FALSE)]
print(m[, .(n = .N, share_no_growth = round(mean(D2 <= D1), 4), mean_ddbh_cm = round(mean(D2 - D1), 3), share_E2_ne_E1 = round(mean(abs(E2 - E1) > 1e-6), 4)), by = cls][order(cls)])
cat("names of the t2 file:", paste(names(T2), collapse = " "), "\n")

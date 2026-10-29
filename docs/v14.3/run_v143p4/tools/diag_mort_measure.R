## PREREG4 post-selection diagnostic (NOT registered; written after the selection record of 2026-10-28T06:26:05, reads fold A
## only and no candidate output). Question: does the trajectory hook's MORT_BA_S measure the same quantity as the observed basal
## area mortality? Uses the frozen bench141 v141LT hindcast (equal to arm g0 by gate H2) on fold A. Aggregates only. No em dashes.
suppressMessages(library(data.table))
H <- "/users/PUOM0008/crsfaaron"; SO <- file.path(H, "v143p4/serveronly_SERVERONLY")
B <- file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/out/v141LT/mefia_l_c")
fa <- fread(file.path(SO, "folds_mefia_l_c_SERVERONLY.csv"))[FOLD == "A", STAND]
om <- fread(file.path(SO, "obsmort_foldA_SERVERONLY.csv"))
tj <- rbindlist(lapply(list.files(B, "_traj\\.csv$", full.names = TRUE), fread))[STAND %in% fa]
rs <- rbindlist(lapply(list.files(B, "_results\\.csv$", full.names = TRUE), fread))[STAND %in% fa]
cat("traj yr values (counts):\n"); print(tj[, .N, by = yr][order(yr)])
first <- tj[, .SD[which.min(yr)], by = STAND]; last <- tj[, .SD[which.max(yr)], by = STAND]
x <- merge(last[, .(STAND, yr_last = yr, BA_last = BA, TPH_last = TPH, MORT_BA_S, MORT_BA_ALL, MORT_N_ALL, MORT_N_S, REC_N, REC_BA, CROSS_BA_INIT, CROSS_BA_REC)],
           first[, .(STAND, BA_0 = BA, TPH_0 = TPH)], by = "STAND")
x <- merge(x, rs[, .(STAND, iv, interval_years, BA_t1, BA_o, BA_p, SCORE_MINDBH_USED)], by = "STAND")
x <- merge(x, om, by = "STAND")
cat(sprintf("stands %d\n", nrow(x)))
s <- x[, lapply(.SD, mean), .SDcols = c("iv", "interval_years", "yr_last", "BA_0", "BA_t1", "BA_last", "BA_p", "BA_o", "MORT_BA_S", "MORT_BA_ALL", "OBS_MORT_BA", "REC_BA", "CROSS_BA_INIT", "CROSS_BA_REC", "TPH_0", "TPH_last", "MORT_N_ALL", "MORT_N_S", "REC_N")]
print(t(round(s, 4)))
cat(sprintf("mean predicted BA change (BA_p - BA_t1) %.4f; observed (BA_o - BA_t1) %.4f\n", x[, mean(BA_p - BA_t1)], x[, mean(BA_o - BA_t1)]))
cat(sprintf("TPH bookkeeping: mean (TPH_0 - TPH_last) %.2f against mean (MORT_N_ALL - REC_N) %.2f\n", x[, mean(TPH_0 - TPH_last)], x[, mean(MORT_N_ALL - REC_N)]))
cat(sprintf("share of t1 stems dead at t2, observed: %.4f (trees: dead / all, from the frame step)\n", x[, sum(N_DEAD) / sum(N_T1)]))
cat(sprintf("predicted stems died over t1 stems, MORT_N_ALL / TPH_0: %.4f\n", x[, sum(MORT_N_ALL) / sum(TPH_0)]))
cat("SCORE_MINDBH_USED distribution:\n"); print(x[, .N, by = SCORE_MINDBH_USED])

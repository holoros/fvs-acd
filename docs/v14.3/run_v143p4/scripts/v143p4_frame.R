## v143p4_frame.R, PREREG4 (md5 a15bd92a) step 3, frame. Folds by the PREREG11 rule (md5 of SITE, digest serialize FALSE,
## first hex digit even = A), fold A keep file, t1 class (plurality rule, the overlay's) and t1 Dq from the frame t1 lists,
## observed basal area mortality for FOLD A ONLY (fold B observed mortality is not computed here), t2 live-only check.
## Identifier files go to serveronly_SERVERONLY/; printed output is aggregates only. Refuses to overwrite. No em dashes.
suppressMessages({ library(data.table); library(digest) })
H <- "/users/PUOM0008/crsfaaron"; P <- file.path(H, "v143p4"); SO <- file.path(P, "serveronly_SERVERONLY"); W <- file.path(P, "work")
FR <- file.path(H, "magplot/verify/gydbreg20260916/frames"); L2P <- file.path(H, "acdx_20261016/long200/work/long200_mefia_l_c_pairs_DATA_2026-10-16.csv")
outs <- file.path(SO, c("folds_mefia_l_c_SERVERONLY.csv", "keep_foldA_SERVERONLY.csv", "t1_class_SERVERONLY.csv", "obsmort_foldA_SERVERONLY.csv", "folds_long200_SERVERONLY.csv"))
if (any(file.exists(outs))) stop("REFUSE: frame outputs exist")
fold_of <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
pr <- fread(file.path(FR, "bench_gyr_mefia_l_c_pairs.csv"), select = c("STAND", "SITE", "CHURN_FLAG", "TAG_STABLE"))
pr[, FOLD := fold_of(as.character(SITE))]
l2 <- fread(L2P, select = c("STAND", "SITE")); l2[, FOLD := fold_of(as.character(SITE))]
cat(sprintf("mefia_l_c pairs %d stands, %d sites; fold A %d stands (%d sites), fold B %d stands (%d sites)\n", nrow(pr), uniqueN(pr$SITE),
  pr[FOLD == "A", .N], pr[FOLD == "A", uniqueN(SITE)], pr[FOLD == "B", .N], pr[FOLD == "B", uniqueN(SITE)]))
cat(sprintf("long200 pairs %d stands; fold A %d, fold B %d; stands in both files %d; fold agreement on common stands %s\n", nrow(l2), l2[FOLD == "A", .N], l2[FOLD == "B", .N],
  length(intersect(pr$STAND, l2$STAND)), all(merge(pr, l2, by = "STAND")[, FOLD.x == FOLD.y])))
cat("CHURN_FLAG by fold:\n"); print(pr[, .N, by = .(FOLD, CHURN_FLAG)][order(FOLD, CHURN_FLAG)])
## t1 class and Dq from the frame t1 lists (overlay rule)
I0 <- fread(file.path(FR, "bench_gyr_mefia_l_c_tree_init.csv"))
SFG <- c("BF", "RS", "WS", "BS", "NS", "TA", "WC"); PHG <- c("WP", "RP", "RN", "JP", "EH", "OS")
I0[, ok := is.finite(EXPF) & EXPF > 0 & is.finite(DBH) & DBH > 0][, ba := fifelse(ok, DBH^2 * pi / 40000 * EXPF, 0)]
TC <- I0[, { tot <- sum(ba); sfs <- sum(ba[SP %in% SFG]) / tot; phs <- sum(ba[SP %in% PHG]) / tot
  .(CLASS = if (tot > 0) { if (sfs >= phs && sfs >= 1 - sfs - phs) "SF" else "NSF" } else NA_character_, DQ1 = if (tot > 0) sqrt(sum((DBH^2 * EXPF)[ok]) / sum(EXPF[ok])) else NA_real_) }, by = STAND]
TC <- merge(TC, pr[, .(STAND, FOLD)], by = "STAND")
cat("t1 class by fold (Dq at least 20 cm in brackets):\n"); print(TC[, .(n = .N, n_dq20 = sum(DQ1 >= 20, na.rm = TRUE)), by = .(FOLD, CLASS)][order(FOLD, CLASS)])
## t2 live-only check (structure only)
T2 <- fread(file.path(FR, "bench_gyr_mefia_l_c_tree_t2.csv"))
cat(sprintf("t2 records %d; with EXPF at or below 0 or missing: %d; with DBH missing: %d\n", nrow(T2), T2[!(is.finite(EXPF) & EXPF > 0), .N], T2[!is.finite(DBH), .N]))
## observed basal area mortality, FOLD A ONLY, at or above the stand's scoring minimum diameter
RS <- rbindlist(lapply(list.files(file.path(H, "magplot/verify/gydbreg20260916/v142_20260925/bench141/out/v141LT/mefia_l_c"), "_results\\.csv$", full.names = TRUE),
  fread, select = c("STAND", "SCORE_MINDBH_USED", "iv", "interval_years")))
fa <- pr[FOLD == "A", STAND]
IA <- I0[STAND %in% fa]; T2A <- T2[STAND %in% fa & is.finite(EXPF) & EXPF > 0]
IA[, live2 := paste(STAND, PLOT, TREE) %chin% T2A[, paste(STAND, PLOT, TREE)]]
IA <- merge(IA, RS[, .(STAND, SMD = SCORE_MINDBH_USED)], by = "STAND", all.x = TRUE)
cat(sprintf("fold A stands without a frozen SCORE_MINDBH_USED: %d\n", IA[is.na(SMD), uniqueN(STAND)]))
OM <- IA[, .(OBS_MORT_BA = sum((EXPF * pi * (DBH / 200)^2)[ok & !live2 & DBH >= SMD]), N_T1 = .N, N_DEAD = sum(!live2)), by = STAND]
cat(sprintf("fold A observed mortality computed for %d stands; t1 trees not found at t2: %.3f of %d (aggregate)\n", nrow(OM), IA[, mean(!live2)], nrow(IA)))
fwrite(pr[, .(STAND, SITE, FOLD, CHURN_FLAG)], outs[1]); fwrite(pr[FOLD == "A", .(STAND)], outs[2])
fwrite(TC, outs[3]); fwrite(OM, outs[4]); fwrite(l2[, .(STAND, SITE, FOLD)], outs[5])
fwrite(pr[, .N, by = FOLD][order(FOLD)], file.path(W, "v143p4_fold_counts_DATA_2026-10-28.csv"))
fwrite(TC[, .(n = .N, n_dq20 = sum(DQ1 >= 20, na.rm = TRUE)), by = .(FOLD, CLASS)][order(FOLD, CLASS)], file.path(W, "v143p4_t1_class_counts_DATA_2026-10-28.csv"))
cat("FRAME_DONE\n")

## PREREG24 independent re-derivation of the headline numbers. Written separately from the main script: tags are
## joined on (STAND, TREE) of the pass28qc frames directly (no row alignment), softwood increments use the runner tree
## id (softwood records are not split), folds are recomputed with tools::md5sum on temporary files. No em dashes.
suppressMessages(library(data.table)); setDTthreads(1L)
J <- "/home/aaron/jobs/v142p19"; TG <- "/home/aaron/jobs/v142p14/in/pass28qc"
r <- fread(file.path(J, "results/p19_a0111/gyr_p19_a0111_qc_c_results.csv"))[RUN_OK == 1]
st <- fread(file.path(J, "tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv"))[arm == "p19_a0111" & label == "qc_c" & cut == FALSE, STAND]
r <- r[STAND %in% st & is.finite(BA_o / QMD_o^2) & is.finite(BA_p / QMD_p^2)]
tf <- tempfile(); md <- vapply(unique(r$SITE), function(s) { writeLines(s, tf, sep = ""); unname(tools::md5sum(tf)) }, ""); unlink(tf)
r[, fold := ifelse(strtoi(substr(md[SITE], 1, 1), 16L) %% 2 == 0, "A", "B")]
t1 <- fread(file.path(TG, "bench_gyr_qc_c_tree_init.csv"))[STAND %in% r$STAND]; t2 <- fread(file.path(TG, "bench_gyr_qc_c_tree_t2.csv"))[STAND %in% r$STAND]
fs <- list.files(file.path(J, "home/out/p19_a0111/qc_c"), "_pred_t2_tree\\.csv$", full.names = TRUE)
p <- rbindlist(lapply(fs, fread))[STAND %in% r$STAND]
thr <- r[, .(STAND, smd = SCORE_MINDBH_USED, yrs = interval_years, fold)]
t1 <- merge(t1, thr, by = "STAND"); t2 <- merge(t2, thr, by = "STAND"); p <- merge(p, thr, by = "STAND")
t2[, surv := paste(STAND, TREE) %in% paste(t1$STAND, t1$TREE)]
t1[, surv := paste(STAND, TREE) %in% paste(t2$STAND, t2$TREE)]
agg <- function(f) {
  a1 <- t1[fold %in% f]; a2 <- t2[fold %in% f]; ap <- p[fold %in% f]; n <- r[fold %in% f, .N]
  No <- a2[DBH >= smd, sum(EXPF)]; Np <- ap[dbh >= smd, sum(expf)]
  Io <- a2[surv == FALSE & DBH >= smd, sum(EXPF)]; Ip <- ap[ing == 1 & dbh >= smd, sum(expf)]
  mo <- a1[, sum(EXPF / yrs)] - a2[surv == TRUE, sum(EXPF / yrs)]; mp <- a1[, sum(EXPF / yrs)] - ap[ing == 0, sum(expf / yrs)]
  BAo <- a2[DBH >= smd, sum(EXPF * DBH^2)]; BAp <- ap[dbh >= smd, sum(expf * dbh^2)]
  ## softwood increments: runner tree id equals the t1 row for unsplit softwood records
  a1[, row0 := seq_len(.N), by = STAND]; swl <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
  s1 <- a1[SP %in% swl & surv == TRUE, .(STAND, TREE, row0, d1 = DBH, e1 = EXPF)]
  s1 <- merge(s1, a2[, .(STAND, TREE, d2 = DBH)], by = c("STAND", "TREE"))
  s1 <- merge(s1, ap[ing == 0, .(STAND, row0 = tree, dp = dbh)], by = c("STAND", "row0"))
  data.table(fold = paste(f, collapse = "+"), stands = n, stems_ratio = Np / No, recruit_share_of_deficit = (Ip - Io) / (Np - No),
             obs_rec_ha_yr = a2[surv == FALSE & DBH >= smd, sum(EXPF / yrs)] / n, pred_rec_ha_yr = ap[ing == 1 & dbh >= smd, sum(expf / yrs)] / n,
             mort_ratio = mp / mo, qmd_pooled_ratio = sqrt((BAp / Np) / (BAo / No)), ba_ratio_lists = BAp / BAo,
             sw_inc_ratio = s1[, sum(e1 * (dp - d1)) / sum(e1 * (d2 - d1))], sw_trees = nrow(s1),
             pred_rec_all_ha = ap[ing == 1, sum(expf)] / n, pred_rec_dbh_mean = ap[ing == 1, sum(expf * dbh) / sum(expf)],
             pred_rec_share_ge7 = ap[ing == 1, sum(expf[dbh >= 7]) / sum(expf)]) }
V <- rbind(agg("A"), agg("B"), agg(c("A", "B")))
print(V, digits = 4)
fwrite(V, "/home/aaron/jobs/v142p24/tables/gyr142-p24-verify_DATA_2026-09-29.csv")
cat("VERIFY_DONE\n")

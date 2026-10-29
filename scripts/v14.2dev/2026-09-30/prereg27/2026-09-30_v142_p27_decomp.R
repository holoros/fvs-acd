## PREREG27 step 1b and 1c: where the stem deficit sits, fold A only. Stems at the score threshold (SCORE_MINDBH_USED per
## stand) are split into survivors (a tree at or above the threshold at t1 that is alive at t2) and recruits (everything at
## or above the threshold at t2 that was not: new tags and trees grown across the threshold). Observed: frame tree lists,
## matched by STAND, PLOT, TREE (tag matched). Predicted: the runner per tree lists (pred_t2_tree with the ing flag, t1_split
## for the t1 size of each record), main chunks plus by name retries (latest attempt wins). Arms: IMULT 1.75, 2.25 (PREREG18),
## 3.0 (PREREG17 fb) and PREREG22 v141LTfi. No coordinates are read or written. Headless. No em dashes.
suppressMessages({library(data.table)})
J <- "/home/aaron/jobs/v142p27"; OUT <- file.path(J, "fit")
FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"
SETS <- c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl")
KA <- readRDS(file.path(J, "in/p27_foldA_keys.rds"))$KA
ARM <- list(m175 = c("/home/aaron/jobs/v142p18/home", "v141LTig_m175"), m225 = c("/home/aaron/jobs/v142p18/home", "v141LTig_m225"),
            m30 = c("/home/aaron/jobs/v142p17/home", "v141LTig_m30"), fi = c("/home/aaron/jobs/v142p22/home", "v141LTfi"))
RES <- list(m175 = "/home/aaron/jobs/v142p18/results/v141LTig_m175/gyr_v141LTig_m175_%s_results.csv",
            m225 = "/home/aaron/jobs/v142p18/results/v141LTig_m225/gyr_v141LTig_m225_%s_results.csv",
            m30  = "/home/aaron/jobs/v142p17/results/v141LTig_m30/gyr_v141LTig_m30_%s_results.csv",
            fi   = "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_%s_results.csv")
tph <- function(ba, q) ba / (pi / 40000 * q^2)
acc <- list(); chk <- list()
for (s in SETS) {
  k <- KA[set == s, .(STAND, ivc, thr = SCORE_MINDBH_USED, interval_years)]
  i1 <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)), select = c("STAND", "PLOT", "TREE", "DBH", "EXPF"))[STAND %in% k$STAND]
  i2 <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_t2.csv", s)), select = c("STAND", "PLOT", "TREE", "DBH", "EXPF"))[STAND %in% k$STAND]
  if (anyDuplicated(i1[, .(STAND, PLOT, TREE)]) || anyDuplicated(i2[, .(STAND, PLOT, TREE)])) stop("tree key not unique in ", s)
  i1 <- merge(i1, k[, .(STAND, thr)], by = "STAND"); i2 <- merge(i2, k[, .(STAND, thr)], by = "STAND")
  i2 <- merge(i2, i1[, .(STAND, PLOT, TREE, D1 = DBH)], by = c("STAND", "PLOT", "TREE"), all.x = TRUE)
  O <- merge(i1[DBH >= thr, .(n1_o = sum(EXPF)), by = STAND],
             i2[DBH >= thr, .(surv_o = sum(EXPF[!is.na(D1) & D1 >= thr]), rec_o = sum(EXPF[is.na(D1) | D1 < thr]),
                              newtag_o = sum(EXPF[is.na(D1)])), by = STAND], by = "STAND", all = TRUE)
  for (a in names(ARM)) { H <- ARM[[a]][1]; A <- ARM[[a]][2]
    r <- fread(sprintf(RES[[a]], s), select = c("STAND", "RUN_OK", "BA_o", "QMD_o", "BA_p", "QMD_p"))[RUN_OK == 1 & STAND %in% k$STAND]
    dirs <- c(file.path(H, "out", A, s), file.path(H, sprintf("out_retry_a%d", 1:3), A, s)); rank <- 0:3
    rd <- function(pat, cols) rbindlist(lapply(seq_along(dirs), function(j) { fs <- list.files(dirs[j], pat, full.names = TRUE)
      if (!length(fs)) return(NULL); x <- rbindlist(lapply(fs, fread, select = cols)); x[, att := rank[j]] }))
    p2 <- rd("^c[0-9]+_pred_t2_tree[.]csv$", c("STAND", "tree", "dbh", "expf", "ing"))[STAND %in% r$STAND]
    p1 <- rd("^c[0-9]+_t1_split_tree[.]csv$", c("STAND", "tree", "dbh", "expf"))[STAND %in% r$STAND]
    la <- p2[, .(att = max(att)), by = STAND]; p2 <- merge(p2, la, by = c("STAND", "att")); p1 <- merge(p1, la, by = c("STAND", "att"))
    p1 <- merge(p1, k[, .(STAND, thr)], by = "STAND"); p2 <- merge(p2, k[, .(STAND, thr)], by = "STAND")
    if (anyDuplicated(p1[, .(STAND, tree)])) stop("t1 split tree key not unique ", a, " ", s)
    p2 <- merge(p2, p1[, .(STAND, tree, d1 = dbh)], by = c("STAND", "tree"), all.x = TRUE)
    P <- merge(p1[dbh >= thr, .(n1_p = sum(expf)), by = STAND],
               p2[dbh >= thr, .(surv_p = sum(expf[ing == 0 & !is.na(d1) & d1 >= thr]), rec_p = sum(expf[ing == 1 | is.na(d1) | d1 < thr]),
                                ing_p = sum(expf[ing == 1])), by = STAND], by = "STAND", all = TRUE)
    X <- merge(merge(O, P, by = "STAND"), r[, .(STAND, to_res = tph(BA_o, QMD_o), tp_res = tph(BA_p, QMD_p))], by = "STAND")
    X <- merge(X, k[, .(STAND, ivc, interval_years)], by = "STAND"); for (cc in names(X)) if (is.numeric(X[[cc]])) set(X, which(is.na(X[[cc]])), cc, 0)
    chk[[paste(a, s)]] <- data.table(arm = a, set = s, stands = nrow(X), stands_results = nrow(r),
      t1_obs_vs_pred_maxrel = max(abs(X$n1_p - X$n1_o) / pmax(X$n1_o, 1)),
      t2_obs_trees_vs_results = sum(X$surv_o + X$rec_o) / sum(X$to_res), t2_pred_trees_vs_results = sum(X$surv_p + X$rec_p) / sum(X$tp_res))
    agg <- function(z) z[, .(stands = .N, iv_mean = mean(interval_years), n1 = sum(n1_o), surv_o = sum(surv_o), surv_p = sum(surv_p),
      rec_o = sum(rec_o), rec_p = sum(rec_p), newtag_o = sum(newtag_o), ing_p = sum(ing_p))]
    acc[[paste(a, s)]] <- rbind(X[, agg(.SD), by = ivc], agg(X)[, ivc := "all"])[, `:=`(arm = a, set = s)]
    cat(a, s, "done\n") } }
CK <- rbindlist(chk); print(CK, digits = 4); fwrite(CK, file.path(OUT, "gyr142-p27-diag-decomp-check_DATA_2026-09-30.csv"))
D <- rbindlist(acc)
D[, `:=`(stems_o = surv_o + rec_o, stems_p = surv_p + rec_p)]
D[, `:=`(stems_ratio = stems_p / stems_o, surv_ratio = surv_p / surv_o, rec_ratio = rec_p / rec_o,
         ann_surv_o = (surv_o / n1)^(1 / iv_mean), ann_surv_p = (surv_p / n1)^(1 / iv_mean),
         deficit = stems_p - stems_o, deficit_surv = surv_p - surv_o, deficit_rec = rec_p - rec_o)]
D[, share_surv := deficit_surv / deficit]
setcolorder(D, c("arm", "set", "ivc")); setorder(D, arm, set, ivc); print(D[, .(arm, set, ivc, stands, iv_mean, stems_ratio, surv_ratio, rec_ratio, ann_surv_o, ann_surv_p, share_surv)], digits = 3)
fwrite(D, file.path(OUT, "gyr142-p27-diag-decomp-class-foldA_DATA_2026-09-30.csv")); cat("DIAG_B_DONE\n")

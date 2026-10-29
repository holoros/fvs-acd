## PREREG36 Part C independent F9 verifier (v141LT rows). Own code; no project scorers used.
suppressPackageStartupMessages(library(data.table))
P <- "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/volconv_p36"
OUT <- file.path(P, "verify_20261001")
plan <- fread(file.path(P, "plan/p36_plan_full_r1_frozen.csv"), colClasses = "character")
plan <- plan[arm == "v141LT"]
cat("v141LT plan rows:", nrow(plan), "\n")
rdef <- fread(file.path(P, "tables_r2/gyr142-volconv-r2defect_DATA_2026-09-27.csv"))[arm == "v141LT"]
rsh  <- fread(file.path(P, "tables_r2/gyr142-volconv-r2stratumshare_DATA_2026-09-27.csv"))[arm == "v141LT"]
need <- c("STAND", "RUN_OK", "TOTVOL_o", "TOTVOL_p", "SCORE_MINDBH_USED")
rd_frame <- function(f) {
  x <- fread(f, select = c("STAND", "DBH", "EXPF"), colClasses = list(character = "STAND"))
  x[, DBH := suppressWarnings(as.numeric(DBH))]; x[, EXPF := suppressWarnings(as.numeric(EXPF))]
  x
}
live_stands <- function(fr, flo) {
  x <- merge(fr, flo, by = "STAND")
  unique(x[is.finite(DBH) & DBH >= MINDBH & is.finite(EXPF) & EXPF > 0, STAND])
}
res_all <- list()
for (i in seq_len(nrow(plan))) {
  pr <- plan[i]
  hdr <- names(fread(pr$res, nrows = 0))
  miss <- setdiff(need, hdr)
  if (length(miss)) cat("LABEL", pr$label, "missing columns:", paste(miss, collapse = ";"), "\n")
  r <- fread(pr$res, select = intersect(need, hdr), colClasses = list(character = "STAND"))
  for (v in c("RUN_OK", "TOTVOL_o", "TOTVOL_p", "SCORE_MINDBH_USED")) r[, (v) := suppressWarnings(as.numeric(get(v)))]
  sc <- unique(r[RUN_OK == 1 & is.finite(TOTVOL_o) & is.finite(TOTVOL_p)], by = "STAND")
  flo <- sc[, .(STAND, MINDBH = SCORE_MINDBH_USED)]
  n_floor_na <- sum(!is.finite(flo$MINDBH))
  t2 <- rd_frame(file.path(pr$fr, sprintf("bench_gyr_%s_tree_t2.csv", pr$set)))
  t1 <- rd_frame(file.path(pr$fr, sprintf("bench_gyr_%s_tree_init.csv", pr$set)))
  L2 <- live_stands(t2, flo); L1 <- live_stands(t1, flo)
  n_scored <- nrow(sc)
  no2 <- !(sc$STAND %in% L2)
  n_t2_none <- sum(no2)
  n_t2_absent <- sum(!(sc$STAND %in% t2$STAND))
  # results-side observed zero (TOTVOL_o == 0), for cross-check
  vo0 <- sc$TOTVOL_o == 0
  n_vo0_res <- sum(vo0)
  n_vo0_with_stem <- sum(vo0 & !no2)      # zero observed volume yet live stem at floor
  n_nostem_pos_vol <- sum(no2 & !vo0)     # no live stem at floor yet positive observed volume
  no1 <- !(sc$STAND %in% L1)
  n_t1_none <- sum(no1); share <- n_t1_none / n_scored
  n_t1_absent <- sum(!(sc$STAND %in% t1$STAND))
  d <- rdef[label == pr$label]; s <- rsh[label == pr$label]
  rep_vo0 <- if (nrow(d)) d$vo_zero else NA_integer_
  rep_cls <- if (nrow(d)) d$vo_zero_with_source_stem else NA_integer_
  # class D: stands r2 reports as V_o = 0 but holding a live stem at floor in t2.
  # r2 reports only counts; the reported vo_zero set is taken as the results-side TOTVOL_o == 0 set
  # when that count matches reported vo_zero, else NA.
  classD <- if (!is.na(rep_vo0) && n_vo0_res == rep_vo0) n_vo0_with_stem else NA_integer_
  res_all[[i]] <- data.table(
    label = pr$label, set = pr$set, n_scored = n_scored,
    rep_scored_defect = if (nrow(d)) d$scored else NA, rep_scored_share = if (nrow(s)) s$scored else NA,
    n_floor_na = n_floor_na,
    n_t2_no_live_stem = n_t2_none, n_t2_absent = n_t2_absent,
    n_vo0_results = n_vo0_res, rep_vo_zero = rep_vo0,
    classD = classD, rep_vo_zero_with_source_stem = rep_cls,
    n_nostem_but_vo_pos = n_nostem_pos_vol,
    t1_zero = n_t1_none, t1_absent = n_t1_absent, rep_t1_zero = if (nrow(s)) s$t1_zero else NA,
    t1_share = share, rep_t1_share = if (nrow(s)) s$t1_zero_share else NA,
    fires = share > 0.05, rep_fires = if (nrow(s)) as.logical(s$fires) else NA)
  cat(sprintf("%s done: scored=%d t2_none=%d vo0_res=%d t1_none=%d\n", pr$label, n_scored, n_t2_none, n_vo0_res, n_t1_none))
}
R <- rbindlist(res_all)
R[, ok_scored := n_scored == rep_scored_defect & n_scored == rep_scored_share]
R[, ok_proxy := n_t2_no_live_stem == rep_vo_zero]
R[, ok_classD := !is.na(classD) & classD == 0]
R[, ok_t1 := t1_zero == rep_t1_zero & abs(t1_share - rep_t1_share) < 1e-9]
R[, ok_fires := fires == rep_fires]
R[, PASS := ok_scored & ok_proxy & ok_classD & ok_t1 & ok_fires]
fwrite(R, file.path(OUT, "p36_verify_c_DATA_2026-10-01.csv"))
print(R[, .(label, n_scored, rep_scored_defect, n_t2_no_live_stem, n_vo0_results, rep_vo_zero, classD,
            n_nostem_but_vo_pos, t1_zero, rep_t1_zero, t1_share = signif(t1_share, 6), fires, rep_fires, PASS)])
cat("rows:", nrow(R), " PASS:", sum(R$PASS), " FAIL:", sum(!R$PASS), "\n")
cat("P36_VERIFY_C_DONE\n")

## PREREG39 F9 compare: verifier values against assembly outputs. Point values, tolerance 1e-9. No em dashes.
suppressMessages(library(data.table))
V <- "/home/aaron/jobs/v142p39/verify_20261002"; A <- "/home/aaron/jobs/v142p39/assembled"
me <- fread(file.path(V, "p39_verify_DATA_2026-10-02.csv"))
mv <- function(a, it) { x <- me[arm == a & item == it, value]; if (length(x) != 1) stop("missing ", a, " ", it); x }
f <- function(n) fread(file.path(A, sprintf("gyr142-p39-%s_DATA_2026-10-02.csv", n)))
lad <- f("ladder"); dl <- f("deltas"); gr <- f("groups"); rp <- f("repro"); dg <- f("diag"); ad <- f("armdiff")
R <- list(); cmp <- function(arm, item, mine, theirs, kind = "point") R[[length(R) + 1]] <<- data.table(arm = arm, item = item, kind = kind, verifier = as.numeric(mine), assembly = as.numeric(theirs))
for (a in c("p19_a0111", "p38_fit")) {
  for (k in paste0("D", 0:6)) {
    L <- lad[arm == a & rung == k]
    cmp(a, k, mv(a, k), L$value)
    if (k == "D0") { cmp(a, "D0_records", mv(a, "D0_records"), L$records) } else {
      cmp(a, paste0(k, "_stands"), mv(a, paste0(k, "_stands")), L$n_units)
      if (k %in% c("D1", "D2", "D3")) cmp(a, paste0(k, "_records"), mv(a, paste0(k, "_records_obs")), L$records)
      if (k == "D4") cmp(a, "D4_records_pred", mv(a, "D4_records_pred"), L$records)
    }
    cmp(a, paste0(k, "_lo"), NA, L$lo, "interval_not_rederived"); cmp(a, paste0(k, "_hi"), NA, L$hi, "interval_not_rederived")
  }
  for (j in 1:6) { x <- dl[arm == a & delta == paste0("delta_", j)]; cmp(a, paste0("delta_", j), mv(a, paste0("delta_", j)), x$value) }
  for (g in paste0("G", 1:5)) { x <- gr[arm == a & group == g]
    cmp(a, g, mv(a, g), x$value); cmp(a, paste0(g, "_share"), mv(a, paste0(g, "_share_of_gap")), x$share)
    cmp(a, paste0(g, "_lo"), mv(a, paste0(g, "_lo")), x$lo, "interval_info"); cmp(a, paste0(g, "_hi"), mv(a, paste0(g, "_hi")), x$hi, "interval_info") }
  x <- gr[arm == a & group == "gap"]; cmp(a, "gap", mv(a, "gap"), x$value)
  cmp(a, "gap_lo", mv(a, "gap_lo"), x$lo, "interval_info"); cmp(a, "gap_hi", mv(a, "gap_hi"), x$hi, "interval_info")
  r <- rp[arm == a]; w <- function(ch) r[check == ch, worst]
  cmp(a, "S1_TOPHT_o_worst", mv(a, "S1_max_abs_diff_TOPHT_o"), w("S1 stand TOPHT_o worst"))
  cmp(a, "S1_TOPHT_p_worst", mv(a, "S1_max_abs_diff_TOPHT_p"), w("S1 stand TOPHT_p worst"))
  cmp(a, "S1_D6_vs_ref_abs", abs(mv(a, "S1_D6_minus_ref_topht_bias_pct")), w("S1 D6 against PREREG38 topht_bias_pct"))
  cmp(a, "S2_D0_vs_ref_abs", abs(mv(a, "S2_D0_minus_ref")), w("S2 D0 against PREREG38 hinc level"))
  cmp(a, "S2_records_diff", mv(a, "D0_records") - mv(a, "S2_ref_trees"), w("S2 D0 records against hinc trees"))
  cmp(a, "S3_stands_diff", mv(a, "S3_stands_diff"), w("S3 stands against PREREG38 stands"))
  for (ch in c("S1", "S2", "S3")) cmp(a, paste0(ch, "_pass"), mv(a, paste0(ch, "_pass")), all(r[grepl(paste0("^", ch), check), pass]))
  d <- dg[arm == a]; q <- function(it) d[item == it, value]
  cmp(a, "Q1_D6obs_himp_share", mv(a, "Q1_D6obs_himp_share"), q("Q1 observed D6 set himp share"))
  cmp(a, "Q1_D6obs_le_1.3", mv(a, "Q1_D6obs_finite_le_1.3_count"), q("Q1 observed D6 set finite heights at or below 1.3 m"))
  cmp(a, "Q1_D6obs_records", mv(a, "Q1_D6obs_records"), q("Q1 observed D6 set records"))
  cmp(a, "Q1_D3obs_himp_share", mv(a, "Q1_D3obs_himp_share"), q("Q1 observed D3 set himp share"))
  cmp(a, "Q1_D3obs_le_1.3", mv(a, "Q1_D3obs_finite_le_1.3_count"), q("Q1 observed D3 set finite heights at or below 1.3 m"))
  cmp(a, "Q1_D3obs_records", mv(a, "Q1_D3obs_records"), q("Q1 observed D3 set records"))
  cmp(a, "Q2_ratio", mv(a, "Q2_D6obs_sum_himp_over_sum_ht"), q("Q2 observed D6 set sum himp over sum measured height"))
  cmp(a, "Q3_obs_share", mv(a, "Q3_D6obs_share_t1dom_survivor"), q("Q3 observed D6 records that are t1 dom survivors, share"))
  cmp(a, "Q3_pred_share", mv(a, "Q3_D6pred_share_t1dom_ing0"), q("Q3 predicted D6 records that are t1 dom rows with ing 0, share"))
  cmp(a, "Q4_D1", mv(a, "Q4_D1_records_per_stand_obs"), q("Q4 records per stand D0 D1"))
  cmp(a, "Q4_D2", mv(a, "Q4_D2_records_per_stand_obs"), q("Q4 records per stand D2"))
  cmp(a, "Q4_D3_obs", mv(a, "Q4_D3_records_per_stand_obs"), q("Q4 records per stand D3 observed"))
  cmp(a, "Q4_D4_pred", mv(a, "Q4_D4_records_per_stand_pred"), q("Q4 records per stand D4 predicted"))
}
for (k in paste0("D", 0:6)) cmp("p38_fit_minus_p19_a0111", k, mv("p38_fit_minus_p19_a0111", k), ad[rung == k, arm_diff])
## outcome
vt <- readLines(file.path(A, "gyr142-p39-verdict_DATA_2026-10-02.txt"))
oc <- fread(file.path(V, "p39_verify_outcome_2026-10-02.txt"), header = FALSE, sep = ",")
g2 <- function(lbl) as.numeric(grepl("dominant source G2", vt[grepl(paste0("^outcome_", lbl, "="), vt)]))
cmp("p38_fit", "outcome_dominant_G2", as.numeric(oc[V1 == "p38_fit", V2] == "dominant G2"), g2("p38_fit"))
cmp("p19_a0111", "outcome_dominant_G2", as.numeric(oc[V1 == "p19_a0111", V2] == "dominant G2"), g2("qc141"))
cmp("p38_fit", "consistent_across_arms", mv("p38_fit", "outcome_consistent_with_qc141"), as.numeric(any(vt == "consistent_across_arms=TRUE")))
X <- rbindlist(R); X[, absdiff := abs(verifier - assembly)]; X[, agree := absdiff <= 1e-9]
fwrite(X, file.path(V, "p39_verify_compare_DATA_2026-10-02.csv"))
P <- X[kind == "point"]
cat(sprintf("point items compared %d, agree %d\n", nrow(P), sum(P$agree)))
print(P[agree == FALSE])
cat(sprintf("worst agreeing point diff %.3g\n", max(P[agree == TRUE, absdiff])))
I <- X[kind == "interval_info"]; cat(sprintf("interval limits (info only) compared %d, agree %d\n", nrow(I), sum(I$agree)))
cat("P39_COMPARE_DONE\n")

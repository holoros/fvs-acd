## PREREG36 [F9] comparison (firebreather): main A1 and A2 tables against the independent verifier CSV, exact on counts,
## 1e-9 on shares and medians. No em dashes.
suppressMessages(library(data.table))
J <- "/home/aaron/jobs/v142p36"; V <- fread(file.path(J, "verify_20261001/p36_verify_a_DATA_2026-10-01.csv"))
A1 <- fread(file.path(J, "tables/gyr142-p36-a1-records_DATA_2026-10-01.csv")); A2 <- fread(file.path(J, "tables/gyr142-p36-a2-agreement_DATA_2026-10-01.csv"))
G <- fread(file.path(J, "tables/gyr142-p36-a2-groups_DATA_2026-10-01.csv"))
v <- function(s, p, f, i) V[set == s & part == p & file == f & item == i, as.numeric(value)]
R <- list(); add <- function(s, what, main, ver, tol) R[[length(R) + 1L]] <<- data.table(set = s, item = what, main = main, verifier = ver, diff = abs(main - ver), pass = length(ver) == 1L && abs(main - ver) <= tol)
gm <- c(S_R_only = "row index only", intersection = "both", S_M_only = "field tag only")
for (s in c("qc_c", "qc_fl")) {
  for (f in c("init", "t2")) { add(s, paste("A1 multiset", f), as.numeric(A1[set == s & frame == f, same_multiset]), v(s, "A1", f, "multiset_pass"), 0)
    add(s, paste("A1 order", f), as.numeric(A1[set == s & frame == f, same_order]), v(s, "A1", f, "row_order_identical"), 0) }
  a <- A2[set == s]
  add(s, "t1 tags", a$t1_tags, v(s, "A2", "rowindex", "t1_tags"), 0); add(s, "t2 tags", a$t2_tags, v(s, "A2", "rowindex", "t2_tags"), 0)
  add(s, "matched R", a$matched_R, v(s, "A2", "rowindex", "matched"), 0); add(s, "matched M", a$matched_M, v(s, "A2", "field", "matched"), 0)
  add(s, "S_R", a$S_R, v(s, "A2", "rowindex", "S_n"), 0); add(s, "S_M", a$S_M, v(s, "A2", "field", "S_n"), 0)
  add(s, "S both", a$S_both, v(s, "A2", "both", "intersection_n"), 0); add(s, "agreement", a$agreement, v(s, "A2", "both", "agreement_a"), 1e-9)
  add(s, "rule A defect", as.numeric(a$rule_A == "tag defect"), v(s, "A2", "both", "ruleA_tag_defect"), 0)
  for (k in names(gm)) { g <- G[set == s & grp == gm[[k]]]
    add(s, paste(k, "n"), g$n, v(s, "A2", k, "n"), 0); add(s, paste(k, "n both HT"), g$n_both_ht, v(s, "A2", k, "n_ht_both"), 0)
    add(s, paste(k, "DBH shrink"), g$dbh_shrink_share, v(s, "A2", k, "share_dbh2_lt_dbh1_minus1"), 1e-9)
    add(s, paste(k, "HT shrink"), g$ht_shrink_share, v(s, "A2", k, "share_ht2_lt_ht1_minus1.5"), 1e-9)
    add(s, paste(k, "median dDBH"), g$dbh_change_median, v(s, "A2", k, "median_dDBH"), 1e-9) } }
R <- rbindlist(R); print(R, nrows = 200); fwrite(R, file.path(J, "verify_20261001/p36_verify_a_compare_DATA_2026-10-01.csv"))
cat(sprintf("%d of %d comparisons pass\n", sum(R$pass), nrow(R))); if (all(R$pass)) cat("P36_VERIFY_DONE A1 A2 all checks pass\n") else cat("P36_VERIFY_FAIL\n")

# PREREG36 F9 independent verifier, Part A1 and A2, sets qc_c and qc_fl
# Own code; no scorer or Part A script sourced. No coordinate columns used.
suppressPackageStartupMessages(library(data.table))
base <- path.expand("~/jobs/v142p14/in")
outd <- path.expand("~/jobs/v142p36/verify_20261001")
cols <- c("STAND","PLOT","TREE","SP","DBH","HT","EXPF","YEAR")
cc <- c(STAND="character",PLOT="character",TREE="numeric",SP="character",
        DBH="numeric",HT="numeric",EXPF="numeric",YEAR="numeric")
rd <- function(f) {
  d <- fread(f, select = cols, colClasses = cc, na.strings = c("", "NA"))
  stopifnot(identical(names(d), cols))
  d[, ROW := .I]
  num <- function(x) ifelse(is.na(x), "NA", formatC(x, digits = 15, format = "g"))
  d[, KEY := paste(STAND, PLOT, SP, num(DBH), num(HT), num(EXPF), num(YEAR), sep = "|")]
  d[, OCC := rowid(KEY)]
  d[, ID := paste0(KEY, "#", OCC)]
  d
}
md5 <- function(f) unname(tools::md5sum(f))
cat("P36 verify A start", format(Sys.time()), "\n")
res <- list()
for (s in c("qc_c", "qc_fl")) {
  fr <- list(); fm <- list()
  for (w in c("init", "t2")) {
    f1 <- file.path(base, "frames",   sprintf("bench_gyr_%s_tree_%s.csv", s, w))
    f2 <- file.path(base, "pass28qc", sprintf("bench_gyr_%s_tree_%s.csv", s, w))
    cat("md5", s, w, "rowindex", md5(f1), " field", md5(f2), "\n")
    a <- rd(f1); b <- rd(f2)
    ms <- nrow(a) == nrow(b) && identical(sort(a$KEY), sort(b$KEY))
    ord <- nrow(a) == nrow(b) && identical(a$KEY, b$KEY)
    cat("A1", s, w, "n_rowindex", nrow(a), "n_field", nrow(b),
        "multiset", if (ms) "PASS" else "FAIL", "row_order_identical", ord, "\n")
    res[[length(res) + 1]] <- data.table(set = s, part = "A1", file = w, item = "multiset_pass",
                                         value = as.numeric(ms))
    res[[length(res) + 1]] <- data.table(set = s, part = "A1", file = w, item = "row_order_identical",
                                         value = as.numeric(ord))
    if (!ms) stop("A1 failed for ", s, " ", w)
    # canonical identity = ID (key + occurrence); same set in both versions
    stopifnot(setequal(a$ID, b$ID), !anyDuplicated(a$ID))
    fr[[w]] <- a; fm[[w]] <- b
  }
  build <- function(d1, d2, lab) {
    t1 <- d1[is.finite(TREE) & TREE < 9e6]
    t2 <- d2[is.finite(TREE) & TREE < 9e6]
    n1 <- nrow(t1); n2 <- nrow(t2)
    t1 <- t1[, if (.N == 1L) .SD, by = .(STAND, TREE)]
    t2 <- t2[, if (.N == 1L) .SD, by = .(STAND, TREE)]
    m <- merge(t1[, .(STAND, TREE, SP1 = SP, DBH1 = DBH, HT1 = HT, ID1 = ID)],
               t2[, .(STAND, TREE, SP2 = SP, DBH2 = DBH, HT2 = HT, ID2 = ID)],
               by = c("STAND", "TREE"))
    nm <- nrow(m)
    S <- m[SP1 == SP2 & is.finite(HT2) & HT2 > 0]
    S[, PID := paste(ID1, ID2, sep = "~~")]
    stopifnot(!anyDuplicated(S$PID))
    cat("A2", s, lab, "t1_tags", n1, "t2_tags", n2, "matched", nm, "S", nrow(S), "\n")
    list(n1 = n1, n2 = n2, nm = nm, S = S)
  }
  R <- build(fr$init, fr$t2, "rowindex")
  M <- build(fm$init, fm$t2, "field")
  for (lab in c("rowindex", "field")) {
    X <- if (lab == "rowindex") R else M
    res[[length(res) + 1]] <- data.table(set = s, part = "A2", file = lab,
      item = c("t1_tags", "t2_tags", "matched", "S_n"),
      value = c(X$n1, X$n2, X$nm, nrow(X$S)))
  }
  inter <- intersect(R$S$PID, M$S$PID)
  a <- length(inter) / nrow(R$S)
  verdict <- if (a >= 0.99) "convention" else "tag defect"
  cat("A2", s, "intersection", length(inter), "agreement_a", sprintf("%.12f", a),
      "RuleA", verdict, "\n")
  res[[length(res) + 1]] <- data.table(set = s, part = "A2", file = "both",
    item = c("intersection_n", "agreement_a", "ruleA_tag_defect"),
    value = c(length(inter), a, as.numeric(a < 0.99)))
  grp <- list(
    S_R_only = R$S[!PID %in% M$S$PID],
    intersection = R$S[PID %in% inter],
    S_M_only = M$S[!PID %in% R$S$PID])
  for (g in names(grp)) {
    G <- grp[[g]]
    n <- nrow(G)
    shD <- if (n) mean(G$DBH2 < G$DBH1 - 1.0) else NA_real_
    hh <- G[is.finite(HT1) & HT1 > 0 & is.finite(HT2) & HT2 > 0]
    shH <- if (nrow(hh)) mean(hh$HT2 < hh$HT1 - 1.5) else NA_real_
    medD <- if (n) median(G$DBH2 - G$DBH1) else NA_real_
    cat("A2", s, g, "n", n, "share_dbh_shrink", sprintf("%.12f", shD),
        "n_ht_both", nrow(hh), "share_ht_shrink", sprintf("%.12f", shH),
        "median_dDBH", sprintf("%.6f", medD), "\n")
    res[[length(res) + 1]] <- data.table(set = s, part = "A2", file = g,
      item = c("n", "share_dbh2_lt_dbh1_minus1", "n_ht_both", "share_ht2_lt_ht1_minus1.5", "median_dDBH"),
      value = c(n, shD, nrow(hh), shH, medD))
  }
}
out <- rbindlist(res)
fwrite(out, file.path(outd, "p36_verify_a_DATA_2026-10-01.csv"))
cat("wrote CSV rows", nrow(out), "\n")
cat("P36_VERIFY_A_DONE\n")

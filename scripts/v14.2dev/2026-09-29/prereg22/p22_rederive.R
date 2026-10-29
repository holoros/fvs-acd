## PREREG22 independent re-derivation [F9], 2026-09-30. Base R only; no code shared with the scorer, h2 or assembly scripts.
## K1 and TOPHT (H1) and stems (S1) from the four v141LTfi results files; E3 and E6b from the per stand C1 volumes;
## H2 (25 cm and over, fold B) from the PREREG20 tag key and the v141LTfi per tree t2 predictions; v141LT references read
## from the PREREG17 Cardinal structure table (md5 checked) and PREREG16 volconv stands. Fold from md5(SITE), PREREG11 rule.
suppressPackageStartupMessages(library(digest))
J <- "/home/aaron/jobs/v142p22"; OUT <- file.path(J, "verify_20260930"); dir.create(OUT, showWarnings = FALSE)
rd <- function(f) read.csv(f, stringsAsFactors = FALSE, check.names = FALSE)
sets <- c("ns_c", "ns_long_c", "ns_fl", "ns_long_fl")
STRF <- "/home/aaron/jobs/v142p18/in/cardinal/gyr142-p17-cardinal-structure_DATA_2026-09-27.csv"
stopifnot(digest(STRF, algo = "md5", file = TRUE) == "732b553f9e9e3f984e014c51141e0dad")
STR <- rd(STRF); STR <- STR[STR$arm == "v141LT", ]
fold_of <- function(site) { h <- vapply(site, function(z) substr(digest(z, algo = "md5", serialize = FALSE), 1, 1), ""); ifelse(strtoi(h, 16L) %% 2 == 0, "A", "B") }
tp <- function(ba, q) ba / (pi / 40000 * q^2)
res <- lapply(sets, function(s) { r <- rd(file.path(J, sprintf("results/v141LTfi/gyr_v141LTfi_%s_results.csv", s))); r$set <- s; r })
names(res) <- sets
K1 <- sapply(res, function(r) sum(r$RUN_OK != 1)); print(K1)
str_fi <- function(r) c(stems = sum(tp(r$BA_p, r$QMD_p)) / sum(tp(r$BA_o, r$QMD_o)), topht = 100 * (mean(r$TOPHT_p) - mean(r$TOPHT_o)) / mean(r$TOPHT_o))
H1 <- t(sapply(sets, function(s) { r <- res[[s]][res[[s]]$RUN_OK == 1, ]; v <- str_fi(r); ref <- STR[STR$label == s & STR$pop == "all", ]
  c(n = nrow(r), topht_fi = v[["topht"]], topht_ref = ref$topht_bias_pct, stems_fi = v[["stems"]], stems_ref = ref$stems_ratio) })); print(H1)
## S1: ns_c fold B, others all
nsc <- res$ns_c[res$ns_c$RUN_OK == 1, ]; nsc$fold <- fold_of(as.character(nsc$SITE)); B <- nsc[nsc$fold == "B", ]
S1 <- rbind(ns_c_B = c(n = nrow(B), fi = str_fi(B)[["stems"]], ref = STR[STR$label == "ns_c" & STR$pop == "B", "stems_ratio"]),
  t(sapply(sets[-1], function(s) c(n = nrow(res[[s]]), fi = H1[s, "stems_fi"], ref = H1[s, "stems_ref"]))))
S1 <- cbind(S1, pass = abs(log(S1[, "fi"])) < abs(log(S1[, "ref"]))); print(S1)
## E3 and E6b from per stand C1 volumes
ST <- rd(list.files(file.path(J, "tables"), "stands_DATA", full.names = TRUE)); ST <- ST[ST$arm == "v141LTfi", ]
RF <- rd("/home/aaron/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv"); RF <- RF[RF$arm == "v141LT", ]
vm <- function(x) c(n = nrow(x), rmse = 100 * sqrt(mean((x$V_ph - x$V_oh)^2)) / mean(x$V_oh), bias = 100 * (mean(x$V_ph) - mean(x$V_oh)) / mean(x$V_oh))
E <- t(sapply(sets, function(s) c(fi = vm(ST[ST$label == s, ]), ref = vm(RF[RF$label == s, ])))); print(E)
d3 <- E[c("ns_c", "ns_long_c"), "ref.rmse"] - E[c("ns_c", "ns_long_c"), "fi.rmse"]
e6 <- abs(E[c("ns_fl", "ns_long_fl"), "fi.bias"]) <= abs(E[c("ns_fl", "ns_long_fl"), "ref.bias"])
## H2: 25 cm and over, fold B, ns_c and ns_long_c; joint arm against 14.1 (Hp141 in the key) and PREREG11 (P11 table)
P11 <- rd(file.path(J, "in/p11/score/h2/gyr142-htfix-h2h3_DATA_2026-09-26.csv")); print(head(P11, 3))
h2 <- t(sapply(c("ns_c", "ns_long_c"), function(s) {
  k <- rd(file.path(J, sprintf("in/key/p20_htkey_%s.csv", s)))
  fl <- list.files(file.path(J, "home/out/v141LTfi", s), "_pred_t2_tree\\.csv$", full.names = TRUE)
  p <- do.call(rbind, lapply(fl, function(f) { z <- rd(f); z[z$ing == 0, c("STAND", "tree", "ht")] }))
  stopifnot(!anyDuplicated(p[, c("STAND", "tree")]))
  x <- merge(k, p, by = c("STAND", "tree")); stopifnot(nrow(x) == nrow(k))
  x <- x[x$fold == "B" & x$D1 >= 25, ]
  dho <- (x$H2 - x$H1) / x$iv; dfi <- (x$ht - x$H1) / x$iv; d141 <- (x$Hp141 - x$H1) / x$iv
  c(trees = nrow(x), sites = length(unique(x$sidx)), rfi = mean(dfi) / mean(dho), r141 = mean(d141) / mean(dho)) })); print(h2)
## compare with assembled
G <- rd(file.path(J, "assembled/gyr142-p22-gatedetail_DATA_2026-09-29.csv")); HS <- rd(file.path(J, "assembled/gyr142-p22-h2-sizeclass_DATA_2026-09-29.csv"))
g <- function(t, s) G$val[G$test == t & G$set == s]
cmp <- data.frame(item = c(paste0("H1_", sets), "S1_ns_c_B", paste0("S1_", sets[-1]), "E3_ns_c", "E3_ns_long_c", "E6b_ns_fl", "E6b_ns_long_fl", "H2_ns_c_rfi", "H2_ns_long_c_rfi", "H2_ns_c_r141", "H2_ns_long_c_r141"),
  rederived = c(H1[, "topht_fi"], S1[, "fi"], E["ns_c", "fi.rmse"], E["ns_long_c", "fi.rmse"], E["ns_fl", "fi.bias"], E["ns_long_fl", "fi.bias"], h2[, "rfi"], h2[, "r141"]),
  assembled = c(sapply(sets, function(s) g("H1", s)), g("S1", "ns_c"), sapply(sets[-1], function(s) g("S1", s)), g("E3", "ns_c"), g("E3", "ns_long_c"), g("E6b", "ns_fl"), g("E6b", "ns_long_fl"),
    HS$rfi[HS$set == "ns_c" & HS$fold == "B" & HS$cls == "25 and over"], HS$rfi[HS$set == "ns_long_c" & HS$fold == "B" & HS$cls == "25 and over"],
    HS$r141[HS$set == "ns_c" & HS$fold == "B" & HS$cls == "25 and over"], HS$r141[HS$set == "ns_long_c" & HS$fold == "B" & HS$cls == "25 and over"]))
cmp$absdiff <- abs(cmp$rederived - cmp$assembled); cmp$pass <- cmp$absdiff < 1e-6  ## per stand tables print to 6 decimals (PREREG18 rev2 precedent)
gates <- data.frame(item = c("K1_total", "H1_all_smaller", "S1_all_pass", "E3_min_d_rmse", "E6b_pass", "H2_fi_better_than_141"),
  rederived = c(sum(K1), as.numeric(all(abs(H1[, "topht_fi"]) < abs(H1[, "topht_ref"]))), as.numeric(all(S1[, "pass"] == 1)), min(d3), as.numeric(all(e6)), as.numeric(all(abs(h2[, "rfi"] - 1) < abs(h2[, "r141"] - 1)))),
  assembled = c(0, 1, 1, NA, 1, 1), absdiff = NA)
gates$pass <- c(gates$rederived[1] == 0, gates$rederived[2] == 1, gates$rederived[3] == 1, gates$rederived[4] >= -0.5, gates$rederived[5] == 1, gates$rederived[6] == 1)
cmp <- rbind(cmp, gates); print(cmp, digits = 12)
write.csv(cmp, file.path(OUT, "p22_rederive_DATA_2026-09-30.csv"), row.names = FALSE)
cat(if (all(cmp$pass)) "REDERIVE_PASS\n" else "REDERIVE_FAIL\n"); quit(status = if (all(cmp$pass)) 0 else 1)

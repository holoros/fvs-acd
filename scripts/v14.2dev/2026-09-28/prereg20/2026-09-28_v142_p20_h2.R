## PREREG20 H2 and the size class height check. Tag matched survivors (key from 2026-09-28_v142_p20_htkey_cardinal.R, the
## PREREG11 pairing) joined to predicted t2 heights of: v141LT (14.1, in the key), v141LTh (PREREG11 arm, firebreather
## ~/jobs/v142htf/home/out/v141LTh) and v141LTf (this arm, with its by name retries). Ratio = mean predicted over mean
## observed annual height increment, by set, fold and class (below 12.7, 12.7 to 25, 25 cm and over; D at t1). Site
## cluster bootstrap intervals (B = 1000, seed 20260928). Reproduction check: v141LT and v141LTh fold B ratios for ns_c
## and ns_long_c must equal the PREREG11 H2 table (gyr142-htfix-h2h3_DATA_2026-09-26.csv) within 1e-9. No coordinates.
## No em dashes.
suppressMessages(library(data.table)); options(width = 200); set.seed(20260928)
J <- "/home/aaron/jobs/v142p20"; H <- file.path(J, "home"); O <- file.path(J, "tables")
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
DIRS <- list(v141LTh = "/home/aaron/jobs/v142htf/home/out/v141LTh", v141LTf = file.path(H, "out/v141LTf"))
pred <- function(col, s) {
  fl <- list.files(file.path(DIRS[[col]], s), "_pred_t2_tree\\.csv$", full.names = TRUE); if (!length(fl)) stop("no pred files ", col, " ", s)
  pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]
  if (col == "v141LTf") for (k in 1:3) { rf <- list.files(file.path(H, sprintf("out_retry_a%d/v141LTf/%s", k, s)), "_pred_t2_tree\\.csv$", full.names = TRUE)
    if (length(rf)) { r <- rbindlist(lapply(rf, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]; pt <- rbind(pt[!STAND %in% r$STAND], r) } }
  if (anyDuplicated(pt[, .(STAND, tree)])) stop("duplicated STAND tree ", col, " ", s)
  pt[, .(STAND, tree, ht)] }
acc <- list()
for (s in c("ns_c", "ns_long_c", "ns_fl", "ns_long_fl")) {
  x <- fread(file.path(J, sprintf("in/key/p20_htkey_%s.csv", s)))
  for (col in names(DIRS)) { p <- pred(col, s); setnames(p, "ht", paste0("Hp_", col)); x <- merge(x, p, by = c("STAND", "tree"), all.x = TRUE) }
  if (x[, anyNA(Hp_v141LTh) | anyNA(Hp_v141LTf)]) stop("unmatched trees in ", s)
  x[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
  x[, `:=`(dho = (H2 - H1) / iv, d141 = (Hp141 - H1) / iv, dh = (Hp_v141LTh - H1) / iv, df = (Hp_v141LTf - H1) / iv)]
  acc[[s]] <- x[, .(set = s, sidx, fold, cls, dho, d141, dh, df)] }
X <- rbindlist(acc)
R <- X[, .(trees = .N, sites = uniqueN(sidx), obs = mean(dho), r141 = mean(d141) / mean(dho), rh = mean(dh) / mean(dho), rf = mean(df) / mean(dho)), by = .(set, fold, cls)][order(set, fold, cls)]
## bootstrap by site within set x fold x class
bsr <- function(d) { S <- d[, .(o = sum(dho), a = sum(d141), h = sum(dh), f = sum(df)), by = sidx]; n <- nrow(S)
  M <- replicate(1000, { i <- sample.int(n, n, TRUE); c(sum(S$a[i]) / sum(S$o[i]), sum(S$h[i]) / sum(S$o[i]), sum(S$f[i]) / sum(S$o[i])) })
  as.list(setNames(c(apply(M, 1, quantile, .025), apply(M, 1, quantile, .975)), c("r141_lo", "rh_lo", "rf_lo", "r141_hi", "rh_hi", "rf_hi"))) }
BI <- X[, bsr(.SD), by = .(set, fold, cls)]; R <- merge(R, BI, by = c("set", "fold", "cls"))
R[, `:=`(dev141 = abs(r141 - 1), devh = abs(rh - 1), devf = abs(rf - 1))]
## reproduction check against PREREG11
P11 <- fread(file.path(J, "in/p11/score/h2/gyr142-htfix-h2h3_DATA_2026-09-26.csv"))
chk <- merge(R[fold == "B" & set %in% c("ns_c", "ns_long_c")], P11[, .(set, cls, ratio_v141LT, ratio_v141LTh)], by = c("set", "cls"))
repro <- chk[, max(abs(r141 - ratio_v141LT), abs(rh - ratio_v141LTh))]
cat(sprintf("PREREG11 reproduction: worst abs difference %.3g over %d cells\n", repro, nrow(chk))); if (nrow(chk) != 6 || repro > 1e-9) stop("H2 REPRO FAIL")
G <- R[fold == "B" & set %in% c("ns_c", "ns_long_c") & cls == "25 and over"][, pass := devf < dev141 & devf < devh]
fwrite(R, f_out("gyr142-p20-h2-sizeclass_DATA_2026-09-28.csv")); fwrite(G, f_out("gyr142-p20-h2-gate_DATA_2026-09-28.csv"))
print(R[, .(set, fold, cls, trees, r141, rh, rf, rf_lo, rf_hi)], digits = 3); print(G, digits = 4)
cat(sprintf("H2 %s\n", if (all(G$pass)) "PASS" else "FAIL")); cat("H2_DONE\n")

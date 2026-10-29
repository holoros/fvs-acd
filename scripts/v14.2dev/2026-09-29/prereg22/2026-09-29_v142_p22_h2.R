## PREREG22 H2 and the size class height check. Derived from ~/jobs/v142p20/scripts/2026-09-28_v142_p20_h2.R (md5 655cf4a9;
## diff in ../diffs/). Tag matched survivors (PREREG20 key, the PREREG11 pairing) joined to predicted t2 heights of: v141LT
## (14.1, in the key), v141LTh (PREREG11 arm, ~/jobs/v142htf/home/out/v141LTh), v141LTf (PREREG20 arm, reported, with its by
## name retries) and v141LTfi (this joint arm, with its by name retries). Ratio = mean predicted over mean observed annual
## height increment, by set, fold and class (below 12.7, 12.7 to 25, 25 cm and over; D at t1). Site cluster bootstrap
## intervals (B = 1000, seed 20260928). Reproduction check before any v141LTfi value is used: v141LT and v141LTh fold B
## ratios for ns_c and ns_long_c equal the PREREG11 H2 table within 1e-9. Gate (carried from PREREG20): on fold B, ns_c and
## ns_long_c, 25 cm and over, |ratio - 1| of v141LTfi smaller than both 14.1 and PREREG11. No coordinates. No em dashes.
suppressMessages(library(data.table)); options(width = 200); set.seed(20260928)
J <- "/home/aaron/jobs/v142p22"; H <- file.path(J, "home"); O <- file.path(J, "tables"); dir.create(O, showWarnings = FALSE)
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
DIRS <- list(v141LTh = "/home/aaron/jobs/v142htf/home/out/v141LTh", v141LTf = "/home/aaron/jobs/v142p20/home/out/v141LTf", v141LTfi = file.path(H, "out/v141LTfi"))
RHOME <- list(v141LTf = "/home/aaron/jobs/v142p20/home", v141LTfi = H)
pred <- function(col, s) {
  fl <- list.files(file.path(DIRS[[col]], s), "_pred_t2_tree\\.csv$", full.names = TRUE); if (!length(fl)) stop("no pred files ", col, " ", s)
  pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]
  if (col %in% names(RHOME)) for (k in 1:3) { rf <- list.files(file.path(RHOME[[col]], sprintf("out_retry_a%d/%s/%s", k, col, s)), "_pred_t2_tree\\.csv$", full.names = TRUE)
    if (length(rf)) { r <- rbindlist(lapply(rf, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]; pt <- rbind(pt[!STAND %in% r$STAND], r) } }
  if (anyDuplicated(pt[, .(STAND, tree)])) stop("duplicated STAND tree ", col, " ", s)
  pt[, .(STAND, tree, ht)] }
acc <- list()
for (s in c("ns_c", "ns_long_c", "ns_fl", "ns_long_fl")) {
  x <- fread(file.path(J, sprintf("in/key/p20_htkey_%s.csv", s)))
  for (col in names(DIRS)) { p <- pred(col, s); setnames(p, "ht", paste0("Hp_", col)); x <- merge(x, p, by = c("STAND", "tree"), all.x = TRUE) }
  if (x[, anyNA(Hp_v141LTh) | anyNA(Hp_v141LTf) | anyNA(Hp_v141LTfi)]) stop("unmatched trees in ", s)
  x[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
  x[, `:=`(dho = (H2 - H1) / iv, d141 = (Hp141 - H1) / iv, dh = (Hp_v141LTh - H1) / iv, df = (Hp_v141LTf - H1) / iv, dfi = (Hp_v141LTfi - H1) / iv)]
  acc[[s]] <- x[, .(set = s, sidx, fold, cls, dho, d141, dh, df, dfi)] }
X <- rbindlist(acc)
R <- X[, .(trees = .N, sites = uniqueN(sidx), obs = mean(dho), r141 = mean(d141) / mean(dho), rh = mean(dh) / mean(dho), rf = mean(df) / mean(dho), rfi = mean(dfi) / mean(dho)), by = .(set, fold, cls)][order(set, fold, cls)]
## reproduction check against PREREG11, before any v141LTfi value is used
P11 <- fread(file.path(J, "in/p11/score/h2/gyr142-htfix-h2h3_DATA_2026-09-26.csv"))
chk <- merge(R[fold == "B" & set %in% c("ns_c", "ns_long_c")], P11[, .(set, cls, ratio_v141LT, ratio_v141LTh)], by = c("set", "cls"))
repro <- chk[, max(abs(r141 - ratio_v141LT), abs(rh - ratio_v141LTh))]
cat(sprintf("PREREG11 reproduction: worst abs difference %.3g over %d cells\n", repro, nrow(chk))); if (nrow(chk) != 6 || repro > 1e-9) stop("H2 REPRO FAIL")
## bootstrap by site within set x fold x class
bsr <- function(d) { S <- d[, .(o = sum(dho), a = sum(d141), h = sum(dh), f = sum(df), fi = sum(dfi)), by = sidx]; n <- nrow(S)
  M <- replicate(1000, { i <- sample.int(n, n, TRUE); c(sum(S$a[i]), sum(S$h[i]), sum(S$f[i]), sum(S$fi[i])) / sum(S$o[i]) })
  as.list(setNames(c(apply(M, 1, quantile, .025), apply(M, 1, quantile, .975)), c("r141_lo", "rh_lo", "rf_lo", "rfi_lo", "r141_hi", "rh_hi", "rf_hi", "rfi_hi"))) }
BI <- X[, bsr(.SD), by = .(set, fold, cls)]; R <- merge(R, BI, by = c("set", "fold", "cls"))
R[, `:=`(dev141 = abs(r141 - 1), devh = abs(rh - 1), devf = abs(rf - 1), devfi = abs(rfi - 1))]
G <- R[fold == "B" & set %in% c("ns_c", "ns_long_c") & cls == "25 and over"][, pass := devfi < dev141 & devfi < devh]
fwrite(R, f_out("gyr142-p22-h2-sizeclass_DATA_2026-09-29.csv")); fwrite(G, f_out("gyr142-p22-h2-gate_DATA_2026-09-29.csv"))
print(R[, .(set, fold, cls, trees, r141, rh, rf, rfi, rfi_lo, rfi_hi)], digits = 3); print(G, digits = 4)
cat(sprintf("H2 %s\n", if (all(G$pass)) "PASS" else "FAIL")); cat("H2_DONE\n")

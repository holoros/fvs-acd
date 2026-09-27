## PREREG11 H2 and H3: held out (fold B) height increment, ns_c and ns_long_c, v141LTh (firebreather) against v141LT (14.1).
## Pairing and fold logic copied from scripts/2026-09-26_v142_htfix_fit.R (pairs_ht), with the prediction directory as a
## parameter. H2: in each of the four cells (set x class 12.7 to 25, 25 and over) |pred/obs - 1| for v141LTh is below that
## for v141LT. H3: fold B below 12.7 cm, ratio change reported; PASS if |change| <= 0.005 [ASSUMPTION, trees can cross 12.7
## cm within the interval]. No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths())); suppressMessages(library(data.table)); options(width = 200)
G <- "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916"; V <- file.path(G, "v142_20260925"); FZ <- file.path(G, "frames"); P28 <- file.path(V, "pass28/frames")
HT <- file.path(V, "recs/htfix")
DIRS <- c(v141LT = file.path(V, "bench141/out/v141LT"), v141LTh = Sys.getenv("H2_HDIR", file.path(HT, "fbout/out/v141LTh")))
if (nzchar(Sys.getenv("H2_SELFTEST"))) DIRS["v141LTh"] <- DIRS["v141LT"]
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest::digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
pairs_ht <- function(s, col) {
  f1 <- fread(file.path(FZ, sprintf("bench_gyr_%s_tree_init.csv", s)))[, tree := seq_len(.N), by = STAND]
  t1 <- fread(file.path(P28, sprintf("bench_gyr_%s_tree_init.csv", s))); t2 <- fread(file.path(P28, sprintf("bench_gyr_%s_tree_t2.csv", s)))
  k <- c("STAND", "SP", "DBH", "HT", "EXPF"); f1[, rk := seq_len(.N), by = k]; t1[, rk := seq_len(.N), by = k]
  mp <- merge(f1[, c(k, "rk", "tree"), with = FALSE], t1[, c(k, "rk", "TREE"), with = FALSE], by = c(k, "rk")); stopifnot(nrow(mp) == nrow(f1))
  fl <- list.files(file.path(DIRS[[col]], s), "_pred_t2_tree\\.csv$", full.names = TRUE); if (!length(fl)) stop("no pred files for ", col, " ", s)
  pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]
  stopifnot(!anyDuplicated(pt[, .(STAND, tree)]))
  pr <- fread(file.path(FZ, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "interval_years", "SITE"))
  x <- merge(merge(mp[TREE < 9e6 & is.finite(HT) & HT > 0, .(STAND, TREE, tree, D1 = DBH, H1 = HT)], t2[TREE < 9e6 & is.finite(HT) & HT > 0, .(STAND, TREE, H2 = HT)], by = c("STAND", "TREE")), pt[, .(STAND, tree, Hp = ht)], by = c("STAND", "tree"))
  x <- merge(x, pr, by = "STAND"); x[, `:=`(dho = (H2 - H1) / interval_years, dhp = (Hp - H1) / interval_years, set = s, col = col)]
  x[, fold := fold(SITE)]; x[fold == "B"] }
X <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) rbindlist(lapply(names(DIRS), function(k) pairs_ht(s, k)))))
X[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
R <- X[, .(trees = .N, obs = mean(dho), pred = mean(dhp)), by = .(set, cls, col)][, ratio := pred / obs]
W <- dcast(R, set + cls + trees + obs ~ col, value.var = c("pred", "ratio"))
stopifnot(W[, !anyNA(ratio_v141LT) & !anyNA(ratio_v141LTh)])
W[, `:=`(dev_141 = abs(ratio_v141LT - 1), dev_fix = abs(ratio_v141LTh - 1))]
W[cls != "below 12.7", H2_cell := dev_fix < dev_141]; W[cls == "below 12.7", H3_cell := abs(ratio_v141LTh - ratio_v141LT) <= 0.005]
print(W, digits = 4)
h2 <- W[cls != "below 12.7", all(H2_cell)]; h3 <- W[cls == "below 12.7", all(H3_cell)]
cat(sprintf("H2 %s (%d of %d cells closer to 1)\nH3 %s (max |ratio change| %.4f)\n", if (h2) "PASS" else "FAIL", W[cls != "below 12.7", sum(H2_cell)], W[cls != "below 12.7", .N],
  if (h3) "PASS" else "FAIL", W[cls == "below 12.7", max(abs(ratio_v141LTh - ratio_v141LT))]))
if (!nzchar(Sys.getenv("H2_SELFTEST"))) fwrite(W, file.path(HT, "score/h2/gyr142-htfix-h2h3_DATA_2026-09-26.csv"))

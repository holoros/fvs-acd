## PREREG11 step 1: fit b in m(D) = exp(-b * max(0, D - 12.7)) on NS height increment (tag matched survivors, measured height
## at both ends), fold A sites of ns_long_c only. Fold by site: md5 of SITE, first hex digit even = A. v141LT predictions.
## No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths())); suppressMessages(library(data.table)); options(width = 200); set.seed(20260926)
G <- "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916"; V <- file.path(G, "v142_20260925"); FZ <- file.path(G, "frames"); P28 <- file.path(V, "pass28/frames")
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest::digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
pairs_ht <- function(s) {
  f1 <- fread(file.path(FZ, sprintf("bench_gyr_%s_tree_init.csv", s)))[, tree := seq_len(.N), by = STAND]
  t1 <- fread(file.path(P28, sprintf("bench_gyr_%s_tree_init.csv", s))); t2 <- fread(file.path(P28, sprintf("bench_gyr_%s_tree_t2.csv", s)))
  k <- c("STAND", "SP", "DBH", "HT", "EXPF"); f1[, rk := seq_len(.N), by = k]; t1[, rk := seq_len(.N), by = k]
  mp <- merge(f1[, c(k, "rk", "tree"), with = FALSE], t1[, c(k, "rk", "TREE"), with = FALSE], by = c(k, "rk")); stopifnot(nrow(mp) == nrow(f1))
  pt <- rbindlist(lapply(list.files(file.path(V, "bench141/out/v141LT", s), "_pred_t2_tree\\.csv$", full.names = TRUE), fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]
  pr <- fread(file.path(FZ, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "interval_years", "SITE"))
  x <- merge(merge(mp[TREE < 9e6 & is.finite(HT) & HT > 0, .(STAND, TREE, tree, D1 = DBH, H1 = HT)], t2[TREE < 9e6 & is.finite(HT) & HT > 0, .(STAND, TREE, H2 = HT)], by = c("STAND", "TREE")), pt[, .(STAND, tree, Hp = ht)], by = c("STAND", "tree"))
  x <- merge(x, pr, by = "STAND"); x[, `:=`(dho = (H2 - H1) / interval_years, dhp = (Hp - H1) / interval_years, set = s)]
  x[, fold := fold(SITE)]; x }
if (!requireNamespace("digest", quietly = TRUE)) stop("digest package missing")
X <- rbindlist(lapply(c("ns_long_c", "ns_c", "ns_fl", "ns_long_fl"), pairs_ht))
cat("trees by set and fold:\n"); print(X[, .N, by = .(set, fold)])
A <- X[set == "ns_long_c" & fold == "A"]
m <- function(D, b) exp(-b * pmax(0, D - 12.7))
sse <- function(b) sum((A$dho - m(A$D1, b) * A$dhp)^2)
opt <- optimize(sse, c(0, 0.3)); b <- opt$minimum
## cluster bootstrap by site for b
sites <- unique(A$SITE); bs <- replicate(500, { s <- sample(sites, length(sites), TRUE); d <- A[data.table(SITE = s), on = "SITE", allow.cartesian = TRUE]
  optimize(function(bb) sum((d$dho - m(d$D1, bb) * d$dhp)^2), c(0, 0.3))$minimum })
cat(sprintf("b = %.5f (site bootstrap 95%%: %.5f to %.5f), trees %d, sites %d\n", b, quantile(bs, .025), quantile(bs, .975), nrow(A), length(sites)))
cat(sprintf("m at 20, 25, 30, 40 cm: %.3f %.3f %.3f %.3f\n", m(20, b), m(25, b), m(30, b), m(40, b)))
X[, cls := cut(D1, c(0, 12.7, 25, Inf), right = FALSE, labels = c("below 12.7", "12.7 to 25", "25 and over"))]
R <- X[, .(trees = .N, obs = mean(dho), pred_141 = mean(dhp), pred_fix = mean(m(D1, b) * dhp)), by = .(set, fold, cls)][order(set, fold, cls)]
R[, `:=`(ratio_141 = pred_141 / obs, ratio_fix = pred_fix / obs)]; print(R, digits = 3)
fwrite(R, "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/htfix/tables/gyr142-htfix-fit_DATA_2026-09-26.csv")
writeLines(sprintf("%.6f", b), "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/htfix/work/htfix_b.txt")
fwrite(data.table(b = b, lo = quantile(bs, .025), hi = quantile(bs, .975), trees = nrow(A), sites = length(sites)), "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/htfix/tables/gyr142-htfix-b_DATA_2026-09-26.csv")
cat("HTFIT_DONE\n")

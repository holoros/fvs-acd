## PREREG20 step 1 (diagnostic extraction, Cardinal login node, read only on frozen inputs). Builds the tag matched
## height key for the four NS sets: survivors with a measured height at both ends, matched through the pass 28 tag frames,
## with the v141LT (14.1) predicted height at t2. Pairing logic copied verbatim from PREREG11
## scripts/2026-09-26_v142_htfix_fit.R (pairs_ht). Output: one slim CSV per set in recs/p20/key/ (new directory), no
## coordinates (SITE is an id; only its fold is written). Refuses to overwrite. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths())); suppressMessages(library(data.table)); options(width = 200)
G <- "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916"; V <- file.path(G, "v142_20260925"); FZ <- file.path(G, "frames"); P28 <- file.path(V, "pass28/frames")
OUT <- file.path(V, "recs/p20/key"); dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest::digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
pairs_ht <- function(s) {
  f1 <- fread(file.path(FZ, sprintf("bench_gyr_%s_tree_init.csv", s)))[, tree := seq_len(.N), by = STAND]
  t1 <- fread(file.path(P28, sprintf("bench_gyr_%s_tree_init.csv", s))); t2 <- fread(file.path(P28, sprintf("bench_gyr_%s_tree_t2.csv", s)))
  k <- c("STAND", "SP", "DBH", "HT", "EXPF"); f1[, rk := seq_len(.N), by = k]; t1[, rk := seq_len(.N), by = k]
  mp <- merge(f1[, c(k, "rk", "tree"), with = FALSE], t1[, c(k, "rk", "TREE"), with = FALSE], by = c(k, "rk")); stopifnot(nrow(mp) == nrow(f1))
  pt <- rbindlist(lapply(list.files(file.path(V, "bench141/out/v141LT", s), "_pred_t2_tree\\.csv$", full.names = TRUE), fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]
  stopifnot(!anyDuplicated(pt[, .(STAND, tree)]))
  pr <- fread(file.path(FZ, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "interval_years", "SITE"))
  x <- merge(merge(mp[TREE < 9e6 & is.finite(HT) & HT > 0, .(STAND, TREE, tree, SP, D1 = DBH, H1 = HT)], t2[TREE < 9e6 & is.finite(HT) & HT > 0, .(STAND, TREE, H2 = HT)], by = c("STAND", "TREE")), pt[, .(STAND, tree, Hp141 = ht)], by = c("STAND", "tree"))
  x <- merge(x, pr, by = "STAND"); x[, fold := fold(SITE)]
  sid <- unique(x[, .(SITE)])[, sidx := .I]; x <- merge(x, sid, by = "SITE")   # integer site index, no site string written
  x[, .(set = s, STAND, tree, TREE, SP, sidx, fold, iv = interval_years, D1, H1, H2, Hp141)] }
for (s in c("ns_c", "ns_fl", "ns_long_c", "ns_long_fl")) {
  f <- file.path(OUT, sprintf("p20_htkey_%s.csv", s)); if (file.exists(f)) stop("REFUSE ", f)
  x <- pairs_ht(s); fwrite(x, f); cat(sprintf("%s: %d trees, fold A %d, sites %d\n", s, nrow(x), x[fold == "A", .N], uniqueN(x$sidx))) }
cat("P20_KEY_DONE\n")

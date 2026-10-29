## PREREG45b shared definitions: measured top height (MTH), observed stand increment, arm cohort increment. No em dashes.
suppressMessages({ library(data.table); library(digest) })
FRM <- "/home/aaron/jobs/v142p45b/home/magplot/verify/gydbreg20260916/frames"; V141 <- "/home/aaron/jobs/v142p19/in/xfer/v142_20260925/bench141/results/v141LT/gyr_v141LT_nb_c_results.csv"
fold_of <- function(x) { u <- unique(as.character(x)); f <- ifelse(strtoi(substr(vapply(u, digest, "", algo = "md5", serialize = FALSE), 1, 1), 16L) %% 2 == 0, "A", "B"); f[match(as.character(x), u)] }
cohort <- function(d) { d <- d[is.finite(DBH) & DBH >= 9.1 & is.finite(EXPF) & EXPF > 0]; setorder(d, STAND, -DBH); d[, cw := cumsum(EXPF), by = STAND]
  d[, keep := cw <= 100 | seq_len(.N) == 1L, by = STAND]; d[keep == TRUE] }
mth <- function(d) cohort(d)[is.finite(HT) & HT > 0, .(MTH = mean(HT), nmeas = .N), by = STAND]
stands_nb <- function() { s <- fread(V141, colClasses = list(character = "STAND"))[, .(STAND, SITE, esi8, iv, TOTVOL_o, TOPHT_o, TOPHT_t1)]
  s[, fold := fold_of(SITE)]; s[is.finite(esi8) & esi8 > 2] }
obs_nb <- function() { i <- fread(file.path(FRM, "bench_gyr_nb_c_tree_init.csv"), colClasses = list(character = "STAND"))
  g <- fread(file.path(FRM, "bench_gyr_nb_c_tree_t2.csv"), colClasses = list(character = "STAND"))
  m1 <- mth(i); m2 <- mth(g); setnames(m1, c("STAND", "MTH1", "n1")); setnames(m2, c("STAND", "MTH2", "n2")); merge(m1, m2, by = "STAND") }
arm_files <- function(home, arm) { d <- c(file.path(home, "out", arm, "nb_c"), file.path(home, sprintf("out_retry_a%d", 1:3), arm, "nb_c")); d[dir.exists(d)] }
rdl <- function(dirs, pat) { acc <- NULL; for (d in dirs) { fs <- sort(list.files(d, pat, full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread, colClasses = list(character = "STAND"))); if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
pred_nb <- function(home, arm) { dirs <- arm_files(home, arm)
  t0 <- rdl(dirs, "^c[0-9]+_t1_split_tree\\.csv$"); tp <- rdl(dirs, "^c[0-9]+_pred_t2_tree\\.csv$")
  c0 <- cohort(t0[, .(STAND, tree, DBH = dbh, HT = ht, EXPF = expf)])[is.finite(HT) & HT > 0]
  z <- merge(c0[, .(STAND, tree, H1 = HT)], tp[ing == 0 & is.finite(ht), .(STAND, tree, Hp = ht, iv)], by = c("STAND", "tree"))
  z[, .(pinc = mean((Hp - H1) / iv), npred = .N), by = STAND] }

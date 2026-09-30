## PREREG27 shared functions: per stand survivor and recruit components at the score threshold. Observed from the frame
## tree lists matched by STAND, PLOT, TREE; predicted from the runner per tree lists (pred_t2_tree, t1_split_tree), main
## chunks plus by name retries, latest attempt wins. Same definitions as 2026-09-30_v142_p27_decomp.R. No coordinates.
suppressMessages(library(data.table))
FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"
ARM <- list(m175 = c("/home/aaron/jobs/v142p18/home", "v141LTig_m175"), m225 = c("/home/aaron/jobs/v142p18/home", "v141LTig_m225"),
            m30 = c("/home/aaron/jobs/v142p17/home", "v141LTig_m30"), fi = c("/home/aaron/jobs/v142p22/home", "v141LTfi"))
RES <- list(m175 = "/home/aaron/jobs/v142p18/results/v141LTig_m175/gyr_v141LTig_m175_%s_results.csv",
            m225 = "/home/aaron/jobs/v142p18/results/v141LTig_m225/gyr_v141LTig_m225_%s_results.csv",
            m30  = "/home/aaron/jobs/v142p17/results/v141LTig_m30/gyr_v141LTig_m30_%s_results.csv",
            fi   = "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_%s_results.csv")
stand_comp <- function(s, a, k) {   # k: STAND, thr
  i1 <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)), select = c("STAND", "PLOT", "TREE", "DBH", "EXPF"))[STAND %in% k$STAND]
  i2 <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_t2.csv", s)), select = c("STAND", "PLOT", "TREE", "DBH", "EXPF"))[STAND %in% k$STAND]
  if (anyDuplicated(i1[, .(STAND, PLOT, TREE)]) || anyDuplicated(i2[, .(STAND, PLOT, TREE)])) stop("tree key not unique in ", s)
  i1 <- merge(i1, k[, .(STAND, thr)], by = "STAND"); i2 <- merge(i2, k[, .(STAND, thr)], by = "STAND")
  i2 <- merge(i2, i1[, .(STAND, PLOT, TREE, D1 = DBH)], by = c("STAND", "PLOT", "TREE"), all.x = TRUE)
  O <- merge(i1[DBH >= thr, .(n1 = sum(EXPF), ba1 = sum(EXPF * pi / 40000 * DBH^2)), by = STAND],
             i2[DBH >= thr, .(surv_o = sum(EXPF[!is.na(D1) & D1 >= thr]), rec_o = sum(EXPF[is.na(D1) | D1 < thr])), by = STAND], by = "STAND", all = TRUE)
  H <- ARM[[a]][1]; A <- ARM[[a]][2]
  r <- fread(sprintf(RES[[a]], s), select = c("STAND", "RUN_OK"))[RUN_OK == 1 & STAND %in% k$STAND]
  dirs <- c(file.path(H, "out", A, s), file.path(H, sprintf("out_retry_a%d", 1:3), A, s))
  rd <- function(pat, cols) rbindlist(lapply(seq_along(dirs), function(j) { fs <- list.files(dirs[j], pat, full.names = TRUE)
    if (!length(fs)) return(NULL); x <- rbindlist(lapply(fs, fread, select = cols)); x[, att := j - 1L] }))
  p2 <- rd("^c[0-9]+_pred_t2_tree[.]csv$", c("STAND", "tree", "dbh", "expf", "ing"))[STAND %in% r$STAND]
  p1 <- rd("^c[0-9]+_t1_split_tree[.]csv$", c("STAND", "tree", "dbh", "expf"))[STAND %in% r$STAND]
  la <- p2[, .(att = max(att)), by = STAND]; p2 <- merge(p2, la, by = c("STAND", "att")); p1 <- merge(p1, la, by = c("STAND", "att"))
  p1 <- merge(p1, k[, .(STAND, thr)], by = "STAND"); p2 <- merge(p2, k[, .(STAND, thr)], by = "STAND")
  if (anyDuplicated(p1[, .(STAND, tree)])) stop("t1 split tree key not unique ", a, " ", s)
  p2 <- merge(p2, p1[, .(STAND, tree, d1 = dbh)], by = c("STAND", "tree"), all.x = TRUE)
  P <- p2[dbh >= thr, .(surv_p = sum(expf[ing == 0 & !is.na(d1) & d1 >= thr]), rec_p = sum(expf[ing == 1 | is.na(d1) | d1 < thr])), by = STAND]
  X <- merge(merge(O, P, by = "STAND", all.y = TRUE), r[, .(STAND)], by = "STAND")
  for (cc in names(X)) if (is.numeric(X[[cc]])) set(X, which(is.na(X[[cc]])), cc, 0)
  X[, `:=`(set = s, arm = a)] }
## pooled ratio with a site cluster bootstrap (sites resampled with replacement), num and den are per stand columns
bsr <- function(d, num, den, B = 1000L) { S <- d[, .(f = sum(get(num)), o = sum(get(den))), by = sidx]; n <- nrow(S)
  if (n < 2) return(list(lo = NA_real_, hi = NA_real_))
  r <- replicate(B, { i <- sample.int(n, n, TRUE); sum(S$f[i]) / sum(S$o[i]) }); list(lo = unname(quantile(r, .025)), hi = unname(quantile(r, .975))) }
prog_of <- function(st) { stopifnot(all(grepl("^NS(_LONG)?__NS_(RS|OP)_", st))); fifelse(grepl("^NS(_LONG)?__NS_RS_", st), "NS_RS", "NS_OP") }

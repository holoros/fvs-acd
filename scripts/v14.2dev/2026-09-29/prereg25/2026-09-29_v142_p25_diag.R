## PREREG25 step 1: diagnose NS small tree (below 12.7 cm) height increment under v141LTf. Data: the PREREG20 tag matched
## height key (in/key/p20_htkey_<set>.csv, copied read only from ~/jobs/v142p20/in/key) joined to the frozen PREREG20
## v141LTf per tree t2 predictions (~/jobs/v142p20/home/out/v141LTf, retries none). ns_c and ns_long_c FOLD A ONLY: the
## fold B rows and the fl sets are dropped before any join, and nothing else is read. Ratio = mean predicted over mean
## observed annual height increment (PREREG20 H2 definition). Site cluster bootstrap B = 1000, seed 20260929.
## Diagnostics: 1 cm and 2.5 cm classes; program (NS_OP operational PSP against NS_RS research plots, parsed from STAND);
## species group; height at t1 near breast height; observed height resolution; shared-site check. Headless. No
## coordinates. Refuses to overwrite. No em dashes.
suppressMessages(library(data.table)); options(width = 220); set.seed(20260929)
J <- "/home/aaron/jobs/v142p25"; P20 <- "/home/aaron/jobs/v142p20"; O <- file.path(J, "fit")
f_out <- function(n) { f <- file.path(O, n); if (file.exists(f)) stop("REFUSE ", f); f }
pred <- function(s) {
  fl <- list.files(file.path(P20, "home/out/v141LTf", s), "_pred_t2_tree\\.csv$", full.names = TRUE); stopifnot(length(fl) > 0)
  for (k in 1:3) stopifnot(!length(list.files(file.path(P20, sprintf("home/out_retry_a%d/v141LTf/%s", k, s)), "_pred_t2_tree")))
  pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]; stopifnot(!anyDuplicated(pt[, .(STAND, tree)])); pt[, .(STAND, tree, Hpf = ht)] }
rd <- function(s) {
  x <- fread(file.path(J, sprintf("in/key/p20_htkey_%s.csv", s)))[fold == "A"]   # fold B dropped here, never used
  x <- merge(x, pred(s), by = c("STAND", "tree"), all.x = TRUE); stopifnot(!anyNA(x$Hpf))
  x[, `:=`(dho = (H2 - H1) / iv, dh141 = (Hp141 - H1) / iv, dhf = (Hpf - H1) / iv,
           prog = sub("_[0-9P]+$", "", tstrsplit(STAND, "__")[[2]]))]
  x[, grp := fcase(SP %in% c("BF"), "balsam fir", SP %in% c("RS", "BS", "WS"), "spruce", SP %in% c("RM", "SM"), "maple",
                   SP %in% c("WB", "PB", "YB", "GB"), "birch", SP %in% c("EH", "WP", "TA", "JP", "RP"), "other conifer", default = "other hardwood")]
  x[, set := s]; x }
X <- rbind(rd("ns_c"), rd("ns_long_c")); stopifnot(all(X$fold == "A"))
tab <- function(d, by) d[, .(trees = .N, sites = uniqueN(sidx), stands = uniqueN(STAND), D_mean = mean(D1), H1_mean = mean(H1), obs = mean(dho),
  pred141 = mean(dh141), predf = mean(dhf), ratio_f = mean(dhf) / mean(dho), share_neg = mean(dho < 0), share_zero = mean(dho == 0),
  share_H1_lt2 = mean(H1 < 2), share_H_int = mean(abs(H1 - round(H1)) < 1e-6 & abs(H2 - round(H2)) < 1e-6),
  share_H_dm = mean(abs(10 * H1 - round(10 * H1)) < 1e-6 & abs(10 * H2 - round(10 * H2)) < 1e-6), iv_mean = mean(iv)), by = by]
bsr <- function(d) { S <- d[, .(o = sum(dho), f = sum(dhf)), by = sidx]; n <- nrow(S); if (n < 2) return(list(ratio_lo = NA_real_, ratio_hi = NA_real_))
  r <- replicate(1000, { i <- sample.int(n, n, TRUE); sum(S$f[i]) / sum(S$o[i]) }); list(ratio_lo = quantile(r, .025), ratio_hi = quantile(r, .975)) }
X[, c25 := cut(D1, c(0, 2.5, 5, 7.5, 10, 12.7, 15, 20, 25, Inf), right = FALSE)]
X[, c1 := cut(D1, c(seq(0, 13, 1), Inf), right = FALSE)]
T1 <- tab(X, c("set", "c25"))[order(set, c25)]; T1 <- merge(T1, X[, bsr(.SD), by = .(set, c25)], by = c("set", "c25"))
T2 <- tab(X[D1 < 12.7], c("set", "c1"))[order(set, c1)]
T3 <- tab(X, c("set", "prog", "c25"))[order(set, prog, c25)]; T3 <- merge(T3, X[, bsr(.SD), by = .(set, prog, c25)], by = c("set", "prog", "c25"))
T4 <- tab(X[D1 < 12.7][, small := D1 < 7.5], c("set", "prog", "grp", "small"))[order(set, prog, grp, small)]
X[, hcl := cut(H1, c(0, 1.8, 2.5, 3.5, 5, 8, Inf), right = FALSE)]
T5 <- tab(X[D1 < 12.7], c("set", "prog", "hcl"))[order(set, prog, hcl)]
## site overlap: do sites with trees below 7.5 cm also hold 7.5 cm and over trees, and how are those predicted?
X[, site_small := sidx %in% sidx[D1 < 7.5], by = set]
T6 <- tab(X, c("set", "site_small", "c25"))[order(set, site_small, c25)]
T1[, table := "class"]; T2[, table := "class 1 cm"]; T3[, table := "program by class"]; T4[, table := "program by species group"]
T5[, table := "program by H1 class"]; T6[, table := "site holds trees below 7.5 cm"]
fwrite(rbindlist(list(T1, T2, T3, T4, T5, T6), fill = TRUE), f_out("gyr142-p25-diag-smalltree-foldA_DATA_2026-09-29.csv"))
cols <- c("trees", "sites", "D_mean", "H1_mean", "obs", "pred141", "predf", "ratio_f", "share_neg", "share_H1_lt2", "share_H_int", "share_H_dm")
cat("== 2.5 cm classes ==\n"); print(T1[, c("set", "c25", cols, "ratio_lo", "ratio_hi"), with = FALSE], digits = 3)
cat("== 1 cm classes below 12.7 ==\n"); print(T2[, c("set", "c1", cols), with = FALSE], digits = 3)
cat("== program by class ==\n"); print(T3[, c("set", "prog", "c25", cols, "ratio_lo", "ratio_hi"), with = FALSE], digits = 3)
cat("== program by species group, below 12.7 ==\n"); print(T4[, c("set", "prog", "grp", "small", cols), with = FALSE], digits = 3)
cat("== program by H1 class, below 12.7 ==\n"); print(T5[, c("set", "prog", "hcl", cols), with = FALSE], digits = 3)
cat("== site holds small trees ==\n"); print(T6[, c("set", "site_small", "c25", cols), with = FALSE], digits = 3)
cat(sprintf("smallest D1: ns_c %.1f, ns_long_c %.1f cm\n", X[set == "ns_c", min(D1)], X[set == "ns_long_c", min(D1)]))
cat("P25_DIAG_DONE\n")

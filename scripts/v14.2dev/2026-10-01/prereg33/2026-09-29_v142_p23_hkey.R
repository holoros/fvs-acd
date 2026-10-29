## PREREG23 shared helper: tag matched survivor height key for QC sets, joined to one arm's predicted t2 heights.
## Reuses the PREREG16 scorer (md5 019df238) species, NSVB and form/risk split code verbatim by parsing its lines between
## the "verbatim from the runner" and "QC harvest screen" markers (no copy, no edit). Tag rules are the scorer's C2 rules:
## TAG finite and below 9e6, duplicate (STAND, TAG) keys dropped at either end, same species at both ends, measured HT2;
## PREREG23 adds measured HT1 (> 0) so the increment is observed. Predicted t2 height of a split hardwood record is the mean
## over its split parts (the spread is reported). Fold: first hex digit of md5(SITE) even is A. No coordinates. No em dashes.
suppressMessages({ library(data.table); library(digest) })
P19 <- "/home/aaron/jobs/v142p19"; SCORER <- file.path(P19, "scripts/2026-09-27_v142_volconv_score.R")
if (unname(tools::md5sum(SCORER)) != "019df23877abd9e1aab83831d13322dc") stop("scorer md5 differs")
hs <- function(fmt, ...) stop(sprintf(fmt, ...))
REFD <- "/home/aaron/jobs/v142p19/home/magplot/verify"; SPLITF <- "/home/aaron/jobs/v142p19/home/hw_formrisk_split.R"
if (unname(tools::md5sum(SPLITF)) != "0b604babd7cbef91afc0ded4b2687431") stop("split file md5 differs")
.L <- readLines(SCORER); .a <- grep("^## ---- verbatim from the runner", .L); .b <- grep("^## ---- QC harvest screen", .L)
eval(parse(text = .L[.a:(.b - 1)]))
FR <- file.path(P19, "home/magplot/verify/gydbreg20260916/frames")
fold_of <- function(x) { u <- unique(as.character(x)); f <- ifelse(strtoi(substr(vapply(u, digest, "", algo = "md5", serialize = FALSE), 1, 1), 16L) %% 2 == 0, "A", "B"); f[match(as.character(x), u)] }
tagok <- function(t) if (is.numeric(t)) is.finite(t) & t < 9e6 else !is.na(t) & nzchar(as.character(t))
## stands: RUN_OK stands of an arm's results file, with fold and the PREREG19 scorer cut flag (screen) attached
stand_frame <- function(resf, set, cutf) {
  r <- fread(resf)[, STAND := as.character(STAND)]
  if (anyDuplicated(r$STAND)) stop("duplicated STAND in ", resf)
  r <- r[RUN_OK == 1]
  cu <- fread(cutf)[label == set & arm == "p19_a0111", .(STAND = as.character(STAND), cut)]
  r <- merge(r, cu, by = "STAND", all.x = TRUE); if (anyNA(r$cut)) stop("stand without cut flag in ", resf)
  r[, fold := fold_of(SITE)]; r }
## tag key for a set of stands (no model output involved)
tag_key <- function(set, stands) {
  F <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", set)))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% stands]
  G <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_t2.csv", set)))[, STAND := as.character(STAND)][, row0 := seq_len(.N), by = STAND][STAND %in% stands]
  F[, sp := mapsp(SP)]; M <- split_map(F)
  t1 <- F[tagok(TREE), .(STAND, TAG = TREE, row0, SP, D1 = DBH, H1 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]
  t2 <- G[tagok(TREE), .(STAND, TAG = TREE, SP2 = SP, D2 = DBH, H2 = fifelse(is.finite(HT) & HT > 0, HT, NA_real_))]
  d1 <- t1[, .N, by = .(STAND, TAG)][N > 1]; d2 <- t2[, .N, by = .(STAND, TAG)][N > 1]
  t1 <- t1[!d1, on = .(STAND, TAG)]; t2 <- t2[!d2, on = .(STAND, TAG)]
  K <- merge(t1, t2, by = c("STAND", "TAG"))[SP == SP2 & is.finite(H2) & is.finite(H1)]
  ## t1 dominant cohort: largest trees by DBH up to 100 stems/ha in the init frame (the runner TOPHT rule, line 208)
  F[, o := frank(-DBH, ties.method = "first"), by = STAND]; setorder(F, STAND, o)
  F[, cw := cumsum(EXPF), by = STAND]; F[, dom := cw <= 100 | o == 1L]
  K <- merge(K, F[, .(STAND, row0, dom)], by = c("STAND", "row0"))
  list(K = K, M = M) }
## predicted t2 height per tag record for one arm (main outputs, later retry directories replace whole stands)
pred_ht <- function(dirs, M, stands) {
  acc <- NULL
  for (d in dirs) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
    x <- rbindlist(lapply(fs, fread, select = c("STAND", "iv", "tree", "ht", "ing")))[, STAND := as.character(STAND)]
    if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }
  P <- acc[ing == 0 & STAND %in% stands]
  if (anyDuplicated(P[, .(STAND, tree)])) stop("duplicated STAND tree in predictions")
  P <- merge(P, M[, .(STAND, tree, row0)], by = c("STAND", "tree"))
  P[, .(Hp = mean(ht), Hp_spread = max(ht) - min(ht), iv = iv[1], nsplit = .N), by = .(STAND, row0)] }
arm_dirs <- function(home, arm, set) c(file.path(home, "out", arm, set), file.path(home, sprintf("out_retry_a%d", 1:3), arm, set))

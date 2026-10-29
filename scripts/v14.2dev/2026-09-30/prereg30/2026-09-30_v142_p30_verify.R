## PREREG30 [F9] independent re-derivation. Shares no code with the assembly: no source(), its own fold code (openssl md5),
## its own tag match (built from the firebreather frames TREE tags and compared with the PREREG20 key), its own dominant
## cohort rule, its own readers of the per tree and per stand outputs. Recomputes every gate point value (H0, L1 to L5 for
## v141LT, v141LTf and v141LTfi on ns_long_c fold B) and every fold B point value of the assembled height and TOPHT tables,
## and compares with ~/jobs/v142p30/assembled/ at tolerance 1e-9 (absolute). Bootstrap limits are not re-derived.
## No coordinates are read. No em dashes.
suppressMessages({ library(data.table); library(openssl) })
J <- "/home/aaron/jobs/v142p30"; A <- file.path(J, "assembled"); V <- file.path(J, "verify_20260930"); TOL <- 1e-9
FRM <- "/home/aaron/jobs/v142p20/home/magplot/verify/gydbreg20260916/frames"
hexfold <- function(site) { h <- as.character(md5(as.character(site))); d <- match(substr(h, 1, 1), c(0:9, letters[1:6])) - 1L; c("A", "B")[1L + (d %% 2L)] }
homes <- list(v141LT = c(file.path(J, "home"), "g0_off"), v141LTf = c("/home/aaron/jobs/v142p20/home", "v141LTf"), v141LTfi = c("/home/aaron/jobs/v142p22/home", "v141LTfi"))
frozen_res <- list(v141LTf = "/home/aaron/jobs/v142p20/results/v141LTf/gyr_v141LTf_%s_results.csv", v141LTfi = "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_%s_results.csv")
## dry test switch (P30_VDRY=1): read dry/assembled and stand the v141LT run in by the frozen v141LTf outputs, as the assembly dry run does
if (Sys.getenv("P30_VDRY") == "1") { A <- file.path(J, "dry/assembled"); homes$v141LT <- homes$v141LTf; V <- file.path(J, "dry") }
stack_files <- function(arm, set, pattern, cols = NULL) {
  roots <- c(file.path(homes[[arm]][1], "out", homes[[arm]][2], set), sapply(1:3, function(k) file.path(homes[[arm]][1], paste0("out_retry_a", k), homes[[arm]][2], set)))
  out <- NULL
  for (r in roots) { f <- list.files(r, pattern, full.names = TRUE); if (length(f) == 0) next
    d <- rbindlist(lapply(f, function(x) if (is.null(cols)) fread(x, colClasses = list(character = "STAND")) else fread(x, select = cols, colClasses = list(character = "STAND"))), fill = TRUE)
    if (!is.null(out)) out <- out[!(STAND %chin% d$STAND)]
    out <- rbind(out, d, fill = TRUE) }
  out }
FLAGS <- list(); VALS <- list()
flag <- function(what, mine, theirs) { d <- abs(mine - theirs); FLAGS[[length(FLAGS) + 1L]] <<- data.table(check = what, mine = mine, assembled = theirs, absdiff = d, ok = is.finite(d) & d <= TOL) }
AH <- fread(file.path(A, "gyr142-p30-height_DATA_2026-09-30.csv")); AT <- fread(file.path(A, "gyr142-p30-topht_DATA_2026-09-30.csv"))
AG <- fread(file.path(A, "gyr142-p30-gates_DATA_2026-09-30.csv")); AH0 <- fread(file.path(A, "gyr142-p30-h0_DATA_2026-09-30.csv"))
for (sx in c("ns_long_c", "ns_long_fl")) {
  rf <- fread(sprintf(frozen_res$v141LTf, sx), select = c("STAND", "SITE", "interval_years"), colClasses = list(character = "STAND"))
  rf[, fold := hexfold(SITE)]; bst <- rf[fold == "B"]
  ## own tag match from the frames: row index within stand, finite tag below 9e6, unique tag per stand and end, same species, heights at both ends
  t1 <- fread(file.path(FRM, sprintf("bench_gyr_%s_tree_init.csv", sx)), select = c("STAND", "TREE", "SP", "DBH", "HT", "EXPF"), colClasses = list(character = "STAND"))
  t1[, tree := rowid(STAND)]
  t2 <- fread(file.path(FRM, sprintf("bench_gyr_%s_tree_t2.csv", sx)), select = c("STAND", "TREE", "SP", "HT"), colClasses = list(character = "STAND"))
  okt <- function(d) d[is.finite(TREE) & TREE < 9e6][, if (.N == 1L) .SD, by = .(STAND, TREE)]
  m1 <- okt(t1[is.finite(HT) & HT > 0]); m2 <- okt(t2[is.finite(HT) & HT > 0]); setnames(m2, c("SP", "HT"), c("SP2", "H2"))
  own <- merge(m1, m2, by = c("STAND", "TREE"))[SP == SP2]
  key <- fread(sprintf("/home/aaron/jobs/v142p20/in/key/p20_htkey_%s.csv", sx), colClasses = list(character = "STAND"))
  key <- key[STAND %chin% rf$STAND]
  both <- merge(own[, .(STAND, tree, H2own = H2)], key[, .(STAND, tree, H2)], by = c("STAND", "tree"))
  VALS[[paste(sx, "t1align")]] <- data.table(set = sx, key_rows_t1_frame_align = nrow(merge(key, t1[, .(STAND, tree, DBH, HT)], by = c("STAND", "tree"))[abs(DBH - D1) < 1e-9 & abs(HT - H1) < 1e-9]), key_rows = nrow(key))
  VALS[[paste(sx, "tagmatch")]] <- data.table(set = sx, own_match = nrow(own[STAND %chin% rf$STAND]), key_trees = nrow(key), in_both = nrow(both),
    h2_agree = sum(abs(both$H2own - both$H2) < 1e-9))
  ## fold of the key recomputed from SITE
  key <- merge(key, rf[, .(STAND, fold2 = fold)], by = "STAND"); VALS[[paste(sx, "fold")]] <- data.table(set = sx, fold_disagree = key[fold != fold2, .N])
  kb <- key[fold2 == "B"]
  ## dominant cohort at t1, base R ordering
  t1 <- t1[order(STAND, -DBH, tree)]; t1[, rk := rowid(STAND)]; t1[, cumx := cumsum(EXPF), by = STAND]; t1[, dom2 := (cumx <= 100) | (rk == 1L)]
  kb <- merge(kb, t1[, .(STAND, tree, dom2)], by = c("STAND", "tree"))
  ## predictions
  for (ax in names(homes)) { p <- stack_files(ax, sx, "_pred_t2_tree\\.csv$", c("STAND", "tree", "ht", "ing"))[ing == 0, .(STAND, tree, ht)]
    setnames(p, "ht", paste0("P_", ax)); kb <- merge(kb, p, by = c("STAND", "tree"), all.x = TRUE) }
  flag(paste(sx, "H0 worst"), max(abs(kb$P_v141LT - kb$Hp141) / pmax(1, abs(kb$Hp141))), AH0[set == sx]$worst_scaled)
  flag(paste(sx, "H0 trees"), nrow(kb), AH0[set == sx]$key_trees_foldB)
  kb[, Q_v141LT := Hp141]; kb[, Q_v141LTf := P_v141LTf]; kb[, Q_v141LTfi := P_v141LTfi]
  groups <- list(overall = rep(TRUE, nrow(kb)), `below 12.7` = kb$D1 < 12.7, `12.7 to 25` = kb$D1 >= 12.7 & kb$D1 < 25, `25 and over` = kb$D1 >= 25,
    `interval below 10` = kb$iv < 10, `interval 10 to 19` = kb$iv >= 10 & kb$iv < 20, `interval 20 and over` = kb$iv >= 20, `interval 10 and over` = kb$iv >= 10, dominant = kb$dom2)
  for (g in names(groups)) { z <- kb[groups[[g]]]; if (!nrow(z)) next
    for (ax in names(homes)) { q <- z[[paste0("Q_", ax)]]; lev <- sum(q) / sum(z$H2); bia <- mean(q - z$H2); ib <- mean((q - z$H1) / z$iv - (z$H2 - z$H1) / z$iv)
      a <- AH[set == sx & fold == "B" & group == g & arm == ax]
      flag(paste(sx, g, ax, "level"), lev, a$level); flag(paste(sx, g, ax, "bias m"), bia, a$bias_m); flag(paste(sx, g, ax, "inc bias"), ib, a$inc_bias_m_yr); flag(paste(sx, g, ax, "trees"), nrow(z), a$trees)
      VALS[[paste(sx, g, ax)]] <- data.table(set = sx, group = g, arm = ax, trees = nrow(z), level = lev, bias_m = bia) } }
  ## TOPHT on fold B stands RUN_OK in all three arms
  rr <- list(v141LT = stack_files("v141LT", sx, "^c[0-9]+_results\\.csv$", c("STAND", "RUN_OK", "TOPHT_o", "TOPHT_p")))
  for (ax in c("v141LTf", "v141LTfi")) rr[[ax]] <- fread(sprintf(frozen_res[[ax]], sx), select = c("STAND", "RUN_OK", "TOPHT_o", "TOPHT_p"), colClasses = list(character = "STAND"))
  good <- bst$STAND; for (ax in names(rr)) good <- intersect(good, rr[[ax]][RUN_OK == 1 & is.finite(TOPHT_o) & is.finite(TOPHT_p), STAND])
  for (ax in names(rr)) { x <- rr[[ax]][STAND %chin% good]; pct <- 100 * (mean(x$TOPHT_p) / mean(x$TOPHT_o) - 1)
    a <- AT[set == sx & group == "all" & arm == ax]
    flag(paste(sx, "TOPHT pct", ax), pct, a$topht_bias_pct); flag(paste(sx, "TOPHT stand bias", ax), mean(x$TOPHT_p - x$TOPHT_o), a$stand_bias_m); flag(paste(sx, "TOPHT stands", ax), nrow(x), a$stands)
    VALS[[paste(sx, "TOPHT", ax)]] <- data.table(set = sx, group = "TOPHT", arm = ax, trees = nrow(x), level = pct, bias_m = mean(x$TOPHT_p - x$TOPHT_o)) }
}
## gate values read back from the gate table against the recomputed values
gv <- function(g, d, ax) { x <- AG[gate == g & detail == d & arm %in% c(ax, paste(ax, "(reported)"))]; if (nrow(x) != 1) stop("gate row ", g, d, ax); x$value }
for (ax in c("v141LTf", "v141LTfi")) {
  src <- function(g) AH[set == "ns_long_c" & fold == "B" & group == g & arm == ax]$level
  flag(paste("gate L1", ax), gv("L1", "pooled level ratio", ax), src("overall"))
  for (g in c("below 12.7", "12.7 to 25", "25 and over")) flag(paste("gate L2", g, ax), gv("L2", paste("level ratio,", g), ax), src(g))
  flag(paste("gate L3", ax), gv("L3", "dominant cohort level", ax), src("dominant"))
  flag(paste("gate L4", ax), gv("L4", "published TOPHT bias percent", ax), AT[set == "ns_long_c" & group == "all" & arm == ax]$topht_bias_pct)
  flag(paste("gate L5", ax), gv("L5", "level ratio, interval 10 years and over", ax), src("interval 10 and over")) }
FL <- rbindlist(FLAGS); VL <- rbindlist(VALS, fill = TRUE)
fwrite(FL, file.path(V, "p30-verify-flags_DATA_2026-09-30.csv")); fwrite(VL, file.path(V, "p30-verify-values_DATA_2026-09-30.csv"))
print(VL[is.na(group) | group %in% c("overall", "dominant", "interval 10 and over", "TOPHT")], digits = 6)
cat(sprintf("checks %d, failed %d, worst absdiff %.3g\n", nrow(FL), FL[ok == FALSE, .N], max(FL$absdiff, na.rm = TRUE)))
if (FL[ok == FALSE, .N] > 0) { print(FL[ok == FALSE]); stop("P30 VERIFY MISMATCH") }
cat("P30_VERIFY_DONE\n")

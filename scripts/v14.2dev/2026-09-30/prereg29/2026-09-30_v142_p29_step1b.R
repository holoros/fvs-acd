## PREREG29 step 1b, fold A only: (i) the matched program contrast with a stable estimator (the step 1 cell ratio of sums
## was unstable where a cell's observed increment summed near zero), (ii) the same contrast at matched ba_all and topht,
## the two production state variables with the steepest within NS_RS gradient, and (iii) whether the same NS_RS site
## carries the same ESI in ns_c and ns_long_c. Estimator: within cells holding both programs, mean predicted and mean
## observed increment per cell and program; each program's matched ratio = sum_c w_c mean_f / sum_c w_c mean_o with w_c
## the NS_RS tree share of cell c. Site cluster bootstrap B = 1000, seed 20260930. No fold B tree is read. No em dashes.
suppressMessages(library(data.table)); options(width = 220); set.seed(20260930)
J <- "/home/aaron/jobs/v142p29_nsrs"; P20 <- "/home/aaron/jobs/v142p20"; KEY <- "/home/aaron/jobs/v142p22/in/key"
FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"
O <- file.path(J, "step1b"); if (dir.exists(O)) stop("REFUSE ", O); dir.create(O)
progof <- function(s) fifelse(grepl("^NS(_LONG)?__NS_RS_", s), "NS_RS", "NS_OP")
pred <- function(s) { fl <- list.files(file.path(P20, "home/out/v141LTf", s), "_pred_t2_tree\\.csv$", full.names = TRUE)
  pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]; stopifnot(!anyDuplicated(pt[, .(STAND, tree)])); pt[, .(STAND, tree, Hpf = ht)] }
ST <- fread(file.path(J, "step1/p29-s1-stand-state-foldA_DATA_2026-09-30.csv"))
K <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) { k <- fread(file.path(KEY, sprintf("p20_htkey_%s.csv", s)))[fold == "A"]
  x <- merge(k, pred(s), by = c("STAND", "tree")); x[, .(set = s, STAND, sidx, D1, dho = (H2 - H1) / iv, dhf = (Hpf - H1) / iv, prog = progof(STAND))] }))
T <- merge(K, ST[, .(set, STAND, qmd9, tph9, topht, esi8, ba_all, sdi_all)], by = c("set", "STAND")); stopifnot(nrow(T) == nrow(K))
matched <- function(d, keys, label) {
  d <- d[complete.cases(d[, ..keys])]; d[, cell := do.call(paste, .SD), .SDcols = keys]
  both <- d[, uniqueN(prog), by = cell][V1 == 2, cell]; dm <- d[cell %in% both]
  C <- dm[, .(o = sum(dho), f = sum(dhf), n = .N), by = .(cell, prog, sidx)]
  est <- function(Cc) { a <- Cc[, .(mo = sum(o) / sum(n), mf = sum(f) / sum(n), n = sum(n)), by = .(cell, prog)]
    ok <- a[, .N, by = cell][N == 2, cell]; a <- a[cell %in% ok]; w <- a[prog == "NS_RS", .(cell, w = n / sum(n))]; a <- merge(a, w, by = "cell")
    c(rs = a[prog == "NS_RS", sum(w * mf) / sum(w * mo)], op = a[prog == "NS_OP", sum(w * mf) / sum(w * mo)]) }
  e0 <- est(C); sites <- unique(C$sidx)
  bb <- t(replicate(1000, { cc <- data.table(sidx = sample(sites, length(sites), TRUE))[, .(k = .N), by = sidx]
    est(merge(C, cc, by = "sidx")[, .(o = o * k, f = f * k, n = n * k, cell, prog, sidx)]) }))
  q <- function(v, p) unname(quantile(v, p, na.rm = TRUE))
  data.table(match = label, rs_trees = d[prog == "NS_RS", .N], rs_trees_matched = dm[prog == "NS_RS", .N], op_trees = d[prog == "NS_OP", .N], op_trees_matched = dm[prog == "NS_OP", .N],
    shared_cells = length(both), rs_ratio = e0[["rs"]], rs_lo = q(bb[, 1], .025), rs_hi = q(bb[, 1], .975), op_ratio = e0[["op"]], op_lo = q(bb[, 2], .025), op_hi = q(bb[, 2], .975),
    diff = e0[["rs"]] - e0[["op"]], diff_lo = q(bb[, 1] - bb[, 2], .025), diff_hi = q(bb[, 1] - bb[, 2], .975),
    rs_raw = d[prog == "NS_RS", sum(dhf) / sum(dho)], op_raw = d[prog == "NS_OP", sum(dhf) / sum(dho)]) }
tert <- function(d, v, k = 3) { sv <- unique(d[, .(STAND, z = get(v))])[is.finite(z)]; br <- unique(quantile(sv$z, seq(0, 1, length.out = k + 1))); cut(d[[v]], br, include.lowest = TRUE, labels = FALSE) }
OUT <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) { d <- T[set == s & D1 >= 9.1]
  d[, dk := cut(D1, c(9.1, 12.7, 25, Inf), right = FALSE, labels = FALSE)]
  for (v in c("qmd9", "tph9", "topht", "esi8")) d[, (paste0(v, "_k")) := tert(d, v)]
  for (v in c("ba_all", "topht")) d[, (paste0(v, "_q5")) := tert(d, v, 5)]
  rbind(matched(copy(d), c("qmd9_k", "tph9_k", "topht_k", "esi8_k", "dk"), "qmd9 tph9 topht esi8 tertiles and size class"),
    matched(copy(d), c("ba_all_q5", "topht_q5", "dk"), "ba_all and topht quintiles and size class"),
    matched(copy(d), c("qmd9_k", "tph9_k", "topht_k", "dk"), "qmd9 tph9 topht tertiles and size class, no ESI"))[, set := s] }))
setcolorder(OUT, "set"); fwrite(OUT, file.path(O, "p29-s1b-matched_DATA_2026-09-30.csv")); print(OUT, digits = 3)
## ESI of the same NS_RS and NS_OP site id in ns_c and ns_long_c (fold A sites only)
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest::digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
e1 <- fread(file.path(FR, "bench_gyr_ns_c_site_esi.csv"))[, id := sub("^NS__", "", SITE)][, fA := fold(SITE)]
e2 <- fread(file.path(FR, "bench_gyr_ns_long_c_site_esi.csv"))[, id := sub("^NS_LONG__", "", SITE)]
EE <- merge(e1[fA == "A", .(id, esi_c = esi8)], e2[, .(id, esi_long = esi8)], by = "id")[, prog := fifelse(grepl("^NS_RS_", id), "NS_RS", "NS_OP")]
ES <- EE[, .(sites = .N, esi_c = mean(esi_c), esi_long = mean(esi_long), mean_diff = mean(esi_long - esi_c), share_equal = mean(abs(esi_long - esi_c) < 1e-6),
  cor = cor(esi_c, esi_long), ratio_long_over_c = mean(esi_long / esi_c)), by = prog]
fwrite(ES, file.path(O, "p29-s1b-esi-cross-set_DATA_2026-09-30.csv")); print(ES, digits = 4)
cat("P29_STEP1B_DONE\n")

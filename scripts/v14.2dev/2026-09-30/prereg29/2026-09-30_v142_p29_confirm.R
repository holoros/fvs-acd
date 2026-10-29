## PREREG29 held out confirmation, offline, no engine run. Runs only when P29_PREREG_MD5 matches the pre-registration.
## (a) the PREREG20 two segment form refit on NS_OP fold A (b1, b2 read from step1/p29-s1-nsop-refit-params) against the
## pooled PREREG20 fit (read from v142p20/fit), both applied offline to the frozen v141LT per tree increments (Hp141 in
## the PREREG20 key), by set, fold, program and class. (b) held out check of the step 1 negative finding: the NS_RS
## deficit at matched production stand state, and by within NS_RS state quartile. Reproduction checks first (PREREG25
## fold A program by class to 1e-9, PREREG20 H2 below 12.7 cells to 1e-9, step 1 refit in sample table to 1e-9), then
## gates, then the decision rule in order. Site cluster bootstrap B = 1000, seed 20260930. Writes a new assembled/
## directory and refuses if it exists. Headless, theme_classic, 300 dpi. No coordinates. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) }); setDTthreads(1); options(width = 230); set.seed(20260930)
J <- "/home/aaron/jobs/v142p29_nsrs"; P20 <- "/home/aaron/jobs/v142p20"; P25 <- "/home/aaron/jobs/v142p25"; KEY <- "/home/aaron/jobs/v142p22/in/key"
FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"
PR <- file.path(J, "prereg/2026-09-30_v142_nsrs-state-and-nsop-refit_PREREG29.md")
want <- Sys.getenv("P29_PREREG_MD5", ""); got <- unname(tools::md5sum(PR)); if (!nzchar(want) || want != got) stop("PREREG md5 mismatch or unset: ", got)
OUT <- file.path(J, "assembled"); if (dir.exists(OUT)) stop("REFUSE ", OUT, " exists"); dir.create(OUT); f_out <- function(n) file.path(OUT, n)
progof <- function(s) fifelse(grepl("^NS(_LONG)?__NS_RS_", s), "NS_RS", "NS_OP")
m2 <- function(D, b1, b2) exp(-b1 * pmax(0, pmin(D, 25) - 12.7) - b2 * pmax(0, D - 25))
## ---- parameters with provenance (F9) ----
PPf <- file.path(P20, "fit/gyr142-p20-fit-params_DATA_2026-09-28.csv"); OPf <- file.path(J, "step1/p29-s1-nsop-refit-params_DATA_2026-09-30.csv")
PP <- fread(PPf)[form == "two segment"]; OPp <- fread(OPf)[fit == "NS_OP"]; stopifnot(nrow(PP) == 1, nrow(OPp) == 1)
prov <- data.table(item = c("pooled b1 b2", "NS_OP b1 b2"), file = c(PPf, OPf), md5 = unname(tools::md5sum(c(PPf, OPf))),
  b1 = c(PP$b1, OPp$b1), b2 = c(PP$b2, OPp$b2), b1_lo = c(PP$b1_lo, OPp$b1_lo), b1_hi = c(PP$b1_hi, OPp$b1_hi), b2_lo = c(PP$b2_lo, OPp$b2_lo), b2_hi = c(PP$b2_hi, OPp$b2_hi))
fwrite(prov, f_out("gyr142-p29-provenance_DATA_2026-09-30.csv"))
## ---- data ----
pred <- function(s) {
  fl <- list.files(file.path(P20, "home/out/v141LTf", s), "_pred_t2_tree\\.csv$", full.names = TRUE); stopifnot(length(fl) > 0)
  pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]
  for (k in 1:3) { rf <- list.files(file.path(P20, sprintf("home/out_retry_a%d/v141LTf/%s", k, s)), "_pred_t2_tree\\.csv$", full.names = TRUE)
    if (length(rf)) { r <- rbindlist(lapply(rf, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]; pt <- rbind(pt[!STAND %in% r$STAND], r) } }
  stopifnot(!anyDuplicated(pt[, .(STAND, tree)])); pt[, .(STAND, tree, Hpf = ht)] }
SETS <- c("ns_c", "ns_long_c", "ns_fl", "ns_long_fl")
X <- rbindlist(lapply(SETS, function(s) {
  x <- merge(fread(file.path(KEY, sprintf("p20_htkey_%s.csv", s))), pred(s), by = c("STAND", "tree"), all.x = TRUE); stopifnot(!anyNA(x$Hpf))
  x[, .(set = s, STAND, sidx, fold, D1, dho = (H2 - H1) / iv, dhp = (Hp141 - H1) / iv, dhf = (Hpf - H1) / iv, prog = progof(STAND))] }))
X[, `:=`(mp = m2(D1, PP$b1, PP$b2), mo = m2(D1, OPp$b1, OPp$b2))]
## ---- reproduction checks ----
X[, c25 := as.character(cut(D1, c(0, 2.5, 5, 7.5, 10, 12.7, 15, 20, 25, Inf), right = FALSE))]
DA <- fread(file.path(P25, "fit/gyr142-p25-diag-smalltree-foldA_DATA_2026-09-29.csv"))[table == "program by class"]
ck1 <- merge(X[fold == "A" & set %in% c("ns_c", "ns_long_c"), .(r = mean(dhf) / mean(dho), n = .N), by = .(set, prog, c25)], DA[, .(set, prog, c25, ratio_f, trees)], by = c("set", "prog", "c25"))
e1 <- ck1[, max(abs(r - ratio_f))]; ok1 <- nrow(ck1) == nrow(DA) && e1 <= 1e-9 && all(ck1$n == ck1$trees)
H2 <- fread(file.path(P20, "tables/gyr142-p20-h2-sizeclass_DATA_2026-09-28.csv"))[cls == "below 12.7"]
ck2 <- merge(X[D1 < 12.7, .(r = mean(dhf) / mean(dho), n = .N), by = .(set, fold)], H2[, .(set, fold, rf, trees)], by = c("set", "fold"))
e2 <- ck2[, max(abs(r - rf))]; ok2 <- nrow(ck2) == 8 && e2 <= 1e-9 && all(ck2$n == ck2$trees)
X[, cls := cut(D1, c(0, 7.5, 12.7, 25, Inf), right = FALSE, labels = c("below 7.5", "7.5 to 12.7", "12.7 to 25", "25 and over"))]
IS <- fread(file.path(J, "step1/p29-s1-nsop-refit-insample-foldA_DATA_2026-09-30.csv"))
ck3 <- merge(X[set == "ns_c" & fold == "A", .(r141 = mean(dhp) / mean(dho), rp = mean(mp * dhp) / mean(dho), ro = mean(mo * dhp) / mean(dho), n = .N), by = .(prog, cls = as.character(cls))], IS, by = c("prog", "cls"))
e3 <- ck3[, max(abs(c(r141.x - r141.y, rp - r_pooled, ro - r_nsop)))]; ok3 <- nrow(ck3) == nrow(IS) && e3 <= 1e-9 && all(ck3$n == ck3$trees)
REP <- data.table(check = c("PREREG25 fold A program by class", "PREREG20 H2 below 12.7", "step 1 refit in sample fold A"), cells = c(nrow(ck1), nrow(ck2), nrow(ck3)), worst = c(e1, e2, e3), pass = c(ok1, ok2, ok3))
fwrite(REP, f_out("gyr142-p29-repro_DATA_2026-09-30.csv")); print(REP)
if (!all(REP$pass)) { writeLines(c(sprintf("PREREG29 md5 %s", got), "Rule 1: reproduction check failed; harness failure, no verdict"), f_out("gyr142-p29-verdict_2026-09-30.txt")); stop("REPRO FAIL") }
## ---- (a) offline refit tables ----
X[, cls2 := fifelse(D1 >= 12.7, "12.7 and over", "below 12.7")]
bsr <- function(d) { S <- d[, .(o = sum(dho), p = sum(mp * dhp), q = sum(mo * dhp)), by = sidx]; n <- nrow(S)
  if (n < 2) return(list(pooled_lo = NA_real_, pooled_hi = NA_real_, nsop_lo = NA_real_, nsop_hi = NA_real_, d_lo = NA_real_, d_hi = NA_real_))
  r <- replicate(1000, { i <- sample.int(n, n, TRUE); c(sum(S$p[i]) / sum(S$o[i]), sum(S$q[i]) / sum(S$o[i])) })
  q <- function(v, p) unname(quantile(v, p))
  list(pooled_lo = q(r[1, ], .025), pooled_hi = q(r[1, ], .975), nsop_lo = q(r[2, ], .025), nsop_hi = q(r[2, ], .975),
    d_lo = q(r[2, ] - r[1, ], .025), d_hi = q(r[2, ] - r[1, ], .975)) }
tab <- function(by) { R <- X[, .(trees = .N, sites = uniqueN(sidx), r141 = mean(dhp) / mean(dho), r_engine_v141LTf = mean(dhf) / mean(dho),
    r_pooled_offline = mean(mp * dhp) / mean(dho), r_nsop_offline = mean(mo * dhp) / mean(dho), r_nsop_engine_adj = mean(mo / mp * dhf) / mean(dho)), by = by]
  merge(R, X[, bsr(.SD), by = by], by = by) }
A4 <- tab(c("set", "fold", "prog", "cls")); A4[, cls := as.character(cls)]
A2 <- tab(c("set", "fold", "prog", "cls2")); setnames(A2, "cls2", "cls")
AP <- tab(c("set", "fold", "cls2")); setnames(AP, "cls2", "cls"); AP[, prog := "pooled"]
TA <- rbind(A4, A2, AP, use.names = TRUE)[, delta := r_nsop_offline - r_pooled_offline][order(set, fold, prog, cls)]
fwrite(TA, f_out("gyr142-p29-a-offline_DATA_2026-09-30.csv"))
g <- function(s, p, c) TA[set == s & fold == "B" & prog == p & cls == c]
M1 <- OPp$b1 < PP$b1_lo || OPp$b1 > PP$b1_hi || OPp$b2 < PP$b2_lo || OPp$b2 > PP$b2_hi
M2v <- c(g("ns_c", "NS_OP", "12.7 to 25")$delta, g("ns_c", "NS_OP", "25 and over")$delta); M2 <- any(abs(M2v) > 0.05)
material <- M1 || M2
GA <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) rbindlist(lapply(c("12.7 to 25", "25 and over"), function(c) { x <- g(s, "NS_OP", c)
  data.table(gate = "A1 NS_OP closer to 1 and within 0.90 to 1.10", set = s, cls = c, pooled = x$r_pooled_offline, nsop = x$r_nsop_offline, nsop_lo = x$nsop_lo, nsop_hi = x$nsop_hi,
    pass = abs(x$r_nsop_offline - 1) < abs(x$r_pooled_offline - 1) && x$r_nsop_offline >= 0.90 && x$r_nsop_offline <= 1.10) }))))
GA2 <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) { x <- g(s, "pooled", "12.7 and over")
  data.table(gate = "A2 all programs 12.7 and over no further from 1 than pooled plus 0.02", set = s, cls = "12.7 and over", pooled = x$r_pooled_offline, nsop = x$r_nsop_offline, nsop_lo = x$nsop_lo, nsop_hi = x$nsop_hi,
    pass = abs(x$r_nsop_offline - 1) <= abs(x$r_pooled_offline - 1) + 0.02) }))
GA3 <- rbindlist(lapply(c("ns_fl", "ns_long_fl"), function(s) { x <- g(s, "NS_OP", "12.7 and over")
  data.table(gate = "A3 fl sets NS_OP 12.7 and over no further from 1 than pooled plus 0.02", set = s, cls = "12.7 and over", pooled = x$r_pooled_offline, nsop = x$r_nsop_offline, nsop_lo = x$nsop_lo, nsop_hi = x$nsop_hi,
    pass = abs(x$r_nsop_offline - 1) <= abs(x$r_pooled_offline - 1) + 0.02) }))
GAT <- rbind(GA, GA2, GA3, fill = TRUE)
MAT <- data.table(gate = c("M1 refit b1 or b2 outside pooled 95% interval (fold A)", "M2 ns_c fold B NS_OP class ratio moves by more than 0.05"),
  value = c(sprintf("NS_OP b1 %.5f (%.5f to %.5f), b2 %.5f; pooled b1 interval %.5f to %.5f, b2 interval %.5f to %.5f", OPp$b1, OPp$b1_lo, OPp$b1_hi, OPp$b2, PP$b1_lo, PP$b1_hi, PP$b2_lo, PP$b2_hi),
    sprintf("delta 12.7 to 25 %.4f, 25 and over %.4f", M2v[1], M2v[2])), pass = c(M1, M2))
## ---- (b) held out check of the negative finding (fold B) ----
ST <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) {
  fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest::digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
  p <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s)), select = c("STAND", "SITE")); p[, fold := fold(SITE)]; p <- p[fold == "B"]
  e <- fread(file.path(P20, sprintf("results/v141LTf/gyr_v141LTf_%s_results.csv", s)), select = c("STAND", "esi8"))
  ti <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)))[STAND %in% p$STAND][, ba := pi / 40000 * DBH^2 * EXPF]
  topht <- function(d) { d <- d[is.finite(HT) & HT > 0][order(-DBH)]; if (!nrow(d)) return(NA_real_); cw <- cumsum(d$EXPF); k <- which(cw >= 100)[1]; if (is.na(k)) k <- nrow(d)
    w <- d$EXPF[seq_len(k)]; if (k > 1) w[k] <- 100 - cw[k - 1] else w[k] <- min(100, cw[1]); sum(w * d$HT[seq_len(k)]) / sum(w) }
  S <- ti[, { f <- .SD[DBH >= 9.1]; tph <- sum(EXPF); ba_ <- sum(ba); q <- sqrt(ba_ / tph * 40000 / pi); t9 <- sum(f$EXPF); b9 <- sum(f$ba)
    list(ba_all = ba_, tph_all = tph, qmd_all = q, sdi_all = tph * (q / 25.4)^1.605, tph9 = t9, qmd9 = if (t9 > 0) sqrt(b9 / t9 * 40000 / pi) else NA_real_, topht = topht(.SD)) }, by = STAND]
  merge(S, e, by = "STAND", all.x = TRUE)[, set := s] }))
TB <- merge(X[fold == "B" & set %in% c("ns_c", "ns_long_c"), .(set, STAND, sidx, D1, dho, dhf, prog)], ST, by = c("set", "STAND")); stopifnot(nrow(TB) == X[fold == "B" & set %in% c("ns_c", "ns_long_c"), .N])
tert <- function(d, v, k = 3) { sv <- unique(d[, .(STAND, z = get(v))])[is.finite(z)]; br <- unique(quantile(sv$z, seq(0, 1, length.out = k + 1))); cut(d[[v]], br, include.lowest = TRUE, labels = FALSE) }
matched <- function(d, keys) {
  d <- d[complete.cases(d[, ..keys])]; d[, cell := do.call(paste, .SD), .SDcols = keys]; both <- d[, uniqueN(prog), by = cell][V1 == 2, cell]; dm <- d[cell %in% both]
  C <- dm[, .(o = sum(dho), f = sum(dhf), n = .N), by = .(cell, prog, sidx)]
  est <- function(Cc) { a <- Cc[, .(mo = sum(o) / sum(n), mf = sum(f) / sum(n), n = sum(n)), by = .(cell, prog)]; ok <- a[, .N, by = cell][N == 2, cell]; a <- a[cell %in% ok]
    w <- a[prog == "NS_RS", .(cell, w = n / sum(n))]; a <- merge(a, w, by = "cell"); c(a[prog == "NS_RS", sum(w * mf) / sum(w * mo)], a[prog == "NS_OP", sum(w * mf) / sum(w * mo)]) }
  e0 <- est(C); sites <- unique(C$sidx)
  bb <- t(replicate(1000, { cc <- data.table(sidx = sample(sites, length(sites), TRUE))[, .(k = .N), by = sidx]; est(merge(C, cc, by = "sidx")[, .(o = o * k, f = f * k, n = n * k, cell, prog, sidx)]) }))
  data.table(rs_trees = d[prog == "NS_RS", .N], rs_matched_trees = dm[prog == "NS_RS", .N], op_matched_trees = dm[prog == "NS_OP", .N], rs = e0[1], op = e0[2], diff = e0[1] - e0[2],
    diff_lo = quantile(bb[, 1] - bb[, 2], .025, na.rm = TRUE), diff_hi = quantile(bb[, 1] - bb[, 2], .975, na.rm = TRUE)) }
B1 <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) { d <- TB[set == s & D1 >= 9.1]; d[, dk := cut(D1, c(9.1, 12.7, 25, Inf), right = FALSE, labels = FALSE)]
  for (v in c("qmd9", "tph9", "topht", "esi8")) d[, (paste0(v, "_k")) := tert(d, v)]; for (v in c("ba_all", "topht")) d[, (paste0(v, "_q5")) := tert(d, v, 5)]
  rbind(matched(copy(d), c("qmd9_k", "tph9_k", "topht_k", "esi8_k", "dk"))[, match := "qmd9 tph9 topht esi8 tertiles, size class"],
    matched(copy(d), c("ba_all_q5", "topht_q5", "dk"))[, match := "ba_all topht quintiles, size class"])[, set := s] }))
fwrite(B1, f_out("gyr142-p29-b-matched-foldB_DATA_2026-09-30.csv"))
bq <- function(d, v) { sv <- unique(d[, .(STAND, z = get(v))])[is.finite(z)]; br <- unique(quantile(sv$z, c(0, .25, .5, .75, 1)))
  d <- copy(d)[, q := cut(get(v), br, include.lowest = TRUE, labels = FALSE)][!is.na(q)]; S <- d[, .(o = sum(dho), f = sum(dhf)), by = .(sidx, q)]
  Mo <- as.matrix(dcast(S, sidx ~ q, value.var = "o", fill = 0)[, -1]); Mf <- as.matrix(dcast(S, sidx ~ q, value.var = "f", fill = 0)[, -1]); n <- nrow(Mo)
  R <- t(replicate(1000, { i <- sample.int(n, n, TRUE); colSums(Mf[i, , drop = FALSE]) / colSums(Mo[i, , drop = FALSE]) }))
  data.table(var = v, q = seq_len(ncol(Mo)), ratio = colSums(Mf) / colSums(Mo), lo = apply(R, 2, quantile, .025, na.rm = TRUE), hi = apply(R, 2, quantile, .975, na.rm = TRUE)) }
B2 <- rbindlist(lapply(c("ns_c", "ns_long_c"), function(s) rbindlist(lapply(c("NS_RS", "NS_OP"), function(p) rbindlist(lapply(c("ba_all", "sdi_all", "topht", "qmd_all", "tph9", "esi8"), function(v)
  bq(TB[set == s & prog == p], v)))[, `:=`(set = s, prog = p)]))))
fwrite(B2, f_out("gyr142-p29-b-quartile-foldB_DATA_2026-09-30.csv"))
GB <- rbind(B1[, .(gate = "B1 matched NS_RS minus NS_OP below -0.25, upper 95% limit below 0", set, detail = sprintf("%s: RS %.3f, OP %.3f, diff %.3f (%.3f to %.3f)", match, rs, op, diff, diff_lo, diff_hi), pass = diff < -0.25 & diff_hi < 0)],
  B2[prog == "NS_RS", .(gate = "B2 every NS_RS state quartile below 0.90 with upper limit below 1", detail = paste(sprintf("%s q%d %.3f (%.3f to %.3f)", var, q, ratio, lo, hi), collapse = "; "), pass = all(ratio < 0.90 & hi < 1)), by = set], use.names = TRUE)
## ---- decision ----
a_pass <- all(GAT$pass); b_pass <- all(GB$pass)
va <- if (!material) "(a) not material: the NS_OP refit does not differ from the pooled PREREG20 fit by the pre-registered thresholds; the pooled form stays" else
  if (a_pass) "(a) pass: material and passes A1 to A3 offline; the next step is a pre-registered (not launched) engine arm with the NS_OP refit in place of the pooled form" else
  "(a) fail: material but fails at least one of A1 to A3 offline; the pooled PREREG20 form stays in the 14.2 candidate"
vb <- if (b_pass) "(b) not material: no production stand state variable explains the NS_RS deficit at matched state on held out sites; the deficit stays a program effect and no state term is proposed" else
  if (!all(GB[grepl("^B1", gate), pass])) "(b) fail of the negative finding: at matched state on fold B the NS_RS deficit shrinks below the threshold; a stand state term is reopened under a new pre-registration" else
  "(b) partial: the matched deficit holds but at least one NS_RS state quartile is predicted at 0.90 or above; reported, and a state term is considered only jointly with a program term under a new pre-registration"
fwrite(rbind(MAT[, .(gate, set = "ns_c", detail = value, pass)], GAT[, .(gate, set, detail = sprintf("%s: pooled %.3f, NS_OP refit %.3f (%.3f to %.3f)", cls, pooled, nsop, nsop_lo, nsop_hi), pass)], GB, use.names = TRUE),
  f_out("gyr142-p29-gates_DATA_2026-09-30.csv"))
writeLines(c(sprintf("PREREG29 md5 %s", got), sprintf("Reproduction worst %.3g, %.3g, %.3g", e1, e2, e3), sprintf("material %s (M1 %s, M2 %s); A1 to A3 %s; B1 and B2 %s", material, M1, M2, a_pass, b_pass), va, vb),
  f_out("gyr142-p29-verdict_2026-09-30.txt"))
## ---- figure: fold B NS_OP and NS_RS by class, pooled offline against NS_OP refit offline ----
pd <- melt(TA[fold == "B" & prog %in% c("NS_OP", "NS_RS") & cls %in% c("7.5 to 12.7", "12.7 to 25", "25 and over")], id.vars = c("set", "prog", "cls"),
  measure.vars = list(r = c("r_pooled_offline", "r_nsop_offline"), lo = c("pooled_lo", "nsop_lo"), hi = c("pooled_hi", "nsop_hi")), variable.name = "form")
pd[, form := factor(form, labels = c("pooled PREREG20", "NS_OP refit"))][, cls := factor(cls, levels = c("7.5 to 12.7", "12.7 to 25", "25 and over"))]
p <- ggplot(pd, aes(cls, r, colour = form)) + geom_hline(yintercept = 1, linetype = 2, colour = "grey50") + geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.5), size = 0.3) +
  facet_grid(prog ~ set, scales = "free_y") + scale_colour_manual(values = c("pooled PREREG20" = "#1b6f8a", "NS_OP refit" = "#b5502a"), name = NULL) +
  labs(x = "Diameter class at t1 (cm), fold B", y = "Offline predicted over observed height increment") + theme_classic(base_size = 10) + theme(legend.position = "bottom")
ggsave(f_out("gyr142-p29-a-offline-foldB_2026-09-30.png"), p, width = 10, height = 5.5, dpi = 300)
print(REP); print(MAT); print(GAT, digits = 3); print(GB); print(TA[fold == "B" & prog != "pooled" & set %in% c("ns_c", "ns_long_c")], digits = 3); print(B1, digits = 3)
cat(va, "\n", vb, "\n"); cat("P29_CONFIRM_DONE\n")

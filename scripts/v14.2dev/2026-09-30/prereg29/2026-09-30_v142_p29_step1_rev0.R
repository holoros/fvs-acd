## PREREG29 step 1: what distinguishes NS_RS stands, fold A only. No fold B tree or ratio is read: fold B stands are
## dropped immediately after the fold is computed from SITE (the PREREG20 rule, first hex digit of md5(SITE) even = A).
## No engine run. Inputs read only: NS frames (v142p22 copy), PREREG20 key, frozen v141LTf per tree t2 predictions and
## results (t1 state columns are engine inputs; v141LT results for NS are not on firebreather). SITE is used only as an
## index and a fold; no coordinates are read or written. Ratio = mean predicted over mean observed annual height
## increment of tag matched survivors (PREREG20 H2 definition). Site cluster bootstrap B = 1000, seed 20260930.
## Also refits the PREREG20 two segment form on NS_OP fold A (same code path as 2026-09-28_v142_p20_fit.R). Headless,
## theme_classic, 300 dpi. No em dashes.
suppressMessages({ library(data.table); library(ggplot2) }); options(width = 240, datatable.print.nrows = 300); set.seed(20260930)
J <- "/home/aaron/jobs/v142p29_nsrs"; P20 <- "/home/aaron/jobs/v142p20"; P25 <- "/home/aaron/jobs/v142p25"
FR <- "/home/aaron/jobs/v142p22/home/magplot/verify/gydbreg20260916/frames"; KEY <- "/home/aaron/jobs/v142p22/in/key"
O <- file.path(J, "step1"); if (dir.exists(O)) stop("REFUSE ", O, " exists"); dir.create(O)
f_out <- function(n) file.path(O, n)
fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest::digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
progof <- function(s) fifelse(grepl("^NS(_LONG)?__NS_RS_", s), "NS_RS", "NS_OP")
SETS <- c("ns_c", "ns_long_c")
## ---------------- per tree height key, fold A only ----------------
pred <- function(s) {
  fl <- list.files(file.path(P20, "home/out/v141LTf", s), "_pred_t2_tree\\.csv$", full.names = TRUE); stopifnot(length(fl) > 0)
  pt <- rbindlist(lapply(fl, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]
  for (k in 1:3) { rf <- list.files(file.path(P20, sprintf("home/out_retry_a%d/v141LTf/%s", k, s)), "_pred_t2_tree\\.csv$", full.names = TRUE)
    if (length(rf)) { r <- rbindlist(lapply(rf, fread, select = c("STAND", "tree", "ht", "ing")))[ing == 0]; pt <- rbind(pt[!STAND %in% r$STAND], r) } }
  stopifnot(!anyDuplicated(pt[, .(STAND, tree)])); pt[, .(STAND, tree, Hpf = ht)] }
K <- rbindlist(lapply(SETS, function(s) { k <- fread(file.path(KEY, sprintf("p20_htkey_%s.csv", s)))[fold == "A"]
  x <- merge(k, pred(s), by = c("STAND", "tree"), all.x = TRUE); stopifnot(!anyNA(x$Hpf))
  x[, .(set = s, STAND, tree, sidx, fold, SP, D1, H1, dho = (H2 - H1) / iv, dhp = (Hp141 - H1) / iv, dhf = (Hpf - H1) / iv, prog = progof(STAND))] }))
cat(sprintf("key fold A: %s\n", paste(K[, .N, by = .(set, prog)][, sprintf("%s %s %d", set, prog, N)], collapse = "; ")))
## ---------------- reproduction check: PREREG25 fold A program by class to 1e-9 ----------------
K[, c25 := as.character(cut(D1, c(0, 2.5, 5, 7.5, 10, 12.7, 15, 20, 25, Inf), right = FALSE))]
DA <- fread(file.path(P25, "fit/gyr142-p25-diag-smalltree-foldA_DATA_2026-09-29.csv"))[table == "program by class"]
ra <- K[, .(r = mean(dhf) / mean(dho), n = .N), by = .(set, prog, c25)]
ck <- merge(ra, DA[, .(set, prog, c25, ratio_f, trees)], by = c("set", "prog", "c25")); e1 <- ck[, max(abs(r - ratio_f))]
repro_ok <- nrow(ck) == nrow(DA) && e1 <= 1e-9 && all(ck$n == ck$trees)
fwrite(data.table(check = "PREREG25 fold A program by class", cells = nrow(ck), cells_ref = nrow(DA), worst_abs = e1, pass = repro_ok), f_out("p29-s1-repro_DATA_2026-09-30.csv"))
if (!repro_ok) stop("REPRO FAIL PREREG25 fold A table ", e1)
cat(sprintf("Reproduction PREREG25 fold A: %d cells, worst %.3g\n", nrow(ck), e1))
## ---------------- stand state at t1, fold A stands only ----------------
ST <- rbindlist(lapply(SETS, function(s) {
  p <- fread(file.path(FR, sprintf("bench_gyr_%s_pairs.csv", s))); p[, fold := fold(SITE)]; p <- p[fold == "A"]
  e <- fread(file.path(FR, sprintf("bench_gyr_%s_site_esi.csv", s)))
  r <- fread(file.path(P20, sprintf("results/v141LTf/gyr_v141LTf_%s_results.csv", s)), select = c("STAND", "BA_t1", "SDI_t1", "QMD_t1", "TOPHT_t1", "SCORE_MINDBH_USED", "esi8", "RUN_OK"))
  ti <- fread(file.path(FR, sprintf("bench_gyr_%s_tree_init.csv", s)))[STAND %in% p$STAND]
  ti[, `:=`(ba = pi / 40000 * DBH^2 * EXPF, swt = toupper(SP) %in% sw)]
  st <- function(d) { if (!nrow(d)) return(list(tph = 0, ba = 0, qmd = NA_real_, sdi = 0))
    tph <- sum(d$EXPF); ba <- sum(d$ba); qmd <- sqrt(ba / tph * 40000 / pi); list(tph = tph, ba = ba, qmd = qmd, sdi = tph * (qmd / 25.4)^1.605) }
  topht <- function(d) { d <- d[is.finite(HT) & HT > 0][order(-DBH)]; if (!nrow(d)) return(NA_real_); cw <- cumsum(d$EXPF); k <- which(cw >= 100)[1]; if (is.na(k)) k <- nrow(d)
    w <- d$EXPF[seq_len(k)]; if (k > 1) w[k] <- 100 - cw[k - 1] else w[k] <- min(100, cw[1]); sum(w * d$HT[seq_len(k)]) / sum(w) }
  S <- ti[, { a <- st(.SD); f <- st(.SD[DBH >= 9.1]); sm <- .SD[DBH < 9.1]
    list(tph_all = a$tph, ba_all = a$ba, qmd_all = a$qmd, sdi_all = a$sdi, tph9 = f$tph, ba9 = f$ba, qmd9 = f$qmd, sdi9 = f$sdi,
      tph_small = sum(sm$EXPF), sw_share = sum(ba[swt]) / sum(ba), bf_share = sum(ba[toupper(SP) == "BF"]) / sum(ba),
      spruce_share = sum(ba[toupper(SP) %in% c("RS", "BS", "WS", "NS")]) / sum(ba), hw_share = sum(ba[!swt]) / sum(ba),
      topht = topht(.SD), ht_meas_share = mean(is.finite(HT) & HT > 0), n_plot = uniqueN(PLOT), plot_m2_med = median(10000 / EXPF),
      expf_max = max(EXPF), dbh_min = min(DBH), dbh_max = max(DBH)) }, by = STAND]
  x <- merge(p[, .(STAND, SITE, Y1, iv = interval_years, MANAGED, MANAGED_OLDFLAG, NSL_SINGLE_REGIME, TRT_AT_Y1, CHURN_FLAG, ESI_SRC, ESI_OLD, FRAME_MINDBH, PLOT_OBS_MINDBH, LINK_SRC)], S, by = "STAND")
  x <- merge(x, r, by = "STAND", all.x = TRUE); x[, `:=`(set = s, prog = progof(STAND))]; x }))
## site index into the key tree table (sidx per SITE from the key)
sm <- unique(K[, .(set, STAND, sidx)]); ST <- merge(ST, sm, by = c("set", "STAND"), all.x = TRUE)
chk_fold <- ST[!is.na(sidx), .N]; cat(sprintf("stands fold A %d, with key trees %d\n", nrow(ST), chk_fold))
stopifnot(all(unique(K$STAND) %in% ST$STAND))   # fold agreement: every fold A key stand is a fold A frame stand
ST[, SITE := NULL]
fwrite(ST, f_out("p29-s1-stand-state-foldA_DATA_2026-09-30.csv"))
## ---------------- program comparison: stand level ----------------
vars <- c("ba_all", "tph_all", "qmd_all", "sdi_all", "ba9", "tph9", "qmd9", "sdi9", "tph_small", "BA_t1", "SDI_t1", "QMD_t1", "TOPHT_t1", "topht",
  "sw_share", "bf_share", "spruce_share", "hw_share", "esi8", "ESI_OLD", "Y1", "iv", "n_plot", "plot_m2_med", "FRAME_MINDBH", "PLOT_OBS_MINDBH", "ht_meas_share")
CMP <- rbindlist(lapply(vars, function(v) ST[, .(var = v, stands = sum(is.finite(get(v))), q10 = quantile(get(v), .1, na.rm = TRUE), q25 = quantile(get(v), .25, na.rm = TRUE),
  med = median(get(v), na.rm = TRUE), mean = mean(get(v), na.rm = TRUE), q75 = quantile(get(v), .75, na.rm = TRUE), q90 = quantile(get(v), .9, na.rm = TRUE)), by = .(set, prog)]))
fwrite(CMP, f_out("p29-s1-program-compare_DATA_2026-09-30.csv")); print(CMP[set == "ns_c"][order(var, prog)], digits = 4)
CAT <- rbindlist(lapply(c("MANAGED", "MANAGED_OLDFLAG", "NSL_SINGLE_REGIME", "TRT_AT_Y1", "CHURN_FLAG", "ESI_SRC", "LINK_SRC"), function(v)
  ST[, .N, by = .(set, prog, value = as.character(get(v)))][, var := v]))
fwrite(CAT, f_out("p29-s1-program-categorical_DATA_2026-09-30.csv")); print(CAT[set == "ns_c"][order(var, prog, value)])
## species mix by program (BA share, ns_c fold A)
SPM <- fread(file.path(FR, "bench_gyr_ns_c_tree_init.csv"))[STAND %in% ST[set == "ns_c", STAND]]
SPM <- SPM[, .(ba = sum(pi / 40000 * DBH^2 * EXPF)), by = .(prog = progof(STAND), SP)][, share := ba / sum(ba), by = prog][order(prog, -share)][share >= 0.01]
fwrite(SPM, f_out("p29-s1-species-mix_DATA_2026-09-30.csv")); print(SPM, digits = 3)
## ESI source agreement: esi8 (engine) against ESI_OLD (old harness) by program and source
ESI <- ST[is.finite(esi8) & is.finite(ESI_OLD), .(stands = .N, esi8 = mean(esi8), esi_old = mean(ESI_OLD), mean_diff = mean(esi8 - ESI_OLD), share_equal = mean(abs(esi8 - ESI_OLD) < 1e-6),
  cor = if (.N > 2) cor(esi8, ESI_OLD) else NA_real_), by = .(set, prog, ESI_SRC)]
fwrite(ESI, f_out("p29-s1-esi-source_DATA_2026-09-30.csv")); print(ESI, digits = 4)
## ---------------- within NS_RS: height increment ratio by stand state quartile ----------------
T <- merge(K, ST[, c("set", "STAND", intersect(vars, names(ST))), with = FALSE], by = c("set", "STAND"))
stopifnot(nrow(T) == nrow(K))
svar <- c("qmd_all", "tph_all", "sdi_all", "ba_all", "qmd9", "tph9", "tph_small", "topht", "esi8", "sw_share", "bf_share", "Y1", "iv")
boot_q <- function(d, v) {   # d: trees of one set and program; quartiles of v at stand level
  sv <- unique(d[, .(STAND, z = get(v))])[is.finite(z)]; br <- unique(quantile(sv$z, c(0, .25, .5, .75, 1)))
  if (length(br) < 3) return(NULL); d <- copy(d)[, q := cut(get(v), br, include.lowest = TRUE, labels = FALSE)][!is.na(q)]
  S <- d[, .(o = sum(dho), f = sum(dhf), p = sum(dhp), n = .N), by = .(sidx, q)]; sites <- unique(S$sidx); nq <- max(S$q)
  pt <- S[, .(ratio = sum(f) / sum(o), ratio141 = sum(p) / sum(o), trees = sum(n), sites = uniqueN(sidx)), by = q][order(q)]
  Mo <- as.matrix(dcast(S, sidx ~ q, value.var = "o", fill = 0)[, -1]); Mf <- as.matrix(dcast(S, sidx ~ q, value.var = "f", fill = 0)[, -1])
  R <- t(replicate(1000, { i <- sample.int(length(sites), length(sites), TRUE); colSums(Mf[i, , drop = FALSE]) / colSums(Mo[i, , drop = FALSE]) }))
  pt[, `:=`(lo = apply(R, 2, quantile, .025), hi = apply(R, 2, quantile, .975), zlo = br[q], zhi = br[q + 1])]
  dd <- R[, nq] - R[, 1]; pt[, `:=`(var = v, q4_minus_q1 = pt$ratio[nq] - pt$ratio[1], d_lo = quantile(dd, .025), d_hi = quantile(dd, .975))]; pt }
WQ <- rbindlist(lapply(SETS, function(s) rbindlist(lapply(c("NS_RS", "NS_OP"), function(g) { d <- T[set == s & prog == g]
  rbindlist(lapply(svar, function(v) { b <- boot_q(d, v); if (is.null(b)) NULL else b[, `:=`(set = s, prog = g)] })) }))))
setcolorder(WQ, c("set", "prog", "var", "q", "zlo", "zhi"))
fwrite(WQ, f_out("p29-s1-within-quartile_DATA_2026-09-30.csv")); print(WQ[set == "ns_c"], digits = 3)
## same within NS_RS on trees at 9.1 cm and over (the size range both programs share)
WQ9 <- rbindlist(lapply(SETS, function(s) { d <- T[set == s & prog == "NS_RS" & D1 >= 9.1]
  rbindlist(lapply(svar, function(v) { b <- boot_q(d, v); if (is.null(b)) NULL else b[, `:=`(set = s, prog = "NS_RS D1>=9.1")] })) }))
fwrite(WQ9, f_out("p29-s1-within-quartile-d91_DATA_2026-09-30.csv"))
## ---------------- overlap and matched comparison, trees >= 9.1 cm ----------------
## coarsened cells on production state at the common 9.1 cm floor (qmd9, tph9, topht, esi8 tertiles pooled over programs)
## and tree size class; the RS minus OP ratio contrast is taken within cells that hold both programs.
cm <- function(s) { d <- T[set == s & D1 >= 9.1 & is.finite(topht) & is.finite(esi8) & is.finite(qmd9)]
  sv <- unique(d[, .(STAND, qmd9, tph9, topht, esi8)])
  for (v in c("qmd9", "tph9", "topht", "esi8")) { br <- quantile(sv[[v]], c(0, 1/3, 2/3, 1)); d[, (paste0(v, "_k")) := cut(get(v), br, include.lowest = TRUE, labels = FALSE)] }
  d[, dk := cut(D1, c(9.1, 12.7, 25, Inf), right = FALSE, labels = FALSE)]
  d[, cell := paste(qmd9_k, tph9_k, topht_k, esi8_k, dk)]
  both <- d[, uniqueN(prog), by = cell][V1 == 2, cell]
  ov <- data.table(set = s, rs_trees = d[prog == "NS_RS", .N], rs_trees_in_shared = d[prog == "NS_RS" & cell %in% both, .N],
    op_trees = d[prog == "NS_OP", .N], op_trees_in_shared = d[prog == "NS_OP" & cell %in% both, .N], cells = uniqueN(d$cell), shared_cells = length(both))
  dm <- d[cell %in% both]
  C <- dm[, .(o = sum(dho), f = sum(dhf), n = .N), by = .(cell, prog, sidx)]
  wt <- dm[prog == "NS_RS", .N, by = cell][, w := N / sum(N)]
  est <- function(C) { a <- C[, .(r = sum(f) / sum(o)), by = .(cell, prog)]; a <- dcast(a, cell ~ prog, value.var = "r"); a <- merge(a, wt, by = "cell")
    c(rs = sum(a$w * a$NS_RS), op = sum(a$w * a$NS_OP)) }
  e0 <- est(C); sites <- unique(C$sidx)
  bb <- t(replicate(1000, { i <- sample(sites, length(sites), TRUE); cc <- data.table(sidx = i)[, .(k = .N), by = sidx]
    Cb <- merge(C, cc, by = "sidx")[, .(o = sum(o * k), f = sum(f * k)), by = .(cell, prog)]
    ok <- Cb[, uniqueN(prog), by = cell][V1 == 2, cell]; Cb <- Cb[cell %in% ok]; a <- dcast(Cb[, .(r = f / o), by = .(cell, prog)], cell ~ prog, value.var = "r")
    a <- merge(a, wt, by = "cell"); a[, w := w / sum(w)]; c(sum(a$w * a$NS_RS), sum(a$w * a$NS_OP)) }))
  ov[, `:=`(rs_matched = e0["rs"], op_matched = e0["op"], rs_lo = quantile(bb[, 1], .025), rs_hi = quantile(bb[, 1], .975),
    op_lo = quantile(bb[, 2], .025), op_hi = quantile(bb[, 2], .975), diff = e0["rs"] - e0["op"], diff_lo = quantile(bb[, 1] - bb[, 2], .025), diff_hi = quantile(bb[, 1] - bb[, 2], .975),
    rs_unmatched_d91 = d[prog == "NS_RS", sum(dhf) / sum(dho)], op_unmatched_d91 = d[prog == "NS_OP", sum(dhf) / sum(dho)])]
  ov }
OV <- rbindlist(lapply(SETS, cm)); fwrite(OV, f_out("p29-s1-matched-overlap_DATA_2026-09-30.csv")); print(OV, digits = 3)
## share of NS_RS fold A stands outside the NS_OP 2.5 to 97.5 percentile range, per variable
OUTR <- rbindlist(lapply(SETS, function(s) rbindlist(lapply(c("qmd_all", "tph_all", "qmd9", "tph9", "sdi9", "topht", "esi8", "sw_share", "Y1"), function(v) {
  op <- ST[set == s & prog == "NS_OP", quantile(get(v), c(.025, .975), na.rm = TRUE)]; rs <- ST[set == s & prog == "NS_RS" & is.finite(get(v)), get(v)]
  data.table(set = s, var = v, op_lo = op[1], op_hi = op[2], rs_below = mean(rs < op[1]), rs_above = mean(rs > op[2]), rs_stands = length(rs)) }))))
fwrite(OUTR, f_out("p29-s1-range-outside_DATA_2026-09-30.csv")); print(OUTR, digits = 3)
## ---------------- step 2(a) fit: PREREG20 form on NS_OP fold A only (ns_c), same method as _p20_fit.R ----------------
m2 <- function(D, b1, b2) exp(-b1 * pmax(0, pmin(D, 25) - 12.7) - b2 * pmax(0, D - 25))
fitset <- function(A, seed) { set.seed(seed)
  S <- A[, .(s11 = sum(dho * dhp), s22 = sum(dhp^2), s00 = sum(dho^2), n = .N), by = .(sidx, D1)]
  sse_w <- function(b1, b2, w) { m <- m2(S$D1, b1, b2); sum(w * (S$s00 - 2 * m * S$s11 + m^2 * S$s22)) }
  fit2 <- function(w) { o <- optim(c(0.03, 0.01), function(p) sse_w(p[1], min(p[2], p[1]), w), method = "L-BFGS-B", lower = c(0, 0), upper = c(0.3, 0.3))
    c(b1 = o$par[1], b2 = min(o$par[2], o$par[1])) }
  w0 <- rep(1, nrow(S)); p2 <- fit2(w0); sites <- unique(S$sidx)
  bs <- rbindlist(lapply(seq_len(1000), function(i) { cnt <- tabulate(match(sample(sites, length(sites), TRUE), sites), length(sites)); w <- cnt[match(S$sidx, sites)]
    q <- fit2(w); data.table(draw = i, b1 = q[1], b2 = q[2]) }))
  list(p = p2, bs = bs, sse = sse_w(p2[1], p2[2], w0), sse0 = sse_w(0, 0, w0), trees = nrow(A), sites = length(sites)) }
## pooled refit reproduces PREREG20 (same data, same seed): harness check for the fit path
A_all <- fread(file.path(KEY, "p20_htkey_ns_c.csv"))[fold == "A"][, `:=`(dho = (H2 - H1) / iv, dhp = (Hp141 - H1) / iv)]
PP <- fread(file.path(P20, "fit/gyr142-p20-fit-params_DATA_2026-09-28.csv"))[form == "two segment"]
fp <- fitset(A_all, 20260928); e_fit <- max(abs(fp$p - c(PP$b1, PP$b2)))
e_bs <- max(abs(c(quantile(fp$bs$b1, c(.025, .975)), quantile(fp$bs$b2, c(.025, .975))) - c(PP$b1_lo, PP$b1_hi, PP$b2_lo, PP$b2_hi)))
cat(sprintf("Pooled refit against PREREG20: point worst %.3g, bootstrap limits worst %.3g\n", e_fit, e_bs))
if (e_fit > 1e-6) stop("REPRO FAIL pooled PREREG20 fit ", e_fit)
fo <- fitset(A_all[!grepl("^NS(_LONG)?__NS_RS_", STAND)], 20260928)
fr <- fitset(A_all[grepl("^NS(_LONG)?__NS_RS_", STAND)], 20260928)   # reported only
FP <- rbindlist(lapply(list(pooled_repro = fp, NS_OP = fo, NS_RS_reported = fr), function(f) data.table(b1 = f$p[1], b2 = f$p[2],
  b1_lo = quantile(f$bs$b1, .025), b1_hi = quantile(f$bs$b1, .975), b2_lo = quantile(f$bs$b2, .025), b2_hi = quantile(f$bs$b2, .975),
  share_b2_eq_b1 = mean(abs(f$bs$b2 - f$bs$b1) < 1e-6), share_b2_eq_0 = mean(f$bs$b2 < 1e-6), sse = f$sse, sse_identity = f$sse0, trees = f$trees, sites = f$sites)), idcol = "fit")
FP[, `:=`(pooled_b1 = PP$b1, pooled_b1_lo = PP$b1_lo, pooled_b1_hi = PP$b1_hi, pooled_b2 = PP$b2, pooled_b2_lo = PP$b2_lo, pooled_b2_hi = PP$b2_hi, fit_repro_worst = e_fit, bs_repro_worst = e_bs)]
fwrite(FP, f_out("p29-s1-nsop-refit-params_DATA_2026-09-30.csv")); fwrite(fo$bs, f_out("p29-s1-nsop-refit-bootstrap_DATA_2026-09-30.csv")); print(FP, digits = 5)
at <- c(12.7, 15, 20, 25, 30, 35, 40, 50)
MM <- data.table(dbh = at, m_pooled = m2(at, PP$b1, PP$b2), m_nsop = m2(at, fo$p[1], fo$p[2]),
  m_nsop_lo = sapply(at, function(d) quantile(m2(d, fo$bs$b1, fo$bs$b2), .025)), m_nsop_hi = sapply(at, function(d) quantile(m2(d, fo$bs$b1, fo$bs$b2), .975)))
fwrite(MM, f_out("p29-s1-nsop-refit-multiplier_DATA_2026-09-30.csv")); print(MM, digits = 4)
## in sample fold A ratios under v141LT, v141LTf (engine), pooled offline and NS_OP refit offline, by program and class
A_all[, `:=`(prog = progof(STAND), cls = cut(D1, c(0, 7.5, 12.7, 25, Inf), right = FALSE, labels = c("below 7.5", "7.5 to 12.7", "12.7 to 25", "25 and over")))]
IS <- A_all[, .(trees = .N, r141 = mean(dhp) / mean(dho), r_pooled = mean(m2(D1, PP$b1, PP$b2) * dhp) / mean(dho), r_nsop = mean(m2(D1, fo$p[1], fo$p[2]) * dhp) / mean(dho)), by = .(prog, cls)][order(prog, cls)]
fwrite(IS, f_out("p29-s1-nsop-refit-insample-foldA_DATA_2026-09-30.csv")); print(IS, digits = 3)
## ---------------- figures ----------------
pd <- ST[set == "ns_c" & tph_all > 0]
g1 <- ggplot(pd, aes(tph_all, qmd_all, colour = prog)) + geom_point(size = 0.6, alpha = 0.5) + scale_x_log10() + scale_y_log10() +
  scale_colour_manual(values = c(NS_OP = "#1b6f8a", NS_RS = "#b5502a"), name = "Program") +
  labs(x = "Trees per ha at t1, all measured trees (log)", y = "QMD at t1, all measured trees (cm, log)") + theme_classic(base_size = 11) + theme(legend.position = "bottom")
ggsave(f_out("p29-s1-state-space_2026-09-30.png"), g1, width = 6, height = 5, dpi = 300)
wq <- WQ[set == "ns_c" & var %in% c("qmd_all", "tph_all", "sdi_all", "topht", "esi8", "sw_share", "Y1", "tph_small")]
g2 <- ggplot(wq, aes(factor(q), ratio, colour = prog)) + geom_hline(yintercept = 1, linetype = 2, colour = "grey50") +
  geom_pointrange(aes(ymin = lo, ymax = hi), position = position_dodge(width = 0.5), size = 0.3) + facet_wrap(~var, nrow = 2) +
  scale_colour_manual(values = c(NS_OP = "#1b6f8a", NS_RS = "#b5502a"), name = "Program") +
  labs(x = "Stand level quartile within program (1 = lowest)", y = "v141LTf predicted over observed height increment") + theme_classic(base_size = 10) + theme(legend.position = "bottom")
ggsave(f_out("p29-s1-within-quartile_2026-09-30.png"), g2, width = 9, height = 5.5, dpi = 300)
cat("P29_STEP1_DONE\n")

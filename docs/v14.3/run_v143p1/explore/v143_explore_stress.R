## v143_explore_stress.R
## EXPLORATORY, NOT REGISTERED. Stress test of the conclusions of the 14.3 pre-registration 1 RESULT (19 October 2026):
## (S1) how robust the HR survivor reading is to weighting, species group, years since thinning, forest type, natural
## disturbance and the Dq definition; (S2) how robust gate F is to the bootstrap seed and to resampling stands instead
## of plots; (S3) the pooled realized share of T's predicted release (one slope over heavy and intermediate stands, the
## rule 4 model without groups), which sizes the follow-up. Reads the frozen 14.1 and the v143p1 A0 outputs, read only;
## writes out/explore/*_DATA.csv (aggregates only). Nothing here changes the registered verdict. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(data.table); library(splines)})
ROOT <- "/users/PUOM0008/crsfaaron/v143p1"; H <- "/users/PUOM0008/crsfaaron"
O <- file.path(ROOT, "out"); E <- file.path(O, "explore"); dir.create(E, FALSE, TRUE)
PHO <- file.path(H, "acdx_20261016/postharv/out"); PHW <- file.path(H, "acdx_20261016/postharv/work")
NB <- 1000L
wout <- function(x, nm) { f <- file.path(E, paste0(nm, "_DATA.csv")); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "lat", "lon"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
rd <- function(dir) rbindlist(lapply(list.files(dir, pattern = "^c[0-9]{3}_results\\.csv$", full.names = TRUE), fread), fill = TRUE)
CL <- fread(file.path(PHW, "mefia_ph_class_DATA_2026-10-16_r1.csv"))[, .(STAND, PLOTKEY, HARVEST_TYPE, NATDSTRB_V2, FT = FORTYPGRP_V0_NAME)]
Q <- fread(file.path(ROOT, "work/elig_quant_v143_SERVERONLY.csv"))[FRAME == "mefia_ph_c", .(STAND = KEY, KNOWN_TST, TSTN, RF, DQR)]
r141 <- rd(file.path(PHO, "v141LT/mefia_ph_c"))[, .(STAND, iv, t1 = BIOMASS_t1, o = BIOMASS_o, p141 = BIOMASS_p, ok1 = RUN_OK)]
rA0 <- rd(file.path(O, "A0/mefia_ph_c"))[, .(STAND, pA0 = BIOMASS_p, ok0 = RUN_OK)]
rL2 <- rd(file.path(PHO, "v141off/mefia_ph_c"))[, .(STAND, pL2 = BIOMASS_p, ok2 = RUN_OK)]
M <- Reduce(function(a, b) merge(a, b, by = "STAND"), list(CL, Q, r141, rA0, rL2))[ok1 == 1 & ok0 == 1 & ok2 == 1]
stopifnot(nrow(M) == 827L)
M[, `:=`(g141 = (p141 - o) / iv, gA0 = (pA0 - o) / iv, D = (p141 - pA0) / iv, Y = (o - pA0) / iv, predA0 = (pA0 - t1) / iv)]
PL <- sort(unique(M$PLOTKEY))
bootw <- function(seed, unit = c("plot", "stand")) { unit <- match.arg(unit); set.seed(seed)
  if (unit == "plot") { W <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(PL), length(PL), TRUE), length(PL)), integer(length(PL))); W[match(M$PLOTKEY, PL), ] }
  else vapply(seq_len(NB), function(b) tabulate(sample.int(nrow(M), nrow(M), TRUE), nrow(M)), integer(nrow(M))) }
ci <- function(v) unname(quantile(v, c(.025, .975), na.rm = TRUE))

ONLY_S1 <- identical(Sys.getenv("ONLY_S1"), "1")
if (!ONLY_S1) {
## ---- S2 gate F robustness
S2 <- rbindlist(lapply(list(list(20261017L, "plot"), list(1L, "plot"), list(2L, "plot"), list(3L, "plot"), list(20261017L, "stand")), function(a) {
  W <- bootw(a[[1]], a[[2]])
  rbindlist(lapply(c("heavy", "intermediate"), function(k) { i <- which(M$HARVEST_TYPE == k)
    lo <- pmin(M$g141, M$gA0); b <- colSums(W[i, ] * lo[i]) / colSums(W[i, ])
    tol <- 0.25 * mean(M$o[i] - M$t1[i]) / mean(M$iv[i])
    data.table(class = k, seed = a[[1]], unit = a[[2]], attainable_min = mean(lo[i]), lo95 = ci(b)[1], hi95 = ci(b)[2],
               tol25 = tol, share_boot_below_tol = mean(b <= tol)) })) }))
wout(S2, "s2_gateF_robustness")

## ---- S3 pooled realized share of T (rule 4 model, no groups), heavy and intermediate, known tst
set.seed(20261017L); Wp <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(PL), length(PL), TRUE), length(PL)), integer(length(PL)))
W0 <- Wp[match(M$PLOTKEY, PL), ]   # the same draws the scorer made (seed 20261017, plots in sorted order)
S3 <- rbindlist(lapply(list(c("heavy"), c("intermediate"), c("heavy", "intermediate"), c("light", "low_volume")), function(ks) {
  i <- which(M$HARVEST_TYPE %in% ks & M$KNOWN_TST %in% TRUE & is.finite(M$RF))
  d <- M[i]; f <- function(w = NULL) unname(coef(lm(Y ~ ns(RF, df = 2) + predA0 + D, data = d, weights = w))["D"])
  b <- vapply(seq_len(NB), function(j) tryCatch(f(W0[i, j]), error = function(e) NA_real_), 0)
  data.table(classes = paste(ks, collapse = "+"), n = length(i), k_pooled = f(), lo95 = ci(b)[1], hi95 = ci(b)[2],
             ratio_sumY_sumD = sum(d$Y) / sum(d$D)) }))
wout(S3, "s3_pooled_T_share")
} else { set.seed(20261017L); Wp <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(PL), length(PL), TRUE), length(PL)), integer(length(PL))) }

## ---- S1 survivor reading robustness
ti <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_init.csv"))
cl <- fread(file.path(PHW, "mefia_ph_class_DATA_2026-10-16_r1.csv"), colClasses = list(character = c("CN_V1", "CN_V2")))[, .(STAND, CN_V1, CN_V2)]
tr <- fread(file.path(H, "fia_data/ME_TREE.csv"), select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "DIA"), colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))[PLT_CN %in% c(cl$CN_V1, cl$CN_V2)]
v1 <- merge(tr[PLT_CN %in% cl$CN_V1 & STATUSCD == 1 & is.finite(DIA) & DIA > 0], cl[, .(PLT_CN = CN_V1, STAND)], by = "PLT_CN")
setorder(v1, STAND, CN); v1[, TREE := seq_len(.N), by = STAND]
v2 <- tr[PLT_CN %in% cl$CN_V2 & STATUSCD == 1 & is.finite(DIA) & DIA > 0 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN, d2 = DIA * 2.54)]
lk <- merge(v1[, .(STAND, TREE, CN)], v2, by.x = "CN", by.y = "PREV_TRE_CN")[, .(STAND, TREE, d2)]
.SPLIT_QUIET <- TRUE; source(file.path(H, "hw_formrisk_split.R"))
AGYR <- c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA","BT","BP","EC","AB","WA","BA","GA","RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC")
SWR <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
mapsp_r <- function(s) { s <- toupper(s); ifelse(s %in% AGYR, s, ifelse(s %in% SWR, "OS", "OH")) }
ti[, SPR := mapsp_r(SP)]
nsub <- vapply(.a9$sp, function(k) { J <- outer(.pform[k, ], .prisk[k, ]); J[J < 0.03] <- 0; if (sum(J) == 0) J <- outer(.pform[k, ], .prisk[k, ]); sum(J > 0) }, 0L)
pmap <- ti[, { hw <- SPR %in% .a9$sp; key <- ifelse(SPR %in% HW_SPP, SPR, "OH"); n <- .N
  hh <- which(hw); ns <- unname(nsub[key[hh]]); st <- n + cumsum(c(0, head(ns, -1)))
  hwt <- if (length(hh)) as.integer(unlist(mapply(function(a, b) a + seq_len(b), st, ns, SIMPLIFY = FALSE))) else integer(0)
  rbind(data.table(tree = which(!hw), TREE = which(!hw)), data.table(tree = hwt, TREE = rep(hh, ns))) }, by = STAND]
x <- merge(ti[, .(STAND, TREE, d1 = DBH, e1 = EXPF, SPR)], lk, by = c("STAND", "TREE"))
dq <- ti[DBH >= 2.54, .(DQE = sqrt(sum(EXPF * DBH^2) / sum(EXPF))), by = STAND]
dq12 <- ti[DBH >= 12.7, .(DQ12 = sqrt(sum(EXPF * DBH^2) / sum(EXPF))), by = STAND]
x <- merge(merge(x, dq, by = "STAND"), dq12, by = "STAND", all.x = TRUE)
for (k in c("141", "A0")) { dir <- if (k == "141") file.path(PHO, "v141LT/mefia_ph_c") else file.path(O, "A0/mefia_ph_c")
  sp0 <- rbindlist(lapply(list.files(dir, pattern = "_t1_split_tree\\.csv$", full.names = TRUE), fread))[, .(STAND, tree, e0 = expf)]
  pt <- rbindlist(lapply(list.files(dir, pattern = "_pred_t2_tree\\.csv$", full.names = TRUE), fread))[ing == 0L, .(STAND, tree, dp = dbh)]
  pt <- merge(merge(pt, sp0, by = c("STAND", "tree")), pmap, by = c("STAND", "tree"))[, .(dp = sum(e0 * dp) / sum(e0)), by = .(STAND, TREE)]
  x <- merge(x, setnames(pt, "dp", paste0("dp_", k)), by = c("STAND", "TREE")) }
x <- merge(x, M[HARVEST_TYPE %in% c("heavy", "intermediate"), .(STAND, PLOTKEY, HARVEST_TYPE, DQR, TSTN, NATDSTRB_V2, FT)], by = "STAND")
x[, `:=`(rel = d1 / DQE, rel12 = d1 / DQ12, HW = SPR %in% .a9$sp, dqg = fifelse(DQR >= 1, "ge1", "lt1"))]
WT <- Wp[match(x$PLOTKEY, PL), ]   # tree rows inherit their plot's resample counts
reading <- function(a, b, thr = 0.10) if (!is.finite(a) || !is.finite(b)) "not readable" else if (abs(a - 1) <= thr && (1 - b) > thr) "HG" else if ((1 - a) > thr && (1 - b) > thr && abs(a - b) <= thr) "HR" else "neither"
variant <- function(nm, keep, w = x$e1, relcol = "rel") {
  idx <- which(keep & is.finite(x[[relcol]]) & x[[relcol]] > 1.15 & !is.na(x$dqg))
  z <- x[idx]; ww <- w[idx]; wb <- WT[idx, , drop = FALSE]
  rr <- function(g) { j <- which(z$dqg == g); io <- ww[j] * (z$d2[j] - z$d1[j]); ip <- ww[j] * (z$dp_141[j] - z$d1[j])
    b <- colSums(wb[j, , drop = FALSE] * io) / colSums(wb[j, , drop = FALSE] * ip); c(sum(io) / sum(ip), ci(b), length(j)) }
  a <- rr("ge1"); b <- rr("lt1")
  data.table(variant = nm, n_ge1 = a[4], ratio_ge1 = a[1], lo_ge1 = a[2], hi_ge1 = a[3], n_lt1 = b[4], ratio_lt1 = b[1], lo_lt1 = b[2], hi_lt1 = b[3],
             reading_010 = reading(a[1], b[1])) }
all <- rep(TRUE, nrow(x))
S1 <- rbind(variant("registered (expf weighted)", all),
  variant("unweighted trees", all, w = rep(1, nrow(x))),
  variant("softwoods only", !x$HW), variant("hardwoods only", x$HW),
  variant("tst 1 to 2 yr", x$TSTN %in% 1:2), variant("tst 3 to 5 yr", x$TSTN %in% 3:5),
  variant("spruce-fir", x$FT == "Spruce_fir"), variant("maple-beech-birch", x$FT == "Maple_beech_birch"),
  variant("no natural disturbance at v2", !(x$NATDSTRB_V2 %in% 1L)),
  variant("heavy only", x$HARVEST_TYPE == "heavy"), variant("intermediate only", x$HARVEST_TYPE == "intermediate"),
  variant("Dq on trees >= 12.7 cm", all, relcol = "rel12"))
wout(S1, "s1_survivor_reading_robustness_r2")
cat("EXPLORE_DONE\n")

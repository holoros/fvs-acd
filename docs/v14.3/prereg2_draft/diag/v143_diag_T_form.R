## v143_diag_T_form.R
## EXPLORATORY, NOT REGISTERED (19 October 2026). The two read-only diagnostics recommended after 14.3 pre-registration 1,
## before any T re-estimation is planned:
##  (a) the CTRN fit set: observed over predicted diameter increment after L and T (14.1 r5 coefficients, offline, exactly
##      as C2 r5 applied them) by relative size class and years since thinning, installation-clustered bootstrap. If 14.1
##      fits CTRN at d / Dq above 1.5, the post-harvest excess is an extrapolation to operational removals; if it
##      overshoots there on CTRN too, the defect is in the fitted form (gamma fixed at 2, GT1).
##  (b) mefia_ph_c survivors in heavy and intermediate stands: observed over 14.1 and over A0 by years since thinning (1 to
##      5) and relative size class, and the implied realized share of T's release, (obs/A0 - 1) / (141/A0 - 1).
## Reads frozen inputs and the v143p1 A0 outputs only; writes out/explore/diag_*_DATA.csv (aggregates only). No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(data.table); library(DBI); library(RSQLite)})
H <- "/users/PUOM0008/crsfaaron"; ROOT <- file.path(H, "v143p1"); E <- file.path(ROOT, "out/explore"); dir.create(E, FALSE, TRUE)
GR <- file.path(H, "magplot/verify/gydbreg20260916"); PD <- file.path(GR, "v1404/phaseD")
PHO <- file.path(H, "acdx_20261016/postharv/out"); PHW <- file.path(H, "acdx_20261016/postharv/work")
NB <- 1000L; set.seed(20261019L)
wout <- function(x, nm) { f <- file.path(E, paste0(nm, "_DATA.csv")); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "location", "lat", "lon"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
ci <- function(v) unname(quantile(v, c(.025, .975), na.rm = TRUE))
RELB <- c(0, 0.6, 0.85, 1.15, 1.5, Inf)
cf <- readRDS(file.path(GR, "v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds"))
CAP <- 2.9848
sstep <- function(d) { u <- pmin(pmax((d - 12.7) / (15 - 12.7), 0), 1); 3 * u^2 - 2 * u^3 }
mL <- function(d) 1 + (cf$lambda - 1) * sstep(d)
mT <- function(tst, rel, cap = Inf) 1 + cf$alpha * exp(-cf$beta * tst) * pmin(rel, cap)^cf$gamma

## ---- (a) CTRN fit set, the frozen C2 r5 record frame
b <- readRDS(file.path(PD, "work", "build_ctrn_c.rds"))
P <- as.data.table(b$POP); P[, Dq1 := sqrt(pmax(BA_t1, 0) / pmax(TPH_t1, 1e-9) * 40000 / pi)]
X <- merge(as.data.table(b$TREE)[column == "v1404L2s0"], P[, .(STAND, S, iv, scored, MANAGED, PLOTKEY, Y1, Dq1)], by = "STAND")[scored == TRUE]
X <- X[is.finite(d1) & d1 >= S & !is.na(e2o) & e2p > 0 & is.finite(Dq1) & Dq1 > 0]
con <- dbConnect(SQLite(), file.path(H, "gydb_ws/data/ALL/ALL_Standardized.sqlite"), flags = SQLITE_RO)
LOC <- merge(as.data.table(dbGetQuery(con, "select PlotID, Location from S_Plots where Dataset=3")),
             as.data.table(dbGetQuery(con, "select PlotID, YR thinYR from S_PlotTreatments where Dataset=3")), by = "PlotID", all.x = TRUE)[
  , .(thinYR = as.numeric(suppressWarnings(min(thinYR, na.rm = TRUE)))), by = Location][is.infinite(thinYR), thinYR := NA]
dbDisconnect(con)
X <- merge(X, LOC[, .(PLOTKEY = Location, thinYR)], by = "PLOTKEY", all.x = TRUE)[, tst := Y1 - thinYR]
X <- X[MANAGED == 1 & !is.na(thinYR) & tst >= 1]                       # role T_post, the T fit records
X[, `:=`(INST = sub("_[0-9]+$", "", PLOTKEY), rel = d1 / Dq1, Do = e2o * (d2o - d1) / iv, Dp = e2o * (d2p - d1) / iv)]
X[, `:=`(DpLT = Dp * mL(d1) * mT(tst, rel), DpLTc = Dp * mL(d1) * mT(tst, rel, CAP), DpL = Dp * mL(d1))]
X[, rcl := cut(rel, RELB, right = FALSE)][, tcl := cut(tst, c(1, 3, 6, 11, Inf), right = FALSE)]
cat(sprintf("CTRN T fit records %d, locations %d, installations %d\n", nrow(X), uniqueN(X$PLOTKEY), uniqueN(X$INST)))
IN <- sort(unique(X$INST)); WI <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(IN), length(IN), TRUE), length(IN)), integer(length(IN)))
cellA <- function(z) { w <- WI[match(z$INST, IN), , drop = FALSE]
  r <- function(p) { b <- colSums(w * z$Do) / colSums(w * z[[p]]); c(sum(z$Do) / sum(z[[p]]), ci(b)) }
  a <- r("DpLTc"); l <- r("DpL"); data.table(n = as.numeric(nrow(z)), inst = as.numeric(uniqueN(z$INST)), obs_over_141 = a[1], lo = a[2], hi = a[3], obs_over_L = l[1], lo_L = l[2], hi_L = l[3]) }
A1 <- X[, cellA(.SD), by = rcl][order(rcl)]
A2 <- X[, cellA(.SD), by = .(tcl, rcl)][order(tcl, rcl)][n >= 30]
wout(A1, "diag_a_ctrn_fitset_by_relsize"); wout(A2, "diag_a_ctrn_fitset_by_tst_relsize")
wout(data.table(stat = c("records", "rel_q50", "rel_q90", "rel_q99", "rel_max", "share_rel_gt_1.5"),
                value = c(nrow(X), quantile(X$rel, c(.5, .9, .99)), max(X$rel), mean(X$rel > 1.5))), "diag_a_ctrn_relsize_support")

## ---- (b) mefia_ph_c survivors by tst and relative size
rd <- function(dir, pat) rbindlist(lapply(list.files(dir, pattern = pat, full.names = TRUE), fread), fill = TRUE)
ti <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_init.csv"))
cl <- fread(file.path(PHW, "mefia_ph_class_DATA_2026-10-16_r1.csv"), colClasses = list(character = c("CN_V1", "CN_V2")))[, .(STAND, PLOTKEY, CN_V1, CN_V2, HARVEST_TYPE, TST)]
tr <- fread(file.path(H, "fia_data/ME_TREE.csv"), select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "DIA"), colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))[PLT_CN %in% c(cl$CN_V1, cl$CN_V2)]
v1 <- merge(tr[PLT_CN %in% cl$CN_V1 & STATUSCD == 1 & is.finite(DIA) & DIA > 0], cl[, .(PLT_CN = CN_V1, STAND)], by = "PLT_CN")
setorder(v1, STAND, CN); v1[, TREE := seq_len(.N), by = STAND]
v2 <- tr[PLT_CN %in% cl$CN_V2 & STATUSCD == 1 & is.finite(DIA) & DIA > 0 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN, d2 = DIA * 2.54)]
lk <- merge(v1[, .(STAND, TREE, CN)], v2, by.x = "CN", by.y = "PREV_TRE_CN")[, .(STAND, TREE, d2)]
.SPLIT_QUIET <- TRUE; source(file.path(H, "hw_formrisk_split.R"))
AGYR <- c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA","BT","BP","EC","AB","WA","BA","GA","RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC")
SWR <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
ti[, SPR := { s <- toupper(SP); ifelse(s %in% AGYR, s, ifelse(s %in% SWR, "OS", "OH")) }]
nsub <- vapply(.a9$sp, function(k) { J <- outer(.pform[k, ], .prisk[k, ]); J[J < 0.03] <- 0; if (sum(J) == 0) J <- outer(.pform[k, ], .prisk[k, ]); sum(J > 0) }, 0L)
pmap <- ti[, { hw <- SPR %in% .a9$sp; key <- ifelse(SPR %in% HW_SPP, SPR, "OH"); n <- .N
  hh <- which(hw); ns <- unname(nsub[key[hh]]); st <- n + cumsum(c(0, head(ns, -1)))
  hwt <- if (length(hh)) as.integer(unlist(mapply(function(a, b) a + seq_len(b), st, ns, SIMPLIFY = FALSE))) else integer(0)
  rbind(data.table(tree = which(!hw), TREE = which(!hw)), data.table(tree = hwt, TREE = rep(hh, ns))) }, by = STAND]
x <- merge(ti[, .(STAND, TREE, d1 = DBH, e1 = EXPF)], lk, by = c("STAND", "TREE"))
x <- merge(x, ti[DBH >= 2.54, .(DQE = sqrt(sum(EXPF * DBH^2) / sum(EXPF))), by = STAND], by = "STAND")
for (k in c("141", "A0")) { dir <- if (k == "141") file.path(PHO, "v141LT/mefia_ph_c") else file.path(ROOT, "out/A0/mefia_ph_c")
  sp0 <- rd(dir, "_t1_split_tree\\.csv$")[, .(STAND, tree, e0 = expf)]
  pt <- rd(dir, "_pred_t2_tree\\.csv$")[ing == 0L, .(STAND, tree, dp = dbh)]
  pt <- merge(merge(pt, sp0, by = c("STAND", "tree")), pmap, by = c("STAND", "tree"))[, .(dp = sum(e0 * dp) / sum(e0)), by = .(STAND, TREE)]
  x <- merge(x, setnames(pt, "dp", paste0("dp_", k)), by = c("STAND", "TREE")) }
x <- merge(x, cl[HARVEST_TYPE %in% c("heavy", "intermediate"), .(STAND, PLOTKEY, TSTN = suppressWarnings(as.integer(TST)))], by = "STAND")[is.finite(TSTN)]
x[, rcl := cut(d1 / DQE, RELB, right = FALSE)]
x[, `:=`(io = e1 * (d2 - d1), i141 = e1 * (dp_141 - d1), iA0 = e1 * (dp_A0 - d1))]
PL <- sort(unique(x$PLOTKEY)); WP <- vapply(seq_len(NB), function(b) tabulate(sample.int(length(PL), length(PL), TRUE), length(PL)), integer(length(PL)))
cellB <- function(z) { w <- WP[match(z$PLOTKEY, PL), , drop = FALSE]
  b141 <- colSums(w * z$io) / colSums(w * z$i141); bA0 <- colSums(w * z$io) / colSums(w * z$iA0)
  bsh <- (colSums(w * z$io) / colSums(w * z$iA0) - 1) / (colSums(w * z$i141) / colSums(w * z$iA0) - 1)
  data.table(n_trees = as.numeric(nrow(z)), obs_over_141 = sum(z$io) / sum(z$i141), lo_141 = ci(b141)[1], hi_141 = ci(b141)[2],
             obs_over_A0 = sum(z$io) / sum(z$iA0), lo_A0 = ci(bA0)[1], hi_A0 = ci(bA0)[2],
             realized_share = (sum(z$io) / sum(z$iA0) - 1) / (sum(z$i141) / sum(z$iA0) - 1), lo_share = ci(bsh)[1], hi_share = ci(bsh)[2]) }
B1 <- x[, cellB(.SD), by = TSTN][order(TSTN)]
B2 <- x[, cellB(.SD), by = .(TSTN, rcl)][order(TSTN, rcl)][n_trees >= 30]
B3 <- x[, cellB(.SD), by = rcl][order(rcl)]
wout(B1, "diag_b_mefia_by_tst"); wout(B2, "diag_b_mefia_by_tst_relsize"); wout(B3, "diag_b_mefia_by_relsize")
cat("DIAG_DONE\n")

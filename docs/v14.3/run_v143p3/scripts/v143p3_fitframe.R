## v143p3_fitframe.R
## 14.3 pre-registration 3 (revision 1, md5 20364c4b, registered 2026-10-28T06:00:59-0400), step 2: the joint fit frame.
## CTRN: the PREREG2 fit frame's CTRN records, read unchanged from ~/v143p2/work/fitframe_SERVERONLY.rds (46,521 asserted).
## mefia_ph_c: the PREREG2 scorer's V1 survivor population (v143p2_score4.R: r1 of the frozen A0 decomposition, fate
## "surv", per frame tree d1 = d1[1], e = sum(e1), v2 diameter from the frame's tree_t2 through TREE2), in the scorer's
## stand population (decomposition POP) with HARVEST_TYPE heavy or intermediate, restricted to stands with a known TST.
## G1 and the engine Dq come from the frozen PREREG1 A0 dumps by PREREG2's engine_base() (copied verbatim from
## v143p2_fitframe.R, with its hardwood split map). mefia_ph_c folds: sorted plot keys, permuted with seed 20261027, fold
## = (position - 1) modulo 10 + 1. RF (removal fraction) joined from PREREG2's source for the R2 report.
## Gate FM: CTRN records 46,521; every mefia_ph_c record maps onto an A0 engine tree (|d1 - D0| <= 1e-9, G1 finite).
## Usage: Rscript v143p3_fitframe.R <root>. Writes work/fitframe3_SERVERONLY.rds and out/frame3_*_DATA.csv. Never overwrites.
## Reads no candidate prediction (none exists). No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
a <- commandArgs(TRUE); ROOT <- if (length(a)) a[1] else "/users/PUOM0008/crsfaaron/v143p3"
H <- "/users/PUOM0008/crsfaaron"
W <- file.path(ROOT, "work"); O <- file.path(ROOT, "out")
P2W <- file.path(H, "v143p2/work"); PHW <- file.path(H, "acdx_20261016/postharv/work"); A0D <- file.path(H, "v143p1/out/A0")
fo <- file.path(W, "fitframe3_SERVERONLY.rds"); if (file.exists(fo)) stop("exists ", fo)
wout <- function(x, nm) { f <- file.path(O, paste0("frame3_", nm, "_DATA.csv")); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "location", "lat", "lon", "inst", "tree", "cn"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
chkmd5 <- function(f, m) { x <- unname(tools::md5sum(f)); if (x != m) stop("md5 ", f, " ", x, " != ", m); cat("md5 ok", basename(f), x, "\n") }
chkmd5(file.path(P2W, "fitframe_SERVERONLY.rds"), "a382ee8e970ff899e84e08127a20d7ce")
chkmd5(file.path(P2W, "decomp_mefia_ph_c_SERVERONLY.rds"), "ab4b52789ce9424e8ea16a6f12f9090e")
RELB <- c(0, 0.6, 0.85, 1.15, 1.5, Inf)

## ---- hardwood form and risk split map and engine_base(): verbatim from v143p2_fitframe.R
.SPLIT_QUIET <- TRUE; source(file.path(H, "hw_formrisk_split.R"))
AGYR <- c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA","BT","BP","EC","AB","WA","BA","GA","RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC")
SWR <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
nsub <- vapply(.a9$sp, function(k) { J <- outer(.pform[k, ], .prisk[k, ]); J[J < 0.03] <- 0; if (sum(J) == 0) J <- outer(.pform[k, ], .prisk[k, ]); sum(J > 0) }, 0L)
splitmap <- function(ti) { ti <- copy(ti); ti[, SPR := { s <- toupper(SP); ifelse(s %in% AGYR, s, ifelse(s %in% SWR, "OS", "OH")) }]
  ti[, { hw <- SPR %in% .a9$sp; key <- ifelse(SPR %in% HW_SPP, SPR, "OH"); n <- .N
    hh <- which(hw); ns <- unname(nsub[key[hh]]); st <- n + cumsum(c(0, head(ns, -1)))
    hwt <- if (length(hh)) as.integer(unlist(mapply(function(a, b) a + seq_len(b), st, ns, SIMPLIFY = FALSE))) else integer(0)
    rbind(data.table(tree = which(!hw), TREE_IDX = which(!hw)), data.table(tree = hwt, TREE_IDX = rep(hh, ns))) }, by = STAND] }
rdA0 <- function(set, pat) rbindlist(lapply(list.files(file.path(A0D, set), pattern = pat, full.names = TRUE), fread), fill = TRUE)
engine_base <- function(set, ti) {
  sp0 <- rdA0(set, "_t1_split_tree\\.csv$")[STAND %in% unique(ti$STAND), .(STAND, tree, d0 = dbh, e0 = expf)]
  y1 <- rdA0(set, "_pred_yr1_tree\\.csv$")[STAND %in% unique(ti$STAND) & ing == 0L, .(STAND, tree, d1y = dbh)]
  dq <- sp0[is.finite(e0) & is.finite(d0) & e0 > 0 & d0 > 0, .(DQ_ENG = sqrt(sum(e0 * d0^2) / sum(e0)),
            DQ_ENG127 = if (any(d0 >= 12.7)) sqrt(sum((e0 * d0^2)[d0 >= 12.7]) / sum(e0[d0 >= 12.7])) else NA_real_), by = STAND]
  pm <- splitmap(ti)
  z <- merge(merge(sp0, y1, by = c("STAND", "tree"), all.x = TRUE), pm, by = c("STAND", "tree"))
  if (nrow(z) != nrow(sp0)) stop(set, ": split records not all mapped to a frame tree")
  g <- z[, .(D0 = d0[1], D0_SPREAD = max(d0) - min(d0),
             G1 = { k <- is.finite(d1y); if (any(k)) sum(e0[k] * (d1y[k] - d0[k])) / sum(e0[k]) else NA_real_ },
             NSUB = .N, NSUB_Y1 = sum(is.finite(d1y)), E0 = sum(e0)), by = .(STAND, TREE_IDX)]
  merge(g, dq, by = "STAND") }

## ---- A. CTRN, unchanged from PREREG2
ff <- readRDS(file.path(P2W, "fitframe_SERVERONLY.rds")); F2 <- as.data.table(ff$FF)
C <- F2[src == "CTRN" & is.finite(G1) & is.finite(DQ_ENG) & DQ_ENG > 0]
if (nrow(C) != 46521L) stop("CTRN records ", nrow(C), " are not the registered 46,521")
C <- C[, .(src = "CTRN", STAND, INST, PLOTKEY, TREE_IDX, iv, tst, d1, y, e, DQ_ENG, DQ_ENG127, G1, HARVEST_TYPE = NA_character_, RF = NA_real_)]

## ---- B. mefia_ph_c survivors (the scorer's V1 population), known tst
D2 <- readRDS(file.path(P2W, "decomp_mefia_ph_c_SERVERONLY.rds"))
POP <- as.data.table(D2$POP); r1 <- as.data.table(D2$r1_A0)
ivs <- as.data.table(D2$DEC$A0$D)[, .(STAND, iv)]
cl <- fread(file.path(PHW, "mefia_ph_class_DATA_2026-10-16_r1.csv"))[, .(STAND, HARVEST_TYPE, TST)]
t2 <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_t2.csv"))
ti <- fread(file.path(PHW, "bench_gyr_mefia_ph_c_tree_init.csv"))
sv <- r1[fate == "surv", .(d1 = d1[1], e = sum(e1), TREE2 = TREE2[1]), by = .(STAND, TREE_IDX)]
sv[t2[, .(STAND, TREE2 = TREE, d2 = DBH)], on = .(STAND, TREE2), d2 := i.d2]
sv <- merge(sv, POP[, .(STAND, PLOTKEY, HARVEST_TYPE)], by = "STAND")
sv <- merge(sv, ivs, by = "STAND")
sv <- merge(sv, cl[, .(STAND, TST)], by = "STAND")
CNT <- list(); cnt <- function(step, x) { CNT[[length(CNT) + 1]] <<- data.table(step = step, records = nrow(x), stands = uniqueN(x$STAND), plots = uniqueN(x$PLOTKEY)) }
cnt("survivors in the scorer population (all classes)", sv)
sv <- sv[HARVEST_TYPE %in% c("heavy", "intermediate")]; cnt("heavy and intermediate stands (the V1 population)", sv)
sv <- sv[TST != "UNKNOWN" & is.finite(suppressWarnings(as.numeric(TST)))]; cnt("known tst", sv)
sv[, tst := as.numeric(TST)]
eb <- engine_base("mefia_ph_c", ti[STAND %in% unique(sv$STAND)])
sv <- merge(sv, eb, by = c("STAND", "TREE_IDX"), all.x = TRUE)
FM <- data.table(set = "mefia_ph_c", records = nrow(sv), unmapped = sv[is.na(D0), .N], G1_nonfinite = sv[!is.finite(G1), .N],
                 d2_missing = sv[!is.finite(d2), .N], d1_vs_engine_d0_maxabs = sv[, max(abs(d1 - D0), na.rm = TRUE)], tst_min = min(sv$tst), tst_max = max(sv$tst))
print(FM)
if (FM$unmapped > 0 || FM$d1_vs_engine_d0_maxabs > 1e-9) stop("mefia_ph_c records do not map onto the A0 engine trees (gate FM)")
sv <- sv[is.finite(G1) & is.finite(d2) & is.finite(DQ_ENG) & DQ_ENG > 0 & e > 0]; cnt("finite G1, d2, Dq, positive weight", sv)
qf <- fread(file.path(H, "v143p1/work/elig_quant_v143_SERVERONLY.csv"))[FRAME == "mefia_ph_c", .(STAND = KEY, RF)]
sv <- merge(sv, qf, by = "STAND", all.x = TRUE)
F <- sv[, .(src = "FIA", STAND, INST = "FIA", PLOTKEY, TREE_IDX, iv = as.integer(round(iv)), tst, d1, y = (d2 - d1) / iv, e, DQ_ENG, DQ_ENG127, G1, HARVEST_TYPE, RF)]
if (any(F$iv < 1)) stop("interval below 1 yr")
PL <- sort(unique(F$PLOTKEY)); set.seed(20261027L); perm <- sample(PL)
FOLD <- data.table(PLOTKEY = perm, fold = (seq_along(perm) - 1L) %% 10L + 1L)
F <- merge(F, FOLD, by = "PLOTKEY"); C[, fold := NA_integer_]
FF <- rbind(C, F, use.names = TRUE)
FF[, r := d1 / DQ_ENG]
SUPP <- FF[, .(records = .N, clusters = fifelse(src[1] == "CTRN", uniqueN(INST), uniqueN(PLOTKEY)), stands = uniqueN(STAND), r_q50 = quantile(r, .5), r_q99 = quantile(r, .99),
               r_max = max(r), share_r_gt_1.5 = mean(r > 1.5), share_r_gt_1.7 = mean(r > 1.7), iv_mean = mean(iv), iv_max = max(iv), tst_min = min(tst), tst_max = max(tst),
               G1_nonpos = sum(G1 <= 0), y_neg = sum(y < 0), weight_total = sum(e)), by = src]
CLS <- FF[, .(records = .N), by = .(src, rcl = as.character(cut(r, RELB, right = FALSE)))][order(src, rcl)]
FOLDS <- FF[src == "FIA", .(records = .N, plots = uniqueN(PLOTKEY)), by = fold][order(fold)]
HT <- FF[src == "FIA", .(records = .N, stands = uniqueN(STAND), rf_known = sum(is.finite(RF))), by = HARVEST_TYPE]
print(SUPP); print(CLS); print(FOLDS); print(HT)
saveRDS(list(FF = FF, created = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")), fo)
cat(sprintf("%s  %s\n", unname(tools::md5sum(fo)), fo))
wout(rbindlist(CNT), "counts"); wout(FM, "map_check"); wout(SUPP, "support"); wout(CLS, "class_records"); wout(FOLDS, "fia_folds"); wout(HT, "fia_harvest_type")
cat("FITFRAME3_DONE\n")

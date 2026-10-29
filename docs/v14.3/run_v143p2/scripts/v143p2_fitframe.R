## v143p2_fitframe.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b), step 2, part A: the fit frame.
## Builds, on the server only, the T fit set (CTRN T_post records exactly as the frozen r5 T frame selects them, plus
## PEF post-thinning records if PEF passes the 80% link test) with everything the fitter needs, and runs the step 2
## checks that need no engine run: the PEF link test, the r5 Dq reconfirmation of the CTRN in-sample ratio above
## d / Dq 1.5, the tst consistency check against the engine TST files, the size floor and Dq definition of 14.1, the
## mefia_l_c check (does it hold observed remeasured survivor increments), and the 500 record H3 sample.
##
## Base increment ("annual step engine increment dump"): for every record, the A0 engine's own first annual step
## increment of that tree, G1 = dbh after step 1 minus dbh at the start, read from the frozen A0 tree dumps of
## PREREG1 (~/v143p1/out/A0/<set>/c*_pred_yr1_tree.csv against c*_t1_split_tree.csv). Hardwood form and risk
## sub-records are mapped to their frame tree with the hw_formrisk_split rule (verbatim from the 19 October
## diagnostic) and averaged with their start-of-step expansion factors. The fitter integrates open loop: G1 (the
## engine's increment at interval-start competition, site and Dq) is held, while tst and the tree's own diameter
## (through r = d / Dq) advance by annual steps. Implementation reading, logged in DEVIATIONS.
## Relative size: r = d / DQ_ENG, with DQ_ENG computed exactly as 14.1 computes Dq in calc_ddbh at step 1 (all records
## of the start-of-step split tree list with expf > 0 and dbh > 0). Gate H3 checks this against an engine trace.
##
## PEF LINK TEST (registered rule; this reading is fixed here before any PEF link count is computed): over pef_c
## intervals whose start visit has a known tst of 1 to 17 yr, the post-thinning live tree records are the live records
## of the interval's end visit (tree_t2); a record links when its GYDB tag (frame TREE, the GYDB Tree tag kept by the
## regional frame builder at the location level) is live at the interval's start visit (tree_init) of the same
## location interval. PEF joins if the linked share is at least 0.80. The forward share (start visit records found
## live at the end visit) and the share restricted to end visit DBH >= 12.7 cm are reported beside it and decide nothing.
## PEF records: trees live at both visits of an interval with start visit tst 1 to 17, d1 at or above the stand's
## SCORE_MINDBH_OBS (the r5 rule's S), weight the end visit expansion factor (r5's E = e2o). tst above 17 excluded and
## counted. PEF is one cluster ("PEF") in every fold and draw.
## Outputs: work/fitframe_SERVERONLY.rds (record level, identifiers), work/h3_sample_SERVERONLY.csv, and aggregates
## out/frame_*_DATA.csv (no identifiers). Never overwrites. No coordinates. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(data.table); library(DBI); library(RSQLite)})
a <- commandArgs(TRUE); ROOT <- if (length(a)) a[1] else "/users/PUOM0008/crsfaaron/v143p2"
H <- "/users/PUOM0008/crsfaaron"
W <- file.path(ROOT, "work"); O <- file.path(ROOT, "out"); dir.create(W, FALSE, TRUE); dir.create(O, FALSE, TRUE)
GR <- file.path(H, "magplot/verify/gydbreg20260916"); PD <- file.path(GR, "v1404/phaseD"); FRM <- file.path(GR, "frames")
A0D <- file.path(H, "v143p1/out/A0"); B141W <- file.path(GR, "v142_20260925/bench141/work")
MS <- file.path(H, "magplot/verify/multisrc")
outs <- c(ff = file.path(W, "fitframe_SERVERONLY.rds"), h3 = file.path(W, "h3_sample_SERVERONLY.csv"))
if (any(file.exists(outs))) stop("refusing to overwrite ", outs[file.exists(outs)][1])
wout <- function(x, nm) { f <- file.path(O, paste0("frame_", nm, "_DATA.csv")); if (file.exists(f)) stop("exists ", f)
  if (any(tolower(names(x)) %in% c("stand", "plotkey", "key", "site", "location", "lat", "lon", "inst", "tree", "cn"))) stop("identifier column in ", nm)
  fwrite(x, f); cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f)) }
cf <- readRDS(file.path(GR, "v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds"))
CAP <- 2.9848; RELB <- c(0, 0.6, 0.85, 1.15, 1.5, Inf)
sstep <- function(d) { u <- pmin(pmax((d - 12.7) / (15 - 12.7), 0), 1); 3 * u^2 - 2 * u^3 }
mL <- function(d) 1 + (cf$lambda - 1) * sstep(d)
mT <- function(tst, rel, cap = Inf) 1 + cf$alpha * exp(-cf$beta * tst) * pmin(rel, cap)^cf$gamma
NB <- 1000L; set.seed(20261027L)
ci <- function(v) unname(quantile(v, c(.025, .975), na.rm = TRUE))

## ---- hardwood form and risk split map (verbatim rule of the 19 October diagnostic)
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
## per frame tree (row index within stand = the engine's tree id before the split): D0, G1, and the stand's engine Dq
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

## ---------------------------------------------------------------- A. CTRN, the frozen r5 T frame
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
XC <- X[MANAGED == 0 & is.na(thinYR)]                 # r5 role L_ctrn_control: the CTRN unthinned records (secondary control)
X <- X[MANAGED == 1 & !is.na(thinYR) & tst >= 1]
cat(sprintf("CTRN T_post records %d, locations %d\n", nrow(X), uniqueN(X$PLOTKEY)))
if (nrow(X) != 46521L) stop("the CTRN T fit set is not the registered 46,521 records")
X[, INST := sub("_[0-9]+$", "", PLOTKEY)]
## r5 Dq reconfirmation (registered: the in-sample 0.775 above 1.5 with the r5 frame's own Dq and weights)
X[, `:=`(rel5 = d1 / Dq1, Do = e2o * (d2o - d1) / iv, Dp = e2o * (d2p - d1) / iv)]
X[, `:=`(DpLTc = Dp * mL(d1) * mT(tst, rel5, CAP), DpL = Dp * mL(d1))]
IN <- sort(unique(X$INST)); WI <- vapply(seq_len(NB), function(i) tabulate(sample.int(length(IN), length(IN), TRUE), length(IN)), integer(length(IN)))
r5c <- X[, { w <- WI[match(INST, IN), , drop = FALSE]; bb <- colSums(w * Do) / colSums(w * DpLTc)
  .(n = as.numeric(.N), obs_over_141 = sum(Do) / sum(DpLTc), lo = ci(bb)[1], hi = ci(bb)[2], obs_over_L = sum(Do) / sum(DpL)) },
  by = .(rcl = cut(rel5, RELB, right = FALSE))][order(rcl)]
print(r5c)
## tst against the engine's TST file for ctrn_c
tf <- fread(file.path(B141W, "v142_bench141_tst_ctrn_c_DATA_2026-09-25.csv"), colClasses = list(character = "TST"))
X[tf, on = "STAND", TST_ENG := suppressWarnings(as.numeric(i.TST))]
tstchk <- data.table(set = "ctrn_c", records = nrow(X), tst_equal = X[TST_ENG == tst, .N], tst_differs = X[is.finite(TST_ENG) & TST_ENG != tst, .N],
                     tst_engine_unknown = X[!is.finite(TST_ENG), .N])
print(tstchk)
if (tstchk$tst_equal != nrow(X)) stop("CTRN fit records whose tst differs from the engine TST file; stop")
## engine base increments
tiC <- fread(file.path(FRM, "bench_gyr_ctrn_c_tree_init.csv"))
tiC <- tiC[STAND %in% unique(c(X$STAND, XC$STAND))]
ebC <- engine_base("ctrn_c", tiC)
tiC[, TREE_IDX := seq_len(.N), by = STAND]
ebC <- merge(ebC, tiC[, .(STAND, TREE_IDX, TREE_TAG = TREE, DBH_FRAME = DBH)], by = c("STAND", "TREE_IDX"))
X <- merge(X, ebC, by.x = c("STAND", "k"), by.y = c("STAND", "TREE_IDX"), all.x = TRUE)
XC <- merge(XC, ebC, by.x = c("STAND", "k"), by.y = c("STAND", "TREE_IDX"), all.x = TRUE)
XC[, INST := sub("_[0-9]+$", "", PLOTKEY)]
cat(sprintf("CTRN unthinned control records %d, unmapped %d\n", nrow(XC), XC[is.na(G1), .N]))
mapchk <- data.table(set = "ctrn_c", records = nrow(X), unmapped = X[is.na(G1), .N], d1_vs_engine_d0_maxabs = X[, max(abs(d1 - D0), na.rm = TRUE)],
                     d1_vs_frame_maxabs = X[, max(abs(d1 - DBH_FRAME), na.rm = TRUE)], tag_equal = X[TREE == TREE_TAG, .N],
                     subrecord_d0_spread_max = X[, max(D0_SPREAD, na.rm = TRUE)])
print(mapchk)
if (mapchk$unmapped > 0 || mapchk$d1_vs_engine_d0_maxabs > 1e-9 || mapchk$tag_equal != nrow(X)) stop("CTRN records do not map one to one onto the A0 engine trees; stop")
FF <- X[, .(src = "CTRN", STAND, INST, PLOTKEY, TREE_IDX = k, sp, iv, tst, d1, d2o, e = e2o, DQ_ENG, DQ_ENG127, Dq_r5 = Dq1, G1,
            y = (d2o - d1) / iv, Do, Dp, E = e2o)]
FC <- XC[is.finite(G1), .(src = "CTRN_CONTROL", STAND, INST, PLOTKEY, TREE_IDX = k, sp, iv, tst = NA_real_, d1, d2o, e = e2o, DQ_ENG, DQ_ENG127,
             Dq_r5 = Dq1, G1, y = (d2o - d1) / iv, Do = e2o * (d2o - d1) / iv, Dp = e2o * (d2p - d1) / iv, E = e2o)]

## ---------------------------------------------------------------- B. PEF, link test and records
prP <- fread(file.path(FRM, "bench_gyr_pef_c_pairs.csv"))
tpP <- fread(file.path(B141W, "v142_bench141_tst_pef_c_DATA_2026-09-25.csv"), colClasses = list(character = "TST"))
prP <- merge(prP, tpP[, .(STAND, TSTN = suppressWarnings(as.numeric(TST)))], by = "STAND")
t1P <- fread(file.path(FRM, "bench_gyr_pef_c_tree_init.csv")); t2P <- fread(file.path(FRM, "bench_gyr_pef_c_tree_t2.csv"))
if (anyDuplicated(t1P[, .(STAND, TREE)]) || anyDuplicated(t2P[, .(STAND, TREE)])) stop("duplicate tag within a pef_c visit")
inS <- prP[is.finite(TSTN) & TSTN >= 1 & TSTN <= 17, STAND]
lk2 <- t2P[STAND %in% inS]; lk2[, lk := paste(STAND, TREE) %chin% t1P[STAND %in% inS, paste(STAND, TREE)]]
fw <- t1P[STAND %in% inS]; fw[, lk := paste(STAND, TREE) %chin% t2P[STAND %in% inS, paste(STAND, TREE)]]
LINK <- data.table(stands = length(inS), end_records = nrow(lk2), end_linked = lk2[lk == TRUE, .N], share_linked = lk2[, mean(lk)],
                   share_linked_dbh_ge_12.7 = lk2[DBH >= 12.7, mean(lk)], start_records = nrow(fw), share_forward = fw[, mean(lk)],
                   threshold = 0.80)
LINK[, PEF_JOINS := share_linked >= threshold]
## the same reading on the CTRN T stands, for reference only
t1C <- fread(file.path(FRM, "bench_gyr_ctrn_c_tree_init.csv")); t2C <- fread(file.path(FRM, "bench_gyr_ctrn_c_tree_t2.csv"))
csT <- unique(X$STAND); l2C <- t2C[STAND %in% csT]; l2C[, lk := paste(STAND, TREE) %chin% t1C[STAND %in% csT, paste(STAND, TREE)]]
LINK[, ctrn_T_stands_share_linked_reference := l2C[, mean(lk)]]
## plausibility of tag links, reported only (species kept, and no diameter loss above 1 cm)
plaus <- function(t1, t2, st) { m <- merge(t1[STAND %in% st, .(STAND, TREE, SP1 = SP, d1 = DBH)], t2[STAND %in% st, .(STAND, TREE, SP2 = SP, d2 = DBH)], by = c("STAND", "TREE"))
  c(linked = nrow(m), same_species = m[, mean(SP1 == SP2)], no_loss_gt_1cm = m[, mean(d2 >= d1 - 1)]) }
pp <- plaus(t1P, t2P, inS); pc <- plaus(t1C, t2C, csT)
LINK[, `:=`(pef_linked_same_species = pp[["same_species"]], pef_linked_no_loss = pp[["no_loss_gt_1cm"]],
            ctrn_linked_same_species = pc[["same_species"]], ctrn_linked_no_loss = pc[["no_loss_gt_1cm"]])]
print(LINK)
## records
PR <- prP[is.finite(TSTN) & TSTN >= 1]
cat(sprintf("pef_c intervals with known tst >= 1: %d, of which tst 1 to 17: %d, above 17: %d\n", nrow(PR), PR[TSTN <= 17, .N], PR[TSTN > 17, .N]))
pt <- fread(file.path(MS, "bench_pef_treatments.csv"))
PR[pt, on = .(OLD_STAND = STAND), TREATMENT := i.TREATMENT]
tiP <- t1P[STAND %in% PR$STAND]; tiP[, TREE_IDX := seq_len(.N), by = STAND]
p1 <- merge(tiP, PR[, .(STAND, PLOTKEY, iv = pmax(1L, as.integer(round(interval_years))), TSTN, S = SCORE_MINDBH_OBS, MANAGED, TREATMENT)], by = "STAND")
p1 <- merge(p1, t2P[, .(STAND, TREE, d2o = DBH, e2o = EXPF)], by = c("STAND", "TREE"))
p1 <- p1[is.finite(DBH) & DBH >= S & is.finite(d2o) & e2o > 0]
excl17 <- p1[TSTN > 17, .(records = .N, intervals = uniqueN(STAND))]
p1 <- p1[TSTN <= 17]
ebP <- engine_base("pef_c", tiP[STAND %in% p1$STAND])
p1 <- merge(p1, ebP, by = c("STAND", "TREE_IDX"), all.x = TRUE)
mapP <- data.table(set = "pef_c", records = nrow(p1), unmapped = p1[is.na(G1), .N], d1_vs_engine_d0_maxabs = p1[, max(abs(DBH - D0), na.rm = TRUE)])
print(mapP)
if (mapP$unmapped > 0 || mapP$d1_vs_engine_d0_maxabs > 1e-9) stop("PEF records do not map onto the A0 engine trees; stop")
cuts <- p1[, .(records = .N, intervals = uniqueN(STAND), share_records = .N / nrow(p1)), by = TREATMENT][order(-records)]
print(cuts)
PFF <- p1[, .(src = "PEF", STAND, INST = "PEF", PLOTKEY, TREE_IDX, sp = SP, iv, tst = TSTN, d1 = DBH, d2o, e = e2o, DQ_ENG, DQ_ENG127, Dq_r5 = NA_real_, G1,
              y = (d2o - DBH) / iv, Do = NA_real_, Dp = NA_real_, E = e2o, TREATMENT, MANAGED)]
pefsum <- data.table(intervals_known_tst = nrow(PR), intervals_tst_1_17 = PR[TSTN <= 17, .N], records_tst_1_17 = nrow(PFF),
                     records_tst_above_17 = excl17$records, intervals_tst_above_17 = excl17$intervals,
                     locations = uniqueN(PFF$PLOTKEY), managed_share = PFF[, mean(MANAGED == 1)], tst_min = min(PFF$tst), tst_max = max(PFF$tst))
print(pefsum)

## ---------------------------------------------------------------- C. fit set and its support
FF[, `:=`(TREATMENT = NA_character_, MANAGED = 1L)]; FC[, `:=`(TREATMENT = NA_character_, MANAGED = 0L)]
FFall <- rbind(FF, PFF, FC, use.names = TRUE)
FFall[, `:=`(r = d1 / DQ_ENG, joins = src == "CTRN" | (src == "PEF" & LINK$PEF_JOINS))]
supp <- FFall[, .(records = .N, clusters = uniqueN(INST), locations = uniqueN(PLOTKEY), r_q50 = quantile(r, .5), r_q99 = quantile(r, .99), r_max = max(r),
                  share_r_gt_1.5 = mean(r > 1.5), share_r_gt_1.7 = mean(r > 1.7), iv_mean = mean(iv), iv_max = max(iv), tst_max = max(tst),
                  G1_nonpos = sum(G1 <= 0), y_neg = sum(y < 0)), by = src]
print(supp)

## ---------------------------------------------------------------- D. 14.1 size floor and Dq (code reading, recorded)
src141 <- readLines(file.path(H, "v14_1_20260923/AcadianGY_14.1.r"))
floor_rec <- data.table(item = c("T applied to every tree record (no size floor)", "Dq over all records with expf > 0 and dbh > 0", "zero growth below 1.3716 m height kept"),
  evidence_line = c(grep("out <- out \\* .acd_v141_mT", src141)[1], grep("st\\$Dq <- if \\(any\\(ok\\)\\)", src141)[1], grep("ifelse\\(ht < 1.3716", src141)[1]))
floor_rec[, holds := is.finite(evidence_line)]
print(floor_rec)

## ---------------------------------------------------------------- E. mefia_l_c check (observed remeasured survivor increments?)
t1L <- fread(file.path(FRM, "bench_gyr_mefia_l_c_tree_init.csv")); t2L <- fread(file.path(FRM, "bench_gyr_mefia_l_c_tree_t2.csv"))
mL1 <- merge(t1L[, .(STAND, TREE, SP1 = SP, d1 = DBH)], t2L[, .(STAND, TREE, SP2 = SP, d2 = DBH)], by = c("STAND", "TREE"))
MLC <- data.table(stands = uniqueN(t1L$STAND), t1_trees = nrow(t1L), t2_trees = nrow(t2L), tag_linked = nrow(mL1),
                  linked_same_species = mL1[SP1 == SP2, .N], linked_d2_ge_d1_minus_1cm = mL1[d2 >= d1 - 1, .N])
MLC[, share_same_species := linked_same_species / tag_linked][, share_plausible := linked_d2_ge_d1_minus_1cm / tag_linked]
## frame tags are not FIA tree identities if the shares above are low; the chained linkage goes through FIADB:
## PLOTKEY = FIA + chain root CN, the visit CN at Y1 and at Y2 from the ME_PLOT chain, live trees (STATUSCD 1, DIA > 0)
## at each visit, survivors = v2 live trees whose PREV_TRE_CN is a v1 live tree. The frame's t1 list must equal the v1
## live list (sorted DBH and ACTUALHT signature, the mefia_ph_c builder's validation) for the link to be usable.
plC <- fread(file.path(H, "fia_data/ME_PLOT.csv"), select = c("CN", "PREV_PLT_CN", "MEASYEAR"), colClasses = list(character = c("CN", "PREV_PLT_CN")))
plC[PREV_PLT_CN %in% c("", "NA"), PREV_PLT_CN := NA_character_]
par <- setNames(plC$PREV_PLT_CN, plC$CN); par[!(par %in% plC$CN)] <- NA_character_
root_of <- function(cn) { r <- cn; for (i in 1:60) { p <- unname(par[r]); mv <- !is.na(p); if (!any(mv)) break; r[mv] <- p[mv] }; r }
plC[, root := root_of(CN)]
prL <- fread(file.path(FRM, "bench_gyr_mefia_l_c_pairs.csv"))[, .(STAND, PLOTKEY, Y1, Y2)]
prL[, root := sub("^FIA", "", PLOTKEY)]
prL <- merge(prL, plC[, .(root, CN1 = CN, Y1 = MEASYEAR)], by = c("root", "Y1"), all.x = TRUE)
prL <- merge(prL, plC[, .(root, CN2 = CN, Y2 = MEASYEAR)], by = c("root", "Y2"), all.x = TRUE)
chainCN <- plC[root %in% prL$root, CN]       # every visit of the chains, so that intermediate visits can be walked
trL <- fread(file.path(H, "fia_data/ME_TREE.csv"), select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "DIA", "ACTUALHT"),
             colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))[PLT_CN %in% chainCN]
trL[PREV_TRE_CN %in% c("", "NA"), PREV_TRE_CN := NA_character_]
tpar <- setNames(trL$PREV_TRE_CN, trL$CN)
lv <- trL[PLT_CN %in% c(prL$CN1, prL$CN2) & STATUSCD == 1 & is.finite(DIA) & DIA > 0]
sg1 <- merge(lv[, .(PLT_CN, s = sprintf("%.2f/%.2f", round(DIA * 2.54, 2), round(fifelse(is.finite(ACTUALHT) & ACTUALHT > 0, ACTUALHT * 0.3048, NA_real_), 2)))],
             prL[, .(PLT_CN = CN1, STAND)], by = "PLT_CN")[, .(sig = paste(sort(s), collapse = ";")), by = STAND]
sgf <- t1L[, .(sigf = paste(sort(sprintf("%.2f/%.2f", DBH, HT)), collapse = ";")), by = STAND]
sgm <- merge(sgf, sg1, by = "STAND", all.x = TRUE)
## chained linkage: walk PREV_TRE_CN up through intermediate visits (at most 10 steps) to a v1 live tree of the stand
v2l <- merge(lv[, .(PLT_CN, CN)], prL[, .(PLT_CN = CN2, STAND, CN1)], by = "PLT_CN")
v1set <- merge(lv[, .(PLT_CN, CN)], prL[, .(PLT_CN = CN1, STAND)], by = "PLT_CN")
cur <- v2l$CN; hit <- rep(NA_character_, length(cur)); nst <- integer(length(cur))
for (i in 1:10) { p <- unname(tpar[cur]); cur <- p; nst <- nst + !is.na(p)
  m <- !is.na(cur) & is.na(hit) & paste(v2l$STAND, cur) %chin% paste(v1set$STAND, v1set$CN); hit[m] <- cur[m]; if (all(is.na(cur) | !is.na(hit))) break }
v2l[, CN1_TREE := hit]
direct <- merge(lv[PLT_CN %in% prL$CN2 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN)], lv[PLT_CN %in% prL$CN1, .(CN)], by.x = "PREV_TRE_CN", by.y = "CN")
MLC[, `:=`(chain_stands_with_both_visits = prL[!is.na(CN1) & !is.na(CN2), .N], chain_t1_signature_equal = sgm[sig == sigf, .N],
           direct_survivors_linked = nrow(direct), chained_survivors_linked = v2l[!is.na(CN1_TREE), .N],
           chained_share_of_t1_trees = v2l[!is.na(CN1_TREE), .N] / nrow(t1L))]
## registered reading fixed here: the frame holds observed remeasured survivor increments if both visits and the t1 list
## are recovered for at least 95% of stands and the chain links at least half of the t1 trees to a v2 survivor
MLC[, holds_observed_survivor_increments := chain_stands_with_both_visits >= 0.95 * stands & chain_t1_signature_equal >= 0.95 * stands &
      chained_share_of_t1_trees >= 0.5]
print(MLC)

## ---------------------------------------------------------------- F. H3 sample: 500 CTRN fit records, seed 20261020
set.seed(20261020L)
h3 <- FFall[src == "CTRN"][sample.int(.N, 500L)][, .(STAND, TREE_IDX, d1, DQ_ENG, r)]

## ---------------------------------------------------------------- write
saveRDS(list(FF = FFall, LINK = LINK, created = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")), outs[["ff"]])
fwrite(h3, outs[["h3"]])
for (f in outs) cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f))
wout(r5c[, .(rcl = as.character(rcl), n, obs_over_141, lo, hi, obs_over_L)], "r5_dq_reconfirm")
wout(tstchk[, .(records, tst_equal, tst_differs, tst_engine_unknown)], "ctrn_tst_check")
wout(rbind(mapchk[, .(set, records, unmapped, d1_vs_engine_d0_maxabs)], mapP, fill = TRUE), "engine_map_check")
wout(LINK, "pef_link_test"); wout(cuts[, .(TREATMENT, records, intervals, share_records)], "pef_cut_type")
wout(pefsum, "pef_summary"); wout(supp, "fitset_support"); wout(floor_rec, "size_floor_14_1"); wout(MLC, "mefia_l_c_check")
cat("FITFRAME_DONE\n")

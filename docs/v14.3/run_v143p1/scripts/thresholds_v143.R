## thresholds_v143.R
## 14.3 pre-registration 1 (registered revision 1, md5 7f3e67c2), TH step. Written 18 October 2026, before any
## 14.3 arm output exists. Computes, in one definition for every frame, the eligibility quantities RF, DQR and
## RD_res (plan section "Eligibility quantities"), the thresholds RF_MAX and RD_MIN over the CTRN threshold
## locations (the locations with a visit before and after their first thinning that are among the 119 of the T
## fit), the support check, the per stand eligibility files for Apv, A1, A2, A3 and every stress variant, and the
## md5 of every file it writes. It reads no projection output of any kind.
##
## Inputs (read only): ALL_Standardized.sqlite (CTRN Dataset 3, PEF Dataset 4), the frozen Phase D build of ctrn_c
## (to reproduce the 119 T fit locations exactly as the frozen C2 r5 fit selected them), the benchmark pairs files
## of ctrn_c, ctrn_fl and pef_c and their bench141 TST files, the mefia_ph_c pairs and r1 class files, ME_TREE.csv,
## the grid pre and post thinning tree lists written by v143_grid_thdump.R, and AcadianGY_13.1.r (for the engine's
## own SDImax functions, which 14.0.4 and 14.1 do not rebind).
## Outputs (new directory only, refusing to overwrite):
##   work/thresholds_v143_DATA.csv                 thresholds, with n of locations and installations
##   work/support_v143_DATA.csv                    support check, aggregates only
##   work/elig_quant_v143_SERVERONLY.csv           per stand quantities and missing reasons (identifiers)
##   work/elig_<arm>_<frame>_SERVERONLY.csv         KEY, ELIG for each arm and variant (identifiers)
##   logs/th_md5.txt                                md5 of every file above
## Usage: Rscript thresholds_v143.R <v143p1 root> [synthetic]
## No coordinates are read. Identifiers stay in *_SERVERONLY files. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages({library(data.table); library(DBI); library(RSQLite)})
a <- commandArgs(TRUE); ROOT <- a[1]; SYN <- length(a) > 1 && a[2] == "synthetic"
stopifnot(dir.exists(ROOT))
W <- file.path(ROOT, "work"); LG <- file.path(ROOT, "logs"); dir.create(W, FALSE, TRUE); dir.create(LG, FALSE, TRUE)
H <- "/users/PUOM0008/crsfaaron"
GR <- file.path(H, "magplot/verify/gydbreg20260916")
DB <- file.path(H, "gydb_ws/data/ALL/ALL_Standardized.sqlite")
FRM <- file.path(GR, "frames"); B141 <- file.path(GR, "v142_20260925/bench141/work")
PH <- file.path(H, "acdx_20261016/postharv/work"); PD <- file.path(GR, "v1404/phaseD")
if (SYN) {   # dry run on synthetic stands: every input is read from <root>/inputs, written by v143_synthetic_inputs.R
  IN <- file.path(ROOT, "inputs"); FRM <- IN; B141 <- IN; PH <- IN; PD <- IN
  DBT <- readRDS(file.path(IN, "db_tables_SYNTHETIC.rds")); ftr <- as.data.table(readRDS(file.path(IN, "fia_tree_SYNTHETIC.rds")))
}

D_FLOOR <- 12.7              # cm, r1 tree link floor and L smoothstep lower bound
MIN_RET <- 4L                # primary minimum retained trees at or above 12.7 cm
MIN_RET_SWEEP <- c(2L, 8L)
FIELD_FLOOR <- 30L           # PREREG45 floor, borrowed for stands
CLASSES <- c("heavy", "intermediate", "light", "low_volume")
ACRES_PER_HA <- 2.4710538147
SDI <- function(d, e) sum((d / 25.4)^1.6 * e)
BA  <- function(d, e) sum(pi * (d / 200)^2 * e)
DQ  <- function(d, e) if (sum(e) > 0) sqrt(sum(e * d^2) / sum(e)) else NA_real_

outs <- c(th = file.path(W, "thresholds_v143_DATA.csv"), sup = file.path(W, "support_v143_DATA.csv"),
          q = file.path(W, "elig_quant_v143_SERVERONLY.csv"))
if (any(file.exists(outs)) || length(list.files(W, "^elig_.*_SERVERONLY\\.csv$")))
  stop("refusing to overwrite TH outputs in ", W)
if (length(list.files(file.path(ROOT, "out"), recursive = TRUE, pattern = "_results\\.csv$|^traj_")))
  stop("arm output already exists under out/; the TH step must precede every arm output")

## ------------------------------------------------------------- engine SDImax (13.1 functions, unrebound)
E131 <- file.path(H, "AcadianGY_13.1.r")
stopifnot(identical(unname(as.character(tools::md5sum(E131))), "5894df6013c701d09e7ba67ba6c2f090"))
suppressMessages(source(E131))
AGY <- c("BF","RS","BS","WS","NS","WP","RP","JP","EH","WC","TA","RM","SM","YB","PB","GB","QA","BT","BP","EC","AB",
         "WA","BA","GA","RO","RN","BC","PR","ST","HH","SB","RB","AS","SW","HW","OH","OS","PC")
SWL <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
mapsp <- function(s) { s <- toupper(s); ifelse(s %in% AGY, s, ifelse(s %in% SWL, "OS", "OH")) }   # runner mapsp
sdimax_engine <- function(sp, dbh, expf, elev) {
  ## the engine's own path: species attributes, plot summary, Weiskittel and Kuehne (2019) SDImax with the site
  ## term off (the runner sets ops$sdimax.site.term FALSE) and no region or forest type multiplier (unset)
  ok <- is.finite(dbh) & dbh > 0 & is.finite(expf) & expf > 0
  if (sum(ok) < 1) return(NA_real_)
  t <- data.frame(plot = 1L, tree = seq_len(sum(ok)), sp = mapsp(sp[ok]), dbh = dbh[ok], expf = expf[ok], stringsAsFactors = FALSE)
  t <- dplyr::left_join(t, sp.attr, by = c("sp" = "species"))
  t$ba <- t$dbh^2 * 0.00007854 * t$expf
  ps <- calc_plot_summary(t)
  sm <- calc_sdi_max(plot.data = ps, tree.data = t, csi = 12, elev = elev, sdimax.csi.term = FALSE)
  as.numeric(sm$sdi.max[1])
}

## ------------------------------------------------------------- one definition of the quantities
## pre: data.table of pre visit trees with d (pre visit cm), e (trees ha-1), fate in retained/removed/died/other,
## e_post for partial removals (grid), sp. Returns RF, DQR, RD_res, counts and the missing reason, for the
## primary rule and for the stress definitions (died counted removed; min retained 2 and 8; net removal).
quant <- function(pre, sdimax, has_pre = TRUE, has_link = TRUE, ba_post_live = NA_real_) {
  z <- list(HAS_PRE = has_pre, HAS_LINK = has_link, SDIMAX = sdimax)
  if (!has_pre || is.null(pre) || !nrow(pre)) {
    return(c(z, list(N_PRE12 = 0L, N_RET12 = 0L, N_REM12 = 0L, N_DIED12 = 0L, N_OTHER12 = 0L, RF = NA_real_, DQR = NA_real_,
      RD_RES = NA_real_, RF_D = NA_real_, DQR_D = NA_real_, RD_RES_D = NA_real_, N_RET12_D = 0L, RF_NET = NA_real_,
      MISSING = "no_pre_visit")))
  }
  p <- pre[d >= D_FLOOR]
  if (!("e_ret" %in% names(p))) p[, e_ret := fifelse(fate == "retained", e, 0)]
  p[, e_rem := fifelse(fate == "removed", e - e_ret, fifelse(fate == "retained", e - e_ret, 0))]
  core <- function(p, died_as_removed) {
    q <- if (died_as_removed) copy(p)[fate == "died", e_rem := e][fate != "other"] else p[!(fate %in% c("died", "other"))]
    ba_all <- BA(q$d, q$e); ba_rem <- BA(q$d, q$e_rem)
    nret <- q[e_ret > 0, .N]
    list(RF = if (ba_all > 0) ba_rem / ba_all else NA_real_,
         DQR = { a <- DQ(q$d, q$e); b <- DQ(q$d[q$e_ret > 0], q$e_ret[q$e_ret > 0]); if (is.finite(a) && is.finite(b) && a > 0) b / a else NA_real_ },
         RD_RES = if (is.finite(sdimax) && sdimax > 0) SDI(q$d[q$e_ret > 0], q$e_ret[q$e_ret > 0]) / sdimax else NA_real_,
         NRET = nret, DQALL = DQ(q$d, q$e))
  }
  c1 <- core(p, FALSE); c2 <- core(p, TRUE)
  ba_pre <- BA(p$d, p$e)
  miss <- if (!has_link) "no_link" else if (!is.finite(c1$DQALL)) "no_dq" else if (!(is.finite(sdimax) && sdimax > 0)) "no_sdimax" else if (c1$NRET < MIN_RET) "few_retained" else ""
  c(z, list(N_PRE12 = nrow(p), N_RET12 = c1$NRET, N_REM12 = p[fate == "removed" | (fate == "retained" & e_ret < e), .N],
    N_DIED12 = p[fate == "died", .N], N_OTHER12 = p[fate == "other", .N], RF = c1$RF, DQR = c1$DQR, RD_RES = c1$RD_RES,
    RF_D = c2$RF, DQR_D = c2$DQR, RD_RES_D = c2$RD_RES, N_RET12_D = c2$NRET,
    RF_NET = if (is.finite(ba_post_live) && ba_pre > 0) 1 - ba_post_live / ba_pre else NA_real_,
    MISSING = miss))
}
qrow <- function(...) as.data.table(quant(...))

## ------------------------------------------------------------- CTRN and PEF tree lists (GYDB, builder rules)
if (!SYN) {
  con <- dbConnect(SQLite(), DB, flags = SQLITE_RO)
  qq <- function(s) as.data.table(dbGetQuery(con, s))
  PLT <- qq("select Dataset, PlotID, Location from S_Plots where Dataset in (3,4)")
  VIS <- qq("select Dataset, VisitID, PlotID, YR, Design from S_Visits where Dataset in (3,4)")
  FRMS <- qq("select Dataset, Design, Frame, Exclude, Area, BAF, MinDBH, MicroPlots from S_Frames where Dataset in (3,4)")
  TRS <- qq("select Dataset, VisitID, Tree, Frame, SpeciesCD, DBH, Status, Membership, Out, BoundaryFactor, NumberTallied from S_Trees where Dataset in (3,4)")
  TRT <- qq("select Dataset, PlotID, YR from S_PlotTreatments where Dataset in (3,4)")
  dbDisconnect(con)
} else { PLT <- as.data.table(DBT$PLT); VIS <- as.data.table(DBT$VIS); FRMS <- as.data.table(DBT$FRMS); TRS <- as.data.table(DBT$TRS); TRT <- as.data.table(DBT$TRT) }
SP2AGY <- c(ABBA="BF", PIRU="RS", PIMA="BS", PIGL="WS", PIAB="NS", PIST="WP", PIRE="RP", PIBA2="JP",
            TSCA="EH", THOC2="WC", LALA="TA", ACRU="RM", ACSA3="SM", BEAL2="YB", BEPA="PB", BEPO="GB",
            POTR5="QA", POGR4="BT", POBA2="BP", PODE3="EC", FAGR="AB", FRAM2="WA", FRNI="BA", FRPE="GA",
            QURU="RO", PRSE2="BC", PRPE2="PR", ACPE="ST", OSVI="HH", BELE="SB", BENI="RB", FRAXI="AS",
            T_B="OH", T_C="OS", T_X="OH")
TRS <- merge(TRS, VIS, by = c("Dataset", "VisitID"))
TRS <- merge(TRS, FRMS, by = c("Dataset", "Design", "Frame"), all.x = TRUE)
TRS[, keep := (Status %in% 1:9) & !is.na(DBH) & !(is.na(Area) | Exclude %in% 1) & !(Out %in% 1 | Membership %in% 5:7)]
TRS[, dead := !is.na(Status) & Status >= 10]
TRS[, EXPF := round(fifelse(is.na(BAF), 10000 / Area, BAF / (DBH^2 * 0.00007853981634)) / MicroPlots * NumberTallied * BoundaryFactor, 4)]
TRS[, SP := unname(SP2AGY[SpeciesCD])][is.na(SP), SP := "OH"]
TRS <- merge(TRS, PLT, by = c("Dataset", "PlotID"))
cat(sprintf("GYDB CTRN and PEF tree rows %d, kept live %d, dead records %d\n", nrow(TRS), TRS[keep == TRUE, .N], TRS[dead == TRUE, .N]))

## per location removal at year R: pre = last visit strictly before R, post = first visit strictly after R, by plot;
## plots lacking either visit are dropped and counted; expansion per ha is averaged over the plots used
## In GYDB each CTRN and PEF PlotID is one remeasurement interval of the location's physical plot (S_Plots.PlotKey
## <Location>_I<y1>_<y2>): a visit year shared by two intervals is stored twice, identically, and tree tags are stable
## across interval records. Visits are therefore taken at the location level, one record per visit year, and trees are
## linked by tag across interval records. A tag duplicated within one visit record stops the run.
loc_quant <- function(ds, loc, R, elev = 200) {
  X <- TRS[Dataset == ds & Location == loc]
  vy <- X[, .(PlotID = min(PlotID)), by = YR]
  ypre <- if (any(vy$YR < R)) max(vy$YR[vy$YR < R]) else NA_real_
  ypost <- if (any(vy$YR > R)) min(vy$YR[vy$YR > R]) else NA_real_
  info <- list(N_PLOTS = uniqueN(X$PlotID), N_PLOTS_USED = 1L, Y_PRE = ypre, Y_POST = ypost,
               LAG_TO_REMOVAL = if (is.finite(ypre)) R - ypre else NA_real_)
  if (!is.finite(ypre) || !is.finite(ypost)) { r <- quant(NULL, NA_real_, has_pre = FALSE); if (is.finite(ypre)) r$MISSING <- "no_link"; return(c(info, r)) }
  pr <- X[YR == ypre & PlotID == vy[YR == ypre, PlotID]][keep == TRUE]
  po <- X[YR == ypost & PlotID == vy[YR == ypost, PlotID]]
  if (anyDuplicated(pr$Tree) || anyDuplicated(po$Tree)) stop("duplicate tree tag within one visit record at ", loc)
  pr[, e := EXPF]
  pr[po, on = .(Tree), `:=`(post_keep = i.keep, post_dead = i.dead)]
  pr[, fate := fifelse(is.na(post_keep), "removed", fifelse(post_dead %in% TRUE, "died", fifelse(post_keep, "retained", "other")))]
  ba_post <- po[keep == TRUE & DBH >= D_FLOOR, BA(DBH, EXPF)]
  sm <- sdimax_engine(pr$SP, pr$DBH, pr$e, elev)
  c(info, quant(pr[, .(d = DBH, e, fate, sp = SP)], sm, has_pre = TRUE, has_link = TRUE, ba_post_live = ba_post))
}

## ------------------------------------------------------------- the 119 T fit locations, frozen C2 r5 rule
b <- readRDS(file.path(PD, "work", "build_ctrn_c.rds"))
P <- as.data.table(b$POP); P[, Dq1 := sqrt(pmax(BA_t1, 0) / pmax(TPH_t1, 1e-9) * 40000 / pi)]
tt <- merge(as.data.table(b$TREE)[column == "v1404L2s0"], P[, .(STAND, SITE, S, iv, scored, MANAGED, PLOTKEY, Y1, Dq1)], by = "STAND")[scored == TRUE]
tt <- tt[is.finite(d1) & d1 >= S & !is.na(e2o) & e2p > 0 & is.finite(Dq1) & Dq1 > 0]
LOC3 <- merge(PLT[Dataset == 3, .(PlotID, Location)], TRT[Dataset == 3, .(PlotID, thinYR = YR)], by = "PlotID", all.x = TRUE)[
  , .(thinYR = as.numeric(suppressWarnings(min(thinYR, na.rm = TRUE)))), by = Location][is.infinite(thinYR), thinYR := NA]
tt <- merge(tt, LOC3[, .(PLOTKEY = Location, thinYR)], by = "PLOTKEY", all.x = TRUE)[, tst := Y1 - thinYR]
TFIT <- unique(tt[MANAGED == 1 & !is.na(thinYR) & tst >= 1, PLOTKEY])
TFIT_INST <- uniqueN(sub("_[0-9]+$", "", TFIT))
cat(sprintf("T fit locations reproduced: %d in %d installations (registered: 119 in 17)\n", length(TFIT), TFIT_INST))
if (!SYN && (length(TFIT) != 119L || TFIT_INST != 17L)) stop("the T fit location set does not reproduce 119 in 17; stop")

## ------------------------------------------------------------- CTRN locations
ctrn_pairs <- rbindlist(lapply(c("ctrn_c", "ctrn_fl"), function(s) fread(file.path(FRM, sprintf("bench_gyr_%s_pairs.csv", s)))[, set := s]), fill = TRUE)
elev_loc <- ctrn_pairs[, .(ELEV = { x <- ELEV[is.finite(ELEV) & ELEV > 0]; if (length(x)) x[1] else 200 }), by = PLOTKEY]
thinned <- LOC3[!is.na(thinYR)]
CL <- rbindlist(lapply(seq_len(nrow(thinned)), function(i) {
  l <- thinned$Location[i]; ev <- elev_loc[PLOTKEY == l, ELEV]; if (!length(ev)) ev <- 200
  r <- loc_quant(3L, l, thinned$thinYR[i], ev)
  as.data.table(c(list(FRAME = "ctrn_loc", KEY = l, INST = sub("_[0-9]+$", "", l), R_YR = thinned$thinYR[i]), r))
}), fill = TRUE)
CL[, PREPOST := is.finite(Y_PRE) & is.finite(Y_POST)]
CL[, IN_TFIT := KEY %in% TFIT]
CL[, THRESH_LOC := PREPOST & IN_TFIT & MISSING == ""]
cat(sprintf("thinned CTRN locations %d; with a visit before and after %d in %d installations; of those in the T fit %d in %d installations; usable threshold locations %d in %d installations\n",
  nrow(CL), CL[PREPOST == TRUE, .N], CL[PREPOST == TRUE, uniqueN(INST)], CL[PREPOST & IN_TFIT, .N], CL[PREPOST & IN_TFIT, uniqueN(INST)],
  CL[THRESH_LOC == TRUE, .N], CL[THRESH_LOC == TRUE, uniqueN(INST)]))
if (!SYN && CL[PREPOST == TRUE, .N] != 30L) stop("the pre and post visit location count does not reproduce the registered 30; stop")
TL <- CL[THRESH_LOC == TRUE]
if (nrow(TL) < 1) stop("no usable threshold location")

## ------------------------------------------------------------- thresholds
thr <- function(x, f, nm, src) data.table(threshold = nm, value = f(x), source = src)
TH <- rbind(
  data.table(threshold = "RF_MAX", value = max(TL$RF), rule = "max RF over threshold locations"),
  data.table(threshold = "RD_MIN", value = min(TL$RD_RES), rule = "min RD_res over threshold locations"),
  data.table(threshold = "RF_MAX_P95", value = unname(quantile(TL$RF, 0.95, type = 7)), rule = "stress: 95th percentile RF"),
  data.table(threshold = "RD_MIN_P05", value = unname(quantile(TL$RD_RES, 0.05, type = 7)), rule = "stress: 5th percentile RD_res"),
  data.table(threshold = "RF_MAX_D", value = max(TL$RF_D), rule = "stress: died counted removed"),
  data.table(threshold = "RD_MIN_D", value = min(TL$RD_RES_D), rule = "stress: died counted removed"),
  data.table(threshold = "DQR_MIN", value = 1, rule = "definitional"))
TH[, `:=`(n_locations = nrow(TL), n_installations = uniqueN(TL$INST))]

## ------------------------------------------------------------- benchmark stands: ctrn_c, ctrn_fl, pef_c
tstf <- function(s) { x <- fread(file.path(B141, sprintf("v142_bench141_tst_%s_DATA_2026-09-25.csv", s)), colClasses = list(character = "TST")); x[, TSTN := suppressWarnings(as.numeric(TST))]; x }
BS <- list()
for (s in c("ctrn_c", "ctrn_fl")) {
  pr <- fread(file.path(FRM, sprintf("bench_gyr_%s_pairs.csv", s))); x <- merge(pr[, .(STAND, PLOTKEY, Y1)], tstf(s)[, .(STAND, TSTN)], by = "STAND")
  stopifnot(nrow(x) == nrow(pr))
  q <- CL[, !c("FRAME", "INST", "PREPOST", "IN_TFIT", "THRESH_LOC")]
  y <- merge(x, q, by.x = "PLOTKEY", by.y = "KEY", all.x = TRUE)
  y[is.na(MISSING), MISSING := "no_pre_visit"]
  ## a known tst refers to the location's first thinning (bench141 rule, verbatim from E6), so its removal year is R_YR
  nbad <- y[is.finite(TSTN) & TSTN >= 1 & (Y1 - TSTN) != R_YR, .N]
  cat(sprintf("[%s] stands whose known tst refers to a removal other than the first thinning: %d\n", s, nbad))
  if (nbad > 0) stop("a CTRN stand's known tst does not point at the first thinning; stop")
  BS[[s]] <- y[, c(list(FRAME = s, KEY = STAND, LOCKEY = PLOTKEY), .SD), .SDcols = setdiff(names(y), c("STAND", "PLOTKEY"))]
}
pr4 <- fread(file.path(FRM, "bench_gyr_pef_c_pairs.csv")); tp <- tstf("pef_c")
x4 <- merge(pr4[, .(STAND, PLOTKEY, Y1, ELEV)], tp[, .(STAND, TSTN)], by = "STAND"); stopifnot(nrow(x4) == nrow(pr4))
x4[, R_YR := Y1 - TSTN]
uq <- unique(x4[is.finite(R_YR), .(PLOTKEY, R_YR, ELEV)], by = c("PLOTKEY", "R_YR"))
PQ <- rbindlist(lapply(seq_len(nrow(uq)), function(i) as.data.table(c(list(PLOTKEY = uq$PLOTKEY[i], R_YR = uq$R_YR[i]),
  loc_quant(4L, uq$PLOTKEY[i], uq$R_YR[i], if (is.finite(uq$ELEV[i]) && uq$ELEV[i] > 0) uq$ELEV[i] else 200)))), fill = TRUE)
y4 <- merge(x4, PQ, by = c("PLOTKEY", "R_YR"), all.x = TRUE); y4[is.na(MISSING), MISSING := "no_pre_visit"]
BS[["pef_c"]] <- y4[, c(list(FRAME = "pef_c", KEY = STAND, LOCKEY = PLOTKEY), .SD), .SDcols = setdiff(names(y4), c("STAND", "PLOTKEY", "ELEV"))]

## ------------------------------------------------------------- mefia_ph_c (FIA v0 to v1, r1 rule)
cl <- fread(file.path(PH, "mefia_ph_class_DATA_2026-10-16_r1.csv"), colClasses = list(character = c("CN_V0", "CN_V1", "CN_V2")))
pph <- fread(file.path(PH, "bench_gyr_mefia_ph_c_pairs.csv"))[, .(STAND, ELEV)]
cl <- merge(cl, pph, by = "STAND")
if (!SYN) {
  ftr <- fread(file.path(H, "fia_data/ME_TREE.csv"), select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "SPCD", "DIA", "TPA_UNADJ", "AGENTCD", "AGENTCD_NERS"),
               colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))
  ftr <- ftr[PLT_CN %in% c(cl$CN_V0, cl$CN_V1)]
}
ftr[PREV_TRE_CN %in% c("", "NA"), PREV_TRE_CN := NA_character_]
SPCD_to_AGY <- c("12"="BF","97"="RS","95"="BS","94"="WS","91"="NS","129"="WP","125"="RP","105"="JP","261"="EH","241"="WC","71"="TA",
 "316"="RM","318"="SM","371"="YB","375"="PB","379"="GB","746"="QA","743"="BT","741"="BP","742"="EC","531"="AB","541"="WA","543"="BA",
 "544"="GA","833"="RO","762"="BC","761"="PR","315"="ST","701"="HH","391"="HH","935"="SB","370"="RB","68"="PC")
map_fia <- function(spcd) { a <- SPCD_to_AGY[as.character(spcd)]; ifelse(!is.na(a), a, ifelse(spcd >= 300, "OH", "OS")) }
v0all <- ftr[PLT_CN %in% cl$CN_V0 & STATUSCD == 1 & is.finite(DIA) & DIA > 0]
v0all[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ > 0, TPA_UNADJ, fifelse(DIA < 5, 74.965, 6.018))]
v0all[, `:=`(d = DIA * 2.54, e = tpa * ACRES_PER_HA, sp = map_fia(SPCD))]
v1 <- ftr[PLT_CN %in% cl$CN_V1]
v1l <- v1[!is.na(PREV_TRE_CN), .(PREV_TRE_CN, st1 = STATUSCD, ag = AGENTCD, agn = AGENTCD_NERS)]
v0all[v1l, on = .(CN = PREV_TRE_CN), `:=`(st1 = i.st1, ag = i.ag, agn = i.agn)]
v0all[, fate := fifelse(is.na(st1), "removed",
               fifelse(st1 == 3L | (st1 == 2L & (ag %in% 80L | agn %in% 80L)), "removed",
               fifelse(st1 == 2L, "died", fifelse(st1 == 1L, "retained", "other"))))]
v1live <- v1[STATUSCD == 1 & is.finite(DIA) & DIA * 2.54 >= D_FLOOR]
v1live[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ > 0, TPA_UNADJ, 6.018)]
MQ <- rbindlist(lapply(seq_len(nrow(cl)), function(i) {
  c0 <- cl$CN_V0[i]; c1 <- cl$CN_V1[i]; pre <- v0all[PLT_CN == c0]
  has_link <- v1[PLT_CN == c1 & !is.na(PREV_TRE_CN), .N] > 0
  bpost <- v1live[PLT_CN == c1, BA(DIA * 2.54, tpa * ACRES_PER_HA)]
  sm <- sdimax_engine(pre$sp, pre$d, pre$e, if (is.finite(cl$ELEV[i]) && cl$ELEV[i] > 0) cl$ELEV[i] else 200)
  as.data.table(c(list(FRAME = "mefia_ph_c", KEY = cl$STAND[i], LOCKEY = cl$PLOTKEY[i], HARVEST_TYPE = cl$HARVEST_TYPE[i],
    TSTN = suppressWarnings(as.numeric(cl$TST[i])), LAG_TO_REMOVAL = cl$HARVEST_YEAR_V1[i] - cl$Y0[i],
    RF_VOL = cl$PCT_REMOVED[i] / 100, RF_NETVOL = cl$PCT_REMOVED_NET[i] / 100, NATDSTRB_V2 = cl$NATDSTRB_V2[i], FORTYPGRP_V0 = cl$FORTYPGRP_V0_NAME[i]),
    quant(pre[, .(d, e, fate, sp)], sm, has_pre = nrow(pre) > 0, has_link = has_link, ba_post_live = bpost)))
}), fill = TRUE)

## ------------------------------------------------------------- grid (driver lists immediately before and after the thinning)
gfs <- sort(list.files(file.path(W, "grid_thdump"), pattern = "^cell[0-9]{2}_SERVERONLY\\.rds$", full.names = TRUE))
GL <- setNames(lapply(gfs, readRDS), sub("_SERVERONLY\\.rds$", "", basename(gfs)))
GQ <- rbindlist(lapply(names(GL), function(k) {
  g <- GL[[k]]; pre <- as.data.table(g$pre); post <- as.data.table(g$post)
  stopifnot(nrow(pre) == nrow(post), all(pre$tree == post$tree))
  x <- data.table(d = pre$dbh, e = pre$expf, e_ret = pmax(post$expf, 0), sp = pre$sp)
  x[, fate := fifelse(e_ret > 0, "retained", "removed")]
  sm <- sdimax_engine(x$sp, x$d, x$e, 200)
  bpost <- BA(post$dbh[post$dbh >= D_FLOOR], post$expf[post$dbh >= D_FLOOR])
  as.data.table(c(list(FRAME = "grid", KEY = k, THIN_AGE = g$thin_age, TSTN = 1, LAG_TO_REMOVAL = 0),
                  quant(x, sm, TRUE, TRUE, ba_post_live = bpost)))
}), fill = TRUE)
if (!SYN && nrow(GQ) != 20L) stop("expected 20 thinned grid cells, found ", nrow(GQ))

## ------------------------------------------------------------- eligibility, arms and variants
Q <- rbindlist(list(CL[, c(list(FRAME = FRAME, KEY = KEY, LOCKEY = KEY), .SD), .SDcols = setdiff(names(CL), c("FRAME", "KEY"))],
                    rbindlist(BS, fill = TRUE), MQ, GQ), fill = TRUE)
gv <- function(nm) TH[threshold == nm, value]
missing_at <- function(nret, base_missing, m) fifelse(base_missing %in% c("no_pre_visit", "no_link", "no_dq", "no_sdimax"), base_missing,
                                                     fifelse(nret < m, "few_retained", ""))
Q[, MISS := MISSING]
Q[, MISS_R2 := missing_at(N_RET12, MISSING, 2L)][, MISS_R8 := missing_at(N_RET12, MISSING, 8L)]
Q[, MISS_D := missing_at(N_RET12_D, MISSING, MIN_RET)]
Q[, KNOWN_TST := is.finite(TSTN) & TSTN >= 1]
## a non-finite volume removal fraction is missing, not threshold ineligible, in the two variants that use it
Q[, MISS_NET := fifelse(FRAME == "mefia_ph_c" & MISS == "" & !is.finite(RF_NETVOL), "no_rf_netvol", MISS)]
Q[, MISS_VOL := fifelse(FRAME == "mefia_ph_c" & MISS == "" & !is.finite(RF_VOL), "no_rf_vol", MISS)]
## less restrictive variant: threshold locations plus pef_c stands with a pre visit and a known tst of 17 yr or less
LR <- rbind(TL[, .(RF, RD_RES)], Q[FRAME == "pef_c" & MISS == "" & KNOWN_TST & TSTN <= 17, .(RF, RD_RES)])
TH <- rbind(TH, data.table(threshold = c("RF_MAX_LR", "RD_MIN_LR"), value = c(max(LR$RF), min(LR$RD_RES)),
  rule = "stress: less restrictive, threshold locations plus pef_c stands with a pre visit and tst 17 yr or less",
  n_locations = nrow(LR), n_installations = NA_integer_))
ARMS <- list(
  Apv      = quote(MISS == ""),
  A1       = quote(MISS == "" & RF <= gv("RF_MAX")),
  A2       = quote(MISS == "" & RD_RES >= gv("RD_MIN")),
  A3       = quote(MISS == "" & DQR >= 1),
  A1_P95   = quote(MISS == "" & RF <= gv("RF_MAX_P95")),
  A2_P05   = quote(MISS == "" & RD_RES >= gv("RD_MIN_P05")),
  A1_LR    = quote(MISS == "" & RF <= gv("RF_MAX_LR")),
  A2_LR    = quote(MISS == "" & RD_RES >= gv("RD_MIN_LR")),
  A3_095   = quote(MISS == "" & DQR >= 0.95),
  A3_105   = quote(MISS == "" & DQR >= 1.05),
  A1_D     = quote(MISS_D == "" & RF_D <= gv("RF_MAX_D")),
  A2_D     = quote(MISS_D == "" & RD_RES_D >= gv("RD_MIN_D")),
  A3_D     = quote(MISS_D == "" & DQR_D >= 1),
  A1_R2    = quote(MISS_R2 == "" & RF <= gv("RF_MAX")),
  A2_R2    = quote(MISS_R2 == "" & RD_RES >= gv("RD_MIN")),
  A3_R2    = quote(MISS_R2 == "" & DQR >= 1),
  A1_R8    = quote(MISS_R8 == "" & RF <= gv("RF_MAX")),
  A2_R8    = quote(MISS_R8 == "" & RD_RES >= gv("RD_MIN")),
  A3_R8    = quote(MISS_R8 == "" & DQR >= 1),
  A1_NET   = quote(MISS_NET == "" & ifelse(FRAME == "mefia_ph_c", RF_NETVOL, RF) <= gv("RF_MAX")),
  A1_035   = quote(MISS == "" & RF <= 0.35),
  A1_065   = quote(MISS == "" & RF <= 0.65),
  A1_VOL   = quote(MISS_VOL == "" & ifelse(FRAME == "mefia_ph_c", RF_VOL, RF) <= gv("RF_MAX")))
## the disturbed-excluded variant uses the primary arms with the 128 stands dropped at scoring, so it needs no file
for (nm in names(ARMS)) {
  ok <- with(Q, eval(ARMS[[nm]])) %in% TRUE
  mcol <- if (grepl("_D$", nm)) "MISS_D" else if (grepl("_R2$", nm)) "MISS_R2" else if (grepl("_R8$", nm)) "MISS_R8" else if (nm == "A1_NET") "MISS_NET" else if (nm == "A1_VOL") "MISS_VOL" else "MISS"
  set(Q, j = paste0("E_", nm), value = as.integer(Q$KNOWN_TST & ok))
  set(Q, j = paste0("TI_", nm), value = as.integer(Q$KNOWN_TST & !ok & Q[[mcol]] == ""))
}
stopifnot(Q[, sum(E_A3)] > 0 || SYN)
## stands without a known tst carry ELIG 0: T is inert there by the 14.1 contract whichever value is written
wr <- c()
for (fr in c("ctrn_c", "ctrn_fl", "pef_c", "mefia_ph_c", "grid")) for (nm in c(names(ARMS), "ALL0")) {
  x <- if (nm == "ALL0") Q[FRAME == fr, .(KEY, ELIG = 0L)] else Q[FRAME == fr, .(KEY, ELIG = get(paste0("E_", nm)))]
  f <- file.path(W, sprintf("elig_%s_%s_SERVERONLY.csv", nm, fr)); if (file.exists(f)) stop("exists ", f)
  fwrite(x, f); wr <- c(wr, f)
}

## ALL0 files (every stand ELIG 0) for gate E0b on every set and for gate E0c on the 200 yr frame
ALLSETS <- c("baxter_c","ctrn_c","ctrn_fl","medev_c","medev_fl","mefia_l_c","memat_c","memat_fl","mnap_c","nb_c","ns_c","ns_fl",
             "ns_long_c","ns_long_fl","pef_c","pef_fl","qc_c","qc_fl","silc_l_c")
for (s in ALLSETS) { f <- file.path(W, sprintf("elig_ALL0_%s_SERVERONLY.csv", s)); if (file.exists(f)) next
  pf <- file.path(FRM, sprintf("bench_gyr_%s_pairs.csv", s)); if (!file.exists(pf)) { if (SYN) next else stop("missing ", pf) }
  fwrite(fread(pf, select = "STAND")[, .(KEY = STAND, ELIG = 0L)], f); wr <- c(wr, f) }
L200 <- if (SYN) file.path(IN, "long200_mefia_l_c_pairs_DATA_2026-10-16.csv") else file.path(H, "acdx_20261016/long200/work/long200_mefia_l_c_pairs_DATA_2026-10-16.csv")
f <- file.path(W, "elig_ALL0_long200_SERVERONLY.csv"); fwrite(fread(L200, select = "STAND")[, .(KEY = STAND, ELIG = 0L)], f); wr <- c(wr, f)
## every threshold location is eligible under A1 and A2 by construction; reported, and checked
TLE <- data.table(thr_loc_n = nrow(TL), thr_loc_elig_A1 = sum(TL$RF <= gv("RF_MAX")), thr_loc_elig_A2 = sum(TL$RD_RES >= gv("RD_MIN")),
                  thr_loc_elig_A3 = sum(TL$DQR >= 1, na.rm = TRUE))
stopifnot(TLE$thr_loc_elig_A1 == nrow(TL), TLE$thr_loc_elig_A2 == nrow(TL))

## ------------------------------------------------------------- support check (aggregates only)
sm5 <- function(v) { v <- v[is.finite(v)]; if (!length(v)) return(rep(NA_real_, 5)); unname(quantile(v, c(0, .25, .5, .75, 1))) }
grp <- rbind(cbind(GROUP = "ctrn_threshold_locations", Q[FRAME == "ctrn_loc" & THRESH_LOC == TRUE]),
             cbind(GROUP = "ctrn_prepost_locations_all30", Q[FRAME == "ctrn_loc" & PREPOST == TRUE]),
             Q[FRAME %in% c("ctrn_c", "ctrn_fl", "pef_c", "grid") & KNOWN_TST][, GROUP := paste0(FRAME, "_known_tst")],
             Q[FRAME == "mefia_ph_c" & KNOWN_TST][, GROUP := paste0("mefia_ph_c_", HARVEST_TYPE)], fill = TRUE)
rng <- list(RF = range(TL$RF), DQR = range(TL$DQR), RD_RES = range(TL$RD_RES))
SUP <- grp[, {
  r <- list(n = .N, n_installations = if (GROUP[1] %like% "^ctrn_") uniqueN(sub("_[0-9]+$", "", LOCKEY)) else NA_integer_,
    miss_no_pre = sum(MISS == "no_pre_visit"), miss_no_link = sum(MISS == "no_link"), miss_no_dq = sum(MISS == "no_dq"),
    miss_few_retained = sum(MISS == "few_retained"), miss_no_sdimax = sum(MISS == "no_sdimax"), n_died_excluded_trees = sum(N_DIED12, na.rm = TRUE),
    n_other_excluded_trees = sum(N_OTHER12, na.rm = TRUE),
    mean_lag_to_removal = mean(LAG_TO_REMOVAL, na.rm = TRUE),
    dqr_0.95_1.05_share = mean(DQR >= 0.95 & DQR <= 1.05, na.rm = TRUE))
  for (v in c("RF", "DQR", "RD_RES")) { s <- sm5(get(v)); names(s) <- paste0(v, c("_min", "_q25", "_med", "_q75", "_max"))
    r <- c(r, as.list(s)); r[[paste0(v, "_outside_ctrn_range")]] <- sum(get(v) < rng[[v]][1] | get(v) > rng[[v]][2], na.rm = TRUE) }
  for (nm in c("Apv", "A1", "A2", "A3")) { r[[paste0("elig_", nm)]] <- sum(get(paste0("E_", nm))); r[[paste0("thrinelig_", nm)]] <- sum(get(paste0("TI_", nm))) }
  r }, by = GROUP]
## the class floor (30 eligible and 30 ineligible) counts every stand of the class that is not eligible, the population
## the P gates compare; the threshold ineligible count (the rule 4 withheld group) is reported beside it
for (nm in c("A1", "A2", "A3")) SUP[, (paste0("informative_", nm)) := get(paste0("elig_", nm)) >= FIELD_FLOOR & (n - get(paste0("elig_", nm))) >= FIELD_FLOOR]
SUP[, intersect_30_with_tfit := Q[FRAME == "ctrn_loc" & PREPOST & IN_TFIT, .N]]
SUP[, intersect_30_with_tfit_inst := Q[FRAME == "ctrn_loc" & PREPOST & IN_TFIT, uniqueN(sub("_[0-9]+$", "", KEY))]]
SUP[, tfit_locations := length(TFIT)]
SUP[, grid_cells_thinned := nrow(GQ)]
SUP <- cbind(SUP, TLE)

bad <- grep("^(lat|lon|long|latitude|longitude|coord|utm|easting|northing|x|y)$", tolower(c(names(Q), names(SUP), names(TH))), value = TRUE)
if (length(bad)) stop("coordinate-like column refused")
fwrite(TH, outs[["th"]]); fwrite(SUP, outs[["sup"]]); fwrite(Q, outs[["q"]])
print(TH); print(SUP[, .(GROUP, n, miss_no_pre, miss_few_retained, RF_med, DQR_med, RD_RES_med, elig_A1, elig_A2, elig_A3, thrinelig_A1, thrinelig_A2, thrinelig_A3)])
allf <- c(outs, wr)
m <- data.table(md5 = unname(as.character(tools::md5sum(allf))), file = sub(paste0(ROOT, "/"), "", allf), written = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"))
mf <- file.path(LG, if (SYN) "th_md5_SYNTHETIC.txt" else "th_md5.txt"); if (file.exists(mf)) stop("exists ", mf)
fwrite(m, mf, sep = " ", col.names = FALSE)
cat(sprintf("%s  %s\n", unname(tools::md5sum(mf)), mf))
cat("TH_DONE\n")

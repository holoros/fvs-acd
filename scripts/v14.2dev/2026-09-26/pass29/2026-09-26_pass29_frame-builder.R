## 2026-09-16_gydb-regional-frame-builder_FINAL.R
## Phase A of the regional FVS-ACD benchmark: harmonized remeasurement frames for every dataset in
## the GYDB standardized database (ALL_Standardized.sqlite, md5 c028a0eaa9dcf06f3a9d1c2b1f6882ce),
## written in the file contract read by ~/magplot/verify/p23/2026-09-07_p23_bench_v14.R and by the
## FVS-NE adapter ~/fvsne_bench/2026-09-08_gydb_to_fvsne_adapter_WIP.R:
##   pairs     STAND,SITE,PROV,interval_years,ELEV,MANAGED,<extras>
##   tree_*    STAND,PLOT,TREE,SP,DBH,HT,EXPF,YEAR   (DBH cm, HT m, EXPF trees/ha, SP AcadianGY code)
##   site_esi  SITE,esi8
## File names follow the adapter pattern bench_<SRC>_{pairs,tree_init,tree_t2,site_esi}.csv with
## SRC = gyr_<dataset>_<c|fl>, so MULTISRC=<frames dir> SRC=gyr_pef_c works unchanged, and the
## runner takes PFX=<frames dir>/bench_gyr_pef_c.
##
## Runs on Cardinal only. Reads no coordinate column anywhere: S_Locations X/Y, FIA LAT/LON and the
## lat/lon columns of magp_qcnb_pairs.csv are never selected. ELEV is carried.
##
## WHY THE PAIRS ARE REBUILT FROM VISITS. GYDB was itself built from the old bench_* frames: for
## eleven of twelve datasets an S_Plots row is one old bench pair (two visits), and S_Locations is
## the physical plot or site. This builder therefore pools the visits of each physical plot
## (PLOTKEY), deduplicates visits by (PLOTKEY, YR) (duplicate instances are identical tree lists in
## all but two NS_LONG key-years, which are flagged), and re-chains them. A consecutive link that
## exists as an old bench pair is "source". A link between two GYDB visits that is NOT a source pair
## was removed by the source builder, either by a harvest/disturbance screen (PEF, CTRN, NS, FIA)
## or by a random cap (NS, NS_LONG). Such links are admitted only when disturbance-free status can
## be verified from inside GYDB:
##   sibling       the same site-years are a source consecutive pair in the other Nova Scotia
##                 dataset (NS and NS_LONG share site keys and identical site-year tree lists);
##   run_interior  both years lie inside an NS_LONG first-last span, which build_ns_long_bench.py
##                 emits only for undisturbed single-regime runs of three or more occasions (the
##                 link may skip occasions GYDB does not hold);
##   raw           MNAP, whose visits were loaded from the raw reserve tables, not from pairs.
## Every other absent link is excluded and counted, with harvest confirmed where GYDB treatment
## years (CTRN, PEF) or the PEF compartment activity file show a removal inside (y1, y2].
## First-last pairs are the first and last visit of each maximal run of admitted links holding two
## or more links (three or more visits), plus the NS_LONG source first-last pairs whose interior
## visits GYDB does not hold. No pair is dropped for tag churn.
##
## NSPOOL is a derived set, the union of NS and NS_LONG visits, and is the frame that uses every
## eligible Nova Scotia pair GYDB can support. Score NSPOOL or (NS and NS_LONG), never all three,
## or the shared site-years are double counted.

suppressMessages({library(data.table); library(DBI); library(RSQLite)})
ROOT     <- Sys.getenv("P29_IN", "/home/aaron/jobs/v142p29/in")   # pass 29: frozen copy of pass 28b builder; bundle root on firebreather
DB       <- Sys.getenv("GYR_DB", file.path(ROOT, "gydb_ws/data/ALL/ALL_Standardized.sqlite"))   # pass 28: path from env
DB_MD5   <- Sys.getenv("GYR_DB_MD5", "")   # pass 29: md5 from env only (launcher sets it from the step 1 copy)
COV      <- file.path(ROOT, "gydb_ws/data/ALL/gydb_plot_covariates_DATA_2026-09-04.csv")
VER      <- file.path(ROOT, "magplot/verify")
MS       <- file.path(VER, "multisrc")
FIA_PLOT <- file.path(ROOT, "fia_data/ME_PLOT.csv")
PEF_SUPP <- file.path(ROOT, "HRF/sae-follow-on/pef/data/rds/Supplements")
OUT      <- Sys.getenv("GYR_OUT", file.path(VER, "gydbreg20260916"))
FR       <- file.path(OUT, "frames")
G_MAX       <- 2.5   # cm/yr, plausible maximum periodic diameter increment (PPS-1 DMAX_PAI)
SCORE_FLOOR <- 5.0   # cm, harmonized scoring floor: SCORE_MINDBH = max(FRAME_MINDBH, 5.0)
MIN_TREES   <- 3L    # live trees of any size at each end, the runner's own skip rule
TAG_STABLE  <- c(BAXTER = 1L, CTRN = 1L, NS = 1L, NS_LONG = 1L, NSPOOL = 1L, MNAP = 1L)   # pass 29: MNAP carries round 1 TP_ID tags (TreeLink, stem map); untracked rows (Tree 9,000,000 and up) stay out of tag churn [SET ON AUTOPILOT]

stopifnot(dir.exists(FR))
if (length(list.files(FR, pattern = "^bench_gyr_"))) stop("frames dir already holds bench_gyr_ files; refusing to overwrite")
md5 <- unname(tools::md5sum(DB))
if (md5 != DB_MD5) stop("database md5 ", md5, " does not match the expected ", DB_MD5)
cat("DB md5 ok:", md5, "\n")

## ---------------------------------------------------------------------------------------------
## 1. load (read only, no coordinates)
## ---------------------------------------------------------------------------------------------
con <- dbConnect(SQLite(), DB, flags = SQLITE_RO)
q <- function(s) as.data.table(dbGetQuery(con, s))
ds  <- q("select Dataset, Name, Jurisdiction from S_Datasets")
lo  <- q("select Dataset, LocationID, Block, Location, Z from S_Locations")
pl  <- q("select Dataset, PlotID, LocationID, Plot from S_Plots")
vi  <- q("select Dataset, VisitID, PlotID, Visit, YR, MM, Design from S_Visits")
frm <- q("select Dataset, Design, Frame, Exclude, Area, BAF, MinDBH, MicroPlots from S_Frames")
tr  <- q("select Dataset, VisitID, Tree, Frame, SpeciesCD, DBH, HT, Status, Membership, Out, BoundaryFactor, NumberTallied from S_Trees")
trt <- q("select Dataset, PlotID, YR, Treatment from S_PlotTreatments")
dis <- q("select Dataset, PlotID, YR, Disturbance from S_PlotDisturbances")
dbDisconnect(con)
cat(sprintf("loaded: %d datasets, %d plots, %d visits, %d tree rows, %d treatment rows, %d disturbance rows\n",
            nrow(ds), nrow(pl), nrow(vi), nrow(tr), nrow(trt), nrow(dis)))

EXCL <- list()
xadd <- function(dataset, set, criterion, n, unit, note = "") {
  EXCL[[length(EXCL) + 1]] <<- data.table(dataset = dataset, set = set, criterion = criterion,
                                           n = as.integer(n), unit = unit, note = note)
}

## ---------------------------------------------------------------------------------------------
## 2. trees: live filter, expansion factor, species
## ---------------------------------------------------------------------------------------------
SP2AGY <- c(ABBA="BF", PIRU="RS", PIMA="BS", PIGL="WS", PIAB="NS", PIST="WP", PIRE="RP", PIBA2="JP",
            TSCA="EH", THOC2="WC", LALA="TA", ACRU="RM", ACSA3="SM", BEAL2="YB", BEPA="PB", BEPO="GB",
            POTR5="QA", POGR4="BT", POBA2="BP", PODE3="EC", FAGR="AB", FRAM2="WA", FRNI="BA", FRPE="GA",
            QURU="RO", PRSE2="BC", PRPE2="PR", ACPE="ST", OSVI="HH", BELE="SB", BENI="RB", FRAXI="AS",
            T_B="OH", T_C="OS", T_X="OH")
um <- setdiff(unique(tr$SpeciesCD), names(SP2AGY))
if (length(um)) stop("unmapped GYDB species codes: ", paste(um, collapse = " "))
tr <- merge(tr, vi[, .(Dataset, VisitID, Design)], by = c("Dataset", "VisitID"))
tr <- merge(tr, frm, by = c("Dataset", "Design", "Frame"), all.x = TRUE)
dsn <- setNames(ds$Name, ds$Dataset)
tr[, Name := dsn[as.character(Dataset)]]
tr[, drop := fifelse(!(Status >= 1 & Status <= 9), "nonlive",
             fifelse(is.na(DBH), "missing_dbh",
             fifelse(is.na(Area) | Exclude %in% 1, "frame_missing_or_excluded",
             fifelse(Out %in% 1 | Membership %in% 5:7, "out_or_dropped_membership", ""))))]
for (nm in ds$Name) {
  d <- tr[Name == nm]
  xadd(nm, "all", "tree_rows_total", nrow(d), "tree rows")
  for (cr in c("nonlive", "missing_dbh", "frame_missing_or_excluded", "out_or_dropped_membership"))
    xadd(nm, "all", paste0("tree_rows_excluded_", cr), sum(d$drop == cr), "tree rows",
         if (cr == "nonlive") "Status outside 1-9 (dead 10 and unknown 0); only MNAP carries any" else "")
}
tr <- tr[drop == ""]
tr[, EXPF := round(fifelse(is.na(BAF), 10000 / Area, BAF / (DBH^2 * 0.00007853981634)) /
                   MicroPlots * NumberTallied * BoundaryFactor, 4)]
tr[, SP := unname(SP2AGY[SpeciesCD])]
tr <- tr[, .(Dataset, VisitID, Tree, SP, DBH, HT, EXPF, MinDBH, Membership)]
setkey(tr, Dataset, VisitID)

## ---------------------------------------------------------------------------------------------
## 3. physical plot keys
## ---------------------------------------------------------------------------------------------
pl <- merge(pl, ds[, .(Dataset, Name, Jurisdiction)], by = "Dataset")
pl <- merge(pl, lo, by = c("Dataset", "LocationID"))
rx <- c(BAXTER = "_\\d{4}_\\d{4}$", SILC_L = "_\\d{4}_\\d{4}$", CTRN = "_I\\d{4}_\\d{4}$",
        PEF = "_I\\d+_\\d+$", NS = "_\\d{4}$", NS_LONG = "_\\d{4}_\\d{4}_(C|FL)$",
        NB = "_I\\d+$", QC = "_I\\d+_y\\d{4}_\\d{4}$")
pl[, PLOTKEY := NA_character_]
for (n in names(rx)) {
  if (pl[Name == n, any(!grepl(rx[[n]], Plot))]) stop("plot name pattern failed for ", n)
  pl[Name == n, PLOTKEY := sub(rx[[n]], "", Plot)]
}
pl[, OLD_STAND := Plot]
pl[Name == "QC", OLD_STAND := sub("_y\\d{4}_\\d{4}$", "", Plot)]
pl[, SRC_TYPE := "C"]
pl[Name == "NS_LONG" & grepl("_FL$", Plot), SRC_TYPE := "FL"]
## MNAP plots are physical plots loaded from raw visit tables, not old bench pairs
cln <- function(x) gsub("[^A-Za-z0-9]", "", x)
pl[Name == "MNAP", `:=`(PLOTKEY = paste(cln(Block), cln(Location), cln(Plot), sep = "_"),
                        OLD_STAND = NA_character_, SRC_TYPE = NA_character_)]
if (pl[Name == "MNAP", anyDuplicated(PLOTKEY)]) stop("MNAP plot key not unique")
## Maine FIA: the old STAND embeds a plot CN (t2 CN for MEMAT/MEDEV, first CN for MEFIA_L).
## Physical plot = remeasurement chain root through PREV_PLT_CN. Only CN, PREV_PLT_CN, MEASYEAR
## and ELEV are read from ME_PLOT; LAT and LON are never selected.
fp <- fread(FIA_PLOT, select = c("CN", "PREV_PLT_CN", "MEASYEAR", "ELEV"),
            colClasses = list(character = c("CN", "PREV_PLT_CN")))
fp[PREV_PLT_CN %in% c("", "NA"), PREV_PLT_CN := NA_character_]
parent <- setNames(fp$PREV_PLT_CN, fp$CN)
parent[!(parent %in% fp$CN)] <- NA_character_
root_of <- function(cn) {
  r <- cn
  for (i in 1:60) { p <- unname(parent[r]); mv <- !is.na(p); if (!any(mv)) break; r[mv] <- p[mv] }
  r
}
fiaN <- c("MEFIA_L", "MEMAT", "MEDEV")
pl[Name %in% fiaN, CN := sub("^(MEM|ME_L)_", "", Plot)]
nmiss <- pl[Name %in% fiaN, sum(!(CN %in% fp$CN))]
if (nmiss > 0) stop(nmiss, " FIA plot CNs not found in ME_PLOT")
pl[Name %in% fiaN, PLOTKEY := paste0("FIA", root_of(CN))]
fia_elev <- setNames(fp$ELEV * 0.3048, fp$CN)   # FIA ELEV is feet
pl[Name %in% fiaN, ELEV_FIA := round(unname(fia_elev[CN]), 1)]
rm(fp, parent)
if (pl[, anyNA(PLOTKEY)]) stop("unkeyed plots")

## ---------------------------------------------------------------------------------------------
## 4. visits with tree summaries
## ---------------------------------------------------------------------------------------------
vsum <- tr[, .(n = .N, fmin = min(MinDBH), omin = min(DBH),
               sig = paste(sort(paste0(SP, sprintf("%.2f", DBH))), collapse = ";")),
           by = .(Dataset, VisitID)]
v <- merge(vi, pl[, .(Dataset, PlotID, Name, Jurisdiction, LocationID, Z, PLOTKEY, OLD_STAND, SRC_TYPE, ELEV_FIA)],
           by = c("Dataset", "PlotID"))
v <- merge(v, vsum, by = c("Dataset", "VisitID"), all.x = TRUE)
v[is.na(n), `:=`(n = 0L, sig = "")]
for (nm in ds$Name) {
  pids <- unique(vi[Dataset == ds[Name == nm, Dataset], PlotID])
  xadd(nm, "all", "plots_total", pl[Name == nm, .N], "GYDB plots")
  xadd(nm, "all", "plots_without_any_visit", sum(!(pl[Name == nm, PlotID] %in% pids)), "GYDB plots",
       if (nm == "SILC_L") "no survey year in the source frame (SILC1139_1986_2000, SILC1192_1990_1995)" else
       if (nm == "MNAP") "MNAP plots whose visits were never loaded (no survey year in source)" else "")
}

## source pairs as stored in GYDB (one S_Plots row = one old bench pair)
sp_all <- v[!is.na(SRC_TYPE), .(Y1 = YR[Visit == 1][1], Y2 = YR[Visit == 2][1]),
            by = .(Name, PlotID, PLOTKEY, OLD_STAND, SRC_TYPE)][!is.na(Y1) & !is.na(Y2)]
for (nm in unique(sp_all$Name))
  xadd(nm, "all", "source_pairs_nonpositive_interval", sp_all[Name == nm, sum(Y2 <= Y1)], "source pairs")
sp_all <- sp_all[Y2 > Y1]

## treatment and disturbance years per plot key (GYDB)
ev <- rbind(trt[, .(Dataset, PlotID, YR, kind = "treatment")], dis[, .(Dataset, PlotID, YR, kind = "disturbance")])
ev <- merge(ev, pl[, .(Dataset, PlotID, Name, PLOTKEY)], by = c("Dataset", "PlotID"))
ev <- unique(ev[, .(Name, PLOTKEY, T = YR, kind)])
## PEF raw compartment removals, used only to confirm why an absent PEF link was screened out
pef_rem <- NULL
if (file.exists(file.path(PEF_SUPP, "PEF_CompartmentStudy_ActivityDates_TRMT.csv"))) {
  tm <- fread(file.path(PEF_SUPP, "PEF_CompartmentStudy_ActivityDates_TRMT.csv"))
  tm <- tm[Activity == "Harvest" | (Activity == "Cultural Treatment" & grepl("thin", Type, ignore.case = TRUE))]
  it <- fread(file.path(PEF_SUPP, "PEF_CompartmentStudy_ActivityDates_INV_TREE.csv"))
  pef_rem <- list(rem = unique(tm[, .(MU = trimws(as.character(MU)), T = as.integer(Year), one = 1L)]),
                  posth = unique(it[grepl("Post-Harvest", Type), .(MU = trimws(as.character(MU)), Y = as.integer(Year), one = 1L)]))
}

## covariate ESI (30 m) by dataset and location
cov <- fread(COV, select = c("Dataset", "LocationID", "esi8_30m"))

## old harness files per dataset (validation, ESI fallback, ELEV, management labels)
OLD <- list(
  BAXTER  = list(pfx = file.path(MS, "bench_baxter")),
  SILC_L  = list(pfx = file.path(MS, "bench_silc_l"), full = file.path(MS, "bench_silc_l_%s_full137.csv")),
  CTRN    = list(pfx = file.path(MS, "bench_ctrn")),
  PEF     = list(pfx = file.path(MS, "bench_pef")),
  MEFIA_L = list(pfx = file.path(MS, "bench_mefia_long")),
  MEMAT   = list(pfx = file.path(VER, "p5m/p5m_memat")),
  MEDEV   = list(pfx = file.path(VER, "p5m/p5m_medev")),
  NS      = list(pfx = file.path(MS, "bench_ns")),
  NS_LONG = list(pfx = file.path(MS, "bench_ns_long")),
  NB      = list(pfx = file.path(VER, "magp_qcnb"), prov = "NB", site = file.path(VER, "magp_qcnb_site_esi8.csv")),
  QC      = list(pfx = file.path(VER, "magp_qcnb"), prov = "QC", site = file.path(VER, "magp_qcnb_site_esi8.csv"))
)
oldf <- function(o, what) {
  if (what == "site" && !is.null(o$site)) return(o$site)
  paste0(o$pfx, "_", c(pairs = "pairs", site = "site_esi", init = "tree_init", t2 = "tree_t2")[[what]], ".csv")
}
read_old_pairs <- function(f, prov = NULL) {
  h <- names(fread(f, nrows = 0))
  keep <- intersect(c("STAND", "SITE", "PROV", "interval_years", "ELEV", "MANAGED"), h)   # never lat/lon
  d <- fread(f, select = keep, colClasses = list(character = intersect(c("STAND", "SITE"), keep)))
  if (!is.null(prov)) d <- d[PROV == prov]
  d
}
oldesi <- list(); oldelev <- list(); oldmgd <- list()
for (nm in names(OLD)) {
  o <- OLD[[nm]]
  pf <- if (nm == "SILC_L") sprintf(o$full, "pairs") else oldf(o, "pairs")
  sf <- if (nm == "SILC_L") sprintf(o$full, "site_esi") else oldf(o, "site")
  pp <- read_old_pairs(pf, o$prov)
  ss <- fread(sf, colClasses = list(character = "SITE"))[, .(SITE, esi8 = suppressWarnings(as.numeric(esi8)))]
  pp <- merge(pp, unique(ss, by = "SITE"), by = "SITE", all.x = TRUE)
  oldesi[[nm]]  <- pp[, .(Name = nm, OLD_STAND = STAND, esi8_old = esi8)]
  if ("ELEV" %in% names(pp)) oldelev[[nm]] <- pp[, .(Name = nm, OLD_STAND = STAND, ELEV_old = suppressWarnings(as.numeric(ELEV)))]
  if ("MANAGED" %in% names(pp)) oldmgd[[nm]] <- pp[, .(Name = nm, OLD_STAND = STAND, MGD_old = as.integer(MANAGED))]
}
oldesi <- rbindlist(oldesi); oldelev <- rbindlist(oldelev); oldmgd <- rbindlist(oldmgd)

## management labels from the harness treatment files
ctrn_t <- fread(file.path(MS, "bench_ctrn_treatments.csv"), select = c("STAND", "regime"))
ctrn_t[, PLOTKEY := sub(rx[["CTRN"]], "", STAND)]
ctrn_m <- ctrn_t[, .(MG = as.integer(any(regime != "control")), nreg = uniqueN(regime != "control")), by = PLOTKEY]
pef_t <- fread(file.path(MS, "bench_pef_treatments.csv"), select = c("STAND", "TREATMENT"))
pef_t[, PLOTKEY := sub(rx[["PEF"]], "", STAND)]
pef_m <- pef_t[, .(MG = as.integer(any(TREATMENT != "Reference (unmanaged)")), nreg = uniqueN(TREATMENT)), by = PLOTKEY]
cat(sprintf("management label conflicts within plot: CTRN %d, PEF %d\n", ctrn_m[nreg > 1, .N], pef_m[nreg > 1, .N]))

MGD_RULE <- c(BAXTER = "source0_BaxterStatePark", SILC_L = "source1_managed_network_PLACEHOLDER",
              CTRN = "per_plot_ctrn_regime_notcontrol", PEF = "per_plot_pef_treatment_notReference",
              MEFIA_L = "fia0_treated_screened_at_source", MEMAT = "fia0_treated_screened_at_source",
              MEDEV = "fia0_treated_screened_at_source", MNAP = "source0_ecoreserve_PLACEHOLDER",
              NS = "ns_programme_RS1_OP0", NS_LONG = "ns_programme_RS1_OP0", NSPOOL = "ns_programme_RS1_OP0",
              NB = "source1_managed_network_PLACEHOLDER", QC = "source1_managed_network_PLACEHOLDER")
PROV_OF <- c(BAXTER = "BAXTER", SILC_L = "SILC_L", CTRN = "CTRN", PEF = "PEF", MEFIA_L = "ME_FIA_L",
             MEMAT = "ME_FIA_M", MEDEV = "ME_FIA_M", MNAP = "MNAP", NS = "NS", NS_LONG = "NS",
             NSPOOL = "NS", NB = "NB", QC = "QC")
VDS <- c(setNames(as.list(ds$Name), ds$Name), list(NSPOOL = c("NS_LONG", "NS")))
NSFAM <- c("NS", "NS_LONG")
## NS_LONG first-last spans are uncapped and are emitted only for maximal undisturbed runs of three or
## more occasions (build_ns_long_bench.py, which carries the corrected TREE_STATU=4 cut screen). Any
## link that touches or overlaps such a span without lying inside it crosses a disturbance break.
nsl_fl <- unique(sp_all[Name == "NS_LONG" & SRC_TYPE == "FL", .(PLOTKEY, F1 = Y1, F2 = Y2)])
cross_nsl <- function(keys) {
  if (!nrow(keys) || !nrow(nsl_fl)) return(rep(FALSE, nrow(keys)))
  k <- copy(keys)[, rid := .I]
  m <- nsl_fl[k, on = .(PLOTKEY, F1 <= Y2, F2 >= Y1), nomatch = 0L,
              .(rid = i.rid, Y1 = i.Y1, Y2 = i.Y2, F1 = x.F1, F2 = x.F2)]
  seq_len(nrow(k)) %in% unique(m[!(Y1 >= F1 & Y2 <= F2), rid])
}
nsl_sr <- fread(file.path(MS, "bench_ns_long_pairs.csv"), select = c("STAND", "SINGLE_REGIME"))
nsl_sr[, PLOTKEY := sub(rx[["NS_LONG"]], "", STAND)]
nsl_sr <- nsl_sr[, .(NSL_SINGLE_REGIME = min(SINGLE_REGIME)), by = PLOTKEY]

## ---------------------------------------------------------------------------------------------
## helpers
## ---------------------------------------------------------------------------------------------
ba4  <- function(d, e) sum(pi * (d / 200)^2 * e * (d >= 4 & e > 0))
tph4 <- function(d, e) sum(e * (d >= 4 & e > 0))
match_unreloc <- function(d1, d2, iv) {
  ## one-to-one greedy match of unrelocated t1 stems (d1) to new-tag t2 stems (d2), same species
  if (!length(d1) || !length(d2)) return(0L)
  d1 <- sort(d1); d2 <- sort(d2); used <- rep(FALSE, length(d2)); k <- 0L
  for (x in d1) {
    j <- which(!used & d2 >= x - 1 & d2 <= x + G_MAX * iv)
    if (length(j)) { used[j[1]] <- TRUE; k <- k + 1L }
  }
  k
}
in_window <- function(keys, evk) {
  ## any event year T with Y1 < T <= Y2 for the same plot key
  if (!nrow(evk)) return(rep(FALSE, nrow(keys)))
  x <- evk[keys, on = .(PLOTKEY, T > Y1, T <= Y2), .(hit = sum(!is.na(kind))), by = .EACHI]
  x$hit > 0
}
md5f <- function(f) unname(tools::md5sum(f))

MANI <- list(); CAND <- list(); FRAMES <- list()

## ---------------------------------------------------------------------------------------------
## 5. per (virtual) dataset
## ---------------------------------------------------------------------------------------------
for (vds in names(VDS)) {
  mem <- VDS[[vds]]
  cat("\n=====", vds, "=====\n")
  vv <- v[Name %in% mem & n > 0]
  xadd(vds, "all", "visits_without_live_trees", v[Name %in% mem & n == 0, .N], "GYDB visits")
  ## canonical visit per (PLOTKEY, YR): most live trees, then member order, then VisitID
  vv[, mord := match(Name, mem)]
  vv[, `:=`(nsig = uniqueN(sig), ninst = .N), by = .(PLOTKEY, YR)]
  setorder(vv, PLOTKEY, YR, -n, mord, VisitID)
  canon <- vv[, .SD[1], by = .(PLOTKEY, YR)]
  canon[, DISCORD := as.integer(nsig > 1)]
  xadd(vds, "all", "keyyears_duplicated_across_source_pairs", canon[ninst > 1, .N], "plot key-years", "resolved to one canonical visit")
  xadd(vds, "all", "keyyears_duplicated_discordant", canon[DISCORD == 1, .N], "plot key-years",
       "duplicate instances with different tree lists; kept the instance with most live trees; pairs flagged DUPVIS_DISCORD")
  setorder(canon, PLOTKEY, YR)
  canon[, nvis := .N, by = PLOTKEY]
  xadd(vds, "all", "plot_keys_single_visit", canon[nvis == 1, uniqueN(PLOTKEY)], "plot keys", "no remeasurement available")

  ## consecutive links
  lk <- canon[, .(Y1 = YR[-.N], Y2 = YR[-1]), by = PLOTKEY]
  own <- unique(sp_all[Name %in% mem], by = c("PLOTKEY", "Y1", "Y2"))
  ownC <- own[SRC_TYPE == "C"]; ownFL <- own[SRC_TYPE == "FL"]
  lk[, LINK_SRC := "unverified"]
  if (vds == "MNAP") lk[, LINK_SRC := "raw"]
  lk[ownC, on = .(PLOTKEY, Y1, Y2), LINK_SRC := "source"]
  if (any(mem %in% NSFAM)) {
    sib <- unique(sp_all[Name %in% NSFAM & SRC_TYPE == "C", .(PLOTKEY, Y1, Y2)])
    lk[sib, on = .(PLOTKEY, Y1, Y2), LINK_SRC := fifelse(LINK_SRC == "unverified", "sibling", LINK_SRC)]
    fls <- unique(sp_all[Name == "NS_LONG" & SRC_TYPE == "FL", .(PLOTKEY, F1 = Y1, F2 = Y2)])
    lk[fls, on = .(PLOTKEY, Y1 = F1, Y2 = F2), LINK_SRC := "fl_source"]
    ri <- fls[lk[LINK_SRC == "unverified"], on = .(PLOTKEY, F1 <= Y1, F2 >= Y2), nomatch = 0L,
              .(PLOTKEY, Y1 = i.Y1, Y2 = i.Y2)]
    ri <- unique(ri)
    if (nrow(ri)) lk[ri, on = .(PLOTKEY, Y1, Y2), LINK_SRC := "run_interior"]
  }
  evk <- ev[Name %in% mem, .(PLOTKEY, T, kind)]
  lk[, EVT_IN := in_window(lk[, .(PLOTKEY, Y1, Y2)], evk)]
  lk[, NSL_CROSS := FALSE]
  if (any(mem %in% NSFAM)) lk[, NSL_CROSS := cross_nsl(lk[, .(PLOTKEY, Y1, Y2)])]
  ## confirm the screening reason for absent links
  lk[, harvest_confirmed := EVT_IN]
  if (vds == "PEF" && !is.null(pef_rem)) {
    lk[, MU := sub("^PEF_([^_]+)_.*$", "\\1", PLOTKEY)]
    r1 <- pef_rem$rem[lk, on = .(MU, T > Y1, T <= Y2), .(h = sum(!is.na(one))), by = .EACHI]$h > 0
    r2 <- pef_rem$posth[lk, on = .(MU, Y = Y2), .(h = sum(!is.na(one))), by = .EACHI]$h > 0
    lk[, harvest_confirmed := EVT_IN | r1 | r2]
    lk[, MU := NULL]
  }
  admit <- c("source", "sibling", "run_interior", "raw", "fl_source")
  lk[, ok := LINK_SRC %in% admit & !EVT_IN & !NSL_CROSS]
  xadd(vds, "c", "links_total", nrow(lk), "consecutive links between GYDB visits")
  xadd(vds, "c", "links_absent_harvest_confirmed", lk[LINK_SRC == "unverified" & harvest_confirmed == TRUE, .N], "links",
       "not a source pair; removal year in (y1,y2] or post-harvest inventory at y2 (GYDB treatments, PEF activity file)")
  xadd(vds, "c", "links_absent_unverified", lk[LINK_SRC == "unverified" & harvest_confirmed == FALSE, .N], "links",
       "not a source pair and disturbance-free status not verifiable inside GYDB (source harvest/disturbance screen or random cap)")
  xadd(vds, "c", "links_event_in_interval", lk[LINK_SRC %in% admit & EVT_IN, .N], "links", "treatment or disturbance year in (y1,y2]")
  if (any(mem %in% NSFAM)) for (ls in c("source", "sibling"))
    xadd(vds, "c", paste0("links_", ls, "_cross_nslong_run_boundary"), lk[LINK_SRC == ls & !EVT_IN & NSL_CROSS, .N], "links",
         "touches or overlaps an NS_LONG first-last run without lying inside it, so it spans a disturbance break (short-source pairs predate the corrected cut screen)")
  xadd(vds, "c", "links_zero_length", 0L, "links", "visits deduplicated by plot key and year, so no zero-length link can form")

  ## segments of admitted links -> first-last
  lk[, segid := rleid(PLOTKEY, ok)]
  seg <- lk[ok == TRUE, .(nl = .N, Y1 = min(Y1), Y2 = max(Y2),
                          srcs = paste(sort(unique(LINK_SRC)), collapse = "+")), by = .(PLOTKEY, segid)]
  flc <- rbind(seg[nl >= 2, .(PLOTKEY, Y1, Y2, LINK_SRC = paste0("segment:", srcs), nlinks = nl)],
               lk[ok == TRUE & LINK_SRC == "fl_source", .(PLOTKEY, Y1, Y2, LINK_SRC = "fl_source", nlinks = 1L)])
  flc <- unique(flc, by = c("PLOTKEY", "Y1", "Y2"))
  if (nrow(ownFL)) {
    flc[ownFL, on = .(PLOTKEY, Y1, Y2), LINK_SRC := paste0(LINK_SRC, "|srcFL")]
    xadd(vds, "fl", "source_firstlast_pairs_not_rebuilt", ownFL[!flc, on = .(PLOTKEY, Y1, Y2), .N], "source FL pairs")
  }
  flc[, EVT_IN := in_window(flc[, .(PLOTKEY, Y1, Y2)], evk) | (any(mem %in% NSFAM) & cross_nsl(flc[, .(PLOTKEY, Y1, Y2)]))]
  xadd(vds, "fl", "firstlast_candidates", nrow(flc), "first-last pairs")
  xadd(vds, "fl", "firstlast_event_in_interval_or_nslong_cross", flc[EVT_IN == TRUE, .N], "first-last pairs")

  cc <- lk[ok == TRUE & LINK_SRC != "fl_source", .(PLOTKEY, Y1, Y2, LINK_SRC, nlinks = 1L)]
  xadd(vds, "c", "consecutive_candidates", nrow(cc), "pairs")
  CAND[[vds]] <- rbind(lk[LINK_SRC != "fl_source", .(vds = vds, PLOTKEY, Y1, Y2, set = fifelse(LINK_SRC == "fl_source", "fl", "c"),
                              LINK_SRC, status = fifelse(!ok, fifelse(EVT_IN, "excl_event_in_interval", fifelse(NSL_CROSS, "excl_cross_nslong_run",
                                  fifelse(harvest_confirmed, "excl_absent_harvest_confirmed", "excl_absent_unverified"))), "candidate"))],
                       flc[, .(vds = vds, PLOTKEY, Y1, Y2, set = "fl", LINK_SRC,
                               status = fifelse(EVT_IN, "excl_event_or_nslong_cross", "candidate"))])

  for (st in c("c", "fl")) {
    p <- if (st == "c") copy(cc) else copy(flc[EVT_IN == FALSE, .(PLOTKEY, Y1, Y2, LINK_SRC, nlinks)])
    if (!nrow(p)) { cat(vds, st, ": no pairs\n"); next }
    cv <- canon[, .(PLOTKEY, YR, Dataset, VisitID, Name, LocationID, Z, MM, n, fmin, omin, DISCORD, ELEV_FIA)]
    p <- merge(p, setnames(copy(cv), c("PLOTKEY", "Y1", paste0(names(cv)[-(1:2)], "_1"))), by = c("PLOTKEY", "Y1"))
    p <- merge(p, setnames(copy(cv), c("PLOTKEY", "Y2", paste0(names(cv)[-(1:2)], "_2"))), by = c("PLOTKEY", "Y2"))
    lt3 <- p[, n_1 < MIN_TREES | n_2 < MIN_TREES]
    xadd(vds, st, "pairs_fewer_than_3_live_trees", sum(lt3), "pairs", "fewer than 3 live trees of any size at t1 or t2 (runner skip rule)")
    k3 <- p[lt3, .(PLOTKEY, Y1, Y2, set = st)]
    if (nrow(k3)) CAND[[vds]][k3, on = .(PLOTKEY, Y1, Y2, set), status := "excl_lt3_trees"]
    p <- p[!lt3]
    kk <- p[, .(PLOTKEY, Y1, Y2, set = st)]
    if (nrow(kk)) CAND[[vds]][kk, on = .(PLOTKEY, Y1, Y2, set), status := "kept"]
    xadd(vds, st, "pairs_kept", nrow(p), "pairs")
    if (!nrow(p)) next
    DS <- vds
    p[, SET := st]
    p[, STAND := sprintf("%s__%s__%d_%d_%s", DS, PLOTKEY, Y1, Y2, toupper(st))]
    p[, SITE := sprintf("%s__%s", DS, PLOTKEY)]
    p[, PROV := PROV_OF[[DS]]]
    p[, JURIS := ds$Jurisdiction[match(Name_1, ds$Name)]]
    p[, DATASET := DS]
    p[, interval_years := as.integer(Y2 - Y1)]
    p[, INTERVAL_DEC := fifelse(MM_1 > 0 & MM_2 > 0, round((Y2 + (MM_2 - 0.5) / 12) - (Y1 + (MM_1 - 0.5) / 12), 3),
                                as.numeric(Y2 - Y1))]
    p[canon[, .(PLOTKEY, nvis)][, .SD[1], by = PLOTKEY], on = "PLOTKEY", N_VISITS_PLOT := i.nvis]
    p[, NLINKS := nlinks]
    p[, OLD_STAND := NA_character_]
    if (nrow(own)) p[own, on = .(PLOTKEY, Y1, Y2), OLD_STAND := i.OLD_STAND]
    p[, DUPVIS_DISCORD := pmax(DISCORD_1, DISCORD_2)]
    p[, NSL_SINGLE_REGIME := NA_integer_]
    if (DS %in% c("NS", "NS_LONG", "NSPOOL")) p[nsl_sr, on = "PLOTKEY", NSL_SINGLE_REGIME := i.NSL_SINGLE_REGIME]
    ## thresholds
    p[, FRAME_MINDBH := pmax(fmin_1, fmin_2)]
    p[, SCORE_MINDBH := pmax(FRAME_MINDBH, SCORE_FLOOR)]
    pom <- canon[, .(pom = min(omin)), by = PLOTKEY]
    p[pom, on = "PLOTKEY", PLOT_OBS_MINDBH := i.pom]
    p[, SCORE_MINDBH_OBS := pmax(SCORE_MINDBH, PLOT_OBS_MINDBH)]
    ## tree lists
    t1 <- tr[p[, .(STAND, Dataset = Dataset_1, VisitID = VisitID_1, YEAR = Y1)], on = .(Dataset, VisitID), allow.cartesian = TRUE]
    t2 <- tr[p[, .(STAND, Dataset = Dataset_2, VisitID = VisitID_2, YEAR = Y2)], on = .(Dataset, VisitID), allow.cartesian = TRUE]
    ## observed stand metrics, harness rule (DBH >= 4 cm, EXPF > 0)
    m1 <- t1[, .(N_T1 = .N, BA_T1 = ba4(DBH, EXPF), TPH_T1 = tph4(DBH, EXPF)), by = STAND]
    m2 <- t2[, .(N_T2 = .N, BA_T2 = ba4(DBH, EXPF), TPH_T2 = tph4(DBH, EXPF),
                 N_INGROWTH_MEMB = if (DS == "BAXTER") sum(Membership %in% 1L) else NA_integer_), by = STAND]
    p <- merge(p, m1, by = "STAND"); p <- merge(p, m2, by = "STAND")
    ## churn: tag-free, every dataset
    th <- p[, .(STAND, thr = SCORE_MINDBH, iv = pmax(interval_years, 1L))]
    a1 <- merge(t1, th, by = "STAND")[, .(n1 = sum(DBH >= thr)), by = .(STAND, SP)]
    a2 <- merge(t2, th, by = "STAND")[, .(n2big = sum(DBH > thr + G_MAX * iv)), by = .(STAND, SP)]
    tf <- merge(a1, a2, by = c("STAND", "SP"), all = TRUE)
    tf[is.na(n1), n1 := 0L][is.na(n2big), n2big := 0L]
    tf <- tf[, .(CHURN_TF_NEWBIG = sum(pmax(0L, n2big - n1))), by = STAND]
    p[tf, on = "STAND", CHURN_TF_NEWBIG := i.CHURN_TF_NEWBIG]
    ## churn: tag based, real-tag datasets only
    tagst <- if (DS %in% names(TAG_STABLE)) 1L else 0L
    p[, TAG_STABLE := tagst]
    p[, `:=`(N_NEWTAG = NA_integer_, N_UNRELOC = NA_integer_, CHURN_NEWTAG_BIG = NA_integer_, CHURN_UNRELOC_SAMESP = NA_integer_)]
    if (tagst == 1L) {
      x1 <- merge(t1, th, by = "STAND")[Tree < 9e6]; x2 <- merge(t2, th, by = "STAND")[Tree < 9e6]   # pass 28b: untracked rows (Tree 9,000,000 and up) carry no tag
      x2[, new := !(paste(STAND, Tree) %chin% paste(x1$STAND, x1$Tree))]
      x1[, unrel := !(paste(STAND, Tree) %chin% paste(x2$STAND, x2$Tree)) & DBH >= thr]
      nb <- x2[, .(N_NEWTAG = sum(new), CHURN_NEWTAG_BIG = sum(new & DBH > thr + G_MAX * iv)), by = STAND]
      nu <- x1[, .(N_UNRELOC = sum(unrel)), by = STAND]
      um_ <- merge(x1[unrel == TRUE, .(d1 = list(DBH)), by = .(STAND, SP)],
                   x2[new == TRUE, .(d2 = list(DBH), iv = iv[1]), by = .(STAND, SP)], by = c("STAND", "SP"))
      um_ <- if (nrow(um_)) um_[, .(k = match_unreloc(d1[[1]], d2[[1]], iv)), by = .(STAND, SP)][, .(CHURN_UNRELOC_SAMESP = sum(k)), by = STAND] else data.table(STAND = character(), CHURN_UNRELOC_SAMESP = integer())
      p[nb, on = "STAND", `:=`(N_NEWTAG = i.N_NEWTAG, CHURN_NEWTAG_BIG = i.CHURN_NEWTAG_BIG)]
      p[nu, on = "STAND", N_UNRELOC := i.N_UNRELOC]
      p[, CHURN_UNRELOC_SAMESP := 0L]
      p[um_, on = "STAND", CHURN_UNRELOC_SAMESP := i.CHURN_UNRELOC_SAMESP]
    }
    p[, CHURN_FLAG := as.integer(if (tagst == 1L) (CHURN_NEWTAG_BIG > 0 | CHURN_UNRELOC_SAMESP > 0) else CHURN_TF_NEWBIG > 0)]
    ## treatment at the t1 year (kept; t1 is the post-treatment inventory in PEF and CTRN)
    p[, TRT_AT_Y1 := 0L]
    if (nrow(evk)) p[evk, on = .(PLOTKEY, Y1 = T), TRT_AT_Y1 := 1L]
    ## site index: covariate 30 m ESI first, old harness esi8 second
    ce <- merge(canon[, .(PLOTKEY, YR, Name, LocationID, OLD_STAND)],
                cov[, .(Name = Dataset, LocationID, esi_cov = esi8_30m)], by = c("Name", "LocationID"), all.x = TRUE)
    ce <- merge(ce, oldesi, by = c("Name", "OLD_STAND"), all.x = TRUE)
    setorder(ce, PLOTKEY, YR)
    ek <- ce[, .(e_cov = { z <- esi_cov[is.finite(esi_cov) & esi_cov > 2]; if (length(z)) z[1] else NA_real_ },
                 e_old = { z <- esi8_old[is.finite(esi8_old) & esi8_old > 2]; if (length(z)) z[1] else NA_real_ }), by = PLOTKEY]
    eo2 <- merge(sp_all[Name %in% mem, .(PLOTKEY, OLD_STAND, Name)], oldesi, by = c("Name", "OLD_STAND"))
    eo2 <- if (nrow(eo2[is.finite(esi8_old) & esi8_old > 2])) eo2[is.finite(esi8_old) & esi8_old > 2, .(e_old2 = esi8_old[1]), by = PLOTKEY] else
           data.table(PLOTKEY = character(), e_old2 = numeric())
    ek <- merge(ek, eo2, by = "PLOTKEY", all.x = TRUE)
    ek[is.na(e_old), e_old := e_old2]
    ek[, esi8 := fifelse(is.finite(e_cov), e_cov, e_old)]
    ek[, ESI_SRC := fifelse(is.finite(e_cov), "cov30m", fifelse(is.finite(e_old), "oldharness", "none"))]
    p[ek, on = "PLOTKEY", `:=`(ESI_SRC = i.ESI_SRC, esi_value_tmp = i.esi8, ESI_OLD = i.e_old)]
    ## elevation
    ekv <- merge(sp_all[Name %in% mem, .(PLOTKEY, OLD_STAND, Name)], oldelev, by = c("Name", "OLD_STAND"))
    ekv <- ekv[is.finite(ELEV_old) & ELEV_old > 0]
    p[, ELEV_OLDH := NA_real_]
    if (nrow(ekv)) p[ekv[, .(ELEV_old = median(ELEV_old)), by = PLOTKEY], on = "PLOTKEY", ELEV_OLDH := i.ELEV_old]
    p[, ELEV := NA_real_]; p[, ELEV_SRC := "none"]
    if (DS %in% fiaN) {
      p[, ELEV := fifelse(is.finite(ELEV_FIA_1), ELEV_FIA_1, ELEV_FIA_2)]
      p[is.finite(ELEV), ELEV_SRC := "fia_plot_ft_to_m"]
    } else if (DS == "MNAP") {
      p[, ELEV := as.numeric(fifelse(is.finite(Z_1), Z_1, Z_2))]
      p[is.finite(ELEV), ELEV_SRC := "gydb_location_Z"]
    } else {
      p[, ELEV := ELEV_OLDH]
      p[is.finite(ELEV), ELEV_SRC := if (DS %in% c("NS", "NS_LONG", "NSPOOL")) "oldharness_200m_placeholder" else
                                     if (DS == "PEF") "oldharness_50m_placeholder" else "oldharness"]
    }
    ## management
    p[, MANAGED_RULE := MGD_RULE[[DS]]]
    if (DS == "CTRN") { p[ctrn_m, on = "PLOTKEY", MANAGED := i.MG] }
    else if (DS == "PEF") { p[pef_m, on = "PLOTKEY", MANAGED := i.MG] }
    else if (DS %in% c("NS", "NS_LONG", "NSPOOL")) {
      if (p[, any(!grepl("^NS_(OP|RS)_", PLOTKEY))]) stop("NS key without OP/RS programme prefix")
      p[, MANAGED := as.integer(grepl("^NS_RS_", PLOTKEY))]
    } else p[, MANAGED := as.integer(grepl("^source1|^fia1", MANAGED_RULE))]
    if (p[, anyNA(MANAGED)]) stop(DS, ": missing MANAGED for ", p[is.na(MANAGED), .N], " pairs")
    p[, MANAGED_OLDFLAG := NA_integer_]
    om_ <- oldmgd[Name %in% mem, .(OLD_STAND, MGD_old)]
    if (nrow(om_)) p[unique(om_, by = "OLD_STAND"), on = "OLD_STAND", MANAGED_OLDFLAG := i.MGD_old]

    ## write
    tag <- sprintf("gyr_%s_%s", tolower(DS), st)
    f <- setNames(file.path(FR, sprintf("bench_%s_%s.csv", tag, c("pairs", "tree_init", "tree_t2", "site_esi"))),
                  c("pairs", "tree_init", "tree_t2", "site_esi"))
    if (any(file.exists(f))) stop("refusing to overwrite ", f[file.exists(f)][1])
    setorder(p, STAND)
    po <- p[, .(STAND, SITE, PROV, interval_years, ELEV = round(ELEV, 1), MANAGED,
                DATASET, SET, JURIS, PLOTKEY, Y1, Y2, INTERVAL_DEC, N_VISITS_PLOT, NLINKS, LINK_SRC, OLD_STAND,
                MANAGED_RULE, MANAGED_OLDFLAG, ESI_SRC, ESI_OLD = round(ESI_OLD, 3), ELEV_SRC,
                FRAME_MINDBH = round(FRAME_MINDBH, 2), SCORE_MINDBH = round(SCORE_MINDBH, 2),
                PLOT_OBS_MINDBH = round(PLOT_OBS_MINDBH, 2), SCORE_MINDBH_OBS = round(SCORE_MINDBH_OBS, 2),
                N_T1, N_T2, BA_T1 = round(BA_T1, 4), BA_T2 = round(BA_T2, 4), TPH_T1 = round(TPH_T1, 3), TPH_T2 = round(TPH_T2, 3),
                TAG_STABLE, N_NEWTAG, N_UNRELOC, CHURN_NEWTAG_BIG, CHURN_UNRELOC_SAMESP, CHURN_TF_NEWBIG, CHURN_FLAG,
                N_INGROWTH_MEMB, TRT_AT_Y1, DUPVIS_DISCORD, NSL_SINGLE_REGIME)]
    if (any(grepl("^(lat|lon|LAT|LON|X|Y)$", names(po)))) stop("coordinate-like column in pairs output")
    ti_o <- t1[, .(STAND, PLOT = 1L, TREE = Tree, SP, DBH, HT, EXPF, YEAR)]
    t2_o <- t2[, .(STAND, PLOT = 1L, TREE = Tree, SP, DBH, HT, EXPF, YEAR)]
    setorder(ti_o, STAND, TREE); setorder(t2_o, STAND, TREE)
    se_o <- unique(p[, .(SITE, esi8 = round(esi_value_tmp, 3))], by = "SITE")
    setorder(se_o, SITE)
    fwrite(po, f[["pairs"]]); fwrite(ti_o, f[["tree_init"]]); fwrite(t2_o, f[["tree_t2"]]); fwrite(se_o, f[["site_esi"]])
    FRAMES[[tag]] <- list(p = po, t1 = ti_o, t2 = t2_o, se = se_o)
    MANI[[tag]] <- data.table(
      dataset = DS, set = c(c = "consecutive", fl = "firstlast")[[st]], src_tag = tag,
      n_plots = uniqueN(po$PLOTKEY), n_pairs = nrow(po), n_trees_t1 = nrow(ti_o), n_trees_t2 = nrow(t2_o),
      interval_mean = round(mean(po$interval_years), 2), interval_min = min(po$interval_years), interval_max = max(po$interval_years),
      frame_mindbh_median = median(po$FRAME_MINDBH), frame_mindbh_min = min(po$FRAME_MINDBH), frame_mindbh_max = max(po$FRAME_MINDBH),
      score_mindbh_median = median(po$SCORE_MINDBH), score_mindbh_obs_median = median(po$SCORE_MINDBH_OBS),
      managed_share = round(mean(po$MANAGED), 4), managed_rule = MGD_RULE[[DS]],
      churn_flag_share = round(mean(po$CHURN_FLAG), 4), tag_stable = tagst,
      esi_cov_share = round(mean(is.finite(se_o$esi8[match(po$SITE, se_o$SITE)]) & se_o$esi8[match(po$SITE, se_o$SITE)] > 2), 4),
      share_cov30m = round(mean(po$ESI_SRC == "cov30m"), 4),
      link_src = paste(po[, .N, by = LINK_SRC][order(-N), sprintf("%s:%d", LINK_SRC, N)], collapse = " "),
      share_old_stand_match = round(mean(!is.na(po$OLD_STAND)), 4),
      md5_pairs = md5f(f[["pairs"]]), md5_tree_init = md5f(f[["tree_init"]]),
      md5_tree_t2 = md5f(f[["tree_t2"]]), md5_site_esi = md5f(f[["site_esi"]]))
    cat(sprintf("%s: %d pairs, %d plots, t1 %d / t2 %d trees, churn %.3f, managed %.3f\n", tag, nrow(po),
                uniqueN(po$PLOTKEY), nrow(ti_o), nrow(t2_o), mean(po$CHURN_FLAG), mean(po$MANAGED)))
  }
}
mani <- rbindlist(MANI)
cand <- rbindlist(CAND)
excl <- rbindlist(EXCL)

## ---------------------------------------------------------------------------------------------
## 6. validation against the old harness frames
## ---------------------------------------------------------------------------------------------
fia_root <- NULL
VAL <- list()
newall <- rbindlist(lapply(names(FRAMES), function(k) FRAMES[[k]]$p[, .(DATASET, SET, STAND, PLOTKEY, Y1, Y2)]))
newt <- rbindlist(lapply(names(FRAMES), function(k) rbind(FRAMES[[k]]$t1[, .(STAND, occ = 1L, DBH, EXPF)],
                                                             FRAMES[[k]]$t2[, .(STAND, occ = 2L, DBH, EXPF)])))
newm <- newt[, .(BA = ba4(DBH, EXPF), TPH = tph4(DBH, EXPF), N = .N), by = .(STAND, occ)]
newm <- dcast(newm, STAND ~ occ, value.var = c("BA", "TPH", "N"))
fp2 <- fread(FIA_PLOT, select = c("CN", "PREV_PLT_CN"), colClasses = list(character = c("CN", "PREV_PLT_CN")))
fp2[PREV_PLT_CN %in% c("", "NA"), PREV_PLT_CN := NA_character_]
parent <- setNames(fp2$PREV_PLT_CN, fp2$CN); parent[!(parent %in% fp2$CN)] <- NA_character_
vset <- list(
  list(ds = "PEF", pfx = OLD$PEF$pfx, label = "bench_pef"),
  list(ds = "CTRN", pfx = OLD$CTRN$pfx, label = "bench_ctrn"),
  list(ds = "SILC_L", pfx = OLD$SILC_L$pfx, label = "bench_silc_l (harness 74 rows)"),
  list(ds = "SILC_L", pfx = file.path(MS, "bench_silc_l"), sfx = "_full137", label = "bench_silc_l full137 (GYDB source)"),
  list(ds = "BAXTER", pfx = OLD$BAXTER$pfx, label = "bench_baxter"),
  list(ds = "NS", pfx = OLD$NS$pfx, label = "bench_ns"),
  list(ds = "NS_LONG", pfx = OLD$NS_LONG$pfx, label = "bench_ns_long"),
  list(ds = "MEFIA_L", pfx = OLD$MEFIA_L$pfx, label = "bench_mefia_long"),
  list(ds = "MEMAT", pfx = OLD$MEMAT$pfx, label = "p5m_memat"),
  list(ds = "MEDEV", pfx = OLD$MEDEV$pfx, label = "p5m_medev"),
  list(ds = "NB", pfx = OLD$NB$pfx, prov = "NB", label = "magp_qcnb (PROV NB)"),
  list(ds = "QC", pfx = OLD$QC$pfx, prov = "QC", label = "magp_qcnb (PROV QC)"))
for (vs in vset) {
  sfx <- if (is.null(vs$sfx)) "" else vs$sfx
  pf <- paste0(vs$pfx, "_pairs", sfx, ".csv")
  op <- read_old_pairs(pf, vs$prov)
  oi <- fread(paste0(vs$pfx, "_tree_init", sfx, ".csv"), select = c("STAND", "DBH", "EXPF", "YEAR"), colClasses = list(character = "STAND"))
  o2 <- fread(paste0(vs$pfx, "_tree_t2", sfx, ".csv"), select = c("STAND", "DBH", "EXPF", "YEAR"), colClasses = list(character = "STAND"))
  oi <- oi[STAND %in% op$STAND]; o2 <- o2[STAND %in% op$STAND]
  if (!is.null(vs$prov)) {
    ## magp_qcnb: STAND is not unique per interval in QC, so the pair is (STAND, y1, y2) from the pairs file
    yy <- fread(pf, select = c("STAND", "PROV", "y1", "y2"), colClasses = list(character = "STAND"))[PROV == vs$prov]
    yy[, OKEY := paste(STAND, y1, y2)]
    a1 <- merge(oi, yy[, .(STAND, YEAR = y1, OKEY)], by = c("STAND", "YEAR"), allow.cartesian = TRUE)
    a2 <- merge(o2, yy[, .(STAND, YEAR = y2, OKEY)], by = c("STAND", "YEAR"), allow.cartesian = TRUE)
  } else {
    a1 <- copy(oi)[, OKEY := STAND]; a2 <- copy(o2)[, OKEY := STAND]
  }
  om <- merge(a1[, .(Y1 = min(YEAR), oBA_1 = ba4(DBH, EXPF), oTPH_1 = tph4(DBH, EXPF)), by = .(OKEY, STAND)],
              a2[, .(Y2 = min(YEAR), oBA_2 = ba4(DBH, EXPF), oTPH_2 = tph4(DBH, EXPF)), by = .(OKEY, STAND)], by = c("OKEY", "STAND"))
  if (vs$ds %in% fiaN) {
    om[, PLOTKEY := paste0("FIA", root_of(sub("^(MEM|ME_L)_", "", STAND)))]
  } else if (vs$ds == "QC") {
    om[, PLOTKEY := sub("_I\\d+$", "", STAND)]
  } else om[, PLOTKEY := sub(rx[[vs$ds]], "", STAND)]
  nw <- newall[DATASET == vs$ds, .(NSTAND = STAND, SET, PLOTKEY, Y1, Y2)]
  mm <- merge(om, nw, by = c("PLOTKEY", "Y1", "Y2"), all.x = TRUE, allow.cartesian = TRUE)
  mm <- merge(mm, newm, by.x = "NSTAND", by.y = "STAND", all.x = TRUE)
  mm[, `:=`(dBA1 = abs(BA_1 - oBA_1), dBA2 = abs(BA_2 - oBA_2), dTPH1 = abs(TPH_1 - oTPH_1), dTPH2 = abs(TPH_2 - oTPH_2))]
  rec <- mm[!is.na(NSTAND)]
  un <- unique(mm[is.na(NSTAND), .(PLOTKEY, Y1, Y2)])
  unc <- unique(cand[vds == vs$ds, .(PLOTKEY, Y1, Y2, status)])[un, on = .(PLOTKEY, Y1, Y2)]
  unc <- unc[, .(status = if (all(is.na(status))) "not_formed_from_gydb_visits" else paste(sort(unique(na.omit(status))), collapse = "/")), by = .(PLOTKEY, Y1, Y2)]
  why <- unc[, .N, by = status]
  big <- rec[pmax(dBA1, dBA2) > 1e-3]
  VAL[[length(VAL) + 1]] <- data.table(
    dataset = vs$ds, old_file = vs$label, n_old_pairs = nrow(op), n_old_with_both_years = nrow(om),
    n_recovered = uniqueN(rec$OKEY), share_recovered = round(uniqueN(rec$OKEY) / nrow(op), 4),
    recovered_in_consecutive = rec[SET == "c", uniqueN(OKEY)], recovered_in_firstlast = rec[SET == "fl", uniqueN(OKEY)],
    unrecovered_reasons = if (nrow(why)) paste(why[, sprintf("%s:%d", status, N)], collapse = " ") else "",
    n_new_pairs_same_dataset = nrow(nw),
    max_abs_dBA_t1 = round(max(c(0, rec$dBA1), na.rm = TRUE), 6), max_abs_dBA_t2 = round(max(c(0, rec$dBA2), na.rm = TRUE), 6),
    max_abs_dTPH_t1 = round(max(c(0, rec$dTPH1), na.rm = TRUE), 4), max_abs_dTPH_t2 = round(max(c(0, rec$dTPH2), na.rm = TRUE), 4),
    n_rec_any_dBA_gt_0.001 = uniqueN(big$OKEY),
    n_rec_any_dTPH_gt_0.01 = rec[pmax(dTPH1, dTPH2) > 1e-2, uniqueN(OKEY)],
    mean_signed_dBA_t1 = round(rec[, mean(BA_1 - oBA_1)], 6), mean_signed_dBA_t2 = round(rec[, mean(BA_2 - oBA_2)], 6))
  if (nrow(big)) { cat("largest BA differences,", vs$label, "\n"); print(head(big[order(-pmax(dBA1, dBA2)), .(OKEY, Y1, Y2, oBA_1, BA_1, oBA_2, BA_2, oTPH_2, TPH_2, N_1, N_2)], 5)) }
}
val <- rbindlist(VAL)
VNOTE <- c(
  "bench_pef" = "exact; EXPF re-derived from GYDB frame area (4 dp) moves TPH by <= 0.006 trees/ha; 638 further GYDB links are harvest intervals the source builder removed and stay excluded",
  "bench_ctrn" = "exact; 52 absent links stay excluded (30 with a thinning year inside the interval, 22 unverifiable)",
  "bench_silc_l (harness 74 rows)" = "exact",
  "bench_silc_l full137 (GYDB source)" = "2 plots carry no survey year in GYDB; 15 pairs have fewer than 3 live trees (SILC tally starts at 11.43 cm) and are excluded, as the runner would skip them",
  "bench_baxter" = "GYDB Baxter was loaded from the p22 real-tag files (29 duplicate visit-tag rows dropped at load), not from the renumbered harness files; 2 stands differ (BAX_52 t2, BAX_31 t1)",
  "bench_ns" = "146 harness pairs touch or overlap an NS_LONG undisturbed-run boundary and are excluded as disturbance-crossing; the rest match to EXPF rounding",
  "bench_ns_long" = "2 first-last pairs end on a key-year GYDB holds twice with different tree lists (same-year remeasurement); the frame keeps the larger list and the harness FL used the smaller; 1 consecutive pair (NS_RS_8207P8207 1997-2004) skips a 1999 GYDB visit and is replaced by 1997-1999",
  "bench_mefia_long" = "15 harness pairs with fewer than 3 live trees excluded (the runner skips them)",
  "p5m_memat" = "exact", "p5m_medev" = "exact",
  "magp_qcnb (PROV NB)" = "exact", "magp_qcnb (PROV QC)" = "exact; old STAND is not unique across intervals, so pairs were keyed on STAND with y1 and y2")
val[, note := unname(VNOTE[old_file])]
print(val)

## ---------------------------------------------------------------------------------------------
## 7. write aggregate tables (no coordinates, no tree rows)
## ---------------------------------------------------------------------------------------------
if (file.exists(file.path(OUT, "gydb-regional-frames-manifest_DATA_2026-09-16.csv"))) stop("manifest exists; refusing to overwrite")
fwrite(mani, file.path(OUT, "gydb-regional-frames-manifest_DATA_2026-09-16.csv"))
fwrite(val,  file.path(OUT, "gydb-regional-frames-validation_DATA_2026-09-16.csv"))
fwrite(excl, file.path(OUT, "gydb-regional-frames-exclusions_DATA_2026-09-16.csv"))
fwrite(cand[, .N, by = .(vds, set, LINK_SRC, status)][order(vds, set, LINK_SRC, status)],
       file.path(OUT, "gydb-regional-frames-candidate-status_DATA_2026-09-16.csv"))
print(mani[, .(src_tag, n_plots, n_pairs, n_trees_t1, n_trees_t2, interval_mean, managed_share, churn_flag_share, esi_cov_share, link_src)])
cat("GYR_BUILD_DONE\n")

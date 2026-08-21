## build_gydb.R v3 -- fixes found in v2's first real run:
## (a) HT occasionally out of schema range [0.01,110] m (1 record, CTRN t2, 200.1m, data entry
##     error) -- nulled with a logged warning, applied uniformly to every source.
## (b) PEF's TREE column is not a unique per-stand key: 73110 init rows collide on (STAND,TREE).
##     PEF appears to use tally counts, not individually numbered stems (TallyMethod set to
##     Tally=3 below). Any source whose TREE numbering collides within a visit is renumbered
##     sequentially per visit, with the collision count logged as a real, disclosed finding.
## (c) Baxter's real-tag file has 29 already-disclosed within-visit collisions (2 stands,
##     ingrowth stems reusing raw ids). Real identity is preserved; colliding duplicates are
##     dropped (kept: first), logged with a count.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths()))
suppressMessages({ library(gydb); library(RSQLite); library(DBI); library(data.table) })
setwd("~/gydb_ws")
MSD <- "/users/PUOM0008/crsfaaron/magplot/verify"
DB <- "data/ALL/ALL_Standardized.sqlite"
dir.create("data/ALL", recursive = TRUE, showWarnings = FALSE)
if (file.exists(DB)) file.remove(DB)
create_standardized_db(DB)
con <- dbConnect(SQLite(), DB)
dbExecute(con, "PRAGMA foreign_keys = OFF")
dbExecute(con, "PRAGMA synchronous = OFF")
dbExecute(con, "PRAGMA journal_mode = MEMORY")

LOG <- data.table(Dataset=integer(), Provider=character(), Level=character(), Message=character())
logmsg <- function(ds, prov, level, msg) {
  LOG <<- rbind(LOG, data.table(Dataset=ds, Provider=prov, Level=level, Message=msg))
  cat(sprintf("[%s] Dataset %d (%s): %s\n", level, ds, prov, msg))
}

AGY2SP <- c(AB="FAGR", AS="FRAXI", BA="FRNI", BC="PRSE2", BF="ABBA", BP="POBA2", BS="PIMA",
            BT="POGR4", EC="PODE3", EH="TSCA", GA="FRPE", GB="BEPO", HH="OSVI", JP="PIBA2",
            NC="THOC2", NS="PIAB", OH="T_B", OS="T_C", PB="BEPA", PC="PRPE2", PR="PRPE2",
            QA="POTR5", RB="BENI", RM="ACRU", RN="PIRE", RO="QURU", RP="PIRE", RS="PIRU",
            SB="BELE", SM="ACSA3", ST="ACPE", TA="LALA", WA="FRAM2", WC="THOC2", WP="PIST",
            WS="PIGL", YB="BEAL2")
map_sp <- function(agy) { out <- AGY2SP[agy]; out[is.na(out)] <- "T_X"; unname(out) }
cat("PART1_OK\n")

build_generic_source <- function(dataset_id, name, full_name, jurisdiction, owner,
                                  pairs_f, init_f, t2_f, treat_f = NULL, real_tag = FALSE) {
  logmsg(dataset_id, name, "INFO", "starting build")
  pairs <- fread(file.path(MSD, pairs_f))
  ti    <- fread(file.path(MSD, init_f))
  t2    <- fread(file.path(MSD, t2_f))
  treat <- if (!is.null(treat_f) && file.exists(file.path(MSD, treat_f))) fread(file.path(MSD, treat_f)) else NULL

  n0i <- nrow(ti); n0t <- nrow(t2)
  ti <- ti[!is.na(TREE)]; t2 <- t2[!is.na(TREE)]
  if (nrow(ti) < n0i) logmsg(dataset_id, name, "WARNING", sprintf("dropped %d init row(s) with TREE=NA", n0i - nrow(ti)))
  if (nrow(t2) < n0t) logmsg(dataset_id, name, "WARNING", sprintf("dropped %d t2 row(s) with TREE=NA", n0t - nrow(t2)))

  ## HT range fix, applied uniformly
  bad_i <- which(!is.na(ti$HT) & (ti$HT <= 0 | ti$HT > 110))
  bad_t <- which(!is.na(t2$HT) & (t2$HT <= 0 | t2$HT > 110))
  if (length(bad_i)) { logmsg(dataset_id, name, "WARNING", sprintf("nulled %d init HT value(s) outside [0.01,110] m", length(bad_i))); ti$HT[bad_i] <- NA_real_ }
  if (length(bad_t)) { logmsg(dataset_id, name, "WARNING", sprintf("nulled %d t2 HT value(s) outside [0.01,110] m", length(bad_t))); t2$HT[bad_t] <- NA_real_ }

  dbExecute(con, sprintf(
    "INSERT INTO S_Datasets (Dataset,Name,FullName,Country,Jurisdiction,Owner,OwnerType,License,
       SamplingLayout,ProgramDescription,Received,Compiled,Compiler,Active) VALUES
       (%d,'%s','%s','USA','%s','%s','Research','Internal',
        'Fixed radius permanent plot','FVS-ACD hardwood form-risk benchmark source',
        '2026-08-20','2026-08-20','gydb build (Cowork pass 22)',1)",
    dataset_id, name, full_name, jurisdiction, owner))

  dbExecute(con, sprintf(
    "INSERT INTO S_Designs (Dataset,Design,DesignName,Description) VALUES
     (%d,1,'Fixed radius remeasurement','Fixed-radius permanent plot, remeasured; used as an FVS-ACD scoring benchmark.')",
    dataset_id))

  expf_vals <- sort(unique(round(ti$EXPF, 4)))
  tallymethod <- if (real_tag) 1L else 2L  ## corrected to 3L (Tally) below for PEF specifically
  frm <- rbindlist(lapply(seq_along(expf_vals), function(i) {
    e <- expf_vals[i]
    sub <- ti[round(EXPF,4) == e]; sub2 <- t2[round(EXPF,4) == e]
    dmin <- suppressWarnings(min(c(sub$DBH, sub2$DBH), na.rm = TRUE))
    data.table(Frame = i, EXPF = e, Area = 10000/e, Radius = sqrt((10000/e)/pi), MinDBHobs = dmin)
  }))
  for (i in seq_len(nrow(frm))) {
    dbExecute(con, sprintf(
      "INSERT INTO S_Frames (Dataset,Design,Frame,FrameName,Area,Radius,MinDBH,Census,
         StandingDead,TallyMethod,BreastHt) VALUES (%d,1,%d,'%s',%.4f,%.4f,%.2f,1,0,%d,1.3)",
      dataset_id, frm$Frame[i], if (nrow(frm) > 1) sprintf("Nested tier %d", frm$Frame[i]) else "Main plot",
      frm$Area[i], frm$Radius[i], if (is.finite(frm$MinDBHobs[i])) frm$MinDBHobs[i] else 4,
      tallymethod))
  }
  frame_lookup <- setNames(frm$Frame, as.character(frm$EXPF))

  sites <- unique(pairs$SITE)
  dbExecute(con, sprintf("INSERT INTO S_Blocks (Dataset,Block,Name) VALUES (%d,'-1','%s')", dataset_id, name))
  loc_id <- setNames(seq_along(sites), as.character(sites))
  loc_dt <- data.table(Dataset=dataset_id, LocationID=unname(loc_id), Block="-1",
                        Location=as.character(sites), X=NA_real_, Y=NA_real_, Plots=1L)
  dbAppendTable(con, "S_Locations", loc_dt)

  plot_id <- setNames(seq_along(pairs$STAND), pairs$STAND)
  plot_dt <- data.table(Dataset=dataset_id, LocationID=unname(loc_id[as.character(pairs$SITE)]),
                         PlotID=unname(plot_id[pairs$STAND]), Block="-1",
                         Location=as.character(pairs$SITE), Plot=pairs$STAND)
  dbAppendTable(con, "S_Plots", plot_dt)

  y1v <- suppressWarnings(sapply(pairs$STAND, function(st) as.integer(min(ti[STAND==st]$YEAR))))
  y2v <- suppressWarnings(sapply(pairs$STAND, function(st) as.integer(min(t2[STAND==st]$YEAR))))
  ok <- is.finite(y1v) & is.finite(y2v)
  if (any(!ok)) logmsg(dataset_id, name, "WARNING", sprintf("no year for %d stand(s): %s",
                        sum(!ok), paste(head(pairs$STAND[!ok],5), collapse=", ")))
  st_ok <- pairs$STAND[ok]
  v1id <- seq_along(st_ok) * 2L - 1L
  v2id <- seq_along(st_ok) * 2L
  names(v1id) <- st_ok; names(v2id) <- st_ok
  visit_dt <- rbindlist(list(
    data.table(Dataset=dataset_id, LocationID=unname(loc_id[as.character(pairs$SITE[ok])]),
               PlotID=unname(plot_id[st_ok]), VisitID=v1id, Block="-1",
               Location=as.character(pairs$SITE[ok]), Plot=st_ok, Visit=1L, YR=y1v[ok], Design=1L),
    data.table(Dataset=dataset_id, LocationID=unname(loc_id[as.character(pairs$SITE[ok])]),
               PlotID=unname(plot_id[st_ok]), VisitID=v2id, Block="-1",
               Location=as.character(pairs$SITE[ok]), Plot=st_ok, Visit=2L, YR=y2v[ok], Design=1L)
  ))
  dbAppendTable(con, "S_Visits", visit_dt)

  build_tree_dt <- function(d, vidmap) {
    d <- d[STAND %in% names(vidmap)]
    if (nrow(d) == 0) return(NULL)
    data.table(Dataset=dataset_id, VisitID=vidmap[d$STAND], Tree=d$TREE, STAND=d$STAND,
               Frame=frame_lookup[as.character(round(d$EXPF,4))],
               SpeciesCD=map_sp(d$SP), DBH=d$DBH, HT=d$HT, Status=1L)
  }
  t1dt <- build_tree_dt(ti, v1id)
  t2dt <- build_tree_dt(t2, v2id)

  ## Membership only where real cross-visit identity exists (Baxter)
  t1dt[, Membership := NA_integer_]
  if (real_tag && !is.null(t2dt)) {
    t2dt[, Membership := NA_integer_]
    for (st in unique(t2dt$STAND)) {
      idx <- which(t2dt$STAND == st)
      t1trees <- t1dt[STAND == st]$Tree
      t2dt$Membership[idx] <- ifelse(t2dt$Tree[idx] %in% t1trees, 0L, 1L)
    }
  } else if (!is.null(t2dt)) {
    t2dt[, Membership := NA_integer_]
  }

  tdt <- rbindlist(list(t1dt, t2dt))
  ## Resolve within-visit (VisitID,Tree) collisions: drop-duplicate for real-tag sources (keeps
  ## real identity), renumber sequentially for non-real-tag sources (TREE has no identity
  ## meaning there, and gydb's PK requires uniqueness).
  ndup <- sum(duplicated(tdt[, .(VisitID, Tree)]))
  if (ndup > 0) {
    if (real_tag) {
      tdt <- tdt[!duplicated(tdt[, .(VisitID, Tree)])]
      logmsg(dataset_id, name, "WARNING", sprintf("dropped %d duplicate (VisitID,Tree) row(s), real tag preserved for the rest", ndup))
    } else {
      tdt[, Tree := seq_len(.N), by = VisitID]
      logmsg(dataset_id, name, "WARNING", sprintf("%d (VisitID,Tree) collisions found in source TREE numbering; renumbered sequentially per visit (TREE is not a stable identity in this source)", ndup))
    }
  }
  tdt[, STAND := NULL]
  dbAppendTable(con, "S_Trees", tdt)
  logmsg(dataset_id, name, "INFO", sprintf("inserted %d tree records (t1+t2)", nrow(tdt)))

  if (!is.null(treat)) {
    treat <- treat[STAND %in% names(plot_id)]
    if ("YR" %in% names(treat) && nrow(treat) > 0) {
      treat_dt <- data.table(Dataset=dataset_id, PlotID=plot_id[treat$STAND],
                              YR=as.integer(treat$YR), Treatment=1L, Comments=NA_integer_)
      treat_dt <- treat_dt[is.finite(YR)]
      treat_dt <- unique(treat_dt, by=c("Dataset","PlotID","YR","Treatment"))
      if (nrow(treat_dt) > 0) dbAppendTable(con, "S_PlotTreatments", treat_dt)
      logmsg(dataset_id, name, "INFO", sprintf("inserted %d treatment records (generic Treatment code, pending real crosswalk)", nrow(treat_dt)))
    }
  }
  logmsg(dataset_id, name, "INFO", "build complete")
}
cat("PART2_OK\n")

sources <- list(
  list(id=1, name="BAXTER", full="Baxter State Park CFI (mature, held-out)", jur="ME", owner="Baxter State Park Authority",
       pairs="multisrc/bench_baxter_pairs.csv",
       init="p22/bench_baxter_tree_init_realtag.csv", t2="p22/bench_baxter_tree_t2_realtag.csv",
       treat=NULL, real_tag=TRUE),
  list(id=2, name="SILC_L", full="Seven Islands / SILC long-horizon CFI", jur="ME", owner="Seven Islands Land Company",
       pairs="multisrc/bench_silc_l_pairs_full137.csv",
       init="multisrc/bench_silc_l_tree_init_full137.csv", t2="multisrc/bench_silc_l_tree_t2_full137.csv",
       treat=NULL, real_tag=FALSE),
  list(id=3, name="CTRN", full="CFRU Cooperative Thinning Research Network", jur="ME", owner="Cooperative Forestry Research Unit",
       pairs="multisrc/bench_ctrn_pairs.csv",
       init="multisrc/bench_ctrn_tree_init.csv", t2="multisrc/bench_ctrn_tree_t2.csv",
       treat="multisrc/bench_ctrn_treatments.csv", real_tag=FALSE),
  list(id=4, name="PEF", full="Penobscot Experimental Forest (developing)", jur="ME", owner="USDA Forest Service",
       pairs="multisrc/bench_pef_pairs.csv",
       init="multisrc/bench_pef_tree_init.csv", t2="multisrc/bench_pef_tree_t2.csv",
       treat="multisrc/bench_pef_treatments.csv", real_tag=FALSE),
  list(id=5, name="MEFIA_L", full="Maine FIA whole-plot (long interval)", jur="ME", owner="USDA Forest Service FIA",
       pairs="multisrc/bench_mefia_long_pairs.csv",
       init="multisrc/bench_mefia_long_tree_init.csv", t2="multisrc/bench_mefia_long_tree_t2.csv",
       treat=NULL, real_tag=FALSE),
  list(id=6, name="MEMAT", full="Maine FIA mature stratum (consecutive remeasurement)", jur="ME", owner="USDA Forest Service FIA",
       pairs="p5m/p5m_memat_pairs.csv",
       init="p5m/p5m_memat_tree_init.csv", t2="p5m/p5m_memat_tree_t2.csv",
       treat=NULL, real_tag=FALSE),
  list(id=7, name="MEDEV", full="Maine FIA developing stratum (consecutive remeasurement)", jur="ME", owner="USDA Forest Service FIA",
       pairs="p5m/p5m_medev_pairs.csv",
       init="p5m/p5m_medev_tree_init.csv", t2="p5m/p5m_medev_tree_t2.csv",
       treat=NULL, real_tag=FALSE)
)

for (s in sources) {
  t0 <- Sys.time()
  res <- tryCatch({
    build_generic_source(s$id, s$name, s$full, s$jur, s$owner, s$pairs, s$init, s$t2, s$treat, s$real_tag)
    "OK"
  }, error = function(e) { logmsg(s$id, s$name, "ERROR", conditionMessage(e)); "FAILED" })
  cat(sprintf(">>> %s: %s (%.1fs)\n", s$name, res, as.numeric(Sys.time()-t0, units="secs")))
}

## PEF uses tally counts, not individually numbered stems (found this run); correct its Frame
## rows' TallyMethod from the generic default (2, Indv. Records) to 3 (Tally).
dbExecute(con, "UPDATE S_Frames SET TallyMethod = 3 WHERE Dataset = 4")

dbExecute(con, "PRAGMA foreign_keys = ON")
fwrite(LOG, "build_log_generic_sources.csv")
cat("ALL_GENERIC_SOURCES_DONE\n")

cat("\n=== row counts per table ===\n")
for (tb in c("S_Datasets","S_Designs","S_Frames","S_Blocks","S_Locations","S_Plots","S_Visits","S_Trees","S_PlotTreatments")) {
  cat(sprintf("%-20s %d\n", tb, dbGetQuery(con, sprintf("SELECT COUNT(*) n FROM %s", tb))$n))
}
dbDisconnect(con)
cat("SCRIPT_DONE\n")

## ---- MNAP Ecological Reserve (custom: nested 2-frame design, real coordinates, real
## TreeLink identity -- but NO survey calendar year is present anywhere in the CSVs made
## available this pass (only an ordinal Round 1/2, no YR/MM/DD, no year column in Plots either).
## S_Visits.YR is NOT NULL (checked directly against the schema DDL this pass: SMALLINT NOT
## NULL CHECK 1900-2050), so Visits and Trees are NOT built for MNAP in this v1 rather than
## invent a date. S_Datasets/S_Blocks/S_Locations/S_Plots ARE built since every field there is
## real, sourced data (including real lat/long, which is fine to use since MNAP is not FIA and
## not coordinate-restricted). ----
con <- dbConnect(SQLite(), DB)
dbExecute(con, "PRAGMA foreign_keys = OFF")
build_mnap <- function() {
  logmsg(8, "MNAP", "INFO", "starting build (Locations/Plots only, see header note on YR)")
  pl <- fread("mnap_raw/ERM_ME_Plots.csv")
  dbExecute(con, sprintf(
    "INSERT INTO S_Datasets (Dataset,Name,FullName,Country,Jurisdiction,Owner,OwnerType,License,
       SamplingLayout,ProgramDescription,Received,Compiled,Compiler,Active) VALUES
       (8,'MNAP','Maine Ecological Reserves Monitoring (MNAP/TNC)','USA','ME',
        'Maine Natural Areas Program / The Nature Conservancy','Public','Internal',
        'Nested fixed-radius permanent plot','Ecological Reserve long-term forest monitoring',
        '2026-08-20','2026-08-20','gydb build (Cowork pass 22)',1)"))
  dbExecute(con, "INSERT INTO S_Designs (Dataset,Design,DesignName,Description) VALUES
    (8,1,'Nested fixed-radius plot','Two-tier nested fixed-radius plot: small-tree subplot and large-tree plot, remeasured.')")
  ## frame radii back-calculated from the two EXPF constants found in ERM_ME_LiveTrees.csv
  dbExecute(con, "INSERT INTO S_Frames (Dataset,Design,Frame,FrameName,Area,Radius,MinDBH,MaxDBH,Census,StandingDead,TallyMethod,BreastHt) VALUES
    (8,1,1,'Small tree subplot',167.87,7.31,4,50.9,1,0,1,1.3)")
  dbExecute(con, "INSERT INTO S_Frames (Dataset,Design,Frame,FrameName,Area,Radius,MinDBH,Census,StandingDead,TallyMethod,BreastHt) VALUES
    (8,1,2,'Large tree plot',1012.23,17.95,51.0,1,0,1,1.3)")

  blocks <- unique(pl$EcoRName)
  bdt <- data.table(Dataset=8, Block=blocks, Name=blocks)
  dbAppendTable(con, "S_Blocks", bdt)

  loc_id <- setNames(seq_len(nrow(pl)), as.character(pl$Plot_ID))
  loc_dt <- data.table(Dataset=8, LocationID=unname(loc_id), Block=pl$EcoRName,
                        Location=as.character(pl$Plot_ID), X=pl$Longitude, Y=pl$Latitude,
                        Z=round(pl$Elevation), Plots=1L)
  dbAppendTable(con, "S_Locations", loc_dt)

  plot_dt <- data.table(Dataset=8, LocationID=unname(loc_id), PlotID=seq_len(nrow(pl)),
                         Block=pl$EcoRName, Location=as.character(pl$Plot_ID),
                         Plot=as.character(pl$Plot_ID),
                         Slope=pmin(pmax(round(pl$SlopePct),0),85), Aspect=pl$Aspect)
  dbAppendTable(con, "S_Plots", plot_dt)
  logmsg(8, "MNAP", "INFO", sprintf("built %d locations/plots; Visits and Trees deferred (no survey year in the source CSVs)", nrow(pl)))
  logmsg(8, "MNAP", "WARNING", "S_Visits/S_Trees NOT built for MNAP: no YR is present in ERM_ME_Plots.csv or ERM_ME_LiveTrees.csv (only ordinal Round 1/2). YR is NOT NULL in the schema, so no row was invented. Next step: locate survey years from EcoreserveMonitoring.accdb (needs Windows access_to_sqlite conversion or Aaron confirming dates directly) before tree data can be loaded.")
}
tryCatch(build_mnap(), error = function(e) logmsg(8, "MNAP", "ERROR", conditionMessage(e)))
dbExecute(con, "PRAGMA foreign_keys = ON")
fwrite(LOG, "build_log_full.csv")
cat("\n=== final row counts ===\n")
for (tb in c("S_Datasets","S_Locations","S_Plots","S_Visits","S_Trees")) {
  cat(sprintf("%-16s %d\n", tb, dbGetQuery(con, sprintf("SELECT COUNT(*) n FROM %s", tb))$n))
}
dbDisconnect(con)
cat("MNAP_DONE\n")

## Pass 27: extend the pass 23-26 GYDB instance with 4 Canadian sources (NS, NS_LONG, NB, QC)
## as datasets 9-12. Run against a copy of the live database (does not recreate it).
##
## OBSERVE found tree-level init/t2/pairs sources DO exist for all four (bench_ns_*,
## bench_ns_long_*, magp_qcnb_* split by PROV), contradicting the pass-23 handoff's claim that
## only scored results, not tree-level sources, were available. A cheap prototype (EXPF*DBH^2
## constancy test) confirmed these are fixed-radius designs like every other GYDB source, not
## point-sampled/BAF plots, despite NS/NS_LONG carrying 100+ distinct EXPF values (one per
## plot-size convention pooled into the composite source, not per-tree as BAF would produce).
##
## Two real defects found and fixed on the first attempt, both disclosed with exact counts:
## (a) NS: t2 carries 57 rows at EXPF 13.33, a value absent from init's EXPF set, so a
##     frame_lookup built from init alone left those rows with no Frame, violating the
##     NOT NULL constraint. Fixed by building frame_lookup from the union of init and t2 EXPF.
## (b) QC: 131 of 2,200 pairs rows share a STAND with a second, later remeasurement interval
##     (a location measured on 3+ occasions; unlike CTRN this source's STAND does not embed
##     the interval), so STAND-only tree selection could not tell which interval's trees
##     belonged to which pairs row and produced a duplicate (Dataset,PlotID). Fixed by keying
##     on (STAND, YEAR) matched against each pairs row's own y1/y2 rather than STAND membership
##     plus min(YEAR). Verified NOT needed for NB (0 duplicate STANDs, spot-checked 0 mismatches
##     between declared y1/y2 and min(YEAR) in the tree files) or NS/NS_LONG (STAND is already
##     unique per pairs row in both).
##
## A third defect, unrelated to the collision handling above: build_gydb.R's Country field was
## hardcoded 'USA' in every S_Datasets insert. Harmless for the 8 Maine sources but wrong for
## these four, which are Nova Scotia, Nova Scotia, New Brunswick, and Quebec. Parameterized here;
## worth back-porting into build_gydb.R itself so a future full rebuild does not reintroduce it.
suppressMessages({ library(RSQLite); library(DBI); library(data.table) })
DB <- "~/gydb_ws/data/ALL/ALL_Standardized.sqlite"
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

build_source_v2 <- function(dataset_id, name, full_name, jurisdiction, country, owner,
                             pairs_f, init_f, t2_f, match_by_year = FALSE) {
  logmsg(dataset_id, name, "INFO", "starting build")
  pairs <- fread(pairs_f); ti <- fread(init_f); t2 <- fread(t2_f)

  n0i <- nrow(ti); n0t <- nrow(t2)
  ti <- ti[!is.na(TREE)]; t2 <- t2[!is.na(TREE)]
  if (nrow(ti) < n0i) logmsg(dataset_id, name, "WARNING", sprintf("dropped %d init row(s) with TREE=NA", n0i - nrow(ti)))
  if (nrow(t2) < n0t) logmsg(dataset_id, name, "WARNING", sprintf("dropped %d t2 row(s) with TREE=NA", n0t - nrow(t2)))

  bad_i <- which(!is.na(ti$HT) & (ti$HT <= 0 | ti$HT > 110))
  bad_t <- which(!is.na(t2$HT) & (t2$HT <= 0 | t2$HT > 110))
  if (length(bad_i)) { logmsg(dataset_id, name, "WARNING", sprintf("nulled %d init HT value(s) outside [0.01,110] m", length(bad_i))); ti$HT[bad_i] <- NA_real_ }
  if (length(bad_t)) { logmsg(dataset_id, name, "WARNING", sprintf("nulled %d t2 HT value(s) outside [0.01,110] m", length(bad_t))); t2$HT[bad_t] <- NA_real_ }

  dbExecute(con, sprintf(
    "INSERT INTO S_Datasets (Dataset,Name,FullName,Country,Jurisdiction,Owner,OwnerType,License,
       SamplingLayout,ProgramDescription,Received,Compiled,Compiler,Active) VALUES
       (%d,'%s','%s','%s','%s','%s','Research','Internal',
        'Fixed radius permanent plot','FVS-ACD hardwood form-risk benchmark source',
        '2026-08-25','2026-08-25','gydb build (Cowork pass 27)',1)",
    dataset_id, name, full_name, country, jurisdiction, owner))
  dbExecute(con, sprintf(
    "INSERT INTO S_Designs (Dataset,Design,DesignName,Description) VALUES
     (%d,1,'Fixed radius remeasurement','Fixed-radius permanent plot, remeasured; used as an FVS-ACD scoring benchmark.')",
    dataset_id))

  expf_vals <- sort(unique(round(c(ti$EXPF, t2$EXPF), 4)))  ## fix (a): union, not init alone
  frm <- rbindlist(lapply(seq_along(expf_vals), function(i) {
    e <- expf_vals[i]
    sub <- ti[round(EXPF,4) == e]; sub2 <- t2[round(EXPF,4) == e]
    dmin <- suppressWarnings(min(c(sub$DBH, sub2$DBH), na.rm = TRUE))
    data.table(Frame = i, EXPF = e, Area = 10000/e, Radius = sqrt((10000/e)/pi), MinDBHobs = dmin)
  }))
  for (i in seq_len(nrow(frm))) {
    dbExecute(con, sprintf(
      "INSERT INTO S_Frames (Dataset,Design,Frame,FrameName,Area,Radius,MinDBH,Census,
         StandingDead,TallyMethod,BreastHt) VALUES (%d,1,%d,'%s',%.4f,%.4f,%.2f,1,0,2,1.3)",
      dataset_id, frm$Frame[i], if (nrow(frm) > 1) sprintf("Nested tier %d", frm$Frame[i]) else "Main plot",
      frm$Area[i], frm$Radius[i], if (is.finite(frm$MinDBHobs[i])) frm$MinDBHobs[i] else 4))
  }
  frame_lookup <- setNames(frm$Frame, as.character(frm$EXPF))

  sites <- unique(pairs$SITE)
  dbExecute(con, sprintf("INSERT INTO S_Blocks (Dataset,Block,Name) VALUES (%d,'-1','%s')", dataset_id, name))
  loc_id <- setNames(seq_along(sites), as.character(sites))
  dbAppendTable(con, "S_Locations", data.table(Dataset=dataset_id, LocationID=unname(loc_id), Block="-1",
                        Location=as.character(sites), X=NA_real_, Y=NA_real_, Plots=1L))

  pairs[, .rowkey := .I]
  ## fix (b): disambiguate STAND that repeats across intervals (3+ occasion locations) by
  ## folding y1/y2 into the plot key when the source's pairs file carries explicit years
  if (match_by_year) pairs[, .plotkey := paste0(STAND, "_y", y1, "_", y2)] else pairs[, .plotkey := STAND]
  ndup_plotkey <- sum(duplicated(pairs$.plotkey))
  if (ndup_plotkey > 0) logmsg(dataset_id, name, "WARNING", sprintf("%d pairs row(s) still share a plot key after disambiguation, dropping duplicates", ndup_plotkey))
  pairs <- pairs[!duplicated(.plotkey)]

  plot_id <- setNames(seq_len(nrow(pairs)), pairs$.plotkey)
  dbAppendTable(con, "S_Plots", data.table(Dataset=dataset_id, LocationID=unname(loc_id[as.character(pairs$SITE)]),
                         PlotID=unname(plot_id[pairs$.plotkey]), Block="-1",
                         Location=as.character(pairs$SITE), Plot=pairs$.plotkey))

  if (match_by_year) { y1v <- pairs$y1; y2v <- pairs$y2
  } else {
    y1v <- suppressWarnings(sapply(pairs$STAND, function(st) as.integer(min(ti[STAND==st]$YEAR))))
    y2v <- suppressWarnings(sapply(pairs$STAND, function(st) as.integer(min(t2[STAND==st]$YEAR))))
  }
  ok <- is.finite(y1v) & is.finite(y2v)
  if (any(!ok)) logmsg(dataset_id, name, "WARNING", sprintf("no year for %d pairs row(s)", sum(!ok)))
  pk_ok <- pairs$.plotkey[ok]; stand_ok <- pairs$STAND[ok]; y1_ok <- y1v[ok]; y2_ok <- y2v[ok]
  v1id <- seq_along(pk_ok) * 2L - 1L; v2id <- seq_along(pk_ok) * 2L
  names(v1id) <- pk_ok; names(v2id) <- pk_ok

  dbAppendTable(con, "S_Visits", rbindlist(list(
    data.table(Dataset=dataset_id, LocationID=unname(loc_id[as.character(pairs$SITE[ok])]),
               PlotID=unname(plot_id[pk_ok]), VisitID=v1id, Block="-1",
               Location=as.character(pairs$SITE[ok]), Plot=pk_ok, Visit=1L, YR=y1_ok, Design=1L),
    data.table(Dataset=dataset_id, LocationID=unname(loc_id[as.character(pairs$SITE[ok])]),
               PlotID=unname(plot_id[pk_ok]), VisitID=v2id, Block="-1",
               Location=as.character(pairs$SITE[ok]), Plot=pk_ok, Visit=2L, YR=y2_ok, Design=1L))))

  build_tree_dt_v2 <- function(d, yr_col) {
    if (match_by_year) {
      key_dt <- data.table(STAND = stand_ok, YEAR = yr_col, .plotkey = pk_ok, VisitID = if (identical(yr_col, y1_ok)) v1id else v2id)
      dm <- merge(d, key_dt, by = c("STAND","YEAR"), allow.cartesian = TRUE)
    } else {
      key_dt <- data.table(STAND = stand_ok, .plotkey = pk_ok, VisitID = if (identical(yr_col, y1_ok)) v1id else v2id)
      dm <- merge(d, key_dt, by = "STAND", allow.cartesian = TRUE)
    }
    if (nrow(dm) == 0) return(NULL)
    data.table(Dataset=dataset_id, VisitID=dm$VisitID, Tree=dm$TREE, .plotkey=dm$.plotkey,
               Frame=frame_lookup[as.character(round(dm$EXPF,4))],
               SpeciesCD=map_sp(dm$SP), DBH=dm$DBH, HT=dm$HT, Status=1L)
  }
  t1dt <- build_tree_dt_v2(ti, y1_ok); t2dt <- build_tree_dt_v2(t2, y2_ok)
  t1dt[, Membership := NA_integer_]; if (!is.null(t2dt)) t2dt[, Membership := NA_integer_]

  tdt <- rbindlist(list(t1dt, t2dt))
  ndup <- sum(duplicated(tdt[, .(VisitID, Tree)]))
  if (ndup > 0) {
    tdt[, Tree := seq_len(.N), by = VisitID]
    logmsg(dataset_id, name, "WARNING", sprintf("%d (VisitID,Tree) collisions found in source TREE numbering; renumbered sequentially per visit (TREE is not a stable identity in this source)", ndup))
  }
  tdt[, .plotkey := NULL]
  dbAppendTable(con, "S_Trees", tdt)
  logmsg(dataset_id, name, "INFO", sprintf("inserted %d tree records (t1+t2)", nrow(tdt)))
  logmsg(dataset_id, name, "INFO", "build complete")
  gc()
}
cat("FUNCTIONS_LOADED\n")

MSD2 <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
MSD  <- "/users/PUOM0008/crsfaaron/magplot/verify"
GWS  <- "/users/PUOM0008/crsfaaron/gydb_ws"

sources27 <- list(
  list(id=9,  name="NS",      full="Nova Scotia permanent sample plot network (overall)",
       jur="NS", country="CAN", owner="Not documented in source files",
       pairs=file.path(MSD2,"bench_ns_pairs.csv"), init=file.path(MSD2,"bench_ns_tree_init.csv"),
       t2=file.path(MSD2,"bench_ns_tree_t2.csv"), match_by_year=FALSE),
  list(id=10, name="NS_LONG", full="Nova Scotia permanent sample plot network (long horizon)",
       jur="NS", country="CAN", owner="Not documented in source files",
       pairs=file.path(MSD2,"bench_ns_long_pairs.csv"), init=file.path(MSD2,"bench_ns_long_tree_init.csv"),
       t2=file.path(MSD2,"bench_ns_long_tree_t2.csv"), match_by_year=FALSE),
  list(id=11, name="NB", full="New Brunswick MagPlot network", jur="NB", country="CAN",
       owner="Not documented in source files",
       pairs=file.path(GWS,"magp_nb_pairs.csv"), init=file.path(MSD,"magp_qcnb_tree_init.csv"),
       t2=file.path(MSD,"magp_qcnb_tree_t2.csv"), match_by_year=TRUE),
  list(id=12, name="QC", full="Quebec MagPlot network", jur="QC", country="CAN",
       owner="Not documented in source files",
       pairs=file.path(GWS,"magp_qc_pairs.csv"), init=file.path(MSD,"magp_qcnb_tree_init.csv"),
       t2=file.path(MSD,"magp_qcnb_tree_t2.csv"), match_by_year=TRUE)
)
## NB uses match_by_year=TRUE here for consistency even though it was verified unaffected
## (0 duplicate STANDs, 0 mismatches against declared y1/y2); harmless since the plot key
## degenerates to one row per STAND when there is no repeat, and it keeps one code path.

for (s in sources27) {
  t0 <- Sys.time()
  res <- tryCatch({
    build_source_v2(s$id, s$name, s$full, s$jur, s$country, s$owner, s$pairs, s$init, s$t2, s$match_by_year)
    "OK"
  }, error = function(e) { logmsg(s$id, s$name, "ERROR", conditionMessage(e)); "FAILED" })
  cat(sprintf(">>> %s: %s (%.1fs)\n", s$name, res, as.numeric(Sys.time()-t0, units="secs")))
}

dbExecute(con, "PRAGMA foreign_keys = ON")
fwrite(LOG, "/users/PUOM0008/crsfaaron/gydb_ws/build_log_pass27.csv")
cat("\n=== row counts per table ===\n")
for (tb in c("S_Datasets","S_Designs","S_Frames","S_Blocks","S_Locations","S_Plots","S_Visits","S_Trees")) {
  cat(sprintf("%-16s %d\n", tb, dbGetQuery(con, sprintf("SELECT COUNT(*) n FROM %s", tb))$n))
}
dbDisconnect(con)
cat("PASS27_DONE\n")

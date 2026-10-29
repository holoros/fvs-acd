## PREREG32 step 1b: the five non NB empty t2 stands and the NB t1 sub floor check. Read only, aggregates, no coordinates.
suppressMessages({library(data.table); library(DBI); library(RSQLite)}); options(width = 200)
FR <- "/home/aaron/jobs/v142p19/home/magplot/verify/gydbreg20260916/frames"
DB <- "/home/aaron/jobs/fvsacd_survival/ALL_Standardized.sqlite"
ti <- fread(file.path(FR, "bench_gyr_nb_c_tree_init.csv")); ti[, STAND := as.character(STAND)]
ev <- fread("/home/aaron/jobs/v142p32/assembled/p32-nb-empty-evidence_SERVERONLY_2026-09-30.csv")
x <- ti[STAND %in% ev$STAND]
cat("NB empty stands t1: rows", nrow(x), " rows DBH>=5:", x[DBH >= 5, .N], " stands with any t1 DBH>=5:", uniqueN(x[DBH >= 5, STAND]), " t1 DBH max:", max(x$DBH), "\n")
cat("NB other stands: share of stands whose t1 and t2 rows are all microplot (EXPF 200):")
t2 <- fread(file.path(FR, "bench_gyr_nb_c_tree_t2.csv")); t2[, STAND := as.character(STAND)]
a <- merge(ti[, .(i200 = all(EXPF == 200), imax = max(DBH)), by = STAND], t2[, .(t200 = all(EXPF == 200), tmax = max(DBH)), by = STAND], by = "STAND")
a[, empty := STAND %in% ev$STAND]; print(a[, .(stands = .N, all_micro_t1 = sum(i200), all_micro_t2 = sum(t200), t2max_lt5 = sum(tmax < 5)), by = empty])
con <- dbConnect(SQLite(), DB, flags = SQLITE_RO); q <- function(s) as.data.table(dbGetQuery(con, s))
ds <- q("select Dataset, Name, Owner, OwnerType, License from S_Datasets"); print(ds[, .(Dataset, Name, OwnerType, License)])
keys <- data.table(label = c("medev_c", "medev_c", "mefia_l_c", "mefia_l_c", "ns_long_c"),
  name = c("MEDEV", "MEDEV", "MEFIA_L", "MEFIA_L", "NS_LONG"),
  pk = c("52881240010538", "52983798010538", "52983798010538", "53059331010538", "8216P8216"),
  Y1 = c(2016L, 2007L, 2001L, 2003L, 1982L), Y2 = c(2021L, 2012L, 2022L, 2023L, 1987L))
st <- q("select Status, StatusCode, Live, Dead, Cut from Lookup_Status")
for (i in seq_len(nrow(keys))) { k <- keys[i]; dsid <- ds[Name == k$name, Dataset]
  if (!length(dsid)) { cat(k$label, ": dataset", k$name, "not in GYDB\n"); next }
  pl <- q(sprintf("select PlotID, Plot from S_Plots where Dataset = %d and Plot like '%%%s%%'", dsid, k$pk))
  if (!nrow(pl)) { cat(k$label, k$pk, ": no plot\n"); next }
  vi <- q(sprintf("select PlotID, VisitID, YR, Design from S_Visits where Dataset = %d and PlotID in (%s)", dsid, paste(pl$PlotID, collapse = ",")))
  cat(sprintf("== %s stand %d: plots %d, visit years %s\n", k$label, i, nrow(pl), paste(sort(unique(vi$YR)), collapse = " ")))
  for (yy in c(k$Y1, k$Y2)) { v <- vi[YR == yy]; if (!nrow(v)) { cat("   year", yy, ": no visit\n"); next }
    tr <- q(sprintf("select VisitID, Frame, DBH, Status, Membership, Out from S_Trees where Dataset = %d and VisitID in (%s)", dsid, paste(unique(v$VisitID), collapse = ",")))
    tr <- merge(tr, st, by = "Status", all.x = TRUE)
    cat(sprintf("   year %d: visits %d, tree rows %d, live %d, dead %d, cut %d, live DBH>=5 %d, max DBH %s, status codes %s\n", yy, uniqueN(v$VisitID), nrow(tr),
      tr[Live %in% 1, .N], tr[Dead %in% 1, .N], tr[Cut %in% 1, .N], tr[Live %in% 1 & DBH >= 5, .N], if (nrow(tr)) sprintf("%.1f", max(tr$DBH, na.rm = TRUE)) else "NA",
      paste(tr[, .N, by = .(StatusCode)][, paste0(StatusCode, ":", N)], collapse = " "))) }
  tt <- q(sprintf("select PlotID, YR, Treatment from S_PlotTreatments where Dataset = %d and PlotID in (%s)", dsid, paste(pl$PlotID, collapse = ",")))
  dd <- q(sprintf("select PlotID, YR, Disturbance from S_PlotDisturbances where Dataset = %d and PlotID in (%s)", dsid, paste(pl$PlotID, collapse = ",")))
  cat(sprintf("   treatments in (Y1,Y2]: %d (codes %s); disturbances in (Y1,Y2]: %d (codes %s); any treatment rows %d, any disturbance rows %d\n",
    tt[YR > k$Y1 & YR <= k$Y2, .N], paste(unique(tt[YR > k$Y1 & YR <= k$Y2, Treatment]), collapse = ","), dd[YR > k$Y1 & YR <= k$Y2, .N],
    paste(unique(dd[YR > k$Y1 & YR <= k$Y2, Disturbance]), collapse = ","), nrow(tt), nrow(dd))) }
print(q(sprintf("select Frame, Area, MinDBH, MaxDBH from S_Frames where Dataset = %d", ds[Name == "NB", Dataset])))
xx <- x[DBH >= 5, .(STAND, TREE, DBH1 = DBH)]; m <- merge(xx, t2[, .(STAND, TREE, DBH2 = DBH)], by = c("STAND", "TREE"), all.x = TRUE)
cat("NB t1 stems >= 5 cm in empty stands:", nrow(m), " same TREE id found at t2:", m[!is.na(DBH2), .N], " t2 DBH of those:", paste(sort(m[!is.na(DBH2), DBH2]), collapse = " "), "\n")
## ns_long_c frame
p <- fread(file.path(FR, "bench_gyr_ns_long_c_pairs.csv")); p[, STAND := as.character(STAND)]
s <- "NS_LONG__NS_RS_8216P8216__1982_1987_C"; pp <- p[STAND == s]
cat("ns_long_c frame pair: N_T1", pp$N_T1, "N_T2", pp$N_T2, "BA_T1", pp$BA_T1, "BA_T2", pp$BA_T2, "MANAGED", pp$MANAGED, "LINK_SRC", pp$LINK_SRC, "SCORE_MINDBH", pp$SCORE_MINDBH, "\n")
t2n <- fread(file.path(FR, "bench_gyr_ns_long_c_tree_t2.csv"))[STAND == s]; t1n <- fread(file.path(FR, "bench_gyr_ns_long_c_tree_init.csv"))[STAND == s]
cat("ns_long_c t2 rows", nrow(t2n), " max DBH", if (nrow(t2n)) max(t2n$DBH) else NA, " EXPF", paste(unique(round(t2n$EXPF, 2)), collapse = ","), "; t1 rows", nrow(t1n), " t1 DBH>=", pp$SCORE_MINDBH, ":", t1n[DBH >= pp$SCORE_MINDBH, .N], "\n")
dbDisconnect(con); cat("P32_AUDIT2_DONE\n")

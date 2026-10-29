## PREREG32 step 1c: the two medev_c empty t2 stands via the FIA remeasurement chain. ME_PLOT read with CN, PREV_PLT_CN, MEASYEAR only (no coordinates).
suppressMessages({library(data.table); library(DBI); library(RSQLite)}); options(width = 200)
fp <- fread("/home/aaron/jobs/v142p29/in/fia_data/ME_PLOT.csv", select = c("CN", "PREV_PLT_CN", "MEASYEAR"), colClasses = list(character = c("CN", "PREV_PLT_CN")))
fp[PREV_PLT_CN %in% c("", "NA"), PREV_PLT_CN := NA_character_]; par <- setNames(fp$PREV_PLT_CN, fp$CN); par[!(par %in% fp$CN)] <- NA_character_
root <- function(cn) { out <- cn; for (i in 1:30) { p <- par[out]; nx <- !is.na(p); if (!any(nx)) break; out[nx] <- p[nx] }; unname(out) }
fp[, ROOT := root(CN)]
con <- dbConnect(SQLite(), "/home/aaron/jobs/fvsacd_survival/ALL_Standardized.sqlite", flags = SQLITE_RO); q <- function(s) as.data.table(dbGetQuery(con, s))
st <- q("select Status, StatusCode, Live, Dead, Cut from Lookup_Status")
for (k in list(list("52881240010538", 2016L, 2021L), list("52983798010538", 2007L, 2012L))) {
  ch <- fp[ROOT == k[[1]]][order(MEASYEAR)]; cat(sprintf("== medev_c root chain: %d CNs, years %s\n", nrow(ch), paste(ch$MEASYEAR, collapse = " ")))
  for (ds in c(7L, 6L)) { pl <- q(sprintf("select PlotID, Plot from S_Plots where Dataset = %d and Plot in (%s)", ds, paste0("'MEM_", ch$CN, "'", collapse = ",")))
    if (!nrow(pl)) next
    vi <- q(sprintf("select PlotID, VisitID, YR from S_Visits where Dataset = %d and PlotID in (%s)", ds, paste(pl$PlotID, collapse = ",")))
    cat(sprintf("   dataset %d: plots %d visits years %s\n", ds, nrow(pl), paste(sort(vi$YR), collapse = " ")))
    for (yy in c(k[[2]], k[[3]])) { v <- vi[YR == yy]; if (!nrow(v)) { cat("   year", yy, "no visit\n"); next }
      tr <- merge(q(sprintf("select VisitID, DBH, Status from S_Trees where Dataset = %d and VisitID in (%s)", ds, paste(unique(v$VisitID), collapse = ","))), st, by = "Status", all.x = TRUE)
      cat(sprintf("   year %d: visits %d rows %d live %d dead %d cut %d live DBH>=5 %d max DBH %s\n", yy, uniqueN(v$VisitID), nrow(tr), tr[Live %in% 1, .N], tr[Dead %in% 1, .N], tr[Cut %in% 1, .N],
        tr[Live %in% 1 & DBH >= 5, .N], if (nrow(tr)) sprintf("%.1f", max(tr$DBH)) else "NA")) }
    tt <- q(sprintf("select YR, Treatment from S_PlotTreatments where Dataset = %d and PlotID in (%s)", ds, paste(pl$PlotID, collapse = ",")))
    dd <- q(sprintf("select YR, Disturbance from S_PlotDisturbances where Dataset = %d and PlotID in (%s)", ds, paste(pl$PlotID, collapse = ",")))
    cat(sprintf("   treatment rows %d, in (Y1,Y2] %d; disturbance rows %d, in (Y1,Y2] %d\n", nrow(tt), tt[YR > k[[2]] & YR <= k[[3]], .N], nrow(dd), dd[YR > k[[2]] & YR <= k[[3]], .N])) } }
dbDisconnect(con); cat("P32_AUDIT3_DONE\n")

# Read Ben Rice's FIA benchmarking database (AcdFiaBench.db) into start and end tree lists.
# Follows acdR_example.R (Johnson 2024) for expansion factors and CSI; keeps live trees only
# (HISTORY == 1), which the example script did not filter.

acd7_bench_pairs <- function(db) {
  sel <- DBI::dbGetQuery(db, "select * from FiaSelectedPlots where MeasurePeriod > 0")
  sel <- unique(sel[, c("UnitCountyPlot", "TrtPeriod", "MeasurePeriod")])
  si <- DBI::dbGetQuery(db, "select Stand_CN, UnitCountyPlot, TrtPeriod, Inv_Year, CSI, ElevFt, Basal_Area_Factor,
                             Inv_Plot_Size, Brk_DBH, Num_Plots, Age, State from FVS_StandInit")
  si$UnitCountyPlot <- trimws(si$UnitCountyPlot)
  sel$UnitCountyPlot <- trimws(sel$UnitCountyPlot)
  m <- merge(sel, si, by = c("UnitCountyPlot", "TrtPeriod"))
  m <- m[order(m$UnitCountyPlot, m$TrtPeriod, m$Inv_Year), ]
  sp <- split(m, paste(m$UnitCountyPlot, m$TrtPeriod))
  pairs <- do.call(rbind, lapply(sp, function(d) if (nrow(d) >= 2)
    data.frame(key = paste(d$UnitCountyPlot[1], d$TrtPeriod[1]), TrtPeriod = d$TrtPeriod[1], State = d$State[1],
               start_cn = d$Stand_CN[1], end_cn = d$Stand_CN[nrow(d)],
               years = d$Inv_Year[nrow(d)] - d$Inv_Year[1], CSI = d$CSI[1], ElevFt = d$ElevFt[1],
               Age = d$Age[1], stringsAsFactors = FALSE)))
  rownames(pairs) <- NULL
  pairs[pairs$years > 0, ]
}

acd7_bench_trees <- function(db, cn) {
  s <- DBI::dbGetQuery(db, sprintf("select * from FVS_StandInit where Stand_CN = '%s'", cn))[1, ]
  t <- DBI::dbGetQuery(db, sprintf("select Plot_ID, Tree_ID, SPECIES, DBH, HT, CRRATIO, TREE_COUNT, HISTORY
                                    from FVS_TreeInit where Stand_CN = '%s'", cn))
  t <- t[!is.na(t$HISTORY) & t$HISTORY == 1 & !is.na(t$DBH) & t$DBH > 0, ]
  baf <- ifelse(s$Basal_Area_Factor == 0, 1, -s$Basal_Area_Factor)
  t$tpa <- t$TREE_COUNT * ifelse(t$DBH < s$Brk_DBH & s$Brk_DBH != 999, s$Inv_Plot_Size, baf) / s$Num_Plots
  t$HT <- ifelse(is.na(t$HT), 0, t$HT)
  t$cr <- ifelse(!is.na(t$CRRATIO), t$CRRATIO / 100, 0)
  t$SPECIES <- as.integer(t$SPECIES)
  t
}

# stand summaries in the units Greg reported (ft2/ac, trees/ac, inches, feet)
acd7_stand_sum <- function(dbh, ht, tpa) {
  ba <- sum(0.005454154 * dbh^2 * tpa); n <- sum(tpa)
  c(ba = ba, tpa = n, qmd = if (n > 0) sqrt(ba / n / 0.005454154) else NA,
    mht = if (n > 0) sum(ht * tpa) / n else NA)
}

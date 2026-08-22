## load_plot_treatments_pass24.R
## Pass 24 follow-on to build_gydb.R: loads S_PlotTreatments (0 rows going in).
## CTRN: fixes column mismatch (generic builder looked for YR, file has TRT_YR).
## PEF: bench_pef_treatments.csv carries no year column at all. Resolved by joining the real
##      PEF_CompartmentStudy_ActivityDates_TRMT.csv (compartment/MU-level harvest and cultural-
##      treatment dates, referencing StudyPlan1953/1960/1974/2008, range 1952-2024) against each
##      interval-STAND's own measured t1/t2 calendar years (from bench_pef_tree_init/t2.csv).
##      A documented harvest/thinning year is kept as a treatment record when it falls in
##      [t1_year, t2_year] inclusive -- inclusive of t1 because PEF establishment/re-entry cuts
##      are frequently the same year as the inventory that opens the following remeasurement
##      interval. Sanity-checked: 0/152 "Reference (unmanaged)" STAND-intervals matched (correct,
##      those compartments carry no harvest history), and match rate scales with cutting-cycle
##      frequency (Selection 5-yr cycle 139/205=68% vs Selection 20-yr cycle 69/393=18%), which is
##      the expected biological pattern, not an artifact.
## Does not touch S_Visits, S_Trees, or any table besides S_PlotTreatments.

.libPaths(c("~/R/rhel9/4.5.2", "~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5",.libPaths()))
suppressMessages({ library(RSQLite); library(DBI); library(data.table) })

DB   <- "/users/PUOM0008/crsfaaron/gydb_ws/data/ALL/ALL_Standardized.sqlite"
MSD  <- "/users/PUOM0008/crsfaaron/magplot/verify/multisrc"
SUPP <- "/users/PUOM0008/crsfaaron/HRF/sae-follow-on/pef/data/rds/Supplements"

con <- dbConnect(RSQLite::SQLite(), DB)
dbExecute(con, "PRAGMA foreign_keys = ON;")

before <- dbGetQuery(con, "SELECT COUNT(*) n FROM S_PlotTreatments")$n
cat("BEFORE total S_PlotTreatments rows:", before, "\n")

empty_dt <- function() data.table(Dataset=integer(0), PlotID=integer(0), YR=integer(0),
                                   Treatment=integer(0), Severity=integer(0), FuzzyYR=logical(0))

## ---------------- CTRN (Dataset=3) ----------------
ctrn_plots <- dbGetQuery(con, "SELECT PlotID, Plot FROM S_Plots WHERE Dataset=3")
plot_id_ctrn <- setNames(ctrn_plots$PlotID, ctrn_plots$Plot)

treat_ctrn <- fread(file.path(MSD, "bench_ctrn_treatments.csv"), colClasses="character")
n_ctrn_total <- nrow(treat_ctrn)
n_ctrn_blank <- sum(is.na(treat_ctrn$TRT_YR) | trimws(treat_ctrn$TRT_YR) == "")
n_ctrn_nonblank <- n_ctrn_total - n_ctrn_blank
cat(sprintf("CTRN treatments file: %d rows total, %d with non-blank TRT_YR, %d blank\n",
            n_ctrn_total, n_ctrn_nonblank, n_ctrn_blank))

n_ctrn_stand_match <- sum(treat_ctrn$STAND %in% names(plot_id_ctrn))
cat(sprintf("CTRN STAND join check: %d / %d treatment rows have a matching S_Plots.Plot (Dataset=3)\n",
            n_ctrn_stand_match, n_ctrn_total))

treat_ctrn <- treat_ctrn[STAND %in% names(plot_id_ctrn)]
treat_ctrn[, YR := suppressWarnings(as.integer(TRT_YR))]
treat_ctrn <- treat_ctrn[is.finite(YR)]
if (nrow(treat_ctrn) == 0) {
  ctrn_dt <- empty_dt()
} else {
  ctrn_dt <- data.table(Dataset = 3L, PlotID = unname(plot_id_ctrn[treat_ctrn$STAND]),
                         YR = treat_ctrn$YR, Treatment = 99L,
                         Severity = NA_integer_, FuzzyYR = NA)
  ctrn_dt <- unique(ctrn_dt, by = c("Dataset","PlotID","YR","Treatment"))
}
cat("CTRN rows resolved and ready to insert:", nrow(ctrn_dt), "\n")

## ---------------- PEF (Dataset=4) ----------------
pef_treat <- fread(file.path(MSD, "bench_pef_treatments.csv"))     # STAND, MU, TREATMENT, interval_years
pef_ti    <- fread(file.path(MSD, "bench_pef_tree_init.csv"))      # STAND,...,YEAR (t1 calendar year)
pef_t2    <- fread(file.path(MSD, "bench_pef_tree_t2.csv"))        # STAND,...,YEAR (t2 calendar year)

y1 <- pef_ti[, .(y1 = suppressWarnings(min(YEAR, na.rm=TRUE))), by = STAND]
y2 <- pef_t2[, .(y2 = suppressWarnings(min(YEAR, na.rm=TRUE))), by = STAND]
pef_int <- merge(unique(pef_treat[, .(STAND, MU)]), y1, by = "STAND", all.x = TRUE)
pef_int <- merge(pef_int, y2, by = "STAND", all.x = TRUE)
n_pef_stand_total <- nrow(pef_int)
pef_int <- pef_int[is.finite(y1) & is.finite(y2)]
pef_int[, MU := trimws(as.character(MU))]
cat(sprintf("PEF interval-STANDs with resolvable t1/t2 calendar years: %d / %d\n",
            nrow(pef_int), n_pef_stand_total))

trmt <- fread(file.path(SUPP, "PEF_CompartmentStudy_ActivityDates_TRMT.csv"))
trmt[, MU := trimws(as.character(MU))]
trmt[, removal := Activity == "Harvest" | (Activity == "Cultural Treatment" & grepl("thin", Type, ignore.case=TRUE))]
rem <- trmt[removal == TRUE, .(MU, ryear = as.integer(Year))]
rem <- rem[is.finite(ryear)]
cat(sprintf("PEF_CompartmentStudy_ActivityDates_TRMT.csv: %d activity rows, %d flagged as harvest/thinning removal events across %d compartments (MU), year range %d-%d\n",
            nrow(trmt), nrow(rem), uniqueN(rem$MU), min(rem$ryear), max(rem$ryear)))

setkey(rem, MU)
pef_rows <- pef_int[, {
  rr <- rem[MU == .BY$MU]
  yrs <- rr$ryear[rr$ryear >= y1 & rr$ryear <= y2]
  if (length(yrs) == 0) NULL else data.table(YR = unique(yrs))
}, by = .(STAND, MU)]
if (is.null(pef_rows) || nrow(pef_rows) == 0) pef_rows <- data.table(STAND=character(0), MU=character(0), YR=integer(0))
cat(sprintf("PEF interval-STANDs with >=1 documented harvest/thinning year inside [t1,t2]: %d / %d\n",
            uniqueN(pef_rows$STAND), nrow(pef_int)))

pef_plots <- dbGetQuery(con, "SELECT PlotID, Plot FROM S_Plots WHERE Dataset=4")
plot_id_pef <- setNames(pef_plots$PlotID, pef_plots$Plot)
pef_rows <- pef_rows[STAND %in% names(plot_id_pef)]
if (nrow(pef_rows) == 0) {
  pef_dt <- empty_dt()
} else {
  pef_dt <- data.table(Dataset = 4L, PlotID = unname(plot_id_pef[pef_rows$STAND]),
                        YR = pef_rows$YR, Treatment = 99L,
                        Severity = NA_integer_, FuzzyYR = NA)
  pef_dt <- unique(pef_dt, by = c("Dataset","PlotID","YR","Treatment"))
}
cat("PEF rows resolved from ActivityDates_TRMT join and ready to insert:", nrow(pef_dt), "\n")

## ---------------- append ----------------
all_dt <- rbindlist(list(ctrn_dt, pef_dt), use.names = TRUE)
cat("Total rows to append across both sources:", nrow(all_dt), "\n")
if (nrow(all_dt) > 0) dbAppendTable(con, "S_PlotTreatments", all_dt)

after <- dbGetQuery(con, "SELECT COUNT(*) n FROM S_PlotTreatments")$n
cat("AFTER total S_PlotTreatments rows:", after, "\n")
print(dbGetQuery(con, "SELECT Dataset, COUNT(*) n FROM S_PlotTreatments GROUP BY Dataset"))

cat("\n--- spot check: 5 CTRN rows (Dataset=3) joined to Plot/YR/Treatment ---\n")
print(dbGetQuery(con, "SELECT t.Dataset, t.PlotID, p.Plot, t.YR, t.Treatment, lt.Description
                        FROM S_PlotTreatments t
                        JOIN S_Plots p ON p.Dataset=t.Dataset AND p.PlotID=t.PlotID
                        JOIN Lookup_Treatment lt ON lt.Treatment=t.Treatment
                        WHERE t.Dataset=3 LIMIT 5"))

cat("\n--- spot check: 5 PEF rows (Dataset=4) joined to Plot/YR/Treatment ---\n")
print(dbGetQuery(con, "SELECT t.Dataset, t.PlotID, p.Plot, t.YR, t.Treatment, lt.Description
                        FROM S_PlotTreatments t
                        JOIN S_Plots p ON p.Dataset=t.Dataset AND p.PlotID=t.PlotID
                        JOIN Lookup_Treatment lt ON lt.Treatment=t.Treatment
                        WHERE t.Dataset=4 LIMIT 5"))

dbDisconnect(con)
cat("\nDONE\n")

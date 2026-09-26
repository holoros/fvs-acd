# build_v32st_xlsx.R, September 26, 2026. Adds the stress test sheets to the shipped v32 workbook (ship/),
# plus a Changelog row and Version lines. No existing cell value changes otherwise. Helpers copied from build_v32_xlsx.R.
suppressPackageStartupMessages(library(openxlsx))
B    <- Sys.getenv("V32_BASE", file.path(path.expand("~"), "jobs", "silc_v32_docbuild"))
V29  <- file.path(B, "ship", "SILC_Benchmark_DataTables_v32.xlsx")
OUT  <- file.path(B, "out", "SILC_Benchmark_DataTables_v32.xlsx")
wb <- loadWorkbook(V29); n0 <- length(names(wb)); cat("loaded v29 workbook,", n0, "sheets\n")
hdrStyle <- createStyle(fontName="Calibri", fontSize=11, textDecoration="bold", halign="center", valign="center",
  wrapText=TRUE, border="TopBottom", borderStyle="thin", borderColour="black")
bodyStyle <- createStyle(fontName="Calibri", fontSize=11, halign="center", valign="center", wrapText=TRUE)
lastStyle <- createStyle(fontName="Calibri", fontSize=11, halign="center", valign="center", wrapText=TRUE,
  border="bottom", borderStyle="thin", borderColour="black")
noteStyle <- createStyle(fontName="Calibri", fontSize=11, textDecoration="bold", fontColour="#8B0000",
  halign="left", valign="center", wrapText=TRUE)
wrapped_row_heights <- function(df, colwidths, line_pt=13.5, min_pt=15) vapply(seq_len(nrow(df)), function(i) {
  lines <- vapply(seq_along(colwidths), function(j) { txt <- as.character(df[i, j]); if (is.na(txt)) return(1L)
    as.integer(max(1, ceiling(nchar(txt)/max(6, colwidths[j]-2)))) }, integer(1)); max(min_pt, max(lines)*line_pt) }, numeric(1))
add_sheet <- function(name, note, df, colwidths=NULL, wrap_rows=FALSE) {
  if (name %in% names(wb)) removeWorksheet(wb, name)
  addWorksheet(wb, name); r0 <- 1L
  if (!is.null(note) && nzchar(note)) { writeData(wb, name, note, startRow=1, startCol=1)
    addStyle(wb, name, noteStyle, rows=1, cols=1); mergeCells(wb, name, cols=1:max(4, min(ncol(df), 10)), rows=1)
    setRowHeights(wb, name, rows=1, heights=max(30, 13.5*ceiling(nchar(note)/100))); r0 <- 2L }
  writeData(wb, name, df, startRow=r0, startCol=1, headerStyle=hdrStyle)
  nr <- nrow(df); nc <- ncol(df)
  if (nr > 0) { addStyle(wb, name, bodyStyle, rows=(r0+1L):(r0+nr), cols=1:nc, gridExpand=TRUE)
    addStyle(wb, name, lastStyle, rows=r0+nr, cols=1:nc, gridExpand=TRUE) }
  if (is.null(colwidths)) colwidths <- pmin(40, pmax(10, nchar(names(df)) + 2))
  setColWidths(wb, name, cols=1:nc, widths=colwidths)
  if (isTRUE(wrap_rows) && nr > 0) setRowHeights(wb, name, rows=(r0+1L):(r0+nr), heights=wrapped_row_heights(df, colwidths))
  freezePane(wb, name, firstActiveRow=r0+1L)
  if (name != "Changelog") pageSetup(wb, sheet=name, orientation="landscape", fitToWidth=TRUE, fitToHeight=FALSE)
  cat("new sheet", name, nr, "x", nc, "\n") }
rs <- function(p) read.csv(file.path(B, "v32st", p), check.names=FALSE, stringsAsFactors=FALSE)
N1 <- "Stress test, September 26, 2026. Gross volume bias and R2 by plot screen. refined_n51 excludes the 13 removal plots and 1133; no_ftm_n63 excludes 1150 and 1178 (first measurement heights recorded in feet); refined_no_ftm_n49 excludes both sets."
add_sheet("V32ST_StateByScreen", N1, rs("v32st_state_by_screen_DATA_2026-09-26.csv"), colwidths=c(22,30,8,14,12,14,12))
N2 <- "Stress test. Measured height rows with plots 1150 and 1178 scored on the imputed height run (AGM: v8.36), all 65 routine plots."
add_sheet("V32ST_FeetRecordsCorrected", N2, rs("v32st_state_patched_ftm_DATA_2026-09-26.csv"), colwidths=c(30,8,14,12,14,12))
N3 <- "Stress test. Growth rate bias by screen. mean_net_stem_loss_tpa_yr is the mean net change in trees per acre per year; positive values are a net GAIN (ingrowth exceeds mortality), despite the column name."
add_sheet("V32ST_RatesByScreen", N3, rs("v32st_rates_by_screen_DATA_2026-09-26.csv"), colwidths=c(22,30,8,14,14,14,14,28))
N4 <- "Stress test. Paired plot bootstrap, 5,000 resamples, seed 20260926. diff is the bias of a minus the bias of b, in percent of the observed mean."
add_sheet("V32ST_Bootstrap", N4, rs("v32st_bootstrap_DATA_2026-09-26.csv"), colwidths=c(16,14,30,30,8,10,10,10))
N5 <- "Stress test. Trees with a measured first height, classed by first height to diameter ratio and by the ratio of projected second measurement height (measured start) to the imputed start run."
add_sheet("V32ST_StartHeightClasses", N5, rs("v32st_t1_height_class_summary_DATA_2026-09-26.csv"), colwidths=c(36,12,10,26,26,24))
chg_old <- readWorkbook(wb, "Changelog")
newrow <- data.frame(Version="v32 (revised)", Date="September 26, 2026", Entry=paste0(
  "Stress test added in five sheets: V32ST_StateByScreen, V32ST_FeetRecordsCorrected, V32ST_RatesByScreen, V32ST_Bootstrap, ",
  "V32ST_StartHeightClasses. Withdraws the September 23 reading that AGM's remaining defect is basal area growth (removal artifact; ",
  "on 51 screened plots AGM v8.40 is -9.5 percent on BA increment and +0.7 on volume increment). Flags 18 first measurement heights ",
  "recorded in feet on plots 1150 and 1178; correcting them lowers each measured height row about 2 points. Net stem change in ",
  "V32_HeightFactorial_Rates is a net gain, not a loss. No existing sheet value changes and nothing is removed."), stringsAsFactors=FALSE)
names(newrow) <- names(chg_old)
add_sheet("Changelog", NULL, rbind(newrow, chg_old), colwidths=c(24, 22, 108), wrap_rows=TRUE)
writeData(wb, "Version", "2026-09-23, revised 2026-09-26 (stress test), built on v29 of 2026-09-08, revised 2026-09-09 and 2026-09-16", startRow=4, startCol=2)
writeData(wb, "Version", c("Revised September 26, 2026", "5 stress test sheets added (V32ST_*), sources v32st/*_DATA_2026-09-26.csv from Cardinal silc_cfi/v32_stresstest. No sheet above this point changed."), startRow=27, startCol=1, colNames=FALSE)
OUT <- file.path(B, "out", "SILC_Benchmark_DataTables_v32.xlsx")
saveWorkbook(wb, OUT, overwrite=TRUE)
cat("saved", OUT, "sheets", length(names(wb)), "(was", n0, ")\n")
st <- system2("python3", c(shQuote(file.path(B, "fix_xlsx_worksheet_dup_tag.py")), shQuote(OUT)), stdout=TRUE, stderr=TRUE)
cat(st, sep="\n")

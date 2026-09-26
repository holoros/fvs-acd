# build_v32st3_xlsx.R, September 26, 2026 (third change). Records the 14.1 ten-year draft pick in the workbook in ship/,
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
rs <- function(p) read.csv(file.path(B, "v33", p), check.names=FALSE, stringsAsFactors=FALSE)
add_sheet("V33_PickCheck", "Draft pick check, September 26, 2026: FVS-ACD 14.1 replaces v14 L2 as the ten-year draft pick. Paired plot bootstrap of 14.1 against v13.1 hierarchical and v14 L2; diff in percent of the observed mean.", rs("v33st_pick_bootstrap_DATA_2026-09-26.csv"), colwidths=c(14,14,26,26,6,8,8,8))
chg_old <- readWorkbook(wb, "Changelog")
newrow <- data.frame(Version="v32 (revised, pick)", Date="September 26, 2026", Entry=paste0(
  "Draft pick decision: FVS-ACD 14.1 replaces v14 L2 as the ten-year draft pick; v13.1 hierarchical stays the long-horizon pick. ",
  "14.1 is 2.7 points (2.2 to 3.2) closer to observed than v14 L2 on the 51 screened plots and 6.7 points (5.2 to 8.2) below v13.1 hierarchical there. ",
  "Its SILC limitation: basal area increment -54.4 percent on screened plots. Sheet V33_PickCheck added. No existing sheet value changes."), stringsAsFactors=FALSE)
names(newrow) <- names(chg_old)
add_sheet("Changelog", NULL, rbind(newrow, chg_old), colwidths=c(24, 22, 108), wrap_rows=TRUE)
writeData(wb, "Version", c("Draft pick, September 26, 2026", "FVS-ACD 14.1 is the ten-year draft pick (replacing v14 L2); v13.1 hierarchical the long-horizon pick. Sheet V33_PickCheck."), startRow=33, startCol=1, colNames=FALSE)
OUT <- file.path(B, "out", "SILC_Benchmark_DataTables_v32.xlsx")
saveWorkbook(wb, OUT, overwrite=TRUE)
cat("saved", OUT, "sheets", length(names(wb)), "(was", n0, ")\n")
st <- system2("python3", c(shQuote(file.path(B, "fix_xlsx_worksheet_dup_tag.py")), shQuote(OUT)), stdout=TRUE, stderr=TRUE)
cat(st, sep="\n")

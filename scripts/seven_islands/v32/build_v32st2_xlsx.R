# build_v32st2_xlsx.R, September 26, 2026 (second addition). Adds the FVS-ACD 14.1 sheets to the workbook in ship/,
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
sc <- rs("silc_cfi_v33_scorecard_primary_DATA_2026-09-26.csv"); sc <- sc[grepl("14.0.4|14.1|v14 L2 \\(full137\\)", sc$model), ]
add_sheet("V33_v141_State", "FVS-ACD 14.0.4 and 14.1 on the 65 routine plots, primary specification, with the v14.0 L2 (full137) row for the bridge. 14.1 here is 14.0.4 plus the level term L; no SILC stand has a thinning year, so the release term T is the identity.", sc, colwidths=c(42,10,6,rep(11,ncol(sc)-3)))
sl <- rs("silc_cfi_v33_scorecard_specliteral_DATA_2026-09-26.csv"); sl <- sl[grepl("14.0.4|14.1", sl$model), ]
add_sheet("V33_v141_SpecLit", "FVS-ACD 14.0.4 and 14.1, specification-literal reading.", sl, colwidths=c(42,10,6,rep(11,ncol(sl)-3)))
ra <- rs("silc_cfi_rates_scorecard_v33_DATA_2026-09-26.csv"); ra <- ra[grepl("v141|v1404", ra$config), setdiff(names(ra), c("rank_state_bias","rank_rate_bias","shift_bias","rank_state_R2","rank_rate_R2","shift_R2","state_gross4_bias","state_gross4_R2","in_state_scorecard"))]
add_sheet("V33_v141_Rates", "FVS-ACD 14.0.4 and 14.1 growth rates, all 65 routine plots. netstem is a net change (observed is a net gain). Imputed rows carry unmatched volume increments.", ra, colwidths=c(42,24,6,rep(12,ncol(ra)-3)))
add_sheet("V33_v141_ByScreen", "Stress test. Gross volume and value bias by plot screen (refined_n51 excludes 13 removal plots and 1133; no_ftm_n63 excludes 1150 and 1178).", rs("v33st_state_by_screen_DATA_2026-09-26.csv"), colwidths=c(22,30,8,14,12,14,12))
add_sheet("V33_v141_RatesByScreen", "Stress test. Growth rates by screen; mean_net_stem_change_tpa_yr positive is a net gain.", rs("v33st_rates_by_screen_DATA_2026-09-26.csv"), colwidths=c(22,30,8,14,14,14,14,18,32))
add_sheet("V33_v141_Bootstrap", "Stress test. Paired plot bootstrap, 5,000 resamples, seed 20260926; diff is the bias of a minus the bias of b, in percent of the observed mean.", rs("v33st_bootstrap_DATA_2026-09-26.csv"), colwidths=c(16,14,30,30,8,10,10,10))
add_sheet("V33_v141_Leffect", "Gross volume per plot, 14.1 minus 14.0.4 (cd ac-1), measured heights. L raises every plot.", rs("v33st_L_effect_by_plot_DATA_2026-09-26.csv"))
chg_old <- readWorkbook(wb, "Changelog")
newrow <- data.frame(Version="v32 (revised, 14.1)", Date="September 26, 2026", Entry=paste0(
  "FVS-ACD 14.1 and 14.0.4 added in seven sheets (V33_v141_*), runs on Cardinal silc_cfi/v33_v141 (array 14920440, scoring 14920449, ",
  "stress test 14920570). 14.0.4 reproduces v14.0 L2 within 0.4 points; 14.1 adds 2.7 points (+6.6 percent all 65, -6.8 screened 51). ",
  "Feet records repaired in a real rerun lower both engines 1.7 points. No existing sheet value changes and nothing is removed."), stringsAsFactors=FALSE)
names(newrow) <- names(chg_old)
add_sheet("Changelog", NULL, rbind(newrow, chg_old), colwidths=c(24, 22, 108), wrap_rows=TRUE)
writeData(wb, "Version", c("Revised again September 26, 2026", "7 FVS-ACD 14.1 sheets added (V33_v141_*), sources v33/*_DATA_2026-09-26.csv from Cardinal silc_cfi/v33_v141. No sheet above this point changed."), startRow=30, startCol=1, colNames=FALSE)
OUT <- file.path(B, "out", "SILC_Benchmark_DataTables_v32.xlsx")
saveWorkbook(wb, OUT, overwrite=TRUE)
cat("saved", OUT, "sheets", length(names(wb)), "(was", n0, ")\n")
st <- system2("python3", c(shQuote(file.path(B, "fix_xlsx_worksheet_dup_tag.py")), shQuote(OUT)), stdout=TRUE, stderr=TRUE)
cat(st, sep="\n")

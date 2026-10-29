## PREREG48 assembly (plan revision 1, md5 61ab907e): applies the registered decision rule, in order, to the step 2 gate
## table and copies the identifier free tables into assembled/. Rules 2 to 4 are read per arm (attribution gates are per arm);
## rule 5 marks the outcome conditional on the height form when AR fails. The rule 2 sub clause (observed annual survival
## rising with interval while predicted stays flat) has no registered threshold and is reported descriptively from the
## PREREG27 table bins with 30 or more t1 trees. Refuses to overwrite. No coordinates. No em dashes.
## Usage: Rscript p48_assemble.R <indir> <outdir>
suppressMessages(library(data.table))
args <- commandArgs(TRUE); IND <- args[1]; OUTD <- args[2]
J <- "/home/aaron/jobs/v142p48"; DT <- "2026-10-26"
if (unname(tools::md5sum(file.path(J, "plan/2026-10-26_v142_qc-stems-deficit_PREREG48.md"))) != "61ab907e7be70cac0e68264586e9ebec") stop("plan md5 differs")
if (dir.exists(OUTD) && length(list.files(OUTD))) stop("REFUSE ", OUTD, " not empty"); dir.create(OUTD, recursive = TRUE, showWarnings = FALSE)
GT <- fread(file.path(IND, "p48-gates.csv")); SH <- fread(file.path(IND, "p48-shares.csv")); TB <- fread(file.path(IND, "p48-p27-tables.csv"))
for (n in c("p48-gates.csv", "p48-shares.csv", "p48-p27-tables.csv", "p48-T0.csv", "p48-T1-coverage.csv", "p48-T2-crosscheck.csv", "p48-floor.csv", "p48-input-md5.csv")) {
  f <- file.path(OUTD, sprintf("gyr142-p48-%s_DATA_%s.csv", sub("^p48-(.*)\\.csv$", "\\1", n), DT)); if (file.exists(f)) stop("REFUSE ", f); file.copy(file.path(IND, n), f) }
pg <- function(gt, a = NULL) { x <- GT[gate == gt]; if (!is.null(a)) x <- x[arm == a]; if (nrow(x) < 1) stop("gate missing ", gt); all(x$pass) }
V <- character(0)
harness <- c(T0 = pg("T0"), T1 = pg("T1"), T2 = pg("T2"), T3 = pg("T3"), T4 = pg("T4"))
if (!all(harness)) {
  cov <- fread(file.path(IND, "p48-T1-coverage.csv"))[cut == FALSE & fold == "B"]
  V <- c(V, sprintf("Rule 1: harness failure, no attribution. Failing gate(s): %s. Coverage: %d of %d screened fold B stands covered; T4 value %s.",
    paste(names(harness)[!harness], collapse = ", "), cov$covered, cov$stands, GT[gate == "T4"]$value))
} else {
  ar <- pg("AR"); out <- list()
  for (a in c("qc141", "qc_rh")) {
    tb <- TB[fold == "B" & arm == a & ivc != "all" & reported_bin == TRUE][order(ivc)]
    pat <- if (nrow(tb) >= 2) sprintf("observed annual survival %s across %d bins (%s); predicted %s",
      if (tb$ann_surv_o[nrow(tb)] > tb$ann_surv_o[1]) "rises" else "does not rise", nrow(tb), paste(sprintf("%.4f", tb$ann_surv_o), collapse = ", "), paste(sprintf("%.4f", tb$ann_surv_p), collapse = ", ")) else "fewer than two reported interval bins"
    out[[a]] <- if (pg("A_S", a) && pg("SR", a)) sprintf("Rule 2, 14.3 mortality track (%s)", pat) else if (pg("A_I", a)) "Rule 3, 14.3 ingrowth track" else "Rule 4, mixed deficit, no track named" }
  for (a in names(out)) V <- c(V, sprintf("%s: %s.", a, out[[a]]))
  r1 <- sub(" \\(.*$", "", out[["qc141"]]); r2 <- sub(" \\(.*$", "", out[["qc_rh"]])
  if (!ar) V <- c(V, "Rule 5: AR fails, the outcome is conditional on the height form and the split is reported per arm.")
  else V <- c(V, if (r1 == r2) sprintf("AR passes; both arms read %s.", r1) else "AR passes but the arms read different rules; both are reported (the plan does not order this case).")
}
V <- c(V, "No outcome changes 14.2.")
f <- file.path(OUTD, sprintf("gyr142-p48-verdict_DATA_%s.txt", DT)); writeLines(V, f); cat(V, sep = "\n")
cat("P48_ASSEMBLE_DONE\n")

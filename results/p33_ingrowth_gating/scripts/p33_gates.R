# p33_gates.R -- pass 33 pre-registered gates over the probe battery outputs.
# Run from ~/magplot/verify. Exits nonzero on any hard-gate failure (G1, G2).
# G1 cross-layer: ctrn h1check trajectory byte-identical to pass 32 bakuzis_h1 output.
# G2 value range: BA in (0,80] m2/ha, QMD in (0,60] cm, VOL in [0,700] m3/ha, all finite.
#    Bounds external to this run: regional Acadian maxima (dense spruce-fir BA < 80,
#    NSVB merchantable-stem volumes well under 700 m3/ha in these stand types).
# G3 pre-crash inertness: matgate vs h1 VOL at ages <= 40 within 2 pct at every source
#    (the lever multiplies a release factor that is ~0 at high RD, so it must be inert there).
# G4 objective (reported, not pass/fail): VOL site-ordering inversion counts h1 vs noing vs
#    matgate per source, read from the bakuzis check reports.
# G5 anti-shutoff: matgate must differ from noing somewhere (a gate bug driving g~0 would
#    mimic noing exactly and otherwise look like a clean win).
suppressMessages(library(data.table))
P33 <- "~/magplot/verify/bakuzis_p33"; H1 <- "~/magplot/verify/bakuzis_h1"
srcs <- c("ctrn","nb","qc","ns","memat","mefia_l")
fail <- character(0)

## G1
a <- tools::md5sum(path.expand(file.path(P33,"ctrn_h1check_traj.csv")))
b <- tools::md5sum(path.expand(file.path(H1,"ctrn_h1default_traj.csv")))
if (is.na(a) || is.na(b) || a != b) fail <- c(fail, sprintf("G1 FAIL: h1check md5 %s vs pass32 %s", a, b)) else cat("G1 PASS: h1check byte-identical to pass 32\n")

## G2 over all probe trajectories
for (f in list.files(path.expand(P33), pattern="_traj\\.csv$", full.names=TRUE)) {
  d <- fread(f)
  bad <- d[!is.finite(BAPH) | !is.finite(VOL) | !is.finite(QMD) | BAPH <= 0 | BAPH > 80 | QMD <= 0 | QMD > 60 | VOL < 0 | VOL > 700]
  if (nrow(bad)) fail <- c(fail, sprintf("G2 FAIL: %s has %d out-of-range rows", basename(f), nrow(bad)))
}
if (!length(grep("^G2", fail))) cat("G2 PASS: all trajectories inside physical bounds\n")

## G3 and G5
for (s in srcs) {
  h1f <- file.path(H1, sprintf("%s_h1default_traj.csv", s))
  mgf <- file.path(P33, sprintf("%s_matgate_traj.csv", s))
  nif <- file.path(P33, sprintf("%s_noing_traj.csv", s))
  if (!file.exists(path.expand(mgf)) || !file.exists(path.expand(nif))) { cat(sprintf("G3/G5 SKIP %s: missing file\n", s)); next }
  h1 <- fread(path.expand(h1f)); mg <- fread(path.expand(mgf)); ni <- fread(path.expand(nif))
  j <- merge(h1[age <= 40, .(STAND, age, VOL_h1 = VOL)], mg[age <= 40, .(STAND, age, VOL_mg = VOL)], by = c("STAND","age"))
  reldev <- j[VOL_h1 > 0, max(abs(VOL_mg - VOL_h1) / VOL_h1)]
  if (is.finite(reldev) && reldev > 0.02) fail <- c(fail, sprintf("G3 FAIL %s: matgate vs h1 pre-crash VOL max dev %.1f pct", s, 100*reldev))
  else cat(sprintf("G3 PASS %s: pre-crash max VOL dev %.2f pct\n", s, 100*reldev))
  k <- merge(mg[, .(STAND, age, TPH_mg = TPH)], ni[, .(STAND, age, TPH_ni = TPH)], by = c("STAND","age"))
  dmax <- k[, max(abs(TPH_mg - TPH_ni))]
  if (dmax <= 0.001) fail <- c(fail, sprintf("G5 FAIL %s: matgate identical to noing (total shutoff bug)", s))
  else cat(sprintf("G5 PASS %s: matgate differs from noing (max TPH delta %.1f)\n", s, dmax))
}

## G4 report scrape: pull the VOL site-ordering inversion line from each bakuzis report
scrape <- function(f) {
  if (!file.exists(path.expand(f))) return(NA_character_)
  ln <- grep("site-order|site ordering|inversion|VOL", readLines(path.expand(f), warn=FALSE), value=TRUE, ignore.case=TRUE)
  paste(head(ln, 4), collapse=" | ")
}
cat("\n== G4 objective readout ==\n")
for (s in srcs) {
  cat(sprintf("[%s]\n  h1:      %s\n  noing:   %s\n  matgate: %s\n", s,
    scrape(file.path(H1, sprintf("%s_h1default_bakuzis_report.txt", s))),
    scrape(file.path(P33, sprintf("%s_noing_bakuzis_report.txt", s))),
    scrape(file.path(P33, sprintf("%s_matgate_bakuzis_report.txt", s)))))
}

if (length(fail)) { cat("\n== HARD GATE FAILURES ==\n"); cat(paste(fail, collapse="\n"), "\n"); quit(status = 1) }
cat("\nAll hard gates passed.\n")

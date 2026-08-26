# p34_gates.R -- pass 34 pre-registered gates and objective readout for the csi ladder.
# G0 provenance: every arm must contribute 6 sources x 6 ladder rungs, and each arm reads from its
#    OWN directory. The first battery (job 13974660) wrote two arms to one intermediate filename and
#    lost 6 of 36 files to a rename race; that output is discarded, not repaired.
# G1 cross-layer: at age 1 every ladder rung must carry near-identical TPH and BA, since the tree
#    list is identical by construction. Bound 5 pct.
# G2 value range: BA in (0,80] m2/ha, QMD in (0,60] cm, VOL in [0,700] m3/ha. Bounds external
#    (regional Acadian maxima), same as pass 33.
# G3 magnitude (F5): the SDImax-site-term arm must move terminal volume by under 5 pct against the
#    production arm. External prediction: the term's full swing over csi 8 to 20 is 16.7 SDI units
#    on a base of 650 to 1300, so 1 to 2 pct on SDImax.
# G4 objective: spearman(csi, terminal VOL) with the stand held fixed. The decisive number.
suppressMessages(library(data.table))
P <- path.expand("~/magplot/verify/bakuzis_p34")
srcs <- c("ctrn","nb","qc","ns","memat","mefia_l")
arms <- c("h1check_sdioff","matgate_sdioff","h1check_sdion")
armvar <- c(h1check_sdioff = "h1check", matgate_sdioff = "matgate", h1check_sdion = "h1check")
fail <- character(0)
rd <- function(s, a) {
  f <- file.path(P, a, sprintf("%s_%s_p34_traj.csv", s, armvar[[a]]))
  if (!file.exists(f)) return(NULL)
  d <- fread(f); d[, arm := a]; d[]
}

cat("=== G0 provenance: file count and ladder completeness per arm ===\n")
for (a in arms) {
  nf <- length(list.files(file.path(P, a), pattern = "_p34_traj\\.csv$"))
  rung_ok <- TRUE
  for (s in srcs) { d <- rd(s, a); if (is.null(d) || uniqueN(d$site) != 6) rung_ok <- FALSE }
  st <- if (nf == 6 && rung_ok) "PASS" else { fail <- c(fail, sprintf("G0 %s", a)); "FAIL" }
  cat(sprintf("  %-16s traj files=%d, all 6 sources carry 6 rungs=%s  %s\n", a, nf, rung_ok, st))
}

cat("\n=== G1 cross-layer: age-1 identity across ladder rungs (same tree list) ===\n")
for (s in srcs) for (a in arms) {
  d <- rd(s, a); if (is.null(d)) next
  x <- d[age == 1, .(site, TPH, BAPH)]
  if (nrow(x) < 2) next
  dev_t <- (max(x$TPH) - min(x$TPH)) / mean(x$TPH)
  dev_b <- (max(x$BAPH) - min(x$BAPH)) / mean(x$BAPH)
  st <- if (dev_t > 0.05 || dev_b > 0.05) { fail <- c(fail, sprintf("G1 %s/%s", s, a)); "FAIL" } else "PASS"
  cat(sprintf("  %-9s %-16s age1 TPH spread %5.2f pct, BA spread %5.2f pct  %s\n", s, a, 100*dev_t, 100*dev_b, st))
}

cat("\n=== G2 value range ===\n")
nbad <- 0
for (s in srcs) for (a in arms) {
  d <- rd(s, a); if (is.null(d)) next
  b <- d[!is.finite(BAPH) | !is.finite(VOL) | !is.finite(QMD) |
           BAPH <= 0 | BAPH > 80 | QMD <= 0 | QMD > 60 | VOL < 0 | VOL > 700]
  if (nrow(b)) { nbad <- nbad + nrow(b); fail <- c(fail, sprintf("G2 %s/%s n=%d", s, a, nrow(b))) }
}
cat(sprintf("  out-of-range rows across all files: %d  %s\n", nbad, if (nbad) "FAIL" else "PASS"))

cat("\n=== G4 OBJECTIVE: site response with the stand held fixed ===\n")
cat("spearman(csi, terminal VOL). Passes 32 and 33 measured this across four DIFFERENT real stands\n")
cat("and reported inversions. Here only csi varies, isolating the model's actual site response.\n\n")
res <- list()
for (s in srcs) {
  line <- sprintf("  %-9s", s)
  for (a in arms) {
    d <- rd(s, a)
    if (is.null(d)) { line <- paste0(line, "   n/a"); next }
    term <- d[, .(termVOL = VOL[which.max(age)], maxage = max(age), peakVOL = max(VOL),
                  termBA = BAPH[which.max(age)], termQMD = QMD[which.max(age)],
                  termTPH = TPH[which.max(age)], termHT = HT[which.max(age)]), by = site]
    setorder(term, site)
    r <- if (nrow(term) >= 3) suppressWarnings(cor(term$site, term$termVOL, method = "spearman")) else NA_real_
    rp <- if (nrow(term) >= 3) suppressWarnings(cor(term$site, term$peakVOL, method = "spearman")) else NA_real_
    line <- paste0(line, sprintf("  %s term=%+.2f peak=%+.2f", sub("_sdi", " sdi", a), r, rp))
    res[[paste(s,a)]] <- data.table(source = s, arm = a, term)
  }
  cat(line, "\n")
}

cat("\n=== Terminal and peak detail, production arm (h1check_sdioff) ===\n")
for (s in srcs) {
  d <- rd(s, "h1check_sdioff"); if (is.null(d)) next
  term <- d[, .(maxage = max(age), peakVOL = round(max(VOL),1), termVOL = round(VOL[which.max(age)],1),
                termBA = round(BAPH[which.max(age)],1), termQMD = round(QMD[which.max(age)],1),
                termTPH = round(TPH[which.max(age)]), termHT = round(HT[which.max(age)],1)), by = site]
  setorder(term, site)
  cat(sprintf("--- %s ---\n", s)); print(term)
}

cat("\n=== G3 magnitude: SDImax site term on vs off, production arm ===\n")
for (s in srcs) {
  a <- rd(s, "h1check_sdioff"); b <- rd(s, "h1check_sdion")
  if (is.null(a) || is.null(b)) next
  j <- merge(a[, .(vA = VOL[which.max(age)]), by = site], b[, .(vB = VOL[which.max(age)]), by = site], by = "site")
  dev <- j[vA > 0, max(abs(vB - vA)/vA)]
  st <- if (is.finite(dev) && dev > 0.05) { fail <- c(fail, sprintf("G3 %s", s)); "EXCEEDS 5 pct" } else "within 5 pct"
  cat(sprintf("  %-9s max terminal VOL deviation %5.2f pct  (%s)\n", s, 100*dev, st))
}

if (length(fail)) { cat("\n== GATE FAILURES ==\n"); cat(paste(fail, collapse="\n"), "\n") } else cat("\nAll hard gates passed.\n")
if (length(res)) {
  out <- rbindlist(res, fill = TRUE)
  fwrite(out, file.path(P, "p34_csiladder_terminal.csv"))
  cat(sprintf("\nwrote %s  (%d rows)\n", file.path(P, "p34_csiladder_terminal.csv"), nrow(out)))
}

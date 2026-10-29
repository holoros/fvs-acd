## PREREG50 gate G2 (plan revision 1, md5 6ea850d4): the g2 arm (runner copy runner_p50_fb.R, ING_MIN_FROM_SCORE unset,
## trace on) against the frozen qc141 chunk outputs (p19_a0111), byte for byte, on every screened qc_c stand (dry: the 20
## dry run stands). For each stand: its line in _results and its lines, in order, in _pred_t2_tree, _t1_split_tree and
## _pred_yr1_tree. Headers: full mode compares chunk by chunk (cNNN against cNNN); dry mode reports whether the dry header
## occurs among the frozen headers. A retried stand is taken from its latest attempt. Writes identifier free counts only.
## Usage: Rscript p50_g2.R <outdir> [full|dry]
source("/home/aaron/jobs/v142p50/scripts/p50_common.R")
cu <- fread(CUTF)[label == "qc_c" & arm == "p19_a0111", .(STAND = as.character(STAND), cut)]
r0 <- fread(R0_RES)[, STAND := as.character(STAND)][RUN_OK == 1]
ST <- sort(intersect(r0$STAND, cu[cut == FALSE]$STAND))
if (MODE == "dry") ST <- intersect(ST, fread(KEEPF)$STAND)
cat(sprintf("G2 %s: %d screened stands\n", MODE, length(ST)))
lbs <- function(dirs, pat) { acc <- list(); hdr <- list()
  for (d in dirs) { fs <- sort(list.files(d, pat, full.names = TRUE)); if (!length(fs)) next; got <- list()
    for (f in fs) { L <- readLines(f); if (!length(L)) next
      if (basename(d) == "qc_c" && grepl("/out/|/dry_out/", f)) hdr[[sub("^(c[0-9]+).*$", "\\1", basename(f))]] <- L[1]
      b <- L[-1]; if (!length(b)) next
      k <- gsub("\"", "", sub(",.*$", "", b)); s <- split(b, factor(k, levels = unique(k)))
      for (nm in names(s)) got[[nm]] <- c(got[[nm]], s[[nm]]) }
    for (nm in names(got)) acc[[nm]] <- got[[nm]] }
  list(hdr = hdr, x = acc) }
K <- c("results", "pred_t2_tree", "t1_split_tree", "pred_yr1_tree")
G <- rbindlist(lapply(K, function(k) {
  a <- lbs(R0_DIRS, pat19(k)); b <- lbs(arm_dirs50("g2"), pat50(k))
  same <- vapply(ST, function(s) !is.null(a$x[[s]]) && identical(a$x[[s]], b$x[[s]]), TRUE)
  if (MODE == "full") { cn <- union(names(a$hdr), names(b$hdr)); hok <- length(cn) == 19 && all(vapply(cn, function(c) identical(a$hdr[[c]], b$hdr[[c]]), TRUE)) }
  else hok <- all(unlist(b$hdr) %in% unlist(a$hdr))
  data.table(kind = k, stands = length(ST), identical = sum(same), differ = sum(!same), frozen_missing = sum(!ST %in% names(a$x)),
    g2_missing = sum(!ST %in% names(b$x)), lines_frozen = sum(lengths(a$x[ST])), lines_g2 = sum(lengths(b$x[ST])), header_ok = hok) }))
G[, pass := differ == 0 & frozen_missing == 0 & header_ok]
print(G)
wfile(G, "p50-G2.csv")
cat("P50_G2_DONE\n")

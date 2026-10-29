## PREREG33 G0a, G0b (gated) and G0b1 (reported): the H0 test of the PREREG28 and PREREG28b assemblies (same scaled
## difference |a - b| / max(1, |b|) over every _p column, ING_p and RUN_OK, and over the per tree t2 lists: ht, dbh, expf,
## ing), applied to the G0 subsets (qc_c chunks 1, 10, 19 and qc_fl) against frozen arms restricted to the same stands.
##   G0a  p33_g0a  QC_AFAC_DYNAMIC unset (0), PREREG28b settings      against frozen p28b_small (~/jobs/v142p28b)
##   G0b  p33_g0b  QC_AFAC_DYNAMIC 2, SMALL = LARGE = 0.111, knot 25 against frozen p19_a0111 (~/jobs/v142p19)
##   G0b1 p33_g0b1 QC_AFAC_DYNAMIC 1, SMALL = LARGE = 0.111, knot 25 against frozen p19_a0111, reported only (recruits at 0.111)
## Chunk results are joined with by name retry replacements (latest attempt), as the scorer join does. Writes
## logs/g0_result.csv (refuses if it exists); exits 3 if G0a or G0b fails. No coordinates. No em dashes.
source("/home/aaron/jobs/v142p33/scripts/2026-09-29_v142_p23_hkey.R")
J <- "/home/aaron/jobs/v142p33"; P28B <- "/home/aaron/jobs/v142p28b"; OF <- file.path(J, "logs/g0_result.csv"); if (file.exists(OF)) stop("REFUSE ", OF)
cres <- function(home, arm, s) { fs <- sort(list.files(file.path(home, "out", arm, s), "^c[0-9]+_results\\.csv$", full.names = TRUE)); if (!length(fs)) stop("no chunk results ", arm, " ", s)
  r <- rbindlist(lapply(fs, fread), fill = TRUE)[, STAND := as.character(STAND)]
  for (k in 1:3) { g <- list.files(file.path(home, sprintf("out_retry_a%d", k), arm, s), "^c[0-9]+_results\\.csv$", full.names = TRUE); if (!length(g)) next
    x <- rbindlist(lapply(g, fread), fill = TRUE)[, STAND := as.character(STAND)][STAND %in% r$STAND]; i <- match(x$STAND, r$STAND); for (cc in names(r)) set(r, i, cc, x[[cc]]) }
  if (anyDuplicated(r$STAND)) stop("duplicated STAND ", arm, " ", s); r }
rd <- function(h, arm, s) { acc <- NULL; for (d in arm_dirs(h, arm, s)) { fs <- sort(list.files(d, "^c[0-9]+_pred_t2_tree\\.csv$", full.names = TRUE)); if (!length(fs)) next
  x <- rbindlist(lapply(fs, fread))[, STAND := as.character(STAND)]; if (!is.null(acc)) acc <- acc[!STAND %in% unique(x$STAND)]; acc <- rbind(acc, x) }; acc }
cmp <- function(gate, arm, refroot, refarm, s) { a <- cres(file.path(J, "home"), arm, s); b <- fread(file.path(refroot, "results", refarm, sprintf("gyr_%s_%s_results.csv", refarm, s)))[, STAND := as.character(STAND)]
  b <- b[STAND %in% a$STAND]; if (!setequal(a$STAND, b$STAND)) stop(gate, " stand sets differ ", s); setkey(a, STAND); setkey(b, STAND)
  cols <- c(grep("_p$", names(b), value = TRUE), "ING_p", "RUN_OK")
  per <- sapply(cols, function(k) { d <- abs(a[[k]] - b[[k]]) / pmax(1, abs(b[[k]])); d[is.na(a[[k]]) & is.na(b[[k]])] <- 0; d })
  wr <- max(per); ws <- apply(per, 1, max); wc <- cols[which.max(apply(per, 2, max))]
  ta <- rd(file.path(J, "home"), arm, s); tb <- rd(file.path(refroot, "home"), refarm, s)[STAND %in% a$STAND]
  m <- merge(ta, tb, by = c("STAND", "tree")); if (nrow(m) != nrow(ta) || nrow(m) != nrow(tb)) stop(gate, " per tree rows differ ", s, ": ", nrow(ta), " ", nrow(tb), " ", nrow(m))
  m[, dd := pmax(abs(ht.x - ht.y) / pmax(1, abs(ht.y)), abs(dbh.x - dbh.y) / pmax(1, abs(dbh.y)), abs(expf.x - expf.y) / pmax(1, abs(expf.y)), abs(ing.x - ing.y))]
  wt <- max(m$dd); st_t <- m[, .(w = max(dd)), by = STAND]
  data.table(gate = gate, arm = arm, reference = refarm, set = s, stands = nrow(b), not_ok = sum(a$RUN_OK != 1), trees = nrow(m), recruits = sum(m$ing.y == 1), worst_results = wr, worst_col = wc, worst_trees = wt,
    worst_trees_seeded = max(m[ing.y == 0]$dd), stands_over_1e9 = sum(!is.finite(ws) | ws > 1e-9) + st_t[!is.finite(w) | w > 1e-9, .N],
    pass = is.finite(wr) && is.finite(wt) && wr <= 1e-9 && wt <= 1e-9, gated = gate != "G0b1") }
R <- rbindlist(lapply(c("qc_c", "qc_fl"), function(s) rbind(cmp("G0a", "p33_g0a", P28B, "p28b_small", s), cmp("G0b", "p33_g0b", P19, "p19_a0111", s), cmp("G0b1", "p33_g0b1", P19, "p19_a0111", s))))
print(R); fwrite(R, OF)
if (!all(R[gated == TRUE]$pass)) { cat("G0_FAIL\n"); quit(status = 3) }
cat("G0_PASS\n")

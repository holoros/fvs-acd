## PREREG28 smoke check: 5 qc_c stands (pairs rows 1 to 5) for p28_g0 (new code path, both 0.111), p28_unset (fallback) and
## p28_cand against frozen p19_a0111, results (_p columns, ING_p, RUN_OK) and per tree t2 lists. No coordinates. No em dashes.
suppressMessages(library(data.table))
H <- "/home/aaron/jobs/v142p28/home/smoke"; F <- "/home/aaron/jobs/v142p19/home/out/p19_a0111/qc_c"
b <- fread(file.path(F, "c001_results.csv"))[, STAND := as.character(STAND)]; tb <- fread(file.path(F, "c001_pred_t2_tree.csv"))[, STAND := as.character(STAND)]
for (a in c("p28_g0", "p28_unset", "p28_cand")) { r <- fread(file.path(H, a, "qc_c/c001_results.csv"))[, STAND := as.character(STAND)]
  bb <- b[STAND %in% r$STAND]; setkey(r, STAND); setkey(bb, STAND); cols <- c(grep("_p$", names(bb), value = TRUE), "ING_p", "RUN_OK")
  wr <- max(sapply(cols, function(k) { d <- abs(r[[k]] - bb[[k]]) / pmax(1, abs(bb[[k]])); d[is.na(r[[k]]) & is.na(bb[[k]])] <- 0; max(d) }))
  t <- fread(file.path(H, a, "qc_c/c001_pred_t2_tree.csv"))[, STAND := as.character(STAND)]; m <- merge(t, tb[STAND %in% r$STAND], by = c("STAND", "tree"))
  wt <- if (nrow(m) == nrow(t) && nrow(m) == tb[STAND %in% r$STAND, .N]) m[, max(abs(ht.x - ht.y) / pmax(1, abs(ht.y)), abs(dbh.x - dbh.y) / pmax(1, abs(dbh.y)), abs(expf.x - expf.y) / pmax(1, abs(expf.y)))] else NA
  s <- m[ing.x == 0, .(below25_dht = mean(ht.x - ht.y), n = .N), by = .(big = dbh.y >= 25)]
  cat(sprintf("%s: %d stands %s, RUN_OK %d, worst results %.3g, worst trees %.3g (rows %d/%d)\n", a, nrow(r), paste(r$STAND, collapse = " "), sum(r$RUN_OK), wr, wt, nrow(m), nrow(t)))
  print(s) }

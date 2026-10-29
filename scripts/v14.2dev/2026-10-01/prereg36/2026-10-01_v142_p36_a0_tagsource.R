## PREREG36 Part A0 (Cardinal): classify each C2 plan row's tag frame as row index or field tag. Frames only; reads
## STAND and TREE (plus SP and DBH for the row index pairs' shrinkage share); no coordinate column. No em dashes.
suppressMessages(library(data.table))
PLANF <- Sys.getenv("P36_PLAN"); OUT <- Sys.getenv("P36_OUT")
PL <- unique(rbindlist(lapply(strsplit(PLANF, ",")[[1]], fread, colClasses = "character"))[c2 == "TRUE"], by = c("set", "tagfr"))
res <- list()
for (i in seq_len(nrow(PL))) { p <- PL[i]; s <- p$set
  f <- file.path(p$tagfr, sprintf("bench_gyr_%s_tree_%s.csv", s, c("init", "t2")))
  m <- unname(tools::md5sum(f))
  G <- lapply(f, function(x) fread(x, select = c("STAND", "TREE", "SP", "DBH", "HT"))[, STAND := as.character(STAND)])
  rix <- vapply(G, function(g) g[, all(TREE == seq_len(.N)), by = STAND][, all(V1)], logical(1))
  ## row index pairs as the scorer would form them: same STAND and TREE, same SP, measured t2 HT
  a <- G[[1]][, .(STAND, TREE, SP, DBH1 = DBH)]; b <- G[[2]][, .(STAND, TREE, SP2 = SP, DBH2 = DBH, H2 = HT)]
  d1 <- a[, .N, by = .(STAND, TREE)][N > 1]; d2 <- b[, .N, by = .(STAND, TREE)][N > 1]
  a <- a[!d1, on = .(STAND, TREE)]; b <- b[!d2, on = .(STAND, TREE)]
  sv <- merge(a, b, by = c("STAND", "TREE")); S <- sv[SP == SP2 & is.finite(H2) & H2 > 0]
  res[[i]] <- data.table(label = p$label, set = s, arm = p$arm, tagfr = sub(".*/gydbreg20260916/", "", p$tagfr),
    md5_init = m[1], md5_t2 = m[2], row_index_init = rix[1], row_index_t2 = rix[2], same_as_run_frame = normalizePath(p$tagfr) == normalizePath(p$fr),
    pairs_S = nrow(S), dbh_shrink_gt1cm_share = S[, mean(DBH2 < DBH1 - 1.0)], dbh_change_median = S[, median(DBH2 - DBH1)])
  cat(sprintf("A0 %s: row index init %s t2 %s; S %d; shrink share %.4f\n", s, rix[1], rix[2], nrow(S), res[[i]]$dbh_shrink_gt1cm_share)) }
R <- rbindlist(res)
fwrite(R, file.path(OUT, "gyr142-p36-a0-tagsource_DATA_2026-10-01.csv")); print(R); cat("P36_A0_DONE\n")

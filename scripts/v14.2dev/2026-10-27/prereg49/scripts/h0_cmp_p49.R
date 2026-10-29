## PREREG49 gate H0 (PREREG38 H0 and PREREG45 H0 code pattern): the switch at its null (v141LTfis0: overlay on, form fr, theta
## 0) on the PREREG22 G0 subset (ns_c rows 1 to 100, task 37) against frozen v141LTfi (PREREG22). Results: every _p column, ING_p
## and RUN_OK, worst scaled |a - b| / max(1, |b|); per tree (pred_t2_tree): dbh, ht, expf and ing on STAND and tree, same row
## sets required. By name retries replace timed out stands (latest attempt). Pass: both worst values at or below 1e-9 and the
## stand set equal. Usage: Rscript h0_cmp_p49.R ROOT RESULT. Writes aggregates only. No coordinates. No em dashes.
suppressMessages(library(data.table)); a <- commandArgs(TRUE); J <- a[1]; H <- file.path(J, "home")
if (file.exists(a[2])) stop("REFUSE ", a[2])
FR <- "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_c_results.csv"; stopifnot(unname(tools::md5sum(FR)) == "9fe608de2e4261bd60d637019c83022e")
FT <- "/home/aaron/jobs/v142p22/home/out/v141LTfi/ns_c/c001_pred_t2_tree.csv"
rd <- function(pat, root = H, arm = "v141LTfis0") { fs <- c(file.path(root, "out", arm, "ns_c", pat), file.path(root, sprintf("out_retry_a%d", 1:3), arm, "ns_c"))
  x <- rbindlist(lapply(seq_along(fs), function(k) { f <- if (k == 1) fs[k] else list.files(fs[k], sub("^c001", "^c[0-9]+", gsub(".", "[.]", pat, fixed = TRUE)), full.names = TRUE)
    if (!length(f) || !all(file.exists(f))) return(NULL); z <- rbindlist(lapply(f, fread), fill = TRUE); z[, `:=`(STAND = as.character(STAND), att = k - 1L)] }), fill = TRUE)
  la <- x[, .(att = max(att)), by = STAND]; merge(x, la, by = c("STAND", "att"))[, att := NULL][] }
A <- rd("c001_results.csv"); B <- fread(FR)[, STAND := as.character(STAND)][STAND %in% A$STAND]
pc <- unique(c(grep("_p$", names(B), value = TRUE), "ING_p", "RUN_OK")); m <- merge(A[, c("STAND", pc), with = FALSE], B[, c("STAND", pc), with = FALSE], by = "STAND")
dr <- sapply(pc, function(v) { x <- m[[paste0(v, ".x")]]; y <- m[[paste0(v, ".y")]]; if (any(is.na(x) != is.na(y))) Inf else max(abs(x - y) / pmax(1, abs(y)), 0, na.rm = TRUE) })
ta <- rd("c001_pred_t2_tree.csv")[, .(STAND, tree, dbh, ht, expf, ing)]; tb <- fread(FT)[, STAND := as.character(STAND)][STAND %in% A$STAND, .(STAND, tree, dbh, ht, expf, ing)]
mt <- merge(ta, tb, by = c("STAND", "tree"))
dt <- sapply(c("dbh", "ht", "expf", "ing"), function(v) { x <- mt[[paste0(v, ".x")]]; y <- mt[[paste0(v, ".y")]]; if (any(is.na(x) != is.na(y))) Inf else max(abs(x - y) / pmax(1, abs(y)), 0, na.rm = TRUE) })
R <- data.table(gate = "H0", stands = nrow(A), stands_matched = nrow(m), frozen_stands = nrow(B), result_columns = length(pc), worst_results = max(dr), worst_results_col = names(dr)[which.max(dr)],
  tree_rows = nrow(ta), tree_rows_frozen = nrow(tb), tree_rows_matched = nrow(mt), worst_trees = max(dt), worst_trees_col = names(dt)[which.max(dt)])
R[, pass := stands == 100L & stands_matched == stands & frozen_stands == stands & tree_rows_matched == tree_rows & tree_rows == tree_rows_frozen & worst_results <= 1e-9 & worst_trees <= 1e-9]
print(R); fwrite(R, a[2]); if (!R$pass) quit(status = 1); cat("H0_PASS\n")

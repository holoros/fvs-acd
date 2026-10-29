## PREREG50 dry run stand pick (plan revision 1, md5 6ea850d4): 20 screened fold A qc_c stands, RUN_OK 1 in the frozen
## qc141 results, drawn with set.seed(20261028) from the sorted list; written to home/work/dry_keep_SERVERONLY.csv. Reads no
## outcome. Prints counts only. No em dashes.
source("/home/aaron/jobs/v142p50/scripts/p50_common.R")
cu <- fread(CUTF)[label == "qc_c" & arm == "p19_a0111", .(STAND = as.character(STAND), cut)]
r0 <- fread(R0_RES)[, STAND := as.character(STAND)][RUN_OK == 1, .(STAND, SITE = as.character(SITE))]
x <- merge(r0, cu, by = "STAND")[cut == FALSE][, fold := fold(SITE)][fold == "A"]
pool <- sort(x$STAND); set.seed(20261028L); keep <- sample(pool, 20L)
if (file.exists(KEEPF)) stop("REFUSE overwrite dry keep file")
fwrite(data.table(STAND = keep), KEEPF)
cat(sprintf("dry pick: %d of %d screened fold A stands\n", length(keep), length(pool)))

## PREREG4 dry run check (mechanics only, 3 fold A stands, aggregates only): per arm stands run, and the sum over stands of the
## trajectory MORT_BA_S at the last row (to see that the lever acts and is monotone in delta); the g0 trace structure. No em dashes.
suppressMessages(library(data.table))
D <- "/users/PUOM0008/crsfaaron/v143p4/dry/root"
keep <- fread(file.path(D, "so/keep_foldA_SERVERONLY.csv"))$STAND
for (a in list.files(file.path(D, "out/hc"))) {
  f <- list.files(file.path(D, "out/hc", a, "mefia_l_c"), "_results\\.csv$", full.names = TRUE); if (!length(f)) next
  r <- fread(f); t <- fread(list.files(file.path(D, "out/hc", a, "mefia_l_c"), "_traj\\.csv$", full.names = TRUE))
  m <- t[, .SD[which.max(yr)], by = STAND][, sum(MORT_BA_S)]
  cat(sprintf("%-8s stands %d ok %d in_keep %s sum_last_MORT_BA_S %.6f\n", a, nrow(r), sum(r$RUN_OK == 1), all(r$STAND %in% keep), m)) }
tf <- list.files(file.path(D, "out/hc/g0/mefia_l_c"), "trace.*rds$", full.names = TRUE)
if (length(tf)) { tr <- as.data.table(readRDS(tf[1]))
  cat(sprintf("trace rows %d, keys %d, keys in keep %s, YEAR NA share %.3f, DELTA all 0 %s, floor sets share %.3f\n", nrow(tr), uniqueN(tr$KEY), all(tr$KEY %in% keep), mean(is.na(tr$YEAR)), all(tr$DELTA == 0), mean(tr$FLOOR_SETS)))
  print(tr[, .N, by = CLASS]); print(names(tr)) } else cat("NO TRACE FILE\n")
for (a in list.files(file.path(D, "out/l200"))) {
  f <- list.files(file.path(D, "out/l200", a, "mefia_l_c"), "_traj\\.csv$", full.names = TRUE); if (!length(f)) next
  t <- fread(f); cat(sprintf("l200 %-6s stands %d max yr %d sum BIOMASS yr200 %.3f\n", a, uniqueN(t$STAND), max(t$yr), t[yr == max(yr), sum(BIOMASS)])) }

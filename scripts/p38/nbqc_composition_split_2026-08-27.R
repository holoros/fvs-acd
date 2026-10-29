suppressMessages(library(data.table))
init <- fread(file.path(Sys.getenv("HOME"), "magplot/verify/magp_qcnb_tree_init.csv"))
pairs <- fread(file.path(Sys.getenv("HOME"), "magplot/verify/magp_qcnb_pairs.csv"))
cat("pairs PROV table:\n"); print(table(pairs$PROV))
TARGET <- c("AB","WA","SM")
init <- merge(init, unique(pairs[, .(STAND, PROV)]), by = "STAND", all.x = TRUE)
cat("init rows with resolved PROV:", sum(!is.na(init$PROV)), "of", nrow(init), "\n")
for (pv in c("NB","QC")) {
  sub <- init[PROV == pv]
  tot <- nrow(sub); n_stand <- length(unique(sub$STAND))
  cnt <- sub[, .N, by = SP][SP %in% TARGET]
  out <- setNames(rep(0L, length(TARGET)), TARGET)
  if (nrow(cnt)) out[cnt$SP] <- cnt$N
  pct <- round(100 * out / tot, 3)
  cat(sprintf("%s: n_trees=%d n_stand=%d AB=%d(%.3f%%) WA=%d(%.3f%%) SM=%d(%.3f%%)\n",
              pv, tot, n_stand, out["AB"], pct["AB"], out["WA"], pct["WA"], out["SM"], pct["SM"]))
}

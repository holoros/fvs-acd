# 100-year projections of a random sample of AcdFiaBench.db start stands, for biological realism checks
# (maximum basal area, Reineke stand density index against the self-thinning line, top height by site).
# Usage: Rscript tests/run_longterm.R <db> <variant compiled|corrected> <ingrowth 0|1> <n_plots> <out.csv>
args <- commandArgs(TRUE)
suppressPackageStartupMessages(library(DBI))
here <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))
for (f in c("acd7_params.R", "acd7.R", "bench_data.R")) source(file.path(here, "..", "R", f))
opt <- if (args[2] == "corrected") acd7_options_corrected() else acd7_options()
ing <- as.integer(args[3])
db <- dbConnect(RSQLite::SQLite(), args[1])
pairs <- acd7_bench_pairs(db); pairs <- pairs[pairs$TrtPeriod == "none", ]
set.seed(20261112); pick <- pairs[sample(nrow(pairs), as.integer(args[4])), ]
res <- list()
for (i in seq_len(nrow(pick))) {
  p <- pick[i, ]; t <- acd7_bench_trees(db, p$start_cn); if (!nrow(t)) next
  g <- tryCatch(grow_acd7(100L, "ME", 10L, 1L, p$CSI * 3.28, as.numeric(p$ElevFt), -1, 0L, 0L, 0L, ing, 0.5, 3 / 2.54,
                          as.integer(t$Plot_ID), as.integer(t$Tree_ID), t$SPECIES, t$DBH, t$HT, t$tpa, t$cr,
                          integer(nrow(t)), integer(nrow(t)), opt = opt, trace_every = 10L), error = function(e) NULL)
  if (is.null(g)) next
  tr <- attr(g, "trace"); tr$key <- p$key; tr$CSI <- p$CSI; res[[i]] <- tr
  if (i %% 25 == 0) cat(i, "\n")
}
write.csv(do.call(rbind, res), args[5], row.names = FALSE)
cat("done\n")

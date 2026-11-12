# Benchmark ACD7 on Ben Rice's FIA remeasurement set (AcdFiaBench.db).
# Usage: Rscript tests/run_benchmark.R <db> <engine: cpp|port> <variant: compiled|corrected> <ingrowth 0|1> <out.csv> [Rlib]
# Errors are predicted minus observed, annualized, in the units of Greg's reports (ft2/ac, trees/ac, in).
args <- commandArgs(TRUE)
if (length(args) >= 6) .libPaths(c(args[6], .libPaths()))
suppressPackageStartupMessages(library(DBI))
here <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))
for (f in c("acd7_params.R", "acd7.R", "bench_data.R")) source(file.path(here, "..", "R", f))
engine <- args[2]; variant <- args[3]; ing <- as.integer(args[4])
if (engine == "cpp") suppressPackageStartupMessages(library(acdR))
opt <- if (variant == "corrected") acd7_options(dht_cr_exponent = "b3", reset_ingrowth_maps = TRUE, hcb_re_alignment = "as_intended") else acd7_options()

# acdR 0.75 calls std::terminate (killing R) when a NaN dbh reaches STAND::compute_ba_tph_bal, which happens
# when stand CCF < 1 makes the height imputation log(CCF)^b5 undefined. Run it in a forked child so a crash
# loses one plot, not the session.
safe_cpp <- function(a) {
  job <- parallel::mcparallel(do.call(acdR::grow_acd, a), silent = TRUE)
  r <- parallel::mccollect(job, wait = TRUE)[[1]]
  if (is.data.frame(r)) r else NULL
}

db <- dbConnect(RSQLite::SQLite(), args[1])
pairs <- acd7_bench_pairs(db)
res <- vector("list", nrow(pairs))
t0 <- Sys.time()
for (i in seq_len(nrow(pairs))) {
  p <- pairs[i, ]
  t0t <- acd7_bench_trees(db, p$start_cn); t1 <- acd7_bench_trees(db, p$end_cn)
  if (nrow(t0t) == 0) next
  a <- list(as.integer(p$years), "ME", 10L, 1L, p$CSI * 3.28, as.numeric(p$ElevFt), -1, 0L, 0L, 0L, ing, 0.5, 3 / 2.54,
            as.integer(t0t$Plot_ID), as.integer(t0t$Tree_ID), t0t$SPECIES, t0t$DBH, t0t$HT, t0t$tpa, t0t$cr,
            integer(nrow(t0t)), integer(nrow(t0t)))
  g <- tryCatch(if (engine == "cpp") safe_cpp(a) else do.call(grow_acd7, c(a, list(opt = opt))),
                error = function(e) NULL)
  if (is.null(g) || !is.data.frame(g)) next
  s0 <- acd7_stand_sum(t0t$DBH, t0t$HT, t0t$tpa); sp <- acd7_stand_sum(g$dbh, g$ht, g$expf); so <- acd7_stand_sum(t1$DBH, t1$HT, t1$tpa)
  res[[i]] <- data.frame(key = p$key, TrtPeriod = p$TrtPeriod, State = p$State, years = p$years, CSI = p$CSI,
    ba0 = s0["ba"], tpa0 = s0["tpa"], qmd0 = s0["qmd"],
    ba_obs = so["ba"], tpa_obs = so["tpa"], qmd_obs = so["qmd"], ba_pred = sp["ba"], tpa_pred = sp["tpa"], qmd_pred = sp["qmd"],
    e_ba = (sp["ba"] - so["ba"]) / p$years, e_tpa = (sp["tpa"] - so["tpa"]) / p$years, e_qmd = (sp["qmd"] - so["qmd"]) / p$years,
    any_nan = any(!is.finite(g$dbh)) || any(!is.finite(g$ht)), row.names = NULL)
  if (i %% 250 == 0) cat(i, "of", nrow(pairs), format(Sys.time() - t0), "\n")
}
out <- do.call(rbind, res)
out$engine <- engine; out$variant <- variant; out$ingrowth <- ing
write.csv(out, args[5], row.names = FALSE)
cat("done", nrow(out), "pairs\n")

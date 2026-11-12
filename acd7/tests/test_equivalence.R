# Equivalence test: R port (acd7.R) against the compiled acdR 0.75 C++ engine.
# Usage: Rscript tests/test_equivalence.R <AcdFiaBench.db> <n_plots> <out.csv> [Rlib]
args <- commandArgs(TRUE)
if (length(args) >= 4) .libPaths(c(args[4], .libPaths()))
suppressPackageStartupMessages({ library(acdR); library(DBI) })
here <- dirname(sub("--file=", "", grep("--file=", commandArgs(FALSE), value = TRUE)))
for (f in c("acd7_params.R", "acd7.R", "bench_data.R")) source(file.path(here, "..", "R", f))

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
set.seed(20261112)
pick <- pairs[sample(nrow(pairs), min(as.integer(args[2]), nrow(pairs))), ]

scen <- list(
  base     = list(ing = 0, sbw = 0, hw = 0, cdef = -1, fr = FALSE),
  ingrowth = list(ing = 1, sbw = 0, hw = 0, cdef = -1, fr = FALSE),
  sbw      = list(ing = 0, sbw = 1, hw = 0, cdef = 30,  fr = FALSE),
  hw_form  = list(ing = 0, sbw = 0, hw = 1, cdef = -1, fr = TRUE))

res <- list()
for (i in seq_len(nrow(pick))) {
  p <- pick[i, ]; t <- acd7_bench_trees(db, p$start_cn)
  if (nrow(t) == 0) next
  ub <- any(acd7_resolve_species(unique(t$SPECIES))$idx == -1)  # C++ undefined behaviour for these species
  for (sn in names(scen)) {
    s <- scen[[sn]]
    set.seed(i); form <- if (s$fr) sample(0:8, nrow(t), TRUE) else integer(nrow(t))
    risk <- if (s$fr) sample(0:4, nrow(t), TRUE) else integer(nrow(t))
    args_common <- list(as.integer(p$years), "ME", as.integer(10), as.integer(1), p$CSI * 3.28, as.numeric(p$ElevFt), s$cdef,
                        as.integer(s$sbw), as.integer(s$hw), as.integer(0), as.integer(s$ing), 0.5, 3 / 2.54,
                        as.integer(t$Plot_ID), as.integer(t$Tree_ID), t$SPECIES, t$DBH, t$HT, t$tpa, t$cr,
                        as.integer(form), as.integer(risk))
    cpp <- safe_cpp(args_common)
    r   <- tryCatch(do.call(grow_acd7, args_common), error = function(e) { message(p$key, " ", sn, ": ", conditionMessage(e)); NULL })
    if (is.null(cpp) || !is.data.frame(cpp) || is.null(r)) { res[[length(res) + 1]] <- data.frame(key = p$key, scen = sn, ok = FALSE, ub = ub,
        n_cpp = NA, n_r = NA, max_dbh = NA, max_ht = NA, max_expf = NA, max_cr = NA, d_ba = NA, d_tpa = NA); next }
    sc <- acd7_stand_sum(cpp$dbh, cpp$ht, cpp$expf); sr <- acd7_stand_sum(r$dbh, r$ht, r$expf)
    if (s$ing == 0 && nrow(cpp) == nrow(r)) {
      a <- cpp[order(cpp$plot.id, cpp$tree.id), ]; b <- r[order(r$plot.id, r$tree.id), ]
      md <- c(max(abs(a$dbh - b$dbh)), max(abs(a$ht - b$ht)), max(abs(a$expf - b$expf)), max(abs(a$cr - b$cr)))
    } else md <- rep(NA, 4)
    res[[length(res) + 1]] <- data.frame(key = p$key, scen = sn, ok = TRUE, ub = ub, n_cpp = nrow(cpp), n_r = nrow(r),
      max_dbh = md[1], max_ht = md[2], max_expf = md[3], max_cr = md[4],
      d_ba = unname(sr["ba"] - sc["ba"]), d_tpa = unname(sr["tpa"] - sc["tpa"]))
  }
  if (i %% 25 == 0) cat(i, "plots\n")
}
out <- do.call(rbind, res)
write.csv(out, args[3], row.names = FALSE)
for (sn in names(scen)) {
  o <- out[out$scen == sn & out$ok & !out$ub, ]
  cat(sprintf("%-9s plots with undefined-behaviour species (excluded): %d\n", sn, sum(out$scen == sn & out$ub)))
  cat(sprintf("%-9s n=%d  rows equal %d  max|dDBH| %.2e  max|dHT| %.2e  max|dEXPF| %.2e  max|dCR| %.2e  max|dBA| %.2e  max|dTPA| %.2e\n",
      sn, nrow(o), sum(o$n_cpp == o$n_r), max(o$max_dbh, na.rm = TRUE), max(o$max_ht, na.rm = TRUE),
      max(o$max_expf, na.rm = TRUE), max(o$max_cr, na.rm = TRUE), max(abs(o$d_ba)), max(abs(o$d_tpa))))
}

## Pass 20: Bakuzis-lite site-ordering check for the v13.2 site-fsm overlay, run through the
## ACTUAL production call path (AcadianGYOneStand -> calc_ddbh), not the isolated plot_ba_incr_v132
## unit test already done in the smoke test. Mirrors sanity_hooks_v131.R's harness conventions
## (lowercase tree-list columns, make_ops/base_ops pattern) so this exercises the real pipeline.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(dplyr))

source("~/magplot/verify/p20_v132/2026-08-19_v132_sitefsm_overlay_WIP.R")  # sources AcadianGY_13.1.r, defines v132 fns

base_ops <- function() {
  o <- make_ops(verbose = FALSE, use.ingrowth = FALSE, use.cap.dbh = TRUE, use.cap.ht = TRUE,
                use.hw.mod = FALSE, use.sbw.mod = FALSE, use.thin.mod = FALSE, use.vol = FALSE)
  o
}
project <- function(cur, ops, years, csi_val, region_val) {
  # calc_ht()/calc_ddbh() etc. take csi/region as default args (e.g. csi = stand$csi) resolved
  # lexically against a GLOBAL `stand` object, not whatever is passed as AcadianGYOneStand's own
  # stand= argument (see sanity_hooks_v131.R's stand<<-make_stand(...) convention). Match that.
  stand <<- make_stand(stand.id = "bz", csi = csi_val, elev = 200, region = region_val)
  for (yr in seq_len(years)) {
    nx <- AcadianGYOneStand(tree = cur, stand = stand, ops = ops)
    if (is.null(nx) || nrow(nx) == 0) stop("empty projection")
    cur <- nx
  }
  cur
}
plot_ba <- function(x) sum(x$dbh^2 * 0.00007854 * x$expf, na.rm = TRUE)

## Two starting structures: large-tree-dominated (low f_sm) and small-tree-dominated (high f_sm)
mk_stand <- function(small_heavy = FALSE) {
  set.seed(2020)
  n <- 60
  if (small_heavy) {
    dbh <- c(runif(round(n * 0.8), 3, 11), runif(n - round(n * 0.8), 15, 30))
  } else {
    dbh <- c(runif(round(n * 0.15), 3, 11), runif(n - round(n * 0.15), 15, 40))
  }
  data.frame(year = 0, plot = 1L, tree = 1:n, sp = rep(c("RS","BF","RM","YB"), length.out = n),
             dbh = dbh[1:n], ht = NA_real_, hcb = NA_real_, cr = 0.45,
             expf = rep(700 / n, n), form = NA_character_, risk = NA_character_,
             ddbh.mult = 1, dht.mult = 1, mort.mult = 1, max.dbh = 200, max.height = 50,
             stringsAsFactors = FALSE)
}

csi_grid <- c(12, 14, 16, 18, 20)
YRS <- 10

run_grid <- function(small_heavy, label) {
  cat(sprintf("\n=== %s (small_heavy=%s) ===\n", label, small_heavy))
  init <- mk_stand(small_heavy)
  ba0 <- plot_ba(init)
  cat(sprintf("t0 plot BA = %.3f, f_sm at t0 = %.3f\n", ba0,
              1 - sum(ifelse(init$dbh >= 12.7, init$dbh^2 * 0.00007854 * init$expf, 0)) / ba0))
  res <- data.frame(csi = csi_grid, ba_v131 = NA_real_, ba_v132 = NA_real_)
  for (i in seq_along(csi_grid)) {
    deactivate_v132()
    ops <<- base_ops()
    out131 <- tryCatch(project(init, ops, YRS, csi_grid[i], "ME"), error = function(e) {cat("v131 ERROR csi=",csi_grid[i],":",conditionMessage(e),"\n"); NULL})
    activate_v132()
    ops <<- base_ops()
    out132 <- tryCatch(project(init, ops, YRS, csi_grid[i], "ME"), error = function(e) {cat("v132 ERROR csi=",csi_grid[i],":",conditionMessage(e),"\n"); NULL})
    res$ba_v131[i] <- if (!is.null(out131)) plot_ba(out131) else NA
    res$ba_v132[i] <- if (!is.null(out132)) plot_ba(out132) else NA
  }
  print(res)
  verdict <- function(x) {
    if (anyNA(x)) return("INCONCLUSIVE (NA present, see errors above)")
    ifelse(all(diff(x) >= 0), "PASS", "FLAG")
  }
  cat(sprintf("Bakuzis-lite site ordering (BA at yr %d increases monotonically with csi): v13.1 %s | v13.2 %s\n",
              YRS, verdict(res$ba_v131), verdict(res$ba_v132)))
  res
}

r_lg <- run_grid(FALSE, "large-tree-dominated stand (low f_sm)")
r_sm <- run_grid(TRUE,  "small-tree-dominated stand (high f_sm)")

cat("\nBAKUZIS_PIPELINE_CHECK_DONE\n")

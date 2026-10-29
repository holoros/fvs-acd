.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(dplyr))
source("~/magplot/verify/p20_v132/2026-08-19_v132_sitefsm_overlay_WIP.R")

cat("\n--- structural check: calc_ddbh_v132 vs calc_ddbh, args and non-target lines ---\n")
cat("formals identical:", identical(formals(calc_ddbh_v132), formals(calc_ddbh)), "\n")
cat("body line count v132:", length(deparse(body(calc_ddbh_v132))),
    " original:", length(deparse(body(calc_ddbh))), "\n")

## ---- unit check on plot_ba_incr_v132 directly: site-ordering across csi, at f_sm = 0 and
## f_sm = median (0.1876, from p19_fit_log.txt f_sm summary) ---------------------------------
csi_grid <- c(12, 14, 16, 18, 20)
cat("\n--- rt(csi) at rd = 0.5, ba.perc.hw = 0.10, f_sm = 0 (pure large-tree stand) ---\n")
for (cs in csi_grid) {
  dba <- plot_ba_incr_v132(rd = 0.5, csi = cs, ba.perc.hw = 0.10, ba.plot = 25, f_sm = 0)
  cat(sprintf("csi=%2d  dba=%.5f\n", cs, dba))
}
cat("\n--- rt(csi) at rd = 0.5, ba.perc.hw = 0.10, f_sm = 0.1876 (median) ---\n")
for (cs in csi_grid) {
  dba <- plot_ba_incr_v132(rd = 0.5, csi = cs, ba.perc.hw = 0.10, ba.plot = 25, f_sm = 0.1876)
  cat(sprintf("csi=%2d  dba=%.5f\n", cs, dba))
}
cat("\n--- shipped plot_ba_incr for comparison, same grid (expect flat-to-inverted site order) ---\n")
for (cs in csi_grid) {
  dba <- plot_ba_incr(rd = 0.5, csi = cs, ba.perc.hw = 0.10, ba.plot = 25)
  cat(sprintf("csi=%2d  dba=%.5f\n", cs, dba))
}

## ---- end-to-end projection smoke test through calc_ddbh_v132 on a synthetic mixed stand ----
cat("\n--- end-to-end calc_ddbh_v132 smoke test ---\n")
set.seed(19)
n <- 40
mk_tree <- function(csi_tag) {
  data.frame(year = 0, plot = 1L, tree = 1:n,
             sp = rep(c("RS","BF","RM","YB"), length.out = n),
             dbh = c(runif(n * 0.6, 2, 12), runif(n - floor(n * 0.6), 15, 35))[1:n],
             ht = NA_real_, hcb = NA_real_, cr = 0.4,
             expf = rep(900 / n, n), form = NA_character_, risk = NA_character_,
             ddbh.mult = 1, dht.mult = 1, mort.mult = 1, max.dbh = 200, max.height = 50,
             bal = 0, bal.sw = 0, bal.hw = 0, stringsAsFactors = FALSE)
}

tree.data <- mk_tree()
plot.data <- data.frame(plot = 1L, rd.mod = 0.5, ba.perc.hw = 0.5,
                         ba.plot = sum(tree.data$dbh^2 * 0.00007854 * tree.data$expf), qmd = 20)

ops <<- make_ops(verbose = FALSE, use.ingrowth = TRUE, ingrowth.min.dbh = 5.0,
                  ingrowth.thrshld = 0, use.cap.dbh = FALSE, use.cap.ht = FALSE,
                  use.hw.mod = FALSE, use.sbw.mod = FALSE, use.thin.mod = FALSE, use.vol = FALSE)

for (cs in c(12, 20)) {
  out <- tryCatch(calc_ddbh_v132(tree.data = tree.data, plot.data = plot.data, csi = cs,
                                  region = "ME", use.cap.dbh = FALSE, use.sbw.mod = FALSE,
                                  use.hw.mod = FALSE, use.thin.mod = FALSE),
                   error = function(e) { cat("ERROR at csi=", cs, ":", conditionMessage(e), "\n"); NULL })
  if (!is.null(out)) {
    cat(sprintf("csi=%2d  n_trees=%d  sum(ddbh)=%.4f  any_NA=%s\n",
                cs, nrow(out), sum(out$ddbh, na.rm = TRUE), any(is.na(out$ddbh))))
  }
}

cat("\nSMOKE_DONE\n")

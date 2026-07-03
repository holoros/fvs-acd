# DIAGNOSE: recover per-stand direct-effect response for managed stands (planted, PCT).
# Show distribution of per-stand increment ratios; confirm 5-10x values come from near-zero
# predicted-untreated increment; quantify how many stands drive the 1.6 clamp. Aggregates only.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
W <- as.data.table(readRDS("Wfull.rds"))
cat("Wfull cols with BA:\n"); print(grep("BA", names(W), value=TRUE))

f <- function(cls){
  d <- W[mgmt==cls]
  d[, obs_inc  := BA_o    - BA_t1]
  d[, pred_inc := v129x.BA - BA_t1]
  d[, ratio    := obs_inc/pred_inc]
  cat(sprintf("\n===== %s  (n=%d) =====\n", cls, nrow(d)))
  cat(sprintf("mean obs_inc=%.3f  mean pred_inc=%.3f  ratio-of-means=%.3f\n",
      mean(d$obs_inc,na.rm=TRUE), mean(d$pred_inc,na.rm=TRUE),
      mean(d$obs_inc,na.rm=TRUE)/mean(d$pred_inc,na.rm=TRUE)))
  cat("pred_inc quantiles (predicted-untreated BA increment, m2/ha over interval):\n")
  print(round(quantile(d$pred_inc, c(0,.1,.25,.5,.75,.9,1), na.rm=TRUE),3))
  cat("obs_inc quantiles:\n")
  print(round(quantile(d$obs_inc, c(0,.1,.25,.5,.75,.9,1), na.rm=TRUE),3))
  # how many stands have near-zero predicted-untreated increment
  for(fl in c(0.1,0.25,0.5,1.0)){
    n_below <- d[abs(pred_inc) < fl, .N]
    cat(sprintf("  |pred_inc| < %.2f : %d of %d stands (%.0f%%)\n", fl, n_below, nrow(d), 100*n_below/nrow(d)))
  }
  # per-stand ratio distribution (only where pred_inc>0 so ratio is defined & meaningful)
  pos <- d[is.finite(ratio) & pred_inc>0]
  cat(sprintf("stands with pred_inc>0: %d ; ratio quantiles among them:\n", nrow(pos)))
  print(round(quantile(pos$ratio, c(0,.1,.25,.5,.75,.9,1), na.rm=TRUE),3))
  cat(sprintf("  per-stand ratio>1.6 (would hit clamp): %d of %d pos-pred stands (%.0f%%)\n",
      pos[ratio>1.6,.N], nrow(pos), 100*pos[ratio>1.6,.N]/nrow(pos)))
  # confirm big ratios come from small denominators
  cat("  among ratio>3 stands, pred_inc summary:\n")
  print(round(summary(pos[ratio>3]$pred_inc),3))
  cat("  among ratio<=1.6 stands, pred_inc median: ",
      round(median(pos[ratio<=1.6]$pred_inc),3),
      " ; among ratio>1.6, pred_inc median: ", round(median(pos[ratio>1.6]$pred_inc),3), "\n")
  invisible(d)
}
dP <- f("PLANTED"); dT <- f("PCT")
saveRDS(list(PLANTED=dP, PCT=dT), "mgmt_diag_perstand.rds")
cat("\nDONE\n")

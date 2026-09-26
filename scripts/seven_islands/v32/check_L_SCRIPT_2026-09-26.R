suppressPackageStartupMessages(library(data.table))
co <- readRDS("/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds")
cat("coef object:\n"); str(co, max.level=1)
t0 <- fread("out/v141L_meas/c001_t1_split_tree.csv"); a <- fread("out/v141L_meas/c001_pred_yr1_tree.csv"); b <- fread("out/v141off_meas/c001_pred_yr1_tree.csv")
t0o <- fread("out/v141off_meas/c001_t1_split_tree.csv"); stopifnot(identical(t0$dbh, t0o$dbh))
x <- merge(merge(t0[,.(STAND,tree,d0=dbh)], a[,.(STAND,tree,dL=dbh)], by=c("STAND","tree")), b[,.(STAND,tree,dO=dbh)], by=c("STAND","tree"))
x <- x[is.finite(d0) & (dO-d0) > 1e-6]; x[, r := (dL-d0)/(dO-d0)]
x[, cls := cut(d0, c(0,12.7,13.3,13.9,14.5,15.0,20,30,100), right=FALSE)]
print(x[, .(n=.N, r_min=round(min(r),5), r_med=round(median(r),5), r_max=round(max(r),5)), by=cls][order(cls)])
lam <- tryCatch(co$lambda, error=function(e) NA); cat("lambda from rds:", lam, "\n")
fwrite(x[, .(n=.N, r_min=min(r), r_med=median(r), r_max=max(r)), by=cls][order(cls)], "v33_L_implementation_check_DATA_2026-09-26.csv")
ss <- function(d, lo=12.7, hi=15) { u <- pmin(pmax((d-lo)/(hi-lo),0),1); u*u*(3-2*u) }
x[, expct := 1 + (lam-1)*ss(d0)]; x[, dev := r/expct]
s <- x[, .(n=.N, dev_min=min(dev), dev_max=max(dev), spread=max(dev)-min(dev)), by=STAND]
cat("stands:", nrow(s), " stands with any tree off expected by >1e-4:", sum(abs(s$dev_min-1)>1e-4 | abs(s$dev_max-1)>1e-4), "\n")
cat("within-stand spread of dev (max):", round(max(s$spread),6), " trees exactly as specified (|dev-1|<1e-4):", mean(abs(x$dev-1)<1e-4), "\n")
print(head(s[order(dev_min)], 5))
fwrite(s, "v33_L_implementation_bystand_DATA_2026-09-26.csv")

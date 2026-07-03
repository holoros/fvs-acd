# Compare robust size-aware direct-effect estimators per class. Aggregates only.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
W <- as.data.table(readRDS("Wfull.rds"))
clamp <- function(x,lo=0.7,hi=1.6) pmax(lo,pmin(hi,x))

est <- function(cls, floor){
  d <- W[mgmt==cls]
  d[, obs_inc := BA_o - BA_t1]
  d[, pred_inc := v129x.BA - BA_t1]
  d[, ba0 := BA_t1]
  # (0) current: ratio of class-mean increments
  rom <- mean(d$obs_inc,na.rm=TRUE)/mean(d$pred_inc,na.rm=TRUE)
  # floor-restricted set: predicted-untreated increment reliably positive
  s <- d[is.finite(pred_inc) & pred_inc>=floor & is.finite(obs_inc)]
  n_s <- nrow(s)
  # (a) log-scale geometric mean of obs/pred among obs_inc>0 & pred_inc>=floor
  sp <- s[obs_inc>0]
  geo <- exp(mean(log(sp$obs_inc) - log(sp$pred_inc)))
  geomed <- exp(median(log(sp$obs_inc) - log(sp$pred_inc)))
  # (b) size (initial-BA) weighted ratio of increment sums on floor set
  wtd <- sum(s$ba0*s$obs_inc)/sum(s$ba0*s$pred_inc)
  # BA-weighted geometric mean of per-stand ratio (obs>0)
  wgeo <- exp(sum(sp$ba0*(log(sp$obs_inc)-log(sp$pred_inc)))/sum(sp$ba0))
  # (c) ratio-of-means restricted to floor set
  romf <- mean(s$obs_inc)/mean(s$pred_inc)
  # median per-stand ratio on floor set
  medr <- median(s$obs_inc/s$pred_inc)
  # (d) additive release (m2/ha over interval), full class and floor set
  add_all <- mean(d$obs_inc,na.rm=TRUE) - mean(d$pred_inc,na.rm=TRUE)
  add_med <- median(d$obs_inc - d$pred_inc, na.rm=TRUE)
  data.table(cls, floor, n_full=nrow(d), n_floor=n_s,
    rom=round(rom,3), romf=round(romf,3), geo=round(geo,3), geomed=round(geomed,3),
    wtd=round(wtd,3), wgeo=round(wgeo,3), medr=round(medr,3),
    add_all=round(add_all,3), add_med=round(add_med,3),
    geo_clamped=round(clamp(geo),3), wgeo_clamped=round(clamp(wgeo),3))
}
res <- rbindlist(lapply(c("PLANTED","PCT"), function(c) rbindlist(lapply(c(0.5,1.0,1.5), function(fl) est(c,fl)))))
print(res)
cat("\nInterpretation columns: rom=ratio-of-means(current, pre-clamp); romf=ratio-of-means on floor set;\n")
cat("geo=geometric mean obs/pred (floor+obs>0); wgeo=BA-weighted geo; medr=median per-stand ratio; add=additive m2/ha.\n")

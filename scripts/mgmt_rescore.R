# Re-score v12.10.1 under robust modifier specs. Reuse the exact release machinery from
# mgmt_modifier_fit.R (additive-on-positive-reference). Report managed bias + gap to OSM. Aggregates only.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
W0 <- as.data.table(readRDS("Wfull.rds"))
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
dg_metrics <- c("BA","SDI","QMD","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
models <- c("v129x","v1210","osm")
biaspct <- function(W,mdl,m,idx) 100*(mean(W[[paste0(mdl,".",m)]][idx],na.rm=TRUE)/mean(W[[paste0(m,"_o")]][idx],na.rm=TRUE)-1)
mae <- function(W,mdl,idx) mean(abs(sapply(M, function(m) biaspct(W,mdl,m,idx))))

build <- function(planted_mult, pct_a, pct_b=0.03){
  W <- copy(W0)
  mfac <- rep(1, nrow(W))
  mfac[W$mgmt=="PLANTED"] <- planted_mult
  tst_use <- W$tst; tst_use[W$mgmt=="PCT" & !is.finite(tst_use)] <- 10
  mfac[W$mgmt=="PCT"] <- 1 + pct_a*exp(-pct_b*tst_use[W$mgmt=="PCT"])
  mfac[!is.finite(mfac)] <- 1; mfac <- pmax(0.5, pmin(1.8, mfac))
  for(m in dg_metrics){
    pinc <- W[[paste0("v129x.",m)]] - W[[paste0(m,"_t1")]]
    posref <- ave(pmax(pinc,0), W$mgmt, FUN=function(z) mean(z,na.rm=TRUE))
    rel <- (mfac-1) * pmax(pinc, posref)
    W[[paste0("v1210.",m)]] <- W[[paste0("v129x.",m)]] + rel
  }
  W[["v1210.TOPHT"]] <- W[["TOPHT_t1"]] + (W[["v129x.TOPHT"]]-W[["TOPHT_t1"]])
  W
}
report <- function(tag, planted_mult, pct_a){
  W <- build(planted_mult, pct_a)
  pl<-which(W$mgmt=="PLANTED"); pc<-which(W$mgmt=="PCT"); mg<-which(W$mgmt%in%c("PLANTED","PCT")); no<-which(W$mgmt=="NONE")
  cat(sprintf("\n[%s] planted_mult=%.3f pct_a=%.3f (pct_mult@10yr=%.3f)\n", tag, planted_mult, pct_a, 1+pct_a*exp(-0.03*10)))
  cat(sprintf("  TOTVOL bias%%   PLANTED %+.1f (osm %+.1f) | PCT %+.1f (osm %+.1f) | MANAGED %+.1f (osm %+.1f) | NONE %+.1f\n",
    biaspct(W,"v1210","TOTVOL",pl), biaspct(W,"osm","TOTVOL",pl),
    biaspct(W,"v1210","TOTVOL",pc), biaspct(W,"osm","TOTVOL",pc),
    biaspct(W,"v1210","TOTVOL",mg), biaspct(W,"osm","TOTVOL",mg),
    biaspct(W,"v1210","TOTVOL",no)))
  cat(sprintf("  BA bias%%      PLANTED %+.1f (osm %+.1f) | PCT %+.1f (osm %+.1f) | MANAGED %+.1f (osm %+.1f)\n",
    biaspct(W,"v1210","BA",pl), biaspct(W,"osm","BA",pl),
    biaspct(W,"v1210","BA",pc), biaspct(W,"osm","BA",pc),
    biaspct(W,"v1210","BA",mg), biaspct(W,"osm","BA",mg)))
  cat(sprintf("  MAE(9metrics) PLANTED %.1f (osm %.1f) | PCT %.1f (osm %.1f) | MANAGED %.1f (osm %.1f)\n",
    mae(W,"v1210",pl), mae(W,"osm",pl), mae(W,"v1210",pc), mae(W,"osm",pc),
    mae(W,"v1210",mg), mae(W,"osm",mg)))
}
# baseline current clamped
report("CURRENT clamp", 1.600, 0.600)
# robust candidates (from mgmt_estimators.R):
report("S1 geo floor1.0", 1.486, 0.791)   # pct geo>clamp
report("S2 geo floor1.5", 1.271, 0.600)
report("S4 median floor1.5", 1.196, 0.389)  # both clear clamp
report("S6 mixed geo/med f1.0", 1.486, 0.226)  # planted geo, pct median: both clear

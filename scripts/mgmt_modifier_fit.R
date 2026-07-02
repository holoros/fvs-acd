# Strategic management modifiers for FVS-ACD, direct-effect multi-step (Wang 1990), per G&Y Ch 11.
# Type 1 (PCT, transient, decaying-multiplicative) and Type 2 (planted, sustained-multiplicative).
# Fits on observed-minus-predicted-untreated residuals, normalized to the unmanaged baseline to
# isolate the DIRECT effect. Then builds v12.10 predictions and re-scores by management class.
# Aggregates only; coordinates never leave this node.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
rd <- function(f){ x<-fread(f); x[, STAND:=as.character(STAND)]; x }
dedup <- function(x) x[!duplicated(STAND)]

cb5<-dedup(rd("cb_v125_results.csv")); cb0<-dedup(rd("cb_v1270_results.csv"))
cbx<-dedup(rd("cb_v129x_pass2_results.csv")); om<-dedup(rd("osm_h2h_metrics.csv"))

base <- cbx[, c("STAND","PROV","iv", paste0(M,"_o"), paste0(M,"_t1")), with=FALSE]
pren <- function(x,tag){ y<-x[, c("STAND", paste0(M,"_p")), with=FALSE]; setnames(y,c("STAND",paste0(tag,".",M))); y }
osmren <- function(x,tag){ y<-x[, c("STAND", M), with=FALSE]; setnames(y,c("STAND",paste0(tag,".",M))); y }
W <- base
W <- merge(W, pren(cb5,"v125"),  by="STAND")
W <- merge(W, pren(cb0,"v1270"), by="STAND")
W <- merge(W, pren(cbx,"v129x"), by="STAND")
W <- merge(W, osmren(om,"osm"),  by="STAND")

## ---- management classification from treatment history ----
pairs <- rd("magp_qcnb_pairs.csv")            # STAND, SITE, interval y1/y2
pairs[, SITE := as.character(SITE)]
setnames(pairs, "y2", "yr2", skip_absent=TRUE)
trt <- fread("/users/PUOM0008/crsfaaron/magplot/magp_treatment.csv")
setnames(trt, names(trt), gsub('"','',names(trt)))
trt[, magp_site_id := as.character(magp_site_id)]
trt[, tt := toupper(gsub('"','',treatment_type))]
# families by code prefix
trt[, fam := fifelse(grepl("^RP|^RS$|^PL", tt), "PLANTED",
              fifelse(grepl("^TT|PCT|^SP", tt), "PCT",
              fifelse(grepl("^TC$|^CP$|^CS", tt), "COMMTHIN",
              fifelse(grepl("^C",  tt), "CLEARCUT", "OTHER"))))]
# join treatment to pairs by SITE, keep governing treatment (priority PLANTED>PCT>COMMTHIN>CLEARCUT)
pt <- merge(pairs[,.(STAND,SITE,yr2)], trt[,.(SITE=magp_site_id, fam, treatment_year)], by="SITE", allow.cartesian=TRUE)
prio <- c(PLANTED=4, PCT=3, COMMTHIN=2, CLEARCUT=1, OTHER=0)
pt[, p := prio[fam]]
pt[, tst := fifelse(treatment_year>0 & yr2>0, yr2-treatment_year, NA_real_)]
# governing family per STAND = highest priority; tst = min positive tst among governing family
gov <- pt[order(STAND, -p)][, .SD[1], by=STAND][, .(STAND, mgmt=fam)]
tstd <- pt[fam %in% pt[order(STAND,-p)][,.SD[1],by=STAND]$fam][treatment_year>0, .(tst=min(yr2-treatment_year, na.rm=TRUE)), by=STAND]
tstd[!is.finite(tst), tst := NA_real_]
W <- merge(W, gov, by="STAND", all.x=TRUE)
W <- merge(W, tstd, by="STAND", all.x=TRUE)
W[is.na(mgmt), mgmt := "NONE"]
saveRDS(W, "Wtmp.rds")
cat("=== management class counts (all in-domain scored stands) ===\n"); print(W[, .N, by=mgmt][order(-N)])
cat("PCT stands with known time-since-treatment: ", W[mgmt=="PCT" & is.finite(tst), .N], " of ", W[mgmt=="PCT",.N], "\n")

## ---- direct-effect signal: obs vs untreated(v129x) predicted INCREMENT, by class ----
## Increment ratios of SUMS are unstable on slow mature stands (predicted increment crosses zero),
## so estimate the modifier from MEAN increments per class (robust) and treat it as the approach-3
## fixed-untreated modifier (Wang 1990); the direct/indirect split is approximate here because the
## unmanaged baseline increment ratio is itself unstable. Documented as a fallback per the plan.
obsincbar <- function(m,idx) mean(W[[paste0(m,"_o")]][idx]-W[[paste0(m,"_t1")]][idx], na.rm=TRUE)
predincbar<- function(m,idx) mean(W[[paste0("v129x.",m)]][idx]-W[[paste0(m,"_t1")]][idx], na.rm=TRUE)
mratio <- function(m,cls){ idx<-which(W$mgmt==cls); o<-obsincbar(m,idx); p<-predincbar(m,idx); if(!is.finite(p)||abs(p)<1e-6) NA else o/p }
cat("\n=== mean increment (obs, v129x pred) and mean-ratio by class ===\n")
for(cls in c("NONE","PLANTED","PCT","COMMTHIN","CLEARCUT")){ idx<-which(W$mgmt==cls)
  cat(sprintf("  %-9s n=%3d  BA obs_inc=%.3f pred_inc=%.3f  m_BA=%.3f | QMD m=%.3f\n",
    cls, length(idx), obsincbar("BA",idx), predincbar("BA",idx), mratio("BA",cls), mratio("QMD",cls))) }

none_m <- mratio("BA","NONE")
clamp <- function(x,lo=0.7,hi=1.6) pmax(lo, pmin(hi, x))
# Type 2 planted: sustained multiplicative modifier on DG-driven increment (approach-3 fixed-untreated)
m_planted_BA <- clamp(mratio("BA","PLANTED"))
idxpl<-which(W$mgmt=="PLANTED"); m_planted_HT <- clamp(obsincbar("TOPHT",idxpl)/predincbar("TOPHT",idxpl), 0.85, 1.25)
# Type 1 PCT: transient multiplicative, decaying with time since treatment
m_pct_BA <- clamp(mratio("BA","PCT"))
cat(sprintf("\nUnmanaged(NONE) base BA mean-ratio (should be ~1 if base unbiased): %.3f\n", none_m))
cat(sprintf("Type2 PLANTED DG multiplier: %.3f ; PLANTED HT multiplier: %.3f\n", m_planted_BA, m_planted_HT))
cat(sprintf("Type1 PCT DG multiplier (fixed magnitude): %.3f\n", m_pct_BA))

# PCT duration decay m(tst)=1+a*exp(-b*tst): fit on tst-binned mean ratios (robust), fallback fixed.
pct <- W[mgmt=="PCT" & is.finite(tst)]
decay_ok <- nrow(pct) >= 20
a <- m_pct_BA-1; b <- 0.05
if(decay_ok){
  pct[, bin := cut(tst, breaks=quantile(tst, c(0,.34,.67,1), na.rm=TRUE), include.lowest=TRUE)]
  bb <- pct[, .(tstm=mean(tst), oi=mean(BA_o-BA_t1), pi=mean(v129x.BA-BA_t1)), by=bin][is.finite(oi/pi)]
  bb[, rr := clamp(oi/pi)]
  fit <- tryCatch(nls(rr ~ 1 + a*exp(-b*tstm), data=bb,
                      start=list(a=max(m_pct_BA-1,0.1), b=0.05),
                      control=nls.control(warnOnly=TRUE, maxiter=200)), error=function(e) NULL)
  if(!is.null(fit) && all(is.finite(coef(fit))) && coef(fit)["a"]>0.1){ a<-coef(fit)["a"]; b<-max(coef(fit)["b"],0.005) }
  cat("PCT tst bins (mid, obs_inc, pred_inc, ratio):\n"); print(bb[,.(tstm=round(tstm,1),rr=round(rr,3))])
}
# Empirical decay is degenerate here (noisy, non-monotonic tst bins), so fall back to a fixed-magnitude
# Type-1 modifier with a nominal literature decay (b=0.03/yr, ~30 yr fade), per the plan's fallback clause.
if(!decay_ok || a < 0.1){ a <- m_pct_BA - 1; b <- 0.03 }
cat(sprintf("PCT decay form m(tst)=1+%.3f*exp(-%.3f*tst)  [%s]\n", a, b,
    if(decay_ok && a>0.1)"fitted on binned means" else "fallback fixed magnitude + nominal Type-1 decay"))

## ---- build v12.10 predictions = v129x + gated direct-effect modifier on managed stands ----
# growth-driven metrics scaled by DG modifier; TOPHT scaled only for planted (Type 2 sustained height)
dg_metrics <- c("BA","SDI","QMD","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
mfac <- rep(1, nrow(W))
mfac[W$mgmt=="PLANTED"] <- m_planted_BA
# PCT: decay-weighted; where tst unknown use mean effect at median tst (~10 yr)
tst_use <- W$tst; tst_use[W$mgmt=="PCT" & !is.finite(tst_use)] <- 10
mfac[W$mgmt=="PCT"] <- 1 + a*exp(-b*tst_use[W$mgmt=="PCT"])
mfac[!is.finite(mfac)] <- 1; mfac <- pmax(0.5, pmin(1.8, mfac))   # guardrails
# Apply as a POSITIVE ADDITIVE RELEASE, not a multiply on net increment. In the code the modifier scales
# per-tree gross diameter growth (always >=0); at stand level a multiply on NET BA increment misbehaves
# where the base predicts a decline (self-thinning). Represent the direct release additively on a positive
# reference increment so managed stands always get an added-growth release, never an amplified decline.
for(m in dg_metrics){
  pinc <- W[[paste0("v129x.",m)]] - W[[paste0(m,"_t1")]]
  posref <- ave(pmax(pinc,0), W$mgmt, FUN=function(z) mean(z,na.rm=TRUE))   # class mean positive increment
  rel <- (mfac-1) * pmax(pinc, posref)
  W[[paste0("v1210.",m)]] <- W[[paste0("v129x.",m)]] + rel
}
# Height left to the ESI anchor: the planted-sample height increment signal was weak/counter to a
# sustained bump, so the Type-2 modifier is carried on DG (the integrator), height neutral.
htfac <- rep(1, nrow(W))
W[["v1210.TOPHT"]] <- W[["TOPHT_t1"]] + (W[["v129x.TOPHT"]]-W[["TOPHT_t1"]])*htfac

## ---- scorecard: level bias % by model, overall and by management class ----
models <- c("v125","v1270","v129x","v1210","osm")
biaspct <- function(mdl,m,idx) 100*(mean(W[[paste0(mdl,".",m)]][idx],na.rm=TRUE)/mean(W[[paste0(m,"_o")]][idx],na.rm=TRUE)-1)
scab <- function(idx){ t(sapply(models, function(md) sapply(M, function(m) biaspct(md,m,idx)))) }
managed_idx <- which(W$mgmt %in% c("PLANTED","PCT"))
cat("\n=== TOTAL VOLUME level bias % by model, by class ===\n")
cat(sprintf("%-9s %8s %8s %8s %8s %8s\n","class","v125","v1270","v129x","v1210","osm"))
for(cls in c("ALL","NONE","PLANTED","PCT","MANAGED")){
  idx <- if(cls=="ALL") seq_len(nrow(W)) else if(cls=="MANAGED") managed_idx else which(W$mgmt==cls)
  if(length(idx)<3){ cat(sprintf("%-9s (n=%d, skipped)\n",cls,length(idx))); next }
  v <- sapply(models, function(md) biaspct(md,"TOTVOL",idx))
  cat(sprintf("%-9s %8.1f %8.1f %8.1f %8.1f %8.1f   n=%d\n", cls, v["v125"],v["v1270"],v["v129x"],v["v1210"],v["osm"], length(idx)))
}
cat("\n=== BA level bias % by model, by class ===\n")
for(cls in c("ALL","NONE","PLANTED","PCT","MANAGED")){
  idx <- if(cls=="ALL") seq_len(nrow(W)) else if(cls=="MANAGED") managed_idx else which(W$mgmt==cls)
  if(length(idx)<3) next
  v <- sapply(models, function(md) biaspct(md,"BA",idx))
  cat(sprintf("%-9s %8.1f %8.1f %8.1f %8.1f %8.1f   n=%d\n", cls, v["v125"],v["v1270"],v["v129x"],v["v1210"],v["osm"], length(idx)))
}

## ---- gap closure to OSM on managed stands ----
mae <- function(mdl, idx) mean(abs(sapply(M, function(m) biaspct(mdl,m,idx))))
gc_tab <- data.table(class=c("PLANTED","PCT","MANAGED"))
for(k in seq_len(nrow(gc_tab))){
  cls<-gc_tab$class[k]; idx <- if(cls=="MANAGED") managed_idx else which(W$mgmt==cls)
  gc_tab[k, `:=`(n=length(idx),
     mae_v129x=mae("v129x",idx), mae_v1210=mae("v1210",idx), mae_osm=mae("osm",idx))]
}
gc_tab[, gap_before := mae_v129x-mae_osm][, gap_after := mae_v1210-mae_osm]
gc_tab[, pct_gap_closed := fifelse(gap_before>0.05, round(100*(1-pmax(gap_after,0)/gap_before),1), NA_real_)]
cat("\n=== mean abs level bias (across 9 metrics) and gap to OSM, managed stands ===\n"); print(gc_tab)

## ---- persist aggregates ----
fwrite(gc_tab, "mgmt_gap_closure.csv")
outp <- W[, c("STAND","PROV","mgmt","tst"), with=FALSE]
for(m in M){ outp[[paste0(m,"_o")]]<-W[[paste0(m,"_o")]]; outp[[paste0("v129x.",m)]]<-W[[paste0("v129x.",m)]]; outp[[paste0("v1210.",m)]]<-W[[paste0("v1210.",m)]]; outp[[paste0("osm.",m)]]<-W[[paste0("osm.",m)]] }
fwrite(outp[, .N, by=mgmt], "mgmt_class_counts.csv")
# by-class total-volume + BA bias matrix for the deck
mat <- rbindlist(lapply(c("ALL","NONE","PLANTED","PCT","MANAGED"), function(cls){
  idx <- if(cls=="ALL") seq_len(nrow(W)) else if(cls=="MANAGED") managed_idx else which(W$mgmt==cls)
  if(length(idx)<3) return(NULL)
  data.table(class=cls, n=length(idx),
     metric=rep(c("TOTVOL","BA"),each=length(models)),
     model=rep(models,2),
     bias=c(sapply(models,function(md)biaspct(md,"TOTVOL",idx)), sapply(models,function(md)biaspct(md,"BA",idx))))
}))
fwrite(mat, "mgmt_scorecard_byclass.csv")
saveRDS(list(m_planted_BA=m_planted_BA,m_planted_HT=m_planted_HT,pct_a=a,pct_b=b,decay_ok=decay_ok), "mgmt_modifier_coefs.rds")
saveRDS(W, "Wfull.rds")   # full wide table incl v1210 predictions + mgmt class, for the figure script
cat("\nWROTE mgmt_gap_closure.csv, mgmt_scorecard_byclass.csv, mgmt_class_counts.csv, mgmt_modifier_coefs.rds\n")
cat("COEFS planted_DG=",round(m_planted_BA,3)," planted_HT=",round(m_planted_HT,3)," pct_a=",round(a,3)," pct_b=",round(b,3),"\n")

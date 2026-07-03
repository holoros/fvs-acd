# Red-team CV v2: corrected SITE join (dedup), absolute MAE, LOIO + leave-one-province + managed split-half.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
dg_metrics <- c("BA","SDI","QMD","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
W <- as.data.table(readRDS("Wfull.rds"))
pairs <- fread("magp_qcnb_pairs.csv"); pairs[, STAND:=as.character(STAND)]; pairs[, SITE:=as.character(SITE)]
pu <- pairs[!duplicated(STAND), .(STAND,SITE)]           # dedup: one SITE per STAND
W <- merge(W, pu, by="STAND", all.x=TRUE)
W[is.na(SITE), SITE := paste0("solo_",STAND)]
stopifnot(nrow(W)==705)
clamp <- function(x,lo=0.7,hi=1.6) pmax(lo, pmin(hi, x))
biaspct <- function(pred,obs,idx) 100*(mean(pred[idx],na.rm=TRUE)/mean(obs[idx],na.rm=TRUE)-1)
fit_coefs <- function(tr){
  oinc <- W$BA_o - W$BA_t1; pinc <- W$v129x.BA - W$BA_t1
  mr <- function(cls){ i<-tr & W$mgmt==cls; p<-mean(pinc[i],na.rm=TRUE); if(!is.finite(p)||abs(p)<1e-6) NA else mean(oinc[i],na.rm=TRUE)/p }
  list(planted=clamp(mr("PLANTED")), pct=clamp(mr("PCT")))
}
ap_train_rows <- rep(TRUE,nrow(W))
posref_train <- function(m){
  pinc <- W[[paste0("v129x.",m)]] - W[[paste0(m,"_t1")]]
  tapply(pmax(pinc,0)[ap_train_rows], W$mgmt[ap_train_rows], function(z) mean(z,na.rm=TRUE))
}
build_pred <- function(cf, b=0.03){
  mfac <- rep(1, nrow(W)); mfac[W$mgmt=="PLANTED"] <- cf$planted
  a <- cf$pct - 1; tst_use <- W$tst; tst_use[W$mgmt=="PCT" & !is.finite(tst_use)] <- 10
  mfac[W$mgmt=="PCT"] <- 1 + a*exp(-b*tst_use[W$mgmt=="PCT"])
  mfac[!is.finite(mfac)] <- 1; mfac <- pmax(0.5, pmin(1.8, mfac))
  out <- list()
  for(m in dg_metrics){ pr<-posref_train(m); pref<-pr[W$mgmt]; pref[is.na(pref)]<-0
    pinc <- W[[paste0("v129x.",m)]]-W[[paste0(m,"_t1")]]
    out[[m]] <- W[[paste0("v129x.",m)]] + (mfac-1)*pmax(pinc,pref) }
  out
}
managed <- which(W$mgmt %in% c("PLANTED","PCT"))
mae_abs <- function(getpred, idx) mean(abs(sapply(M, function(m){
  pv <- if(m %in% dg_metrics) getpred(m) else W[[paste0("v129x.",m)]]; biaspct(pv, W[[paste0(m,"_o")]], idx) })))
maeref <- function(mdl,idx) mean(abs(sapply(M, function(m) biaspct(W[[paste0(mdl,".",m)]], W[[paste0(m,"_o")]], idx))))

cf_all <- fit_coefs(rep(TRUE,nrow(W)))
cat("Full-fit coefs planted=",round(cf_all$planted,3)," pct=",round(cf_all$pct,3)," (both clamp ceiling 1.6)\n")

## LEAVE-ONE-INSTALLATION-OUT (SITE)
oos <- setNames(lapply(M,function(x) rep(NA_real_,nrow(W))), M)
foldcoef <- data.table()
for(s in unique(W$SITE[managed])){
  hold <- which(W$SITE==s & W$mgmt %in% c("PLANTED","PCT"))
  ap_train_rows <<- W$SITE!=s
  cf <- fit_coefs(ap_train_rows)
  if(!is.finite(cf$planted)) cf$planted<-cf_all$planted
  if(!is.finite(cf$pct)) cf$pct<-cf_all$pct
  foldcoef <- rbind(foldcoef, data.table(planted=cf$planted,pct=cf$pct))
  pr <- build_pred(cf)
  for(m in dg_metrics) oos[[m]][hold] <- pr[[m]][hold]
  for(m in setdiff(M,dg_metrics)) oos[[m]][hold] <- W[[paste0("v129x.",m)]][hold]
}
getoos <- function(m) oos[[m]]
cat("\n== LEAVE-ONE-INSTALLATION-OUT CV (out-of-sample) ==\n")
cat(sprintf("fold coef range: planted [%.2f,%.2f] pct [%.2f,%.2f]\n",
    min(foldcoef$planted),max(foldcoef$planted),min(foldcoef$pct),max(foldcoef$pct)))
for(cls in c("PLANTED","PCT","MANAGED")){
  idx <- if(cls=="MANAGED") managed else which(W$mgmt==cls)
  cat(sprintf("  %-8s n=%d  TOTVOL oos=%.1f (v129x %.1f osm %.1f) | absMAE oos=%.1f (v129x %.1f osm %.1f)\n",
    cls,length(idx), biaspct(oos$TOTVOL,W$TOTVOL_o,idx),biaspct(W$v129x.TOTVOL,W$TOTVOL_o,idx),biaspct(W$osm.TOTVOL,W$TOTVOL_o,idx),
    mae_abs(getoos,idx), maeref("v129x",idx), maeref("osm",idx)))
}

## LEAVE-ONE-PROVINCE-OUT
oosp <- setNames(lapply(M,function(x) rep(NA_real_,nrow(W))), M)
for(pv in unique(W$PROV)){
  hold <- which(W$PROV==pv & W$mgmt %in% c("PLANTED","PCT")); if(!length(hold)) next
  ap_train_rows <<- W$PROV!=pv
  cf <- fit_coefs(ap_train_rows); if(!is.finite(cf$planted))cf$planted<-cf_all$planted; if(!is.finite(cf$pct))cf$pct<-cf_all$pct
  pr <- build_pred(cf)
  for(m in dg_metrics) oosp[[m]][hold]<-pr[[m]][hold]
  for(m in setdiff(M,dg_metrics)) oosp[[m]][hold]<-W[[paste0("v129x.",m)]][hold]
}
getoosp <- function(m) oosp[[m]]
cat("\n== LEAVE-ONE-PROVINCE-OUT CV ==\n")
for(cls in c("PLANTED","PCT","MANAGED")){
  idx <- if(cls=="MANAGED") managed else which(W$mgmt==cls); idx<-idx[!is.na(oosp$TOTVOL[idx])]
  cat(sprintf("  %-8s n=%d  TOTVOL oos=%.1f | absMAE oos=%.1f (osm %.1f)\n",
    cls,length(idx),biaspct(oosp$TOTVOL,W$TOTVOL_o,idx),mae_abs(getoosp,idx),maeref("osm",idx)))
}

## MANAGED SPLIT-HALF (random, 200 reps) : fit on half, apply to other half
set.seed(42)
cat("\n== MANAGED SPLIT-HALF (200 random splits, out-of-fold) ==\n")
res <- data.table()
for(rep in 1:200){
  h <- sample(managed, length(managed)%/%2)
  otherA <- setdiff(managed,h)
  # fit on h, apply to otherA
  ap_train_rows <<- rep(FALSE,nrow(W)); ap_train_rows[h]<-TRUE
  cfh <- fit_coefs(ap_train_rows); if(!is.finite(cfh$planted))cfh$planted<-1.6; if(!is.finite(cfh$pct))cfh$pct<-1.6
  prh <- build_pred(cfh)
  getA <- function(m) prh[[m]]
  maeA <- mae_abs(getA, otherA)
  res <- rbind(res, data.table(mae_v1210=maeA, mae_v129x=maeref("v129x",otherA), mae_osm=maeref("osm",otherA)))
}
cat(sprintf("  held-out MANAGED absMAE: v1210 mean=%.1f (sd %.1f)  v129x=%.1f  osm=%.1f  | %% reps v1210<v129x = %.0f\n",
   mean(res$mae_v1210),sd(res$mae_v1210),mean(res$mae_v129x),mean(res$mae_osm), 100*mean(res$mae_v1210<res$mae_v129x)))
cat("DONE\n")

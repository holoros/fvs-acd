# CV battery for robust ADDITIVE direct-effect release vs current clamped multiplier.
# Additive release per class per metric = trimmed mean (10%) of per-stand (obs_inc - pred_inc),
# fit on training fold, applied to held-out fold. Type-2 planted constant; PCT constant release at
# scorecard step (Type-1 decay documented for the engine). Aggregates only; coordinates stay here.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
dg <- c("BA","SDI","QMD","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
W <- as.data.table(readRDS("Wfull.rds"))
pairs <- fread("magp_qcnb_pairs.csv"); pairs[,STAND:=as.character(STAND)]; pairs[,SITE:=as.character(SITE)]
W <- merge(W, pairs[!duplicated(STAND),.(STAND,SITE)], by="STAND", all.x=TRUE)
W[is.na(SITE), SITE:=paste0("solo_",STAND)]; stopifnot(nrow(W)==705)
biaspct <- function(pred,obs,idx) 100*(mean(pred[idx],na.rm=TRUE)/mean(obs[idx],na.rm=TRUE)-1)
tmean <- function(x) mean(x, trim=0.10, na.rm=TRUE)
managed <- which(W$mgmt %in% c("PLANTED","PCT"))

# fit additive release per class per metric on training rows
fit_add <- function(tr){
  rel <- list()
  for(cl in c("PLANTED","PCT")){ i <- tr & W$mgmt==cl
    rel[[cl]] <- sapply(dg, function(m) tmean((W[[paste0(m,"_o")]]-W[[paste0(m,"_t1")]])[i] -
                                              (W[[paste0("v129x.",m)]]-W[[paste0(m,"_t1")]])[i])) }
  rel
}
build_add <- function(rel){
  out <- list()
  for(m in dg){ add <- rep(0,nrow(W))
    add[W$mgmt=="PLANTED"] <- rel[["PLANTED"]][m]; add[W$mgmt=="PCT"] <- rel[["PCT"]][m]
    out[[m]] <- W[[paste0("v129x.",m)]] + add }
  out
}
mae_get <- function(getp, idx) mean(abs(sapply(M, function(m){
  pv <- if(m %in% dg) getp(m) else W[[paste0("v129x.",m)]]; biaspct(pv,W[[paste0(m,"_o")]],idx)})))
maeref <- function(mdl,idx) mean(abs(sapply(M, function(m) biaspct(W[[paste0(mdl,".",m)]],W[[paste0(m,"_o")]],idx))))

rel_all <- fit_add(rep(TRUE,nrow(W)))
cat("=== full-fit additive release (m2/ha etc per metric) ===\n")
cat("PLANTED:\n"); print(round(rel_all$PLANTED,3)); cat("PCT:\n"); print(round(rel_all$PCT,3))

## in-sample scorecard
prA <- build_add(rel_all); getA <- function(m) prA[[m]]
cat("\n=== IN-SAMPLE additive scorecard ===\n")
for(cls in c("PLANTED","PCT","MANAGED","NONE")){ idx <- if(cls=="MANAGED") managed else which(W$mgmt==cls)
  cat(sprintf("  %-8s n=%d TOTVOL=%+.1f (osm %+.1f) BA=%+.1f (osm %+.1f) MAE=%.1f (v129x %.1f osm %.1f)\n",
    cls,length(idx), biaspct(getA("TOTVOL"),W$TOTVOL_o,idx),biaspct(W$osm.TOTVOL,W$TOTVOL_o,idx),
    biaspct(getA("BA"),W$BA_o,idx),biaspct(W$osm.BA,W$BA_o,idx),
    mae_get(getA,idx),maeref("v129x",idx),maeref("osm",idx))) }

## LOIO (SITE)
oos <- setNames(lapply(M,function(x) rep(NA_real_,nrow(W))),M)
fold_pl <- c(); fold_pc <- c()
for(s in unique(W$SITE[managed])){ hold <- which(W$SITE==s & W$mgmt%in%c("PLANTED","PCT"))
  rel <- fit_add(W$SITE!=s)
  for(cl in c("PLANTED","PCT")) if(any(!is.finite(rel[[cl]]))) rel[[cl]][!is.finite(rel[[cl]])] <- rel_all[[cl]][!is.finite(rel[[cl]])]
  fold_pl<-c(fold_pl,rel$PLANTED["BA"]); fold_pc<-c(fold_pc,rel$PCT["BA"])
  pr <- build_add(rel); for(m in dg) oos[[m]][hold]<-pr[[m]][hold]
  for(m in setdiff(M,dg)) oos[[m]][hold]<-W[[paste0("v129x.",m)]][hold] }
getoos <- function(m) oos[[m]]
cat(sprintf("\n== LOIO additive CV == (fold BA-release range planted [%.2f,%.2f] pct [%.2f,%.2f])\n",
   min(fold_pl),max(fold_pl),min(fold_pc),max(fold_pc)))
for(cls in c("PLANTED","PCT","MANAGED")){ idx <- if(cls=="MANAGED") managed else which(W$mgmt==cls)
  cat(sprintf("  %-8s TOTVOL oos=%+.1f (osm %+.1f) | absMAE oos=%.1f (v129x %.1f osm %.1f)\n",
    cls,biaspct(oos$TOTVOL,W$TOTVOL_o,idx),biaspct(W$osm.TOTVOL,W$TOTVOL_o,idx),
    mae_get(getoos,idx),maeref("v129x",idx),maeref("osm",idx))) }

## LOPO (PROV)
oosp <- setNames(lapply(M,function(x) rep(NA_real_,nrow(W))),M)
for(pv in unique(W$PROV)){ hold <- which(W$PROV==pv & W$mgmt%in%c("PLANTED","PCT")); if(!length(hold)) next
  rel <- fit_add(W$PROV!=pv)
  for(cl in c("PLANTED","PCT")) if(any(!is.finite(rel[[cl]]))) rel[[cl]][!is.finite(rel[[cl]])]<-rel_all[[cl]][!is.finite(rel[[cl]])]
  pr <- build_add(rel); for(m in dg) oosp[[m]][hold]<-pr[[m]][hold]
  for(m in setdiff(M,dg)) oosp[[m]][hold]<-W[[paste0("v129x.",m)]][hold] }
getoosp <- function(m) oosp[[m]]
cat("\n== LOPO additive CV ==\n")
for(cls in c("PLANTED","PCT","MANAGED")){ idx <- if(cls=="MANAGED") managed else which(W$mgmt==cls); idx<-idx[!is.na(oosp$TOTVOL[idx])]
  cat(sprintf("  %-8s TOTVOL oos=%+.1f | absMAE oos=%.1f (osm %.1f)\n",
    cls,biaspct(oosp$TOTVOL,W$TOTVOL_o,idx),mae_get(getoosp,idx),maeref("osm",idx))) }

## split-half 200
set.seed(42); res <- data.table()
for(r in 1:200){ h <- sample(managed,length(managed)%/%2); oth <- setdiff(managed,h)
  rel <- fit_add({z<-rep(FALSE,nrow(W));z[h]<-TRUE;z})
  for(cl in c("PLANTED","PCT")) if(any(!is.finite(rel[[cl]]))) rel[[cl]][!is.finite(rel[[cl]])]<-rel_all[[cl]][!is.finite(rel[[cl]])]
  pr <- build_add(rel); geth <- function(m) pr[[m]]
  res <- rbind(res, data.table(v1210=mae_get(geth,oth), v129x=maeref("v129x",oth), osm=maeref("osm",oth))) }
cat(sprintf("\n== SPLIT-HALF additive (200) == held-out MANAGED absMAE: v1210=%.1f (sd %.1f) v129x=%.1f osm=%.1f | %%<v129x=%.0f | %%<osm=%.0f\n",
   mean(res$v1210),sd(res$v1210),mean(res$v129x),mean(res$osm),100*mean(res$v1210<res$v129x),100*mean(res$v1210<res$osm)))

## unmanaged guardrail: additive touches only managed, NONE untouched by construction
cat("\nNONE guardrail: additive applies only to PLANTED/PCT; NONE identical to v129x (max diff 0)\n")
cat("DONE\n")

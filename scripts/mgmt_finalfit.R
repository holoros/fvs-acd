# Finalize robust fit: additive direct-effect release + equivalent effective DG multiplier for the engine.
# Write result CSVs/rds for the repo. Aggregates only; coordinates stay on Cardinal.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
dg <- c("BA","SDI","QMD","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
W <- as.data.table(readRDS("Wfull.rds"))
tmean <- function(x) mean(x, trim=0.10, na.rm=TRUE)
biaspct <- function(pred,obs,idx) 100*(mean(pred[idx],na.rm=TRUE)/mean(obs[idx],na.rm=TRUE)-1)
managed <- which(W$mgmt %in% c("PLANTED","PCT"))

# robust additive release per class per metric (10% trimmed mean of obs_inc - pred_inc)
rel <- list()
for(cl in c("PLANTED","PCT")){ i <- W$mgmt==cl
  rel[[cl]] <- sapply(dg, function(m) tmean((W[[paste0(m,"_o")]]-W[[paste0(m,"_t1")]])[i] -
                                            (W[[paste0("v129x.",m)]]-W[[paste0(m,"_t1")]])[i])) }

# effective sustained DG multiplier that reproduces the additive BA release through the engine proxy
# rel = (mfac-1)*posref  (posref = class-mean positive predicted-untreated increment) => mfac = 1 + rel/posref
posref <- sapply(c("PLANTED","PCT"), function(cl){ i<-W$mgmt==cl
  pinc <- W$v129x.BA[i]-W$BA_t1[i]; mean(pmax(pinc,0),na.rm=TRUE) })
mfac_eff <- 1 + c(PLANTED=rel$PLANTED["BA"], PCT=rel$PCT["BA"])/posref
cat("posref (class-mean positive BA increment): "); print(round(posref,3))
cat("Robust additive BA release: PLANTED", round(rel$PLANTED["BA"],3), " PCT", round(rel$PCT["BA"],3), "\n")
cat("Equivalent effective sustained DG multiplier: PLANTED", round(mfac_eff["PLANTED"],3),
    " PCT(t=0)", round(mfac_eff["PCT"],3), "\n")

# build final v1210.1 predictions via additive release (engine-faithful proxy) and full by-class scorecard
build_add <- function(){ out<-list(); for(m in dg){ add<-rep(0,nrow(W))
  add[W$mgmt=="PLANTED"]<-rel$PLANTED[m]; add[W$mgmt=="PCT"]<-rel$PCT[m]
  out[[m]]<-W[[paste0("v129x.",m)]]+add }; out }
pr <- build_add(); for(m in dg) W[[paste0("v1210.",m)]]<-pr[[m]]
W[["v1210.TOPHT"]] <- W[["v129x.TOPHT"]]
models <- c("v125","v1270","v129x","v1210","osm")
bp <- function(md,m,idx) biaspct(W[[paste0(md,".",m)]],W[[paste0(m,"_o")]],idx)
mae <- function(md,idx) mean(abs(sapply(M, function(m) bp(md,m,idx))))

# scorecard by class (TOTVOL + BA) and gap closure
scc <- rbindlist(lapply(c("ALL","NONE","PLANTED","PCT","MANAGED"), function(cls){
  idx <- if(cls=="ALL") seq_len(nrow(W)) else if(cls=="MANAGED") managed else which(W$mgmt==cls)
  if(length(idx)<3) return(NULL)
  data.table(class=cls,n=length(idx),metric=rep(c("TOTVOL","BA"),each=length(models)),
    model=rep(models,2), bias=c(sapply(models,function(md)bp(md,"TOTVOL",idx)),sapply(models,function(md)bp(md,"BA",idx)))) }))
fwrite(scc,"mgmt_scorecard_byclass_robust.csv")
gc <- data.table(class=c("PLANTED","PCT","MANAGED"))
for(k in 1:3){ cls<-gc$class[k]; idx<-if(cls=="MANAGED") managed else which(W$mgmt==cls)
  gc[k,`:=`(n=length(idx),mae_v129x=mae("v129x",idx),mae_v1210=mae("v1210",idx),mae_osm=mae("osm",idx))] }
gc[,gap_before:=mae_v129x-mae_osm][,gap_after:=mae_v1210-mae_osm]
gc[,pct_gap_closed:=fifelse(gap_before>0.05,round(100*(1-pmax(gap_after,0)/gap_before),1),NA_real_)]
fwrite(gc,"mgmt_gap_closure_robust.csv")
print(gc)
saveRDS(list(form="additive_direct_effect_release",
  planted_release=rel$PLANTED, pct_release=rel$PCT,
  planted_mult_eff=unname(mfac_eff["PLANTED"]), pct_mult_eff=unname(mfac_eff["PCT"]),
  pct_b=0.03, posref_BA=posref), "mgmt_modifier_coefs_robust.rds")
cat("\nPLANTED per-metric release:\n"); print(round(rel$PLANTED,3))
cat("PCT per-metric release:\n"); print(round(rel$PCT,3))
cat("\nWROTE robust CSVs + coefs\n")

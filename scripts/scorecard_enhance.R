# Enhanced scorecard: TOST equivalence + by-forest-type, five models, v12.9.x final (pass2).
# Aggregates only; no coordinates leave Cardinal. R first, data.table.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")

cb5 <- fread("cb_v125_results.csv"); cb0 <- fread("cb_v1270_results.csv")
cb1 <- fread("cb_v1271cB_results.csv"); cbx <- fread("cb_v129x_pass2_results.csv")
om  <- fread("osm_h2h_metrics.csv")   # per-stand OSM t2 predicted, 9 metrics
for(dt in list(cb5,cb0,cb1,cbx,om)) dt[, STAND := as.character(STAND)]

# --- forest type classification from t1 tree list: percent hardwood BA ---
ti <- fread("magp_qcnb_tree_init.csv"); ti[, STAND := as.character(STAND)]
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC","EC","WH","HE")
ti[, isHW := !(toupper(SP) %in% sw)]
ti <- ti[is.finite(DBH) & DBH >= 4]
ti[, baw := pi*(DBH/200)^2*EXPF]
ft <- ti[, .(pctHW = 100*sum(baw[isHW])/sum(baw)), by=STAND]
ft[, fortype := fifelse(pctHW <= 25, "Softwood", fifelse(pctHW >= 75, "Hardwood", "Mixedwood"))]

# --- ecobucket / finer type lookup ---
eb <- fread("v129_ecobucket_fortype.csv"); eb[, STAND := as.character(STAND)]
eb <- unique(eb[, .(STAND, ecobucket, grp)])

prov <- cbx[, .(STAND, PROV, iv)]
obs <- cbx[, c("STAND", paste0(M,"_o")), with=FALSE]; setnames(obs, c("STAND",M))
t1  <- cbx[, c("STAND", paste0(M,"_t1")), with=FALSE]; setnames(t1, c("STAND",M))
mk  <- function(dt) { x <- dt[, c("STAND", paste0(M,"_p")), with=FALSE]; setnames(x, c("STAND",M)); x }
mkosm <- function(dt){ x <- dt[, c("STAND", M), with=FALSE]; x }
mods <- list(v125=mk(cb5), v1270=mk(cb0), v1271=mk(cb1), v129x=mk(cbx), osm=mkosm(om))

common <- Reduce(intersect, c(list(obs$STAND), lapply(mods, function(x) x$STAND)))
pm <- merge(prov[STAND %in% common], ft[, .(STAND,pctHW,fortype)], by="STAND", all.x=TRUE)
pm <- merge(pm, eb, by="STAND", all.x=TRUE)
pm[is.na(fortype), fortype := "Unknown"]
cat(sprintf("Common stands n=%d (NB %d, QC %d). Forest type: SW %d, MW %d, HW %d, Unk %d\n",
  length(common), sum(pm$PROV=="NB"), sum(pm$PROV=="QC"),
  sum(pm$fortype=="Softwood"), sum(pm$fortype=="Mixedwood"),
  sum(pm$fortype=="Hardwood"), sum(pm$fortype=="Unknown")))

# --- Schuirmann TOST on paired differences d = pred - obs ---
# level: delta = 0.10*mean(obs); increment (PAI): delta = 0.25*mean(obs PAI)
tost <- function(d, delta, alpha=0.05){
  n <- length(d); if(n < 3 || !is.finite(delta) || delta<=0) return(list(equiv=NA, p=NA_real_, ci_lo=NA_real_, ci_hi=NA_real_))
  m <- mean(d); se <- sd(d)/sqrt(n); if(se==0) se <- 1e-9
  tcrit <- qt(1-alpha, n-1)
  ci_lo <- m - tcrit*se; ci_hi <- m + tcrit*se       # (1-2alpha) CI
  t_lower <- (m + delta)/se; p_lower <- pt(t_lower, n-1, lower.tail=FALSE) # H0: mu <= -delta
  t_upper <- (m - delta)/se; p_upper <- pt(t_upper, n-1, lower.tail=TRUE)  # H0: mu >= +delta
  p <- max(p_lower, p_upper)
  list(equiv = (ci_lo > -delta && ci_hi < delta), p = p, ci_lo=ci_lo, ci_hi=ci_hi)
}

rows_lvl <- list(); rows_inc <- list()
score <- function(stset, label, cut){
  if(length(stset) < 8) return(invisible())
  O <- obs[STAND %in% stset]; setkey(O,STAND)
  T1 <- t1[STAND %in% stset]; setkey(T1,STAND)
  ivv <- pm[match(stset, STAND)]$iv; names(ivv) <- stset
  for(mod in names(mods)){
    P <- mods[[mod]][STAND %in% stset]; setkey(P,STAND)
    P <- P[O$STAND]; T1o <- T1[O$STAND]
    for(m in M){
      o <- O[[m]]; p <- P[[m]]; tt <- T1o[[m]]
      # level
      d <- p - o; dl <- 0.10*mean(o); ts <- tost(d, dl)
      rows_lvl[[length(rows_lvl)+1]] <<- data.table(cut=cut, subset=label, model=mod, metric=m, n=length(o),
        obs_mean=mean(o), pred_mean=mean(p), bias_pct=100*(mean(p)/mean(o)-1),
        rmse=sqrt(mean((p-o)^2)), nse=1-sum((o-p)^2)/sum((o-mean(o))^2),
        eqreg_pm=dl, tost_equiv=ts$equiv, tost_p=ts$p)
      # increment (PAI per yr)
      ivm <- ivv[O$STAND]
      pai_o <- (o - tt)/ivm; pai_p <- (p - tt)/ivm
      di <- pai_p - pai_o; dinc <- 0.25*abs(mean(pai_o)); tsi <- tost(di, dinc)
      rows_inc[[length(rows_inc)+1]] <<- data.table(cut=cut, subset=label, model=mod, metric=m, n=length(o),
        pai_obs=mean(pai_o), pai_pred=mean(pai_p), pai_bias=mean(pai_p)-mean(pai_o),
        eqreg_pm=dinc, tost_equiv=tsi$equiv, tost_p=tsi$p)
    }
  }
}

# jurisdiction cuts
score(pm$STAND, "POOLED", "jurisdiction")
score(pm[PROV=="NB"]$STAND, "NB", "jurisdiction")
score(pm[PROV=="QC"]$STAND, "QC", "jurisdiction")
# forest type cuts (pooled across jurisdiction)
for(f in c("Softwood","Mixedwood","Hardwood")) score(pm[fortype==f]$STAND, f, "fortype")
# finer ecobucket cuts
for(g in unique(na.omit(pm$grp))) score(pm[grp==g]$STAND, paste0("grp_",g), "ecobucket")
for(e in unique(na.omit(pm$ecobucket))) score(pm[ecobucket==e]$STAND, paste0("eco_",e), "ecobucket")

L <- rbindlist(rows_lvl); I <- rbindlist(rows_inc)
fwrite(L, "scorecard_level_tost.csv"); fwrite(I, "scorecard_incr_tost.csv")

cat("\n=== LEVEL bias% and TOST equivalence (POOLED, key metrics) ===\n")
print(L[subset=="POOLED" & metric %in% c("BA","TOTVOL","BIOMASS","VALUE"),
        .(model,metric,bias_pct=round(bias_pct,1),nse=round(nse,2),eq10=round(eqreg_pm,1),equiv=tost_equiv,p=round(tost_p,3))])
cat("\n=== By forest type: TOTVOL level bias% + equivalence ===\n")
print(L[cut=="fortype" & metric=="TOTVOL", .(fortype=subset,model,n,bias=round(bias_pct,1),equiv=tost_equiv,p=round(tost_p,3))])
cat("\n=== TOST equivalence PASS COUNT per model (level, POOLED, 9 metrics) ===\n")
print(L[subset=="POOLED", .(equiv_pass=sum(tost_equiv, na.rm=TRUE), of=.N), by=model])
cat("DONE_SCORECARD_ENHANCE\n")

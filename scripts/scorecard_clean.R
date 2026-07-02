# CLEAN single-merge scorecard: one wide table keyed by STAND, no index joins.
# Verifies alignment via cor(o,p). Then TOST + by forest type. Aggregates only.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")

rd <- function(f) { x <- fread(f); x[, STAND := as.character(STAND)]; x }
cb5<-rd("cb_v125_results.csv"); cb0<-rd("cb_v1270_results.csv")
cb1<-rd("cb_v1271cB_results.csv"); cbx<-rd("cb_v129x_pass2_results.csv"); om<-rd("osm_h2h_metrics.csv")

# de-duplicate any repeated STAND (keep first)
dedup <- function(x) x[!duplicated(STAND)]
cb5<-dedup(cb5); cb0<-dedup(cb0); cb1<-dedup(cb1); cbx<-dedup(cbx); om<-dedup(om)

# base: observed + t1 + prov + iv from cbx
base <- cbx[, c("STAND","PROV","iv", paste0(M,"_o"), paste0(M,"_t1")), with=FALSE]
# predictions per model, renamed model.metric
pren <- function(x, tag){ y <- x[, c("STAND", paste0(M,"_p")), with=FALSE]; setnames(y, c("STAND", paste0(tag,".",M))); y }
osmren <- function(x, tag){ y <- x[, c("STAND", M), with=FALSE]; setnames(y, c("STAND", paste0(tag,".",M))); y }
W <- base
W <- merge(W, pren(cb5,"v125"),  by="STAND")
W <- merge(W, pren(cb0,"v1270"), by="STAND")
W <- merge(W, pren(cb1,"v1271"), by="STAND")
W <- merge(W, pren(cbx,"v129x"), by="STAND")
W <- merge(W, osmren(om,"osm"),  by="STAND")

# forest type from t1 tree list
ti <- rd("magp_qcnb_tree_init.csv")
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC","EC","WH","HE")
ti[, isHW := !(toupper(SP) %in% sw)]; ti <- ti[is.finite(DBH) & DBH>=4]; ti[, baw := pi*(DBH/200)^2*EXPF]
ft <- ti[, .(pctHW=100*sum(baw[isHW])/sum(baw)), by=STAND]
ft[, fortype := fifelse(pctHW<=25,"Softwood", fifelse(pctHW>=75,"Hardwood","Mixedwood"))]
eb <- dedup(rd("v129_ecobucket_fortype.csv"))[, .(STAND, ecobucket, grp)]
W <- merge(W, ft[,.(STAND,pctHW,fortype)], by="STAND", all.x=TRUE)
W <- merge(W, eb, by="STAND", all.x=TRUE)
W[is.na(fortype), fortype:="Unknown"]
cat(sprintf("n=%d NB=%d QC=%d | SW=%d MW=%d HW=%d Unk=%d\n", nrow(W), sum(W$PROV=="NB"), sum(W$PROV=="QC"),
  sum(W$fortype=="Softwood"),sum(W$fortype=="Mixedwood"),sum(W$fortype=="Hardwood"),sum(W$fortype=="Unknown")))

mods <- c("v125","v1270","v1271","v129x","osm")
cat("\n=== ALIGNMENT CHECK: cor(obs, pred) POOLED, BA and TOTVOL (should be ~0.85-0.95) ===\n")
for(mo in mods) cat(sprintf("  %-6s BA cor=%.3f  TOTVOL cor=%.3f\n", mo,
  cor(W[["BA_o"]], W[[paste0(mo,".BA")]]), cor(W[["TOTVOL_o"]], W[[paste0(mo,".TOTVOL")]])))

tost <- function(d, delta, alpha=0.05){
  n<-length(d); if(n<3||!is.finite(delta)||delta<=0) return(list(equiv=NA,p=NA_real_))
  m<-mean(d); se<-sd(d)/sqrt(n); if(se==0) se<-1e-9; tcrit<-qt(1-alpha,n-1)
  ci_lo<-m-tcrit*se; ci_hi<-m+tcrit*se
  p<-max(pt((m+delta)/se,n-1,lower.tail=FALSE), pt((m-delta)/se,n-1,lower.tail=TRUE))
  list(equiv=(ci_lo>-delta && ci_hi<delta), p=p)
}
scoreset <- function(D, cut, label){
  if(nrow(D)<8) return(NULL)
  out<-list()
  for(mo in mods) for(m in M){
    o<-D[[paste0(m,"_o")]]; p<-D[[paste0(mo,".",m)]]; tt<-D[[paste0(m,"_t1")]]; iv<-D[["iv"]]
    d<-p-o; dl<-0.10*mean(o); ts<-tost(d,dl)
    pai_o<-(o-tt)/iv; pai_p<-(p-tt)/iv; di<-pai_p-pai_o; dinc<-0.25*abs(mean(pai_o)); tsi<-tost(di,dinc)
    out[[length(out)+1]]<-data.table(cut=cut, subset=label, model=mo, metric=m, n=nrow(D),
      obs_mean=mean(o), pred_mean=mean(p), bias_pct=100*(mean(p)/mean(o)-1),
      rmse=sqrt(mean((p-o)^2)), mae=mean(abs(p-o)), nse=1-sum((o-p)^2)/sum((o-mean(o))^2),
      cor=cor(o,p), tost_lvl_equiv=ts$equiv, tost_lvl_p=ts$p,
      pai_obs=mean(pai_o), pai_pred=mean(pai_p), pai_bias=mean(pai_p)-mean(pai_o),
      tost_inc_equiv=tsi$equiv, tost_inc_p=tsi$p)
  }
  rbindlist(out)
}
R<-list()
R[[1]]<-scoreset(W,"jurisdiction","POOLED")
R[[2]]<-scoreset(W[PROV=="NB"],"jurisdiction","NB")
R[[3]]<-scoreset(W[PROV=="QC"],"jurisdiction","QC")
for(f in c("Softwood","Mixedwood","Hardwood")) R[[length(R)+1]]<-scoreset(W[fortype==f],"fortype",f)
for(g in unique(na.omit(W$grp))) R[[length(R)+1]]<-scoreset(W[grp==g],"ecobucket",paste0("grp_",g))
for(e in unique(na.omit(W$ecobucket))) R[[length(R)+1]]<-scoreset(W[ecobucket==e],"ecobucket",paste0("eco_",e))
S<-rbindlist(R)
fwrite(S,"scorecard_clean_all.csv")

cat("\n=== POOLED bias% | RMSE | NSE | cor | TOST-level equiv, TOTVOL & BA ===\n")
print(S[subset=="POOLED" & metric %in% c("BA","TOTVOL","BIOMASS","VALUE"),
  .(model,metric,bias=round(bias_pct,1),rmse=round(rmse,1),nse=round(nse,2),cor=round(cor,3),eqL=tost_lvl_equiv)])
cat("\n=== TOST level equivalence PASS per model (POOLED, 9 metrics) ===\n")
print(S[subset=="POOLED", .(pass=sum(tost_lvl_equiv,na.rm=TRUE), of=.N, mean_absbias=round(mean(abs(bias_pct)),1), mean_nse=round(mean(nse),2)), by=model])
cat("\n=== By forest type TOTVOL: bias% + NSE + equiv ===\n")
print(S[cut=="fortype" & metric=="TOTVOL", .(ftype=subset,model,n,bias=round(bias_pct,1),nse=round(nse,2),eqL=tost_lvl_equiv)])
cat("DONE_CLEAN\n")

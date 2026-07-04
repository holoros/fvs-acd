# Five-way scorecard INCLUDING v12.10.1 (robust additive release), identical single-keyed-merge scoring.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
M <- c("BA","SDI","QMD","TOPHT","TOTVOL","MERCHVOL","SAWVOL","BIOMASS","VALUE")
rd <- function(f){x<-fread(f); x[, STAND:=as.character(STAND)]; x}
cb5<-rd("cb_v125_results.csv"); cb0<-rd("cb_v1270_results.csv"); cbx<-rd("cb_v129x_pass2_results.csv"); om<-rd("osm_h2h_metrics.csv")
dedup<-function(x) x[!duplicated(STAND)]
cb5<-dedup(cb5);cb0<-dedup(cb0);cbx<-dedup(cbx);om<-dedup(om)
base<-cbx[, c("STAND","PROV","iv",paste0(M,"_o"),paste0(M,"_t1")), with=FALSE]
pren<-function(x,tag){y<-x[,c("STAND",paste0(M,"_p")),with=FALSE]; setnames(y,c("STAND",paste0(tag,".",M))); y}
osmren<-function(x,tag){y<-x[,c("STAND",M),with=FALSE]; setnames(y,c("STAND",paste0(tag,".",M))); y}
W<-base
W<-merge(W,pren(cb5,"v125"),by="STAND"); W<-merge(W,pren(cb0,"v1270"),by="STAND")
W<-merge(W,pren(cbx,"v129x"),by="STAND"); W<-merge(W,osmren(om,"osm"),by="STAND")
# fold in v12.10.1 predictions + mgmt class from Wfull.rds
Wf<-readRDS("Wfull.rds"); setDT(Wf); Wf[, STAND:=as.character(STAND)]
v1210cols<-c("STAND",paste0("v1210.",M),"mgmt")
W<-merge(W, Wf[, ..v1210cols], by="STAND", all.x=TRUE)
# forest type
ti<-rd("magp_qcnb_tree_init.csv")
sw<-c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC","EC","WH","HE")
ti[, isHW:=!(toupper(SP)%in%sw)]; ti<-ti[is.finite(DBH)&DBH>=4]; ti[, baw:=pi*(DBH/200)^2*EXPF]
ft<-ti[, .(pctHW=100*sum(baw[isHW])/sum(baw)), by=STAND]
ft[, fortype:=fifelse(pctHW<=25,"Softwood",fifelse(pctHW>=75,"Hardwood","Mixedwood"))]
W<-merge(W, ft[,.(STAND,fortype)], by="STAND", all.x=TRUE); W[is.na(fortype), fortype:="Unknown"]
# management class buckets for by-class cut
W[, mclass := fifelse(mgmt=="PLANTED","PLANTED", fifelse(mgmt=="PCT","PCT", fifelse(mgmt=="NONE","NONE","OTHER")))]
cat(sprintf("n=%d NB=%d QC=%d | mgmt: NONE=%d PLANTED=%d PCT=%d OTHER=%d NA=%d\n", nrow(W),
  sum(W$PROV=="NB"), sum(W$PROV=="QC"), sum(W$mclass=="NONE",na.rm=T), sum(W$mclass=="PLANTED",na.rm=T),
  sum(W$mclass=="PCT",na.rm=T), sum(W$mclass=="OTHER",na.rm=T), sum(is.na(W$mclass))))
mods<-c("v125","v1270","v129x","v1210","osm")
tost<-function(d,delta,alpha=0.05){n<-length(d); if(n<3||!is.finite(delta)||delta<=0) return(list(equiv=NA,p=NA_real_))
  m<-mean(d); se<-sd(d)/sqrt(n); if(se==0) se<-1e-9; tcrit<-qt(1-alpha,n-1); ci_lo<-m-tcrit*se; ci_hi<-m+tcrit*se
  list(equiv=(ci_lo>-delta&&ci_hi<delta), p=max(pt((m+delta)/se,n-1,lower.tail=FALSE),pt((m-delta)/se,n-1,lower.tail=TRUE)))}
scoreset<-function(D,cut,label){ if(nrow(D)<8) return(NULL); out<-list()
  for(mo in mods) for(m in M){ o<-D[[paste0(m,"_o")]]; p<-D[[paste0(mo,".",m)]]; tt<-D[[paste0(m,"_t1")]]; iv<-D[["iv"]]
    if(all(is.na(p))) next
    d<-p-o; dl<-0.10*mean(o); ts<-tost(d,dl); pai_o<-(o-tt)/iv; pai_p<-(p-tt)/iv; di<-pai_p-pai_o; tsi<-tost(di,0.25*abs(mean(pai_o)))
    out[[length(out)+1]]<-data.table(cut=cut,subset=label,model=mo,metric=m,n=nrow(D),
      obs_mean=mean(o),pred_mean=mean(p),bias_pct=100*(mean(p)/mean(o)-1),rmse=sqrt(mean((p-o)^2)),
      mae=mean(abs(p-o)),nse=1-sum((o-p)^2)/sum((o-mean(o))^2),cor=cor(o,p),
      tost_lvl_equiv=ts$equiv,pai_bias=mean(pai_p)-mean(pai_o),tost_inc_equiv=tsi$equiv)}
  rbindlist(out)}
R<-list()
R[[1]]<-scoreset(W,"jurisdiction","POOLED"); R[[2]]<-scoreset(W[PROV=="NB"],"jurisdiction","NB"); R[[3]]<-scoreset(W[PROV=="QC"],"jurisdiction","QC")
for(f in c("Softwood","Mixedwood","Hardwood")) R[[length(R)+1]]<-scoreset(W[fortype==f],"fortype",f)
for(mc in c("NONE","PLANTED","PCT")) R[[length(R)+1]]<-scoreset(W[mclass==mc],"mgmt",mc)
R[[length(R)+1]]<-scoreset(W[mclass %in% c("PLANTED","PCT")],"mgmt","MANAGED")
S<-rbindlist(R); fwrite(S,"scorecard_five_v1210.csv")
cat("\n=== POOLED bias% | RMSE | NSE, TOTVOL & BA ===\n")
print(S[subset=="POOLED"&metric%in%c("BA","TOTVOL"), .(model,metric,bias=round(bias_pct,1),rmse=round(rmse,1),nse=round(nse,2))])
cat("\n=== TOST level pass (POOLED, 9 metrics) + mean|bias| + mean NSE ===\n")
print(S[subset=="POOLED", .(tost_pass=sum(tost_lvl_equiv,na.rm=T), mean_absbias=round(mean(abs(bias_pct)),1), mean_nse=round(mean(nse),2)), by=model])
cat("\n=== By management class: MANAGED mean|bias| across 9 metrics ===\n")
print(S[cut=="mgmt", .(mae_absbias=round(mean(abs(bias_pct)),1)), by=.(subset,model)][order(subset,model)])
cat("DONE_V1210\n")

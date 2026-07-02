suppressMessages({library(data.table)})
has_lm <- requireNamespace("minpack.lm", quietly=TRUE)
set.seed(42)
d <- as.data.table(readRDS("~/bakeoff_v13/ne_plot_table.rds"))
esi <- fread("~/bakeoff_v13/ne_plot_esi.csv")
d <- merge(d, esi, by="rid", all.x=TRUE)
d <- d[is.finite(topht1)&topht1>2&is.finite(topht2)&topht2>2&is.finite(stdage)&stdage>=5&stdage<=250&
       is.finite(years)&years>=1&is.finite(hgi_o)&hgi_o> -1&hgi_o<3 &
       is.finite(esi)&is.finite(bgi)&is.finite(climate_si)&is.finite(cspi)&
       is.finite(dg_a_plot)&is.finite(dbh1_qmd)&dbh1_qmd>0&is.finite(cr1)&cr1>0&
       is.finite(bal_sw1)&is.finite(rd_sdimax)&rd_sdimax>0&rd_sdimax<2.5]
cat("N plots for CV:", nrow(d), "\n")
metrics <- c(esi="esi", bgi="bgi", cspi="cspi", csi="climate_si")
# global z-score per metric (store mean/sd so folds use train-based? use global for simplicity/comparability)
for(m in metrics) d[, paste0("z_",m):=as.numeric(scale(get(m)))]
d[, cell := paste(round(LAT*4), round(LON*4))]
cells <- unique(d$cell); fold_of <- setNames(sample(rep(1:10, length.out=length(cells))), cells)
d[, fold := fold_of[cell]]
d[, qmd_l := log(dbh1_qmd)][, cr_l := log((cr1+0.2)/1.2)][, bal_l := log(bal_sw1+0.01)]
ef <- function(o,p) 1 - sum((o-p)^2)/sum((o-mean(o))^2)
anchor_fit <- function(dd, zcol){ dd<-copy(dd); dd[,Z:=get(zcol)]
  st <- list(a0=mean(dd$topht1), a1=2, k=0.03, p=1.2)
  f <- topht1 ~ (a0 + a1*Z)*(1-exp(-k*stdage))^p
  tryCatch({ if(has_lm) minpack.lm::nlsLM(f,data=dd,start=st,
      lower=c(a0=1,a1=-20,k=1e-3,p=0.3),upper=c(a0=60,a1=20,k=0.4,p=6),
      control=minpack.lm::nls.lm.control(maxiter=300))
    else nls(f,data=dd,start=st,algorithm="port",lower=c(1,-20,1e-3,0.3),upper=c(60,20,0.4,6)) },
    error=function(e) NULL) }
pred_anchor <- function(fit,dd,zcol){ co<-coef(fit); dd<-copy(dd); dd[,Z:=get(zcol)]
  A<-co["a0"]+co["a1"]*dd$Z
  t1<-A*(1-exp(-co["k"]*dd$stdage))^co["p"]; t2<-A*(1-exp(-co["k"]*(dd$stdage+dd$years)))^co["p"]
  list(topht_p=as.numeric(t1),hgi_p=as.numeric((t2-t1)/dd$years)) }
res<-list(); resid_store<-list()
for(mn in names(metrics)){ zc<-paste0("z_",metrics[[mn]])
  op_ht<-oo_ht<-op_hp<-oo_hp<-site_te<-dg_o<-dg_p<-numeric(0)
  for(k in 1:10){ tr<-d[fold!=k]; te<-d[fold==k]
    fa<-anchor_fit(tr,zc)
    if(!is.null(fa)){ pr<-pred_anchor(fa,te,zc)
      op_ht<-c(op_ht,pr$topht_p);oo_ht<-c(oo_ht,te$topht1)
      op_hp<-c(op_hp,pr$hgi_p);oo_hp<-c(oo_hp,te$hgi_o);site_te<-c(site_te,te[[metrics[[mn]]]]) }
    fm<-as.formula(paste0("dg_a_plot ~ ",metrics[[mn]]," + qmd_l + cr_l + bal_l + rd_sdimax"))
    fd<-lm(fm,data=tr); dg_o<-c(dg_o,te$dg_a_plot); dg_p<-c(dg_p,as.numeric(predict(fd,te))) }
  sl<-coef(lm(I(op_hp-oo_hp)~scale(site_te)[,1]))[2]
  corr_ht<-cor(oo_ht, d[[metrics[[mn]]]][match(oo_ht,oo_ht)]) # placeholder
  res[[mn]]<-data.table(metric=mn,n=length(oo_ht),
    ht_level_bias_pct=round(100*(mean(op_ht)/mean(oo_ht)-1),2),
    ht_rmse=round(sqrt(mean((op_ht-oo_ht)^2)),3), ht_ef=round(ef(oo_ht,op_ht),3),
    hgi_ratio=round(mean(op_hp)/mean(oo_hp),3), hgi_rmse=round(sqrt(mean((op_hp-oo_hp)^2)),4),
    hgi_ef=round(ef(oo_hp,op_hp),3), resid_slope_vs_site=round(sl,4),
    dg_bias_pct=round(100*(mean(dg_p)-mean(dg_o))/mean(dg_o),2),
    dg_rmse=round(sqrt(mean((dg_p-dg_o)^2)),4), dg_ef=round(ef(dg_o,dg_p),3)) }
R<-rbindlist(res); print(R); fwrite(R,"~/bakeoff_v13/cv_scores_affine.csv")
# raw information content: correlation of each metric with observed dominant height and observed SI
cat("\n=== metric correlation with observed topht1 and SICOND ===\n")
ic<-data.table(metric=names(metrics),
  cor_topht1=sapply(metrics,function(m) round(cor(d[[m]],d$topht1),3)),
  cor_sicond=sapply(metrics,function(m) round(cor(d[[m]],d$sicond,use="complete.obs"),3)),
  cor_hgi=sapply(metrics,function(m) round(cor(d[[m]],d$hgi_o),3)))
print(ic); fwrite(ic,"~/bakeoff_v13/metric_infocontent.csv")
cat("DONE_FIT2\n")

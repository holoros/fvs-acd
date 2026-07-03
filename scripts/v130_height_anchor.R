## FVS-ACD v13.0 : domain mask + increment-consistent dominant-height anchor
## Fit on US ME/NH/VT remeasurement pairs (in-domain, ESI-covered). Evaluate out of sample on US
## (10-fold spatial CV) and on the HELD-OUT MagPlot NB/QC benchmark (evaluate only, never fit).
## Base-age-invariant anchor (state = current top height) so it transfers with no absolute age.
## Run on Cardinal: ~/bakeoff_v13 (US pairs) and ~/magplot/verify (held-out MagPlot). Aggregates only.
suppressMessages({library(data.table); has_lm <- requireNamespace("minpack.lm", quietly=TRUE)})
set.seed(42); dir.create("~/v13_kickoff", showWarnings=FALSE)
## ---- US fit data ----
d <- as.data.table(readRDS("~/bakeoff_v13/ne_plot_table.rds"))
e <- fread("~/bakeoff_v13/ne_plot_esi.csv"); d <- merge(d,e,by="rid",all.x=TRUE)
d <- d[is.finite(topht1)&topht1>2&is.finite(topht2)&topht2>2&is.finite(stdage)&stdage>=5&stdage<=250&
       is.finite(years)&years>=1&is.finite(hgi_o)&hgi_o> -0.5&hgi_o<2 & is.finite(esi)]
## ---- Domain mask: ESI coverage + Acadian-core ecoregion ----
acadian_L3 <- c("5.3.1","8.1.7","8.1.8","8.1.1")   # Atlantic Highlands + Acadian Plains&Hills + NE Highlands
d[, in_domain := is.finite(esi) & (epaL3 %in% acadian_L3)]
cat("=== DOMAIN MASK (US fit set) ===\n")
cat("total clean pairs:", nrow(d), " ESI-covered:", sum(is.finite(d$esi)),
    " in Acadian-core L3:", sum(d$in_domain), " out-of-domain:", sum(!d$in_domain), "\n")
print(d[,.(n=.N, in_domain=sum(in_domain)),by=.(STATECD)])
dd <- d[in_domain==TRUE]
cat("in-domain pairs used for fitting:", nrow(dd), "\n\n")
dd[, cell := paste(round(LAT*4), round(LON*4))]
cells <- unique(dd$cell); fold_of <- setNames(sample(rep(1:10,length.out=length(cells))),cells); dd[,fold:=fold_of[cell]]
ef <- function(o,p) 1 - sum((o-p)^2)/sum((o-mean(o))^2)
## ---- model fitters ----
# M1 direct linear increment
fitM1 <- function(tr) lm(hgi_o ~ esi + topht1 + log(stdage), data=tr)
predM1 <- function(f,te){ hp<-as.numeric(predict(f,te)); pmax(hp,0) }
# M2 monomolecular (Mitscherlich) base-age-invariant difference anchor: Amax=a0+a1*esi ; no absolute age
fitM2 <- function(tr){ st<-list(a0=8,a1=0.8,k=0.02)
  f <- topht2 ~ (a0+a1*esi) - ((a0+a1*esi)-topht1)*exp(-k*years)
  tryCatch({ if(has_lm) minpack.lm::nlsLM(f,tr,start=st,lower=c(a0=-5,a1=0.1,k=1e-3),upper=c(a0=30,a1=3,k=0.3),
      control=minpack.lm::nls.lm.control(maxiter=400)) else nls(f,tr,start=st) }, error=function(e) NULL) }
predM2 <- function(f,te){ co<-coef(f); Amax<-co["a0"]+co["a1"]*te$esi
  t2<-Amax-(Amax-te$topht1)*exp(-co["k"]*te$years); as.numeric((t2-te$topht1)/te$years) }
## ---- US 10-fold spatial CV: increment bias/rmse/ef ----
o1<-p1<-o2<-p2<-numeric(0)
for(k in 1:10){ tr<-dd[fold!=k]; te<-dd[fold==k]
  f1<-fitM1(tr); p1<-c(p1,predM1(f1,te)); o1<-c(o1,te$hgi_o)
  f2<-fitM2(tr); if(!is.null(f2)){ p2<-c(p2,predM2(f2,te)); o2<-c(o2,te$hgi_o) } }
cvtab <- rbind(
 data.table(model="M1_linear_incr", n=length(o1), incr_bias=round(mean(p1)-mean(o1),4),
   incr_ratio=round(mean(p1)/mean(o1),3), rmse=round(sqrt(mean((p1-o1)^2)),4), ef=round(ef(o1,p1),3)),
 data.table(model="M2_monomol_anchor", n=length(o2), incr_bias=round(mean(p2)-mean(o2),4),
   incr_ratio=round(mean(p2)/mean(o2),3), rmse=round(sqrt(mean((p2-o2)^2)),4), ef=round(ef(o2,p2),3)))
cat("=== US in-domain 10-fold spatial CV (dominant-height INCREMENT, m/yr) ===\n"); print(cvtab)
F1<-fitM1(dd); F2<-fitM2(dd)
cat("\nM1 coefs:\n"); print(round(coef(F1),4)); cat("M2 coefs (Amax=a0+a1*esi ; k):\n"); print(round(coef(F2),4))
saveRDS(list(M1=F1,M2=F2), "~/v13_kickoff/v130_anchor_models.rds")
## ---- HELD-OUT MagPlot NB/QC : EVALUATE ONLY (base-age invariant, uses topht1 + esi8) ----
mp <- fread("~/magplot/verify/cb_v1270_results.csv")[, .(STAND,PROV,esi_cov,iv,TOPHT_t1,TOPHT_o,TOPHT_p)]
mp <- mp[is.finite(TOPHT_t1)&TOPHT_t1>2&is.finite(TOPHT_o)&TOPHT_o>2&is.finite(iv)&iv>0]
pr <- fread("~/magplot/verify/magp_qcnb_pairs.csv")[, .(STAND=as.character(STAND),SITE=as.character(SITE))]
e8 <- fread("~/magplot/verify/magp_qcnb_site_esi8.csv"); e8[,SITE:=as.character(SITE)]
mp[, STAND:=as.character(STAND)]; mp<-merge(mp,pr,by="STAND",all.x=TRUE); mp<-merge(mp,e8,by="SITE",all.x=TRUE)
mp <- mp[is.finite(esi8)]
mp[, hgi_o := (TOPHT_o-TOPHT_t1)/iv]; mp[, hgi_cur := (TOPHT_p-TOPHT_t1)/iv]
c1<-coef(F1); mp[, hgi_M1 := pmax(c1["esi"]*esi8 + c1["topht1"]*TOPHT_t1 + c1["(Intercept)"] + c1["log(stdage)"]*log(60),0)]
c2<-coef(F2); mp[, Amax := c2["a0"]+c2["a1"]*esi8][, TOPHT_M2 := Amax-(Amax-TOPHT_t1)*exp(-c2["k"]*iv)][, hgi_M2:=(TOPHT_M2-TOPHT_t1)/iv]
mp[, TOPHT_M1 := TOPHT_t1 + hgi_M1*iv]
ev <- mp[, .(n=.N, obs_HGI=round(mean(hgi_o),3),
   cur_ratio=round(mean(hgi_cur)/mean(hgi_o),2), M1_ratio=round(mean(hgi_M1)/mean(hgi_o),2),
   M2_ratio=round(mean(hgi_M2)/mean(hgi_o),2), cur_topht_bias=round(100*(mean(TOPHT_p)/mean(TOPHT_o)-1),1),
   M1_topht_bias=round(100*(mean(TOPHT_M1)/mean(TOPHT_o)-1),1),
   M2_topht_bias=round(100*(mean(TOPHT_M2)/mean(TOPHT_o)-1),1)), by=PROV][order(PROV)]
cat("\n=== MagPlot held-out: increment ratio pred/obs (target 1.0) ===\n"); print(ev)
fwrite(ev,"~/v13_kickoff/v130_magplot_eval.csv"); fwrite(cvtab,"~/v13_kickoff/v130_us_cv.csv")
## ---- volume-over reduction: empirical height elasticity of stand volume ----
vv <- fread("~/magplot/verify/cb_v1270_results.csv")[is.finite(TOPHT_p)&TOPHT_p>2&is.finite(TOTVOL_p)&TOTVOL_p>0]
elas <- coef(lm(log(TOTVOL_p)~log(TOPHT_p)+log(pmax(BA_p,0.1)), data=vv))["log(TOPHT_p)"]
cat(sprintf("\nEmpirical height elasticity of total volume (cross-stand, BA held): %.2f\n", elas))
cat("DONE_V130\n")

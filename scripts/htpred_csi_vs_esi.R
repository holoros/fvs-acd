# Easy-fix validation: legacy Climate Site Index (CSI) vs modern ESI inside the
# operational AcadianGY HTPred height-diameter equation. No refit of HTPred; we
# only change the site input. DBHout supplies CSI, dbh, measured ht, ccf, bal,
# coords. ESI comes from the ClimateNA SI raster, auto-identified by matching the
# site-tree SIPred. FVS-ACD site update, 28 June 2026.
suppressPackageStartupMessages({ library(data.table); library(terra) })
D <- "/fs/scratch/PUOM0008/crsfaaron/maine_cfi"; SI <- "/users/PUOM0008/crsfaaron/SiteIndex"
source("~/fvsacd/HTPred_fun.R")   # exact HTPred(SPP,DBH,CSI,CCF,BAL)
set.seed(47)

## 1. identify which raster equals the compilation ESI (SIPred)
a <- fread(file.path(D,"AllEastSIPred.csv"), select=c("LAT","LON","SIPred"))
a <- a[is.finite(LAT)&is.finite(LON)&is.finite(SIPred)][sample(.N, min(.N,30000))]
ap <- vect(a, geom=c("LON","LAT"), crs="EPSG:4326")
cands <- list.files(SI, pattern="SI.*\\.tif$|Final.*\\.tif$", full.names=TRUE)
cat("candidate rasters:\n"); print(basename(cands))
best <- NULL; bestcor <- -2
for (f in cands) {
  r <- tryCatch(rast(f), error=function(e) NULL); if (is.null(r)) next
  v <- tryCatch(terra::extract(r[[1]], project(ap, crs(r)))[[2]], error=function(e) rep(NA,nrow(a)))
  ok <- is.finite(v) & is.finite(a$SIPred)
  if (sum(ok) < 1000) next
  cc <- cor(v[ok], a$SIPred[ok]); rmse <- sqrt(mean((v[ok]-a$SIPred[ok])^2))
  cat(sprintf("  %-34s cor=%.3f rmse=%.2f n=%d\n", basename(f), cc, rmse, sum(ok)))
  if (cc > bestcor) { bestcor <- cc; best <- f }
}
cat("ESI raster selected:", basename(best), " cor=", round(bestcor,3), "\n")
esi_r <- rast(best)[[1]]

## 2. DBHout frame with legacy CSI and measured height
d <- fread(file.path(D,"DBHout.csv"),
     select=c("Source","Stand","Plot","sp1","dbh1","ht1_imp","ht1_stat","ccf1","bal1","lat","long","climatesi"))
# measured height preferred (ht1_stat); fall back to imputed if status sparse
d[, ht_obs := ifelse(is.finite(ht1_stat) & ht1_stat>1.37, ht1_stat, NA_real_)]
use_imp <- mean(is.finite(d$ht_obs)) < 0.1
if (use_imp) d[, ht_obs := ifelse(is.finite(ht1_imp) & ht1_imp>1.37, ht1_imp, NA_real_)]
cat("using", ifelse(use_imp,"imputed","measured/status"), "heights\n")
d <- d[is.finite(dbh1)&dbh1>0 & is.finite(ht_obs) & is.finite(ccf1)&ccf1>=0 &
       is.finite(bal1)&bal1>=0 & is.finite(climatesi)&climatesi>0 &
       is.finite(lat)&is.finite(long) & !is.na(sp1) & sp1!=""]
cat("DBHout valid rows:", nrow(d), "\n")

## 3. extract ESI at DBHout coords
dp <- vect(d, geom=c("long","lat"), crs="EPSG:4326")
d[, ESI := terra::extract(esi_r, project(dp, crs(esi_r)))[[2]]]
d <- d[is.finite(ESI) & ESI>0]
cat("rows with ESI:", nrow(d), " | CSI mean", round(mean(d$climatesi),2),
    " ESI mean", round(mean(d$ESI),2), "\n")

## 4. CSI ~ ESI mapping (transition aid)
mp <- lm(climatesi ~ ESI, data=d); a0 <- coef(mp)[1]; a1 <- coef(mp)[2]
d[, ESI_map := a0 + a1*ESI]
cat(sprintf("mapping  CSI = %.4f + %.4f * ESI   (R2=%.3f)\n", a0, a1, summary(mp)$r.squared))

## 5. predict HT with each site input (HTPred fixed, vectorized per species)
d[, pHT_CSI    := HTPred(sp1[1], dbh1, climatesi, ccf1, bal1), by=sp1]
d[, pHT_ESIraw := HTPred(sp1[1], dbh1, ESI,       ccf1, bal1), by=sp1]
d[, pHT_ESImap := HTPred(sp1[1], dbh1, ESI_map,   ccf1, bal1), by=sp1]

met <- function(obs,prd){ ok<-is.finite(obs)&is.finite(prd); o<-obs[ok];p<-prd[ok]
  data.table(R2=1-sum((o-p)^2)/sum((o-mean(o))^2), RMSE=sqrt(mean((o-p)^2)),
             bias=mean(p-o), n=length(o)) }
tab <- rbindlist(list(
  cbind(site="legacy_CSI",   met(d$ht_obs,d$pHT_CSI)),
  cbind(site="ESI_raw",      met(d$ht_obs,d$pHT_ESIraw)),
  cbind(site="ESI_mapped",   met(d$ht_obs,d$pHT_ESImap))))
fwrite(tab, file.path(D,"htpred_csi_vs_esi_summary.csv"))
cat("\n=== HTPred height prediction by site input (DBHout) ===\n"); print(tab)

## 6. spatial robustness: bias by 1-degree block
d[, blk := paste(floor(lat), floor(long))]
bz <- d[, .(bias_CSI=round(mean(pHT_CSI-ht_obs),2), bias_ESImap=round(mean(pHT_ESImap-ht_obs),2),
            rmse_CSI=round(sqrt(mean((pHT_CSI-ht_obs)^2)),2),
            rmse_ESImap=round(sqrt(mean((pHT_ESImap-ht_obs)^2)),2), n=.N), by=blk][order(-n)]
fwrite(bz, file.path(D,"htpred_bias_by_block.csv"))
cat("\n=== bias by 1-degree block (top 12 by n) ===\n"); print(head(bz,12))
cat("blocks where ESImap beats CSI on RMSE:", sum(bz$rmse_ESImap < bz$rmse_CSI), "of", nrow(bz), "\n")

## 7. does a simple global ESI scale (CSI_SCALE analog) cut height bias?
obj <- function(s){ d[, pp := HTPred(sp1[1], dbh1, ESI*s, ccf1, bal1), by=sp1]; mean(d$pp-d$ht_obs) }
sc <- tryCatch(uniroot(obj, c(0.5,1.6))$root, error=function(e) NA)
cat("\nESI global scale that zeroes height bias:", round(sc,3), "\n")

## 8. Bakuzis ordering check on HTPred curves (no crossing, monotone, ordered by site)
spp_chk <- c("BF","RS","RM","SM","YB"); esi_lv <- c(6,9,12,15,18); dbh_g <- seq(2,50,2)
cross <- 0
for (s in spp_chk) for (i in 2:length(esi_lv)) {
  hi <- HTPred(s, dbh_g, esi_lv[i],   30, 10); lo <- HTPred(s, dbh_g, esi_lv[i-1], 30, 10)
  if (any(hi < lo - 1e-6)) cross <- cross + 1
}
cat("Bakuzis: site-curve crossings across", length(spp_chk),"spp x",length(esi_lv)-1,"gaps:", cross, "(0 = ordered)\n")
saveRDS(list(map=c(a0=a0,a1=a1), esi_raster=basename(best), scale_zero_bias=sc), file.path(D,"htpred_easyfix_meta.rds"))
cat("DONE\n")

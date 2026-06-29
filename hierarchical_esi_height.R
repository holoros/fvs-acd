# Hierarchical ESI-anchored dominant-height sub-model for FVS-ACD.
# Base-age Chapman-Richards with the modern ESI as site anchor and nested
# random effects for ecoregion and species (ecoregion / species). nlme.
# Robust version of the anamorphic baseline. 27 June 2026.

suppressPackageStartupMessages({ library(data.table); library(terra); library(nlme) })
OUT <- "/fs/scratch/PUOM0008/crsfaaron/maine_cfi"; BASE <- 50
set.seed(47)
d <- fread(file.path(OUT,"AllEastSIPred.csv"),
           select=c("SOURCE","SPCD","fvs_ne_var","AGEDIA","HT","SIPred","LAT","LON"))
d <- d[is.finite(AGEDIA)&AGEDIA>=5&AGEDIA<=250 & is.finite(HT)&HT>1.3&HT<60 &
       is.finite(SIPred)&SIPred>0 & is.finite(LAT)&is.finite(LON) & !is.na(fvs_ne_var)]

# Level 3 ecoregion by point-in-polygon
eco <- tryCatch(vect("/users/PUOM0008/crsfaaron/SiteIndex/NA_Eco_L3_WGS84.shp"), error=function(e) NULL)
if (!is.null(eco)) {
  pts <- vect(d, geom=c("LON","LAT"), crs="EPSG:4326")
  enm <- grep("L3|NA_L3|NameL3|name", names(eco), value=TRUE, ignore.case=TRUE)
  ecocol <- if(length(enm)) enm[1] else names(eco)[1]
  d[, eco := terra::extract(eco[,ecocol], pts)[[2]]]
} else d[, eco := "all"]
d <- d[!is.na(eco)]
d[, eco := factor(eco)][, spp := factor(fvs_ne_var)]
cat("obs:", nrow(d), " ecoregions:", nlevels(d$eco), " species:", nlevels(d$spp), "\n")

# subsample for tractable nlme convergence; report n used
ds <- if (nrow(d) > 120000) d[sample(.N, 120000)] else d
ds <- groupedData(HT ~ AGEDIA | eco/spp, data = as.data.frame(ds))

crfun <- function(AGEDIA, SIPred, k, p) SIPred*((1-exp(-k*AGEDIA))/(1-exp(-k*BASE)))^p
start <- c(k=0.0039, p=0.726)
fit <- tryCatch(
  nlme(HT ~ crfun(AGEDIA, SIPred, k, p),
       fixed = k + p ~ 1, random = k + p ~ 1 | eco/spp,
       data = ds, start = start,
       control = nlmeControl(maxIter=80, msMaxIter=80, returnObject=TRUE, opt="nlminb")),
  error=function(e){cat("nlme error:",conditionMessage(e),"\n"); NULL})

if (!is.null(fit)) {
  pr <- predict(fit); res <- ds$HT - pr
  R2c <- 1 - sum(res^2)/sum((ds$HT-mean(ds$HT))^2)
  prf <- predict(fit, level=0); resf <- ds$HT - prf
  R2m <- 1 - sum(resf^2)/sum((ds$HT-mean(ds$HT))^2)
  cat("\n== hierarchical ESI-anchored dominant-height fit ==\n")
  cat("fixed effects: k =", round(fixef(fit)["k"],5), " p =", round(fixef(fit)["p"],3), "\n")
  cat("marginal R2 (fixed only):", round(R2m,3), "  conditional R2 (with eco/spp RE):", round(R2c,3), "\n")
  cat("RMSE conditional:", round(sqrt(mean(res^2)),2), "m   (anamorphic baseline was 2.45 m, R2 0.804)\n")
  cat("\nvariance components (SD):\n"); print(VarCorr(fit))
  saveRDS(fit, file.path(OUT,"hier_esi_height_nlme.rds"))
  dt <- data.table(metric=c("k_fixed","p_fixed","R2_marginal","R2_conditional","RMSE_cond_m","n_used"),
                   value=round(c(fixef(fit)["k"],fixef(fit)["p"],R2m,R2c,sqrt(mean(res^2)),nrow(ds)),5))
  fwrite(dt, file.path(OUT,"hier_esi_height_summary.csv"))
} else cat("nlme did not converge; see charter for the staged production fit.\n")
cat("DONE\n")

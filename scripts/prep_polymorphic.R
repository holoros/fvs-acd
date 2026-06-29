# Stage A: polymorphic (species-specific) Chapman-Richards shapes with ESI as
# site level, plus back-transform to a base-age-50 implied site level and plot
# aggregation for the Stage B structured level model. FVS-ACD site update.
suppressPackageStartupMessages({ library(data.table); library(terra); library(spdep) })
OUT <- "/fs/scratch/PUOM0008/crsfaaron/maine_cfi"; BASE <- 50; set.seed(47)

d <- fread(file.path(OUT,"AllEastSIPred.csv"),
           select=c("SOURCE","ID","PLOT","SPCD","fvs_ne_var","AGEDIA","HT","SI","SIPred","LAT","LON"))
d <- d[is.finite(AGEDIA)&AGEDIA>=5&AGEDIA<=250 & is.finite(HT)&HT>1.3&HT<60 &
       is.finite(SIPred)&SIPred>0 & is.finite(LAT)&is.finite(LON) & !is.na(fvs_ne_var) & fvs_ne_var!=""]
d[, plotid := paste(SOURCE, ID, PLOT, sep="_")]
d[, spp := factor(fvs_ne_var)]
cat("obs:", nrow(d), " plots:", uniqueN(d$plotid), " species:", nlevels(d$spp), "\n")

# --- Level 3 ecoregion by point in polygon ---
eco <- vect("/users/PUOM0008/crsfaaron/SiteIndex/NA_Eco_L3_WGS84.shp")
enm <- grep("NA_L3NAME|US_L3NAME|L3NAME|NameL3|L3", names(eco), value=TRUE, ignore.case=TRUE)
ecocol <- if (length(enm)) enm[1] else names(eco)[1]
cat("ecoregion field:", ecocol, " | fields:", paste(names(eco),collapse=","), "\n")
pts <- vect(d, geom=c("LON","LAT"), crs="EPSG:4326")
d[, eco := terra::extract(eco[,ecocol], pts)[[2]]]
d <- d[!is.na(eco) & eco!=""]
d[, eco := factor(eco)]
cat("after eco join obs:", nrow(d), " ecoregions:", nlevels(d$eco), "\n")

# --- Stage A: per species polymorphic CR shape, ESI as level anchor ---
shapefac <- function(age,k,p) ((1-exp(-k*age))/(1-exp(-k*BASE)))^p
crH      <- function(age,SI,k,p) SI*shapefac(age,k,p)
# global shape (fallback / baseline)
fg <- nls(HT ~ crH(AGEDIA,SIPred,k,p), data=d, start=list(k=0.0039,p=0.726),
          control=nls.control(maxiter=300,warnOnly=TRUE))
gk <- coef(fg)["k"]; gp <- coef(fg)["p"]
cat("global shape k=",round(gk,5)," p=",round(gp,4),"\n")

fit_sp <- function(sub){
  if (nrow(sub) < 200) return(c(k=gk,p=gp,conv=0L,n=nrow(sub)))
  f <- tryCatch(nls(HT ~ crH(AGEDIA,SIPred,k,p), data=sub,
                    start=list(k=as.numeric(gk),p=as.numeric(gp)),
                    control=nls.control(maxiter=300,warnOnly=TRUE)),
                error=function(e) NULL)
  if (is.null(f)) return(c(k=gk,p=gp,conv=0L,n=nrow(sub)))
  kk <- coef(f)["k"]; pp <- coef(f)["p"]
  if (!is.finite(kk)||!is.finite(pp)||kk<=0||kk>0.2||pp<=0||pp>6) return(c(k=gk,p=gp,conv=0L,n=nrow(sub)))
  c(k=kk,p=pp,conv=1L,n=nrow(sub))
}
sl <- split(d, d$spp)
sh <- rbindlist(lapply(names(sl), function(s){ v<-fit_sp(sl[[s]]); data.table(spp=s,k=v["k"],p=v["p"],conv=v["conv"],n=v["n"]) }))
setkey(sh, spp)
fwrite(sh, file.path(OUT,"species_shapes.csv"))
cat("species shapes fit (conv=1 count):", sum(sh$conv),"of",nrow(sh),"\n"); print(sh)

# attach species shapes, polymorphic predictions and implied base-age-50 site level
d[, k_s := sh[.(as.character(spp)), k, on="spp"]]
d[, p_s := sh[.(as.character(spp)), p, on="spp"]]
d[, Hhat_poly := crH(AGEDIA, SIPred, k_s, p_s)]
d[, sf := shapefac(AGEDIA, k_s, p_s)]
d <- d[is.finite(sf) & sf>0.05]              # avoid divide blow-up at very young ages
d[, SI_implied := HT / sf]
d <- d[is.finite(SI_implied) & SI_implied>0 & SI_implied<40]

# polymorphic fit quality + residual by age (bias check vs anamorphic)
res <- d$HT - d$Hhat_poly
R2 <- 1 - sum(res^2)/sum((d$HT-mean(d$HT))^2)
cat(sprintf("\nPOLYMORPHIC in-sample: R2=%.3f RMSE=%.2f m  (anamorphic was R2=0.804 RMSE=2.45)\n", R2, sqrt(mean(res^2))))
d[, age_cls := cut(AGEDIA, c(0,30,50,70,90,120,250))]
d[, res_poly := res]
rr <- d[, .(mean_resid=round(mean(res_poly),2), n=.N), by=age_cls][order(age_cls)]
fwrite(rr, file.path(OUT,"poly_residual_by_age.csv")); cat("\nresidual by age (polymorphic):\n"); print(rr)

# --- plot aggregation for Stage B level model ---
domsp <- d[, .N, by=.(plotid,spp)][order(-N)][, .SD[1], by=plotid][, .(plotid, dom_spp=spp)]
pl <- d[, .(SI_implied=mean(SI_implied), ESI=mean(SIPred), measSI=mean(SI),
            LON=mean(LON), LAT=mean(LAT), eco=eco[1], ntree=.N), by=plotid]
pl <- merge(pl, domsp, by="plotid")
pl <- pl[is.finite(SI_implied)&is.finite(ESI)]
pl[, dom_spp := factor(dom_spp)][, eco := factor(eco)]
cat("\nplot-level rows:", nrow(pl), " unique eco:", nlevels(pl$eco), " dom species:", nlevels(pl$dom_spp), "\n")
saveRDS(pl, file.path(OUT,"plot_level_frame.rds"))
fwrite(pl, file.path(OUT,"plot_level_frame.csv"))

# --- ecoregion adjacency graph for car()/dagar() ---
ecosub <- eco[eco[[ecocol]] %in% levels(pl$eco), ]
ecod <- terra::aggregate(ecosub, by=ecocol)          # dissolve to one polygon per L3
ecosf <- sf::st_as_sf(ecod)
nb <- spdep::poly2nb(ecosf, queen=TRUE)
adj <- spdep::nb2mat(nb, style="B", zero.policy=TRUE)
nm <- as.character(ecosf[[ecocol]])
dimnames(adj) <- list(nm, nm)
saveRDS(list(adj=adj, names=nm, n_islands=sum(spdep::card(nb)==0)), file.path(OUT,"eco_adjacency.rds"))
cat("eco adjacency areas:", length(nm), " isolated(no-neighbor):", sum(spdep::card(nb)==0), "\n")
cat("DONE\n")

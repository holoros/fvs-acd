# Score OSM on ALL FIVE Bakuzis law-like relations from a long-horizon (160-yr)
# OSM run over the SILC/CFI stands, binned into three site-productivity levels by
# T50HT (height at reference age 50, OSM's site metric) as the analog to the
# AcadianGY seeded ESI 12/16/20 gradient. Relation definitions mirror
# magplot/verify/bakuzis_allmodels.R exactly. Aggregates only; no coordinates.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/silc_cfi/osm_150yr_bakuzis")

D <- fread("osm150_StandList.csv")
setnames(D, c("T50HT","LryH","BA","QMD","Trees","%RD","GMV"),
             c("T50HT","LryH","BA","QMD","TPH","RD","GMV"), skip_absent=TRUE)
D <- D[is.finite(BA) & is.finite(QMD) & is.finite(TPH) & TPH>0]

# --- site levels: tercile-bin stands by their age-0 T50HT (OSM site index proxy) ---
s0 <- D[Age==0, .(t50=mean(T50HT)), by=SurveyID]
qs <- quantile(s0$t50, c(1/3,2/3), na.rm=TRUE)
s0[, site := ifelse(t50<=qs[1], "LOW", ifelse(t50<=qs[2], "MID", "HIGH"))]
D <- merge(D, s0[,.(SurveyID,site,t50_stand=t50)], by="SurveyID")
sitelab <- c(LOW="LOW", MID="MID", HIGH="HIGH")
cat("=== SITE LEVELS (T50HT terciles, m) ===\n")
print(s0[, .(n=.N, t50_min=round(min(t50),1), t50_mean=round(mean(t50),1),
             t50_max=round(max(t50),1)), by=site][order(t50_mean)])

# --- stand-level derived: VOL uses same 0.45*BA*HT rule as the AcadianGY battery ---
D[, HT  := LryH]
D[, VOL := 0.45*BA*HT]
D[, SDI := TPH*(QMD/25.4)^1.6]   # Reineke SDI, same per-stand form as battery sdi_of

# --- per-site mean trajectory by projection age (analog of the single seeded stand) ---
TR <- D[, .(HT=mean(HT,na.rm=TRUE), TPH=mean(TPH,na.rm=TRUE), BAPH=mean(BA,na.rm=TRUE),
            QMD=mean(QMD,na.rm=TRUE), SDI=mean(SDI,na.rm=TRUE), VOL=mean(VOL,na.rm=TRUE),
            nst=.N), by=.(site,age=Age)]
TR <- TR[is.finite(HT)&is.finite(BAPH)]
fwrite(TR, "osm_bakuzis_traj_bysite.csv")
cat("\nmax projection age reached:", max(TR$age),
    " | sites:", paste(unique(TR$site),collapse=","), "\n")

s <- copy(TR)   # mirror the battery variable name

# 1 Eichhorn: V ~ unique function of HT across sites. CV of VOL at matched HT bins.
s[, htbin := round(HT/2)*2]
ei  <- s[, .(v=mean(VOL), n=length(unique(site))), by=htbin][n>=2]
cvv <- s[htbin %in% ei$htbin, .(cv=sd(VOL)/mean(VOL)), by=htbin]
eich_cv <- 100*mean(cvv$cv, na.rm=TRUE)
eich <- ifelse(eich_cv<15, "PASS", "FLAG")

# 2 Reineke self-thinning slope on the MID-site trajectory (analog of seeded site 16):
#   mature phase = TPH declining and QMD>10; slope of log(TPH)~log(QMD).
reslope <- NA_real_
st <- s[site=="MID"][order(age)]; st[, dTPH := c(NA, diff(TPH))]
mat <- st[is.finite(dTPH) & dTPH < -1 & QMD>10]
if (nrow(mat)>=5) reslope <- coef(lm(log(TPH)~log(QMD), data=mat))[2]
# robustness: pooled per-stand density-frontier slope
Dm <- D[order(SurveyID,Age)]; Dm[, dT := c(NA,diff(TPH)), by=SurveyID]
poolmat <- Dm[is.finite(dT) & dT < -1 & QMD>10]
reslope_pool <- if (nrow(poolmat)>=20) coef(lm(log(TPH)~log(QMD), data=poolmat))[2] else NA_real_
reineke <- ifelse(is.finite(reslope) && reslope>=-1.8 && reslope<=-1.4, "PASS", "FLAG")

# 3 site ordering: higher site never below lower at same age (HT and VOL)
w <- dcast(s, age~site, value.var=c("HT","VOL"))
inv_ht  <- sum((w$HT_HIGH  < w$HT_MID)  | (w$HT_MID  < w$HT_LOW),  na.rm=TRUE)
inv_vol <- sum((w$VOL_HIGH < w$VOL_MID) | (w$VOL_MID < w$VOL_LOW), na.rm=TRUE)
siteord <- ifelse(inv_ht==0 & inv_vol==0, "PASS", "FLAG")

# 4 yield-density / plateau on MID-site trajectory: BA plateau in realistic range vs runaway
bamax <- max(st$BAPH); ba160 <- st$BAPH[st$age==max(st$age)]
sdlast <- sd(tail(st$BAPH,20))
plateau <- ifelse(bamax<=42 & sdlast<2.0, "PASS", "FLAG")

# 5 Sukachev: mean size (QMD) rises as density (TPH) falls in mature phase (neg slope)
suk <- NA_real_; if (nrow(mat)>=5) suk <- coef(lm(QMD~TPH, data=mat))[2]
sukachev <- ifelse(is.finite(suk) && suk<0, "PASS", "FLAG")

# --- supporting endpoint stats per site ---
ep <- TR[, .SD[age==max(age)], by=site][, .(site, ageEnd=age, BA_end=round(BAPH,1),
        SDI_end=round(SDI,0), QMD_end=round(QMD,1), TPH_end=round(TPH,0),
        HT_end=round(HT,1), VOL_end=round(VOL,1))]
bamax_site <- TR[, .(BAmax=round(max(BAPH),1), BA_end=round(BAPH[which.max(age)],1)), by=site]

OSM <- data.table(model="OSM", Eichhorn=eich, eich_cv=round(eich_cv,1),
  Reineke=reineke, reineke_slope=round(reslope,2), reineke_slope_pooled=round(reslope_pool,2),
  SiteOrdering=siteord, inv_ht=inv_ht, inv_vol=inv_vol,
  YieldDensity_plateau=plateau, BAmax=round(bamax,1), BA160=round(ba160,1),
  Sukachev=sukachev, sukachev_slope=round(suk,4))

cat("\n=== OSM SITE ENDPOINT STATS (age", max(TR$age), ") ===\n"); print(ep)
cat("\n=== OSM BAmax vs BA-end by site (plateau/runaway check) ===\n"); print(bamax_site)
cat("\n=== OSM BAKUZIS FIVE-RELATION SCORE ===\n"); print(OSM)
fwrite(OSM, "osm_bakuzis_relations_row.csv")

# Eichhorn cross-site volume spread at matched heights (report the numbers)
cat("\n=== Eichhorn: CV of VOL across sites at matched HT bins ===\n")
print(cvv[order(htbin)])
cat("mean eich_cv (%):", round(eich_cv,1), "\n")

cat("\nDONE_OSM_BAKUZIS\n")

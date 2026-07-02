# ESI-consistent dominant-height anchor recalibration DIAGNOSTIC.
# The v12 anchor is Htop=A*(1-exp(-k*age))^p with A set by ESI; top height is over-predicted (+7% NB,
# +13% QC). Quantify the top-height LEVEL bias factor f = pred/obs and the height-increment bias, as a
# function of ESI and region, so the ESI-to-A mapping can be scaled (A_new = A/f) to make top height
# unbiased. Uses the per-stand comprehensive results (TOPHT_t1, TOPHT_o, TOPHT_p) joined to ESI per site.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
d <- fread("cb_v1270_results.csv"); d[, STAND:=as.character(STAND)]
pr <- fread("magp_qcnb_pairs.csv")[, .(STAND=as.character(STAND), SITE=as.character(SITE))]
e8 <- fread("magp_qcnb_site_esi8.csv"); e8[, SITE:=as.character(SITE)][, esi8:=as.numeric(esi8)]
d <- merge(d, pr, by="STAND"); d <- merge(d, e8, by="SITE", all.x=TRUE)
d <- d[is.finite(TOPHT_o) & TOPHT_o>2 & is.finite(TOPHT_p) & is.finite(TOPHT_t1)]
d[, f := TOPHT_p/TOPHT_o]                      # level bias factor
d[, hgi_o := (TOPHT_o-TOPHT_t1)/iv]           # obs top-height increment (m/yr)
d[, hgi_p := (TOPHT_p-TOPHT_t1)/iv]           # pred top-height increment
cat("=== top-height level bias factor f = pred/obs, by region ===\n")
for(pv in c("NB","QC")){ s<-d[PROV==pv]
  cat(sprintf("%s n=%d: mean f %.3f (bias %+.1f%%) | obs HGI %.3f pred HGI %.3f (ratio %.2f) | mean ESI %.1f\n",
    pv, nrow(s), mean(s$f), 100*(mean(s$TOPHT_p)/mean(s$TOPHT_o)-1),
    mean(s$hgi_o), mean(s$hgi_p), mean(s$hgi_p)/mean(s$hgi_o), mean(s$esi8,na.rm=TRUE))) }
cat("\n=== f vs ESI (does the anchor over-prediction scale with ESI?) ===\n")
d[, esibin := cut(esi8, c(0,15,17,19,21,60))]
print(d[!is.na(esibin), .(n=.N, meanESI=round(mean(esi8),1), f=round(mean(f),3),
        bias_pct=round(100*(mean(TOPHT_p)/mean(TOPHT_o)-1),1)), by=.(PROV,esibin)][order(PROV,esibin)])
cat("\n=== ESI-consistent correction: scale factor to apply to A (=1/f) ===\n")
m <- lm(f ~ esi8*PROV, data=d[is.finite(esi8)])
cat("f = ", round(coef(m)[1],3), "+", round(coef(m)["esi8"],4), "*ESI (NB); QC offset ",
    round(coef(m)["PROVQC"],3), "\n", sep="")
cat(sprintf("Region correction (divide anchor A by these): NB %.3f, QC %.3f\n",
    mean(d[PROV=="NB"]$f), mean(d[PROV=="QC"]$f)))
fwrite(d[, .(STAND,PROV,esi8,TOPHT_t1,TOPHT_o,TOPHT_p,f,hgi_o,hgi_p)], "topht_recal_diag.csv")
cat("DONE\n")

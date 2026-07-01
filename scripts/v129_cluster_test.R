.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron")
m <- fread("magplot/verify/v129_magplot_sdimax.csv")
f <- fread("silc_cfi/v129_fia_sdimax.csv")
d <- rbind(m, f, fill=TRUE)
d <- d[is.finite(lat)&is.finite(lon)&is.finite(esi)&is.finite(sdimax_cur)&is.finite(SDI_o)&
       is.finite(TPH1)&TPH1>0&is.finite(TPH2)&TPH2>0&is.finite(years)&years>0&sdimax_cur>0]
cat("n stands total:", nrow(d), " by source:\n"); print(table(d$source, d$PROV))

## ESI SPATIAL CLUSTER: k-means on scaled [esi, lat, lon] so clusters are geographically coherent
## zones of similar site quality, not just an ESI value bin scattered across the map.
set.seed(42)
K <- 6
X <- scale(d[, .(esi, lat, lon)])
km <- kmeans(X, centers=K, nstart=25, iter.max=50)
d[, esi_cluster := factor(km$cluster)]
cat("\nCluster sizes and mean ESI / lat / lon / PROV mix:\n")
print(d[, .(n=.N, mean_esi=round(mean(esi),1), mean_lat=round(mean(lat),2), mean_lon=round(mean(lon),2),
            pctNB=round(100*mean(PROV=="NB"),0), pctQC=round(100*mean(PROV=="QC"),0), pctME=round(100*mean(PROV=="ME"),0)),
         by=esi_cluster][order(esi_cluster)])

## Relative density under the CURRENT model max SDI, and observed density-loss rate (self-thinning)
d[, RD_cur := SDI_o/sdimax_cur]
d[, mort := -log(TPH2/TPH1)/years]
d <- d[is.finite(RD_cur) & is.finite(mort) & mort > -0.15 & mort < 0.30]
cat("\nn after mort filter:", nrow(d), "\n")

cat("\n=== Does RD (under the CURRENT sdimax formula) differ by ESI cluster among heavy self-thinners? ===\n")
hi <- d[mort > quantile(mort, 0.90, na.rm=TRUE)]
print(hi[, .(n=.N, median_RD_heavy_thinners=round(median(RD_cur),3)), by=esi_cluster][order(esi_cluster)])
cat("(if the current formula's ceiling were correct everywhere, heavy self-thinners should sit at RD near 1\n")
cat(" in every cluster; systematic deviation by cluster is the signal that a cluster factor is needed)\n")

cat("\n=== Same diagnostic by PROV (NB vs QC vs ME), for comparison to the cluster factor ===\n")
print(hi[, .(n=.N, median_RD_heavy_thinners=round(median(RD_cur),3)), by=PROV])

## Derive a per-cluster multiplier so heavy self-thinners sit at RD ~ 1, then test pooled improvement
mult <- hi[, .(mult=1/median(RD_cur)), by=esi_cluster]
d <- merge(d, mult, by="esi_cluster", all.x=TRUE)
d[is.na(mult), mult:=1]
d[, RD_adj := RD_cur*mult]
cat(sprintf("\nPooled correlation(mort, RD): current formula %.3f  |  + ESI-cluster level correction %.3f\n",
    cor(d$RD_cur, d$mort), cor(d$RD_adj, d$mort)))
r2 <- function(fit) summary(fit)$r.squared
cat(sprintf("Pooled linear R2 of mort ~ pmax(0,RD-1): current %.4f  |  + ESI-cluster correction %.4f\n",
    r2(lm(mort ~ I(pmax(0,RD_cur-1)), data=d)), r2(lm(mort ~ I(pmax(0,RD_adj-1)), data=d))))

fwrite(d, "magplot/verify/v129_combined_sdimax.csv")
fwrite(mult, "magplot/verify/v129_cluster_multipliers.csv")
cat("\nDONE_CLUSTER_TEST\n")

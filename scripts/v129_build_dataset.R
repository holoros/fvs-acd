# v12.9 exploration: does an ESI spatial cluster factor improve on AcadianGY's existing
# Weiskittel & Kuehne (2019) calc_sdi_max() (already composition- and site-aware)?
# Builds a per-stand table: current model sdi.max, observed SDI at t2, mortality rate,
# ESI, lat/lon, from MagPlot NB+QC and recent Maine FIA (both already benchmarked datasets).
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({library(data.table); library(dplyr)})
setwd("/users/PUOM0008/crsfaaron")
source("~/AcadianGY_12.7.1.r")  # gives sp.attr, calc_plot_summary(), calc_sdi_max()

mkTree <- function(STAND, sp, dbh, expf){
  data.frame(plot=STAND, tree=seq_along(dbh), sp=sp, dbh=dbh, expf=expf, stringsAsFactors=FALSE) %>%
    mutate(ba = pi*(dbh/200)^2*expf) %>%
    left_join(sp.attr %>% dplyr::rename(sp=species), by="sp")
}
sdiObs <- function(dbh, expf) sum(ifelse(dbh>=10, (dbh/25.4)^1.6*expf, 0), na.rm=TRUE)  # matches calc_plot_summary$sdi

out <- list()

## ---- MagPlot NB+QC ----
pr <- fread("magplot/verify/magp_qcnb_pairs.csv")
ti <- fread("magplot/verify/magp_qcnb_tree_init.csv")
t2 <- fread("magplot/verify/magp_qcnb_tree_t2.csv")
e8 <- fread("magplot/verify/magp_qcnb_site_esi8.csv")
pr <- merge(pr, e8, by="SITE", all.x=TRUE)
cat("MagPlot pairs:", nrow(pr), "\n")
setkey(ti, STAND); setkey(t2, STAND)
res <- vector("list", nrow(pr))
for(k in seq_len(nrow(pr))){
  p <- pr[k]; sid <- p$STAND
  it <- ti[.(sid)]; ot <- t2[.(sid)]
  if(nrow(it)<3 || nrow(ot)<3) next
  tr <- mkTree(sid, toupper(it$SP), it$DBH, it$EXPF)
  tr$sp[!(tr$sp %in% sp.attr$species)] <- "99"
  tr <- tr %>% dplyr::select(-sp.type,-sg,-wd,-shade,-drought,-waterlog,-sp.grp.ingrowth) %>%
       left_join(sp.attr %>% dplyr::rename(sp=species), by="sp")
  ps <- tryCatch(calc_plot_summary(tr), error=function(e) NULL)
  if(is.null(ps) || nrow(ps)==0) next
  elev_use <- if(is.finite(p$ELEV) && p$ELEV>0) p$ELEV else 200
  csi_use  <- if(is.finite(p$esi8) && p$esi8>2) p$esi8 else 14
  dbhr <- tr %>% dplyr::group_by(plot) %>%
    dplyr::summarise(dbh.range = ifelse(any(dbh>=10,na.rm=TRUE),
        max(ifelse(dbh>=10,dbh,NA),na.rm=TRUE)-min(ifelse(dbh>=10,dbh,NA),na.rm=TRUE),0),
        spp.div=dplyr::n_distinct(sp), .groups="drop")
  sdimax_cur <- 475.2079 - 1.5908*ps$ba.perc.hw[1] - 236.9051*log(ps$meansg[1]) +
    50.3299*sqrt(dbhr$dbh.range[1]) + 13.5202*dbhr$spp.div[1] +
    0.0685*elev_use - 2.8537*sqrt(elev_use) + 222.7836/csi_use
  sdi_o <- sdiObs(ot$DBH, ot$EXPF)
  tph1 <- sum(it$EXPF); tph2 <- sum(ot$EXPF)
  res[[k]] <- data.frame(source="magplot", STAND=sid, PROV=p$PROV, lat=p$lat, lon=p$lon, esi=csi_use,
                          elev=elev_use, years=p$interval_years, sdimax_cur=sdimax_cur, SDI_o=sdi_o,
                          TPH1=tph1, TPH2=tph2)
}
mres <- rbindlist(res); cat("MagPlot stands scored:", nrow(mres), "\n")
out[["magplot"]] <- mres
fwrite(mres, "magplot/verify/v129_magplot_sdimax.csv")

cat("DONE_PART1\n")

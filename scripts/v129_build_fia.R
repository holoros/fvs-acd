.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({library(data.table); library(dplyr)})
setwd("/users/PUOM0008/crsfaaron")
source("~/AcadianGY_12.7.1.r")

sdiObs <- function(dbh, expf) sum(ifelse(dbh>=10, (dbh/25.4)^1.6*expf, 0), na.rm=TRUE)
SPCD_to_AGY <- c("12"="BF","97"="RS","375"="PB","371"="YB","316"="RM","241"="WC","261"="EH","95"="BS","91"="WS","105"="JP","129"="WP","318"="SM","531"="BC","746"="QA","833"="RO","541"="WA","934"="GB","126"="PR","136"="RP","743"="BP","356"="HH","409"="EC","491"="PC")
mapsp <- function(spcd){ s<-SPCD_to_AGY[as.character(spcd)]; s[is.na(s)]<-"99"; s }

FIA <- "/users/PUOM0008/crsfaaron/fia_data"
pl <- fread(file.path(FIA,"ME_PLOT.csv"), select=c("CN","PREV_PLT_CN","MEASYEAR","REMPER","LAT","LON","ELEV"))
pl[, CN:=as.character(CN)][, PREV_PLT_CN:=as.character(PREV_PLT_CN)]
pr <- pl[!is.na(PREV_PLT_CN) & PREV_PLT_CN!="" & PREV_PLT_CN!="NA" & is.finite(REMPER) & REMPER>=4 & REMPER<=15 & MEASYEAR>=2010]
tr <- fread(file.path(FIA,"ME_TREE.csv"), select=c("PLT_CN","SPCD","DIA","HT","TPA_UNADJ","STATUSCD"))
tr[, PLT_CN:=as.character(PLT_CN)]; tr <- tr[STATUSCD==1 & is.finite(DIA) & DIA>0]
tr[, tpa := fifelse(is.finite(TPA_UNADJ)&TPA_UNADJ>0, TPA_UNADJ, fifelse(DIA<5,74.965,6.018))]
tr[, tph := tpa*2.4710538147][, dbh_cm := DIA*2.54][, sp := mapsp(SPCD)]
esi <- fread("silc_cfi/me_plot_esi8.csv", colClasses=c(CN="character"))
pr <- merge(pr, esi, by="CN", all.x=TRUE)
set.seed(11); N <- min(nrow(pr), 3000); pr <- pr[sample(.N, N)]
setkey(tr, PLT_CN); setDF(pr)
cat("FIA pairs sampled:", nrow(pr), "\n")
res <- vector("list", nrow(pr))
for(k in seq_len(nrow(pr))){
  p <- pr[k,]
  it <- tr[.(p$PREV_PLT_CN)]; ot <- tr[.(p$CN)]
  if(nrow(it)<5 || nrow(ot)<5) next
  trd <- data.frame(plot=p$CN, tree=seq_len(nrow(it)), sp=it$sp, dbh=it$dbh_cm, expf=it$tph, stringsAsFactors=FALSE) %>%
    mutate(ba = pi*(dbh/200)^2*expf) %>% left_join(sp.attr %>% dplyr::rename(sp=species), by="sp")
  ps <- tryCatch(calc_plot_summary(trd), error=function(e) NULL)
  if(is.null(ps) || nrow(ps)==0) next
  elev_use <- if(is.finite(p$ELEV)&&p$ELEV>0) p$ELEV*0.3048 else 200
  csi_use  <- if(is.finite(p$esi8)&&p$esi8>2) p$esi8 else 14
  dbhr <- trd %>% dplyr::group_by(plot) %>%
    dplyr::summarise(dbh.range = ifelse(any(dbh>=10,na.rm=TRUE),
        max(ifelse(dbh>=10,dbh,NA),na.rm=TRUE)-min(ifelse(dbh>=10,dbh,NA),na.rm=TRUE),0),
        spp.div=dplyr::n_distinct(sp), .groups="drop")
  sdimax_cur <- 475.2079 - 1.5908*ps$ba.perc.hw[1] - 236.9051*log(ps$meansg[1]) +
    50.3299*sqrt(dbhr$dbh.range[1]) + 13.5202*dbhr$spp.div[1] +
    0.0685*elev_use - 2.8537*sqrt(elev_use) + 222.7836/csi_use
  sdi_o <- sdiObs(ot$dbh_cm, ot$tph)
  res[[k]] <- data.frame(source="fia_recent", STAND=p$CN, PROV="ME", lat=p$LAT, lon=p$LON, esi=csi_use,
                          elev=elev_use, years=p$REMPER, sdimax_cur=sdimax_cur, SDI_o=sdi_o,
                          TPH1=sum(it$tph), TPH2=sum(ot$tph))
}
fres <- rbindlist(res); cat("FIA stands scored:", nrow(fres), "\n")
fwrite(fres, "silc_cfi/v129_fia_sdimax.csv")
cat("DONE_PART2\n")

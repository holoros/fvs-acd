# Remeasured Maine FIA stress test for AcadianGY: site input (legacy CSI, ESI,
# 2030 CSI) crossed with MORTCAL off/on, BA/TPA/QMD bias by horizon. Rebuilds the
# remeasurement pairs from ME_PLOT/ME_TREE (the prior validation_data is gone),
# extracts the three site surfaces at plot coordinates, projects each pair its
# REMPER years, and scores against observed t2. AcadianGY 12.3.9.
suppressMessages({ library(data.table); library(terra); library(dplyr); library(plyr); library(purrr) })
FIA <- "/users/PUOM0008/crsfaaron/fia_data"; SI <- "/users/PUOM0008/crsfaaron/SiteIndex"
ACL <- "/users/PUOM0008/crsfaaron/SiteIndex/acd_clim"
ENR <- "/fs/scratch/PUOM0008/crsfaaron/maine_pilot/maine_pilot_results/maine_enriched_frame.csv"
OUT <- "/users/PUOM0008/crsfaaron/acadgy_fia_verify"; set.seed(2030)
ACRES_PER_HA <- 2.4710538147; ft2_ac_per_m2_ha <- 4.35; N_PLOTS <- 700L
source("~/AcadianGY_12.3.9.r")

## 1. remeasurement pairs from ME_PLOT
pl <- fread(file.path(FIA,"ME_PLOT.csv"), select=c("CN","PREV_PLT_CN","MEASYEAR","REMPER","LAT","LON"))
pl[, CN:=as.character(CN)][, PREV_PLT_CN:=as.character(PREV_PLT_CN)]
pr <- pl[!is.na(PREV_PLT_CN) & PREV_PLT_CN!="" & PREV_PLT_CN!="NA" &
         is.finite(REMPER) & REMPER>=4 & REMPER<=15 & is.finite(LAT) & is.finite(LON)]
cat("remeasurement pairs:", nrow(pr), "\n")

## 2. trees: live, with FIA expansion
tr <- fread(file.path(FIA,"ME_TREE.csv"), select=c("PLT_CN","SPCD","DIA","HT","TPA_UNADJ","STATUSCD"))
tr[, PLT_CN:=as.character(PLT_CN)]
tr <- tr[STATUSCD==1 & is.finite(DIA) & DIA>0]
tr[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ>0, TPA_UNADJ, fifelse(DIA<5, 74.965, 6.018))]

## 3. observed t2 metrics (at curr plot CN)
obs <- tr[, .(BA_t2=sum(0.005454*DIA^2*tpa), TPA_t2=sum(tpa),
              QMD_t2=sqrt(sum(DIA^2*tpa)/sum(tpa))), by=PLT_CN]
pr <- merge(pr, obs, by.x="CN", by.y="PLT_CN")           # require observed t2
pr <- pr[is.finite(BA_t2) & BA_t2>0]
# t1 trees must exist
t1n <- tr[, .N, by=PLT_CN]; pr <- pr[PREV_PLT_CN %in% t1n$PLT_CN]
cat("pairs with t2 obs and t1 trees:", nrow(pr), "\n")
if (nrow(pr) > N_PLOTS) pr <- pr[sample(.N, N_PLOTS)]

## 4. site inputs at plot coords: ESI (enriched + raster), legacy CSI, 2030 CSI
enr <- fread(ENR, select=c("PLT_CN","ESI")); enr[, PLT_CN:=as.character(PLT_CN)]
pr <- merge(pr, enr, by.x="CN", by.y="PLT_CN", all.x=TRUE)   # ESI by curr CN
pts <- vect(as.data.frame(pr[, .(LON,LAT)]), geom=c("LON","LAT"), crs="EPSG:4326")
esi_r <- rast(file.path(SI,"Final_SI_Output.tif"))[[1]]
csi_r <- rast(file.path(SI,"ClimateNA_SI_m.tif"))[[1]]
c30_r <- rast(file.path(ACL,"AcadianSIm_2030.tif"))[[1]]
pr[, ESI_rast := terra::extract(esi_r, project(pts, crs(esi_r)))[[2]]]
pr[, legacyCSI := terra::extract(csi_r, project(pts, crs(csi_r)))[[2]]]
pr[, CSI2030 := terra::extract(c30_r, project(pts, crs(c30_r)))[[2]]]
pr[, ESIuse := fifelse(is.finite(ESI), ESI, ESI_rast)]
cat("site means: ESI", round(mean(pr$ESIuse,na.rm=T),2), " legacyCSI", round(mean(pr$legacyCSI,na.rm=T),2),
    " CSI2030", round(mean(pr$CSI2030,na.rm=T),2), "\n")
pr <- pr[is.finite(ESIuse) & is.finite(legacyCSI) & is.finite(CSI2030)]
cat("pairs with all 3 site inputs:", nrow(pr), "\n")

## 5. build AcadianGY t1 input
SPCD_to_AGY <- c("12"="BF","97"="RS","375"="PB","371"="YB","316"="RM","241"="WC","261"="EH","95"="BS",
  "91"="WS","105"="JP","129"="WP","318"="SM","531"="BC","746"="QA","833"="RO","541"="WA","934"="GB",
  "126"="PR","130"="PR","136"="RP","68"="WC","241"="WC","746"="QA","743"="BP","742"="BT","935"="ST",
  "313"="ST","356"="HH","391"="HH","402"="GB","409"="EC","491"="PC","543"="BC","762"="PR")
acadgy_species <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TA","WA","WC","WP","WS","YB")
t1 <- tr[PLT_CN %in% pr$PREV_PLT_CN]
t1[, SP := SPCD_to_AGY[as.character(SPCD)]]
t1[is.na(SP) | !(SP %in% acadgy_species), SP := fifelse(SPCD>=300,"OH","OS")]
t1[, DBHcm := DIA*2.54]
t1[, HTm := fifelse(is.finite(HT) & HT>0, HT*0.3048, pmax(2,1.3+30*(1-exp(-0.04*DBHcm))))]
t1[, EXPF := tpa*ACRES_PER_HA]
base_init <- t1[, .(STAND=PLT_CN, PLOT=1L, SP, DBH=DBHcm, HT=HTm, HCB=NA_real_, EXPF,
  YEAR=2000, dDBH.mult=1, dHt.mult=1, mort.mult=1, max.dbh=200, max.height=50, Form=NA, Risk=NA)]
base_init[, TREE := seq_len(.N), by=STAND]
base_init <- as.data.frame(base_init[, .(STAND,PLOT,TREE,SP,DBH,HT,HCB,EXPF,YEAR,dDBH.mult,dHt.mult,mort.mult,max.dbh,max.height,Form,Risk)])
setkey(pr, PREV_PLT_CN)
n_years <- 15L

## 6. project + score
basnap <- function(df) tapply((df$DBH^2)*0.00007854*df$EXPF, df$STAND, sum, na.rm=TRUE)
tpsnap <- function(df) tapply(df$EXPF, df$STAND, sum, na.rm=TRUE)
qmsnap <- function(df) sqrt(tapply(df$DBH^2*df$EXPF, df$STAND, sum, na.rm=TRUE)/tapply(df$EXPF, df$STAND, sum, na.rm=TRUE))
site_col <- function(cfg) switch(cfg, legacy="legacyCSI", ESI="ESIuse", CSI2030="CSI2030")
run_cfg <- function(site_cfg, mortcal) {
  sc <- site_col(site_cfg)
  csi_of <- setNames(pr[[sc]], pr$PREV_PLT_CN); int_of <- setNames(pmin(pmax(round(pr$REMPER),1L),n_years), pr$PREV_PLT_CN)
  cur <- base_init; bl<-list();tl<-list();ql<-list()
  bl[["0"]]<-basnap(cur);tl[["0"]]<-tpsnap(cur);ql[["0"]]<-qmsnap(cur)
  for (yr in 1:n_years) {
    pc <- list()
    for (sid in unique(cur$STAND)) {
      sub <- cur[cur$STAND==sid,]; if(!nrow(sub)) next
      st <- list(CSI=as.numeric(csi_of[sid]), ELEV=200)
      ops <- list(verbose=FALSE, INGROWTH="Y", MinDBH=3.0)
      if (mortcal) { ops$MORTCAL<-TRUE; iv<-as.numeric(int_of[sid]); ops$MORTCAL_INTERVAL<-if(is.na(iv)||iv<1) 5 else iv }
      p <- tryCatch(AcadianGYOneStand(sub, stand=st, ops=ops), error=function(e) NULL)
      if (!is.null(p)) pc[[sid]] <- p
    }
    if (!length(pc)) break
    cur <- dplyr::bind_rows(pc)
    bl[[as.character(yr)]]<-basnap(cur);tl[[as.character(yr)]]<-tpsnap(cur);ql[[as.character(yr)]]<-qmsnap(cur)
  }
  gm <- function(by,s,i){k<-as.character(min(max(round(i),1),n_years));v<-by[[k]][as.character(s)];if(length(v)==0||is.na(v)) NA_real_ else as.numeric(v)}
  data.table(PREV=pr$PREV_PLT_CN, interval=pr$REMPER,
    BA_pred=mapply(function(s,i) gm(bl,s,i), pr$PREV_PLT_CN, pr$REMPER)*ft2_ac_per_m2_ha,
    TPA_pred=mapply(function(s,i) gm(tl,s,i), pr$PREV_PLT_CN, pr$REMPER)/ACRES_PER_HA,
    QMD_pred=mapply(function(s,i) gm(ql,s,i), pr$PREV_PLT_CN, pr$REMPER)/2.54,
    BA_t2=pr$BA_t2, TPA_t2=pr$TPA_t2, QMD_t2=pr$QMD_t2)
}
bias <- function(p,o){ok<-is.finite(p)&is.finite(o);100*(mean(p[ok])/mean(o[ok])-1)}
hbinf <- function(iv) cut(iv, c(0,7,11,20), labels=c("5-7yr","8-11yr","12-15yr"))
rows <- list()
for (cfg in c("legacy","ESI","CSI2030")) for (mc in c(FALSE,TRUE)) {
  d <- run_cfg(cfg, mc); d <- d[is.finite(BA_pred)&is.finite(BA_t2)]; d[, hb:=hbinf(interval)]
  lab <- paste0(cfg, if(mc) "_on" else "_off")
  for (HB in c("ALL","5-7yr","8-11yr","12-15yr")) { s <- if(HB=="ALL") d else d[d$hb==HB]
    rows[[paste(lab,HB)]] <- data.frame(config=lab, horizon=HB, n=nrow(s),
      BA_bias=round(bias(s$BA_pred,s$BA_t2),1), TPA_bias=round(bias(s$TPA_pred,s$TPA_t2),1), QMD_bias=round(bias(s$QMD_pred,s$QMD_t2),1)) }
  cat(lab, "ALL BA", round(bias(d$BA_pred,d$BA_t2),1), "% TPA", round(bias(d$TPA_pred,d$TPA_t2),1), "%\n")
}
tab <- do.call(rbind, rows)
write.csv(tab, file.path(OUT,"acadgy_fia_remeas_stress.csv"), row.names=FALSE)
cat("\n=== Maine FIA remeasured: site x MORTCAL (BA/TPA/QMD bias by horizon) ===\n")
print(tab[tab$horizon=="ALL",], row.names=FALSE)
cat("\n-- by horizon --\n"); print(tab[tab$horizon!="ALL",], row.names=FALSE); cat("DONE\n")

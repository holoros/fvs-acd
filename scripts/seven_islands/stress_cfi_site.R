# Seven Islands CFI site-driver stress test. Project every CFI remeasurement
# pair under three site inputs (flat CSI=12 baseline, per-plot legacy ClimateNA
# SI, per-plot modern ESI) plus a context grid, scored vs observed BA/TPA/QMD.
# Coordinates are GNIS township centroids (10 km uncertainty). AcadianGY 12.3.9.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(plyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
ACRES_PER_HA <- 2.4710538147
source("~/AcadianGY_12.3.9.r")
manifest <- read.csv("silc_cfi_pair_summary.csv", stringsAsFactors=FALSE)
si <- read.csv("silc_plot_si.csv", stringsAsFactors=FALSE)
manifest <- merge(manifest, si[,c("PLOT","legacyCSI","ESI")], by="PLOT", all.x=TRUE)
cat("pairs:", nrow(manifest), " with SI:", sum(is.finite(manifest$ESI)), "\n")

acadgy_species <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS",
  "OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TA","WA","WC","WP","WS","YB")
cfi_to_agy <- c("BF"="BF","RS"="RS","PB"="PB","YB"="YB","RM"="RM","SM"="SM","WA"="WA","RO"="RO","BS"="BS",
  "WS"="WS","JP"="JP","RP"="RP","WP"="WP","EH"="EH","HM"="EH","CE"="WC","WC"="WC","BE"="BC","QA"="QA",
  "GB"="GB","BC"="BC","BA"="BA","AB"="AB","ST"="ST","TA"="TA")
SPCD_to_AGY <- c("12"="BF","97"="RS","375"="PB","371"="YB","316"="RM","241"="WC","261"="EH","95"="BS",
  "91"="WS","105"="JP","129"="WP","318"="SM","531"="BC","746"="QA","833"="RO","541"="WA","934"="GB")
prep_tree_metric <- function(td, year_prev) {
  td$SP <- ifelse(td$SP %in% names(cfi_to_agy), cfi_to_agy[td$SP], NA)
  miss <- is.na(td$SP) | nchar(td$SP)==0
  td$SP[miss] <- SPCD_to_AGY[as.character(td$SPCD[miss])]
  bad <- is.na(td$SP) | !(td$SP %in% acadgy_species)
  td$SP[bad] <- ifelse(td$SPCD[bad] >= 300, "OH", "OS")
  DBH_cm <- td$DBH * 2.54
  HT_m <- ifelse(!is.na(td$HT)&td$HT>0, td$HT*0.3048, NA_real_)
  mh <- is.na(HT_m)|HT_m==0; HT_m[mh] <- pmax(2,1.3+25*(1-exp(-0.04*DBH_cm[mh])))
  data.frame(STAND=sprintf("CFI_%04d",td$PLOT[1]), PLOT=1L, TREE=seq_len(nrow(td)), SP=td$SP,
    DBH=DBH_cm, HT=HT_m, HCB=NA_real_, EXPF=td$EXPF*ACRES_PER_HA, YEAR=year_prev,
    dDBH.mult=1, dHt.mult=1, mort.mult=1, max.dbh=200, max.height=50, Form=NA, Risk=NA, stringsAsFactors=FALSE)
}
stand_metrics_imperial <- function(df) {
  DBH_in <- df$DBH/2.54; HT_ft <- df$HT/0.3048; EXPF_ac <- df$EXPF/ACRES_PER_HA
  live <- DBH_in>=4.5 & !is.na(DBH_in); d<-DBH_in[live]; h<-HT_ft[live]; e<-EXPF_ac[live]
  if (length(d)==0) return(list(BA=0,TPA=0,QMD=NA,Cords=0))
  BA<-sum(0.005454*d^2*e); TPA<-sum(e); QMD<-if(TPA>0) sqrt((BA/TPA)/0.005454) else NA
  Cords<-sum(0.0025*d^2*h*0.90*e)/79
  list(BA=BA,TPA=TPA,QMD=QMD,Cords=Cords)
}
run_one_pair <- function(p_row, CSI_M, ELEV_M=305) {
  tf <- p_row$tree_list_file; if(!file.exists(tf)) return(NULL)
  td <- read.csv(tf, stringsAsFactors=FALSE); if(nrow(td)==0) return(NULL)
  if (!is.finite(CSI_M)) return(NULL)
  cur <- prep_tree_metric(td, p_row$YEAR_PREV)
  ops <- list(verbose=FALSE, INGROWTH="Y", MinDBH=5.0)
  stand <- list(CSI=CSI_M, ELEV=ELEV_M)
  ok <- TRUE
  for (yr in seq_len(p_row$PERIOD_YR)) {
    nxt <- tryCatch(AcadianGYOneStand(cur, stand=stand, ops=ops), error=function(e) NULL)
    if (is.null(nxt)) { ok<-FALSE; break }; cur<-nxt; cur$YEAR<-p_row$YEAR_PREV+yr
  }
  if (!ok) return(NULL)
  pm <- stand_metrics_imperial(cur)
  data.frame(PLOT=p_row$PLOT, BA_PRED=pm$BA, TPA_PRED=pm$TPA, QMD_PRED=pm$QMD, Cords_PRED=pm$Cords,
    BA_OBS=p_row$BA_CURR_FT2AC, TPA_OBS=p_row$TPA_CURR, QMD_OBS=p_row$QMD_CURR)
}
bias <- function(p,o){ok<-is.finite(p)&is.finite(o); 100*(mean(p[ok])/mean(o[ok])-1)}
r2  <- function(p,o){ok<-is.finite(p)&is.finite(o); if(sum(ok)<3) return(NA); 1-sum((o[ok]-p[ok])^2)/sum((o[ok]-mean(o[ok]))^2)}
score_config <- function(label, csi_vec) {
  res <- do.call(rbind, lapply(seq_len(nrow(manifest)), function(i) run_one_pair(manifest[i,], csi_vec[i])))
  data.frame(config=label, n=nrow(res), mean_site=round(mean(csi_vec,na.rm=TRUE),2),
    BA_bias=round(bias(res$BA_PRED,res$BA_OBS),1), BA_R2=round(r2(res$BA_PRED,res$BA_OBS),3),
    TPA_bias=round(bias(res$TPA_PRED,res$TPA_OBS),1), QMD_bias=round(bias(res$QMD_PRED,res$QMD_OBS),1),
    mean_BA_pred=round(mean(res$BA_PRED,na.rm=TRUE),1), mean_BA_obs=round(mean(res$BA_OBS,na.rm=TRUE),1))
}
N <- nrow(manifest)
rows <- list()
rows[["flat12"]]    <- score_config("flat_CSI_12",       rep(12, N))
rows[["legacy"]]    <- score_config("legacy_CSI_perplot", manifest$legacyCSI)
rows[["esi"]]       <- score_config("ESI_perplot",        manifest$ESI)
for (g in c(13,14,15,16)) rows[[paste0("g",g)]] <- score_config(paste0("flat_",g), rep(g,N))
tab <- do.call(rbind, rows)
write.csv(tab, "silc_cfi_site_sensitivity.csv", row.names=FALSE)
cat("\n=== Seven Islands CFI site-driver stress test (AcadianGY 12.3.9, n=", N, "pairs) ===\n", sep="")
cat("legacy CSI mean", round(mean(manifest$legacyCSI,na.rm=TRUE),2),
    "| ESI mean", round(mean(manifest$ESI,na.rm=TRUE),2),
    "| harness baseline uses flat 12\n\n")
print(tab, row.names=FALSE)
gridrows <- tab[grepl("flat_1", tab$config), ]
mono <- all(diff(gridrows$mean_BA_pred) > 0)
cat("\nBakuzis: projected BA monotone increasing in site index:", mono, "\n")
cat("DONE\n")

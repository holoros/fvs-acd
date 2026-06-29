# Seven Islands CFI site-driver stress test, long-horizon + by-horizon bias.
# Routine plots only (establishment pairs excluded). flat CSI=12 vs per-plot
# legacy ClimateNA SI vs per-plot ESI. AcadianGY 12.3.9.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(plyr); library(purrr) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
ACRES_PER_HA <- 2.4710538147
source("~/AcadianGY_12.3.9.r")
ps <- read.csv("silc_cfi_longhorizon_pairs_v16.csv", stringsAsFactors=FALSE)
si <- read.csv("silc_plot_si.csv", stringsAsFactors=FALSE)
ps <- merge(ps, si[,c("PLOT","legacyCSI","ESI")], by="PLOT", all.x=TRUE)
ps$estbl <- (ps$BA_CURR_FT2AC / pmax(ps$BA_PREV_FT2AC,1)) > 2.0
ps <- ps[!ps$estbl & is.finite(ps$ESI), ]
cat("routine long-horizon pairs with SI:", nrow(ps), "\n")

acadgy_species <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","HW","JP","NS",
  "OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","SW","TA","WA","WC","WP","WS","YB")
cfi_to_agy <- c("BF"="BF","RS"="RS","PB"="PB","YB"="YB","RM"="RM","SM"="SM","WA"="WA","RO"="RO","BS"="BS",
  "WS"="WS","JP"="JP","RP"="RP","WP"="WP","EH"="EH","HM"="EH","CE"="WC","WC"="WC","BE"="BC","QA"="QA",
  "GB"="GB","BC"="BC","BA"="BA","AB"="AB","ST"="ST","TA"="TA")
SPCD_to_AGY <- c("12"="BF","97"="RS","375"="PB","371"="YB","316"="RM","241"="WC","261"="EH","95"="BS",
  "91"="WS","105"="JP","129"="WP","318"="SM","531"="BC","746"="QA","833"="RO","541"="WA","934"="GB")
prep_tree_metric <- function(td, year_prev) {
  td$SP <- ifelse(td$SP %in% names(cfi_to_agy), cfi_to_agy[td$SP], NA)
  miss <- is.na(td$SP) | nchar(td$SP)==0; td$SP[miss] <- SPCD_to_AGY[as.character(td$SPCD[miss])]
  bad <- is.na(td$SP) | !(td$SP %in% acadgy_species); td$SP[bad] <- ifelse(td$SPCD[bad]>=300,"OH","OS")
  DBH_cm <- td$DBH*2.54; HT_m <- ifelse(!is.na(td$HT)&td$HT>0, td$HT*0.3048, NA_real_)
  mh <- is.na(HT_m)|HT_m==0; HT_m[mh] <- pmax(2,1.3+25*(1-exp(-0.04*DBH_cm[mh])))
  data.frame(STAND=sprintf("CFI_%04d",td$PLOT[1]), PLOT=1L, TREE=seq_len(nrow(td)), SP=td$SP,
    DBH=DBH_cm, HT=HT_m, HCB=NA_real_, EXPF=td$EXPF*ACRES_PER_HA, YEAR=year_prev,
    dDBH.mult=1, dHt.mult=1, mort.mult=1, max.dbh=200, max.height=50, Form=NA, Risk=NA, stringsAsFactors=FALSE)
}
stand_metrics <- function(df) {
  DBH_in <- df$DBH/2.54; EXPF_ac <- df$EXPF/ACRES_PER_HA
  live <- DBH_in>=4.5 & !is.na(DBH_in); d<-DBH_in[live]; e<-EXPF_ac[live]
  if (length(d)==0) return(list(BA=0,TPA=0,QMD=NA))
  BA<-sum(0.005454*d^2*e); TPA<-sum(e); QMD<-if(TPA>0) sqrt((BA/TPA)/0.005454) else NA
  list(BA=BA,TPA=TPA,QMD=QMD)
}
run_one <- function(p, CSI_M) {
  tf <- p$tree_list_file; if(!file.exists(tf)) return(NULL)
  td <- read.csv(tf, stringsAsFactors=FALSE); if(nrow(td)==0) return(NULL)
  cur <- prep_tree_metric(td, p$YEAR_PREV)
  ops <- list(verbose=FALSE, INGROWTH="Y", MinDBH=5.0); stand <- list(CSI=CSI_M, ELEV=305)
  for (yr in seq_len(p$PERIOD_YR)) {
    nxt <- tryCatch(AcadianGYOneStand(cur, stand=stand, ops=ops), error=function(e) NULL)
    if (is.null(nxt)) return(NULL); cur<-nxt; cur$YEAR<-p$YEAR_PREV+yr
  }
  pm <- stand_metrics(cur)
  data.frame(PLOT=p$PLOT, PERIOD=p$PERIOD_YR, BA_PRED=pm$BA, BA_OBS=p$BA_CURR_FT2AC)
}
bias <- function(p,o){ok<-is.finite(p)&is.finite(o); 100*(mean(p[ok])/mean(o[ok])-1)}
r2 <- function(p,o){ok<-is.finite(p)&is.finite(o); if(sum(ok)<3) return(NA); 1-sum((o[ok]-p[ok])^2)/sum((o[ok]-mean(o[ok]))^2)}
configs <- list(flat12=rep(12,nrow(ps)), legacy=ps$legacyCSI, ESI=ps$ESI)
ps$hbin <- cut(ps$PERIOD_YR, c(0,7,11,20), labels=c("5-7yr","8-11yr","12-15yr"))
allres <- list()
for (cn in names(configs)) {
  res <- do.call(rbind, lapply(seq_len(nrow(ps)), function(i) run_one(ps[i,], configs[[cn]][i])))
  res <- merge(res, ps[,c("PLOT","PERIOD_YR","hbin")], by=c("PLOT"), all.x=TRUE)
  res <- res[!duplicated(paste(res$PLOT,res$PERIOD)),]
  for (hb in levels(ps$hbin)) {
    s <- res[res$hbin==hb,]
    allres[[paste(cn,hb)]] <- data.frame(config=cn, horizon=hb, n=nrow(s),
      BA_bias=round(bias(s$BA_PRED,s$BA_OBS),1), BA_R2=round(r2(s$BA_PRED,s$BA_OBS),3))
  }
  allres[[paste(cn,"ALL")]] <- data.frame(config=cn, horizon="ALL", n=nrow(res),
    BA_bias=round(bias(res$BA_PRED,res$BA_OBS),1), BA_R2=round(r2(res$BA_PRED,res$BA_OBS),3))
}
tab <- do.call(rbind, allres)
write.csv(tab, "silc_cfi_horizon_scorecard.csv", row.names=FALSE)
cat("\n=== Seven Islands CFI by-horizon site-driver scorecard (routine plots) ===\n")
cat("legacy CSI mean", round(mean(ps$legacyCSI),2), "| ESI mean", round(mean(ps$ESI),2), "| baseline flat 12\n\n")
print(tab, row.names=FALSE)
cat("DONE\n")

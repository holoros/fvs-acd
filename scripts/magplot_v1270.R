# MAGPlot (Canadian CFI, NB) validation of AcadianGY 12.7.0 on the new-contract API.
# Projects each stand annually to its remeasurement interval, scores BA/TPH/QMD vs observed t2.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(purrr); library(data.table) })
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
MODEL <- Sys.getenv("MODEL_FILE", "~/AcadianGY_12.7.0.r"); source(MODEL)
CSI_DEFAULT <- as.numeric(Sys.getenv("CSI_DEFAULT", "14"))
TAG <- Sys.getenv("CONFIG_TAG", "magplot_v1270")

ti  <- fread("magplot_tree_init.csv"); prs <- fread("magplot_pairs.csv")
ti[, STAND := as.character(STAND)]; prs[, STAND := as.character(STAND)]
acadgy <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
mapsp <- function(s){ s<-toupper(s); ifelse(s %in% acadgy, s, ifelse(s %in% sw,"OS","OH")) }
bf <- function(x){ for(c in c("ddbh.mult","dht.mult","mort.mult")) x[[c]][is.na(x[[c]])]<-1; x$max.dbh[is.na(x$max.dbh)]<-200; x$max.height[is.na(x$max.height)]<-50; x }

ops <<- make_ops(verbose=FALSE, use.ingrowth=TRUE, ingrowth.min.dbh=5.0, ingrowth.thrshld=0,
                 use.cap.dbh=TRUE, use.cap.ht=TRUE, use.hw.mod=FALSE, use.sbw.mod=FALSE, use.thin.mod=FALSE, use.vol=FALSE)
ops$use.sdimort <- TRUE; ops$sdimort.onset <- 0.55; ops$sdimort.beta <- 0.10; ops$sdimort.max <- 1.0
ops$sdimax.site.term <- FALSE; ops$use.mortcal <- FALSE
setDF(ti); setDF(prs)
sids <- prs$STAND; out <- list(); fail <- 0
for (k in seq_along(sids)){
  sid <- sids[k]; p <- prs[prs$STAND==sid, , drop=FALSE][1, ]
  it <- ti[ti$STAND==sid, , drop=FALSE]
  if (nrow(it) < 3){ fail <- fail+1; next }
  iv <- max(1, round(p$interval_years))
  elev <- if (is.finite(p$ELEV) && p$ELEV>0) p$ELEV else 200
  cur <- data.frame(year=0, plot=1L, tree=seq_len(nrow(it)), sp=mapsp(it$SP),
    dbh=it$DBH, ht=ifelse(is.finite(it$HT)&it$HT>0, it$HT, NA_real_), hcb=NA_real_, cr=NA_real_, expf=it$EXPF,
    form=NA_character_, risk=NA_character_, ddbh.mult=1, dht.mult=1, mort.mult=1,
    max.dbh=200, max.height=50, stringsAsFactors=FALSE)
  stand <<- make_stand(stand.id=sid, csi=CSI_DEFAULT, elev=elev, region="NB")
  ok <- TRUE
  for (yr in seq_len(iv)){
    nx <- tryCatch(AcadianGYOneStand(tree=cur, stand=stand, ops=ops), error=function(e) NULL)
    if (is.null(nx) || nrow(nx)==0){ ok<-FALSE; break }
    cur <- bf(nx)
  }
  if (!ok){ fail<-fail+1; next }
  live <- cur[cur$dbh>=4 & is.finite(cur$dbh), ]
  BA <- sum(pi*(live$dbh/200)^2*live$expf); TPH <- sum(live$expf)
  QMD <- sqrt((BA/TPH)/(pi/40000))
  out[[sid]] <- data.frame(STAND=sid, interval=iv, BA_obs=p$BA_t2_obs, BA_pred=BA,
    TPH_obs=p$TPH_t2_obs, TPH_pred=TPH, QMD_obs=p$QMD_t2_obs, QMD_pred=QMD)
}
res <- rbindlist(out); fwrite(res, paste0(TAG, "_results.csv"))
bias <- function(p,o){ ok<-is.finite(p)&is.finite(o); round(100*(mean(p[ok])/mean(o[ok])-1),1) }
r2 <- function(p,o){ ok<-is.finite(p)&is.finite(o); round(1-sum((p[ok]-o[ok])^2)/sum((o[ok]-mean(o[ok]))^2),3) }
cat(sprintf("=== %s: MAGPlot NB Canadian CFI, AcadianGY %s, n=%d (%d failed) ===\n", TAG, basename(MODEL), nrow(res), fail))
cat(sprintf("BA  obs %.1f pred %.1f  bias %+.1f%%  R2 %.3f\n", mean(res$BA_obs), mean(res$BA_pred), bias(res$BA_pred,res$BA_obs), r2(res$BA_pred,res$BA_obs)))
cat(sprintf("QMD obs %.1f pred %.1f  bias %+.1f%%\n", mean(res$QMD_obs), mean(res$QMD_pred), bias(res$QMD_pred,res$QMD_obs)))
cat(sprintf("TPH obs %.0f pred %.0f  bias %+.1f%%\n", mean(res$TPH_obs), mean(res$TPH_pred), bias(res$TPH_pred,res$TPH_obs)))
cat("DONE\n")

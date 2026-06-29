# Project NB/NS/ME intervals under a v12.6.x config and score predicted volume+value.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({ library(dplyr); library(purrr); library(data.table) })
setwd("/users/PUOM0008/crsfaaron/silc_cfi"); source("value_fns.R")
MODEL_FILE <- Sys.getenv("MODEL_FILE","~/AcadianGY_12.6.1.r")
TAG <- Sys.getenv("CONFIG_TAG","v1261def")
source(MODEL_FILE)
USE_SDIMORT <- toupper(Sys.getenv("USE_SDIMORT","TRUE")) %in% c("TRUE","T","1","YES")
USE_MORTCAL <- toupper(Sys.getenv("USE_MORTCAL","FALSE")) %in% c("TRUE","T","1","YES")
SITE_TERM   <- toupper(Sys.getenv("SDIMAX_SITE_TERM","FALSE")) %in% c("TRUE","T","1","YES")
USE_ING     <- toupper(Sys.getenv("USE_INGROWTH","TRUE")) %in% c("TRUE","T","1","YES")
ING_THR     <- as.numeric(Sys.getenv("INGROWTH_THRSHLD","0"))   # 0=expected value, 0.95=hurdle
ING_MULT    <- as.numeric(Sys.getenv("INGROWTH_MULT","1"))
cat(sprintf("%s | model=%s sdimort=%s mortcal=%s ing=%s thr=%.2f mult=%.2f\n",
  TAG, basename(MODEL_FILE), USE_SDIMORT, USE_MORTCAL, USE_ING, ING_THR, ING_MULT))

sw_set <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS")
acadgy <- c("AB","AS","BA","BC","BF","BP","BS","BT","EC","EH","GA","GB","HH","JP","NS","OH","OS","PB","PC","PR","QA","RB","RM","RN","RO","RP","RS","SB","SM","ST","TA","WA","WC","WP","WS","YB")
mapsp <- function(sp){ sp <- toupper(sp); ifelse(sp %in% acadgy, sp, ifelse(sp %in% sw_set,"OS","OH")) }

INP <- fread("region_input_trees.csv"); MAN <- fread(Sys.getenv("MANIFEST","region_manifest.csv"))
MAXPR <- as.integer(Sys.getenv("MAXPLOTS_PER_REGION","90"))
set.seed(3); MAN <- MAN[, .SD[sample(.N, min(.N, MAXPR))], by=region]
cat(sprintf("capped to %d plots (per-region max %d)\n", nrow(MAN), MAXPR))
data.table::setDF(MAN); data.table::setDF(INP)  # base-R subsetting below (avoid data.table NSE masking the pid loop var)
ops <<- make_ops(verbose=FALSE, use.ingrowth=USE_ING, ingrowth.min.dbh=5.0,
                 ingrowth.thrshld=ING_THR, use.cap.dbh=TRUE, use.cap.ht=TRUE,
                 use.hw.mod=FALSE, use.sbw.mod=FALSE, use.thin.mod=FALSE, use.vol=FALSE)
ops$use.sdimort <- USE_SDIMORT; ops$sdimort.onset <- 0.55; ops$sdimort.beta <- 0.10; ops$sdimort.max <- 1.0
ops$sdimax.site.term <- SITE_TERM; ops$use.mortcal <- USE_MORTCAL; ops$mortcal.interval <- 5; ops$mortcal.lambda <- 1
ops$ingrowth.mult <- ING_MULT
ops$mort.cut.scale <- as.numeric(Sys.getenv("MORT_CUT_SCALE","1"))   # v12.6.4 regional stand-mortality cut scale
bf <- function(x){ for(c in c("ddbh.mult","dht.mult","mort.mult")) x[[c]][is.na(x[[c]])]<-1; x$max.dbh[is.na(x$max.dbh)]<-200; x$max.height[is.na(x$max.height)]<-50; x }

out <- list(); fail <- 0
pids <- MAN$pid
for (k in seq_along(pids)){
  pid <- pids[k]; m <- MAN[MAN$pid==pid, , drop=FALSE][1, ]
  it <- INP[INP$pid==pid, , drop=FALSE]
  if (nrow(it)<5){ fail<-fail+1; next }
  .mm <- c(ME=as.numeric(Sys.getenv("MORT_MULT_ME","1")), NB=as.numeric(Sys.getenv("MORT_MULT_NB","1")),
           NS=as.numeric(Sys.getenv("MORT_MULT_NS","1")))[m$region]
  if (!is.finite(.mm)) .mm <- 1
  cur <- data.frame(year=0, plot=1L, tree=seq_len(nrow(it)), sp=mapsp(it$sp),
    dbh=it$dbh_cm, ht=NA_real_, hcb=NA_real_, cr=NA_real_, expf=it$expf_tph,
    form=NA_character_, risk=NA_character_, ddbh.mult=1, dht.mult=1, mort.mult=.mm,
    max.dbh=200, max.height=50, stringsAsFactors=FALSE)
  stand <<- make_stand(stand.id=pid, csi=m$csi, elev=m$elev, region="ME")
  ok <- TRUE
  for (yr in seq_len(m$remper)){
    nx <- tryCatch(AcadianGYOneStand(tree=cur, stand=stand, ops=ops), error=function(e) NULL)
    if (is.null(nx) || nrow(nx)==0){ ok<-FALSE; break }
    cur <- bf(nx)
  }
  if (!ok){ fail<-fail+1; next }
  pv <- plot_value(cur$sp, cur$dbh, cur$expf)
  out[[pid]] <- data.frame(config=TAG, region=m$region, pid=pid, pv)
}
res <- rbindlist(out)
fwrite(res, paste0("region_pred_", TAG, ".csv"))
cat(sprintf("done %s: %d plots (%d failed)\n", TAG, nrow(res), fail))

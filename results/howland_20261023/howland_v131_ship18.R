# Howland plots grown with FVS-ACD v13.1 ship18 (fvs-acd main b314b1c harness wiring) at CSI 10, 12, 14.
.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages({library(data.table); library(parallel)})
set.seed(20261023)
OUT <- "/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/v131_check"
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
Sys.setenv(B0NEW="-1.88365516930746", B1NEW="0.497878016309701", B2NEW="-0.0293425859449079")
source("~/hw_formrisk_split.R"); .SPLIT_QUIET <- TRUE
source("~/magplot/verify/p4e/model_b0b1b2.r")
cat("model sourced; AcadianGYOneStand exists:", exists("AcadianGYOneStand"), "\n")
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult")) if(c %in% names(x)) x[[c]][is.na(x[[c]])]<-1
  if("max.dbh" %in% names(x)) x$max.dbh[is.na(x$max.dbh)]<-200; if("max.height" %in% names(x)) x$max.height[is.na(x$max.height)]<-50; x}
ops <- make_ops(verbose=FALSE)
ops$use.ingrowth <- TRUE; ops$use.cap.dbh <- TRUE; ops$use.cap.ht <- TRUE
ops$use.hw.mod <- FALSE; ops$use.sbw.mod <- FALSE; ops$use.thin.mod <- FALSE; ops$use.vol <- FALSE
ops$use.sdimort <- TRUE; ops$sdimort.onset <- 0.30; ops$sdimort.break <- 0.62
ops$sdimort.beta.gentle <- 0.020; ops$sdimort.beta.steep <- 0.80; ops$sdimort.max <- 1.0
ops$sdimax.site.term <- FALSE; ops$use.mortcal <- FALSE
ops$use.ingrowth.release <- TRUE; ops$ingrowth.rd.center <- 0.58; ops$ingrowth.rd.k <- 8
if ("active_ecobucket" %in% names(ops)) ops$active_ecobucket <- "OTHER_ECO"
# ship18 lever
ops$sdimort.onset <- 0.55
ops$use.ddbh.standcon <- TRUE; ops$ddbh.standcon.lo <- 0.35; ops$ddbh.standcon.hi <- 0.45; ops$ddbh.standcon.qmin <- 18
ops$ingrowth.mult <- 2.5
HWL <- data.table::fread("/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/trees.tab")
spp <- c(PIRU="RS",TSCA="EH",ACRU="RM",THOC="WC",ABBA="BF",PIST="WP",BEPA="PB",BEPO="GB",BEAL="YB",POGR="BT",POTR="QA",FAGR="AB",UNK="OH")
JENK <- list(spruce=c(-2.0773,2.3323),fir_hem=c(-2.5384,2.4814),pine=c(-2.5356,2.4349),cedar=c(-2.0336,2.2592),
             aspen=c(-2.2094,2.3867),smb=c(-1.9123,2.3651),mixhw=c(-2.4800,2.4835),hmo=c(-2.0127,2.4342))
grp <- c(RS="spruce",BS="spruce",WS="spruce",EH="fir_hem",BF="fir_hem",WP="pine",WC="cedar",RM="smb",PB="smb",GB="smb",
         YB="smb",BT="aspen",QA="aspen",AB="hmo",SM="hmo",OH="mixhw")
jk <- function(sp,dbh){g<-grp[sp];g[is.na(g)]<-"mixhw";b<-do.call(rbind,JENK[g]);exp(b[,1]+b[,2]*log(dbh))}
HWL[, PLOT := sub("^([A-Z]+_[0-9]+).*", "\\1", Plot)]
HWL <- HWL[grepl("^HL", PLOT) & (is.na(Snag) | Snag == "") & DBH >= 10]
HWL <- HWL[, .SD[Year == max(Year)], by = PLOT]
mk <- function(d) { x <- data.frame(year=0, plot=1L, tree=seq_len(nrow(d)), sp=unname(spp[d$Species]), dbh=d$DBH,
  ht=NA_real_, hcb=NA_real_, cr=NA_real_, expf=10000/250, form=NA_character_, risk=NA_character_,
  ddbh.mult=1, dht.mult=1, mort.mult=1, max.dbh=200, max.height=50, stringsAsFactors=FALSE)
  x$sp[is.na(x$sp)] <- "OH"; split_formrisk(x) }
run1 <- function(pid, csi, ncyc=50) {
  cur <- mk(HWL[PLOT == pid]); out <- list()
  stand <<- tryCatch(make_stand(stand.id=paste0(pid,"_",csi), csi=csi, elev=60, region="ME"), error=function(e) NULL)
  if (is.null(stand)) return(NULL)
  for (i in 1:ncyc) {
    prev <- cur
    nx <- tryCatch(AcadianGYOneStand(tree=cur, stand=stand, ops=ops), error=function(e) {message(pid," ",conditionMessage(e)); NULL})
    if (is.null(nx) || nrow(nx) == 0) break
    cur <- bf(nx)
    m <- merge(prev[,c("tree","sp","dbh","expf")], cur[,c("tree","dbh","expf")], by="tree", suffixes=c("0","1"))
    live <- cur[is.finite(cur$dbh) & cur$dbh >= 10, ]
    out[[i]] <- data.table(PLOT=pid, CSI=csi, year=2025+i,
      agb_J = sum(jk(live$sp, live$dbh) * live$expf) / 1000,
      ba = sum(pi*(live$dbh/200)^2*live$expf), tph = sum(live$expf),
      gross = sum((jk(m$sp,m$dbh1) - jk(m$sp,m$dbh0)) * m$expf1) / 1000,
      mort  = sum(jk(m$sp,m$dbh1) * pmax(m$expf0 - m$expf1, 0)) / 1000,
      ingrowth_tph = sum(cur$expf[!cur$tree %in% prev$tree]))
  }
  rbindlist(out)
}
pids <- unique(HWL$PLOT)
a0 <- HWL[, .(agb0 = sum(jk(unname(spp[Species]), DBH) * 40) / 1000), by = PLOT]
res <- rbindlist(lapply(c(10,12,14), function(csi) rbindlist(mclapply(pids, run1, csi=csi, mc.cores=12))))
fwrite(res, file.path(OUT, "v131_ship18_trajectories.csv"))
cat("plots", length(pids), " initial AGB", round(mean(a0$agb0),1), "\n")
s8 <- res[year <= 2033, .(gross8=sum(gross), mort8=sum(mort), ing8=sum(ingrowth_tph)), by=.(CSI,PLOT)][
  , .(gross_8yr=mean(gross8), mortality_8yr=mean(mort8), ingrowth_tph_8yr=mean(ing8), n=.N), by=CSI]
lv <- res[year %in% c(2033,2075), .(agb=mean(agb_J), ba=mean(ba), tph=mean(tph), n=.N), by=.(CSI,year)]
dec <- res[year == 2075][a0, on="PLOT"][, .(n_decline_50yr = sum(agb_J < agb0, na.rm=TRUE)), by=CSI]
summ <- merge(merge(s8, dcast(lv, CSI ~ year, value.var=c("agb","ba","tph")), by="CSI"), dec, by="CSI")
print(summ); fwrite(summ, file.path(OUT, "v131_ship18_summary.csv"))

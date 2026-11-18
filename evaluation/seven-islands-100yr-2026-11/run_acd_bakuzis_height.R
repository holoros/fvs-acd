#!/usr/bin/env Rscript
# Research AcadianGY 100-year plot trajectories on firebreather.
suppressPackageStartupMessages({ library(data.table); library(dplyr); library(purrr) })
args <- commandArgs(trailingOnly=TRUE)
model <- if(length(args)>=1) args[[1]] else stop("model required")
head_n <- if(length(args)>=2) as.integer(args[[2]]) else 0L
shard_id <- if(length(args)>=3) as.integer(args[[3]]) else 1L
shard_n <- if(length(args)>=4) as.integer(args[[4]]) else 1L
base <- normalizePath(".")
HA <- 2.4710538147
BA_FACTOR <- 4.356
P <- fread(file.path(base,"plots.csv"), colClasses=list(character=c("Stand","Matrix","Unit")))
T <- fread(file.path(base,"trees.csv"))
sample_path <- file.path(base,"version_sample_plots.csv")
if(file.exists(sample_path) && head_n==0L)
  P <- P[PLOT_ID %in% fread(sample_path)$PLOT_ID]
setorder(P,Stand,PLOT_ID)
if(shard_n>1L) P <- P[((seq_len(nrow(P))-1L)%%shard_n)+1L==shard_id]
if(head_n>0) P <- P[seq_len(min(head_n,nrow(P)))]
model_file <- switch(model,
  "v12.11.1"="AcadianGY_12.11.1.r",
  "v13.1-base"="AcadianGY_13.1.r",
  "v14.0.4-L2"="AcadianGY_14.0.4.r",
  "v14.1-L2L"="AcadianGY_14.1.r",
  stop("unknown model"))
if(startsWith(model,"v14")) {
  Sys.setenv(ACD_V14_BASE=file.path(base,"AcadianGY_13.1.r"))
  source(file.path(base,"AcadianGY_14.0.4.r"))
  if(model=="v14.1-L2L") source(file.path(base,"AcadianGY_14.1.r"))
} else source(file.path(base,model_file))
sp_valid <- unique(as.character(sp.attr$species))
mapsp <- function(s) {
  s <- toupper(as.character(s))
  # Input CE and WB denote cedar and white birch. AcadianGY uses WC and PB.
  s[s == "CE"] <- "WC"
  s[s == "WB"] <- "PB"
  ifelse(s %in% sp_valid,s,ifelse(s %in% c("HE","NC"),"OS","OH"))
}
bf <- function(x) {
  for(col in c("ddbh.mult","dht.mult","mort.mult")) x[[col]][is.na(x[[col]])] <- 1
  x$max.dbh[is.na(x$max.dbh)] <- 200
  x$max.height[is.na(x$max.height)] <- 50
  x
}
ops <<- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5,
  ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,
  use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort <- TRUE
ops$sdimort.onset <- .30
ops$sdimort.break <- .62
ops$sdimort.beta.gentle <- .02
ops$sdimort.beta.steep <- .80
ops$sdimort.max <- 1
ops$sdimax.site.term <- FALSE
ops$use.mortcal <- FALSE
ops$use.ingrowth.release <- TRUE
ops$ingrowth.rd.center <- .58
ops$ingrowth.rd.k <- 8
ops$ingrowth.mult <- 1
ops$use.esi.domht <- FALSE
if(model=="v12.11.1") {
  # Historical v12.11 candidate levers; unmanaged is an explicit scenario.
  ops$use.ddbh.standcon <- TRUE
  ops$ddbh.standcon.lo <- .40
  ops$ddbh.standcon.hi <- .50
  ops$ddbh.standcon.qmin <- 22
  ops$mort.dens.scale <- TRUE
  ops$stand.managed <- FALSE
  ops$mort.dens.fmin <- .13
  ops$mort.dens.k <- 12.4
  ops$mort.dens.rd0 <- .38
  ops$use.dht.hw.mod <- TRUE
  ops$ingrowth.mult <- 2.5
}
if(model=="v13.1-base") {
  ops$use.hier.ingrowth <- FALSE
  ops$use.hier.mortality <- FALSE
}
if(startsWith(model,"v14")) {
  ops$use.linked.mortality <- TRUE
  ops$linked.mortality.mode <- "L2"
  ops$linked.coef.file <- file.path(base,"v14_coef_bundle_2026-09-08.rds")
  ops$linked.stage3.species.re <- TRUE
  ops$linked.fix.threshold <- TRUE
  ops$linked.fix.floordomain <- FALSE
  ops$linked.fix.pool <- TRUE
  ops$linked.fix.s3offset <- TRUE
  ops$linked.fix.stepinv <- TRUE
  ops$linked.threshold.dref <- 5
  ops$use.dba.v1404 <- TRUE
  ops$use.sdimort <- FALSE
  ops$stand.managed <- FALSE
  if(model=="v14.1-L2L") {
    ops$use.lsdg.v141 <- TRUE
    ops$use.thin.v141 <- FALSE
    ops$v141.coef.file <- file.path(base,"v141_option3_offline_coefs_r5_2026-09-23.rds")
    ops$stand.tst <- NA_real_
  }
}
metric <- function(cur,p,y) {
  d <- as.numeric(cur$dbh);e <- as.numeric(cur$expf)
  ok <- is.finite(d)&is.finite(e)&d>0&e>0
  d<-d[ok];e<-e[ok]
  ba <- sum(e*pi*(d/200)^2)
  tph <- sum(e)
  hh <- as.numeric(cur$ht)[ok]
  hk <- is.finite(hh)&hh>0
  top_height <- NA_real_
  if(any(hk)) {
    ord <- order(hh[hk],decreasing=TRUE)
    hs <- hh[hk][ord];ws <- e[hk][ord]
    wtop <- pmax(0,pmin(ws,50-c(0,head(cumsum(ws),-1))))
    if(sum(wtop)>0) top_height <- sum(hs*wtop)/sum(wtop)
  }
  data.table(plot_id=as.integer(p$PLOT_ID),stand_id=as.character(p$Stand),
    model=paste0("ACD-",model),year_offset=y,calendar_year=as.integer(p$INV_YEAR)+y,
    ba_ft2ac=ba*BA_FACTOR,tpa=tph/HA,
    qmd_in=if(tph>0) sqrt(sum(e*d*d)/tph)/2.54 else NA_real_,
    HT=top_height,VOL=ba*top_height*.40)
}
out <- vector("list", nrow(P)); errs <- vector("list",nrow(P))
for(i in seq_len(nrow(P))) {
  p<-P[i]; tt<-T[PLOT_ID==p$PLOT_ID & is.finite(DIAMETER) & DIAMETER*2.54>=1]
  if(!nrow(tt)) {
    errs[[i]]<-data.table(plot_id=p$PLOT_ID,model=paste0("ACD-",model),reason="no live input trees")
    next
  }
  cur<-data.frame(year=0,plot=1L,tree=seq_len(nrow(tt)),sp=mapsp(tt$SPECIES),
    dbh=tt$DIAMETER*2.54,ht=ifelse(is.finite(tt$HT)&tt$HT>0,tt$HT*.3048,NA_real_),
    hcb=NA_real_,cr=NA_real_,expf=tt$TREE_COUNT*
      ifelse(tt$DIAMETER>=4.6,20/(pi*(tt$DIAMETER/24)^2),500)*HA,
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,
    max.dbh=200,max.height=50,stringsAsFactors=FALSE)
  stand <<- make_stand(stand.id=as.character(p$Stand),csi=as.numeric(p$ClimateSiteIndexMeters),
    elev=as.numeric(p$ElevationMeters),region="ME")
  z <- vector("list",21);z[[1]]<-metric(cur,p,0)
  err <- tryCatch({
    for(y in seq_len(100)) {
      nx<-AcadianGYOneStand(tree=cur,stand=stand,ops=ops)
      if(is.null(nx)||!nrow(nx)) stop("empty model result")
      cur<-bf(nx)
      if(y%%5==0)z[[y/5+1]]<-metric(cur,p,y)
    }
    NULL
  },error=function(e)conditionMessage(e))
  if(is.null(err)) out[[i]]<-rbindlist(z)
  else errs[[i]]<-data.table(plot_id=p$PLOT_ID,model=paste0("ACD-",model),reason=substr(err,1,220))
  if(i%%10==0)cat(model,i,"/",nrow(P),"\n",file=stderr())
}
od<-file.path(base,"results");dir.create(od,showWarnings=FALSE)
slug<-gsub("[.-]","_",model)
if(shard_n>1L) slug<-paste0(slug,"_part",sprintf("%02d",shard_id))
fwrite(rbindlist(out,fill=TRUE),file.path(od,paste0("bakuzis_acd_",slug,".csv")))
fwrite(rbindlist(errs,fill=TRUE),file.path(od,paste0("bakuzis_acd_",slug,"_errors.csv")))
cat(model,"complete",sum(vapply(out,function(x)!is.null(x),logical(1))),"errors",sum(vapply(errs,function(x)!is.null(x),logical(1))),"\n")

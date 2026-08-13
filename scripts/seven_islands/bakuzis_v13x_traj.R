# bakuzis_v13x_traj.R
# Reusable, parameterized Bakuzis (Leary 1997) long-horizon trajectory + relations harness for
# the v13.x FVS-ACD candidate family. Consolidates three scripts that were previously
# hand-duplicated per model (g2_bakuzis_v1211_traj.R, g2_bakuzis_v131_traj.R,
# p9lev3/bakuzis_ship18.R) into one script selected by MODEL_TAG so a fourth candidate never
# needs this reconstructed from scratch again. Trajectory/scoring logic is byte-identical to
# those three scripts (same age-160 x ESI 12/16/20 gradient, same seed, same relation tests);
# only the per-model ops wiring is now a lookup keyed on MODEL_TAG instead of copy-pasted files.
#
# Usage:
#   MODEL_TAG=v1211_full     Rscript bakuzis_v13x_traj.R   # v12.11, hand-lever candidate
#   MODEL_TAG=v131_full      Rscript bakuzis_v13x_traj.R   # v13.1, hierarchical posterior candidate
#   MODEL_TAG=v131_ship18    Rscript bakuzis_v13x_traj.R   # v13.1, ship18 lever stack (3 stand types)
#
# Env overrides:
#   HIER_POSTDIR   posterior directory for v131_full only (default ~/v13_comb_post; v13_subplot
#                  is missing v131r_ingrowth_norm.csv and silently inflates ingrowth ~97%, see
#                  hier_norm_guard_patch.R -- do not point this back at v13_subplot).
#   OUT_PREFIX     override the output file stem (default bakuzis_<MODEL_TAG>_v25)
#   OUT_DIR        output directory (default ~/silc_cfi)
#
# Outputs (compatible, unmodified, with bakuzis_check.R and bakuzis_matrix.R -- both scripts take
# a trajectories CSV as arg 1, and here "origin" is written as an alias of "model" so no adapter
# is needed):
#   <OUT_DIR>/<OUT_PREFIX>_traj.csv
#   <OUT_DIR>/<OUT_PREFIX>_relations.csv

.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

MODEL_TAG <- Sys.getenv("MODEL_TAG", "")
if (!MODEL_TAG %in% c("v1211_full","v131_full","v131_ship18"))
  stop("set MODEL_TAG to one of v1211_full | v131_full | v131_ship18")

OUT_DIR    <- Sys.getenv("OUT_DIR", "/users/PUOM0008/crsfaaron/silc_cfi")
OUT_PREFIX <- Sys.getenv("OUT_PREFIX", sprintf("bakuzis_%s_v25", MODEL_TAG))

bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult")) if(c %in% names(x)) x[[c]][is.na(x[[c]])]<-1
  if("max.dbh" %in% names(x)) x$max.dbh[is.na(x$max.dbh)]<-200; if("max.height" %in% names(x)) x$max.height[is.na(x$max.height)]<-50; x}

init <- function(spvec, seed){ set.seed(seed); n<-40
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(spvec,each=n/length(spvec)),
    dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=rep(3000/n,n),
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }

sdi_of <- function(d){ live<-d[d$dbh>=4 & is.finite(d$dbh),]; sum((live$dbh/25.4)^1.6*live$expf) }

base_ops <- function(){
  o <- make_ops(verbose=FALSE)
  o$verbose <- FALSE
  o$use.ingrowth <- TRUE; o$use.cap.dbh <- TRUE; o$use.cap.ht <- TRUE
  o$use.hw.mod <- FALSE; o$use.sbw.mod <- FALSE; o$use.thin.mod <- FALSE; o$use.vol <- FALSE
  o$use.sdimort <- TRUE
  o$sdimort.onset <- 0.30; o$sdimort.break <- 0.62
  o$sdimort.beta.gentle <- 0.020; o$sdimort.beta.steep <- 0.80; o$sdimort.max <- 1.0
  o$sdimax.site.term <- FALSE; o$use.mortcal <- FALSE
  o$use.ingrowth.release <- TRUE; o$ingrowth.rd.center <- 0.58; o$ingrowth.rd.k <- 8
  o$ingrowth.mult <- 1.0
  if ("active_ecobucket" %in% names(o)) o$active_ecobucket <- "OTHER_ECO"
  o
}

## ---- per-MODEL_TAG wiring (this block is the only thing that differs between candidates) -----
if (MODEL_TAG == "v1211_full") {
  MODEL_FILE <- Sys.getenv("MODEL_FILE", "~/_scripts/AcadianGY_12.11.r")
  cat(sprintf("MODEL_FILE=%s\n", MODEL_FILE)); source(MODEL_FILE)
  source("~/hw_formrisk_split.R")
  # v1211 has no hierarchical postdir; guard patch not applicable.
  candidate_lever <- function(o, managed){
    o$use.ddbh.standcon <- TRUE; o$ddbh.standcon.lo <- 0.40; o$ddbh.standcon.hi <- 0.50; o$ddbh.standcon.qmin <- 22
    o$use.dht.hw.mod <- TRUE
    o$mort.dens.scale <- TRUE; o$stand.managed <- isTRUE(managed)
    o$mort.dens.fmin <- 0.13; o$mort.dens.k <- 12.4; o$mort.dens.rd0 <- 0.38
    o$ingrowth.mult <- 2.5
    o
  }
  CONFIGS <- list(
    base                = list(split=FALSE, lever=function(o) o),
    candidate_unmanaged = list(split=TRUE,  lever=function(o) candidate_lever(o, FALSE)),
    candidate_managed   = list(split=TRUE,  lever=function(o) candidate_lever(o, TRUE))
  )
  STAND_SETS <- list(default = c("BF","RS","BS","WS"))

} else if (MODEL_TAG == "v131_full") {
  MODEL_FILE <- Sys.getenv("MODEL_FILE", "~/AcadianGY_13.1.r")
  cat(sprintf("MODEL_FILE=%s\n", MODEL_FILE)); source(MODEL_FILE)
  source("~/hw_formrisk_split.R")
  if (exists(".acd_hier_load", envir=.GlobalEnv)) source("~/magplot/verify/p9sweep/hier_norm_guard_patch.R")  # pass 11 Track E fix: loud fail on missing normalizer
  candidate_lever <- function(o, managed){
    o$use.hier.ingrowth  <- TRUE
    o$use.hier.mortality <- TRUE
    o$hier.postdir       <- Sys.getenv("HIER_POSTDIR", "~/v13_comb_post")  # pass 11: v13_subplot lacked a normalizer, redirected per Aaron 2026-08-13
    o$stand.managed      <- isTRUE(managed)
    o
  }
  CONFIGS <- list(
    base                = list(split=FALSE, lever=function(o) o),
    candidate_unmanaged = list(split=TRUE,  lever=function(o) candidate_lever(o, FALSE)),
    candidate_managed   = list(split=TRUE,  lever=function(o) candidate_lever(o, TRUE))
  )
  STAND_SETS <- list(default = c("BF","RS","BS","WS"))

} else if (MODEL_TAG == "v131_ship18") {
  BASE_FILE <- Sys.getenv("BASE_FILE", "~/_scripts/AcadianGY_12.10.1.r")
  CAND_FILE <- Sys.getenv("CAND_FILE", "~/magplot/verify/p4e/model_b0b1b2.r")  # sources AcadianGY_13.1.r, patches ddbh() via B0NEW/B1NEW/B2NEW
  Sys.setenv(B0NEW="-1.88365516930746", B1NEW="0.497878016309701", B2NEW="-0.0293425859449079")
  source("~/hw_formrisk_split.R")
  .SPLIT_QUIET <- TRUE
  ship18_lever <- function(o){
    o$sdimort.onset <- 0.55
    o$use.ddbh.standcon <- TRUE; o$ddbh.standcon.lo <- 0.35; o$ddbh.standcon.hi <- 0.45; o$ddbh.standcon.qmin <- 18
    o$ingrowth.mult <- 2.5
    o
  }
  # ship18 never sets use.hier.ingrowth/mortality, so it is unaffected by the postdir defect;
  # included here for the complete three-way harness, not because it needed the fix.
  CONFIGS <- list(
    base   = list(file=BASE_FILE, split=FALSE, lever=function(o) o),
    ship18 = list(file=CAND_FILE, split=TRUE,  lever=ship18_lever)
  )
  STAND_SETS <- list(SW=c("BF","RS","BS","WS"), MW=c("BF","RS","RM","SM"), HW=c("RM","SM","YB","PB"))
}

## ---- shared trajectory loop (identical machinery for all three MODEL_TAGs) --------------------
alltraj <- list()
for (cfg in names(CONFIGS)) {
  C <- CONFIGS[[cfg]]
  if (MODEL_TAG == "v131_ship18") { cat(sprintf("[%s] sourcing %s\n", cfg, C$file)); source(C$file) }
  ops <<- base_ops(); ops <<- C$lever(ops)
  cat(sprintf("[%s] use.hier.ingrowth=%s use.hier.mortality=%s hier.postdir=%s stand.managed=%s SPLIT=%s\n",
    cfg, isTRUE(ops$use.hier.ingrowth), isTRUE(ops$use.hier.mortality),
    ifelse(is.null(ops$hier.postdir),"<unset>",ops$hier.postdir), isTRUE(ops$stand.managed), isTRUE(C$split)))
  for (standtype in names(STAND_SETS)) {
    for (esi in c(12,16,20)) {
      cur <- init(STAND_SETS[[standtype]], seed=101)
      if (isTRUE(C$split)) cur <- split_formrisk(cur)
      stand <<- tryCatch(make_stand(stand.id=paste0(cfg,"_",standtype,"_E",esi), csi=esi, elev=200, region="ME"), error=function(e) NULL)
      if (is.null(stand)) next
      for (age in 1:160) {
        nx <- tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops), error=function(e) NULL)
        if (is.null(nx) || nrow(nx)==0) break
        cur <- bf(nx); live <- cur[cur$dbh>=4 & is.finite(cur$dbh),]; if (nrow(live)<1) break
        ba<-sum(pi*(live$dbh/200)^2*live$expf); tph<-sum(live$expf); qmd<-sqrt((ba/tph)/(pi/40000))
        htd<-{o<-order(-live$dbh); cw<-cumsum(live$expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1; mean(live$ht[o][idx],na.rm=TRUE)}
        sdi<-sdi_of(live); vol<-0.45*ba*htd
        alltraj[[length(alltraj)+1]] <- data.table(model=cfg, standtype=standtype, site=esi, age=age,
          HT=htd, TPH=tph, BAPH=ba, QMD=qmd, SDI=sdi, VOL=vol)
      }
    }
    cat(sprintf("traj done: %s / %s\n", cfg, standtype))
  }
}
TR <- rbindlist(alltraj); TR <- TR[is.finite(HT) & is.finite(BAPH)]
TR[, origin := model]   # compatibility alias: bakuzis_check.R / bakuzis_matrix.R key off "origin"
traj_path <- file.path(OUT_DIR, paste0(OUT_PREFIX, "_traj.csv"))
fwrite(TR, traj_path)

## ---- shared relations scoring (identical test logic to the three predecessor scripts) ---------
rel <- list()
for (mod in unique(TR$model)) {
  s <- TR[model==mod]
  s[, htbin := round(HT/2)*2]
  ei  <- s[, .(v=mean(VOL), n=length(unique(site))), by=htbin][n>=2]
  cvv <- s[htbin %in% ei$htbin, .(cv=sd(VOL)/mean(VOL)), by=htbin]
  eich_cv <- 100*mean(cvv$cv, na.rm=TRUE)
  eich <- ifelse(eich_cv<15, "PASS", "FLAG")
  reslope <- NA_real_
  st  <- s[site==16][order(age)]; st[, dTPH := c(NA, diff(TPH))]
  mat <- st[is.finite(dTPH) & dTPH < -1 & QMD>10]
  if (nrow(mat)>=5) reslope <- coef(lm(log(TPH)~log(QMD), data=mat))[2]
  reineke <- ifelse(is.finite(reslope) && reslope>=-1.8 && reslope<=-1.4, "PASS", "FLAG")
  w <- dcast(s, age~site, value.var=c("HT","VOL"))
  inv_ht  <- sum((w$HT_20<w$HT_16)|(w$HT_16<w$HT_12), na.rm=TRUE)
  inv_vol <- sum((w$VOL_20<w$VOL_16)|(w$VOL_16<w$VOL_12), na.rm=TRUE)
  siteord <- ifelse(inv_ht==0 & inv_vol==0, "PASS", "FLAG")
  bamax <- max(st$BAPH); ba160 <- st$BAPH[st$age==max(st$age)]; sdlast <- sd(tail(st$BAPH,20))
  plateau <- ifelse(bamax<=42 & sdlast<2.0, "PASS", "FLAG")
  suk <- NA_real_; if (nrow(mat)>=5) suk <- coef(lm(QMD~TPH, data=mat))[2]
  sukachev <- ifelse(is.finite(suk) && suk<0, "PASS", "FLAG")
  rel[[length(rel)+1]] <- data.table(model=mod, Eichhorn=eich, eich_cv=round(eich_cv,1),
    Reineke=reineke, reineke_slope=round(reslope,2), SiteOrdering=siteord, inv_ht=inv_ht, inv_vol=inv_vol,
    YieldDensity_plateau=plateau, BAmax=round(bamax,1), BA160=round(ba160,1), Sukachev=sukachev)
}
RB <- rbindlist(rel)
rel_path <- file.path(OUT_DIR, paste0(OUT_PREFIX, "_relations.csv"))
fwrite(RB, rel_path)
cat(sprintf("\n=== BAKUZIS RELATIONS: %s ===\n", MODEL_TAG)); print(RB)
cat(sprintf("wrote %s\nwrote %s\n", traj_path, rel_path))
cat("DONE_BAKUZIS_V13X\n")

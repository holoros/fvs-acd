# g2_bakuzis_v131_traj.R
# Guardrail 2 (Bakuzis five relations, Leary 1997) for the locked FVS-ACD v12.11 candidate
# lever configuration vs its BASE (levers off) counterpart. NEW script -- does not edit any
# frozen/canonical harness file. Adapts the trajectory/scoring machinery of
# ~/magplot/verify/bakuzis_allmodels.R (unedited, used only as a reference for methodology) to
# the v12.11 gated-lever ops wiring documented in ~/magplot/verify/bench_parity_split_ms_v1211.R
# (unedited, used only as a reference for which ops$ fields the V1211_* env levers touch).
#
# Three configs are run across the same synthetic ESI(csi) site gradient x 160-year horizon used
# to build bakuzis_traj_allmodels.csv:
#   base                 - MODEL_FILE=AcadianGY_12.11.r, all V1211_* levers OFF, SPLIT=FALSE.
#                          Reproduces frozen 12.10.1/12.10.2 on the core engine (already confirmed
#                          byte-identical elsewhere; this run re-derives long-horizon trajectories
#                          under the exact same base ops so base and candidate are scored on
#                          identical machinery).
#   candidate_unmanaged  - CANDIDATE levers (IGMULT=2.5, MORTGATE+STANDCON+DHTHW, SPLIT=TRUE),
#                          V1211_MANAGED=FALSE. Primary candidate result: the synthetic gradient
#                          here is an unthinned, continuously-grown stand (no management events
#                          are applied in this trajectory loop), which maps onto the "unmanaged /
#                          developing" source class (baxter, me_fia, pef) in the candidate spec.
#   candidate_managed    - identical candidate levers with V1211_MANAGED=TRUE, run as a robustness
#                          check against the "managed" source class (ctrn, nb, silc_l), since
#                          ops$mort.dens.scale response is management-gated.
#
# Frozen-canon core sdimort/ingrowth parameters (ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58
# IRK=8 SDMAX=1.0) are hardcoded in base_ops() below to reproduce operational baseline behavior.
# USE_BRMS/USE_ANCHOR/NB_AFAC/QC_AFAC/NB_BREAK/QC_BREAK/INDOMAIN from the frozen-canon block are
# NOT wired here: grep of AcadianGY_12.11.r confirms it has no brms.sdimax / esi.anchor.recal
# machinery at all (that was v12.9.x-lineage-only), and NB/QC-region-specific terms are inert for
# this synthetic single-region (ME) site gradient, matching how bakuzis_allmodels.R itself never
# wired them for v1271/v129x either.

.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

MODEL_FILE <- Sys.getenv("MODEL_FILE", "~/AcadianGY_13.1.r")
cat(sprintf("MODEL_FILE=%s\n", MODEL_FILE))
source(MODEL_FILE)
source("~/hw_formrisk_split.R")
if (exists(".acd_hier_load", envir=.GlobalEnv)) source("~/magplot/verify/p9sweep/hier_norm_guard_patch.R")  # pass 11 Track E fix: loud fail on missing normalizer

bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult")) if(c %in% names(x)) x[[c]][is.na(x[[c]])]<-1
  if("max.dbh" %in% names(x)) x$max.dbh[is.na(x$max.dbh)]<-200; if("max.height" %in% names(x)) x$max.height[is.na(x$max.height)]<-50; x}
init <- function(seed){ set.seed(seed); n<-40
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(c("BF","RS","BS","WS"),each=n/4),
    dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=rep(3000/n,n),
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }

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

candidate_lever <- function(o, managed){
  # v13.1 posterior-enable switches replace the v12.11 hand levers. The fitted hierarchical
  # recruitment and the MULTIPLICATIVE mortality hazard modifier are applied by the model file when
  # these switches are TRUE; managed vs unmanaged is resolved inside the posterior surface
  # (region/eco/fortype ranef refinement over the population-level fixef), so no hand mortality
  # gate, no hand diameter-form / hardwood-height / ingrowth-mult lever is set here.
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

sdi_of <- function(d){ live<-d[d$dbh>=4 & is.finite(d$dbh),]; sum((live$dbh/25.4)^1.6*live$expf) }

alltraj <- list()
for(cfg in names(CONFIGS)){
  C <- CONFIGS[[cfg]]
  ops <<- base_ops(); ops <<- C$lever(ops)
  cat(sprintf("[%s] use.hier.ingrowth=%s use.hier.mortality=%s hier.postdir=%s stand.managed=%s SPLIT=%s\n",
    cfg, isTRUE(ops$use.hier.ingrowth), isTRUE(ops$use.hier.mortality),
    ifelse(is.null(ops$hier.postdir),"<unset>",ops$hier.postdir), isTRUE(ops$stand.managed), isTRUE(C$split)))
  for(esi in c(12,16,20)){
    cur <- init(101)
    if (isTRUE(C$split)) cur <- split_formrisk(cur)
    stand <<- tryCatch(make_stand(stand.id=paste0(cfg,"_E",esi), csi=esi, elev=200, region="ME"), error=function(e) NULL)
    if(is.null(stand)) next
    for(age in 1:160){
      nx <- tryCatch(AcadianGYOneStand(tree=cur,stand=stand,ops=ops), error=function(e) NULL)
      if(is.null(nx)||nrow(nx)==0) break
      cur <- bf(nx); live <- cur[cur$dbh>=4 & is.finite(cur$dbh),]; if(nrow(live)<1) break
      ba<-sum(pi*(live$dbh/200)^2*live$expf); tph<-sum(live$expf); qmd<-sqrt((ba/tph)/(pi/40000))
      htd<-{o<-order(-live$dbh); cw<-cumsum(live$expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1; mean(live$ht[o][idx],na.rm=TRUE)}
      sdi<-sdi_of(live); vol<-0.45*ba*htd
      alltraj[[length(alltraj)+1]]<-data.table(model=cfg,site=esi,age=age,HT=htd,TPH=tph,BAPH=ba,QMD=qmd,SDI=sdi,VOL=vol)
    }
  }
  cat(sprintf("traj done: %s\n", cfg))
}
TR<-rbindlist(alltraj); TR<-TR[is.finite(HT)&is.finite(BAPH)]
fwrite(TR,"g2_bakuzis_v131_traj.csv")

# --- Bakuzis relations per config (identical objective test logic to bakuzis_allmodels.R) ---
rel<-list()
for(mod in unique(TR$model)){
  s<-TR[model==mod]
  s[,htbin:=round(HT/2)*2]
  ei<-s[,.(v=mean(VOL),n=length(unique(site))),by=htbin][n>=2]
  cvv<-s[htbin %in% ei$htbin, .(cv=sd(VOL)/mean(VOL)), by=htbin]
  eich_cv<-100*mean(cvv$cv,na.rm=TRUE)
  eich<-ifelse(eich_cv<15,"PASS","FLAG")
  reslope<-NA_real_
  st<-s[site==16][order(age)]; st[,dTPH:=c(NA,diff(TPH))]
  mat<-st[is.finite(dTPH) & dTPH< -1 & QMD>10]
  if(nrow(mat)>=5) reslope<-coef(lm(log(TPH)~log(QMD),data=mat))[2]
  reineke<-ifelse(is.finite(reslope) && reslope>=-1.8 && reslope<=-1.4,"PASS","FLAG")
  w<-dcast(s,age~site,value.var=c("HT","VOL"))
  inv_ht<-sum((w$HT_20<w$HT_16)|(w$HT_16<w$HT_12),na.rm=TRUE)
  inv_vol<-sum((w$VOL_20<w$VOL_16)|(w$VOL_16<w$VOL_12),na.rm=TRUE)
  siteord<-ifelse(inv_ht==0 & inv_vol==0,"PASS","FLAG")
  bamax<-max(st$BAPH); ba160<-st$BAPH[st$age==max(st$age)]; sdlast<-sd(tail(st$BAPH,20))
  plateau<-ifelse(bamax<=42 & sdlast<2.0,"PASS","FLAG")
  suk<-NA_real_; if(nrow(mat)>=5) suk<-coef(lm(QMD~TPH,data=mat))[2]
  sukachev<-ifelse(is.finite(suk) && suk<0,"PASS","FLAG")
  rel[[length(rel)+1]]<-data.table(model=mod, Eichhorn=eich, eich_cv=round(eich_cv,1),
    Reineke=reineke, reineke_slope=round(reslope,2), SiteOrdering=siteord, inv_ht=inv_ht, inv_vol=inv_vol,
    YieldDensity_plateau=plateau, BAmax=round(bamax,1), BA160=round(ba160,1), Sukachev=sukachev)
}
RB<-rbindlist(rel); fwrite(RB,"g2_bakuzis_v131_relations.csv")
cat("\n=== BAKUZIS RELATIONS: v12.11 CANDIDATE vs BASE (guardrail 2) ===\n"); print(RB)
cat("DONE_G2_BAKUZIS\n")

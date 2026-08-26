# bakuzis_h1default_traj.R
# Long-horizon Bakuzis trajectory builder for FVS-ACD under h1_v132_mortgate (density-dependent
# mortality scaling, gated on the managed flag), the config Aaron adopted as the new production
# default across all 11 benchmarked sources on 25 August 2026 (commit 10ea8418, pass 31).
#
# This script does NOT reimplement AcadianGYOneStand, the growth/mortality/ingrowth engine, or the
# NSVB volume emulator. It reuses, verbatim, the exact preamble blocks (model sourcing, v13.2
# site-fsm overlay, ops lever assembly, metrics()/nsvb() functions) from the production scoring
# harness scripts/gydb/merge_v24/2026-08-21_merge-v24-runner.R and the h1default sbatch env-var
# recipe (2026-08-25_p21ship_h1default.sbatch and its bax_mef companion). The only new logic here
# is (a) a per-source config table pointing at each source's real t1 data, (b) selection of real
# t1 stands spanning that source's observed site-index range, and (c) chaining AcadianGYOneStand
# annually over a long horizon instead of one short remeasurement interval -- the same one-year-
# per-call pattern the production harness already uses inside its `for (yr in seq_len(iv))` loop,
# and the same pattern bakuzis_v13x_traj.R already uses out to age 160 for synthetic stands. No
# multi-cycle "project N years in one call" argument exists on AcadianGYOneStand or in
# AcadianGY_13.1.r; chaining single annual steps, feeding each year's output tree list back in as
# the next year's input, is the model's native and only mechanism for multi-year projection.
#
# Usage: SRC=<one of the 11 source tokens below> Rscript bakuzis_h1default_traj.R
# Output: <OUT_DIR>/<SRC>_h1default_traj.csv (long format: origin, site, age, HT, TPH, BAPH, QMD, VOL)
#         plus a stand-selection log <OUT_DIR>/<SRC>_h1default_standlog.csv

.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

SRC       <- Sys.getenv("SRC", "")
HORIZON   <- as.integer(Sys.getenv("HORIZON", "100"))
OUT_DIR   <- Sys.getenv("OUT_DIR", "/users/PUOM0008/crsfaaron/magplot/verify/bakuzis_h1")
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)
if (!nzchar(SRC)) stop("set SRC")

VALID_SRC <- c("baxter","mefia_l","memat","medev","pef","ctrn","silc_l","nb","qc","ns","ns_long")
if (!SRC %in% VALID_SRC) stop(sprintf("SRC must be one of: %s", paste(VALID_SRC, collapse=", ")))

## ---- per-source config table, read directly from the two h1default sbatch scripts, not guessed
## MODEL_FILE: the 10-task main array (memat,medev,pef,ctrn,silc_l,nb/qc,ns_managed,ns_unmanaged,
## ns_long_managed,ns_long_unmanaged) sets MODEL_FILE to the ship18 ddbh refit (p4e/model_b0b1b2.r,
## B0NEW/B1NEW/B2NEW patched); the 2-task bax_mef array leaves MODEL_FILE at its default, plain
## AcadianGY_13.1.r. MANAGED is the fixed V1211_MANAGED value each task exports, verbatim.
MS  <- "multisrc"; P5M <- "p5m"
SHIP18_MODEL <- "p4e/model_b0b1b2.r"
B0NEW <- "-1.88365516930746"; B1NEW <- "0.497878016309701"; B2NEW <- "-0.0293425859449079"

cfg <- switch(SRC,
  memat    = list(model = SHIP18_MODEL, managed = FALSE, pairs = file.path(P5M,"p5m_memat_pairs.csv"),
                   init = file.path(P5M,"p5m_memat_tree_init.csv"), site = file.path(P5M,"p5m_memat_site_esi.csv"),
                   indomain = TRUE, prov_filter = NULL),
  medev    = list(model = SHIP18_MODEL, managed = FALSE, pairs = file.path(P5M,"p5m_medev_pairs.csv"),
                   init = file.path(P5M,"p5m_medev_tree_init.csv"), site = file.path(P5M,"p5m_medev_site_esi.csv"),
                   indomain = TRUE, prov_filter = NULL),
  pef      = list(model = SHIP18_MODEL, managed = FALSE, pairs = file.path(MS,"bench_pef_pairs.csv"),
                   init = file.path(MS,"bench_pef_tree_init.csv"), site = file.path(MS,"bench_pef_site_esi.csv"),
                   indomain = TRUE, prov_filter = NULL),
  ctrn     = list(model = SHIP18_MODEL, managed = TRUE,  pairs = file.path(MS,"bench_ctrn_pairs.csv"),
                   init = file.path(MS,"bench_ctrn_tree_init.csv"), site = file.path(MS,"bench_ctrn_site_esi.csv"),
                   indomain = TRUE, prov_filter = NULL),
  silc_l   = list(model = SHIP18_MODEL, managed = TRUE,  pairs = file.path(MS,"bench_silc_l_pairs.csv"),
                   init = file.path(MS,"bench_silc_l_tree_init.csv"), site = file.path(MS,"bench_silc_l_site_esi.csv"),
                   indomain = TRUE, prov_filter = NULL),
  baxter   = list(model = "default", managed = FALSE, pairs = file.path(MS,"bench_baxter_pairs.csv"),
                   init = file.path(MS,"bench_baxter_tree_init.csv"), site = file.path(MS,"bench_baxter_site_esi.csv"),
                   indomain = TRUE, prov_filter = NULL),
  mefia_l  = list(model = "default", managed = FALSE, pairs = file.path(MS,"bench_mefia_long_pairs.csv"),
                   init = file.path(MS,"bench_mefia_long_tree_init.csv"), site = file.path(MS,"bench_mefia_long_site_esi.csv"),
                   indomain = TRUE, prov_filter = NULL),
  nb       = list(model = SHIP18_MODEL, managed = TRUE,  pairs = "magp_qcnb_pairs.csv",
                   init = "magp_qcnb_tree_init.csv", site = "magp_qcnb_site_esi8.csv",
                   indomain = TRUE, prov_filter = "NB"),
  qc       = list(model = SHIP18_MODEL, managed = TRUE,  pairs = "magp_qcnb_pairs.csv",
                   init = "magp_qcnb_tree_init.csv", site = "magp_qcnb_site_esi8.csv",
                   indomain = TRUE, prov_filter = "QC"),
  ns       = list(model = SHIP18_MODEL, managed = NA, pairs = c(file.path(MS,"bench_ns_pairs_managed.csv"), file.path(MS,"bench_ns_pairs_unmanaged.csv")),
                   init = file.path(MS,"bench_ns_tree_init.csv"), site = file.path(MS,"bench_ns_site_esi.csv"),
                   indomain = FALSE, prov_filter = NULL),
  ns_long  = list(model = SHIP18_MODEL, managed = NA, pairs = c(file.path(MS,"bench_ns_long_pairs_managed_singleregime.csv"), file.path(MS,"bench_ns_long_pairs_unmanaged.csv")),
                   init = file.path(MS,"bench_ns_long_tree_init.csv"), site = file.path(MS,"bench_ns_long_site_esi.csv"),
                   indomain = FALSE, prov_filter = NULL)
)

## ---- 1. source the model exactly as the h1default sbatch does for this source ------------------
MODEL_FILE <- if (identical(cfg$model,"default")) "~/AcadianGY_13.1.r" else file.path("~/magplot/verify", cfg$model)
if (identical(cfg$model, SHIP18_MODEL)) { Sys.setenv(B0NEW=B0NEW, B1NEW=B1NEW, B2NEW=B2NEW) }
cat(sprintf("[%s] MODEL_FILE=%s\n", SRC, MODEL_FILE))
source(MODEL_FILE); source("~/hw_sawfrac_smith.R"); source("~/hw_formrisk_split.R")
SPLIT <- TRUE

## ---- 2. v13.2 site-fsm overlay (V132=1 in both h1default sbatch scripts) -----------------------
source("~/magplot/verify/p20_v132/2026-08-19_v132_sitefsm_overlay_WIP.R")
source(MODEL_FILE)
activate_v132()
cat(sprintf("[%s] v13.2 site-fsm overlay active on top of %s\n", SRC, MODEL_FILE))

ecobucket_lookup <- fread("v129_gate3_dedup.csv"); ecobucket_lookup[, STAND := as.character(STAND)]
bmapdt <- fread("v129x_brms_sdimax_map.csv"); BV <- setNames(bmapdt$sdimax_brms, as.character(bmapdt$STAND))

## ---- 3. NSVB metrics()/nsvb() -- copied verbatim from merge-v24-runner.R -----------------------
CSI_DEFAULT <- 14
co <- fread("nsvb_emulator_coefs.csv"); sp2g <- fread("spcd_spgrpcd.csv")
AGY2SPCD <- c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,JP=105,EH=261,WC=241,TA=71,
 RM=316,SM=318,YB=371,PB=375,GB=379,QA=746,BT=743,BP=741,EC=742,AB=531,WA=541,BA=543,GA=544,
 RO=833,RN=833,BC=762,PR=761,ST=315,HH=701,SB=935,RB=370,AS=541,SW=298,HW=998,OH=998,OS=298,PC=68)
sw <- c("WP","RP","PP","JP","RN","RS","BF","BS","WS","NS","EH","WC","TA","HM","CE","SPR","OS","PC")
himp <- function(sp,d) ifelse(sp %in% sw, 1.3+27*(1-exp(-0.030*d)), 1.3+25*(1-exp(-0.028*d)))
agy_codes <- names(AGY2SPCD)
spcd2grp <- setNames(sp2g$SPGRPCD, as.character(sp2g$SPCD))
agy_grp <- sapply(AGY2SPCD, function(s){ g<-spcd2grp[as.character(s)]; if(is.na(g)) 998L else as.integer(g) })
ci <- match(agy_grp, co$SPGRPCD); ci[is.na(ci)] <- match(998, co$SPGRPCD); ci[is.na(ci)] <- 1
RESP <- c("VOLCFGRS","VOLCFNET","VOLCSNET","DRYBIO_AG"); CF <- list()
for (r in RESP) CF[[r]] <- list(a=setNames(co[[paste0(r,"_a")]][ci],agy_codes),
  b=setNames(co[[paste0(r,"_b")]][ci],agy_codes), sm=setNames(co[[paste0(r,"_sm")]][ci],agy_codes))
nsvb <- function(agy,dbh_cm,ht_m,resp){
  ht <- ifelse(is.finite(ht_m)&ht_m>0,ht_m,himp(agy,dbh_cm))
  lX <- log((dbh_cm/2.54)^2*(ht/0.3048))
  a <- CF[[resp]]$a[agy]; b <- CF[[resp]]$b[agy]; sm <- CF[[resp]]$sm[agy]
  y <- sm*exp(a+b*lX); y[!is.finite(y)] <- 0; unname(y)
}
FT3_M3 <- 0.0283168
metrics <- function(sp,dbh,ht,expf,form=NULL,risk=NULL){
  live <- is.finite(dbh)&dbh>=4&is.finite(expf)&expf>0
  sp<-sp[live];dbh<-dbh[live];ht<-ht[live];expf<-expf[live]
  if (!length(dbh)) return(c(BA=0,QMD=0,TOPHT=0,TOTVOL=0,TPH=0))
  BA<-sum(pi*(dbh/200)^2*expf); TPH<-sum(expf); QMD<-sqrt((BA/TPH)/(pi/40000))
  o<-order(-dbh); cw<-cumsum(expf[o]); idx<-which(cw<=100); if(!length(idx))idx<-1
  TOPHT<-mean(ifelse(is.finite(ht[o][idx]),ht[o][idx],himp(sp[o][idx],dbh[o][idx])))
  tot<-sum(nsvb(sp,dbh,ht,"VOLCFGRS")*expf)*FT3_M3
  c(BA=BA,QMD=QMD,TOPHT=TOPHT,TOTVOL=tot,TPH=TPH)
}
acadgy <- names(AGY2SPCD); mapsp <- function(s){s<-toupper(s);ifelse(s%in%acadgy,s,ifelse(s%in%sw,"OS","OH"))}
bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult"))x[[c]][is.na(x[[c]])]<-1;x$max.dbh[is.na(x$max.dbh)]<-200;x$max.height[is.na(x$max.height)]<-50;x}

## ---- 4. ops assembly -- exactly the h1default env-var recipe, hardcoded (no env indirection) ---
ONSET<-0.55; BREAK<-0.62; BG<-0.020; BS<-0.80; IRC<-0.58; IRK<-8; SDMAX<-1.0; IMULT<-2.5
NB_BREAK<-0.70; QC_BREAK<-0.62; NB_AFAC<-0.579; QC_AFAC<-0.111
USE_BRMS<-TRUE; USE_ANCHOR<-TRUE
ops<<-make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$use.sdimort<-TRUE;ops$sdimort.onset<-ONSET;ops$sdimort.break<-BREAK;ops$sdimort.beta.gentle<-BG;ops$sdimort.beta.steep<-BS;ops$sdimort.max<-SDMAX;ops$sdimax.site.term<-FALSE;ops$use.mortcal<-FALSE
ops$use.ingrowth.release<-TRUE;ops$ingrowth.rd.center<-IRC;ops$ingrowth.rd.k<-IRK;ops$ingrowth.mult<-IMULT
ops$use.esi.domht <- FALSE
ops$use.brms.sdimax <- USE_BRMS; ops$brms.sdimax.map <- list(BV)
ops$use.esi.anchor.recal <- USE_ANCHOR
ops$esi.anchor.coef <- list(list(NB=c(0.885,0.01027), QC=c(0.441,0.03783)))
ops$sdimort.break.region <- list(c(NB=NB_BREAK, QC=QC_BREAK))
ops$ingrowth.mult.region <- list(c(NB=1.0, QC=1.0))
## LEV3 (h1default: LEV3=1, LO=0.35 HI=0.45 QMIN=18)
ops$use.ddbh.standcon<-TRUE; ops$ddbh.standcon.hi<-0.45; ops$ddbh.standcon.lo<-0.35; ops$ddbh.standcon.qmin<-18
## hierarchical posterior switches: FALSE in h1default (h1 is the hand-lever candidate, not the posterior one)
ops$use.hier.ingrowth <- FALSE; ops$use.hier.mortality <- FALSE; ops$hier.postdir <- "~/v13_kickoff"
## MERGE_V24 h1_v132_mortgate block: V1211_MORTGATE=TRUE V1211_DHTHW=FALSE, MORT_FMIN/K/RD0 defaults
ops$mort.dens.scale <- TRUE
ops$mort.dens.fmin <- 0.13; ops$mort.dens.k <- 12.4; ops$mort.dens.rd0 <- 0.38
## ops$use.dht.hw.mod left at model default (V1211_DHTHW=FALSE => not set here, per merge_v24 runner)
## ops$stand.managed is set PER STAND below (fixed per source, or per-row MANAGED for ns/ns_long)

## ---- 5. load this source's real t1 data ---------------------------------------------------------
prs <- rbindlist(lapply(cfg$pairs, fread), fill = TRUE)
ti  <- fread(cfg$init)
e8  <- fread(cfg$site); e8[, esi8 := as.numeric(esi8)]
prs <- merge(prs, e8, by = "SITE", all.x = TRUE)
prs[, csi_site := ifelse(is.finite(esi8) & esi8 > 2, esi8, CSI_DEFAULT)]
prs[, esi_cov  := is.finite(esi8) & esi8 > 2]
if (isTRUE(cfg$indomain)) prs <- prs[PROV == "NB" | esi_cov == TRUE]
if (!is.null(cfg$prov_filter)) prs <- prs[PROV == cfg$prov_filter]
if (!"MANAGED" %in% names(prs)) prs[, MANAGED := cfg$managed]
prs <- unique(prs, by = "STAND")
setkey(ti, STAND)

cat(sprintf("[%s] domain-filtered pairs n=%d, esi_cov TRUE n=%d, csi_site range %.2f-%.2f\n",
  SRC, nrow(prs), sum(prs$esi_cov), min(prs$csi_site,na.rm=TRUE), max(prs$csi_site,na.rm=TRUE)))

## ---- 6. select real t1 stands spanning the site gradient ----------------------------------------
covered <- prs[esi_cov == TRUE]
pool <- if (nrow(covered) >= 6) covered else prs
uST <- unique(pool$STAND)
qs <- if (length(uST) >= 15) c(0.10,0.35,0.65,0.90) else if (length(uST) >= 6) c(0.15,0.50,0.85) else c(0.50)
target_csi <- quantile(pool$csi_site, probs = qs, na.rm = TRUE, type = 1)
pick_stand <- function(target){
  d <- abs(pool$csi_site - target)
  pool$STAND[which.min(d)]
}
sel_stand <- unique(sapply(target_csi, pick_stand))
sel <- prs[STAND %in% sel_stand]
sel <- sel[!duplicated(STAND)]
SINGLE_SITE <- FALSE
## If this source's real site index is effectively a single point (e.g. Baxter: IQR=0, one ESI
## value across all 91 held-out mature stands), a site GRADIENT cannot be built from real data.
## Rather than fabricate a synthetic multi-CSI spread, or pool several same-site stands into one
## bakuzis_check.R "site" bucket (which would corrupt its per-age, one-row assumption), this source
## is run as a single real trajectory and site-ordering (#1/#7) and Eichhorn (#8), which require a
## real productivity gradient, are reported NOT ASSESSABLE for it in the memo, flagged explicitly
## rather than silently defaulting to a vacuous PASS on an n=1 comparison.
if (uniqueN(round(sel$csi_site,2)) < 2) {
  SINGLE_SITE <- TRUE
  cat(sprintf("[%s] SINGLE-SITE SOURCE: real ESI is a single point (%.2f) across all %d domain stands; site-ordering/Eichhorn not assessable from real data for this source.\n", SRC, sel$csi_site[1], nrow(pool)))
}
cat(sprintf("[%s] selected %d real t1 stands: %s (csi_site: %s)\n",
  SRC, nrow(sel), paste(sel$STAND, collapse=", "), paste(round(sel$csi_site,1), collapse=", ")))
sel[, single_site_source := SINGLE_SITE]
fwrite(sel, file.path(OUT_DIR, paste0(SRC, "_h1default_standlog.csv")))
if (!SINGLE_SITE && nrow(sel) < 3) cat(sprintf("[%s] WARNING: fewer than 3 site strata available (n=%d); site-ordering test will be underpowered for this source\n", SRC, nrow(sel)))

## ---- 7. chain AcadianGYOneStand annually from each selected real t1 stand -----------------------
alltraj <- list()
for (k in seq_len(nrow(sel))) {
  p <- sel[k]; sid <- p$STAND
  it <- ti[.(sid)]
  if (nrow(it) < 3) { cat(sprintf("[%s] SKIP %s: fewer than 3 init trees\n", SRC, sid)); next }
  elev <- if (is.finite(p$ELEV) && p$ELEV > 0) p$ELEV else 200
  reg  <- if (identical(p$PROV,"NB")) "NB" else if (identical(p$PROV,"QC")) "QC" else "ME"
  dhtm <- if (reg=="NB") NB_AFAC else if (reg=="QC") QC_AFAC else 1
  managed_here <- if (!is.na(cfg$managed)) cfg$managed else isTRUE(as.logical(p$MANAGED))
  ops$stand.managed <- isTRUE(managed_here)
  cur <- data.frame(year=0, plot=1L, tree=seq_len(nrow(it)), sp=mapsp(it$SP), dbh=it$DBH,
    ht=ifelse(is.finite(it$HT)&it$HT>0, it$HT, NA_real_), hcb=NA, cr=NA, expf=it$EXPF,
    form=NA_character_, risk=NA_character_, ddbh.mult=1, dht.mult=dhtm, mort.mult=1,
    max.dbh=200, max.height=50, stringsAsFactors=FALSE)
  if (SPLIT) cur <- split_formrisk(cur)
  csi_use <- if (is.finite(p$csi_site) && p$csi_site > 2) p$csi_site else CSI_DEFAULT
  stand <<- tryCatch(make_stand(stand.id=sid, csi=csi_use, elev=elev, region=reg), error=function(e) NULL)
  if (is.null(stand)) { cat(sprintf("[%s] SKIP %s: make_stand failed\n", SRC, sid)); next }
  eb <- ecobucket_lookup[STAND==sid, gate3][1]
  ops$active_ecobucket <- if (length(eb) && !is.na(eb)) eb else NULL
  yr_ok <- 0
  for (age in 1:HORIZON) {
    nx <- tryCatch(AcadianGYOneStand(tree=cur, stand=stand, ops=ops), error=function(e) NULL)
    if (is.null(nx) || nrow(nx) == 0) break
    cur <- bf(nx)
    m <- metrics(cur$sp, cur$dbh, cur$ht, cur$expf, cur$form, cur$risk)
    if (m["TPH"] < 1 || !is.finite(m["TOPHT"])) break
    alltraj[[length(alltraj)+1]] <- data.table(origin="h1_v132_mortgate", source=SRC, STAND=sid,
      managed=isTRUE(managed_here), site=round(csi_use,1), age=age,
      HT=unname(m["TOPHT"]), TPH=unname(m["TPH"]), BAPH=unname(m["BA"]), QMD=unname(m["QMD"]), VOL=unname(m["TOTVOL"]))
    yr_ok <- age
  }
  cat(sprintf("[%s] stand %s (site %.1f, managed=%s): reached age %d of %d\n", SRC, sid, csi_use, managed_here, yr_ok, HORIZON))
}

if (length(alltraj) == 0) {
  cat(sprintf("[%s] NOT ASSESSABLE: no trajectory produced any output year (all selected stands failed)\n", SRC))
  quit(save="no", status=1)
}
TR <- rbindlist(alltraj)
out_path <- file.path(OUT_DIR, paste0(SRC, "_h1default_traj.csv"))
fwrite(TR, out_path)
cat(sprintf("[%s] wrote %s (rows=%d, sites=%d, max age reached=%d)\n", SRC, out_path, nrow(TR), uniqueN(TR$site), max(TR$age)))
cat("DONE_BAKUZIS_H1DEFAULT_TRAJ\n")

## v143_grid_thdump.R. 14.3 pre-registration 1 (md5 7f3e67c2), TH step input for the thinned grid. COPY of the frozen
## v142_20260925/bak141/scripts/2026-09-25_v142_bak141_harness.R (md5 3b35a11b) with one change: when V143_THDUMP names a
## file, the tree list held immediately before thin_below and the list it returns are saved there (same rows, same
## order; thin_below keeps every row and only sets expf), with the thinning age and cell, and the projection stops.
## Run only with REGIME=thin and 14.1 settings. Before the thinning tst is NA, so 14.1, 14.1 with T off and every arm
## project identically up to this point. No em dashes.
## 2026-09-25_v142_bak141_harness.R. Pre-registration 4, part B. FROZEN COPY of
## v141_20260923/e6_20260925/scripts/2026-09-25_v141_E6_F_bakuzis_v141.R with three changes, diff in ../diffs/:
## the grid adds n0 12000; an optional single commercial thinning (REGIME=thin) fixed in PREREG4; and three
## output columns (REGIME, THIN_AGE, TST). With REGIME=none the projection is the parent's. Parent header follows.
## 2026-09-25_v141_E6_F_bakuzis_v141.R
## E6 leg 1 under pre-registration 2 revision 5, R2.17 and R2.18. V141 COPY of
## v1404/bakuzis_dflt_20260923/scripts/2026-09-23_v1404_F_bakuzis_envlev3.R. Adds exactly one thing:
## the 14.1 option 3 overlay is sourced after MODEL_FILE and before make_ops, gated on V141=1, so
## ops carries the v141 fields. Everything else is the parent verbatim. With V141 unset this file
## reproduces its parent, which gate B1 of 23 September proved reproduces the frozen 17 September
## reference exactly in all 15 cells.
##
## This grid has no thinning at any age. ops$stand.tst is therefore NA at every step and the
## overlay leaves T as the identity, by contract. That is the point of the v141LT configuration:
## it must equal v141L exactly, which tests the refusal to guess a thinning date over 160
## projection years rather than asserting it. No em dashes.
.libPaths(c("~/R/rhel9/4.5.2", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")
CFG <- Sys.getenv("CONFIG"); CELL <- as.integer(Sys.getenv("CELL")); OUT <- Sys.getenv("OUT_DIR")
YEARS <- as.integer(Sys.getenv("YEARS", "160"))
GRID <- CJ(esi = c(12, 14, 16, 18, 20), n0 = c(1500, 3000, 6000, 12000))
REGIME <- Sys.getenv("REGIME", "none"); stopifnot(REGIME %in% c("none", "thin"))
g <- GRID[CELL + 1L]
of <- file.path(OUT, sprintf("traj_%s_%s_cell%02d.csv", REGIME, CFG, CELL)); if (file.exists(of)) stop("exists")
source(Sys.getenv("MODEL_FILE")); source("~/hw_formrisk_split.R")

## ---- 14.1 option 3 overlay, the only addition to the parent harness -------------------------
V141 <- identical(Sys.getenv("V141","0"), "1")
if (V141) {
  .v141_file <- path.expand(Sys.getenv("V141_FILE","~/v14_1_20260923/AcadianGY_14.1.r"))
  if (!file.exists(.v141_file)) stop("v141: V141=1 but the overlay file does not exist: ", .v141_file)
  source(.v141_file)
  cat(sprintf("[F] v141 overlay %s md5 %s\n", .v141_file, as.character(tools::md5sum(.v141_file))))
} else {
  cat("[F] v141: V141=0, unhooked\n")
}

bf <- function(x){for(c in c("ddbh.mult","dht.mult","mort.mult")) if(c %in% names(x)) x[[c]][is.na(x[[c]])]<-1
  if("max.dbh" %in% names(x)) x$max.dbh[is.na(x$max.dbh)]<-200; if("max.height" %in% names(x)) x$max.height[is.na(x$max.height)]<-50; x}
init <- function(spvec, seed, n0){ set.seed(seed); n<-40
  data.frame(year=0,plot=1L,tree=1:n,sp=rep(spvec,each=n/length(spvec)),
    dbh=runif(n,2,5),ht=NA_real_,hcb=NA_real_,cr=NA_real_,expf=rep(n0/n,n),
    form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE) }
ops <<- make_ops(verbose=FALSE,use.ingrowth=TRUE,ingrowth.min.dbh=5.0,ingrowth.thrshld=0,use.cap.dbh=TRUE,use.cap.ht=TRUE,use.hw.mod=FALSE,use.sbw.mod=FALSE,use.thin.mod=FALSE,use.vol=FALSE)
ops$sdimort.onset<-0.55;ops$sdimort.break<-0.62;ops$sdimort.beta.gentle<-0.02;ops$sdimort.beta.steep<-0.80;ops$sdimort.max<-1.0;ops$sdimax.site.term<-FALSE;ops$use.mortcal<-FALSE
ops$use.ingrowth.release<-TRUE;ops$ingrowth.rd.center<-0.58;ops$ingrowth.rd.k<-8;ops$ingrowth.mult<-2.5
ops$use.esi.domht <- FALSE; ops$use.brms.sdimax <- FALSE; ops$use.esi.anchor.recal <- TRUE
ops$esi.anchor.coef <- list(list(NB=c(0.885,0.01027), QC=c(0.441,0.03783)))
ops$use.ddbh.standcon<-TRUE
ops$ddbh.standcon.lo   <- as.numeric(Sys.getenv("LEV3_LO",   "0.35"))
ops$ddbh.standcon.hi   <- as.numeric(Sys.getenv("LEV3_HI",   "0.45"))
ops$ddbh.standcon.qmin <- as.numeric(Sys.getenv("LEV3_QMIN", "18"))
cat(sprintf("[F] standcon lo %s hi %s qmin %s\n", ops$ddbh.standcon.lo, ops$ddbh.standcon.hi, ops$ddbh.standcon.qmin))
ops$use.hier.ingrowth <- FALSE; ops$use.hier.mortality <- FALSE
ops$stand.managed <- FALSE; ops$active_ecobucket <- NA

## ---- v141 switches and the explicit absence of a thinning date -------------------------------
if (V141) {
  ops$use.lsdg.v141 <- identical(Sys.getenv("LSDG_V141","0"), "1")
  ops$use.thin.v141 <- identical(Sys.getenv("THIN_V141","0"), "1")
  ops$v141.coef.file <- Sys.getenv("V141_COEF", NA_character_)
  ops$v141.d.lo <- as.numeric(Sys.getenv("V141_DLO","12.7"))
  ops$v141.d.hi <- as.numeric(Sys.getenv("V141_DHI","15.0"))
  ops$v141.rel.cap <- as.numeric(Sys.getenv("V141_RELCAP","NA"))
  ## R2.18. This grid is never thinned, so years since thinning is not unknown by omission, it is
  ## absent as a fact. NA is what the overlay contracts to receive, and it leaves T as the identity.
  ops$stand.tst <- NA_real_
  cat(sprintf("[F] v141 L=%s T=%s coef=%s relcap=%s stand.tst=NA (grid is never thinned)\n",
    ops$use.lsdg.v141, ops$use.thin.v141, ops$v141.coef.file, ops$v141.rel.cap))
  if (isTRUE(ops$use.thin.v141) && !is.finite(ops$v141.rel.cap))
    stop("v141: THIN_V141=1 requires a finite V141_RELCAP, which gate GT6 forbids leaving unset")
}

cat(sprintf("[F] %s cell %d esi %d n0 %d linked=%s mode=%s sdimort=%s\n", CFG, CELL, g$esi, g$n0,
  isTRUE(ops$use.linked.mortality), ops$linked.mortality.mode, isTRUE(ops$use.sdimort)))
cur <- split_formrisk(init(c("BF","RS","BS","WS"), seed = 101, n0 = g$n0)); n_init <- max(cur$tree)
stand <<- make_stand(stand.id = sprintf("%s_cell%02d", CFG, CELL), csi = g$esi, elev = 200, region = "ME")
FR <- function(Dq) 10^(5.745 - 1.892 * log10(Dq))
out <- list(); stop_msg <- NA_character_
## PREREG4 thinning: one commercial thinning from below at the end of the first year harness QMD reaches
## 12 cm, removing 35 percent of basal area among trees at or above 4 cm; last tree partially by expansion.
## Afterwards stand.managed is TRUE and stand.tst for the growth step ending at age y is y - THIN_AGE (>= 1).
THIN_AGE <- NA_integer_; BA_REMOVED <- NA_real_
thin_below <- function(tr, frac) {
  i <- which(tr$dbh >= 4 & is.finite(tr$dbh) & tr$expf > 0)
  b <- pi * (tr$dbh[i] / 200)^2 * tr$expf[i]; target <- frac * sum(b)
  o <- i[order(tr$dbh[i])]; bo <- pi * (tr$dbh[o] / 200)^2 * tr$expf[o]; cb <- cumsum(bo)
  full <- o[cb <= target]; tr$expf[full] <- 0
  k <- o[cb > target][1]; rem <- target - sum(bo[cb <= target])
  if (!is.na(k) && rem > 0) tr$expf[k] <- tr$expf[k] * (1 - rem / (pi * (tr$dbh[k] / 200)^2 * tr$expf[k]))
  list(tr = tr, removed = target) }
for (age in 1:YEARS) {
  ops$stand.tst <- if (is.na(THIN_AGE)) NA_real_ else as.numeric(age - THIN_AGE)
  nx <- tryCatch(AcadianGYOneStand(tree = cur, stand = stand, ops = ops), error = function(e) { stop_msg <<- conditionMessage(e); NULL })
  if (is.null(nx) || nrow(nx) == 0) break
  cur <- bf(nx); live <- cur[cur$dbh >= 4 & is.finite(cur$dbh), ]; if (nrow(live) < 1) break
  ba <- sum(pi * (live$dbh / 200)^2 * live$expf); tph <- sum(live$expf); qmd <- sqrt((ba / tph) / (pi / 40000))
  htd <- { o <- order(-live$dbh); cw <- cumsum(live$expf[o]); idx <- which(cw <= 100); if (!length(idx)) idx <- 1; mean(live$ht[o][idx], na.rm = TRUE) }
  sdi <- sum((live$dbh / 25.4)^1.6 * live$expf)
  out[[age]] <- data.table(config = CFG, cell = CELL, esi = g$esi, n0 = g$n0, age = age, HT = htd, TPH = tph, BAPH = ba, QMD = qmd, SDI = sdi,
    VOL = 0.45 * ba * htd, TPH5 = sum(cur$expf[cur$dbh >= 5 & cur$expf > 1e-4]), REC_TPH = sum(cur$expf[cur$tree > n_init & cur$expf > 1e-4]),
    REC_NEW = NA_real_, MAXDBH = max(live$dbh, na.rm = TRUE),
    exceed = log10(tph) - log10(FR(qmd)), REGIME = REGIME, THIN_AGE = THIN_AGE, TST = ops$stand.tst)
  if (REGIME == "thin" && is.na(THIN_AGE) && qmd >= 12) {
    .v143_pre <- cur
    th <- thin_below(cur, 0.35); cur <- th$tr; BA_REMOVED <- th$removed; THIN_AGE <- age
    if (nzchar(Sys.getenv("V143_THDUMP"))) {
      stopifnot(nrow(.v143_pre) == nrow(cur), identical(.v143_pre$tree, cur$tree))
      saveRDS(list(pre = .v143_pre, post = cur, thin_age = age, cell = CELL, qmd = qmd, ba = ba, ba_removed = BA_REMOVED), Sys.getenv("V143_THDUMP"))
      cat(sprintf("[F] v143 TH dump written at age %d, stopping\n", age)); break }
    ops$stand.managed <- TRUE
    cat(sprintf("[F] thinned at age %d, QMD %.2f, BA %.3f, removed %.3f m2/ha\n", age, qmd, ba, BA_REMOVED))
  }
}
TR <- rbindlist(out)
dir.create(OUT, showWarnings = FALSE, recursive = TRUE)
fwrite(TR, of)
if (V141 && exists(".acd_v141_report")) { cat("[F] v141 counters:\n"); print(.acd_v141_report()) }
cat(sprintf("[F] wrote %s rows=%d stop=%s\n", of, nrow(TR), stop_msg))

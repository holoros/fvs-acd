# PERSEUS-ME v2.6 track V: run one FVS keyfile through the production FVS-ACD bridge (rFVS + customRun_fvsRunAcadian.R).
# usage: Rscript bridge_batch.R BATCHDIR  (runs every BATCHDIR/<sid>.key in its own folder BATCHDIR/<sid>/ in one R session;
#        each keyfile's DSNOUT writes BATCHDIR/<sid>/fvsout.db; done list BATCHDIR/<sid>/DONE)
# env: V_ARM prod_fix | prod_main | b141 | u26 ; V_ARMDIR folder holding AcadianGY.R and customRun_fvsRunAcadian.R (the bridge);
#      V_ACDREPO engines_ext/fvs-acd (14.1 stack, b141/u26) ; V_MANAGED 1 = C5 managed convention (stand.managed TRUE, tst0 0);
#      V_MGMAP csv stand_key,managed0 (C2, b141) ; V_U26 csv grp,db0,db1,gamma (u26) ; V_CAPTURE rds path (identity checks)
.libPaths(c("~/Rlib", .libPaths()))
suppressPackageStartupMessages({ library(rFVS); library(dplyr) })
bdir <- normalizePath(commandArgs(TRUE)[1])
arm <- Sys.getenv("V_ARM"); adir <- Sys.getenv("V_ARMDIR"); capf <- Sys.getenv("V_CAPTURE", "")
rtn <- try(fvsLoad("FVSne", bin = "/home/aaron/opt/fvs/bin"))
if (inherits(rtn, "try-error")) stop("fvs load failed")
invisible(capture.output(suppressMessages(source(file.path(adir, "AcadianGY.R")))))
source(file.path(adir, "customRun_fvsRunAcadian.R"))
stopifnot(exists("make_fvs_tree"), exists("AcadianGYOneStand"))
newcap <- function() list(arm = arm, version = AcadianVersionTag, calls = list(), handoff = list(), first = NULL)
CAP <- newcap()

if (arm %in% c("b141", "u26")) {
  keep <- c("make_acd_tree", "make_fvs_tree", "validate_acd_tree_spp", "validate_acd_tree_status", "make_fvs_calib", "make_ops")
  K <- mget(keep, envir = globalenv())
  owd <- setwd(Sys.getenv("V_ACDREPO")); source("engine/load_acd141.R"); cf <- load_acd141(); setwd(owd)
  mk141 <- make_ops; one141 <- AcadianGYOneStand
  list2env(K, globalenv())                       # production bridge functions and production make_ops for the runner
  OPS0 <- mk141(use.ingrowth = FALSE, ingrowth.min.dbh = 5.0, ingrowth.thrshld = 0, use.cap.dbh = TRUE, use.cap.ht = TRUE,
                use.linked.mortality = TRUE, linked.mortality.mode = "L2", linked.coef.file = cf$linked.coef.file,
                linked.stage3.species.re = TRUE, use.dba.v1404 = TRUE, use.smalltree.dg = FALSE, use.lsdg.v141 = TRUE,
                use.thin.v141 = TRUE, v141.coef.file = cf$v141.coef.file, v141.rel.cap = 2.9848)
  OPS0$ingrowth.mult <- 2.5; OPS0$use.ddbh.standcon <- TRUE; OPS0$ddbh.standcon.lo <- 0.35; OPS0$ddbh.standcon.hi <- 0.45
  OPS0$ddbh.standcon.qmin <- 18; OPS0$use.mortcal <- FALSE
  MAN <- Sys.getenv("V_MANAGED", "0") == "1"
  MG <- if (nzchar(Sys.getenv("V_MGMAP"))) read.csv(Sys.getenv("V_MGMAP"), colClasses = "character") else NULL
  U26 <- if (arm == "u26") read.csv(Sys.getenv("V_U26")) else NULL
  # track U species groups (u_build.py sgrp: SF = SPCD 12 and 90 to 98, IH = 375 379 741 743 746 761, OS other softwood, NH other
  # hardwood) on AcadianGY alpha codes (engines/acd141/acd_engine.py AGY table)
  acd_group <- function(sp) ifelse(sp %in% c("BF", "RS", "BS", "WS", "NS"), "SF", ifelse(sp %in% c("PB", "GB", "BP", "BT", "QA", "PR", "PC"), "IH",
                                  ifelse(sp %in% c("WP", "RN", "JP", "EH", "WC", "TA", "OS", "SP", "NC", "RC", "BN", "SC", "PP"), "OS", "NH")))
  y0 <- NA_real_
  AcadianGYOneStand <- function(tree, stand, ops) {
    sid <- trimws(fvsGetStandIDs()[["standid"]])
    if (is.na(y0)) y0 <<- tree$year[1]
    o <- OPS0
    o$stand.managed <- if (MAN) TRUE else if (!is.null(MG) && sid %in% MG$stand_key) MG$managed0[MG$stand_key == sid][1] == "1" else FALSE
    o$stand.tst <- if (MAN) tree$year[1] - y0 else NA_real_
    for (v in c("ddbh.mult", "dht.mult", "mort.mult")) tree[[v]][is.na(tree[[v]])] <- 1   # standalone refill convention
    tree$max.dbh[is.na(tree$max.dbh)] <- 200; tree$max.height[is.na(tree$max.height)] <- 50
    if (!is.null(U26)) {
      g <- U26[match(acd_group(tree$sp), U26$grp), ]
      tree$ddbh.mult <- exp(g$db0 + g$db1 * log(tree$dbh)); tree$mort.mult <- exp(g$gamma); o$linked.use.mortmult <- TRUE
    }
    if (is.null(CAP$first)) CAP$first <<- list(tree = tree, stand = stand, ops = o, sid = sid)
    # the registered standalone runner assigns ops and stand to the global environment before each call (acd141_pairs.R);
    # 14.x helpers read them there, so the 14.1 ops are swapped in for the call and the runner's production ops restored
    old_ops <- get("ops", envir = globalenv()); assign("ops", o, envir = globalenv()); assign("stand", stand, envir = globalenv())
    out <- one141(tree = tree, stand = stand, ops = o)
    assign("ops", old_ops, envir = globalenv())
    CAP$calls[[length(CAP$calls) + 1]] <<- as.data.frame(out)[, intersect(c("tree", "sp", "dbh", "ht", "expf", "year"), names(out))]
    out
  }
} else {
  orig_one <- AcadianGYOneStand
  # fvsacd142 x142: env V_X142 = csv fold,comp,form,coef (coef space separated, track U term order); V_X142_FOLDMAP = csv sid,fold
  # (out of fold runs; fold 0 = full sample); V_X142_CUT = csv sid,rem (cut stands: R term applies). Multiplied into production.
  X142 <- if (nzchar(Sys.getenv("V_X142"))) read.csv(Sys.getenv("V_X142"), colClasses = "character") else NULL
  XFM <- if (nzchar(Sys.getenv("V_X142_FOLDMAP"))) read.csv(Sys.getenv("V_X142_FOLDMAP"), colClasses = "character") else NULL
  XCUT <- if (nzchar(Sys.getenv("V_X142_CUT"))) read.csv(Sys.getenv("V_X142_CUT"), colClasses = c("character", "numeric")) else NULL
  xgrp <- function(sp) ifelse(sp %in% c("BF", "RS", "BS", "WS", "NS"), "SF", ifelse(sp %in% c("PB", "GB", "BP", "BT", "QA", "PR", "PC"), "IH",
                       ifelse(sp %in% c("WP", "RN", "JP", "EH", "WC", "TA", "OS", "SP", "NC", "RC", "BN", "SC", "PP"), "OS", "NH")))
  xterms <- function(form, tr, csi, rem) {
    d <- pmax(tr$dbh, 1e-6); g <- xgrp(tr$sp); n <- nrow(tr)
    ba <- pi / 40000 * d^2 * tr$expf; sw <- g %in% c("SF", "OS")
    bal_all <- sapply(seq_len(n), function(i) sum(ba[d > d[i]])); balsw <- sapply(seq_len(n), function(i) sum(ba[d > d[i] & sw]))
    balhw <- bal_all - balsw; sdi <- sum(tr$expf * (d / 25.4)^1.605); dq <- sqrt(sum(d^2 * tr$expf) / sum(tr$expf))
    sg <- sapply(c("SF", "OS", "IH", "NH"), function(s) as.numeric(g == s))
    if (n == 1) sg <- matrix(sg, nrow = 1)
    switch(form,
      G1 = , S1 = , R1 = matrix(1, n, 1),
      G2 = , S2 = sg,
      G3 = , S3 = cbind(sg, log(d)),
      G4 = cbind(sg, log(d), d),
      G5 = cbind(sg, log(d), d, log(balsw + 0.1), balhw),
      G6 = cbind(sg, log(d), d, log(balsw + 0.1), balhw, log(csi)),
      S4 = cbind(sg, log(d), bal_all),
      S5 = cbind(sg, log(d), bal_all, sdi / 1000),
      R2 = cbind(1, rem),
      R3 = cbind(1, rem, log(d / dq)),
      SR1 = matrix(1, n, 1), SR2 = cbind(1, rem), SR3 = cbind(1, rem, log(d)),   # D10 cut-stand survival
      DS1 = matrix(xds(tr, d), n, 1), DS2 = cbind(xds(tr, d), log(d)),   # D11 density survival, s0 from env V_X142_DS0
      stop(paste("x142 form", form)))
  }
  xds <- function(tr, d) { s0 <- as.numeric(Sys.getenv("V_X142_DS0", "NA")); if (is.na(s0)) stop("x142 DS needs V_X142_DS0")
    rep(max(sum(tr$expf * (d / 25)^1.605) / 1000 - s0, 0), length(d)) }
  xmult <- function(comp, fold, tr, csi, rem) {
    r <- X142[X142$comp == comp & X142$fold == fold, ]
    if (nrow(r) == 0 || r$form[1] %in% c("R0", "SR0", "none")) return(rep(1, nrow(tr)))
    b <- as.numeric(strsplit(r$coef[1], " ")[[1]]); X <- xterms(r$form[1], tr, csi, rem)
    stopifnot(ncol(X) == length(b)); as.vector(exp(X %*% b))
  }
  AcadianGYOneStand <- function(tree, stand, ops) {
    sid0 <- trimws(fvsGetStandIDs()[["standid"]])
    if (!is.null(X142) && nrow(tree) > 0) {
      fold <- if (!is.null(XFM) && sid0 %in% XFM$sid) XFM$fold[XFM$sid == sid0][1] else "0"
      csi <- if (!is.null(stand$csi)) stand$csi else NA_real_
      rem <- if (!is.null(XCUT) && sid0 %in% XCUT$sid) XCUT$rem[XCUT$sid == sid0][1] else NA_real_
      for (v in c("ddbh.mult", "mort.mult")) tree[[v]][is.na(tree[[v]])] <- 1
      base_d <- tree$ddbh.mult; base_m <- tree$mort.mult; ids <- tree$tree
      mg <- xmult("G", fold, tree, csi, rem); ms <- xmult("S", fold, tree, csi, rem)
      mr <- if (!is.na(rem)) xmult("R", fold, tree, csi, rem) else rep(1, nrow(tree))
      msr <- if (!is.na(rem)) xmult("SR", fold, tree, csi, rem) else rep(1, nrow(tree))
      mds <- xmult("DS", fold, tree, csi, rem)
      tree$ddbh.mult <- tree$ddbh.mult * mg * mr; tree$mort.mult <- tree$mort.mult * ms * msr * mds
    }
    if (is.null(CAP$first)) CAP$first <<- list(tree = tree, stand = stand, ops = ops, sid = sid0)
    out <- orig_one(tree, stand, ops)
    # D6: customRun feeds each year's output back in (tree = treeout), so the production multipliers are restored after every
    # call (matched by tree id); the 14.2 terms then act once per annual step instead of compounding
    if (!is.null(X142) && nrow(tree) > 0 && !inherits(out, "try-error") && all(c("ddbh.mult", "mort.mult", "tree") %in% names(out))) {
      k <- match(out$tree, ids); hit <- !is.na(k)
      out$ddbh.mult[hit] <- base_d[k[hit]]; out$mort.mult[hit] <- base_m[k[hit]]
    }
    CAP$calls[[length(CAP$calls) + 1]] <<- as.data.frame(out)[, intersect(c("tree", "sp", "dbh", "ht", "expf", "year"), names(out))]
    out
  }
}
orig_mft <- make_fvs_tree
make_fvs_tree <- function(tree.data, orgtree.list, num.plots) {
  res <- orig_mft(tree.data, orgtree.list, num.plots)
  CAP$handoff[[length(CAP$handoff) + 1]] <<- list(ids = fvsGetTreeAttrs(c("id", "species", "dbh", "tpa")),
    acd = as.data.frame(tree.data)[, c("tree", "sp", "dbh", "ht", "expf")],
    org = as.data.frame(orgtree.list)[, intersect(c("tree", "fvs.num", "sp", "dbh", "ht", "expf", "acd.ex"), names(orgtree.list))],
    tofvs = as.data.frame(res))
  res
}
runOps <- list(uiAcadianIngrowth = Sys.getenv("SILC_INGROWTH", "Yes"), uiAcadianMinDBH = Sys.getenv("SILC_MINDBH", "3.0"), uiAcadianMort = "Acadian", uiAcadianCutPoint = Sys.getenv("SILC_CUT", "0.95"),
               uiAcadianVolume = "Base Model", uiAcadianTHIN = "Yes", uiAcadianSBW = "No", uiAcadianSBWCDEF = "100",
               uiAcadianSBW.YR = "2020", uiAcadianSBW.DUR = "10")
keys <- sort(list.files(bdir, pattern = "[.]key$"))
# FVS keeps file units open across runs in one session ("Too many open files" after about 1,000 runs): at most V_MAXRUNS
# runs per session; v_batch.py starts new sessions until every keyfile has a DONE marker
maxruns <- as.integer(Sys.getenv("V_MAXRUNS", "400")); nrun <- 0L
# 2026-11-17 x142sb: env V_SDIB = csv with columns sid, sdimax (brms SDImax per stand); passed to AcadianGY.R as ACD_SDIMAX_BRMS
SDIB <- if (nzchar(Sys.getenv("V_SDIB"))) read.csv(Sys.getenv("V_SDIB"), colClasses = c(sid = "character")) else NULL
for (k in keys) {
  sid <- sub("[.]key$", "", k); wd <- file.path(bdir, sid)
  if (file.exists(file.path(wd, "DONE"))) next
  if (nrun >= maxruns) break
  nrun <- nrun + 1L
  dir.create(wd, showWarnings = FALSE); file.copy(file.path(bdir, k), file.path(wd, "s.key"), overwrite = TRUE)
  setwd(wd); CAP <- newcap(); if (exists("y0")) y0 <- NA_real_
  t1 <- proc.time()[["elapsed"]]
  if (!is.null(SDIB)) { v <- SDIB$sdimax[match(sid, SDIB$sid)]; if (length(v) && is.finite(v)) Sys.setenv(ACD_SDIMAX_BRMS = v) else Sys.unsetenv("ACD_SDIMAX_BRMS") }
  r <- tryCatch({ fvsSetCmdLine("--keywordfile=s.key"); fvsRunAcadian(runOps, autoload.model = FALSE) }, error = function(e) { sink(); -99 })
  while (sink.number() > 0) sink()
  if (nzchar(capf) && !is.null(CAP$first)) saveRDS(CAP, file.path(capf, paste0(sid, ".rds")))
  writeLines(sprintf("rtn %s calls %d s %.2f", r, length(CAP$calls), proc.time()[["elapsed"]] - t1), "DONE")
  setwd(bdir)
}
cat("batch done", arm, length(keys), "\n")

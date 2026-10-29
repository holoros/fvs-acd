## ==== PREREG26 BLOCK (replaces runner lines 420 to 491) ===========================================================
## Modes: P26_MODE=g0 projects named real NS stands (P26_G0_STANDS, comma separated) for their own interval and writes one
## result row per stand in the runner's column layout; P26_MODE=grid projects the synthetic cells listed in P26_CELLS
## (a CSV: cell,mix,esi,n0) for P26_NYR years and writes one summary row per cell per year.
P26_MODE <- Sys.getenv("P26_MODE"); P26_OUT <- Sys.getenv("P26_OUT"); P26_ARM <- Sys.getenv("P26_ARM")
if (!(P26_MODE %in% c("g0","grid")) || !nzchar(P26_OUT) || !nzchar(P26_ARM)) stop("p26: need P26_MODE g0|grid, P26_OUT, P26_ARM")
if (file.exists(P26_OUT)) stop("p26: REFUSE, output exists: ", P26_OUT)
cat(sprintf("p26: mode=%s arm=%s IMULT=%s ING_MIN_FROM_SCORE=%s HTFIX_B1=%s HTFIX_B2=%s\n", P26_MODE, P26_ARM, format(IMULT),
  Sys.getenv("ING_MIN_FROM_SCORE","unset"), Sys.getenv("HTFIX_B1","unset"), Sys.getenv("HTFIX_B2","unset")))
## one stand, nyr annual steps; the per stand setup and the per year loop are runner lines 431 to 440 without PD_* hooks.
## rec(cur, yr) is called at yr = 0 (after htfx on the initial list) and after every step.
p26_project <- function(cur, p, nyr, rec = NULL, tlim = 60) {
  sid <- p$STAND; elev <- if (is.finite(p$ELEV) && p$ELEV > 0) p$ELEV else 200
  setTimeLimit(elapsed = tlim, transient = TRUE); on.exit(setTimeLimit(), add = TRUE)
  if (SPLIT) { cur <- split_formrisk(cur) }
  csi_use <- if (is.finite(p$csi_site) && p$csi_site > 2) p$csi_site else CSI_DEFAULT
  reg <- if (p$PROV == "NB") "NB" else if (p$PROV == "QC") "QC" else if (p$PROV == "NS") "NS" else "ME"
  stand <<- make_stand(stand.id = sid, csi = csi_use, elev = elev, region = reg)
  o <- ops
  o$stand.managed <- as.logical(p$MGD_USE)
  .tst0 <<- { v <- suppressWarnings(as.numeric(p$TST_RAW)); if (length(v) != 1L || !is.finite(v)) NA_real_ else v }
  o$stand.tst <- .tst0
  if (identical(Sys.getenv("ING_MIN_FROM_SCORE", "0"), "1")) o$ingrowth.min.dbh <- GYR_smd(p)   # PREREG9 threshold matching
  o$active_ecobucket <- ecobucket_lookup[STAND == GYR_alias(p, sid), gate3][1]
  ops <<- o
  n_init <- max(cur$tree)
  cur <- htfx(cur, p); if (!is.null(rec)) rec(cur, 0L, n_init)
  for (yr in seq_len(nyr)) {
    ops$stand.tst <<- if (is.na(.tst0)) NA_real_ else .tst0 + (yr - 1L)
    nx <- AcadianGYOneStand(tree = cur, stand = stand, ops = ops)
    if (is.null(nx) || nrow(nx) == 0) stop("empty")
    cur <- htfx(bf(nx), p); if (!is.null(rec)) rec(cur, yr, n_init)
  }
  attr(cur, "n_init") <- n_init; cur
}
if (P26_MODE == "g0") {
  ids <- strsplit(Sys.getenv("P26_G0_STANDS"), ",")[[1]]; setDT(prs); rows <- list()
  for (sid in ids) { p <- as.list(prs[STAND == sid]); if (length(p$STAND) != 1L) stop("p26 g0: stand not admitted once: ", sid)
    it <- ti[.(sid)]; iv <- max(1, round(p$interval_years))
    cur <- data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=(if(p$PROV=="NB") NB_AFAC else if(p$PROV=="QC") QC_AFAC else 1),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    res <- p26_project(cur, p, iv)
    n_init <- attr(res, "n_init"); ing_rate <- sum(res$expf[res$tree > n_init & is.finite(res$dbh) & res$dbh >= 5], na.rm = TRUE) / iv
    m2p <- metrics(res$sp, res$dbh, res$ht, res$expf, res$form, res$risk, mindbh = GYR_smd(p))
    rows[[sid]] <- data.table(STAND = sid, iv = iv, t(setNames(m2p, paste0(names(m2p), "_p"))), ING_p = ing_rate) }
  fwrite(rbindlist(rows), P26_OUT); cat("p26 g0 WROTE", P26_OUT, "\n")
} else {
  cells <- fread(Sys.getenv("P26_CELLS")); NYR <- as.integer(Sys.getenv("P26_NYR", "100")); SMD <- as.numeric(Sys.getenv("P26_SMD"))
  if (!is.finite(SMD)) stop("p26 grid: P26_SMD (the synthetic stand's scoring threshold) must be set")
  MIX <- list(BF = c(BF = 40), RS = c(RS = 40), MX = c(RS = 12, BF = 10, RM = 6, SM = 4, WS = 4, YB = 4))
  set.seed(20260930); D0 <- runif(40, 2, 5)          # one draw, shared by every cell and arm
  out <- list()
  for (k in seq_len(nrow(cells))) { cc <- cells[k]; t0 <- Sys.time()
    sp <- rep(names(MIX[[cc$mix]]), MIX[[cc$mix]]); if (length(sp) != 40L) stop("mix size")
    cur <- data.frame(year=0,plot=1L,tree=1:40,sp=sp,dbh=D0,ht=NA_real_,hcb=NA,cr=NA,expf=rep(cc$n0/40,40),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=1,mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    p <- list(STAND = sprintf("P26_%s", cc$cell), PROV = "NS", ELEV = 200, csi_site = cc$esi, MGD_USE = 0L, TST_RAW = NA_real_, SCORE_MINDBH_OBS = SMD)
    acc <- list()
    rec <- function(x, yr, n_init) { lv <- is.finite(x$dbh) & is.finite(x$expf) & x$expf > 0
      m4 <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = 4); ms <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = SMD)
      acc[[length(acc) + 1L]] <<- data.table(arm = P26_ARM, cell = cc$cell, mix = cc$mix, esi = cc$esi, n0 = cc$n0, age = yr,
        HT = m4[["TOPHT"]], TPH = sum(x$expf[lv & x$dbh >= 4]), BAPH = m4[["BA"]], QMD = m4[["QMD"]], SDI = m4[["SDI"]], VOL = m4[["TOTVOL"]],
        MERCHVOL = m4[["MERCHVOL"]], TPH_s = sum(x$expf[lv & x$dbh >= SMD]), BAPH_s = ms[["BA"]], VOL_s = ms[["TOTVOL"]],
        TPH_all = sum(x$expf[lv]), TPH_cohort = sum(x$expf[lv & x$tree <= n_init]), TPH_ing = sum(x$expf[lv & x$tree > n_init]),
        nrec = sum(lv), smd = SMD) }
    ok <- tryCatch({ p26_project(cur, p, NYR, rec, tlim = 5400); TRUE }, error = function(e) { cat("p26 FAIL cell", cc$cell, conditionMessage(e), "\n"); FALSE })
    d <- rbindlist(acc); d[, run_ok := as.integer(ok && nrow(d) == NYR + 1L)]; out[[k]] <- d
    cat(sprintf("p26 cell %s done ok=%s rows=%d secs=%.0f\n", cc$cell, ok, nrow(d), as.numeric(difftime(Sys.time(), t0, units = "secs")))) }
  fwrite(rbindlist(out), P26_OUT); cat("p26 grid WROTE", P26_OUT, "\n")
}
if (V141 && exists(".acd_v141_report")) { .rep <- .acd_v141_report(); cat("v141 overlay counters:\n"); print(.rep) }
cat("DONE\n")

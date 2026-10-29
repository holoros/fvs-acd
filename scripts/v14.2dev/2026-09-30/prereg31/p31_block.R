## ==== PREREG31 BLOCK (replaces runner lines 420 to 486) ===========================================================
## Modes: P31_MODE=g0 projects named real QC stands (P31_G0_STANDS, comma separated) for their own interval and writes one
## result row per stand in the runner's column layout; P31_MODE=grid projects the synthetic cells listed in P31_CELLS
## (a CSV: cell,mix,esi,n0) for P31_NYR years and writes one summary row per cell per year. Same structure as PREREG26.
P31_MODE <- Sys.getenv("P31_MODE"); P31_OUT <- Sys.getenv("P31_OUT"); P31_ARM <- Sys.getenv("P31_ARM")
if (!(P31_MODE %in% c("g0","grid")) || !nzchar(P31_OUT) || !nzchar(P31_ARM)) stop("p31: need P31_MODE g0|grid, P31_OUT, P31_ARM")
if (file.exists(P31_OUT)) stop("p31: REFUSE, output exists: ", P31_OUT)
cat(sprintf("p31: mode=%s arm=%s IMULT=%s QC_AFAC=%s QC_AFAC_SMALL=%s QC_AFAC_LARGE=%s QC_AFAC_KNOT=%s ING_MIN_FROM_SCORE=%s HTFIX_B=%s\n", P31_MODE, P31_ARM, format(IMULT),
  format(QC_AFAC), Sys.getenv("QC_AFAC_SMALL","unset"), Sys.getenv("QC_AFAC_LARGE","unset"), Sys.getenv("QC_AFAC_KNOT","unset"),
  Sys.getenv("ING_MIN_FROM_SCORE","unset"), Sys.getenv("HTFIX_B","unset")))
## the initial dht.mult, set once per tree from its initial DBH: runner line 425's expression, inserted verbatim by the build
p31_dht <- function(p, it) @@DHT@@
## one stand, nyr annual steps; the per stand setup and the per year loop are runner lines 426 to 437 without PD_* hooks.
## rec(cur, yr) is called at yr = 0 (after htfx on the initial list) and after every step.
p31_project <- function(cur, p, nyr, rec = NULL, tlim = 60) {
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
if (P31_MODE == "g0") {
  ids <- strsplit(Sys.getenv("P31_G0_STANDS"), ",")[[1]]; setDT(prs); rows <- list()
  for (sid in ids) { p <- as.list(prs[STAND == sid]); if (length(p$STAND) != 1L) stop("p31 g0: stand not admitted once: ", sid)
    it <- ti[.(sid)]; iv <- max(1, round(p$interval_years))
    cur <- data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=p31_dht(p, it),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    res <- p31_project(cur, p, iv)
    n_init <- attr(res, "n_init"); ing_rate <- sum(res$expf[res$tree > n_init & is.finite(res$dbh) & res$dbh >= 5], na.rm = TRUE) / iv
    m2p <- metrics(res$sp, res$dbh, res$ht, res$expf, res$form, res$risk, mindbh = GYR_smd(p))
    rows[[sid]] <- data.table(STAND = sid, iv = iv, t(setNames(m2p, paste0(names(m2p), "_p"))), ING_p = ing_rate) }
  fwrite(rbindlist(rows), P31_OUT); cat("p31 g0 WROTE", P31_OUT, "\n")
} else {
  cells <- fread(Sys.getenv("P31_CELLS")); NYR <- as.integer(Sys.getenv("P31_NYR", "100")); SMD <- as.numeric(Sys.getenv("P31_SMD"))
  if (!is.finite(SMD)) stop("p31 grid: P31_SMD (the synthetic stand's scoring threshold) must be set")
  ELEV31 <- as.numeric(Sys.getenv("P31_ELEV")); if (!is.finite(ELEV31)) stop("p31 grid: P31_ELEV must be set")
  MIX <- list(BF = c(BF = 40), SM = c(SM = 40), MX = c(BF = 15, SM = 5, PB = 4, WS = 3, RM = 3, QA = 3, BS = 3, YB = 2, WC = 2))
  set.seed(20260930); D0 <- runif(40, 2, 5)          # one draw, shared by every cell and arm (the PREREG26 draw)
  out <- list()
  for (k in seq_len(nrow(cells))) { cc <- cells[k]; t0 <- Sys.time()
    sp <- rep(names(MIX[[cc$mix]]), MIX[[cc$mix]]); if (length(sp) != 40L) stop("mix size")
    if (!all(mapsp(sp) == sp)) stop("p31 grid: a mix species is not an AcadianGY code: ", paste(unique(sp[mapsp(sp) != sp]), collapse = " "))
    p <- list(STAND = sprintf("P31_%s", cc$cell), PROV = "QC", ELEV = ELEV31, csi_site = cc$esi, MGD_USE = 1L, TST_RAW = NA_real_, SCORE_MINDBH_OBS = SMD)
    it0 <- data.frame(DBH = D0)
    cur <- data.frame(year=0,plot=1L,tree=1:40,sp=sp,dbh=D0,ht=NA_real_,hcb=NA,cr=NA,expf=rep(cc$n0/40,40),form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=p31_dht(p, it0),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    acc <- list()
    wm <- function(v, w) if (sum(w) > 0) sum(v*w)/sum(w) else NA_real_
    rec <- function(x, yr, n_init) { lv <- is.finite(x$dbh) & is.finite(x$expf) & x$expf > 0; co <- lv & x$tree <= n_init; ig <- lv & x$tree > n_init
      m4 <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = 4); ms <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = SMD)
      acc[[length(acc) + 1L]] <<- data.table(arm = P31_ARM, cell = cc$cell, mix = cc$mix, esi = cc$esi, n0 = cc$n0, age = yr,
        HT = m4[["TOPHT"]], TPH = sum(x$expf[lv & x$dbh >= 4]), BAPH = m4[["BA"]], QMD = m4[["QMD"]], SDI = m4[["SDI"]], VOL = m4[["TOTVOL"]],
        MERCHVOL = m4[["MERCHVOL"]], TPH_s = sum(x$expf[lv & x$dbh >= SMD]), BAPH_s = ms[["BA"]], VOL_s = ms[["TOTVOL"]],
        TPH_all = sum(x$expf[lv]), TPH_cohort = sum(x$expf[co]), TPH_ing = sum(x$expf[ig]),
        TPH_cohort_ge25 = sum(x$expf[co & x$dbh >= 25]), DHTM_cohort = wm(x$dht.mult[co], x$expf[co]),
        DHTM_cohort_ge25 = wm(x$dht.mult[co & x$dbh >= 25], x$expf[co & x$dbh >= 25]), DHTM_ing = wm(x$dht.mult[ig], x$expf[ig]),
        nrec = sum(lv), smd = SMD) }
    ok <- tryCatch({ p31_project(cur, p, NYR, rec, tlim = 5400); TRUE }, error = function(e) { cat("p31 FAIL cell", cc$cell, conditionMessage(e), "\n"); FALSE })
    d <- rbindlist(acc); d[, run_ok := as.integer(ok && nrow(d) == NYR + 1L)]; out[[k]] <- d
    cat(sprintf("p31 cell %s done ok=%s rows=%d secs=%.0f\n", cc$cell, ok, nrow(d), as.numeric(difftime(Sys.time(), t0, units = "secs")))) }
  fwrite(rbindlist(out), P31_OUT); cat("p31 grid WROTE", P31_OUT, "\n")
}
if (V141 && exists(".acd_v141_report")) { .rep <- .acd_v141_report(); cat("v141 overlay counters:\n"); print(.rep) }
cat("DONE\n")

if (P31_MODE == "slgrid") {
  ## PREREG44: measured qc_c t1 stand lists. P44_STANDS is a CSV (STAND, cell, esi_bin, sdi_bin); each stand starts from its
  ## own t1 tree list, built exactly as mode g0 builds it, and is projected P31_NYR annual steps with the mode grid recorder
  ## (same columns, plus STAND, esi_bin and sdi_bin; mix is OBS, esi is the stand's csi_site, n0 its t1 stems of all sizes).
  sl <- fread(Sys.getenv("P44_STANDS"), colClasses = list(character = "STAND")); NYR <- as.integer(Sys.getenv("P31_NYR", "100"))
  SMD <- as.numeric(Sys.getenv("P31_SMD")); if (!is.finite(SMD)) stop("p44 slgrid: P31_SMD (the scoring threshold for the _s metrics) must be set")
  setDT(prs); out <- list(); wm <- function(v, w) if (sum(w) > 0) sum(v*w)/sum(w) else NA_real_
  for (k in seq_len(nrow(sl))) { sid <- sl$STAND[k]; t0 <- Sys.time()
    p <- as.list(prs[STAND == sid]); if (length(p$STAND) != 1L) stop("p44 slgrid: stand not admitted once: ", sid)
    it <- ti[.(sid)]; if (nrow(it) < 1L) stop("p44 slgrid: no t1 trees for ", sid)
    cur <- data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=p31_dht(p, it),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
    n0 <- sum(it$EXPF); acc <- list()
    rec <- function(x, yr, n_init) { lv <- is.finite(x$dbh) & is.finite(x$expf) & x$expf > 0; co <- lv & x$tree <= n_init; ig <- lv & x$tree > n_init
      m4 <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = 4); ms <- metrics(x$sp, x$dbh, x$ht, x$expf, x$form, x$risk, mindbh = SMD)
      acc[[length(acc) + 1L]] <<- data.table(arm = P31_ARM, cell = sl$cell[k], mix = "OBS", esi = p$csi_site, n0 = n0, age = yr,
        HT = m4[["TOPHT"]], TPH = sum(x$expf[lv & x$dbh >= 4]), BAPH = m4[["BA"]], QMD = m4[["QMD"]], SDI = m4[["SDI"]], VOL = m4[["TOTVOL"]],
        MERCHVOL = m4[["MERCHVOL"]], TPH_s = sum(x$expf[lv & x$dbh >= SMD]), BAPH_s = ms[["BA"]], VOL_s = ms[["TOTVOL"]],
        TPH_all = sum(x$expf[lv]), TPH_cohort = sum(x$expf[co]), TPH_ing = sum(x$expf[ig]),
        TPH_cohort_ge25 = sum(x$expf[co & x$dbh >= 25]), DHTM_cohort = wm(x$dht.mult[co], x$expf[co]),
        DHTM_cohort_ge25 = wm(x$dht.mult[co & x$dbh >= 25], x$expf[co & x$dbh >= 25]), DHTM_ing = wm(x$dht.mult[ig], x$expf[ig]),
        nrec = sum(lv), smd = SMD, STAND = sid, esi_bin = sl$esi_bin[k], sdi_bin = sl$sdi_bin[k]) }
    ok <- tryCatch({ p31_project(cur, p, NYR, rec, tlim = 5400); TRUE }, error = function(e) { cat("p44 FAIL stand", sl$cell[k], conditionMessage(e), "\n"); FALSE })
    d <- rbindlist(acc); d[, run_ok := as.integer(ok && nrow(d) == NYR + 1L)]; out[[k]] <- d
    cat(sprintf("p44 stand %s done ok=%s rows=%d secs=%.0f\n", sl$cell[k], ok, nrow(d), as.numeric(difftime(Sys.time(), t0, units = "secs")))) }
  fwrite(rbindlist(out), P31_OUT); cat("p44 slgrid WROTE", P31_OUT, "\n")
} else if (P31_MODE == "g0") {

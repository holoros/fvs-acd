## ==== PREREG37 BLOCK (replaces runner lines 420 to 486) ===========================================================
## One engine year per listed stand from its t1 state, QC_AFAC = 1, with a recorder around calc_dht (the original is
## called unchanged). Writes the recorded calc_dht inputs and output per tree (SERVERONLY, identifiers) and dht.spp.
P37_OUT <- Sys.getenv("P37_OUT"); P37_STANDS <- Sys.getenv("P37_STANDS"); P37_SPP <- Sys.getenv("P37_SPP")
if (!nzchar(P37_OUT) || file.exists(P37_OUT)) stop("p37: P37_OUT unset or exists: ", P37_OUT)
if (!isTRUE(QC_AFAC == 1) || any(nzchar(Sys.getenv(c("QC_AFAC_SMALL","QC_AFAC_LARGE","QC_AFAC_KNOT"))))) stop("p37: QC_AFAC must be 1 with SMALL/LARGE/KNOT unset")
P37_DHT_EXPR
.p37_cd0 <- calc_dht; .p37_cap <- list()
calc_dht <- function(tree.data, plot.data, ...) {
  o <- .p37_cd0(tree.data, plot.data, ...)
  .p37_cap[[length(.p37_cap) + 1L]] <<- data.table::data.table(tree = tree.data$tree, sp = tree.data$sp, dbh = tree.data$dbh, ht = tree.data$ht,
    cr = tree.data$cr, ccfl = tree.data$ccfl, expf = tree.data$expf, dht_mult = tree.data$dht.mult, max_height = tree.data$max.height,
    csi = stand$csi, dht_out = o$dht)
  o }
if (nzchar(P37_SPP) && !file.exists(P37_SPP)) fwrite(as.data.table(dht.spp), P37_SPP)
keep <- fread(P37_STANDS)$STAND; setDT(prs); rows <- list(); nfail <- 0L
for (sid in keep) {
  p <- as.list(prs[STAND == sid]); if (length(p$STAND) != 1L) { cat("p37 not admitted once:", sid, "\n"); nfail <- nfail + 1L; next }
  it <- ti[.(sid)]; iv <- max(1, round(p$interval_years)); elev <- if (is.finite(p$ELEV) && p$ELEV > 0) p$ELEV else 200
  cur <- data.frame(year=0,plot=1L,tree=seq_len(nrow(it)),sp=mapsp(it$SP),dbh=it$DBH,ht=ifelse(is.finite(it$HT)&it$HT>0,it$HT,NA_real_),hcb=NA,cr=NA,expf=it$EXPF,form=NA_character_,risk=NA_character_,ddbh.mult=1,dht.mult=p31_dht(p, it),mort.mult=1,max.dbh=200,max.height=50,stringsAsFactors=FALSE)
  if (SPLIT) { cur <- split_formrisk(cur) }
  csi_use <- if (is.finite(p$csi_site) && p$csi_site > 2) p$csi_site else CSI_DEFAULT
  reg <- if (p$PROV == "NB") "NB" else if (p$PROV == "QC") "QC" else if (p$PROV == "NS") "NS" else "ME"
  stand <<- make_stand(stand.id = sid, csi = csi_use, elev = elev, region = reg)
  ops$stand.managed <- as.logical(p$MGD_USE)
  .tst0 <<- { v <- suppressWarnings(as.numeric(p$TST_RAW)); if (length(v) != 1L || !is.finite(v)) NA_real_ else v }
  ops$stand.tst <- .tst0
  ops$active_ecobucket <- ecobucket_lookup[STAND == GYR_alias(p, sid), gate3][1]
  cur <- htfx(cur, p); .p37_cap <- list()
  setTimeLimit(elapsed = 120, transient = TRUE)
  nx <- tryCatch(AcadianGYOneStand(tree = cur, stand = stand, ops = ops), error = function(e) { cat("p37 FAIL", sid, conditionMessage(e), "\n"); NULL })
  setTimeLimit()
  if (is.null(nx) || length(.p37_cap) != 1L) { cat("p37 skip", sid, "calls", length(.p37_cap), "\n"); nfail <- nfail + 1L; next }
  cp <- .p37_cap[[1]]; cp[, `:=`(STAND = sid, iv = iv, n_init = nrow(it))]; rows[[sid]] <- cp
}
fwrite(rbindlist(rows), P37_OUT); cat(sprintf("p37 WROTE %s stands=%d failed=%d rows=%d\n", P37_OUT, length(rows), nfail, sum(sapply(rows, nrow))))
cat("DONE\n")

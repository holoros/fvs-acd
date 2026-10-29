
## ==== HD FX BLOCK (2026-10-28, Howland decline diagnostic for 14.3) ===================================
## Appended to a byte-identical copy of the frozen long200 trajectory hooks
## (2026-10-16_acdx_long200_trajhooks.R). Wraps PD_init, PD_step, PD_finish and PD_write: each wrapper
## first calls the frozen function, unchanged, and then records per year aboveground biomass fluxes in a
## separate environment FX. The block only READS the engine tree lists; it never modifies cur, nx, stand,
## ops or PD, and it uses no random numbers, so the projection and every frozen output are unchanged.
## Biomass per stem is the runner's own nsvb(DRYBIO_AG) * LB_KG / 1000 (Mg per stem, times expf gives
## Mg ha-1) on stems at or above the scoring threshold PD$smd, the same definition metrics() uses, so for
## every year B_END - B_START = G_INIT + G_REC - M_INIT - M_REC + I holds exactly, and B_END at the 5 yr
## snapshots must equal the trajectory BIOMASS column (gate H2 of the 28 October pre-registration).
##   G_INIT, G_REC  survivor growth of the initial cohort and of earlier recruits: e2 (b2 l2 - b1 l1)
##   M_INIT, M_REC  mortality: (e1 - e2) b1 l1, stems or expansion lost during the year
##   I              ingrowth: biomass of stems new this year that are at or above the threshold
## No coordinates. No em dashes.
FX <- new.env(); FX$rows <- list(); FX$cur_rows <- list()
FX_bio <- function(sp, dbh, ht) { b <- nsvb(sp, dbh, ht, "DRYBIO_AG") * LB_KG / 1000; b[!is.finite(b)] <- 0; b }
.PD_init_frozen <- PD_init; .PD_step_frozen <- PD_step; .PD_finish_frozen <- PD_finish; .PD_write_frozen <- PD_write
PD_init <- function(cur, p) { .PD_init_frozen(cur, p); FX$cur_rows <- list(); invisible(NULL) }
PD_step <- function(cur, nx, yr) {
  .PD_step_frozen(cur, nx, yr)
  S <- PD$smd; n0 <- PD$n_init
  e1 <- cur$expf; e1[!is.finite(e1)] <- 0
  l1 <- is.finite(cur$dbh) & cur$dbh >= S & e1 > 0
  b1 <- FX_bio(cur$sp, cur$dbh, cur$ht)
  m <- match(cur$tree, nx$tree); hit <- !is.na(m)
  e2 <- rep(0, length(m)); e2[hit] <- nx$expf[m[hit]]; e2[!is.finite(e2)] <- 0
  d2 <- rep(NA_real_, length(m)); d2[hit] <- nx$dbh[m[hit]]
  l2 <- hit & is.finite(d2) & d2 >= S & e2 > 0
  b2 <- rep(0, length(m)); if (any(hit)) b2[hit] <- FX_bio(nx$sp[m[hit]], d2[hit], nx$ht[m[hit]])
  rec <- cur$tree > n0
  g <- e2 * (b2 * l2) - e2 * (b1 * l1)
  mo <- (e1 - e2) * b1 * l1
  isnew <- !(nx$tree %in% cur$tree)
  bi <- 0
  if (any(isnew)) { en <- nx$expf[isnew]; en[!is.finite(en)] <- 0
    ln <- is.finite(nx$dbh[isnew]) & nx$dbh[isnew] >= S & en > 0
    bi <- sum(en * FX_bio(nx$sp[isnew], nx$dbh[isnew], nx$ht[isnew]) * ln) }
  e3 <- nx$expf; e3[!is.finite(e3)] <- 0
  l3 <- is.finite(nx$dbh) & nx$dbh >= S & e3 > 0
  FX$cur_rows[[length(FX$cur_rows) + 1L]] <- c(yr = yr, B_START = sum(e1 * b1 * l1),
    B_END = sum(e3 * FX_bio(nx$sp, nx$dbh, nx$ht) * l3),
    G_INIT = sum(g[!rec]), G_REC = sum(g[rec]), M_INIT = sum(mo[!rec]), M_REC = sum(mo[rec]), I = bi,
    N_NEGMORT = sum(l1 & e2 > e1 + 1e-12), N_DUPTREE = sum(duplicated(nx$tree)) + sum(duplicated(cur$tree)))
  invisible(NULL)
}
PD_finish <- function(sid, p, iv, res) {
  .PD_finish_frozen(sid, p, iv, res)
  if (length(FX$cur_rows)) FX$rows[[length(FX$rows) + 1L]] <- data.table::data.table(STAND = sid, iv = iv, SMD = PD$smd,
    data.table::as.data.table(do.call(rbind, FX$cur_rows)))
  FX$cur_rows <- list(); invisible(NULL)
}
PD_write <- function(prefix) {
  .PD_write_frozen(prefix)
  data.table::fwrite(data.table::rbindlist(FX$rows, fill = TRUE), paste0(prefix, "_flux.csv"))
  cat(sprintf("HDFX wrote %s_flux.csv for %d stands\n", prefix, length(FX$rows)))
}
## ==== END HD FX BLOCK ===================================================================================

## 2026-09-16_gydbreg-phaseD_trajhooks.R
## Phase D recording hooks, sourced by the Phase D runner copies after metrics(), nsvb() and GYR_smd()
## exist. The hooks only READ the engine tree lists; they never modify cur, nx, stand or ops, and
## they use no random numbers, so the projection is unchanged. Inside the timed projection they do
## vectorised bookkeeping only (per-year mortality and recruitment fluxes, 5-yr snapshots by
## reference); all metric computation happens in PD_finish(), after setTimeLimit() is cleared.
##   PD_init(cur, p)          after split_formrisk() and n_init: stores the t1 (split) list
##   PD_step(cur, nx, yr)     each year, before bf(): mortality, recruitment and threshold-crossing fluxes
##   PD_snap(cur, yr, iv)     each year, after bf(): keeps the list every 5 yr and at the last year
##   PD_finish(sid, p, iv, res) after a successful stand: builds trajectory rows, keeps t1 and t2 lists
##   PD_write(prefix)         end of run: <prefix>_traj.csv, <prefix>_pd_t1.csv, <prefix>_pd_t2.csv
## Units: stems ha^-1, m^2 ha^-1, m^3 ha^-1. No coordinates. No em dashes.
PD <- new.env()
PD$rows <- list(); PD$t1 <- list(); PD$t2 <- list()
PD_ba <- function(d) pi * (d / 200)^2
PD_init <- function(cur, p) {
  PD$smd <- GYR_smd(p); PD$n_init <- max(cur$tree)
  PD$t0 <- as.data.frame(cur)[, c("tree","sp","dbh","ht","expf")]
  PD$acc <- c(MORT_N_ALL = 0, MORT_BA_ALL = 0, MORT_N_S = 0, MORT_BA_S = 0, MORT_V_S = 0,
              MORT_N_S_REC = 0, MORT_V_S_REC = 0,
              REC_N = 0, REC_BA = 0, CROSS_N_INIT = 0, CROSS_N_REC = 0, CROSS_BA_INIT = 0, CROSS_BA_REC = 0,
              CROSS_V_INIT = 0, CROSS_V_REC = 0)
  PD$snaps <- list(); PD$snapacc <- list()
  PD$snaps[["0"]] <- PD$t0; PD$snapacc[["0"]] <- PD$acc
  invisible(NULL)
}
PD_step <- function(cur, nx, yr) {
  S <- PD$smd
  m <- match(cur$tree, nx$tree)
  e2 <- nx$expf[m]; e2[is.na(e2)] <- 0
  died <- pmax(cur$expf - e2, 0); died[!is.finite(died)] <- 0
  b1 <- PD_ba(cur$dbh); b1[!is.finite(b1)] <- 0
  big <- is.finite(cur$dbh) & cur$dbh >= S
  rec <- cur$tree > PD$n_init
  a <- PD$acc
  a["MORT_N_ALL"] <- a["MORT_N_ALL"] + sum(died)
  a["MORT_BA_ALL"] <- a["MORT_BA_ALL"] + sum(died * b1)
  k <- which(big & died > 0)
  if (length(k)) {
    v <- nsvb(cur$sp[k], cur$dbh[k], cur$ht[k], "VOLCFGRS") * FT3_M3
    a["MORT_N_S"] <- a["MORT_N_S"] + sum(died[k]); a["MORT_BA_S"] <- a["MORT_BA_S"] + sum(died[k] * b1[k])
    a["MORT_V_S"] <- a["MORT_V_S"] + sum(died[k] * v)
    kr <- rec[k]
    a["MORT_N_S_REC"] <- a["MORT_N_S_REC"] + sum(died[k][kr]); a["MORT_V_S_REC"] <- a["MORT_V_S_REC"] + sum((died[k] * v)[kr])
  }
  isnew <- !(nx$tree %in% cur$tree)
  if (any(isnew)) {
    a["REC_N"] <- a["REC_N"] + sum(nx$expf[isnew]); a["REC_BA"] <- a["REC_BA"] + sum(nx$expf[isnew] * PD_ba(nx$dbh[isnew]), na.rm = TRUE)
  }
  ## threshold crossings: survivors below S that end the year at or above S, and recruits entering at or above S
  d2 <- nx$dbh[m]
  cr <- !is.na(m) & is.finite(cur$dbh) & cur$dbh < S & is.finite(d2) & d2 >= S & e2 > 0
  nw <- isnew & is.finite(nx$dbh) & nx$dbh >= S
  if (any(cr) || any(nw)) {
    tr <- c(cur$tree[cr], nx$tree[nw]); ee <- c(e2[cr], nx$expf[nw]); dd <- c(d2[cr], nx$dbh[nw])
    hh <- c(nx$ht[m][cr], nx$ht[nw]); ss <- c(nx$sp[m][cr], nx$sp[nw])
    vv <- nsvb(ss, dd, hh, "VOLCFGRS") * FT3_M3
    ri <- tr > PD$n_init
    a["CROSS_N_INIT"] <- a["CROSS_N_INIT"] + sum(ee[!ri]); a["CROSS_N_REC"] <- a["CROSS_N_REC"] + sum(ee[ri])
    a["CROSS_BA_INIT"] <- a["CROSS_BA_INIT"] + sum((ee * PD_ba(dd))[!ri]); a["CROSS_BA_REC"] <- a["CROSS_BA_REC"] + sum((ee * PD_ba(dd))[ri])
    a["CROSS_V_INIT"] <- a["CROSS_V_INIT"] + sum((ee * vv)[!ri]); a["CROSS_V_REC"] <- a["CROSS_V_REC"] + sum((ee * vv)[ri])
  }
  PD$acc <- a
  invisible(NULL)
}
PD_snap <- function(cur, yr, iv) {
  if (yr %% 5L == 0L || yr == iv) {
    PD$snaps[[as.character(yr)]] <- as.data.frame(cur)[, c("tree","sp","dbh","ht","expf")]
    PD$snapacc[[as.character(yr)]] <- PD$acc
  }
  invisible(NULL)
}
PD_finish <- function(sid, p, iv, res) {
  S <- PD$smd
  rows <- lapply(names(PD$snaps), function(y) {
    x <- PD$snaps[[y]]
    mm <- metrics(x$sp, x$dbh, x$ht, x$expf, mindbh = S)
    live <- is.finite(x$dbh) & x$dbh >= S & is.finite(x$expf) & x$expf > 0
    rc <- x$tree > PD$n_init
    vol <- if (any(live & rc)) sum(nsvb(x$sp[live & rc], x$dbh[live & rc], x$ht[live & rc], "VOLCFGRS") * x$expf[live & rc]) * FT3_M3 else 0
    data.table::data.table(STAND = sid, iv = iv, yr = as.integer(y), SMD = S,
      TPH = sum(x$expf[live]), BA = mm[["BA"]], QMD = mm[["QMD"]], TOPHT = mm[["TOPHT"]], TOTVOL = mm[["TOTVOL"]], SDI = mm[["SDI"]], BIOMASS = mm[["BIOMASS"]], MERCHVOL = mm[["MERCHVOL"]],
      N_ALL = sum(x$expf[is.finite(x$expf)]), REC_LIVE_N_S = sum(x$expf[live & rc]), REC_LIVE_BA_S = sum((x$expf * PD_ba(x$dbh))[live & rc]),
      REC_LIVE_V_S = vol, REC_LIVE_N_SUB = sum(x$expf[rc & !live & is.finite(x$dbh)]),
      t(PD$snapacc[[y]]))
  })
  PD$rows[[length(PD$rows) + 1L]] <- data.table::rbindlist(rows)
  PD$t1[[length(PD$t1) + 1L]] <- data.table::data.table(STAND = sid, n_init = PD$n_init, PD$t0)
  PD$t2[[length(PD$t2) + 1L]] <- data.table::data.table(STAND = sid, n_init = PD$n_init, as.data.frame(res)[, c("tree","sp","dbh","ht","expf")])
  invisible(NULL)
}
PD_write <- function(prefix) {
  data.table::fwrite(data.table::rbindlist(PD$rows, fill = TRUE), paste0(prefix, "_traj.csv"))
  data.table::fwrite(data.table::rbindlist(PD$t1), paste0(prefix, "_pd_t1.csv"))
  data.table::fwrite(data.table::rbindlist(PD$t2), paste0(prefix, "_pd_t2.csv"))
  cat(sprintf("PHASED wrote %s_{traj,pd_t1,pd_t2}.csv for %d stands\n", prefix, length(PD$rows)))
}

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

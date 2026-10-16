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

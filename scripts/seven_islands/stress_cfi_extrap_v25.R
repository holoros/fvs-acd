#!/usr/bin/env Rscript
# stress_cfi_extrap_v25.R
# v25 extrapolation/domain stress test for the two new full-coverage candidate
# models, FVSACD_v1211_full and FVSACD_v131_full. Companion to stress_cfi_site.R /
# stress_cfi_horizon.R / stress_cfi_climate.R (same repo, same house convention:
# source the real driver's model infra, run a synthetic-stand battery, write a
# scored CSV, print a summary) but targeted at density (SDI), site index, and
# species-mix EXTREMES plus a headline bootstrap CI, rather than routine
# site-driver sensitivity at the observed range.
#
# Long-horizon (100+ yr) extrapolation is deliberately NOT duplicated here.
# bakuzis_v1211_full_v25_traj.csv / bakuzis_v131_full_v25_traj.csv (in
# ~/silc_cfi) already project to age 160 at sites 12/16/20; this script does
# not re-run that machinery. Its flags are folded into the combined verdict
# by hand from bakuzis_v{1211,131}_full_v25_check.txt.
#
# Reuses the model setup EXACTLY as coded in the real v25 full137 driver
# (species maps, ops, NSVB emulator, AcadianGYOneStand call convention) by
# sourcing the driver script with NMAX=1 (one real throwaway stand so the
# driver's own post-loop summary code does not error on an empty result;
# CONFIG_TAG/TREE_OUT_PATH both point at /tmp so no real output is touched),
# then running its OWN per-stand loop over synthetic density/site/species-
# extreme stands built from the same 120-stand full137 init trees.
#
# SAFETY: v1 of this script (first full run, killed after 14+ min with v131
# RSS climbing past 300MB and still in the density-extreme loop) hit a real
# performance/behavior issue at the high-SDI extreme: sustained ingrowth
# (IGMULT=2.5 for v1211; hierarchical ingrowth posterior for v131) with no
# apparent density-based ingrowth shutoff let the per-stand tree list grow
# essentially unbounded over 30 annual steps, which is itself a stress-test
# finding, not just a runtime problem. This version (a) caps N_YEARS at 20 (b)
# hard-caps live tree count per stand at MAX_TREES=4000 and RECORDS an
# "ingrowth_explosion" flag + the tree count at cutoff instead of running
# forever (c) wraps each annual step in setTimeLimit like the real driver does
# (d) prints per-stand progress so a stall is visible in the log rather than
# silent.
#
# Run once per model: STRESS_MODEL=v1211|v131 Rscript stress_cfi_extrap_v25.R
# SMOKE=1 restricts to 3 stands x 3 years for a fast correctness check.

.libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
suppressMessages(library(data.table))
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

STRESS_MODEL <- Sys.getenv("STRESS_MODEL","v1211")
stopifnot(STRESS_MODEL %in% c("v1211","v131"))
SMOKE <- identical(Sys.getenv("SMOKE"),"1")
OUTDIR <- "/users/PUOM0008/crsfaaron/silc_cfi"
MAX_TREES <- 4000L

if (STRESS_MODEL == "v1211") {
  Sys.setenv(MODEL_FILE="/users/PUOM0008/crsfaaron/_scripts/AcadianGY_12.11.r",
             SPLIT="TRUE", V1211_IGMULT="2.5", V1211_MORTGATE="TRUE", V1211_STANDCON="TRUE",
             SC_LO="0.40", SC_HI="0.50", SC_QMIN="22", V1211_DHTHW="TRUE", V1211_MANAGED="TRUE",
             ONSET="0.30",BREAK="0.62",BG="0.020",BS="0.80",IRC="0.58",IRK="8",SDMAX="1.0",
             USE_BRMS="TRUE",USE_ANCHOR="TRUE",NB_BREAK="0.70",QC_BREAK="0.62",
             NB_AFAC="0.579",QC_AFAC="0.111",INDOMAIN="1",
             CONFIG_TAG="stress_throwaway_v1211", TREE_OUT_PATH="/tmp/stress_throwaway_v1211_treeout.csv",
             PAIRS_FILE="multisrc/bench_silc_l_pairs_full137.csv",
             INIT_FILE="multisrc/bench_silc_l_tree_init_full137.csv",
             T2_FILE="multisrc/bench_silc_l_tree_t2_full137.csv",
             SITE_FILE="multisrc/bench_silc_l_site_esi_full137.csv",
             NMAX="1")
  DRIVER <- "bench_parity_split_ms_v1211_silc_treeout.R"
  INGEST_TREELIST <- "/users/PUOM0008/crsfaaron/silc_cfi/v25_inputs/fvsacd_v1211_full137_treelist.csv"
} else {
  Sys.setenv(MODEL_FILE="/users/PUOM0008/crsfaaron/AcadianGY_13.1.r",
             USE_HIER_ING="TRUE", USE_HIER_MORT="TRUE", HIER_POSTDIR="/users/PUOM0008/crsfaaron/v13_comb_post",
             SPLIT="TRUE", ONSET="0.30",BREAK="0.62",BG="0.020",BS="0.80",IRC="0.58",IRK="8",SDMAX="1.0",
             USE_BRMS="TRUE",USE_ANCHOR="TRUE",NB_BREAK="0.70",QC_BREAK="0.62",
             NB_AFAC="0.579",QC_AFAC="0.111",INDOMAIN="1",
             CONFIG_TAG="stress_throwaway_v131", TREE_OUT_PATH="/tmp/stress_throwaway_v131_treeout.csv",
             PAIRS_FILE="multisrc/bench_silc_l_pairs_full137.csv",
             INIT_FILE="multisrc/bench_silc_l_tree_init_full137.csv",
             T2_FILE="multisrc/bench_silc_l_tree_t2_full137.csv",
             SITE_FILE="multisrc/bench_silc_l_site_esi_full137.csv",
             NMAX="1")
  DRIVER <- "bench_parity_split_ms_v131_silc_treeout.R"
  INGEST_TREELIST <- "/users/PUOM0008/crsfaaron/silc_cfi/v25_inputs/fvsacd_v131_full137_treelist.csv"
}

cat(sprintf("=== stress_cfi_extrap_v25 [%s]: sourcing %s (NMAX=1, throwaway TAG) to load model infra ===\n", STRESS_MODEL, DRIVER))
source(DRIVER)
cat("=== model infra loaded (ops, AcadianGYOneStand, mapsp, ecobucket_lookup) ===\n")
stopifnot(exists("ops"), exists("mapsp"), exists("ecobucket_lookup"))
if (!exists("AcadianGYOneStand")) stop("AcadianGYOneStand not found in global env after sourcing model file")

stress_metrics <- function(dbh, ht, expf) {
  live <- is.finite(dbh) & dbh>=4 & is.finite(expf) & expf>0
  dbh<-dbh[live]; ht<-ht[live]; expf<-expf[live]
  if (!length(dbh)) return(c(BA=0,TPH=0,QMD=0,SDI=0,n_neg_dbh=0,n_nan=0,n_trees=0))
  BA<-sum(pi*(dbh/200)^2*expf); TPH<-sum(expf)
  QMD<-if(TPH>0) sqrt((BA/TPH)/(pi/40000)) else NA_real_
  SDI<-if(is.finite(QMD)) TPH*(QMD/25.0)^1.605 else NA_real_
  c(BA=BA,TPH=TPH,QMD=QMD,SDI=SDI,n_neg_dbh=sum(dbh<0),n_nan=sum(!is.finite(dbh)),n_trees=length(dbh))
}

ti_all  <- fread("multisrc/bench_silc_l_tree_init_full137.csv")
pr_all  <- fread("multisrc/bench_silc_l_pairs_full137.csv")
esi_all <- fread("multisrc/bench_silc_l_site_esi_full137.csv")
pr_all  <- merge(pr_all, esi_all, by="SITE", all.x=TRUE)

ingested_stands <- unique(fread(INGEST_TREELIST)$STAND)
pr <- pr_all[STAND %in% ingested_stands]
stands <- unique(pr$STAND)
if (SMOKE) stands <- head(stands, 3)
SUBSET_N <- as.integer(Sys.getenv("SUBSET_N","0"))
if (SUBSET_N > 0 && SUBSET_N < length(stands)) {
  set.seed(20260812)
  stands <- sort(sample(stands, SUBSET_N))
  cat(sprintf("SUBSET_N=%d: using a random subsample of %d of the %d full137 stands (reproducible seed 20260812) -- invoked because the v131 hierarchical-posterior model does not terminate within a practical per-step timeout at the high-SDI extreme across the full 120-stand grid; see the timed_out column in the output CSVs.\n", SUBSET_N, length(stands), length(ingested_stands)))
}
cat(sprintf("full137 stands available for stress test: %d%s\n", length(stands), if(SMOKE) " (SMOKE mode)" else ""))

run_stand <- function(sid, dbh0, ht0, sp0, expf0, csi_use, n_years) {
  cur <- data.frame(year=0, plot=1L, tree=seq_len(length(dbh0)), sp=mapsp(sp0), dbh=dbh0,
    ht=ifelse(is.finite(ht0)&ht0>0, ht0, NA_real_), hcb=NA, cr=NA, expf=expf0,
    form=NA_character_, risk=NA_character_, ddbh.mult=1, dht.mult=1, mort.mult=1,
    max.dbh=200, max.height=50, stringsAsFactors=FALSE)
  stand_i <- make_stand(stand.id=sid, csi=csi_use, elev=200, region="ME")
  ops$active_ecobucket <- ecobucket_lookup[STAND==sid, gate3][1]
  traj <- list()
  m0 <- stress_metrics(cur$dbh, cur$ht, cur$expf)
  traj[["0"]] <- as.data.table(as.list(c(year=0, m0)))
  exploded <- FALSE
  for (yr in seq_len(n_years)) {
    # OS-level forked timeout (setTimeLimit alone does not reliably interrupt a
    # long-running call inside compiled/vectorized model code -- confirmed on
    # the v131 hierarchical-posterior model at the 1.5x-max-SDI extreme, which
    # hung past 5 minutes wall-clock on a single call with setTimeLimit(45)
    # in place and never returned). parallel::mcparallel forks a real child
    # process that tools::pskill can hard-kill on timeout, which does work.
    job <- parallel::mcparallel({ AcadianGYOneStand(tree=cur, stand=stand_i, ops=ops) })
    res <- tryCatch(parallel::mccollect(job, wait=FALSE, timeout=20), error=function(e) NULL)
    if (is.null(res) || length(res)==0) {
      tools::pskill(job$pid, tools::SIGKILL)
      parallel::mccollect(job, wait=FALSE)
      return(list(ok=FALSE, traj=rbindlist(traj,fill=TRUE), fail_year=yr, exploded=exploded, timed_out=TRUE))
    }
    nx <- res[[1]]
    if (inherits(nx, "try-error") || is.null(nx)) nx <- NULL
    if (is.null(nx) || !is.data.frame(nx) || nrow(nx)==0) return(list(ok=FALSE, traj=rbindlist(traj,fill=TRUE), fail_year=yr, exploded=exploded, timed_out=FALSE))
    for (cc in c("ddbh.mult","dht.mult","mort.mult")) if (cc %in% names(nx)) nx[[cc]][is.na(nx[[cc]])] <- 1
    if ("max.dbh" %in% names(nx)) nx$max.dbh[is.na(nx$max.dbh)] <- 200
    if ("max.height" %in% names(nx)) nx$max.height[is.na(nx$max.height)] <- 50
    cur <- nx
    m <- stress_metrics(cur$dbh, cur$ht, cur$expf)
    traj[[as.character(yr)]] <- as.data.table(as.list(c(year=yr, m)))
    if (nrow(cur) > MAX_TREES) { exploded <- TRUE; return(list(ok=TRUE, traj=rbindlist(traj,fill=TRUE), fail_year=NA_integer_, exploded=TRUE, timed_out=FALSE)) }
  }
  list(ok=TRUE, traj=rbindlist(traj, fill=TRUE), fail_year=NA_integer_, exploded=exploded, timed_out=FALSE)
}

N_YEARS <- if (SMOKE) 3 else 20

cat("\n--- 1. density/SDI extremes ---\n")
base_sdi <- sapply(stands, function(sid) {
  tt <- ti_all[STAND==sid]; if(nrow(tt)<3) return(NA_real_)
  unname(stress_metrics(tt$DBH, tt$HT, tt$EXPF)["SDI"])
})
base_sdi <- base_sdi[is.finite(base_sdi) & base_sdi>0]
sdi_min <- min(base_sdi); sdi_max <- max(base_sdi)
target_low  <- 0.5*sdi_min; target_high <- 1.5*sdi_max
cat(sprintf("observed SDI range across %d stands: %.1f - %.1f | targets: low=%.1f (0.5x min) high=%.1f (1.5x max)\n",
  length(base_sdi), sdi_min, sdi_max, target_low, target_high))

density_res <- list()
t_start <- Sys.time()
i_prog <- 0
for (sid in stands) {
  i_prog <- i_prog + 1
  tt <- ti_all[STAND==sid]; if(nrow(tt)<3) next
  csi0 <- pr[STAND==sid, esi8][1]; csi0 <- if(is.finite(csi0)&&csi0>2) csi0 else 14
  sdi0 <- unname(stress_metrics(tt$DBH, tt$HT, tt$EXPF)["SDI"]); if(!is.finite(sdi0)||sdi0<=0) next
  f_low  <- target_low  / sdi0
  f_high <- target_high / sdi0
  for (scen in c("low","high")) {
    f <- if (scen=="low") f_low else f_high
    r <- run_stand(sid, tt$DBH, tt$HT, tt$SP, tt$EXPF*f, csi0, N_YEARS)
    tr <- r$traj; tr[, `:=`(STAND=sid, scenario=scen, ok=r$ok, fail_year=r$fail_year, exploded=r$exploded, timed_out=isTRUE(r$timed_out),
                             sdi0=sdi0, sdi_target=if(scen=="low") target_low else target_high)]
    density_res[[paste(sid,scen)]] <- tr
  }
  if (i_prog %% 20 == 0) cat(sprintf("  density loop: %d/%d stands done (%.1f sec elapsed)\n",
    i_prog, length(stands), as.numeric(difftime(Sys.time(), t_start, units="secs"))))
}
density_dt <- rbindlist(density_res, fill=TRUE)
fwrite(density_dt, sprintf("%s/stress_extrap_density_%s.csv", OUTDIR, STRESS_MODEL))
cat(sprintf("density loop done: %.1f sec, %d stands with ingrowth_explosion (>%.0f trees)\n",
  as.numeric(difftime(Sys.time(), t_start, units="secs")),
  uniqueN(density_dt[exploded==TRUE, STAND]), MAX_TREES))

cat("\n--- 2. site index extremes ---\n")
esi_obs <- pr$esi8[is.finite(pr$esi8) & pr$esi8>2]
esi_min <- min(esi_obs); esi_max <- max(esi_obs)
esi_low <- 0.5*esi_min; esi_high <- 1.5*esi_max
cat(sprintf("observed ESI range across %d plots: %.2f - %.2f | targets: low=%.2f (0.5x) high=%.2f (1.5x)\n",
  length(esi_obs), esi_min, esi_max, esi_low, esi_high))

site_res <- list()
t_start2 <- Sys.time(); i_prog <- 0
for (sid in stands) {
  i_prog <- i_prog + 1
  tt <- ti_all[STAND==sid]; if(nrow(tt)<3) next
  for (scen in c("low","high")) {
    csi_use <- if (scen=="low") esi_low else esi_high
    r <- run_stand(sid, tt$DBH, tt$HT, tt$SP, tt$EXPF, csi_use, N_YEARS)
    tr <- r$traj; tr[, `:=`(STAND=sid, scenario=scen, ok=r$ok, fail_year=r$fail_year, exploded=r$exploded, timed_out=isTRUE(r$timed_out), esi_target=csi_use)]
    site_res[[paste(sid,scen)]] <- tr
  }
  if (i_prog %% 20 == 0) cat(sprintf("  site loop: %d/%d stands done (%.1f sec elapsed)\n",
    i_prog, length(stands), as.numeric(difftime(Sys.time(), t_start2, units="secs"))))
}
site_dt <- rbindlist(site_res, fill=TRUE)
fwrite(site_dt, sprintf("%s/stress_extrap_site_%s.csv", OUTDIR, STRESS_MODEL))
cat(sprintf("site loop done: %.1f sec\n", as.numeric(difftime(Sys.time(), t_start2, units="secs"))))

cat("\n--- 3. species-mix extremes (monocultures of underrepresented species) ---\n")
sp_share <- ti_all[, .(expf=sum(EXPF)), by=SP][order(expf)]
minor_sp <- head(sp_share$SP, 2)
cat("minor species chosen for monoculture stress:", paste(minor_sp, collapse=", "), "\n")
template_sid <- stands[1]
tmpl <- ti_all[STAND==template_sid]
species_res <- list()
for (msp in minor_sp) {
  csi0 <- pr[STAND==template_sid, esi8][1]; csi0 <- if(is.finite(csi0)&&csi0>2) csi0 else 14
  r <- run_stand(template_sid, tmpl$DBH, tmpl$HT, rep(msp, nrow(tmpl)), tmpl$EXPF, csi0, N_YEARS)
  tr <- r$traj; tr[, `:=`(STAND=template_sid, species=msp, ok=r$ok, fail_year=r$fail_year, exploded=r$exploded, timed_out=isTRUE(r$timed_out))]
  species_res[[msp]] <- tr
}
species_dt <- rbindlist(species_res, fill=TRUE)
fwrite(species_dt, sprintf("%s/stress_extrap_species_%s.csv", OUTDIR, STRESS_MODEL))

cat("\n--- 4. bootstrap CI: density-HIGH scenario, year-", N_YEARS, " BA growth and TPH decline ---\n", sep="")
dh <- density_dt[scenario=="high"]
d0 <- dh[year==0, .(STAND, BA0=BA, TPH0=TPH)]
dN <- dh[, .SD[which.max(year)], by=STAND][, .(STAND, BAn=BA, TPHn=TPH, ok, exploded, year_reached=year)]
dj <- merge(d0, dN, by="STAND")
dj[, ba_pai := (BAn-BA0)/pmax(year_reached,1)]
dj[, tph_declined := TPHn < TPH0]
uniq_stands <- unique(dj$STAND)
set.seed(20260812)
NBOOT <- if (SMOKE) 200 else 2000
boot_pai <- numeric(NBOOT); boot_mort_frac <- numeric(NBOOT)
for (b in seq_len(NBOOT)) {
  bs <- sample(uniq_stands, length(uniq_stands), replace=TRUE)
  sub2 <- dj[data.table(STAND=bs), on="STAND"]
  boot_pai[b] <- mean(sub2$ba_pai, na.rm=TRUE)
  boot_mort_frac[b] <- mean(sub2$tph_declined, na.rm=TRUE)
}
pai_ci <- quantile(boot_pai, c(0.025,0.5,0.975), na.rm=TRUE)
mort_ci <- quantile(boot_mort_frac, c(0.025,0.5,0.975), na.rm=TRUE)
cat(sprintf("BA PAI at yr %d (or explosion cutoff) under 1.5x-max-SDI synthetic (m2/ha/yr): mean %.3f, boot 95%% CI [%.3f, %.3f] (n=%d stands, %d resamples)\n",
  N_YEARS, mean(dj$ba_pai,na.rm=TRUE), pai_ci[1], pai_ci[3], length(uniq_stands), NBOOT))
cat(sprintf("Fraction of stands showing TPH decline (mortality engaged): mean %.2f, boot 95%% CI [%.2f, %.2f]\n",
  mean(dj$tph_declined,na.rm=TRUE), mort_ci[1], mort_ci[3]))
n_fail <- sum(!dj$ok); n_neg_ba <- sum(dj$BAn < 0, na.rm=TRUE); n_expl <- sum(dj$exploded, na.rm=TRUE)
cat(sprintf("Failures (non-convergent/errored): %d of %d | negative-BA outcomes: %d | ingrowth_explosion (>%.0f trees): %d\n",
  n_fail, nrow(dj), n_neg_ba, MAX_TREES, n_expl))

boot_out <- data.table(model=STRESS_MODEL, metric=c("BA_PAI_m2ha_yr","mortality_engaged_frac"),
  mean=c(mean(dj$ba_pai,na.rm=TRUE), mean(dj$tph_declined,na.rm=TRUE)),
  ci_lo=c(pai_ci[1], mort_ci[1]), ci_hi=c(pai_ci[3], mort_ci[3]),
  ci_type=sprintf("bootstrap percentile, plot-clustered, n=%d",NBOOT), n_stands=length(uniq_stands),
  n_fail=n_fail, n_ingrowth_explosion=n_expl)
fwrite(boot_out, sprintf("%s/stress_extrap_bootstrap_%s.csv", OUTDIR, STRESS_MODEL))

cat(sprintf("\n=== stress_cfi_extrap_v25 [%s] DONE ===\n", STRESS_MODEL))

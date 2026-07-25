# bench_ns_long_scorecard.R -- NS long-interval (first-to-last, principle 14) benchmark
# scorecard: BASE (frozen, no v12.11 levers) vs CANDIDATE v12.11 vs OSM-ACD v2.26.1, stratified by
# interval-length bucket (<15, 15-30, >30 yr), managed (single-regime) vs unmanaged
# (disturbance-screened), and forest group (HW/MW/SW from %HW BA at t1, same convention as
# bench_ns_scorecard.R: SW<25, MW 25-75, HW>75), plus the bucket x managed interaction that is the
# key read on whether the maturity-dependent long-horizon volume pattern seen elsewhere in this
# project shows up in NS.
# THIRD PASS (23 Jul 2026): OSM-ACD v2.26.1 now run on the NS long-interval set via osm_ns_run.py +
# osm_score_ns.R (SRC="ns_long"), same recipe/conventions as bench_ns_scorecard.R's OSM addition
# (Zone=NS native Acadian zone, Management=None for all stands, same NSVB metrics()). First attempt
# (job 12547956 task 2) crashed OSM.ConsoleApp mid-run on regen stems <1cm DBH; osm_ns_run.py now
# drops those rows before ingestion (job 12548192, clean rc=0) -- see osm_ns_run.py header.
# Site input is the Task 1 corrected NS site_esi (raw NS SITE_INDEX/AVGTOPHTM + documented +7.0 m
# ESI v8 raster bias, see build_ns_site_correction.py). Aggregates only leave this script; no raw
# NS coordinates are read or written here.
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4","~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})
setwd("/users/PUOM0008/crsfaaron/magplot/verify")

sp_type <- c(
  AB="HW", AS="HW", BA="HW", BC="HW", BF="SW", BP="HW", BS="SW", BT="HW",
  EC="HW", EH="SW", GA="HW", GB="HW", HH="HW", JP="SW", NS="SW", OH="HW",
  OS="SW", PB="HW", PC="HW", PR="HW", QA="HW", RB="HW", RM="HW", RP="SW",
  RN="SW", RO="HW", RS="SW", SB="HW", SM="HW", ST="HW", TA="SW", WA="HW",
  WC="SW", WP="SW", WS="SW", YB="HW", `99`="HW"
)
FG_SW_MAX <- 25; FG_HW_MIN <- 75
assign_fg <- function(pct_hw) fifelse(is.na(pct_hw), NA_character_,
  fifelse(pct_hw < FG_SW_MAX, "Softwood", fifelse(pct_hw > FG_HW_MIN, "Hardwood", "Mixedwood")))

composition_from_treeinit <- function(path) {
  ti <- fread(path)
  ti[, sp_t := sp_type[SP]]
  ti[is.na(sp_t), sp_t := "SW"]
  ti[, ba := pi * (DBH/200)^2 * EXPF]
  agg <- ti[, .(BA_t1_calc = sum(ba), HW_BA_t1 = sum(ba[sp_t == "HW"])), by = STAND]
  agg[, pct_hw_t1 := 100 * HW_BA_t1 / BA_t1_calc]
  agg[, forest_group := assign_fg(pct_hw_t1)]
  agg[, .(STAND, pct_hw_t1, forest_group)]
}

bias_pct <- function(o,p) 100*(mean(p,na.rm=TRUE)/mean(o,na.rm=TRUE)-1)
rmse_pct <- function(o,p){ rmse<-sqrt(mean((p-o)^2,na.rm=TRUE)); mo<-mean(o,na.rm=TRUE); if(is.finite(mo)&&abs(mo)>1e-9) 100*rmse/mo else NA_real_ }
summ_row <- function(split_dim, split_val, model, d){
  if (is.null(d) || nrow(d)==0) return(NULL)
  data.table(split_dim=split_dim, split_val=split_val, model=model, n=nrow(d),
    interval_mean=round(mean(d$interval_years,na.rm=TRUE),1),
    TOTVOL_bias_pct=round(bias_pct(d$TOTVOL_o,d$TOTVOL_p),2),
    TOTVOL_rmse_pct=round(rmse_pct(d$TOTVOL_o,d$TOTVOL_p),2),
    BA_bias_pct=round(bias_pct(d$BA_o,d$BA_p),2),
    BA_rmse_pct=round(rmse_pct(d$BA_o,d$BA_p),2))
}

pairs <- fread("multisrc/bench_ns_long_pairs.csv")
pairs[, STAND := as.character(STAND)]
pairs[, bucket := fifelse(interval_years < 15, "<15",
                    fifelse(interval_years <= 30, "15-30", ">30"))]
pairs[, bucket := factor(bucket, levels=c("<15","15-30",">30"))]
managed_lookup <- setNames(pairs$MANAGED, pairs$STAND)
bucket_lookup  <- setNames(as.character(pairs$bucket), pairs$STAND)
ptype_lookup   <- setNames(pairs$PAIR_TYPE, pairs$STAND)
interval_lookup <- setNames(pairs$interval_years, pairs$STAND)

comp <- composition_from_treeinit("multisrc/bench_ns_long_tree_init.csv")

base_u <- fread("ns_long_base_unmanaged_results.csv"); base_u[, STAND := as.character(STAND)]
cand_u <- fread("ns_long_cand_unmanaged_results.csv"); cand_u[, STAND := as.character(STAND)]
base_m <- fread("ns_long_base_managed_results.csv");   base_m[, STAND := as.character(STAND)]
cand_m <- fread("ns_long_cand_managed_results.csv");   cand_m[, STAND := as.character(STAND)]
base <- rbindlist(list(base_u, base_m), fill=TRUE)
cand <- rbindlist(list(cand_u, cand_m), fill=TRUE)
osm  <- fread("osm_score_ns_long_results.csv"); osm[, STAND := as.character(STAND)]

for (dt in list(base, cand, osm)) {
  dt[, MANAGED := managed_lookup[STAND]]
  dt[, bucket  := bucket_lookup[STAND]]
  dt[, PAIR_TYPE := ptype_lookup[STAND]]
  dt[, interval_years := interval_lookup[STAND]]
}
base <- merge(base, comp, by="STAND", all.x=TRUE)
cand <- merge(cand, comp, by="STAND", all.x=TRUE)
osm  <- merge(osm,  comp, by="STAND", all.x=TRUE)

rows <- list()
rows[[length(rows)+1]] <- summ_row("overall","ALL","BASE (frozen, no levers)", base)
rows[[length(rows)+1]] <- summ_row("overall","ALL","CANDIDATE v12.11", cand)
rows[[length(rows)+1]] <- summ_row("overall","ALL","OSM-ACD v2.26.1", osm)

for (mflag in c(0,1)) {
  lab <- if (mflag==1) "Managed" else "Unmanaged"
  rows[[length(rows)+1]] <- summ_row("managed",lab,"BASE (frozen, no levers)", base[MANAGED==mflag])
  rows[[length(rows)+1]] <- summ_row("managed",lab,"CANDIDATE v12.11", cand[MANAGED==mflag])
  rows[[length(rows)+1]] <- summ_row("managed",lab,"OSM-ACD v2.26.1", osm[MANAGED==mflag])
}
for (fg in c("Softwood","Mixedwood","Hardwood")) {
  rows[[length(rows)+1]] <- summ_row("forest_group",fg,"BASE (frozen, no levers)", base[forest_group==fg])
  rows[[length(rows)+1]] <- summ_row("forest_group",fg,"CANDIDATE v12.11", cand[forest_group==fg])
  rows[[length(rows)+1]] <- summ_row("forest_group",fg,"OSM-ACD v2.26.1", osm[forest_group==fg])
}
for (bk in c("<15","15-30",">30")) {
  rows[[length(rows)+1]] <- summ_row("interval_bucket",bk,"BASE (frozen, no levers)", base[bucket==bk])
  rows[[length(rows)+1]] <- summ_row("interval_bucket",bk,"CANDIDATE v12.11", cand[bucket==bk])
  rows[[length(rows)+1]] <- summ_row("interval_bucket",bk,"OSM-ACD v2.26.1", osm[bucket==bk])
}
# key deliverable: bucket x managed interaction (long-horizon behavior split by disturbance state)
for (bk in c("<15","15-30",">30")) for (mflag in c(0,1)) {
  lab <- if (mflag==1) "Managed" else "Unmanaged"
  sv <- paste0(bk, "_", lab)
  rows[[length(rows)+1]] <- summ_row("interval_bucket_x_managed", sv, "BASE (frozen, no levers)",
                                      base[bucket==bk & MANAGED==mflag])
  rows[[length(rows)+1]] <- summ_row("interval_bucket_x_managed", sv, "CANDIDATE v12.11",
                                      cand[bucket==bk & MANAGED==mflag])
  rows[[length(rows)+1]] <- summ_row("interval_bucket_x_managed", sv, "OSM-ACD v2.26.1",
                                      osm[bucket==bk & MANAGED==mflag])
}
# PAIR_TYPE (CONSECUTIVE vs FIRST_LAST) as a sanity split -- confirms the long-horizon signal is
# not just an artifact of the FIRST_LAST construction vs ordinary consecutive remeasurement
for (pt in c("CONSECUTIVE","FIRST_LAST")) {
  rows[[length(rows)+1]] <- summ_row("pair_type",pt,"BASE (frozen, no levers)", base[PAIR_TYPE==pt])
  rows[[length(rows)+1]] <- summ_row("pair_type",pt,"CANDIDATE v12.11", cand[PAIR_TYPE==pt])
  rows[[length(rows)+1]] <- summ_row("pair_type",pt,"OSM-ACD v2.26.1", osm[PAIR_TYPE==pt])
}

sc <- rbindlist(rows, fill=TRUE)
sc[, site_note := "Site input: Task-1-corrected NS SITE_INDEX/AVGTOPHTM (+7.0 m documented ESI v8 raster positive bias); see build_ns_site_correction.py and 20260722_ns_benchmark_philosophy_pass.md."]
sc[, osm_note := sprintf(
  "OSM-ACD v2.26.1 run on NS long-interval set 23 Jul 2026 (job 12548192 task 2; osm_ns_run.py + osm_score_ns.R): same stand set as FVS BASE (%d stands scored, %d matched by OSM after dropping rows <1cm DBH per OSM's own ingestion floor -- those never count in NSVB metrics regardless), Zone=NS (native Acadian zone), Management=None for all stands (same convention as the NB/CTRN OSM runs), scored on the identical NSVB metrics() as FVS-ACD.",
  nrow(base), uniqueN(osm$STAND))]
fwrite(sc, "bench_ns_long_scorecard.csv")

cnt <- base[, .N, by=.(MANAGED, bucket, forest_group)]
setorder(cnt, MANAGED, bucket, forest_group)
fwrite(cnt, "bench_ns_long_stand_counts.csv")

cat("=== NS LONG-INTERVAL SCORECARD ===\n"); print(sc)
cat("\n=== stand counts by managed x bucket x forest_group ===\n"); print(cnt)
cat("\nbase n=", nrow(base), " cand n=", nrow(cand), " osm n=", nrow(osm), "\n")
cat("DONE\n")

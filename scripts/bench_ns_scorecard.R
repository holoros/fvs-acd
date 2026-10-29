# bench_ns_scorecard.R -- NS remeasurement benchmark scorecard: BASE (frozen, no v12.11 levers)
# vs CANDIDATE v12.11 (Lever2 managed mortality-density scale + Lever3b stand constraint +
# Lever4 hardwood height + IGMULT=2.5) vs OSM-ACD v2.26.1, overall / managed vs unmanaged /
# forest group (HW/MW/SW from %HW BA at t1, thresholds SW<25, MW 25-75, HW>75 per task spec).
# THIRD PASS (23 Jul 2026): OSM-ACD v2.26.1 now run on NS via osm_ns_run.py + osm_score_ns.R,
# mirroring the recipe already used for the other five multi-source strata (osm_multisrc_run.py)
# and NB (g4_osm_v1211_nb_run.py) -- same species conventions, same NSVB metrics() (verbatim from
# bench_parity_split_ms.R), same "Management=None for every stand" convention already used for the
# other managed sources scored this way (NB, CTRN; OSM ingests the t1 tree list directly, which
# already reflects any management history). Zone is fixed 'NS', OSM's own native Acadian zone for
# Nova Scotia (confirmed valid by a smoke test 2026-07-23; more faithful than the ME/NB fallback
# used for sources with no native zone). First attempt (job 12547956) crashed OSM.ConsoleApp
# mid-run (Exit Code 1, "Minimum DBH accepted by 'AcadianStandModel' is 1 (cm)") on regen/seedling
# stems <1cm DBH and silently truncated the treelist; osm_ns_run.py now drops those rows before
# OSM ingestion (job 12548192, clean rc=0) -- they never count toward the scored NSVB metrics
# anyway (metrics() requires DBH>=4cm). See osm_ns_run.py header for the full note.
# Aggregates only leave this script; no raw NS coordinates are read or written here.
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
FG_SW_MAX <- 25; FG_HW_MIN <- 75  # SW <25, MW 25-75, HW >75 (task spec, strict inequalities)
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
    TOTVOL_bias_pct=round(bias_pct(d$TOTVOL_o,d$TOTVOL_p),2),
    TOTVOL_rmse_pct=round(rmse_pct(d$TOTVOL_o,d$TOTVOL_p),2),
    BA_bias_pct=round(bias_pct(d$BA_o,d$BA_p),2),
    BA_rmse_pct=round(rmse_pct(d$BA_o,d$BA_p),2))
}

pairs <- fread("multisrc/bench_ns_pairs.csv")
pairs[, STAND := as.character(STAND)]
managed_lookup <- setNames(pairs$MANAGED, pairs$STAND)

comp <- composition_from_treeinit("multisrc/bench_ns_tree_init.csv")

base <- fread("ns_base_results.csv"); base[, STAND := as.character(STAND)]
cand_m <- fread("ns_cand_managed_results.csv"); cand_m[, STAND := as.character(STAND)]
cand_u <- fread("ns_cand_unmanaged_results.csv"); cand_u[, STAND := as.character(STAND)]
cand <- rbindlist(list(cand_m, cand_u), fill=TRUE)
osm <- fread("osm_score_ns_results.csv"); osm[, STAND := as.character(STAND)]

base[, MANAGED := managed_lookup[STAND]]
cand[, MANAGED := managed_lookup[STAND]]
osm[, MANAGED := managed_lookup[STAND]]
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
sc <- rbindlist(rows, fill=TRUE)
sc[, osm_note := sprintf(
  "OSM-ACD v2.26.1 run on NS 23 Jul 2026 (job 12548192 task 1; osm_ns_run.py + osm_score_ns.R): same stand set as FVS BASE (%d stands scored, %d matched by OSM after dropping %d rows <1cm DBH per OSM's own ingestion floor -- those never count in NSVB metrics regardless), Zone=NS (native Acadian zone), Management=None for all stands (same convention as the NB/CTRN OSM runs), scored on the identical NSVB metrics() as FVS-ACD.",
  nrow(base), uniqueN(osm$STAND), 1710L)]
# carried forward verbatim from the prior (second-pass) scorecard -- not dropped by the OSM addition
sc[, site_index_note := "SECOND PASS (22 Jul 2026): NS SITE_INDEX/AVGTOPHTM confirmed on the SAME basis as esi8 (dominant height m, ~breast-height age 50; handbook/protocol PDF) -- no species/base-age/unit bug. The real mismatch is that QC/NB esi8 itself is a documented-flawed raster (Acadian_ESI_v8_stress_test.md: positive bias +7.0 m, Pearson r=0.146 vs measured SI, compressed range) that the model's NB/QC height-growth anchor factors were tuned against; NS gets no equivalent correction. Re-scoring the unmanaged set with NS site index +7.0 m (esi8-matched) moved TOTVOL bias from -6.04% to -4.84% (base) and -6.07% to -5.04% (v12.11) -- a real but SECONDARY effect (~15-20% relative reduction of an already-small unmanaged bias). The large biases in this table (managed -58 to -42%, overall -41 to -31%) are NOT primarily a site-index artifact; they are dominated by managed-stand post-disturbance response, not the esi8 basis. See build_ns_site_correction.py, bench_ns_sitefix_compare.csv, and 20260722_ns_benchmark_philosophy_pass.md."]
fwrite(sc, "bench_ns_scorecard.csv")

cnt <- base[, .N, by=.(MANAGED, forest_group)]
setorder(cnt, MANAGED, forest_group)
fwrite(cnt, "bench_ns_stand_counts.csv")

cat("=== NS SCORECARD ===\n"); print(sc)
cat("\n=== stand counts by managed x forest_group (from BASE stand list) ===\n"); print(cnt)
cat("\nbase n=", nrow(base), " cand n=", nrow(cand), " osm n=", nrow(osm), "\n")
cat("DONE\n")

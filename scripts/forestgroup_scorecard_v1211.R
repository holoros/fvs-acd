# forestgroup_scorecard_v1211.R
# OVERALL (pooled) and per-source performance scorecard for FVS-ACD v12.11 benchmark,
# split by FOREST GROUP (Hardwood/Mixedwood/Softwood) assigned from t1 percent hardwood
# basal area, using the frozen convention already committed in
# scorecard_fortype_composite_frozen.R (softwood-BA fraction rule: <=25% HW BA = Softwood,
# >=75% HW BA = Hardwood, else Mixedwood). Reuses that threshold, not reinvented.
#
# Model comparison, sources, and metric definitions match v1211_allsites_scorecard.R
# (Task #18 all-sites run): BASE (frozen, no V1211_* levers) vs CANDIDATE v12.11
# (red-team-fixed) vs OSM-ACD v2.26.1. Level bias% = 100*(mean(p)/mean(o)-1).
# %RMSE = 100*sqrt(mean((p-o)^2))/mean(o). Pooled numbers are STAND-WEIGHTED (each
# benchmark stand counts once, not EXPNS-weighted).
#
# Forest-group composition (%HW BA at t1) is computed from each source's per-tree
# init list (bench_<src>_tree_init.csv / magp_qcnb_tree_init.csv: STAND,PLOT,TREE,SP,
# DBH,HT,EXPF,YEAR) using the species HW/SW flag from AcadianGY's sp.attr table
# (sp.type column), reproduced here as a static lookup -- NOT sourced from the model
# file, so this script does not edit or execute AcadianGY_12.11.r or the frozen harness.
#
# Aggregates only. Does not touch operational AcadianGY_*.r or the frozen harness.
#   Rscript forestgroup_scorecard_v1211.R
# ============================================================================
suppressMessages({
  .libPaths(c("~/R/x86_64-pc-linux-gnu-library/4.4",
              "~/R/x86_64-pc-linux-gnu-library/4.5", .libPaths()))
  library(data.table)
})

VERIFY_DIR <- path.expand("~/magplot/verify")
setwd(VERIFY_DIR)

OUT_SCORECARD <- file.path(VERIFY_DIR, "v1211_forestgroup_scorecard.csv")
OUT_COUNTS    <- file.path(VERIFY_DIR, "v1211_forestgroup_stand_counts.csv")

# ---- species HW/SW lookup (AGY 2-letter code -> sp.type), reproduced from
# AcadianGY sp.attr tribble for composition purposes only ----
sp_type <- c(
  AB="HW", AS="HW", BA="HW", BC="HW", BF="SW", BP="HW", BS="SW", BT="HW",
  EC="HW", EH="SW", GA="HW", GB="HW", HH="HW", JP="SW", NS="SW", OH="HW",
  OS="SW", PB="HW", PC="HW", PR="HW", QA="HW", RB="HW", RM="HW", RP="SW",
  RN="SW", RO="HW", RS="SW", SB="HW", SM="HW", ST="HW", TA="SW", WA="HW",
  WC="SW", WP="SW", WS="SW", YB="HW", `99`="HW"
)

# Frozen forest-group threshold (matches scorecard_fortype_composite_frozen.R comment):
#   <=25% HW BA = Softwood, >=75% HW BA = Hardwood, else Mixedwood.
FG_SW_MAX <- 25
FG_HW_MIN <- 75

assign_fg <- function(pct_hw) {
  fifelse(is.na(pct_hw), NA_character_,
    fifelse(pct_hw <= FG_SW_MAX, "Softwood",
      fifelse(pct_hw >= FG_HW_MIN, "Hardwood", "Mixedwood")))
}

# ---- compute t1 %HW-BA and forest group per STAND from a tree_init file ----
composition_from_treeinit <- function(path) {
  ti <- fread(path)
  ti[, sp_t := sp_type[SP]]
  ti[is.na(sp_t), sp_t := "SW"]  # unmapped/other codes default softwood-lite bucket (rare, logged)
  n_unmapped <- ti[is.na(sp_type[SP]), .N]
  ti[, ba := pi * (DBH/200)^2 * EXPF]
  agg <- ti[, .(BA_t1_calc = sum(ba), HW_BA_t1 = sum(ba[sp_t == "HW"])), by = STAND]
  agg[, pct_hw_t1 := 100 * HW_BA_t1 / BA_t1_calc]
  agg[, forest_group := assign_fg(pct_hw_t1)]
  attr(agg, "n_unmapped_sp_rows") <- n_unmapped
  agg[, .(STAND, pct_hw_t1, forest_group)]
}

bias_pct <- function(o,p) 100*(mean(p,na.rm=TRUE)/mean(o,na.rm=TRUE)-1)
rmse_pct <- function(o,p){ rmse<-sqrt(mean((p-o)^2,na.rm=TRUE)); mo<-mean(o,na.rm=TRUE); if(is.finite(mo)&&abs(mo)>1e-9) 100*rmse/mo else NA_real_ }

summ_row <- function(region, source, model, forest_group, d){
  if(is.null(d) || nrow(d)==0) return(NULL)
  data.table(region=region, source=source, forest_group=forest_group, model=model, n=nrow(d),
    TOTVOL_bias_pct = round(bias_pct(d$TOTVOL_o, d$TOTVOL_p),2),
    BA_bias_pct     = round(bias_pct(d$BA_o, d$BA_p),2),
    TOTVOL_rmse_pct = round(rmse_pct(d$TOTVOL_o, d$TOTVOL_p),2))
}

rd <- function(f) if(file.exists(f)) fread(f) else NULL

# ---- source specs (mirrors v1211_allsites_scorecard.R, Task #18 frozen inputs) ----
specs <- list(
  list(region="ME", source="Baxter (mature, held-out)",
       base="base_baxter_results.csv", cand="cand_baxter_results.csv", osm="osm_score_baxter_results.csv",
       tree_init="multisrc/bench_baxter_tree_init.csv", prov_filter=NULL),
  list(region="ME", source="SILC/Seven Islands (calibration, managed)",
       base="base_silc_l_results.csv", cand="cand_silc_l_results.csv", osm="osm_score_silc_l_results.csv",
       tree_init="multisrc/bench_silc_l_tree_init.csv", prov_filter=NULL),
  list(region="ME", source="PEF (developing)",
       base="base_pef_results.csv", cand="cand_pef_results.csv", osm="osm_score_pef_results.csv",
       tree_init="multisrc/bench_pef_tree_init.csv", prov_filter=NULL),
  list(region="ME", source="CFRU CTRN (managed)",
       base="base_ctrn_results.csv", cand="cand_ctrn_results.csv", osm="osm_score_ctrn_results.csv",
       tree_init="multisrc/bench_ctrn_tree_init.csv", prov_filter=NULL),
  list(region="ME", source="Maine FIA (whole-plot, developing)",
       base="base_mefia_l_results.csv", cand="cand_mefia_l_results.csv", osm="osm_score_me_fia_l_results.csv",
       tree_init="multisrc/bench_mefia_long_tree_init.csv", prov_filter=NULL),
  list(region="NB", source="NB MagPlot (managed)",
       base="base_nb_results.csv", cand="cand_nb_results.csv", osm="g4_osm_score_nb_results.csv",
       tree_init="magp_qcnb_tree_init.csv", prov_filter="NB"),
  list(region="QC", source="QC MagPlot (managed)",
       base="base_nb_results.csv", cand="cand_nb_results.csv", osm=NULL,
       tree_init="magp_qcnb_tree_init.csv", prov_filter="QC")
)

sc_rows <- list()
count_rows <- list()
unmapped_log <- list()

for (sp in specs) {
  comp <- composition_from_treeinit(sp$tree_init)

  b <- rd(sp$base); c <- rd(sp$cand); o <- if(!is.null(sp$osm)) rd(sp$osm) else NULL
  if (!is.null(sp$prov_filter)) {
    if (!is.null(b)) b <- b[PROV == sp$prov_filter]
    if (!is.null(c)) c <- c[PROV == sp$prov_filter]
    if (!is.null(o)) o <- o[PROV == sp$prov_filter]
  }

  # attach forest group (from the shared t1 composition table) to each model's stands
  attach_fg <- function(d) { if (is.null(d)) return(NULL); merge(d, comp, by="STAND", all.x=TRUE) }
  b <- attach_fg(b); c <- attach_fg(c); o <- attach_fg(o)

  # stand counts per forest group (use BASE stand list as the canonical per-source stand set)
  if (!is.null(b)) {
    cnt <- b[, .N, by=forest_group]
    cnt[, `:=`(region=sp$region, source=sp$source)]
    count_rows[[length(count_rows)+1]] <- cnt
  }

  for (fg in c("Softwood","Mixedwood","Hardwood")) {
    if (!is.null(b)) sc_rows[[length(sc_rows)+1]] <- summ_row(sp$region, sp$source, "BASE (frozen, no levers)", fg, b[forest_group==fg])
    if (!is.null(c)) sc_rows[[length(sc_rows)+1]] <- summ_row(sp$region, sp$source, "CANDIDATE v12.11", fg, c[forest_group==fg])
    if (!is.null(o)) sc_rows[[length(sc_rows)+1]] <- summ_row(sp$region, sp$source, "OSM-ACD v2.26.1", fg, o[forest_group==fg])
  }

  # keep a pooled-eligible long stand table per model for the OVERALL pooled rows below
  mk_long <- function(d, model) { if(is.null(d)) return(NULL)
    d[, .(source=sp$source, region=sp$region, model=model, forest_group, STAND, TOTVOL_o, TOTVOL_p, BA_o, BA_p)] }
  if (!exists("pooled_long")) pooled_long <- list()
  pooled_long[[length(pooled_long)+1]] <- mk_long(b, "BASE (frozen, no levers)")
  pooled_long[[length(pooled_long)+1]] <- mk_long(c, "CANDIDATE v12.11")
  pooled_long[[length(pooled_long)+1]] <- mk_long(o, "OSM-ACD v2.26.1")
}

# ---- OVERALL (pooled across all sources, stand-weighted: each stand counts once) ----
PL <- rbindlist(pooled_long, fill=TRUE)
for (fg in c("Softwood","Mixedwood","Hardwood")) {
  for (mdl in c("BASE (frozen, no levers)","CANDIDATE v12.11","OSM-ACD v2.26.1")) {
    dd <- PL[forest_group==fg & model==mdl]
    sc_rows[[length(sc_rows)+1]] <- summ_row("ALL", "OVERALL (pooled, stand-weighted)", mdl, fg, dd)
  }
}
# OVERALL pooled counts (all forest groups, all sources) for the reported stand-count table
cnt_all <- PL[model=="BASE (frozen, no levers)", .N, by=forest_group]
cnt_all[, `:=`(region="ALL", source="OVERALL (pooled)")]
count_rows[[length(count_rows)+1]] <- cnt_all

sc <- rbindlist(sc_rows, fill=TRUE)
sc[, forest_group := factor(forest_group, levels=c("Softwood","Mixedwood","Hardwood"))]
sc[, model := factor(model, levels=c("BASE (frozen, no levers)","CANDIDATE v12.11","OSM-ACD v2.26.1"))]
setorder(sc, region, source, forest_group, model)
fwrite(sc, OUT_SCORECARD)

counts <- rbindlist(count_rows, fill=TRUE)
counts[, forest_group := factor(forest_group, levels=c("Softwood","Mixedwood","Hardwood"))]
setorder(counts, region, source, forest_group)
fwrite(counts, OUT_COUNTS)

cat("THRESHOLDS: Softwood <=", FG_SW_MAX, "% HW BA at t1; Mixedwood", FG_SW_MAX, "-", FG_HW_MIN,
    "% (exclusive of endpoints); Hardwood >=", FG_HW_MIN, "% HW BA at t1.\n")
cat("WROTE", OUT_SCORECARD, "rows=", nrow(sc), "\n")
cat("WROTE", OUT_COUNTS, "rows=", nrow(counts), "\n")
print(sc[region=="ALL"])
cat("--- stand counts per group per source ---\n")
print(counts)
cat("DONE_FORESTGROUP_SCORECARD\n")

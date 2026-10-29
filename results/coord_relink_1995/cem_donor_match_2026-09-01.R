# cem_donor_match_2026-09-01.R
# CEM donor match for the 83 Master Stem plots against Maine ME_COND, then a validation
# comparison against the p37 form/risk crosswalk (apply_formrisk_crosswalk.R's cw()).
# County is blocked exactly (verified FIA-COUNTYCD-equivalent in the scoping doc). Forest
# type group comes from the real REF_FOREST_TYPE.csv TYPGRPCD, fetched from the USDA FIA
# datamart this session, not reconstructed from memory. Ownership binary comes from the
# real REF_OWNGRPCD.csv (10/20/30 public, 40 private). Size class uses STDSZCD's raw code
# directly rather than an invented label. No true coordinates anywhere in this script.
suppressMessages({ library(data.table) })
set.seed(42)

FIA  <- "/users/PUOM0008/crsfaaron/fia_data"
HERE <- "/users/PUOM0008/crsfaaron/gydb_ws/repo_push/fvs-acd/results/coord_relink_1995"
OUT  <- HERE
LOG <- function(...) cat(sprintf(...), "\n")

## ---- 1. Master Stem, 83 plots ----
ms <- fread(file.path(HERE, "2017_master_stem_form_risk.csv"))
ms <- ms[!is.na(Tree) & Tree != "" & Form != "" & Risk != ""]
ms[, COUNTYCD := as.integer(County)]
ms[, Plot := as.character(Plot)]

# Collapse to the A/B form and LR/HR risk convention stated in apply_formrisk_crosswalk.R's
# own header comment (the ddbh_hw_mod collapse): A={F1,F3,F4,F7} vs B={F2,F5,F6,F8};
# LR={R1,R2} vs HR={R3,R4}. Applied here to Master Stem's NHRI 1-8/1-4 codes directly.
ms[, form_ab := fifelse(Form %in% c("1","3","4","7"), "A", fifelse(Form %in% c("2","5","6","8"), "B", NA_character_))]
ms[, risk_lrhr := fifelse(Risk %in% c("1","2"), "LR", fifelse(Risk %in% c("3","4"), "HR", NA_character_))]

ms_plots <- ms[, .(
  n_trees = .N,
  pct_A   = mean(form_ab == "A", na.rm = TRUE),
  pct_LR  = mean(risk_lrhr == "LR", na.rm = TRUE)
), by = .(COUNTYCD, Plot)]
LOG("Master Stem: %d plots, %d trees", nrow(ms_plots), sum(ms_plots$n_trees))

## ---- 2. FIA reference tables, real, fetched this session ----
ref_ft <- fread(file.path(HERE, "REF_FOREST_TYPE.csv"), select = c("VALUE", "TYPGRPCD"))
setnames(ref_ft, "VALUE", "FORTYPCD")
ref_own <- fread(file.path(HERE, "REF_OWNGRPCD.csv"), select = c("OWNGRPCD", "MEANING"))

## ---- 3. ME_COND, the donor population ----
cond <- fread(file.path(FIA, "ME_COND.csv"),
  select = c("PLT_CN","COUNTYCD","PLOT","COND_STATUS_CD","OWNGRPCD","FORTYPCD","STDAGE","STDSZCD","SICOND"))
cond <- cond[COND_STATUS_CD == 1 & !is.na(FORTYPCD)]  # forested conditions only
cond <- merge(cond, ref_ft, by = "FORTYPCD", all.x = TRUE)
cond[, fortyp_bin := fifelse(TYPGRPCD < 400, "softwood",
                     fifelse(TYPGRPCD == 400, "mixed",
                     fifelse(TYPGRPCD %in% c(999), "nonstocked", "hardwood")))]
cond[, own_bin := fifelse(OWNGRPCD %in% c(10,20,30), "public",
                  fifelse(OWNGRPCD == 40, "private", NA_character_))]
sicond_q <- quantile(cond$SICOND, probs = c(1/3, 2/3), na.rm = TRUE, type = 7)
cond[, site_tercile := fifelse(is.na(SICOND), NA_integer_,
                        fifelse(SICOND <= sicond_q[1], 1L,
                        fifelse(SICOND <= sicond_q[2], 2L, 3L)))]  # statewide terciles
cond[, size_bin := STDSZCD]

LOG("ME_COND: %d forested conditions statewide", nrow(cond))
LOG("fortyp_bin table:"); print(table(cond$fortyp_bin, useNA = "ifany"))

## ---- 4. CORRECTION to Section 4 of the scoping doc, caught while implementing it ----
# Section 4 proposed blocking on County (exact) plus coarsened forest type, site tercile,
# size class, and ownership. That assumed the Master Stem plots carry those attributes to
# match against. They do not: Section 1's own profile shows the file is County, Plot,
# SubPlot, Tree, Form, Risk only. There is nothing on the Master Stem side to coarsen except
# County, so a genuine per-plot stratified donor match cannot run as Section 4 described it.
# This is disclosed here rather than silently downgraded. What CAN run honestly is a
# COUNTY-ONLY exact block (Section 5 below), plus a within-county stratified breakdown of
# the FIA donor population itself, reported as a sensitivity range rather than a per-plot
# match, so Aaron can see how much the missing stand attributes could matter.
donor_pool <- cond[, .(n_donor_plots = uniqueN(PLT_CN)), by = COUNTYCD]
donor_strat <- cond[, .(n_donor_plots = uniqueN(PLT_CN)), by = .(COUNTYCD, fortyp_bin)]
fwrite(donor_pool, file.path(OUT, "cem_donor_pool_by_county_2026-09-01.csv"))
fwrite(donor_strat, file.path(OUT, "cem_donor_pool_by_county_fortyp_2026-09-01.csv"))
LOG("Donor pool by county written, %d counties, %d county x forest-type strata",
    nrow(donor_pool), nrow(donor_strat))

## ---- 5. crosswalk comparison: apply cw()-equivalent logic to every county's live hardwood
##         trees, compare the crosswalk's A/LR proportions against Master Stem's own, by county
##         (the coarsest, most defensible level given Master Stem carries no stand attributes) ----
tr <- fread(file.path(FIA, "ME_TREE.csv"),
  select = c("PLT_CN","COUNTYCD","SPCD","DIA","STATUSCD","TREECLCD","TREEGRCD",
             "TREE_GRADE_NCRS","CULL_FLD","DAMAGE_AGENT_CD1","DAMAGE_AGENT_CD2","DAMAGE_AGENT_CD3"))
tr <- tr[STATUSCD == 1 & is.finite(DIA) & DIA > 0]
spcd <- suppressWarnings(as.numeric(tr$SPCD))
tr <- tr[is.finite(spcd) & spcd >= 300]  # hardwoods only, same threshold as apply_formrisk_crosswalk.R

tc  <- suppressWarnings(as.integer(tr$TREECLCD))
gr  <- suppressWarnings(as.integer(ifelse(tr$TREEGRCD %in% c("", NA), tr$TREE_GRADE_NCRS, tr$TREEGRCD)))
cf  <- suppressWarnings(as.numeric(tr$CULL_FLD)); cf[!is.finite(cf)] <- NA_real_
dis <- function(x) { v <- suppressWarnings(as.numeric(x)); is.finite(v) & v >= 20000 & v < 30000 }
decay_dmg <- dis(tr$DAMAGE_AGENT_CD1) | dis(tr$DAMAGE_AGENT_CD2) | dis(tr$DAMAGE_AGENT_CD3)

form <- rep(NA_character_, nrow(tr)); risk <- rep(NA_character_, nrow(tr))
i <- tc == 3;                          form[i] <- "F2"
i <- tc == 2 & gr %in% c(1,2);         form[i] <- "F1"
i <- tc == 2 & gr %in% c(4,5);         form[i] <- "F2"
i <- tc == 2 & gr == 3;                form[i] <- "F1"
i <- tc == 2 & is.na(gr);              form[i] <- "F1"
i <- tc == 4 & gr %in% c(1,2);         form[i] <- "F1"
i <- tc == 4 & gr %in% c(3,4,5);       form[i] <- "F2"

i <- tc == 4;                                              risk[i] <- "R3"
i <- tc != 4 & is.finite(cf) & cf > 20;                     risk[i] <- "R3"
i <- tc != 4 & is.na(risk) & ((is.finite(cf) & cf > 5 & cf <= 20) | decay_dmg); risk[i] <- "R2"
i <- tc %in% c(2,3) & is.na(risk) & ((is.finite(cf) & cf <= 5) | is.na(cf)) & !decay_dmg; risk[i] <- "R1"

tr[, `:=`(cw_form = form, cw_risk = risk)]
tr[, cw_A  := fifelse(cw_form == "F1", TRUE, fifelse(cw_form == "F2", FALSE, NA))]
tr[, cw_LR := fifelse(cw_risk %in% c("R1","R2"), TRUE, fifelse(cw_risk == "R3", FALSE, NA))]

cw_by_county <- tr[!is.na(cw_A) | !is.na(cw_LR), .(
  n_hw_trees = .N,
  crosswalk_pct_A  = mean(cw_A,  na.rm = TRUE),
  crosswalk_pct_LR = mean(cw_LR, na.rm = TRUE)
), by = COUNTYCD]

# Stratified sensitivity range: same crosswalk calls, split by county x forest-type-bin
# (the coarsest, most defensible stratifier, since it is the strongest driver of species
# mix and therefore of TREECLCD/grade composition). Shows how much the missing Master Stem
# stand attributes could move the comparison, without pretending to target a specific stratum.
plt_fortyp <- unique(cond[, .(PLT_CN, fortyp_bin)])
tr_strat <- merge(tr, plt_fortyp, by = "PLT_CN", all.x = TRUE)
cw_by_county_strat <- tr_strat[!is.na(fortyp_bin) & (!is.na(cw_A) | !is.na(cw_LR)), .(
  n_hw_trees = .N,
  crosswalk_pct_A  = mean(cw_A,  na.rm = TRUE),
  crosswalk_pct_LR = mean(cw_LR, na.rm = TRUE)
), by = .(COUNTYCD, fortyp_bin)]
cw_range <- cw_by_county_strat[n_hw_trees >= 10, .(
  strata_n = .N,
  pct_A_min  = min(crosswalk_pct_A),  pct_A_max  = max(crosswalk_pct_A),
  pct_LR_min = min(crosswalk_pct_LR), pct_LR_max = max(crosswalk_pct_LR)
), by = COUNTYCD]
fwrite(cw_by_county_strat, file.path(OUT, "cem_crosswalk_by_county_fortyp_2026-09-01.csv"))
fwrite(cw_range, file.path(OUT, "cem_crosswalk_stratum_range_2026-09-01.csv"))

ms_by_county <- ms[, .(
  n_ms_trees   = .N,
  ms_pct_A  = mean(form_ab == "A", na.rm = TRUE),
  ms_pct_LR = mean(risk_lrhr == "LR", na.rm = TRUE)
), by = COUNTYCD]

comparison <- merge(ms_by_county, cw_by_county, by = "COUNTYCD", all.x = TRUE)
comparison <- merge(comparison, cw_range, by = "COUNTYCD", all.x = TRUE)
comparison[, diff_pct_A  := ms_pct_A  - crosswalk_pct_A]
comparison[, diff_pct_LR := ms_pct_LR - crosswalk_pct_LR]
comparison[, pct_A_in_stratum_range  := !is.na(pct_A_min)  & ms_pct_A  >= pct_A_min  & ms_pct_A  <= pct_A_max]
comparison[, pct_LR_in_stratum_range := !is.na(pct_LR_min) & ms_pct_LR >= pct_LR_min & ms_pct_LR <= pct_LR_max]
fwrite(comparison, file.path(OUT, "cem_crosswalk_comparison_2026-09-01.csv"))

LOG("\n=== County-level comparison, Master Stem field calls vs p37 crosswalk ===")
print(comparison[order(COUNTYCD)])

LOG("\nStatewide (tree-count-weighted): MS pct_A=%.4f crosswalk pct_A=%.4f | MS pct_LR=%.4f crosswalk pct_LR=%.4f",
    weighted.mean(comparison$ms_pct_A, comparison$n_ms_trees, na.rm=TRUE),
    weighted.mean(comparison$crosswalk_pct_A, comparison$n_hw_trees, na.rm=TRUE),
    weighted.mean(comparison$ms_pct_LR, comparison$n_ms_trees, na.rm=TRUE),
    weighted.mean(comparison$crosswalk_pct_LR, comparison$n_hw_trees, na.rm=TRUE))

cat("\nDONE cem_donor_match\n")

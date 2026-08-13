#!/usr/bin/env Rscript
# value_silcspec_v25.R
# v25 volume + stumpage VALUE scorecard. Same methodology as v24
# (value_silcspec_v24.R, unchanged): Seven Islands' own merch spec
# (silc_merch_specs.csv), the grade-driven sawlog/studwood/pallet/pulp
# cascade in merch_silcspec.R, Aroostook County 2024 observed stumpage.
#
# WHAT CHANGED FROM v24 (methodology untouched, inputs/config vectors only):
#   1. UNI default points at results/silc_cfi_unified_treelists_v25.csv
#      (build_unified_treelist_v25.R output).
#   2. "FVSACD_v1211_silc73" (73/154-plot partial-coverage rerun) is RETIRED
#      from the config list -- it no longer exists in the v25 unified
#      treelist (build_unified_treelist_v25.R dropped it) -- replaced by
#      "FVSACD_v1211_full" (120/137-plot full-coverage rerun, same model,
#      same version, just full coverage).
#   3. "FVSACD_v131_full" is ADDED -- brand-new v13.1 hierarchical-posterior
#      candidate, not benchmarked at all in v24.
#   AGM_v835, OSM_ACD, FVS_NE_default, FVS_ACD_default unchanged from v24.
t0 <- Sys.time()
source("kozak_taper.R"); source("merch_cords.R"); source("merch_asg.R")
source("merch_silcspec.R")
ACRES_PER_HA <- 2.4710538147
UNI  <- Sys.getenv("UNI_FILE", "silc_cfi_unified_treelists_v25.csv")
spec <- .load_silc_specs("silc_merch_specs.csv")

# ---- Aroostook price table (latest observed <= 2024) -----------------------
pr <- read.csv("aroostook_stumpage.csv", stringsAsFactors = FALSE)
pr <- pr[pr$kind == "observed" & pr$year <= 2024, ]
price_of <- function(product, sppgrp) {
  s <- pr[pr$product == product & pr$species == sppgrp, ]
  if (nrow(s) == 0) return(NA_real_)
  s$price_real_2024[which.max(s$year)]
}
SAWG <- c(BF="SPRUCE & FIR",RS="SPRUCE & FIR",BS="SPRUCE & FIR",WS="SPRUCE & FIR",
  NS="SPRUCE & FIR",RP="SPRUCE & FIR",RN="SPRUCE & FIR",TA="SPRUCE & FIR",
  WP="WHITE PINE",EH="HEMLOCK",WC="CEDAR",SM="SUGAR MAPLE",RM="RED/WHITE MAPLE",
  YB="YELLOW BIRCH",WA="ASH",BA="ASH",GA="ASH",AS="ASH",RO="RED OAK",AB="BEECH",
  PB="WHITE BIRCH",GB="WHITE BIRCH",SB="WHITE BIRCH",QA="ASPEN/POPLAR",
  BT="ASPEN/POPLAR",BP="ASPEN/POPLAR")
PULPG <- function(sp){
  if (sp %in% c("BF","RS","BS","WS","NS","WP","RP","RN","JP","TA","OS")) "SPRUCE & FIR"
  else if (sp=="EH") "HEMLOCK" else if (sp=="WC") "CEDAR"
  else if (sp %in% c("QA","BT","BP")) "ASPEN/POPLAR" else "MIXED HARDWOOD"
}
STUDG  <- function(sp) if (sp %in% c("BF","RS","BS","WS","NS","RP","RN")) "SPRUCE & FIR" else "OTHER SPECIES"
saw_price  <- function(sp){ g<-SAWG[sp]; if(is.na(g)) return(0); v<-price_of("SAWLOGS",unname(g)); if(is.na(v)) 0 else v }
pulp_price <- function(sp){ v<-price_of("PULPWOOD",PULPG(sp)); if(is.na(v)) 0 else v }
stud_price <- function(sp){ v<-price_of("STUDWOOD",STUDG(sp)); if(is.na(v)) 0 else v }   # $/cord (low)
PALLET_P_HW <- price_of("PALLETWOOD","HARDWOOD")   # $/MBF, all pallet spp are HW
allsp <- c("BF","RS","BS","WS","NS","WP","RP","RN","EH","WC","JP","TA","OS",
           "SM","RM","YB","WA","BA","GA","AS","RO","AB","PB","GB","SB","QA",
           "BT","BP","OH","ST","BC","AE","BL","BW","NC","HH","PR")
SAW_P  <- sapply(allsp, saw_price)
PULP_P <- sapply(allsp, pulp_price)
STUD_P <- sapply(allsp, stud_price)
cat(sprintf("Prices: RS saw $%.0f/MBF stud $%.0f/cd pulp $%.0f/cd | YB saw $%.0f | HW pallet $%.0f/MBF\n",
    SAW_P["RS"],STUD_P["RS"],PULP_P["RS"],SAW_P["YB"],PALLET_P_HW))

# ---- routine pair subset ---------------------------------------------------
uni <- read.csv(UNI, stringsAsFactors = FALSE)
uni <- uni[!is.na(suppressWarnings(as.numeric(uni$dbh_cm))), ]
uni$dbh_cm <- as.numeric(uni$dbh_cm); uni$ht_m <- as.numeric(uni$ht_m)
uni$expf_tph <- as.numeric(uni$expf_tph)
ps  <- read.csv("silc_cfi_longhorizon_pairs_v16.csv", stringsAsFactors = FALSE)
ps$estbl <- (ps$BA_CURR_FT2AC / pmax(ps$BA_PREV_FT2AC,1)) > 2.0
routine <- ps$PLOT[!ps$estbl]; n_routine <- length(routine)
uni <- uni[uni$PLOT %in% routine, ]; uni$expf_ac <- uni$expf_tph / ACRES_PER_HA
cat(sprintf("Routine plots: %d | tree rows: %d | model_configs present: %s\n",
    n_routine, nrow(uni), paste(sort(unique(uni$model_config)), collapse=", ")))

# ---- memoized per-tree merchandizing (sp x dbh x ht) -----------------------
key <- paste(uni$sp, round(uni$dbh_cm,1), round(uni$ht_m,1), sep="|")
uk  <- unique(key)
cat(sprintf("Unique tree types: %d (of %d rows)\n", length(uk), nrow(uni)))
suppressMessages(library(parallel))
ncores <- max(1, detectCores() - 1)
ukm <- do.call(rbind, mclapply(uk, function(k){
  p <- strsplit(k,"\\|")[[1]]
  merch_silc_tree(p[1], as.numeric(p[2]), as.numeric(p[3]), spec)
}, mc.cores = ncores))
rownames(ukm) <- uk
M <- ukm[key, , drop = FALSE]

uni$tot_cd    <- M[,"merch"]  * M3_TO_FT3/CORD_FT3 * uni$expf_ac
uni$saw_cd    <- M[,"saw"]    * M3_TO_FT3/CORD_FT3 * uni$expf_ac
uni$stud_cd   <- M[,"stud"]   * M3_TO_FT3/CORD_FT3 * uni$expf_ac
uni$pallet_cd <- M[,"pallet"] * M3_TO_FT3/CORD_FT3 * uni$expf_ac
uni$pulp_cd   <- M[,"pulp"]   * M3_TO_FT3/CORD_FT3 * uni$expf_ac
uni$saw_mbf    <- M[,"saw_bf"]    * uni$expf_ac / 1000
uni$pallet_mbf <- M[,"pallet_bf"] * uni$expf_ac / 1000

sp_idx <- match(uni$sp, allsp); sp_idx[is.na(sp_idx)] <- match("OH", allsp)
uni$saw_val    <- uni$saw_mbf    * SAW_P[sp_idx]            # $/MBF
uni$stud_val   <- uni$stud_cd    * STUD_P[sp_idx]           # $/cord (studwood, low)
uni$pallet_val <- uni$pallet_mbf * PALLET_P_HW             # $/MBF (palletwood)
uni$pulp_val   <- uni$pulp_cd    * PULP_P[sp_idx]           # $/cord
uni$tot_val    <- uni$saw_val + uni$stud_val + uni$pallet_val + uni$pulp_val

# ---- aggregate per model x plot, score vs observed -------------------------
fl <- c("tot_cd","saw_cd","stud_cd","pallet_cd","pulp_cd","saw_mbf","pallet_mbf",
        "saw_val","stud_val","pallet_val","pulp_val","tot_val")
agg <- aggregate(uni[fl], by = list(model_config = uni$model_config, PLOT = uni$PLOT), FUN = sum)
obs <- agg[agg$model_config == "OBSERVED", ]
on  <- paste0(c("tot_cd","saw_cd","stud_cd","pallet_cd","pulp_cd","tot_val"), "_o")
obs2 <- obs[, c("PLOT","tot_cd","saw_cd","stud_cd","pallet_cd","pulp_cd","tot_val")]; names(obs2)[-1] <- on

bias <- function(p,o) 100*(mean(p,na.rm=TRUE)/mean(o,na.rm=TRUE)-1)
r2 <- function(p,o){ok<-is.finite(p)&is.finite(o); if(sum(ok)<3) return(NA); 1-sum((o[ok]-p[ok])^2)/sum((o[ok]-mean(o[ok]))^2)}
# v25 config list: FVSACD_v1211_silc73 retired (dropped from the unified
# treelist itself, see build_unified_treelist_v25.R); FVSACD_v1211_full
# replaces it (same model, full coverage); FVSACD_v131_full added (new).
configs <- c("AGM_v835","OSM_ACD","FVS_NE_default","FVS_ACD_default","FVSACD_v1211_full","FVSACD_v131_full")
labels  <- c("AcadianGY v8.35 (byPlot)","OSM-ACD","FVS-NE default","FVS-ACD default (v16-v22 vintage)","FVS-ACD v12.11 (full137 rerun, tree-level)","FVS-ACD v13.1 (full137 rerun, tree-level)")
rows <- list()
for (k in seq_along(configs)) {
  m <- merge(agg[agg$model_config==configs[k],], obs2, by="PLOT")
  if (nrow(m)==0) { cat(sprintf("NOTE: model_config '%s' has zero rows after merge with observed plots -- skipped.\n", configs[k])); next }
  rows[[k]] <- data.frame(model=labels[k], n=nrow(m),
    totvol_bias=round(bias(m$tot_cd,m$tot_cd_o),1),
    saw_bias=round(bias(m$saw_cd,m$saw_cd_o),1),
    stud_bias=round(bias(m$stud_cd,m$stud_cd_o),1),
    pallet_bias=round(bias(m$pallet_cd,m$pallet_cd_o),1),
    pulp_bias=round(bias(m$pulp_cd,m$pulp_cd_o),1),
    value_bias=round(bias(m$tot_val,m$tot_val_o),1),
    value_R2=round(r2(m$tot_val,m$tot_val_o),3),
    mean_val=round(mean(m$tot_val),0))
}
sc <- do.call(rbind, rows)
om <- obs[obs$PLOT %in% routine, ]
cat(sprintf("\n=== v25 SILC-spec volume + VALUE scorecard (routine n=%d, Aroostook 2024 $, MFS units) ===\n", n_routine))
cat(sprintf("Observed mean: total %.1f cd | sawlog %.1f | studwood %.1f | pallet %.1f | pulp %.1f cd | value $%.0f/ac\n",
    mean(om$tot_cd),mean(om$saw_cd),mean(om$stud_cd),mean(om$pallet_cd),mean(om$pulp_cd),mean(om$tot_val)))
cat(sprintf("Observed value split: sawlog $%.0f + studwood $%.0f + pallet $%.0f + pulp $%.0f /ac\n\n",
    mean(om$saw_val),mean(om$stud_val),mean(om$pallet_val),mean(om$pulp_val)))
print(sc, row.names = FALSE)

write.csv(sc,  "silc_cfi_value_v25_scorecard.csv", row.names = FALSE)
write.csv(agg, "silc_cfi_value_v25_byplot.csv",    row.names = FALSE)

# ---- per-species observed product split (audit) ----------------------------
spp <- aggregate(uni[uni$model_config=="OBSERVED", c("saw_cd","stud_cd","pallet_cd","pulp_cd","tot_cd")],
                 by=list(sp=uni$sp[uni$model_config=="OBSERVED"]), FUN=sum)
spp <- spp[order(-spp$tot_cd),]
write.csv(spp, "silc_cfi_obs_species_split_v25.csv", row.names = FALSE)

# ---- coverage check: how many distinct v16 plots make it into the final scorecard ----
n_v16_plots <- length(unique(ps$PLOT))
cov <- data.frame(model_config = configs,
                   n_plots_in_scorecard = sapply(configs, function(cc) length(unique(agg$PLOT[agg$model_config==cc]))))
cov$pct_of_routine <- round(100*cov$n_plots_in_scorecard/n_routine,1)
write.csv(cov, "silc_cfi_v25_coverage_by_model.csv", row.names = FALSE)
cat("\nCoverage by model_config (of", n_routine, "routine plots):\n")
print(cov, row.names = FALSE)

cat(sprintf("\nDONE in %.1f min\n", as.numeric(difftime(Sys.time(),t0,units="mins"))))

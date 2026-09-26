#!/usr/bin/env Rscript
# value_silcspec_v32ht.R (September 23, 2026): v29b scorer copied unchanged except OUT, output file
# names, and the configuration list, which gains the height-initialization factorial cells.
# value_silcspec_v29.R  -- SILC CFI benchmark, v29 metric restack.
#
# WHAT CHANGED FROM v28 (Aaron's call, September 8, 2026, after Bruce Carroll
# flagged the merch-column question):
#
#  1. PRIMARY METRIC is now GROSS merchantable volume to a 4 in (10.16 cm) top,
#     column `gross4_cd`. v23-v28 scored `tot_cd`, which was NET of a flat
#     modeled rotten-cull fraction (0.86 softwood, 0.66 hardwood from
#     merch_asg.R) and was labelled "total volume" in the report, which it was
#     not. AGM's own delivery carries zero defect (Cull and FVSDefect are
#     identically zero and GrossVolume == NetVolume exactly across all 12,755
#     InventoryG stand-years), so gross-to-4in is the basis on which the two
#     accountings are directly comparable.
#  2. SECOND PRIMARY is aboveground biomass and carbon, via the NSVB emulator
#     (log(y) ~ log(DIA^2*HT) by SPGRPCD with Duan smearing, fitted from FIA
#     ME_TREE NSVB outputs) applied uniformly to every configuration including
#     OBSERVED, so the apples-to-apples principle holds.
#  3. VALUE is demoted to a secondary table. Two defects are fixed and both are
#     disclosed: the pallet board-foot discount leak, and the studwood override.
#  4. SILC_SPEC_LITERAL=1 reruns the whole scorecard with the studwood override
#     off, reading Seven Islands' three-product spec literally, to size the
#     override rather than leave it undisclosed.
t0 <- Sys.time()
setwd("/users/PUOM0008/crsfaaron/silc_cfi")
source("kozak_taper.R"); source("merch_cords.R"); source("merch_asg.R")
source("v29_run/merch_silcspec_v29.R")
suppressPackageStartupMessages(library(data.table))
ACRES_PER_HA <- 2.4710538147
LB_KG <- 0.45359237
CARBON_FRACTION <- 0.5   # FIA default; stated explicitly, never applied silently
LITERAL <- identical(Sys.getenv("SILC_SPEC_LITERAL"), "1")
TAG <- if (LITERAL) "specliteral" else "primary"
OUT <- "/users/PUOM0008/crsfaaron/silc_cfi/v32_htdub"
UNI <- Sys.getenv("UNI_FILE", "v29_run/silc_cfi_unified_treelists_v29.csv")
spec <- .load_silc_specs("silc_merch_specs.csv")
cat(sprintf("=== v29 scorecard | mode=%s | uni=%s ===\n", TAG, UNI))

# ---- prices (unchanged from v25-v28) ---------------------------------------
pr <- read.csv("aroostook_stumpage.csv", stringsAsFactors = FALSE)
pr <- pr[pr$kind == "observed" & pr$year <= 2024, ]
price_of <- function(product, sppgrp) {
  s <- pr[pr$product == product & pr$species == sppgrp, ]
  if (nrow(s) == 0) return(NA_real_); s$price_real_2024[which.max(s$year)]
}
SAWG <- c(BF="SPRUCE & FIR",RS="SPRUCE & FIR",BS="SPRUCE & FIR",WS="SPRUCE & FIR",
  NS="SPRUCE & FIR",RP="SPRUCE & FIR",RN="SPRUCE & FIR",TA="SPRUCE & FIR",
  WP="WHITE PINE",EH="HEMLOCK",WC="CEDAR",SM="SUGAR MAPLE",RM="RED/WHITE MAPLE",
  YB="YELLOW BIRCH",WA="ASH",BA="ASH",GA="ASH",AS="ASH",RO="RED OAK",AB="BEECH",
  PB="WHITE BIRCH",GB="WHITE BIRCH",SB="WHITE BIRCH",QA="ASPEN/POPLAR",
  BT="ASPEN/POPLAR",BP="ASPEN/POPLAR")
PULPG <- function(sp){ if (sp %in% c("BF","RS","BS","WS","NS","WP","RP","RN","JP","TA","OS")) "SPRUCE & FIR"
  else if (sp=="EH") "HEMLOCK" else if (sp=="WC") "CEDAR"
  else if (sp %in% c("QA","BT","BP")) "ASPEN/POPLAR" else "MIXED HARDWOOD" }
STUDG <- function(sp) if (sp %in% c("BF","RS","BS","WS","NS","RP","RN")) "SPRUCE & FIR" else "OTHER SPECIES"
saw_price <- function(sp){ g<-SAWG[sp]; if(is.na(g)) return(0); v<-price_of("SAWLOGS",unname(g)); if(is.na(v)) 0 else v }
pulp_price<- function(sp){ v<-price_of("PULPWOOD",PULPG(sp)); if(is.na(v)) 0 else v }
stud_price<- function(sp){ v<-price_of("STUDWOOD",STUDG(sp)); if(is.na(v)) 0 else v }
PALLET_P_HW <- price_of("PALLETWOOD","HARDWOOD")
allsp <- c("BF","RS","BS","WS","NS","WP","RP","RN","EH","WC","JP","TA","OS","SM","RM","YB",
           "WA","BA","GA","AS","RO","AB","PB","GB","SB","QA","BT","BP","OH","ST","BC","AE",
           "BL","BW","NC","HH","PR")
SAW_P<-sapply(allsp,saw_price); PULP_P<-sapply(allsp,pulp_price); STUD_P<-sapply(allsp,stud_price)

# ---- NSVB emulator for aboveground dry biomass -----------------------------
co  <- fread("/users/PUOM0008/crsfaaron/magplot/verify/nsvb_emulator_coefs.csv")
sgx <- fread("/users/PUOM0008/crsfaaron/magplot/verify/spcd_spgrpcd.csv")
# AcadianGY 2-letter code -> FIA SPCD (same crosswalk the FVS-ACD parity harness uses)
AGY2SPCD <- c(BF=12,RS=97,BS=95,WS=94,NS=91,WP=129,RP=125,RN=125,JP=105,TA=71,EH=261,
  WC=241,OS=299,SM=318,RM=316,YB=371,PB=375,GB=379,SB=372,AB=531,QA=746,BT=743,BP=741,
  WA=541,BA=543,GA=544,AS=541,RO=833,OH=999,ST=935,BC=762,AE=972,BL=951,BW=951,NC=241,
  HH=701,PR=760)
spgrp_of <- function(sp){
  s <- AGY2SPCD[sp]; if (is.na(s)) return(NA_integer_)
  g <- sgx$SPGRPCD[match(s, sgx$SPCD)]; if (is.na(g)) NA_integer_ else g
}
# fallback group: 6 (eastern softwood) / 25-ish hardwood; use the most common in-frame group
drybio_ag_lb <- function(sp, dbh_cm, ht_m){
  g <- spgrp_of(sp)
  r <- if (!is.na(g)) co[SPGRPCD==g] else co[0]
  if (nrow(r)==0) r <- co[which.max(co$n)]          # largest-n group as fallback
  a <- r$DRYBIO_AG_a[1]; b <- r$DRYBIO_AG_b[1]; sm <- r$DRYBIO_AG_sm[1]
  if (!is.finite(a) || !is.finite(b)) return(NA_real_)
  dia_in <- dbh_cm/2.54; ht_ft <- ht_m/0.3048
  if (!is.finite(dia_in) || !is.finite(ht_ft) || dia_in<=0 || ht_ft<=0) return(0)
  exp(a + b*log(dia_in^2 * ht_ft)) * (if (is.finite(sm)) sm else 1)
}

# ---- treelist --------------------------------------------------------------
uni <- as.data.frame(fread(UNI))
uni <- uni[is.finite(suppressWarnings(as.numeric(uni$dbh_cm))), ]
uni$dbh_cm<-as.numeric(uni$dbh_cm); uni$ht_m<-as.numeric(uni$ht_m); uni$expf_tph<-as.numeric(uni$expf_tph)
ps <- read.csv("silc_cfi_longhorizon_pairs_v16.csv", stringsAsFactors = FALSE)
ps$estbl <- (ps$BA_CURR_FT2AC / pmax(ps$BA_PREV_FT2AC,1)) > 2.0
routine <- ps$PLOT[!ps$estbl]; n_routine <- length(routine)
uni <- uni[uni$PLOT %in% routine, ]; uni$expf_ac <- uni$expf_tph / ACRES_PER_HA
cat(sprintf("Routine plots %d | rows %d | configs: %s\n", n_routine, nrow(uni),
            paste(sort(unique(uni$model_config)), collapse=", ")))

key <- paste(uni$sp, round(uni$dbh_cm,1), round(uni$ht_m,1), sep="|"); uk <- unique(key)
suppressMessages(library(parallel)); ncores <- max(1, detectCores()-1)
ukm <- do.call(rbind, mclapply(uk, function(k){
  p <- strsplit(k,"\\|")[[1]]
  m <- merch_silc_tree(p[1], as.numeric(p[2]), as.numeric(p[3]), spec)
  c(m, bio_lb = drybio_ag_lb(p[1], as.numeric(p[2]), as.numeric(p[3])))
}, mc.cores = ncores))
rownames(ukm) <- uk; M <- ukm[key, , drop=FALSE]

CF <- M3_TO_FT3/CORD_FT3
uni$gross4_cd <- M[,"gross4"] * CF * uni$expf_ac      # PRIMARY 1
uni$tot_cd    <- M[,"merch"]  * CF * uni$expf_ac      # v23-v28 basis, retained
uni$totstem_cd<- M[,"total"]  * CF * uni$expf_ac      # whole-stem, context only
uni$saw_cd<-M[,"saw"]*CF*uni$expf_ac; uni$stud_cd<-M[,"stud"]*CF*uni$expf_ac
uni$pallet_cd<-M[,"pallet"]*CF*uni$expf_ac; uni$pulp_cd<-M[,"pulp"]*CF*uni$expf_ac
uni$saw_mbf<-M[,"saw_bf"]*uni$expf_ac/1000; uni$pallet_mbf<-M[,"pallet_bf"]*uni$expf_ac/1000
uni$agb_Mg <- M[,"bio_lb"] * LB_KG/1000 * uni$expf_ac          # PRIMARY 2, Mg ac-1
uni$agc_Mg <- uni$agb_Mg * CARBON_FRACTION
si <- match(uni$sp, allsp); si[is.na(si)] <- match("OH", allsp)
uni$saw_val<-uni$saw_mbf*SAW_P[si]; uni$stud_val<-uni$stud_cd*STUD_P[si]
uni$pallet_val<-uni$pallet_mbf*PALLET_P_HW; uni$pulp_val<-uni$pulp_cd*PULP_P[si]
uni$tot_val <- uni$saw_val+uni$stud_val+uni$pallet_val+uni$pulp_val

fl <- c("gross4_cd","tot_cd","totstem_cd","saw_cd","stud_cd","pallet_cd","pulp_cd",
        "saw_mbf","pallet_mbf","agb_Mg","agc_Mg",
        "saw_val","stud_val","pallet_val","pulp_val","tot_val")
agg <- aggregate(uni[fl], by=list(model_config=uni$model_config, PLOT=uni$PLOT), FUN=sum)
obs <- agg[agg$model_config=="OBSERVED", ]
okeep <- c("gross4_cd","tot_cd","totstem_cd","saw_cd","stud_cd","pallet_cd","pulp_cd","agb_Mg","agc_Mg","tot_val")
obs2 <- obs[, c("PLOT", okeep)]; names(obs2)[-1] <- paste0(okeep,"_o")

bias <- function(p,o) 100*(mean(p,na.rm=TRUE)/mean(o,na.rm=TRUE)-1)
r2 <- function(p,o){ok<-is.finite(p)&is.finite(o); if(sum(ok)<3) return(NA_real_)
  1-sum((o[ok]-p[ok])^2)/sum((o[ok]-mean(o[ok]))^2)}
configs <- c("AGM_v835","AGM_v836","AGM_v836_native","AGM_v840_meas","OSM_ACD","FVS_NE_default","FVS_ACD_default",
             "FVSACD_v1211_full","FVSACD_v131_full","FVSACD_v131_ship18",
             "FVSACD_v14_L1","FVSACD_v14_L2",
             "FVSACD_v131_hier_meas","FVSACD_v131_hier_dub","FVSACD_v14_L1_meas","FVSACD_v14_L1_dub",
             "FVSACD_v14_L2_meas","FVSACD_v14_L2_dub")
labels <- c("AGM v8.35 (byPlot)","AGM v8.36 (byStrata)","AGM v8.36 (byStrata, native table)",
            "AGM v8.40 (byStrata, measured heights)","OSM-ACD","FVS-NE default",
            "FVS-ACD default (v16-v22 vintage)","FVS-ACD v12.11 (full137)",
            "FVS-ACD v13.1 hierarchical (full137)","FVS-ACD v13.1 ship18 (full137)",
            "FVS-ACD v14 L1 (full137)","FVS-ACD v14 L2 (full137)",
            "FVS-ACD v13.1 hierarchical, measured heights","FVS-ACD v13.1 hierarchical, imputed heights",
            "FVS-ACD v14 L1, measured heights","FVS-ACD v14 L1, imputed heights",
            "FVS-ACD v14 L2, measured heights","FVS-ACD v14 L2, imputed heights")
family <- c("AGM","AGM","AGM","AGM","OSM","FVS-NE",rep("FVS-ACD",12))
stopifnot(length(configs)==length(labels), length(labels)==length(family))
rows <- list()
for (k in seq_along(configs)) {
  m <- merge(agg[agg$model_config==configs[k],], obs2, by="PLOT")
  if (nrow(m)==0) { cat(sprintf("NOTE: '%s' absent from this treelist, skipped.\n", configs[k])); next }
  rows[[length(rows)+1]] <- data.frame(model=labels[k], family=family[k], n=nrow(m),
    gross4_bias=round(bias(m$gross4_cd,m$gross4_cd_o),1),
    gross4_R2  =round(r2(m$gross4_cd,m$gross4_cd_o),3),
    agc_bias   =round(bias(m$agc_Mg,m$agc_Mg_o),1),
    agc_R2     =round(r2(m$agc_Mg,m$agc_Mg_o),3),
    netmerch_bias=round(bias(m$tot_cd,m$tot_cd_o),1),
    saw_bias=round(bias(m$saw_cd,m$saw_cd_o),1),
    stud_bias=round(bias(m$stud_cd,m$stud_cd_o),1),
    pallet_bias=round(bias(m$pallet_cd,m$pallet_cd_o),1),
    pulp_bias=round(bias(m$pulp_cd,m$pulp_cd_o),1),
    value_bias=round(bias(m$tot_val,m$tot_val_o),1),
    value_R2=round(r2(m$tot_val,m$tot_val_o),3),
    mean_gross4=round(mean(m$gross4_cd),2),
    mean_agc=round(mean(m$agc_Mg),2),
    mean_val=round(mean(m$tot_val),0))
}
sc <- do.call(rbind, rows)
om <- obs[obs$PLOT %in% routine, ]
cat(sprintf("\nObserved means: gross4 %.2f cd/ac | net merch %.2f cd/ac | whole stem %.2f cd/ac | AGB %.2f Mg/ac | AGC %.2f Mg/ac | value $%.0f/ac\n",
  mean(om$gross4_cd),mean(om$tot_cd),mean(om$totstem_cd),mean(om$agb_Mg),mean(om$agc_Mg),mean(om$tot_val)))
cat(sprintf("Observed product split (cd/ac): sawlog %.2f | studwood %.2f | pallet %.2f | pulp %.2f\n",
  mean(om$saw_cd),mean(om$stud_cd),mean(om$pallet_cd),mean(om$pulp_cd)))
cat(sprintf("Observed value split ($/ac): sawlog %.0f | studwood %.0f | pallet %.0f | pulp %.0f\n\n",
  mean(om$saw_val),mean(om$stud_val),mean(om$pallet_val),mean(om$pulp_val)))
print(sc, row.names=FALSE)
write.csv(sc,  file.path(OUT, sprintf("silc_cfi_v32ht_scorecard_%s_DATA_2026-09-23.csv", TAG)), row.names=FALSE)
write.csv(agg, file.path(OUT, sprintf("silc_cfi_v32ht_byplot_%s_DATA_2026-09-23.csv", TAG)), row.names=FALSE)
cat(sprintf("\nCARBON_FRACTION applied: %.2f (FIA default, stated not silent). AGB is NSVB-emulator DRYBIO_AG.\n", CARBON_FRACTION))
cat(sprintf("DONE in %.1f min\n", as.numeric(difftime(Sys.time(),t0,units="mins"))))

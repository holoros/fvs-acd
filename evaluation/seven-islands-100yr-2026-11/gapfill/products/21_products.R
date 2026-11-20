#!/usr/bin/env Rscript
# SILC products add-on, step 3 (19 Nov 2026). Per plot and year: merchantable cords (total, sawlog, pulp), sawlog MBF (International 1/4),
# stumpage value ($ ac^-1, real 2024 $) and aboveground live tree carbon, for the five primary arms.
# Merch and value: the SILC v22 pipeline unchanged (kozak_taper.R, merch_cords.R, merch_asg.R: Kozak taper, Smith ASG merchandizing,
# SILC CFI grade rates, 79 ft3 solid wood per cord) priced with Aroostook County 2024 Maine Forest Service stumpage.
# Two deviations from v22, both logged: (1) the Maine FS report quotes pulpwood in $/ton, which v22 applied as $/cord; here pulp is
# converted with the report's tons per cord (spruce-fir 2.1, hemlock 2.4, cedar 1.7, aspen 2.15, hardwood 2.7); (2) species with no
# Aroostook sawlog price (white birch, beech, aspen, red oak) take the 2024 statewide average instead of $0.
# Carbon: NSVB total aboveground biomass (Westfall et al. 2024, GTR-WO-104; segmented model k = 9 softwood, 11 hardwood; species x
# ecological division 210, then species, then Jenkins group), times each species' carbon fraction taken from the US Forest Service FIA
# Maine TREE table (median CARBON_AG / DRYBIO_AG). Live trees >= 2.54 cm. Stress alternatives: v22 pulp handling, statewide prices,
# constant 0.50 carbon fraction. usage: Rscript 21_products.R  (run from the job folder holding the v22 R files)
source("kozak_taper.R"); source("merch_cords.R"); source("merch_asg.R")
H <- path.expand("~"); P <- file.path(H, "restricted/silc_agmbench_gapfill_20261117/products")
NS <- file.path(H, "jobs/bakuzis_fvsconus_20261027/repos/fvs-modern/data/NSBE")
HA <- 2.4710538147; FT3 <- 35.314667; CORD <- 79
ARMS <- c(osm = "OSM 2.26.1", fvs_ne = "FVS-NE", prod_fix_ing1 = "FVS-ACD 12.5.2 production",
          x142sb_ingT0 = "FVS-ACD 14.2 brms SDImax", x143m1l5m2_ingT0 = "FVS-ACD 14.3 + SDImax cap")
# ---- species: everything to FIA SPCD, then to the AGY code the v22 merch and price tables use -----------------------------
AGY2SP <- c(BF=12, RS=97, WS=94, BS=95, NS=91, EH=261, HE=261, WP=129, RN=125, RP=125, JP=105, TA=71, TL=71, WC=241, NC=241, CE=241,
            RM=316, SM=318, ST=315, MM=319, YB=371, PB=375, WB=375, GB=379, SB=372, AB=531, BE=531, QA=746, BT=743, BP=741,
            WA=541, BA=543, GA=544, AS=541, RO=833, PR=761, PC=761, BC=762, HH=701, BW=951, EC=742, OH=998, OS=299)
SP2AGY <- c(`12`="BF",`97`="RS",`94`="WS",`95`="BS",`91`="NS",`261`="EH",`129`="WP",`125`="RN",`105`="JP",`71`="TA",`241`="WC",
            `316`="RM",`318`="SM",`315`="ST",`319`="MM",`371`="YB",`375`="PB",`379`="GB",`372`="SB",`531`="AB",`746`="QA",`743`="BT",
            `741`="BP",`541`="WA",`543`="BA",`544`="GA",`833`="RO",`761`="PR",`762`="BC",`701`="HH",`951`="BW",`742`="EC")
ref <- read.csv(file.path(NS, "REF_SPECIES.csv"), check.names = FALSE)[, c("SPCD", "JENKINS_SPGRPCD", "SFTWD_HRDWD")]
names(ref)[1] <- "SPCD"; ref <- ref[!duplicated(ref$SPCD), ]; rownames(ref) <- ref$SPCD
rd <- function(a) { x <- read.csv(file.path(P, paste0("tl_", a, ".csv"))); x$arm <- a; if (!"spcd" %in% names(x)) x$spcd <- NA_real_
  x[, c("plot_id", "year_offset", "sp", "spcd", "dbh_cm", "ht_m", "tph", "arm")] }
TL <- do.call(rbind, lapply(names(ARMS), rd))
TL$spcd[is.na(TL$spcd)] <- AGY2SP[TL$sp[is.na(TL$spcd)]]
unk <- is.na(TL$spcd); cat("records with unmapped species:", sum(unk), "of", nrow(TL), "codes:", paste(unique(TL$sp[unk]), collapse = " "), "\n")
TL$spcd[unk] <- 998
TL <- TL[TL$dbh_cm >= 2.54 & TL$tph > 0 & TL$ht_m > 1.37, ]
sw <- ref[as.character(TL$spcd), "SFTWD_HRDWD"] == "S"; sw[is.na(sw)] <- FALSE
TL$agy <- SP2AGY[as.character(TL$spcd)]; TL$agy[is.na(TL$agy)] <- ifelse(sw[is.na(TL$agy)], "OS", "OH")
TL$sw <- sw
# ---- merch, per unique (species, dbh 0.1 cm, ht 0.1 m) --------------------------------------------------------------------
# merch is evaluated once per (species, dbh to 0.5 cm, height to 0.5 m) cell and rescaled to each tree by (D/D1)^2 (H/H1);
# trees below the 10.16 cm pulp top carry no merchantable volume and are skipped (0.05 s per tree made a per-tree pass too slow)
TL$d1 <- round(TL$dbh_cm * 2) / 2; TL$h1 <- pmax(round(TL$ht_m * 2) / 2, 1.5); key <- paste(TL$agy, TL$d1, TL$h1)
mer <- TL$dbh_cm >= 10.16
U <- TL[mer & !duplicated(key), c("agy", "d1", "h1")]; U <- U[!duplicated(paste(U$agy, U$d1, U$h1)), ]; cat("unique merch cells:", nrow(U), "\n")
library(parallel); NC <- as.integer(Sys.getenv("NCORES", "3")); ch <- split(seq_len(nrow(U)), cut(seq_len(nrow(U)), NC * 4, labels = FALSE))
t0 <- Sys.time(); M <- do.call(rbind, mclapply(ch, function(ii) t(mapply(merch_asg_tree, U$agy[ii], U$d1[ii], U$h1[ii], USE.NAMES = FALSE)), mc.cores = NC)); cat("merch secs", round(as.numeric(Sys.time() - t0, units = "secs")), "\n")
M <- as.data.frame(M); rownames(M) <- paste(U$agy, U$d1, U$h1); MM <- M[key, ]; MM[is.na(MM)] <- 0; MM[!mer, ] <- 0
sc <- (TL$dbh_cm / TL$d1)^2 * (TL$ht_m / TL$h1); sc[!is.finite(sc)] <- 1; MM <- MM * sc
ac <- TL$tph / HA
TL$tot_cd <- MM$merch * FT3 / CORD * ac; TL$saw_cd <- MM$saw * FT3 / CORD * ac; TL$pulp_cd <- MM$pulp * FT3 / CORD * ac
TL$saw_mbf <- MM$saw_bf * ac / 1000
# ---- prices --------------------------------------------------------------------------------------------------------------
pr <- read.csv("aroostook_stumpage_2024.csv", stringsAsFactors = FALSE)
STATE_SAW <- c(`WHITE BIRCH` = 223, BEECH = 115, `ASPEN/POPLAR` = 76, `RED OAK` = 293)    # Maine FS 2024 statewide average $/MBF
STATE_ALL_SAW <- c(ASH=231, `ASPEN/POPLAR`=76, BEECH=115, CEDAR=81, HEMLOCK=69, `RED OAK`=293, `RED/WHITE MAPLE`=183, `SPRUCE & FIR`=108,
                   `SUGAR MAPLE`=251, `WHITE BIRCH`=223, `WHITE PINE`=208, `YELLOW BIRCH`=204)
STATE_ALL_PULP <- c(`ASPEN/POPLAR`=9, CEDAR=20, HEMLOCK=3, `MIXED HARDWOOD`=7, `SPRUCE & FIR`=4)          # $/ton
TPC <- c(`SPRUCE & FIR`=2.1, HEMLOCK=2.4, CEDAR=1.7, `ASPEN/POPLAR`=2.15, `MIXED HARDWOOD`=2.7)          # Maine FS tons per cord (advisory)
SAWG <- c(BF="SPRUCE & FIR",RS="SPRUCE & FIR",BS="SPRUCE & FIR",WS="SPRUCE & FIR",NS="SPRUCE & FIR",RP="SPRUCE & FIR",RN="SPRUCE & FIR",
  TA="SPRUCE & FIR",JP="SPRUCE & FIR",OS="SPRUCE & FIR",WP="WHITE PINE",EH="HEMLOCK",WC="CEDAR",SM="SUGAR MAPLE",RM="RED/WHITE MAPLE",
  YB="YELLOW BIRCH",WA="ASH",BA="ASH",GA="ASH",AS="ASH",RO="RED OAK",AB="BEECH",PB="WHITE BIRCH",GB="WHITE BIRCH",SB="WHITE BIRCH",
  QA="ASPEN/POPLAR",BT="ASPEN/POPLAR",BP="ASPEN/POPLAR")
pulpg <- function(a) ifelse(a %in% c("BF","RS","BS","WS","NS","WP","RP","RN","JP","TA","OS"), "SPRUCE & FIR", ifelse(a == "EH", "HEMLOCK",
  ifelse(a == "WC", "CEDAR", ifelse(a %in% c("QA","BT","BP"), "ASPEN/POPLAR", "MIXED HARDWOOD"))))
aro <- function(prod, g) { s <- pr$price_real_2024[pr$product == prod & pr$species == g]; if (length(s)) s[1] else NA }
g_saw <- unname(SAWG[TL$agy]); g_pulp <- pulpg(TL$agy)
saw_aro <- sapply(g_saw, function(g) if (is.na(g)) NA else aro("SAWLOGS", g))
fill <- is.na(saw_aro) & !is.na(g_saw); saw_p <- saw_aro; saw_p[fill] <- STATE_SAW[g_saw[fill]]; saw_p[is.na(saw_p)] <- 0
pulp_ton <- sapply(g_pulp, function(g) aro("PULPWOOD", g)); pulp_ton[is.na(pulp_ton)] <- 0
TL$saw_val <- TL$saw_mbf * saw_p; TL$pulp_val <- TL$pulp_cd * pulp_ton * TPC[g_pulp]
TL$val <- TL$saw_val + TL$pulp_val
TL$val_v22pulp <- TL$saw_val + TL$pulp_cd * pulp_ton                                   # stress: v22 ($/ton applied per cord)
sp_state <- ifelse(is.na(g_saw), 0, STATE_ALL_SAW[g_saw]); sp_state[is.na(sp_state)] <- 0
TL$val_state <- TL$saw_mbf * sp_state + TL$pulp_cd * STATE_ALL_PULP[g_pulp] * TPC[g_pulp] # stress: statewide 2024 prices
cat("sawlog value from fallback statewide prices: share", round(sum(TL$saw_val[fill], na.rm = TRUE) / sum(TL$saw_val, na.rm = TRUE), 4), "\n")
# ---- NSVB aboveground biomass and carbon ---------------------------------------------------------------------------------
B <- read.csv(file.path(NS, "Coefs/combined/total_biomass_coefs.csv"), stringsAsFactors = FALSE)
pick <- function(spcd) {
  r <- B[!is.na(B$SPCD_DIVISION) & B$SPCD_DIVISION == paste(spcd, "210"), ]
  if (!nrow(r)) r <- B[!is.na(B$SPCD) & B$SPCD == as.character(spcd), ]
  if (!nrow(r)) { j <- ref[as.character(spcd), "JENKINS_SPGRPCD"]; r <- B[!is.na(B$JENKINS_SPGRPCD) & B$JENKINS_SPGRPCD == j, ] }
  if (!nrow(r)) stop(paste("no NSVB biomass coefficients for SPCD", spcd)); r[1, ]
}
agb_lb <- function(c, D, Ht, k) switch(as.character(c$equation),
  `3` = c$a * D^c$b * Ht^c$c,
  `4` = ifelse(D < k, c$a0 * D^c$b0 * Ht^c$c, c$a0 * k^(c$b0 - c$b1) * D^c$b1 * Ht^c$c),
  `5` = c$a * D^(c$a1 * (1 - exp(-c$b1 * D))^c$c1) * Ht^c$c,
  `50` = c$a * D^c$b * Ht^c$c * exp(-(c$b2 * D)), stop(paste("form", c$equation)))
TL$agb_kg <- NA_real_
for (s in unique(TL$spcd)) { i <- TL$spcd == s; cf <- pick(s); k <- if (isTRUE(TL$sw[which(i)[1]])) 9 else 11
  TL$agb_kg[i] <- agb_lb(cf, TL$dbh_cm[i] / 2.54, TL$ht_m[i] / 0.3048, k) * 0.45359237 }
hdr <- strsplit(readLines(file.path(H, "fia_data/ME_TREE.csv"), n = 1), ",")[[1]]; ix <- match(c("STATUSCD", "SPCD", "CARBON_AG", "DRYBIO_AG"), gsub('"', "", hdr))
stopifnot(!anyNA(ix), all(diff(ix) > 0))
cfr <- read.csv(pipe(paste0("cut -d, -f", paste(ix, collapse = ","), " ", file.path(H, "fia_data/ME_TREE.csv"))), colClasses = "character")
names(cfr) <- c("STATUSCD", "SPCD", "CARBON_AG", "DRYBIO_AG")
cfr$SPCD <- as.character(as.integer(as.numeric(cfr$SPCD))); cfr <- cfr[as.numeric(cfr$STATUSCD) %in% 1, ]; cfr$r <- as.numeric(cfr$CARBON_AG) / as.numeric(cfr$DRYBIO_AG); cfr <- cfr[is.finite(cfr$r) & cfr$r > 0.3 & cfr$r < 0.7, ]
CF <- tapply(cfr$r, cfr$SPCD, median); swc <- ref[names(CF), "SFTWD_HRDWD"] == "S"
cf_sw <- median(CF[which(swc)]); cf_hw <- median(CF[which(!swc)])
cat("carbon fraction n species", length(CF), "| SW median", round(cf_sw, 4), "HW median", round(cf_hw, 4),
    "| BF", round(CF["12"], 4), "RS", round(CF["97"], 4), "RM", round(CF["316"], 4), "YB", round(CF["371"], 4), "\n")
fr <- CF[as.character(TL$spcd)]; fr[is.na(fr)] <- ifelse(TL$sw[is.na(fr)], cf_sw, cf_hw)
TL$agc_mgha <- TL$agb_kg * fr * TL$tph / 1000; TL$agc05_mgha <- TL$agb_kg * 0.5 * TL$tph / 1000
# ---- plot totals ---------------------------------------------------------------------------------------------------------
v <- c("tot_cd", "saw_cd", "pulp_cd", "saw_mbf", "saw_val", "pulp_val", "val", "val_v22pulp", "val_state", "agc_mgha", "agc05_mgha")
A <- aggregate(TL[, v], by = list(arm = TL$arm, plot_id = TL$plot_id, year_offset = TL$year_offset), FUN = sum)
A$arm_label <- ARMS[A$arm]; A$co2e_tac <- A$agc_mgha * 44 / 12 / HA
write.csv(A, file.path(P, "products_by_plot.csv"), row.names = FALSE)
s <- aggregate(A[, c(v, "co2e_tac")], by = list(arm = A$arm_label, year = A$year_offset), FUN = mean)
print(s[s$year %in% c(0, 100), c("arm", "year", "tot_cd", "saw_mbf", "val", "agc_mgha", "co2e_tac")], row.names = FALSE, digits = 4)
cat("DONE\n")

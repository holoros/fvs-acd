## v143p3_conf_fia.R
## 14.3 pre-registration 3 (draft 1, md5 72c9c7e4), step 1: confirmation set lookup, candidate sources 1 and 2.
##   Source 1: Maine post-harvest FIA triples whose v2 visit postdates the mefia_ph_c frame.
##   Source 2: New Hampshire post-harvest FIA triples from visits later than the PREREG2 NH and VT set, east of 71.5 W
##             (read as: the Acadian ESI v8 30 m raster, whose extent ends at 71.5 W, has a value above 2 there).
## Host: firebreather. FIA source: the FIADB state CSVs downloaded 26 September 2026 (jobs/rdgrowth_trial_20260926/fia_raw),
## which hold visits to MEASYEAR 2025 (ME) and 2026 (NH). The mefia_ph_c frame and the PREREG2 NH and VT set were built on
## Cardinal from FIADB files whose latest MEASYEAR is 2024 (ME_PLOT.csv of 17 April 2026, NH_PLOT.csv of 30 May 2026).
## NEW-DATA RULE (fixed here before any count): a triple is new when its v2 MEASYEAR is 2025 or later; no new triple can
## then be in either excluded frame, without moving any identifier between hosts (gate H7 by construction). A new triple
## whose plot chain also carries a qualifying triple with v2 at or before 2024 is labelled "same plots, new interval".
## DEFINITIONS: PREREG1 rule 7, exactly as v143p2_sealed_build.R applies it (v0-v1-v2 triples; PLOT_STATUS_CD 1 at all
## three; TRTCD 10 at v1; single forested condition at v0, v1, v2; v2 free of treatment, fire and human disturbance; at
## least 3 live trees at v1 and v2; harvest class from PCT_REMOVED of v0 merchantable volume, r1 removal rule; TST known
## when the v1 condition carries a harvest year in [y0, y1 - 1]).
## READ RESTRICTION (PREREG2 H6, as the draft's step 2): this script reads only stand counts by harvest class and source,
## ESI coverage, and survivor tree counts by d / Dq class at v1 (status only: live at v1 and live at the linked v2 record).
## It reads no v2 diameter, computes no growth, no prediction, no gap and no ratio. Every read is listed in the allowlist
## log it writes. Coordinates (PLOT LAT, LON) are passed only to gdallocationinfo through a pipe, held in memory and
## dropped; nothing with a coordinate or an identifier is written or printed. No em dashes.
suppressMessages(library(data.table))
FIA  <- "/home/aaron/jobs/rdgrowth_trial_20260926/fia_raw"
RAST <- "/home/aaron/jobs/na30/rasters/acadian/Acadian_ESI_v8_30m.tif"
OUT  <- "/home/aaron/jobs/v143p3/out"; dir.create(OUT, FALSE, TRUE)
fo <- file.path(OUT, c("conf_fia_counts_DATA.csv", "conf_fia_survivors_DATA.csv", "conf_fia_allowlist_reads.log"))
if (any(file.exists(fo))) stop("refusing to overwrite ", fo[file.exists(fo)][1])
AL <- character(0); al <- function(s) AL <<- c(AL, sprintf("%s  %s", format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"), s))
NEWY <- 2025L; RELB <- c(0, 0.6, 0.85, 1.15, 1.5, Inf)
one_state <- function(S) {
  al(sprintf("%s_PLOT.csv: CN, PREV_PLT_CN, MEASYEAR, PLOT_STATUS_CD", S))
  pl <- fread(file.path(FIA, sprintf("%s_PLOT.csv", S)), select = c("CN", "PREV_PLT_CN", "MEASYEAR", "PLOT_STATUS_CD"),
              colClasses = list(character = c("CN", "PREV_PLT_CN")))
  pl[PREV_PLT_CN %in% c("", "NA"), PREV_PLT_CN := NA_character_]
  parent <- setNames(pl$PREV_PLT_CN, pl$CN); parent[!(parent %in% pl$CN)] <- NA_character_
  root_of <- function(cn) { r <- cn; for (i in 1:60) { p <- unname(parent[r]); mv <- !is.na(p); if (!any(mv)) break; r[mv] <- p[mv] }; r }
  pl[, root := root_of(CN)]
  yr <- setNames(pl$MEASYEAR, pl$CN); ps <- setNames(pl$PLOT_STATUS_CD, pl$CN)
  tri <- pl[!is.na(parent[CN]), .(cn2 = CN, cn1 = unname(parent[CN]))][, cn0 := unname(parent[cn1])][!is.na(cn0)]
  tri[, `:=`(y0 = yr[cn0], y1 = yr[cn1], y2 = yr[cn2], root = pl$root[match(cn1, pl$CN)])]
  tri <- tri[y1 > y0 & y2 > y1]
  al(sprintf("%s_COND.csv: PLT_CN, CONDID, COND_STATUS_CD, DSTRBCD1-3, TRTCD1-3, TRTYR1-3", S))
  co <- fread(file.path(FIA, sprintf("%s_COND.csv", S)), select = c("PLT_CN", "CONDID", "COND_STATUS_CD", "DSTRBCD1", "DSTRBCD2", "DSTRBCD3",
              "TRTCD1", "TRTCD2", "TRTCD3", "TRTYR1", "TRTYR2", "TRTYR3"), colClasses = list(character = "PLT_CN"))
  for (cc in c("DSTRBCD1", "DSTRBCD2", "DSTRBCD3", "TRTCD1", "TRTCD2", "TRTCD3")) set(co, which(is.na(co[[cc]])), cc, 0L)
  cs <- co[, { d <- c(DSTRBCD1, DSTRBCD2, DSTRBCD3); t <- c(TRTCD1, TRTCD2, TRTCD3); ty <- c(TRTYR1, TRTYR2, TRTYR3)
    hy <- ty[t == 10 & is.finite(ty) & ty > 1900 & ty < 9999]
    .(ncond = .N, allfor = all(COND_STATUS_CD %in% 1L), harv = any(t == 10), trt = any(t != 0), fire = any(d %in% 30:32), human = any(d == 80),
      harv_yr = if (length(hy)) max(hy) else NA_integer_) }, by = PLT_CN]
  g <- function(v, k) cs[match(tri[[v]], cs$PLT_CN), get(k)]
  for (s in c("0", "1", "2")) for (k in c("ncond", "allfor", "harv", "trt", "fire", "human", "harv_yr")) tri[, (paste0(k, "_", s)) := g(paste0("cn", s), k)]
  tri <- tri[ps[cn0] %in% 1 & ps[cn1] %in% 1 & ps[cn2] %in% 1]
  tri <- tri[harv_1 %in% TRUE]
  tri <- tri[ncond_0 == 1 & ncond_1 == 1 & ncond_2 == 1 & allfor_0 & allfor_1 & allfor_2]
  tri <- tri[!trt_2 & !fire_2 & !human_2]
  al(sprintf("%s_TREE.csv: CN, PLT_CN, PREV_TRE_CN, STATUSCD, DIA, TPA_UNADJ, VOLCFNET, AGENTCD, AGENTCD_NERS (no v2 DIA is read: v2 records are used for STATUSCD and the link only)", S))
  tr <- fread(file.path(FIA, sprintf("%s_TREE.csv", S)), select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "DIA", "TPA_UNADJ", "VOLCFNET", "AGENTCD", "AGENTCD_NERS"),
              colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))[PLT_CN %in% c(tri$cn0, tri$cn1, tri$cn2)]
  tr[PREV_TRE_CN %in% c("", "NA"), PREV_TRE_CN := NA_character_]
  tr[PLT_CN %in% tri$cn2 & !(PLT_CN %in% c(tri$cn0, tri$cn1)), DIA := NA_real_]   # v2 diameters are never used
  live <- tr[STATUSCD == 1 & (PLT_CN %in% tri$cn2 | (is.finite(DIA) & DIA > 0))]
  live[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ > 0, TPA_UNADJ, fifelse(is.finite(DIA) & DIA < 5, 74.965, 6.018))]
  n1 <- live[PLT_CN %in% tri$cn1, .N, by = PLT_CN]; n2 <- live[PLT_CN %in% tri$cn2, .N, by = PLT_CN]
  tri[, n1 := n1$N[match(cn1, n1$PLT_CN)]][, n2 := n2$N[match(cn2, n2$PLT_CN)]][is.na(n1), n1 := 0L][is.na(n2), n2 := 0L]
  tri <- tri[n1 >= 3L & n2 >= 3L]
  ## harvest class, r1 removal rule on v0 merchantable trees (DIA >= 5 in)
  v0 <- live[PLT_CN %in% tri$cn0 & DIA >= 5]
  v0[, vol := fifelse(is.finite(VOLCFNET), VOLCFNET, 0) * fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ > 0, TPA_UNADJ, 6.018)]
  v1r <- tr[PLT_CN %in% tri$cn1 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN, st1 = STATUSCD, ag = AGENTCD, agn = AGENTCD_NERS)]
  v0[v1r, on = .(CN = PREV_TRE_CN), `:=`(st1 = i.st1, ag = i.ag, agn = i.agn)]
  v0[, fate := fifelse(is.na(st1), "missing", fifelse(st1 == 3L | (st1 == 2L & (ag %in% 80L | agn %in% 80L)), "cut", fifelse(st1 == 2L, "died", fifelse(st1 == 1L, "live", "other"))))]
  rem <- v0[, .(VOL0 = sum(vol), VCUT = sum(vol[fate %in% c("cut", "missing")])), by = PLT_CN]
  tri[, VOL0 := rem$VOL0[match(cn0, rem$PLT_CN)]][, VCUT := rem$VCUT[match(cn0, rem$PLT_CN)]][is.na(VOL0), VOL0 := 0][is.na(VCUT), VCUT := 0]
  tri[, PCT := fifelse(VOL0 > 0, 100 * VCUT / VOL0, NA_real_)]
  tri[, HARVEST_TYPE := fifelse(VOL0 < 1200, "low_volume", fifelse(PCT < 35, "light", fifelse(PCT > 65, "heavy", "intermediate")))]
  tri[, TST_KNOWN := is.finite(harv_yr_1) & (y1 - harv_yr_1) >= 1 & harv_yr_1 >= y0]
  tri[, NEW := y2 >= NEWY]
  oldroots <- tri[NEW == FALSE, unique(root)]
  tri[, SAME_PLOT_NEW_INTERVAL := NEW & root %in% oldroots]
  ## ESI coverage: the Acadian ESI v8 30 m raster at v1, then v2, then v0 (the builder's order); coordinates in memory only
  al(sprintf("%s_PLOT.csv: LAT, LON of new-triple visits, in memory, piped to gdallocationinfo on %s (value above 2 counts as covered)", S, basename(RAST)))
  cns <- unique(tri[NEW == TRUE, c(cn1, cn2, cn0)])
  esi <- setNames(rep(NA_real_, length(cns)), cns)
  if (length(cns)) {
    xy <- fread(file.path(FIA, sprintf("%s_PLOT.csv", S)), select = c("CN", "LAT", "LON"), colClasses = list(character = "CN"))[CN %in% cns & is.finite(LAT) & is.finite(LON)]
    v <- suppressWarnings(as.numeric(system2("gdallocationinfo", c("-wgs84", "-valonly", RAST), input = sprintf("%.6f %.6f", xy$LON, xy$LAT), stdout = TRUE)))
    if (length(v) != nrow(xy)) stop("gdallocationinfo returned ", length(v), " values for ", nrow(xy), " points")
    esi[xy$CN] <- v; rm(xy, v); invisible(gc())
  }
  pick <- function(a, b, c) { x <- esi[a]; k <- !(is.finite(x) & x > 2); x[k] <- esi[b][k]; k <- !(is.finite(x) & x > 2); x[k] <- esi[c][k]; unname(x) }
  tri[NEW == TRUE, ESI_COV := { e <- pick(cn1, cn2, cn0); is.finite(e) & e > 2 }]
  ## survivors at v1 (status only): live v1 trees with DIA >= 5 cm whose linked v2 record has STATUSCD 1, d / Dq class at v1
  nt <- tri[NEW == TRUE & HARVEST_TYPE %in% c("heavy", "intermediate")]
  l1 <- live[PLT_CN %in% nt$cn1 & is.finite(DIA) & DIA > 0]
  dq <- l1[, .(DQ = sqrt(sum(tpa * DIA^2) / sum(tpa))), by = PLT_CN]
  st2 <- tr[PLT_CN %in% nt$cn2 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN, st2 = STATUSCD)]
  l1[st2, on = .(CN = PREV_TRE_CN), st2 := i.st2]
  sv <- merge(l1[st2 %in% 1L & DIA * 2.54 >= 5], dq, by = "PLT_CN")
  sv <- merge(sv, nt[, .(PLT_CN = cn1, ESI_COV, SAME_PLOT_NEW_INTERVAL)], by = "PLT_CN")
  sv[, rcl := cut(DIA / DQ, RELB, right = FALSE)]
  SV <- sv[, .(survivor_trees = .N), by = .(rcl)][order(rcl)][, state := S]
  SVe <- sv[ESI_COV == TRUE, .(survivor_trees_esi = .N), by = .(rcl)]
  SV <- merge(SV, SVe, by = "rcl", all.x = TRUE)[is.na(survivor_trees_esi), survivor_trees_esi := 0L]
  CNT <- tri[, .(triples = .N, heavy = sum(HARVEST_TYPE == "heavy"), intermediate = sum(HARVEST_TYPE == "intermediate"),
                 light = sum(HARVEST_TYPE == "light"), low_volume = sum(HARVEST_TYPE == "low_volume"), known_tst = sum(TST_KNOWN),
                 esi_covered = sum(ESI_COV %in% TRUE), heavy_esi_covered = sum(HARVEST_TYPE == "heavy" & ESI_COV %in% TRUE),
                 same_plots_new_interval = sum(SAME_PLOT_NEW_INTERVAL), v2_year_min = min(y2), v2_year_max = max(y2)), by = .(new_v2_2025_or_later = NEW)]
  CNT[, `:=`(state = S, esi_coverage = fifelse(new_v2_2025_or_later, esi_covered / triples, NA_real_))]
  list(CNT = CNT, SV = SV)
}
R <- lapply(c("ME", "NH"), one_state)
CNT <- rbindlist(lapply(R, `[[`, "CNT")); SV <- rbindlist(lapply(R, `[[`, "SV"))
CNT[, source := fifelse(state == "ME", "1 Maine FIA, v2 after the mefia_ph_c frame", "2 New Hampshire FIA, visits after the PREREG2 set")]
if (any(grepl("^(cn|plt_cn|root|stand|plotkey|lat|lon)", tolower(c(names(CNT), names(SV)))))) stop("identifier or coordinate column in an output")
SV[, `:=`(rcl = as.character(rcl), gated_class = as.numeric(sub("^\\[([0-9.]+),.*$", "\\1", as.character(rcl))) >= 0.6)]
fwrite(CNT, fo[1]); fwrite(SV, fo[2]); writeLines(AL, fo[3])
print(CNT); print(SV)
for (f in fo) cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), basename(f)))
cat("CONF_FIA_DONE\n")

## v143p2_sealed_build.R
## 14.3 pre-registration 2 (revision 5, md5 b7562e8b), step 2: the SEALED New Hampshire and Vermont post-harvest FIA
## set (SET nhvt_ph_c, stand prefix NHVT_PH__), built with PREREG1 rule 7's definitions: a copy of the mefia_ph_c builder
## (~/acdx_20261016/postharv/scripts/2026-10-16_mefia_ph_frame_builder.R) with its r1 classification
## (2026-10-16_mefia_ph_class_r1.R) folded in. READ RESTRICTED: this script builds the frame and the harvest class only.
## It computes and prints no growth, no survivor ratio and no gap; the AGB columns of the class file stay on the server.
##
## REGISTERED DIFF against the mefia_ph_c builder (recorded with its md5 before this script runs; logs/sealed_diff.txt):
##  D1 state tables: NH and VT instead of ME (PLOT, COND, TREE read for both states and stacked; CNs are unique);
##     JURIS is the state abbreviation; DS NHVT_PH; SET nhvt_ph_c; PROV NHVT_FIA_PH.
##  D2 the mefia_l_c validation step (height source and ESI extraction) is replaced by the same checks against an
##     unmanaged New Hampshire and Vermont set built by this copy (chains v1 -> v2 with a single forested condition at
##     both visits, no treatment code at either visit, no fire or human disturbance at v2). The height column is the
##     Maine builder's validated choice (ACTUALHT, 918 of 918 mefia_l_c stands identical); the check reports the share
##     of live trees with a usable ACTUALHT and with HT in both NH and VT sets. The ESI check reports raster coverage
##     on the unmanaged set and on the sealed set.
##  D3 classification uses the r1 removal rule (v0 merchantable tree removed when its v1 record is STATUSCD 3, or
##     STATUSCD 2 with AGENTCD or AGENTCD_NERS 80, or absent); harvest type by the FCCL rule from PCT_REMOVED.
##  D4 AARON'S DECISION, 27 October 2026 (logged as a deviation): the Acadian ESI v8 raster ends near 71.5 W, so Vermont
##     and western New Hampshire plots have no ESI. For a stand with no ESI above 2 at v1, v2 or v0 (the builder's
##     order), the site input falls back to the climate site index (CSI), converted the way the project has entered CSI
##     for FIA plots before: the ClimateNA site index raster ~/SiteIndex/ClimateNA_SI_m.tif (the raster the fvs-modern
##     calibration extracts as ClimateSI at FIA plot locations, R/extract_raster_values.py), in metres, entered directly
##     in the AcadianGY site slot (cardinal_acadgy_csisensitivity_v25.R: ClimateSI_ft * 0.3048, the ft to m round trip).
##     ESI_SRC is "cov30m" or "csi_fallback". The fallback count is written; for stands that have both, the ESI and CSI
##     values are compared (site values only, no outcome).
##  D5 output names and directory: ~/v143p2/sealed_SERVERONLY/bench_gyr_nhvt_ph_c_*.csv, the class and tst files there;
##     the AGB means by harvest type the Maine builder printed are not printed (read restriction).
## RESTRICTED DATA: LAT and LON are read only inside site_lookup(), held in memory, and dropped there. They are never
## printed, returned or written. No em dashes.
suppressMessages({library(data.table); library(terra)})
a <- commandArgs(TRUE); OUT <- if (length(a)) a[1] else "/users/PUOM0008/crsfaaron/v143p2/sealed_SERVERONLY"
FIA  <- "/users/PUOM0008/crsfaaron/fia_data"
RAST <- "/fs/scratch/PUOM0008/crsfaaron/canada/acadian/Acadian_ESI_v8_30m.tif"
CSIR <- "/users/PUOM0008/crsfaaron/SiteIndex/ClimateNA_SI_m.tif"
ST <- c("NH", "VT")
DS <- "NHVT_PH"; TAG <- "gyr_nhvt_ph_c"
ACRES_PER_HA <- 2.4710538147; FT_M <- 0.3048
LBAC_TO_MGHA  <- 0.45359237 / 1000 * ACRES_PER_HA
G_MAX <- 2.5; SCORE_FLOOR <- 5.0; MIN_TREES <- 3L; FRAME_MINDBH_FIA <- 2.54; HTCOL <- "ACTUALHT"
dir.create(OUT, FALSE, TRUE)
fout <- c(pairs = sprintf("%s/bench_%s_pairs.csv", OUT, TAG), tree_init = sprintf("%s/bench_%s_tree_init.csv", OUT, TAG),
          tree_t2 = sprintf("%s/bench_%s_tree_t2.csv", OUT, TAG), site_esi = sprintf("%s/bench_%s_site_esi.csv", OUT, TAG),
          class = file.path(OUT, "nhvt_ph_class_SERVERONLY.csv"), tst = file.path(OUT, "nhvt_ph_tst_SERVERONLY.csv"),
          excl = file.path(OUT, "nhvt_ph_exclusions_DATA.csv"), checks = file.path(OUT, "nhvt_ph_build_checks_DATA.csv"))
if (any(file.exists(fout))) stop("refusing to overwrite ", fout[file.exists(fout)][1])

## ---- 1. plots and chains (no coordinates) ----
pl <- rbindlist(lapply(ST, function(s) { x <- fread(file.path(FIA, sprintf("%s_PLOT.csv", s)), select = c("CN", "PREV_PLT_CN", "MEASYEAR", "ELEV", "PLOT_STATUS_CD", "DESIGNCD"),
            colClasses = list(character = c("CN", "PREV_PLT_CN"))); x[, JUR := s]; x }))
if (anyDuplicated(pl$CN)) stop("duplicate plot CN across states")
pl[PREV_PLT_CN %in% c("", "NA"), PREV_PLT_CN := NA_character_]
parent <- setNames(pl$PREV_PLT_CN, pl$CN); parent[!(parent %in% pl$CN)] <- NA_character_
root_of <- function(cn) { r <- cn; for (i in 1:60) { p <- unname(parent[r]); mv <- !is.na(p); if (!any(mv)) break; r[mv] <- p[mv] }; r }
pl[, root := root_of(CN)]
pl[, nvis := .N, by = root]
yr <- setNames(pl$MEASYEAR, pl$CN); jur <- setNames(pl$JUR, pl$CN)
pairs_all <- pl[!is.na(parent[CN]), .(cn2 = CN, cn1 = unname(parent[CN]))]
tri <- copy(pairs_all); tri[, cn0 := unname(parent[cn1])]
tri <- tri[!is.na(cn0)]
tri[, `:=`(y0 = yr[cn0], y1 = yr[cn1], y2 = yr[cn2])]
cat(sprintf("plot rows %d, chains %d, linked triples v0-v1-v2 %d\n", nrow(pl), uniqueN(pl$root), nrow(tri)))
EX <- list(); ex <- function(step, n) { EX[[length(EX) + 1]] <<- data.table(step = step, n_triples = as.integer(n)); cat(sprintf("  %-60s %d\n", step, n)) }
ex("linked triples", nrow(tri))
tri <- tri[y1 > y0 & y2 > y1]; ex("positive intervals", nrow(tri))

## ---- 2. conditions ----
co <- rbindlist(lapply(ST, function(s) fread(file.path(FIA, sprintf("%s_COND.csv", s)),
            select = c("PLT_CN", "CONDID", "COND_STATUS_CD", "CONDPROP_UNADJ", "FORTYPCD", "STDAGE", "SITECLCD",
                       "DSTRBCD1", "DSTRBCD2", "DSTRBCD3", "TRTCD1", "TRTCD2", "TRTCD3", "TRTYR1", "TRTYR2", "TRTYR3"),
            colClasses = list(character = "PLT_CN"))))
for (cc in c("DSTRBCD1", "DSTRBCD2", "DSTRBCD3", "TRTCD1", "TRTCD2", "TRTCD3")) set(co, which(is.na(co[[cc]])), cc, 0L)
cs <- co[, {
  d <- c(DSTRBCD1, DSTRBCD2, DSTRBCD3); t <- c(TRTCD1, TRTCD2, TRTCD3); ty <- c(TRTYR1, TRTYR2, TRTYR3)
  hy <- ty[t == 10 & is.finite(ty) & ty > 1900 & ty < 9999]
  .(ncond = .N, allfor = all(COND_STATUS_CD %in% 1L), harv = any(t == 10), trt = any(t != 0),
    fire = any(d %in% 30:32), human = any(d == 80), natd = any(d != 0 & !(d %in% c(30:32, 80))),
    dcodes = paste(sort(unique(d[d != 0])), collapse = "|"), tcodes = paste(sort(unique(t[t != 0])), collapse = "|"),
    harv_yr = if (length(hy)) max(hy) else NA_integer_,
    FORTYPCD = FORTYPCD[1], STDAGE = STDAGE[1], SITECLCD = SITECLCD[1])
}, by = PLT_CN]
g <- function(v, k, tab = tri) cs[match(tab[[v]], cs$PLT_CN), get(k)]
for (s in c("0", "1", "2")) for (k in c("ncond", "allfor", "harv", "trt", "fire", "human", "natd", "dcodes", "tcodes", "harv_yr", "FORTYPCD", "STDAGE", "SITECLCD"))
  tri[, (paste0(k, "_", s)) := g(paste0("cn", s), k)]
ps <- setNames(pl$PLOT_STATUS_CD, pl$CN)
tri <- tri[ps[cn0] %in% 1 & ps[cn1] %in% 1 & ps[cn2] %in% 1]; ex("all three visits PLOT_STATUS_CD 1 (forested)", nrow(tri))
tri <- tri[harv_1 %in% TRUE]; ex("TRTCD 10 at v1", nrow(tri))
tri <- tri[ncond_0 == 1 & ncond_1 == 1 & ncond_2 == 1 & allfor_0 & allfor_1 & allfor_2]; ex("single forested condition at v0, v1 and v2", nrow(tri))
tri <- tri[!trt_2 & !fire_2 & !human_2]; ex("v2 free of treatment, fire and human disturbance", nrow(tri))
## D2 unmanaged validation set: pairs v1 -> v2, single forested condition at both, no treatment at either, clean v2
un <- copy(pairs_all)[, `:=`(y1 = yr[cn1], y2 = yr[cn2])][y2 > y1]
for (s in c("1", "2")) for (k in c("ncond", "allfor", "trt", "fire", "human")) un[, (paste0(k, "_", s)) := g(paste0("cn", s), k, un)]
un <- un[ps[cn1] %in% 1 & ps[cn2] %in% 1 & ncond_1 == 1 & ncond_2 == 1 & allfor_1 & allfor_2 & !trt_1 & !trt_2 & !fire_2 & !human_2]
cat(sprintf("unmanaged validation pairs (D2): %d\n", nrow(un)))

## ---- 3. trees ----
tr <- rbindlist(lapply(ST, function(s) fread(file.path(FIA, sprintf("%s_TREE.csv", s)),
            select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "SPCD", "DIA", "HT", "ACTUALHT", "TPA_UNADJ", "VOLCFNET", "DRYBIO_AG", "AGENTCD", "AGENTCD_NERS"),
            colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))))
need <- unique(c(tri$cn0, tri$cn1, tri$cn2))
tr <- tr[PLT_CN %in% c(need, un$cn1, un$cn2)]
tr[PREV_TRE_CN %in% c("", "NA"), PREV_TRE_CN := NA_character_]
live <- tr[STATUSCD == 1 & is.finite(DIA) & DIA > 0]
live[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ > 0, TPA_UNADJ, fifelse(DIA < 5, 74.965, 6.018))]
SPCD_to_AGY <- c(
 "12"="BF","97"="RS","95"="BS","94"="WS","91"="NS","129"="WP","125"="RP","105"="JP",
 "261"="EH","241"="WC","71"="TA","316"="RM","318"="SM","371"="YB","375"="PB","379"="GB",
 "746"="QA","743"="BT","741"="BP","742"="EC","531"="AB","541"="WA","543"="BA","544"="GA",
 "833"="RO","762"="BC","761"="PR","315"="ST","701"="HH","391"="HH","935"="SB","370"="RB","68"="PC")
map_sp <- function(spcd) { a <- SPCD_to_AGY[as.character(spcd)]; ifelse(!is.na(a), a, ifelse(spcd >= 300, "OH", "OS")) }
## D2 height source check on both sets (availability only)
hchk <- function(cns, lab) live[PLT_CN %in% cns, .(set = lab, live_trees = .N, share_actualht = mean(is.finite(ACTUALHT) & ACTUALHT > 0),
                                                   share_ht = mean(is.finite(HT) & HT > 0), share_actualht_equals_ht = mean(ACTUALHT == HT, na.rm = TRUE))]
HCHK <- rbind(hchk(c(tri$cn1, tri$cn2), "sealed v1 and v2"), hchk(c(un$cn1, un$cn2), "unmanaged v1 and v2"))
print(HCHK)

## ---- 4. site values, restricted coordinates in memory only ----
site_lookup <- function(cns) {
  xy <- rbindlist(lapply(ST, function(s) fread(file.path(FIA, sprintf("%s_PLOT.csv", s)), select = c("CN", "LAT", "LON"), colClasses = list(character = "CN"))))
  xy <- xy[CN %in% cns & is.finite(LAT) & is.finite(LON)]
  v <- vect(as.data.frame(xy[, .(LON, LAT)]), geom = c("LON", "LAT"), crs = "EPSG:4326")
  r <- rast(RAST); e <- terra::extract(r, project(v, crs(r)))[, 2]
  c2 <- rast(CSIR); s2 <- terra::extract(c2[[1]], project(v, crs(c2)))[, 2]
  out <- list(esi = setNames(as.numeric(e), xy$CN), csi = setNames(as.numeric(s2), xy$CN))
  rm(xy, v); invisible(gc())
  out
}
sv <- site_lookup(unique(c(tri$cn0, tri$cn1, tri$cn2, un$cn1, un$cn2)))
pick <- function(vals, a, b, c) { x <- vals[a]; k <- !(is.finite(x) & x > 2); x[k] <- vals[b][k]; k <- !(is.finite(x) & x > 2); x[k] <- vals[c][k]; unname(x) }
tri[, esi_raw := pick(sv$esi, cn1, cn2, cn0)][, csi_raw := pick(sv$csi, cn1, cn2, cn0)]
tri[, ESI_SRC := fifelse(is.finite(esi_raw) & esi_raw > 2, "cov30m", fifelse(is.finite(csi_raw) & csi_raw > 2, "csi_fallback", "none"))]
tri[, esi8 := fifelse(ESI_SRC == "cov30m", esi_raw, fifelse(ESI_SRC == "csi_fallback", csi_raw, NA_real_))]
un[, esi_raw := pick(sv$esi, cn1, cn2, cn2)][, csi_raw := pick(sv$csi, cn1, cn2, cn2)]
ECHK <- rbind(
  tri[, .(set = "sealed (all triples before the tree count screen)", n = .N, share_esi = mean(ESI_SRC == "cov30m"), share_csi_fallback = mean(ESI_SRC == "csi_fallback"),
          share_none = mean(ESI_SRC == "none"), both_n = sum(is.finite(esi_raw) & esi_raw > 2 & is.finite(csi_raw) & csi_raw > 2),
          both_mean_esi = mean(esi_raw[is.finite(esi_raw) & esi_raw > 2 & is.finite(csi_raw) & csi_raw > 2]),
          both_mean_csi = mean(csi_raw[is.finite(esi_raw) & esi_raw > 2 & is.finite(csi_raw) & csi_raw > 2]),
          both_cor = suppressWarnings(cor(esi_raw, csi_raw, use = "complete.obs")))],
  un[, .(set = "unmanaged validation pairs", n = .N, share_esi = mean(is.finite(esi_raw) & esi_raw > 2), share_csi_fallback = mean(!(is.finite(esi_raw) & esi_raw > 2) & is.finite(csi_raw) & csi_raw > 2),
         share_none = mean(!(is.finite(esi_raw) & esi_raw > 2) & !(is.finite(csi_raw) & csi_raw > 2)), both_n = sum(is.finite(esi_raw) & esi_raw > 2 & is.finite(csi_raw) & csi_raw > 2),
         both_mean_esi = mean(esi_raw[is.finite(esi_raw) & esi_raw > 2 & is.finite(csi_raw) & csi_raw > 2]),
         both_mean_csi = mean(csi_raw[is.finite(esi_raw) & esi_raw > 2 & is.finite(csi_raw) & csi_raw > 2]),
         both_cor = suppressWarnings(cor(esi_raw, csi_raw, use = "complete.obs")))])
print(ECHK)
rm(sv)

## ---- 5. frame ----
tri[, PLOTKEY := paste0("FIA", pl$root[match(cn1, pl$CN)])]
tri[, STAND := sprintf("%s__%s__%d_%d_C", DS, PLOTKEY, y1, y2)]
if (anyDuplicated(tri$STAND)) stop("duplicate STAND")
mk_tree <- function(cns, stands, years) {
  d <- live[PLT_CN %in% cns]
  d <- merge(d, data.table(PLT_CN = cns, STAND = stands, YEAR = years), by = "PLT_CN")
  setorder(d, STAND, CN)
  d[, TREE := seq_len(.N), by = STAND]
  h <- d[[HTCOL]]
  d[, .(STAND, PLOT = 1L, TREE, SP = map_sp(SPCD), DBH = round(DIA * 2.54, 2),
        HT = round(fifelse(is.finite(h) & h > 0, h * FT_M, NA_real_), 2),
        EXPF = round(tpa * ACRES_PER_HA, 4), YEAR)]
}
t1 <- live[PLT_CN %in% tri$cn1][, .N, by = PLT_CN]; t2n <- live[PLT_CN %in% tri$cn2][, .N, by = PLT_CN]
tri[, n1 := t1$N[match(cn1, t1$PLT_CN)]][, n2 := t2n$N[match(cn2, t2n$PLT_CN)]]
tri[is.na(n1), n1 := 0L][is.na(n2), n2 := 0L]
tri <- tri[n1 >= MIN_TREES & n2 >= MIN_TREES]; ex("at least 3 live trees at v1 and v2 (runner skip rule)", nrow(tri))
ti <- mk_tree(tri$cn1, tri$STAND, tri$y1)
t2 <- mk_tree(tri$cn2, tri$STAND, tri$y2)
ba4 <- function(d, e) sum(pi * (d / 200)^2 * e * (d >= 4 & e > 0)); tph4 <- function(d, e) sum(e * (d >= 4 & e > 0))
m1 <- ti[, .(N_T1 = .N, BA_T1 = ba4(DBH, EXPF), TPH_T1 = tph4(DBH, EXPF)), by = STAND]
m2 <- t2[, .(N_T2 = .N, BA_T2 = ba4(DBH, EXPF), TPH_T2 = tph4(DBH, EXPF)), by = STAND]
omin <- live[, .(omin = min(DIA * 2.54)), by = PLT_CN]
p <- tri[, .(STAND, SITE = sprintf("%s__%s", DS, PLOTKEY), PROV = "NHVT_FIA_PH", interval_years = as.integer(y2 - y1),
             ELEV = round(fifelse(is.finite(pl$ELEV[match(cn1, pl$CN)]), pl$ELEV[match(cn1, pl$CN)], pl$ELEV[match(cn2, pl$CN)]) * FT_M, 1),
             MANAGED = 1L, DATASET = DS, SET = "c", JURIS = unname(jur[cn1]), PLOTKEY, Y1 = y1, Y2 = y2, INTERVAL_DEC = as.numeric(y2 - y1),
             N_VISITS_PLOT = pl$nvis[match(cn1, pl$CN)], NLINKS = 1L, LINK_SRC = "fiadb_prev_plt_cn", OLD_STAND = NA_character_,
             MANAGED_RULE = "fia1_harvest_trtcd10_at_t1", MANAGED_OLDFLAG = NA_integer_,
             ESI_SRC, ESI_OLD = NA_real_, ELEV_SRC = "fia_plot_ft_to_m",
             FRAME_MINDBH = FRAME_MINDBH_FIA, SCORE_MINDBH = pmax(FRAME_MINDBH_FIA, SCORE_FLOOR),
             PLOT_OBS_MINDBH = round(pmin(omin$omin[match(cn0, omin$PLT_CN)], omin$omin[match(cn1, omin$PLT_CN)], omin$omin[match(cn2, omin$PLT_CN)], na.rm = TRUE), 2),
             esi8, cn1, cn2)]
fm <- live[, .(fm = fifelse(any(DIA * 2.54 < 12.7), FRAME_MINDBH_FIA, 12.7)), by = PLT_CN]; fmv <- setNames(fm$fm, fm$PLT_CN)
p[, FRAME_MINDBH := pmax(unname(fmv[cn1]), unname(fmv[cn2]))][, SCORE_MINDBH := pmax(FRAME_MINDBH, SCORE_FLOOR)]
p[, SCORE_MINDBH_OBS := pmax(SCORE_MINDBH, PLOT_OBS_MINDBH)]
p <- merge(p, m1, by = "STAND"); p <- merge(p, m2, by = "STAND")
th <- p[, .(STAND, thr = SCORE_MINDBH, iv = pmax(interval_years, 1L))]
a1 <- merge(ti, th, by = "STAND")[, .(n1 = sum(DBH >= thr)), by = .(STAND, SP)]
a2 <- merge(t2, th, by = "STAND")[, .(n2big = sum(DBH > thr + G_MAX * iv)), by = .(STAND, SP)]
tf <- merge(a1, a2, by = c("STAND", "SP"), all = TRUE); tf[is.na(n1), n1 := 0L][is.na(n2big), n2big := 0L]
tf <- tf[, .(CHURN_TF_NEWBIG = sum(pmax(0L, n2big - n1))), by = STAND]
p[tf, on = "STAND", CHURN_TF_NEWBIG := i.CHURN_TF_NEWBIG]; p[is.na(CHURN_TF_NEWBIG), CHURN_TF_NEWBIG := 0L]
p[, `:=`(TAG_STABLE = 0L, N_NEWTAG = NA_integer_, N_UNRELOC = NA_integer_, CHURN_NEWTAG_BIG = NA_integer_, CHURN_UNRELOC_SAMESP = NA_integer_)]
p[, CHURN_FLAG := as.integer(CHURN_TF_NEWBIG > 0)]
p[, `:=`(N_INGROWTH_MEMB = NA_integer_, TRT_AT_Y1 = 1L, DUPVIS_DISCORD = 0L, NSL_SINGLE_REGIME = NA_integer_)]
p[, MANAGED := as.integer(grepl("^source1|^fia1", MANAGED_RULE))]
setorder(p, STAND)
mefl_names <- names(fread("/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work/bench_gyr_mefia_ph_c_pairs.csv", nrows = 0))
po <- p[, .(STAND, SITE, PROV, interval_years, ELEV, MANAGED,
            DATASET, SET, JURIS, PLOTKEY, Y1, Y2, INTERVAL_DEC, N_VISITS_PLOT, NLINKS, LINK_SRC, OLD_STAND,
            MANAGED_RULE, MANAGED_OLDFLAG, ESI_SRC, ESI_OLD, ELEV_SRC,
            FRAME_MINDBH = round(FRAME_MINDBH, 2), SCORE_MINDBH = round(SCORE_MINDBH, 2),
            PLOT_OBS_MINDBH = round(PLOT_OBS_MINDBH, 2), SCORE_MINDBH_OBS = round(SCORE_MINDBH_OBS, 2),
            N_T1, N_T2, BA_T1 = round(BA_T1, 4), BA_T2 = round(BA_T2, 4), TPH_T1 = round(TPH_T1, 3), TPH_T2 = round(TPH_T2, 3),
            TAG_STABLE, N_NEWTAG, N_UNRELOC, CHURN_NEWTAG_BIG, CHURN_UNRELOC_SAMESP, CHURN_TF_NEWBIG, CHURN_FLAG,
            N_INGROWTH_MEMB, TRT_AT_Y1, DUPVIS_DISCORD, NSL_SINGLE_REGIME)]
stopifnot(identical(names(po), mefl_names))
if (any(grepl("^(lat|lon|latitude|longitude|x|y)$", tolower(names(po))))) stop("coordinate-like column in pairs output")
se <- unique(p[, .(SITE, esi8 = round(esi8, 3))], by = "SITE"); setorder(se, SITE)
setorder(ti, STAND, TREE); setorder(t2, STAND, TREE)

## ---- 6. classification (v0 to v1 removal, r1 rule; AGB kept on the server, not printed) ----
mv <- function(d) d[DIA >= 5, .(vol = sum(fifelse(is.finite(VOLCFNET), VOLCFNET, 0) * tpa),
                                qmd = sqrt(sum(DIA^2 * tpa) / sum(tpa)), tpa5 = sum(tpa)), by = PLT_CN]
agb <- function(d) d[, .(agb = sum(fifelse(is.finite(DRYBIO_AG), DRYBIO_AG, 0) * tpa) * LBAC_TO_MGHA), by = PLT_CN]
V <- mv(live); A <- agb(live)
v0 <- live[PLT_CN %in% tri$cn0 & DIA >= 5]
v0[, vol := fifelse(is.finite(VOLCFNET), VOLCFNET, 0) * fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ > 0, TPA_UNADJ, 6.018)]
v1r <- tr[PLT_CN %in% tri$cn1 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN, st1 = STATUSCD, ag = AGENTCD, agn = AGENTCD_NERS)]
v0[v1r, on = .(CN = PREV_TRE_CN), `:=`(st1 = i.st1, ag = i.ag, agn = i.agn)]
v0[, fate := fifelse(is.na(st1), "missing", fifelse(st1 == 3L | (st1 == 2L & (ag %in% 80L | agn %in% 80L)), "cut",
             fifelse(st1 == 2L, "died", fifelse(st1 == 1L, "live", "other"))))]
rem <- v0[, .(VOL_CUT = sum(vol[fate == "cut"]), VOL_MISSING = sum(vol[fate == "missing"]), VOL_DIED = sum(vol[fate == "died"]), VOL0 = sum(vol)), by = PLT_CN]
cl <- tri[STAND %in% po$STAND]
gv <- function(tab, cn, col) { x <- tab[[col]][match(cn, tab$PLT_CN)]; x[is.na(x)] <- 0; x }
cl[, `:=`(VOL0_FT3AC = gv(V, cn0, "vol"), VOL1_FT3AC = gv(V, cn1, "vol"), VOL2_FT3AC = gv(V, cn2, "vol"),
          AGB0_MGHA = gv(A, cn0, "agb"), AGB1_MGHA = gv(A, cn1, "agb"), AGB2_MGHA = gv(A, cn2, "agb"),
          VOL_CUT_FT3AC = gv(rem, cn0, "VOL_CUT"), VOL_MISSING_FT3AC = gv(rem, cn0, "VOL_MISSING"), VOL_DIED_FT3AC = gv(rem, cn0, "VOL_DIED"))]
cl[, PCT_REMOVED := round(fifelse(VOL0_FT3AC > 0, 100 * (VOL_CUT_FT3AC + VOL_MISSING_FT3AC) / VOL0_FT3AC, NA_real_), 2)]
cl[, HARVEST_TYPE := fifelse(VOL0_FT3AC < 1200, "low_volume", fifelse(PCT_REMOVED < 35, "light", fifelse(PCT_REMOVED > 65, "heavy", "intermediate")))]
fgrp <- function(f) { b <- fifelse(f >= 100 & f < 120, 100L, fifelse(f >= 120 & f < 140, 120L, fifelse(f >= 160 & f < 170, 160L,
       fifelse(f >= 380 & f < 400, 380L, fifelse(f >= 400 & f < 500, 400L, fifelse(f >= 500 & f < 600, 500L,
       fifelse(f >= 700 & f < 800, 700L, fifelse(f >= 800 & f < 900, 800L, fifelse(f >= 900 & f < 960, 900L,
       fifelse(f >= 960 & f < 999, 960L, fifelse(f == 999, 999L, NA_integer_)))))))))))
  nm <- c("100" = "White_red_jack_pine", "120" = "Spruce_fir", "160" = "Loblolly_shortleaf_pine", "380" = "Exotic_softwoods",
          "400" = "Oak_pine", "500" = "Oak_hickory", "700" = "Elm_ash_cottonwood", "800" = "Maple_beech_birch",
          "900" = "Aspen_birch", "960" = "Other_hardwoods", "999" = "Nonstocked")
  list(b, unname(nm[as.character(b)])) }
cl[, c("FORTYPGRP_V0", "FORTYPGRP_V0_NAME") := fgrp(FORTYPCD_0)]
cl[, TST := fifelse(is.finite(harv_yr_1) & (y1 - harv_yr_1) >= 1 & harv_yr_1 >= y0, as.character(y1 - harv_yr_1), "UNKNOWN")]
co_out <- cl[, .(STAND, PLOTKEY, JURIS = unname(jur[cn1]), CN_V0 = cn0, CN_V1 = cn1, CN_V2 = cn2, Y0 = y0, Y1 = y1, Y2 = y2,
                 HARVEST_YEAR_V1 = harv_yr_1, TST, NATDSTRB_V2 = as.integer(natd_2), ESI_SRC,
                 VOL0_FT3AC = round(VOL0_FT3AC, 1), VOL1_FT3AC = round(VOL1_FT3AC, 1),
                 VOL_CUT_FT3AC = round(VOL_CUT_FT3AC, 1), VOL_MISSING_FT3AC = round(VOL_MISSING_FT3AC, 1), VOL_DIED_FT3AC = round(VOL_DIED_FT3AC, 1),
                 PCT_REMOVED, AGB0_MGHA = round(AGB0_MGHA, 3), AGB1_MGHA = round(AGB1_MGHA, 3), AGB2_MGHA = round(AGB2_MGHA, 3),
                 FORTYPCD_V0 = FORTYPCD_0, FORTYPGRP_V0, FORTYPGRP_V0_NAME, HARVEST_TYPE,
                 REMOVAL_RULE = "tree_linked_v0_merch_STATUSCD3_or_STATUSCD2_AGENT80_or_absent_at_v1")]
setorder(co_out, STAND)
stopifnot(identical(co_out$STAND, po$STAND))

## ---- 7. write (counts only are printed) ----
fwrite(po, fout[["pairs"]]); fwrite(ti, fout[["tree_init"]]); fwrite(t2, fout[["tree_t2"]]); fwrite(se, fout[["site_esi"]])
fwrite(co_out, fout[["class"]]); fwrite(co_out[, .(STAND, TST)], fout[["tst"]]); fwrite(rbindlist(EX), fout[["excl"]])
CHK <- co_out[, .(stands = .N, plots = uniqueN(PLOTKEY), nh = sum(JURIS == "NH"), vt = sum(JURIS == "VT"),
                  esi_cov30m = sum(ESI_SRC == "cov30m"), csi_fallback = sum(ESI_SRC == "csi_fallback"), no_site = sum(ESI_SRC == "none"),
                  esi_coverage_share = mean(ESI_SRC == "cov30m"), known_tst = sum(TST != "UNKNOWN"),
                  heavy = sum(HARVEST_TYPE == "heavy"), intermediate = sum(HARVEST_TYPE == "intermediate"), light = sum(HARVEST_TYPE == "light"),
                  low_volume = sum(HARVEST_TYPE == "low_volume"), heavy_esi = sum(HARVEST_TYPE == "heavy" & ESI_SRC == "cov30m"),
                  heavy_csi = sum(HARVEST_TYPE == "heavy" & ESI_SRC == "csi_fallback"), t1_trees = nrow(ti), t2_trees = nrow(t2))]
CHK <- cbind(CHK, HCHK[set == "sealed v1 and v2", .(sealed_share_actualht = share_actualht, sealed_share_ht = share_ht)],
             HCHK[set == "unmanaged v1 and v2", .(unmanaged_pairs = nrow(un), unmanaged_share_actualht = share_actualht, unmanaged_share_ht = share_ht)],
             ECHK[1, .(sealed_both_n = both_n, sealed_both_mean_esi = both_mean_esi, sealed_both_mean_csi = both_mean_csi, sealed_both_cor = both_cor)],
             ECHK[2, .(unmanaged_esi_share = share_esi, unmanaged_csi_fallback_share = share_csi_fallback, unmanaged_both_n = both_n,
                       unmanaged_both_mean_esi = both_mean_esi, unmanaged_both_mean_csi = both_mean_csi, unmanaged_both_cor = both_cor)])
fwrite(CHK, fout[["checks"]])
print(t(CHK))
for (f in fout) cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f))
cat("SEALED_BUILD_DONE\n")

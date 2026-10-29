## 2026-10-16_mefia_ph_frame_builder.R
## Post-harvest Maine FIA remeasurement frame, SET mefia_ph_c (stand prefix MEFIA_PH__), for the
## October 16, 2026 FVS-ACD cross-version hindcast (v131h, v141LT, v141off).
## Population: Maine FIA plot chains v0 -> v1 -> v2 linked by PREV_PLT_CN, every visit a single
## forested condition (one COND row, COND_STATUS_CD 1), TRTCD 10 on any TRTCD slot at v1 (cut between
## v0 and v1), and at v2 no treatment (TRTCD 1-3 all 0), no fire (DSTRBCD 30-32) and no human
## disturbance (DSTRBCD 80). Hindcast pair t1 = v1 (post-harvest tree list), t2 = v2.
## Conventions reused from:
##   ~/magplot/verify/multisrc/build_mefia_long_bench.R (md5 bb42f828): SPCD to AcadianGY crosswalk,
##     live trees STATUSCD 1 and DIA > 0, TPA fallback, DBH = DIA*2.54, EXPF = TPA*2.4710538, ELEV ft to m.
##   ~/magplot/verify/gydbreg20260916/R/2026-09-16_gydb-regional-frame-builder_FINAL.R (md5 775393cd):
##     PLOTKEY = FIA + chain root CN, STAND/SITE naming, pairs schema, SCORE_MINDBH rules, BA/TPH (DBH >= 4),
##     tag-free churn, MIN_TREES 3, MANAGED from the MANAGED_RULE prefix (fia1 -> 1).
##   ~/gydb_ws/cov/build_cov.R (md5 d73ced59): ESI cov30m = terra::extract of Acadian_ESI_v8_30m.tif at the
##     FIA plot coordinate (EPSG:4326).
## RESTRICTED DATA: LAT and LON are read only inside esi_lookup(), held in memory, and dropped there.
## They are never printed, never returned, never written. No em dashes.
suppressMessages({library(data.table); library(terra)})
FIA  <- "/users/PUOM0008/crsfaaron/fia_data"
FRM  <- "/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames"
RAST <- "/fs/scratch/PUOM0008/crsfaaron/canada/acadian/Acadian_ESI_v8_30m.tif"
OUT  <- "/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work"
DS <- "MEFIA_PH"; SETN <- "mefia_ph_c"; TAG <- "gyr_mefia_ph_c"
ACRES_PER_HA <- 2.4710538147; FT_M <- 0.3048
FT3AC_TO_M3HA <- 0.0283168466 * ACRES_PER_HA          # 0.0699725
LBAC_TO_MGHA  <- 0.45359237 / 1000 * ACRES_PER_HA      # 0.00112085
G_MAX <- 2.5; SCORE_FLOOR <- 5.0; MIN_TREES <- 3L; FRAME_MINDBH_FIA <- 2.54
fout <- c(pairs = sprintf("%s/bench_%s_pairs.csv", OUT, TAG), tree_init = sprintf("%s/bench_%s_tree_init.csv", OUT, TAG),
          tree_t2 = sprintf("%s/bench_%s_tree_t2.csv", OUT, TAG), site_esi = sprintf("%s/bench_%s_site_esi.csv", OUT, TAG),
          class = file.path(OUT, "mefia_ph_class_DATA_2026-10-16.csv"),
          tst = file.path(OUT, "mefia_ph_tst_mefia_ph_c_DATA_2026-10-16.csv"),
          excl = file.path(OUT, "mefia_ph_exclusions_DATA_2026-10-16.csv"))
if (any(file.exists(fout))) stop("refusing to overwrite ", fout[file.exists(fout)][1])

## ---- 1. plots and chains (no coordinates) ----
pl <- fread(file.path(FIA, "ME_PLOT.csv"), select = c("CN", "PREV_PLT_CN", "MEASYEAR", "ELEV", "PLOT_STATUS_CD", "DESIGNCD"),
            colClasses = list(character = c("CN", "PREV_PLT_CN")))
pl[PREV_PLT_CN %in% c("", "NA"), PREV_PLT_CN := NA_character_]
parent <- setNames(pl$PREV_PLT_CN, pl$CN); parent[!(parent %in% pl$CN)] <- NA_character_
root_of <- function(cn) { r <- cn; for (i in 1:60) { p <- unname(parent[r]); mv <- !is.na(p); if (!any(mv)) break; r[mv] <- p[mv] }; r }
pl[, root := root_of(CN)]
pl[, nvis := .N, by = root]
yr <- setNames(pl$MEASYEAR, pl$CN)
tri <- pl[!is.na(parent[CN]), .(cn2 = CN, cn1 = unname(parent[CN]))]
tri[, cn0 := unname(parent[cn1])]
tri <- tri[!is.na(cn0)]
tri[, `:=`(y0 = yr[cn0], y1 = yr[cn1], y2 = yr[cn2])]
cat(sprintf("plot rows %d, chains %d, linked triples v0-v1-v2 %d\n", nrow(pl), uniqueN(pl$root), nrow(tri)))
EX <- list(); ex <- function(step, n) { EX[[length(EX) + 1]] <<- data.table(step = step, n_triples = as.integer(n)); cat(sprintf("  %-60s %d\n", step, n)) }
ex("linked triples", nrow(tri))
tri <- tri[y1 > y0 & y2 > y1]; ex("positive intervals", nrow(tri))

## ---- 2. conditions ----
co <- fread(file.path(FIA, "ME_COND.csv"),
            select = c("PLT_CN", "CONDID", "COND_STATUS_CD", "CONDPROP_UNADJ", "FORTYPCD", "STDAGE", "SITECLCD",
                       "DSTRBCD1", "DSTRBCD2", "DSTRBCD3", "TRTCD1", "TRTCD2", "TRTCD3", "TRTYR1", "TRTYR2", "TRTYR3"),
            colClasses = list(character = "PLT_CN"))
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
g <- function(v, k) cs[match(tri[[v]], cs$PLT_CN), get(k)]
for (s in c("0", "1", "2")) for (k in c("ncond", "allfor", "harv", "trt", "fire", "human", "natd", "dcodes", "tcodes", "harv_yr", "FORTYPCD", "STDAGE", "SITECLCD"))
  tri[, (paste0(k, "_", s)) := g(paste0("cn", s), k)]
ps <- setNames(pl$PLOT_STATUS_CD, pl$CN)
tri <- tri[ps[cn0] %in% 1 & ps[cn1] %in% 1 & ps[cn2] %in% 1]; ex("all three visits PLOT_STATUS_CD 1 (forested)", nrow(tri))
tri <- tri[harv_1 %in% TRUE]; ex("TRTCD 10 at v1", nrow(tri))
n_allfor <- tri[allfor_0 & allfor_1 & allfor_2 & !trt_2 & !fire_2 & !human_2, .N]
tri <- tri[ncond_0 == 1 & ncond_1 == 1 & ncond_2 == 1 & allfor_0 & allfor_1 & allfor_2]; ex("single forested condition at v0, v1 and v2", nrow(tri))
cat(sprintf("  (for reference: multi-condition but all conditions forested, clean v2: %d triples)\n", n_allfor))
tri <- tri[!trt_2 & !fire_2 & !human_2]; ex("v2 free of treatment, fire and human disturbance", nrow(tri))

## ---- 3. trees ----
tr <- fread(file.path(FIA, "ME_TREE.csv"),
            select = c("CN", "PLT_CN", "PREV_TRE_CN", "STATUSCD", "SPCD", "DIA", "HT", "ACTUALHT", "TPA_UNADJ", "VOLCFNET", "DRYBIO_AG"),
            colClasses = list(character = c("CN", "PLT_CN", "PREV_TRE_CN")))
need <- unique(c(tri$cn0, tri$cn1, tri$cn2))
mefl <- fread(file.path(FRM, "bench_gyr_mefia_l_c_pairs.csv"), colClasses = list(character = c("STAND", "OLD_STAND")))
stopifnot(all(mefl$FRAME_MINDBH %in% c(FRAME_MINDBH_FIA, 12.7)))
val_cn <- unique(sub("^ME_L_", "", mefl$OLD_STAND[!is.na(mefl$OLD_STAND) & nzchar(mefl$OLD_STAND)]))
tr <- tr[PLT_CN %in% c(need, val_cn)]
tr[PREV_TRE_CN %in% c("", "NA"), PREV_TRE_CN := NA_character_]
live <- tr[STATUSCD == 1 & is.finite(DIA) & DIA > 0]
live[, tpa := fifelse(is.finite(TPA_UNADJ) & TPA_UNADJ > 0, TPA_UNADJ, fifelse(DIA < 5, 74.965, 6.018))]
SPCD_to_AGY <- c(
 "12"="BF","97"="RS","95"="BS","94"="WS","91"="NS","129"="WP","125"="RP","105"="JP",
 "261"="EH","241"="WC","71"="TA","316"="RM","318"="SM","371"="YB","375"="PB","379"="GB",
 "746"="QA","743"="BT","741"="BP","742"="EC","531"="AB","541"="WA","543"="BA","544"="GA",
 "833"="RO","762"="BC","761"="PR","315"="ST","701"="HH","391"="HH","935"="SB","370"="RB","68"="PC")
map_sp <- function(spcd) { a <- SPCD_to_AGY[as.character(spcd)]; ifelse(!is.na(a), a, ifelse(spcd >= 300, "OH", "OS")) }

## height source check against the frozen mefia_l_c t1 tree lists (OLD_STAND ME_L_<first CN> is the t1 CN)
ti_ref <- fread(file.path(FRM, "bench_gyr_mefia_l_c_tree_init.csv"))
vm <- mefl[!is.na(OLD_STAND) & nzchar(OLD_STAND) & Y1 == as.integer(yr[sub("^ME_L_", "", OLD_STAND)]), .(STAND, cn = sub("^ME_L_", "", OLD_STAND))]
hv <- merge(live[PLT_CN %in% vm$cn], vm, by.x = "PLT_CN", by.y = "cn")
cmp <- merge(hv[, .(n_new = .N, ex_new = round(sum(tpa * ACRES_PER_HA), 1),
                    sig_act = paste(sort(sprintf("%.2f/%.2f", round(DIA * 2.54, 2), round(fifelse(is.finite(ACTUALHT) & ACTUALHT > 0, ACTUALHT * FT_M, NA_real_), 2))), collapse = ";"),
                    sig_ht  = paste(sort(sprintf("%.2f/%.2f", round(DIA * 2.54, 2), round(fifelse(is.finite(HT) & HT > 0, HT * FT_M, NA_real_), 2))), collapse = ";")), by = STAND],
             ti_ref[STAND %in% vm$STAND, .(n_ref = .N, ex_ref = round(sum(EXPF), 1),
                    sig_ref = paste(sort(sprintf("%.2f/%.2f", DBH, HT)), collapse = ";")), by = STAND], by = "STAND")
m_act <- mean(cmp$sig_act == cmp$sig_ref); m_ht <- mean(cmp$sig_ht == cmp$sig_ref)
cat(sprintf("\nVALIDATION vs mefia_l_c t1 (%d stands): n trees equal %.4f, EXPF sum equal %.4f, DBH/HT identical with ACTUALHT %.4f, with HT %.4f\n",
            nrow(cmp), mean(cmp$n_new == cmp$n_ref), mean(abs(cmp$ex_new - cmp$ex_ref) < 0.5), m_act, m_ht))
HTCOL <- if (m_ht > m_act) "HT" else "ACTUALHT"
cat("height column used:", HTCOL, "\n")
rm(ti_ref, hv, cmp)

## ---- 4. ESI cov30m, restricted coordinates in memory only ----
esi_lookup <- function(cns) {
  xy <- fread(file.path(FIA, "ME_PLOT.csv"), select = c("CN", "LAT", "LON"), colClasses = list(character = "CN"))
  xy <- xy[CN %in% cns & is.finite(LAT) & is.finite(LON)]
  r <- rast(RAST)
  v <- vect(as.data.frame(xy[, .(LON, LAT)]), geom = c("LON", "LAT"), crs = "EPSG:4326")
  val <- terra::extract(r, v)[, 2]
  out <- setNames(as.numeric(val), xy$CN)
  rm(xy, v); invisible(gc())
  out
}
## validation: same extraction at the mefia_l_c t1 CNs reproduces the frozen cov30m esi8
sref <- fread(file.path(FRM, "bench_gyr_mefia_l_c_site_esi.csv"))
vv <- unique(mefl[ESI_SRC == "cov30m" & !is.na(OLD_STAND) & nzchar(OLD_STAND), .(SITE, cn = sub("^ME_L_", "", OLD_STAND))], by = "SITE")
e_all <- esi_lookup(unique(c(tri$cn0, tri$cn1, tri$cn2, vv$cn)))
vv[, e_new := round(unname(e_all[cn]), 3)]; vv <- merge(vv, sref, by = "SITE")
cat(sprintf("VALIDATION ESI: %d mefia_l_c cov30m sites, |new - frozen| < 0.01 for %.4f, median abs diff %.4f\n",
            nrow(vv), mean(abs(vv$e_new - vv$esi8) < 0.01, na.rm = TRUE), median(abs(vv$e_new - vv$esi8), na.rm = TRUE)))
pick_esi <- function(a, b, c) { x <- e_all[a]; x[!(is.finite(x) & x > 2)] <- e_all[b][!(is.finite(x) & x > 2)]
  x[!(is.finite(x) & x > 2)] <- e_all[c][!(is.finite(x) & x > 2)]; unname(x) }
tri[, esi8 := pick_esi(cn1, cn2, cn0)]
rm(e_all)

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
p <- tri[, .(STAND, SITE = sprintf("%s__%s", DS, PLOTKEY), PROV = "ME_FIA_PH", interval_years = as.integer(y2 - y1),
             ELEV = round(fifelse(is.finite(pl$ELEV[match(cn1, pl$CN)]), pl$ELEV[match(cn1, pl$CN)], pl$ELEV[match(cn2, pl$CN)]) * FT_M, 1),
             MANAGED = 1L, DATASET = DS, SET = "c", JURIS = "ME", PLOTKEY, Y1 = y1, Y2 = y2, INTERVAL_DEC = as.numeric(y2 - y1),
             N_VISITS_PLOT = pl$nvis[match(cn1, pl$CN)], NLINKS = 1L, LINK_SRC = "fiadb_prev_plt_cn", OLD_STAND = NA_character_,
             MANAGED_RULE = "fia1_harvest_trtcd10_at_t1", MANAGED_OLDFLAG = NA_integer_,
             ESI_SRC = fifelse(is.finite(esi8) & esi8 > 2, "cov30m", "none"), ESI_OLD = NA_real_, ELEV_SRC = "fia_plot_ft_to_m",
             FRAME_MINDBH = FRAME_MINDBH_FIA, SCORE_MINDBH = pmax(FRAME_MINDBH_FIA, SCORE_FLOOR),
             PLOT_OBS_MINDBH = round(pmin(omin$omin[match(cn0, omin$PLT_CN)], omin$omin[match(cn1, omin$PLT_CN)], omin$omin[match(cn2, omin$PLT_CN)], na.rm = TRUE), 2),
             esi8, cn1, cn2)]
## FRAME_MINDBH as GYDB stored it for MEFIA_L: a visit with any live tree under 12.7 cm carries the 2.54 cm
## microplot frame, otherwise only the 12.7 cm subplot frame; pair value = max over t1 and t2 (reproduces all
## 918 mefia_l_c FRAME_MINDBH values from the frozen tree files).
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
po <- p[, .(STAND, SITE, PROV, interval_years, ELEV, MANAGED,
            DATASET, SET, JURIS, PLOTKEY, Y1, Y2, INTERVAL_DEC, N_VISITS_PLOT, NLINKS, LINK_SRC, OLD_STAND,
            MANAGED_RULE, MANAGED_OLDFLAG, ESI_SRC, ESI_OLD, ELEV_SRC,
            FRAME_MINDBH = round(FRAME_MINDBH, 2), SCORE_MINDBH = round(SCORE_MINDBH, 2),
            PLOT_OBS_MINDBH = round(PLOT_OBS_MINDBH, 2), SCORE_MINDBH_OBS = round(SCORE_MINDBH_OBS, 2),
            N_T1, N_T2, BA_T1 = round(BA_T1, 4), BA_T2 = round(BA_T2, 4), TPH_T1 = round(TPH_T1, 3), TPH_T2 = round(TPH_T2, 3),
            TAG_STABLE, N_NEWTAG, N_UNRELOC, CHURN_NEWTAG_BIG, CHURN_UNRELOC_SAMESP, CHURN_TF_NEWBIG, CHURN_FLAG,
            N_INGROWTH_MEMB, TRT_AT_Y1, DUPVIS_DISCORD, NSL_SINGLE_REGIME)]
stopifnot(identical(names(po), names(mefl)))
if (any(grepl("^(lat|lon|latitude|longitude|x|y)$", tolower(names(po))))) stop("coordinate-like column in pairs output")
se <- unique(p[, .(SITE, esi8 = round(esi8, 3))], by = "SITE"); setorder(se, SITE)
setorder(ti, STAND, TREE); setorder(t2, STAND, TREE)

## ---- 6. classification (v0 to v1 removal, AGB, type) ----
mv <- function(d) d[DIA >= 5, .(vol = sum(fifelse(is.finite(VOLCFNET), VOLCFNET, 0) * tpa),
                                qmd = sqrt(sum(DIA^2 * tpa) / sum(tpa)), tpa5 = sum(tpa)), by = PLT_CN]
agb <- function(d) d[, .(agb = sum(fifelse(is.finite(DRYBIO_AG), DRYBIO_AG, 0) * tpa) * LBAC_TO_MGHA), by = PLT_CN]
V <- mv(live); A <- agb(live)
## tree-linked removal: v0 live merch trees whose v1 record is STATUSCD 3 (cut) or absent
v0t <- live[PLT_CN %in% tri$cn0 & DIA >= 5, .(PLT_CN, CN, vol = fifelse(is.finite(VOLCFNET), VOLCFNET, 0) * tpa)]
v1r <- tr[PLT_CN %in% tri$cn1 & !is.na(PREV_TRE_CN), .(PREV_TRE_CN, st1 = STATUSCD)]
v0t[v1r, on = .(CN = PREV_TRE_CN), st1 := i.st1]
rem <- v0t[, .(vol_cut = sum(vol[st1 %in% 3L]), vol_missing = sum(vol[is.na(st1)]),
               vol_died = sum(vol[st1 %in% 2L]), vol_other0 = sum(vol[st1 %in% 0L])), by = PLT_CN]
cl <- tri[STAND %in% po$STAND]
gv <- function(tab, cn, col) { x <- tab[[col]][match(cn, tab$PLT_CN)]; x[is.na(x)] <- 0; x }
cl[, `:=`(VOL0_FT3AC = gv(V, cn0, "vol"), VOL1_FT3AC = gv(V, cn1, "vol"), VOL2_FT3AC = gv(V, cn2, "vol"),
          QMD0_IN = V$qmd[match(cn0, V$PLT_CN)], QMD1_IN = V$qmd[match(cn1, V$PLT_CN)],
          AGB0_MGHA = gv(A, cn0, "agb"), AGB1_MGHA = gv(A, cn1, "agb"), AGB2_MGHA = gv(A, cn2, "agb"),
          VOL_CUT_FT3AC = gv(rem, cn0, "vol_cut"), VOL_MISSING_FT3AC = gv(rem, cn0, "vol_missing"),
          VOL_DIED_FT3AC = gv(rem, cn0, "vol_died"))]
cl[, PCT_REMOVED := fifelse(VOL0_FT3AC > 0, 100 * (VOL_CUT_FT3AC + VOL_MISSING_FT3AC) / VOL0_FT3AC, NA_real_)]
cl[, PCT_REMOVED_NET := fifelse(VOL0_FT3AC > 0, 100 * (1 - VOL1_FT3AC / VOL0_FT3AC), NA_real_)]
cl[, HARVEST_TYPE := fifelse(VOL0_FT3AC < 1200, "low_volume",
                     fifelse(PCT_REMOVED < 35, "light", fifelse(PCT_REMOVED > 65, "heavy", "intermediate")))]
fgrp <- function(f) {
  b <- fifelse(f >= 100 & f < 120, 100L, fifelse(f >= 120 & f < 140, 120L, fifelse(f >= 160 & f < 170, 160L,
       fifelse(f >= 380 & f < 400, 380L, fifelse(f >= 400 & f < 500, 400L, fifelse(f >= 500 & f < 600, 500L,
       fifelse(f >= 700 & f < 800, 700L, fifelse(f >= 800 & f < 900, 800L, fifelse(f >= 900 & f < 960, 900L,
       fifelse(f >= 960 & f < 999, 960L, fifelse(f == 999, 999L, NA_integer_)))))))))))
  nm <- c("100" = "White_red_jack_pine", "120" = "Spruce_fir", "160" = "Loblolly_shortleaf_pine", "380" = "Exotic_softwoods",
          "400" = "Oak_pine", "500" = "Oak_hickory", "700" = "Elm_ash_cottonwood", "800" = "Maple_beech_birch",
          "900" = "Aspen_birch", "960" = "Other_hardwoods", "999" = "Nonstocked")
  list(b, unname(nm[as.character(b)]))
}
cl[, c("FORTYPGRP_V0", "FORTYPGRP_V0_NAME") := fgrp(FORTYPCD_0)]
cl[, c("FORTYPGRP_V1", "FORTYPGRP_V1_NAME") := fgrp(FORTYPCD_1)]
cl[, TST := fifelse(is.finite(harv_yr_1) & (y1 - harv_yr_1) >= 1 & harv_yr_1 >= y0, as.character(y1 - harv_yr_1), "UNKNOWN")]
co_out <- cl[, .(STAND, PLOTKEY, CN_V0 = cn0, CN_V1 = cn1, CN_V2 = cn2, Y0 = y0, Y1 = y1, Y2 = y2,
                 HARVEST_YEAR_V1 = harv_yr_1, TST, TRTCODES_V0 = tcodes_0, TRTCODES_V1 = tcodes_1, DSTRBCODES_V1 = dcodes_1,
                 NATDSTRB_V2 = as.integer(natd_2), DSTRBCODES_V2 = dcodes_2,
                 VOL0_FT3AC = round(VOL0_FT3AC, 1), VOL0_M3HA = round(VOL0_FT3AC * FT3AC_TO_M3HA, 2),
                 VOL1_FT3AC = round(VOL1_FT3AC, 1), VOL1_M3HA = round(VOL1_FT3AC * FT3AC_TO_M3HA, 2),
                 VOL2_FT3AC = round(VOL2_FT3AC, 1), VOL2_M3HA = round(VOL2_FT3AC * FT3AC_TO_M3HA, 2),
                 VOL_CUT_FT3AC = round(VOL_CUT_FT3AC, 1), VOL_MISSING_FT3AC = round(VOL_MISSING_FT3AC, 1), VOL_DIED_FT3AC = round(VOL_DIED_FT3AC, 1),
                 PCT_REMOVED = round(PCT_REMOVED, 2), PCT_REMOVED_NET = round(PCT_REMOVED_NET, 2),
                 QMD0_IN = round(QMD0_IN, 2), QMD1_IN = round(QMD1_IN, 2), QMD0_CM = round(QMD0_IN * 2.54, 2), QMD1_CM = round(QMD1_IN * 2.54, 2),
                 AGB0_MGHA = round(AGB0_MGHA, 3), AGB1_MGHA = round(AGB1_MGHA, 3), AGB2_MGHA = round(AGB2_MGHA, 3),
                 FORTYPCD_V0 = FORTYPCD_0, FORTYPGRP_V0, FORTYPGRP_V0_NAME, FORTYPCD_V1 = FORTYPCD_1, FORTYPGRP_V1, FORTYPGRP_V1_NAME,
                 STDAGE_V1 = STDAGE_1, SITECLCD_V1 = SITECLCD_1, HARVEST_TYPE)]
setorder(co_out, STAND)
stopifnot(identical(co_out$STAND, po$STAND))

## ---- 7. write ----
fwrite(po, fout[["pairs"]]); fwrite(ti, fout[["tree_init"]]); fwrite(t2, fout[["tree_t2"]]); fwrite(se, fout[["site_esi"]])
fwrite(co_out, fout[["class"]]); fwrite(co_out[, .(STAND, TST)], fout[["tst"]]); fwrite(rbindlist(EX), fout[["excl"]])
cat("\n===== SUMMARY =====\n")
cat(sprintf("stands %d, plots %d, sites %d, t1 trees %d, t2 trees %d\n", nrow(po), uniqueN(po$PLOTKEY), nrow(se), nrow(ti), nrow(t2)))
cat(sprintf("ESI cov30m > 2: %d of %d stands (runner INDOMAIN admits only these)\n", sum(po$ESI_SRC == "cov30m"), nrow(po)))
cat("interval_years:\n"); print(table(po$interval_years))
cat("harvest type:\n"); print(co_out[, .N, by = HARVEST_TYPE][order(HARVEST_TYPE)])
cat("harvest type, ESI in domain only:\n"); print(co_out[STAND %in% po[ESI_SRC == "cov30m", STAND], .N, by = HARVEST_TYPE][order(HARVEST_TYPE)])
cat("TST state:\n"); print(co_out[, .(state = fifelse(TST == "UNKNOWN", "UNKNOWN", "known"))][, .N, by = state])
k <- suppressWarnings(as.numeric(co_out$TST)); k <- k[is.finite(k)]; if (length(k)) cat(sprintf("known TST %g to %g, median %g\n", min(k), max(k), median(k)))
cat(sprintf("removal tree-linked vs net: cor %.3f, mean %.1f vs %.1f\n", cor(co_out$PCT_REMOVED, co_out$PCT_REMOVED_NET, use = "complete"),
            mean(co_out$PCT_REMOVED, na.rm = TRUE), mean(co_out$PCT_REMOVED_NET, na.rm = TRUE)))
cat(sprintf("natural disturbance recorded at v2 (kept): %d\n", sum(co_out$NATDSTRB_V2, na.rm = TRUE)))
cat("forest type group v0:\n"); print(co_out[, .N, by = FORTYPGRP_V0_NAME][order(-N)])
print(co_out[, .(n = .N, vol0 = round(mean(VOL0_FT3AC)), rem = round(mean(PCT_REMOVED, na.rm = TRUE), 1), agb0 = round(mean(AGB0_MGHA), 1),
                 agb1 = round(mean(AGB1_MGHA), 1), agb2 = round(mean(AGB2_MGHA), 1)), by = HARVEST_TYPE])
for (f in fout) cat(sprintf("%s  %s\n", unname(tools::md5sum(f)), f))
cat("BUILD_DONE\n")

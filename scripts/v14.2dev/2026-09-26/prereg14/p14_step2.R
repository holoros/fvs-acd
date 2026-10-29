## PREREG14 step 2 (NB): raw MAGPlot tag check on trees 15 cm and over, Phase D criteria per pair, then the height
## level and increment check (observed vs predicted v141LT) on survivors with measured height at both ends.
## Logic of recs/probe_tags4_magp.R for the pairing and criteria. Diagnostic only. No em dashes.
source(file.path(Sys.getenv("P14_ROOT", "/home/aaron/jobs/v142p14"), "scripts/p14_common.R"))
s <- "nb_c"; prov <- "NB"
pr <- fread(file.path(IN, "frames/bench_gyr_nb_c_pairs.csv"), select = c("STAND", "OLD_STAND", "PLOTKEY", "Y1", "Y2", "interval_years"))
cs <- cut_stands(pr); pr[, cut := STAND %in% cs]
r <- fread(file.path(IN, "v141LT/nb_c/c001_results.csv"))[RUN_OK == 1, .(STAND, iv)]
hd <- fread(file.path(IN, "magp/p14_magp_header_nbqc_DATA_2026-09-26.csv"))[, .(plot_id, meas_num, meas_year)]
tr <- fread(file.path(IN, "magp/p14_magp_nb_trees_DATA_2026-09-26.csv"))
tr <- merge(tr, hd, by = c("plot_id", "meas_num"))
spm <- fread(file.path(IN, "pass28qc/qc_species_map_gs_to_acd.csv"))
tk <- tr[tree_num < 8e6 & dbh > 0]
a <- merge(pr, tk, by.x = c("OLD_STAND", "Y1"), by.y = c("plot_id", "meas_year"))
b <- merge(pr, tk, by.x = c("OLD_STAND", "Y2"), by.y = c("plot_id", "meas_year"))
a <- a[!duplicated(a[, .(STAND, Y1, Y2, tree_num)])]; b <- b[!duplicated(b[, .(STAND, Y1, Y2, tree_num)])]
m <- merge(a[, .(STAND, Y1, Y2, cut, interval_years, tree_num, SP1 = species_gs, D1 = dbh, H1r = height, ST1 = tree_status)],
           b[, .(STAND, tree_num, SP2 = species_gs, D2 = dbh, H2r = height, ST2 = tree_status)], by = c("STAND", "tree_num"))
m[, iv_obs := Y2 - Y1]
m[, `:=`(same_sp = SP1 == SP2, plaus = (D2 - D1) >= -1 & (D2 - D1) <= 2.5 * iv_obs, cls15 = fifelse(D1 < 15, "<15", ">=15"))]
## C4 (reported, not a hard stop): probe_tags4 NB rows
c4 <- m[, .(trees = .N, pairs = uniqueN(STAND), same_sp = mean(same_sp), plausible = mean(plaus), same_sp_and_plaus = mean(same_sp & plaus)), by = .(cls = cls15)]
c4 <- merge(c4, fread(file.path(IN, "ref/gyr142-recs-magp-tagcheck_DATA_2026-09-26.csv"))[PROV == "NB", .(cls, trees_ref = trees, pairs_ref = pairs, same_sp_ref = same_sp, ssp_ref = same_sp_and_plaus)], by = "cls", all = TRUE)
print(c4, digits = 6); wout(c4, "check-C4-nb-probe")
## per pair Phase D criteria on trees 15 cm and over
g <- m[D1 >= 15, .(n15 = .N, same_sp15 = mean(same_sp), ssp15 = mean(same_sp & plaus)), by = STAND]
g[, pass := n15 >= 5 & same_sp15 >= 0.97 & ssp15 >= 0.98]
pairs_tab <- merge(pr[, .(STAND, cut)], g, by = "STAND", all.x = TRUE)[, n15 := fcoalesce(n15, 0L)][, pass := fcoalesce(pass, FALSE)]
pairs_tab[, in_runner := STAND %in% r$STAND]
cat(sprintf("NB pairs %d; with >= 5 tracked trees 15 cm and over %d; passing Phase D %d; passing and RUN_OK %d\n",
    nrow(pairs_tab), pairs_tab[n15 >= 5, .N], pairs_tab[pass == TRUE, .N], pairs_tab[pass == TRUE & in_runner == TRUE, .N]))
wout(pairs_tab, "s2-nb-pair-criteria")
PASS <- pairs_tab[pass == TRUE & in_runner == TRUE, STAND]
if (SMOKE_N > 0) PASS <- head(PASS, SMOKE_N)
if (length(PASS) < 1) hs("step2: no NB pair passes the Phase D criteria on trees 15 cm and over")
## ---- map raw t1 trees to frozen frame rows (runner ids) on (STAND, DBH, HT) with within key rank
## (raw ordered by tree_num, frame by row order); unique key only as sensitivity
F <- fread(file.path(IN, "frames/bench_gyr_nb_c_tree_init.csv"))[, row0 := seq_len(.N), by = STAND][STAND %in% r$STAND]
F[, `:=`(sp = mapsp(SP), kD = round(DBH, 1), kH = fifelse(is.finite(HT) & HT > 0, round(HT, 1), NA_real_))]
rw <- a[STAND %in% r$STAND & substr(tree_status, 1, 1) == "L", .(STAND, tree_num, species_gs, kD = round(dbh, 1), kH = fifelse(height > 0, round(height, 1), NA_real_))]
setorder(rw, STAND, tree_num); setorder(F, STAND, row0)
rw[, rk := seq_len(.N), by = .(STAND, kD, kH)]; F[, rk := seq_len(.N), by = .(STAND, kD, kH)]
rw[, nk := .N, by = .(STAND, kD, kH)]; F[, nk := .N, by = .(STAND, kD, kH)]
mp <- merge(F[, .(STAND, row0, kD, kH, rk, nkF = nk, SP, sp)], rw[, .(STAND, kD, kH, rk, nkR = nk, tree_num, species_gs)], by = c("STAND", "kD", "kH", "rk"))
mp <- merge(mp, spm[, .(species_gs, SPmap = SP)], by = "species_gs", all.x = TRUE)
mp[, sp_agree := !is.na(SPmap) & SPmap == SP]
share <- mp[STAND %in% PASS, .N] / F[STAND %in% PASS, .N]
cat(sprintf("mapping: %d of %d frame rows in passing pairs mapped (%.3f); SP agreement %.3f; unique key rows %d\n",
    mp[STAND %in% PASS, .N], F[STAND %in% PASS, .N], share, mp[STAND %in% PASS, mean(sp_agree)], mp[STAND %in% PASS & nkF == 1 & nkR == 1, .N]))
if (share < 0.8) hs("step2: only %.3f of frame rows in passing pairs map to raw MAGPlot tags", share)
## ---- runner records for NB: split map (checked against the runner list) and per tree pht, Hp
T1 <- fread(file.path(IN, "v141LT/nb_c/c001_t1_split_tree.csv")); YR <- fread(file.path(IN, "v141LT/nb_c/c001_pred_yr1_tree.csv")); P <- fread(file.path(IN, "v141LT/nb_c/c001_pred_t2_tree.csv"))
M <- split_map(F[, .(STAND, row0, sp, DBH, EXPF)])
x <- merge(M, T1, by = c("STAND", "tree"), all = TRUE, suffixes = c("", "_r"))
bad <- x[is.na(row0) | is.na(sp_r) | sp != sp_r | abs(dbh - dbh_r) > 1e-6 | abs(expf - expf_r) > 1e-6 * pmax(1, expf)]
if (nrow(bad)) hs("step2: split map disagrees with the runner t1 list on %d records", nrow(bad))
Y0 <- merge(YR[ing == 0], M[, .(STAND, tree, row0)], by = c("STAND", "tree"))[, .(pht = sum(pht * expf) / sum(expf)), by = .(STAND, row0)]
P0 <- merge(P[ing == 0], M[, .(STAND, tree, row0)], by = c("STAND", "tree"))[, .(Hp = sum(ht * expf) / sum(expf)), by = .(STAND, row0)]
## ---- survivors on passing pairs: 15 cm and over, live at both ends, same species, measured height at both ends
sv <- m[STAND %in% PASS & D1 >= 15 & substr(ST1, 1, 1) == "L" & substr(ST2, 1, 1) == "L" & same_sp == TRUE]
sv <- merge(sv, mp[, .(STAND, tree_num, row0, sp, nkF, nkR)], by = c("STAND", "tree_num"))
sv <- merge(merge(sv, Y0, by = c("STAND", "row0")), P0, by = c("STAND", "row0"))
sv <- merge(sv, r, by = "STAND")
cat(sprintf("survivors >= 15 cm on passing pairs, mapped: %d; with measured height both ends %d\n", nrow(sv), sv[H1r > 0 & H2r > 0, .N]))
S <- sv[H1r > 0 & H2r > 0][, `:=`(H1 = H1r, H2 = H2r, himp1 = himp(sp, D1), dho = (H2r - H1r) / interval_years, dhp = (Hp - H1r) / interval_years,
                                    cls = fifelse(D1 < 25, "15 to 25", "25 and over"))]
S[, horizon_mismatch := iv != Y2 - Y1]
out <- list(); inc <- list()
for (samp in c("all", "unique key only")) for (pop in c("all", "screened")) for (cc in c("all", "15 to 25", "25 and over")) {
  d <- S[(samp == "all" | (nkF == 1 & nkR == 1)) & (pop == "all" | cut == FALSE) & (cc == "all" | cls == cc)]
  for (ms in list(c("H1", "pht", "L1 pht vs measured HT1"), c("H1", "himp1", "L2 himp vs measured HT1"), c("H2", "Hp", "L3 predicted t2 vs measured HT2")))
    out[[paste(samp, pop, cc, ms[3])]] <- cbind(data.table(set = s, prov = prov, sample = samp, pop = pop, cls = cc, measure = ms[3]), levsum(d, ms[1], ms[2]))
  if (nrow(d)) { b1 <- bratio(d$STAND, d$dhp, d$dho); b2 <- bratio(d$STAND, d$dho, d$dhp) * AFAC[["NB"]]
    inc[[paste(samp, pop, cc)]] <- data.table(set = s, prov = prov, sample = samp, pop = pop, cls = cc, trees = nrow(d), stands = uniqueN(d$STAND),
      obs_dht_m_yr = mean(d$dho), pred_dht_m_yr = mean(d$dhp), pred_over_obs = b1[1], pred_over_obs_lo95 = b1[2], pred_over_obs_hi95 = b1[3],
      afac = AFAC[["NB"]], R_static = b2[1], R_lo95 = b2[2], R_hi95 = b2[3], obs_neg_share = mean(d$dho < 0), horizon_mismatch = sum(d$horizon_mismatch),
      thin = nrow(d) < 30 | uniqueN(d$STAND) < 10) } }
LV <- rbindlist(out, fill = TRUE); IN2 <- rbindlist(inc); print(LV, digits = 4); print(IN2, digits = 4)
wout(LV, "s2-nb-level"); wout(IN2, "s2-nb-increment")
wout(data.table(stat = c("pairs", "pass", "pass_run_ok", "map_share", "sp_agree", "survivors_mapped", "survivors_ht_both"),
                value = c(nrow(pairs_tab), pairs_tab[pass == TRUE, .N], length(PASS), share, mp[STAND %in% PASS, mean(sp_agree)], nrow(sv), nrow(S))), "s2-nb-counts")
E <- rbind(LV[sample == "all" & pop == "all" & grepl("^L1|^L3", measure) & trees > 0, .(hyp = "H-level", set, prov, pop, cls, measure, n = trees, stands, est = ratio, lo95, hi95, thin,
             supports = !thin & (ratio < 0.95 | ratio > 1.05) & (lo95 > 1 | hi95 < 1), strong = !thin & (lo95 > 1.05 | hi95 < 0.95))],
           IN2[sample == "all" & pop == "all", .(hyp = "H-increment", set, prov, pop, cls, measure = "R = obs/pred x AFAC", n = trees, stands, est = R_static, lo95 = R_lo95, hi95 = R_hi95, thin,
             supports = !thin & (R_static < 0.9 | R_static > 1.1) & (R_lo95 > 1 | R_hi95 < 1), strong = NA)])
print(E, digits = 4); wout(E, "s2-evidence")
cat("STEP2_DONE\n")

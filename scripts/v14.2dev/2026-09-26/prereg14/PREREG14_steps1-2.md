# PREREG14, steps 1 and 2: height level, volume and increment measurement study (FVS-ACD 14.2 track)

Written 2026-09-26 on firebreather before any computation on the moved inputs. Diagnostic only: no gate in this
document changes any model, coefficient, runner or configuration. The study reports. Author of record: Aaron
Weiskittel; prepared by Claude on autopilot. Tags: [SET ON AUTOPILOT] marks a choice made without Aaron;
[UNVERIFIED] marks an inherited number this job cannot re-derive from the moved inputs.

## 0. Question and hypotheses

The benchmark runner sets per tree `dht.mult` = NB_AFAC 0.579 (NB stands) and QC_AFAC 0.111 (QC stands) at
`cur <- data.frame(..., dht.mult = ...)` (runner line ~425; htfix copy md5 3f0f6b49, v141LT runner md5 300a0d61).
Its comment calls these "dominant height anchor factors" and "a scoring input, not a growth lever". Code facts
checked on Cardinal on 2026-09-26 (grep of AcadianGY_13.1.r, AcadianGY_14.0.4.r, AcadianGY_14.1.r, p4e model_b0b1b2.r):
- `dht.mult` enters the model in one place, `dht = dht * dht.thin.mod * dht.sbw.mod * dht.hw.mod * dht.mult`
  (13.1 line 1878). It scales the annual height INCREMENT only.
- Missing heights are imputed at the start of every annual step by `calc_ht` / `pred_ht` (13.1 lines 640 to 695,
  4059 to 4064): Chapman Richards in csi, ccf, bal with species c0 and c3; used when ht is NA, 0 or above 50 and
  dbh above 2.5. `dht.mult` does not touch this level. The imputed value is written as `pht` and appears in the
  runner's `*_pred_yr1_tree.csv`.
- `ops$use.esi.anchor.recal` and `ops$esi.anchor.coef` are set by the runner but are read by none of the four
  sourced model files (grep returns nothing). `ops$use.esi.domht` is FALSE. So in the v141LT configuration AFAC
  is the only height lever and it is an increment lever.
- The runner's `metrics()` computes observed AND predicted NSVB volume with `himp(sp, d)` (a generic two curve
  Chapman Richards, softwood 1.3+27(1-exp(-0.030 d)), hardwood 1.3+25(1-exp(-0.028 d))) wherever a height is
  missing. Observed volume therefore uses measured height or himp; predicted volume uses model heights (pht plus
  grown increment). This is a scoring asymmetry the study measures.

Hypotheses (not exclusive):
- H-level: the initial or imputed height LEVEL is off by more than 5 percent in QC or NB.
- H-volume: with observed heights substituted, predicted total volume is still more than 5 percent high.
- H-increment: tag matched height increment ratio lies outside 0.9 to 1.1 with the anchor at 1, computed
  statically as R = (observed dHT / predicted dHT) x AFAC.

Inherited context: QC tag matched survivors show predicted dHT at 7.5 to 12 percent of observed
(diag3 table md5 96e41471; re-derived here as check C3), implying an anchor near 1.27 [UNVERIFIED as a single
number; C3 re-derives the per class ratios]. QC total volume ratio screened: 1.100 under 14.0.4 (v141off arm),
1.122 under 14.1 (v141LT) (diag3 harvest screen table; re-derived here as check C2). NB raw MAGPlot tags fail
Phase D below 15 cm, same species 0.968 (re-derived as check C4); "166 of 304 pairs" [UNVERIFIED: the probe
output on Cardinal shows 318 NB pairs with tracked trees below 15 cm and prints no per pair pass table].

## 1. Data (moved to in/, manifest in manifest/, md5 checked at both ends)

Sets: qc_c, qc_fl, nb_c. Arm: v141LT (14.1, both gates on) for all tree lists; v141off results only for check C2.
- in/frames/: frozen frames bench_gyr_<set>_{tree_init,tree_t2,pairs,site_esi}.csv. TREE is a row index.
- in/pass28qc/: pass 28 QC tag frames bench_gyr_qc_{c,fl}_tree_{init,t2}.csv (TREE = MAGPlot tag), species map.
- in/v141LT/<set>/: c001_t1_split_tree (runner list at t1 after the form/risk split, ht NA where unmeasured),
  c001_pred_yr1_tree (after year 1; `pht` = pred_ht at the t1 state for every record), c001_pred_t2_tree
  (end of interval; ing = 1 for ingrowth), c001_results (per stand metrics, RUN_OK).
- in/v141off/<set>/c001_results.csv (check C2 only).
- in/magp/: extracts made on Cardinal under v142_20260925/p14/ by 2026-09-26_p14_magp_extract.R: NB nb_c plot
  tree rows (plot_id, tree_num, meas_num, species_gs, dbh, meas_est_dbh, height, meas_est_height, stem_ha,
  tree_status), tree header for NB and QC benchmark plots (magp_site_id, plot_id, meas_num, meas_year,
  taglimit_dbh), treatment table (magp_site_id, treatment_type, treatment_year).
- in/ref/: hw_formrisk_split.R, nsvb_emulator_coefs.csv, spcd_spgrpcd.csv, both runners, diag3 and qcscreen
  tables and scripts, probe_tags4_magp.R (reference and checks only).
Coordinates: none of the moved files carries lat, lon, UTM, X or Y. magp_sites.csv and magp_site_sources.csv
(which hold coordinates) were never read; pairs files carry ELEV only; raw_qc_header.rds was not moved. No column
was dropped because none of the selected files had one.

## 2. Linking runner records to trees

Runner tree ids: `tree = seq_len(nrow(it))` over the frozen frame rows of the stand (keyed sort, stable), then
`split_formrisk` keeps softwood ids and replaces each hardwood row (sp in AB PB QA RM RO SM WA YB OH) by 1..k
sub-records with ids max(tree)+1, ... in row order. The script re-runs split_formrisk (md5 0b604bab) on the
frozen rows to get sub-record id -> frame row, and hard stops unless ids, sp, dbh and expf equal the runner's
t1_split list. A hardwood tree's predicted height is the expf weighted mean over its sub-records (they share
dbh and ht at t1; expf weighting only matters after mortality) [SET ON AUTOPILOT].
QC tags: pass 28 frames are row aligned with the frozen frames (reconcile summary share 1). The script hard stops
unless (STAND, SP, DBH, HT, EXPF) agree row by row, then takes TREE as the tag. Tag matched survivor: same tag
(TREE < 9e6) present at t1 and t2 with the same SP [SET ON AUTOPILOT: same SP required].
NB tags (step 2): raw MAGPlot rows at meas_year = Y1 on plot_id = OLD_STAND are joined to frozen nb_c t1 rows
on (STAND, DBH, HT) with a within key rank; a key that is not unique on either side is dropped [SET ON
AUTOPILOT]. SP agreement after mapping species_gs with the pass 28 map is reported. Hard stop if fewer than 80
percent of frozen rows in passing pairs map [SET ON AUTOPILOT].

## 3. Step 1 (qc_c, qc_fl, nb_c)

DBH classes at t1: below 12.7, 12.7 to 25, 25 and over (cm). Populations: all RUN_OK stands, and screened.
QC harvest screen, rule verbatim from recs/diag3/2026-09-26_v142_qcscreen_nsvol.R: a stand is cut if its site
(first 8 characters of PLOTKEY) has a MAGPlot treatment whose type starts with C and whose year is in (Y1, Y2].
Check C1 (hard stop): 65 of 378 qc_c stands and 11 of 19 qc_fl stands flagged. NB is screened by the same rule
as a secondary population (5 of 355 in diag3).
(a) Measured height share at t1 by class: frozen tree_init HT finite and above 0, counted over trees and expf
    weighted, per set and population; also at t2 (tree_t2) and, for QC, from the pass 28 tag frames (must equal).
(b) Level.
    L0 identity check: runner t1 ht equals measured HT1 on measured trees (hard stop if any differs by >1e-6).
    L1 imputation level: pht (runner pred_ht at t1) vs measured HT1 on measured trees; ratio of means,
       mean percent difference, trees, stands.
    L2 scoring imputation level: himp(sp, DBH1) vs measured HT1, same stats.
    L3 t2 level: predicted t2 height vs measured HT2 on tag matched survivors with measured HT2 (QC from pass 28
       tags; NB only through the step 2 tag set). Also reported with measured HT1 at t1 (increment sample).
    Where heights are imputed, the equation is pred_ht (above); AFAC does not enter the level (code fact, checked
    in data as: for unmeasured records, yr1 ht minus pht is small, non negative, and equals the year 1 increment).
(d) Volume decomposition per stand at SCORE_MINDBH_USED, NSVB TOTVOL with the runner's own nsvb/himp code
    (copied verbatim). Check C5 (hard stop): recomputed TOTVOL_o, TOTVOL_p, TOTVOL_t1 match c001_results within
    1e-6 relative for every RUN_OK stand.
    V_o observed t2 (measured HT2 else himp); V_p predicted t2 (model heights).
    V_x predicted diameters and expf, height = measured HT2 on tag matched survivors with measured HT2, else
       himp(sp, D_pred) (QC). For NB, V_x uses himp everywhere on the predicted side (no tag stable frame).
    V_ph, V_oh: both sides with himp for every tree (a pure diameter and stem count comparison).
    Decomposition: V_p/V_o = (V_p/V_x) x (V_x/V_o): height part V_p/V_x, diameter/stem part V_x/V_o.
    Secondary: V_ph/V_oh and (V_p/V_o)/(V_ph/V_oh).
    t1 counterpart: V_t1 (TOTVOL_t1, measured else himp) vs V_t1m (measured else pht): the start level gap from
    the two imputation equations alone.
    Pooled ratios are ratios of sums over stands. Uncertainty: stand cluster bootstrap, 2000 reps, seed 20260926,
    percentile 95 percent interval [SET ON AUTOPILOT].

## 4. Step 2 (NB, trees 15 cm and over)

Raw MAGPlot, tracked trees only (tree_num < 8,000,000), measurement at Y1 and Y2 of each nb_c pair on plot_id =
OLD_STAND. Tree pairs: same tree_num at both ends, dbh above 0, t1 dbh >= 15. Per pair Phase D criteria on those
trees (logic of probe_tags4_magp.R, all statuses as in the probe): same species share >= 0.97 AND same species and
plausible (dD in [-1, 2.5 x interval]) share >= 0.98; pairs with fewer than 5 such trees are excluded [SET ON
AUTOPILOT: n >= 5]. On passing pairs, survivors = status starting with L at both ends, same species, measured
height (height > 0) at both ends. Observed dHT = H2 - H1; predicted dHT = runner t2 ht - H1 through the mapping in
section 2. Report by class (15 to 25, 25 and over), trees, stands, ratio of mean predicted to mean observed dHT,
R = (obs/pred) x 0.579, and the step 1 L1, L2, L3 quantities on the same trees.

## 5. Evidence rules (pre-registered)

Minimum cell: 30 trees in 10 stands; smaller cells are reported and marked THIN, never used as evidence
[SET ON AUTOPILOT]. Primary population: QC screened, NB all (screened as secondary).
- H-level supported in a province if L1 or L3 ratio (pred/obs) lies outside 0.95 to 1.05 in any non THIN class,
  and the bootstrap 95 percent interval excludes 1. Strong if the whole interval lies outside 0.95 to 1.05.
  L2 outside the band is reported as a scoring asymmetry finding, not as H-level.
- H-volume supported if pooled V_x/V_o > 1.05 and its interval lower bound > 1.00 (screened for QC).
  Not supported if the upper bound < 1.05. Otherwise inconclusive.
- H-increment supported if R lies outside 0.9 to 1.1 in any non THIN class and its interval excludes 1.
  Static approximation: dht is proportional to dht.mult within a year, so the unanchored increment is taken as
  predicted/AFAC; feedback through height on later years, crown ratio and caps is ignored and stated as a limit.
- Reading (reported, not gated): H-increment with R near 1 and H-volume supported points to the anchor
  compensating a volume problem upstream of increment; H-level supported points to the imputation equation.

## 6. Hard stops and run protocol

Hard stops write `P14_FAIL <step>` to logs/_status_p14.txt: md5 mismatch on any input (C0), C1 screen counts,
C2 screened qc_c v141LT TOTVOL ratio 1.122 and v141off 1.100 within 0.001, C3 softwood only QC tag check
reproduces diag3 qc_c trees per class exactly, C5 volume recomputation, L0, split re-derivation, NB mapping share.
R 4.5.1, data.table, seed 20260926, R_LIBS_USER=/home/aaron/R/x86_64-pc-linux-gnu-library/4.5. No em dashes.
launch_after_htf.sh waits (300 s loop) until ~/jobs/v142htf/home/logs/_status.txt contains ALL_DONE, never
touches ~/jobs/v142htf, then runs step 1 then step 2, writes tables/, an md5 list and a tgz, and ends the status
file with P14_DONE or P14_FAIL <step>. Nothing is sent to anyone. Zenodo deposit and GitHub push are deferred to
Aaron (the job is diagnostic and includes MAGPlot derived tree data).

## 7. Deviations

Any deviation after this file is written is appended below with a date, never edited above.

- 2026-09-26, after the one minute smoke (15 stands per set, 50 bootstrap reps, smoke/), before the full run.
  (1) Transfer: the laptop scp could not create /tmp/v142p14/, so the inputs moved as one archive
  /tmp/v142p14_in.tgz (md5 82344724e0cf406abe65cce7ed61081f at Cardinal, laptop and firebreather); the 52 member
  md5s were checked on firebreather against the Cardinal list (manifest/in_md5_cardinal.txt).
  (2) NB mapping ties (section 2): resolved by within key rank, raw ordered by tree_num and frame by row order,
  instead of dropping non unique keys; frozen NB frame rows follow tree_num order. The unique key only sample is
  reported as a sensitivity (sample column). Smoke: 659 of 659 frame rows in passing pairs mapped, SP agreement 1.000.
  (3) Increments are per year, (H2 - H1) / interval_years on both sides, as in the diag3 script; ratios are ratios
  of sums of those per year values. Stands where the runner horizon differs from Y2 - Y1 are counted (0 in smoke).
  (4) C4 is reproduced exactly (NB below 15: 10633 trees, 318 pairs, same species 0.968306).
  No evidence rule, threshold or population changed.

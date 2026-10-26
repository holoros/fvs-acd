# PREREG49 server lookups (26 October 2026)

Read only lookups on firebreather for the PREREG49 draft (NS survival over multi year steps and the v141LTfi Bakuzis question). Nothing was run, edited or moved; only this file was written. All md5 values are full md5sum output taken on 26 October 2026. No stand, plot or coordinate values are reproduced.

## Summary table

| Item | File (full path) | md5 | Confidence |
|:--|:--|:--|:--|
| 1 driver | /home/aaron/jobs/v142p26/scripts/driver_p26.R | 9696daea51f491e74967cca24d08a6aa | High |
| 1 runner it copies | /home/aaron/jobs/v142p22/home/runner_p20_fb.R (lines 1 to 419) | 65392afbbe67e2e80524855fea7a41da | High |
| 1 thresholds script | /home/aaron/jobs/v142p26/scripts/thresholds_p26.R | 48633d838626381124f0d7a69328eb1b | High |
| 1 thresholds output | /home/aaron/jobs/v142p26/assembled/thresholds_p26_DATA_2026-09-30.csv | cf3d3c247b647a73a783f55c8c95fedb | High |
| 1 PREREG26 plan r2 | /home/aaron/jobs/v142p26/plan/2026-09-30_v142_bakuzis-ns-v141LTfi_PREREG26.md | 291bb1ecedaf59bbb13f53408077d20e | High |
| 1 PREREG26 RESULT | /home/aaron/jobs/v142p26/2026-09-30_v142_bakuzis-ns-v141LTfi_RESULT.md | 1f7a7f54711464b3905bb54ed594fab2 | High |
| 1 seed | set.seed(20260930), driver_p26.R line 475 | (in driver md5) | High |
| 2 fold rule, PREREG22 script | /home/aaron/jobs/v142p22/scripts/2026-09-27_v142_p17_summ.R (line 9) | 14c530827fd9e8f5685911c9bb1dacb3 | High |
| 2 fold rule, PREREG22 rederive | /home/aaron/jobs/v142p22/verify_20260930/p22_rederive_rev3.R (line 12) | 1de2d7f8036092024ffcb5c29aaa559c | High |
| 2 PREREG22 plan | /home/aaron/jobs/v142p22/plan/2026-09-29_v142_ns-height-by-ingrowth_PREREG22.md | 4d7b64ad8d8b18add4f25bf0b07edacc | High |
| 3 frozen v141LTfi results, ns_c | /home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_c_results.csv | 9fe608de2e4261bd60d637019c83022e | High |
| 3 frozen v141LTfi results, ns_fl | /home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_fl_results.csv | 52c8b5882d9f18ab7c2f807b0297306a | High |
| 3 frozen v141LTfi results, ns_long_c | /home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_long_c_results.csv | 9ac03bc21b372d26791b9919f83a5948 | High |
| 3 frozen v141LTfi results, ns_long_fl | /home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_long_fl_results.csv | cf8bf849176715a9b1dfad9c8c715e17 | High |
| 3 per tree outputs | /home/aaron/jobs/v142p22/home/out/v141LTfi/{ns_c,ns_fl,ns_long_c,ns_long_fl}/cNNN_*.csv | combined md5 of all 36 cNNN_pred_t2_tree.csv lines: b0516d6712dbcf025920be3e7480712d | Medium (directory, not one file) |
| 3 PREREG22 env (arm definition) | /home/aaron/jobs/v142p22/home/p22_env.sh | a77e811715ccf4d82f96f430db36f8c5 | High |
| 3 PREREG26 frozen grid trajectories, v141LTfi | /home/aaron/jobs/v142p26/out/traj_v141LTfi_BF.csv, _MX.csv, _RS.csv | b10a03bb2be602196c18838afb2fc8aa, e7c7dc0ec751cc5443e09cd58ad79aaf, dc7479cdd3576efe0f33eb9ddb1dc5d2 | High |
| 4 engine (mortality) | /home/aaron/jobs/v142p22/home/v14_0_4_20260917/AcadianGY_14.0.4.r | 61f95d99f896e8e513930d6e33a7391a | High |
| 4 14.1 overlay | /home/aaron/jobs/v142p22/home/v14_1_20260923/AcadianGY_14.1.r | 0bf27dde81240e6bdf59c9a90f0051bd | High |
| 5 PREREG27 fold A survivor table | /home/aaron/jobs/v142p27/fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv | f11349019596f6b8f198fba680973f5a | High |
| 5 PREREG27 repro check script | /home/aaron/jobs/v142p27/scripts/2026-09-30_v142_p27_confirm.R | b0b80b6146149b73663381d3b48fe0a6 | High |
| 5 PREREG27 shared lib | /home/aaron/jobs/v142p27/scripts/p27_lib.R | 6da99284aac424a1187cbbe899679ab4 | High |
| 5 PREREG27 table writer | /home/aaron/jobs/v142p27/scripts/2026-09-30_v142_p27_diag2.R | 4d0cffc8ea78e335516c89e4eb6583dd | High |
| 5 PREREG44 slgrid driver | /home/aaron/jobs/v142p44/scripts/driver_p44.R | 7d5da479e5016f8d4f00568c93e9efe0 | High |
| 5 PREREG44 slgrid branch part | /home/aaron/jobs/v142p44/scripts/parts/slgrid_branch.R | 110b1f524e363387bdc1f34f10560ae1 | High |
| 5 PREREG44 build script | /home/aaron/jobs/v142p44/scripts/build_driver_p44.sh | eb2c857a13b1936c03e4eb68fd1c6af9 | High |

## 1. PREREG26 NS Bakuzis grid driver, thresholds and seed

The PREREG26 RESULT names the driver: "Driver `driver_p26.R` (runner `runner_p20_fb.R` lines 1 to 419 byte for byte), assembly `assemble_p26.R`." build_driver_p26.sh checks the runner md5 (65392afb...) and concatenates parts/head.txt, the first 419 runner lines and parts/p26_block.R. The driver md5 matches the value recorded before launch in /home/aaron/jobs/v142p26/logs/launch_md5s.txt.

Thresholds: thresholds_p26.R re-derives the NS frontier and BA and SDI percentiles from ns_c t1 lists (trees 9.1 cm and over) and writes thresholds_p26_DATA_2026-09-30.csv, which assemble_p26.R reads at line 11 ("TH <- fread(file.path(J, \"assembled/thresholds_p26_DATA_2026-09-30.csv\"))"). Logged values: n_stands 5566, frontier_a 4.9869, frontier_b -1.3108, BA_q99 54.75, BA_q999 70.00, SDI_q99 1277.9, SDI_q999 1600.8, eichhorn_obs_meanCV 0.1043 over 7 bins. The relation pass rules themselves (Reineke band, ordering, NI rule) are stated in the PREREG26 plan, not in a separate file.

Seed: driver_p26.R line 475, "set.seed(20260930); D0 <- runif(40, 2, 5)   # one draw, shared by every cell and arm". The plan says the same (seed 20260930). This seed governs only the synthetic 40 record DBH cohort; there is no other set.seed in driver_p26.R.

Confidence: high. Caveat for PREREG49 stage 2 (see item 5): the PREREG44 slgrid edit anchors on P31_MODE strings, while driver_p26.R uses P26_MODE (line 431: if (!(P26_MODE %in% c("g0","grid")) ...). The PREREG44 edit as written will not match driver_p26.R.

## 2. PREREG22 fold rule

The fold rule is a deterministic hash, not a seed: md5 of the SITE string (digest, serialize = FALSE), first hex digit even is fold A, odd is fold B. PREREG22 uses it in /home/aaron/jobs/v142p22/scripts/2026-09-27_v142_p17_summ.R line 9:
"fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = \"md5\", serialize = FALSE), \"\"), 1, 1), 16L) %% 2 == 0, \"A\", \"B\")"
The header of that script calls it the "PREREG11 rule: md5 of SITE, first hex digit even = A". The same function appears as fold_of in /home/aaron/jobs/v142p22/verify_20260930/p22_rederive_rev3.R line 12, and verbatim in PREREG27 (2026-09-30_v142_p27_diag.R and _confirm.R line 12). The PREREG22 H2 script (2026-09-29_v142_p22_h2.R, md5 ce974a15517b8cb9dd7429d76dd55c82) does not compute folds; it reads a precomputed fold column from /home/aaron/jobs/v142p22/in/key/p20_htkey_<set>.csv.

Confidence: high for the function and files. The original PREREG11 source file was not located under ~/jobs (no v142p11 directory found).

## 3. Frozen v141LTfi benchmark output

The arm is defined in /home/aaron/jobs/v142p22/home/p22_env.sh (case v141LTfi: HTFIX_B1=0.034416, HTFIX_B2=0.005072, ING_MIN_FROM_SCORE=1, IMULT=$P22_IMULT); /home/aaron/jobs/v142p22/plan/mstar.env sets P22_IMULT=1.5. Results files are the four CSVs in /home/aaron/jobs/v142p22/results/v141LTfi/ (md5 in the table). Plan /home/aaron/jobs/v142p22/plan/p22_plan_fb.csv maps each set to that results file and to tree directories home/out/v141LTfi/<set> plus out_retry_a1 to a3; the retry directories do not exist, so the main chunks are the full per tree output (ns_c 7 chunks, ns_fl 5, ns_long_c 12, ns_long_fl 12; each chunk has pd_t1, pd_t2, pred_t2_tree, pred_yr1_tree, results, t1_split_tree, traj). PREREG27 reads the same files as its frozen v141LTfi reference (p27_lib.R line 11: fi = "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_%s_results.csv", and ARM fi = c("/home/aaron/jobs/v142p22/home", "v141LTfi")). For the stage 2 G0b gate, the frozen PREREG26 grid trajectories are /home/aaron/jobs/v142p26/out/traj_v141LTfi_{BF,MX,RS}.csv, also assembled in /home/aaron/jobs/v142p26/assembled/gyr142-p26-traj-annual_DATA_2026-09-30.csv (md5 83dd415b672d2065e21e15dd7446efea).

Confidence: high for the results CSVs and trajectories. The per tree outputs are a directory set; I recorded one combined md5 over the 36 pred_t2_tree chunk md5 lines, and per file md5s should be written into the plan at registration.

## 4. Does the runner separate density dependent from background mortality?

Not as separable tree level terms. With LINKED=1 and LINKED_MODE=L2 (p22_env.sh), the v141LTfi arm sources AcadianGY_14.0.4.r, whose calc_mortality (line 934) calls .acd_v14_mortality (line 641) when ops$use.linked.mortality is on; make_ops sets use.sdimort FALSE under the lever (line 1017), the runner sets use.mortcal FALSE (runner line 276), and the 14.1 overlay contains no mortality code. The plot level decrement is computed in .acd_v14_stand_decrement (line 504):
- a Garcia stage 2 decrement driven by top height growth with an SDI term (line 550: lnS2 <- .acd_v14_garcia(S1n, H1, H2, s2, lSDI1)), gated by the stage 1 linkage indicator, giving N2_L1 (line 573);
- a separate floor hazard (lines 553 to 559: cloglog of relative spacing, BA, Dq, balsam fir share, intolerant hardwood share and interval; N2_floor <- N1 * (1 - pf));
- L2 takes the larger kill: line 579, N2_L2 <- if (fx_fd && fit_ok) N2_L1 else min(N2_L1, N2_floor), with linked.fix.floordomain FALSE by default.
Stage 3 (lines 735 to 764) then allocates the single total kill to stems by proportional allocation on a per stem cloglog hazard, writing td$.dexpf.

So the engine has a density driven Garcia branch and a floor branch at plot level, but they are combined by min(), the floor itself carries density covariates (relative spacing, BA, Dq), and the tree level output is one decrement per record with no background component. The PREREG49 [ASSUMPTION] should resolve to: the switch acts on the whole record annual survival p_t (the stage 3 allocated decrement), not on a background term.

Confidence: high for the code reading; medium on whether the floor should be called background, since it is not density free.

## 5. PREREG27 fold A survivor table and PREREG44 slgrid branch

Fold A table: /home/aaron/jobs/v142p27/fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv (68 data rows plus header; written by 2026-09-30_v142_p27_diag2.R line 24). It carries a prog column (NS_OP rows are present). The confirm script reproduces it at 1e-9 before any fold B read (confirm.R line 29 reads it; line 34: if (... || e > 1e-9) stop("REPRO FAIL fold A table: ", ...)). Recorded check /home/aaron/jobs/v142p27/assembled/gyr142-p27-repro_DATA_2026-09-30.csv (md5 c3f8796db89c57b17942a15a53beaa65): foldA_survrec, 68 cells, worst 4.88e-15, pass TRUE. The RESULT (md5 54ad489da4c657048c8f57d0f2fa569b) states the same.

PREREG44 slgrid: /home/aaron/jobs/v142p44/scripts/driver_p44.R contains the branch (line 437 mode check admits "slgrid"; line 470 if (P31_MODE == "slgrid") {; line 494 writes output). It was built by build_driver_p44.sh from /home/aaron/jobs/v142p31/scripts/driver_p31.R (md5 checked as 467fb5188a868ed4be4cba9e5a53a3dc) with two edits asserted to match once (anchors 'if (!(P31_MODE %in% c("g0","grid"))' and 'if (P31_MODE == "g0") {') and the inserted parts/slgrid_branch.R. driver_p44.R, build_driver_p44.sh and parts md5s match /home/aaron/jobs/v142p44/logs/launch_md5s.txt. PREREG44 stand draw seed: set.seed(20261005) in select_p44.R line 32.

Confidence: high. Two cautions for PREREG49 stage 2: (a) driver_p31.R was built from the QC runner /home/aaron/jobs/v142p28b/home/runner_p28_fb.R (md5 0a2b2742...), not from runner_p20_fb.R, so driver_p44 and driver_p26 descend from different runners; (b) the slgrid anchors name P31_MODE, so transplanting the branch into driver_p26.R needs anchors rewritten to P26_MODE (and P31_* environment names inside slgrid_branch.R, for example P31_SMD at line 475, renamed or mapped). The plan text "an edit asserted to match once" should name the new anchors explicitly.

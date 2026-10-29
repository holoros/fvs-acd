# PREREG50 lookups (plan revision 1, md5 6ea850d4), written before any arm ran

## L1 sources and copies

See lookups_L1_md5.txt (written 2026-10-28T07:04:44-03:00). Every md5 named in the plan Sources matches:
    4e6a29971922b1f7a0397cc91ff56f84  v142p19/home/runner_htfix_fb.R
    ac029e4e6eeb1d71f1784b423c8575fc  v142p19/scripts/run_task_p19.sh
    5894df6013c701d09e7ba67ba6c2f090  v142p19/home/AcadianGY_13.1.r
    61f95d99f896e8e513930d6e33a7391a  v142p19/home/v14_0_4_20260917/AcadianGY_14.0.4.r
    0bf27dde81240e6bdf59c9a90f0051bd  v142p19/home/v14_1_20260923/AcadianGY_14.1.r
    04a0b71da081ae98d1473391c9976896  v142p19/home/magplot/verify/p4e/model_b0b1b2.r
    979101bedafe16c090ce84d1e5e46a07  v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv
    184dc76888580de7c2cfdb7e2ec8580f  v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv
    59196106afe20e57ca1bc7b4894495f1  v142p45/scripts/2026-09-29_v142_p23_hkey.R
    265fc6950ce3f18da751da8b9fd3dbc2  v142p45/scripts/2026-10-01_v142_volconv_score_r2.R
    14c530827fd9e8f5685911c9bb1dacb3  v142p22/scripts/2026-09-27_v142_p17_summ.R
    b8829fa5d37097e024b3733d2e48d30c  v142p48/scripts/p48_split.R
    8c7a865c7723de443d0c35fa973497aa  v142p48/scripts/p48_boot.R
    4e6a29971922b1f7a0397cc91ff56f84  v142p50/home/runner_htfix_fb.R
    5894df6013c701d09e7ba67ba6c2f090  v142p50/home/AcadianGY_13.1.r
    0bf27dde81240e6bdf59c9a90f0051bd  v142p50/home/v14_1_20260923/AcadianGY_14.1.r

ingrowth matches in the 14.1 overlay copy: 0
bundle md5 identical to source (/home/aaron/jobs/v142p19/home): 46 files
Runner copy runner_p50_fb.R md5 7bd249b2e63ffc056600a62cc2345456; diff in diffs/runner_htfix_fb.R_to_runner_p50_fb.R.diff (the two edits only).

## L2 threshold support

L2 threshold support: not found. No record of the threshold range in the fit data of the engine's ingrowth equations (Li, Weiskittel and Kershaw 2011 GNLS parameters, ENG lines 2774 to 2779) was found on firebreather.
Read 2026-10-28 from lookups_L2_candidates.txt (71 candidate files): copies of the engine and of AcadianGY.R in FVS interface trees (citation only), koa manuscript text and a publication list (citation only), the PREREG43 search hit list (no threshold range), and git mirrors under ~/repos-mirror (fvs_remodeling, fvs-modern, fvs-acd; a git grep of fvs-acd for an ingrowth fit threshold range returned nothing).
Related but not a record of the engine's fit: ~/jobs/ingrowth_refit_20260917 is a separate ingrowth refit whose prediction table carries per stand thresholds (values such as 9.1 and 12.7 cm appear); it is not the source of the engine coefficients and was not used.
The laptop repository was not searched by this run (plan, Support limit).

## L3 (gate G7)

29 files contain ING_MIN_FROM_SCORE=1; 0 also name qc_c or qc_fl. File list: lookups_G7.csv.

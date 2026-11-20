# Seven Islands 100-year benchmark: additions of 19 and 20 November 2026

Host firebreather; queue ~/bin/fbq. Restricted inputs and per-plot outputs stay in ~/restricted/silc_agmbench_gapfill_20261117.

- 07 to 09: 2x2 factorial (multipliers x brms SDImax) and the four FVS-ACD 14.3 arms on all 525 plots (bridge_silc3.R; launch2/3).
- 10 to 14, bakz_final.sh: Bakuzis set (25 stands across strata x site index 12, 15, 18 m; 75 runs per model), assessment, figures and
  the step-aware checker (~/jobs/acd_bakuzis/bakuzis_check_step-aware_FINAL_2026-09-07.R, 0.40, 0.10) per arm (launch4).
- 15 to 18: final aggregates (stand-cluster bootstrap, 2,000 draws, seed 20261117), figures 1 to 4, and the cap check on the model's
  own relative density definition.
- products/19 to 23: tree lists for OSM 2.26.1 and FVS-NE (rerun of PR 30's run_seven_islands_100yr.py keeping tree lists) and the
  three FVS-ACD bridge arms; merchantable cords, sawlog MBF, stumpage value and aboveground carbon (SILC v22 merch pipeline:
  kozak_taper.R, merch_cords.R, merch_asg.R from the v22 Zenodo deposit, not copied here; Aroostook County 2024 Maine Forest
  Service stumpage with pulpwood converted from $/ton to $/cord; NSVB biomass with k = 9 softwood and 11 hardwood; FIA Maine
  carbon fractions); aggregates and figure 5.
- Code only: no plot data, coordinates, stand identifiers or tree lists.

# Frozen engine files as run on Cardinal (copied 19 October 2026)

These are byte copies of the files the 14.0.4, 14.1 and 14.3 PREREG1 benchmarks ran on OSC Cardinal, so that a clone can run 14.1 end to end. md5 of each file:

| File | md5 | Role |
|:--|:--|:--|
| AcadianGY_13.1.r | 5894df6013c701d09e7ba67ba6c2f090 | 13.1 base the benchmarks ran (the older `scripts/AcadianGY_13.1.r` in this repo is 5140bf9b) |
| model_b0b1b2.r | bb51eeada62796532ce3a7212a5c6451 | 14.x base (`ACD_V14_BASE`); every Cardinal 14.x launcher checks this md5 |
| AcadianGY_14.0.4.r | 61f95d99f896e8e513930d6e33a7391a | 14.0.4 linked mortality engine |
| AcadianGY_14.1.r | 0bf27dde81240e6bdf59c9a90f0051bd | 14.1 option 3 overlay (L and T) |
| v14_coef_bundle_2026-09-08.rds | see `md5sum` | `LINKED_COEF` (launchers check 4740de88) |
| v141_option3_offline_coefs_r5_2026-09-23.rds | see `md5sum` | `V141_COEF` (launchers check c8f02f58) |
| hw_formrisk_split.R, hw_sawfrac_smith.R | 0b604bab, 918fc303 | helpers the runner sources from `~` |
| 2026-09-25_v142_phaseD_runner_p23_tst_counters.R | 300a0d610070f77517352c8e23f07922 | counters runner |
| 2026-09-16_gydbreg-phaseD_trajhooks.R | a217889b4342398bd7af51efe9b93aaa | Phase D trajectory hooks |
| 2026-08-19_v132_sitefsm_overlay_WIP.R | dc249665be905da9e330eebcd64ce624 | sourced only when V132=1 |
| nsvb_emulator_coefs.csv, spcd_spgrpcd.csv | 98cfb4e7, 2f3f9819 | coefficient tables the runner reads |

Not included: `v129_gate3_dedup.csv` and `v129x_brms_sdimax_map.csv`, which the runner reads from its working directory. Both are keyed by stand identifiers and stay on the compute hosts. `USE_BRMS` is inert in 13.1, so the second affects nothing; the first sets `ops$active_ecobucket`, which matters only when the forest type SDImax multiplier is set (it is not in any 14.x benchmark).

The files hard code Cardinal paths (`/users/PUOM0008/crsfaaron/...`, `~/`): `model_b0b1b2.r` sources the 13.1 base by absolute path, and the runner sources the helpers from `~`. Copy them to those locations, or edit the paths, to run elsewhere. The two coefficient rds files were scanned and hold no identifier-like data frames.

The md5 04a0b71da081ae98d1473391c9976896 recorded for `model_b0b1b2.r` in the 14.2 records appears only in a firebreather launch bundle (`v142_20260925/recs/htfix/fb_bundle/home/run_task.sh`). It is firebreather's copy and was not verifiable on 19 October (host unreachable). The benchmarked 14.1 used bb51eead. No em dashes.

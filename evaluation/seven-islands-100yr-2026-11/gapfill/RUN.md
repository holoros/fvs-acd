# RUN: Seven Islands 100-year gap-fill, 17 to 18 November 2026

Host firebreather (private alias), R 4.5.1, Python 3.9 (perseus_me environment). All jobs through `fbq`, one thread each. Job folder `~/jobs/silc_agmbench_100yr_20261117`; restricted folder `~/restricted/silc_agmbench_gapfill_20261117` (plot records, coordinates, keyfiles, per-plot output). Only the files in this deliverable folder left the server.

## Inputs (md5)
- plots.csv daee2e4fc96dd19eff42dddd566963e3 and trees.csv b11af67ced743726b8dcddda5e241ba0, byte copies of the PR 30 inputs built from Seven Islands' two workbooks of 13 November 2026 (536 plots, 525 with live trees, 117 stands with trees, 3,715 records at DBH of 1 cm or more).
- GitHub, read 17 November 2026: holoros/fvs-acd main 3f4ee21a, inside-bark-dg (PR 28) 1837778d, analysis/seven-islands-100yr-20261117 (PR 30) 2a236c2c.

## Engines (md5)
- Production arm: AcadianGY.R 65ff4cbfb12d3ab5080b4e5a771f687a (12.5.2), customRun_fvsRunAcadian.R dcb970c4b9a9e228dc3421619ea68a8d, FVSne.so f4864c459ef0bb8f86b6b736f1133e54.
- 14.2 arm (x142sb): AcadianGY.R 0b1a06cf9a1d83ffeb6b5dc050e2ab9e, x142_gseq.csv f7be2c66dabe26d07a66636ab331a647, silc_sdib.csv d7cd17fa187963d5d2dee1a9d1096571.
- Runner: bridge_silc.R d2ecf67c26e48caac88bc56f8a9da181, which is tools/v26_V/bridge_batch.R (f7d5d5c08ff39c1f26b938ee97369653) with one line changed so the ingrowth switch is read from SILC_INGROWTH.
- Research arms: AcadianGY 12.11.1 127cffc3..., 13.1 5894df60..., 14.0.4 61f95d99..., 14.1 0bf27dde..., v14 coefficients 4740de88..., v14.1 coefficients c8f02f58..., run_acd_versions_100yr.R 00416fd6a22648ae100c08cb79dd4d5c (PR 30 files, unchanged; no sample file, so all plots run).

## Choices
- One plot is one stand. 20 BAF at DBH of 4.6 in or more, otherwise 1/500 ac; DBH under 1 cm dropped, as in PR 30.
- Species: CE to WC, WB to PB; codes outside the model's species table to OH (HE and NC to OS). In the bridge arms PC goes to PR, because production dropped the PC row.
- Bridge keyfiles: per-acre expansion in the tree record (DESIGN -1 1 999), location 922, age 60, slope 5, elevation from the stand table, site species BF, Seven Islands climate site index passed directly as CSI through COMPUTE, twenty 5-year cycles, tree list every cycle.
- Bridge run options: ingrowth Yes, minimum DBH 3.0 in, cut point 0.95, Acadian mortality, base model volume, thinning modifier on, budworm off.
- brms SDImax: track G lookup (L3 ecoregion x forest type group, at least 30 FIA plots), type group from the starting tree list, plot coordinates read on the server only.

## Run order
prep.sh; launch.sh (smoke test of two plots per bridge arm, then the queue: 4 bridge shards, 8 research shards, 2 cycle-length checks, 4 ingrowth-off shards); post1.sh; post2.sh (05_aggregate.py, 06_figures.R). Wall time per shard 3.9 to 5.7 hours. Bootstrap seed 20261117, 2,000 draws, stands as clusters.

## Status at 08:50 ET, 18 November
Complete: both bridge arms with ingrowth on (525 of 525, return code 0), the four research arms (525 of 525), both cycle-length checks (41 plots each). Running: ingrowth-off bridge arms (293 and 257 of 525 done).

GitHub: not pushed. Zenodo: not applicable, exploratory comparison on proprietary data.

# PREREG43 searcher B findings: provenance of QC_AFAC 0.111

5 October 2026, searcher B (independent verifier), firebreather `~/jobs/v142p43/search_b/`. Plan md5 e3326190b1c8dd00d0ea6bdd261023c8 checked before the search. Records only. search_a not read. No coordinates, no per tree rows.

## Search as run

Roots `~/jobs`, `~/repos-mirror`, `~/src`, `~/output`; extensions .r .R .md .txt .csv .json .sh .py .log; size at most 5 MB; literals `0.111`, `QC_AFAC`, `dht.mult` (fixed strings, case sensitive). Pruned: `jobs/v142p38` to `jobs/v142p43`, any path component matching `*gh_v142*`, `*_laptop*`, `*_PREV_*`. 42,671 files scanned, 73,567 hit lines (QC_AFAC 1,374; dht.mult 1,617; 0.111 only 70,621) in 5,227 files. Scripts: `scan_b.sh`, `prep_b.py`, `classify_b.py`.

Read in full where the literal appears: `AcadianGY_14.1.r` (0bf27dde): no literal. `runner_p28_fb.R` (0a2b2742): `Sys.getenv("QC_AFAC","1")` default 1 (USE), comment and warning naming 0.579/0.111 as the freeze values (MENTION), line 425 assigns `dht.mult` from QC_AFAC (USE). v141 coefficient bundle (`v141_option3_offline_coefs_r5_2026-09-23.rds`, c8f02f58, read in R): no value within 5e-4 of 0.111, no afac or dht names.

## Counts by class (all 73,567 hits)

SET 61; FIT 0; USE 1,893; MENTION 71,613. The table lists 5,537 rows: every SET and USE, and MENTION from code, prose and logs (3,113 of them tagged `[unrelated]`, mostly koa HiGy `dht.mult` and stray 0.111 numbers). Not listed, counted only: 68,030 CSV data rows holding 0.111 as a number (51,118 under FVS-ACD job folders, mostly v142p31 and v142p33 trajectories; 16,912 under koa and other unrelated folders).

## Earliest dated SET

All repos-mirror files carry the mirror copy mtime (2026-08-25), so dates there come from file names and contents. The earliest dated SET is `repos-mirror/fvs-acd/docs/handoffs/20260710_v12101_FREEZE_and_run_recipe.md` line 22 (md5 478c67fa...), `export NB_AFAC=0.579 QC_AFAC=0.111`, the 10 July 2026 operational recipe for `bench_parity.R` on Cardinal (`MODEL_FILE=~/_scripts/AcadianGY_12.10.1.r`, `CONFIG_TAG=cb_v12101`). Undated repos-mirror script SETs of the same era: `run_bench_frozen.sh:48`, `bench_parity_v130.sh:75`, `run_v130_baonly_adopt.sh:92`, `fit_v130_esi_anchor_cofit.R:229`, `fit_v130_esi_anchor_cofit_v2.R:306`, `stress_cfi_extrap_v25.R:57,71` (dated 20260812 inside). The earliest firebreather born SET by mtime is `jobs/v142htf/home/run_task.sh:17` (2026-09-26 12:35, 81c9f0b0); every later v142 runner SET (p15 to p37) copies that export line.

Traced inputs of the earliest SET: `bench_parity.R` on Cardinal, which reads QC_AFAC from the environment with default 1 (quoted in `FROZEN_HARNESS_README.md`); the value is supplied by the wrapper. `bench_parity.R` and `run_parity.sh` are not in the search set (not on firebreather). The prose (GTR draft line 489) calls the pre freeze value the "development afac"; no file says where 0.111 came from.

## FIT hits

None. No script or table in the search set estimates 0.111. Checked and not FIT: PREREG19 (`v142p19`) grid scored 0.111 as one arm and selected 0.030, verdict "flat ... not adopted"; PREREG23 (`p23_fit.R`) and PREREG28 (`p28_fit.R`) estimate other values (1.061; 1.265/0.030 pair) with 0.111 as the reference arm; PREREG14 step 1 (`p14_common.R:13` SET, tables USE) evaluates increment at 0.111 and fits nothing. These are classed SET or USE, not FIT. The repos-mirror v130 cofit scripts fit `esi.anchor.coef` and pass 0.111 through unchanged.

Frames, for reference only (no FIT read them): `v142p14/in/frames/bench_gyr_qc_c_tree_init.csv` md5 6fb1ff68... (run frames); `v142p14/in/pass28qc/bench_gyr_qc_c_tree_init.csv` md5 521d6468... (field tag frames).

## Pairing verdict

**not found.** Within the search set, 0.111 enters only as an assigned constant (env export, R vector, recipe), first dated 10 July 2026 in the v12.10.1 freeze recipe for the Cardinal `bench_parity.R` harness. No record of the fit, its data, or its tag pairing exists on firebreather.

## Not searched

The fvs-acd branch history (plan item 2). Note: `~/repos-mirror/fvs-acd/.git` exists but was not read. Cardinal, including `bench_parity.R`, `run_parity.sh` and `cb_v12102`/`cb_v12101` outputs. The laptop (plan item 3). Binary formats (.rds, .docx, .pptx, .pdf) and files over 5 MB, apart from the v141 coefficient bundle the plan names.

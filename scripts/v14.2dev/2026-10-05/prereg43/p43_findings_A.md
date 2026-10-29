# PREREG43 searcher A findings: provenance of QC_AFAC 0.111

5 October 2026, firebreather, searcher A. Plan md5 e3326190b1c8dd00d0ea6bdd261023c8 verified. Records only. No coordinates.

## Search as run

Roots ~/jobs, ~/repos-mirror, ~/src, ~/output (empty). Extensions .r .R .md .txt .csv .json .sh .py .log, size at most 5 MB.
Excluded paths: v142p38 to v142p43, ~/jobs/gh_v142, any path containing `_laptop` or `_PREV_`. 42,671 files; fixed string,
case sensitive grep for `0.111`, `QC_AFAC`, `dht.mult` (scan.sh, raw_hits.txt). 73,567 matching lines.

Classes (p43_hits_A_DATA_2026-10-05.csv): SET 61, FIT 78, USE 2,368, MENTION 3,357 listed lines, plus 67,703 matches of
`0.111` as numeric csv data in 3,460 files unrelated to the anchor, aggregated one row per file (MENTION, rows not copied).

## Earliest dated SET

By document date: `~/repos-mirror/fvs-acd/docs/handoffs/20260710_v12101_FREEZE_and_run_recipe.md` line 22,
`export NB_AFAC=0.579 QC_AFAC=0.111` (md5 478c67fa..., dated 10 July 2026 in name and text; file mtime 2026-08-25 13:18 is the
mirror copy time, shared by every repos-mirror file, so mtime cannot order the mirror SETs). The same mtime holds for the
undated mirror SETs in run_bench_frozen.sh:48, run_v130_baonly_adopt.sh:92, bench_parity_v130.sh:75,
fit_v130_esi_anchor_cofit.R:229, fit_v130_esi_anchor_cofit_v2.R:306, stress_cfi_extrap_v25.R:57 and 71.
Earliest SET by mtime outside the mirror: `~/jobs/v142htf/home/run_task.sh` line 17 (2026-09-26 12:35, md5 81c9f0b0...).

Traced inputs of the earliest SET: none. The recipe says the value is read by `bench_parity.R` on Cardinal from the environment
(default 1.0) and reproduces cb_v12101; VERSION_HISTORY.md (line 76 to 77) lists it as part of the AcadianGY_12.9.2.r ops recipe
behind the frozen v12.10.1; the 14.1 runner comment (runner_p28_fb.R line 237 to 238) says the per province AFAC assembly is
"reused unchanged from v12.11". No file states the data, pairing or method that produced 0.111. `bench_parity.R` itself is not
on firebreather (only bench_parity_v130.R, which passes QC_AFAC through). The mirror GTR draft (20260629, line 483 and 503)
describes 0.111 only as the operational value (MENTION).

14.1 harness: AcadianGY_14.1.r (0bf27dde, 12 copies) contains none of the three literals. runner_p28_fb.R (0a2b2742) reads
QC_AFAC from the environment with default 1 (line 232, USE), comments and warns that the freeze uses 0.579/0.111 (235, 241,
MENTION) and sets QC dht.mult from QC_AFAC at initialisation (line 425, USE). No v141 coefficient bundle file was found by name.

## FIT hits

Every FIT found estimates a replacement for 0.111; none estimates 0.111. Each reads 0.111 as the reference grid arm.

| FIT | files (md5, mtime) | data | frames read | class |
|---|---|---|---|---|
| PREREG19 grid selection | gyr142-p19-selection_DATA_2026-09-28.csv (9b303cd8, 09-28 23:04) | stand level C1 volume ratio, screened qc_c fold A, arms 0.030 to 1.000 | engine runs on v142p19 frames, qc_c init 6fb1ff68 | run frames; no tree pairing (other) |
| PREREG23 fit | 2026-09-29_v142_p23_fit.R (ade1780c), log_fit.txt (8c312973), gyr142-p23-fit-hinc-foldA_DATA (570ac0d4), all 09-29 07:43 | tag matched survivors, screened qc_c fold A, R(a)=1 by log interpolation | hkey helper 59196106: v142p19 frames bench_gyr_qc_c_tree_init 6fb1ff68 and tree_t2 684ebb34, TAG = TREE, plus row0 join to predictions | run frames, row index |
| PREREG28 fit | 2026-09-30_v142_p28_fit.R (fe2a9932) and gyr142-p28-fit-class-foldA_DATA (0aa25cda), in v142p28 (09-30 07:45) and copied to xfer_p26p29 (09-30 14:16) | same key, class zero bias and step/taper forms on eight arms | same helper and frames (6fb1ff68, 684ebb34); v142p23 and v142p28 frames have the same md5s | run frames, row index |

No file read by any FIT has md5 521d6468 (field tag frames init); that md5 is named only in PREREG36 plan text.

## Pairing verdict

For 0.111 itself: **not found**. No file in the search set fits or derives 0.111; it first appears as a fixed harness setting
(10 July 2026 freeze recipe, v12.9.2 era ops) with no recorded data or pairing. The later refits that used 0.111 as a reference
(PREREG23, PREREG28) read the run frames (row index pairing).

## Not searched

The laptop (no shell; folder names not listed by this searcher). Cardinal, including bench_parity.R and the v12.x fitting work.
holoros/fvs-acd branch history (a .git directory exists in ~/repos-mirror/fvs-acd but was not read, per plan item 2). Files over
5 MB and other extensions (.rds, .RData, .rda). ~/jobs/laptop_archive_20260930 was searched (its name does not contain `_laptop`).

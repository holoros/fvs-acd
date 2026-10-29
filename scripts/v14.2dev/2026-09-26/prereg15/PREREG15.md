# PREREG15: FVS-ACD 14.1 as shipped on the pass 29b MNAP frames (written 2026-09-26 before any p15 run, smoke included)

Job: ~/jobs/v142p15 on firebreather. Bundle root home/ (HOME is set to it, as in v142htf). Nothing in ~/jobs/v142htf is
modified; everything used from it is a copy with md5 and diff in diffs/. Prepared on autopilot for Aaron Weiskittel.
No coordinates in any output. Nothing is sent to anyone.

## Arm
- v141LT only: 14.1 as shipped. Environment = the bench141 array v141LT branch (Cardinal
  bench141/scripts/2026-09-25_v142_bench141_array.sbatch, md5 571dd71d) as carried into v142htf/home/run_task.sh,
  with HTFIX_B UNSET (runner treats unset as identity; the runner line prints "PREREG11 HTFIX_B=unset") and no
  ING_MIN_FROM_SCORE. Nothing re-estimated. L (LSDG_V141=1) and T (THIN_V141=1) untouched. GT1 stays a named failure,
  not addressed here.
- Engines and coefficients md5 checked in run_task.sh exactly as the parent (chk lines unchanged).
- Runner: runner_htfix_fb.R (md5 4e6a2997), the PREREG11 firebreather runner. Versus the bench141 runner (md5 300a0d61)
  it differs only by the HTFIX block (identity when unset), the PREREG9 ING_MIN_FROM_SCORE line (off) and two path
  rebases (Cardinal diffs runner_ingthr/htfix and runner_htfix_vs_fb). [UNVERIFIED: identity of 300a0d61 and the
  unset htfix runner on MNAP is what Q0 tests.]
- OMP_NUM_THREADS=1 per task (parent fb setting; Cardinal used 8). R 4.5.1 on firebreather vs R 4.5.2 on Cardinal.

## Sets (set label = frame file stem)
| label | frame source | pairs | admitted (INDOMAIN=1: esi8 finite and > 2) | role |
|---|---|---|---|---|
| mnap_c | v142p29b PROVISIONAL_p29b frames, State plots, TAG_STABLE 1 | 348 | 348 | candidate MNAP benchmark |
| mnap_tnc_c | v142p29b PROVISIONAL_p29b frames, TNC plots, TAG_STABLE 0 | 136 | 131 (5 without esi8) | flagged, not tag stable |
| mnapfrz_c | frozen mnap_c (Cardinal gydbreg20260916/frames, md5 d598c60a pairs; identical copy at v142p29b/ref/pass28b) | 99 | 99 | identity check, all 99 are TNC plots |

- Setup mirrored from bench141 mnap_c (task 85): PAIRS/INIT/T2/SITE files = the set's frame files incl. its own
  site_esi file; INDOMAIN=1; per pair scoring threshold SCORE_MINDBH_OBS (no SCORE_MINDBH_FIXED); TST_FILE per set
  with TST_COL=TST built by the bench141 tstfile rule for MNAP (MANAGED 0 NEVER, MANAGED 1 UNKNOWN; all MNAP stands
  are MANAGED 0, so every stand is NEVER and T is the identity by data). Frozen set uses the Cardinal TST file
  verbatim (md5 d4f42394). The MNAP threshold 13.46 cm is the median SCORE_MINDBH_OBS of the frozen/TNC frames
  (State median 13.0); it is reported, not imposed [UNVERIFIED as the origin of the recorded 13.46].
- Chunking: mnapfrz_c one chunk 1..99 (as bench141 c001); mnap_c 4 chunks of at most 87; mnap_tnc_c 2 chunks
  [SET ON AUTOPILOT]. The runner holds no RNG (grep: no set.seed, runif, rnorm, sample), so chunks are invariant.
- 7 tasks, at most 8 in parallel, started only after v142htf logs/_status.txt contains ALL_DONE (300 s poll).

## Gates (all must pass; failing gate named in logs/_status_p15.txt)
- Q0 identity: mnapfrz_c results (c001) vs Cardinal bench141 results/v141LT/gyr_v141LT_mnap_c_results.csv (md5
  3b1d67f2): same column names and row count, character columns identical, NA pattern identical, worst scaled
  difference max(|a-b|/max(1,|b|)) <= 1e-9 over numeric columns (the PREREG11 H0 precedent, h0_compare.R, R 4.5.1
  vs 4.5.2) [UNVERIFIED that 1e-9 transfers from baxter_c to MNAP; it is taken as recorded].
- Q1 no run failures: every task exits 0, every chunk results file exists, assembled rows = admitted count per set,
  RUN_OK = 1 on every row, all predicted metrics finite.
- Q2 F5 magnitude: stands scored = admitted pairs in frame (348, 131, 99); observed BA_o in (0, 150] m2/ha, TPH_o in
  (0, 10000] trees/ha, QMD_o in [SCORE_MINDBH_USED, 100] cm, on every scored stand [bounds SET ON AUTOPILOT].
  Reported, not gating: BA_o <= frame BA_T2 and BA_t1 <= BA_T1 (scoring threshold >= frame threshold).
- S0 scoring identity [SET ON AUTOPILOT, hard stop]: the adapted scorer on mnapfrz_c, restricted to the bench141
  common population (98 stands; osm failure MNAP__Debsconeags_287_287__2004_2015_C dropped) and using the Phase C
  site index file siteidx_mnap_c.rds (md5 10ab8a55), reproduces the bench141 perset v141LT mnap_c row
  (in/cardinal/bench141_perset_v141LT_mnap_c_REF.csv) to the stored rounding (abs diff <= 0.0011 on rounded values).

## Reporting (not gating)
Per set, metrics BA, TPH, SDI, QMD, TOPHT, TOTVOL, MERCHVOL, SAWVOL, BIOMASS, VALUE (ht_score_core METRICS; TPH
recovered from BA and QMD, A4): n, mean obs, mean pred, observed over predicted ratio of means, %bias, %RMSE, OLS
intercept, slope (obs on pred), r2, with 95 percent percentile intervals from B = 2000 stand bootstrap draws. In MNAP
SITE is unique per stand (checked, hard stop otherwise), so the core's site cluster bootstrap is a stand bootstrap.
Draws: mnapfrz_c uses siteidx_mnap_c.rds; new sets draw with set.seed(20260916) per set, sample.int(n, n * B,
replace = TRUE) [SET ON AUTOPILOT]. Contrasts State minus TNC, State minus frozen, TNC minus frozen of ratio, %bias
and %RMSE, intervals from independent draws (unpaired, different stands) [SET ON AUTOPILOT].
Headline metrics: BA, TPH, QMD, TOTVOL.

## Adoption rule (stated in advance)
- If Q0, Q1, Q2 (and S0) pass: mnap_c (State, 348 pairs) is adopted as the MNAP benchmark set.
- mnap_tnc_c is kept as a flagged, not tag stable set (as NB), reported, never in a composite as MNAP.
- The frozen mnap_c scores (bench141 and every earlier record) are relabelled TNC in the record.
- If any gate fails: no adoption; status ends P15_FAIL <step>; nothing is relabelled until reviewed by Aaron.

## Outputs
logs/_status_p15.txt ending P15_DONE or P15_FAIL <step>; logs/p15_outputs_md5.txt; out/p15_tables_2026-09-26.tgz;
tables/*.csv. Lock: logs/p15.lock (flock) so the launcher cannot double start.

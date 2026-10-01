# PREREG37 implementation log (firebreather, 1 October 2026, ADT server time)

- 11:30 directory ~/jobs/v142p37 created (did not exist). 11:31:35 plan written, md5 c7f1244d, logs/prereg_md5.txt; no output file existed (a clarifying line was appended at 11:31:44 because the first line counted the three ls directory headers).
- 11:32 stands script (2026-10-01_v142_p37_stands.R): 153 fold A and 160 fold B screened RUN_OK qc_c stands (tables/gyr142-p37-stands-count).
- driver_p37.R built by build_driver_p37.sh: runner lines 1 to 419 byte for byte (diffs/driver_p37_vs_runner_1to419.diff shows only the 3 header lines and the block added).
- 11:33 smoke, 3 fold A stands (logs/smoke_*): term reconstruction relative error within 7e-15; dht.mult 1 on every record.
- 11:35 fold A capture, 153 stands, 0 failed. 11:36 assembly attempt 1 stopped before writing any file: data.table() reserves the argument name key; the column was renamed tagkey (logs/assemble_foldA_attempt1_key_argument_error.log). 11:37 fold A assembled.
- 11:38:21 logs/foldA_md5.txt written; only then fold B driver run (160 stands, 0 failed, 11:39:58) and fold B assembly.
- 11:38 to 11:40 seedling run at QC_AFAC 1, driver_p31_copy.R (byte identical to PREREG31, md5 467fb518), three cells, 50 years, all run_ok.
- 11:41 verdict script: rules table, seedling table, verdict file, figure and data file.
- run_p37.sh carries a no-op md5 check of run_task_p28.sh against its own md5 (harmless); that file's md5 is ad1fb918.
- Site curve helper: an increment of 0 is used where the curve is at its asymptote for a trial m (u >= 1); no stand is at or above A at frame ESI.
- Fold B has no tree with HT1/ESI at or above 1.25, so that bin is absent.

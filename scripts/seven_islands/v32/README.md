# Seven Islands (SILC) CFI benchmark, v32 scripts (September 23 to 26, 2026)

Analysis and document-build scripts behind the v32 SILC CFI growth, yield and value benchmark and its
September 26 revisions. No data are included: the SILC CFI inventory and the AGM deliveries are Seven
Islands Land Company and FORSight Resources material and stay off GitHub. Paths point at the Cardinal
(`silc_cfi/`) and firebreather (`jobs/silc_v32_docbuild/`) working folders where the runs were made.

- v32 height factorial (September 23): `bench_v32_htdub_treeout.R`, `run_htdub_factorial_v32.slurm`,
  `score_v32ht.slurm`, `build_unified_treelist_v32ht.R`, `value_silcspec_v32ht.R`,
  `silc_cfi_rates_v32ht_SCRIPT_2026-09-23.R`, `diag_htdub.R`, AGM v8.40 ingest and comparison scripts.
- v32 stress test (September 26): `stresstest_v32_SCRIPT_2026-09-26.R`, `loo_v32_SCRIPT_2026-09-26.R`,
  `st_heights*_SCRIPT_2026-09-26.R` (first measurement height audit, 18 feet-recorded heights).
- FVS-ACD 14.0.4 and 14.1 cells (September 26): `runner_v33_htswitch.R` (the 14.1 Phase D runner with
  DUB_HT and FTM_FIX starting height switches), `v33_v141_array.sbatch`, `score_v33.slurm`,
  `build_unified_treelist_v33.R`, `value_silcspec_v33.R`, `silc_cfi_rates_v33_SCRIPT_2026-09-26.R`,
  `stresstest_v33_SCRIPT_2026-09-26.R`, `pickcheck_v33_SCRIPT_2026-09-26.R`,
  `valuemerch_v33_SCRIPT_2026-09-26.R`, `check_L_SCRIPT_2026-09-26.R` (14.1 level term implementation
  check), `probe2_input_parity_SCRIPT_2026-09-26.R`.
- Document builds: `patch_v32*.py` (anchored, insertion-first source patches) and `build_v32st*_xlsx.R`.

Engines are not copied here; they are identified by md5 against the engines-14.1-20260924 manifest:
AcadianGY_14.0.4.r 61f95d99, AcadianGY_14.1.r 0bf27dde, option 3 coefficients c8f02f58.

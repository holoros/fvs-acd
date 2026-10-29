# assemble_p46.R: notes against assemble_p45.R

## Changes

The template's order, helpers (res, rd, chunk_res, build_hk, ht_tab, gate_arm, the p44 relations) and reproduction stops are kept. What changed:

- Job root v142p46, date 2026-10-11, prefix gyr142-p46, plan md5 eb4b753d.
- qc_lz and qc_ez are each gated and decided separately.
- Fit stops: fit file present with md5 equal to fit_md5.txt, Newton converged, b negative, boot_nonconverged at most 50.
- H0, K1, G1 and G2 run per arm. G0x and TR are read from logs.
- H relbin and H upper are added. H upper uses ht_tab's existing ratio_lo and ratio_hi (seed 20261001, PREREG37 weights), so ht_tab is unchanged.
- Reported, not gated: engine fold A ratio, and frozen qc_rh beside qc141 and p38_fit.
- Gate C has two parts, plus the reported quantities.
- The decision rule and tie rule run per arm.
- New outputs: fit-stops and harness tables, and a five arm figure.

## Ambiguities and choices

1. H0 is mapped per arm: qc_lz0 gates qc_lz and qc_ez0 gates qc_ez. G0, G0b and G0x are shared by both arms.
2. The tie metric is worst_abs_rel: HT/ESI bins with 30 or more trees, rounded to three decimals.
3. The raw ceiling is hardcoded at the registered 1.285 and checked against the frontier file's max column.
4. The crossing year uses the raw median, as ST2 did.
5. I added F9 stops beyond the template. The frozen qc_rh stand summaries, height rows and relations must equal the PREREG45 tables. The gate C offset must reproduce the ST2 table. Remove these if they are out of scope.
6. w_out refuses STAND, SITE or tree columns. traj-5yr also drops SITE.
7. The figs folder is created if missing, and figures are never overwritten.

## Needs server files

- Stands table name: I glob tables/gyr142-p46-fb-stands_DATA_*.csv and require exactly one match. To fix the name I need run_score_p45.sh or run_score_p46.sh.
- The g0_result.csv and g0b_result.csv columns. I assume a pass column and need g0_cmp_p31.R and g0b_p44.R to confirm.
- The trajectory arm column and the meaning of cell. I need the header of driver_p45.R or of out/traj_qc_rh_S1.csv.
- That v142p45st holds scripts/st2_offset.R and assembled/st2_gatec-offset_DATA_2026-10-05.csv.
- R was unavailable, so nothing has been executed. Dry run into scratch before recording the assembly md5.

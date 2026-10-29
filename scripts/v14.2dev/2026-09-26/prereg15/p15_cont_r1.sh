#!/bin/bash
cd ~/jobs/v142p15; export R_LIBS_USER=/home/aaron/R/x86_64-pc-linux-gnu-library/4.5; ST=logs/_status_p15_r1.txt
fail() { echo "P15R1_FAIL $1 $(date -Is)" >> $ST; exit 1; }
echo "START r1 $(date -Is) amend_md5 $(md5sum PREREG15_AMEND_r1.md | cut -c1-32)" > $ST
Rscript scripts/p15_patch_r1.R > logs/p15_r1_patch.log 2>&1 || fail patch
Rscript scripts/p15_gates_r1.R > logs/p15_r1_gates.log 2>&1; rc=$?; [ $rc -eq 11 ] && fail Q1; [ $rc -eq 12 ] && fail Q2; [ $rc -ne 0 ] && fail gates
echo "OK Q1 Q2 $(date -Is)" >> $ST
Rscript scripts/p15_q0_compare.R results_r1/v141LT/gyr_v141LT_mnapfrz_c_results.csv in/cardinal/gyr_v141LT_mnap_c_results.csv tables/p15-Q0-identity_r1_DATA_2026-09-26.csv > logs/p15_r1_q0.log 2>&1 || fail Q0
echo "OK Q0 $(grep -o 'worst scaled difference [^ ]*' logs/p15_r1_q0.log) $(date -Is)" >> $ST
mkdir -p tables_r1; P15_RES=$PWD/results_r1/v141LT P15_TAB=$PWD/tables_r1 Rscript scripts/p15_score.R > logs/p15_r1_score.log 2>&1; rc=$?; [ $rc -eq 2 ] && fail S0; [ $rc -ne 0 ] && fail score
echo "OK score $(date -Is)" >> $ST
grep -r -l -i -E '(^|,)(lat|lon|long|latitude|longitude|x_coord|y_coord|easting|northing|utm_x|utm_y)(,|$)' tables_r1 results_r1 > logs/p15_r1_coord_scan.txt && fail coordinate_scan
mkdir -p out && tar czf out/p15_tables_r1_2026-09-26.tgz PREREG15.md PREREG15_AMEND_r1.md tables_r1 tables/p15-Q0-identity_r1_DATA_2026-09-26.csv results_r1 logs/p15_*.log logs/retry diag scripts diffs || fail tgz
md5sum out/p15_tables_r1_2026-09-26.tgz >> $ST; echo P15R1_DONE >> $ST

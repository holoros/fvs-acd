#!/bin/bash
# PREREG15 launcher. Waits (300 s loop) until ~/jobs/v142htf/home/logs/_status.txt contains ALL_DONE, then runs the
# 7 tasks (at most 8 parallel, nice 5), assembles, gates Q1 Q2, Q0, scores (with S0), writes md5 list and tables tgz.
# Status: logs/_status_p15.txt ends P15_DONE or P15_FAIL <step>. flock on logs/p15.lock prevents a double start.
# Nothing is sent anywhere. No em dashes.
J=$HOME/jobs/v142p15; REALHOME=$HOME; ST=$J/logs/_status_p15.txt; HTF=$HOME/jobs/v142htf/home/logs/_status.txt
exec 9> $J/logs/p15.lock
flock -n 9 || { echo "p15 launcher already running (lock held), refusing to start $(date -Is)" >> $J/logs/p15_refused.txt; exit 1; }
[ ! -e "$ST" ] || { echo "REFUSE: $ST exists (already launched once)" >> $J/logs/p15_refused.txt; exit 1; }
export R_LIBS_USER=/home/aaron/R/x86_64-pc-linux-gnu-library/4.5 OMP_NUM_THREADS=1
fail() { echo "P15_FAIL $1 $(date -Is)" >> $ST; exit 1; }
echo "START $(date -Is) pid $$ prereg_md5 $(md5sum < $J/PREREG15.md | cut -d' ' -f1)" >> $ST
while ! grep -q ALL_DONE "$HTF" 2>/dev/null; do echo "WAIT v142htf not ALL_DONE $(date -Is)" > $J/logs/p15_wait.txt; sleep 300; done
echo "OK wait v142htf ALL_DONE seen $(date -Is)" >> $ST
cd $J && md5sum -c --quiet MANIFEST_md5.txt > logs/p15_manifest_check.txt 2>&1 || fail manifest
echo "OK manifest $(date -Is)" >> $ST
N=$(($(wc -l < home/work/p15_taskmap_DATA_2026-09-26.csv) - 1))
seq 1 $N | HOME=$J/home xargs -P 8 -I{} bash -c 'nice -n 5 bash '"$J"'/home/run_task.sh {} > '"$J"'/logs/task_{}.log 2>&1; echo "task {} exit $?" >> '"$ST"
echo "OK tasks $(date -Is)" >> $ST
grep -q -E 'task [0-9]+ exit [1-9]' $ST && fail tasks
mkdir -p results/v141LT
for s in mnapfrz_c mnap_c mnap_tnc_c; do
  o=results/v141LT/gyr_v141LT_${s}_results.csv; [ ! -e "$o" ] || fail "assemble_exists_$s"
  fs=$(ls home/out/v141LT/$s/c*_results.csv 2>/dev/null | sort); [ -n "$fs" ] || fail "assemble_$s"
  awk 'FNR==1 && NR!=1 {next} {print}' $fs > $o || fail "assemble_$s"
done
echo "OK assemble $(date -Is)" >> $ST
Rscript scripts/p15_gates.R > logs/p15_gates.log 2>&1; rc=$?
[ $rc -eq 11 ] && fail Q1; [ $rc -eq 12 ] && fail Q2; [ $rc -ne 0 ] && fail gates
echo "OK Q1 Q2 $(date -Is)" >> $ST
Rscript scripts/p15_q0_compare.R results/v141LT/gyr_v141LT_mnapfrz_c_results.csv in/cardinal/gyr_v141LT_mnap_c_results.csv tables/p15-Q0-identity_DATA_2026-09-26.csv > logs/p15_q0.log 2>&1 || fail Q0
echo "OK Q0 $(grep -o 'worst scaled difference [^ ]*' logs/p15_q0.log) $(date -Is)" >> $ST
Rscript scripts/p15_score.R > logs/p15_score.log 2>&1; rc=$?
[ $rc -eq 2 ] && fail S0; [ $rc -ne 0 ] && fail score
echo "OK score $(date -Is)" >> $ST
grep -r -l -i -E '(^|,)(lat|lon|long|latitude|longitude|x_coord|y_coord|easting|northing|utm_x|utm_y)(,|$)' tables results > logs/p15_coord_scan.txt && fail coordinate_scan
( md5sum PREREG15.md launch_after_htf.sh scripts/* home/run_task.sh home/work/* results/v141LT/* tables/*.csv ) > logs/p15_outputs_md5.txt
mkdir -p out && tar czf out/p15_tables_2026-09-26.tgz PREREG15.md tables results logs/p15_*.log logs/p15_outputs_md5.txt || fail tgz
md5sum out/p15_tables_2026-09-26.tgz >> logs/p15_outputs_md5.txt
echo "ADOPTION: Q0 Q1 Q2 S0 passed; per PREREG15 mnap_c (State) is adopted as the MNAP benchmark set, mnap_tnc_c kept flagged, frozen mnap_c relabelled TNC" >> $ST
echo "$(md5sum out/p15_tables_2026-09-26.tgz)" >> $ST
echo P15_DONE >> $ST

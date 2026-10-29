#!/bin/bash
# PREREG14 launcher: waits (300 s loop) until ~/jobs/v142htf/home/logs/_status.txt contains ALL_DONE (read only;
# nothing under ~/jobs/v142htf is written), then runs steps 1 and 2. Status: logs/_status_p14.txt, last line
# P14_DONE or P14_FAIL <step>. Diagnostic only; nothing is sent anywhere. No em dashes.
set -u
J=/home/aaron/jobs/v142p14; ST=$J/logs/_status_p14.txt; HTF=/home/aaron/jobs/v142htf/home/logs/_status.txt
exec 9>"$J/logs/.p14.lock"; flock -n 9 || { echo "p14 launcher already running (lock held)"; exit 1; }
fail() { echo "P14_FAIL $1" >> "$ST"; exit 3; }
echo "P14 WAITING pid $$ since $(date -Is) for ALL_DONE in $HTF" > "$ST"
while ! grep -q ALL_DONE "$HTF" 2>/dev/null; do echo "$(date -Is) waiting" >> "$J/logs/p14_wait.log"; sleep 300; done
echo "P14 START $(date -Is) (v142htf ALL_DONE seen)" >> "$ST"
export R_LIBS_USER=/home/aaron/R/x86_64-pc-linux-gnu-library/4.5 P14_ROOT=$J P14_OUT=$J/tables P14_NBOOT=2000 P14_SMOKE_N=0
export OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
cd "$J" || fail setup
md5sum -c --quiet manifest/in_md5_cardinal.txt >> logs/p14_md5check.log 2>&1 || fail C0_inputs
md5sum -c --quiet manifest/scripts_md5.txt >> logs/p14_md5check.log 2>&1 || fail C0_scripts
rm -f tables/*.csv tables/_hardstop.txt
for s in step1 step2; do
  Rscript scripts/p14_$s.R > logs/p14_$s.log 2>&1; rc=$?
  if [ $rc -ne 0 ]; then echo "rc=$rc $(grep -h 'HARD STOP' logs/p14_$s.log | head -1)" >> "$ST"; fail $s; fi
  grep -q "${s^^}_DONE" logs/p14_$s.log || fail $s
  echo "$s OK $(date -Is)" >> "$ST"
done
( cd tables && md5sum *.csv > ../manifest/tables_md5.txt ) || fail md5
TGZ=v142p14_results_$(date +%Y-%m-%d).tgz
tar czf "$TGZ" PREREG14_steps1-2.md launch_after_htf.sh scripts tables manifest logs/p14_step1.log logs/p14_step2.log || fail tgz
md5sum "$TGZ" > manifest/results_tgz_md5.txt || fail md5
echo "P14_DONE $(date -Is) $(cut -d' ' -f1 manifest/results_tgz_md5.txt) $TGZ" >> "$ST"

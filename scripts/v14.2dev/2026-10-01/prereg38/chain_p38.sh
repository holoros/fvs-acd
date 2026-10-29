#!/bin/bash
# PREREG38 chain (modelled on PREREG28b chain_p28b.sh): refuses unless the pre-registration md5 line exists and every launch
# md5 matches; runs the fold A fit and records its md5; launches tasks 1 to 24 (p38_fit 1 to 20, p38_one 21 to 24, at most
# 2 at once, strict load gate 12); waits for ALL_DONE; retries host time limit stands by name for both arms; scores with r2;
# checks the helper md5; assembles. Stops at the first failure; nothing is overwritten. No em dashes.
# Usage: cd ~/jobs/v142p38 && setsid nohup bash scripts/chain_p38.sh > logs/chain_nohup.log 2>&1 < /dev/null &
set -u
J=/home/aaron/jobs/v142p38; H=$J/home; LOG=$J/logs/chain.txt
echo "chain start $(date -Is) pid=$$" >> $LOG
grep -q "PREREG38 revision 1" $J/logs/prereg_md5.txt 2>/dev/null || { echo "REFUSE no pre-registration md5 line" >> $LOG; exit 4; }
md5sum -c --quiet $J/logs/launch_md5s.txt >> $LOG 2>&1 || { echo "STOP launch md5 mismatch" >> $LOG; exit 4; }
[ -e $H/logs/_status_main.txt ] && { echo "REFUSE main status exists" >> $LOG; exit 5; }
cd $J
Rscript scripts/fit_p38.R > $J/logs/fit.txt 2>&1; rc=$?; echo "fit exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
[ -e $J/logs/fit_md5.txt ] && { echo "REFUSE fit md5 exists" >> $LOG; exit 5; }
md5sum $J/fit/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv > $J/logs/fit_md5.txt; echo "fit md5 $(cat $J/logs/fit_md5.txt) value $(awk -F, 'NR==2{print $2}' $J/fit/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv)" >> $LOG
HOME=$H bash $J/scripts/launch_p38.sh $H/work/p38_ids.txt main >> $J/logs/launch_main.log 2>&1
until grep -q ALL_DONE $H/logs/_status_main.txt 2>/dev/null; do sleep 60; done
echo "main done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_main.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_main.txt) nonzero" >> $LOG
grep -q 'exit [1-9]' $H/logs/_status_main.txt && { echo "STOP a task exited nonzero" >> $LOG; exit 6; }
for A in p38_fit p38_one; do HOME=$H bash $H/retry_timeouts_p38.sh $A; echo "retry $A done $(date -Is): $(tail -1 $H/logs/retry_$A.log 2>/dev/null)" >> $LOG; done
bash scripts/run_score_p38.sh > $J/logs/score.txt 2>&1; rc=$?; echo "score exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
echo "59196106afe20e57ca1bc7b4894495f1  $J/scripts/2026-09-29_v142_p23_hkey.R" | md5sum -c --quiet - || { echo "STOP height key helper md5" >> $LOG; exit 7; }
Rscript scripts/assemble_p38.R > $J/logs/assemble.txt 2>&1; rc=$?; echo "assemble exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
echo "CHAIN_DONE $(date -Is)" >> $LOG

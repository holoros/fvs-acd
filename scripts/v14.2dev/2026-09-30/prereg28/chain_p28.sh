#!/bin/bash
# PREREG28 chain (pattern of PREREG23 chain_p23.sh): refuses unless the pre-registration md5 line exists; launches tasks 1 to 40
# (p28_g0 and p28_cand, at most 2 at once, load gate 12), waits for ALL_DONE, retries host time limit stands by name for both
# arms (up to three attempts), scores (run_score_p28.sh), checks the height key helper md5, then assembles
# (2026-09-30_v142_p28_assemble.R, which refuses to overwrite assembled/). Stops at the first failure; nothing is overwritten.
# Usage: cd ~/jobs/v142p28 && setsid nohup bash scripts/chain_p28.sh > logs/chain_nohup.log 2>&1 < /dev/null &
set -u
J=/home/aaron/jobs/v142p28; H=$J/home; LOG=$J/logs/chain.txt
echo "chain start $(date -Is) pid=$$" >> $LOG
grep -q "PREREG28 revision" $J/logs/prereg_md5.txt 2>/dev/null || { echo "REFUSE no pre-registration md5 line" >> $LOG; exit 4; }
[ -e $H/logs/_status_grid.txt ] && { echo "REFUSE grid status exists" >> $LOG; exit 5; }
HOME=$H bash $J/scripts/launch_p28.sh $H/work/p28_grid_ids.txt grid >> $J/logs/launch_grid.log 2>&1
until grep -q ALL_DONE $H/logs/_status_grid.txt 2>/dev/null; do sleep 60; done
echo "main done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_grid.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_grid.txt) nonzero" >> $LOG
grep -q 'exit [1-9]' $H/logs/_status_grid.txt && { echo "STOP a grid task exited nonzero" >> $LOG; exit 6; }
for A in p28_g0 p28_cand; do
  HOME=$H bash $H/retry_timeouts_p28.sh $A; echo "retry $A done $(date -Is): $(tail -1 $H/logs/retry_$A.log 2>/dev/null)" >> $LOG; done
cd $J
bash scripts/run_score_p28.sh > $J/logs/score.txt 2>&1; rc=$?; echo "score exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
echo "59196106afe20e57ca1bc7b4894495f1  $J/scripts/2026-09-29_v142_p23_hkey.R" | md5sum -c --quiet - || { echo "STOP height key helper md5" >> $LOG; exit 7; }
echo "height key helper md5 ok $(date -Is)" >> $LOG
Rscript scripts/2026-09-30_v142_p28_assemble.R > $J/logs/assemble.txt 2>&1; rc=$?; echo "assemble exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
echo "CHAIN_DONE $(date -Is)" >> $LOG

#!/bin/bash
# PREREG23 chain (pattern of PREREG19 chain_p19.sh): launches the grid (tasks 1 to 60, at most 2 at once, load gate 14),
# waits for ALL_DONE, retries host time limit stands by name for every arm (up to three attempts), scores
# (run_score_p23.sh), then assembles (2026-09-29_v142_p23_assemble.R, which refuses to overwrite assembled/). Stops at the
# first failure; nothing is overwritten. Usage: cd ~/jobs/v142p23 && setsid nohup bash scripts/chain_p23.sh > chain_nohup.log 2>&1 &
set -u
J=/home/aaron/jobs/v142p23; H=$J/home; LOG=$J/logs/chain.txt
echo "chain start $(date -Is) pid=$$" >> $LOG
[ -e $H/logs/_status_grid.txt ] && { echo "REFUSE grid status exists" >> $LOG; exit 5; }
HOME=$H bash $J/scripts/launch_p23.sh $H/work/p23_grid_ids.txt grid >> $J/logs/launch_grid.log 2>&1
until grep -q ALL_DONE $H/logs/_status_grid.txt 2>/dev/null; do sleep 120; done
echo "main done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_grid.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_grid.txt) nonzero" >> $LOG
grep -q 'exit [1-9]' $H/logs/_status_grid.txt && { echo "STOP a grid task exited nonzero" >> $LOG; exit 6; }
for A in p23_a0111 p23_a1061 p23_a1250; do
  HOME=$H bash $H/retry_timeouts_p23.sh $A; echo "retry $A done $(date -Is): $(tail -1 $H/logs/retry_$A.log 2>/dev/null)" >> $LOG; done
cd $J
bash scripts/run_score_p23.sh > $J/logs/score.txt 2>&1; rc=$?; echo "score exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
Rscript scripts/2026-09-29_v142_p23_assemble.R > $J/logs/assemble.txt 2>&1; rc=$?; echo "assemble exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
echo "CHAIN_DONE $(date -Is)" >> $LOG

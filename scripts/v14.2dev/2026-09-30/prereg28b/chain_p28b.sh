#!/bin/bash
# PREREG28b chain (copy of PREREG28 chain_p28.sh with the arm list, job root and the PREREG28 wait added): refuses unless the
# pre-registration md5 line exists; launches tasks 1 to 20 (p28b_small, at most 2 at once, load gate 12), waits for ALL_DONE,
# retries host time limit stands by name (up to three attempts), scores p28b_small, then waits for PREREG28 scoring
# ("score exit 0" in ~/jobs/v142p28/logs/chain.txt; H0 and the p28_cand comparator are read from there), checks the height
# key helper md5 and assembles. Stops at the first failure; nothing is overwritten. No em dashes.
# Usage: cd ~/jobs/v142p28b && setsid nohup bash scripts/chain_p28b.sh > logs/chain_nohup.log 2>&1 < /dev/null &
set -u
J=/home/aaron/jobs/v142p28b; H=$J/home; LOG=$J/logs/chain.txt; P28LOG=/home/aaron/jobs/v142p28/logs/chain.txt
echo "chain start $(date -Is) pid=$$" >> $LOG
grep -q "PREREG28b revision" $J/logs/prereg_md5.txt 2>/dev/null || { echo "REFUSE no pre-registration md5 line" >> $LOG; exit 4; }
[ -e $H/logs/_status_grid.txt ] && { echo "REFUSE grid status exists" >> $LOG; exit 5; }
HOME=$H bash $J/scripts/launch_p28b.sh $H/work/p28b_grid_ids.txt grid >> $J/logs/launch_grid.log 2>&1
until grep -q ALL_DONE $H/logs/_status_grid.txt 2>/dev/null; do sleep 60; done
echo "main done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_grid.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_grid.txt) nonzero" >> $LOG
grep -q 'exit [1-9]' $H/logs/_status_grid.txt && { echo "STOP a grid task exited nonzero" >> $LOG; exit 6; }
HOME=$H bash $H/retry_timeouts_p28b.sh p28b_small; echo "retry p28b_small done $(date -Is): $(tail -1 $H/logs/retry_p28b_small.log 2>/dev/null)" >> $LOG
cd $J
bash scripts/run_score_p28b.sh > $J/logs/score.txt 2>&1; rc=$?; echo "score exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
until grep -q "score exit 0" $P28LOG 2>/dev/null; do grep -qE "^STOP|^REFUSE|score exit [1-9]" $P28LOG && { echo "STOP PREREG28 chain stopped before scoring; no verdict" >> $LOG; exit 9; }; sleep 60; done
echo "PREREG28 scoring seen $(date -Is)" >> $LOG
echo "59196106afe20e57ca1bc7b4894495f1  $J/scripts/2026-09-29_v142_p23_hkey.R" | md5sum -c --quiet - || { echo "STOP height key helper md5" >> $LOG; exit 7; }
Rscript scripts/2026-09-30_v142_p28b_assemble.R > $J/logs/assemble.txt 2>&1; rc=$?; echo "assemble exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
echo "CHAIN_DONE $(date -Is)" >> $LOG

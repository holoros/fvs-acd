#!/bin/bash
# PREREG19 chain: waits for the grid launcher's ALL_DONE, retries host time limit stands by name for every arm (load gated),
# then scores (run_score_p19.sh) and assembles (2026-09-28_v142_p19_assemble.R). Stops at the first failure; nothing is
# overwritten. Usage: setsid nohup bash scripts/chain_p19.sh > chain_nohup.log 2>&1 &. No coordinates. No em dashes.
J=/home/aaron/jobs/v142p19; H=$J/home; LOG=$J/logs_chain.txt
echo "chain start $(date -Is) pid=$$" >> $LOG
until grep -q ALL_DONE $H/logs/_status_grid.txt 2>/dev/null; do sleep 300; done
echo "main done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_grid.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_grid.txt) nonzero" >> $LOG
for A in p19_a0111 p19_a1000 p19_a0030 p19_a0500 p19_a0060 p19_a0250 nbctl_a1000; do
  HOME=$H bash $H/retry_timeouts_p19.sh $A; echo "retry $A done $(date -Is): $(tail -1 $H/logs/retry_$A.log 2>/dev/null)" >> $LOG; done
cd $J
bash scripts/run_score_p19.sh > $J/logs_score.txt 2>&1; rc=$?; echo "score exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
Rscript scripts/2026-09-28_v142_p19_assemble.R > $J/logs_assemble.txt 2>&1; rc=$?; echo "assemble exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
echo "CHAIN_DONE $(date -Is)" >> $LOG

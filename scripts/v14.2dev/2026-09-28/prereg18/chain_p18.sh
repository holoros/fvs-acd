#!/bin/bash
# PREREG18 chain: waits for the launcher's ALL_DONE, then for each arm retries host time limit stands by name (the
# revision 2 rule, up to three attempts, one stand at a time, each arm's pass held while the 1 minute load is above 14),
# then scores (run_score_p18.sh), computes fold volume (2026-09-28_v142_p18_foldvol.R) and assembles
# (2026-09-28_v142_p18_assemble.R). Each step logs to its own file; the chain stops at the first failure; nothing is
# overwritten. Usage: setsid nohup bash chain_p18.sh > ../logs_chain_nohup.txt 2>&1 &. No coordinates. No em dashes.
J=/home/aaron/jobs/v142p18; H=$J/home; LOG=$J/logs_chain.txt
waitload() { while awk -v l=$(cut -d' ' -f1 /proc/loadavg) 'BEGIN{exit !(l > 14)}'; do sleep 120; done; }
echo "chain start $(date -Is) pid=$$" >> $LOG
until grep -q ALL_DONE $H/logs/_status.txt 2>/dev/null; do sleep 300; done
echo "main done $(date -Is): $(grep -c 'exit 0' $H/logs/_status.txt) tasks exit 0, $(grep -c 'exit [1-9]' $H/logs/_status.txt) nonzero" >> $LOG
for A in v141LTig_m175 v141LTig_m225; do waitload
  HOME=$H bash $H/retry_timeouts_p18.sh $A; echo "retry $A done $(date -Is): $(tail -1 $H/logs/retry_$A.log 2>/dev/null)" >> $LOG; done
cd $J
bash scripts/run_score_p18.sh > $J/logs_score.txt 2>&1; rc=$?; echo "score exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
Rscript scripts/2026-09-28_v142_p18_foldvol.R > $J/logs_foldvol.txt 2>&1; rc=$?; echo "foldvol exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
Rscript scripts/2026-09-28_v142_p18_assemble.R > $J/logs_assemble.txt 2>&1; rc=$?; echo "assemble exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || exit $rc
echo "CHAIN_DONE $(date -Is)" >> $LOG

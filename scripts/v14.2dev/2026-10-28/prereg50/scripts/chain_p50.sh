#!/bin/bash
# PREREG50 chain (plan revision 1, md5 6ea850d4). Refuses unless the registration line and every launch md5 match. Runs the
# 57 runner tasks (g2, e1, s2; 19 qc_c chunks each; at most 2 at once, none started at load 12 or above), the PREREG19 retry
# rule, then G2 (p50_g2.R), the split with G1, G3 to G6 (p50_split.R) and the bootstrap, G0 and decision rule (p50_boot.R).
# Assembly is a separate step. Stops at the first failure; nothing is overwritten. Usage: setsid nohup bash chain_p50.sh
# > logs/chain_nohup.txt 2>&1 &. Chain log lines carry counts only. No em dashes.
J=/home/aaron/jobs/v142p50; H=$J/home; S=$J/scripts; LOG=$J/logs/chain.txt; OUT=$J/out
waitload() { for i in $(seq 1 60); do l=$(cut -d' ' -f1 /proc/loadavg); if awk -v l=$l 'BEGIN{exit !(l<12)}'; then return 0; fi; echo "load $l, waiting" >> $LOG; sleep 30; done; echo "LOAD GATE TIMEOUT" >> $LOG; exit 4; }
step() { local n=$1; shift; waitload; echo "$n start $(date -Iseconds) load $(cut -d' ' -f1 /proc/loadavg)" >> $LOG; "$@"; local rc=$?; echo "$n exit $rc $(date -Iseconds)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Iseconds)" >> $LOG; exit $rc; }; }
echo "chain start $(date -Iseconds) pid=$$" >> $LOG
grep -q "PREREG50 revision 1 registered" $J/logs/prereg_md5.txt || { echo "REFUSE no registration line" >> $LOG; exit 4; }
md5sum -c --quiet $J/logs/launch_md5s.txt >> $LOG 2>&1 || { echo "STOP launch md5 mismatch" >> $LOG; exit 4; }
[ -e $H/logs/_status_main.txt ] && { echo "REFUSE main status exists" >> $LOG; exit 5; }
[ -e $OUT ] && { echo "REFUSE out exists" >> $LOG; exit 5; }
HOME=$H bash $S/launch_p50.sh $H/work/p50_ids.txt main >> $J/logs/launch_main.txt 2>&1
until grep -q ALL_DONE $H/logs/_status_main.txt 2>/dev/null; do sleep 60; done
echo "runner tasks done $(date -Iseconds): $(grep -c 'exit 0' $H/logs/_status_main.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_main.txt) nonzero" >> $LOG
grep -q 'exit [1-9]' $H/logs/_status_main.txt && { echo "CHAIN_STOP a runner task exited nonzero" >> $LOG; exit 6; }
bash $S/retry_p50.sh >> $LOG 2>&1
mkdir -p $OUT
step g2 bash -c "Rscript $S/p50_g2.R $OUT full > $J/logs/g2.txt 2>&1"
step split bash -c "Rscript $S/p50_split.R $OUT full > $J/logs/split.txt 2>&1"
step boot bash -c "Rscript $S/p50_boot.R $OUT full > $J/logs/boot.txt 2>&1"
echo "CHAIN_DONE ready for assembly $(date -Iseconds)" >> $LOG

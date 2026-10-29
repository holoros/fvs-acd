#!/bin/bash
# PREREG50 dry run (plan revision 1, md5 6ea850d4): 20 screened fold A stands; g2 and e1 by stand file (2 R processes at
# once), then s2; then G2, the split and the bootstrap restricted to those stands, written under dryrun/ (fold A only, no
# fold B output). Load gated at 12. Output checks the scripts and is not interpreted. No em dashes.
J=/home/aaron/jobs/v142p50; H=$J/home; S=$J/scripts; LOG=$J/logs/dryrun_chain.txt
waitload() { for i in $(seq 1 60); do l=$(cut -d' ' -f1 /proc/loadavg); if awk -v l=$l 'BEGIN{exit !(l<12)}'; then return 0; fi; echo "load $l, waiting" >> $LOG; sleep 30; done; echo "LOAD GATE TIMEOUT" >> $LOG; exit 4; }
echo "dry start $(date -Iseconds)" >> $LOG
[ -e $H/work/dry_keep_SERVERONLY.csv ] || { waitload; Rscript $S/p50_drypick.R $J/dryrun dry >> $LOG 2>&1 || { echo "DRYPICK FAILED" >> $LOG; exit 2; }; }
KF=$H/work/dry_keep_SERVERONLY.csv
waitload; ( HOME=$H OUTROOT=dry_out bash $S/run_task_p50.sh keep g2 $KF c000 > $H/logs/dry_g2_SERVERONLY.log 2>&1; echo "dry g2 exit $?" >> $LOG ) &
sleep 5; waitload; ( HOME=$H OUTROOT=dry_out bash $S/run_task_p50.sh keep e1 $KF c000 > $H/logs/dry_e1_SERVERONLY.log 2>&1; echo "dry e1 exit $?" >> $LOG ) &
wait
waitload; HOME=$H OUTROOT=dry_out bash $S/run_task_p50.sh keep s2 $KF c000 > $H/logs/dry_s2_SERVERONLY.log 2>&1; echo "dry s2 exit $?" >> $LOG
grep -c 'exit 0' $LOG >> $LOG
waitload; Rscript $S/p50_g2.R $J/dryrun dry >> $LOG 2>&1 || { echo "DRY G2 FAILED" >> $LOG; exit 2; }
waitload; Rscript $S/p50_split.R $J/dryrun dry >> $LOG 2>&1 || { echo "DRY SPLIT FAILED" >> $LOG; exit 2; }
waitload; Rscript $S/p50_boot.R $J/dryrun dry >> $LOG 2>&1 || { echo "DRY BOOT FAILED" >> $LOG; exit 2; }
echo "DRY_DONE $(date -Iseconds)" >> $LOG

#!/bin/bash
# PREREG26 chain (plan revision 2, md5 291bb1ec). Gated arms v141LT and v141LTfi (one task per arm and mix, 12 cells each),
# at most 2 R model processes, none started while the 1 minute load is above 12; then the G0 record (from the dry G0 output,
# no model rerun), the primary assembly and verdict; v141LTf and v141LTi only if the verdict is rule 2; then v141LTfi5; then
# the follow up assembly; CHAIN_DONE. Each step logs to logs/chain.txt; the chain stops at the first failure; nothing is
# overwritten. No coordinates. No em dashes.
J=/home/aaron/jobs/v142p26; LOG=$J/logs/chain.txt; S=$J/scripts
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 > 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
runarms() { # arms as arguments; tasks arm:mix, 2 at a time
  for a in "$@"; do for m in BF RS MX; do echo "$a $m"; done; done | xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> '$J'/logs/tasks.txt; bash '$S'/run_p26.sh $0 grid '$J'/out/traj_$0_$1.csv '$J'/plan/cells_$1.csv > '$J'/logs/task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/tasks.txt; exit $rc'
}
cd $J; echo "chain start $(date -Is) pid=$$" >> $LOG
step gated runarms v141LT v141LTfi
step g0record Rscript $S/g0_cmp_p26.R $J/dry/g0_v141LT.csv $J/logs/g0_result.csv
step assemble_primary bash -c "Rscript $S/assemble_p26.R primary > $J/logs/assemble_primary.log 2>&1"
OUT=$(grep '^outcome=' $J/assembled/gyr142-p26-verdict_DATA_2026-09-30.txt | cut -d= -f2); echo "primary outcome $OUT" >> $LOG
if [ "$OUT" = RULE2_NOT_CLEARED ]; then step components runarms v141LTf v141LTi; fi
step sens_fi5 runarms v141LTfi5
step assemble_followup bash -c "Rscript $S/assemble_p26.R followup $J/assembled/followup > $J/logs/assemble_followup.log 2>&1"
echo "CHAIN_DONE $(date -Is)" >> $LOG

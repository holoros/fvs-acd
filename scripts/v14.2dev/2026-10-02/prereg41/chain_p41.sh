#!/bin/bash
# PREREG41 chain (plan revision 1, md5 a1aa4b35). Tasks: the G2 identity cell (qc141, MX_E19.8_N6000, through run_p41.sh)
# and the candidate p38_fit (one task per mix, 12 cells each), at most 2 R model processes at once, none started while the
# 1 minute load average is 12 or above; then Part A assembly and verdict, Part B assembly; CHAIN_DONE. The frozen PREREG31
# qc141 trajectories are read through in/ links, never rerun. Stops at the first failure; nothing is overwritten. No em dashes.
J=/home/aaron/jobs/v142p41; LOG=$J/logs/chain.txt; S=$J/scripts; P31=/home/aaron/jobs/v142p31
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
runtasks() {
  printf '%s\n' "$@" | xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> '$J'/logs/tasks.txt; bash '$S'/run_p41.sh $0 grid $2 $3 > '$J'/logs/task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/tasks.txt; exit $rc'
}
cd $J; echo "chain start $(date -Is) pid=$$" >> $LOG
T=("qc141 dry $J/dry/dry_qc141_MX_E19.8_N6000.csv $P31/plan/cells_dry.csv")
for m in BF SM MX; do T+=("p38_fit $m $J/out/traj_p38_fit_${m}.csv $P31/plan/cells_${m}.csv"); done
step grid runtasks "${T[@]}"
step assembleA bash -c "P31_PLAN_MD5=a1aa4b3532f0b3ac9ec30e63a3f7fcec Rscript $S/assemble_p41.R > $J/logs/assemble.log 2>&1"
echo "outcome $(grep '^outcome=' $J/assembled/gyr142-p41-verdict_DATA_2026-10-02.txt | cut -d= -f2)" >> $LOG
step assembleB bash -c "Rscript $S/assemble_p41b.R > $J/logs/assemble_b.log 2>&1"
echo "CHAIN_DONE $(date -Is)" >> $LOG

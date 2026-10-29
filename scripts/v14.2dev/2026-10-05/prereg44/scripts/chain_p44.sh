#!/bin/bash
# PREREG44 chain (plan revision 1). G0 (driver_p44 mode g0, qc141, the PREREG31 G0 stands, against frozen p19_a0111 at 1e-9),
# G0b (driver_p44 mode grid reproduces the frozen PREREG31 dry trajectory exactly), then the stand list grid: arms qc141 and
# p38_fit, one task per arm and SDI bin, at most 2 R model processes at once, none started while the 1 minute load average
# is 12 or above; then the assembly and verdict; CHAIN_DONE. Stops at the first failure; nothing is overwritten. No em dashes.
J=/home/aaron/jobs/v142p44; LOG=$J/logs/chain.txt; S=$J/scripts; P31=/home/aaron/jobs/v142p31
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
runtasks() {
  printf '%s\n' "$@" | xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> '$J'/logs/tasks.txt; bash '$S'/run_p44.sh $0 slgrid $2 $3 > '$J'/logs/task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/tasks.txt; exit $rc'
}
cd $J; mkdir -p g0 out; echo "chain start $(date -Is) pid=$$" >> $LOG
step g0run bash -c "P31_G0_STANDS=$(cat $P31/logs/g0_stands.txt) bash $S/run_p44.sh qc141 g0 $J/g0/g0_qc141.csv > $J/logs/task_g0.log 2>&1"
step g0cmp bash -c "Rscript $P31/scripts/g0_cmp_p31.R $J/g0/g0_qc141.csv $J/logs/g0_result.csv > $J/logs/g0_cmp.log 2>&1"
step g0brun bash -c "bash $S/run_p44.sh qc141 grid $J/g0/g0b_qc141_MX_E19.8_N6000.csv $P31/plan/cells_dry.csv > $J/logs/task_g0b.log 2>&1"
step g0bcmp bash -c "Rscript $S/g0b_p44.R $J/g0/g0b_qc141_MX_E19.8_N6000.csv $J/logs/g0b_result.csv > $J/logs/g0b_cmp.log 2>&1"
T=(); for a in qc141 p38_fit; do for b in 1 2 3; do T+=("$a S$b $J/out/traj_${a}_S${b}.csv $J/plan/stands_S${b}_SERVERONLY.csv"); done; done
step grid runtasks "${T[@]}"
step assemble bash -c "P44_PLAN_MD5=$(cut -d' ' -f1 $J/logs/prereg_md5.txt | head -1) Rscript $S/assemble_p44.R > $J/logs/assemble.log 2>&1"
echo "outcome $(grep '^outcome=' $J/assembled/gyr142-p44-verdict_DATA_2026-10-05.txt | cut -d= -f2)" >> $LOG
echo "CHAIN_DONE $(date -Is)" >> $LOG

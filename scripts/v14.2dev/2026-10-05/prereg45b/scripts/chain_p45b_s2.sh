#!/bin/bash
# PREREG45b chain, stage 2: nb_rh benchmark (tasks 40 to 57), retries, then the NB stand list long run for nb141 and nb_rh
# (six tasks, at most 2 R processes, none at load 12 or above). Refuses unless stage 1 finished and the fit md5 matches. No em dashes.
J=/home/aaron/jobs/v142p45b; H=$J/home; LOG=$J/logs/chain.txt; S=$J/scripts
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }; export -f gate
grep -q CHAIN_S1_DONE $LOG || { echo "REFUSE s2 before s1" >> $LOG; exit 4; }
md5sum -c --quiet $J/logs/fit_md5.txt || { echo "STOP fit md5" >> $LOG; exit 4; }
echo "chain s2 start $(date -Is) pid=$$" >> $LOG; cd $J
HOME=$H bash $S/launch_p45b.sh $H/work/p45b_ids_stage2.txt s2 >> $J/logs/launch_s2.log 2>&1
until grep -q ALL_DONE $H/logs/_status_s2.txt 2>/dev/null; do sleep 60; done
grep -q 'exit [1-9]' $H/logs/_status_s2.txt && { echo "CHAIN_STOP a bench task exited nonzero" >> $LOG; exit 6; }
HOME=$H bash $H/retry_timeouts_p45b.sh nb_rh; echo "bench s2 done, retry nb_rh $(date -Is): $(tail -1 $H/logs/retry_nb_rh.log 2>/dev/null)" >> $LOG
T=(); for a in nb141 nb_rh; do for b in 1 2 3; do T+=("$a S$b $J/out/traj_${a}_S${b}.csv $J/plan/stands_S${b}_SERVERONLY.csv"); done; done
runtasks() { printf '%s\n' "$@" | xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is)" >> '$J'/logs/tasks.txt; bash '$S'/run_p45b.sh $0 slgrid $2 $3 > '$J'/logs/task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/tasks.txt; exit $rc'; }
step grid runtasks "${T[@]}"
echo "CHAIN_DONE ready for assembly $(date -Is)" >> $LOG

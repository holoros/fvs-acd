#!/bin/bash
# Post hoc stress tests for PREREG45 (not registered): ST1 branch trace (2 stands, 3 years) and ST3 b quantile long runs
# (36 PREREG44 stands, 100 years, two arms). Waits until the PREREG45b chain (both stages) has finished. No em dashes.
J=/home/aaron/jobs/v142p45st; LOG=$J/logs/chain.txt; P44=/home/aaron/jobs/v142p44
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }; export -f gate
echo "st start $(date -Is)" >> $LOG
until grep -q "CHAIN_DONE ready\|CHAIN_STOP" /home/aaron/jobs/v142p45b/logs/chain.txt; do sleep 60; done
echo "p45b chain finished, st proceeds $(date -Is)" >> $LOG
ST1_TRACE=$J/out/st1_trace_SERVERONLY.csv P31_NYR=3 bash $J/scripts/run_st1.sh qc_rh slgrid $J/out/st1_traj_SERVERONLY.csv $J/out/st1_stands_SERVERONLY.csv > $J/logs/st1.log 2>&1; echo "st1 run exit $? $(date -Is)" >> $LOG
Rscript $J/scripts/st1_check.R > $J/logs/st1_check.log 2>&1; echo "st1 check $(tail -1 $J/logs/st1_check.log) $(date -Is)" >> $LOG
T=(); for a in qc_rh_blo qc_rh_bhi; do for b in 1 2 3; do T+=("$a S$b $J/out/traj_${a}_S${b}.csv $P44/plan/stands_S${b}_SERVERONLY.csv"); done; done
printf '%s\n' "${T[@]}" | xargs -P 1 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is)" >> '$J'/logs/tasks.txt; bash '$J'/scripts/run_st3.sh $0 slgrid $2 $3 > '$J'/logs/task_$0_$1.log 2>&1; echo "task $0 $1 exit $? $(date -Is)" >> '$J'/logs/tasks.txt'
echo "ST_DONE $(date -Is)" >> $LOG

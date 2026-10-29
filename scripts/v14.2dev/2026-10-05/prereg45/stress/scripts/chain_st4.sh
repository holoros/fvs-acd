#!/bin/bash
# ST4 (post hoc stress test): qc_rh with ingrowth kept at m = 1, 36 PREREG44 stands, 100 years; runs after ST_DONE, one R process. No em dashes.
J=/home/aaron/jobs/v142p45st; LOG=$J/logs/chain.txt; P44=/home/aaron/jobs/v142p44
until grep -q ST_DONE $LOG; do sleep 60; done
for b in 1 2 3; do echo "task st4 S$b start $(date -Is)" >> $J/logs/tasks.txt; bash $J/scripts/run_st4.sh qc_rh_ing1 slgrid $J/out/traj_qc_rh_ing1_S$b.csv $P44/plan/stands_S${b}_SERVERONLY.csv > $J/logs/task_st4_S$b.log 2>&1; echo "task st4 S$b exit $? $(date -Is)" >> $J/logs/tasks.txt; done
echo "ST4_DONE $(date -Is)" >> $LOG

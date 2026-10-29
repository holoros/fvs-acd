#!/bin/bash
# PREREG45 chain (revision 1). Refuses unless the registration line and every launch md5 match. G0 (driver_p45 mode g0,
# qc141 with RH unset, against frozen p19_a0111 at 1e-9), G0b (driver_p45 mode grid reproduces the frozen PREREG31 dry
# trajectory exactly), the benchmark (tasks 1 to 24: qc_rh 1 to 20, qc_rh0 21 to 24; at most 2 at once, none at load 12 or
# above), the PREREG38 retry rule for both arms, scoring r2, then the PREREG44 stand list long run for qc_rh (three tasks,
# at most 2 R processes). Assembly is a separate step. Stops at the first failure; nothing is overwritten. No em dashes.
J=/home/aaron/jobs/v142p45; H=$J/home; LOG=$J/logs/chain.txt; S=$J/scripts; P31=/home/aaron/jobs/v142p31; P44=/home/aaron/jobs/v142p44
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
echo "chain start $(date -Is) pid=$$" >> $LOG
grep -q "PREREG45 revision 1 registered" $J/logs/prereg_md5.txt || { echo "REFUSE no registration line" >> $LOG; exit 4; }
md5sum -c --quiet $J/logs/launch_md5s.txt >> $LOG 2>&1 || { echo "STOP launch md5 mismatch" >> $LOG; exit 4; }
[ -e $H/logs/_status_main.txt ] && { echo "REFUSE main status exists" >> $LOG; exit 5; }
cd $J; mkdir -p g0 out
step g0run bash -c "P31_G0_STANDS=$(cat $P31/logs/g0_stands.txt) bash $S/run_p45.sh qc141 g0 $J/g0/g0_qc141.csv > $J/logs/task_g0.log 2>&1"
step g0cmp bash -c "Rscript $P31/scripts/g0_cmp_p31.R $J/g0/g0_qc141.csv $J/logs/g0_result.csv > $J/logs/g0_cmp.log 2>&1"
step g0brun bash -c "bash $S/run_p45.sh qc141 grid $J/g0/g0b_qc141_MX_E19.8_N6000.csv $P31/plan/cells_dry.csv > $J/logs/task_g0b.log 2>&1"
step g0bcmp bash -c "Rscript $P44/scripts/g0b_p44.R $J/g0/g0b_qc141_MX_E19.8_N6000.csv $J/logs/g0b_result.csv > $J/logs/g0b_cmp.log 2>&1"
HOME=$H bash $S/launch_p45.sh $H/work/p45_ids.txt main >> $J/logs/launch_main.log 2>&1
until grep -q ALL_DONE $H/logs/_status_main.txt 2>/dev/null; do sleep 60; done
echo "bench done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_main.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_main.txt) nonzero" >> $LOG
grep -q 'exit [1-9]' $H/logs/_status_main.txt && { echo "CHAIN_STOP a bench task exited nonzero" >> $LOG; exit 6; }
for A in qc_rh qc_rh0; do HOME=$H bash $H/retry_timeouts_p45.sh $A; echo "retry $A done $(date -Is): $(tail -1 $H/logs/retry_$A.log 2>/dev/null)" >> $LOG; done
step score bash -c "bash $S/run_score_p45.sh > $J/logs/score.txt 2>&1"
T=(); for b in 1 2 3; do T+=("qc_rh S$b $J/out/traj_qc_rh_S${b}.csv $P44/plan/stands_S${b}_SERVERONLY.csv"); done
runtasks() { printf '%s\n' "$@" | xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is)" >> '$J'/logs/tasks.txt; bash '$S'/run_p45.sh $0 slgrid $2 $3 > '$J'/logs/task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/tasks.txt; exit $rc'; }
step grid runtasks "${T[@]}"
echo "CHAIN_DONE ready for assembly $(date -Is)" >> $LOG

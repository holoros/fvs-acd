#!/bin/bash
# PREREG46 chain (plan revision 1, md5 eb4b753d). Refuses unless the registration line and every launch md5 match. G0 (driver_p46
# mode g0, qc141 with RH unset, against frozen p19_a0111 at 1e-9), G0b (mode grid reproduces the frozen PREREG31 dry trajectory
# exactly), G0x (arm qc_rh, form exp, PREREG44 S1 list, against frozen PREREG45 traj_qc_rh_S1.csv at 1e-9), TR (trace gate,
# both arms, 2 stands, 3 years), the benchmark (tasks 1 to 48: qc_lz 1 to 20, qc_ez 21 to 40, qc_lz0 41 to 44, qc_ez0 45 to
# 48; at most 2 at once, none at load 12 or above), the PREREG38 retry rule for every arm, scoring r2, then the PREREG44
# stand list long run for qc_lz and qc_ez (six tasks, at most 2 R processes). Assembly is a separate step. Stops at the first
# failure; nothing is overwritten. Prepared 11 October 2026 on the laptop; reviewed on the server before launch. No em dashes.
J=/home/aaron/jobs/v142p46; H=$J/home; LOG=$J/logs/chain.txt; S=$J/scripts; P31=/home/aaron/jobs/v142p31; P44=/home/aaron/jobs/v142p44; P45=/home/aaron/jobs/v142p45
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
echo "chain start $(date -Is) pid=$$" >> $LOG
grep -q "eb4b753d5ff58f8246cf89e8e2fc5c96  plan/2026-10-11_v142_qc-relht-zero-form_PREREG46.md  PREREG46 revision 1 registered" $J/logs/prereg_md5.txt || { echo "REFUSE no registration line" >> $LOG; exit 4; }
( cd $J && echo "eb4b753d5ff58f8246cf89e8e2fc5c96  plan/2026-10-11_v142_qc-relht-zero-form_PREREG46.md" | md5sum -c --quiet - ) || { echo "REFUSE plan md5" >> $LOG; exit 4; }
cd $J || exit 4
md5sum -c --quiet $J/logs/launch_md5s.txt >> $LOG 2>&1 || { echo "STOP launch md5 mismatch" >> $LOG; exit 4; }
[ -e $H/logs/_status_main.txt ] && { echo "REFUSE main status exists" >> $LOG; exit 5; }
cd $J; mkdir -p g0 out tr fit
[ -e $J/logs/fit_md5.txt ] && { echo "REFUSE fit md5 exists" >> $LOG; exit 5; }
step fit bash -c "Rscript $S/fit_p46.R > $J/logs/fit.txt 2>&1 && grep -q P46_FIT_DONE $J/logs/fit.txt"
md5sum $J/fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv > $J/logs/fit_md5.txt; echo "fit md5 $(cut -c1-8 $J/logs/fit_md5.txt) $(date -Is)" >> $LOG
step build bash -c "bash $S/build_p46.sh > $J/logs/build.txt 2>&1"
( cd $J && md5sum scripts/driver_p46.R scripts/run_task_p46.sh scripts/run_p46.sh scripts/run_score_p46.sh scripts/launch_p46.sh home/runner_p46_fb.R home/run_retry_p46.sh home/retry_timeouts_p46.sh home/work/p46_taskmap_DATA_2026-10-11.csv ) > $J/logs/build_md5s.txt
grep -nE "<= *2[04]|>= *21|seq 1 2[04]" $H/run_retry_p46.sh $H/retry_timeouts_p46.sh >> $LOG && { echo "CHAIN_STOP fixed task range in retry scripts" >> $LOG; exit 6; }
step g0run bash -c "P31_G0_STANDS=$(cat $P31/logs/g0_stands.txt) bash $S/run_p46.sh qc141 g0 $J/g0/g0_qc141.csv > $J/logs/task_g0.log 2>&1"
step g0cmp bash -c "Rscript $P31/scripts/g0_cmp_p31.R $J/g0/g0_qc141.csv $J/logs/g0_result.csv > $J/logs/g0_cmp.log 2>&1"
step g0brun bash -c "bash $S/run_p46.sh qc141 grid $J/g0/g0b_qc141_MX_E19.8_N6000.csv $P31/plan/cells_dry.csv > $J/logs/task_g0b.log 2>&1"
step g0bcmp bash -c "Rscript $P44/scripts/g0b_p44.R $J/g0/g0b_qc141_MX_E19.8_N6000.csv $J/logs/g0b_result.csv > $J/logs/g0b_cmp.log 2>&1"
step g0xrun bash -c "bash $S/run_p46.sh qc_rh slgrid $J/g0/g0x_traj_qc_rh_S1.csv $P44/plan/stands_S1_SERVERONLY.csv > $J/logs/task_g0x.log 2>&1"
step g0xcmp bash -c "Rscript $S/g0x_cmp_p46.R $J/g0/g0x_traj_qc_rh_S1.csv $P45/out/traj_qc_rh_S1.csv $J/logs/g0x_result.csv > $J/logs/g0x_cmp.log 2>&1"
head -1 $P44/plan/stands_S1_SERVERONLY.csv > $J/tr/tr_stands_SERVERONLY.csv; sed -n 2,3p $P44/plan/stands_S1_SERVERONLY.csv >> $J/tr/tr_stands_SERVERONLY.csv
for A in qc_lz qc_ez; do
  step tr_$A bash -c "P31_NYR=3 P46_TRACE=$J/tr/tr_${A}_SERVERONLY.csv bash $S/run_p46.sh $A slgrid $J/tr/tr_traj_${A}_SERVERONLY.csv $J/tr/tr_stands_SERVERONLY.csv > $J/logs/task_tr_$A.log 2>&1"
  step trchk_$A bash -c "Rscript $S/tr_check_p46.R $A $J/tr/tr_${A}_SERVERONLY.csv $J/logs/tr_result_$A.csv > $J/logs/tr_check_$A.log 2>&1; test -s $J/logs/tr_result_$A.csv"
done
HOME=$H setsid nohup bash $S/launch_p46.sh $H/work/p46_ids.txt main >> $J/logs/launch_main.log 2>&1 < /dev/null &
LP=$!; sleep 30; kill -0 $LP 2>/dev/null || grep -q ALL_DONE $H/logs/_status_main.txt 2>/dev/null || { echo "CHAIN_STOP launch died $(date -Is)" >> $LOG; exit 6; }
until grep -q ALL_DONE $H/logs/_status_main.txt 2>/dev/null; do sleep 60; done
echo "bench done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_main.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_main.txt) nonzero" >> $LOG
grep -q 'exit [1-9]' $H/logs/_status_main.txt && { echo "CHAIN_STOP a bench task exited nonzero" >> $LOG; exit 6; }
for A in qc_lz qc_ez qc_lz0 qc_ez0; do HOME=$H bash $H/retry_timeouts_p46.sh $A; echo "retry $A done $(date -Is): $(tail -1 $H/logs/retry_$A.log 2>/dev/null)" >> $LOG; done
step score bash -c "bash $S/run_score_p46.sh > $J/logs/score.txt 2>&1"
T=(); for A in qc_lz qc_ez; do for b in 1 2 3; do T+=("$A S$b $J/out/traj_${A}_S${b}.csv $P44/plan/stands_S${b}_SERVERONLY.csv"); done; done
runtasks() { printf '%s\n' "$@" | xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is)" >> '$J'/logs/tasks.txt; bash '$S'/run_p46.sh $0 slgrid $2 $3 > '$J'/logs/task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/tasks.txt; exit $rc'; }
step grid runtasks "${T[@]}"
echo "CHAIN_DONE ready for assembly $(date -Is)" >> $LOG

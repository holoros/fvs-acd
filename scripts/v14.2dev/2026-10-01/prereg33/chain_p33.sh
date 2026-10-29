#!/bin/bash
# PREREG33 chain (plan revision 1). Refuses unless the pre-registration md5 line exists and every launch md5 matches.
# Benchmark: G0 tasks 21 to 32 (p33_g0a, p33_g0b, p33_g0b1 on qc_c chunks 1, 10, 19 and qc_fl), by name retries, the G0
# record (stops on a G0a or G0b failure: harness failure, no verdict); then p33_dyn tasks 1 to 20, retries, scoring, the
# benchmark assembly and its re-derivation. Grid: G0 and G0d (driver g0 mode), G0c, the qc141 and p33_dyn grids (one task
# per arm and mix), the grid assembly and its re-derivation; then the PREREG33 decision rule and the figures. At most 2 R
# model processes at once, none started while the 1 minute load average is 12 or above. Stops at the first failure;
# nothing is overwritten. Usage: cd ~/jobs/v142p33 && setsid nohup bash scripts/chain_p33.sh > logs/chain_nohup.log 2>&1 < /dev/null &
# No coordinates. No em dashes.
J=/home/aaron/jobs/v142p33; H=$J/home; LOG=$J/logs/chain.txt; S=$J/scripts
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
cd $J; echo "chain start $(date -Is) pid=$$" >> $LOG
grep -q "PREREG33 revision 1 md5" $J/logs/prereg_md5.txt 2>/dev/null || { echo "REFUSE no pre-registration md5 line" >> $LOG; exit 4; }
md5sum -c --quiet $J/logs/launch_md5s.txt >> $LOG 2>&1 || { echo "REFUSE launch md5 mismatch" >> $LOG; exit 4; }
waitall() { until grep -q ALL_DONE $H/logs/_status_$1.txt 2>/dev/null; do sleep 60; done
  echo "$1 done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_$1.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_$1.txt) nonzero" >> $LOG
  ! grep -q 'exit [1-9]' $H/logs/_status_$1.txt || { echo "CHAIN_STOP a $1 task exited nonzero" >> $LOG; exit 6; }; }
## ---- benchmark G0
[ -e $H/logs/_status_g0.txt ] && { echo "REFUSE g0 status exists" >> $LOG; exit 5; }
HOME=$H bash $S/launch_p33.sh $H/work/p33_g0_ids.txt g0 >> $J/logs/launch_g0.log 2>&1; waitall g0
for a in p33_g0a p33_g0b p33_g0b1; do HOME=$H bash $H/retry_timeouts_p33.sh $a; echo "retry $a done $(date -Is): $(tail -1 $H/logs/retry_$a.log 2>/dev/null)" >> $LOG; done
step g0_record bash -c "Rscript $S/g0_cmp_p33.R > $J/logs/g0_cmp.txt 2>&1"
## ---- benchmark candidate
[ -e $H/logs/_status_main.txt ] && { echo "REFUSE main status exists" >> $LOG; exit 5; }
HOME=$H bash $S/launch_p33.sh $H/work/p33_main_ids.txt main >> $J/logs/launch_main.log 2>&1; waitall main
HOME=$H bash $H/retry_timeouts_p33.sh p33_dyn; echo "retry p33_dyn done $(date -Is): $(tail -1 $H/logs/retry_p33_dyn.log 2>/dev/null)" >> $LOG
step score bash -c "bash $S/run_score_p33.sh > $J/logs/score.txt 2>&1"
echo "59196106afe20e57ca1bc7b4894495f1  $S/2026-09-29_v142_p23_hkey.R" | md5sum -c --quiet - || { echo "CHAIN_STOP height key helper md5" >> $LOG; exit 7; }
step assemble_bench bash -c "Rscript $S/2026-10-01_v142_p33_assemble_bench.R > $J/logs/assemble_bench.txt 2>&1"
echo "bench $(grep '^verdict=' $J/assembled/bench/gyr142-p33-verdict_DATA_2026-10-01.txt)" >> $LOG
step verify_bench bash -c "gate; cd $J/verify_20261001 && Rscript p33_rederive_bench.R > p33_rederive_bench.log 2>&1"
## ---- grid
G0S=QC__30000019L2__2001_2015_C,QC__30000213L2__2012_2018_C,QC__30000223L2__2013_2018_C
step grid_g0 bash -c "gate; P31_G0_STANDS=$G0S bash $S/run_p33.sh qc141 g0 $J/dry/g0_qc141.csv > $J/logs/task_grid_g0_qc141.log 2>&1"
step grid_g0d bash -c "gate; P31_G0_STANDS=$G0S bash $S/run_p33.sh p33_g0d g0 $J/dry/g0_p33_g0d.csv > $J/logs/task_grid_g0_p33_g0d.log 2>&1"
step grid_g0_record Rscript $S/g0_cmp_p31.R $J/dry/g0_qc141.csv $J/logs/grid_g0_result.csv
step grid_g0d_record Rscript $S/g0_cmp_p31.R $J/dry/g0_p33_g0d.csv $J/logs/grid_g0d_result.csv
step g0c bash $S/g0c_p33.sh
runtasks() { printf '%s\n' "$@" | xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> '$J'/logs/tasks.txt; bash '$S'/run_p33.sh $0 grid $2 $3 > '$J'/logs/task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/tasks.txt; exit $rc'; }
T=(); for m in BF SM MX; do for a in qc141 p33_dyn; do T+=("$a $m $J/out/traj_${a}_${m}.csv $J/plan/cells_${m}.csv"); done; done
step grid runtasks "${T[@]}"
step assemble_grid bash -c "P33_PLAN_MD5=$(tail -1 $J/logs/prereg_md5.txt | cut -d' ' -f1) Rscript $S/assemble_p33_grid.R > $J/logs/assemble_grid.log 2>&1"
echo "grid $(grep '^outcome=' $J/assembled/grid/gyr142-p33grid-verdict_DATA_2026-10-01.txt)" >> $LOG
step verify_grid bash -c "gate; cd $J/verify_20261001 && Rscript rederive_p33_grid.R > rederive_p33_grid.log 2>&1"
step final bash -c "Rscript $S/final_verdict_p33.R > $J/logs/final.txt 2>&1"
echo "$(grep '^final=' $J/assembled/gyr142-p33-final-verdict_DATA_2026-10-01.txt)" >> $LOG
step figures bash -c "Rscript $J/figs/fig_p33.R > $J/logs/figures.log 2>&1"
echo "CHAIN_DONE $(date -Is)" >> $LOG

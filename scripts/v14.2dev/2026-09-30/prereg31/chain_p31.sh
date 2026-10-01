#!/bin/bash
# PREREG31 chain (plan revision 1). Tasks: the dry cell (qc141, MX_E19.8_N6000, 100 yr) and the gated arms qc141 and
# p28b_small (one task per arm and mix, 12 cells each), at most 2 R model processes at once, none started while the 1 minute
# load average is 12 or above; then G0c, the G0 record (from the pre registration G0 output, no model rerun), the assembly and
# verdict, the load gated re-derivation [F9], and the figures; CHAIN_DONE. Each step logs to logs/chain.txt; the chain stops
# at the first failure; nothing is overwritten. No coordinates. No em dashes.
J=/home/aaron/jobs/v142p31; LOG=$J/logs/chain.txt; S=$J/scripts
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
runtasks() { # lines "arm mix outfile cellsfile", 2 at a time
  printf '%s\n' "$@" | xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> '$J'/logs/tasks.txt; bash '$S'/run_p31.sh $0 grid $2 $3 > '$J'/logs/task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/tasks.txt; exit $rc'
}
cd $J; echo "chain start $(date -Is) pid=$$" >> $LOG
T=("qc141 dry $J/dry/dry_qc141_MX_E19.8_N6000.csv $J/plan/cells_dry.csv")
for m in BF SM MX; do for a in qc141 p28b_small; do T+=("$a $m $J/out/traj_${a}_${m}.csv $J/plan/cells_${m}.csv"); done; done
step grid runtasks "${T[@]}"
step g0c bash $S/g0c_p31.sh
step g0record Rscript $S/g0_cmp_p31.R $J/dry/g0_qc141.csv $J/logs/g0_result.csv
step assemble bash -c "P31_PLAN_MD5=$(cut -d' ' -f1 $J/logs/prereg_md5.txt | tail -1) Rscript $S/assemble_p31.R > $J/logs/assemble.log 2>&1"
echo "outcome $(grep '^outcome=' $J/assembled/gyr142-p31-verdict_DATA_2026-09-30.txt | cut -d= -f2)" >> $LOG
step verify bash $J/verify_20260930/run_rederive_p31.sh
step figures bash -c "Rscript $J/figs/fig_p31.R > $J/logs/figures.log 2>&1"
echo "CHAIN_DONE $(date -Is)" >> $LOG

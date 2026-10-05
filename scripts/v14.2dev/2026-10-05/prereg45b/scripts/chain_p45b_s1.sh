#!/bin/bash
# PREREG45b chain, stage 1: G0 and G0b (driver_p45b, RH unset, QC set), benchmark tasks 1 to 39 (nb141, nb_one, nb_rh0), retries,
# then the fold A fit and its md5. Stage 2 (nb_rh benchmark and the long run) is chain_p45b_s2.sh. Stops at the first failure. No em dashes.
J=/home/aaron/jobs/v142p45b; H=$J/home; LOG=$J/logs/chain.txt; S=$J/scripts; P31=/home/aaron/jobs/v142p31; P44=/home/aaron/jobs/v142p44
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
echo "chain s1 start $(date -Is) pid=$$" >> $LOG
grep -q "PREREG45b revision 1 registered" $J/logs/prereg_md5.txt || { echo "REFUSE no registration line" >> $LOG; exit 4; }
md5sum -c --quiet $J/logs/launch_md5s.txt >> $LOG 2>&1 || { echo "STOP launch md5 mismatch" >> $LOG; exit 4; }
cd $J
step g0run bash -c "P45B_SET=qc_c P31_G0_STANDS=$(cat $P31/logs/g0_stands.txt) bash $S/run_p45b.sh qc141 g0 $J/g0/g0_qc141.csv > $J/logs/task_g0.log 2>&1"
step g0cmp bash -c "Rscript $P31/scripts/g0_cmp_p31.R $J/g0/g0_qc141.csv $J/logs/g0_result.csv > $J/logs/g0_cmp.log 2>&1"
step g0brun bash -c "P45B_SET=qc_c bash $S/run_p45b.sh qc141 grid $J/g0/g0b_qc141_MX_E19.8_N6000.csv $P31/plan/cells_dry.csv > $J/logs/task_g0b.log 2>&1"
step g0bcmp bash -c "Rscript $P44/scripts/g0b_p44.R $J/g0/g0b_qc141_MX_E19.8_N6000.csv $J/logs/g0b_result.csv > $J/logs/g0b_cmp.log 2>&1"
HOME=$H bash $S/launch_p45b.sh $H/work/p45b_ids_stage1.txt s1 >> $J/logs/launch_s1.log 2>&1
until grep -q ALL_DONE $H/logs/_status_s1.txt 2>/dev/null; do sleep 60; done
echo "bench s1 done $(date -Is): $(grep -c 'exit 0' $H/logs/_status_s1.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_s1.txt) nonzero" >> $LOG
grep -q 'exit [1-9]' $H/logs/_status_s1.txt && { echo "CHAIN_STOP a bench task exited nonzero" >> $LOG; exit 6; }
for A in nb141 nb_one nb_rh0; do HOME=$H bash $H/retry_timeouts_p45b.sh $A; echo "retry $A done $(date -Is): $(tail -1 $H/logs/retry_$A.log 2>/dev/null)" >> $LOG; done
step fit bash -c "Rscript $S/fit_p45b.R > $J/logs/fit.txt 2>&1"
md5sum $J/fit/gyr142-p45b-nbrh-fit_DATA_2026-10-05.csv > $J/logs/fit_md5.txt; echo "fit md5 $(cat $J/logs/fit_md5.txt)" >> $LOG
echo "CHAIN_S1_DONE $(date -Is)" >> $LOG

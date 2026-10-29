#!/bin/bash
# PREREG49 chain (plan revision 1, md5 c2188088), detached with setsid nohup. Order as the plan's Execution section: input md5s,
# fit and its md5, build, H0, TR, benchmark tasks, retry rule, scoring r2 (and H2), stage 1 assembly (md5 recorded first),
# frontier (md5 recorded), draw, G0, G0b, long run, stage 2 assembly (md5 recorded first). Refuses unless the registration line
# and every launch md5 match. At most 2 R processes at once (the launcher and the long run task pool hold 2; every other step is
# one process), none started while the 1 minute load average is 12 or above. A fit stop, H0 or TR failure skips the benchmark
# (stage 1 rule 1, harness failure) and the chain goes on to stage 2 without v141LTfis. Nothing is overwritten. No em dashes.
J=/home/aaron/jobs/v142p49; H=$J/home; LOG=$J/logs/chain.txt; S=$J/scripts; PMD5=c218808858938c889ac771b0de5db531
note() { echo "$* $(date -Is)" >> $LOG; }
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
export -f gate
cd $J; note "chain start pid=$$"
grep -q "^$PMD5  plan/2026-10-26_v142_ns-survival-step_PREREG49.md  registered" $J/logs/prereg_md5.txt || { note "REFUSE no registration line"; exit 4; }
echo "$PMD5  plan/2026-10-26_v142_ns-survival-step_PREREG49.md" | md5sum -c --quiet - || { note "REFUSE plan md5"; exit 4; }
md5sum -c --quiet $J/logs/launch_md5s.txt >> $LOG 2>&1 || { note "STOP launch md5 mismatch"; exit 4; }
## 0. frozen input md5s, per file, before the fit (combined pred_t2_tree md5 must equal LOOKUPS b0516d67)
step inputs bash -c "md5sum /home/aaron/jobs/v142p22/home/out/v141LTfi/*/c*.csv /home/aaron/jobs/v142p22/results/v141LTfi/*.csv /home/aaron/jobs/v142p22/home/p22_env.sh /home/aaron/jobs/v142p27/fit/gyr142-p27-diag-survrec-foldA_DATA_2026-09-30.csv /home/aaron/jobs/v142p26/out/traj_v141LTfi_BF.csv /home/aaron/jobs/v142p26/assembled/thresholds_p26_DATA_2026-09-30.csv > $J/logs/input_md5s.txt && cd /home/aaron/jobs/v142p22/home/out/v141LTfi && [ \"\$(md5sum */c*_pred_t2_tree.csv | md5sum | cut -d' ' -f1)\" = b0516d6712dbcf025920be3e7480712d ]"
## 1. fit (fold A), its md5 before any engine run
gate; note "fit start load $(cut -d' ' -f1 /proc/loadavg)"; Rscript $S/fit_p49.R > $J/logs/fit.txt 2>&1; rc=$?; echo $rc > $J/logs/fit_rc.txt; note "fit exit $rc"
FIT_OK=0; if [ $rc -eq 0 ]; then md5sum $J/fit/gyr142-p49-sffr-fit_DATA_2026-10-26.csv > $J/logs/fit_md5.txt; FIT_OK=1; note "fit md5 recorded $(cut -d' ' -f1 $J/logs/fit_md5.txt)"; fi
## 2. build (bundle copy, runner and driver edits, taskmap); outputs must equal the md5s recorded before the chain
step build bash -c "bash $S/build_p49.sh > $J/logs/build.txt 2>&1 && cd $J && md5sum -c --quiet logs/build_expected_md5s.txt"
## 3. H0, TR, benchmark, retry rule, scoring r2, H2
if [ $FIT_OK -eq 1 ]; then
  HOME=$H bash $S/launch_p49.sh $H/work/p49_ids_h0.txt h0 >> $J/logs/launch_h0.log 2>&1; note "h0 task done: $(grep -c 'exit 0' $H/logs/_status_h0.txt) exit 0"
  HOME=$H bash $S/retry_timeouts_p49.sh v141LTfis0; note "retry v141LTfis0: $(tail -1 $H/logs/retry_v141LTfis0.log 2>/dev/null)"
  gate; Rscript $S/h0_cmp_p49.R $J $J/logs/h0_result.csv > $J/logs/h0_cmp.log 2>&1; H0RC=$?; note "h0 compare exit $H0RC"
  gate; bash $S/tr_p49.sh > $J/logs/tr_run.log 2>&1; note "tr run exit $?"
  gate; Rscript $S/tr_check_p49.R $J/out/tr/trace_SERVERONLY.csv $J/fit/gyr142-p49-sffr-fit_DATA_2026-10-26.csv $J/logs/tr_result.csv > $J/logs/tr_check.log 2>&1; TRRC=$?; note "tr check exit $TRRC"
  if [ $H0RC -eq 0 ] && [ $TRRC -eq 0 ]; then
    HOME=$H bash $S/launch_p49.sh $H/work/p49_ids_main.txt main >> $J/logs/launch_main.log 2>&1
    note "bench done: $(grep -c 'exit 0' $H/logs/_status_main.txt) exit 0, $(grep -c 'exit [1-9]' $H/logs/_status_main.txt) nonzero"
    HOME=$H bash $S/retry_timeouts_p49.sh v141LTfis; note "retry v141LTfis: $(tail -1 $H/logs/retry_v141LTfis.log 2>/dev/null)"
    gate; bash $S/run_score_p49.sh > $J/logs/score.txt 2>&1; note "score exit $?"
    gate; Rscript $S/h2_p49.R > $J/logs/h2.txt 2>&1; note "h2 exit $?"
  else note "H0 or TR failed: benchmark not run (stage 1 rule 1)"; fi
else note "fit stop or fit failure: H0, TR and benchmark not run (stage 1 rule 1)"; fi
## 4. stage 1 assembly, md5 first
md5sum $S/assemble_s1_p49.R >> $J/logs/assemble_md5.txt; note "stage 1 assembly md5 recorded"
gate; P49_PLAN_MD5=$PMD5 Rscript $S/assemble_s1_p49.R > $J/logs/assemble_s1.log 2>&1; note "assemble_s1 exit $?"
V1=$J/assembled/s1/gyr142-p49-s1-verdict_DATA_2026-10-26.txt; note "stage 1 $(grep '^outcome=' $V1)"
FIS=0; grep -q '^fis_enters_stage2=TRUE$' $V1 && FIS=1
## 5. NS measured frontier, md5 before the draw
mkdir -p $J/out/s2
step frontier bash -c "gate; Rscript $S/frontier_p49.R $J/out/s2/frontier_p49_DATA.csv > $J/logs/frontier.txt 2>&1"
md5sum $J/out/s2/frontier_p49_DATA.csv > $J/logs/frontier_md5.txt; note "frontier md5 recorded $(cut -d' ' -f1 $J/logs/frontier_md5.txt)"
## 6. draw
gate; Rscript $S/select_p49.R $J/out/s2 > $J/logs/select.txt 2>&1; rc=$?; note "select exit $rc"
if [ $rc -ne 0 ]; then note "stage 2 harness failure at the draw (exit $rc); long run not started"; echo "CHAIN_DONE $(date -Is)" >> $LOG; exit 0; fi
## 7. G0 and G0b (driver_p49, switch off)
G0S=$(Rscript -e 'f <- "/home/aaron/jobs/v142p26/dry/g0_v141LT.csv"; stopifnot(unname(tools::md5sum(f)) == "988dd346c3693953295423a868050ac9"); cat(paste(data.table::fread(f, colClasses = list(character = "STAND"))$STAND, collapse = ","))')
gate; P26_G0_STANDS=$G0S bash $S/run_p49.sh v141LTfi g0 $J/out/s2/g0_v141LTfi.csv > $J/logs/s2_task_g0.log 2>&1; note "s2 g0 run exit $?"
Rscript $S/g0_cmp_p49.R $J/out/s2/g0_v141LTfi.csv $J/logs/s2_g0_result.csv > $J/logs/s2_g0_cmp.log 2>&1; note "s2 g0 compare exit $?"
gate; bash $S/run_p49.sh v141LTfi grid $J/out/s2/g0b_v141LTfi_BF.csv /home/aaron/jobs/v142p26/plan/cells_BF.csv > $J/logs/s2_task_g0b.log 2>&1; note "s2 g0b run exit $?"
Rscript $S/g0b_p49.R $J/out/s2/g0b_v141LTfi_BF.csv $J/logs/s2_g0b_result.csv > $J/logs/s2_g0b_cmp.log 2>&1; note "s2 g0b compare exit $?"
## 8. long run: arms by SDI bin, at most 2 at once
ARMS="v141LT v141LTfi"; [ $FIS -eq 1 ] && ARMS="$ARMS v141LTfis"; note "long run arms: $ARMS"
for a in $ARMS; do for b in 1 2 3; do echo "$a S$b $J/out/s2/traj_${a}_S${b}.csv $J/out/s2/stands_S${b}_SERVERONLY.csv"; done; done | \
  xargs -P 2 -L 1 bash -c 'gate; echo "task $0 $1 start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> '$J'/logs/s2_tasks.txt; bash '$S'/run_p49.sh $0 slgrid $2 $3 > '$J'/logs/s2_task_$0_$1.log 2>&1; rc=$?; echo "task $0 $1 exit $rc $(date -Is)" >> '$J'/logs/s2_tasks.txt; exit 0'
note "long run done: $(grep -c 'exit 0' $J/logs/s2_tasks.txt) exit 0, $(grep -c 'exit [1-9]' $J/logs/s2_tasks.txt) nonzero"
## 9. stage 2 assembly, md5 first
md5sum $S/assemble_s2_p49.R >> $J/logs/assemble_md5.txt; note "stage 2 assembly md5 recorded"
gate; P49_PLAN_MD5=$PMD5 Rscript $S/assemble_s2_p49.R > $J/logs/assemble_s2.log 2>&1; note "assemble_s2 exit $?"
note "stage 2 $(grep '^outcome_' $J/assembled/s2/gyr142-p49-s2-verdict_DATA_2026-10-26.txt 2>/dev/null | tr '\n' ' ')"
echo "CHAIN_DONE $(date -Is)" >> $LOG

#!/bin/bash
# PREREG35 scoring: unmodified PREREG16 scorer (md5 019df238) and r2 on identical firebreather plans. New directories only;
# refuses to overwrite. One R process at a time; waits while the 1 minute load is 12 or above. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p35; P=/home/aaron/jobs; X=$P/v142p19/in/xfer
cd $J
echo "019df23877abd9e1aab83831d13322dc  $P/v142p28/scripts/2026-09-27_v142_volconv_score.R" | md5sum -c - || exit 4
echo "0b604babd7cbef91afc0ded4b2687431  $P/v142p28/home/hw_formrisk_split.R" | md5sum -c - || exit 4
export OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
waitload() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do echo "load $(cut -d' ' -f1 /proc/loadavg), waiting"; sleep 60; done; }
md5sum scripts/*.R plan/*.csv $X/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv $X/score/work/*.rds $X/v142_20260925/bench141/results/v141LT/*.csv
run() { local scr=$1 out=$2 plan=$3 tag=$4 refh=$5 trt=$6
  [ -e $out ] && { echo "REFUSE $out exists"; exit 5; }; mkdir -p $out; waitload
  VC_OUT=$out VC_PLAN=$plan VC_TAG=$tag VC_REFDIR=$refh/magplot/verify VC_SPLIT=$refh/hw_formrisk_split.R VC_TRT=$trt Rscript $scr; rc=$?
  echo "EXIT $rc $scr $out"; [ $rc -eq 0 ] || exit $rc
  for f in $out/*_PROVISIONAL_*.csv; do [ -e "$f" ] && mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done; }
B=$P/v142p28/scripts/2026-09-27_v142_volconv_score.R; R2=$J/scripts/2026-10-01_v142_volconv_score_r2.R
T=$X/v142_20260925/p14/out/p14_magp_treatment_DATA_2026-09-26.csv
run $B  $J/tables/p16_fb    $J/plan/p35_plan_fb_v141LT.csv volconv $P/v142p28/home $T
run $R2 $J/tables/r2_fb     $J/plan/p35_plan_fb_v141LT.csv volconv $P/v142p28/home $T
run $B  $J/tables/p16_state $J/plan/p35_plan_state.csv volconv-state $P/v142p15/home ""
run $R2 $J/tables/r2_state  $J/plan/p35_plan_state.csv volconv-state $P/v142p15/home ""
echo P35_SCORE_DONE

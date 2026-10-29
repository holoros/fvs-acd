#!/bin/bash
# PREREG16 State MNAP (PREREG15 amended run r1) scored where its per tree outputs live. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142vc; H=/home/aaron/jobs/v142p15/home
export OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
export VC_OUT=$J/tables_state_r1 VC_PLAN=$J/plan/volconv_plan_state.csv VC_REFDIR=$H/magplot/verify VC_SPLIT=$H/hw_formrisk_split.R VC_TAG=volconv-state
md5sum $J/scripts/*.R $VC_SPLIT $VC_REFDIR/nsvb_emulator_coefs.csv $VC_REFDIR/spcd_spgrpcd.csv
Rscript $J/scripts/2026-09-27_v142_volconv_score.R; rc=$?
[ $rc -eq 0 ] && for f in $VC_OUT/*_PROVISIONAL_*.csv; do mv -n "$f" "${f/_PROVISIONAL_/_DATA_}"; done
echo "EXIT $rc"; [ $rc -eq 0 ] && echo VC_STATE_DONE

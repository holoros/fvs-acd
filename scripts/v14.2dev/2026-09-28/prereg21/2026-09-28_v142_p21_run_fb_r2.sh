#!/bin/bash
# PREREG21 r2 MNAP State height diagnostic on firebreather. Single R process, two threads. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p21; H=/home/aaron/jobs/v142p15/home
export OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
export P21_OUT=$J/tables_r2 P21_SET=mnap_c P21_LABEL=mnap_c_state
export P21_RES=/home/aaron/jobs/v142p15/results_r1/v141LT/gyr_v141LT_mnap_c_results.csv
export P21_TREEDIRS="$H/out/v141LT/mnap_c;$H/out_retry/v141LT/mnap_c"
export P21_FR=$H/magplot/verify/gydbreg20260916/frames P21_REFDIR=$H/magplot/verify P21_SPLIT=$H/hw_formrisk_split.R
export P21_IDX=SEED:20260916:2000
export P21_GAPREF=/home/aaron/jobs/v142vc/tables_state_r1/gyr142-volconv-state-scores_DATA_2026-09-27.csv P21_GAPLAB=mnap_c_state
export P21_CTRL_FR=/home/aaron/jobs/v142p29b/out/PROVISIONAL_p29b/frames P21_CTRL_SET=mefia_l_c
[ -e "$P21_OUT" ] && { echo "refusing: $P21_OUT exists"; exit 4; }
md5sum $J/scripts/*_r2.R $P21_SPLIT $P21_REFDIR/nsvb_emulator_coefs.csv $P21_REFDIR/spcd_spgrpcd.csv $P21_RES $P21_GAPREF \
  $P21_FR/bench_gyr_mnap_c_*.csv $P21_CTRL_FR/bench_gyr_mefia_l_c_*.csv
nice -n 10 Rscript $J/scripts/2026-09-28_v142_p21_height_diag_r2.R; rc=$?
echo "EXIT $rc"; [ $rc -eq 0 ] && echo P21_RUN_DONE

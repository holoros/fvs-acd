#!/bin/bash
# PREREG31 G0c (PREREG26 g0c_p26.sh with the job root changed): rerun the step-aware checker on the stored v1402 L1 s5
# trajectories; compare with the stored report below the path line. No em dashes.
set -eu; J=/home/aaron/jobs/v142p31; V=/home/aaron/jobs/v1402_bakuzis_20260917/out; O=$J/logs/g0c_rerun.txt; [ ! -e $O ] || { echo REFUSE; exit 3; }
Rscript --vanilla /home/aaron/jobs/acd_bakuzis/bakuzis_check_step-aware_FINAL_2026-09-07.R $V/traj_v1402_L1_s5_2026-09-17.csv > $O 2>&1
if diff <(grep -v "^BAKUZIS ASSESSMENT" $O) <(grep -v "^BAKUZIS ASSESSMENT" $V/bakuzis_stepaware_v1402_L1_s5_2026-09-17.txt) > $J/logs/g0c_diff.txt; then echo "G0C_PASS" | tee $J/logs/g0c_status.txt; else echo "G0C_FAIL" | tee $J/logs/g0c_status.txt; exit 5; fi

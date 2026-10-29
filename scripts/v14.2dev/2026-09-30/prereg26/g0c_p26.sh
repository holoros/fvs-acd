#!/bin/bash
# PREREG26 G0c: rerun the step-aware checker on the stored v1402 L1 s5 trajectories; compare with the stored report below the path line.
set -eu; J=/home/aaron/jobs/v142p26; V=/home/aaron/jobs/v1402_bakuzis_20260917/out; O=$J/logs/g0c_rerun.txt; [ ! -e $O ] || { echo REFUSE; exit 3; }
Rscript --vanilla /home/aaron/jobs/acd_bakuzis/bakuzis_check_step-aware_FINAL_2026-09-07.R $V/traj_v1402_L1_s5_2026-09-17.csv > $O 2>&1
if diff <(grep -v "^BAKUZIS ASSESSMENT" $O) <(grep -v "^BAKUZIS ASSESSMENT" $V/bakuzis_stepaware_v1402_L1_s5_2026-09-17.txt) > $J/logs/g0c_diff.txt; then echo "G0C_PASS"; else echo "G0C_FAIL"; exit 5; fi

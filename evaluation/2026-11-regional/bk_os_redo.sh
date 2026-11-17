#!/bin/bash
# rerun the Bakuzis checker and matrix for the corrected OSM trajectories, one R process at a time, only when <= 1 other R runs
cd ~/jobs/gy2eval_20261112
until [ $(ps -eo args | grep -E "^(/usr/lib/R/bin/exec/R|Rscript)" | grep -v grep | wc -l) -le 1 ]; do sleep 60; done
echo "start $(date -Iseconds)"
nice -n 10 Rscript ~/jobs/acd_bakuzis/bakuzis_check_step-aware_FINAL_2026-09-07.R bakz/traj_bkos.csv 0.40 0.10 > bakz/check_bkos.txt 2>&1
nice -n 10 Rscript ~/jobs/fvsacd_bakuzis/bakuzis_matrix.R bakz/traj_bkos.csv bakz/matrix_bkos.png > bakz/mat_bkos.log 2>&1
cp bakz/check_bkos.txt bakz/matrix_bkos.png plan/2026-11-13_comparators/
echo "BKOS_DONE $(date -Iseconds)"

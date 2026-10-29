#!/bin/bash
# PREREG4 dry run setup: a dry root with the real scripts (symlink), copies of the grid coefficient files, a test coefficient
# file for candL (the delta -1 grid file), a keep file of the first 3 fold A stands, and dry taskmaps. No em dashes.
set -euo pipefail
D=/users/PUOM0008/crsfaaron/v143p4/dry/root; P=/users/PUOM0008/crsfaaron/v143p4
[ -e $D/work ] && { echo "dry root exists"; exit 0; }
mkdir -p $D/work $D/so $D/logs $D/out
ln -sfn $P/scripts $D/scripts
cp -p $P/work/grid_coef_*.csv $P/work/senft_coef_D1.csv $D/work/
cp -p $P/work/grid_coef_m100.csv $D/work/senft_coef_L.csv
head -4 $P/serveronly_SERVERONLY/keep_foldA_SERVERONLY.csv > $D/so/keep_foldA_SERVERONLY.csv
{ cat $P/logs/launch_md5s.txt; (cd $D && md5sum work/senft_coef_L.csv); } > $D/logs/launch_md5s.txt
{ echo "task,arm,chunk,set,from,to"; k=0; for a in off g0 gL_m200 gL_m150 gL_m100 gL_m050 gL_p050 gL_p100 gS_m200 gS_m150 gS_m100 gS_m050 gS_p050 gS_p100 candL; do k=$((k+1)); echo "$k,$a,1,mefia_l_c,1,3"; done; } > $D/work/taskmap_dry_hc.csv
printf 'task,arm,chunk,set,from,to\n1,off,1,mefia_l_c,1,2\n2,candL,1,mefia_l_c,1,2\n3,D1,1,mefia_l_c,1,2\n' > $D/work/taskmap_dry_l200.csv
cd $P
V143P4_ROOT=$D V143_TASKMAP=$D/work/taskmap_dry_hc.csv V143_MD5FILE=$D/logs/launch_md5s.txt V143_WORK=$D/work V143_SO=$D/so \
  sbatch --array=1-15 --time=00:40:00 --job-name=v143p4dryhc --output=$D/logs/dryhc_%A_%a.out scripts/v143p4_hc_array.sbatch
V143P4_ROOT=$D V143_TASKMAP=$D/work/taskmap_dry_l200.csv V143_MD5FILE=$D/logs/launch_md5s.txt V143_WORK=$D/work V143_SO=$D/so \
  sbatch --array=1-3 --time=01:00:00 --job-name=v143p4dryL2 --output=$D/logs/dryl2_%A_%a.out scripts/v143p4_l200_array.sbatch
echo DRY_SETUP_DONE

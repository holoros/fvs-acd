#!/bin/bash
#SBATCH --job-name=v142p21m
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=01:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=2 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/recs/p21/logs/%x_%j.out
# PREREG21 control: the same r2 diagnostic on mefia_l_c v141LT, where its frozen per tree outputs live. Reads only;
# no model run. New directory only. Aggregates only. No em dashes.
set -uo pipefail
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
R0=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916; J=$R0/v142_20260925/recs/p21
export OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
export P21_OUT=$J/tables_mefia_r2 P21_SET=mefia_l_c P21_LABEL=mefia_l_c
export P21_RES=$R0/v142_20260925/bench141/results/v141LT/gyr_v141LT_mefia_l_c_results.csv
export P21_TREEDIRS=$R0/v142_20260925/bench141/out/v141LT/mefia_l_c P21_FR=$R0/frames
export P21_REFDIR=$HOME/magplot/verify P21_SPLIT=$HOME/hw_formrisk_split.R P21_IDX=$R0/score/work/siteidx_mefia_l_c.rds
export P21_GAPREF=$R0/v142_20260925/recs/volconv/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv P21_GAPLAB=mefia_l_c
[ -e "$P21_OUT" ] && { echo "refusing: $P21_OUT exists"; exit 4; }
md5sum $J/scripts/*_r2.R $P21_SPLIT $P21_REFDIR/nsvb_emulator_coefs.csv $P21_RES $P21_GAPREF $P21_FR/bench_gyr_mefia_l_c_*.csv
Rscript $J/scripts/2026-09-28_v142_p21_height_diag_r2.R; rc=$?
echo "EXIT $rc"; [ $rc -eq 0 ] && echo P21M_DONE

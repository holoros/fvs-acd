#!/bin/bash
#SBATCH --job-name=nbqc_v2
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=03:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p21/nbqc_v2_%j.out
# Rescore NB+QC (magp_qcnb_pairs.csv) against magp_qcnb_site_esi8_v2.csv, which fills QC's
# raster-uncovered sites with real pointwise-predicted SI (acadian_v8_model.rds applied via
# ClimateNA + Copernicus DEM at each site) instead of leaving them out of the domain filter.
# Original p9_v132_nb_results.csv (733 rows, 378 QC) is untouched; this writes a new tag.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc
P21=$HOME/magplot/verify/p21

export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
export INDOMAIN=1

export PAIRS_FILE=$HOME/magplot/verify/magp_qcnb_pairs.csv
export INIT_FILE=$HOME/magplot/verify/magp_qcnb_tree_init.csv
export T2_FILE=$HOME/magplot/verify/magp_qcnb_tree_t2.csv
export SITE_FILE=/fs/scratch/PUOM0008/crsfaaron/canada/qc_esi/magp_qcnb_site_esi8_v2.csv
export CONFIG_TAG=${P21}/p9_v132_nb_v2
export TREE_OUT=""
echo "[nbqc_v2] TAG=$CONFIG_TAG SITE_FILE=$SITE_FILE"
Rscript ${P21}/2026-08-19_p21_bench_v132.R
echo "=== ${CONFIG_TAG} DONE ==="

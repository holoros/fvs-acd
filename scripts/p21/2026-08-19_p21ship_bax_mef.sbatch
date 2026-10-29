#!/bin/bash
#SBATCH --job-name=p21v132bm
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-2
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p21/p21v132bm_%A_%a.out
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc
P9=$HOME/magplot/verify/p9lev3
P21=$HOME/magplot/verify/p21
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export INDOMAIN=1
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
set_src () { PFX=$1; export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv \
             T2_FILE=${PFX}_tree_t2.csv SITE_FILE=${PFX}_site_esi.csv; }
case "$SLURM_ARRAY_TASK_ID" in
  1)  CFG=bax_v132;  set_src $MS/bench_baxter ;;
  2)  CFG=mef_v132;  set_src $MS/bench_mefia_long ;;
  *) echo "bad array id"; exit 2 ;;
esac
export CONFIG_TAG=${P21}/p9_${CFG}
export TREE_OUT=""
echo "[p21v132bm] task=$SLURM_ARRAY_TASK_ID CFG=$CFG"
Rscript ${P21}/2026-08-19_p21_bench_v132.R
echo "=== ${CONFIG_TAG} DONE ==="

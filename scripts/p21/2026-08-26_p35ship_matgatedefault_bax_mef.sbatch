#!/bin/bash
#SBATCH --job-name=p35matgatebm
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-2
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p21/p35matgatebm_%A_%a.out
# Pass 35: maturity-gate companion to 2026-08-26_p35ship_matgatedefault.sbatch, covering the two
# sources the production battery splits out of the main array, Baxter and MEFIA_L (mef, Maine FIA
# whole-plot), exactly as 2026-08-25_p21ship_h1default_bax_mef.sbatch does for the pass 31 default.
# Both are V1211_MANAGED=FALSE, so h1_v132_mortgate is inert at both and the maturity gate is the
# only lever acting there. Baxter is the source where the gate moves the most in the pass 33
# short-interval check, RMSE 25.725 to 24.860 with bias moving -0.22 to +3.23 percent, and it
# already has an h2_matgate result file on Cardinal (~/magplot/verify/p33/
# h2_matgate_baxter_results.csv), so this array is a documentation artifact, not a required rerun,
# exactly as 2026-08-26_p35ship_matgatedefault.sbatch is for the other nine sources. MEFIA_L was not
# scored under the gate in pass 33 and has no h2_matgate result file, so if a MEFIA_L short-interval
# number is ever needed under the pass 35 default, task 2 of this array is the way to get it.
# Model of record ~/AcadianGY_13.1.r UNMODIFIED: ops$use.ingrowth.matgate stays default FALSE in the
# engine, exactly as ops$mort.dens.scale does, and the production sbatch turns it on.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc
P21=$HOME/magplot/verify/p21; P33=$HOME/magplot/verify/p33
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export INDOMAIN=1
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE V1211_MANAGED=FALSE
export P33_MATGATE=TRUE MATGATE_QC=12.7 MATGATE_K=0.6
set_src () { PFX=$1; export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv \
             T2_FILE=${PFX}_tree_t2.csv SITE_FILE=${PFX}_site_esi.csv; }
case "$SLURM_ARRAY_TASK_ID" in
  1)  CFG=bax_matgatedefault;  set_src $MS/bench_baxter ;;
  2)  CFG=mef_matgatedefault;  set_src $MS/bench_mefia_long ;;
  *) echo "bad array id"; exit 2 ;;
esac
export CONFIG_TAG=${P21}/matgatedefault_v132_${CFG}
export TREE_OUT=""
echo "[p35matgatebm] task=$SLURM_ARRAY_TASK_ID CFG=$CFG"
Rscript $P33/2026-08-26_p33-matgate-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

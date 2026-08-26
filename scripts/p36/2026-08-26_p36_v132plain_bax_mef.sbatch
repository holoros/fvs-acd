#!/bin/bash
#SBATCH --job-name=p36v132bm
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-2
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p36/p36v132bm_%A_%a.out
#
# Pass 36, column B of the three-model benchmark: PLAIN v13.2, meaning V132=1 with neither adopted
# lever set, so ops$mort.dens.scale and ops$use.ingrowth.matgate both resolve to their engine
# defaults of FALSE. This is the middle column of the table and the honest answer to what v13.2
# does before the pass 31 and pass 35 levers are applied.
#
# The p9_v132_*_results.csv family already covers ten sources at current authoritative coverage
# plus the nb_v2 NB and QC cell at the 2,555 pair basis, so this array covers only the two the
# 2026-08-19_p21ship_full.sbatch battery splits out, Baxter and MEFIA_L (mef, Maine FIA whole-plot,
# bench_mefia_long). That mirrors how the pass 31 and pass 35 batteries each carry a bax_mef
# companion to the main ten-task array.
#
# Every export below is byte-identical to 2026-08-19_p21ship_full.sbatch, which is the sbatch of
# record for the p9_v132 family, so the two new cells sit on the same configuration as the ten
# reused ones. Both sources run INDOMAIN=1. Neither V1211_MORTGATE nor P33_MATGATE is exported,
# which is the whole point of this column, and V1211_MANAGED is left unset exactly as the p9_v132
# battery leaves it, since the plain v13.2 configuration of record never carried a managed flag.
#
# Output naming: CONFIG_TAG is p36/p36_v132plain_<src>, unique per array task and disjoint from the
# p36 v1211cand and prod arrays, so no intermediate filename is ever shared across concurrent tasks.
#
# Runner p21/2026-08-19_p21_bench_v132.R, UNMODIFIED.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc
P21=$HOME/magplot/verify/p21; P36=$HOME/magplot/verify/p36
mkdir -p $P36

export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
export INDOMAIN=1

set_src () { PFX=$1; export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv \
             T2_FILE=${PFX}_tree_t2.csv SITE_FILE=${PFX}_site_esi.csv; }

case "$SLURM_ARRAY_TASK_ID" in
  1) SRC=baxter; set_src $MS/bench_baxter ;;
  2) SRC=mef;    set_src $MS/bench_mefia_long ;;
  *) echo "bad array id"; exit 2 ;;
esac

export CONFIG_TAG=${P36}/p36_v132plain_${SRC}
export TREE_OUT=""
echo "[p36v132bm] task=$SLURM_ARRAY_TASK_ID SRC=$SRC TAG=$CONFIG_TAG"
Rscript ${P21}/2026-08-19_p21_bench_v132.R
echo "=== ${CONFIG_TAG} DONE ==="

#!/bin/bash
#SBATCH --job-name=v32_htdub
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=02:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=24G
#SBATCH --array=1-6
#SBATCH --output=/users/PUOM0008/crsfaaron/silc_cfi/v32_htdub/v32_htdub_%A_%a.out
# September 23, 2026. Height-treatment factorial for FVS-ACD, matched to Carroll's AGM v8.40
# noHTdub delivery. Tasks 1-3 measured heights retained (DUB_HT=0, reproduction of v29 treelists),
# tasks 4-6 all starting heights imputed (DUB_HT=1). Configs: v13.1 hierarchical, v14 L1, v14 L2.
# Env recipe copied from v29_run/v14/v14_silc137.slurm and ~/magplot/verify/v131_silc_full137_treeout.sbatch.
set -uo pipefail
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0 R/4.4.0
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
W=/users/PUOM0008/crsfaaron/silc_cfi/v32_htdub
V14=/users/PUOM0008/crsfaaron/silc_cfi/v29_run/v14
cd $HOME/magplot/verify
MS=$HOME/magplot/verify/multisrc
T=$SLURM_ARRAY_TASK_ID
if [ $T -le 3 ]; then export DUB_HT=0; HT=meas; else export DUB_HT=1; HT=dub; fi
C=$(( (T-1) % 3 ))
export USE_HIER_ING=TRUE USE_HIER_MORT=TRUE HIER_POSTDIR=$HOME/v13_comb_post SPLIT=TRUE
export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
export NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1
if [ $C -eq 0 ]; then
  export MODEL_FILE=$HOME/AcadianGY_13.1.r; CFG=v131hier; TAGM=FVSACD_v131_hier
else
  if [ $C -eq 1 ]; then M=L1; else M=L2; fi
  export MODEL_FILE=$V14/AcadianGY_14.0.r ACD_V14_BASE=$HOME/AcadianGY_13.1.r
  export LINKED=1 LINKED_MODE=$M LINKED_COEF=$V14/v14_coef_bundle_2026-09-08_namemap.rds
  export LINKED_SPRE=1 LINKED_JURRE=1 LINKED_MORTMULT=0
  CFG=v14${M}; TAGM=FVSACD_v14_${M}
fi
export CONFIG_TAG=v32_${CFG}_${HT}_silc_l_full137
export PAIRS_FILE=$MS/bench_silc_l_pairs_full137.csv INIT_FILE=$MS/bench_silc_l_tree_init_full137.csv
export T2_FILE=$MS/bench_silc_l_tree_t2_full137.csv SITE_FILE=$MS/bench_silc_l_site_esi_full137.csv
export TREE_OUT_PATH=$W/fvsacd_${CFG}_${HT}_full137_treelist_raw.csv
echo "[v32 $CFG $HT] MODEL_FILE=$MODEL_FILE DUB_HT=$DUB_HT"; md5sum $MODEL_FILE $W/bench_v32_htdub_treeout.R; date
Rscript $W/bench_v32_htdub_treeout.R
date
RAW_PATH=$TREE_OUT_PATH OUT_PATH=$W/fvsacd_${CFG}_${HT}_treelist.csv MODEL_TAG=${TAGM}_${HT} Rscript $V14/ingest_fvsacd_v14.R
echo "=== V32_HTDUB_${CFG}_${HT}_DONE ==="


#!/bin/bash
#SBATCH --job-name=p36gydbbax
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-3
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p36/p36gydbbax_%A_%a.out
#
# Pass 36, defect 3 retirement: Baxter rescored on a GYDB basis across all three benchmark
# configurations, to test whether the pass 35 h2_matgate adoption survives once the tree tag
# correspondence is correct. The staged Baxter tree lists link 4,969 trees between occasions, of
# which 2,352 (47.3 percent) shrink in diameter and 3,094 change species, which is a broken
# within-stand tag correspondence, not biology. GYDB repairs it to 74 of 3,582 (2.1 percent) and 98
# species changes. Baxter is the source where h1 is inert, so it is the only cell where the
# maturity gate acts alone, making this the load-bearing rescore for the pass 35 decision.
#
# Inputs are gen_baxter/gydb_baxter_{tree_init,tree_t2,pairs,site_esi}.csv from
# 2026-08-26_p36_gydb_generate.py against the current ALL_Standardized.sqlite (predates the
# dataset-9/10 NS reload, which does not touch Baxter's tag correspondence).
#
# Every lever below is byte-identical, task for task, to the source it is cloned from:
# task 1 to 2026-08-26_p36_v1211cand_baxter.sbatch, task 2 to 2026-08-26_p36_v132plain_bax_mef.sbatch
# task 1, task 3 to 2026-08-26_p36_prod_array.sbatch's shared preamble plus its task 11 (baxter)
# branch, including the P33_MATGATE / MATGATE_QC / MATGATE_K levers that first submission of this
# job omitted (caught before it ran past 10 seconds, cancelled as 13977312, resubmitted here).
# CONFIG_TAG is namespaced p36gydb_, disjoint from every existing p36 tag.
set -euo pipefail
source /etc/profile.d/lmod.sh
module purge

HOME_V=$HOME
P36=$HOME_V/magplot/verify/p36
GB=$P36/gen_baxter
export PAIRS_FILE=$GB/gydb_baxter_pairs.csv
export INIT_FILE=$GB/gydb_baxter_tree_init.csv
export T2_FILE=$GB/gydb_baxter_tree_t2.csv
export SITE_FILE=$GB/gydb_baxter_site_esi.csv
export TREE_OUT=""

case "$SLURM_ARRAY_TASK_ID" in
  1)
    module load gcc/12.3.0 R/4.4.0
    export FROZEN_MODULES_LOADED=1
    export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-8}
    export R_DATATABLE_NUM_THREADS=${SLURM_CPUS_PER_TASK:-8}
    export MODEL_FILE=$HOME_V/_scripts/AcadianGY_12.11.r
    export SPLIT=TRUE
    export V1211_IGMULT=2.5
    export V1211_MORTGATE=TRUE
    export V1211_STANDCON=TRUE
    export SC_LO=0.40 SC_HI=0.50 SC_QMIN=22
    export V1211_DHTHW=TRUE
    export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
    export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
    export NB_AFAC=0.579 QC_AFAC=0.111
    export INDOMAIN=1
    export V1211_MANAGED=FALSE
    export CONFIG_TAG=${P36}/p36gydb_v1211cand_baxter
    cd $HOME_V/magplot/verify
    echo "[p36gydbbax] task=1 cfg=v1211cand SRC=baxter(gydb) TAG=$CONFIG_TAG"
    Rscript $HOME_V/magplot/verify/bench_parity_split_ms_v1211.R
    ;;
  2)
    module load gcc/12.3.0 R/4.5.2
    export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
    export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
    export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME_V/v13_kickoff SPLIT=TRUE
    export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
    export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
    export MODEL_FILE=$HOME_V/magplot/verify/p4e/model_b0b1b2.r
    export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
    export ONSET=0.55 IMULT=2.5
    export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
    export V132=1
    export INDOMAIN=1
    export CONFIG_TAG=${P36}/p36gydb_v132plain_baxter
    cd $HOME_V/magplot/verify
    echo "[p36gydbbax] task=2 cfg=v132plain SRC=baxter(gydb) TAG=$CONFIG_TAG"
    Rscript $HOME_V/magplot/verify/p21/2026-08-19_p21_bench_v132.R
    ;;
  3)
    module load gcc/12.3.0 R/4.5.2
    export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
    export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
    export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME_V/v13_kickoff SPLIT=TRUE
    export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
    export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
    export MODEL_FILE=$HOME_V/magplot/verify/p4e/model_b0b1b2.r
    export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
    export ONSET=0.55 IMULT=2.5
    export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
    export V132=1
    export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
    export P33_MATGATE=TRUE MATGATE_QC=12.7 MATGATE_K=0.6
    export INDOMAIN=1
    export V1211_MANAGED=FALSE
    export CONFIG_TAG=${P36}/p36gydb_prod_baxter
    cd $HOME_V/magplot/verify
    echo "[p36gydbbax] task=3 cfg=prod_h2matgate SRC=baxter(gydb) TAG=$CONFIG_TAG"
    Rscript $HOME_V/magplot/verify/p33/2026-08-26_p33-matgate-runner.R
    ;;
  *) echo "bad array id"; exit 2 ;;
esac
echo "=== ${CONFIG_TAG} DONE ==="


#!/bin/bash
#SBATCH --job-name=p37accept
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-4
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p37/p37accept_%A_%a.out
#
# p37 ACCEPTANCE TEST for the calc_ddbh vectorization fix, 27 August 2026.
#
# Reruns silc_l and baxter under USE_MODS=TRUE against the FIXED engines and checks the scored and
# failed stand counts return to the full population. The USE_MODS=FALSE control (job 13982126)
# established the target: silc_l 73 scored / 0 failed, baxter 91 scored / 0 failed. With the lever ON
# against the PRE-fix engines (jobs 13981173 / 13981174) the same two sources returned silc_l 14 / 59
# and baxter 3 / 88, because every hardwood-bearing stand errored inside calc_ddbh and was silently
# discarded by the runner's per-stand tryCatch.
#
# Every lever export below is copied verbatim from scripts/p36/2026-08-26_pv133_prodhw_array.sbatch
# and its candidate twin, not reconstructed. The only changes are the array mapping (four tasks =
# two arms x two sources), the MODEL_FILE selection per arm, and the CONFIG_TAG namespace, which is
# p37/p37acc_<arm>_<src>, disjoint from every p_v133, p36, p35, p33 and p21 tag. No two tasks in
# this array ever write the same path.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc; P5M=$HOME/magplot/verify/p5m
P33=$HOME/magplot/verify/p33; P37=$HOME/magplot/verify/p37
mkdir -p $P37

export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
export P33_MATGATE=TRUE MATGATE_QC=12.7 MATGATE_K=0.6
export USE_MODS=TRUE

QC_ESI=/fs/scratch/PUOM0008/crsfaaron/canada/qc_esi/magp_qcnb_site_esi8_v2.csv
INDOMAIN=1

case "$SLURM_ARRAY_TASK_ID" in
  1) ARM=prodhw; SRC=silc_l; PFX=$MS/bench_silc_l ; MANAGED=TRUE  ;;
  2) ARM=prodhw; SRC=baxter; PFX=$MS/bench_baxter ; MANAGED=FALSE ;;
  3) ARM=cand;   SRC=silc_l; PFX=$MS/bench_silc_l ; MANAGED=TRUE  ;;
  4) ARM=cand;   SRC=baxter; PFX=$MS/bench_baxter ; MANAGED=FALSE ;;
  *) echo "bad array id"; exit 2 ;;
esac

if [ "$ARM" = "prodhw" ]; then
  export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
else
  export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2_v133.r
fi

export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv T2_FILE=${PFX}_tree_t2.csv
export SITE_FILE=${PFX}_site_esi.csv
export INDOMAIN=$INDOMAIN
export V1211_MANAGED=$MANAGED
export CONFIG_TAG=${P37}/p37acc_${ARM}_${SRC}
export TREE_OUT=""
echo "[p37accept] task=$SLURM_ARRAY_TASK_ID ARM=$ARM SRC=$SRC MANAGED=$MANAGED TAG=$CONFIG_TAG MODEL_FILE=$MODEL_FILE USE_MODS=$USE_MODS"
Rscript $P33/2026-08-26_p33-matgate-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

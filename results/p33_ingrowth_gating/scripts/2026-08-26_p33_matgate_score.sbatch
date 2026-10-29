#!/bin/bash
#SBATCH --job-name=p33score
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-5
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p33/p33score_%A_%a.out
# Pass 33 short-interval regression check: h1_v132_mortgate PLUS the pass 33 maturity gate
# (ops$use.ingrowth.matgate, qc=12.7 cm, k=0.6), scored on the same GYDB pair sets the pass 31
# adoption decision rests on. Every env var below is copied verbatim from pass 24's
# merge_v24/2026-08-21_merge-v24-hybrids.sbatch hybrid h1 block; the ONLY additions are
# P33_MATGATE=TRUE and the MATGATE_* parameters. Comparison baseline is the existing
# merge_v24/h1_v132_mortgate_<src>_results.csv, not a rerun, so a difference here is
# attributable to the gate alone.
# Sources: baxter, ctrn, nb (yields NB and QC by PROV), ns_managed, ns_unmanaged.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify
MS=$HOME/magplot/verify/multisrc
P33=$HOME/magplot/verify/p33

export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export IMULT=2.5
export V132=1
export TREE_OUT=""
# h1 lever block, verbatim from pass 24 hybrid 1
export ONSET=0.55 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
# pass 33 addition
export P33_MATGATE=TRUE MATGATE_QC=12.7 MATGATE_K=0.6
HTAG=h2_matgate

unset PAIRS_OVR INIT_OVR T2_OVR SITE_OVR || true
INDOMAIN=1
case "$SLURM_ARRAY_TASK_ID" in
  1) SRC=baxter;       PFX=$MS/bench_baxter;                MANAGED=FALSE ;;
  2) SRC=ctrn;         PFX=$MS/bench_ctrn;                  MANAGED=TRUE  ;;
  3) SRC=nb;           PFX=$HOME/magplot/verify/magp_qcnb;  MANAGED=TRUE ; SITE_OVR=${PFX}_site_esi8.csv ;;
  4) SRC=ns_managed;   PAIRS_OVR=$MS/bench_ns_pairs_managed.csv;   INIT_OVR=$MS/bench_ns_tree_init.csv; T2_OVR=$MS/bench_ns_tree_t2.csv; SITE_OVR=$MS/bench_ns_site_esi.csv; MANAGED=TRUE;  INDOMAIN=0 ;;
  5) SRC=ns_unmanaged; PAIRS_OVR=$MS/bench_ns_pairs_unmanaged.csv; INIT_OVR=$MS/bench_ns_tree_init.csv; T2_OVR=$MS/bench_ns_tree_t2.csv; SITE_OVR=$MS/bench_ns_site_esi.csv; MANAGED=FALSE; INDOMAIN=0 ;;
  *) echo "bad source id"; exit 2 ;;
esac

if [ -n "${PAIRS_OVR:-}" ]; then
  export PAIRS_FILE=$PAIRS_OVR INIT_FILE=$INIT_OVR T2_FILE=$T2_OVR SITE_FILE=$SITE_OVR
else
  export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv T2_FILE=${PFX}_tree_t2.csv
  export SITE_FILE=${SITE_OVR:-${PFX}_site_esi.csv}
fi
export INDOMAIN=$INDOMAIN
export V1211_MANAGED=$MANAGED
export CONFIG_TAG=$P33/${HTAG}_${SRC}
echo "[p33score] task=$SLURM_ARRAY_TASK_ID src=$SRC managed=$MANAGED indomain=$INDOMAIN tag=$CONFIG_TAG"
Rscript $P33/2026-08-26_p33-matgate-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

#!/bin/bash
#SBATCH --job-name=mv24hyb
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-20
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/merge_v24/mv24hyb_%A_%a.out
# Pass 24 config merge: four hybrids of the v13.2 stack with v12.11 levers restored, scored on
# baxter, ctrn, nb (yields NB and QC by PROV), ns_managed, ns_unmanaged. Runner is
# merge_v24/2026-08-21_merge-v24-runner_WIP.R (p21 v13.2 harness + MERGE_V24 lever block;
# verified byte-identical to p21/2026-08-19_p21_bench_v132.R outside the block).
# Hybrid definitions (v13.2 ship18 base config unless stated):
#   h1_v132_mortgate        v13.2 + lever 2 (mort.dens.scale, managed-gated, fmin .13 k 12.4 rd0 .38)
#   h2_v132_dhthw           v13.2 + lever 4 (hardwood form/risk height modifier)
#   h3_v132_mortgate_dhthw  v13.2 + levers 2 and 4
#   h4_v132_full1211        h3 + v12.11 tunings: ONSET 0.30, standcon lo .40 hi .50 qmin 22
# Model of record ~/AcadianGY_13.1.r UNMODIFIED throughout.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify
MS=$HOME/magplot/verify/multisrc
MV=$HOME/magplot/verify/merge_v24

# ---- v13.2 stack, identical to p21ship (pass 21) ----
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export IMULT=2.5
export V132=1
export TREE_OUT=""

HY=$(( (SLURM_ARRAY_TASK_ID - 1) / 5 + 1 ))
SRCID=$(( (SLURM_ARRAY_TASK_ID - 1) % 5 + 1 ))

case "$HY" in
  1) HTAG=h1_v132_mortgate;       export ONSET=0.55 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18 V1211_MORTGATE=TRUE  V1211_DHTHW=FALSE ;;
  2) HTAG=h2_v132_dhthw;          export ONSET=0.55 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18 V1211_MORTGATE=FALSE V1211_DHTHW=TRUE  ;;
  3) HTAG=h3_v132_mortgate_dhthw; export ONSET=0.55 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18 V1211_MORTGATE=TRUE  V1211_DHTHW=TRUE  ;;
  4) HTAG=h4_v132_full1211;       export ONSET=0.30 LEV3=1 LEV3_LO=0.40 LEV3_HI=0.50 LEV3_QMIN=22 V1211_MORTGATE=TRUE  V1211_DHTHW=TRUE  ;;
  *) echo "bad hybrid id"; exit 2 ;;
esac

unset PAIRS_OVR INIT_OVR T2_OVR SITE_OVR || true
INDOMAIN=1
case "$SRCID" in
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
export CONFIG_TAG=$MV/${HTAG}_${SRC}
echo "[mv24hyb] task=$SLURM_ARRAY_TASK_ID hybrid=$HTAG src=$SRC managed=$MANAGED indomain=$INDOMAIN tag=$CONFIG_TAG"
Rscript $MV/2026-08-21_merge-v24-runner_WIP.R
echo "=== ${CONFIG_TAG} DONE ==="

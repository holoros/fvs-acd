#!/bin/bash
#SBATCH --job-name=p38fiaon
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-12
#SBATCH --time=24:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p38/p38fiaon_%A_%a.out
#
# PASS 38, 27 August 2026. Sugar maple FIA survival modifier benchmark, ARM ON.
# Derived from scripts/p37/2026-08-27_p37_cand_array.sbatch with every lever export identical.
# Three deliberate differences and nothing else:
#   1. USE_HW_SURV_FIA=TRUE, the new sub-flag, consumed by the p38 runner as
#      ops$use.hw.surv.fia. The engine gates the SM modifier behind use.hw.mod AND this flag.
#   2. CONFIG_TAG namespace p38/p38_fiaon_<src>, disjoint from every p37/p36/p33/p21 tag.
#   3. Rscript points at the p38 runner, a copy of the p33 runner whose single change is
#      reading USE_HW_SURV_FIA from the environment (default FALSE).
# The BASELINE arm of this benchmark is p37's candidate arm (p37_cand_<src>), which ran the
# byte-identical engine lineage with the SM patch's flag off; the p38 unit probe proves the
# OFF state multiplies tsurv by exactly 1 on every row, and the off-state acceptance job
# additionally proves byte-identical result files on silc_l and baxter. The only rows that can
# differ between p37_cand and this arm are sugar maple, which is the isolation property under
# test. Engine: ~/AcadianGY_13.3.r (post p37 vectorization fixes, post SM wiring) via
# model_b0b1b2_v133.r. use.hw.mod is ON (USE_MODS=TRUE) in both arms.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc; P5M=$HOME/magplot/verify/p5m
P38=$HOME/magplot/verify/p38
mkdir -p $P38

export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2_v133.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
export P33_MATGATE=TRUE MATGATE_QC=12.7 MATGATE_K=0.6
export USE_MODS=TRUE
export USE_HW_SURV_FIA=TRUE

QC_ESI=/fs/scratch/PUOM0008/crsfaaron/canada/qc_esi/magp_qcnb_site_esi8_v2.csv
INDOMAIN=1

case "$SLURM_ARRAY_TASK_ID" in
  1)  SRC=memat;             PFX=$P5M/p5m_memat ;                                                                                                                                                                         MANAGED=FALSE ;;
  2)  SRC=medev;             PFX=$P5M/p5m_medev ;                                                                                                                                                                         MANAGED=FALSE ;;
  3)  SRC=pef;               PFX=$MS/bench_pef ;                                                                                                                                                                          MANAGED=FALSE ;;
  4)  SRC=ctrn;              PFX=$MS/bench_ctrn ;                                                                                                                                                                          MANAGED=TRUE  ;;
  5)  SRC=silc_l;            PFX=$MS/bench_silc_l ;                                                                                                                                                                        MANAGED=TRUE  ;;
  6)  SRC=nb_v2;             PFX=$HOME/magplot/verify/magp_qcnb; SITE_OVR=$QC_ESI ;                                                                                                                                        MANAGED=TRUE  ;;
  7)  SRC=ns_managed;        PAIRS_OVR=$MS/bench_ns_pairs_managed.csv;                   INIT_OVR=$MS/bench_ns_tree_init.csv;      T2_OVR=$MS/bench_ns_tree_t2.csv;      SITE_OVR=$MS/bench_ns_site_esi.csv;      INDOMAIN=0; MANAGED=TRUE  ;;
  8)  SRC=ns_unmanaged;      PAIRS_OVR=$MS/bench_ns_pairs_unmanaged.csv;                 INIT_OVR=$MS/bench_ns_tree_init.csv;      T2_OVR=$MS/bench_ns_tree_t2.csv;      SITE_OVR=$MS/bench_ns_site_esi.csv;      INDOMAIN=0; MANAGED=FALSE ;;
  9)  SRC=ns_long_managed;   PAIRS_OVR=$MS/bench_ns_long_pairs_managed_singleregime.csv; INIT_OVR=$MS/bench_ns_long_tree_init.csv; T2_OVR=$MS/bench_ns_long_tree_t2.csv; SITE_OVR=$MS/bench_ns_long_site_esi.csv; INDOMAIN=0; MANAGED=TRUE  ;;
  10) SRC=ns_long_unmanaged; PAIRS_OVR=$MS/bench_ns_long_pairs_unmanaged.csv;            INIT_OVR=$MS/bench_ns_long_tree_init.csv; T2_OVR=$MS/bench_ns_long_tree_t2.csv; SITE_OVR=$MS/bench_ns_long_site_esi.csv; INDOMAIN=0; MANAGED=FALSE ;;
  11) SRC=baxter;            PFX=$MS/bench_baxter ;                                                                                                                                                                        MANAGED=FALSE ;;
  12) SRC=mef;               PFX=$MS/bench_mefia_long ;                                                                                                                                                                    MANAGED=FALSE ;;
  *) echo "bad array id"; exit 2 ;;
esac

if [ -n "${PAIRS_OVR:-}" ]; then
  export PAIRS_FILE=$PAIRS_OVR INIT_FILE=$INIT_OVR T2_FILE=$T2_OVR SITE_FILE=$SITE_OVR
else
  export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv T2_FILE=${PFX}_tree_t2.csv
  export SITE_FILE=${SITE_OVR:-${PFX}_site_esi.csv}
fi
export INDOMAIN=$INDOMAIN
export V1211_MANAGED=$MANAGED
export CONFIG_TAG=${P38}/p38_fiaon_${SRC}
export TREE_OUT=""
echo "[p38fiaon] task=$SLURM_ARRAY_TASK_ID SRC=$SRC INDOMAIN=$INDOMAIN MANAGED=$MANAGED TAG=$CONFIG_TAG MODEL_FILE=$MODEL_FILE USE_MODS=$USE_MODS USE_HW_SURV_FIA=$USE_HW_SURV_FIA"
echo "[p38fiaon] PAIRS=$PAIRS_FILE INIT=$INIT_FILE T2=$T2_FILE SITE=$SITE_FILE"
Rscript $P38/2026-08-27_p38-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

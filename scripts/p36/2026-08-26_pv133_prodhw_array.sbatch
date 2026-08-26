#!/bin/bash
#SBATCH --job-name=pv133prodhw
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-12
#SBATCH --time=08:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p_v133/pv133prodhw_%A_%a.out
#
# v13.3 benchmark, ARM A (baseline comparator): current production (h2_matgate, the pass-35-adopted
# default: h1_v132_mortgate plus h2_matgate) with ops$use.hw.mod switched ON. This is NOT the shipped
# production default as-is (which leaves use.hw.mod at its default FALSE, per
# 2026-08-26_p36_prod_array.sbatch and 2026-08-26_p35ship_matgatedefault.sbatch, neither of which
# exports USE_MODS). It is the correct comparator for THIS test: Aaron's brief states the v13.3
# gap-fill "only touches AB, WA, SM, so sources with none of those three species will be identical
# between the two configurations by construction". That is only true if the pre-existing six-species
# Castle modifier (RO/SM/YB/RM/PB/QA growth, QA/RM/RO/YB/PB survival) is turned ON identically in
# both arms; if this arm left use.hw.mod OFF while the v13.3 arm turned it ON, every one of those six
# species would also differ, which is not what is being tested here and is not what the brief
# describes. Holding use.hw.mod ON in both arms isolates exactly the AB/WA growth and (absent) SM
# survival gap-fill contribution, with every other production lever (matgate, mortgate, ingrowth,
# etc.) untouched from the exact shipped defaults. Documented explicitly rather than silently chosen.
#
# Every other export below is byte-identical to 2026-08-26_p36_prod_array.sbatch (itself documented
# there as byte-identical to the shipped 2026-08-26_p35ship_matgatedefault.sbatch pair), including the
# NB/QC nb_v2 site-file fix and the twelve-source uniform rerun. Same 12-source case statement, same
# runner (p33/2026-08-26_p33-matgate-runner.R, UNMODIFIED), same R/4.5.2 toolchain.
#
# Model of record: MODEL_FILE=p4e/model_b0b1b2.r, the exact production overlay (sources
# AcadianGY_13.1.r, UNMODIFIED, then patches only ddbh()'s b0/b1/b2; ddbh_hw_mod/tsurv_hw_mod come
# from the unmodified base). Output naming: CONFIG_TAG is p_v133/pv133_prodhw_<src>, unique per
# array task and disjoint from every p36/p33/p21 tag and from the v133 candidate arm's
# p_v133/pv133_cand_<src> tag below.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc; P5M=$HOME/magplot/verify/p5m
P33=$HOME/magplot/verify/p33; PV133=$HOME/magplot/verify/p_v133
mkdir -p $PV133

export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
export P33_MATGATE=TRUE MATGATE_QC=12.7 MATGATE_K=0.6
export USE_MODS=TRUE
# NOTE: MODEL_FILE above (p4e/model_b0b1b2.r) is the exact production overlay: it sources
# AcadianGY_13.1.r, UNMODIFIED, then patches only ddbh()'s b0/b1/b2. ddbh_hw_mod/tsurv_hw_mod come
# from the sourced AcadianGY_13.1.r untouched.

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
export CONFIG_TAG=${PV133}/pv133_prodhw_${SRC}
export TREE_OUT=""
echo "[pv133prodhw] task=$SLURM_ARRAY_TASK_ID SRC=$SRC INDOMAIN=$INDOMAIN MANAGED=$MANAGED TAG=$CONFIG_TAG MODEL_FILE=$MODEL_FILE USE_MODS=$USE_MODS"
echo "[pv133prodhw] PAIRS=$PAIRS_FILE INIT=$INIT_FILE T2=$T2_FILE SITE=$SITE_FILE"
Rscript $P33/2026-08-26_p33-matgate-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

#!/bin/bash
#SBATCH --job-name=p36prod
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-12
#SBATCH --time=08:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p36/p36prod_%A_%a.out
#
# Pass 36, column C of the three-model benchmark: CURRENT PRODUCTION, meaning the pass 31 default
# h1_v132_mortgate and the pass 35 default h2_matgate together, which is the configuration
# 2026-08-26_p35ship_matgatedefault.sbatch and its bax_mef companion ship. Every export below is
# byte-identical to that pair, with two deliberate departures documented here.
#
# Departure one, and the reason this array reruns all twelve cells rather than the eight the
# pre-flight inventory called missing. Only five h2_matgate result files exist, they were produced
# by the pass 33 scoring battery rather than by the pass 35 production sbatch, and one of the five
# sits at the stale 733 row NB-only basis. Reusing them would put the production column of a
# manuscript table on two different provenances and one wrong basis. Twelve tasks run in parallel,
# so the uniform rerun costs wall clock equal to the slowest single source, not twelve times
# anything, and it buys one provenance for the column the manuscript's claim actually rests on.
# The five pass 33 files stay on disk untouched as an independent reproducibility check.
#
# Departure two, the NB and QC site file. Task 6 in the pass 31 and pass 35 batteries points at
# magp_qcnb_site_esi8.csv, which predates the QC ESI fill. The current NB plus QC basis is
# magp_qcnb_pairs.csv at 2,555 pairs against magp_qcnb_site_esi8_v2.csv, the site file
# 2026-08-25_p21_nbqc_v2.sbatch used to build p9_v132_nb_v2_results.csv and the file the reused
# plain v13.2 cell therefore sits on. Leaving the old site file in place here would silently put
# the production column on a different site basis from the v13.2 column at NB and QC, which is
# precisely the kind of cross-column basis mismatch the observed-basis gate exists to catch, so it
# is fixed at the source instead. The source is named nb_v2 for that reason.
#
# Output naming: CONFIG_TAG is p36/p36_prod_<src>, unique per array task and disjoint from the p36
# v1211cand and v132plain arrays. No task writes a shared intermediate and renames afterward.
#
# MEFIA_L (task 12) is also being scored separately under the pass 35 tag matgatedefault_v132_mef
# by task 2 of 2026-08-26_p35ship_matgatedefault_bax_mef.sbatch, which closes the one gap in the
# pass 35 adoption evidence. The two runs are the same configuration under different tags, so they
# double as a reproducibility check on the production column.
#
# Model of record $HOME/AcadianGY_13.1.r, UNMODIFIED. Both ops$mort.dens.scale and
# ops$use.ingrowth.matgate stay default FALSE in the engine and are switched on here.
# Runner p33/2026-08-26_p33-matgate-runner.R, UNMODIFIED, since it is the only runner that wires
# P33_MATGATE, MATGATE_QC and MATGATE_K through to ops$use.ingrowth.matgate.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc; P5M=$HOME/magplot/verify/p5m
P33=$HOME/magplot/verify/p33; P36=$HOME/magplot/verify/p36
mkdir -p $P36

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
export CONFIG_TAG=${P36}/p36_prod_${SRC}
export TREE_OUT=""
echo "[p36prod] task=$SLURM_ARRAY_TASK_ID SRC=$SRC INDOMAIN=$INDOMAIN MANAGED=$MANAGED TAG=$CONFIG_TAG"
echo "[p36prod] PAIRS=$PAIRS_FILE INIT=$INIT_FILE T2=$T2_FILE SITE=$SITE_FILE"
Rscript $P33/2026-08-26_p33-matgate-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

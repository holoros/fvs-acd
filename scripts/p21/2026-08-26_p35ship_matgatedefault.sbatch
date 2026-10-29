#!/bin/bash
#SBATCH --job-name=p35matgatedef
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-10
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p21/p35matgatedef_%A_%a.out
# Pass 35: production config with the pass 33 maturity-gated ingrowth release
# (ops$use.ingrowth.matgate) adopted as the default ON TOP OF the pass 31 h1_v132_mortgate default,
# same 10-task battery 2026-08-25_p21ship_h1default.sbatch scores (memat, medev, pef, ctrn, silc_l,
# nb, ns_managed, ns_unmanaged, ns_long_managed, ns_long_unmanaged), per Aaron's decision
# 26 August 2026 on the pass 34 evidence (results/gydb/README.md, Pass 35 section). The gate is
# short-interval neutral across the five sources measured in pass 33, worst regression NS unmanaged
# at +0.078 RMSE points against a 0.5 point adoption gate with three of five improving, and it
# returns a perfect site response (rho +1.00) at all six sources in the pass 34 controlled csi
# ladder against four of six under production. Baxter and MEFIA_L (mef) are the companion
# 2026-08-26_p35ship_matgatedefault_bax_mef.sbatch, parallel to how the pass 31 pair splits.
#
# This is a config artifact and documentation trail, not a rerun, exactly as the pass 31 pair was.
# The pass 33 short-interval battery already produced h2_matgate result files on Cardinal at
# ~/magplot/verify/p33/ (h2_matgate_{baxter,ctrn,nb,ns_managed,ns_unmanaged}_results.csv), so
# submitting this array is not required to establish the pass 35 verdict. Kept runnable so a future
# full rebuild has a matgate-default battery to resubmit directly.
#
# Runner is scripts/p33/2026-08-26_p33-matgate-runner.R, which is the merge_v24 runner (v13.2
# harness plus the MERGE_V24 V1211_* lever block) plus the P33_MATGATE env-lever block, since only
# that runner wires P33_MATGATE / MATGATE_QC / MATGATE_K to ops$use.ingrowth.matgate. Every other
# environment variable, source mapping, and V1211_MANAGED assignment below is byte-identical to
# 2026-08-25_p21ship_h1default.sbatch, so the only configuration difference between the pass 31
# default and the pass 35 default is the three MATGATE exports.
# CONFIG_TAG is namespaced matgatedefault_v132_<src> so output files never collide with the pass 31
# h1default_v132_<src> files or the p9_v132_<src> v13.2 baseline files, both of which stay on disk
# as comparison references.
# Model of record ~/AcadianGY_13.1.r UNMODIFIED: ops$use.ingrowth.matgate stays default FALSE in the
# engine, exactly as ops$mort.dens.scale does, and the production sbatch turns it on.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc; P5M=$HOME/magplot/verify/p5m
P21=$HOME/magplot/verify/p21; P33=$HOME/magplot/verify/p33
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
INDOMAIN=1
case "$SLURM_ARRAY_TASK_ID" in
  1)  SRC=memat;             PFX=$P5M/p5m_memat ;                                                        MANAGED=FALSE ;;
  2)  SRC=medev;             PFX=$P5M/p5m_medev ;                                                        MANAGED=FALSE ;;
  3)  SRC=pef;               PFX=$MS/bench_pef ;                                                         MANAGED=FALSE ;;
  4)  SRC=ctrn;              PFX=$MS/bench_ctrn ;                                                        MANAGED=TRUE  ;;
  5)  SRC=silc_l;            PFX=$MS/bench_silc_l ;                                                      MANAGED=TRUE  ;;
  6)  SRC=nb;                PFX=$HOME/magplot/verify/magp_qcnb; SITE_OVR=${PFX}_site_esi8.csv ;         MANAGED=TRUE  ;;
  7)  SRC=ns_managed;        PAIRS_OVR=$MS/bench_ns_pairs_managed.csv;               INIT_OVR=$MS/bench_ns_tree_init.csv;      T2_OVR=$MS/bench_ns_tree_t2.csv;      SITE_OVR=$MS/bench_ns_site_esi.csv;      INDOMAIN=0; MANAGED=TRUE  ;;
  8)  SRC=ns_unmanaged;      PAIRS_OVR=$MS/bench_ns_pairs_unmanaged.csv;             INIT_OVR=$MS/bench_ns_tree_init.csv;      T2_OVR=$MS/bench_ns_tree_t2.csv;      SITE_OVR=$MS/bench_ns_site_esi.csv;      INDOMAIN=0; MANAGED=FALSE ;;
  9)  SRC=ns_long_managed;   PAIRS_OVR=$MS/bench_ns_long_pairs_managed_singleregime.csv; INIT_OVR=$MS/bench_ns_long_tree_init.csv; T2_OVR=$MS/bench_ns_long_tree_t2.csv; SITE_OVR=$MS/bench_ns_long_site_esi.csv; INDOMAIN=0; MANAGED=TRUE  ;;
  10) SRC=ns_long_unmanaged; PAIRS_OVR=$MS/bench_ns_long_pairs_unmanaged.csv;        INIT_OVR=$MS/bench_ns_long_tree_init.csv; T2_OVR=$MS/bench_ns_long_tree_t2.csv; SITE_OVR=$MS/bench_ns_long_site_esi.csv; INDOMAIN=0; MANAGED=FALSE ;;
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
export CONFIG_TAG=${P21}/matgatedefault_v132_${SRC}
export TREE_OUT=""
echo "[p35matgatedef] task=$SLURM_ARRAY_TASK_ID SRC=$SRC INDOMAIN=$INDOMAIN MANAGED=$MANAGED TAG=$CONFIG_TAG"
Rscript $P33/2026-08-26_p33-matgate-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

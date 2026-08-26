#!/bin/bash
#SBATCH --job-name=p21h1default
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-10
#SBATCH --time=06:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p21/p21h1default_%A_%a.out
# Pass 31: production config with h1_v132_mortgate (density-dependent mortality scaling, gated on
# the managed flag) adopted as the default, same 10-task battery p21ship_full.sbatch scores
# (memat, medev, pef, ctrn, silc_l, nb, ns_managed, ns_unmanaged, ns_long_managed,
# ns_long_unmanaged), per Aaron's direct decision 25 August 2026 after reviewing pass 30's verdict
# (results/gydb/README.md, Pass 31 section). h1 never loses to v13.2 on RMSE at any of the 11
# sources tested to date (7 non-Canadian in pass 24, 4 Canadian in pass 30). QC's bias increase
# and the NS/NS_LONG slope inversion are documented, accepted tradeoffs, not blockers. Baxter and
# MEFIA_L (mef) are the companion 2026-08-25_p21ship_h1default_bax_mef.sbatch, parallel to how
# p21ship_bax_mef.sbatch splits from p21ship_full.sbatch today.
#
# This is a config artifact and documentation trail, not a rerun. Every one of these 10 tasks
# already has a matching h1_v132_mortgate result file on Cardinal from pass 24
# (~/magplot/verify/merge_v24/h1_v132_mortgate_{memat,medev,pef,ctrn,silc_l,nb}_results.csv,
# h1_v132_mortgate_ns_{managed,unmanaged}_results.csv) or pass 30
# (h1_v132_mortgate_ns_long_managed_singleregime_results.csv,
# h1_v132_mortgate_ns_long_unmanaged_results.csv), so submitting this array is not required to
# establish the pass 31 verdict. Kept runnable so a future full rebuild has an h1-default battery
# to resubmit directly.
#
# Runner is scripts/gydb/merge_v24/2026-08-21_merge-v24-runner.R (the p21 v13.2 harness plus the
# MERGE_V24 V1211_* lever block, byte-identical to 2026-08-19_p21_bench_v132.R outside that block),
# not the plain v13.2 harness p21ship_full.sbatch calls, since only the merge_v24 runner wires the
# V1211_MORTGATE env lever to ops$mort.dens.scale. V1211_MANAGED is set per task to match exactly
# how pass 24 and pass 30 scored each source under h1 (mv24hyb/mv24ext job logs and the pass30
# rerun sbatch), not guessed: TRUE for ctrn, silc_l, nb (and QC, carried via nb's PROV split),
# ns_managed, and ns_long_managed; FALSE for memat, medev, pef, ns_unmanaged, and ns_long_unmanaged.
# CONFIG_TAG is namespaced h1default_v132_<src> so output files never collide with the existing
# p9_v132_<src> v13.2 baseline files, which stay on disk as the comparison reference.
# Model of record ~/AcadianGY_13.1.r UNMODIFIED.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc; P5M=$HOME/magplot/verify/p5m
P21=$HOME/magplot/verify/p21; MV=$HOME/magplot/verify/merge_v24
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
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
export CONFIG_TAG=${P21}/h1default_v132_${SRC}
export TREE_OUT=""
echo "[p21h1default] task=$SLURM_ARRAY_TASK_ID SRC=$SRC INDOMAIN=$INDOMAIN MANAGED=$MANAGED TAG=$CONFIG_TAG"
Rscript $MV/2026-08-21_merge-v24-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

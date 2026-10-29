#!/bin/bash
#SBATCH --job-name=pass30h1
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-4
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p21/pass30h1_%A_%a.out
# Pass 30: rerun h1_v132_mortgate (pass 24's merge-v24 hybrid 1, mort.dens.scale gated on
# stand.managed, fmin/k/rd0 defaults .13/12.4/.38) against the CURRENT, wider Canadian pair
# coverage that postdates pass 24's own h1 sweep: NB+QC v2 (magp_qcnb_site_esi8_v2.csv, 2547
# rows) and the newly closed NS_LONG multi-regime slice (176 rows), plus NS_LONG's pre-existing
# managed-singleregime and unmanaged slices, which pass 24 never scored under h1 at all. NS
# managed/unmanaged are NOT rerun here: merge_v24/h1_v132_mortgate_ns_{managed,unmanaged}_results.csv
# already match the current p21 baseline pair coverage exactly (row counts and STAND id sets both
# diff clean against p21/p9_v132_ns_{managed,unmanaged}_results.csv, checked 2026-08-25) and are
# reused as-is. Same v13.2 stack as p21ship_full.sbatch / merge_v24 hybrids sbatch, same MERGE_V24
# lever block, same runner (byte-identical to p21/2026-08-19_p21_bench_v132.R outside that block).
# Model of record ~/AcadianGY_13.1.r UNMODIFIED.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify
MS=$HOME/magplot/verify/multisrc
MV=$HOME/magplot/verify/merge_v24
P21=$HOME/magplot/verify/p21

# ---- v13.2 stack, identical to p21ship_full.sbatch / merge_v24 hybrids sbatch ----
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export IMULT=2.5
export V132=1
export TREE_OUT=""

# ---- h1_v132_mortgate lever, identical to merge_v24 hybrids sbatch case HY=1 ----
export ONSET=0.55 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
# MORT_FMIN/MORT_K/MORT_RD0 left unset so the lever block's defaults (.13/12.4/.38) apply,
# exactly as pass 24's hybrids sbatch did.

case "$SLURM_ARRAY_TASK_ID" in
  1) SRC=nb_v2
     PAIRS=$HOME/magplot/verify/magp_qcnb_pairs.csv
     INIT=$HOME/magplot/verify/magp_qcnb_tree_init.csv
     T2=$HOME/magplot/verify/magp_qcnb_tree_t2.csv
     SITE=/fs/scratch/PUOM0008/crsfaaron/canada/qc_esi/magp_qcnb_site_esi8_v2.csv
     INDOMAIN=1; MANAGED=TRUE
     TAG=$MV/h1_v132_mortgate_nb_v2
     ;;
  2) SRC=ns_long_managed_singleregime
     PAIRS=$MS/bench_ns_long_pairs_managed_singleregime.csv
     INIT=$MS/bench_ns_long_tree_init.csv
     T2=$MS/bench_ns_long_tree_t2.csv
     SITE=$MS/bench_ns_long_site_esi.csv
     INDOMAIN=0; MANAGED=TRUE
     TAG=$MV/h1_v132_mortgate_ns_long_managed_singleregime
     ;;
  3) SRC=ns_long_unmanaged
     PAIRS=$MS/bench_ns_long_pairs_unmanaged.csv
     INIT=$MS/bench_ns_long_tree_init.csv
     T2=$MS/bench_ns_long_tree_t2.csv
     SITE=$MS/bench_ns_long_site_esi.csv
     INDOMAIN=0; MANAGED=FALSE
     TAG=$MV/h1_v132_mortgate_ns_long_unmanaged
     ;;
  4) SRC=ns_long_managed_multiregime
     PAIRS=$MS/bench_ns_long_pairs_managed_multiregime.csv
     INIT=$MS/bench_ns_long_tree_init.csv
     T2=$MS/bench_ns_long_tree_t2.csv
     SITE=$MS/bench_ns_long_site_esi.csv
     INDOMAIN=0; MANAGED=TRUE
     TAG=$MV/h1_v132_mortgate_ns_long_multiregime
     ;;
  *) echo "bad array id"; exit 2 ;;
esac

export PAIRS_FILE=$PAIRS INIT_FILE=$INIT T2_FILE=$T2 SITE_FILE=$SITE
export INDOMAIN=$INDOMAIN
export V1211_MANAGED=$MANAGED
export CONFIG_TAG=$TAG
echo "[pass30h1] task=$SLURM_ARRAY_TASK_ID src=$SRC managed=$MANAGED indomain=$INDOMAIN tag=$TAG"
Rscript $MV/2026-08-21_merge-v24-runner_WIP.R
echo "=== ${TAG} DONE ==="

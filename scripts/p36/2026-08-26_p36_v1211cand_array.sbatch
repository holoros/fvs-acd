#!/bin/bash
#SBATCH --job-name=p36v1211
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-7
#SBATCH --time=08:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p36/p36v1211_%A_%a.out
#
# Pass 36, column A of the three-model benchmark: v12.11 CANDIDATE, the configuration the published
# table results/gydb/v1211_vs_v132_vs_osm_comparison.csv reports in its rmse_cand and bias_cand
# columns. Every environment export below is byte-identical to v1211_candidate_array.sbatch, which
# is the sbatch of record for the cand_*_results.csv files that table was built from, so this array
# extends that battery to the five sources it never covered and rescores NB plus QC at the current
# 2,555 pair basis rather than the stale 733 row NB-only basis.
#
# The six sources v1211_candidate_array.sbatch already covers at current authoritative coverage
# (baxter 91, ctrn 1086, pef 2853, silc_l 73, mefia_l 918, and mefia_subp) are NOT rerun. Their
# cand_*_results.csv files match the authoritative pair sets exactly and carry the same provenance,
# so rerunning them would burn allocation to reproduce identical numbers.
#
# NB plus QC is task 1 and is the one cell that supersedes rather than extends. cand_nb_results.csv
# sits at 733 rows, which is NB only, and splits 355 NB against 378 QC in the published table.
# The current basis is magp_qcnb_pairs.csv at 2,555 pairs against the post-ESI-fill site file
# magp_qcnb_site_esi8_v2.csv, the same site file 2026-08-25_p21_nbqc_v2.sbatch used to build
# p9_v132_nb_v2_results.csv. Using the older magp_qcnb_site_esi8.csv here would silently put the
# v12.11 column on a different site basis from the v13.2 and production columns.
#
# Output naming: CONFIG_TAG is p36/p36_v1211cand_<src>, unique per array task. No two tasks in this
# array, or in the p36 v132plain and prod arrays, ever write the same path, and no task writes an
# intermediate under a shared name and renames afterward. That pattern cost pass 34 a discarded
# 36-file battery when two arms shared VARIANT=h1check.
#
# Model of record $HOME/_scripts/AcadianGY_12.11.r, UNMODIFIED. Runner bench_parity_split_ms_v1211.R,
# UNMODIFIED. R/4.4.0 as the candidate array used, not the 4.5.2 the v13 batteries use, because the
# v12.11 harness is frozen against that toolchain.
set -euo pipefail
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0 R/4.4.0
export FROZEN_MODULES_LOADED=1
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-8}
export R_DATATABLE_NUM_THREADS=${SLURM_CPUS_PER_TASK:-8}

cd $HOME/magplot/verify
MS=$HOME/magplot/verify/multisrc
P5M=$HOME/magplot/verify/p5m
P36=$HOME/magplot/verify/p36
mkdir -p $P36

export MODEL_FILE=$HOME/_scripts/AcadianGY_12.11.r
export SPLIT=TRUE
export V1211_IGMULT=2.5
export V1211_MORTGATE=TRUE
export V1211_STANDCON=TRUE
export SC_LO=0.40 SC_HI=0.50 SC_QMIN=22
export V1211_DHTHW=TRUE
# frozen canon
export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
export NB_AFAC=0.579 QC_AFAC=0.111

QC_ESI=/fs/scratch/PUOM0008/crsfaaron/canada/qc_esi/magp_qcnb_site_esi8_v2.csv
INDOMAIN=1

case "$SLURM_ARRAY_TASK_ID" in
  1) SRC=nb_v2;             PFX=$HOME/magplot/verify/magp_qcnb; SITE_OVR=$QC_ESI ;                                                                                                                                        MANAGED=TRUE  ;;
  2) SRC=memat;             PFX=$P5M/p5m_memat ;                                                                                                                                                                         MANAGED=FALSE ;;
  3) SRC=medev;             PFX=$P5M/p5m_medev ;                                                                                                                                                                         MANAGED=FALSE ;;
  4) SRC=ns_managed;        PAIRS_OVR=$MS/bench_ns_pairs_managed.csv;                   INIT_OVR=$MS/bench_ns_tree_init.csv;      T2_OVR=$MS/bench_ns_tree_t2.csv;      SITE_OVR=$MS/bench_ns_site_esi.csv;      INDOMAIN=0; MANAGED=TRUE  ;;
  5) SRC=ns_unmanaged;      PAIRS_OVR=$MS/bench_ns_pairs_unmanaged.csv;                 INIT_OVR=$MS/bench_ns_tree_init.csv;      T2_OVR=$MS/bench_ns_tree_t2.csv;      SITE_OVR=$MS/bench_ns_site_esi.csv;      INDOMAIN=0; MANAGED=FALSE ;;
  6) SRC=ns_long_managed;   PAIRS_OVR=$MS/bench_ns_long_pairs_managed_singleregime.csv; INIT_OVR=$MS/bench_ns_long_tree_init.csv; T2_OVR=$MS/bench_ns_long_tree_t2.csv; SITE_OVR=$MS/bench_ns_long_site_esi.csv; INDOMAIN=0; MANAGED=TRUE  ;;
  7) SRC=ns_long_unmanaged; PAIRS_OVR=$MS/bench_ns_long_pairs_unmanaged.csv;            INIT_OVR=$MS/bench_ns_long_tree_init.csv; T2_OVR=$MS/bench_ns_long_tree_t2.csv; SITE_OVR=$MS/bench_ns_long_site_esi.csv; INDOMAIN=0; MANAGED=FALSE ;;
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
export CONFIG_TAG=${P36}/p36_v1211cand_${SRC}

echo "[p36v1211] task=$SLURM_ARRAY_TASK_ID SRC=$SRC INDOMAIN=$INDOMAIN MANAGED=$MANAGED TAG=$CONFIG_TAG"
echo "[p36v1211] PAIRS=$PAIRS_FILE INIT=$INIT_FILE T2=$T2_FILE SITE=$SITE_FILE"
Rscript $HOME/magplot/verify/bench_parity_split_ms_v1211.R
echo "=== ${CONFIG_TAG} DONE ==="

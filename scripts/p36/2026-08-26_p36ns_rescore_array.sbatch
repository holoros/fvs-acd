#!/bin/bash
#SBATCH --job-name=p36ns
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-12
#SBATCH --time=10:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p36/p36ns_%A_%a.out
#
# Pass 36, NS rescore on the corrected observed basis. Twelve cells, being the four NS scoring
# units crossed with the three benchmark configurations.
#
# Why this exists. The NS research network is a thinning-trial design in which one `stand` carries
# several `plot` subplots, each an independent treatment unit with its own already-per-hectare
# expansion factor. `build_ns_bench.py` keyed on the stand alone and aggregated with
# groupby(["stand_key","year"]), which summed the expansion across subplots and multiplied stand
# density by the subplot count. Observed basal area reached 1,076 m2 ha-1 against a self-thinning
# ceiling near 64, the model initialised from that inflated list, its density-dependent mortality
# collapsed the stand, and the surviving prediction was mostly ingrowth. That produced NS managed's
# 156 percent RMSE, -39 percent bias and 0.12 slope, which results/gydb/README.md line 784 recorded
# as a property of the h1 configuration. It was a property of the input.
#
# The builders now key on (stand, plot), verified against the raw NS_PSP_research_tree.csv, whose
# `plot` column carries the subplot identity that was being discarded. Subplot rather than average
# is the right unit and not merely the right scale: of the 515 stand-years carrying more than one
# subplot, 238 contain subplots with different basal area removed and 102 with different treatment
# years, so averaging would mix treatment units rather than replicate them.
#
# Effect on the observed record, measured after the rebuild. NS research stands go from a maximum
# basal area of 1,076 to 86.1 m2 ha-1 at the initial occasion and 148.6 at remeasurement, with 1.14
# and 2.22 percent above the ceiling, which reproduces the raw per-subplot distribution exactly
# (1.53 percent above, maximum 148.6) rather than beating it down artificially. The operational NS
# stands were never affected and are unchanged at 0.09 percent. Coverage rises where the subplot
# split creates genuine units: NS-long managed single-regime goes from 1,334 to 3,267 pairs.
#
# CONFIG_TAG is namespaced p36ns_ rather than p36_ so the pre-rebuild results stay on disk as the
# comparison that documents the size of the defect. Every task writes a distinct path and no task
# writes a shared intermediate and renames afterward.
#
# Configurations are byte-identical to their p36 arrays apart from the source mapping. Tasks 1 to 4
# are the v12.11 candidate under R/4.4.0, tasks 5 to 8 plain v13.2, tasks 9 to 12 current
# production (h1_v132_mortgate plus h2_matgate). All twelve run INDOMAIN=0, as the NS cells do in
# the pass 31, 35 and 36 batteries.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge

MS=$HOME/magplot/verify/multisrc
P21=$HOME/magplot/verify/p21; P33=$HOME/magplot/verify/p33; P36=$HOME/magplot/verify/p36
mkdir -p $P36
cd $HOME/magplot/verify

# --- which cell -------------------------------------------------------------------------------
CELL_ID=$(( (SLURM_ARRAY_TASK_ID - 1) % 4 + 1 ))
CFG_ID=$(( (SLURM_ARRAY_TASK_ID - 1) / 4 + 1 ))
case "$CELL_ID" in
  1) SRC=ns_managed;        PAIRS=$MS/bench_ns_pairs_managed.csv;                   PFX=$MS/bench_ns;      MANAGED=TRUE  ;;
  2) SRC=ns_unmanaged;      PAIRS=$MS/bench_ns_pairs_unmanaged.csv;                 PFX=$MS/bench_ns;      MANAGED=FALSE ;;
  3) SRC=ns_long_managed;   PAIRS=$MS/bench_ns_long_pairs_managed_singleregime.csv; PFX=$MS/bench_ns_long; MANAGED=TRUE  ;;
  4) SRC=ns_long_unmanaged; PAIRS=$MS/bench_ns_long_pairs_unmanaged.csv;            PFX=$MS/bench_ns_long; MANAGED=FALSE ;;
  *) echo "bad cell"; exit 2 ;;
esac
export PAIRS_FILE=$PAIRS
export INIT_FILE=${PFX}_tree_init.csv
export T2_FILE=${PFX}_tree_t2.csv
export SITE_FILE=${PFX}_site_esi.csv
export INDOMAIN=0
export TREE_OUT=""

# --- shared canon -----------------------------------------------------------------------------
export SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
export NB_AFAC=0.579 QC_AFAC=0.111
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8

case "$CFG_ID" in
  1) CFG=v1211cand
     module load gcc/12.3.0 R/4.4.0
     export FROZEN_MODULES_LOADED=1
     export MODEL_FILE=$HOME/_scripts/AcadianGY_12.11.r
     export V1211_IGMULT=2.5 V1211_MORTGATE=TRUE V1211_STANDCON=TRUE
     export SC_LO=0.40 SC_HI=0.50 SC_QMIN=22 V1211_DHTHW=TRUE
     export ONSET=0.30
     export V1211_MANAGED=$MANAGED
     RUNNER=$HOME/magplot/verify/bench_parity_split_ms_v1211.R
     ;;
  2) CFG=v132plain
     module load gcc/12.3.0 R/4.5.2
     export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
     export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff
     export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
     export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
     export ONSET=0.55 IMULT=2.5
     export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
     export V132=1
     RUNNER=$P21/2026-08-19_p21_bench_v132.R
     ;;
  3) CFG=prod
     module load gcc/12.3.0 R/4.5.2
     export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
     export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff
     export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2.r
     export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
     export ONSET=0.55 IMULT=2.5
     export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
     export V132=1
     export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
     export P33_MATGATE=TRUE MATGATE_QC=12.7 MATGATE_K=0.6
     export V1211_MANAGED=$MANAGED
     RUNNER=$P33/2026-08-26_p33-matgate-runner.R
     ;;
  *) echo "bad cfg"; exit 2 ;;
esac

export CONFIG_TAG=${P36}/p36ns_${CFG}_${SRC}
echo "[p36ns] task=$SLURM_ARRAY_TASK_ID CFG=$CFG SRC=$SRC MANAGED=$MANAGED TAG=$CONFIG_TAG"
echo "[p36ns] PAIRS=$PAIRS_FILE INIT=$INIT_FILE T2=$T2_FILE SITE=$SITE_FILE"
Rscript $RUNNER
echo "=== ${CONFIG_TAG} DONE ==="

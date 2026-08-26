#!/bin/bash
#SBATCH --job-name=p36v1211bax
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p36/p36v1211bax_%j.out
#
# Pass 36, correction to column A. Baxter is rescored under v12.11 rather than reused, because the
# observed-basis gate rejected the reused cell.
#
# What the gate caught. Comparing the reused cand_baxter_results.csv against the fresh v13.2 and
# production Baxter cells, observed total volume disagreed on 78 of 91 stands, mean absolute
# difference 4.25 percent and maximum 81.4 percent, while CTRN, PEF, SILC_L and MEFIA_L all agreed
# to exactly zero. Since the published comparison table reports a Baxter margin of 2.75 RMSE points
# between v12.11 and v13.2, a 4.25 percent disagreement in the target the two are scored against is
# larger than the effect being reported, and the reused cell could not be trusted.
#
# The cause, established rather than assumed. It is not the model and it is not height imputation.
# The staged Baxter tree lists were rebuilt on 4 August 2026 by the height recovery in baxfix_p4b,
# which added 119 measured heights at t1 and 463 at t2 to files that previously carried none, and
# also corrected 104 and 78 diameters. cand_baxter_results.csv was written 22 July 2026, before that
# rebuild; every p36 cell was written after it. So the two harnesses were reading two different
# Baxter tree lists. The per-stand signature confirms it: all 49 stands whose initial top height
# moved contain at least one newly measured height, all 31 stands with no measured height are
# bit-identical, initial basal area and stand density index differ in 0 of 91 stands, and every
# height-derived quantity moves. PEF refutes the alternative explanation, since it is 97.7 percent
# missing height against Baxter's 97.9 yet agrees to exactly zero, its staged files having never
# been rebuilt.
#
# Every export below is byte-identical to 2026-08-26_p36_v1211cand_array.sbatch, which is itself
# byte-identical to v1211_candidate_array.sbatch. Only the source mapping and CONFIG_TAG differ, so
# this cell sits on the same v12.11 candidate configuration as the other twelve.
set -euo pipefail
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0 R/4.4.0
export FROZEN_MODULES_LOADED=1
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK:-8}
export R_DATATABLE_NUM_THREADS=${SLURM_CPUS_PER_TASK:-8}

cd $HOME/magplot/verify
MS=$HOME/magplot/verify/multisrc
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
export INDOMAIN=1

export PAIRS_FILE=$MS/bench_baxter_pairs.csv
export INIT_FILE=$MS/bench_baxter_tree_init.csv
export T2_FILE=$MS/bench_baxter_tree_t2.csv
export SITE_FILE=$MS/bench_baxter_site_esi.csv
export V1211_MANAGED=FALSE
export CONFIG_TAG=${P36}/p36_v1211cand_baxter

echo "[p36v1211bax] SRC=baxter TAG=$CONFIG_TAG"
Rscript $HOME/magplot/verify/bench_parity_split_ms_v1211.R
echo "=== ${CONFIG_TAG} DONE ==="

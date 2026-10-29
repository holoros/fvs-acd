#!/bin/bash
#SBATCH --job-name=p36silc
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-3
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=24G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p36/p36silc_%A_%a.out
#
# Pass 36, SILC_L rescored at full coverage under all three benchmark configurations.
#
# The gap was never unclosable. The 73 plot subset does not come from a decision made in this
# benchmark at all; it is inherited verbatim from silc_cfi_longhorizon_pairs_v16.R, whose dominant
# filter is a source QC flag, METRICS_RELIABLE == "Y", which removes 51 of 150 plots outright, with
# a 5 yr span rule removing 25 more, mostly because the span is computed on the surviving reliable
# occasions so 23 of those had exactly one occasion left. Of the 234 STAND_METRICS rows carrying
# METRICS_RELIABLE = N, 200 carry no explanatory note at all. Aaron reviewed this on 12 August 2026
# and decided to relax the gate entirely and carry the reliability flags as reported covariates
# rather than as an exclusion, on the grounds that 57 of 137 would otherwise be silently dropped.
#
# The full coverage staging was then built, verified and uploaded on 12 August and has been sitting
# in multisrc ever since as bench_silc_l_{pairs,tree_init,tree_t2,site_esi}_full137.csv. The 73
# plot subset reproduces the old files exactly, 0 mismatches across 73 stands and 2,127 tree rows,
# and the T2 side was reconciled independently against BA_CURR_FT2AC to within 0.01 ft2 ac-1 across
# all 137 plots. Three configurations have already scored against it at n = 120. The only thing
# that kept it out of the pass 36 battery was a filename shape: the array builds its inputs as
# ${PFX}_pairs.csv while the full coverage files put the suffix after the role token. The
# bench_silc137_* symlinks in multisrc resolve that, and are symlinks rather than copies so there
# is exactly one set of bytes.
#
# Expect n = 120, not 137. The 17 shortfall is the scoring driver's own minimum of three trees at
# both occasions (bench_parity_split_ms_v1211.R, `if(nrow(it)<3||nrow(ot)<3)`), not a data gap, and
# every one of the 17 genuinely has fewer than three trees at one end. None of the 17 is among the
# original 73, so this run adds 47 stands and loses none.
#
# DISCLOSE THIS AS A METHODOLOGY BREAK, NOT AN EXPANSION. The full coverage esi8 sits on a
# different basis from the 73 row file, because Acadian_ESI_v8_240m.tif had zero valid pixels by 8
# July 2026 and the 30 m raster resampled to the 240 m grid was substituted for all 137 plots,
# including redoing the original 73. On the 73 shared sites not one value matches, the mean shift is
# +3.42 m and the range of shifts is +1.21 to +4.49. The observed side moved too, from a T2 species
# crosswalk correction in which valid white cedar and hemlock codes had been defaulting to other
# hardwood, so on the same 73 stands observed total volume moves from 85.80 to 80.24 m3 ha-1 and
# observed value from 3210.77 to 3530.60 while observed basal area is bit identical at 13.12
# m2 ha-1. Every historical SILC_L number therefore moves, and the 47 added stands are materially
# harder than the original 73, with basal area bias +22.3 against +13.1 percent.
#
# Configurations are byte-identical to the p36 arrays. SILC_L is MANAGED=TRUE and INDOMAIN=1
# throughout, matching how the pass 31, 35 and 36 batteries score it.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge

MS=$HOME/magplot/verify/multisrc
P21=$HOME/magplot/verify/p21; P33=$HOME/magplot/verify/p33; P36=$HOME/magplot/verify/p36
mkdir -p $P36
cd $HOME/magplot/verify

PFX=$MS/bench_silc137
export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv
export T2_FILE=${PFX}_tree_t2.csv SITE_FILE=${PFX}_site_esi.csv
export INDOMAIN=1
export TREE_OUT=""

export SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
export NB_AFAC=0.579 QC_AFAC=0.111
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8

case "$SLURM_ARRAY_TASK_ID" in
  1) CFG=v1211cand
     module load gcc/12.3.0 R/4.4.0
     export FROZEN_MODULES_LOADED=1
     export MODEL_FILE=$HOME/_scripts/AcadianGY_12.11.r
     export V1211_IGMULT=2.5 V1211_MORTGATE=TRUE V1211_STANDCON=TRUE
     export SC_LO=0.40 SC_HI=0.50 SC_QMIN=22 V1211_DHTHW=TRUE
     export ONSET=0.30 V1211_MANAGED=TRUE
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
     export V1211_MANAGED=TRUE
     RUNNER=$P33/2026-08-26_p33-matgate-runner.R
     ;;
  *) echo "bad array id"; exit 2 ;;
esac

export CONFIG_TAG=${P36}/p36silc137_${CFG}_silc_l
echo "[p36silc] task=$SLURM_ARRAY_TASK_ID CFG=$CFG TAG=$CONFIG_TAG"
Rscript $RUNNER
echo "=== ${CONFIG_TAG} DONE ==="

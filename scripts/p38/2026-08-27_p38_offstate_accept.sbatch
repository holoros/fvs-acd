#!/bin/bash
#SBATCH --job-name=p38offacc
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=5,11
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p38/p38offacc_%A_%a.out
#
# PASS 38 OFF-STATE ACCEPTANCE, 27 August 2026. Proves the SM survival patch is inert when the
# sub-flag is off, end to end rather than by construction: rerun silc_l (task 5) and baxter
# (task 11) with the PATCHED ~/AcadianGY_13.3.r, USE_MODS=TRUE, and USE_HW_SURV_FIA left unset
# (runner default FALSE), through the p38 runner. The result CSVs must be BYTE-IDENTICAL to
# p37/p37_cand_silc_l_results.csv and p37/p37_cand_baxter_results.csv, which the pre-SM-patch
# engine produced under the same levers. Any diff means the patch is not behaviour-neutral with
# the flag off and the p38 ON arm must not be scored. Every lever export below is identical to
# the p37 candidate arm.
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
# USE_HW_SURV_FIA deliberately NOT exported: the runner's default FALSE path is itself under test.

INDOMAIN=1
case "$SLURM_ARRAY_TASK_ID" in
  5)  SRC=silc_l;            PFX=$MS/bench_silc_l ;  MANAGED=TRUE  ;;
  11) SRC=baxter;            PFX=$MS/bench_baxter ;  MANAGED=FALSE ;;
  *) echo "bad array id"; exit 2 ;;
esac

export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv T2_FILE=${PFX}_tree_t2.csv
export SITE_FILE=${PFX}_site_esi.csv
export INDOMAIN=$INDOMAIN
export V1211_MANAGED=$MANAGED
export CONFIG_TAG=${P38}/p38_offacc_${SRC}
export TREE_OUT=""
echo "[p38offacc] task=$SLURM_ARRAY_TASK_ID SRC=$SRC TAG=$CONFIG_TAG USE_MODS=$USE_MODS USE_HW_SURV_FIA=<unset>"
Rscript $P38/2026-08-27_p38-runner.R
echo "=== ${CONFIG_TAG} DONE ==="
cmp $P38/p38_offacc_${SRC}_results.csv $HOME/magplot/verify/p37/p37_cand_${SRC}_results.csv \
  && echo "=== OFF-STATE BYTE-IDENTICAL: ${SRC} ===" \
  || { echo "=== OFF-STATE MISMATCH: ${SRC} ==="; exit 3; }

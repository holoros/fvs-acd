#!/bin/bash
#SBATCH --job-name=acdx131h
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=8G
#SBATCH --array=1-62
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_20261016/bench131h/logs/%x_%A_%a.out
# FVS-ACD cross-version benchmark (October 16, 2026): v13.1 hierarchical arm on all 19 benchmark sets.
# Derived from bench141 array (2026-09-25_v142_bench141_array.sbatch). Same frames, chunks, counters runner (md5 300a0d61).
# Environment is the Seven Islands v13.1h configuration (v131_silc_full137_treeout.sbatch): MODEL_FILE 13.1 only,
# hierarchical ingrowth and mortality on, HIER_POSTDIR ~/v13_comb_post, ONSET 0.30; no p4e patch, no 14.x overlay.
# New outputs only; frozen runs untouched. No em dashes.
set -euo pipefail
FR=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames
V=/users/PUOM0008/crsfaaron/magplot/verify
R1=/users/PUOM0008/crsfaaron/acdx_20261016/bench131h
TM=$R1/work/bench131h_taskmap_DATA_2026-10-16.csv
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task $SLURM_ARRAY_TASK_ID not in $TM"; exit 2; }
IFS=, read -r COL CHUNK SET FROM TO <<< "$ROW"
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=$FROM CHUNK_TO=$TO
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
mkdir -p $R1/out/$COL/$SET
export CONFIG_TAG=$R1/out/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE: ${CONFIG_TAG}_results.csv exists"; exit 3; }
chk() { local f=$1 w=$2; local m; m=$(md5sum "$f" | cut -d' ' -f1); [ "$m" = "$w" ] || { echo "FATAL md5 $f $m != $w"; exit 4; }; echo "md5 ok $f $m"; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
unset ACD_V14_BASE LINKED LINKED_MODE LINKED_SPRE LINKED_COEF LINKED_MORTMULT NOSDI NOCON B0NEW B1NEW B2NEW IMULT || true
unset LEV3 LEV3_LO LEV3_HI LEV3_QMIN V141 V141_FILE V141_COEF LSDG_V141 THIN_V141 DBA_V1404 SMALLTREE TST_FILE TST_COL SRC_TST || true
export MODEL_FILE=$HOME/AcadianGY_13.1.r
chk $MODEL_FILE 5894df6013c701d09e7ba67ba6c2f090
export USE_HIER_ING=TRUE USE_HIER_MORT=TRUE HIER_POSTDIR=$HOME/v13_comb_post SPLIT=TRUE
export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1 V132=0
for f in v131r_mortB_fixef.csv v131r_ingrowth_fixef.csv; do [ -s $HIER_POSTDIR/$f ] || { echo "FATAL missing $f"; exit 6; }; done
export SRC_TST=UNKNOWN
RUNNER=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/runner/scripts/2026-09-25_v142_phaseD_runner_p23_tst_counters.R
chk $RUNNER 300a0d610070f77517352c8e23f07922
export TREE_OUT=$CONFIG_TAG
cd $V
echo "[acdx131h] COL=$COL task=$SLURM_ARRAY_TASK_ID set=$SET chunk=$CHUNK rows=$FROM..$TO host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[acdx131h] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"


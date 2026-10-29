#!/bin/bash
#SBATCH --job-name=howland_xver
#SBATCH --array=1-20
#SBATCH --time=06:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=4
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/howland_xver_20261026/logs/howland_xver_%A_%a.out
# Howland cross-version completion (26 October 2026): the two cross-version arms not yet run on the 93 DigiSylva Howland plots,
# 13.1h (Seven Islands configuration) and 14.0.4 L2 (v141off: 14.1 overlay sourced, both gates off), through the same long200
# runner (md5 3d05cbad), the same Howland inputs (read in place from the October 23 v141L run) and the same ESI 12, 15, 18 and
# 50 yr horizon as the frozen v141L run (job 15795712, holoros/fvs-acd 8b6b670). Arm environments verbatim from the October 16
# long200 launcher (cardinal_mcp_job_3936542.slurm). Tasks 1 to 10 v131h, 11 to 20 v141off, 28 stands each. New outputs only.
# No em dashes.
set -euo pipefail
IN=/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/v141_check
A=/users/PUOM0008/crsfaaron/howland_xver_20261026
V=/users/PUOM0008/crsfaaron/magplot/verify; P4E=$V/p4e; P23=$V/p23
R1=/users/PUOM0008/crsfaaron/acdx_20261016/long200
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; echo "md5 ok $1"; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
for f in howland_pairs.csv howland_tree_init.csv howland_tree_t2.csv howland_site_esi.csv; do [ -s $IN/$f ] || { echo "FATAL missing $IN/$f"; exit 2; }; done
grep -q "^$(md5sum $IN/howland_pairs.csv | cut -d' ' -f1) " $A/logs/input_md5s.txt || { echo "FATAL input md5 differs from the record"; exit 2; }
N=$(($(wc -l < $IN/howland_pairs.csv) - 1))
K=$SLURM_ARRAY_TASK_ID; if [ $K -le 10 ]; then COL=v131h; C=$K; else COL=v141off; C=$((K-10)); fi
F=$(( (C-1)*28+1 )); T=$(( C*28 )); [ $T -le $N ] || T=$N
export PAIRS_FILE=$IN/howland_pairs.csv INIT_FILE=$IN/howland_tree_init.csv T2_FILE=$IN/howland_tree_t2.csv SITE_FILE=$IN/howland_site_esi.csv
export CHUNK_FROM=$F CHUNK_TO=$T TIMELIM=20000
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
unset ACD_V14_BASE LINKED LINKED_MODE LINKED_SPRE LINKED_COEF LINKED_MORTMULT NOSDI NOCON B0NEW B1NEW B2NEW IMULT LEV3 LEV3_LO LEV3_HI LEV3_QMIN || true
unset V141 V141_FILE V141_COEF LSDG_V141 THIN_V141 DBA_V1404 SMALLTREE TST_FILE TST_COL SRC_TST V141_REPORT_DIR || true
mkdir -p $A/out/$COL
if [ "$COL" = "v131h" ]; then
  export MODEL_FILE=$HOME/AcadianGY_13.1.r; chk $MODEL_FILE 5894df6013c701d09e7ba67ba6c2f090
  export USE_HIER_ING=TRUE USE_HIER_MORT=TRUE HIER_POSTDIR=$HOME/v13_comb_post SPLIT=TRUE
  export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
  export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1 V132=0 SRC_TST=UNKNOWN
else
  export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
  export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
  export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
  export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
  export ONSET=0.55 IMULT=2.5 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18 V132=0 INDOMAIN=1
  chk $P4E/model_b0b1b2.r bb51eeada62796532ce3a7212a5c6451; chk $HOME/AcadianGY_13.1.r 5894df6013c701d09e7ba67ba6c2f090
  export ACD_V14_BASE=$P4E/model_b0b1b2.r LINKED=1 LINKED_SPRE=1 LINKED_COEF=$P23/v14_coef_bundle_2026-09-08.rds
  chk $LINKED_COEF 4740de88af8231677d828dec8e5b753c
  ENG=$HOME/v14_0_4_20260917/AcadianGY_14.0.4.r; chk $ENG 61f95d99f896e8e513930d6e33a7391a
  export DBA_V1404=1 MODEL_FILE=$ENG LINKED_MODE=L2 SMALLTREE=0
  export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r
  export V141_COEF=$V/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
  export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0 V141_REPORT_DIR=$A/out/counters_$COL
  chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd; chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
  export LSDG_V141=0 THIN_V141=0
fi
RUNNER=$R1/scripts/2026-10-16_acdx_long200_runner.R; chk $RUNNER 3d05cbade76bbe298e5e93ca6c7b8230
export CONFIG_TAG=$A/out/$COL/c$(printf %02d $C) TREE_OUT=$A/out/$COL/c$(printf %02d $C)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE ${CONFIG_TAG}_results.csv exists"; exit 3; }
cd $V
echo "[howland_xver] COL=$COL task=$K chunk=$C rows=$F..$T host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[howland_xver] DONE end=$(date -Is)"

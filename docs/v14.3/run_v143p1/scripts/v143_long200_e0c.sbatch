#!/bin/bash
#SBATCH --job-name=v143L200
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=16:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p1/logs/%x_%A_%a.out
# 14.3 pre-registration 1 (md5 7f3e67c2), gate E0c: the 200 yr no-harvest mefia_l_c frame with the 14.3dev overlay
# switched on (eligibility file ALL0) must equal the frozen 16 October 14.1 run (long200/out/v141LT) exactly.
# COPY of ~/acdx_20261016/long200/scripts/cardinal_mcp_job_3936542.slurm, the frozen long200 launcher, v141LT branch
# only, verbatim. Changes: the array index runs over the v141LT rows of the frozen task map (task t here is the t-th
# v141LT row); V141_FILE is the overlay with THINELIG=1 and the ALL0 file; outputs go to ~/v143p1/out/e0c only.
# The frozen long200 runner (md5 3d05cbad) is used unmodified. No em dashes.
set -euo pipefail
FR=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames
V=/users/PUOM0008/crsfaaron/magplot/verify; P4E=$V/p4e; P23=$V/p23
L2=/users/PUOM0008/crsfaaron/acdx_20261016/long200
ROOT=/users/PUOM0008/crsfaaron/v143p1
[ -z "${V143_OUT:-}" ] || { echo "FATAL E0c is not part of the dry run"; exit 2; }
B141=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141
TM=$L2/work/long200_taskmap_DATA_2026-10-16.csv
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $2=="v141LT" {k++; if (k==t) print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task not in map"; exit 2; }
IFS=, read -r COL0 CHUNK SET FROM TO <<< "$ROW"
COL=e0c
export PAIRS_FILE=$L2/work/long200_mefia_l_c_pairs_DATA_2026-10-16.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv CHUNK_FROM=$FROM CHUNK_TO=$TO TIMELIM=3000
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
mkdir -p $ROOT/out/$COL/$SET
export CONFIG_TAG=$ROOT/out/$COL/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE exists"; exit 3; }
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; echo "md5 ok $1"; }
lmd5() { awk -v f="$1" '$2==f {print $1}' $ROOT/logs/launch_md5s.txt; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
unset ACD_V14_BASE LINKED LINKED_MODE LINKED_SPRE LINKED_COEF LINKED_MORTMULT NOSDI NOCON B0NEW B1NEW B2NEW IMULT LEV3 LEV3_LO LEV3_HI LEV3_QMIN || true
unset V141 V141_FILE V141_COEF LSDG_V141 THIN_V141 DBA_V1404 SMALLTREE TST_FILE TST_COL SRC_TST V141_REPORT_DIR || true
# ---- verbatim from the frozen long200 launcher, 14.x branch ----
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
  export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0 V141_REPORT_DIR=$ROOT/out/counters_$COL
  chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd; chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
  export LSDG_V141=1 THIN_V141=1 TST_FILE=$B141/work/v142_bench141_tst_${SET}_DATA_2026-09-25.csv TST_COL=TST
# ---- end of the verbatim block ----
export V143_V141_BASE=$V141_FILE
OVL=$ROOT/scripts/AcadianGY_14.3dev_thinelig.r; chk $OVL "$(lmd5 scripts/AcadianGY_14.3dev_thinelig.r)"
export V141_FILE=$OVL THINELIG=1 THINELIG_FILE=$ROOT/work/elig_ALL0_long200_SERVERONLY.csv
export THINELIG_REPORT=$ROOT/out/$COL/$SET/c$(printf %03d $CHUNK)_thinelig_report_SERVERONLY.csv
[ -s "$THINELIG_FILE" ] || { echo "FATAL no eligibility file"; exit 5; }
RUNNER=$L2/scripts/2026-10-16_acdx_long200_runner.R; chk $RUNNER "$(md5sum $RUNNER | cut -d' ' -f1)"
case "$(md5sum $RUNNER | cut -c1-8)" in 3d05cbad) ;; *) echo "FATAL long200 runner md5"; exit 4 ;; esac
export TREE_OUT=$CONFIG_TAG
cd $V
echo "[v143L200] COL=$COL task=$SLURM_ARRAY_TASK_ID chunk=$CHUNK rows=$FROM..$TO host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v143L200] DONE end=$(date -Is)"

#!/bin/bash
# PREREG4 (md5 a15bd92a) build: the two array launchers, each a copy of a frozen launcher with its 14.1 environment block
# VERBATIM (extracted by marker lines and asserted to occur once, byte for byte), and the grid coefficient files.
# Hindcast: copy of 2026-09-25_v142_bench141_array.sbatch. 200 yr: copy of cardinal_mcp_job_3936542.slurm (acdx long200).
# Runners unchanged (300a0d61, 3d05cbad). Outputs only under ~/v143p4/out. Refuses if any built file exists. No em dashes.
set -euo pipefail
P=/users/PUOM0008/crsfaaron/v143p4; S=$P/scripts; W=$P/work
B141L=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141/scripts/2026-09-25_v142_bench141_array.sbatch
L200L=/users/PUOM0008/crsfaaron/acdx_20261016/long200/scripts/cardinal_mcp_job_3936542.slurm
for f in $S/v143p4_hc_array.sbatch $S/v143p4_l200_array.sbatch; do [ -e $f ] && { echo "REFUSE $f exists"; exit 3; }; done
ck() { [ "$(md5sum "$1" | cut -d' ' -f1)" = "$2" ] || { echo "FATAL md5 $1"; exit 4; }; echo "md5 ok $1"; }
md5sum $B141L $L200L
python3 - "$B141L" "$L200L" "$S/v143p4_hc_array.sbatch" "$S/v143p4_l200_array.sbatch" <<'PY'
import sys
b141, l200, ohc, ol2 = sys.argv[1:5]
def block(path, start, end):
    t = open(path).read(); i = t.index(start); assert t.count(start) == 1, start
    j = t.index(end, i); assert t.count(end) == 1, end
    return t[i:j + len(end)] + "\n"
BH = block(b141, "source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2", "chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51")
BL = block(l200, "source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2", "    v141LT)  export LSDG_V141=1 THIN_V141=1 TST_FILE=$B141/work/v142_bench141_tst_${SET}_DATA_2026-09-25.csv TST_COL=TST ;;\n  esac\nfi")
HEAD_HC = r'''#!/bin/bash
#SBATCH --job-name=v143p4hc
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=04:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p4/logs/hc_%A_%a.out
# 14.3 pre-registration 4 (revision 1, md5 a15bd92a): ten year hindcast arms. COPY of the frozen bench141 launcher
# 2026-09-25_v142_bench141_array.sbatch; its environment block from "source /etc/profile.d/lmod.sh" to the V141_COEF check is
# below VERBATIM (asserted by build_v143p4.sh). Changes, and nothing else: taskmap and output root under ~/v143p4; the arm ARM
# from the taskmap with the 14.1 (v141LT) settings; V141_REPORT_DIR per arm; V141_FILE pointed at the senft overlay, which
# sources the frozen 14.1 file; SENFT switches per arm; STAND_KEEP_FILE (fold A) for the grid arms. Same runner (300a0d61).
#   off      overlay sourced, SENFT 0                         gate H1a, must equal frozen v141LT
#   g0       SENFT 1, form L, delta 0 both classes, trace     gate H2, floor domain, the delta 0 grid point
#   gL_*     SENFT 1, form L, grid delta (work/grid_coef_*)   fold A only
#   gS_*     SENFT 1, form S, grid delta                       fold A only
#   candL    SENFT 1, form L, work/senft_coef_L.csv            selected coefficients
#   candS    SENFT 1, form S, work/senft_coef_S.csv            selected coefficients
# New outputs only. No em dashes.
set -euo pipefail
FR=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames
V=/users/PUOM0008/crsfaaron/magplot/verify
P4E=$V/p4e; P23=$V/p23
ROOT=${V143P4_ROOT:-/users/PUOM0008/crsfaaron/v143p4}
B141=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141
R1=$ROOT/out/hc
TM=${V143_TASKMAP:?set V143_TASKMAP}
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task $SLURM_ARRAY_TASK_ID not in $TM"; exit 2; }
IFS=, read -r ARM CHUNK SET FROM TO <<< "$ROW"; COL=v141LT
[ -n "${V143_FRAMES:-}" ] && FR=$V143_FRAMES   # dry run only
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
export CHUNK_FROM=$FROM CHUNK_TO=$TO
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
mkdir -p $R1/$ARM/$SET
export CONFIG_TAG=$R1/$ARM/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE: ${CONFIG_TAG}_results.csv exists"; exit 3; }
chk() { local f=$1 w=$2; local m; m=$(md5sum "$f" | cut -d' ' -f1); [ "$m" = "$w" ] || { echo "FATAL md5 $f $m != $w"; exit 4; }; echo "md5 ok $f $m"; }
MD5F=${V143_MD5FILE:-$ROOT/logs/launch_md5s.txt}
lmd5() { awk -v f="$1" '$2==f {print $1}' $MD5F | tail -1; }

'''
TAIL_COMMON = r'''
## ---- end of the verbatim block; PREREG4 arm settings follow ----
export LSDG_V141=1 THIN_V141=1
export V141_REPORT_DIR=$R1/$ARM/counters; mkdir -p $V141_REPORT_DIR
export V143_V141_BASE=$V141_FILE
OVL=$ROOT/scripts/AcadianGY_14.3dev_senft.r
W_OVL=$(lmd5 scripts/AcadianGY_14.3dev_senft.r); [ -n "$W_OVL" ] || { echo "FATAL overlay md5 not in launch_md5s.txt"; exit 4; }
chk $OVL $W_OVL
export V141_FILE=$OVL
unset SENFT SENFT_FORM SENFT_COEF SENFT_TRACE || true
EW=${V143_WORK:-$ROOT/work}; SO=${V143_SO:-$ROOT/serveronly_SERVERONLY}
case "$ARM" in
  off)   export SENFT=0 ;;
  g0)    export SENFT=1 SENFT_FORM=L SENFT_COEF=$EW/grid_coef_g0.csv STAND_KEEP_FILE=$SO/keep_foldA_SERVERONLY.csv
         export SENFT_TRACE=$R1/$ARM/$SET/trace_c$(printf %03d $CHUNK)_SERVERONLY.rds ;;
  gL_*)  export SENFT=1 SENFT_FORM=L SENFT_COEF=$EW/grid_coef_${ARM#gL_}.csv STAND_KEEP_FILE=$SO/keep_foldA_SERVERONLY.csv ;;
  gS_*)  export SENFT=1 SENFT_FORM=S SENFT_COEF=$EW/grid_coef_${ARM#gS_}.csv STAND_KEEP_FILE=$SO/keep_foldA_SERVERONLY.csv ;;
  candL) export SENFT=1 SENFT_FORM=L SENFT_COEF=$EW/senft_coef_L.csv ;;
  candS) export SENFT=1 SENFT_FORM=S SENFT_COEF=$EW/senft_coef_S.csv ;;
  D1)    export SENFT=1 SENFT_FORM=L SENFT_COEF=$EW/senft_coef_D1.csv ;;
  *) echo "FATAL unknown ARM $ARM"; exit 2 ;;
esac
if [ -n "${SENFT_COEF:-}" ]; then
  [ -s "$SENFT_COEF" ] || { echo "FATAL no coefficient file $SENFT_COEF"; exit 5; }
  W_C=$(lmd5 work/$(basename $SENFT_COEF)); [ -n "$W_C" ] || { echo "FATAL coefficient md5 not in launch_md5s.txt"; exit 4; }
  chk $SENFT_COEF $W_C
fi
if [ -n "${STAND_KEEP_FILE:-}" ]; then [ -s "$STAND_KEEP_FILE" ] || { echo "FATAL no keep file"; exit 5; }; fi
'''
TAIL_HC = TAIL_COMMON + r'''case "$SET" in
  nb_c|qc_c|qc_fl|ns_c|ns_fl|ns_long_c|ns_long_fl) export SRC_TST=UNKNOWN ;;
  *) export TST_FILE=$B141/work/v142_bench141_tst_${SET}_DATA_2026-09-25.csv TST_COL=TST
     [ -n "${V143_TST_DIR:-}" ] && export TST_FILE=$V143_TST_DIR/$(basename $TST_FILE)   # dry run only
     [ -s "$TST_FILE" ] || { echo "FATAL no tst file $TST_FILE"; exit 5; } ;;
esac
RUNNER=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/runner/scripts/2026-09-25_v142_phaseD_runner_p23_tst_counters.R
chk $RUNNER 300a0d610070f77517352c8e23f07922
export TREE_OUT=$CONFIG_TAG
cd $V
echo "[v143p4hc] ARM=$ARM task=$SLURM_ARRAY_TASK_ID set=$SET chunk=$CHUNK rows=$FROM..$TO SENFT=${SENFT:-unset} FORM=${SENFT_FORM:-none} COEF=$(basename ${SENFT_COEF:-none}) KEEP=$( [ -n "${STAND_KEEP_FILE:-}" ] && echo foldA || echo none) TST_FILE=$(basename ${TST_FILE:-none}) SRC_TST=${SRC_TST:-unset} host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v143p4hc] DONE ${CONFIG_TAG}_results.csv end=$(date -Is)"
'''
HEAD_L2 = r'''#!/bin/bash
#SBATCH --job-name=v143p4L2
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=16:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=8G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p4/logs/l200_%A_%a.out
# 14.3 pre-registration 4 (revision 1, md5 a15bd92a): 200 yr no-harvest arms on the 918 mefia_l_c t1 lists. COPY of the frozen
# acdx long200 launcher cardinal_mcp_job_3936542.slurm; its environment block from "source /etc/profile.d/lmod.sh" to the end
# of the arm branch is below VERBATIM (asserted by build_v143p4.sh) and runs with COL=v141LT (the 14.1 branch). Changes, and
# nothing else: taskmap and output root under ~/v143p4; the arm ARM from the taskmap; V141_REPORT_DIR per arm; V141_FILE pointed
# at the senft overlay; SENFT switches per arm (off, candL, candS, D1). Same long200 runner (3d05cbad), TIMELIM 3000.
# New outputs only. No em dashes.
set -euo pipefail
FR=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames
V=/users/PUOM0008/crsfaaron/magplot/verify; P4E=$V/p4e; P23=$V/p23
ROOT=${V143P4_ROOT:-/users/PUOM0008/crsfaaron/v143p4}
R0L=/users/PUOM0008/crsfaaron/acdx_20261016/long200
R1=$ROOT/out/l200
B141=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141
TM=${V143_TASKMAP:?set V143_TASKMAP}
ROW=$(awk -F, -v t="$SLURM_ARRAY_TASK_ID" 'NR>1 && $1==t {print $2","$3","$4","$5","$6}' "$TM")
[ -n "$ROW" ] || { echo "task not in map"; exit 2; }
IFS=, read -r ARM CHUNK SET FROM TO <<< "$ROW"; COL=v141LT
export PAIRS_FILE=${V143_L2PAIRS:-$R0L/work/long200_mefia_l_c_pairs_DATA_2026-10-16.csv} INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv
export SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv CHUNK_FROM=$FROM CHUNK_TO=$TO TIMELIM=3000
unset SCORE_MINDBH_FIXED STAND_KEEP_FILE MGD_FILE MGD_COL MGD_UNMANAGED SRC_MANAGED V1211_MGD_PERSTAND || true
mkdir -p $R1/$ARM/$SET
export CONFIG_TAG=$R1/$ARM/$SET/c$(printf %03d $CHUNK)
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo "REFUSE exists"; exit 3; }
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; echo "md5 ok $1"; }
MD5F=${V143_MD5FILE:-$ROOT/logs/launch_md5s.txt}
lmd5() { awk -v f="$1" '$2==f {print $1}' $MD5F | tail -1; }
'''
TAIL_L2 = TAIL_COMMON + r'''RUNNER=$R0L/scripts/2026-10-16_acdx_long200_runner.R; chk $RUNNER 3d05cbade76bbe298e5e93ca6c7b8230
export TREE_OUT=$CONFIG_TAG
cd $V
echo "[v143p4L2] ARM=$ARM task=$SLURM_ARRAY_TASK_ID chunk=$CHUNK rows=$FROM..$TO SENFT=${SENFT:-unset} FORM=${SENFT_FORM:-none} COEF=$(basename ${SENFT_COEF:-none}) host=$(hostname) start=$(date -Is)"
Rscript $RUNNER
echo "[v143p4L2] DONE end=$(date -Is)"
'''
hc = HEAD_HC + BH + TAIL_HC; l2 = HEAD_L2 + BL + TAIL_L2
assert hc.count(BH) == 1 and l2.count(BL) == 1
python3 -c "import glob,sys; b=[f for f in glob.glob('$S/*') if chr(0x2014) in open(f,encoding='utf-8',errors='replace').read()]; print('em dash in', b) if b else None; sys.exit(8 if b else 0)" || { echo "FATAL em dash"; exit 8; }
open(ohc, "w").write(hc); open(ol2, "w").write(l2)
print("built", len(hc), len(l2))
PY
chmod +x $S/v143p4_hc_array.sbatch $S/v143p4_l200_array.sbatch
## grid coefficient files (same delta for both classes) and D1
mk() { [ -e $W/$1 ] && { echo "REFUSE $W/$1"; exit 3; }; printf 'CLASS,delta\nSF,%s\nNSF,%s\n' "$2" "$3" > $W/$1; }
mk grid_coef_g0.csv 0 0
for p in m200:-2 m150:-1.5 m100:-1 m050:-0.5 p050:0.5 p100:1; do mk grid_coef_${p%%:*}.csv ${p#*:} ${p#*:}; done
mk senft_coef_D1.csv 0 -30
diff $B141L $S/v143p4_hc_array.sbatch > $P/logs/diff_hc_launcher.txt || true
diff $L200L $S/v143p4_l200_array.sbatch > $P/logs/diff_l200_launcher.txt || true
grep -l $'\xe2\x80\x94' $S/* && { echo "FATAL em dash"; exit 8; } || true
echo BUILD_DONE

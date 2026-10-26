# PREREG46 task wrapper (run_p45.sh with job root, driver and md5, arm case, unset line and tag changed). PREREG45 task wrapper (run_p44.sh with job root, driver and md5, arm case and tag changed). PREREG44 task wrapper: run_p41.sh (md5 d7fd3101) with job paths, log tag and driver changed and P44_STANDS exported; diff in ../diffs/.
#!/bin/bash
# PREREG41 task wrapper (run_p31.sh with job paths, arm case and log tag changed). Usage: run_p41.sh ARM MODE OUT [CELLS_CSV]. The environment block is PREREG28b run_task_p28b.sh
# (md5 3969483d) verbatim from OMP_NUM_THREADS to the unset line (the bench141 v141LT block: IMULT 2.5, no height form, no
# threshold matching, QC_AFAC 0.111, SRC_TST UNKNOWN for qc_c). Changes against it (diff in ../diffs/): no taskmap or chunk
# rows (the frames are qc_c, read whole), V141_REPORT_DIR and CONFIG_TAG redirected into ~/jobs/v142p31, TREE_OUT unset,
# the arm case below, and the PREREG31 driver in place of the runner. Arms:
#   qc141       QC_AFAC=0.111 everywhere, no QC_AFAC_SMALL/LARGE/KNOT   (14.1 as shipped; the reference)
#   p28b_small  QC_AFAC=0.111 QC_AFAC_SMALL=1.265 QC_AFAC_LARGE=0.111 QC_AFAC_KNOT=25 (PREREG28b, the candidate)
# Refuses to overwrite. No coordinates. No em dashes.
set -euo pipefail
ARM=$1; MODE=$2; OUT=$3; CELLS=${4:-}
[ ! -e "$OUT" ] || { echo "REFUSE $OUT exists"; exit 3; }
export HOME=/home/aaron/jobs/v142p28b/home; R1=$HOME; SET=qc_c
FR=$HOME/magplot/verify/gydbreg20260916/frames
export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
unset CHUNK_FROM CHUNK_TO STAND_KEEP_FILE || true
export CONFIG_TAG=/home/aaron/jobs/v142p46/logs/tag_${ARM}_${MODE}
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; }
export OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=1 R_LIBS_USER=/home/aaron/R/x86_64-pc-linux-gnu-library/4.5
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18 V132=0 INDOMAIN=1
chk $HOME/magplot/verify/p4e/model_b0b1b2.r 04a0b71da081ae98d1473391c9976896
chk $HOME/AcadianGY_13.1.r 5894df6013c701d09e7ba67ba6c2f090
export ACD_V14_BASE=$HOME/magplot/verify/p4e/model_b0b1b2.r LINKED=1 LINKED_SPRE=1 LINKED_COEF=$HOME/magplot/verify/p23/v14_coef_bundle_2026-09-08.rds
chk $LINKED_COEF 4740de88af8231677d828dec8e5b753c
export MODEL_FILE=$HOME/v14_0_4_20260917/AcadianGY_14.0.4.r; chk $MODEL_FILE 61f95d99f896e8e513930d6e33a7391a
export DBA_V1404=1 LINKED_MODE=L2 SMALLTREE=0
export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r V141_COEF=$HOME/magplot/verify/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0 V141_REPORT_DIR=/home/aaron/jobs/v142p46/logs/counters_$ARM
chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd; chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
export LSDG_V141=1 THIN_V141=1
case "$SET" in qc_c|qc_fl) export SRC_TST=UNKNOWN ;; *) echo "FATAL set $SET not in PREREG28b"; exit 5 ;; esac
unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT QC_RH_A QC_RH_B QC_RH_RFILL QC_RH_FORM QC_RH_RMAX QC_RH_TRACE || true
case "$ARM" in
  qc141) export QC_AFAC=0.111 ;;
  qc_rh) FF=/home/aaron/jobs/v142p45/fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv; chk $FF 24cb959a3fc80f3c87761f9dc3737fd0; export QC_RH_FORM=exp QC_RH_A=$(awk -F, '$1=="a"{print $3}' $FF) QC_RH_B=$(awk -F, '$1=="b"{print $3}' $FF) QC_RH_RFILL=0.815 ;;
  qc_lz) FF=/home/aaron/jobs/v142p46/fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv; chk $FF $(cut -d" " -f1 /home/aaron/jobs/v142p46/logs/fit_md5.txt); export QC_RH_FORM=lz QC_RH_A=$(awk -F, '$1=="qc_lz" && $2=="a"{print $4}' $FF) QC_RH_B=$(awk -F, '$1=="qc_lz" && $2=="b"{print $4}' $FF) QC_RH_RFILL=0.815 ;;
  qc_ez) FF=/home/aaron/jobs/v142p46/fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv; chk $FF $(cut -d" " -f1 /home/aaron/jobs/v142p46/logs/fit_md5.txt); export QC_RH_FORM=ez QC_RH_RMAX=1.285 QC_RH_A=$(awk -F, '$1=="qc_ez" && $2=="a"{print $4}' $FF) QC_RH_B=$(awk -F, '$1=="qc_ez" && $2=="b"{print $4}' $FF) QC_RH_RFILL=0.815 ;;
  *) echo "bad ARM $ARM"; exit 2 ;;
esac
unset TREE_OUT || true
export QC_RH_TRACE=${P46_TRACE:-}
chk $HOME/runner_p28_fb.R 0a2b27421ee7b25eaab7f4591ce3af97
export P44_STANDS=$CELLS
export P31_MODE=$MODE P31_OUT=$OUT P31_ARM=$ARM P31_CELLS=$CELLS P31_NYR=${P31_NYR:-100} P31_SMD=${P31_SMD:-9.1} P31_ELEV=${P31_ELEV:-385}
D=/home/aaron/jobs/v142p46/scripts/driver_p46.R; chk $D c94794fba136dcb611541aee22cd2742
cd $HOME/magplot/verify
echo "[p46] ARM=$ARM MODE=$MODE IMULT=$IMULT QC_AFAC=$QC_AFAC SMALL=${QC_AFAC_SMALL:-unset} LARGE=${QC_AFAC_LARGE:-unset} KNOT=${QC_AFAC_KNOT:-unset} SMD=$P31_SMD ELEV=$P31_ELEV NYR=$P31_NYR start=$(date -Is)"
Rscript $D
echo "[p46] DONE $OUT end=$(date -Is)"

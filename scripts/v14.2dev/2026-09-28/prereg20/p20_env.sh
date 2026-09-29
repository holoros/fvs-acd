#!/bin/bash
# PREREG20 shared environment (sourced by run_task_p20.sh and run_retry_p20.sh). The bench141 v141LT block verbatim from
# run_task_p17.sh, with the PREREG20 changes listed in run_task_p20.sh. Parameters are the PREREG20 fixed values.
P20_B1=0.034416; P20_B2=0.005072
p20_env() { local COL=$1 SET=$2
  FR=$HOME/magplot/verify/gydbreg20260916/frames
  export PAIRS_FILE=$FR/bench_gyr_${SET}_pairs.csv INIT_FILE=$FR/bench_gyr_${SET}_tree_init.csv T2_FILE=$FR/bench_gyr_${SET}_tree_t2.csv SITE_FILE=$FR/bench_gyr_${SET}_site_esi.csv
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
  export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0 V141_REPORT_DIR=$HOME/tables/counters_$COL
  chk $V141_FILE 0bf27dde81240e6bdf59c9a90f0051bd; chk $V141_COEF c8f02f5841e98b93cb532b6fa9b1fc51
  export LSDG_V141=1 THIN_V141=1
  unset TST_FILE TST_COL SRC_TST HTFIX_B HTFIX_B1 HTFIX_B2 ING_MIN_FROM_SCORE || true
  case "$SET" in
    ns_c|ns_fl|ns_long_c|ns_long_fl) export SRC_TST=UNKNOWN ;;
    memat_c) export TST_FILE=$HOME/work/v142_bench141_tst_memat_c_DATA_2026-09-25.csv TST_COL=TST; chk $TST_FILE 34c37d29f5601f4e509565035d7582cd ;;
    *) echo "FATAL set $SET not in PREREG20"; exit 5 ;;
  esac
  case "$COL" in
    g0_off) : ;;                                              # correction switched off: must reproduce frozen v141LT
    v141LTf|ctl_memat) export HTFIX_B1=$P20_B1 HTFIX_B2=$P20_B2 ;;
    *) echo "bad COL $COL"; exit 2 ;;
  esac
  RUNNER=$HOME/runner_p20_fb.R; chk $RUNNER 65392afbbe67e2e80524855fea7a41da
}

#!/bin/bash
# PREREG30 smoke: the first 3 fold B ns_long_c stands of task 1, v141LT (g0_off), to out_smoke/. Load gated. No em dashes.
set -euo pipefail
cd $HOME; gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }; gate
source $HOME/p20_env.sh; p20_env g0_off ns_long_c
head -4 work/keep/keep_ns_long_c_c001.csv > work/keep_smoke.csv; export STAND_KEEP_FILE=$HOME/work/keep_smoke.csv
mkdir -p out_smoke; export CONFIG_TAG=$HOME/out_smoke/s001 TREE_OUT=$HOME/out_smoke/s001
[ ! -e "${CONFIG_TAG}_results.csv" ] || { echo REFUSE; exit 3; }
cd $HOME/magplot/verify; Rscript $RUNNER; echo SMOKE_DONE

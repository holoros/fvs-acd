#!/bin/bash
# PREREG49 trace gate TR, run part. Two stands, picked by rule before any engine run: ns_c, NS_OP, fold A (PREREG22 fold rule),
# interval_years at or above 4 (so three traced years each have a following call), RUN_OK 1 in frozen v141LTfi, sorted by
# STAND, the first two. They run alone BY NAME (STAND_KEEP_FILE) under arm v141LTfis (the fitted theta) with the overlay trace
# hook on, through the task driver rewritten as the PREREG38 retry rewrite does (taskmap row and chunk lines replaced).
# Writes out/tr/ (stand file and trace are SERVERONLY). Usage: bash tr_p49.sh. Refuses to overwrite. No em dashes.
set -euo pipefail
J=${P49_ROOT:-/home/aaron/jobs/v142p49}; H=$J/home; O=$J/out/tr
[ -e $O ] && { echo "REFUSE $O exists"; exit 3; }; mkdir -p $O
D=$J/scripts/run_task_p49.sh; echo "4efa7a9f332255654915c7ae7f70ec44  $D" | md5sum -c --quiet - || { echo "FATAL driver md5"; exit 4; }
Rscript -e 'suppressMessages({library(data.table); library(digest)}); a <- commandArgs(TRUE)
  f <- "/home/aaron/jobs/v142p22/results/v141LTfi/gyr_v141LTfi_ns_c_results.csv"; stopifnot(unname(tools::md5sum(f)) == "9fe608de2e4261bd60d637019c83022e")
  r <- fread(f, select = c("STAND", "SITE", "RUN_OK", "interval_years"))[, `:=`(STAND = as.character(STAND), SITE = as.character(SITE))]
  fold <- function(site) ifelse(strtoi(substr(vapply(site, function(z) digest(z, algo = "md5", serialize = FALSE), ""), 1, 1), 16L) %% 2 == 0, "A", "B")
  r <- r[grepl("^NS(_LONG)?__NS_OP_", STAND) & RUN_OK == 1 & interval_years >= 4][, fold := fold(SITE)][fold == "A"][order(STAND)]
  if (nrow(r) < 2) stop("fewer than 2 TR stands"); fwrite(r[1:2, .(STAND)], a[1]); cat("TR stands picked: 2 of", nrow(r), "eligible\n")' $O/tr_stands_SERVERONLY.csv
TMP=$H/work/drv_tr_p49.sh; [ -e $TMP ] && { echo "REFUSE $TMP"; exit 3; }
sed -e "s|^ROW=.*|ROW=\"v141LTfis,0,ns_c,0,0\"|" -e "s|^export CHUNK_FROM=.*|unset CHUNK_FROM CHUNK_TO \|\| true; export STAND_KEEP_FILE=$O/tr_stands_SERVERONLY.csv|" \
    -e "s|c\$(printf %03d \$CHUNK)|ctr|" $D > $TMP
grep -q "STAND_KEEP_FILE=$O/tr_stands_SERVERONLY.csv" $TMP && grep -q "/ctr" $TMP || { echo "FATAL driver rewrite failed"; exit 6; }
OUTROOT=out_tr P49_TRACE=$O/trace_SERVERONLY.csv HOME=$H bash $TMP tr > $J/logs/task_tr.log 2>&1
[ -s $O/trace_SERVERONLY.csv ] || { echo "FATAL no trace written"; exit 7; }
echo TR_RUN_DONE

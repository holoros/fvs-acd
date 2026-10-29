#!/bin/bash
# PREREG17 revision 2: rerun, alone, every stand of arm $1 whose FAIL_REASON is a host time limit, up to three attempts.
# Attempt k reruns the stands still timed out after attempt k-1. Usage: HOME=<bundle home> bash retry_timeouts_p17.sh <COL>
# Writes out_retry_a<k>/ only; never touches out/. No coordinates. No em dashes.
set -uo pipefail
COL=$1; cd $HOME; FR=$HOME/magplot/verify/gydbreg20260916/frames; L=$HOME/logs/retry_$COL.log
todo() { # list "SET ROW" still timed out, reading the latest file for each stand
  for f in out/$COL/*/c*_results.csv; do s=$(basename $(dirname $f))
    grep -a 'reached elapsed time limit' $f | cut -d, -f1 | tr -d '"' | while read st; do
      row=$(awk -F, -v st="$st" 'NR>1 { gsub(/"/, "", $1); if ($1 == st) { print NR - 1; exit } }' $FR/bench_gyr_${s}_pairs.csv)
      last=""; for k in 1 2 3; do g=out_retry_a$k/$COL/$s/c$(printf %04d $row)_results.csv; [ -e $g ] && last=$g; done
      if [ -z "$last" ] || grep -aq 'reached elapsed time limit' $last; then echo "$s $row"; fi
    done; done; }
for k in 1 2 3; do
  todo | while read s row; do
    [ -e out_retry_a$k/$COL/$s/c$(printf %04d $row)_results.csv ] && continue
    echo "attempt $k $COL $s row $row start $(date -Is)" >> $L
    bash run_retry_p17.sh $COL $s $row $k >> $L 2>&1; echo "attempt $k $COL $s row $row exit $? $(date -Is)" >> $L
  done
done
echo "RETRY_DONE $COL remaining: $(todo | wc -l)" >> $L

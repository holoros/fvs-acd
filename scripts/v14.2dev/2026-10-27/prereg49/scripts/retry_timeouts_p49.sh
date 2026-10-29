#!/bin/bash
# PREREG38 (copy of PREREG28b retry_timeouts_p28b.sh md5 c2988f6a; strict load test). PREREG28b (copy of PREREG28 retry_timeouts_p28.sh). PREREG28 (copy of PREREG23 retry_timeouts_p23.sh, itself a copy of PREREG19 retry_timeouts_p19.sh): rerun, alone and BY NAME, every stand of arm $1 whose FAIL_REASON is the host time limit, up to three attempts.
# Pattern of ~/jobs/v142p17/home/retry_timeouts_p17_rev2.sh with the PREREG19 driver and a load gate. No em dashes.
set -uo pipefail
COL=$1; cd $HOME; L=$HOME/logs/retry_$COL.log
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
cid() { printf %s "$1" | cksum | cut -d' ' -f1; }
todo() { for f in out/$COL/*/c*_results.csv; do s=$(basename $(dirname $f))
    grep -a 'reached elapsed time limit' $f | cut -d, -f1 | tr -d '"' | while read st; do id=$(cid "$st")
      last=""; for k in 1 2 3; do g=out_retry_a$k/$COL/$s/c${id}_results.csv; [ -e $g ] && last=$g; done
      if [ -z "$last" ] || grep -aq 'reached elapsed time limit' $last; then echo "$s $st"; fi
    done; done; }
for k in 1 2 3; do
  todo | while read s st; do id=$(cid "$st")
    [ -e out_retry_a$k/$COL/$s/c${id}_results.csv ] && continue
    gate; echo "attempt $k $COL $s $st start $(date -Is)" >> $L
    bash ${P49_ROOT:-/home/aaron/jobs/v142p49}/scripts/run_retry_p49.sh $COL $s "$st" $k >> $L 2>&1; echo "attempt $k $COL $s $st exit $? $(date -Is)" >> $L
  done
done
echo "RETRY_DONE $COL remaining: $(todo | wc -l)" >> $L

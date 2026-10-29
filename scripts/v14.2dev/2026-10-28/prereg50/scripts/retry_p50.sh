#!/bin/bash
# PREREG50 retry rule (PREREG19 rule, run_retry_p19.sh and retry_timeouts_p19.sh): every stand of arms g2, e1 and s2 whose
# FAIL_REASON is the host time limit is rerun alone, by name (stand file), up to three attempts, into out_retry_a<k>; the
# latest attempt replaces it when results are read. One R process at a time, none started at load 12 or above. Stand names
# go only to _SERVERONLY files; the summary line printed to stdout carries counts only. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p50; H=$J/home; S=$J/scripts; cd $H; mkdir -p work/retry_keep
gate() { while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 60; done; }
cid() { printf %s "$1" | cksum | cut -d' ' -f1; }
todo() { local A=$1; for f in out/$A/qc_c/c*_SERVERONLY_results.csv; do [ -e "$f" ] || continue
    grep -a 'elapsed time limit' $f | cut -d, -f1 | tr -d '"' | while read st; do id=$(cid "$st"); last=""
      for k in 1 2 3; do g=out_retry_a$k/$A/qc_c/c${id}_SERVERONLY_results.csv; [ -e $g ] && last=$g; done
      if [ -z "$last" ] || grep -aq 'elapsed time limit' $last; then echo "$st"; fi; done; done; }
for A in g2 e1 s2; do
  L=logs/retry_${A}_SERVERONLY.log; n0=$(todo $A | wc -l)
  for k in 1 2 3; do
    todo $A | while read st; do id=$(cid "$st"); [ -e out_retry_a$k/$A/qc_c/c${id}_SERVERONLY_results.csv ] && continue
      KF=work/retry_keep/${A}_${id}_SERVERONLY.csv; printf 'STAND\n%s\n' "$st" > $KF
      gate; echo "attempt $k $A $st start $(date -Is)" >> $L
      HOME=$H OUTROOT=out_retry_a$k bash $S/run_task_p50.sh keep $A $H/$KF c$id >> $L 2>&1; echo "attempt $k $A $st exit $? $(date -Is)" >> $L
    done
  done
  echo "retry $A: $n0 stands hit the time limit in the main run; $(todo $A | wc -l) remain after the retry rule"
done

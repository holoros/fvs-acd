#!/bin/bash
# load gated launcher for the PREREG31 re-derivation (1 minute load average below 12). No em dashes.
cd /home/aaron/jobs/v142p31/verify_20260930
while awk '{exit !($1 >= 12)}' /proc/loadavg; do sleep 30; done
echo "start $(date -Is) load $(cut -d" " -f1 /proc/loadavg)" >> rederive_p31.log
Rscript rederive_p31.R >> rederive_p31.log 2>&1; rc=$?; echo "exit $rc $(date -Is)" >> rederive_p31.log; exit $rc

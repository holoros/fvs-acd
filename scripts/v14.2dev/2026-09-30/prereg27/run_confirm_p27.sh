#!/bin/bash
# PREREG27: run the confirmation once the 1 minute load is at or below 12 (the track load rule). One R process. No em dashes.
cd /home/aaron/jobs/v142p27
while awk '{exit !($1 > 12)}' /proc/loadavg; do sleep 30; done
echo "confirm start $(date -Is) load $(cut -d' ' -f1 /proc/loadavg)" >> logs/chain.txt
P27_PREREG_MD5=8ef3d6e37641f4dd1637c0c2de43386b Rscript scripts/2026-09-30_v142_p27_confirm.R > logs/confirm.txt 2>&1; rc=$?
echo "confirm exit $rc $(date -Is)" >> logs/chain.txt; [ $rc -eq 0 ] && echo "CHAIN_DONE $(date -Is)" >> logs/chain.txt

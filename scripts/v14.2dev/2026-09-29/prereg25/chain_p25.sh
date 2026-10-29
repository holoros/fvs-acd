#!/bin/bash
# PREREG25 chain: diagnostic confirmation only (no engine arm; see the pre-registration). Waits for the 1 minute load to be
# at or below 14, checks the pre-registration md5, runs the confirmation script, which refuses to overwrite assembled/.
# Nothing else is launched. No em dashes.
J=/home/aaron/jobs/v142p25; cd $J
export P25_PREREG_MD5=2f7f4a152a186766bdcc61184fa3e515 OMP_NUM_THREADS=1 R_DATATABLE_NUM_THREADS=2
while awk '{exit !($1 > 14)}' /proc/loadavg; do sleep 60; done
echo "start $(date -Is) load $(cut -d' ' -f1 /proc/loadavg)" >> logs_chain.txt
echo "$P25_PREREG_MD5  prereg/2026-09-29_v142_ns-small-tree-height_PREREG25.md" | md5sum -c - >> logs_chain.txt 2>&1 || { echo "PREREG MD5 FAIL" >> logs_chain.txt; exit 4; }
echo "6b72fd0cc37c36dc3a6932602f03cd72  scripts/2026-09-29_v142_p25_confirm.R" | md5sum -c - >> logs_chain.txt 2>&1 || { echo "SCRIPT MD5 FAIL" >> logs_chain.txt; exit 4; }
[ -e assembled ] && { echo "REFUSE assembled exists" >> logs_chain.txt; exit 5; }
Rscript scripts/2026-09-29_v142_p25_confirm.R > logs_confirm.txt 2>&1; echo "confirm exit $? $(date -Is)" >> logs_chain.txt
echo CHAIN_DONE >> logs_chain.txt

#!/bin/bash
# PREREG27 verify: after CHAIN_DONE, when the 1 minute load is at or below 12. No em dashes.
cd /home/aaron/jobs/v142p27
until grep -q CHAIN_DONE logs/chain.txt 2>/dev/null; do sleep 30; done
while awk '{exit !($1 > 12)}' /proc/loadavg; do sleep 30; done
Rscript verify_20260930/2026-09-30_v142_p27_verify.R > verify_20260930/verify_log.txt 2>&1; echo "verify exit $? $(date -Is)" >> logs/chain.txt

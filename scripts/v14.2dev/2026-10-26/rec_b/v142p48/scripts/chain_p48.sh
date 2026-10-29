#!/bin/bash
## PREREG48 chain: step 1 split (T0, T1, per stand components) then step 2 shares and gates. One R process at a time;
## refuses to start a step at 1 minute load 12 or above (waits up to 30 minutes). Assembly is a separate step.
J=/home/aaron/jobs/v142p48; OUT=${1:-$J/out}; MODE=${2:-}
cd $J || exit 1
waitload() { for i in $(seq 1 60); do l=$(cut -d' ' -f1 /proc/loadavg); if awk -v l=$l 'BEGIN{exit !(l<12)}'; then return 0; fi; echo "load $l, waiting"; sleep 30; done; echo "LOAD GATE TIMEOUT"; exit 4; }
echo "chain start $(date -Iseconds) out=$OUT mode=$MODE"
waitload; echo "split start $(date -Iseconds) load $(cut -d' ' -f1 /proc/loadavg)"
Rscript scripts/p48_split.R $OUT $MODE || { echo "SPLIT FAILED $(date -Iseconds)"; exit 2; }
waitload; echo "boot start $(date -Iseconds) load $(cut -d' ' -f1 /proc/loadavg)"
Rscript scripts/p48_boot.R $OUT $OUT || { echo "BOOT FAILED $(date -Iseconds)"; exit 3; }
echo "CHAIN_DONE $(date -Iseconds)"

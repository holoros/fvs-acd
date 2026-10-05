#!/bin/bash
# Starts PREREG45b stage 2 once stage 1 has finished cleanly; does nothing on a stage 1 stop. No em dashes.
L=/home/aaron/jobs/v142p45b/logs/chain.txt
until grep -q "CHAIN_S1_DONE\|CHAIN_STOP" $L; do sleep 60; done
grep -q CHAIN_STOP $L && exit 0
bash /home/aaron/jobs/v142p45b/scripts/chain_p45b_s2.sh

#!/bin/bash
# PREREG20 chain: after the main run writes ALL_DONE, retry host time limit stands BY NAME for every column, then G0 and the
# Maine control, scoring (C0, C1, structure, TOPHT), H2, and assembly. Each step logs; nothing is overwritten. No em dashes.
J=/home/aaron/jobs/v142p20; H=$J/home
until grep -q ALL_DONE $H/logs/_status.txt 2>/dev/null; do sleep 300; done
echo "main done $(date -Is)" >> $J/logs_chain.txt
for c in g0_off ctl_memat v141LTf; do HOME=$H bash $H/retry_timeouts_p20.sh $c; echo "retry $c done $(date -Is): $(tail -1 $H/logs/retry_$c.log)" >> $J/logs_chain.txt; done
cd $J
Rscript scripts/2026-09-28_v142_p20_g0ctl.R > logs_g0ctl.txt 2>&1; echo "g0ctl exit $? $(date -Is)" >> logs_chain.txt
bash scripts/run_score_p20.sh > logs_score.txt 2>&1; echo "score exit $? $(date -Is)" >> logs_chain.txt
Rscript scripts/2026-09-28_v142_p20_h2.R > logs_h2.txt 2>&1; echo "h2 exit $? $(date -Is)" >> logs_chain.txt
Rscript scripts/2026-09-28_v142_p20_assemble.R > logs_assemble.txt 2>&1; echo "assemble exit $? $(date -Is)" >> logs_chain.txt
echo CHAIN_DONE >> logs_chain.txt

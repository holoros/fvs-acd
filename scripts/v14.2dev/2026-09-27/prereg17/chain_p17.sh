#!/bin/bash
# PREREG17: after the main run writes ALL_DONE, retry host time limit stands of v141LTig_m30 (revision 2), then score the arm
# (run_score_fb_rev2.sh). Each step logs; nothing is overwritten. No em dashes.
J=/home/aaron/jobs/v142p17; H=$J/home
until grep -q ALL_DONE $H/logs/_status.txt 2>/dev/null; do sleep 300; done
echo "main done $(date -Is)" >> $J/logs_chain.txt
HOME=$H bash $H/retry_timeouts_p17_rev2.sh v141LTig_m30; echo "retry done $(date -Is): $(tail -1 $H/logs/retry_v141LTig_m30.log)" >> $J/logs_chain.txt
cd $J && bash scripts/run_score_fb_rev2.sh > $J/logs_score_fb.txt 2>&1; echo "score exit $? $(date -Is)" >> $J/logs_chain.txt

#!/bin/bash
# PREREG31 chain resume after the assembly stop (type fix in the reported dht.mult table, diffs/assemble_p31.R.typefix.diff).
# Runs only the steps after g0record of chain_p31.sh, unchanged: assembly, load gated re-derivation, figures. No em dashes.
J=/home/aaron/jobs/v142p31; LOG=$J/logs/chain.txt; S=$J/scripts
step() { local n=$1; shift; "$@"; local rc=$?; echo "$n exit $rc $(date -Is)" >> $LOG; [ $rc -eq 0 ] || { echo "CHAIN_STOP at $n (exit $rc) $(date -Is)" >> $LOG; exit $rc; }; }
cd $J; echo "chain resume $(date -Is) pid=$$" >> $LOG; mv $J/logs/assemble.log $J/logs/assemble_attempt1_typeerror.log
step assemble bash -c "P31_PLAN_MD5=$(cut -d' ' -f1 $J/logs/prereg_md5.txt | tail -1) Rscript $S/assemble_p31.R > $J/logs/assemble.log 2>&1"
echo "outcome $(grep '^outcome=' $J/assembled/gyr142-p31-verdict_DATA_2026-09-30.txt | cut -d= -f2)" >> $LOG
step verify bash $J/verify_20260930/run_rederive_p31.sh
step figures bash -c "Rscript $J/figs/fig_p31.R > $J/logs/figures.log 2>&1"
echo "CHAIN_DONE $(date -Is)" >> $LOG

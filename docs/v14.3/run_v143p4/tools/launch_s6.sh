#!/bin/bash
# PREREG4 step 6 launch: after the selection record exists, the candidate arms of every eligible form (coefficient file present
# and its md5 in launch_md5s.txt) on the 19 sets (62 tasks) and the 200 yr frame (31 tasks), and the diagnostic arm D1 on the
# 200 yr frame (31 tasks). Job ids to logs/chain_s6_jobs.txt. Refuses if that file exists or the selection record is absent.
# No em dashes.
set -euo pipefail
P=/users/PUOM0008/crsfaaron/v143p4; cd $P
[ -e logs/selection_md5.txt ] || { echo "REFUSE no selection record"; exit 3; }
[ -e logs/chain_s6_jobs.txt ] && { echo "REFUSE chain_s6_jobs.txt exists"; cat logs/chain_s6_jobs.txt; exit 3; }
L="$(date +%Y-%m-%dT%H:%M:%S%z)"
for F in L S; do
  if [ -e work/senft_coef_$F.csv ] && grep -q "work/senft_coef_$F.csv" logs/launch_md5s.txt; then
    a=$(V143_TASKMAP=$P/work/taskmap_hc_cand$F.csv sbatch --parsable --array=1-62 scripts/v143p4_hc_array.sbatch)
    b=$(V143_TASKMAP=$P/work/taskmap_l200_cand$F.csv sbatch --parsable --array=1-31 scripts/v143p4_l200_array.sbatch)
    L="$L hc_cand$F $a l200_cand$F $b"
  else L="$L cand$F not_eligible"; fi
done
d=$(V143_TASKMAP=$P/work/taskmap_l200_D1.csv sbatch --parsable --array=1-31 scripts/v143p4_l200_array.sbatch)
echo "$L l200_D1 $d" | tee logs/chain_s6_jobs.txt

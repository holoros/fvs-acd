#!/bin/bash
# PREREG4 step 4 launch: harness arm off on the 19 sets (62 tasks) and on the 200 yr frame (31 tasks), the fold A grid (26 tasks);
# identity checks H1a, H1b, H2 and the fit with its selection record, each after the runs it needs (afterok). Job ids to
# logs/chain_s4_jobs.txt. Refuses if that file exists. No em dashes.
set -euo pipefail
P=/users/PUOM0008/crsfaaron/v143p4; cd $P
[ -e logs/chain_s4_jobs.txt ] && { echo "REFUSE chain_s4_jobs.txt exists"; cat logs/chain_s4_jobs.txt; exit 3; }
J1=$(V143_TASKMAP=$P/work/taskmap_hc_off.csv sbatch --parsable --array=1-62 scripts/v143p4_hc_array.sbatch)
J2=$(V143_TASKMAP=$P/work/taskmap_hc_grid.csv sbatch --parsable --array=1-26 scripts/v143p4_hc_array.sbatch)
J3=$(V143_TASKMAP=$P/work/taskmap_l200_off.csv sbatch --parsable --array=1-31 scripts/v143p4_l200_array.sbatch)
J4=$(sbatch --parsable --job-name=v143p4H1a --dependency=afterok:$J1 tools/cmp_all.sbatch H1a)
J5=$(sbatch --parsable --job-name=v143p4H2 --dependency=afterok:$J2 tools/cmp_all.sbatch H2)
J6=$(sbatch --parsable --job-name=v143p4H1b --dependency=afterok:$J3 tools/cmp_all.sbatch H1b)
J7=$(sbatch --parsable --job-name=v143p4fit --dependency=afterok:$J2 tools/fit_record.sbatch)
echo "$(date +%Y-%m-%dT%H:%M:%S%z) hc_off $J1 hc_grid $J2 l200_off $J3 cmp_H1a $J4 cmp_H2 $J5 cmp_H1b $J6 fit $J7" | tee logs/chain_s4_jobs.txt

set -euo pipefail
cd /users/PUOM0008/crsfaaron/howland_decline_20261028
ls agg; [ ! -e agg_PREV_20261028 ] && mv agg agg_PREV_20261028
ls fig work_SERVERONLY | wc -l
{ md5sum scripts/2026-10-28_hd_assemble_r1.R scripts/howland_decline_assemble_r1.slurm scripts/launch_r1.sh; echo "recorded r1 $(date -Is) (assembly r0 15945902 failed at kv(), agg moved to agg_PREV_20261028)"; } >> logs/launch_md5s.txt
J=$(sbatch --parsable scripts/howland_decline_assemble_r1.slurm); echo "assemble_r1 $J $(date -Is)" >> logs/jobs.txt
tail -5 logs/launch_md5s.txt; tail -2 logs/jobs.txt

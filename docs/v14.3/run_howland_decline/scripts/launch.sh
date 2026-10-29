set -euo pipefail
cd /users/PUOM0008/crsfaaron/howland_decline_20261028
[ ! -e logs/launch_md5s.txt ] || { echo REFUSE launch_md5s exists; exit 3; }
{ md5sum scripts/2026-10-28_hd_runner.R scripts/2026-10-28_hd_trajhooks_fx.R scripts/2026-10-28_hd_fx_block.R scripts/howland_decline_array.slurm scripts/2026-10-28_hd_assemble.R scripts/howland_decline_assemble.slurm scripts/2026-10-28_hd_build.sh scripts/2026-10-28_hd_build_verify.sh scripts/launch.sh; echo "recorded $(date -Is)"; } > logs/launch_md5s.txt
J=$(sbatch --parsable scripts/howland_decline_array.slurm); echo "array $J $(date -Is)" >> logs/jobs.txt
J2=$(sbatch --parsable --dependency=afterany:$J scripts/howland_decline_assemble.slurm); echo "assemble $J2 after $J $(date -Is)" >> logs/jobs.txt
cat logs/launch_md5s.txt logs/jobs.txt

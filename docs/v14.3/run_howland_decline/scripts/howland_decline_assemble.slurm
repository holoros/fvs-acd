#!/bin/bash
#SBATCH --job-name=hd_assemble
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/howland_decline_20261028/logs/hd_assemble_%j.out
# Howland decline diagnostic, assembly (28 October 2026). Runs only if the assembly script md5 is recorded in
# logs/launch_md5s.txt. Its log prints aggregates and key numbers only. No em dashes.
set -euo pipefail
A=/users/PUOM0008/crsfaaron/howland_decline_20261028
S=$A/scripts/2026-10-28_hd_assemble.R
grep -q "^$(md5sum $S | cut -d' ' -f1) " $A/logs/launch_md5s.txt || { echo "FATAL assembly md5 not recorded"; exit 4; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=2 R_DATATABLE_NUM_THREADS=2
echo "[hd_assemble] start $(date -Is) md5 $(md5sum $S | cut -c1-32)"
Rscript $S
echo "[hd_assemble] DONE $(date -Is)"

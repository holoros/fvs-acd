#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=48G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p4/logs/%x_%j.out
# PREREG4 generic R step: checks the script md5 against logs/launch_md5s.txt (or logs/assemble_md5.txt), then runs it. No em dashes.
set -euo pipefail
P=/users/PUOM0008/crsfaaron/v143p4; S=$1; shift
W=$(awk -v f="scripts/$(basename $S)" '$2==f {print $1}' $P/logs/launch_md5s.txt $P/logs/assemble_md5.txt 2>/dev/null | tail -1)
M=$(md5sum $P/scripts/$(basename $S) | cut -d' ' -f1)
[ -n "$W" ] && [ "$W" = "$M" ] || { echo "FATAL md5 of $S ($M) not recorded"; exit 4; }
echo "md5 ok $S $M start=$(date -Is)"
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
Rscript --vanilla $P/scripts/$(basename $S) "$@"
echo "end=$(date -Is)"

#!/bin/bash
#SBATCH --job-name=v143p3asm
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=00:20:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=1 --mem=4G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p3/logs/assemble_%j.out
set -euo pipefail
R3=/users/PUOM0008/crsfaaron/v143p3
W=$(awk '$2=="scripts/v143p3_assemble.R" {print $1}' $R3/logs/launch_md5s.txt | tail -1); M=$(md5sum $R3/scripts/v143p3_assemble.R | cut -d' ' -f1)
[ "$W" = "$M" ] || { echo "FATAL assembly md5 $M != $W"; exit 4; }; echo "md5 ok assemble $M"
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
Rscript $R3/scripts/v143p3_assemble.R $R3

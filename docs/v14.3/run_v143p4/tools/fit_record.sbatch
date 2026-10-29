#!/bin/bash
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=02:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=16G
#SBATCH --output=/users/PUOM0008/crsfaaron/v143p4/logs/%x_%j.out
# PREREG4 step 5: runs v143p4_fit.R (md5 checked against logs/launch_md5s.txt), then writes the selection record line
# logs/selection_md5.txt (time and md5 of the selection, R and harness tables and of each coefficient file written) and appends
# the coefficient file md5s to logs/launch_md5s.txt, so the candidate launchers can check them. Refuses if the record exists.
# No em dashes.
set -euo pipefail
P=/users/PUOM0008/crsfaaron/v143p4; cd $P
[ -e logs/selection_md5.txt ] && { echo "REFUSE selection record exists"; exit 3; }
W=$(awk '$2=="scripts/v143p4_fit.R" {print $1}' logs/launch_md5s.txt | tail -1); M=$(md5sum scripts/v143p4_fit.R | cut -d' ' -f1)
[ "$W" = "$M" ] || { echo "FATAL fit md5"; exit 4; }
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
echo "fit md5 ok $M start=$(date -Is)"
Rscript --vanilla scripts/v143p4_fit.R
T=$(date +%Y-%m-%dT%H:%M:%S%z)
{ echo "# PREREG4 selection record, recorded $T after v143p4_fit.R (md5 $M) and before any candidate run or fold B read."
  md5sum assembled/v143p4_selection_DATA_2026-10-28.csv assembled/v143p4_fit_R_DATA_2026-10-28.csv assembled/v143p4_fit_harness_DATA_2026-10-28.csv
  for f in work/senft_coef_L.csv work/senft_coef_S.csv; do [ -e $f ] && md5sum $f || echo "absent  $f  (form not eligible)"; done; } > logs/selection_md5.txt
chmod 444 logs/selection_md5.txt
for f in work/senft_coef_L.csv work/senft_coef_S.csv; do [ -e $f ] && echo "$(md5sum $f)  # appended $T at the selection record" >> logs/launch_md5s.txt; done
cat logs/selection_md5.txt
echo FIT_RECORD_DONE

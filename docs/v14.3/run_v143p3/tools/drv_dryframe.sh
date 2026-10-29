cd ~/v143p3
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
Rscript -e 'for (f in c("scripts/v143p3_fitframe.R","scripts/v143p3_fit.R")) { invisible(parse(f)); cat("parse ok", f, "\n") }'
V143P3_ROOT=$HOME/v143p3/dry sbatch --job-name=v143p3dryframe tools/s2_frame.sbatch

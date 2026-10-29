cd ~/v143p3
mkdir -p dry2/work && cp -p dry/work/fitframe3_SERVERONLY.rds dry2/work/
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
Rscript -e 'invisible(parse("scripts/v143p3_fit.R")); invisible(parse("scripts/v143p3_assemble.R")); cat("parse ok\n")'
V143P3_ROOT=$HOME/v143p3/dry2 V143P3_DRY=1 V143P3_VARIANT=primary sbatch --job-name=v143p3dryfit2 --cpus-per-task=16 --mem=32G --time=02:00:00 tools/s3_fit.sbatch

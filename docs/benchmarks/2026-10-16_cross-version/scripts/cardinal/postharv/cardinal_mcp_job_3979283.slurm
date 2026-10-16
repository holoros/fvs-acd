#!/bin/bash
#SBATCH --job-name=mefiaph_build
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --time=01:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4 --mem=48G
#SBATCH --output=/users/PUOM0008/crsfaaron/acdx_20261016/postharv/logs/%x_%j.out
# Frame build for mefia_ph_c. R 4.4.0 with gdal/proj/geos, the environment of ~/gydb_ws/cov/build_cov.R,
# because terra in the R 4.5.2 library links a GDAL/PROJ that is not on the module path. No em dashes.
set -euo pipefail
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 gdal/3.7.3 proj/9.2.1 geos/3.12.0 R/4.4.0
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/cardinal/4.4.0
cd /users/PUOM0008/crsfaaron/acdx_20261016/postharv/work
Rscript /users/PUOM0008/crsfaaron/acdx_20261016/postharv/scripts/2026-10-16_mefia_ph_frame_builder.R


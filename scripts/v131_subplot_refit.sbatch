#!/bin/bash
#SBATCH --account=puom0008
#SBATCH --job-name=v131sp_prod
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=3-00:00:00
#SBATCH --output=/users/PUOM0008/crsfaaron/v13_subplot/v131sp_prod_%j.log
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu
set -euo pipefail
## 4 chains x threading(8) = 32 cores; 72 h wall covers recruitment + mortality run
## in one job with margin. DO NOT launch while job 12526556 (v131r_mortB_*) writes ~/v13_kickoff.
module purge
module load gcc/12.3.0
module load gdal/3.7.3 geos/3.12.0 proj/9.2.1
module load R/4.4.0
cd /users/PUOM0008/crsfaaron/v13_subplot
Rscript --vanilla /users/PUOM0008/crsfaaron/v131_subplot_refit.R

#!/bin/bash
#SBATCH --job-name=v131refit
#SBATCH --time=08:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=8
#SBATCH --account=PUOM0008
#SBATCH --output=logs/v131refit_%j.out
#SBATCH --error=logs/v131refit_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

module load gcc/12.3.0
module load gdal/3.7.3 geos/3.12.0 proj/9.2.1
module load R/4.4.0

mkdir -p logs
Rscript --vanilla v131_mort_ingrowth_refit.R

#!/bin/bash
#SBATCH --job-name=v130joint
#SBATCH --time=02:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=8
#SBATCH --account=PUOM0008
#SBATCH --output=logs/v130joint_%j.out
#SBATCH --error=logs/v130joint_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu

module load gcc/12.3.0
module load gdal/3.7.3 geos/3.12.0 proj/9.2.1
module load R/4.4.0

mkdir -p logs
Rscript --vanilla v130_joint_anchor.R

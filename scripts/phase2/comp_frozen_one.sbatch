#!/bin/bash
#SBATCH --job-name=comp1
#SBATCH --account=puom0008
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=comp1_%j.out
# Single-model species-composition harness on the FROZEN canon.
# Usage: sbatch --export=ALL,MODEL_FILE=...,CONFIG_TAG=... comp_frozen_one.sbatch
set -e
source /etc/profile.d/lmod.sh
module purge
module load gcc/12.3.0 R/4.4.0
cd /users/PUOM0008/crsfaaron/magplot/verify
export NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1
export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
: "${MODEL_FILE:?}" ; : "${CONFIG_TAG:?}"
echo "[comp1] MODEL_FILE=$MODEL_FILE CONFIG_TAG=$CONFIG_TAG"
Rscript bench_species_comp_frozen.R
echo "=== comp1 DONE: ${CONFIG_TAG}_results.csv ==="

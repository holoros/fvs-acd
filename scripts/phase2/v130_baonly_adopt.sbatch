#!/bin/bash
#SBATCH --job-name=v130baonly
#SBATCH --time=02:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=8
#SBATCH --account=PUOM0008
#SBATCH --output=logs/v130baonly_%j.out
#SBATCH --error=logs/v130baonly_%j.err
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=aaron.weiskittel@maine.edu
#
# FVS-ACD v13.0 Phase 2: BA-only conservative adoption candidate (cb_v130ba).
# Banks the validated BA post-mortality correction; holds dominant height at
# OPERATIONAL v12.10.1 (the height re-anchor is deferred, it PARKED at the gate).
# Calls run_v130_baonly_adopt.sh, which pins ~/v130_esi_anchor_coef.csv to the
# operational values, builds ~/AcadianGY_13.0_baonly.r from ~/AcadianGY_12.10.2.r,
# benches cb_v130ba (results cb_v130ba_results.csv, not clobbering the joint
# cb_v130_results.csv), and gates against cb_v12101. No em dashes.

set -euo pipefail

module load gcc/12.3.0
module load gdal/3.7.3
module load geos/3.12.0
module load proj/9.2.1
module load R/4.4.0

mkdir -p logs

export CONFIG_TAG=cb_v130ba
export PHASE2_DIR="$HOME/repos/fvs-acd/scripts/phase2"

bash "$PHASE2_DIR/run_v130_baonly_adopt.sh"

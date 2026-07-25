#!/bin/bash
#SBATCH --job-name=g1_indomain
#SBATCH --account=PUOM0008
#SBATCH --partition=cpu
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=01:30:00
#SBATCH --output=/users/PUOM0008/crsfaaron/logs/g1_indomain_%j.out
# =====================================================================
# g1_indomain_v1211.sbatch -- Guardrail 1 (frozen in-domain FIA NSVB no-regression)
# for the locked FVS-ACD v12.11 candidate. NEW script, does not touch the frozen
# run_bench_frozen.sh / bench_parity.R / bench_frozen.sbatch files.
#
# Produces three result files in ~/magplot/verify:
#   g1_v1211_base_results.csv        MODEL_FILE=AcadianGY_12.11.r, all V1211_* levers OFF,
#                                     SPLIT=FALSE -- should reproduce cb_v12101_results.csv
#                                     byte-for-byte (already confirmed gate-off 0.000e+00).
#   g1_v1211_cand_mgdT_results.csv   candidate levers ON, V1211_MANAGED=TRUE (all magp_qcnb
#                                     stands treated as managed, i.e. the NB-role treatment).
#   g1_v1211_cand_mgdF_results.csv   candidate levers ON, V1211_MANAGED=FALSE (the
#                                     baxter/me_fia/pef-role treatment).
# Guardrail-1 candidate is then built by taking PROV==NB rows from the mgdT run and
# PROV==QC rows from the mgdF run, matching the source-level managed flag used in the
# maturity scorecard (nb=managed, no QC entry in the named-source list => treated as
# unmanaged/developing here). Both full mgdT and mgdF pooled numbers are also reported so
# the reader can see the sensitivity to that choice.
# =====================================================================
set -uo pipefail
source /etc/profile.d/lmod.sh
module purge; module load gcc/12.3.0 R/4.4.0
export R_DATATABLE_NUM_THREADS=${SLURM_CPUS_PER_TASK:-4}
V=$HOME/magplot/verify
cd "$V"

# --- frozen canon (identical to run_bench_frozen.sh; do not edit) ---
export NB_AFAC=0.579 QC_AFAC=0.111 INDOMAIN=1
export ONSET=0.30 BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62
export MODEL_FILE=$HOME/_scripts/AcadianGY_12.11.r

echo "[g1] BASE run start $(date)"
export SPLIT=FALSE V1211_REIN=FALSE V1211_STANDCON=FALSE V1211_MORTGATE=FALSE V1211_IGTAPER=FALSE V1211_IGMULT=1.0 V1211_DHTHW=FALSE V1211_MANAGED=FALSE
export CONFIG_TAG=g1_v1211_base
Rscript bench_parity_split_ms_v1211.R
echo "[g1] BASE run done rc=$? $(date)"

echo "[g1] CANDIDATE managed=TRUE run start $(date)"
export SPLIT=TRUE V1211_IGMULT=2.5 V1211_MORTGATE=TRUE V1211_STANDCON=TRUE SC_LO=0.40 SC_HI=0.50 SC_QMIN=22 V1211_DHTHW=TRUE
export V1211_MANAGED=TRUE
export CONFIG_TAG=g1_v1211_cand_mgdT
Rscript bench_parity_split_ms_v1211.R
echo "[g1] CANDIDATE managed=TRUE done rc=$? $(date)"

echo "[g1] CANDIDATE managed=FALSE run start $(date)"
export V1211_MANAGED=FALSE
export CONFIG_TAG=g1_v1211_cand_mgdF
Rscript bench_parity_split_ms_v1211.R
echo "[g1] CANDIDATE managed=FALSE done rc=$? $(date)"

echo "[g1] aggregating $(date)"
Rscript - <<'EOF'
suppressMessages(library(data.table))
setwd("~/magplot/verify")
score <- function(o,p){ok<-is.finite(o)&is.finite(p); o<-o[ok];p<-p[ok]
  data.table(n=length(o), obs=mean(o), pred=mean(p), bias_pct=100*(mean(p)/mean(o)-1))}
base <- fread("g1_v1211_base_results.csv")
mgdT <- fread("g1_v1211_cand_mgdT_results.csv")
mgdF <- fread("g1_v1211_cand_mgdF_results.csv")
cand_mixed <- rbindlist(list(mgdT[PROV=="NB"], mgdF[PROV=="QC"]), fill=TRUE)
fwrite(cand_mixed, "g1_v1211_cand_mixed_results.csv")
mets <- c("BA","TOPHT","TOTVOL")
out <- rbindlist(lapply(list(base=base, cand_mixed=cand_mixed, cand_mgdT=mgdT, cand_mgdF=mgdF), function(d){
  rbindlist(lapply(mets, function(m) cbind(metric=m, score(d[[paste0(m,"_o")]], d[[paste0(m,"_p")]]))))
}), idcol="config")
fwrite(out, "g1_v1211_guardrail1_summary.csv")
print(out)
cat("G1_SUMMARY_DONE\n")
EOF
echo "=== g1_indomain DONE ==="

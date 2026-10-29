#!/bin/bash
#SBATCH --job-name=p37cand
#SBATCH --account=puom0008
#SBATCH --partition=cpu
#SBATCH --array=1-12
#SBATCH --time=24:00:00
#SBATCH --nodes=1 --ntasks=1 --cpus-per-task=8 --mem=32G
#SBATCH --output=/users/PUOM0008/crsfaaron/magplot/verify/p37/p37cand_%A_%a.out
#
# PASS 37 RERUN, 27 August 2026. Byte-identical to scripts/p36/2026-08-26_pv133_cand_array.sbatch
# in every lever export, produced from it by sed rather than retyped, with only the output and
# CONFIG_TAG namespace moved from p_v133/pv133_cand_<src> to p37/p37_cand_<src> and the wall clock
# raised from 08:00:00 to 24:00:00. The wall clock is raised because the original run was fast for
# the wrong reason: three quarters of its stands errored inside calc_ddbh within milliseconds and
# were discarded, so its elapsed times are not a guide to the cost of actually projecting them.
# The engines this run loads carry the 27 August 2026 vectorization fixes (the calc_ddbh
# ddbh_hw_mod call site, and the tsurv_hw_mod call-site NA guard that the first fix unmasked).
# Both fixes are unit-proven behaviour-neutral, see scripts/p37/p37_vecfix_unit_probe_2026-08-27.R
# and scripts/p37/p37_tsurv_unit_probe_2026-08-27.R.
#
# v13.3 benchmark, ARM B (candidate): identical to 2026-08-26_pv133_prodhw_array.sbatch (ARM A) in
# every export except MODEL_FILE, which points at model_b0b1b2_v133.r instead of model_b0b1b2.r.
# That overlay sources AcadianGY_13.3.r (v13.1 plus the v13.3 AB/WA growth and SM-survival-
# investigated hardwood form/risk gap-fill; see scripts/AcadianGY_13.3_DRAFT.r in the repo and its
# 13.3 (DRAFT) changelog entry) in place of AcadianGY_13.1.r, then applies the identical b0/b1/b2
# ddbh() patch on top. use.hw.mod is ON in both arms (USE_MODS=TRUE) so the pre-existing six-species
# Castle modifier (RO/SM/YB/RM/PB/QA growth, QA/RM/RO/YB/PB survival) is active identically in both;
# confirmed byte-identical for those six species between AcadianGY_13.1.r and AcadianGY_13.3.r by
# direct unit test on Cardinal before this job was ever submitted (max abs diff 0 across a form x
# risk x dbh x bal grid). The only cells that can possibly differ between ARM A and ARM B are trees
# of species AB or WA (growth); SM carries no survival modifier in either arm (investigated and not
# added, see the changelog). Sources with none of AB/WA/SM present are expected to be identical
# between the two arms BY CONSTRUCTION, and are included in this run as a confirmation of that, not
# skipped, per the brief.
#
# Output naming: CONFIG_TAG is p_v133/pv133_cand_<src>, unique per array task and disjoint from
# every p36/p33/p21 tag and from ARM A's p_v133/pv133_prodhw_<src> tag. No two tasks in either arm,
# and no task in ARM A and ARM B together, ever write the same path.
set -euo pipefail
source /etc/profile.d/lmod.sh; module purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
export OMP_NUM_THREADS=8 R_DATATABLE_NUM_THREADS=8
cd $HOME/magplot/verify; MS=$HOME/magplot/verify/multisrc; P5M=$HOME/magplot/verify/p5m
P33=$HOME/magplot/verify/p33; P37=$HOME/magplot/verify/p37
mkdir -p $P37

export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export MODEL_FILE=$HOME/magplot/verify/p4e/model_b0b1b2_v133.r
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5
export LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18
export V132=1
export V1211_MORTGATE=TRUE V1211_DHTHW=FALSE
export P33_MATGATE=TRUE MATGATE_QC=12.7 MATGATE_K=0.6
export USE_MODS=TRUE

QC_ESI=/fs/scratch/PUOM0008/crsfaaron/canada/qc_esi/magp_qcnb_site_esi8_v2.csv
INDOMAIN=1

case "$SLURM_ARRAY_TASK_ID" in
  1)  SRC=memat;             PFX=$P5M/p5m_memat ;                                                                                                                                                                         MANAGED=FALSE ;;
  2)  SRC=medev;             PFX=$P5M/p5m_medev ;                                                                                                                                                                         MANAGED=FALSE ;;
  3)  SRC=pef;               PFX=$MS/bench_pef ;                                                                                                                                                                          MANAGED=FALSE ;;
  4)  SRC=ctrn;              PFX=$MS/bench_ctrn ;                                                                                                                                                                          MANAGED=TRUE  ;;
  5)  SRC=silc_l;            PFX=$MS/bench_silc_l ;                                                                                                                                                                        MANAGED=TRUE  ;;
  6)  SRC=nb_v2;             PFX=$HOME/magplot/verify/magp_qcnb; SITE_OVR=$QC_ESI ;                                                                                                                                        MANAGED=TRUE  ;;
  7)  SRC=ns_managed;        PAIRS_OVR=$MS/bench_ns_pairs_managed.csv;                   INIT_OVR=$MS/bench_ns_tree_init.csv;      T2_OVR=$MS/bench_ns_tree_t2.csv;      SITE_OVR=$MS/bench_ns_site_esi.csv;      INDOMAIN=0; MANAGED=TRUE  ;;
  8)  SRC=ns_unmanaged;      PAIRS_OVR=$MS/bench_ns_pairs_unmanaged.csv;                 INIT_OVR=$MS/bench_ns_tree_init.csv;      T2_OVR=$MS/bench_ns_tree_t2.csv;      SITE_OVR=$MS/bench_ns_site_esi.csv;      INDOMAIN=0; MANAGED=FALSE ;;
  9)  SRC=ns_long_managed;   PAIRS_OVR=$MS/bench_ns_long_pairs_managed_singleregime.csv; INIT_OVR=$MS/bench_ns_long_tree_init.csv; T2_OVR=$MS/bench_ns_long_tree_t2.csv; SITE_OVR=$MS/bench_ns_long_site_esi.csv; INDOMAIN=0; MANAGED=TRUE  ;;
  10) SRC=ns_long_unmanaged; PAIRS_OVR=$MS/bench_ns_long_pairs_unmanaged.csv;            INIT_OVR=$MS/bench_ns_long_tree_init.csv; T2_OVR=$MS/bench_ns_long_tree_t2.csv; SITE_OVR=$MS/bench_ns_long_site_esi.csv; INDOMAIN=0; MANAGED=FALSE ;;
  11) SRC=baxter;            PFX=$MS/bench_baxter ;                                                                                                                                                                        MANAGED=FALSE ;;
  12) SRC=mef;               PFX=$MS/bench_mefia_long ;                                                                                                                                                                    MANAGED=FALSE ;;
  *) echo "bad array id"; exit 2 ;;
esac

if [ -n "${PAIRS_OVR:-}" ]; then
  export PAIRS_FILE=$PAIRS_OVR INIT_FILE=$INIT_OVR T2_FILE=$T2_OVR SITE_FILE=$SITE_OVR
else
  export PAIRS_FILE=${PFX}_pairs.csv INIT_FILE=${PFX}_tree_init.csv T2_FILE=${PFX}_tree_t2.csv
  export SITE_FILE=${SITE_OVR:-${PFX}_site_esi.csv}
fi
export INDOMAIN=$INDOMAIN
export V1211_MANAGED=$MANAGED
export CONFIG_TAG=${P37}/p37_cand_${SRC}
export TREE_OUT=""
echo "[p37cand] task=$SLURM_ARRAY_TASK_ID SRC=$SRC INDOMAIN=$INDOMAIN MANAGED=$MANAGED TAG=$CONFIG_TAG MODEL_FILE=$MODEL_FILE USE_MODS=$USE_MODS"
echo "[p37cand] PAIRS=$PAIRS_FILE INIT=$INIT_FILE T2=$T2_FILE SITE=$SITE_FILE"
Rscript $P33/2026-08-26_p33-matgate-runner.R
echo "=== ${CONFIG_TAG} DONE ==="

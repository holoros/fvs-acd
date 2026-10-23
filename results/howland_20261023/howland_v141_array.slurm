#!/bin/bash
#SBATCH --job-name=howland_v141
#SBATCH --array=1-10
#SBATCH --time=06:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=4
#SBATCH --account=PUOM0008
#SBATCH --output=/users/PUOM0008/crsfaaron/logs/howland_v141_%A_%a.out
#SBATCH --error=/users/PUOM0008/crsfaaron/logs/howland_v141_%A_%a.err
# FVS-ACD 14.1 (v141L: 14.0.4 L2 engine + 14.1 overlay, level term on, thinning term off since stands are unmanaged)
# on 93 DigiSylva Howland plots, 50 yr, ESI 12, 15, 18. Arm environment verbatim from the Oct 16 cross-version long200 launcher.
set -euo pipefail
W=/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/v141_check; mkdir -p $W/out
FR=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/frames
V=/users/PUOM0008/crsfaaron/magplot/verify; P4E=$V/p4e; P23=$V/p23
R1=/users/PUOM0008/crsfaaron/acdx_20261016/long200
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2 OMP_NUM_THREADS=4 R_DATATABLE_NUM_THREADS=4
cat > $W/build_inputs.R <<'EOF'
suppressMessages(library(data.table))
W <- "/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/v141_check"
tmpl <- fread("/users/PUOM0008/crsfaaron/acdx_20261016/long200/work/long200_mefia_l_c_pairs_DATA_2026-10-16.csv", nrows = 1)
td <- fread("/fs/scratch/PUOM0008/crsfaaron/HRF_v2maps/trees.tab")
td[, PL := sub("^([A-Z]+_[0-9]+).*", "\\1", Plot)]
td <- td[grepl("^HL", PL) & (is.na(Snag) | Snag == "") & DBH >= 10]
td <- td[, .SD[Year == max(Year)], by = PL]
spp <- c(PIRU="RS",TSCA="EH",ACRU="RM",THOC="WC",ABBA="BF",PIST="WP",BEPA="PB",BEPO="GB",BEAL="YB",POGR="BT",POTR="QA",FAGR="AB",UNK="OH")
td[, SP := unname(spp[Species])][is.na(SP), SP := "OH"]
P <- list(); I <- list(); S <- list()
for (e in c(12, 15, 18)) for (pl in unique(td$PL)) {
  st <- sprintf("HOWLAND__%s__2025_2075_E%d", pl, e); site <- sprintf("HOWLAND__%s_E%d", pl, e)
  x <- copy(tmpl); x[, `:=`(STAND = st, SITE = site, interval_years = 50L, ELEV = 60, MANAGED = 0L, Y1 = 2025L, Y2 = 2075L,
                           PLOTKEY = pl, OLD_STAND = st, ESI_OLD = e, N_T1 = nrow(td[PL == pl]), N_T2 = nrow(td[PL == pl]))]
  P[[length(P)+1]] <- x
  t <- td[PL == pl]
  I[[length(I)+1]] <- data.table(STAND = st, PLOT = 1L, TREE = seq_len(nrow(t)), SP = t$SP, DBH = t$DBH, HT = NA_real_, EXPF = 40, YEAR = 2025L)
  S[[length(S)+1]] <- data.table(SITE = site, esi8 = e)
}
P <- rbindlist(P); I <- rbindlist(I)
fwrite(P, file.path(W, "howland_pairs.csv")); fwrite(I, file.path(W, "howland_tree_init.csv"))
fwrite(copy(I)[, YEAR := 2075L], file.path(W, "howland_tree_t2.csv")); fwrite(rbindlist(S), file.path(W, "howland_site_esi.csv"))
cat("stands", nrow(P), "trees", nrow(I), "\n")
EOF
[ -s $W/howland_pairs.csv ] || Rscript $W/build_inputs.R
N=$(($(wc -l < $W/howland_pairs.csv) - 1))
export PAIRS_FILE=$W/howland_pairs.csv INIT_FILE=$W/howland_tree_init.csv T2_FILE=$W/howland_tree_t2.csv SITE_FILE=$W/howland_site_esi.csv
F=$(( (SLURM_ARRAY_TASK_ID-1)*28+1 )); T=$(( SLURM_ARRAY_TASK_ID*28 )); [ $T -le $N ] || T=$N; export CHUNK_FROM=$F CHUNK_TO=$T TIMELIM=20000
export USE_HIER_ING=FALSE USE_HIER_MORT=FALSE HIER_POSTDIR=$HOME/v13_kickoff SPLIT=TRUE
export BREAK=0.62 BG=0.020 BS=0.80 IRC=0.58 IRK=8 SDMAX=1.0
export USE_BRMS=TRUE USE_ANCHOR=TRUE NB_BREAK=0.70 QC_BREAK=0.62 NB_AFAC=0.579 QC_AFAC=0.111
export B0NEW=-1.88365516930746 B1NEW=0.497878016309701 B2NEW=-0.0293425859449079
export ONSET=0.55 IMULT=2.5 LEV3=1 LEV3_LO=0.35 LEV3_HI=0.45 LEV3_QMIN=18 V132=0 INDOMAIN=1
export ACD_V14_BASE=$P4E/model_b0b1b2.r LINKED=1 LINKED_SPRE=1 LINKED_COEF=$P23/v14_coef_bundle_2026-09-08.rds
export DBA_V1404=1 MODEL_FILE=$HOME/v14_0_4_20260917/AcadianGY_14.0.4.r LINKED_MODE=L2 SMALLTREE=0
export V141=1 V141_FILE=$HOME/v14_1_20260923/AcadianGY_14.1.r
export V141_COEF=$V/gydbreg20260916/v141_20260923/work/v141_option3_offline_coefs_r5_2026-09-23.rds
export V141_RELCAP=2.9848 V141_DLO=12.7 V141_DHI=15.0 V141_REPORT_DIR=$W/out/counters
export LSDG_V141=1 THIN_V141=0
export CONFIG_TAG=$W/out/c$(printf %02d $SLURM_ARRAY_TASK_ID) TREE_OUT=$W/out/c$(printf %02d $SLURM_ARRAY_TASK_ID)
md5sum $V141_FILE $MODEL_FILE
cd $V
Rscript $R1/scripts/2026-10-16_acdx_long200_runner.R
echo DONE


#!/bin/bash
## PREREG47 dry assembly (allowed by the plan): five year tables of the frozen arms (laptop aggregates, no identifiers), three
## synthetic arms built to fail one gate each (syn_stall: top height frozen, the red team adversarial case; syn_fall: 2.5 m top
## height fall at year 50, HM; syn_dense: stems x 10, F), synthetic thresholds, scratch root. Not a reading. thresholds_p31 values
## are the plan's rounded ones (the file lives on firebreather), so Frontier, Magnitude and Reineke are held at 1e-3 in this dry
## run only. Also exercises thresholds_p47.R on a synthetic results file and frames, with its md5 stops removed in a scratch copy.
## Usage: bash dry_p47.sh <dir holding this bundle>
set -uo pipefail
D=${1:-$PWD}; S=$D/scratch; rm -rf "$S"; mkdir -p "$S/plan" "$S/logs" "$S/syn"
cp "$D/in/2026-10-11_v142_qc-bakuzis-absolute_PREREG47.md" "$D/in/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r2.md" "$D/in/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r3.md" "$D/in/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r4.md" "$D/in/2026-10-15_v142_qc-bakuzis-absolute_PREREG47r5.md" "$S/plan/"
Rscript --vanilla -e '
suppressMessages(library(data.table)); a <- commandArgs(TRUE); x <- fread(a[1])[arm == "qc141"]
s1 <- copy(x)[, `:=`(arm = "syn_stall", HT = HT[age == 0]), by = cell]
s2 <- copy(x)[, arm := "syn_fall"][age >= 50, HT := HT - 2.5]
s3 <- copy(x)[, arm := "syn_dense"][, `:=`(TPH_s = TPH_s * 10, TPH = TPH * 10)]
q <- fread(a[1])[arm == "qc_rh"]; s4 <- copy(q)[, arm := "syn_plateau"][, HT := fifelse(age > 25, HT[age == 25], HT), by = cell]
cz <- sort(unique(q$cell))[1:17]; s5 <- copy(q)[, arm := "syn_mask"][cell %in% cz, HT := HT[age == 0], by = cell]
fwrite(rbind(s1, s2, s3, s4, s5), a[2])
set.seed(1); n <- 378; r <- data.table(STAND = sprintf("S%03d", 1:n), esi8 = runif(n, 14, 22), SCORE_MINDBH_USED = 9.1, interval_years = runif(n, 4.5, 7.5))
r[, TOPHT_t1 := esi8 * runif(n, .6, 1.1)][, TOPHT_o := TOPHT_t1 + rnorm(n, .8, .7)]; fwrite(r, a[3])
mk <- function(h) rbindlist(lapply(r$STAND, function(s) data.table(STAND = s, DBH = runif(30, 9, 40), EXPF = 10, HT = ifelse(runif(30) < .3, NA, h + rnorm(30)))))
fwrite(mk(14), a[4]); fwrite(mk(15), a[5])' "$D/in/gyr142-p45-traj-5yr_DATA_2026-10-05.csv" "$S/syn/traj_syn.csv" "$S/syn/results_syn.csv" "$S/syn/fi.csv" "$S/syn/fg.csv"
export P47_DRY=1 P47_ROOT=$S P47_DRY_TH=$D/in/thresholds_p47_SYNTH.csv P31_TH=$D/in/thresholds_p31_ROUNDED.csv \
  P44_ASSEMBLE=$D/in/assemble_p44_r2.R P44_RELATIONS=$D/in/gyr142-p44-relations_DATA_2026-10-05.csv \
  P45_RELATIONS=$D/in/gyr142-p45-relations_DATA_2026-10-05.csv P45_CREDIBILITY=$D/in/gyr142-p45-credibility_DATA_2026-10-05.csv \
  P45_FRONTIER=$D/in/frontier_p45_DATA.csv P47_DRY_TRAJ=$D/in/gyr142-p45-traj-5yr_DATA_2026-10-05.csv,$S/syn/traj_syn.csv \
  P47_ARMS=qc141,p38_fit,qc_rh,syn_stall,syn_fall,syn_dense,syn_plateau,syn_mask
Rscript --vanilla "$D/scripts/assemble_p47.R" 2>&1
echo "ASSEMBLE EXIT $?"
ls -la "$S/assembled_dry" "$S/figs_dry" 2>/dev/null; cat "$S/logs/error_log.txt" 2>/dev/null
## thresholds_p47.R on synthetic inputs: scratch copy with the three md5 stops removed (the shipped script keeps them)
sed -e '/stop("plan md5 differs/d' -e '/stop("source md5 differs/d' -e 's/if (md5(FI) != "521d6468861b66b8f73864fb9a6bf0fc" || md5(FG) != "7fd42665dccd3c3e9e188ee0ad9ca5d0") stop("pass28qc frame md5 differs from the PREREG40 record")/NULL/' \
  "$D/scripts/thresholds_p47.R" > "$S/syn/thresholds_p47_dry.R"
diff "$D/scripts/thresholds_p47.R" "$S/syn/thresholds_p47_dry.R"
P47_ROOT=$S P47_P19_RESULTS=$S/syn/results_syn.csv P47_FI=$S/syn/fi.csv P47_FG=$S/syn/fg.csv Rscript --vanilla "$S/syn/thresholds_p47_dry.R" 2>&1
echo "THRESHOLDS EXIT $?"; cat "$S/plan/thresholds_p47_DATA.csv" | cut -c1-200

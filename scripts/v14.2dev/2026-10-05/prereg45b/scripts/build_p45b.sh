#!/bin/bash
# PREREG45b build: bundle copied from v142p45/home (md5 list must equal PREREG45's); runner_p45b_fb.R and driver_p45b.R are the
# PREREG45 runner and driver with parts/htfx_nb_block.R inserted once after the PREREG45 htfx line; wrappers are PREREG45 copies
# with job root, runner or driver and md5, set nb_c, taskmap and arm case changed. Refuses if home exists. No em dashes.
set -euo pipefail
S=/home/aaron/jobs/v142p45; J=/home/aaron/jobs/v142p45b
[ -e $J/home ] && { echo "REFUSE"; exit 3; }
mkdir -p $J/home/work
LIST="AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R magplot v14_0_4_20260917 v14_1_20260923"
cd $S/home; for f in AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R runner_p45_fb.R; do cp -p $f $J/home/; done
cp -a magplot v14_0_4_20260917 v14_1_20260923 $J/home/
( cd $J/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p45b.txt
cmp $S/logs/bundle_md5_p45.txt $J/logs/bundle_md5_p45b.txt && echo "bundle md5 identical to PREREG45: $(wc -l < $J/logs/bundle_md5_p45b.txt) files" > $J/logs/bundle_check.txt
python3 - <<'PY'
blk = open("/home/aaron/jobs/v142p45b/scripts/parts/htfx_nb_block.R").read().rstrip("\n")
anchor = 'htfx <- function(x, p) { if (is.finite(QC_RH_A) && p$PROV == "QC") return(htfx_rh(x, p)); if (!is.finite(HTFIX_B) || p$PROV != "NS") return(x); x$dht.mult <- exp(-HTFIX_B * pmax(0, x$dbh - 12.7)); x }\n'
for src, dst in [("/home/aaron/jobs/v142p45b/home/runner_p45_fb.R", "/home/aaron/jobs/v142p45b/home/runner_p45b_fb.R"), ("/home/aaron/jobs/v142p45/scripts/driver_p45.R", "/home/aaron/jobs/v142p45b/scripts/driver_p45b.R")]:
    t = open(src).read(); assert t.count(anchor) == 1, src; open(dst, "w").write(t.replace(anchor, anchor + blk + "\n")); print("edited", dst)
PY
diff $J/home/runner_p45_fb.R $J/home/runner_p45b_fb.R > $J/diffs/runner_p45_fb.R_to_runner_p45b_fb.R.diff || true
diff $S/scripts/driver_p45.R $J/scripts/driver_p45b.R > $J/diffs/driver_p45.R_to_driver_p45b.R.diff || true
RM=$(md5sum $J/home/runner_p45b_fb.R | cut -d' ' -f1); DM=$(md5sum $J/scripts/driver_p45b.R | cut -d' ' -f1)
# taskmap: nb_c 355 rows in chunks of 20 (18 chunks) for nb141 (1 to 18), nb_one (19 to 36), nb_rh0 (chunks 1, 9, 18: 37 to 39), nb_rh (40 to 57)
TM=$J/home/work/p45b_taskmap_DATA_2026-10-05.csv; echo "task,COL,CHUNK,SET,FROM,TO" > $TM
t=0; for A in nb141 nb_one; do for c in $(seq 1 18); do t=$((t+1)); f=$(( (c-1)*20+1 )); to=$(( c*20 )); [ $to -gt 355 ] && to=355; echo "$t,$A,$c,nb_c,$f,$to" >> $TM; done; done
for c in 1 9 18; do t=$((t+1)); f=$(( (c-1)*20+1 )); to=$(( c*20 )); [ $to -gt 355 ] && to=355; echo "$t,nb_rh0,$c,nb_c,$f,$to" >> $TM; done
for c in $(seq 1 18); do t=$((t+1)); f=$(( (c-1)*20+1 )); to=$(( c*20 )); [ $to -gt 355 ] && to=355; echo "$t,nb_rh,$c,nb_c,$f,$to" >> $TM; done
seq 1 39 > $J/home/work/p45b_ids_stage1.txt; seq 40 57 > $J/home/work/p45b_ids_stage2.txt
cat > $J/scripts/.case.txt <<'CASE'
  nb141) export NB_AFAC=0.579 ;;
  nb_one) export NB_AFAC=1.000 ;;
  nb_rh0) export NB_RH_A=0 NB_RH_B=0 NB_RH_RFILL=0.8 NB_AFAC=1.000 ;;
  nb_rh) FF=/home/aaron/jobs/v142p45b/fit/gyr142-p45b-nbrh-fit_DATA_2026-10-05.csv; chk $FF $(cut -d' ' -f1 /home/aaron/jobs/v142p45b/logs/fit_md5.txt); A=$(awk -F, '$1=="a"{print $3}' $FF); Bv=$(awk -F, '$1=="b"{print $3}' $FF); RF=$(awk -F, 'NR==2{print $NF}' /home/aaron/jobs/v142p45b/plan/frontier_p45b_DATA.csv); [[ "$A" =~ ^-?[0-9]+\.[0-9]+$ && "$Bv" =~ ^-?[0-9]+\.[0-9]+$ ]] || { echo "FATAL fit values $A $Bv"; exit 2; }; export NB_RH_A=$A NB_RH_B=$Bv NB_RH_RFILL=$RF ;;
CASE
awk -v bf=$J/scripts/.case.txt '/^  qc_rh\) FF=/ { while ((getline l < bf) > 0) print l; next } /^  qc_rh0\) export/ {next} {print}' $S/scripts/run_task_p45.sh | \
  sed -e 's#p45_taskmap_DATA_2026-10-05.csv#p45b_taskmap_DATA_2026-10-05.csv#' -e 's#\[v142p45-fb\]#[v142p45b-fb]#g' -e 's#not in PREREG45"#not in PREREG45b"#' \
      -e 's#case "$SET" in qc_c|qc_fl) export SRC_TST=UNKNOWN#case "$SET" in nb_c) export SRC_TST=UNKNOWN#' \
      -e 's#QC_RH_A QC_RH_B QC_RH_RFILL || true#QC_RH_A QC_RH_B QC_RH_RFILL NB_RH_A NB_RH_B NB_RH_RFILL || true#' \
      -e "s#RUNNER=\$HOME/runner_p45_fb.R; chk \$RUNNER e85b3612d4bf9475309042436c761701#RUNNER=\$HOME/runner_p45b_fb.R; chk \$RUNNER $RM#" \
      -e 's#RH_A=${QC_RH_A:-unset} RH_B=${QC_RH_B:-unset}#NBRH_A=${NB_RH_A:-unset} NBRH_B=${NB_RH_B:-unset}#' \
      -e '2s#^\# PREREG45 task driver#\# PREREG45b task driver (PREREG45 run_task_p45.sh; set nb_c, taskmap, NB arm case, runner). PREREG45 task driver#' > $J/scripts/run_task_p45b.sh
rm $J/scripts/.case.txt
grep -q '^  nb_rh) ' $J/scripts/run_task_p45b.sh && grep -q 'in nb_c) export' $J/scripts/run_task_p45b.sh && grep -q runner_p45b_fb.R $J/scripts/run_task_p45b.sh && ! grep -q 'qc_rh' $J/scripts/run_task_p45b.sh || { echo "FATAL task build"; exit 6; }
D5=$(md5sum $J/scripts/run_task_p45b.sh | cut -d' ' -f1); D45=$(md5sum $S/scripts/run_task_p45.sh | cut -d' ' -f1)
sed -e 's#run_task_p45.sh#run_task_p45b.sh#g' $S/scripts/launch_p45.sh > $J/scripts/launch_p45b.sh
sed -e 's#run_retry_p45.sh#run_retry_p45b.sh#g' $S/home/retry_timeouts_p45.sh > $J/home/retry_timeouts_p45b.sh
sed -e 's#run_task_p45.sh#run_task_p45b.sh#g' -e "s#$D45#$D5#" -e 's#\[v142p45-retry\]#[v142p45b-retry]#g' -e 's#/v142p45/#/v142p45b/#g' $S/home/run_retry_p45.sh > $J/home/run_retry_p45b.sh
grep -q "$D5" $J/home/run_retry_p45b.sh || { echo "FATAL retry md5"; exit 6; }
# long run wrapper: set nb_c, arms nb141 and nb_rh
sed -e 's#/home/aaron/jobs/v142p45/#/home/aaron/jobs/v142p45b/#g' -e "s#D=/home/aaron/jobs/v142p45b/scripts/driver_p45.R; chk \$D 06465636a88ff0c2559dd1b1b2d21b26#D=/home/aaron/jobs/v142p45b/scripts/driver_p45b.R; chk \$D $DM#" \
    -e 's#R1=$HOME; SET=qc_c#R1=$HOME; SET=nb_c#' -e 's#case "$SET" in qc_c|qc_fl) export SRC_TST=UNKNOWN#case "$SET" in qc_c|qc_fl|nb_c) export SRC_TST=UNKNOWN#' \
    -e 's#^  qc_rh) FF=.*#  nb141) export NB_AFAC=0.579 ;;\n  nb_rh) FF=/home/aaron/jobs/v142p45b/fit/gyr142-p45b-nbrh-fit_DATA_2026-10-05.csv; chk $FF $(cut -d" " -f1 /home/aaron/jobs/v142p45b/logs/fit_md5.txt); export NB_RH_A=$(awk -F, '"'"'$1=="a"{print $3}'"'"' $FF) NB_RH_B=$(awk -F, '"'"'$1=="b"{print $3}'"'"' $FF) NB_RH_RFILL=$(awk -F, '"'"'NR==2{print $NF}'"'"' /home/aaron/jobs/v142p45b/plan/frontier_p45b_DATA.csv) ;;#' \
    -e 's#\[p45\]#[p45b]#g' -e '1s#^\# PREREG45 task wrapper#\# PREREG45b task wrapper (run_p45.sh with job root, driver, set nb_c and NB arms). PREREG45 task wrapper#' $S/scripts/run_p45.sh > $J/scripts/run_p45b.sh
grep -q "^  nb_rh) " $J/scripts/run_p45b.sh && grep -q driver_p45b.R $J/scripts/run_p45b.sh && grep -q "SET=nb_c" $J/scripts/run_p45b.sh || { echo "FATAL run_p45b build"; exit 6; }
for p in "$S/scripts/run_task_p45.sh scripts/run_task_p45b.sh" "$S/scripts/launch_p45.sh scripts/launch_p45b.sh" "$S/home/run_retry_p45.sh home/run_retry_p45b.sh" "$S/scripts/run_p45.sh scripts/run_p45b.sh"; do set -- $p; diff $1 $J/$2 > $J/diffs/$(basename $1)_to_$(basename $2).diff || true; done
echo "BUILD_DONE runner $RM driver $DM task $D5"

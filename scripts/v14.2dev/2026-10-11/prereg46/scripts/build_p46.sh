#!/bin/bash
# PREREG46 build (plan md5 eb4b753d). Prepared 11 October 2026 on the laptop while firebreather was unreachable; to be
# reviewed on the server before its md5 enters logs/launch_md5s.txt.
# (1) Benchmark bundle: the PREREG45 bundle files copied, md5 list must equal PREREG38's (as PREREG45's did).
# (2) runner_p46_fb.R and driver_p46.R are runner_p45_fb.R (e85b3612) and driver_p45.R (06465636) with the two edits of
#     parts/p46_edit.py (form switch, trace hook), each asserted once.
# (3) Taskmap: PREREG45 tasks 1 to 20 become qc_lz 1 to 20 and qc_ez 21 to 40 (same chunks), tasks 21 to 24 become qc_lz0
#     41 to 44 and qc_ez0 45 to 48. Task, launcher, retry and score wrappers are PREREG45 copies with job root, taskmap,
#     arm case, runner and md5 and tags changed; run_p46.sh is run_p45.sh with job root, driver and md5, arm case, unset
#     line and tag changed. The fit md5 path is set explicitly, never by a path rewrite. Refuses if home exists. No em dashes.
set -euo pipefail
S38=/home/aaron/jobs/v142p38; S45=/home/aaron/jobs/v142p45; J=/home/aaron/jobs/v142p46
[ -e $J/home ] && { echo "REFUSE $J/home exists"; exit 3; }
mkdir -p $J/home/work $J/diffs $J/logs
LIST="AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R magplot v14_0_4_20260917 v14_1_20260923"
cd $S45/home; for f in AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p28_fb.R runner_p45_fb.R; do cp -p $f $J/home/; done
cp -a magplot v14_0_4_20260917 v14_1_20260923 $J/home/
( cd $J/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $J/logs/bundle_md5_p46.txt
cmp $S38/logs/bundle_md5_p38.txt $J/logs/bundle_md5_p46.txt || { echo "FATAL bundle md5 differs from PREREG38"; exit 4; }; echo "bundle md5 identical to PREREG38: $(wc -l < $J/logs/bundle_md5_p46.txt) files" > $J/logs/bundle_check.txt
echo "e85b3612d4bf9475309042436c761701  $J/home/runner_p45_fb.R" | md5sum -c - || exit 4
echo "06465636a88ff0c2559dd1b1b2d21b26  $S45/scripts/driver_p45.R" | md5sum -c - || exit 4
python3 $J/scripts/parts/p46_edit.py $J/home/runner_p45_fb.R $J/home/runner_p46_fb.R
python3 $J/scripts/parts/p46_edit.py $S45/scripts/driver_p45.R $J/scripts/driver_p46.R
diff $J/home/runner_p45_fb.R $J/home/runner_p46_fb.R > $J/diffs/runner_p45_fb.R_to_runner_p46_fb.R.diff || true
diff $S45/scripts/driver_p45.R $J/scripts/driver_p46.R > $J/diffs/driver_p45.R_to_driver_p46.R.diff || true
RM=$(md5sum $J/home/runner_p46_fb.R | cut -d' ' -f1); DM=$(md5sum $J/scripts/driver_p46.R | cut -d' ' -f1)
TM45=$S45/home/work/p45_taskmap_DATA_2026-10-05.csv; TM=$J/home/work/p46_taskmap_DATA_2026-10-11.csv
awk -F, 'NR==1{print; next} $1>=1&&$1<=20{$2="qc_lz"; print} ' OFS=, $TM45 > $TM
awk -F, 'NR>1 && $1>=1&&$1<=20{$1=$1+20; $2="qc_ez"; print}' OFS=, $TM45 >> $TM
awk -F, 'NR>1 && $1>=21&&$1<=24{$1=$1+20; $2="qc_lz0"; print}' OFS=, $TM45 >> $TM
awk -F, 'NR>1 && $1>=21&&$1<=24{$1=$1+24; $2="qc_ez0"; print}' OFS=, $TM45 >> $TM
[ "$(tail -n +2 $TM | wc -l)" -eq 48 ] || { echo "FATAL taskmap rows"; exit 6; }
seq 1 48 > $J/home/work/p46_ids.txt
FIT=/home/aaron/jobs/v142p46/fit/gyr142-p46-qczero-fit_DATA_2026-10-11.csv; FMD=/home/aaron/jobs/v142p46/logs/fit_md5.txt
cat > $J/scripts/.case.txt <<CASE
  qc_lz) FF=$FIT; chk \$FF \$(cut -d' ' -f1 $FMD); A=\$(awk -F, '\$1=="qc_lz" && \$2=="a"{print \$4}' \$FF); Bv=\$(awk -F, '\$1=="qc_lz" && \$2=="b"{print \$4}' \$FF); [[ "\$A" =~ ^-?[0-9]+\.[0-9]+\$ && "\$Bv" =~ ^-?[0-9]+\.[0-9]+\$ ]] || { echo "FATAL fit values \$A \$Bv"; exit 2; }; export QC_RH_FORM=lz QC_RH_A=\$A QC_RH_B=\$Bv QC_RH_RFILL=0.815 ;;
  qc_ez) FF=$FIT; chk \$FF \$(cut -d' ' -f1 $FMD); A=\$(awk -F, '\$1=="qc_ez" && \$2=="a"{print \$4}' \$FF); Bv=\$(awk -F, '\$1=="qc_ez" && \$2=="b"{print \$4}' \$FF); [[ "\$A" =~ ^-?[0-9]+\.[0-9]+\$ && "\$Bv" =~ ^-?[0-9]+\.[0-9]+\$ ]] || { echo "FATAL fit values \$A \$Bv"; exit 2; }; export QC_RH_FORM=ez QC_RH_RMAX=1.285 QC_RH_A=\$A QC_RH_B=\$Bv QC_RH_RFILL=0.815 ;;
  qc_lz0) export QC_RH_FORM=lz QC_RH_A=1 QC_RH_B=0 QC_RH_RFILL=0.815 QC_AFAC=1.000 ;;
  qc_ez0) export QC_RH_FORM=ez QC_RH_RMAX=Inf QC_RH_A=0 QC_RH_B=0 QC_RH_RFILL=0.815 QC_AFAC=1.000 ;;
CASE
awk -v bf=$J/scripts/.case.txt '/^  qc_rh\) FF=/ { while ((getline l < bf) > 0) print l; next } /^  qc_rh0\) export/ {next} {print}' $S45/scripts/run_task_p45.sh | \
  sed -e 's#p45_taskmap_DATA_2026-10-05.csv#p46_taskmap_DATA_2026-10-11.csv#' -e 's#\[v142p45-fb\]#[v142p46-fb]#g' -e 's#not in PREREG45"#not in PREREG46"#' \
      -e 's#QC_RH_A QC_RH_B QC_RH_RFILL || true#QC_RH_A QC_RH_B QC_RH_RFILL QC_RH_FORM QC_RH_RMAX QC_RH_TRACE || true#' \
      -e "s#RUNNER=\$HOME/runner_p45_fb.R; chk \$RUNNER e85b3612d4bf9475309042436c761701#RUNNER=\$HOME/runner_p46_fb.R; chk \$RUNNER $RM#" \
      -e 's#^\# PREREG45 task driver#\# PREREG46 task driver (copy of PREREG45 run_task_p45.sh md5 ba24284a; taskmap, arm case, runner, log tag only). PREREG45 task driver#' \
      -e 's#RH_B=${QC_RH_B:-unset} SMALL#RH_B=${QC_RH_B:-unset} FORM=${QC_RH_FORM:-unset} RMAX=${QC_RH_RMAX:-unset} SMALL#' > $J/scripts/run_task_p46.sh
rm $J/scripts/.case.txt
for a in qc_lz qc_ez qc_lz0 qc_ez0; do grep -q "^  $a) " $J/scripts/run_task_p46.sh || { echo "FATAL case $a"; exit 6; }; done
grep -q runner_p46_fb.R $J/scripts/run_task_p46.sh && ! grep -q 'p45_\|qc_rh)' $J/scripts/run_task_p46.sh || { echo "FATAL task driver build"; exit 6; }
D6=$(md5sum $J/scripts/run_task_p46.sh | cut -d' ' -f1); D5=$(md5sum $S45/scripts/run_task_p45.sh | cut -d' ' -f1)
sed -e 's#run_task_p45.sh#run_task_p46.sh#g' -e 's#^\# PREREG45 launcher#\# PREREG46 launcher (PREREG45 launch_p45.sh, driver name only). PREREG45 launcher#' $S45/scripts/launch_p45.sh > $J/scripts/launch_p46.sh
sed -e 's#run_retry_p45.sh#run_retry_p46.sh#g' $S45/home/retry_timeouts_p45.sh > $J/home/retry_timeouts_p46.sh
sed -e 's#run_task_p45.sh#run_task_p46.sh#g' -e "s#$D5#$D6#" -e 's#\[v142p45-retry\]#[v142p46-retry]#g' -e 's#/v142p45/#/v142p46/#g' $S45/home/run_retry_p45.sh > $J/home/run_retry_p46.sh
grep -q "$D6" $J/home/run_retry_p46.sh || { echo "FATAL retry md5"; exit 6; }
grep -q "v142p45\|qc_rh" $J/home/run_retry_p46.sh $J/home/retry_timeouts_p46.sh $J/scripts/launch_p46.sh && { echo "FATAL p45 residue"; grep -n "v142p45\|qc_rh" $J/home/run_retry_p46.sh $J/home/retry_timeouts_p46.sh $J/scripts/launch_p46.sh; exit 6; } || true
# long run wrapper: qc_lz, qc_ez and qc_rh (form exp, PREREG45 fit, for G0x); trace path from P46_TRACE only
sed -e 's#/home/aaron/jobs/v142p45/logs/#/home/aaron/jobs/v142p46/logs/#g' -e 's#/home/aaron/jobs/v142p45/scripts/driver_p45.R; chk $D 06465636a88ff0c2559dd1b1b2d21b26#/home/aaron/jobs/v142p46/scripts/driver_p46.R; chk $D '"$DM"'#' \
    -e 's#^unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT || true#unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT QC_RH_A QC_RH_B QC_RH_RFILL QC_RH_FORM QC_RH_RMAX QC_RH_TRACE || true#' \
    -e 's#\[p45\]#[p46]#g' -e '1s#^\# PREREG45 task wrapper#\# PREREG46 task wrapper (run_p45.sh with job root, driver and md5, arm case, unset line and tag changed). PREREG45 task wrapper#' $S45/scripts/run_p45.sh | \
  awk -v fit=$FIT -v fmd=$FMD '/^  qc_rh\) FF=/ { print "  qc_rh) FF=/home/aaron/jobs/v142p45/fit/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv; chk $FF 24cb959a3fc80f3c87761f9dc3737fd0; export QC_RH_FORM=exp QC_RH_A=$(awk -F, '"'"'$1==\"a\"{print $3}'"'"' $FF) QC_RH_B=$(awk -F, '"'"'$1==\"b\"{print $3}'"'"' $FF) QC_RH_RFILL=0.815 ;;";
      print "  qc_lz) FF=" fit "; chk $FF $(cut -d\" \" -f1 " fmd "); export QC_RH_FORM=lz QC_RH_A=$(awk -F, '"'"'$1==\"qc_lz\" && $2==\"a\"{print $4}'"'"' $FF) QC_RH_B=$(awk -F, '"'"'$1==\"qc_lz\" && $2==\"b\"{print $4}'"'"' $FF) QC_RH_RFILL=0.815 ;;";
      print "  qc_ez) FF=" fit "; chk $FF $(cut -d\" \" -f1 " fmd "); export QC_RH_FORM=ez QC_RH_RMAX=1.285 QC_RH_A=$(awk -F, '"'"'$1==\"qc_ez\" && $2==\"a\"{print $4}'"'"' $FF) QC_RH_B=$(awk -F, '"'"'$1==\"qc_ez\" && $2==\"b\"{print $4}'"'"' $FF) QC_RH_RFILL=0.815 ;;"; next }
    /^unset TREE_OUT/ { print; print "export QC_RH_TRACE=${P46_TRACE:-}"; next } {print}' > $J/scripts/run_p46.sh
for a in qc_rh qc_lz qc_ez; do grep -q "^  $a) " $J/scripts/run_p46.sh || { echo "FATAL run_p46 case $a"; exit 6; }; done
grep -q driver_p46.R $J/scripts/run_p46.sh && ! grep -q "driver_p45\|v142p45/logs" $J/scripts/run_p46.sh || { echo "FATAL run_p46 build"; exit 6; }
# scoring wrapper: both arms, task filter widened to 40
sed -e 's#J=/home/aaron/jobs/v142p45#J=/home/aaron/jobs/v142p46#' -e 's#p45_taskmap_DATA_2026-10-05.csv#p46_taskmap_DATA_2026-10-11.csv#' -e 's#\$1<=20 \&\& \$2==a#$1<=40 \&\& $2==a#' \
    -e 's#^for s in qc_c qc_fl; do join_arm qc_rh \$s; done#for A in qc_lz qc_ez; do for s in qc_c qc_fl; do join_arm $A $s; done; done#' \
    -e 's#p45_plan_fb.csv#p46_plan_fb.csv#' -e 's#VC_TAG=p45-fb#VC_TAG=p46-fb#' -e 's#P45_SCORE_DONE#P46_SCORE_DONE#' \
    -e '/^#/s#qc_rh#qc_lz and qc_ez#g' \
    -e '1,2s#^\# PREREG45 scoring#\# PREREG46 scoring (run_score_p45.sh with job root, taskmap, arms, filter, plan and tag changed). PREREG45 scoring#' $S45/scripts/run_score_p45.sh | \
  awk '/^  echo "\$s,\$s,qc_rh,/ { l=$0; a=l; gsub(/qc_rh/,"qc_lz",a); print a; b=l; gsub(/qc_rh/,"qc_ez",b); print b; next } {print}' > $J/scripts/run_score_p46.sh
grep -q 'join_arm $A $s' $J/scripts/run_score_p46.sh && grep -q 'qc_lz,' $J/scripts/run_score_p46.sh && grep -q 'qc_ez,' $J/scripts/run_score_p46.sh && ! grep -q 'qc_rh\|v142p45' $J/scripts/run_score_p46.sh || { echo "FATAL score build"; exit 6; }
for p in "$S45/scripts/run_task_p45.sh scripts/run_task_p46.sh" "$S45/scripts/launch_p45.sh scripts/launch_p46.sh" "$S45/home/run_retry_p45.sh home/run_retry_p46.sh" "$S45/home/retry_timeouts_p45.sh home/retry_timeouts_p46.sh" "$S45/scripts/run_p45.sh scripts/run_p46.sh" "$S45/scripts/run_score_p45.sh scripts/run_score_p46.sh" "$TM45 home/work/p46_taskmap_DATA_2026-10-11.csv"; do
  set -- $p; diff $1 $J/$2 > $J/diffs/$(basename $1)_to_$(basename $2).diff || true; done
cp -p $S45/scripts/2026-10-01_v142_volconv_score_r2.R $S45/scripts/2026-09-29_v142_p23_hkey.R $J/scripts/
grep -l $'\xe2\x80\x94' $J/scripts/*.sh $J/scripts/*.R $J/home/*_p46* 2>/dev/null && { echo "FATAL em dash"; exit 7; } || true
echo "BUILD_DONE runner $RM driver $DM task $D6"

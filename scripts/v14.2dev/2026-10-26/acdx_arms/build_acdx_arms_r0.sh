#!/bin/bash
# acdx arms build (26 October 2026). Adds the frozen 14.2 arms p38_fit and qc_rh to the 16 October acdx cross-version
# launchers for mefia_l_c (10 yr hindcast, bench141 launcher), mefia_ph_c (post-harvest, acdx postharv launcher) and the
# 200 yr mefia_l_c frame (acdx long200 launcher). Each arm is the v141LT environment verbatim plus the arm's exports, as in
# firebreather run_task_p38.sh (423e0162) and run_task_p45.sh (ba24284a). Runners: runner_p45_fb.R (e85b3612, verbatim;
# carries both the p38 QC dht.mult line and the PREREG45 htfx_rh block) for the 10 yr and post-harvest frames; for 200 yr,
# runner_p45_fb.R with the three long200 changes (header line, long200 trajhooks source, TIMELIM). Inputs are read in place;
# outputs only under ~/acdx_arms_20261026. Refuses if any built file exists. No em dashes.
set -euo pipefail
A=/users/PUOM0008/crsfaaron/acdx_arms_20261026; S=$A/src; SC=$A/scripts; W=$A/work; D=$A/diffs
R0PH=/users/PUOM0008/crsfaaron/acdx_20261016/postharv; R0L=/users/PUOM0008/crsfaaron/acdx_20261016/long200
R0B=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/bench141
RUN300=/users/PUOM0008/crsfaaron/magplot/verify/gydbreg20260916/v142_20260925/runner/scripts/2026-09-25_v142_phaseD_runner_p23_tst_counters.R
mkdir -p $SC $W $D $A/logs
for f in $SC/runner_arms_10y_ph.R $SC/runner_arms_long200.R $SC/arms_ph.sbatch $SC/arms_long200.sbatch $SC/arms_b141.sbatch; do [ -e $f ] && { echo "REFUSE $f exists"; exit 3; }; done
ck() { [ "$(md5sum "$1" | cut -d' ' -f1)" = "$2" ] || { echo "FATAL md5 $1"; exit 4; }; }
ck $S/runner_p45_fb.R e85b3612d4bf9475309042436c761701
ck $S/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv e782957cc297e60f1f22744aea96d529
ck $S/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv 24cb959a3fc80f3c87761f9dc3737fd0
ck $RUN300 300a0d610070f77517352c8e23f07922
ck $R0L/scripts/2026-10-16_acdx_long200_runner.R 3d05cbade76bbe298e5e93ca6c7b8230
ck $R0PH/scripts/2026-10-16_mefia_ph_array.sbatch "$(md5sum $R0PH/scripts/2026-10-16_mefia_ph_array.sbatch | cut -d' ' -f1)"
## runners
cp -p $S/runner_p45_fb.R $SC/runner_arms_10y_ph.R
python3 - "$S/runner_p45_fb.R" "$SC/runner_arms_long200.R" <<'PY'
import sys
s, d = sys.argv[1], sys.argv[2]; t = open(s).read()
o1 = 'source(path.expand("~/magplot/verify/gydbreg20260916/phaseD/scripts/2026-09-16_gydbreg-phaseD_trajhooks.R"))  # PHASE D hooks'
n1 = 'source("/users/PUOM0008/crsfaaron/acdx_20261016/long200/scripts/2026-10-16_acdx_long200_trajhooks.R")  # PHASE D hooks'
o2 = 'setTimeLimit(elapsed=60,transient=TRUE)'
n2 = 'setTimeLimit(elapsed=as.numeric(Sys.getenv("TIMELIM","60")),transient=TRUE)'
for o in (o1, o2): assert t.count(o) == 1, o
t = t.replace(o1, n1).replace(o2, n2)
t = "# ACDX ARMS LONG200 COPY (2026-10-26) of runner_p45_fb.R (md5 e85b3612) with the long200 changes of 2026-10-16_acdx_long200_runner.R (md5 3d05cbad): long200 trajhooks (TIMELIM, BIOMASS) and TIMELIM. No em dashes.\n" + t
open(d, "w").write(t)
PY
diff $RUN300 $S/runner_p45_fb.R > $D/runner300a_to_p45.diff || true
diff $R0L/scripts/2026-10-16_acdx_long200_runner.R $SC/runner_arms_long200.R > $D/long200runner_to_arms_long200.diff || true
## identity check of the long200 runner edit: the change from the long200 runner must be the same edit as 300a to p45, apart
## from the header line, the setwd line (absolute vs ~) and the trajhooks source line
grep -E '^[<>]' $D/runner300a_to_p45.diff | grep -v -E 'setwd|trajhooks' | sort > $W/.h1
grep -E '^[<>]' $D/long200runner_to_arms_long200.diff | grep -v -E 'setwd|trajhooks|^< # ACDX LONG200 COPY|^> # ACDX ARMS LONG200 COPY' | sort > $W/.h2
cmp $W/.h1 $W/.h2 || { echo "FATAL long200 runner edit is not the 300a to p45 edit"; diff $W/.h1 $W/.h2 | head; exit 5; }; rm $W/.h1 $W/.h2
RM1=$(md5sum $SC/runner_arms_10y_ph.R | cut -d' ' -f1); RM2=$(md5sum $SC/runner_arms_long200.R | cut -d' ' -f1)
## taskmaps: v141LT rows of the frozen maps, arm renamed, tasks renumbered (p38_fit first, then qc_rh)
mk() { local src=$1 dst=$2 filt=$3; echo "task,arm,chunk,set,from,to" > $dst
  awk -F, -v f="$filt" 'NR>1 && $2=="v141LT" && $4 ~ f {print}' $src > $W/.rows; n=$(wc -l < $W/.rows); [ $n -gt 0 ] || { echo "FATAL no rows $src"; exit 6; }
  k=0; for arm in p38_fit qc_rh; do while IFS=, read -r t a c s fr to; do k=$((k+1)); echo "$k,$arm,$c,$s,$fr,$to" >> $dst; done < $W/.rows; done; rm $W/.rows; echo $k; }
NPH=$(mk $R0PH/work/mefia_ph_taskmap_DATA_2026-10-16.csv $W/arms_ph_taskmap_DATA_2026-10-26.csv mefia_ph_c)
NL=$(mk $R0L/work/long200_taskmap_DATA_2026-10-16.csv $W/arms_long200_taskmap_DATA_2026-10-26.csv mefia_l_c)
NB=$(mk $R0B/work/bench141_taskmap_DATA_2026-09-25.csv $W/arms_b141_taskmap_DATA_2026-10-26.csv '^mefia_l_c$')
## arm block, inserted before the RUNNER line of each launcher
cat > $W/.armblock <<'BLK'
## acdx arms (2026-10-26): v141LT environment above, verbatim, plus the frozen 14.2 arm exports (firebreather run_task_p38.sh
## 423e0162 and run_task_p45.sh ba24284a). Both act only where PROV is QC.
unset HTFIX_B ING_MIN_FROM_SCORE QC_AFAC_SMALL QC_AFAC_LARGE QC_AFAC_KNOT QC_RH_A QC_RH_B QC_RH_RFILL || true
case "$ARM" in
  p38_fit) FF=/users/PUOM0008/crsfaaron/acdx_arms_20261026/src/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv; chk $FF e782957cc297e60f1f22744aea96d529; QV=$(awk -F, 'NR==2 && $1=="QC_AFAC_FIT" {print $2}' $FF); [[ "$QV" =~ ^[0-9]\.[0-9]{3}$ ]] || { echo "FATAL fit value $QV"; exit 2; }; export QC_AFAC=$QV QC_AFAC_SMALL=$QV QC_AFAC_LARGE=$QV QC_AFAC_KNOT=25 ;;
  qc_rh) FF=/users/PUOM0008/crsfaaron/acdx_arms_20261026/src/gyr142-p45-qcrh-fit_DATA_2026-10-05.csv; chk $FF 24cb959a3fc80f3c87761f9dc3737fd0; QA=$(awk -F, '$1=="a"{print $3}' $FF); QB=$(awk -F, '$1=="b"{print $3}' $FF); [[ "$QA" =~ ^-?[0-9]+\.[0-9]+$ && "$QB" =~ ^-?[0-9]+\.[0-9]+$ ]] || { echo "FATAL fit values $QA $QB"; exit 2; }; export QC_RH_A=$QA QC_RH_B=$QB QC_RH_RFILL=0.815 ;;
  *) echo "bad ARM $ARM"; exit 2 ;;
esac
echo "[acdxarms] ARM=$ARM QC_AFAC=$QC_AFAC SMALL=${QC_AFAC_SMALL:-unset} RH_A=${QC_RH_A:-unset} RH_B=${QC_RH_B:-unset}"
BLK
## launcher transform: taskmap and output root new; ARM read from the map, COL set to v141LT so the frozen env branch runs;
## outputs, counters and logs under the arms root; runner and its md5 swapped. Inputs (frames, TST files) keep the frozen roots.
xf() { local src=$1 dst=$2 tm=$3 out=$4 runner=$5 rmd=$6 tag=$7
  awk -v blk=$W/.armblock '/^RUNNER=/ { while ((getline l < blk) > 0) print l; close(blk) } {print}' $src | \
  sed -e "s#^TM=.*#TM=$tm#" \
      -e 's#^IFS=, read -r COL CHUNK SET FROM TO <<< "\$ROW"#IFS=, read -r ARM CHUNK SET FROM TO <<< "$ROW"; COL=v141LT#' \
      -e "s#\$R1/out/\$COL#$out/out/\$ARM#g" -e "s#\$R1/out/counters_\$COL#$out/out/counters_\$ARM#g" -e "s#\$R1/tables/counters_\$COL#$out/out/counters_\$ARM#g" \
      -e "s#^RUNNER=\$R1/scripts/2026-10-16_acdx_long200_runner.R; chk \$RUNNER .*#RUNNER=$runner; chk \$RUNNER $rmd#" \
      -e "s#^RUNNER=[^;]*\$#RUNNER=$runner#" -e "s#^chk \$RUNNER .*#chk \$RUNNER $rmd#" \
      -e "s#^\#SBATCH --output=.*#\#SBATCH --output=$A/logs/%x_%A_%a.out#" -e "s#^\#SBATCH --job-name=.*#\#SBATCH --job-name=$tag#" \
      -e "s#^\#SBATCH --array=.*#\#SBATCH --array=1-NTASK#" \
      -e "2a # ACDX ARMS COPY (2026-10-26) of $src: arms p38_fit and qc_rh (taskmap column 2), v141LT env verbatim plus arm exports, runner $runner. Diff in $D." > $dst
  grep -q '^RUNNER=' $dst; grep -q 'case "\$ARM" in' $dst; grep -q "chk \$RUNNER $rmd" $dst || { echo "FATAL runner chk not set in $dst"; exit 7; }
  ! grep -n -E '\$R1/out|\$R1/tables/counters' $dst || { echo "FATAL frozen output root left in $dst"; exit 7; }
  diff $src $dst > $D/$(basename $dst).diff || true; }
xf $R0PH/scripts/2026-10-16_mefia_ph_array.sbatch $SC/arms_ph.sbatch $W/arms_ph_taskmap_DATA_2026-10-26.csv $A/ph $SC/runner_arms_10y_ph.R $RM1 acdxAph
xf $R0L/scripts/cardinal_mcp_job_3936542.slurm $SC/arms_long200.sbatch $W/arms_long200_taskmap_DATA_2026-10-26.csv $A/long200 $SC/runner_arms_long200.R $RM2 acdxAL200
xf $R0B/scripts/2026-09-25_v142_bench141_array.sbatch $SC/arms_b141.sbatch $W/arms_b141_taskmap_DATA_2026-10-26.csv $A/b141 $SC/runner_arms_10y_ph.R $RM1 acdxAb141
sed -i "s#1-NTASK#1-$NL#" $SC/arms_long200.sbatch; sed -i '/--array=1-NTASK/d' $SC/arms_ph.sbatch $SC/arms_b141.sbatch
rm $W/.armblock
grep -l $'\xe2\x80\x94' $SC/* && { echo "FATAL em dash"; exit 8; } || true
( cd $A && md5sum src/* scripts/* work/*.csv ) > $A/logs/build_md5s.txt
echo "tasks ph $NPH long200 $NL b141 $NB; runner 10y/ph $RM1 long200 $RM2"
echo BUILD_ARMS_DONE

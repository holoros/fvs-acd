#!/bin/bash
# PREREG49 build (plan md5 c2188088). Usage: bash build_p49.sh [ROOT] (ROOT defaults to ~/jobs/v142p49; dryrun/build in the dry run).
# (1) Bundle: the PREREG22 bundle files (~/jobs/v142p22/home: model, coefficient, frame, overlay and runner files) copied into
#     ROOT/home; the md5 list of the copy must equal the md5 list of the source (frozen bundle read, never written).
# (2) runner_p49_fb.R = runner_p20_fb.R (65392afb) with edit S of parts/p49_edit.py (survival switch source line, asserted once);
#     driver_p49.R = driver_p26.R (9696daea) with edit S and the slgrid port (edits 1 and 2, port table in p49_edit.py) of
#     parts/slgrid_branch.R (110b1f52). Diffs in ROOT/diffs.
# (3) Taskmap: the 36 v141LTfi rows of the PREREG22 taskmap (same chunks and rows) become v141LTfis tasks 1 to 36; task 37 is
#     v141LTfis0 (the switch at its null) on the PREREG22 G0 rows (ns_c rows 1 to 100) for H0.
# (4) The r2 scorer (PREREG45 copy, 265fc695) and the PREREG17 structure summary (PREREG22 copy, 14c53082) copied unedited.
# Refuses if ROOT/home exists. No coordinates. No em dashes.
set -euo pipefail
J=/home/aaron/jobs/v142p49; ROOT=${1:-$J}; S22=/home/aaron/jobs/v142p22; S26=/home/aaron/jobs/v142p26; S44=/home/aaron/jobs/v142p44; S45=/home/aaron/jobs/v142p45
[ -e $ROOT/home ] && { echo "REFUSE $ROOT/home exists"; exit 3; }
chk() { local m; m=$(md5sum "$1" | cut -d' ' -f1); [ "$m" = "$2" ] || { echo "FATAL md5 $1 $m != $2"; exit 4; }; }
chk $S22/home/runner_p20_fb.R 65392afbbe67e2e80524855fea7a41da; chk $S22/home/p22_env.sh a77e811715ccf4d82f96f430db36f8c5
chk $S22/home/v14_0_4_20260917/AcadianGY_14.0.4.r 61f95d99f896e8e513930d6e33a7391a; chk $S22/home/v14_1_20260923/AcadianGY_14.1.r 0bf27dde81240e6bdf59c9a90f0051bd
chk $S26/scripts/driver_p26.R 9696daea51f491e74967cca24d08a6aa; chk $S44/scripts/parts/slgrid_branch.R 110b1f524e363387bdc1f34f10560ae1
chk $S45/scripts/2026-10-01_v142_volconv_score_r2.R 265fc6950ce3f18da751da8b9fd3dbc2; chk $S22/scripts/2026-09-27_v142_p17_summ.R 14c530827fd9e8f5685911c9bb1dacb3
mkdir -p $ROOT/home/work $ROOT/diffs $ROOT/logs $ROOT/scripts
LIST="AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p20_fb.R p22_env.sh magplot v14_0_4_20260917 v14_1_20260923"
( cd $S22/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $ROOT/logs/bundle_md5_src.txt
cd $S22/home; cp -p AcadianGY_13.1.r hw_formrisk_split.R hw_sawfrac_smith.R runner_htfix_fb.R runner_p20_fb.R p22_env.sh $ROOT/home/; cp -a magplot v14_0_4_20260917 v14_1_20260923 $ROOT/home/
( cd $ROOT/home && find $LIST -type f -print0 | sort -z | xargs -0 md5sum ) > $ROOT/logs/bundle_md5_p49.txt
cmp $ROOT/logs/bundle_md5_src.txt $ROOT/logs/bundle_md5_p49.txt || { echo "FATAL bundle copy differs from the PREREG22 bundle"; exit 4; }
echo "bundle md5 identical to PREREG22 home: $(wc -l < $ROOT/logs/bundle_md5_p49.txt) files" > $ROOT/logs/bundle_check.txt
python3 $J/scripts/parts/p49_edit.py runner $ROOT/home/runner_p20_fb.R $ROOT/home/runner_p49_fb.R
python3 $J/scripts/parts/p49_edit.py driver $S26/scripts/driver_p26.R $ROOT/scripts/driver_p49.R $S44/scripts/parts/slgrid_branch.R
diff $ROOT/home/runner_p20_fb.R $ROOT/home/runner_p49_fb.R > $ROOT/diffs/runner_p20_fb.R_to_runner_p49_fb.R.diff || true
diff $S26/scripts/driver_p26.R $ROOT/scripts/driver_p49.R > $ROOT/diffs/driver_p26.R_to_driver_p49.R.diff || true
diff $S44/scripts/parts/slgrid_branch.R $ROOT/scripts/driver_p49.R > $ROOT/diffs/slgrid_branch.R_to_driver_p49.R.diff || true
TM=$ROOT/home/work/p49_taskmap_DATA_2026-10-26.csv
awk -F, 'BEGIN{OFS=","} NR==1{print; next} $2=="v141LTfi"{k++; $1=k; $2="v141LTfis"; print}' $S22/home/work/p22_taskmap_DATA_2026-09-29.csv > $TM
echo "37,v141LTfis0,1,ns_c,1,100" >> $TM
[ "$(awk -F, 'NR>1 && $2=="v141LTfis"' $TM | wc -l)" -eq 36 ] && [ "$(tail -n +2 $TM | wc -l)" -eq 37 ] || { echo "FATAL taskmap rows"; exit 6; }
diff $S22/home/work/p22_taskmap_DATA_2026-09-29.csv $TM > $ROOT/diffs/p22_taskmap_to_p49_taskmap.diff || true
seq 1 36 > $ROOT/home/work/p49_ids_main.txt; echo 37 > $ROOT/home/work/p49_ids_h0.txt
[ -e $ROOT/scripts/2026-10-01_v142_volconv_score_r2.R ] || cp -p $S45/scripts/2026-10-01_v142_volconv_score_r2.R $ROOT/scripts/
[ -e $ROOT/scripts/2026-09-27_v142_p17_summ.R ] || cp -p $S22/scripts/2026-09-27_v142_p17_summ.R $ROOT/scripts/
grep -l $'\xe2\x80\x94' $ROOT/home/runner_p49_fb.R $ROOT/scripts/driver_p49.R 2>/dev/null && { echo "FATAL em dash"; exit 7; } || true
( cd $ROOT && md5sum home/runner_p49_fb.R scripts/driver_p49.R home/work/p49_taskmap_DATA_2026-10-26.csv home/work/p49_ids_main.txt home/work/p49_ids_h0.txt scripts/2026-10-01_v142_volconv_score_r2.R scripts/2026-09-27_v142_p17_summ.R ) > $ROOT/logs/build_md5s.txt
cat $ROOT/logs/build_md5s.txt; echo BUILD_DONE

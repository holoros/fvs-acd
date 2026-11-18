#!/bin/bash
J=~/jobs/silc_agmbench_100yr_20261117; R=~/restricted/silc_agmbench_gapfill_20261117; S=~/restricted/seven_islands_100yr_20261117
umask 077; mkdir -p $R/results; chmod 700 $R
cp -n $S/plots.csv $S/trees.csv $R/; md5sum $S/plots.csv $R/plots.csv $S/trees.csv $R/trees.csv | awk '{print $1}' | uniq -c
python3 -c "import json;print(json.load(open('$S/results/meta.json'))['input_md5'])"
T=~/fvsacd142/tools/v26_V/bridge_batch.R; md5sum $T | awk '{print "bridge_batch.R",$1}'
sed 's/uiAcadianIngrowth = "No"/uiAcadianIngrowth = Sys.getenv("SILC_INGROWTH", "Yes")/' $T > $J/bridge_silc.R
diff $T $J/bridge_silc.R | head; chmod +x $J/03_run_bridge.sh
nice -n 10 Rscript $J/01_build_bridge_inputs.R $R ~/fvsacd142/state/work/arms/prod_fix
ls $R/keys/c5 | wc -l; K=$(ls $R/keys/c5/*.key | head -1); head -24 $K | sed 's/^P[0-9]*$/P<id>/'; sed -n 25,30p $K
source ~/opt/geos/activate.sh
nice -n 10 Rscript $J/02_sdib_silc.R $R
echo PREP_DONE

B=~/LSOG/nb_magplot/20260618Weiskittel_1037_1/MAGPlot_NB
find $B -maxdepth 3 | head -60
for f in $(find $B -maxdepth 3 -name '*.csv'); do echo "== $f $(wc -l < $f)"; head -1 $f; done
echo "== ~/magplot magp csvs"; ls -la ~/magplot/*.csv | head -30
for f in ~/magplot/magp_treatment.csv ~/magplot/magp_site_info.csv ~/magplot/magp_tree.csv; do [ -f $f ] && { echo "== $f $(wc -l < $f)"; head -1 $f; }; done
ls ~/LSOG/nb_magplot/ ~/LSOG/nb_magplot/exact_coords | head
echo FIND4_DONE

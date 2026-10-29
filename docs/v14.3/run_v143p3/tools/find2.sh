cd ~
echo "== ESI-like rasters"
timeout 200 find ~ /fs/scratch/PUOM0008/crsfaaron /fs/ess/PUOM0008 -maxdepth 6 \( -iname '*esi*.tif' -o -iname '*esi*.vrt' -o -iname '*site*index*.tif' \) -size +1M 2>/dev/null | head -80
echo "== NB PSP-like"
timeout 200 find ~ /fs/scratch/PUOM0008/crsfaaron /fs/ess/PUOM0008 -maxdepth 6 \( -iname '*nb*psp*' -o -iname '*psp*nb*' -o -iname '*new*brunswick*' -o -iname 'NB_*' -o -iname '*_NB_*' \) 2>/dev/null | head -60
echo "== mefia_ph_c pair years"
python3 - <<'PY'
import csv
f='/users/PUOM0008/crsfaaron/acdx_20261016/postharv/work/bench_gyr_mefia_ph_c_pairs.csv'
y1=[];y2=[]
with open(f) as h:
  for r in csv.DictReader(h): y1.append(int(r['Y1'])); y2.append(int(r['Y2']))
print('stands',len(y1),'Y1',min(y1),max(y1),'Y2',min(y2),max(y2))
PY
ls -la --time-style=full-iso fia_data/ME_PLOT.csv fia_data/ME_TREE.csv fia_data/NH_PLOT.csv fia_data/VT_PLOT.csv
ls -la --time-style=full-iso ~/acdx_20261016/postharv/work/bench_gyr_mefia_ph_c_pairs.csv ~/acdx_20261016/postharv/scripts/ 
echo FIND2_DONE

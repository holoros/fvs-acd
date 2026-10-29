cd ~
echo "== fia_data"; ls -la fia_data | head -60
echo "== ME/NH latest MEASYEAR"
for s in ME NH VT; do f=fia_data/${s}_PLOT.csv; [ -f $f ] && python3 - "$f" <<'PY'
import csv,sys,collections
f=sys.argv[1]; c=collections.Counter()
with open(f) as h:
  r=csv.DictReader(h)
  for row in r:
    c[row.get('MEASYEAR','')]+=1
print(f, sorted(c.items())[-8:])
PY
done
echo "== ESI rasters"; ls -la /fs/scratch/PUOM0008/crsfaaron/canada/acadian/ 2>&1 | head -40

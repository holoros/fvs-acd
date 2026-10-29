#!/bin/bash
# PREREG4 export: identifier free files only into export/v143p4_export_2026-10-28.tgz. Screens every candidate file for any
# STAND or SITE value of the mefia_l_c frame (and for PLT_CN, LAT, LON column names in data files) and refuses the tar if any
# hit. No em dashes.
set -euo pipefail
P=/users/PUOM0008/crsfaaron/v143p4; cd $P
OUT=export/v143p4_export_2026-10-28.tgz; [ -e $OUT ] && { echo "REFUSE $OUT"; exit 3; }
L=export/filelist.txt
{ ls plan/* review/* scripts/* tools/* work/*.csv explore/* assembled/* fig/* 2026-10-28_v143_senescence-forest-type_RESULT.md
  ls logs/prereg_md5.txt logs/launch_md5s.txt logs/selection_md5.txt logs/assemble_md5.txt logs/chain_s4_jobs.txt logs/chain_s6_jobs.txt \
     logs/launch_s4.log logs/launch_s6.log logs/build.log logs/diff_hc_launcher.txt logs/diff_l200_launcher.txt logs/cmp_*_DATA.csv \
     logs/v143p4frame_*.out logs/v143p4fit_*.out logs/v143p4diag_*.out logs/v143p4diag2_*.out logs/v143p4asm_*.out logs/v143p4figr1_*.out \
     logs/v143p4H1a_*.out logs/v143p4H1b_*.out logs/v143p4H2_*.out logs/v143p4dryfit_*.out logs/v143p4dryH*.out
  ls dry/dry_setup.log dry/drycheck_*.out dry/fit/* dry/root/work/* dry/root/logs/cmp_*_DATA.csv; } > $L
python3 - $L <<'PY'
import sys, csv
fl = [l.strip() for l in open(sys.argv[1]) if l.strip()]
ids = set()
for f in ["serveronly_SERVERONLY/folds_mefia_l_c_SERVERONLY.csv"]:
    for r in csv.DictReader(open(f)): ids.add(r["STAND"]); ids.add(r["SITE"])
ids = {i for i in ids if len(i) >= 4}
bad = []
for f in fl:
    try: t = open(f, encoding="utf-8", errors="replace").read()
    except IsADirectoryError: continue
    if chr(0x2014) in t and "PREV" not in f: bad.append((f, "em dash"))
    hit = [i for i in ids if i in t]
    if hit: bad.append((f, "%d identifier values" % len(hit)))
print("files screened", len(fl), "identifier values", len(ids))
for b in bad: print("HIT", b)
sys.exit(1 if any(b[1] != "em dash" for b in bad) else 0)
PY
tar czf $OUT -T $L
md5sum $OUT; wc -l < $L

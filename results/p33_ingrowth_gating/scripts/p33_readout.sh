#!/bin/bash
# Pass 33 consolidated readout: one call, writes everything to p33_readout.txt
V=/users/PUOM0008/crsfaaron/magplot/verify
P=$V/bakuzis_p33
H=$V/bakuzis_h1
OUT=$V/p33_readout.txt
{
echo "=== A. FLAGS and VOL/HT inversion counts, h1 (pass 32) vs noing vs matgate ==="
printf "%-9s %-9s %-7s %-16s\n" SOURCE VARIANT FLAGS INVERSIONS
for s in ctrn nb qc ns memat mefia_l; do
  for pair in "$H/${s}_h1default_bakuzis_report.txt h1" "$P/${s}_noing_bakuzis_report.txt noing" "$P/${s}_matgate_bakuzis_report.txt matgate"; do
    set -- $pair; f=$1; v=$2
    if [ -f "$f" ]; then
      fl=$(grep -m1 "^FLAGS:" "$f" | awk '{print $2}')
      inv=$(grep -m1 "HT inversions" "$f" | sed 's/^ *//')
      printf "%-9s %-9s %-7s %s\n" "$s" "$v" "${fl:-NA}" "${inv:-NA}"
    else
      printf "%-9s %-9s %-7s %s\n" "$s" "$v" MISSING "file not found"
    fi
  done
done

echo
echo "=== B. Eichhorn CV line per source/variant ==="
for s in ctrn nb qc ns memat mefia_l; do
  for pair in "$H/${s}_h1default_bakuzis_report.txt h1" "$P/${s}_noing_bakuzis_report.txt noing" "$P/${s}_matgate_bakuzis_report.txt matgate"; do
    set -- $pair; f=$1; v=$2
    [ -f "$f" ] && printf "%-9s %-9s %s\n" "$s" "$v" "$(grep -m1 'mean CV' "$f" | sed 's/^ *//')"
  done
done

echo
echo "=== C. CTRN trajectory comparison, first selected stand, every 8 years ==="
for v in "$H/ctrn_h1default_traj.csv h1" "$P/ctrn_noing_traj.csv noing" "$P/ctrn_matgate_traj.csv matgate"; do
  set -- $v; f=$1; lab=$2
  st=$(awk -F, 'NR==2{print $3}' "$f")
  echo "--- $lab (stand $st) ---"
  awk -F, -v S="$st" 'NR>1 && $3==S && $6%8==0 {printf "  age=%3s TPH=%7.0f BA=%5.1f QMD=%5.1f VOL=%6.1f\n",$6,$8,$9,$10,$11}' "$f"
done

echo
echo "=== D. Terminal-age (age 100) VOL by site, per variant, CTRN ==="
for v in "$H/ctrn_h1default_traj.csv h1" "$P/ctrn_noing_traj.csv noing" "$P/ctrn_matgate_traj.csv matgate"; do
  set -- $v; f=$1; lab=$2
  echo "--- $lab ---"
  awk -F, 'NR>1 && $6==100 {printf "  site=%5s VOL=%7.1f BA=%5.1f TPH=%7.0f\n",$5,$11,$9,$8}' "$f" | sort
done

echo
echo "=== E. G5 anti-shutoff: max |TPH matgate - TPH noing| per source ==="
for s in ctrn nb qc ns memat mefia_l; do
  a=$P/${s}_matgate_traj.csv; b=$P/${s}_noing_traj.csv
  if [ -f "$a" ] && [ -f "$b" ]; then
    awk -F, -v S="$s" 'FNR>1 && FILENAME==ARGV[1]{k=$3"|"$6; m[k]=$8} FNR>1 && FILENAME==ARGV[2]{k=$3"|"$6; if(k in m){d=m[k]-$8; if(d<0)d=-d; if(d>x)x=d; n++}} END{printf "  %-9s maxTPHdelta=%.2f over n=%d matched rows\n",S,x,n}' "$a" "$b"
  fi
done

echo
echo "=== F. G2 physical bounds over all p33 trajectories ==="
for f in $P/*_traj.csv; do
  awk -F, -v F="$(basename $f)" 'NR>1 { if ($9<=0 || $9>80 || $10<=0 || $10>60 || $11<0 || $11>700) bad++ } END{printf "  %-34s out-of-range rows=%d\n", F, bad+0}' "$f"
done

echo
echo "=== G. G3 pre-crash inertness: max pct VOL dev matgate vs h1, ages<=40 ==="
for s in ctrn nb qc ns memat mefia_l; do
  a=$H/${s}_h1default_traj.csv; b=$P/${s}_matgate_traj.csv
  if [ -f "$a" ] && [ -f "$b" ]; then
    awk -F, -v S="$s" 'FNR>1 && FILENAME==ARGV[1] && $6<=40 {k=$3"|"$6; m[k]=$11} FNR>1 && FILENAME==ARGV[2] && $6<=40 {k=$3"|"$6; if((k in m) && m[k]>0){d=($11-m[k])/m[k]; if(d<0)d=-d; if(d>x)x=d; n++}} END{printf "  %-9s maxVOLdev=%.2f pct over n=%d\n",S,100*x,n}' "$a" "$b"
  fi
done
} > "$OUT" 2>&1
echo "WROTE $OUT"
wc -l "$OUT"

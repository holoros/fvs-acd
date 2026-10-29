#!/bin/bash
# Howland decline diagnostic (28 October 2026): builds the two derived scripts from the frozen originals and
# verifies the diffs. The runner copy differs from the frozen long200 runner (md5 3d05cbad) by one header
# comment line and the one PHASE D hooks source line. The hooks copy is the frozen hooks file byte for byte
# followed by the FX block. Refuses to overwrite. Parses every R script of the study. No em dashes.
set -euo pipefail
A=/users/PUOM0008/crsfaaron/howland_decline_20261028
R1=/users/PUOM0008/crsfaaron/acdx_20261016/long200/scripts
FR=$R1/2026-10-16_acdx_long200_runner.R; FH=$R1/2026-10-16_acdx_long200_trajhooks.R
[ "$(md5sum $FR | cut -d' ' -f1)" = 3d05cbade76bbe298e5e93ca6c7b8230 ] || { echo "FATAL frozen runner md5"; exit 4; }
echo "frozen runner $(md5sum $FR)"; echo "frozen hooks  $(md5sum $FH)"
NR=$A/scripts/2026-10-28_hd_runner.R; NH=$A/scripts/2026-10-28_hd_trajhooks_fx.R; FXB=$A/scripts/2026-10-28_hd_fx_block.R
for f in $NR $NH; do [ ! -e $f ] || { echo "REFUSE $f exists"; exit 3; }; done
OLD='source("/users/PUOM0008/crsfaaron/acdx_20261016/long200/scripts/2026-10-16_acdx_long200_trajhooks.R")  # PHASE D hooks'
NEW="source(\"$NH\")  # PHASE D hooks plus the HD FX flux block, 2026-10-28"
[ "$(grep -cxF "$OLD" $FR)" = 1 ] || { echo "FATAL hooks source line not found exactly once"; exit 5; }
[ "$(tail -c1 $FR | od -An -tx1 | tr -d ' ')" = 0a ] || { echo "FATAL runner lacks a final newline"; exit 5; }
[ "$(tail -c1 $FH | od -An -tx1 | tr -d ' ')" = 0a ] || { echo "FATAL hooks lack a final newline"; exit 5; }
{ echo "# HD COPY (2026-10-28) of $FR (md5 3d05cbad) for the Howland decline diagnostic. One change only: the PHASE D hooks line sources $NH, the frozen hooks file byte for byte followed by an appended FX block that writes per year biomass fluxes to <prefix>_flux.csv. Projection and every frozen output unchanged. No em dashes."
  awk -v old="$OLD" -v new="$NEW" '{ if ($0 == old) print new; else print }' $FR; } > $NR
cat $FH $FXB > $NH
ND=$(diff $FR $NR | grep -c '^[<>]' || true); [ "$ND" = 3 ] || { echo "FATAL runner diff has $ND changed lines, expected 3"; diff $FR $NR | cut -c1-200; exit 6; }
diff $FR $NR | cut -c1-250 > $A/scripts/2026-10-28_hd_runner.diff
[ "$(head -c $(stat -c%s $FH) $NH | md5sum | cut -d' ' -f1)" = "$(md5sum $FH | cut -d' ' -f1)" ] || { echo "FATAL hooks prefix differs from frozen"; exit 6; }
echo "runner diff (3 changed lines expected):"; cat $A/scripts/2026-10-28_hd_runner.diff
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
for f in $NR $NH $A/scripts/2026-10-28_hd_assemble.R; do Rscript -e "invisible(parse('$f')); cat('parse ok $f\n')"; done
Rscript -e 'for(p in c("data.table","ggplot2","jsonlite","patchwork","scales")) cat("pkg", p, requireNamespace(p, quietly=TRUE), "\n")'
md5sum $NR $NH $FXB $A/scripts/2026-10-28_hd_build.sh
echo BUILD_OK

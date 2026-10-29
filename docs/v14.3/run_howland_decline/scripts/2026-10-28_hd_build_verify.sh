#!/bin/bash
# Howland decline diagnostic (28 October 2026): completes the verification steps of 2026-10-28_hd_build.sh, which wrote
# both derived scripts and the runner diff and then stopped silently at `diff | cut` (diff exits 1 when files differ,
# and pipefail with set -e ended the script). Generates nothing; re-verifies the derived files from scratch. No em dashes.
set -uo pipefail
A=/users/PUOM0008/crsfaaron/howland_decline_20261028
R1=/users/PUOM0008/crsfaaron/acdx_20261016/long200/scripts
FR=$R1/2026-10-16_acdx_long200_runner.R; FH=$R1/2026-10-16_acdx_long200_trajhooks.R
NR=$A/scripts/2026-10-28_hd_runner.R; NH=$A/scripts/2026-10-28_hd_trajhooks_fx.R; FXB=$A/scripts/2026-10-28_hd_fx_block.R
FAIL=0
ND=$(diff $FR $NR | grep -c '^[<>]'); echo "runner changed lines: $ND (expected 3)"; [ "$ND" = 3 ] || FAIL=1
diff $FR $NR | cut -c1-250
cmp -s <(diff $FR $NR | cut -c1-250) $A/scripts/2026-10-28_hd_runner.diff && echo "runner.diff file matches" || { echo "runner.diff file differs"; FAIL=1; }
[ "$(head -c $(stat -c%s $FH) $NH | md5sum | cut -d' ' -f1)" = "$(md5sum $FH | cut -d' ' -f1)" ] && echo "hooks prefix identical to frozen" || { echo "FATAL hooks prefix"; FAIL=1; }
cmp -s <(tail -c +$(( $(stat -c%s $FH) + 1 )) $NH) $FXB && echo "hooks suffix identical to FX block" || { echo "FATAL hooks suffix"; FAIL=1; }
grep -c 'hd_trajhooks_fx.R' $NR
source /etc/profile.d/lmod.sh; module --force purge; module load gcc/12.3.0 R/4.5.2
export R_LIBS_USER=/users/PUOM0008/crsfaaron/R/rhel9/4.5.2
for f in $NR $NH $A/scripts/2026-10-28_hd_assemble.R; do Rscript -e "invisible(parse('$f')); cat('parse ok $f\n')" || FAIL=1; done
Rscript -e 'for(p in c("data.table","ggplot2","jsonlite","patchwork","scales")) cat("pkg", p, requireNamespace(p, quietly=TRUE), "\n")'
md5sum $NR $NH $FXB $A/scripts/2026-10-28_hd_build.sh $A/scripts/2026-10-28_hd_build_verify.sh
[ $FAIL = 0 ] && echo VERIFY_OK || echo VERIFY_FAIL

#!/bin/bash
# PREREG22 m* extraction. Runs only after CHAIN_DONE in ~/jobs/v142p18/logs_chain.txt. Reads ONE PREREG18 file, the
# assembly's selection and verdict output ~/jobs/v142p18/assembled/gyr142-p18-verdict_DATA_2026-09-28.txt (lines m_star=,
# m_star_arm=, tie=, alt_..., verdict=; written by 2026-09-28_v142_p18_assemble.R), and writes ../plan/mstar.env. Stops with a
# clear message, and PREREG22 does not launch, if: CHAIN_DONE is absent; the file is absent or older than the PREREG18 chain
# start; m_star is absent or not a grid value; m_star_arm does not match m_star; or the verdict is Rule 1 (K1 fails at m*).
# Any other PREREG18 verdict launches (m* is used whatever the verdict). Refuses to overwrite. No coordinates. No em dashes.
set -uo pipefail
J=/home/aaron/jobs/v142p22; P18=/home/aaron/jobs/v142p18
V=$P18/assembled/gyr142-p18-verdict_DATA_2026-09-28.txt; OUT=$J/plan/mstar.env; P18_START="2026-09-28T19:42:29-03:00"
stop() { echo "MSTAR_STOP: $1. PREREG22 does not launch."; exit $2; }
[ -e $OUT ] && { echo "REFUSE $OUT exists"; exit 5; }
grep -q CHAIN_DONE $P18/logs_chain.txt 2>/dev/null || stop "CHAIN_DONE not in $P18/logs_chain.txt" 10
[ -e "$V" ] || stop "PREREG18 selection output $V is absent (no m*)" 11
[ -n "$(find "$V" -newermt "$P18_START")" ] || stop "$V is older than the PREREG18 chain start $P18_START" 12
MS=$(sed -n 's/^m_star=//p' "$V" | head -1); MA=$(sed -n 's/^m_star_arm=//p' "$V" | head -1); VD=$(sed -n 's/^verdict=//p' "$V" | head -1)
[ -n "$MS" ] || stop "no m_star line in $V" 13
case "$MS" in 1.5) M=1.5; A=v141LTig_m15 ;; 1.75) M=1.75; A=v141LTig_m175 ;; 2|2.0) M=2.0; A=v141LTig_m20 ;; 2.25) M=2.25; A=v141LTig_m225 ;;
  *) stop "m_star '$MS' is not a PREREG18 grid value" 14 ;; esac
[ "$MA" = "$A" ] || stop "m_star_arm '$MA' does not match m_star $MS (expected $A)" 15
RULE=$(printf %s "$VD" | grep -o '^Rule [0-9][ab]*' || true); [ -n "$RULE" ] || stop "verdict line has no rule label: '$VD'" 16
[ "$RULE" = "Rule 1" ] && stop "PREREG18 verdict is Rule 1, K1 fails at m*" 17
mkdir -p $J/plan; cp -n "$V" $J/plan/p18_verdict_copy.txt
{ echo "P22_IMULT=$M"; echo "P18_MSTAR_ARM=$A"; echo "P18_RULE='$RULE'"; echo "P18_VERDICT_MD5=$(md5sum "$V" | cut -d' ' -f1)"; echo "P22_MSTAR_WRITTEN='$(date -Is)'"; } > $OUT
cat $OUT; echo MSTAR_OK

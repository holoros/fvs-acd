# PREREG43 addendum 3: the unrounded Quebec increment ratio behind 0.111

5 October 2026. Recorded before the file below is read. Addendum 2 (md5 64b982de; RESULT 5b9b6699) found that 0.111 was set by
hand as the inverse of the Quebec ratio printed by `topht_recal_diag.R` (commit a259273d) as 8.89, whose inverse rounds to
0.112. Aaron asked (5 October, autopilot) that every open item be resolved. Records only: no engine run, nothing changed. No
coordinates. No em dashes.

## Source and computation, fixed now

Cardinal `~/magplot/verify/topht_recal_diag.csv` (written by line 32 of the diagnostic: STAND, PROV, esi8, TOPHT_t1, TOPHT_o,
TOPHT_p, f, hgi_o, hgi_p). Read with short commands (a listing with size and date, `md5sum`, the header, the row count, then
one awk pass), at most 10 Cardinal commands. No stand identifier is copied off Cardinal. The quantity is the diagnostic's own
line 19 to 20 statistic for PROV QC: mean(hgi_p) over mean(hgi_o) (ratio of means) and its inverse, printed to 6 decimals,
with n. As a check the same for NB, whose inverse should round to 0.579. Mean f by province is also reported against the 4 July
note (1.101 QC, 1.075 NB). If the file is absent, or its date is later than 4 July 2026, or the NB check fails, the verdict is
"not settled" and the reason is named.

## Verdict scale

SETTLED 0.111 (the unrounded inverse rounds to 0.111), SETTLED 0.112 (it rounds to 0.112, so 0.111 is a transcription or
rounding choice), or NOT SETTLED. Either settled verdict leaves the 14.2 decision unchanged.

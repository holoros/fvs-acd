# PREREG43 addendum 2, part D: Cardinal folders not reached by addendum 1

5 October 2026. Read only, grep -rIl then grep -n, one folder per command, files under 5 MB. Patterns: QC_AFAC, qc_afac, afac
(case insensitive in the archives), 0.111, plus topht_recal and dht.mult added once part C named topht_recal_diag.R.

## Result

No FIT. No Cardinal file in these folders estimates 0.111 or any QC height multiplier near it. No SET of QC_AFAC either: the
value lives only in the bench_parity environment recipes already found by revision 1 and addendum 1.

| Folder | Files scanned | SET | USE | FIT | OTHER |
|:--|--:|--:|--:|--:|--:|
| ~/scripts | 16 | 0 | 0 | 0 | 0 |
| ~/_scripts (691 top level + 13 in 3 subfolders) | 704 | 0 | 1 | 0 | 30 files |
| ~/fvsacd_bak30 | 48 | 0 | 0 | 0 | 4 files |
| ~/fvs-freeze-archive_20260805 | 4,069 | 0 | 0 | 0 | up to 85 files |
| ~/fvs-freeze-archive_20260806 | 4,068 | 0 | 0 | 0 | 7 files |

The one relevant context hit is `~/_scripts/AcadianGY_12.9.2.r` (2 July 2026, md5 0b115f6f), whose comments at lines 1421 and
3581 cite topht_recal_diag.R/.csv for the separate ESI anchor coefficients (QC 0.441 + 0.0378 esi), not for dht.mult.

Cardinal calls used: 29 of 30 (4 dropped connections counted). Large files skipped: 14 (0805) and 2 (0806). Tarballs:
0806 listed once (4,302 members; calibration names are FVS dbscalib and test keys, all present in the extracted folder and
grepped there); 0805 tarball not listed (superseded, folder grepped instead).

## Not read

The 79 non ACD Fortran files in 0805 src-converted that contain the string 0.111 (listed, not line read; 0 in acd); the same
set in 0806 (not listed); the 7 out of fold csv files in the _scripts subfolders (listed, not line read).
Cardinal `~/magplot/verify/topht_recal_diag.csv` (diagnostic output) was not read because it lies outside the pre-registered
folders and computing a ratio from it would be a new estimate.

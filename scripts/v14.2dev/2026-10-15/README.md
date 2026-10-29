# 14.2 refinement, October 15, 2026: PREREG47 revisions 1 to 5 and their scripts

PREREG47 sets absolute QC Bakuzis gates for the PREREG46 long run arms. Revisions 1 to 5 were registered on October 11 and 15, 2026, each before `thresholds_p47.R` ran and before any PREREG46 long run output existed, so the PREREG47 reading of PREREG46 will be blind. The full registration record is `prereg47/logs/prereg_md5.txt`. The scripts were dry run end to end on OSC Cardinal on synthetic and frozen arms only (job 15537483 for revision 5); none of this is a reading.

| Revision | md5 (first 8) | What it adds or changes |
|:--|:--|:--|
| 1 | 7f64d22c | gate C in the PREREG46 form, site ordering on HT gain, Reineke median slope, HM thresholds as a registered procedure |
| 2 | 6a77fa5f | gate CL (raw median HT/ESI at 100 yr at or above 0.815) and strict site ordering |
| 3 | 21a36a30 | gate MG (median early top height growth at or above MG_LO) |
| 4 | 4fa7aea1 | gates MGN and LG |
| 5 | d93f3035 | MGN count 27 to 23 (5 percent point of Binomial(36, 0.75)); LGR reported only |

| Script | md5 (first 8) |
|:--|:--|
| `prereg47/scripts/thresholds_p47.R` | ce7b6d2f |
| `prereg47/scripts/assemble_p47.R` | 02257096 |
| `prereg47/scripts/launch_md5s_p47.sh` | a4bef35b |
| `prereg47/dry/dry_p47.sh` | c9a92063 |
| `prereg47/scripts/implementation-notes_p47.md` | f89affaf |

`prereg47/review/` holds the red team of the scripts and of each patch. `prereg47/dry/` holds the revision 5 dry run log and the revision 3 dry gate figure; the dry bundles (aggregates only) stay on the laptop and Cardinal. Intermediate script versions are not copied here; they are kept on the laptop with `_PREV_20261015` suffixes.

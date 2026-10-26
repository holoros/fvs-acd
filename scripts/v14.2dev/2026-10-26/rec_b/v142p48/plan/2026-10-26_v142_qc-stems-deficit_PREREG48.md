# Splitting the QC stems deficit into survivor mortality and ingrowth, for 14.3: preregistration 48

**Revision 1, registered 26 October 2026** (md5 and time in `logs/prereg_md5.txt`), on Aaron's instruction to resolve all open items and recommendations on autopilot. It is draft 2 of 11 October with only the second arm filled in: the PREREG46 RESULT (26 October, `2026-10-26_v142_qc-relht-zero-form_RESULT.md`, md5 88ee102d) names no candidate, so under choice 1a the second arm is frozen qc_rh (PREREG45, `v142p45`). Draft 1 kept as `_PREV_20261011`. Written before any PREREG48 script, join or table exists, and before
the PREREG46 RESULT. A diagnostic, not a fix: nothing is fitted and no engine is run. The outcome **informs 14.3 only;
14.2 keeps QC_AFAC 0.111 and NB_AFAC 0.579**. L and T are not refitted. GT1 stays a named failure. Frozen runs are
read, never rerun. Stand identifiers stay in `*_SERVERONLY` files. No coordinates. No em dashes.

## Scope and what it informs

Every QC anchor arm runs about 24 points low on stems on screened qc_c fold B (PREREG19, PREREG28): stems deviation 24.23
points for qc141 (0.111) and 24.55 for qc_rh (PREREG45 RESULT), so it does not move with the height form, and PREREG19
placed the QC volume excess in diameters and stems. The PREREG24 QC stems diagnostic has no RESULT on the host and is not
used. PREREG48 asks what share of the qc_c fold B stems deficit is survivor mortality and what share is ingrowth past the
scoring floor. The answer names a 14.3 track; it changes no setting.

## Dependency

PREREG48 reads the frozen 14.1 reference (p19_a0111, md5 979101be) and, if the PREREG46 RESULT names a candidate under its
rule 5, that arm's frozen benchmark output. Height feeds crown ratio and competition, so the split must be read on the
height form 14.3 would carry. PREREG48 therefore cannot register before the PREREG46 RESULT is assembled and its md5
recorded. Without a PREREG46 candidate, choice 1 sets the second arm. **Resolved 26 October 2026: PREREG46 named no candidate (qc_ez rule 1 fit stop, qc_lz rule 2), so the second arm is frozen qc_rh.**

## Design, modeled on the PREREG27 NS survivor loss study

PREREG27 located the NS long interval stem deficit as survivor loss by comparing predicted and observed survivors of t1
trees on held out sites (fold B survivor ratio at 16 to 60 years 0.868 on ns_c, 0.921 on ns_long_c) and by comparing
predicted with observed annual survival by interval. PREREG48 ports that design to qc_c fold B with one change forced by
the QC record: every t1 to t2 pairing uses the MAGPlot field tags (`v142p14/in/pass28qc`), never the run frame TREE column,
which is a row index (PREREG36, PREREG37). Any join keyed on run frame TREE stops the script.

Per stand, stems in trees ha⁻¹ at or above the r2 scoring floor (read from scorer r2 and recorded in the RESULT; PREREG32
records 5 cm on NB plots, and the QC value is not restated here):

| Component | Observed | Predicted |
|:--|:--|:--|
| S, survivors | t1 tags at or above floor, alive at t2 | expf weighted t1 records at or above floor carried to t2 |
| U, upgrowth | t1 tags below floor, at or above floor at t2 | t1 records below floor whose t2 DBH reaches the floor |
| I, recruitment | t2 trees at or above floor with no t1 tag | ING_p reaching the floor |
| R, residual | D minus (D_S + D_U + D_I) | tag defects, missed trees |

D = observed minus predicted stems; D_S, D_U and D_I are the component differences; attribution shares are each component
over D. Ingrowth past the floor is U + I (choice 3 decides whether U is reported apart). Shares are pooled over stands by
the r2 stand weights, with site cluster bootstrap intervals (B = 1000, PREREG37 seed and weights). Beside the shares, the
PREREG27 tables are reproduced for QC: survivor ratio (predicted over observed S) and predicted against observed annual
survival, (S over t1 count) to the power 1 over interval, in the PREREG27 interval bins, bins of 30 or more trees (the
PREREG45 bin floor). Fold A tables are a replication, reported, not gated. Screening on the PREREG19 cut flag keeps harvest
out of tag loss.

## Harness gates

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| T0 | field tag survivor join reproduces the PREREG37 counts | 698 fold A, 737 fold B, exactly | PREREG37 |
| T1 | per stand t1 stems in the field tag frame equal t1 stems in the run frame | worst scaled difference at or below 1e-6; failing stands excluded and counted | PREREG44 G2 tolerance |
| T2 | qc141 D over all fold B stands, expressed as the r2 stems deviation, equals the published value | 24.23 points, to the published rounding | PREREG45 RESULT |
| T3 | residual R over D on covered stands | at or below 0.10 [choice 2a, no record] | this draft |
| T4 | covered stands carry this share of the fold B qc141 deficit | at least 0.5 [choice 2a, no record] | this draft |

## Attribution gates (fold B, per arm)

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| A_S | survivor share D_S over D | at or above 2/3, bootstrap lower limit above 0.5 [choice 2a, no record] | this draft |
| A_I | ingrowth share (D_U + D_I) over D | as A_S | this draft |
| SR | survivor ratio, pooled | outside 0.90 to 1.10 counts as material | PREREG14 window, as read by PREREG27 |
| AR | arm invariance: D for the second arm minus D for qc141 | within 2.0 points | PREREG38 B2, as applied in PREREG45 |

## Decision rule, in order

1. T0, T1, T2, T3 or T4 fails: harness failure, no attribution; the failing gate is named and the coverage reported.
2. A_S passes and SR is material: **14.3 mortality track**. If observed annual survival also rises with interval while
   predicted stays flat, the pattern PREREG27 found in NS, the QC track is folded into the NS survival step correction
   (PREREG49) rather than opened alone.
3. A_I passes: **14.3 ingrowth track**, with U and I reported so the track knows whether the deficit is recruitment or
   diameter growth near the floor (the latter points back to the diameter increment, where PREREG19 placed the excess).
4. Neither share passes: mixed deficit, no track named; shares and intervals reported.
5. AR fails in any of rules 2 to 4: the named track is conditional on the height form, and the split is reported per arm.

**No outcome changes 14.2.**

## Execution

New directory `~/jobs/v142p48/` on firebreather. This preregistration's md5 is recorded in `logs/prereg_md5.txt` before
any script runs. Chain detached (`setsid nohup`): T0, T1, the split for each arm, T2 to T4, bootstrap, then assembly as a
separate step with its md5 recorded before it runs. At most 2 R processes, none started at load 12 or above. Script md5s
go to `logs/launch_md5s.txt` before the chain starts. Inputs are read only; nothing is overwritten. Deviations are logged
in the RESULT.

## Choices made (11 October 2026)

Aaron's instruction of 11 October resolved every choice to its recommended option. Second arm: the PREREG46 candidate if
one is named, otherwise frozen qc_rh (1a). Thresholds: survivor or ingrowth share at or above 2/3 with bootstrap lower
limit above 0.5, residual at or below 0.10, coverage at least 0.5 (2a); these carry no record provenance and are set by
this choice before any PREREG48 table exists. Upgrowth is reported as its own component and summed into ingrowth for A_I
(3a).

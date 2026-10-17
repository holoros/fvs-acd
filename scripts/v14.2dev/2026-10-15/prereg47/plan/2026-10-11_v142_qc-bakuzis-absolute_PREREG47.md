# Absolute Bakuzis gates for QC on the measured stand list grid, for 14.3: preregistration 47

11 October 2026, revision 1. Registers the draft of the same day (`2026-10-11_v142_qc-bakuzis-absolute_PREREG47_DRAFT.md`)
with the recommended option on each of its four choices, on Aaron's instruction to resolve all recommendations; recorded
before any PREREG46 long run output exists. Nothing here has been run, fitted or read against a new output. The outcome **informs
14.3 only; 14.2 keeps QC_AFAC 0.111** and no 14.2 verdict is reopened. QC only: NS, NB and ME Bakuzis rules are untouched.
No model run. Stand identifiers stay in `*_SERVERONLY` files. No coordinates. No em dashes.

## What it replaces, and why

PREREG44 (plan md5 37cde199) and the long run clauses of PREREG45 and PREREG46 clear a QC arm only if it is non inferior
to qc141 (QC_AFAC 0.111) under rule (A) and (B). That reference is not a credible long run projection: its benchmark
pooled height increment ratio is 0.093 (PREREG45), its top height falls at some point in all 36 PREREG44 stands (HT
monotone 36 of 36, worst fall 1.04 m), and its median HT/ESI at 100 years is 0.916 from 0.784 at t1 (PREREG45 credibility
table). Non inferiority to it rewards stalled growth: a unit that qc141 passes only by not growing counts against any arm
that grows (PREREG45 traces its two new Reineke flags to faster growth on unchanged mortality). The release notes list this
as an open item. For QC, PREREG47 replaces (A) and (B) with absolute gates on the same grid, measured or external.

## Grid, relations and inputs, unchanged

The 36 fold B stands of PREREG44 (`v142p44/plan/stands_S{1,2,3}_SERVERONLY.csv`), 100 annual steps, read every five years.
Every relation statistic is computed by the `relations()` function of `assemble_p44_r2.R` (md5 5ac535e6) copied unchanged;
PREREG47 changes only what is gated and against what. Thresholds from PREREG31 (`thresholds_p31_DATA_2026-09-30.csv`):
frontier log10 TPH = 5.0914 - 1.4690 log10 QMD, BA 51.73 m² ha⁻¹ and SDI 1,178 at the measured qc_c 99.9th percentile.

## Gates, per arm

| Gate | Relation, unit | Absolute test | Threshold | Provenance |
|:--|:--|:--|:--|:--|
| C | Credibility, stand | offset removed median HT/ESI at 100 years and count of stands above 1.175; raw median | offset removed median at or below 1.175 with at most 3 of 36 stands over, and raw median at or below 1.285 | 1.175, 99th percentile, and 1.285, maximum, of measured TOPHT/esi8 over 756 admitted qc_c visits (`frontier_p45_DATA.csv`, md5 63826d67); offset by `st2_offset.R` (md5 567fa63d) |
| F | Frontier, stand | log10 TPH above the frontier at any five year point | no stand | measured, thresholds_p31 |
| M | Magnitude, stand | max BA over 51.73, max SDI over 1,178 | no stand above 1 | measured, thresholds_p31 |
| S | Sukachev, ESI bin | cohort stems lost strictly increasing across SDI bins at 50 and 100 | no violation | structural; the PREREG44 rule has no tuned constant |
| HM | HT monotone, stand | largest five year top height fall; stands with a fall over 0.01 m | worst fall at or below F_HT; flagged stands at or below S_HT | F_HT: 99th percentile of the measured t1 to t2 TOPHT decrease over admitted qc_c stands with a decrease; S_HT: ceiling of 36 times the share of admitted qc_c stands whose measured TOPHT decreases by more than 0.01 m. Measured heights only (the PREREG40 basis, avoiding the `himp` share PREREG39 found), frozen p19_a0111 observed columns (md5 979101be). [ASSUMPTION: a remeasurement interval decrease is compared with a five year model fall; intervals are reported] |
| R | Reineke, stand, from RD 0.5, QMD advancing more than 0.5 cm per step | median slope of log TPH on log QMD over evaluated stands, per stand flags | reported, not gated: median inside (-2.2, -1.2) | RD from the measured frontier; window from PREREG31 with no external source in the records, so demoted to reported (choice 4) |
| SO | Site ordering, SDI bin | ESI bin means of HT gain since age 0 at 50 and 100 years; VOL gain and levels reported | zero inversions | structural |
| E | Eichhorn, SDI bin | mean CV of VOL across ESI bin means at 8 matched top heights | reported, not gated: below 0.15 | PREREG31 constant with no external source in the records, demoted to reported (choice 4) |
| YD | Yield density, ESI bin | CV of SDI bin mean VOL at 100, and at 30 | gated: CV at 100 below the CV at 30; reported: CV at 100 below 0.15 | the first part is structural; 0.15 demoted to reported as for Eichhorn |

[F4] Shared sources, stated: gate C (both bounds), the PREREG46 RMAX of qc_ez and the HM thresholds all derive from the frozen
p19_a0111 observed columns (md5 979101be); F, M and the RD 0.5 start of R derive from thresholds_p31. Gates on the same file
are not independent checks of it. No threshold is anchored to a qc141 output.

## Decision rule, per arm, in order

1. Any input md5 differs from its frozen record, the copied `relations()` does not reproduce the frozen PREREG44 and
   PREREG45 relations files to 1e-9, or the thresholds file md5 was not recorded before the first reading: harness failure,
   no reading.
2. Gate C fails: not credible on long run grounds; every other gate still reported.
3. F, M, S or HM fails: structural failure, failing gates named.
4. SO or the structural part of YD fails: not cleared on Bakuzis grounds, failing relations named. R, E and the 0.15 part of
   YD are reported beside the outcome and do not change it.
5. All pass: the arm clears the QC absolute grid; for 14.3 it remains subject to its own benchmark gates.

Where several fail, the first applicable rule is the outcome and every failing gate is reported. **No outcome changes 14.2.**

## Retroactive reading, reported and not gated

Frozen qc141 and p38_fit (PREREG44) and qc_rh (PREREG45) are read through these gates and reported beside their registered
verdicts, which stand. Expectation from the inputs: qc141 passes raw gate C (median 0.916, 0 stands over) and fails HM
unless F_HT exceeds 1.04 m; p38_fit fails gate C (median 1.515, 34 over); qc_rh fails gate C raw (1.309, 32 over) and with
the offset removed (1.205, 24 over, PREREG45 ST2). PREREG46 (registered, md5 eb4b753d) keeps its own rule 4 with non
inferiority. Its arms qc_lz and qc_ez are read through PREREG47 once its RESULT exists, as a second reported column. That
reading is blind only if PREREG47 is registered before any PREREG46 long run output is opened; otherwise it is labelled post
hoc. Prospectively, (A) and (B) are replaced by these gates for QC arms registered after PREREG47.

## Execution

New directory `~/jobs/v142p47/` on firebreather; frozen runs are read, never rerun; nothing is overwritten. Order: record
this plan's md5; build `thresholds_p47_DATA.csv` (F_HT, S_HT and the interval distribution behind them) from frozen inputs and
record its md5; record md5s of `assemble_p47.R` and every trajectory read (`v142p44/out/`, `v142p45/out/`, later
`v142p46/out/`) in `logs/launch_md5s.txt` before any reading. A dry assembly on synthetic trajectories is allowed.

## Choices made at registration

Gate C takes the PREREG46 form (choice 1a), so a PREREG46 arm and a PREREG47 reading use the same bound. Site ordering is
gated on growth since age 0 (2a), because levels invert at all 20 ages in every SDI bin in both PREREG44 arms. Reineke is
read as the median slope with per stand flags (3a). No external source for the three PREREG31 constants (Reineke window,
Eichhorn and yield density 0.15) exists in the records and none was cited, so under 4a all three are reported, not gated;
a later revision may promote any of them once a source is supplied, before the reading it would govern.

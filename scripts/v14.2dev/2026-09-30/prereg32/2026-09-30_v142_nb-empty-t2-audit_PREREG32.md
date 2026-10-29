# PREREG32: nb_c and other scored sets with empty observed t2, audit and rescoring

Revision 1, 30 September 2026. Written before any rescored ratio is computed. Scoring only: no engine, coefficient,
frame, scorer file or frozen verdict is changed. Aggregates only leave the server; no coordinate column is read. No em dashes.

## 1. What was seen

The PREREG29 side sweep (`~/jobs/v142p29_nsrs/scripts/2026-09-30_v142_p29_empty_t2.R`; outputs
`side/p29-side-volconv-vo-zero_DATA_2026-09-30.csv`, `side/p29-side-results-empty-t2_DATA_2026-09-30.csv`) read the
PREREG16 volconv stands table (`~/jobs/v142p18/in/cardinal/gyr142-volconv-stands_DATA_2026-09-27.csv`, arm v141LT, 19
labels) and found observed t2 volume V_o = 0 on 38 stands that are RUN_OK 1 and admitted by the scorer rule
(RUN_OK == 1 and finite TOTVOL_o and TOTVOL_p): nb_c 33 of 355 (all 2016 to 2022 remeasurements), medev_c 2 of 1760,
mefia_l_c 2 of 918, ns_long_c 1 of 8549. In nb_c all 33 also have BA_o = 0 and QMD_o = 0. They enter the pooled scores as
zero observations against positive predictions.

## 2. Classification of the empty t2 stands

Each stand gets exactly one class, tested in this order; the first class whose evidence is met is assigned.

| Class | Meaning | Evidence required |
|:--|:--|:--|
| D, frame or scoring defect | live trees exist at t2 in the source but were lost between source and score | source t2 visit (GYDB S_Trees via the frame builder rules, or the old magp_qcnb t2 frame) holds live stems (status 1 to 9) with DBH at or above SCORE_MINDBH_USED and positive EXPF, while the bench frame tree_t2 holds none, or the frame holds them and the published V_o is still 0 (join, status filter, diameter threshold or plot identity mismatch) |
| H, harvested | removal inside (Y1, Y2] | a GYDB treatment or disturbance year in (Y1, Y2] for the plot key, a harvest or cut status on the t2 tree records, TRT_AT_Y1 or MANAGED showing a removal regime, or source t2 tree rows present only with removal status codes |
| L, lost or not remeasured | t2 visit is a placeholder | t2 visit exists with no tree records of any status in the source and in the frame, and no harvest evidence |
| R, recorded without qualifying trees | t2 visit recorded, no live tree scores | source t2 tree rows exist but all are dead, missing DBH, below SCORE_MINDBH_USED or zero EXPF, with no harvest evidence |
| U, unresolved | evidence on the server is insufficient | none of the above can be established from firebreather files |

The frame builder applies a three live tree minimum at t1 and t2 (any size) before emitting a pair, so a pair with an
empty t2 visit should not reach the frame; the audit records how many empty t2 stands pass or fail that rule as built.
Where the source for a set is not on firebreather (medev_c, mefia_l_c), the class is U unless frame files allow D, H, L or R.

## 3. Rescoring

Admissions, applied to the same published per stand values:
- A0, published: RUN_OK == 1, finite TOTVOL_o and TOTVOL_p (the scorer rule, md5 019df238).
- A1, exclude every stand with V_o = 0.
- A2, exclude only stands classed H or L.

Arms: v141LT as published in PREREG16 tables_r1 (`~/jobs/v142vc/cardinal/tables_r1/gyr142-volconv-scores_DATA_2026-09-27.csv`),
per stand values from the PREREG16 stands table and the v141LT nb_c results file; every arm scored on nb_c in PREREG19,
PREREG23 or PREREG28 (from their tables and results directories) is rescored the same way, and its observed side compared
with v141LT to confirm arm invariance.

Metrics per set, arm and admission: pooled ratio sum(p)/sum(o), bias percent 100(mean p - mean o)/mean o, percent RMSE
100 sqrt(mean (p - o)^2)/mean o, for volume under C0 (as published) and C1 (himp on both sides), basal area (BA_o, BA_p) and
stems (TPH derived per stand as BA / (pi/40000 QMD^2), 0 when BA is 0). A0 volume must reproduce the published PREREG16
point values to 1e-9 (gate G0); otherwise stop. Intervals: nb_c 95 percent site cluster bootstrap with the published site
index `siteidx_nb_c.rds` (B = 1000 if the file holds 1000 draws; the count used is reported), draws reweighted to the
admitted stands. Other sets: point values (their site indices or results may not be on firebreather; stated if so).

## 4. Materiality rule (fixed now)

The exclusion is material for a set if, under A1 or A2 against A0, any pooled volume (C0 or C1), BA or stems ratio moves by
more than 0.02 in absolute value, or any %RMSE moves by more than 1.0 point.

## 5. Decision rule

- Material for any set: propose an admission rule for 14.2 scoring and name every past verdict whose reading of that set
  would change. No verdict is changed by PREREG32.
- Not material for any set: report and close.
- A class D finding is reported as a frame defect regardless of materiality, with the proposed repair, not applied.

## 6. Verification [F9]

An independent script in `verify_20260930/` re-reads frames, results and stand tables (no source() of PREREG32 scripts),
re-derives the empty t2 counts by set and the nb_c pooled ratios under A0, A1 and A2, and compares with `assembled/` at
tolerance 1e-9 (counts exact). It ends with a DONE marker.

## 7. Figure

One ggplot2 figure, 180 mm wide, 300 dpi, theme_classic: nb_c pooled ratios by variable (volume C0, C1, BA, stems) under
A0, A1 and A2 with 95 percent site cluster intervals, SI units.

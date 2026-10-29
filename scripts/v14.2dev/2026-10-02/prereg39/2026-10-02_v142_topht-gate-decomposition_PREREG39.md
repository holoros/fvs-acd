# Decomposing the TOPHT gate against the tag dominant cohort: pre-registration 39

2 October 2026, revision 1, firebreather `~/jobs/v142p39/`. Written before any PREREG39 output exists. A diagnostic on frozen
outputs only: no engine run, no score, no refit, no gate or default changed, nothing adopted. It follows PREREG38
(`~/jobs/v142p38/plan/2026-10-01_v142_qc-anchor-fieldtag-refit_PREREG38.md`, md5 69223abd; RESULT md5 91012d43, verified 76 of
76). L and T are not re-estimated, GT1 stays a named failure. No coordinate column is read. Aggregates only outside
`*_SERVERONLY_*` files. No em dashes.

## Why

On screened qc_c fold B the published stand TOPHT bias and the field tag dominant cohort level disagree by about 16 points
at every QC anchor: at 0.111 TOPHT +6.29 percent against a dominant level of 0.898 (minus 10.2 percent); at 1.242 TOPHT
+16.21 against 0.994 (minus 0.6). The PREREG38 TOPHT gate rejected the anchor that the increment and dominant cohort gates
accept. The two measures differ in construction, and which difference carries the offset is untested. This study
decomposes the gap into named, ordered steps that walk from the dominant cohort metric to the published TOPHT metric, on the
same stands, for the two arms p19_a0111 (qc141, 0.111) and p38_fit (1.242).

## What was already seen, stated openly

The PREREG38 RESULT and every PREREG38 assembled file, including the gates-all table (TOPHT and dominant level for ten arms)
and the hinc table. The runner `runner_p28_fb.R` (0a2b2742) source: `himp` (line 184), `metrics()` and its TOPHT line
(line 208), the observed and predicted `metrics()` calls (line 457) and the `pred_t2_tree` writer. The PREREG23 tag key
helper `2026-09-29_v142_p23_hkey.R` (59196106) source. The header lines and line counts of the qc_c field tag frames in
`~/jobs/v142p14/in/pass28qc/` (init 65,788 rows, t2 68,584 rows) and of the run frame t2 file, and the fact that the field
tag and run frames list the same rows in the same order with a different TREE column. No tree level count, height, fraction
or stand value beyond the PREREG38 tables has been computed for this study.

## Inputs (all frozen, read only)

| Item | Path |
|:--|:--|
| Results, qc141 | `~/jobs/v142p19/results/p19_a0111/gyr_p19_a0111_qc_c_results.csv` |
| Results, p38_fit | `~/jobs/v142p38/results/p38_fit/gyr_p38_fit_qc_c_results.csv` |
| Stand tables (cut flag, screen) | `~/jobs/v142p19/tables/gyr142-p19-fb-stands_DATA_2026-09-27.csv` (qc141), `~/jobs/v142p38/tables/gyr142-p38-fb-stands_DATA_2026-09-27.csv` (p38_fit) |
| Predicted t2 tree lists | `c*_pred_t2_tree.csv` under `<home>/out/<arm>/qc_c` then `<home>/out_retry_a1..3/<arm>/qc_c`, a later directory replacing whole stands (the PREREG38 `rd()` rule); home `~/jobs/v142p19/home` or `~/jobs/v142p38/home` |
| Field tag frames | `~/jobs/v142p14/in/pass28qc/bench_gyr_qc_c_tree_init.csv`, `..._tree_t2.csv` |
| Run frame t2 (reproduction only) | `~/jobs/v142p19/home/magplot/verify/gydbreg20260916/frames/bench_gyr_qc_c_tree_t2.csv` |
| PREREG38 references | `~/jobs/v142p38/assembled/gyr142-p38-stands-summary_DATA_2026-10-01.csv`, `..._hinc_DATA_2026-10-01.csv` |

Every input md5 is written to `logs/input_md5.txt` before the first value is computed.

## Population

For each arm a: the arm's stand table rows with label qc_c and arm a, merged by STAND with the arm's results rows with
RUN_OK 1, kept where cut is FALSE and fold is B (fold: first hex digit of md5(SITE) even is A, the helper `fold_of`). This is
the PREREG38 `STS` screened B population. Species codes map with the runner `mapsp`.

## Definitions

Runner TOPHT rule, `top(sp, dbh, ht, expf, mindbh)`, copied from `metrics()`: keep records with finite dbh at or above mindbh
and finite expf above 0; order by decreasing dbh (R `order(-dbh)`, ties in input order); cumulative expf; keep records with
cumulative expf at or below 100, or the first record if none; return the unweighted mean of ht where ht is finite, else
`himp(sp, dbh)`. mindbh is the stand's SCORE_MINDBH_USED from the arm's results. A record is a row of the list.

Tag link (helper rules): init frame F and t2 frame G from pass28qc, row0 the row number within stand; TAG = TREE where tagok;
(STAND, TAG) keys duplicated at either end dropped at that end. A t1 row is a survivor when its TAG is present at t2. The t1
dominant flag `dom` is the helper rule on all F rows of the stand: order by decreasing DBH (ties first in input order),
cumulative EXPF at or below 100 or the first row. Hp for a t1 row is the mean predicted t2 ht over its split parts with ing 0
(the helper `pred_ht`, split map from the scorer code the helper sources).

## The ladder

Each rung is computed per arm on the population. Rung D0 is in the dominant cohort metric form; D1 to D6 are bias percent
of stand means, B = 100 (mean over stands of the stand mean predicted height minus mean over stands of the stand mean
observed height) divided by the latter, over stands with at least one record on each side.

| Rung | Predicted side | Observed side | Step it isolates |
|:--|:--|:--|:--|
| D0 | Hp of t1 dom survivors with same species at both ends, H1 above 0 and H2 above 0 | H2 of the same records | the PREREG38 dominant metric, 100 (sum Hp over sum H2 minus 1), pooled |
| D1 | same records | same records | aggregation: stand means and bias percent instead of a pooled tree ratio |
| D2 | t1 dom survivors with H2 above 0, any species pairing and any H1 | H2 | tag record rules (species match, measured H1) |
| D3 | all t1 dom survivors | H2 where finite, else `himp(mapsp(SP2), D2)` (the runner observed height rule) | observed height handling |
| D4 | every t1 dom row (any observed fate, any tag status), Hp, `himp` if Hp not finite | as D3 | predicted trees whose observed counterpart died or cannot be followed |
| D5 | `top()` on predicted records with ing 0 (split parts as records) | `top()` on observed t2 rows that are survivors | t2 rank selection to 100 stems ha⁻¹, mindbh, record unit |
| D6 | `top()` on all predicted records | `top()` on all observed t2 rows (adds recruits and t2 rows without a usable tag) | recruits and unlinked rows; equals the published TOPHT |

Step contributions are delta_k = Dk minus D(k minus 1), k = 1 to 6; gap = D6 minus D0 = the sum of the deltas. The order is
fixed here and the attribution is read in this order only.

Groups: G1 aggregation and record rules (delta_1 + delta_2), G2 observed height handling (delta_3), G3 fate (delta_4), G4 t2
rank selection (delta_5), G5 recruits and unlinked rows (delta_6).

Intervals: site cluster bootstrap over the fold B sites of the union of both arms' populations, B = 1000, seed 20261002, one
resampling matrix for both arms. D0 from site sums of Hp and H2; D1 to D6 from stand means with site multiplicity weights.
95 percent percentile intervals for every rung, delta, group and the gap.

## Reproduction stops, before any rung value is used [F9]

S1: D6 stand values equal the arm's results TOPHT_o and TOPHT_p for every population stand (at or below 1e-9), and D6 equals
the PREREG38 stands summary `topht_bias_pct` for set qc_c, pop screened B, that arm (1e-9). S2: D0 equals 100 (level_t2 minus
1) of the PREREG38 hinc row (field tag, qc_c, fold B, group dominant, that arm) to 1e-9 and its record count equals that
row's `trees`. S3: population stand counts equal the PREREG38 stands summary `stands` (screened B, qc_c). S4: the field tag t2
frame and the run frame t2 file agree on every column other than TREE, row for row. Any stop failing: no reading, harness
failure reported.

## Outcome rule, fixed now

Primary arm p38_fit. A group is the dominant source if its contribution is at least 0.5 of the gap and its 95 percent
interval excludes 0. If no group qualifies the outcome is diffuse, naming every group at or above 0.25 of the gap. The
reading is called consistent across arms if qc141 gives the same outcome. The arm difference of each rung (p38_fit minus
qc141) is reported to show which steps respond to the anchor.

Consequences, stated now and acted on only through a separate pre-registration: G2 dominant, the observed TOPHT is driven by
the observed height rule and a TOPHT gate on measured heights is the next track; G3 or G4 dominant, TOPHT measures different
trees from those the anchor acts on, and replacing the TOPHT gate by the dominant cohort or a survivor TOPHT is the next
track; G5 dominant, the offset belongs to ingrowth, outside the anchor's scope; G1 dominant, the gap is a metric form
difference; diffuse, reported with no automatic next track. In every case 14.1 keeps 0.111 and no PREREG38 verdict changes.

## Diagnostics, reported

Q1: in the observed D6 and D3 sets, the share of records whose height came from `himp`, and the count of finite heights at or
below 1.3 m. Q2: for observed D6 records with a finite height above 0, sum `himp(sp, dbh)` over sum height. Q3: the share of
observed D6 records that are t1 dom survivors and the share of predicted D6 records whose row is a t1 dom row with ing 0. Q4:
records per stand at each rung. Q5: the gap for the eight other PREREG38 single value arms is not computed (only the two
named arms have a role here).

## Expectation, stated now

The gap is near constant across anchors (16.5 at 0.111, 16.8 at 1.242), so most of it should sit in steps that do not
respond to the anchor, which points to the observed side (G2, or the observed half of G4 and G5) rather than to the model.
No group is predicted.

## Outputs

`scripts/assemble_p39.R`, `assembled/` (gyr142-p39-ladder, deltas, groups, repro, diag, stands_SERVERONLY per stand rungs,
verdict; `_DATA_2026-10-02`), `figs/gyr142-p39-topht-ladder_2026-10-02.png` (ggplot2 theme_classic, 180 mm by 110 mm, 300 dpi;
(a) rungs D0 to D6 for both arms with intervals, (b) deltas with intervals) with its data file, `logs/` (prereg md5, input
md5, assembly), RESULT `2026-10-02_v142_topht-gate-decomposition_RESULT.md`.

## F9 verification plan

An independent verifier, written from this plan alone without reading the assembly or its outputs until its own numbers are
written, re-derives D0 to D6, the deltas, the group contributions and the gap for both arms (points to 1e-9), S1 to S3, Q1 and
Q2, and the outcome. Bootstrap limits are not re-derived.

## Constraints

New directory `~/jobs/v142p39/` only; every earlier job directory is read, never written. Frozen runs are not rerun. Model
files unedited. No coordinates. Nothing is sent outside by the assembly.

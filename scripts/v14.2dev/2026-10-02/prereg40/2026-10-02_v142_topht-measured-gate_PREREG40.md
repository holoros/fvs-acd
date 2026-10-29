# A TOPHT gate on measured heights for the frozen PREREG38 arms: pre-registration 40

2 October 2026, revision 1, firebreather `~/jobs/v142p40/`. Written before any PREREG40 output exists. Frozen outputs only:
no engine run, no score, no refit of the growth model, no default changed, nothing adopted. It follows PREREG39
(`~/jobs/v142p39/plan/2026-10-02_v142_topht-gate-decomposition_PREREG39.md`, md5 ba0a48ec; RESULT 2976506c, verified 124 of
124) and PREREG38 (plan 69223abd, RESULT 91012d43). L and T are not re-estimated, GT1 stays a named failure. No coordinate
column is read. Aggregates only outside `*_SERVERONLY_*` files. No em dashes.

## Why

PREREG38 rejected the field tag QC anchor 1.242 (p38_fit) on the published TOPHT gate alone (+16.21 percent against a limit
of +14.63, the frozen 1.061 arm). PREREG39 found that 9.3 of the 16.8 point gap between published TOPHT and the tag dominant
cohort comes from one step on the observed side: t2 trees without a measured height enter TOPHT_o with the runner `himp`
curve, 60.6 percent of the observed TOPHT heights are `himp`, and on measured trees of that set `himp` gives 0.892 of the
measured height. The PREREG38 limit is itself an internal arm value under the same imputation (an F4 case). This study asks
whether p38_fit passes a TOPHT gate whose observed side is measured height, with a limit set outside the project.

## What was already seen, stated openly

The PREREG38 and PREREG39 RESULTs and every assembled file of both, including the PREREG38 gates-all table (published TOPHT
and dominant level for ten arms) and the PREREG39 ladder, groups and diagnostics for p19_a0111 and p38_fit (rung D2, tag
survivors with measured H2, any species pairing, stand means: -7.98 for qc141 and +1.61 for p38_fit). The runner
`runner_p28_fb.R` (0a2b2742) source (`sw`, `himp` line 184, the TOPHT line 208), the PREREG23 tag key helper (59196106) and
the PREREG39 assembly r2 (35b8c2ad) source. No value of either variant below, and no height and diameter fit, has been
computed by anyone.

## Arms and population

The ten PREREG38 gate arms, frozen, read only: p19_a0030, p19_a0060, p19_a0111 (qc141), p19_a0250, p19_a0500, p19_a1000,
p23_a1061, p23_a1250, p28b_small, p38_fit. Roots, homes and stand tables as in the PREREG38 assembly (`AR` table, lines 33 to
39 of `v142p38/scripts/assemble_p38.R`); results `<root>/results/<arm>/gyr_<arm>_qc_c_results.csv`; predicted t2 tree lists
by the PREREG38 `rd()` rule (`<home>/out/<arm>/qc_c`, then `out_retry_a1..3`, a later directory replacing whole stands).
Population per arm: the arm's stand table rows with label qc_c and arm a, merged by STAND with results rows with RUN_OK 1,
cut FALSE, fold B (`fold_of(SITE)`), the PREREG38 screened B population. Primary arm p38_fit; qc141 is the reference; the
other eight are reported.

## Definitions

`top(sp, dbh, ht, expf, mindbh)` is the runner TOPHT rule as coded in the PREREG39 assembly r2 (`top_sel`, `top_val`):
records with finite dbh at or above mindbh and finite expf above 0, ordered by decreasing dbh, cumulative expf at or below
100 or the first record, unweighted mean of ht where finite, else the fill function. mindbh is SCORE_MINDBH_USED. Species
map `mapsp_r` and `himp` are parsed from the runner. Tag link: the PREREG39 rules on the pass28qc field tag frames
(`~/jobs/v142p14/in/pass28qc/bench_gyr_qc_c_tree_{init,t2}.csv`), TAG = TREE where `tagok`, duplicated (STAND, TAG) keys
dropped at that end, a t2 row is linked when its TAG is present at t1. Predicted records map to t1 rows through the helper
`split_map` (STAND, tree, row0). Stand bias percent B = 100 (mean over stands of P minus mean over stands of O) / mean over
stands of O, over stands with at least one record on each side.

## Reproduction first, before either variant is computed [F9]

R0a: for every arm, `top()` on all predicted records and on all observed t2 rows with the `himp` fill equals results
TOPHT_p and TOPHT_o for every population stand (at or below 1e-9). R0b: B from those values equals the PREREG38 gates-all
`topht` for that arm (1e-9). R0c: population stand count equals the PREREG38 stands summary `stands` (qc_c, screened B).
R0d: the pass28qc t2 frame and the run frame t2 file agree on every column other than TREE. Any stop failing: harness
failure, no variant is read.

## Variant M, measured heights on both sides (primary)

Observed records: t2 rows that are linked and have finite HT above 0. Predicted records: predicted rows with ing 0 whose t1
row (via `split_map`) is linked to a t2 row in that observed set. TOPHT_o^M and TOPHT_p^M are `top()` on these records, with
the stand's mindbh, so each side is the runner rule restricted to trees with a measured t2 height; the observed side uses no
fill. A predicted ht that is not finite takes `himp` as in the runner; the count is reported. B_M per arm.

## Variant H, height and diameter model fitted on fold A (secondary)

Fit data: pass28qc t2 rows in qc_c stands of the p19_a0111 stand table with cut FALSE whose results SITE is fold A, with
finite DBH above 0 and finite HT above 1.3. Model, by the `himp` species grouping (softwood when `mapsp_r(SP)` is in `sw`,
else hardwood), fitted separately per group by `nls` (default Gauss Newton): HT = 1.3 + a (1 - exp(-b DBH))^c, start a 27, b
0.030, c 1 (softwood) and a 25, b 0.028, c 1 (hardwood). If `nls` fails for a group, the two parameter form with c = 1 is
fitted from the same start and the fallback is reported. No fold B record enters the fit. Observed side: `top()` on all
observed t2 rows (the published set) with the fold A model as the fill in place of `himp`. Predicted side: the published
TOPHT_p (predicted heights are model output; any non finite predicted ht takes the fold A model, count reported). B_H per arm.

## Gate, limit fixed now [F4]

T_M: the absolute value of B_M for p38_fit is at most 10.0 percent. T_H: the same for B_H. Provenance: the USDA Forest
Service FIA National Core Field Guide (Phase 2) measurement quality objective for tree total and actual length, plus or
minus 10 percent of true length. The limit is a field measurement tolerance for one tree; a stand mean model bias larger
than the tolerance accepted for a single measured height is not acceptable whatever the other gates show, so it is a ceiling
and not a target. [UNVERIFIED in this session: the MQO value is stated from the guide as known to the author of this plan;
the FIA site refuses automated fetches, so the guide was not re-read. Aaron confirms the value and section before any
reading is carried forward; if it differs, the gate is re-read under the confirmed value in a dated note and this plan is
not edited.] No arm value enters the limit.

## Decision rule, in order

1. Any reproduction stop R0a to R0d fails: harness failure, no reading.
2. Either fit fails in both forms: variant H not read, reported; the rule continues on T_M alone.
3. T_M and T_H both pass for p38_fit: the published TOPHT rejection of 1.242 is attributed to the observed height rule, and
   p38_fit becomes eligible for the Bakuzis QC grid (the PREREG31 design, p38_fit against qc141) under a separate
   pre-registration with T_M in place of the published TOPHT gate.
4. T_M passes and T_H fails, or the reverse: conflicting; no carry forward, both readings reported.
5. T_M fails: the measured height TOPHT gate also rejects 1.242; the anchor is not carried forward.
In every case 14.1 keeps 0.111, no PREREG38 verdict is changed and nothing is adopted here.

## Reported

For every arm: B_M and B_H with 95 percent site cluster intervals (B = 1000, seed 20261040, one resampling matrix over the
fold B sites of the union of all populations, stand means with site multiplicity weights), stand counts, records per stand,
and the published B. The fold A fit: coefficients, standard errors, records per group, residual standard error, form used.
Diagnostics: D1, share of observed records filled in the published set and in variant H (equal by construction); D2, on
fold B measured trees in the published observed TOPHT set, sum of fill over sum of measured height for `himp` and for the
fold A model; D3, share of published observed TOPHT records that are in the variant M observed set; D4, non finite
predicted ht count.

## Expectation, stated now

From PREREG39 rung D2 (+1.61 for p38_fit, -7.98 for qc141), B_M for p38_fit should sit within a few points of 0 and pass,
with qc141 near -8 to -10. A fold A fill closer to measured height than `himp` (0.892) should take B_H for p38_fit from
+16.2 to roughly +8 to +11, near the limit; T_H is the uncertain gate.

## Outputs

`scripts/assemble_p40.R`, `assembled/` (gyr142-p40-repro, hdfit, gate, arms, diag, verdict, stands_SERVERONLY;
`_DATA_2026-10-02`), `figs/gyr142-p40-topht-measured_2026-10-02.png` (ggplot2 theme_classic, 180 mm by 100 mm, 300 dpi; (a)
published, M and H bias against QC_AFAC for the nine single value arms with p28b_small marked, intervals and the plus or
minus 10 percent band; (b) the fold A fill curves against `himp` over the fit data) with its data file, `logs/` (prereg md5,
assembly md5, input md5, assembly log), RESULT `2026-10-02_v142_topht-measured-gate_RESULT.md`.

## F9 verification plan

An independent verifier, written from this plan alone without reading the assembly or its outputs until its own numbers are
written, re-derives R0a to R0c for every arm, the fold A fit (coefficients to 1e-6 relative), B_M and B_H for every arm (B_M
to 1e-9, B_H to 1e-6), D2 to D4, and the decision. Bootstrap limits are not re-derived. The assembly script is written and
its md5 logged before the verifier is launched; if the verifier still finishes before the assembly outputs exist, the RESULT
says so.

## Constraints

New directory `~/jobs/v142p40/` only; every earlier job directory is read, never written. Frozen runs are not rerun. Model
files unedited. No coordinates. Nothing is sent outside by the assembly.

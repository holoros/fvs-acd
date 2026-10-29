# A single QC height anchor refit on MAGPlot field tags: pre-registration 38

1 October 2026, revision 1, firebreather `~/jobs/v142p38/`. Written before any PREREG38 output exists (no fit file, no
engine run, no score, no assembly). It follows PREREG37 (`~/jobs/v142p37/plan/2026-10-01_v142_qc-height-structure_PREREG37.md`,
md5 c7f1244d; RESULT verified). The session draft of this plan (md5 f0e4f60a) was lost with its workspace before upload;
this revision is rewritten from the brief that described it and supersedes it. L and T are not re-estimated, GT1 stays a
named failure, no 14.1 default or coefficient other than the QC dht.mult is changed. No coordinate column is read.
Aggregates only outside `*_SERVERONLY_*` files. No em dashes.

## Why

PREREG37 showed that the size dependent QC anchor of PREREG28 and 28b (1.265 below 25 cm, 0.111 or 0.030 at and over) is a
row index pairing artifact: the PREREG23 height key helper `2026-09-29_v142_p23_hkey.R` (59196106), reused by PREREG28, 28b
and 33, reads the run frames where TREE is a row index. Under MAGPlot field tags (`~/jobs/v142p14/in/pass28qc/`), the ratio
of observed to unanchored predicted annual height increment R is 1.242 (1.106 to 1.367) on fold A and 1.169 (1.032 to
1.322) on fold B, and S (below over at and over 25 cm) is 1.265 against the 3.376 threshold. A single anchor near R fits;
0.111 does not. Every PREREG23, 28, 28b and 33 height gate was computed on row index pairs, so the reference values for
0.111 are also recomputed here under field tags.

## What was already seen, stated openly

The PREREG37 RESULT in full, including fold A R 1.2418873575799 (`v142p37/assembled/gyr142-p37-ratio-foldA_DATA_2026-10-01.csv`,
md5 2315212d, re-derived by the PREREG37 verifier to 3.3e-15). The frozen stand level values on screened qc_c fold B of
the PREREG19 grid and PREREG23 arms (`v142p19/assembled/gyr142-p19-grid_DATA_2026-09-28.csv`,
`v142p23/assembled/gyr142-p23-stands-summary_DATA_2026-09-29.csv`): TOPHT bias +5.59, +6.29, +7.50, +9.69 and +14.09
percent at QC_AFAC 0.030, 0.111, 0.250, 0.500 and 1.000, +14.63 at 1.061 and +16.28 at 1.250; C1 %RMSE 46.75 to 46.80;
BA ratio 0.998 to 1.002; stems ratio 0.753 to 0.758. Every row index height gate value of PREREG23, 28, 28b and 33. No field
tag height gate value of any engine arm has been computed by anyone.

## Fit, fold A only, frozen before any engine run

QC_AFAC_FIT = R on screened qc_c fold A field tag records, pooled (sum obs over sum p0, PREREG37 definition: obs = (H2 -
H1)/iv, p0 the one year unanchored dht at t1), rounded to three decimals. `scripts/fit_p38.R` reads the PREREG37 fold A ratio
file (md5 checked), selects tagkey "field tag", scheme "all", checks it against the PREREG37 verifier comparison row (fold
A, field, "R all all", difference at most 1e-12), and writes `fit/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv` (value, R,
records, sites, source md5s). The chain records its md5 in `logs/fit_md5.txt` before task 1 starts, and every task checks
it. No fold B value is read by the fit. The value this rule gives is 1.242; it is set by the rule, not by this sentence.

## Arms

| Arm | QC dht.mult | How | Role |
|:--|:--|:--|:--|
| p38_fit | QC_AFAC = QC_AFAC_SMALL = QC_AFAC_LARGE = fit value, KNOT 25 | runner_p28_fb.R, tasks 1 to 20 (qc_c 19 chunks, qc_fl 1) | candidate |
| p38_one | QC_AFAC = SMALL = LARGE = 1.000, KNOT 25 | runner_p28_fb.R, tasks 21 to 24 (qc_c chunks 1, 10, 19 and qc_fl, the PREREG33 G0 subset) | H0 |
| qc141 | 0.111 | frozen p19_a0111, read | reference |
| p28b_small | 1.265 below 25 cm, 0.111 at and over | frozen v142p28b, read | reported comparator |
| one (1.000) | 1.000 | frozen p19_a1000, read; the full benchmark of p38_one by H0 | reported |
| frozen single value arms | 0.030, 0.060, 0.250, 0.500 (p19), 1.061, 1.250 (p23) | read | reported, response curve |

Departure from the draft description: p38_one is run on the G0 subset only. A full benchmark run at 1.000 would repeat the
frozen p19_a1000 run; frozen runs are not rerun. The subset run through the SMALL = LARGE code path against p19_a1000 is
the harness identity test for the path p38_fit uses.

Bundle `~/jobs/v142p38/home`: copy of `~/jobs/v142p28b/home` without `out*`, `logs`, `tables` and `work/retry_keep`; its md5
list must equal the PREREG28b list (`logs/bundle_check.txt`). Runner `runner_p28_fb.R` (0a2b2742) unedited. Task driver,
launcher, retry and scoring scripts are PREREG28b copies with the taskmap, arm case, job root, arm list and scorer changed,
and the launcher load test strict (no start at load 12 or above); diffs in `diffs/`. At most 2 tasks at once. Retry rule,
up front: every stand whose FAIL_REASON is the host time limit is rerun alone by STAND name through STAND_KEEP_FILE, never
by pairs row, up to three attempts, for both arms. Scoring: scorer r2 (`v142p35/scripts/2026-10-01_v142_volconv_score_r2.R`,
265fc695, unedited), C0 and C1 only, on p38_fit and on frozen p19_a0111 (the latter only for the reproduction check R4). The
tables carry the scorer's fixed 2026-09-27 stamp. C1 is primary.

## Assembly

`scripts/assemble_p38.R`: the PREREG28b assembly (90e6c5bc) formulas, with the height key run twice. Pass 1, row index
(helper default frames, seed 20260929, frozen arms only), exists only to reproduce PREREG23. Pass 2, field tag (`FR` set to
`~/jobs/v142p14/in/pass28qc` after sourcing the helper, as PREREG37 did; seed 20261001, site cluster bootstrap B = 1000), is
the basis of every height gate. Predicted annual increment (Hp - H1)/iv, ratio = predicted over observed (the PREREG28
convention; PREREG37 R is its inverse at the anchor 1).

Reproduction stops, before any p38 value is used [F9]: R1, pass 1 reproduces the PREREG23 height table (points at or below
1e-9, at least 60 rows); R2, frozen stand level values reproduce the PREREG19 grid and PREREG23 stands summary (1e-9, at
least 16 rows each) and p28b_small reproduces the PREREG28b stands summary (1e-9); R3, pass 2 screened qc_c tag record counts
equal the PREREG37 field tag counts read from `v142p37/assembled/gyr142-p37-counts-fold{A,B}_DATA_2026-10-01.csv` (698 and
737); R4, r2 stand rows for p19_a0111 equal the frozen PREREG19 stands table on every shared numeric column (1e-9); R5, the
fit file value equals round(R_A, 3) re-read from the PREREG37 file.

## Gates (screened qc_c fold B; height gates on field tags)

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H0 | p38_one against frozen p19_a1000 on the subset: every _p column, ING_p, RUN_OK; per tree t2 ht, dbh, expf, ing | worst scaled difference at or below 1e-9 | PREREG28 H0 test |
| K1 | RUN_OK other than 1, p38_fit, after retry | 0 | PREREG23 K1 |
| H1 level | pooled annual height increment ratio | 0.90 to 1.10 (point) | PREREG14 H increment window |
| H classes | mean bias by t1 class (below 12.7, 12.7 to 25, 25 and over) | no class worse in absolute value than qc141 under field tags by more than 0.03 m yr⁻¹ | PREREG23 M_CLS, parsed |
| TOPHT | published TOPHT bias; dominant cohort t2 level | TOPHT absolute bias no larger than at 1.061 (frozen p23_a1061, read); dominant cohort deviation from 1 no larger than qc141 under field tags plus 0.02 | PREREG23 margin, M_DOM parsed |
| V2 | C1 %RMSE | %RMSE(qc141) minus %RMSE(arm) at or above -0.5 | PREREG23 |
| B1, B2 | basal area, stems ratio | absolute deviation from 1 no worse than qc141 by more than 1.0 and 2.0 points | PREREG23 as coded |

F4 note: the TOPHT limit is an internal arm value (the frozen 1.061 result), kept because the brief and PREREG23 to 33 used
it; its value is read from file, not typed. The H1 window is the only external style bound; V2, B1 and B2 are relative to
qc141.

## Decision rule, in order

1. H0, K1 or any reproduction stop R1 to R5 fails: harness failure, no verdict.
2. H1 level fails: not adopted.
3. H classes fails: not adopted, the class named.
4. TOPHT fails: not adopted, the TOPHT and dominant readings named.
5. V2, B1 or B2 fails with the height gates passing: not adopted, trade off reported.
6. Every gate passes: the single field tag anchor is the 14.2 QC candidate, a regional usage setting, pending a Bakuzis QC
   grid under PREREG39 (the PREREG31 design with this value against qc141).

Where several gates fail the first applicable rule is the outcome and every failing gate is reported. The same gates are
computed for every reported arm and labelled reported. Fixed now: if p38_fit fails and a frozen single value arm passes
every gate under field tags, it is named only as eligible for a separately pre-registered confirmation, because choosing
it after seeing fold B is selection, not a test.

## Expectation, stated now

At anchor a the field tag pooled ratio should sit near a / R_B, about 1.242 / 1.169 = 1.06, so H1 should pass and the class
gates should pass (qc141 under field tags under predicts every class). TOPHT is expected to fail: interpolating the frozen
arms linearly between 1.061 (+14.63) and 1.250 (+16.28) gives about +16.2 percent at 1.242. If so, the field tag increment
evidence and the stand level TOPHT gate disagree, and the window that satisfies both, roughly 0.90 R_B to the 1.061 limit,
is narrow; that reading is reported, not acted on.

## Figure

`figs/gyr142-p38-fieldtag-anchor_2026-10-01.png`, ggplot2 theme_classic, 180 mm by 150 mm, 300 dpi, with its data file.
(a) Pooled ratio against QC_AFAC for the single value arms and p38_fit, fold B, field tag, with intervals and the 0.90 to
1.10 band; (b) TOPHT bias against QC_AFAC with the 1.061 limit; (c) class bias, fold B, field tag, for qc141, p28b_small, one
and p38_fit; (d) dominant cohort t2 level against QC_AFAC with the qc141 plus 0.02 band.

## Outputs

`fit/`, `home/`, `results/`, `tables/`, `assembled/` (gyr142-p38-*_DATA_2026-10-01.csv, verdict file), `figs/`, `logs/`
(prereg md5, fit md5, bundle check, launch md5s, chain, score, assembly), `diffs/`, RESULT
`2026-10-01_v142_qc-anchor-fieldtag-refit_RESULT.md`.

## F9 verification plan

An independent verifier, written from this plan alone without reading the assembly, re-derives from the frames, the
pass28qc field tag frames, the per tree predictions and the results files: the field tag record counts, the pooled ratio,
class biases and dominant level on screened qc_c fold B for p38_fit, qc141 and p28b_small (points to 1e-9), TOPHT bias,
C1 %RMSE, BA and stems ratios for p38_fit and qc141, the H0 worst differences, and the verdict under the rule above.

## Constraints

New directory `~/jobs/v142p38/` only; PREREG19, 23, 28, 28b, 33 and 37 files are read, never written. Frozen runs are not
rerun. Model files unedited. No coordinates. Nothing is sent outside; the laptop, GitHub and Zenodo are not touched by the
chain.

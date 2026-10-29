# A single QC height anchor refit on MAGPlot field tags: PREREG38 result

1 October 2026. Pre-registration `plan/2026-10-01_v142_qc-anchor-fieldtag-refit_PREREG38.md` (revision 1, md5 69223abd),
recorded at 21:57:28 server time before any PREREG38 output (`logs/prereg_md5.txt`). The session draft (f0e4f60a) was lost
with its workspace and never uploaded; this revision was rewritten from the brief. Fit `scripts/fit_p38.R` (7cc3102f), fit
file `fit/gyr142-p38-qcafac-fit_DATA_2026-10-01.csv` (e782957c, md5 logged before task 1). Runner `runner_p28_fb.R`
(0a2b2742) unedited; bundle md5 list identical to PREREG28b (47 files). Task driver `run_task_p38.sh` (423e0162), scorer r2
(265fc695, unedited), assembly `scripts/assemble_p38.R` (0f26a16c), chain `scripts/chain_p38.sh` (505f974e). Chain start
21:57:51, CHAIN_DONE 22:24:05. L and T not re-estimated; GT1 stays a named failure. No coordinates. No em dashes.

## Verdict

**Rule 4. The single field tag anchor 1.242 fixes QC height increment and fails the TOPHT gate: not adopted.** On screened
qc_c fold B under field tags, p38_fit brings the pooled increment ratio to 1.053, every diameter class within 0.04 m yr⁻¹ of
zero and the dominant cohort t2 level to 0.994, but the published TOPHT bias is +16.21 percent against the +14.63 limit set by
the frozen 1.061 arm. This was the stated expectation. 14.1 keeps 0.111. No frozen single value arm passes every gate
(p23_a1061 misses the H1 window at 0.898), so none is eligible for a confirmation run.

| Gate, screened qc_c fold B | p38_fit (1.242) | qc141 (0.111) | Threshold | Pass |
|:--|:--|:--|:--|:--:|
| H0, p38_one against frozen p19_a1000 (58 qc_c, 19 qc_fl stands; 11,594 trees) | 0 | | at or below 1e-9 | Yes |
| K1 after retry | 0 of 378 qc_c, 0 of 19 qc_fl; no time limit hits | | 0 | Yes |
| H1 pooled ratio, field tag | 1.053 (0.930 to 1.213) | 0.093 | 0.90 to 1.10 | Yes |
| Bias below 12.7 cm | -0.027 m yr⁻¹ | -0.190 | not worse than qc141 by 0.03 | Yes |
| Bias 12.7 to 25 cm | +0.022 m yr⁻¹ | -0.141 | same | Yes |
| Bias 25 cm and over | +0.038 m yr⁻¹ (-0.003 to +0.083) | -0.120 | same | Yes |
| TOPHT bias | **+16.21 percent** | +6.29 | at most +14.63 (1.061) | **No** |
| Dominant cohort t2 level | 0.994 (0.977 to 1.014) | 0.898 | deviation at most 0.102 + 0.02 | Yes |
| V2 C1 %RMSE | 46.80, d -0.04 | 46.76 | d at or above -0.5 | Yes |
| B1 basal area | 0.25 points | 0.17 | not worse by 1.0 | Yes |
| B2 stems | 24.66 points | 24.23 | not worse by 2.0 | Yes |

Harness reproductions, all before any p38 value was used (`assembled/gyr142-p38-repro_DATA_2026-10-01.csv`): R1, the row
index pass reproduces the PREREG23 height table (120 rows, worst 4.9e-15); R2, the PREREG19 grid, PREREG23 and PREREG28b
stand summaries (worst 4.8e-13); R3, field tag record counts 698 (fold A) and 737 (fold B), equal to PREREG37; R4, r2 stand
rows for p19_a0111 equal the frozen PREREG19 table (397 rows, difference 0); R5, the fit value equals round(R_A, 3).

## What the data show

**Under field tags the anchor response is close to linear and the fit transfers.** The pooled ratio rises from 0.025 at
QC_AFAC 0.030 through 0.093 at 0.111 and 0.846 at 1.000 to 1.059 at 1.250 (fold B), so interpolating between 1.061 (0.898) and 1.250 (1.059) puts the fold B
unbiased anchor near 1.18. The fold A fit 1.242 gives 0.997 in sample and 1.053 held out. Fold B class biases are small at 1.242 and
the 25 cm and over class runs slightly high, consistent with PREREG37's weaker residual size structure (short trees grow
faster, tall trees slower than the height term predicts).

**The stand TOPHT metric and the tag dominant cohort disagree by about 16 points at every anchor.** At 0.111 the tag dominant
cohort is under predicted by 10 percent (level 0.898) while published TOPHT is over predicted by 6.29 percent; at 1.242 the
dominant level is 0.994 while TOPHT is +16.21 percent. The offset holds across all ten arms (`assembled/gyr142-p38-gates-all_DATA_2026-10-01.csv`).
The two measures differ in construction. TOPHT (runner line 208) is the unweighted mean height of the largest trees by DBH up
to 100 stems ha⁻¹ at each end, with `himp` imputed heights where a tree has none, so the t2 set can hold different trees,
recruits and imputed heights; the tag cohort is the same measured survivors at both ends. Which of these carries the offset
is not tested here [UNVERIFIED], but the TOPHT gate is not measuring the quantity the anchor controls. The gate limit is itself an internal arm value (the 1.061 run), an F4 case.
This result does not change the gate; it names the conflict for a separate track.

**Reported comparators.** p28b_small passes every gate under field tags (pooled 0.979, TOPHT +11.97), because 0.111 for large
trees holds TOPHT down; it is not a single value arm, it rests on the row index fit and it failed the PREREG31 Bakuzis grid,
so it is not reopened. p23_a1061 sits just outside the H1 window (0.898, interval 0.793 to 1.035) at the TOPHT limit by
definition. qc_fl (reported, 13 fold B tag trees on 3 sites) gives a pooled ratio of 1.461 for p38_fit with intervals too
wide to read.

![Field tag anchor response](figs/gyr142-p38-fieldtag-anchor_2026-10-01.png)

**Figure 1. QC height anchor on screened qc_c fold B under MAGPlot field tags, 95 percent site cluster intervals (B = 1000).
(a) Predicted over observed pooled annual height increment against QC_AFAC, band 0.90 to 1.10; (b) published TOPHT bias,
dashed line the +14.63 percent limit at 1.061; (c) mean height increment bias by t1 DBH class for qc141, p28b_small, 1.000 and
p38_fit; (d) dominant cohort predicted over observed t2 height, band qc141 deviation plus 0.02. p38_fit in red.** Data
`figs/gyr142-p38-fieldtag-anchor_DATA_2026-10-01.csv`.

## Re-derivation [F9]

An independent agent wrote `verify_20261001/p38_verify.R` (cbfd6423) from the plan alone, without reading the assembly or
its outputs until its own numbers were written (log 706634b6, ends `P38_VERIFY_DONE`). It re-derived the field tag record
counts, pooled ratio, class biases and dominant level for p38_fit, qc141, p28b_small and p23_a1061, TOPHT, C1 %RMSE, BA and
stems ratios for p38_fit, qc141 and p23_a1061, the H0 worst differences, and the verdict. 76 of 76 items agree within 1e-9,
worst 4.6e-14 (`verify_20261001/p38_verify_compare_DATA_2026-10-01.csv`, 447180a9); verdict Rule 4, matching. It did not
re-derive R1, R2, R4, R5 or the bootstrap limits. It noted that the plan's verifier list omitted p23_a1061 and its stands
table; it used `v142p23/tables/gyr142-p23-fb-stands_DATA_2026-09-27.csv`.

## Deviations

1. p38_one ran on the PREREG33 G0 subset only, as written in the plan (a departure from the lost draft's description); its
   full benchmark values are frozen p19_a1000, identical by H0.
2. The session draft of the plan was lost before upload; the rewrite is the registered revision. No output existed before it.
3. No other deviation. No assembly or task was rerun.

## Consequence for 14.2

The QC height increment has an anchor that works on field tags (about 1.2), and the published TOPHT gate rejects it. Before
any QC anchor is carried to a Bakuzis grid, the TOPHT gate needs a diagnosis: whether TOPHT_o and TOPHT_p are built from the
same trees and heights, and what part of the 16 point offset is recruitment, mortality, height imputation or definition.
PREREG39 (Bakuzis QC grid) is not triggered.

## Files

Firebreather `~/jobs/v142p38/`: `plan/`, `fit/`, `home/` (bundle, retry scripts, taskmap), `scripts/`, `diffs/` (8),
`results/`, `tables/`, `assembled/` (gates 63ac801e, gates-all 35e2fbf8, hinc adce6924, hinc-rowidx 5795f5f1, H0 2e86bd41, K1
878a9962, repro 67073ca9, stands-summary 2b800e4f, verdict 81cd37d0), `figs/` (PNG a91ee42e, data 5f6ac8a5), `logs/`,
`verify_20261001/`.

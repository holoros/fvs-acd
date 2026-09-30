# QC height anchor changed for trees below 25 cm only, 0.111 kept for large trees: pre-registration 28b

30 September 2026, revision 1. Written at Aaron's choice (option 2 of the PREREG28 hand back: keep 0.111 for large trees and
change only the small tree anchor) while the PREREG28 chain is still running (30 of 40 tasks done at 14:37 server time) and
before any PREREG28 candidate output has been read. It follows PREREG28 (`~/jobs/v142p28/plan/2026-09-30_v142_qc-anchor-size_PREREG28.md`,
revision 1, md5 c4275a8d) and PREREG23 (revision 1, md5 cbc3cc2a, rule 3). Nothing is fitted. L and T stay at the 14.1
values and are not re-estimated. GT1 stays a named failure. No em dashes.

## Why this arm

PREREG28 fitted, on screened qc_c fold A tag height increment, a two value anchor: QC_AFAC_SMALL 1.265 below 25 cm t1 DBH and
QC_AFAC_LARGE 0.030 at and above. The large tree value is a clamp at the lowest grid arm, because the fitted value (0.0002)
lay below the grid where the response is flat (fold A 25 cm and over bias +0.029 m/yr at 0.030 and +0.040 at 0.111, interval
-0.052 to +0.161 at 0.111). A clamped value that the data cannot distinguish from the shipped 0.111 is a change to 14.1 with
no evidence for it. This arm keeps the shipped 0.111 for large trees and changes only what the tag data identify: the anchor
for trees below 25 cm.

## What was already seen, stated openly

The whole PREREG28 step 1 (`~/jobs/v142p28/fit/`), including its offline "small only 1.265 / 0.111" row on fold A: pooled
ratio 1.040, bias below 12.7 cm -0.087 and 12.7 to 25 cm +0.027 m/yr (identical to the pair), 25 cm and over +0.040 (the
0.111 value), dominant cohort t2 level 1.029 against 0.973 at 0.111 and 1.026 under the pair. That table applies the
multipliers offline to frozen arms and so carries no interaction between classes. Fold A TOPHT by arm (+5.97 percent at
0.111, +14.51 at 1.061) was in view. No PREREG28 engine output for p28_cand, no fold B value of any new arm, and no gate of
PREREG28 was seen. The PREREG28 H0 arm p28_g0 had reproduced frozen p19_a0111 at 0 on its first two chunks.

## Arm and harness

| Arm | What | Sets | Tasks |
|:--|:--|:--|:--|
| p28b_small | QC_AFAC_SMALL 1.265 below 25 cm t1 DBH, QC_AFAC_LARGE 0.111 at and above (QC_AFAC_KNOT 25) | qc_c (19 chunks), qc_fl (1) | 1 to 20 |

Rows are the PREREG28 taskmap rows 21 to 40 (p28_cand) with the column renamed and renumbered 1 to 20, nothing else changed.
Bundle `~/jobs/v142p28b/home`, a copy of `~/jobs/v142p28/home` without its `out*`, `logs`, `tables` and `smoke`
directories; the bundle md5 list is checked against the PREREG28 bundle before launch. **Runner `runner_p28_fb.R` (md5
0a2b2742) unedited.** The driver, launcher, retry and scoring scripts are PREREG28 copies with only the arm case, the job
root and the arm list changed; every diff is recorded in `logs/`. At most 2 tasks at once, none started while the 1 minute
load is above 12. Wall time is not a result.

**H0 is cited, not rerun.** PREREG28's `p28_g0` runs the same runner through the same code path with both values at 0.111 and
is gated there against frozen p19_a0111 at 1e-9. The PREREG28b assembly reads p28_g0 from `~/jobs/v142p28/` after that
chain's scoring has finished and applies the same H0 test; it therefore waits for `score exit 0` in
`~/jobs/v142p28/logs/chain.txt`. If PREREG28 stops before scoring, or its H0 fails, PREREG28b gives no verdict and H0 is
rerun here under a new revision.

**Retry rule, up front.** Every stand whose FAIL_REASON is the host time limit is rerun alone, selected by STAND name
through `STAND_KEEP_FILE` (never by pairs row), up to three attempts. K1 counts failures after retry.

## Gates (screened qc_c fold B), identical to PREREG28

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H0 | PREREG28 p28_g0 against frozen p19_a0111, qc_c and qc_fl | Worst scaled difference at or below 1e-9 | PREREG23, PREREG28 |
| K1 | RUN_OK other than 1, p28b_small, after retry | 0 | PREREG23 K1 |
| H_inc pooled | Pooled annual height increment ratio | Absolute deviation from 1 smaller than at 0.111 | PREREG23 |
| H_inc classes | Mean bias by t1 class (below 12.7, 12.7 to 25, 25 and over) | No class worse in absolute value than at 0.111 by more than 0.03 m/yr | PREREG23 rule 3 |
| TOPHT | Published TOPHT bias; dominant cohort t2 level | TOPHT absolute bias no worse than at 1.061; dominant cohort absolute deviation from 1 no worse than at 0.111 plus 0.02 | PREREG23 margin |
| V2 | C1 %RMSE | d = %RMSE(0.111) minus %RMSE(arm) at or above -0.5 | PREREG23 |
| B1, B2 | Basal area, stems ratio | Absolute deviation from 1 no worse than 0.111 by more than 1.0 and 2.0 points | PREREG23 as coded |

Margins are parsed from the PREREG23 assembly and every reference is read from a file [F9], through the PREREG28 assembly
copied with only the arm names, roots and output names changed. The PREREG28 candidate p28_cand is carried as a reported
comparator (read from `~/jobs/v142p28/`), with every gate computed for it too, labelled reported.

## Decision rule, in order

1. H0 (as cited) or K1 fails: harness failure, no verdict.
2. H_inc pooled fails: not adopted.
3. H_inc classes fails: not adopted, the failing class named. A 25 cm and over failure here means taller small trees suppress
   large tree height growth through the model's competition terms, since the large tree multiplier is unchanged.
4. TOPHT fails: not adopted, the dominant cohort reading named.
5. V2, B1 or B2 fails with the height gates passing: not adopted; the trade off reported.
6. Every gate passes: the small tree only anchor (1.265 below 25 cm, 0.111 at and above) is the 14.2 QC candidate, a regional
   usage setting, not adopted into a release before a Bakuzis QC grid under its own pre-registration.

**Choice between the two arms, fixed now.** If PREREG28 and PREREG28b both reach their rule 6, the 14.2 QC candidate is the
arm with the smaller absolute TOPHT bias on screened qc_c fold B; a difference under 0.5 percentage points goes to PREREG28b,
which leaves 14.1 unchanged for large trees. If only one reaches rule 6, it is the candidate. If neither does, 14.1 keeps
0.111 and the failing gates of both are reported.

**Expectation, stated now.** Pooled and both small classes pass, as in the offline row. The 25 cm and over class sits near the
0.111 value unless interaction moves it; any shift there is interaction by construction. TOPHT is the gate at risk: 54
percent of the fold A dominant cohort is below 25 cm and its offline level rises to 1.029, so TOPHT is expected between the
0.111 value and the PREREG28 pair, roughly +10 to +12 percent against the +14.6 limit.

## Caveats

The small tree value was chosen on fold A in sample by PREREG28 and is reused, not refit. dht.mult is set per tree from t1
DBH and held through the interval, so a tree that crosses 25 cm keeps the small tree anchor; ingrowth recruits enter at 1.
Fold A and fold B share no sites. qc_fl is scored and reported, not gated. The scorer's tables carry its fixed 2026-09-27
stamp.

## Constraints

New directory only (`~/jobs/v142p28b/`). PREREG28 outputs are read, never written. Frozen runs are not rerun. No
coordinates. Nothing is sent outside.

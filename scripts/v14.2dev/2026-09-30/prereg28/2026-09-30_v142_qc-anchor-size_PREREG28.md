# A size dependent QC height anchor: pre-registration 28

30 September 2026, revision 1. Written after the fold A fit and before any PREREG28 engine output on the full benchmark is
read. It follows PREREG23 (revision 1 md5 cbc3cc2a, closed on rule 3) and PREREG19. L and T stay at the 14.1 values and are
not re-estimated. GT1 stays a named failure. No coordinates are read or written. No em dashes.

## Why

PREREG23 refit the flat QC anchor (QC_AFAC, the dht.mult every QC tree carries) on tag height increment. The candidate
1.061 improved the pooled fold B ratio (0.828 against 0.086 at 0.111) but failed rule 3: trees 25 cm and over moved from
-0.021 to +0.099 m/yr, worse by 0.077 against the 0.03 threshold. Rule 3 named the route taken here: one multiplier does
not serve every size, so the anchor is allowed to depend on t1 DBH.

## Step 1, fold A only (done, files in `fit/`)

Screened qc_c fold A (153 stands, 147 sites; 264 tag matched survivors with measured height at both ends on 103 sites, 76 in
the t1 dominant cohort). Eight frozen arms (p19_a0030 to p19_a1000, p23_a1061, p23_a1250). Per class zero bias anchors
(linear in log QC_AFAC, site cluster bootstrap B = 1,000, seed 20260930): below 12.7 cm 2.06 [1.50, 2.90] (beyond the grid),
12.7 to 25 cm 1.10 [0.80, 1.38], 25 cm and over no zero inside the grid (bias +0.029 at 0.030 and +0.040 at 0.111; the
interval reaches 0.495). In 5 cm classes the zero falls from 1.97 (below 10) through 1.69, 1.37 and 0.62 (20 to 25) to
none inside the grid from 25 cm up, so the break sits at 20 to 25 cm.

Forms tried (fold A, in sample, by per tree interpolation of predicted height on log QC_AFAC across the eight arms): step
at knots 20, 25 and 30, and a log linear taper log a = c0 + c1 (D1 - 25). Knot 20 and knot 25 fit about equally (RMS 5 cm
class bias 0.062 and 0.063 m/yr, largest 0.11 and 0.10); knot 30 is worse (0.105, 0.22); the taper is unusable (RMS 0.19,
c0 near -5, interval of c0 from -18 to -0.4). **Knot 25 is kept** because it ties with 20 on fit, it is the prior named in the
brief, it matches the PREREG20 NS knot, and it is a class boundary of the gate that failed; moving it to 20 on fold A
evidence that does not separate the two is fitting noise. **a_small = 1.265** [1.007, 1.586], the zero of pooled fold A
bias for trees below 25 cm (a 1 percent extension of the 1.061 to 1.250 segment). **a_large = 0.030**, the lowest grid arm:
the fitted zero for 25 cm and over lies below the grid (point 0.0002), which is not evidence, and the response is flat
there (0.011 m/yr from 0.030 to 0.111), so the value is clamped at the lowest supported arm rather than extrapolated.

In sample reading of the pair (fold A): pooled bias +0.005 m/yr (ratio 1.03), below 12.7 -0.087, 12.7 to 25 +0.027, 25 and
over +0.029 (0.111: -0.261, -0.156, +0.040); dominant cohort t2 level 1.026 [0.984, 1.073] against 0.973 at 0.111 and 1.048
at 1.061. Of the dominant cohort, 54 percent are below 25 cm at t1, so the pair raises the cohort. Fold A TOPHT bias is +5.24
percent at 0.030, +5.97 at 0.111 and +14.51 at 1.061; placing the pair by its dominant cohort level between the 0.111 and
1.061 arms gives about +12 percent, so TOPHT is expected to rise but stay under the 1.061 value.

**Known approximation.** dht.mult is set per tree at initialisation from t1 DBH and held through the interval; a tree that
crosses 25 cm keeps the small anchor, and ingrowth recruits enter with dht.mult NA, which `bf()` sets to 1. The fit also
assumes each tree's height increment depends on its own anchor only; interaction through crowns and competition is what the
engine run measures.

## What was already seen, stated openly

All PREREG23 fold B gate values, as in the brief. The assembly dry run (`dryrun/`, 07:59 server time, after the pair was
fixed in `scripts/run_task_p28.sh` at 07:51) stood p28_g0 in with p19_a0111 and p28_cand with p23_a1061 and so printed the
frozen PREREG23 fold B values again, including the dominant cohort level (0.922 at 0.111, 1.008 at 1.061), TOPHT (+6.29 and
+14.63 percent) and V2, B1, B2 at both. It reproduced the PREREG23 verdict (rule 3, 25 cm and over worse by 0.077). No fold
B value under the pair has been seen.

## Arms and harness

| Column | QC dht.mult | Sets | Tasks |
|:--|:--|:--|:--|
| p28_g0 | 0.111 below and at and above 25 cm, through the new code path | qc_c (19 chunks), qc_fl (1) | 1 to 20 |
| p28_cand | 1.265 below 25 cm t1 DBH, 0.030 at and above | qc_c, qc_fl | 21 to 40 |

Rows are the PREREG23 taskmap rows for p23_a0111 with the column renamed (20 per arm; the brief said 21 chunks, the PREREG23
taskmap has 19 qc_c chunks covering 378 stands plus 1 qc_fl chunk of 19). Bundle `~/jobs/v142p28/home`, a copy of the
PREREG23 bundle (46 model, coefficient and frame files md5 identical). **Runner** `runner_p28_fb.R` (md5 0a2b2742) is the
PREREG23 runner `runner_htfix_fb.R` (md5 4e6a2997; the brief calls it runner_p20_fb.R) with only line 425 changed: when any of
`QC_AFAC_SMALL`, `QC_AFAC_LARGE`, `QC_AFAC_KNOT` is set all three are required and QC trees get SMALL below KNOT and LARGE at
and above; when none is set the line returns QC_AFAC exactly (diff in `logs/runner_p28_vs_htfix.diff`). Smoke on five qc_c
stands (`logs/smoke_check.txt`): p28_g0 and the unset fallback reproduce frozen p19_a0111 results and per tree t2 lists at 0;
p28_cand runs and moves heights. At most 2 tasks at once, none started while the 1 minute load is above 12. Wall time is not a
result.

**Retry rule, up front.** Every stand whose FAIL_REASON is the host time limit is rerun alone, selected by STAND name through
`STAND_KEEP_FILE` (never by pairs row), up to three attempts; the driver checks the stand returned and renames otherwise. K1
counts failures after retry.

## Gates (screened qc_c fold B)

| Gate | Test | Threshold | Provenance |
|:--|:--|:--|:--|
| H0 | p28_g0 against frozen p19_a0111, every _p column, ING_p, RUN_OK and per tree ht, dbh, expf, ing, qc_c and qc_fl | Worst scaled difference at or below 1e-9 on every stand | PREREG23 H0 |
| K1 | RUN_OK other than 1, p28_cand, after retry | 0 | PREREG23 K1 |
| H_inc pooled | Pooled annual height increment ratio | Absolute deviation from 1 smaller than at 0.111 | PREREG23 |
| H_inc classes | Mean bias by t1 class (below 12.7, 12.7 to 25, 25 and over) | No class worse in absolute value than at 0.111 by more than 0.03 m/yr | PREREG23 rule 3 |
| TOPHT | Published TOPHT bias; dominant cohort t2 level | TOPHT absolute bias no worse than at 1.061, and dominant cohort absolute deviation from 1 no worse than at 0.111 plus 0.02 | PREREG23 margin |
| V2 | C1 %RMSE | d = %RMSE(0.111) minus %RMSE(pair) at or above -0.5 | PREREG23 |
| B1, B2 | Basal area, stems ratio | Absolute deviation from 1 no worse than 0.111 by more than 1.0 and 2.0 points | PREREG23 as coded |

References are read, never typed [F9]: the margins are parsed from the PREREG23 assembly (md5 429f441e); the assembly
first reproduces the PREREG19 grid and PREREG23 stands summary for the frozen arms (worst 4.6e-13 in the dry run) and the
PREREG23 height table, points and intervals (seed 20260929, worst 4.9e-15), and checks each reference class bias against the
PREREG23 class gate file, stopping on any mismatch. Scorer `2026-09-27_v142_volconv_score.R` (md5 019df238), copied unedited.

## Decision rule, in order

1. H0 or K1 fails: harness failure, no verdict; repaired under a new revision.
2. H_inc pooled fails: the fold A pair does not transfer; not adopted.
3. H_inc classes fails: not adopted, the failing class named.
4. TOPHT fails: not adopted, the dominant cohort reading named.
5. V2, B1 or B2 fails with the height gates passing: not adopted; the trade off reported.
6. Every gate passes: the size dependent anchor (1.265 below 25 cm, 0.030 at and above) is the 14.2 QC candidate, a regional
   usage setting, not adopted into a release before a Bakuzis QC grid under its own pre-registration.

Where several gates fail, the first applicable rule is the outcome and every failing gate is reported.

**Expectation, stated now.** Pooled and small class gates pass (1.061 already passed them). The 25 cm and over class is
expected to pass because its anchor falls rather than rises; the risk is interaction, taller small trees suppressing large
tree growth. TOPHT is the gate at risk, expected near +12 percent against +14.6 at 1.061.

## Caveats

Fold A holds 264 tag trees, 42 of them 25 cm and over; the large tree anchor is weakly identified and clamped. The pair was
chosen on fold A in sample. qc_fl is scored and reported, not gated. The scorer's tables carry its fixed 2026-09-27 stamp.

## Constraints

New directories only (`~/jobs/v142p28/`). Frozen runs are read, not rerun. No coordinates. L and T not re-estimated. Nothing
is sent outside; the laptop, GitHub and Zenodo are not touched.

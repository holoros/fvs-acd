# QC height anchor refit on tag height increment (QC_AFAC 1.061): PREREG23 result

29 September 2026. Pre-registration: PREREG23 (revision 1, md5 cbc3cc2a; file name to be confirmed from the `p23/`
folder, deviation 1; this RESULT's own name follows the track), recorded
in `~/jobs/v142p23/logs/prereg_md5.txt` before the chain launched at 08:03 server time). Three arms ran in
`~/jobs/v142p23/` on the 21 benchmark QC chunks each (60 tasks): `p23_a0111` (the shipped 0.111, harness control),
`p23_a1061` (the candidate, fitted on fold A tag height increment) and `p23_a1250` (bracket). Chain `chain_p23.sh`,
CHAIN_DONE 09:30 server time; scored by `2026-09-27_v142_volconv_score.R` (019df238, copied) with the PREREG19 harness
(`run_score_p23_vs_p19.diff`, `p23_vs_p19_harness.diff` record the only differences), height increment by
`2026-09-29_v142_p23_hkey.R` and `_fit.R`, assembled by `2026-09-29_v142_p23_assemble.R`. Base v141LT. L and T
unchanged; GT1 stays a named failure. No em dashes.

## Verdict

**Not adopted. Rule 3 applies: a diameter class is worse by more than 0.03 m per year.** H0 and K1 pass and the pooled
tag height increment gate passes, but the 25 cm and over class moves from -0.021 to +0.099 m per year (worse by
+0.077), so one multiplier does not serve every size. The route named by rule 3 is a size dependent QC anchor, under its
own pre-registration. 14.1 stays at 0.111.

| Gate (screened qc_c fold B unless stated) | Result at 1.061 against 0.111 | Pass |
|:--|:--|:--:|
| H0 harness | `p23_a0111` against frozen `p19_a0111`: qc_c results and trees 0.00e+00 on 378 stands, qc_fl 0.00e+00 on 19 | Yes |
| K1 failures | RUN_OK other than 1 after retries: qc_c 0, qc_fl 0 (all three arms) | Yes |
| H_inc pooled | fold B ratio 0.828 against 0.086 (abs deviation from 1: 0.172 against 0.914); 301 trees on 108 sites | Yes |
| H_inc classes | below 12.7: bias -0.115 against -0.254 (better by 0.140); 12.7 to 25: -0.020 against -0.161 (better by 0.141); 25 and over: +0.099 against -0.021 (worse by 0.077) | No |
| TOPHT reading | published TOPHT bias +14.63 against +6.29 percent (worse); dominant cohort t2 level 1.008 against 0.922 (within margin) | Yes (reported) |
| V2 %RMSE | fold B C1 %RMSE 46.79 against 46.76, d -0.04 | Yes |
| B1 basal area | fold B abs(BA ratio minus 1) 0.19 against 0.17 points | Yes |
| B2 stems | fold B abs(stems ratio minus 1) 24.59 against 24.23 points | Yes |

## What the increment grid shows

On fold A (264 tagged trees, 103 sites) the pooled ratio of predicted to observed annual height increment runs from 0.028
at QC_AFAC 0.030 to 0.942 at 1.000 and reaches 1.000 at 1.061, which is where the fold A fit put the candidate. Fold B
tracks fold A about 0.1 lower at the top of the grid (0.828 at 1.061, 0.98 at 1.250). The shipped 0.111 predicts about a
tenth of the observed height increment on tagged survivors in both folds: -0.145 m per year bias on fold A, -0.170 on
fold B.

The class pattern is the finding. Trees below 25 cm are under predicted at 0.111 by 0.16 to 0.25 m per year and the
candidate brings them to within 0.02 to 0.12 of zero. Trees at 25 cm and over have near zero observed increment on these
plots (-0.025 m per year on fold A, 41 to 42 trees per fold) and any anchor above about 0.25 over predicts them; at 1.061
the bias is +0.099 on fold B and +0.169 on fold A, with intervals that exclude zero. The dominant cohort sits between
(fold B t2 height level 1.008). The same lever that closes the small and mid tree deficit opens a large tree excess, which
is what rule 3 was written to catch.

![Tag height increment against QC_AFAC, pooled and by class, fold A and fold B](assembled/gyr142-p23-hinc_2026-09-29.png)

**Figure 1.** Pooled ratio and class biases of predicted against observed annual height increment on screened qc_c,
fold A (fit) and fold B (held out), against QC_AFAC on a log scale, with 95 percent site cluster intervals. Dotted lines
mark 0.111 and 1.061. The three points at the right are 1.000, 1.061 and 1.250; their x labels overlap.

Stand level, screened qc_c fold B (160 stands): the candidate leaves C1 volume (1.1216 against 1.1146), basal area
(1.002 against 0.998), stems (0.754 against 0.758) and %RMSE within a point of the shipped anchor, as PREREG19 found
across its whole grid, and lifts TOPHT bias from +6.3 to +14.6 percent. The two height diagnostics that PREREG19 said
disagreed (tag increment near 1.2, top height already tall at 0.111) are now on one footing: they are different trees.
Tagged survivors below 25 cm grow faster than the model says; the dominant cohort and the largest tagged trees do not.

## Re-derivation [F9]

`verify/p23_rederive_rev2.R` (its own fold code from md5(SITE), its own tag key match, its own hardwood split grouping;
no code shared with the height key or assembly scripts) rebuilt the fold B increment table for `p19_a0111`,
`p23_a1061` and the `p23_a0111` rerun. Pooled ratios (0.0855 and 0.8280), the three class biases (-0.2545, -0.1605,
-0.0213 against -0.1148, -0.0195, +0.0987), the dominant cohort levels (0.9215 against 1.0083) and the stand level C1,
%RMSE, basal area, stems and TOPHT (1.11456, 46.7556, 0.99833, 0.75774, 6.289 against 1.12158, 46.7950, 1.00194,
0.75411, 14.625) agree with `assembled/` to the printed precision; the `p23_a0111` rerun reproduces `p19_a0111` exactly.
Revision 1 of the script halted before its stand block on a data.table `..arm` prefix in an i clause; revision 2 renames
the argument and changes nothing else (`verify/rev2_vs_rev1.diff`).

## Deviations

1. **Pre-registration text not checked line by line this session.** The PREREG23 file lives in the previous session's
   `p23/` folder, which did not reach the laptop; firebreather holds only its md5 (cbc3cc2a). The gates above are the
   gates as coded in the assembly and the rule as written in `verdict`. When the file is copied in, its md5 is checked
   against the log entry and the gate list here against its text; any difference is recorded as a revision of this RESULT.
2. **Retry by name armed, no stand time limited.** All three arms report `RETRY_DONE remaining: 0` and K1 0.
3. **Re-derivation script revised once** (above), a repair of the check, not of any result.
4. **Chain launched by the previous session** at 08:03 server time and finished unattended; this session found it at
   CHAIN_DONE and did not relaunch anything.
5. **Figure x labels overlap** at 1.000, 1.061 and 1.250 (log axis). Not regenerated; the values are in the tables.
6. **Table date stamps.** The scorer tables carry `2026-09-27`; C2 tables in `tables_c2/` are reported for provenance
   only, since PREREG19 revision 2 withdraws row aligned C2.

## Files

`p23/assembled/` beside this file (class gate, gates, H0, K1, increment grid, stand summary, verdict, Figure 1;
firebreather `~/jobs/v142p23/assembled/`, all eight files md5 verified on the laptop). Re-derivation scripts, diff, log
and tables in `~/jobs/v142p23/verify/`. Scripts go to GitHub under `scripts/v14.2dev/2026-09-29/prereg23/` on
`v142-refinement-20260926`.

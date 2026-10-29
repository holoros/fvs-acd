# NS ingrowth multiplier refined between 1.5 and 2.25 on a held out volume criterion: PREREG18 result

28 September 2026 content, chain finished 29 September 09:09 server time on firebreather, read out 29 September.
Pre-registration: `2026-09-28_v142_ns-imult-refine_PREREG18.md` (revision 1, md5 c78b477c). Two new arms (IMULT 1.75 and
2.25) ran in `~/jobs/v142p18/` on the 36 bench141 NS chunks each (72 tasks, driver `run_task_p18.sh`, chain `chain_p18.sh`);
1.5 and 2.0 were read frozen from Cardinal, v141LT from PREREG16 `tables_r1`. Scored by `2026-09-27_v142_volconv_score.R`
(019df238, copied, not edited), fold volume by `2026-09-28_v142_p18_foldvol.R`, assembled by
`2026-09-28_v142_p18_assemble.R` into `assembled/`. Base v141LT. L and T unchanged; GT1 stays a named failure. No em dashes.

## Verdict

**Not adopted. Rule 2a applies: m* = 1.5, the lower edge of the grid.** K1 passes (rule 1 does not stop the run), Edge
fails, and rule 2 precedes every other rule. The held out consecutive volume criterion asks for no more ingrowth than 1.5,
exactly as the pre-registration's stated expectation predicted from the PREREG17 all stands values. A flat NS multiplier
cannot be placed inside the window that the long frame gates accept from consecutive held out data. The next step named
in rule 2a is an interval length dependent term (ingrowth or survival over long intervals), not another flat scalar.
14.1 is unchanged; Maine stays at 1.0.

| Gate | Result at m* = 1.5 | Pass |
|:--|:--|:--:|
| K1 failures | 0 RUN_OK other than 1 in 17,918 NS stands | Yes |
| S1 stems (held out) | ns_c fold B 0.959 against 0.912; ns_long_c 0.954 against 0.910; ns_fl 0.909 against 0.841; ns_long_fl 0.875 against 0.866 (v141LT) | Yes |
| E3 (C1) | ns_c %RMSE 23.83 against 23.68, d_rmse -0.16; ns_long_c 23.18 against 22.92, d_rmse -0.26 | Yes |
| E6b (C1) | ns_fl bias +0.24 against -2.28; ns_long_fl -2.00 against -4.49 | Yes |
| Edge | m* = 1.5 on {1.5, 1.75, 2.0, 2.25} | No |
| VB volume (held out, ns_c fold B) | ratio 1.0074 (0.9969 to 1.0179) contains 1; fold B %RMSE 24.31 against 24.18, d_rmse -0.13 | Yes |

Every gate other than Edge passes at 1.5, which is reported and not read beyond its own test: the design does not permit
an edge value to be adopted, and the pre-registration said in advance that an Edge failure at 1.5 would be the
informative outcome.

## Selection (ns_c fold A, 2,771 stands)

| IMULT | C1 ratio, fold A | Loss (gated) | Loss, fold B | Loss, ns_long_c | BA loss, fold A | Stems loss, fold A |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **1.5** | **1.0050** | **0.00494** | 0.00740 | 0.00109 | 0.0133 | 0.0358 |
| 1.75 | 1.0068 | 0.00673 | 0.00912 | 0.00111 | 0.0094 | 0.0248 |
| 2.0 | 1.0085 | 0.00851 | 0.01086 | 0.00326 | 0.0056 | 0.0139 |
| 2.25 | 1.0104 | 0.01031 | 0.01256 | 0.0054 | 0.0018 | 0.0033 |

No tie: the two smallest losses differ by 0.0018, above the 0.0005 rule. The volume loss is monotone on fold A, on fold B
and on ns_long_c (where 1.5 and 1.75 are within 0.00002 of each other), so the criterion points to the lower edge on any
grid that starts above 1.0. The two alternatives the pre-registration set aside, basal area and stems, both choose 2.25,
the upper edge, as predicted. The between frame tension stated up front is real and is not a grid artifact.

![Stems and C1 volume ratios against IMULT on the six NS populations](p18_assembled/gyr142-p18-grid_2026-09-28.png)

**Figure 1.** Pooled predicted over observed stems (blue) and C1 volume (red) against IMULT, with 95 percent site
cluster intervals for volume. Filled points are the PREREG18 grid, open points the PREREG17 context (1.0, 2.5, 3.0), the
shaded band the grid, the dashed line m*, and dotted lines v141LT. Volume crosses 1 below 1.5 on every consecutive frame
while stems cross 1 near 2.5.

## What the grid shows

C1 volume on ns_c is above 1 at every grid value and rises 0.18 points per 0.25 step; stems rise 1.0 to 1.1 points per
step and reach 1 only at 2.5. Basal area sits between them. The all stands C1 values (1.0062, 1.0080, 1.0098, 1.0116) match
the PREREG17 table to the fourth decimal for 1.5 and 2.0, which is the G0 licence for mixing the Cardinal and firebreather
arms holding at full scale. TOPHT bias on ns_c is flat at +1.45 percent across the grid, so ingrowth does not touch the
height diagnostics.

Reported, not gated, for the other grid values (`gyr142-p18-gridgates`): 1.75 also passes every gate except Edge; 2.0
fails VB because its fold B interval (1.0004 to 1.0215) excludes 1; 2.25 fails VB and E3 (ns_long_c d_rmse -0.52). So the
held out consecutive volume gate would have rejected any interior point at 2.0 or above even under a different selection
rule, and E6b's long frame biases change sign inside the grid (ns_long_fl -2.00 at 1.5, +0.43 at 2.25; ns_fl +0.24 to
+1.93). The window in which the consecutive frames and the long frames both accept a flat multiplier is at most 1.5 to
1.75 on these data, and the consecutive criterion sits at or below its lower end.

## Re-derivation [F9]

`verify_20260929/p18_rederive.R` (base R, no code shared with the scorer, fold volume or assembly scripts) rebuilt the
per stand C1 volumes for every arm from the Cardinal and firebreather stand tables, recomputed the fold from md5(SITE),
the four fold A losses, the tie test, m*, the fold B ratio and its 1,000 draw site cluster interval, fold B %RMSE, E3 and
E6b, and compared 17 quantities with `assembled/`. Fifteen agree within 1e-9; the two E6b biases differ by 1.4e-8 and
2.6e-9 percentage points because the per stand tables are printed to six decimals. Revision 2 of the script sets the
tolerance to 1e-6 for that reason (diff in `rev2_vs_rev1.diff`) and reports REDERIVE_PASS. m* = 1.5, no tie, rule 2.

## Deviations

1. **Retry by name armed, no stand time limited.** The chain ran the by name retry for both new arms after ALL_DONE
   (`RETRY_DONE remaining: 0` for each) and K1 records 0 RUN_OK other than 1 on every NS set for both arms, so no stand
   was rerun. The section 8 rule did not fire.
2. **Verify script revised once** (tolerance 1e-9 to 1e-6, above), a repair of the check, not of any result.
3. **Table date stamps.** The scorer and fold volume tables carry the 2026-09-28 stamp of the pre-registration day;
   the chain finished on 29 September. Names were not changed.
4. **PREREG22 read the verdict automatically.** The PREREG22 chain, launched 29 September 07:58 server time, waited on
   PREREG18 CHAIN_DONE, read `assembled/gyr142-p18-verdict` (md5 dd59123b) and wrote `mstar.env` with P22_IMULT 1.5 and
   Rule 2a at 09:13, before this RESULT existed. That is the PREREG22 design; this RESULT changes nothing it read.
5. **Host.** Firebreather ran the PREREG18 grid beside the PREREG19, PREREG20 and PREREG23 chains at load 12 to 16 on 8
   cores. Wall time (about 13.5 h from chain start to CHAIN_DONE) is not a result.
6. **Read out a day late.** The chain finished 09:09 server time and the RESULT was written the same afternoon; nothing
   in `~/jobs/v142p18/` was touched between the two except the new `verify_20260929/` directory.

## Files

`p18_assembled/` beside this file (gates, gate detail, grid, grid gates, selection, verdict, Figure 1; firebreather
`~/jobs/v142p18/assembled/`, all seven files md5 verified on the laptop). The re-derivation scripts, both revisions, their
log, diff and tables are in `~/jobs/v142p18/verify_20260929/`. Scripts go to GitHub under
`scripts/v14.2dev/2026-09-28/prereg18/` on `v142-refinement-20260926`.

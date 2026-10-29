# NS ingrowth multiplier under threshold matching, scored under C1: PREREG17 result

27 September 2026 content, assembled 28 September. Pre-registration: `2026-09-27_v142_ns-ingrowth-multiplier-C1_PREREG17.md`
(revision 2, md5 b9dbd707). Arms IMULT 1.0 to 2.5 are the frozen Cardinal runs (arrays 14922031 and 14921116), scored under
C1 by Cardinal job 14938375 into `recs/p17/`. IMULT 3.0 ran on firebreather in `~/jobs/v142p17/` and was scored there by
the same scorer (`2026-09-27_v142_volconv_score.R`, md5 019df238). The v141LT references are read from PREREG16 `tables_r1`
(scores table md5 a3ed3b76), never typed in. Assembly: `2026-09-27_v142_p17_assemble_r2.R` into `assembled_r2/`. L and T
unchanged; GT1 stays a named failure. No em dashes.

## Verdict

**Not adopted. Rule 5 applies by the pre-registered order, but its written reading does not fit.** G0, K1, S1 and Edge
pass; E3 and E6b fail. The selection rule chose m* = 2.5, which is interior. 14.1 is unchanged.

| Gate | Result | Pass |
|:--|:--|:--:|
| G0 harness | Worst scaled difference 6.27e-15 over 150 stands (SAWVOL_s_p), after the revision 2 retry | Yes |
| K1 failures | 0 RUN_OK other than 1 in 17,918 NS stands at m* | Yes |
| S1 stems, held out | ns_c fold B 0.912 to 1.000; ns_long_c 0.910 to 1.002; ns_fl 0.841 to 1.001; ns_long_fl 0.866 to 0.982 | Yes |
| E3 (C1) | ns_c %RMSE 23.68 to 24.00, d_rmse -0.33; ns_long_c 22.92 to 23.53, d_rmse -0.61 | No |
| E6b (C1) | ns_fl bias -2.28 to +2.46 percent; ns_long_fl -4.49 to +1.16 percent | No |
| Edge | m* = 2.5 on {1.0, 1.5, 2.0, 2.5, 3.0} | Yes |

## Why rule 5's reading does not fit

Rule 5 was written for one pattern: stems restored while the long frame volume deficit stays, which would point at survivor
diameter growth. That is not what happened. On ns_long_fl, C1 volume rises monotonically with IMULT and the deficit closes
(bias -4.49 under 14.1, -0.35 at 2.0, +1.16 at 2.5). The E6b failure is on ns_fl and is an overshoot of the same size as
the 14.1 deficit with the opposite sign (-2.28 to +2.46). So the long frame volume deficit is carried by stems, and the rule
5 diagnosis ("next suspect: survivor diameter growth") is not supported by these data. The consequence of rule 5, not
adopted, stands on its own: E6b fails as written, and E3 fails independently on ns_long_c, by 0.11 beyond the -0.5
threshold. Rule 6 does not apply because E6b also fails.

The selection criterion and the volume gates disagree about the target. At stem balance (2.5), basal area is on target but
QMD runs 2 to 3 percent low, and C1 volume sits 1 to 2.5 percent high on every NS set. Stems ratio at 1 is not the volume
optimum.

## Selection (ns_c fold A, 2,771 stands, 1,287 sites)

| IMULT | Stems ratio | Loss, fold A | Loss, ns_c fold B | Loss, ns_long_c | Maine loss (control) |
|:--:|:--:|:--:|:--:|:--:|:--:|
| 1.0 | 0.943 | 0.058 | 0.064 | 0.073 | 0.037 |
| 1.5 | 0.965 | 0.036 | 0.042 | 0.047 | 0.046 |
| 2.0 | 0.986 | 0.014 | 0.021 | 0.022 | 0.066 |
| **2.5** | **1.007** | **0.007** | **0.000** | **0.002** | 0.087 |
| 3.0 | 1.028 | 0.027 | 0.020 | 0.024 | not run |

The minimum does not move between fold A, fold B and the long frame. Loss is the absolute log of the pooled stems ratio.

## Grid, NS four (predicted over observed; C1 bias in percent)

| Set | 14.1 stems / C1 bias | 1.0 | 1.5 | 2.0 | 2.5 | 3.0 |
|:--|:--:|:--:|:--:|:--:|:--:|:--:|
| ns_c | 0.915 / -0.37 | 0.941 / +0.26 | 0.962 / +0.62 | 0.983 / +0.98 | 1.003 / +1.33 | 1.024 / +1.67 |
| ns_fl | 0.841 / -2.28 | 0.858 / -0.96 | 0.909 / +0.24 | 0.957 / +1.38 | 1.001 / +2.46 | 1.042 / +3.51 |
| ns_long_c | 0.910 / -1.26 | 0.930 / -0.56 | 0.954 / -0.11 | 0.978 / +0.33 | 1.002 / +0.75 | 1.025 / +1.17 |
| ns_long_fl | 0.866 / -4.49 | 0.812 / -3.79 | 0.875 / -2.00 | 0.932 / -0.35 | 0.982 / +1.16 | 1.028 / +2.59 |

TOPHT bias does not move with IMULT (ns_c 1.45 to 1.46 percent, ns_long_fl 5.47 under 14.1 and 5.71 to 5.74 on the grid),
as expected, since height is scored separately under PREREG16. Under C0 the same arm reads ns_long_fl +9.9 percent at 2.5
against +1.2 under C1: the height carry PREREG16 removed.

![Stems and C1 volume ratio against IMULT on the NS four; dotted lines are 14.1, dashed line is m*](p17_assembled/gyr142-p17-grid_2026-09-27.png)

**Figure 1.** Pooled stems ratio and C1 total volume ratio (95 percent site cluster interval) against the ingrowth
multiplier, NS four. Dotted lines mark 14.1 (v141LT); the dashed line marks m* = 2.5.

## Controls (reported, not gated)

**Maine.** The Maine loss rises monotonically from 1.0 (0.037) to 2.5 (0.087), reproducing PREREG10. NS wants 2.5 by the
same criterion. One flat multiplier cannot serve both, so any NS value would be a regional usage setting, as the NB and QC
anchors are. Maine C1 volume barely moves across the grid (memat_c -4.14 to -4.06, medev_c -4.47 to -3.98, pef_c -1.66 to
-1.17, ctrn_c -2.27 to -2.18, baxter_c +11.6 to +11.8 percent); mefia_l_c improves most (-12.5 to -10.7).

**QC.** Stems rise from 0.909 (1.0) to 1.057 (2.5) against 0.802 under 14.1, while screened C1 volume worsens from 1.132 to
1.185 against 1.088. More ingrowth makes QC volume worse; the QC problem is the volume anchor, not stems.

## Post hoc observation (not a result)

Applying the same gates to every interior grid point after seeing the held out output: IMULT 1.5 and 2.0 both pass every
gate; 2.5 fails.

| IMULT | S1 | d_rmse ns_c / ns_long_c | E3 | C1 bias ns_fl / ns_long_fl | E6b | All |
|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| 1.5 | Pass | -0.16 / -0.26 | Pass | +0.24 / -2.00 | Pass | Pass |
| 2.0 | Pass | -0.23 / -0.43 | Pass | +1.38 / -0.35 | Pass | Pass |
| 2.5 | Pass | -0.33 / -0.61 | Fail | +2.46 / +1.16 | Fail | Fail |

The handoff named only 2.0 as passing [F9: re-derived here, 1.5 also passes]. Neither can be adopted: both were found by
looking at the gated sets, and the pre-registered criterion puts the optimum at 2.5. A new pre-registration with a
criterion fitted on held out data and a volume or basal area target, rather than stems alone, is the honest route.

## Deviations

1. **Revision 2 retries.** G0 as first read failed (worst scaled Inf on BA_p) because one stand hit the runner's 60 s
   elapsed limit on firebreather and ran normally on Cardinal. Revision 2 (written after the first G0 read and after the
   ns_c part of the 3.0 arm; harness only) reruns time limited stands alone, up to three attempts. G0 retried 1 stand; the
   3.0 arm retried 3 (one ns_fl, two ns_long_fl). All cleared on attempt 1, and G0 then matched Cardinal to 6.27e-15, which
   also shows a stand run alone reproduces the stand run in its chunk.
2. **BADROW failed repair [F8].** The first retry script located stands by their line in the pairs file and passed that
   number as CHUNK_FROM = CHUNK_TO. For G0 row 668 the runner ran a different stand (the 1965 to 1980 measurement pair of
   the neighbouring plot, not the 1965 to 2005 pair that timed out), because the runner's row index is not the pairs file
   line order. The output was set aside in `out_retry_a1_BADROW/` and not used. The revision 2 retry selects stands by name
   (`retry_timeouts_p17_rev2.sh`). Do not retry by row number.
3. **Host load.** Firebreather ran at a load near 16 on 8 cores through the 3.0 arm because another session shared it. Wall
   time is not a result.
4. **Assembly r2.** The first assembly (`..._p17_assemble.R`, md5 5bd0b478) dropped the 3.0 row from the written selection
   table through an inner merge with the Maine loss, which has no 3.0 value, and labelled the figure axis with arm names.
   m* and every gate were computed before that merge. r2 keeps all grid rows, fixes the axis, and adds the post hoc table.
   Gates, gate detail, grid table and verdict files are byte identical between the two assemblies.
5. **Stand counts.** K1 counts 8,549 ns_long_c stands; the scorer scores 8,548 in every arm including v141LT, the same
   admission as PREREG16.

## Files

`p17_assembled/` beside this file: selection, gates, gate detail, grid, post hoc grid gates, verdict and Figure 1
(firebreather `~/jobs/v142p17/assembled_r2/`). Scripts are on GitHub under `scripts/v14.2dev/2026-09-27/prereg17/` on
`v142-refinement-20260926`.

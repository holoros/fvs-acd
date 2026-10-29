# Empty observed t2 stands in nb_c and three other sets: PREREG32 result

30 September 2026. Pre-registration `plan/2026-09-30_v142_nb-empty-t2-audit_PREREG32.md` (revision 1, md5 3ca53a09,
recorded 20:21 server time before any rescoring, `logs/prereg_md5.txt`). Scorer `2026-09-27_v142_volconv_score.R` (md5
019df238) read, not run. Inputs: PREREG16 stands table (d600f398) and `tables_r1` scores (a3ed3b76); v141LT nb_c results
(97ac93f0); v141LTf ns_long_c results (e475736f); nb_c site index (eef09653); nbctl_a1000 (59176541); GYDB (c028a0ea, the
md5 the FINAL frame builder expects); magp_qcnb pairs (cc32c800) and t2 trees (648d2062). Scripts: audit (dbed7b4f),
audit2 (161a1b99), audit3 (809538c5), rescore revision 3 (56bed04b), exploratory (ad3a5812), figure (3499384c). No
coordinate column was read.

## Verdict

**All 38 empty t2 stands are class R: plots remeasured with live stems, every one below the 5 cm scoring floor.** None is
harvested, lost or a frame defect. **Excluding them (A1) is material for nb_c and for no other set**; A2 (exclude H or L)
equals A0 because no stand is H or L. Under the decision rule an admission rule is proposed for 14.2 below; no verdict is
changed.

| Set | Empty t2 | D | H | L | R | U |
|:--|--:|--:|--:|--:|--:|--:|
| nb_c | 33 of 355 | 0 | 0 | 0 | 33 | 0 |
| medev_c | 2 of 1760 | 0 | 0 | 0 | 2 | 0 |
| mefia_l_c | 2 of 918 | 0 | 0 | 0 | 2 | 0 |
| ns_long_c | 1 of 8549 | 0 | 0 | 0 | 1 | 0 |

## What the audit shows

**nb_c.** The 33 t2 visits exist in GYDB with 537 tree records, all live (status 1), all in the 50 m2 microplot (frame 3,
EXPF 200 ha-1), DBH 1.0 to 4.9 cm, 3 to 57 stems per plot. The bench frame and the old magp_qcnb t2 list hold the same 537
rows, so nothing was dropped by a join, status filter or identity mismatch. At the 5 cm floor, observed volume, BA and stems
are truly zero. At t1, 24 of 33 have no stem at or above 5 cm; 9 carry 12 stems of 5 to 7 cm that are absent above the
floor at t2 (NB tree numbers are not stable tags). Mean stem count rises from 13.5 to 16.3: regeneration, not removal. GYDB
holds no NB treatment or disturbance rows at all, so the harvest test is weak by construction; TRT_AT_Y1 is 0 on all 33.
v141LT predicts 0.7 to 5.8 m3 ha-1 on them. NB is licensed "Internal", owner undocumented; aggregates only.

**Other sets.** medev_c and mefia_l_c (3 to 5 live t2 stems, maximum 4.8 cm) and ns_long_c (50 microplot stems, maximum
3.7 cm) show the same pattern, with no treatment or disturbance record. One FIA plot enters both medev_c and mefia_l_c.

**Arm invariance.** No arm in the PREREG19, PREREG23 or PREREG28 score tables covers nb_c (qc_c and qc_fl only). The
PREREG19 N0 control nbctl_a1000 (40 nb_c stands, 4 of them empty) matches v141LT on RUN_OK and all 23 observed and predicted
columns, worst scaled difference 0.

**Rescoring, nb_c, v141LT** (95 percent site cluster intervals, B = 2000; A0 reproduces the published PREREG16 values, gate G0):

| Variable | A0 ratio | A1 ratio | d ratio | A0 %RMSE | A1 %RMSE | d %RMSE | A0 bias | A1 bias |
|:--|:--|:--|--:|--:|--:|--:|--:|--:|
| Volume C0 | 0.987 (0.952 to 1.029) | 0.985 (0.949 to 1.027) | -0.002 | 38.23 | 36.40 | -1.83 | -1.26 | -1.48 |
| Volume C1 | 0.956 (0.922 to 0.993) | 0.954 (0.920 to 0.991) | -0.002 | 37.27 | 35.49 | -1.78 | -4.38 | -4.60 |
| Basal area | 0.994 (0.963 to 1.031) | 0.985 (0.954 to 1.020) | -0.009 | 33.02 | 31.30 | -1.73 | -0.56 | -1.46 |
| Stems | 1.187 (1.118 to 1.267) | 1.140 (1.073 to 1.214) | -0.047 | 67.38 | 62.13 | -5.25 | +18.72 | +14.01 |

Volume ratios barely move; %RMSE falls because its denominator rises by a tenth, and stems fall because predicted ingrowth
past 5 cm on these plots is a real overprediction. Elsewhere the largest moves are 0.0003 in ratio and 0.04 points.

**Proposed admission rule for 14.2 (not applied).** Keep the published admission. Class R zeros are valid observations,
and A1 conditions on the outcome, removing exactly the stands where predicted ingrowth did not happen. Add three checks to the scorer: (a) fail if any V_o = 0 stand has a source live stem at or above SCORE_MINDBH with
positive EXPF (class D); (b) exclude a stand as H or L only on a positive record; (c) where more than 5 percent of a set has
zero observed t1 volume at the floor (nb_c 37 of 355), report an "established at t1" row beside the all stands row. An
exploratory run of (c), not pre-registered, gives nb_c 318 stands: volume C0 0.986 (%RMSE 36.20), C1 0.955 (35.30), BA 0.988
(31.24), stems 1.154 (63.04).

**Verdicts whose nb_c reading would change under A1.** PREREG16 nb_c row (C0 0.987 to 0.985, C1 0.956 to 0.954, %RMSE 38.2
/ 37.3 to 36.4 / 35.5); PREREG14 steps 1 and 2, NB total V_p/V_o 0.987 to 0.985 (its diameter and height decomposition not
recomputed). PREREG19 N0 is an identity check and is unaffected. Under the proposed rule none changes.

![nb_c pooled ratios and percent RMSE under two admissions](assembled/gyr142-p32-nb-admission_2026-09-30.png)

**Figure 1. nb_c pooled ratio (left) and percent RMSE (right) for volume C0 and C1 (m3 ha-1), basal area (m2 ha-1) and
stems (ha-1), v141LT, published admission (355 stands) against V_o = 0 excluded (322 stands), 95 percent site cluster
bootstrap intervals from the published 2000 draws. A2 is identical to A0 and not drawn.** Every A1 ratio sits inside its
A0 interval; the stems point shifts most, and every %RMSE drops by 1.7 to 5.3 points.

## Re-derivation [F9]

`verify_20260930/2026-09-30_v142_p32_verify.R` (md5 e31f9062) sources no PREREG32 script. Empty t2 counts from the frame t2
lists (eight sets) and the stands table (medev_c, mefia_l_c) match all ten exactly. nb_c A0 and A1 for four variables, C0
from the results TOTVOL columns: worst difference 3.9e-10 (tolerance 1e-6). A per draw loop reproduces the A1 C0 interval
(0.9491 to 1.0269). The log ends `P32_VERIFY_DONE all checks pass`.

## Deviations

1. G0 tolerance 1e-9 is below the stands table's six decimal rounding (observed 3.9e-8 in points); the first run stopped at
   G0 (log and `.bak` kept). Revision 2 uses 1e-8 for ratio, 1e-6 for points; revision 3 fixed a column clash in the
   interval check (log kept).
2. B = 2000, not 1000: the published nb_c index holds 2000 draws, and using it reproduces the published intervals (5.2e-8).
3. No BA or stems for medev_c and mefia_l_c (results on Cardinal only); ns_long_c BA and stems use v141LTf. Stems are
   BA / (pi/40000 QMD^2).
4. The figure was redrawn from `fig_DATA` by `scripts/2026-09-30_v142_p32_fig.R` (panel order, margin); no value differs.
5. The frame builder read is the frozen PREREG29 copy of the FINAL builder; the 16 September original is not on firebreather.
6. The PREREG16 stands table holds 19 v141LT labels, not 21.

## Files

`assembled/`: gyr142-p32-classes (d30ecd17), rescore (cee434e7), materiality (a4238c86), arminv (62daea5b), fig_DATA
(3d6f0f82), figure (2f982ef5), per stand evidence marked SERVERONLY (3196329b). `logs/`: prereg_md5, audits, rescore,
explore_t1. `verify_20260930/`: script and log.

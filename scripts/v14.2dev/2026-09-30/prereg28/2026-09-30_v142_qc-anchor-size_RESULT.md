# Size dependent QC height anchor, 1.265 below 25 cm and 0.030 at and above: PREREG28 result

30 September 2026. Pre-registration: `plan/2026-09-30_v142_qc-anchor-size_PREREG28.md` (revision 1, md5 c4275a8d, recorded
08:01 server time before chain launch in `~/jobs/v142p28/logs/prereg_md5.txt`). Runner `runner_p28_fb.R` (md5 0a2b2742),
assembly `2026-09-30_v142_p28_assemble.R` (md5 2734ff5d), scorer `2026-09-27_v142_volconv_score.R` (md5 019df238, unedited).
Chain start 08:01, CHAIN_DONE 15:26 server time. L and T unchanged; GT1 stays a named failure. No em dashes.

## Verdict

**Rule 6. Every gate passes on screened qc_c fold B; the size dependent anchor is a 14.2 QC candidate, a regional usage
setting, not adopted into a release before a Bakuzis QC grid under its own pre-registration.** Which QC anchor goes forward
is decided by the PREREG28b choice rule (smaller absolute TOPHT bias on screened qc_c fold B, a difference under 0.5 points
going to PREREG28b), recorded before either candidate was read and applied in the PREREG28b result. 14.1 is unchanged.

| Gate, screened qc_c fold B | p28_cand | Reference | Pass |
|:--|:--|:--|:--:|
| H0 harness | p28_g0 against frozen p19_a0111: 0 over results and trees in qc_c (378 stands) and qc_fl (19) | at or below 1e-9 | Yes |
| K1 | RUN_OK other than 1 after retry: 0 in qc_c, 0 in qc_fl (no stand hit the time limit) | 0 | Yes |
| H_inc pooled | ratio 0.875 (0.736 to 1.102), 301 trees on 108 sites | 0.086 at 0.111 | Yes |
| H_inc below 12.7 cm | bias -0.084 m/yr (-0.132 to -0.029) | -0.254 at 0.111 | Yes |
| H_inc 12.7 to 25 cm | bias +0.011 m/yr (-0.027 to +0.052) | -0.161 at 0.111 | Yes |
| H_inc 25 cm and over | bias -0.032 m/yr (-0.115 to +0.073), worse by 0.010 | -0.021 at 0.111, margin 0.03 | Yes |
| TOPHT | +11.64 percent | +14.63 at 1.061 (limit); +6.29 at 0.111 | Yes |
| Dominant cohort t2 level | 0.983 | 0.922 at 0.111, margin 0.02 | Yes |
| V2 C1 %RMSE | 46.92, d -0.16 | 46.76 at 0.111, floor -0.5 | Yes |
| B1 basal area | abs(BA - 1) 0.41 points | 0.17 at 0.111, margin 1.0 | Yes |
| B2 stems | abs(stems - 1) 24.51 points | 24.23 at 0.111, margin 2.0 | Yes |

## What the held out data show

**The pair closes the small tree height growth deficit without the large tree cost that sank PREREG23.** At the shipped
0.111 the model grows QC trees at 9 percent of observed height increment (pooled ratio 0.086). The pair lifts that to 0.875,
close to the 0.828 of the single 1.061 multiplier, and does better in both small classes: bias below 12.7 cm moves from
-0.254 to -0.084 m/yr (1.061: -0.115), and 12.7 to 25 cm from -0.161 to +0.011 (1.061: -0.020). For trees 25 cm and over the
single 1.061 multiplier had pushed bias to +0.099 m/yr and failed rule 3; the pair holds it at -0.032 against -0.021 at 0.111,
worse by 0.010 against the 0.03 margin. The ratio in that class is not informative (observed increment 0.036 m/yr on 41
trees, interval spanning zero), so the gate reads bias, as pre-registered.

**Fold A transferred.** Fold A to fold B the pooled ratio fell from 1.03 to 0.875 and the class biases moved by 0.002 to
0.061 m/yr (fold A -0.086, +0.027 and +0.029), each fold A value inside its fold B interval (Figure 1). The clamped large tree value behaves as the fit said it would: 0.030
and 0.111 are indistinguishable in the 25 cm and over panel on both folds.

**TOPHT passes the pre-registered limit but nearly doubles.** Published TOPHT bias rises from +6.29 percent at 0.111 to
+11.64 percent, inside the +14.63 limit set by 1.061 and near the +12 expected. This is the cost of the gate structure
fixed in PREREG23: the reference for TOPHT is the worst accepted single multiplier, not the shipped value. The dominant
cohort (largest trees to 100 stems per ha at t1, 78 tag trees on 53 sites) shows the same trade in the other direction:
its t2 height level rises from 0.922 to 0.983, while its increment ratio sits at 0.72 against 0.98 under 1.061, because
the part of that cohort at 25 cm and over (46 percent on fold A) takes the 0.030 anchor. Stand volume, basal area and stems
barely move (C1 %RMSE 46.92 against 46.76; BA ratio 1.004 against 0.998; stems 0.755 against 0.758). The stems deficit of
about 24 points is a mortality and ingrowth property of the QC frame shared by every arm, not a height result.

**qc_fl, reported and not gated.** Five tag trees on four sites, all 12.7 to 25 cm: ratio 1.26 against 0.106 at 0.111;
screened fold B TOPHT +14.8 percent against +2.6 at 0.111 on five stands. Too few to read, and pointing the same way as
qc_c TOPHT.

![Fold A and fold B height increment by QC anchor](assembled/gyr142-p28-hinc_2026-09-30.png)

**Figure 1.** Predicted against observed annual height increment for tag matched QC survivors on screened qc_c, pooled
ratio (top left) and mean bias by t1 diameter class, for the four single multiplier arms of PREREG19 and PREREG23 and the
PREREG28 pair, fold A (fit) and fold B (held out), with 95 percent site cluster bootstrap intervals (B = 1000).

## Re-derivation [F9]

`verify_20260930/p28_rederive.R` (md5 2dd53738) shares no code with the helper or the assembly: its own fold code (md5 of
SITE), its own tag match, its own map from frame row to split runner trees (softwood id equals frame row with DBH checked;
hardwood rows claim the appended split parts whose EXPF sums to the frame EXPF) and its own retry replacement. It recomputes
the screened qc_c fold B height rows for p19_a0111, p23_a1061, p28_g0 and p28_cand and the stand quantities (TOPHT, BA,
stems, C1 %RMSE). All 20 height rows agree with `assembled/` (trees identical; worst ratio 4.4e-15, bias 4.4e-16, level
4.4e-15) and all 4 stand rows agree (stands identical; worst TOPHT 1.2e-14, RMSE 2.8e-14). The log ends
`P28_REDERIVE_DONE`. Bootstrap limits are not re-derived.

## Deviations

1. **Fit script revised once** before the pre-registration (rev1 failed; kept as `fit/fit_rev1_d5cf8067.R.bak` with the
   diff and failing log).
2. **No retries needed.** Both retry passes ended `remaining: 0`.
3. **Smoke check** on five p28_cand stands before launch confirmed the per tree multiplier (606 trees below 25 cm, 48 at
   and above in the smoke set) and RUN_OK 5 of 5; it is a harness check, not a result.

## Files

`~/jobs/v142p28/`: `plan/` (PREREG28, plans), `fit/` (step 1 on fold A), `scripts/` (fit, chosen, assembly, driver,
launcher, scorer and helper copies, chain), `logs/` (prereg md5, bundle and script diffs against PREREG23, chain, score,
assemble), `tables/` (scorer stand tables), `results/`, `assembled/` (gates, H0, K1, class gate, height and stand tables,
verdict, figure), `verify_20260930/`. Laptop: `outputs/2026-09/fvs-acd-v14.2-recs/p28/`.

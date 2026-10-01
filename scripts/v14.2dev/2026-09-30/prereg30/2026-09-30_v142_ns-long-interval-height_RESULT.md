# NS long interval end of interval height and top height, v141LTf and v141LTfi against 14.1: PREREG30 result

30 September 2026 (chain ran 30 September 20:26 to 1 October 00:57 server time). Pre-registration:
`plan/2026-09-30_v142_ns-long-interval-height_PREREG30.md` (revision 1, md5 2f407844, recorded 20:22:12 in
`logs/prereg_md5.txt` before any fold B read; no later revision). Frozen inputs, md5 checked by the assembly and listed in
`assembled/gyr142-p30-provenance_DATA_2026-09-30.csv`: PREREG20 key `p20_htkey_ns_long_c.csv` (fd8ab6d5) and
`p20_htkey_ns_long_fl.csv` (dce39692), fit parameters (b06277a2), v141LTf results (e475736f, f9b72f15), v141LTfi results
(9ac03bc2, cf8bf849), siteidx draws (f1cb3043, 7def79ab). v141LT per stand outputs for these sets are not on firebreather
(PREREG29 find logs), so v141LT was run new on fold B stands of both sets with the frozen runner `runner_p20_fb.R` (md5
65392afb, unedited) and `p20_env.sh` (8edd89f4, unedited) at column g0_off, stands selected by name. Assembly
`scripts/2026-09-30_v142_p30_assemble.R` revision 2 (md5 7a3d74c6). The PREREG16 scorer (019df238) was not needed: no
volume quantity is gated. L and T not re-estimated; GT1 stays a named failure. No em dashes.

## Verdict

**Rule 3. Every gate passes on ns_long_c fold B: the long interval data support the height form, and the PREREG26 top
height loss is read as a synthetic start artifact.** 14.1 over predicts end of interval height and top height on the long
NS intervals; v141LTf removes most of that, and v141LTfi is indistinguishable from it on survivors. The pre-registered
expectation (L4 the most likely failure) was wrong.

| Gate, ns_long_c fold B | v141LTf | v141LTfi (reported) | v141LT (14.1) | Threshold | Pass |
|:--|:--|:--|:--|:--|:--:|
| H0, new v141LT against frozen Cardinal Hp141, 81,966 key trees | | | worst 5.3e-15; K1 0 not OK, 0 retries | at or below 1e-9 | Yes |
| L1 pooled level ratio | 1.0041 | 1.0041 | 1.0152 | closer to 1 | Yes |
| L2 below 12.7 cm | 1.0004 | 1.0004 | 1.0014 | margin 0.03 | Yes |
| L2 12.7 to 25 cm | 1.0077 | 1.0078 | 1.0228 | margin 0.03 | Yes |
| L2 25 cm and over | 0.9987 | 0.9988 | 1.0220 | margin 0.03 | Yes |
| L3 dominant cohort level | 0.9925 | 0.9925 | 1.0153 | margin 0.02 | Yes |
| L4 published TOPHT bias | +0.41 percent | +0.42 | +2.37 | abs no worse | Yes |
| L5 level, intervals 10 years and over | 1.0368 | 1.0369 | 1.0628 | margin 0.02 | Yes |

Values from `assembled/gyr142-p30-gates_DATA_2026-09-30.csv`; H0 and K1 from `gyr142-p30-h0_` and `gyr142-p30-k1_DATA`.
Fold B: 69,333 tag matched survivors on 1,122 sites (ns_long_c), 12,633 on 976 sites (ns_long_fl); TOPHT on 4,279 and
1,165 fold B stands, all RUN_OK in all three arms.

## What the held out data show

**14.1 over predicts, and the error grows with interval length.** On ns_long_c fold B the v141LT level ratio is 1.0045
below 10 years, 1.0441 at 10 to 19 and 1.1194 at 20 years and over (2,925 trees, 213 sites); v141LTf gives 0.9967, 1.0247
and 1.0734. The height form halves the long interval excess but does not remove it: at 20 years and over v141LTf is still
+0.82 m against +1.34 m for 14.1, interval 1.0486 to 1.1018 (all from `gyr142-p30-height_DATA_2026-09-30.csv`). The
annual increment reading agrees: in the 25 cm and over class 14.1 is +0.044 m yr⁻¹ (0.034 to 0.055) against an observed
0.112, and v141LTf is -0.013 (-0.023 to -0.003), a small under prediction that is the cost of the fit.

**The dominant cohort moves from above to slightly below.** At t1 the largest trees to 100 stems ha⁻¹ that survive end at
1.0153 under 14.1 and 0.9925 (0.9886 to 0.9964) under v141LTf, a deviation of 0.75 percent against 1.53. The cohort level
sits below 1 because the form trims large tree growth on every interval, including the 5 year ones that dominate the set.

**Published TOPHT agrees with the survivors.** Fold B TOPHT bias is +2.37 percent for 14.1 (1.84 to 2.89) and +0.41 for
v141LTf (-0.11 to 0.92); by stand interval it is +12.67 against +4.92 at 20 years and over (227 stands) and +5.84 against
+2.00 at 10 to 19 years (`gyr142-p30-topht_DATA_2026-09-30.csv`). Mean absolute per stand error barely moves (1.093 to
1.060 m), so the gain is in level, not in stand to stand scatter.

**ns_long_fl, reported, points the same way with one exception.** Pooled level is 1.0755 for 14.1 and 1.0255 for v141LTf;
the 25 cm and over class goes from 1.1255 to 1.0443 and TOPHT from +4.96 to -2.26 percent. The exception is the 10 to 19
year bin (334 stands): every arm under predicts (level 0.9353 for 14.1, 0.9186 for v141LTf) and TOPHT goes from -8.69 to
-11.29 percent, so where 14.1 was already low the form makes it lower. That bin needs its own look before the form is
read as safe everywhere.

**v141LTfi adds nothing on survivors.** Its level ratios match v141LTf to within 0.0006 in every fold B row, because
threshold matching acts on recruits; its TOPHT effect here is +0.01 points on ns_long_c and +0.27 on ns_long_fl.

**Fold A transfers.** ns_long_c fold A gives 1.0146 (14.1) against 1.0038 (v141LTf) pooled, and 1.1089 against 1.0664 at
20 years and over, all inside the corresponding fold B intervals.

The reading of PREREG26 that rule 3 carries is narrower than its wording: the longest intervals in these sets are 35 years
(ns_long_c) and 40 years (ns_long_fl) in the PREREG20 key, not 100, and over that span 14.1 runs high, so a form that lowers projected top height moves toward the data. The
size of the PREREG26 loss at 100 years (14 to 25 percent) is not tested here.

![Fold B end of interval height by t1 diameter class](assembled/gyr142-p30-height-foldB_2026-09-30.png)

**Figure 1. Tag matched survivors, fold B, ns_long_c (left) and ns_long_fl (right), by t1 diameter class: predicted over
observed t2 height (top), mean bias in t2 height (m, middle) and mean bias in annual height increment (m yr⁻¹, bottom) for
v141LT (14.1), v141LTf and v141LTfi, with 95 percent site cluster bootstrap intervals (B = 1000, PREREG20 siteidx draws).
v141LTf and v141LTfi overlap in every class.**

## Re-derivation [F9]

`verify_20260930/2026-09-30_v142_p30_verify.R` (md5 ad11fdbc) uses no source(), its own fold code (openssl md5), its own
dominant cohort ordering and its own readers of the per tree and per stand outputs. It recomputes H0, every gate value
and every fold B point value of the height and TOPHT tables: 252 checks, 0 failed, worst absolute difference 1.06e-14
(`p30-verify-flags_DATA_2026-09-30.csv`); fold disagreement 0 in both sets; all key rows align with the t1 frame. Its own
tag match from the firebreather frame TREE column does not reproduce the key (96,685 of 137,915 ns_long_c key trees found,
H2 equal for 58,213), because the PREREG20 key used pass 28 tag frames that exist only on Cardinal; the gates are therefore
recomputed on the key population. The log ends `P30_VERIFY_DONE`. Bootstrap limits are not re-derived.

## Deviations

1. **Assembly revision 2.** The dry run of revision 1 stopped on a bootstrap quantile with empty draws in a small TOPHT
   interval bin; `na.rm = TRUE` was added to the two TOPHT quantiles (`diffs/assemble_rev2_vs_rev1.diff`, revision 1 kept
   as `scripts/2026-09-30_v142_p30_assemble_rev1.R.bak`). Only the dry run (v141LT stood in by v141LTf, `dry/`) was affected.
2. **v141LT run on fold B only**, as pre-registered, so fold A TOPHT for 14.1 is not reported. 3 of 4,282 fold B ns_long_c
   and 2 of 1,167 ns_long_fl keep list stands were outside the runner's admitted domain, as in the frozen arms.
3. **No retries were needed** (`RETRY_DONE g0_off remaining: 0`). A 3 stand smoke run (`home/out_smoke/`) preceded launch.
4. **Verify edits before its real run:** a renamed column and a dry test switch, both before any comparison was read.
5. File dates stay 2026-09-30 although the chain finished after midnight.

## Files

`~/jobs/v142p30/`: `plan/` (PREREG30), `logs/` (prereg md5, assembly, verify, dry runs), `scripts/` (taskmap, assembly and
revision 1), `home/` (bundle copy, p30 driver, launcher, retry scripts, taskmap, keep lists, `out/g0_off/`), `diffs/`,
`assembled/` (H0, K1, height, TOPHT, TOPHT per stand, gates, verdict, provenance, figure), `figs/` (preview JPEG),
`dry/`, `verify_20260930/`.

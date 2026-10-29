# QC height anchor changed for trees below 25 cm only, 0.111 kept for large trees: PREREG28b result

30 September 2026. Pre-registration: `plan/2026-09-30_v142_qc-anchor-small-only_PREREG28b.md` (revision 1, md5 8934d0b5,
recorded 15:21 server time before chain launch in `~/jobs/v142p28b/logs/prereg_md5.txt`, while PREREG28 was still running
and before any PREREG28 candidate output was read). Runner `runner_p28_fb.R` (md5 0a2b2742, unedited), bundle md5 identical
to PREREG28, scorer `2026-09-27_v142_volconv_score.R` (md5 019df238, unedited), assembly `2026-09-30_v142_p28b_assemble.R`
revision 2 (md5 90e6c5bc; see Deviations). Chain start 15:21, CHAIN_DONE 16:51 server time. L and T unchanged; GT1 stays a
named failure. No em dashes.

## Verdict

**Rule 6. Every gate passes on screened qc_c fold B. Under the pre-registered choice rule the small tree only anchor
(QC_AFAC_SMALL 1.265 below 25 cm t1 DBH, QC_AFAC_LARGE 0.111 at and above) is the 14.2 QC candidate**, a regional usage
setting, not adopted into a release before a Bakuzis QC grid under its own pre-registration. PREREG28 also reached rule 6.
Its published TOPHT bias on screened qc_c fold B is +11.64 percent against +11.97 here; the difference, 0.33 points, is
under the 0.5 point threshold fixed in PREREG28b, so the choice goes to PREREG28b, which leaves 14.1 unchanged for trees
25 cm and over. 14.1 is unchanged.

| Gate, screened qc_c fold B | p28b_small | p28_cand (PREREG28, reported) | Reference | Pass |
|:--|:--|:--|:--|:--:|
| H0 (cited from PREREG28 p28_g0) | 0 over results and trees, qc_c and qc_fl | same | at or below 1e-9 | Yes |
| K1 after retry | 0 in qc_c (378), 0 in qc_fl (19); no time limit hits | 0 | 0 | Yes |
| H_inc pooled | 0.883 (0.742 to 1.113) | 0.875 (0.736 to 1.102) | 0.086 at 0.111 | Yes |
| Bias below 12.7 cm | -0.084 m yr⁻¹ | -0.084 | -0.254 at 0.111 | Yes |
| Bias 12.7 to 25 cm | +0.011 m yr⁻¹ | +0.011 | -0.161 at 0.111 | Yes |
| Bias 25 cm and over | -0.021 m yr⁻¹ (-0.105 to +0.084), worse by 0.000 | -0.032, worse by 0.010 | -0.021 at 0.111, margin 0.03 | Yes |
| TOPHT | +11.97 percent | +11.64 | +14.63 at 1.061 (limit); +6.29 at 0.111 | Yes |
| Dominant cohort t2 level | 0.986 | 0.983 | 0.922 at 0.111, margin 0.02 | Yes |
| V2 C1 %RMSE | 46.91, d -0.16 | 46.92, d -0.16 | 46.76 at 0.111, floor -0.5 | Yes |
| B1 basal area | abs(BA - 1) 0.40 points | 0.41 | 0.17 at 0.111, margin 1.0 | Yes |
| B2 stems | abs(stems - 1) 24.52 points | 24.51 | 24.23 at 0.111, margin 2.0 | Yes |

Tag matched survivors: 301 trees on 108 sites (fold B), 264 trees (fold A).

## What the held out data show

**The small tree anchor does all the work; the large tree value does none.** In both small classes the two arms agree to
the seventh decimal on fold B (below 12.7 cm bias -0.0840107 against -0.0840107 m yr⁻¹; 12.7 to 25 cm +0.0111373 against
+0.0111372). In the 25 cm and over class p28b_small reproduces the 0.111 arm to 5e-9 m yr⁻¹ (-0.0213037 against -0.0213037),
so taller small trees do not change large tree height growth through the competition terms over one remeasurement interval.
The PREREG28 pair's large tree clamp at 0.030 moved that class to -0.032 m yr⁻¹, a change the tag data cannot distinguish
from zero (interval -0.115 to +0.073). This arm drops that change and costs nothing measurable.

**What it costs is TOPHT, and that cost is the same for both arms.** Published TOPHT bias goes from +6.29 percent at 0.111
to +11.97 percent, inside the +14.63 limit and inside the +10 to +12 range stated in the plan. It is 0.33 points above the
pair because large trees at 0.111 keep slightly more height growth than at 0.030. The dominant cohort level (0.986) is
closer to 1 than at 0.111 (0.922). Volume, basal area and stems do not move (C1 %RMSE 46.91; BA 1.004; stems 0.755).

**Fold A transferred.** Fold A values (pooled 1.041; biases -0.086, +0.027 and +0.040 m yr⁻¹ by class) all sit inside the
fold B intervals, as in PREREG28. The fold A offline row in the plan (pooled 1.040; -0.087, +0.027, +0.040) is within 0.001 of
the engine run on every entry, so the offline reading of step 1 was a fair guide for this arm.

**qc_fl, reported and not gated.** Five tag trees on four sites, ratio 1.26; screened fold B TOPHT +15.4 percent on five
stands (pair +14.8, 0.111 +2.6). Too few to read, pointing the same way as qc_c TOPHT.

![Height increment by QC anchor, both folds](figs/gyr142-p28b-hinc-labelled_2026-09-30.png)

**Figure 1.** Predicted against observed annual height increment for tag matched QC survivors on screened qc_c: pooled ratio
and mean bias by t1 diameter class for the PREREG19 and PREREG23 single multiplier arms, the PREREG28 pair and the PREREG28b
small tree only anchor, fold A (fit) and fold B (held out), 95 percent site cluster bootstrap intervals (B = 1000). Redrawn
from `assembled/gyr142-p28b-hinc_DATA_2026-09-30.csv` with wrapped arm labels because the two long labels overlap in the
assembly figure; no value differs.

## Re-derivation [F9]

`verify_20260930/p28b_rederive.R` (md5 3227f525) is the PREREG28 re-derivation (md5 2dd53738, which shares no code with the
helper or the assembly) with p28b_small added and the comparison read from the PREREG28b assembly. All 25 height rows agree
with `assembled/` (trees identical; worst ratio 4.4e-15, bias 4.4e-16, level 4.4e-15) and all 5 stand rows agree (stands
identical; worst TOPHT 1.2e-14, RMSE 2.8e-14); it recomputes TOPHT +11.645 for p28_cand and +11.968 for p28b_small, the two
values the choice rule reads. The log ends `P28B_REDERIVE_DONE`. Bootstrap limits are not re-derived.

## Deviations

1. **Assembly revision 2.** The first assembly stopped (exit 1) after H0 had passed and before any gate or fold B value was
   computed: the build step's blanket rename of output names (`gyr142-p28-` to `gyr142-p28b-`) had also renamed the path of
   the PREREG28 stand table, so the p28_g0 and p28_cand stand tables were looked for under a name that does not exist. The
   dry run did not catch it because in dry mode those two arms are stood in by PREREG19 and PREREG23 arms with their own
   tables. One path was restored (`diffs/assemble_rev2_vs_rev1.diff`); revision 1 is kept as
   `scripts/assemble_rev1_*_failed.R.bak` with its log `logs/assemble_rev1_failed.txt`, and the empty output directory it
   created as `assembled_rev1_failed_empty/`. The assembly was then run by hand and CHAIN_DONE recorded in the chain log.
   No engine output, score or gate changed.
2. **Figure 1 redrawn** from the assembled table (see caption).
3. **No retries needed.** The retry pass ended `remaining: 0`.

## Files

`~/jobs/v142p28b/`: `plan/` (PREREG28b, plans), `scripts/` (driver, launcher, scorer and helper copies, assembly revisions,
chain, `src_build/`), `home/` (bundle copy, retry scripts, taskmap), `diffs/` (every script against PREREG28, taskmap,
assembly revision), `logs/` (prereg md5, bundle checks, chain, score, assemble), `tables/`, `results/`, `assembled/` (gates,
H0, K1, class gate, height and stand tables, verdict, figure), `figs/`, `verify_20260930/`. Laptop:
`outputs/2026-09/fvs-acd-v14.2-recs/p28b/`.
